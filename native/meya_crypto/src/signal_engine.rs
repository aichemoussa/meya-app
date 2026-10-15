//
// Copyright 2026 PRIMA ELITE FZ-LLC.
// SPDX-License-Identifier: AGPL-3.0-only
//
//! MEYA's end-to-end encryption engine.
//!
//! This module wraps Signal's maintained `libsignal-protocol` implementation
//! (PQXDH session setup + Triple Ratchet = Double Ratchet + SPQR). MEYA does
//! not implement any cryptographic protocol itself.
//!
//! What this module adds:
//! * a persistent protocol store (identity, pre-keys, sessions, trusted
//!   identities), encrypted at rest with AES-256-GCM under a 32-byte storage
//!   key that the app keeps in the platform's secure storage;
//! * a strict trust policy: a remote identity is only trusted after the app
//!   has explicitly pinned it (from a scanned QR code, or when the user
//!   accepts a connection request). Unknown or changed identities are refused;
//! * a portable encoding of pre-key bundles for MEYA's pairing messages.
//!
//! Private keys and session state never leave this module.

use std::cell::RefCell;
use std::collections::HashMap;
use std::fs;
use std::path::{Path, PathBuf};
use std::time::SystemTime;

use aes_gcm::{
    Aes256Gcm, Key, Nonce,
    aead::{Aead, KeyInit, Payload},
};
use async_trait::async_trait;
use base64::{Engine as _, engine::general_purpose::STANDARD as B64};
use futures_util::FutureExt;
use libsignal_protocol::{
    CiphertextMessage, CiphertextMessageType, DeviceId, Direction, GenericSignedPreKey,
    IdentityChange, IdentityKey, IdentityKeyPair, IdentityKeyStore, KeyPair, KyberPreKeyId,
    KyberPreKeyRecord, KyberPreKeyStore, PreKeyBundle, PreKeyId, PreKeyRecord, PreKeySignalMessage,
    PreKeyStore, ProtocolAddress, PublicKey, SessionRecord, SessionStore, SignalMessage,
    SignalProtocolError, SignedPreKeyId, SignedPreKeyRecord, SignedPreKeyStore, Timestamp, kem,
    message_decrypt, message_encrypt, process_prekey_bundle,
};
use rand::rngs::OsRng;
use rand::{Rng, TryRngCore as _};
use serde::{Deserialize, Serialize};

type SignalResult<T> = Result<T, SignalProtocolError>;

const STORE_FORMAT_VERSION: u8 = 1;
const STORE_AAD: &[u8] = b"meya-signal-store-v1";
const BUNDLE_FORMAT_VERSION: u8 = 1;
const STORAGE_KEY_LENGTH: usize = 32;
const NONCE_LENGTH: usize = 12;
/// MEYA addresses each remote device by its relay device ID, device 1.
const REMOTE_DEVICE: u8 = 1;

/// Errors returned to the app. Messages never contain key material.
#[derive(Debug)]
pub enum EngineError {
    Storage(String),
    Protocol(String),
    UntrustedIdentity,
    InvalidInput(String),
}

impl std::fmt::Display for EngineError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            EngineError::Storage(m) => write!(f, "MEYA encryption storage error: {m}"),
            EngineError::Protocol(m) => write!(f, "MEYA encryption error: {m}"),
            EngineError::UntrustedIdentity => write!(
                f,
                "This contact's identity key is not trusted on this device. Verify them again in person."
            ),
            EngineError::InvalidInput(m) => write!(f, "Invalid input: {m}"),
        }
    }
}

impl From<SignalProtocolError> for EngineError {
    fn from(error: SignalProtocolError) -> Self {
        match error {
            SignalProtocolError::UntrustedIdentity(_) => EngineError::UntrustedIdentity,
            other => EngineError::Protocol(other.to_string()),
        }
    }
}

pub type EngineResult<T> = Result<T, EngineError>;

/// Ciphertext produced for one message.
#[derive(Debug, Clone)]
pub struct EncryptedMessage {
    /// 3 = PreKey (first message of a session), 2 = normal message.
    pub message_type: u8,
    pub body: Vec<u8>,
}

// ---------------------------------------------------------------------------
// Persistent, encrypted protocol store
// ---------------------------------------------------------------------------

