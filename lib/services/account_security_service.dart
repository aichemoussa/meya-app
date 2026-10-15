import 'dart:convert';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import 'meya_secure_storage.dart';

/// The outcome of checking a passcode or a recovery code.
class SecurityCheck {
  /// True when the code was right.
  final bool ok;

  /// Not null when the check was refused because of too many wrong tries.
  /// Nothing was compared while locked, so there is no way to probe.
  final Duration? lockedFor;

  const SecurityCheck._(this.ok, this.lockedFor);

  static const accepted = SecurityCheck._(true, null);
  static const wrong = SecurityCheck._(false, null);
  static SecurityCheck locked(Duration remaining) =>
      SecurityCheck._(false, remaining);

  bool get isLocked => lockedFor != null;
}

/// The MEYA passcode, the recovery code and the app lock.
///
/// - The passcode is never stored. Only a salted PBKDF2-HMAC-SHA256 hash is,
///   in the phone's secure key storage.
/// - Wrong tries add growing waiting times (see [delayAfter]); they survive
///   restarts and are checked before anything is compared.
/// - The recovery code is a random 120-bit code shown once at set-up. It is the
///   only way to reset a forgotten passcode without erasing the account,
///   because MEYA has no email address or phone number to send a reset to.
class AccountSecurityService {
  static const _storage = meyaSecureStorage;

  /// Used before hashing existed (plain text). Replaced on the next unlock.
  static const _legacyPasscodeKey = 'meya_account_passcode';
  static const _passcodeKey = 'meya_passcode_v2';
  static const _recoveryKey = 'meya_recovery_v1';
  static const _passcodeLockKey = 'meya_lock_passcode';
  static const _recoveryLockKey = 'meya_lock_recovery';
  static const _appLockKey = 'meya_app_lock';

  /// PBKDF2 rounds. Lowered by tests only.
  static int iterations = 100000;

  /// Hash on a background isolate so the screen does not freeze. Tests turn
  /// this off.
  static bool useIsolate = true;

  /// The clock; tests replace it.
  static DateTime Function() now = DateTime.now;

  /// How long the app lock waits after the person leaves MEYA.
  static const appLockGrace = Duration(seconds: 30);

  /// Wrong tries allowed before a waiting time starts.
  static const freeTries = 4;

  /// The waiting time after the given number of wrong tries in a row.
  static Duration delayAfter(int failures) {
    if (failures <= freeTries) return Duration.zero;
    return switch (failures) {
      5 => const Duration(seconds: 30),
      6 => const Duration(minutes: 1),
      7 => const Duration(minutes: 5),
      8 => const Duration(minutes: 15),
      _ => const Duration(hours: 1),
    };
  }

  // -------------------------------------------------------------- passcode

  static Future<void> savePasscode(String passcode) async {
    await _storage.write(key: _passcodeKey, value: await _newHash(passcode));
    await _storage.delete(key: _legacyPasscodeKey);
    await _storage.delete(key: _passcodeLockKey);
  }

  static Future<bool> hasPasscode() async {
    final hash = await _storage.read(key: _passcodeKey);
    if (hash != null && hash.isNotEmpty) return true;
    final legacy = await _storage.read(key: _legacyPasscodeKey);
    return legacy != null && legacy.isNotEmpty;
  }

  /// Checks [passcode]. Counts wrong tries and refuses while locked.
  static Future<SecurityCheck> checkPasscode(String passcode) async {
    final locked = await lockRemaining();
    if (locked > Duration.zero) return SecurityCheck.locked(locked);

    var valid = false;
    final stored = await _storage.read(key: _passcodeKey);
    if (stored != null && stored.isNotEmpty) {
      valid = await _matches(passcode, stored);
    } else {
      // An account made before passcodes were hashed: compare, then upgrade.
      final legacy = await _storage.read(key: _legacyPasscodeKey);
      if (legacy != null && legacy.isNotEmpty && _sameText(legacy, passcode)) {
        valid = true;
        await savePasscode(passcode);
      }
    }
    return _record(_passcodeLockKey, valid);
  }

  static Future<void> clearPasscode() async {
    await _storage.delete(key: _passcodeKey);
    await _storage.delete(key: _legacyPasscodeKey);
    await _storage.delete(key: _passcodeLockKey);
  }

  /// How long until the passcode can be tried again (zero if it can be now).
  static Future<Duration> lockRemaining() => _remaining(_passcodeLockKey);

  // --------------------------------------------------------- recovery code

  /// Crockford base32: no I, L, O or U, so a code copied from paper is hard
  /// to misread. 24 characters carry 120 bits.
  static const _alphabet = '0123456789ABCDEFGHJKMNPQRSTVWXYZ';
  static const _recoveryLength = 24;

  /// Makes a new recovery code, keeps only its hash, and returns the code to
  /// show once. Any earlier code stops working.
  static Future<String> createRecoveryCode() async {
    final random = Random.secure();
    final raw = List.generate(
      _recoveryLength,
      (_) => _alphabet[random.nextInt(_alphabet.length)],
    ).join();
    await _storage.write(key: _recoveryKey, value: await _newHash(raw));
    await _storage.delete(key: _recoveryLockKey);
    return formatRecoveryCode(raw);
  }

