//
// Copyright 2026 PRIMA ELITE.
// SPDX-License-Identifier: AGPL-3.0-only
//
// Feasibility tests for MEYA's messaging protocol: PQXDH session setup and
// the Triple Ratchet (Double Ratchet + SPQR), using Signal's maintained
// libsignal-protocol implementation without modification.
//
// The pre-key bundle helper follows libsignal's own test support code
// (rust/protocol/tests/support/mod.rs, AGPL-3.0-only, Signal Messenger LLC).

use std::time::SystemTime;

use futures_util::FutureExt;
use libsignal_protocol::*;
use rand::rngs::OsRng;
use rand::{Rng, TryRngCore as _};

/// In-memory stores complete synchronously; this keeps the tests simple.
fn sync<T>(future: impl std::future::Future<Output = T>) -> T {
    future
        .now_or_never()
        .expect("in-memory store operations complete synchronously")
}

struct Party {
    address: ProtocolAddress,
    identity: IdentityKeyPair,
    registration_id: u32,
    store: InMemSignalProtocolStore,
}

impl Party {
    fn new(name: &str) -> Self {
        let mut csprng = OsRng.unwrap_err();
        let identity = IdentityKeyPair::generate(&mut csprng);
        // Registration IDs fit in 14 bits.
        let registration_id = u32::from(csprng.random::<u16>() & 0x3fff);
        let store = InMemSignalProtocolStore::new(identity, registration_id)
            .expect("store can be created");
        Self {
            address: ProtocolAddress::new(name.to_owned(), DeviceId::new(1).unwrap()),
            identity,
            registration_id,
            store,
        }
    }

    /// Publishes a pre-key bundle (signed EC pre-key, one-time EC pre-key and
    /// signed ML-KEM pre-key) and keeps the private halves in this party's
    /// store, as a real device would.
    fn publish_bundle(&mut self) -> PreKeyBundle {
        let mut csprng = OsRng.unwrap_err();
        let pre_key_pair = KeyPair::generate(&mut csprng);
        let signed_pre_key_pair = KeyPair::generate(&mut csprng);
        let kyber_pre_key_pair = kem::KeyPair::generate(kem::KeyType::Kyber1024, &mut csprng);

        let signed_pre_key_public = signed_pre_key_pair.public_key.serialize();
        let signed_pre_key_signature = self
            .identity
            .private_key()
            .calculate_signature(&signed_pre_key_public, &mut csprng)
            .expect("signing works");

        let kyber_pre_key_public = kyber_pre_key_pair.public_key.serialize();
        let kyber_pre_key_signature = self
            .identity
            .private_key()
            .calculate_signature(&kyber_pre_key_public, &mut csprng)
            .expect("signing works");

        let pre_key_id: u32 = csprng.random();
        let signed_pre_key_id: u32 = csprng.random();
        let kyber_pre_key_id: u32 = csprng.random();

        let bundle = PreKeyBundle::new(
            self.registration_id,
            DeviceId::new(1).unwrap(),
            Some((pre_key_id.into(), pre_key_pair.public_key)),
            signed_pre_key_id.into(),
            signed_pre_key_pair.public_key,
            signed_pre_key_signature.to_vec(),
            kyber_pre_key_id.into(),
            kyber_pre_key_pair.public_key.clone(),
            kyber_pre_key_signature.to_vec(),
            *self.identity.identity_key(),
        )
        .expect("bundle is valid");

        sync(self.store.save_pre_key(
            pre_key_id.into(),
            &PreKeyRecord::new(pre_key_id.into(), &pre_key_pair),
        ))
        .expect("pre-key saved");
        sync(self.store.save_signed_pre_key(
            signed_pre_key_id.into(),
            &SignedPreKeyRecord::new(
                signed_pre_key_id.into(),
                Timestamp::from_epoch_millis(42),
                &signed_pre_key_pair,
                &signed_pre_key_signature,
            ),
        ))
        .expect("signed pre-key saved");
        sync(self.store.save_kyber_pre_key(
            kyber_pre_key_id.into(),
            &KyberPreKeyRecord::new(
                kyber_pre_key_id.into(),
                Timestamp::from_epoch_millis(43),
                &kyber_pre_key_pair,
                &kyber_pre_key_signature,
            ),
        ))
        .expect("kyber pre-key saved");

        bundle
    }

    /// Starts a session with `other` from their published bundle (PQXDH).
    fn start_session(&mut self, other: &ProtocolAddress, bundle: &PreKeyBundle) -> Result<(), SignalProtocolError> {
        let mut csprng = OsRng.unwrap_err();
        sync(process_prekey_bundle(
            other,
            &self.address,
            &mut self.store.session_store,
            &mut self.store.identity_store,
            bundle,
            SystemTime::now(),
            &mut csprng,
        ))
    }

