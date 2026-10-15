import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// The one secure-storage configuration MEYA uses for keys and secrets.
///
/// On iPhone and Mac, items are readable after the first unlock (so calls
/// and messages can arrive in the background) and are *this device only*:
/// they are never copied into iCloud backups or to a new device. A backup
/// of MEYA's files therefore holds only ciphertext it cannot open.
/// On Android, items are encrypted with a key in the Android Keystore, and
/// MEYA's data is excluded from backups (see AndroidManifest.xml).
const meyaSecureStorage = FlutterSecureStorage(
  iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device),
  mOptions: MacOsOptions(accessibility: KeychainAccessibility.first_unlock_this_device),
);
