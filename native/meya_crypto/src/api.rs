use aes_gcm::{
    Aes256Gcm, Key, Nonce,
    aead::{Aead, KeyInit, Payload},
};
use ed25519_dalek::{Signer, SigningKey};
use getrandom::fill as random_fill;
use ml_kem::{
    MlKem768,
    kem::{Decapsulate, Encapsulate, Kem},
};
use x25519_dalek::{PublicKey, StaticSecret};

const ENVELOPE_VERSION: u8 = 1;
const NONCE_LENGTH: usize = 12;
const KEY_LENGTH: usize = 32;
const ED25519_SIGNATURE_LENGTH: usize = 64;

pub fn meya_crypto_ready() -> String {
    "MEYA crypto core ready".to_string()
}

pub fn generate_identity_key_pair() -> (Vec<u8>, Vec<u8>) {
    let mut private_key = [0u8; KEY_LENGTH];
    random_fill(&mut private_key).expect("Secure random generation failed");

    let secret = StaticSecret::from(private_key);
    let public = PublicKey::from(&secret);

    (secret.to_bytes().to_vec(), public.as_bytes().to_vec())
}

pub fn identity_public_key(private_key: Vec<u8>) -> Result<Vec<u8>, String> {
    if private_key.len() != KEY_LENGTH {
        return Err("Identity private key must be exactly 32 bytes".to_string());
    }

    let private_key: [u8; KEY_LENGTH] = private_key
        .try_into()
        .map_err(|_| "Identity private key must be exactly 32 bytes".to_string())?;

    let secret = StaticSecret::from(private_key);
    let public = PublicKey::from(&secret);

    Ok(public.as_bytes().to_vec())
}

/// Generates a device-specific Ed25519 key pair for relay authentication.
///
/// This key is intentionally separate from the X25519 identity key used for
/// key agreement. Reusing an X25519 key as a signing key would be unsafe.
pub fn generate_device_signing_key_pair() -> (Vec<u8>, Vec<u8>) {
    let mut private_key = [0u8; KEY_LENGTH];
    random_fill(&mut private_key).expect("Secure random generation failed");

    let signing_key = SigningKey::from_bytes(&private_key);

    (
        signing_key.to_bytes().to_vec(),
        signing_key.verifying_key().to_bytes().to_vec(),
    )
}

/// Signs a domain-separated relay challenge using a device's Ed25519 key.
pub fn sign_device_authentication_payload(
    private_key: Vec<u8>,
    payload: Vec<u8>,
) -> Result<Vec<u8>, String> {
    if private_key.len() != KEY_LENGTH {
        return Err("Device signing private key must be exactly 32 bytes".to_string());
    }

    if payload.is_empty() {
        return Err("Device authentication payload cannot be empty".to_string());
    }

    let private_key: [u8; KEY_LENGTH] = private_key
        .try_into()
        .map_err(|_| "Device signing private key must be exactly 32 bytes".to_string())?;

    let signing_key = SigningKey::from_bytes(&private_key);
    let signature = signing_key.sign(&payload);
    let signature_bytes = signature.to_bytes().to_vec();

    debug_assert_eq!(signature_bytes.len(), ED25519_SIGNATURE_LENGTH);

    Ok(signature_bytes)
}

pub fn encrypt_message(
    session_key: Vec<u8>,
    plaintext: Vec<u8>,
    aad: Vec<u8>,
) -> Result<Vec<u8>, String> {
    if session_key.len() != KEY_LENGTH {
        return Err("Session key must be exactly 32 bytes".to_string());
    }

    let key = Key::<Aes256Gcm>::try_from(session_key.as_slice())
        .map_err(|_| "Session key must be exactly 32 bytes".to_string())?;

    let cipher = Aes256Gcm::new(&key);

    let mut nonce_bytes = [0u8; NONCE_LENGTH];
    random_fill(&mut nonce_bytes).map_err(|error| format!("Failed to generate nonce: {error}"))?;

    let nonce = Nonce::try_from(nonce_bytes.as_slice())
        .map_err(|_| "Nonce must be exactly 12 bytes".to_string())?;

    let ciphertext = cipher
        .encrypt(
            &nonce,
            Payload {
                msg: plaintext.as_ref(),
                aad: aad.as_ref(),
            },
        )
        .map_err(|_| "Message encryption failed".to_string())?;

    let mut envelope = Vec::with_capacity(1 + NONCE_LENGTH + ciphertext.len());

    envelope.push(ENVELOPE_VERSION);
    envelope.extend_from_slice(&nonce_bytes);
    envelope.extend_from_slice(&ciphertext);

    Ok(envelope)
}