    fn encrypt(&mut self, to: &ProtocolAddress, text: &str) -> CiphertextMessage {
        let mut csprng = OsRng.unwrap_err();
        sync(message_encrypt(
            text.as_bytes(),
            to,
            &self.address,
            &mut self.store.session_store,
            &mut self.store.identity_store,
            SystemTime::now(),
            &mut csprng,
        ))
        .expect("encryption succeeds")
    }

    fn decrypt(
        &mut self,
        from: &ProtocolAddress,
        message: &CiphertextMessage,
    ) -> Result<String, SignalProtocolError> {
        let mut csprng = OsRng.unwrap_err();
        let plaintext = sync(message_decrypt(
            message,
            from,
            &self.address,
            &mut self.store.session_store,
            &mut self.store.identity_store,
            &mut self.store.pre_key_store,
            &self.store.signed_pre_key_store,
            &mut self.store.kyber_pre_key_store,
            &mut csprng,
        ))?;
        Ok(String::from_utf8(plaintext).expect("test messages are UTF-8"))
    }
}

/// Asserts the message carries SPQR (post-quantum ratchet) data, and for the
/// first message, a PQXDH ML-KEM ciphertext.
fn assert_triple_ratchet(message: &CiphertextMessage) {
    match message {
        CiphertextMessage::PreKeySignalMessage(m) => {
            assert!(
                m.kyber_ciphertext().is_some(),
                "PQXDH must include an ML-KEM ciphertext"
            );
            assert!(
                !m.message().pq_ratchet().is_empty(),
                "first message must carry SPQR data"
            );
        }
        CiphertextMessage::SignalMessage(m) => {
            assert!(!m.pq_ratchet().is_empty(), "message must carry SPQR data");
        }
        other => panic!("unexpected message type {:?}", other.message_type()),
    }
}

/// Alice and Bob with an established session (Alice's first message decrypted).
fn established_pair() -> (Party, Party) {
    let mut alice = Party::new("alice");
    let mut bob = Party::new("bob");
    let bundle = bob.publish_bundle();
    alice
        .start_session(&bob.address.clone(), &bundle)
        .expect("PQXDH session setup succeeds");

    let first = alice.encrypt(&bob.address.clone(), "hello");
    assert_eq!(bob.decrypt(&alice.address.clone(), &first).unwrap(), "hello");
    (alice, bob)
}

#[test]
fn pqxdh_session_and_triple_ratchet_round_trip() {
    let mut alice = Party::new("alice");
    let mut bob = Party::new("bob");
    let (a, b) = (alice.address.clone(), bob.address.clone());

    let bundle = bob.publish_bundle();
    alice.start_session(&b, &bundle).expect("PQXDH session setup succeeds");

    let first = alice.encrypt(&b, "Salut Bob");
    assert_eq!(first.message_type(), CiphertextMessageType::PreKey);
    assert_triple_ratchet(&first);
    assert_eq!(bob.decrypt(&a, &first).unwrap(), "Salut Bob");

    // Alternate directions so both the DH ratchet and SPQR advance.
    for round in 0..20 {
        let to_alice = format!("bob to alice {round}");
        let message = bob.encrypt(&a, &to_alice);
        assert_triple_ratchet(&message);
        assert_eq!(alice.decrypt(&b, &message).unwrap(), to_alice);

        let to_bob = format!("alice to bob {round}");
        let message = alice.encrypt(&b, &to_bob);
        assert_triple_ratchet(&message);
        assert_eq!(bob.decrypt(&a, &message).unwrap(), to_bob);
    }
}

#[test]
fn tampered_ciphertext_is_rejected() {
    let (mut alice, mut bob) = established_pair();
    let (a, b) = (alice.address.clone(), bob.address.clone());

    let message = bob.encrypt(&a, "do not modify");
    assert_eq!(message.message_type(), CiphertextMessageType::Whisper);

    // Flip one bit in the trailing MAC: the message still parses, so this
    // checks that authentication itself rejects it.
    let mut bytes = message.serialize().to_vec();
    let last = bytes.len() - 1;
    bytes[last] ^= 0x01;
    let tampered = CiphertextMessage::SignalMessage(
        SignalMessage::try_from(bytes.as_slice()).expect("tampered message still parses"),
    );
    assert!(alice.decrypt(&b, &tampered).is_err(), "tampering must be detected");

    // The genuine message still decrypts: a forgery cannot break the session.
    assert_eq!(alice.decrypt(&b, &message).unwrap(), "do not modify");
}

