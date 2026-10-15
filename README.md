# meya

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Releasing for Android

Test versions are published as GitHub releases in
[primaelite/meya-website](https://github.com/primaelite/meya-website/releases).
The "Download for Android" button on https://meya-app.pages.dev/ always
serves the latest one.

Once, on a new computer:

1. `.\tool\create-signing-key.ps1` creates the signing key. Back up
   `%USERPROFILE%\.meya\meya-release.jks` and its password. Without them no
   further updates are possible.
2. `gh auth login` signs the GitHub CLI in.

For every update:

1. Raise `version:` in `pubspec.yaml`. The number after `+` must go up.
2. `.\tool\release-android.ps1 -Notes "What changed"`