  static Future<bool> hasRecoveryCode() async {
    final hash = await _storage.read(key: _recoveryKey);
    return hash != null && hash.isNotEmpty;
  }

  /// Checks a typed recovery code. Counts wrong tries separately from the
  /// passcode and refuses while locked.
  static Future<SecurityCheck> checkRecoveryCode(String input) async {
    final locked = await _remaining(_recoveryLockKey);
    if (locked > Duration.zero) return SecurityCheck.locked(locked);

    final stored = await _storage.read(key: _recoveryKey);
    final valid = stored != null &&
        stored.isNotEmpty &&
        await _matches(normalizeRecoveryCode(input), stored);
    return _record(_recoveryLockKey, valid);
  }

  static Future<Duration> recoveryLockRemaining() =>
      _remaining(_recoveryLockKey);

  /// Upper case, no spaces or dashes, and the look-alikes the code never uses
  /// read as the digits they resemble (O as 0, I and L as 1).
  static String normalizeRecoveryCode(String input) => input
      .toUpperCase()
      .replaceAll(RegExp(r'[\s\-]'), '')
      .replaceAll('O', '0')
      .replaceAll('I', '1')
      .replaceAll('L', '1');

  /// XXXX-XXXX-XXXX-XXXX-XXXX-XXXX
  static String formatRecoveryCode(String raw) => [
        for (var i = 0; i < raw.length; i += 4) raw.substring(i, i + 4),
      ].join('-');

  // -------------------------------------------------------------- app lock

  static Future<bool> isAppLockEnabled() async =>
      await _storage.read(key: _appLockKey) == '1';

  static Future<void> setAppLockEnabled(bool enabled) =>
      _storage.write(key: _appLockKey, value: enabled ? '1' : '0');

  // ---------------------------------------------------------------- inside

  static Future<SecurityCheck> _record(String lockKey, bool valid) async {
    if (valid) {
      await _storage.delete(key: lockKey);
      return SecurityCheck.accepted;
    }
    final state = await _readLock(lockKey);
    final failures = state.failures + 1;
    final delay = delayAfter(failures);
    await _storage.write(
      key: lockKey,
      value: jsonEncode({
        'f': failures,
        'u': delay == Duration.zero
            ? 0
            : now().add(delay).millisecondsSinceEpoch,
      }),
    );
    return delay == Duration.zero
        ? SecurityCheck.wrong
        : SecurityCheck.locked(delay);
  }

  static Future<Duration> _remaining(String lockKey) async {
    final until = (await _readLock(lockKey)).until;
    if (until == 0) return Duration.zero;
    final left = DateTime.fromMillisecondsSinceEpoch(until).difference(now());
    // A phone clock set far back must not lock the app for days.
    if (left > const Duration(hours: 1)) return const Duration(hours: 1);
    return left.isNegative ? Duration.zero : left;
  }

  static Future<({int failures, int until})> _readLock(String lockKey) async {
    try {
      final raw = await _storage.read(key: lockKey);
      if (raw == null || raw.isEmpty) return (failures: 0, until: 0);
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return (failures: json['f'] as int, until: json['u'] as int);
    } catch (_) {
      return (failures: 0, until: 0);
    }
  }

  /// "iterations$salt$hash", all text, so the format can change later.
  static Future<String> _newHash(String secret) async {
    final random = Random.secure();
    final salt = Uint8List.fromList(List.generate(16, (_) => random.nextInt(256)));
    final rounds = iterations;
    final hash = await _derive(secret, salt, rounds);
    return '$rounds\$${base64Encode(salt)}\$${base64Encode(hash)}';
  }

  static Future<bool> _matches(String secret, String stored) async {
    final parts = stored.split('\$');
    if (parts.length != 3) return false;
    final rounds = int.tryParse(parts[0]);
    if (rounds == null || rounds < 1) return false;
    try {
      final expected = base64Decode(parts[2]);
      final actual = await _derive(secret, base64Decode(parts[1]), rounds);
      return _sameBytes(expected, actual);
    } catch (_) {
      return false;
    }
  }

  static Future<Uint8List> _derive(String secret, Uint8List salt, int rounds) {
    final password = Uint8List.fromList(utf8.encode(secret));
    if (!useIsolate) return Future.value(pbkdf2(password, salt, rounds));
    return Isolate.run(() => pbkdf2(password, salt, rounds));
  }

  /// PBKDF2 with HMAC-SHA-256, one 32-byte block.
  static Uint8List pbkdf2(Uint8List password, Uint8List salt, int rounds) {
    final hmac = Hmac(sha256, password);
    var u = Uint8List.fromList(
      hmac.convert([...salt, 0, 0, 0, 1]).bytes,
    );
    final result = Uint8List.fromList(u);
    for (var i = 1; i < rounds; i++) {
      u = Uint8List.fromList(hmac.convert(u).bytes);
      for (var j = 0; j < result.length; j++) {
        result[j] ^= u[j];
      }
    }
    return result;
  }

  static bool _sameBytes(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }

  static bool _sameText(String a, String b) =>
      _sameBytes(utf8.encode(a), utf8.encode(b));
}
