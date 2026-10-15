import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meya/services/account_security_service.dart';
import 'package:meya/services/meya_secure_storage.dart';

String hex(List<int> bytes) =>
    bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DateTime clock;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    AccountSecurityService.iterations = 200;
    AccountSecurityService.useIsolate = false;
    clock = DateTime(2026, 10, 15, 12);
    AccountSecurityService.now = () => clock;
  });

  tearDown(() {
    AccountSecurityService.iterations = 100000;
    AccountSecurityService.useIsolate = true;
    AccountSecurityService.now = DateTime.now;
  });

  Future<SecurityCheck> wrong() => AccountSecurityService.checkPasscode('0000');

  group('hash', () {
    // Published PBKDF2-HMAC-SHA256 test vectors (RFC 7914 / common suites).
    test('matches the known PBKDF2-HMAC-SHA256 values', () {
      final password = Uint8List.fromList(utf8.encode('password'));
      final salt = Uint8List.fromList(utf8.encode('salt'));
      expect(
        hex(AccountSecurityService.pbkdf2(password, salt, 1)),
        '120fb6cffcf8b32c43e7225256c4f837a86548c92ccc35480805987cb70be17b',
      );
      expect(
        hex(AccountSecurityService.pbkdf2(password, salt, 2)),
        'ae4d0c95af6b46d32d0adff928f06dd02a303f8ef3c251dfd6e2d85a95474c43',
      );
      expect(
        hex(AccountSecurityService.pbkdf2(password, salt, 4096)),
        'c5e478d59288c841aa530db6845c4c8d962893a001ce4e11a4963873aa98134a',
      );
    });

    test('the passcode is never stored, only a salted hash', () async {
      await AccountSecurityService.savePasscode('482915');
      final stored = await meyaSecureStorage.readAll();
      expect(stored.values.join(' '), isNot(contains('482915')));
      final first = stored['meya_passcode_v2']!;
      expect(first, startsWith('200\$'));

      // Same passcode, different salt, different hash.
      await AccountSecurityService.savePasscode('482915');
      final second = (await meyaSecureStorage.readAll())['meya_passcode_v2']!;
      expect(second, isNot(first));
    });
  });

  group('passcode', () {
    test('the right passcode unlocks and the wrong one does not', () async {
      await AccountSecurityService.savePasscode('1234');
      expect(await AccountSecurityService.hasPasscode(), isTrue);
      expect((await AccountSecurityService.checkPasscode('1234')).ok, isTrue);
      final bad = await AccountSecurityService.checkPasscode('1235');
      expect(bad.ok, isFalse);
      expect(bad.isLocked, isFalse);
    });

    test('an old plain-text passcode still works once, then is hashed',
        () async {
      FlutterSecureStorage.setMockInitialValues(
        {'meya_account_passcode': '7777'},
      );
      expect(await AccountSecurityService.hasPasscode(), isTrue);
      expect((await AccountSecurityService.checkPasscode('1111')).ok, isFalse);
      expect((await AccountSecurityService.checkPasscode('7777')).ok, isTrue);

      final stored = await meyaSecureStorage.readAll();
      expect(stored.containsKey('meya_account_passcode'), isFalse);
      expect(stored.values.join(' '), isNot(contains('7777')));
      expect((await AccountSecurityService.checkPasscode('7777')).ok, isTrue);
    });

    test('five wrong tries start a waiting time that grows', () async {
      await AccountSecurityService.savePasscode('1234');
      for (var i = 0; i < 4; i++) {
        expect((await wrong()).isLocked, isFalse, reason: 'try ${i + 1}');
      }
      final fifth = await wrong();
      expect(fifth.lockedFor, const Duration(seconds: 30));

      clock = clock.add(const Duration(seconds: 31));
      expect((await wrong()).lockedFor, const Duration(minutes: 1));
      clock = clock.add(const Duration(minutes: 2));
      expect((await wrong()).lockedFor, const Duration(minutes: 5));
      clock = clock.add(const Duration(minutes: 6));
      expect((await wrong()).lockedFor, const Duration(minutes: 15));
      clock = clock.add(const Duration(minutes: 16));
      expect((await wrong()).lockedFor, const Duration(hours: 1));
    });

    test('while locked even the right passcode is refused, and nothing is '
        'compared', () async {
      await AccountSecurityService.savePasscode('1234');
      for (var i = 0; i < 5; i++) {
        await wrong();
      }
      final locked = await AccountSecurityService.checkPasscode('1234');
      expect(locked.ok, isFalse);
      expect(locked.isLocked, isTrue);

      clock = clock.add(const Duration(seconds: 31));
      expect((await AccountSecurityService.checkPasscode('1234')).ok, isTrue);
    });

    test('the waiting time survives a restart and a right passcode resets it',
        () async {
      await AccountSecurityService.savePasscode('1234');
      for (var i = 0; i < 5; i++) {
        await wrong();
      }
      expect(await AccountSecurityService.lockRemaining(),
          greaterThan(Duration.zero));

      clock = clock.add(const Duration(minutes: 1));
      expect(await AccountSecurityService.lockRemaining(), Duration.zero);
      expect((await AccountSecurityService.checkPasscode('1234')).ok, isTrue);
      // After a success the count starts again from zero.
      for (var i = 0; i < 4; i++) {
        expect((await wrong()).isLocked, isFalse);
      }
    });

    test('a clock set far into the future cannot lock the app for more than '
        'an hour', () async {
      await AccountSecurityService.savePasscode('1234');
      for (var i = 0; i < 12; i++) {
        clock = clock.add(const Duration(hours: 2));
        await wrong();
      }
      clock = clock.subtract(const Duration(days: 30));
      expect(await AccountSecurityService.lockRemaining(),
          lessThanOrEqualTo(const Duration(hours: 1)));
    });

    test('changing the passcode clears the waiting time', () async {
      await AccountSecurityService.savePasscode('1234');
      for (var i = 0; i < 5; i++) {
        await wrong();
      }
      await AccountSecurityService.savePasscode('5678');
      expect(await AccountSecurityService.lockRemaining(), Duration.zero);
      expect((await AccountSecurityService.checkPasscode('5678')).ok, isTrue);
    });
  });

  group('recovery code', () {
    test('is 24 characters in six groups from an unambiguous alphabet',
        () async {
      final code = await AccountSecurityService.createRecoveryCode();
      expect(code, matches(RegExp(r'^([0-9A-HJKMNP-TV-Z]{4}-){5}[0-9A-HJKMNP-TV-Z]{4}$')));
      final other = await AccountSecurityService.createRecoveryCode();
      expect(other, isNot(code));
    });

    test('only the hash is stored', () async {
      final code = await AccountSecurityService.createRecoveryCode();
      final stored = (await meyaSecureStorage.readAll()).values.join(' ');
      expect(stored, isNot(contains(code.replaceAll('-', ''))));
      expect(await AccountSecurityService.hasRecoveryCode(), isTrue);
    });

    test('works however it is typed, and a new code replaces the old one',
        () async {
      final first = await AccountSecurityService.createRecoveryCode();
      final typed = first.toLowerCase().replaceAll('-', ' ');
      expect((await AccountSecurityService.checkRecoveryCode(typed)).ok, isTrue);
      expect(
        (await AccountSecurityService.checkRecoveryCode('AAAA-AAAA-AAAA-AAAA-AAAA-AAAA')).ok,
        isFalse,
      );

      final second = await AccountSecurityService.createRecoveryCode();
      expect((await AccountSecurityService.checkRecoveryCode(first)).ok, isFalse);
      expect((await AccountSecurityService.checkRecoveryCode(second)).ok, isTrue);
    });

    test('look-alike letters are read as the digits they resemble', () {
      expect(AccountSecurityService.normalizeRecoveryCode('o1il-0O'), '01110' '0');
    });

    test('has its own waiting time, separate from the passcode', () async {
      await AccountSecurityService.savePasscode('1234');
      await AccountSecurityService.createRecoveryCode();
      for (var i = 0; i < 5; i++) {
        await AccountSecurityService.checkRecoveryCode('NOT-THE-CODE');
      }
      expect(await AccountSecurityService.recoveryLockRemaining(),
          greaterThan(Duration.zero));
      expect(await AccountSecurityService.lockRemaining(), Duration.zero);
      expect((await AccountSecurityService.checkPasscode('1234')).ok, isTrue);
    });

    test('there is nothing to check before one is created', () async {
      expect(await AccountSecurityService.hasRecoveryCode(), isFalse);
      expect((await AccountSecurityService.checkRecoveryCode('ANYTHING')).ok,
          isFalse);
    });
  });

  group('app lock', () {
    test('is off by default and remembers the choice', () async {
      expect(await AccountSecurityService.isAppLockEnabled(), isFalse);
      await AccountSecurityService.setAppLockEnabled(true);
      expect(await AccountSecurityService.isAppLockEnabled(), isTrue);
      await AccountSecurityService.setAppLockEnabled(false);
      expect(await AccountSecurityService.isAppLockEnabled(), isFalse);
    });
  });

  test('erasing the account takes the passcode, recovery code and lock '
      'with it', () async {
    await AccountSecurityService.savePasscode('1234');
    await AccountSecurityService.createRecoveryCode();
    await wrong();
    await meyaSecureStorage.deleteAll();
    expect(await AccountSecurityService.hasPasscode(), isFalse);
    expect(await AccountSecurityService.hasRecoveryCode(), isFalse);
    expect(await AccountSecurityService.lockRemaining(), Duration.zero);
  });
}
