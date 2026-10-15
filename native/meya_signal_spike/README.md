# MEYA Triple Ratchet spike

Feasibility test for using Signal's `libsignal-protocol` (tag `v0.105.0`)
as MEYA's one-to-one messaging protocol: PQXDH session setup plus the
Triple Ratchet (Double Ratchet + Sparse Post-Quantum Ratchet, SPQR).

Nothing in the MEYA app depends on this crate yet.

## Requirements

- Rust 1.93.1 (installed automatically by rustup from `rust-toolchain.toml`)
- `protoc` (Protocol Buffers compiler) on `PATH`, needed by libsignal's
  build scripts. On Windows: `winget install --id Google.Protobuf`
- Git (libsignal is fetched from GitHub)

## Run

```bash
cd native/meya_signal_spike
cargo test -- --nocapture
```

## What the tests prove

| Test | Property |
|---|---|
| `pqxdh_session_and_triple_ratchet_round_trip` | Two identities set up a PQXDH session and exchange messages both ways; every message carries SPQR data |
| `tampered_ciphertext_is_rejected` | AEAD/MAC failure is an error, never plaintext; the session keeps working |
| `replayed_message_is_rejected` | A message cannot be decrypted twice |
| `out_of_order_messages_decrypt` | Delayed messages still decrypt once |
| `third_party_cannot_decrypt` | Only the intended recipient can decrypt |
| `forged_signed_prekey_is_rejected` | A bundle whose signature does not match the identity is refused |
| `changed_identity_key_is_not_trusted` | A replaced identity key is refused, not silently accepted |
| `session_survives_serialization` | Session state can be saved and restored (app restart) |