#[derive(Serialize, Deserialize, Default)]
struct StoreSnapshot {
    version: u8,
    identity_key_pair: String,
    registration_id: u32,
    next_pre_key_id: u32,
    /// address -> serialized IdentityKey (explicitly pinned identities only)
    identities: HashMap<String, String>,
    sessions: HashMap<String, String>,
    pre_keys: HashMap<u32, String>,
    signed_pre_keys: HashMap<u32, String>,
    kyber_pre_keys: HashMap<u32, String>,
}

struct MeyaProtocolStore {
    path: PathBuf,
    storage_key: [u8; STORAGE_KEY_LENGTH],
    identity_key_pair: IdentityKeyPair,
    registration_id: u32,
    next_pre_key_id: u32,
    identities: HashMap<String, IdentityKey>,
    sessions: HashMap<String, Vec<u8>>,
    pre_keys: HashMap<u32, Vec<u8>>,
    signed_pre_keys: HashMap<u32, Vec<u8>>,
    kyber_pre_keys: HashMap<u32, Vec<u8>>,
}

fn storage_error(message: impl Into<String>) -> SignalProtocolError {
    SignalProtocolError::InvalidState("meya_store", message.into())
}

fn b64(bytes: &[u8]) -> String {
    B64.encode(bytes)
}

fn unb64(text: &str) -> EngineResult<Vec<u8>> {
    B64.decode(text)
        .map_err(|_| EngineError::Storage("corrupt base64 in store".into()))
}

fn seal(key: &[u8; STORAGE_KEY_LENGTH], plaintext: &[u8], aad: &[u8]) -> EngineResult<Vec<u8>> {
    let key = Key::<Aes256Gcm>::try_from(key.as_slice())
        .map_err(|_| EngineError::Storage("invalid storage key".into()))?;
    let cipher = Aes256Gcm::new(&key);
    let mut nonce_bytes = [0u8; NONCE_LENGTH];
    OsRng
        .try_fill_bytes(&mut nonce_bytes)
        .map_err(|_| EngineError::Storage("secure random generation failed".into()))?;
    let nonce = Nonce::try_from(nonce_bytes.as_slice())
        .map_err(|_| EngineError::Storage("invalid nonce".into()))?;
    let ciphertext = cipher
        .encrypt(&nonce, Payload { msg: plaintext, aad })
        .map_err(|_| EngineError::Storage("store encryption failed".into()))?;
    let mut out = Vec::with_capacity(1 + NONCE_LENGTH + ciphertext.len());
    out.push(STORE_FORMAT_VERSION);
    out.extend_from_slice(&nonce_bytes);
    out.extend_from_slice(&ciphertext);
    Ok(out)
}

fn open(key: &[u8; STORAGE_KEY_LENGTH], sealed: &[u8], aad: &[u8]) -> EngineResult<Vec<u8>> {
    if sealed.len() < 1 + NONCE_LENGTH + 16 || sealed[0] != STORE_FORMAT_VERSION {
        return Err(EngineError::Storage("unsupported or truncated store file".into()));
    }
    let key = Key::<Aes256Gcm>::try_from(key.as_slice())
        .map_err(|_| EngineError::Storage("invalid storage key".into()))?;
    let cipher = Aes256Gcm::new(&key);
    let nonce = Nonce::try_from(&sealed[1..1 + NONCE_LENGTH])
        .map_err(|_| EngineError::Storage("invalid nonce".into()))?;
    cipher
        .decrypt(
            &nonce,
            Payload {
                msg: &sealed[1 + NONCE_LENGTH..],
                aad,
            },
        )
        .map_err(|_| {
            EngineError::Storage(
                "the encrypted store could not be authenticated (wrong key or tampered file)"
                    .into(),
            )
        })
}