pub fn decrypt_message(
    session_key: Vec<u8>,
    envelope: Vec<u8>,
    aad: Vec<u8>,
) -> Result<Vec<u8>, String> {
    if session_key.len() != KEY_LENGTH {
        return Err("Session key must be exactly 32 bytes".to_string());
    }

    if envelope.len() < 1 + NONCE_LENGTH + 16 {
        return Err("Encrypted message envelope is too short".to_string());
    }

    if envelope[0] != ENVELOPE_VERSION {
        return Err("Unsupported encrypted message version".to_string());
    }

    let key = Key::<Aes256Gcm>::try_from(session_key.as_slice())
        .map_err(|_| "Session key must be exactly 32 bytes".to_string())?;

    let cipher = Aes256Gcm::new(&key);

    let nonce = Nonce::try_from(&envelope[1..1 + NONCE_LENGTH])
        .map_err(|_| "Invalid message nonce".to_string())?;

    let ciphertext = &envelope[1 + NONCE_LENGTH..];

    cipher
        .decrypt(
            &nonce,
            Payload {
                msg: ciphertext,
                aad: aad.as_ref(),
            },
        )
        .map_err(|_| "Message authentication failed".to_string())
}

// ---------------------------------------------------------------------------
// End-to-end encryption (libsignal: PQXDH + Triple Ratchet)
//
// One engine per app process. Private keys and session state stay inside
// Rust; Dart only ever sees public keys, bundles and ciphertext.
// ---------------------------------------------------------------------------

static SIGNAL_ENGINE: std::sync::Mutex<Option<crate::signal_engine::SignalEngine>> =
    std::sync::Mutex::new(None);

fn with_signal_engine<T>(
    action: impl FnOnce(&crate::signal_engine::SignalEngine) -> crate::signal_engine::EngineResult<T>,
) -> Result<T, String> {
    let guard = SIGNAL_ENGINE
        .lock()
        .map_err(|_| "MEYA encryption engine is unavailable".to_string())?;
    let engine = guard
        .as_ref()
        .ok_or_else(|| "MEYA encryption engine is not open".to_string())?;
    action(engine).map_err(|error| error.to_string())
}

/// A message encrypted for one contact.
pub struct SignalCiphertext {
    /// 3 = first message of a session (PreKey), 2 = normal message.
    pub message_type: u8,
    pub body: Vec<u8>,
}

/// Opens (or creates on first run) this device's encrypted protocol store and
/// returns this device's identity public key (33 bytes) for the QR code.
pub fn signal_open(
    store_path: String,
    storage_key: Vec<u8>,
    local_device_id: String,
) -> Result<Vec<u8>, String> {
    let engine =
        crate::signal_engine::SignalEngine::open(&store_path, &storage_key, &local_device_id)
            .map_err(|error| error.to_string())?;
    let identity = engine.identity_public_key();
    let mut guard = SIGNAL_ENGINE
        .lock()
        .map_err(|_| "MEYA encryption engine is unavailable".to_string())?;
    *guard = Some(engine);
    Ok(identity)
}

pub fn signal_close() {
    if let Ok(mut guard) = SIGNAL_ENGINE.lock() {
        *guard = None;
    }
}

pub fn signal_identity_public_key() -> Result<Vec<u8>, String> {
    with_signal_engine(|engine| Ok(engine.identity_public_key()))
}

/// Fresh one-time pre-keys for a contact, as a JSON bundle.
pub fn signal_create_pre_key_bundle() -> Result<String, String> {
    with_signal_engine(|engine| engine.create_pre_key_bundle())
}

/// Trusts `identity_key` for `remote_device_id` (from a scanned QR code or an
/// accepted request). Fails if a different key is already trusted.
pub fn signal_pin_identity(remote_device_id: String, identity_key: Vec<u8>) -> Result<(), String> {
    with_signal_engine(|engine| engine.pin_identity(&remote_device_id, &identity_key))
}

/// Starts a session from the contact's bundle; its identity must match the
/// pinned identity.
pub fn signal_start_session(remote_device_id: String, bundle_json: String) -> Result<(), String> {
    with_signal_engine(|engine| engine.start_session(&remote_device_id, &bundle_json))
}

pub fn signal_has_session(remote_device_id: String) -> Result<bool, String> {
    with_signal_engine(|engine| engine.has_session(&remote_device_id))
}

