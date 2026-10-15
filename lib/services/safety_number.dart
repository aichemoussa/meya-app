import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import '../database/meya_database.dart';
import 'meya_secure_storage.dart';

/// A 60-digit code that two people compare (or scan) to confirm that their
/// end-to-end encryption is with each other and nobody in between.
///
/// It is derived only from the two identity keys and MEYA IDs, the same way
/// Signal computes safety numbers: each side's key is hashed 5200 times with
/// SHA-512 into 30 digits, and the two halves are put in a fixed order so
/// both phones show the same number.
class SafetyNumber {
  static const _iterations = 5200;
  static const _version = [0, 0];
  static const qrPrefix = 'MEYA-SAFETY:1:';

  /// The 60 digits, or throws if a key is not valid base64.
  static String compute({
    required String localKeyBase64,
    required String localId,
    required String remoteKeyBase64,
    required String remoteId,
  }) {
    final local = _half(base64Decode(localKeyBase64), localId);
    final remote = _half(base64Decode(remoteKeyBase64), remoteId);
    return local.compareTo(remote) <= 0 ? '$local$remote' : '$remote$local';
  }

  static String _half(Uint8List key, String id) {
    var hash = sha512.convert([..._version, ...key, ...utf8.encode(id)]).bytes;
    for (var i = 1; i < _iterations; i++) {
      hash = sha512.convert([...hash, ...key]).bytes;
    }
    final digits = StringBuffer();
    for (var chunk = 0; chunk < 6; chunk++) {
      var value = 0;
      for (var b = 0; b < 5; b++) {
        value = value * 256 + hash[chunk * 5 + b];
      }
      digits.write((value % 100000).toString().padLeft(5, '0'));
    }
    return digits.toString();
  }

  /// The number in 12 groups of five digits, for display and reading aloud.
  static List<String> groups(String number) => [
        for (var i = 0; i < number.length; i += 5) number.substring(i, i + 5),
      ];

  static String qrData(String number) => '$qrPrefix$number';

  /// The number inside a scanned safety-number QR code, or null.
  static String? fromQr(String data) {
    if (!data.startsWith(qrPrefix)) return null;
    final number = data.substring(qrPrefix.length);
    return RegExp(r'^\d{60}$').hasMatch(number) ? number : null;
  }

  // ------------------------------------------------------ verified marks

  static String _storageKey(Contact contact) => 'meya_verified_${contact.contactId}';

  static String _fingerprint(Contact contact) =>
      sha256.convert(utf8.encode(contact.identityPublicKey)).toString();

  /// True when this contact was verified and still has the same key. A new
  /// key (reinstall, new phone, or an attack) clears the mark automatically.
  static Future<bool> isVerified(Contact contact) async =>
      await meyaSecureStorage.read(key: _storageKey(contact)) == _fingerprint(contact);

  static Future<void> setVerified(Contact contact, bool verified) => verified
      ? meyaSecureStorage.write(key: _storageKey(contact), value: _fingerprint(contact))
      : meyaSecureStorage.delete(key: _storageKey(contact));
}