impl MeyaProtocolStore {
    fn open_or_create(path: &Path, storage_key: &[u8]) -> EngineResult<Self> {
        let storage_key: [u8; STORAGE_KEY_LENGTH] = storage_key
            .try_into()
            .map_err(|_| EngineError::InvalidInput("storage key must be 32 bytes".into()))?;

        if path.exists() {
            let sealed = fs::read(path).map_err(|e| EngineError::Storage(e.to_string()))?;
            let json = open(&storage_key, &sealed, STORE_AAD)?;
            let snapshot: StoreSnapshot = serde_json::from_slice(&json)
                .map_err(|_| EngineError::Storage("store contents are not valid".into()))?;
            if snapshot.version != STORE_FORMAT_VERSION {
                return Err(EngineError::Storage("unsupported store version".into()));
            }
            let identity_key_pair =
                IdentityKeyPair::try_from(unb64(&snapshot.identity_key_pair)?.as_slice())?;

            let mut identities = HashMap::new();
            for (address, key) in snapshot.identities {
                identities.insert(address, IdentityKey::decode(&unb64(&key)?)?);
            }
            let decode_map = |map: HashMap<String, String>| -> EngineResult<HashMap<String, Vec<u8>>> {
                map.into_iter().map(|(k, v)| Ok((k, unb64(&v)?))).collect()
            };
            let decode_id_map = |map: HashMap<u32, String>| -> EngineResult<HashMap<u32, Vec<u8>>> {
                map.into_iter().map(|(k, v)| Ok((k, unb64(&v)?))).collect()
            };

            return Ok(Self {
                path: path.to_path_buf(),
                storage_key,
                identity_key_pair,
                registration_id: snapshot.registration_id,
                next_pre_key_id: snapshot.next_pre_key_id,
                identities,
                sessions: decode_map(snapshot.sessions)?,
                pre_keys: decode_id_map(snapshot.pre_keys)?,
                signed_pre_keys: decode_id_map(snapshot.signed_pre_keys)?,
                kyber_pre_keys: decode_id_map(snapshot.kyber_pre_keys)?,
            });
        }

        let mut rng = OsRng.unwrap_err();
        let store = Self {
            path: path.to_path_buf(),
            storage_key,
            identity_key_pair: IdentityKeyPair::generate(&mut rng),
            // Registration IDs fit in 14 bits and must not be 0.
            registration_id: u32::from(rng.random_range(1u16..=0x3fff)),
            next_pre_key_id: rng.random_range(1u32..0x00ff_ffff),
            identities: HashMap::new(),
            sessions: HashMap::new(),
            pre_keys: HashMap::new(),
            signed_pre_keys: HashMap::new(),
            kyber_pre_keys: HashMap::new(),
        };
        store.persist().map_err(EngineError::from)?;
        Ok(store)
    }

    /// Writes the whole store, encrypted, via a temporary file + rename so a
    /// crash never leaves a half-written store.
    fn persist(&self) -> SignalResult<()> {
        let snapshot = StoreSnapshot {
            version: STORE_FORMAT_VERSION,
            identity_key_pair: b64(&self.identity_key_pair.serialize()),
            registration_id: self.registration_id,
            next_pre_key_id: self.next_pre_key_id,
            identities: self
                .identities
                .iter()
                .map(|(k, v)| (k.clone(), b64(&v.serialize())))
                .collect(),
            sessions: self.sessions.iter().map(|(k, v)| (k.clone(), b64(v))).collect(),
            pre_keys: self.pre_keys.iter().map(|(k, v)| (*k, b64(v))).collect(),
            signed_pre_keys: self
                .signed_pre_keys
                .iter()
                .map(|(k, v)| (*k, b64(v)))
                .collect(),
            kyber_pre_keys: self.kyber_pre_keys.iter().map(|(k, v)| (*k, b64(v))).collect(),
        };
        let json = serde_json::to_vec(&snapshot).map_err(|e| storage_error(e.to_string()))?;
        let sealed = seal(&self.storage_key, &json, STORE_AAD)
            .map_err(|e| storage_error(e.to_string()))?;
        let tmp = self.path.with_extension("tmp");
        fs::write(&tmp, &sealed).map_err(|e| storage_error(e.to_string()))?;
        fs::rename(&tmp, &self.path).map_err(|e| storage_error(e.to_string()))?;
        Ok(())
    }

    fn take_pre_key_id(&mut self) -> u32 {
        let id = self.next_pre_key_id;
        self.next_pre_key_id = if id >= 0x00ff_fffe { 1 } else { id + 1 };
        id
    }
}

/// A handle to the store. libsignal takes each store role as a separate
/// `&mut dyn Trait`; giving it several distinct handles that share one
/// `RefCell` avoids aliasing mutable references (no `unsafe`). Every method
/// borrows the store only for its synchronous body.
#[derive(Clone, Copy)]
struct StoreRef<'a>(&'a RefCell<MeyaProtocolStore>);

