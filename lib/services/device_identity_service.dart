import 'dart:convert';
import 'dart:math';


import 'meya_secure_storage.dart';
import 'package:meya/bridge/api.dart';

class DeviceIdentityService {
  static const _storage = meyaSecureStorage;

  static const _deviceIdKey = 'meya_device_id';
  static const _identityPrivateKey = 'meya_identity_private_key';
  static const _identityPublicKey = 'meya_identity_public_key';
  static const _relaySigningPrivateKey = 'meya_relay_signing_private_key';
  static const _relaySigningPublicKey = 'meya_relay_signing_public_key';

  static Future<String> getOrCreateDeviceId() async {
    final existingDeviceId = await _storage.read(key: _deviceIdKey);

    if (existingDeviceId != null && existingDeviceId.isNotEmpty) {
      return existingDeviceId;
    }

    final deviceId = _generateDeviceId();

    await _storage.write(key: _deviceIdKey, value: deviceId);

    return deviceId;
  }

  static Future<String?> getDeviceId() async {
    return _storage.read(key: _deviceIdKey);
  }

  static Future<bool> hasDeviceId() async {
    final deviceId = await getDeviceId();
    return deviceId != null && deviceId.isNotEmpty;
  }

  static Future<void> clearDeviceId() async {
    await _storage.delete(key: _deviceIdKey);
  }

  static Future<void> ensureIdentityKeyPair() async {
    final existingPrivateKey = await _storage.read(key: _identityPrivateKey);
    final existingPublicKey = await _storage.read(key: _identityPublicKey);

    if (existingPrivateKey != null &&
        existingPrivateKey.isNotEmpty &&
        existingPublicKey != null &&
        existingPublicKey.isNotEmpty) {
      return;
    }

    final keyPair = await generateIdentityKeyPair();

    final privateKey = keyPair.$1;
    final publicKey = keyPair.$2;

    if (privateKey.length != 32 || publicKey.length != 32) {
      throw StateError('Invalid MEYA identity key pair');
    }

    await _storage.write(
      key: _identityPrivateKey,
      value: base64Encode(privateKey),
    );

    await _storage.write(
      key: _identityPublicKey,
      value: base64Encode(publicKey),
    );
  }

  static Future<String?> getIdentityPublicKey() async {
    return _storage.read(key: _identityPublicKey);
  }

  static Future<void> clearIdentityKeyPair() async {
    await _storage.delete(key: _identityPrivateKey);
    await _storage.delete(key: _identityPublicKey);
  }

  /// Creates the device key used to authenticate to the relay, if needed.
  ///
  /// It is separate from the X25519 identity key. Both private keys stay in
  /// the platform-backed secure storage provided by flutter_secure_storage.
  static Future<void> ensureRelaySigningKeyPair() async {
    final existingPrivateKey = await _storage.read(key: _relaySigningPrivateKey);
    final existingPublicKey = await _storage.read(key: _relaySigningPublicKey);

    if (existingPrivateKey != null &&
        existingPrivateKey.isNotEmpty &&
        existingPublicKey != null &&
        existingPublicKey.isNotEmpty) {
      return;
    }

    final keyPair = await generateDeviceSigningKeyPair();
    final privateKey = keyPair.$1;
    final publicKey = keyPair.$2;

    if (privateKey.length != 32 || publicKey.length != 32) {
      throw StateError('Invalid MEYA relay signing key pair.');
    }

    await _storage.write(
      key: _relaySigningPrivateKey,
      value: base64Encode(privateKey),
    );
    await _storage.write(
      key: _relaySigningPublicKey,
      value: base64Encode(publicKey),
    );
  }

  static Future<String?> getRelaySigningPublicKey() {
    return _storage.read(key: _relaySigningPublicKey);
  }

  static Future<List<int>> signRelayAuthenticationPayload(
    List<int> payload,
  ) async {
    final encodedPrivateKey = await _storage.read(key: _relaySigningPrivateKey);

    if (encodedPrivateKey == null || encodedPrivateKey.isEmpty) {
      throw StateError('MEYA relay signing key is not available.');
    }

    return signDeviceAuthenticationPayload(
      privateKey: base64Decode(encodedPrivateKey),
      payload: payload,
    );
  }

  static Future<void> clearRelaySigningKeyPair() async {
    await _storage.delete(key: _relaySigningPrivateKey);
    await _storage.delete(key: _relaySigningPublicKey);
  }

  static String _generateDeviceId() {
    final random = Random.secure();
    final values = List<int>.generate(16, (_) => random.nextInt(256));

    return values
        .map((value) => value.toRadixString(16).padLeft(2, '0'))
        .join();
  }
}