pub fn signal_encrypt(
    remote_device_id: String,
    plaintext: Vec<u8>,
) -> Result<SignalCiphertext, String> {
    with_signal_engine(|engine| {
        engine
            .encrypt(&remote_device_id, &plaintext)
            .map(|message| SignalCiphertext {
                message_type: message.message_type,
                body: message.body,
            })
    })
}

pub fn signal_decrypt(
    remote_device_id: String,
    message_type: u8,
    body: Vec<u8>,
) -> Result<Vec<u8>, String> {
    with_signal_engine(|engine| engine.decrypt(&remote_device_id, message_type, &body))
}

/// Forgets a contact's pinned identity and session (when removing a contact).
pub fn signal_forget(remote_device_id: String) -> Result<(), String> {
    with_signal_engine(|engine| engine.forget(&remote_device_id))
}

#[cfg(test)]
mod tests {
    use super::*;
    use hkdf::Hkdf;
    use sha2::Sha256;
    use x25519_dalek::{EphemeralSecret, PublicKey};

    #[test]
    fn ml_kem_768_round_trip() {
        let (decapsulation_key, encapsulation_key) = MlKem768::generate_keypair();

        let (ciphertext, sender_shared_secret) = encapsulation_key.encapsulate();

        let receiver_shared_secret = decapsulation_key.decapsulate(&ciphertext);

        assert_eq!(sender_shared_secret, receiver_shared_secret);
    }

    #[test]
    fn x25519_shared_secret_round_trip() {
        let alice_secret = EphemeralSecret::random();
        let alice_public = PublicKey::from(&alice_secret);

        let bob_secret = EphemeralSecret::random();
        let bob_public = PublicKey::from(&bob_secret);

        let alice_shared_secret = alice_secret.diffie_hellman(&bob_public);
        let bob_shared_secret = bob_secret.diffie_hellman(&alice_public);

        assert_eq!(alice_shared_secret.as_bytes(), bob_shared_secret.as_bytes());
    }

    #[test]
    fn identity_key_pair_has_valid_lengths() {
        let (private_key, public_key) = generate_identity_key_pair();

        assert_eq!(private_key.len(), KEY_LENGTH);
        assert_eq!(public_key.len(), KEY_LENGTH);
    }

    #[test]
    fn identity_public_key_matches_generated_pair() {
        let (private_key, public_key) = generate_identity_key_pair();

        let derived_public_key =
            identity_public_key(private_key).expect("Public key derivation should succeed");

        assert_eq!(derived_public_key, public_key);
    }

    #[test]
    fn identity_public_key_rejects_invalid_private_key() {
        let result = identity_public_key(vec![0u8; 31]);

        assert!(result.is_err());
    }

    #[test]
    fn device_signing_key_pair_signs_authentication_payload() {
        use ed25519_dalek::{Signature, Verifier, VerifyingKey};

        let (private_key, public_key) = generate_device_signing_key_pair();
        let payload = b"MEYA relay authentication v1\ndevice\nnonce".to_vec();

        let signature_bytes = sign_device_authentication_payload(private_key, payload.clone())
            .expect("Payload should be signed");

        assert_eq!(signature_bytes.len(), ED25519_SIGNATURE_LENGTH);

        let public_key: [u8; KEY_LENGTH] =
            public_key.try_into().expect("Public key must be 32 bytes");
        let verifying_key =
            VerifyingKey::from_bytes(&public_key).expect("Generated public key must be valid");
        let signature =
            Signature::from_slice(&signature_bytes).expect("Generated signature must be valid");

        verifying_key
            .verify(&payload, &signature)
            .expect("Signature must verify");
    }

    #[test]
    fn device_signing_rejects_invalid_private_key() {
        let result =
            sign_device_authentication_payload(vec![0u8; KEY_LENGTH - 1], b"payload".to_vec());

        assert!(result.is_err());
    }

    #[test]
    fn hkdf_hybrid_key_derivation_is_deterministic() {
        let x25519_secret = [0x11u8; 32];
        let ml_kem_secret = [0x22u8; 32];

        let mut combined_secret = Vec::with_capacity(64);
        combined_secret.extend_from_slice(&x25519_secret);
        combined_secret.extend_from_slice(&ml_kem_secret);

        let hkdf = Hkdf::<Sha256>::new(None, &combined_secret);

        let mut session_key = [0u8; 32];
        hkdf.expand(b"MEYA hybrid session key v1", &mut session_key)
            .expect("HKDF expansion should succeed");

        let hkdf_again = Hkdf::<Sha256>::new(None, &combined_secret);

        let mut session_key_again = [0u8; 32];
        hkdf_again
            .expand(b"MEYA hybrid session key v1", &mut session_key_again)
            .expect("HKDF expansion should succeed");

        assert_eq!(session_key, session_key_again);
    }