#[async_trait(?Send)]
impl IdentityKeyStore for StoreRef<'_> {
    async fn get_identity_key_pair(&self) -> SignalResult<IdentityKeyPair> {
        Ok(self.0.borrow().identity_key_pair)
    }

    async fn get_local_registration_id(&self) -> SignalResult<u32> {
        Ok(self.0.borrow().registration_id)
    }

    async fn save_identity(
        &mut self,
        address: &ProtocolAddress,
        identity: &IdentityKey,
    ) -> SignalResult<IdentityChange> {
        let mut store = self.0.borrow_mut();
        let key = address.name().to_string();
        match store.identities.get(&key) {
            Some(existing) if existing == identity => Ok(IdentityChange::NewOrUnchanged),
            // Never silently replace a pinned identity.
            Some(_) => Err(SignalProtocolError::UntrustedIdentity(address.clone())),
            None => {
                store.identities.insert(key, *identity);
                store.persist()?;
                Ok(IdentityChange::NewOrUnchanged)
            }
        }
    }

    async fn is_trusted_identity(
        &self,
        address: &ProtocolAddress,
        identity: &IdentityKey,
        _direction: Direction,
    ) -> SignalResult<bool> {
        // Strict: only identities the app explicitly pinned are trusted.
        Ok(self
            .0
            .borrow()
            .identities
            .get(address.name())
            .is_some_and(|pinned| pinned == identity))
    }

    async fn get_identity(&self, address: &ProtocolAddress) -> SignalResult<Option<IdentityKey>> {
        Ok(self.0.borrow().identities.get(address.name()).copied())
    }
}

#[async_trait(?Send)]
impl PreKeyStore for StoreRef<'_> {
    async fn get_pre_key(&self, id: PreKeyId) -> SignalResult<PreKeyRecord> {
        let store = self.0.borrow();
        let bytes = store
            .pre_keys
            .get(&u32::from(id))
            .ok_or(SignalProtocolError::InvalidPreKeyId)?;
        PreKeyRecord::deserialize(bytes)
    }

    async fn save_pre_key(&mut self, id: PreKeyId, record: &PreKeyRecord) -> SignalResult<()> {
        let mut store = self.0.borrow_mut();
        store.pre_keys.insert(u32::from(id), record.serialize()?);
        store.persist()
    }

    async fn remove_pre_key(&mut self, id: PreKeyId) -> SignalResult<()> {
        let mut store = self.0.borrow_mut();
        store.pre_keys.remove(&u32::from(id));
        store.persist()
    }
}

#[async_trait(?Send)]
impl SignedPreKeyStore for StoreRef<'_> {
    async fn get_signed_pre_key(&self, id: SignedPreKeyId) -> SignalResult<SignedPreKeyRecord> {
        let store = self.0.borrow();
        let bytes = store
            .signed_pre_keys
            .get(&u32::from(id))
            .ok_or(SignalProtocolError::InvalidSignedPreKeyId)?;
        SignedPreKeyRecord::deserialize(bytes)
    }

    async fn save_signed_pre_key(
        &mut self,
        id: SignedPreKeyId,
        record: &SignedPreKeyRecord,
    ) -> SignalResult<()> {
        let mut store = self.0.borrow_mut();
        store.signed_pre_keys.insert(u32::from(id), record.serialize()?);
        store.persist()
    }
}

#[async_trait(?Send)]
impl KyberPreKeyStore for StoreRef<'_> {
    async fn get_kyber_pre_key(&self, id: KyberPreKeyId) -> SignalResult<KyberPreKeyRecord> {
        let store = self.0.borrow();
        let bytes = store
            .kyber_pre_keys
            .get(&u32::from(id))
            .ok_or(SignalProtocolError::InvalidKyberPreKeyId)?;
        KyberPreKeyRecord::deserialize(bytes)
    }

    async fn save_kyber_pre_key(
        &mut self,
        id: KyberPreKeyId,
        record: &KyberPreKeyRecord,
    ) -> SignalResult<()> {
        let mut store = self.0.borrow_mut();
        store.kyber_pre_keys.insert(u32::from(id), record.serialize()?);
        store.persist()
    }

    async fn mark_kyber_pre_key_used(
        &mut self,
        id: KyberPreKeyId,
        _ec_prekey_id: SignedPreKeyId,
        _base_key: &PublicKey,
    ) -> SignalResult<()> {
        // MEYA issues one-time ML-KEM pre-keys (one per pairing), so a used
        // key is deleted. A replayed first message then fails to decrypt.
        let mut store = self.0.borrow_mut();
        store.kyber_pre_keys.remove(&u32::from(id));
        store.persist()
    }
}

