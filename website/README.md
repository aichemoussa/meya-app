# MEYA

**Private messaging for the people closest to you.**

MEYA is a private messenger for families and close friends. You add people only
in person, by scanning their QR code. There is no phone number, no email
address, no address-book upload and no public directory. Everything you share
is encrypted on your phone before it leaves, and only the people in the
conversation can read it.

**Website:** https://meya-app.pages.dev/

> MEYA is in testing and under active development. Features, availability and
> this document may change.

---

## What MEYA does today

| Area | What works |
|---|---|
| **Connecting** | In-person pairing with a QR code; a safety-number screen to verify a contact's encryption; a warning if a contact's key ever changes |
| **Messages** | Text, voice messages, photos, videos (recorded in the app, with preview thumbnails) and files up to 100 MB |
| **Conversations** | Replies, emoji reactions, forwarding, pinning, favourites, editing, delete for me or for everyone, search, mute, archive, unread counts |
| **Delivery** | Sent, delivered and read ticks (read receipts can be switched off); messages written offline are sent when you reconnect, and never arrive twice |
| **Calls** | Voice calls, and calls planned in a shared calendar with a Join button. Video calls are in testing |
| **Status and profile** | Profile, About and status updates shared only with the people you choose; statuses expire on their own |
| **Safety** | Block and report |
| **Accessibility and language** | Light, dark and high-contrast themes, adjustable text size, reduced motion, screen-reader labels, 20 languages including right-to-left scripts |

Not available yet: groups, push notifications while the app is closed, and
iPhone builds. These are planned, and will be listed here when they are ready.

## Privacy and security

- **End-to-end encrypted.** Messages, voice messages, media, statuses, profiles,
  calendar invitations and calls are encrypted on your phone and opened only on
  the recipient's phone. MEYA's servers cannot read them.
- **Proven building blocks.** MEYA does not invent its own cryptography. It is
  built on the open-source [libsignal](https://github.com/signalapp/libsignal)
  library from the Signal project, and on the encryption built into WebRTC for
  calls. MEYA is not affiliated with or endorsed by Signal.
- **Encrypted on the phone.** The app's database, messages and media are
  encrypted with keys kept in the phone's secure key storage, and MEYA's data is
  left out of cloud backups.
- **What the servers see.** To deliver messages, the hosted relay sees a random
  device ID for each phone, which device sent a sealed envelope to which and
  when, its size, and the network address the phone connects from. It never sees
  content, and envelopes are deleted once delivered. When a call cannot connect
  directly, an encrypted call can pass through a relay that sees network
  addresses but not the call.
- **No tracking.** No advertising, no analytics and no tracking libraries, in the
  app or on the website.

Read the full [privacy policy](https://meya-app.pages.dev/privacy.html) and
[terms of use](https://meya-app.pages.dev/terms.html).

### Reporting a security problem

Please report security concerns **privately**, not as a public issue. Use the
**Security** tab of the
[source repository](https://github.com/primaelite/meya-app/security)
(**Report a vulnerability**). We will not take action against people who
report in good faith and give us reasonable time to fix the problem. See
[SECURITY.md](https://github.com/primaelite/meya-app/blob/main/SECURITY.md).

## Trying MEYA

Android test builds are published under this repository's **Releases**.
Download the latest `.apk` and install it on an Android phone. Test builds may
contain bugs and may change or stop working without notice. Please do not rely
on them for anything important yet. Each release links to the exact source code
it was built from.

## Source code

MEYA's source code is public, under the AGPL-3.0-only licence:

**https://github.com/primaelite/meya-app**

It contains the Flutter app, the Rust cryptographic core, the relay and the
back-end, with build instructions. MEYA has not yet had an independent security
audit.

## About this repository

This repository hosts MEYA's public information: this README and the Android
downloads under **Releases**. The application itself is in the
[source repository](https://github.com/primaelite/meya-app).

MEYA's website is plain HTML and CSS with no build step, no cookies and no
third-party requests, served from Cloudflare Pages at
https://meya-app.pages.dev/. The images on the website are AI-generated
illustrations. They do not show real users.

## Licence and ownership

MEYA is free software under the **GNU Affero General Public License, version 3
only (AGPL-3.0-only)**. The licence text and the corresponding source code are
in the [source repository](https://github.com/primaelite/meya-app). MEYA is
built on Signal's libsignal, which uses the same licence.

MEYA uses other third-party components under their own licences, listed in the
[NOTICE](https://github.com/primaelite/meya-app/blob/main/NOTICE) file and in
the app under **Settings → About MEYA → Open-source licences**. The ringtones
and notification sounds are public-domain (CC0) recordings from
[BigSoundBank](https://bigsoundbank.com).

Copyright © 2026 **PRIMA ELITE FZ-LLC**.

"MEYA" and the MEYA logo are names and marks of PRIMA ELITE FZ-LLC. A licence
to the source code does not grant rights to the name or logo, and use of the
name or logo does not grant any licence to the source code.

## Company

PRIMA ELITE FZ-LLC
Ras Al Khaimah Economic Zone (RAKEZ), United Arab Emirates
