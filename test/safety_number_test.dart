import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meya/database/meya_database.dart';
import 'package:meya/services/safety_number.dart';

String key(int seed) => base64Encode(List.generate(33, (i) => (i * 7 + seed) % 256));

Contact contactWith(String identityKey) => Contact(
      contactId: 'contact_ana',
      identityId: 'ana',
      displayName: 'Ana',
      identityPublicKey: identityKey,
      trustState: 'trusted',
      createdAt: 't',
      updatedAt: 't',
      isRevoked: false,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('both phones show the same 60-digit number', () {
    final onMine = SafetyNumber.compute(
      localKeyBase64: key(1),
      localId: 'me',
      remoteKeyBase64: key(2),
      remoteId: 'ana',
    );
    final onAnas = SafetyNumber.compute(
      localKeyBase64: key(2),
      localId: 'ana',
      remoteKeyBase64: key(1),
      remoteId: 'me',
    );
    expect(onMine, onAnas);
    expect(onMine, matches(RegExp(r'^\d{60}$')));
    expect(SafetyNumber.groups(onMine), hasLength(12));
  });

  test('a different key gives a different number', () {
    final real = SafetyNumber.compute(
      localKeyBase64: key(1), localId: 'me', remoteKeyBase64: key(2), remoteId: 'ana');
    final attacker = SafetyNumber.compute(
      localKeyBase64: key(1), localId: 'me', remoteKeyBase64: key(3), remoteId: 'ana');
    expect(attacker, isNot(real));
  });

  test('the QR code carries the number and nothing else is accepted', () {
    final number = SafetyNumber.compute(
      localKeyBase64: key(1), localId: 'me', remoteKeyBase64: key(2), remoteId: 'ana');
    expect(SafetyNumber.fromQr(SafetyNumber.qrData(number)), number);
    expect(SafetyNumber.fromQr('MEYA-SAFETY:1:123'), isNull);
    expect(SafetyNumber.fromQr('https://example.com'), isNull);
  });

  test('verification is cleared automatically when the key changes', () async {
    FlutterSecureStorage.setMockInitialValues({});
    final ana = contactWith(key(2));
    expect(await SafetyNumber.isVerified(ana), isFalse);
    await SafetyNumber.setVerified(ana, true);
    expect(await SafetyNumber.isVerified(ana), isTrue);

    expect(await SafetyNumber.isVerified(contactWith(key(9))), isFalse);

    await SafetyNumber.setVerified(ana, false);
    expect(await SafetyNumber.isVerified(ana), isFalse);
  });
}