#[async_trait(?Send)]
impl SessionStore for StoreRef<'_> {
    async fn load_session(&self, address: &ProtocolAddress) -> SignalResult<Option<SessionRecord>> {
        match self.0.borrow().sessions.get(address.name()) {
            Some(bytes) => Ok(Some(SessionRecord::deserialize(bytes)?)),
            None => Ok(None),
        }
    }

    async fn store_session(
        &mut self,
        address: &ProtocolAddress,
        record: &SessionRecord,
    ) -> SignalResult<()> {
        let mut store = self.0.borrow_mut();
        store
            .sessions
            .insert(address.name().to_string(), record.serialize()?);
        store.persist()
    }
}

// ---------------------------------------------------------------------------
// Portable pre-key bundle (sent inside MEYA's pairing response)
// ---------------------------------------------------------------------------

#[derive(Serialize, Deserialize)]
struct BundleWire {
    v: u8,
    registration_id: u32,
    pre_key_id: u32,
    pre_key: String,
    signed_pre_key_id: u32,
    signed_pre_key: String,
    signed_pre_key_signature: String,
    kyber_pre_key_id: u32,
    kyber_pre_key: String,
    kyber_pre_key_signature: String,
    identity_key: String,
}

// ---------------------------------------------------------------------------
// Engine
// ---------------------------------------------------------------------------

/// Runs a store future that completes synchronously (all store I/O is sync).
fn run<T>(future: impl std::future::Future<Output = T>) -> T {
    future
        .now_or_never()
        .expect("MEYA protocol store operations are synchronous")
}

fn address(remote: &str) -> EngineResult<ProtocolAddress> {
    if remote.is_empty() || remote.len() > 128 {
        return Err(EngineError::InvalidInput("remote device ID is invalid".into()));
    }
    let device = DeviceId::new(REMOTE_DEVICE)
        .map_err(|_| EngineError::InvalidInput("invalid device number".into()))?;
    Ok(ProtocolAddress::new(remote.to_string(), device))
}

pub struct SignalEngine {
    store: RefCell<MeyaProtocolStore>,
    local: ProtocolAddress,
}

impl SignalEngine {
    /// Opens (or creates on first use) the encrypted store at `store_path`.
    pub fn open(store_path: &str, storage_key: &[u8], local_device_id: &str) -> EngineResult<Self> {
        let store = MeyaProtocolStore::open_or_create(Path::new(store_path), storage_key)?;
        Ok(Self {
            store: RefCell::new(store),
            local: address(local_device_id)?,
        })
    }

    /// This device's identity public key (33 bytes). It goes into the QR code.
    pub fn identity_public_key(&self) -> Vec<u8> {
        self.store.borrow().identity_key_pair.identity_key().serialize().to_vec()
    }

    /// Creates fresh one-time pre-keys and returns a bundle to send to a
    /// contact during pairing.
    pub fn create_pre_key_bundle(&self) -> EngineResult<String> {
        let mut rng = OsRng.unwrap_err();
        let (identity, registration_id, pre_key_id, signed_pre_key_id, kyber_pre_key_id) = {
            let mut store = self.store.borrow_mut();
            (
                store.identity_key_pair,
                store.registration_id,
                store.take_pre_key_id(),
                store.take_pre_key_id(),
                store.take_pre_key_id(),
            )
        };
        let mut handle = StoreRef(&self.store);

        let pre_key = KeyPair::generate(&mut rng);
        let signed_pre_key = KeyPair::generate(&mut rng);
        let signed_signature = identity
            .private_key()
            .calculate_signature(&signed_pre_key.public_key.serialize(), &mut rng)
            .map_err(|e| EngineError::Protocol(e.to_string()))?;
        let kyber_record = KyberPreKeyRecord::generate(
            kem::KeyType::Kyber1024,
            kyber_pre_key_id.into(),
            identity.private_key(),
        )?;

        let now = SystemTime::now()
            .duration_since(SystemTime::UNIX_EPOCH)
            .map(|d| d.as_millis() as u64)
            .unwrap_or(0);

        run(handle.save_pre_key(
            pre_key_id.into(),
            &PreKeyRecord::new(pre_key_id.into(), &pre_key),
        ))?;
        run(handle.save_signed_pre_key(
            signed_pre_key_id.into(),
            &SignedPreKeyRecord::new(
                signed_pre_key_id.into(),
                Timestamp::from_epoch_millis(now),
                &signed_pre_key,
                &signed_signature,
            ),
        ))?;
        run(handle.save_kyber_pre_key(kyber_pre_key_id.into(), &kyber_record))?;

        let wire = BundleWire {
            v: BUNDLE_FORMAT_VERSION,
            registration_id,
            pre_key_id,
            pre_key: b64(&pre_key.public_key.serialize()),
            signed_pre_key_id,
            signed_pre_key: b64(&signed_pre_key.public_key.serialize()),
            signed_pre_key_signature: b64(&signed_signature),
            kyber_pre_key_id,
            kyber_pre_key: b64(&kyber_record.public_key()?.serialize()),
            kyber_pre_key_signature: b64(&kyber_record.signature()?),
            identity_key: b64(&identity.identity_key().serialize()),
        };
        serde_json::to_string(&wire).map_err(|e| EngineError::Protocol(e.to_string()))
    }

