import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:sqlite3/sqlite3.dart';

import '../services/meya_secure_storage.dart';

/// Encryption of the whole MEYA database (SQLite3MultipleCiphers,
/// ChaCha20-Poly1305 by default) with a random 256-bit key that exists only
/// in this phone's secure storage.
///
/// Message text was already sealed separately; this also protects contact
/// names, timestamps, reactions and chat settings if someone copies the
/// app's files from an unlocked or rooted phone.
class MeyaDatabaseEncryption {
  static const _storageKey = 'meya_database_key_v1';
  static final _hex = RegExp(r'^[0-9a-f]{64}$');

  /// The database key as 64 hex characters, created on first use.
  static Future<String> loadKey() async {
    final stored = await meyaSecureStorage.read(key: _storageKey);
    if (stored != null && _hex.hasMatch(stored)) return stored;
    final random = Random.secure();
    final key = List.generate(32, (_) => random.nextInt(256))
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
    await meyaSecureStorage.write(key: _storageKey, value: key);
    return key;
  }

  /// The existing database key, or null. Never creates one (for code that
  /// only reads, such as the push handler).
  static Future<String?> readExistingKey() async {
    final stored = await meyaSecureStorage.read(key: _storageKey);
    return stored != null && _hex.hasMatch(stored) ? stored : null;
  }

  static Future<void> forgetKey() => meyaSecureStorage.delete(key: _storageKey);

  /// SQL that unlocks an encrypted connection. Must run before anything else.
  static String keyPragma(String hexKey) {
    if (!_hex.hasMatch(hexKey)) throw ArgumentError('Invalid database key');
    return "PRAGMA hexkey = '$hexKey';";
  }

  /// Prepares [file] for opening with [hexKey]:
  /// - a database from before encryption is encrypted in place, keeping
  ///   all its data;
  /// - a database that this key cannot open (its key was lost, e.g. after
  ///   a secure-storage reset) is moved aside so MEYA can start again.
  static void prepare(File file, String hexKey) {
    if (!file.existsSync()) return;

    if (_isPlaintext(file)) {
      final database = sqlite3.open(file.path);
      try {
        // Re-keying needs a rollback journal, not WAL.
        database.execute('PRAGMA journal_mode = DELETE;');
        database.execute("PRAGMA hexrekey = '$hexKey';");
      } finally {
        database.close();
      }
      debugPrint('MEYA database: encrypted the existing database.');
    }

    if (!_opensWith(file, hexKey)) {
      final aside = File('${file.path}.unreadable-${DateTime.now().millisecondsSinceEpoch}');
      file.renameSync(aside.path);
      debugPrint('MEYA database: could not open with this key; moved aside.');
    }
  }

  static bool _isPlaintext(File file) {
    final database = sqlite3.open(file.path);
    try {
      database.select('SELECT count(*) FROM sqlite_master;');
      return true;
    } on SqliteException {
      return false;
    } finally {
      database.close();
    }
  }

  static bool _opensWith(File file, String hexKey) {
    final database = sqlite3.open(file.path);
    try {
      database.execute(keyPragma(hexKey));
      database.select('SELECT count(*) FROM sqlite_master;');
      return true;
    } on SqliteException {
      return false;
    } finally {
      database.close();
    }
  }
}
