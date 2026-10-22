# MEYA

**Private messaging for the people closest to you.**

MEYA is a private, end-to-end encrypted messenger for families and close
friends. You add people only in person, by scanning their QR code: no phone
number, no email address, no address-book upload and no public directory.

This repository is MEYA's application source: the Flutter app, its Rust
cryptographic core, a self-hostable relay and the Supabase back-end. It is
free software under the **GNU Affero General Public License v3.0**
([LICENSE](LICENSE), [NOTICE](NOTICE)).

- **Website:** https://meya-app.pages.dev/
- **Android test builds:** https://github.com/primaelite/meya-website/releases

> MEYA is in testing and under active development. Please do not rely on it
> for anything important yet. It has not had an independent security audit.

## What it does

| Area | What works |
|---|---|
| **Connecting** | In-person QR pairing or a one-time invite link; safety numbers to verify a contact's encryption; a warning if a contact's key changes |
| **Messages** | Text, voice messages, photos, videos (recorded in the app, with preview thumbnails) and files up to 100 MB |
| **Conversations** | Replies, reactions, forwarding, pinning, favourites, editing, delete for everyone, search, mute, archive, unread counts |
| **Delivery** | Sent, delivered and read ticks (read receipts can be switched off); offline queue with retries; no duplicates |
| **Calls** | Voice calls and calls planned in a shared calendar; video calls are in testing |
| **Status and profile** | Profile and status shared only with chosen people; statuses expire |
| **Safety** | Block and report |
| **Accessibility and language** | Light, dark and high-contrast themes, text scaling, reduced motion, screen-reader labels, 20 languages including right-to-left |
| **Notifications** | Messages, invitations, calls, reactions and statuses, with sound and vibration, also when MEYA is closed (an empty wake-up push through Firebase Cloud Messaging) |
| **Groups** | Private groups, each message sent to every member over their own encrypted session |

Not available yet: iPhone builds.

## How it is built

```
lib/                 Flutter app (Dart): screens, services, local database
native/meya_crypto/  Rust cryptographic core on libsignal, called from Dart
                     through flutter_rust_bridge
native/meya_signal_spike/  Tests of the Signal protocol building blocks
supabase/            Back-end: database migration with row-level security,
                     and two Edge Functions (device registration, TURN)
relay/               A self-hostable WebSocket relay (an alternative to Supabase)
website/             The static website
tool/                Release, translation and setup scripts
test/                Flutter tests
```

**Security design, in short**

- Messages, media, statuses, profiles, call invitations and calls are
  end-to-end encrypted. MEYA does not invent new cryptographic algorithms or
  protocols: it uses Signal's open-source
  [libsignal](https://github.com/signalapp/libsignal) for messages, and
  WebRTC's built-in encryption for calls. MEYA's own code around them (key
  storage, pairing, attachments, groups, safety numbers) has not yet had an
  independent security review.
- The relay (Supabase, or the self-hostable relay) only forwards sealed
  envelopes. It sees which device sends to which, when, and the size, but never
  the content. Row-level security lets each phone read only what is addressed
  to it.
- On the phone, the whole database is encrypted, keys are kept in the
  platform's secure storage, and the app is left out of cloud backups.

## Building

You need [Flutter](https://docs.flutter.dev/get-started/install) (Dart SDK
3.13 or newer), the [Rust toolchain](https://rustup.rs),
[`protoc`](https://github.com/protocolbuffers/protobuf/releases) (Protocol
Buffers compiler) and, for Android, the Android SDK. The Rust core is built
automatically by Flutter.

```bash
flutter pub get
flutter analyze
flutter test
```

Run on a device, pointing the app at your own Supabase project (the address and
the **publishable** key are designed to be public; never use a secret key):

```bash
flutter run \
  --dart-define=MEYA_SUPABASE_URL=https://<your-project>.supabase.co \
  --dart-define=MEYA_SUPABASE_KEY=<your publishable key>
```

Optional: `--dart-define=MEYA_REPORT_EMAIL=<address>` sets where the in-app
Report feature sends reports.

### Your own back-end

With the [Supabase CLI](https://supabase.com/docs/guides/cli):

```bash
npx supabase login
npx supabase link --project-ref <your-project-ref>
npx supabase db push
npx supabase functions deploy register-device turn-credentials --no-verify-jwt
```

Turn on **anonymous sign-ins** in your project's authentication settings.
Calls work between phones that can reach each other directly. For calls
across networks that block direct connections, create a TURN key (for example
with Cloudflare Realtime) and store it as the Supabase secrets
`MEYA_TURN_KEY_ID` and `MEYA_TURN_KEY_TOKEN`; `tool/set-turn-secrets.ps1` asks
for them without echoing the token.

### Instead of Supabase: the self-hostable relay

```bash
cd relay
cargo run --release --bin meya-relay
```

Build the app with `--dart-define=MEYA_RELAY_URL=wss://<your relay>/v1/ws`. The
app only accepts encrypted `wss://` addresses, except `ws://127.0.0.1:8787/v1/ws`
in debug builds.

### Tests of the Rust code

```bash
cd native/meya_crypto && cargo test
cd native/meya_signal_spike && cargo test
cd relay && cargo test
```

### Release builds (maintainers)

`tool/release-android.ps1` builds and publishes an Android release. It needs a
signing key and a private `tool/release.config.ps1`
(see `tool/release.config.example.ps1`). It refuses to publish a version whose
source tag is not yet in this repository.

## Contributing and security

- Contributions are welcome. Read [CONTRIBUTING.md](CONTRIBUTING.md).
- **Please report security problems privately**, using this repository's
  **Security** tab (**Report a vulnerability**). See [SECURITY.md](SECURITY.md).

## Licence and ownership

Copyright © 2026 **PRIMA ELITE FZ-LLC**. MEYA is licensed under the GNU Affero
General Public License, version 3 only (AGPL-3.0-only). MEYA is built on
Signal's libsignal, which uses the same licence, and uses other open-source
components listed in [NOTICE](NOTICE) and in the app under
**Settings → About MEYA → Open-source licences**. MEYA is not affiliated with
or endorsed by Signal.

The names **MEYA** and the MEYA logo are trademarks claimed by PRIMA ELITE
FZ-LLC and are not covered by the software licence. See
[TRADEMARKS.md](TRADEMARKS.md).

## Company

PRIMA ELITE FZ-LLC
Ras Al Khaimah Economic Zone (RAKEZ), United Arab Emirates