    /// Pins `identity_key` for `remote`. Called when the identity is known
    /// out of band: scanned from a QR code, or accepted by the user.
    /// Fails if a different identity is already pinned for that device.
    pub fn pin_identity(&self, remote: &str, identity_key: &[u8]) -> EngineResult<()> {
        let identity = IdentityKey::decode(identity_key)?;
        run(StoreRef(&self.store).save_identity(&address(remote)?, &identity))?;
        Ok(())
    }

    /// Starts a session from a contact's bundle. The bundle's identity must
    /// equal the identity already pinned for that contact (from the QR code).
    pub fn start_session(&self, remote: &str, bundle_json: &str) -> EngineResult<()> {
        let wire: BundleWire = serde_json::from_str(bundle_json)
            .map_err(|_| EngineError::InvalidInput("pre-key bundle is malformed".into()))?;
        if wire.v != BUNDLE_FORMAT_VERSION {
            return Err(EngineError::InvalidInput("unsupported pre-key bundle version".into()));
        }

        let remote_address = address(remote)?;
        let identity = IdentityKey::decode(&unb64(&wire.identity_key)?)?;
        if run(StoreRef(&self.store).get_identity(&remote_address))? != Some(identity) {
            return Err(EngineError::UntrustedIdentity);
        }

        let bundle = PreKeyBundle::new(
            wire.registration_id,
            DeviceId::new(REMOTE_DEVICE)
                .map_err(|_| EngineError::InvalidInput("invalid device number".into()))?,
            Some((
                wire.pre_key_id.into(),
                PublicKey::deserialize(&unb64(&wire.pre_key)?)
                    .map_err(|e| EngineError::Protocol(e.to_string()))?,
            )),
            wire.signed_pre_key_id.into(),
            PublicKey::deserialize(&unb64(&wire.signed_pre_key)?)
                .map_err(|e| EngineError::Protocol(e.to_string()))?,
            unb64(&wire.signed_pre_key_signature)?,
            wire.kyber_pre_key_id.into(),
            kem::PublicKey::deserialize(&unb64(&wire.kyber_pre_key)?)?,
            unb64(&wire.kyber_pre_key_signature)?,
            identity,
        )?;

        let mut rng = OsRng.unwrap_err();
        let (mut sessions, mut identities) = (StoreRef(&self.store), StoreRef(&self.store));
        run(process_prekey_bundle(
            &remote_address,
            &self.local,
            &mut sessions,
            &mut identities,
            &bundle,
            SystemTime::now(),
            &mut rng,
        ))?;
        Ok(())
    }

    pub fn has_session(&self, remote: &str) -> EngineResult<bool> {
        Ok(self.store.borrow().sessions.contains_key(address(remote)?.name()))
    }

    pub fn encrypt(&self, remote: &str, plaintext: &[u8]) -> EngineResult<EncryptedMessage> {
        let remote_address = address(remote)?;
        let mut rng = OsRng.unwrap_err();
        let (mut sessions, mut identities) = (StoreRef(&self.store), StoreRef(&self.store));
        let message = run(message_encrypt(
            plaintext,
            &remote_address,
            &self.local,
            &mut sessions,
            &mut identities,
            SystemTime::now(),
            &mut rng,
        ))?;
        Ok(EncryptedMessage {
            message_type: message.message_type() as u8,
            body: message.serialize().to_vec(),
        })
    }