    #[test]
    fn real_hybrid_key_agreement_derives_same_session_key() {
        let alice_x25519_secret = EphemeralSecret::random();
        let alice_x25519_public = PublicKey::from(&alice_x25519_secret);

        let bob_x25519_secret = EphemeralSecret::random();
        let bob_x25519_public = PublicKey::from(&bob_x25519_secret);

        let alice_x25519_shared = alice_x25519_secret.diffie_hellman(&bob_x25519_public);

        let bob_x25519_shared = bob_x25519_secret.diffie_hellman(&alice_x25519_public);

        assert_eq!(alice_x25519_shared.as_bytes(), bob_x25519_shared.as_bytes());

        let (ml_kem_decapsulation_key, ml_kem_encapsulation_key) = MlKem768::generate_keypair();

        let (ciphertext, sender_ml_kem_shared) = ml_kem_encapsulation_key.encapsulate();

        let receiver_ml_kem_shared = ml_kem_decapsulation_key.decapsulate(&ciphertext);

        assert_eq!(sender_ml_kem_shared, receiver_ml_kem_shared);

        let mut sender_combined_secret = Vec::with_capacity(64);
        sender_combined_secret.extend_from_slice(alice_x25519_shared.as_bytes());
        sender_combined_secret.extend_from_slice(sender_ml_kem_shared.as_ref());

        let mut receiver_combined_secret = Vec::with_capacity(64);
        receiver_combined_secret.extend_from_slice(bob_x25519_shared.as_bytes());
        receiver_combined_secret.extend_from_slice(receiver_ml_kem_shared.as_ref());

        let sender_hkdf = Hkdf::<Sha256>::new(None, &sender_combined_secret);

        let receiver_hkdf = Hkdf::<Sha256>::new(None, &receiver_combined_secret);

        let mut sender_session_key = [0u8; 32];
        let mut receiver_session_key = [0u8; 32];

        sender_hkdf
            .expand(b"MEYA hybrid session key v1", &mut sender_session_key)
            .expect("Sender HKDF expansion should succeed");

        receiver_hkdf
            .expand(b"MEYA hybrid session key v1", &mut receiver_session_key)
            .expect("Receiver HKDF expansion should succeed");

        assert_eq!(sender_session_key, receiver_session_key);
    }

    #[test]
    fn aes_256_gcm_encrypt_decrypt_round_trip() {
        let session_key = [0x42u8; 32];
        let nonce = [0x24u8; 12];
        let plaintext = b"MEYA private message";

        let key = Key::<Aes256Gcm>::try_from(session_key.as_slice())
            .expect("Session key must be 32 bytes");

        let cipher = Aes256Gcm::new(&key);

        let nonce = Nonce::try_from(nonce.as_slice()).expect("Nonce must be 12 bytes");

        let ciphertext = cipher
            .encrypt(&nonce, plaintext.as_ref())
            .expect("Encryption should succeed");

        let decrypted = cipher
            .decrypt(&nonce, ciphertext.as_ref())
            .expect("Decryption should succeed");

        assert_eq!(decrypted, plaintext);
    }

    #[test]
    fn aes_256_gcm_rejects_tampered_ciphertext() {
        let session_key = [0x42u8; 32];
        let nonce = [0x24u8; 12];
        let plaintext = b"MEYA private message";

        let key = Key::<Aes256Gcm>::try_from(session_key.as_slice())
            .expect("Session key must be 32 bytes");

        let cipher = Aes256Gcm::new(&key);

        let nonce = Nonce::try_from(nonce.as_slice()).expect("Nonce must be 12 bytes");

        let mut ciphertext = cipher
            .encrypt(&nonce, plaintext.as_ref())
            .expect("Encryption should succeed");

        ciphertext[0] ^= 0x01;

        let result = cipher.decrypt(&nonce, ciphertext.as_ref());

        assert!(result.is_err());
    }

