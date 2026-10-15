import 'package:flutter_test/flutter_test.dart';
import 'package:meya/bridge/api.dart';
import 'package:meya/bridge/frb_generated.dart';

void main() {
  setUpAll(() async {
    await RustLib.init();
  });

  test('Rust crypto core is reachable', () async {
    expect(await meyaCryptoReady(), 'MEYA crypto core ready');
  });

  test(
    'Flutter can generate an X25519 identity key pair through Rust',
    () async {
      final keyPair = await generateIdentityKeyPair();

      final privateKey = keyPair.$1;
      final publicKey = keyPair.$2;

      expect(privateKey.length, 32);
      expect(publicKey.length, 32);
    },
  );

  test('Flutter can derive the identity public key through Rust', () async {
    final keyPair = await generateIdentityKeyPair();

    final privateKey = keyPair.$1;
    final expectedPublicKey = keyPair.$2;

    final derivedPublicKey = await identityPublicKey(privateKey: privateKey);

    expect(derivedPublicKey, expectedPublicKey);
  });

  test(
    'Flutter rejects an invalid identity private key through Rust',
    () async {
      expect(
        () => identityPublicKey(privateKey: List<int>.filled(31, 0)),
        throwsA(anything),
      );
    },
  );

  test('Flutter can encrypt and decrypt a message through Rust', () async {
    final sessionKey = List<int>.filled(32, 0x42);
    final plaintext = List<int>.from('MEYA private message'.codeUnits);
    final aad = List<int>.from(
      'meya-v1|conversation-001|message-001'.codeUnits,
    );

    final envelope = await encryptMessage(
      sessionKey: sessionKey,
      plaintext: plaintext,
      aad: aad,
    );

    expect(envelope.length, greaterThan(29));
    expect(envelope.first, 1);

    final decrypted = await decryptMessage(
      sessionKey: sessionKey,
      envelope: envelope,
      aad: aad,
    );

    expect(decrypted, plaintext);
  });

  test('Flutter detects tampered encrypted message', () async {
    final sessionKey = List<int>.filled(32, 0x42);
    final plaintext = List<int>.from('MEYA private message'.codeUnits);
    final aad = List<int>.from(
      'meya-v1|conversation-001|message-001'.codeUnits,
    );

    final envelope = await encryptMessage(
      sessionKey: sessionKey,
      plaintext: plaintext,
      aad: aad,
    );

    final tamperedEnvelope = List<int>.from(envelope);
    tamperedEnvelope[13] ^= 0x01;

    expect(
      () => decryptMessage(
        sessionKey: sessionKey,
        envelope: tamperedEnvelope,
        aad: aad,
      ),
      throwsA(anything),
    );
  });
}