    pub fn decrypt(&self, remote: &str, message_type: u8, body: &[u8]) -> EngineResult<Vec<u8>> {
        let remote_address = address(remote)?;
        let message = match CiphertextMessageType::try_from(message_type) {
            Ok(CiphertextMessageType::PreKey) => {
                CiphertextMessage::PreKeySignalMessage(PreKeySignalMessage::try_from(body)?)
            }
            Ok(CiphertextMessageType::Whisper) => {
                CiphertextMessage::SignalMessage(SignalMessage::try_from(body)?)
            }
            _ => return Err(EngineError::InvalidInput("unsupported message type".into())),
        };
        let mut rng = OsRng.unwrap_err();
        let (mut sessions, mut identities, mut pre_keys, signed_pre_keys, mut kyber_pre_keys) = (
            StoreRef(&self.store),
            StoreRef(&self.store),
            StoreRef(&self.store),
            StoreRef(&self.store),
            StoreRef(&self.store),
        );
        let plaintext = run(message_decrypt(
            &message,
            &remote_address,
            &self.local,
            &mut sessions,
            &mut identities,
            &mut pre_keys,
            &signed_pre_keys,
            &mut kyber_pre_keys,
            &mut rng,
        ))?;
        Ok(plaintext)
    }

    /// Removes everything known about a contact (identity pin and session).
    pub fn forget(&self, remote: &str) -> EngineResult<()> {
        let key = address(remote)?.name().to_string();
        let mut store = self.store.borrow_mut();
        store.identities.remove(&key);
        store.sessions.remove(&key);
        store.persist()?;
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    struct TempDir(PathBuf);
    impl TempDir {
        fn new(tag: &str) -> Self {
            let mut path = std::env::temp_dir();
            let mut suffix = [0u8; 8];
            OsRng.try_fill_bytes(&mut suffix).unwrap();
            path.push(format!("meya-engine-{tag}-{}", b64(&suffix).replace(['/', '+', '='], "")));
            fs::create_dir_all(&path).unwrap();
            Self(path)
        }
        fn file(&self, name: &str) -> String {
            self.0.join(name).to_string_lossy().into_owned()
        }
    }
    impl Drop for TempDir {
        fn drop(&mut self) {
            let _ = fs::remove_dir_all(&self.0);
        }
    }

    fn key(byte: u8) -> Vec<u8> {
        vec![byte; 32]
    }

    /// Simulates MEYA pairing: Alice scans Bob's QR (pins his identity),
    /// Bob accepts (pins Alice's identity) and sends a bundle.
    fn paired(dir: &TempDir) -> (SignalEngine, SignalEngine) {
        let alice = SignalEngine::open(&dir.file("alice.store"), &key(1), "alice-device").unwrap();
        let bob = SignalEngine::open(&dir.file("bob.store"), &key(2), "bob-device").unwrap();

        alice.pin_identity("bob-device", &bob.identity_public_key()).unwrap();
        bob.pin_identity("alice-device", &alice.identity_public_key()).unwrap();
        let bundle = bob.create_pre_key_bundle().unwrap();
        alice.start_session("bob-device", &bundle).unwrap();
        (alice, bob)
    }

    #[test]
    fn two_way_conversation() {
        let dir = TempDir::new("conv");
        let (alice, bob) = paired(&dir);

        let first = alice.encrypt("bob-device", b"Salut Bob").unwrap();
        assert_eq!(first.message_type, 3, "first message is a PreKey message");
        assert_eq!(bob.decrypt("alice-device", first.message_type, &first.body).unwrap(), b"Salut Bob");

        for i in 0..10 {
            let text = format!("bob {i}");
            let m = bob.encrypt("alice-device", text.as_bytes()).unwrap();
            assert_eq!(alice.decrypt("bob-device", m.message_type, &m.body).unwrap(), text.as_bytes());
            let text = format!("alice {i}");
            let m = alice.encrypt("bob-device", text.as_bytes()).unwrap();
            assert_eq!(bob.decrypt("alice-device", m.message_type, &m.body).unwrap(), text.as_bytes());
        }
    }

    #[test]
    fn sessions_survive_reopening_the_store() {
        let dir = TempDir::new("reopen");
        let (alice, bob) = paired(&dir);
        let m = alice.encrypt("bob-device", b"one").unwrap();
        bob.decrypt("alice-device", m.message_type, &m.body).unwrap();
        drop(alice);
        drop(bob);

        let alice = SignalEngine::open(&dir.file("alice.store"), &key(1), "alice-device").unwrap();
        let bob = SignalEngine::open(&dir.file("bob.store"), &key(2), "bob-device").unwrap();
        let m = bob.encrypt("alice-device", b"after restart").unwrap();
        assert_eq!(alice.decrypt("bob-device", m.message_type, &m.body).unwrap(), b"after restart");
    }

    #[test]
    fn wrong_storage_key_cannot_open_store() {
        let dir = TempDir::new("key");
        let path = dir.file("s.store");
        SignalEngine::open(&path, &key(7), "d").unwrap();
        assert!(SignalEngine::open(&path, &key(8), "d").is_err());
    }

    #[test]
    fn store_file_contains_no_plaintext_keys() {
        let dir = TempDir::new("plain");
        let path = dir.file("s.store");
        let engine = SignalEngine::open(&path, &key(9), "d").unwrap();
        let raw = fs::read(&path).unwrap();
        let identity = engine.identity_public_key();
        assert!(!raw.windows(identity.len()).any(|w| w == identity.as_slice()));
        assert!(!String::from_utf8_lossy(&raw).contains("identity_key_pair"));
    }

    #[test]
    fn bundle_from_unpinned_identity_is_refused() {
        let dir = TempDir::new("unpinned");
        let alice = SignalEngine::open(&dir.file("a"), &key(1), "alice-device").unwrap();
        let bob = SignalEngine::open(&dir.file("b"), &key(2), "bob-device").unwrap();
        let bundle = bob.create_pre_key_bundle().unwrap();
        assert!(matches!(
            alice.start_session("bob-device", &bundle),
            Err(EngineError::UntrustedIdentity)
        ));
    }

    #[test]
    fn bundle_with_substituted_identity_is_refused() {
        let dir = TempDir::new("subst");
        let alice = SignalEngine::open(&dir.file("a"), &key(1), "alice-device").unwrap();
        let bob = SignalEngine::open(&dir.file("b"), &key(2), "bob-device").unwrap();
        let mallory = SignalEngine::open(&dir.file("m"), &key(3), "mallory").unwrap();
        // Alice scanned Bob's QR, but the bundle comes from Mallory.
        alice.pin_identity("bob-device", &bob.identity_public_key()).unwrap();
        let forged = mallory.create_pre_key_bundle().unwrap();
        assert!(alice.start_session("bob-device", &forged).is_err());
    }

    #[test]
    fn pinned_identity_cannot_be_replaced() {
        let dir = TempDir::new("pin");
        let alice = SignalEngine::open(&dir.file("a"), &key(1), "alice-device").unwrap();
        let bob = SignalEngine::open(&dir.file("b"), &key(2), "bob-device").unwrap();
        let other = SignalEngine::open(&dir.file("o"), &key(3), "other").unwrap();
        alice.pin_identity("bob-device", &bob.identity_public_key()).unwrap();
        assert!(alice.pin_identity("bob-device", &other.identity_public_key()).is_err());
    }

    #[test]
    fn tampered_and_replayed_messages_are_rejected() {
        let dir = TempDir::new("tamper");
        let (alice, bob) = paired(&dir);
        let first = alice.encrypt("bob-device", b"hello").unwrap();
        bob.decrypt("alice-device", first.message_type, &first.body).unwrap();

        let m = bob.encrypt("alice-device", b"genuine").unwrap();
        let mut tampered = m.body.clone();
        let last = tampered.len() - 1;
        tampered[last] ^= 1;
        assert!(alice.decrypt("bob-device", m.message_type, &tampered).is_err());
        assert_eq!(alice.decrypt("bob-device", m.message_type, &m.body).unwrap(), b"genuine");
        assert!(alice.decrypt("bob-device", m.message_type, &m.body).is_err(), "replay");
    }

    #[test]
    fn replayed_first_message_is_rejected() {
        let dir = TempDir::new("replay1");
        let (alice, bob) = paired(&dir);
        let first = alice.encrypt("bob-device", b"hello").unwrap();
        bob.decrypt("alice-device", first.message_type, &first.body).unwrap();
        assert!(bob.decrypt("alice-device", first.message_type, &first.body).is_err());
    }

    #[test]
    fn third_party_cannot_decrypt() {
        let dir = TempDir::new("third");
        let (alice, _bob) = paired(&dir);
        let carol = SignalEngine::open(&dir.file("c"), &key(4), "carol").unwrap();
        carol.pin_identity("alice-device", &alice.identity_public_key()).unwrap();
        let m = alice.encrypt("bob-device", b"for bob").unwrap();
        assert!(carol.decrypt("alice-device", m.message_type, &m.body).is_err());
    }
}