#[test]
fn replayed_message_is_rejected() {
    let (mut alice, mut bob) = established_pair();
    let (a, b) = (alice.address.clone(), bob.address.clone());

    let message = bob.encrypt(&a, "only once");
    assert_eq!(alice.decrypt(&b, &message).unwrap(), "only once");
    assert!(
        alice.decrypt(&b, &message).is_err(),
        "a replayed message must not decrypt again"
    );
}

#[test]
fn out_of_order_messages_decrypt() {
    let (mut alice, mut bob) = established_pair();
    let (a, b) = (alice.address.clone(), bob.address.clone());

    let m1 = bob.encrypt(&a, "one");
    let m2 = bob.encrypt(&a, "two");
    let m3 = bob.encrypt(&a, "three");

    assert_eq!(alice.decrypt(&b, &m3).unwrap(), "three");
    assert_eq!(alice.decrypt(&b, &m1).unwrap(), "one");
    assert_eq!(alice.decrypt(&b, &m2).unwrap(), "two");
}

#[test]
fn third_party_cannot_decrypt() {
    let mut alice = Party::new("alice");
    let mut bob = Party::new("bob");
    let mut carol = Party::new("carol");
    let (a, b) = (alice.address.clone(), bob.address.clone());

    let bundle = bob.publish_bundle();
    alice.start_session(&b, &bundle).unwrap();
    let message = alice.encrypt(&b, "for Bob only");

    // Carol intercepts the message but has none of Bob's keys.
    let _ = carol.publish_bundle();
    assert!(carol.decrypt(&a, &message).is_err());
    assert_eq!(bob.decrypt(&a, &message).unwrap(), "for Bob only");
}

#[test]
fn forged_signed_prekey_is_rejected() {
    let mut alice = Party::new("alice");
    let mut bob = Party::new("bob");
    let mut mallory = Party::new("mallory");
    let b = bob.address.clone();

    // Mallory's pre-keys and signatures, presented under Bob's identity key.
    let forged_source = mallory.publish_bundle();
    let _ = bob.publish_bundle();
    let forged = PreKeyBundle::new(
        forged_source.registration_id().unwrap(),
        forged_source.device_id().unwrap(),
        forged_source
            .pre_key_id()
            .unwrap()
            .zip(forged_source.pre_key_public().unwrap()),
        forged_source.signed_pre_key_id().unwrap(),
        forged_source.signed_pre_key_public().unwrap(),
        forged_source.signed_pre_key_signature().unwrap().to_vec(),
        forged_source.kyber_pre_key_id().unwrap(),
        forged_source.kyber_pre_key_public().unwrap().clone(),
        forged_source.kyber_pre_key_signature().unwrap().to_vec(),
        *bob.identity.identity_key(),
    )
    .unwrap();

    assert!(alice.start_session(&b, &forged).is_err());
}

#[test]
fn changed_identity_key_is_not_trusted() {
    let (mut alice, _bob) = established_pair();

    // Someone else appears at Bob's address with a different identity key.
    let mut impostor = Party::new("bob");
    let bundle = impostor.publish_bundle();

    let result = alice.start_session(&impostor.address.clone(), &bundle);
    assert!(
        matches!(result, Err(SignalProtocolError::UntrustedIdentity(_))),
        "a changed identity key must be refused, got {result:?}"
    );
}

#[test]
fn session_survives_serialization() {
    let (mut alice, mut bob) = established_pair();
    let (a, b) = (alice.address.clone(), bob.address.clone());

    // Simulate an app restart: save Alice's session and identity, then
    // rebuild her store from the saved bytes only.
    let saved = sync(alice.store.load_session(&b))
        .unwrap()
        .expect("session exists")
        .serialize()
        .unwrap();
    let bob_identity = sync(alice.store.get_identity(&b)).unwrap().unwrap();

    let mut restored = InMemSignalProtocolStore::new(alice.identity, alice.registration_id).unwrap();
    sync(restored.store_session(&b, &SessionRecord::deserialize(&saved).unwrap())).unwrap();
    sync(restored.save_identity(&b, &bob_identity)).unwrap();
    alice.store = restored;

    let message = alice.encrypt(&b, "after restart");
    assert_triple_ratchet(&message);
    assert_eq!(bob.decrypt(&a, &message).unwrap(), "after restart");

    let reply = bob.encrypt(&a, "welcome back");
    assert_eq!(alice.decrypt(&b, &reply).unwrap(), "welcome back");
}