    #[test]
    fn encrypted_message_round_trip_with_aad() {
        let session_key = vec![0x42u8; 32];
        let plaintext = b"MEYA private message".to_vec();
        let aad = b"meya-v1|conversation-001|message-001".to_vec();

        let envelope = encrypt_message(session_key.clone(), plaintext.clone(), aad.clone())
            .expect("Message encryption should succeed");

        assert_eq!(envelope[0], ENVELOPE_VERSION);
        assert_eq!(envelope.len(), 1 + NONCE_LENGTH + plaintext.len() + 16);

        let decrypted =
            decrypt_message(session_key, envelope, aad).expect("Message decryption should succeed");

        assert_eq!(decrypted, plaintext);
    }

    #[test]
    fn encrypted_message_uses_a_fresh_nonce() {
        let session_key = vec![0x42u8; 32];
        let plaintext = b"MEYA private message".to_vec();
        let aad = b"meya-v1|conversation-001|message-001".to_vec();

        let first = encrypt_message(session_key.clone(), plaintext.clone(), aad.clone())
            .expect("First encryption should succeed");

        let second =
            encrypt_message(session_key, plaintext, aad).expect("Second encryption should succeed");

        assert_ne!(&first[1..1 + NONCE_LENGTH], &second[1..1 + NONCE_LENGTH]);
        assert_ne!(first, second);
    }

    #[test]
    fn encrypted_message_rejects_tampered_ciphertext() {
        let session_key = vec![0x42u8; 32];
        let plaintext = b"MEYA private message".to_vec();
        let aad = b"meya-v1|conversation-001|message-001".to_vec();

        let mut envelope = encrypt_message(session_key.clone(), plaintext, aad.clone())
            .expect("Message encryption should succeed");

        let ciphertext_start = 1 + NONCE_LENGTH;
        envelope[ciphertext_start] ^= 0x01;

        let result = decrypt_message(session_key, envelope, aad);

        assert!(result.is_err());
    }

    #[test]
    fn encrypted_message_rejects_tampered_aad() {
        let session_key = vec![0x42u8; 32];
        let plaintext = b"MEYA private message".to_vec();
        let aad = b"meya-v1|conversation-001|message-001".to_vec();

        let envelope = encrypt_message(session_key.clone(), plaintext, aad)
            .expect("Message encryption should succeed");

        let tampered_aad = b"meya-v1|conversation-001|message-002".to_vec();

        let result = decrypt_message(session_key, envelope, tampered_aad);

        assert!(result.is_err());
    }

    #[test]
    fn encrypted_message_rejects_wrong_version() {
        let session_key = vec![0x42u8; 32];
        let plaintext = b"MEYA private message".to_vec();
        let aad = b"meya-v1|conversation-001|message-001".to_vec();

        let mut envelope = encrypt_message(session_key.clone(), plaintext, aad.clone())
            .expect("Message encryption should succeed");

        envelope[0] = 99;

        let result = decrypt_message(session_key, envelope, aad);

        assert!(result.is_err());
    }
}
#[cfg(test)]
mod openmls_foundation_tests {
    use super::*;
    use openmls::{
        key_packages::{KeyPackage, KeyPackageIn},
        prelude::{
            BasicCredential, Ciphersuite, CredentialWithKey, OpenMlsProvider, ProtocolVersion,
            tls_codec::{Deserialize, Serialize},
        },
    };
    use openmls_basic_credential::SignatureKeyPair;
    use openmls_rust_crypto::OpenMlsRustCrypto;

    #[test]
    fn mls_key_package_generation_and_validation() {
        let provider = OpenMlsRustCrypto::default();
        let ciphersuite = Ciphersuite::MLS_128_DHKEMX25519_AES128GCM_SHA256_Ed25519;

        let credential = BasicCredential::new(b"MEYA-device".to_vec());

        let signer = SignatureKeyPair::new(ciphersuite.signature_algorithm())
            .expect("MLS signing key generation should succeed");

        signer
            .store(provider.storage())
            .expect("MLS signing key should be stored");

        let credential_with_key = CredentialWithKey {
            credential: credential.into(),
            signature_key: signer.public().into(),
        };

        let key_package = KeyPackage::builder()
            .build(ciphersuite, &provider, &signer, credential_with_key)
            .expect("MLS KeyPackage generation should succeed");

        let serialized = key_package
            .key_package()
            .tls_serialize_detached()
            .expect("MLS KeyPackage serialization should succeed");

        let key_package_in = KeyPackageIn::tls_deserialize(&mut serialized.as_slice())
            .expect("MLS KeyPackage deserialization should succeed");

        key_package_in
            .validate(provider.crypto(), ProtocolVersion::Mls10)
            .expect("Generated MLS KeyPackage should validate");
    }
}
