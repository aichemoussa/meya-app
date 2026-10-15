# Contributing to MEYA

Thank you for your interest in MEYA. It is a privacy tool, so we review changes
carefully, especially anything touching encryption, keys, storage or the
relay.

## Before you start

- For anything larger than a small fix, open an issue first so we can agree on
  the approach.
- **Security problems:** do not open an issue. Follow [SECURITY.md](SECURITY.md).
- Do not add analytics, trackers, advertising, or any service that sends user
  data to a third party. MEYA is built not to.
- Do not invent cryptography. Use the existing libsignal-based core.

## Licence of your contribution

MEYA is licensed under the **GNU Affero General Public License, version 3
only (AGPL-3.0-only)**. By contributing you confirm that:

1. you wrote the contribution, or have the right to submit it under the
   AGPL-3.0-only licence, and
2. you agree it is licensed under AGPL-3.0-only.

Sign off every commit with the
[Developer Certificate of Origin](https://developercertificate.org/):

```bash
git commit -s -m "Your message"
```

That adds a `Signed-off-by: Your Name <you@example.com>` line. We may ask for a
separate contributor agreement before accepting larger contributions.

## Checks every change must pass

```bash
flutter analyze
flutter test
```

If you change the Rust code, also run `cargo test` in the folder you changed
(`native/meya_crypto`, `native/meya_signal_spike` or `relay`).

## Text and translations

All text the person sees is in English in the code, and translated into 20
languages by `tool/translations/generate.py`. When you add or change text, add
it to every language file in `tool/translations/` (the English file is the
key) and run the script. `flutter test` checks that every language has the
same strings and keeps every placeholder such as `{0}`.

## Accessibility

Every control needs a text label for screen readers, text must keep strong
contrast in light, dark and high-contrast themes, and layouts must work with
large text and right-to-left languages.

## Name and logo

Contributions do not grant any right to the MEYA name or logo. See
[TRADEMARKS.md](TRADEMARKS.md).
