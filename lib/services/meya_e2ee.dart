import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';


import 'meya_secure_storage.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../bridge/api.dart' as bridge;
import 'device_identity_service.dart';

/// A message encrypted for one contact device.
class E2eeCiphertext {
  /// 3 = first message of a session, 2 = normal message.
  final int messageType;
  final Uint8List body;

  const E2eeCiphertext({required this.messageType, required this.body});
}

/// End-to-end encryption operations used by MEYA's services.
///
/// The real implementation ([MeyaE2ee]) calls the Rust engine (libsignal:
/// PQXDH + Triple Ratchet). Tests provide a fake.
abstract class E2eeOperations {
  /// This device's identity public key, base64. Null until opened.
  String? get identityKeyBase64;

  Future<String> open();
  Future<void> pinIdentity(String deviceId, String identityKeyBase64);
  Future<String> createPreKeyBundle();
  Future<void> startSession(String deviceId, String bundleJson);
  Future<bool> hasSession(String deviceId);
  Future<E2eeCiphertext> encrypt(String deviceId, Uint8List plaintext);
  Future<Uint8List> decrypt(String deviceId, int messageType, Uint8List body);
  Future<void> forget(String deviceId);

  /// Encrypts data kept on this phone (message history) with the local
  /// storage key, bound to [context] (for example the message ID).
  Future<Uint8List> sealLocal(Uint8List plaintext, String context);
  Future<Uint8List> openLocal(Uint8List sealed, String context);
}

class MeyaE2ee implements E2eeOperations {
  MeyaE2ee._();

  static final MeyaE2ee instance = MeyaE2ee._();

  static const _secureStorage = meyaSecureStorage;
  static const _storageKeyName = 'meya_e2ee_storage_key_v1';
  static const _storeFileName = 'meya_signal.store';

  String? _identityKeyBase64;
  Uint8List? _storageKey;
  Future<String>? _opening;

  @override
  String? get identityKeyBase64 => _identityKeyBase64;

  bool get isOpen => _identityKeyBase64 != null;

  /// Opens the encrypted protocol store (creating it on first run) and
  /// returns this device's identity public key. Safe to call repeatedly.
  @override
  Future<String> open() {
    final existing = _identityKeyBase64;
    if (existing != null) return Future.value(existing);
    return _opening ??= _open().whenComplete(() => _opening = null);
  }

  Future<String> _open() async {
    final deviceId = await DeviceIdentityService.getOrCreateDeviceId();
    final storageKey = await _loadOrCreateStorageKey();
    final directory = await getApplicationSupportDirectory();
    await directory.create(recursive: true);

    final identity = await bridge.signalOpen(
      storePath: p.join(directory.path, _storeFileName),
      storageKey: storageKey,
      localDeviceId: deviceId,
    );

    _storageKey = storageKey;
    _identityKeyBase64 = base64Encode(identity);
    return _identityKeyBase64!;
  }

  /// The storage key lives only in the platform's secure storage (Android
  /// Keystore-backed). It never goes into SQLite or ordinary files.
  Future<Uint8List> _loadOrCreateStorageKey() async {
    final stored = await _secureStorage.read(key: _storageKeyName);
    if (stored != null && stored.isNotEmpty) {
      final bytes = base64Decode(stored);
      if (bytes.length == 32) return Uint8List.fromList(bytes);
    }

    final random = Random.secure();
    final key = Uint8List.fromList(
      List<int>.generate(32, (_) => random.nextInt(256)),
    );
    await _secureStorage.write(key: _storageKeyName, value: base64Encode(key));
    return key;
  }

  /// Closes the protocol store and deletes it from this phone (used when
  /// the account is deleted). The storage key is removed separately.
  Future<void> closeAndDeleteStore() async {
    try {
      await bridge.signalClose();
    } catch (_) {
      // Not open.
    }
    _identityKeyBase64 = null;
    _storageKey = null;
    final directory = await getApplicationSupportDirectory();
    final store = File(p.join(directory.path, _storeFileName));
    if (await store.exists()) await store.delete();
  }

  Future<void> _requireOpen() async {
    if (!isOpen) await open();
  }

  @override
  Future<void> pinIdentity(String deviceId, String identityKeyBase64) async {
    await _requireOpen();
    await bridge.signalPinIdentity(
      remoteDeviceId: deviceId,
      identityKey: base64Decode(identityKeyBase64),
    );
  }

  @override
  Future<String> createPreKeyBundle() async {
    await _requireOpen();
    return bridge.signalCreatePreKeyBundle();
  }

  @override
  Future<void> startSession(String deviceId, String bundleJson) async {
    await _requireOpen();
    await bridge.signalStartSession(
      remoteDeviceId: deviceId,
      bundleJson: bundleJson,
    );
  }

  @override
  Future<bool> hasSession(String deviceId) async {
    await _requireOpen();
    return bridge.signalHasSession(remoteDeviceId: deviceId);
  }

  @override
  Future<E2eeCiphertext> encrypt(String deviceId, Uint8List plaintext) async {
    await _requireOpen();
    final result = await bridge.signalEncrypt(
      remoteDeviceId: deviceId,
      plaintext: plaintext,
    );
    return E2eeCiphertext(messageType: result.messageType, body: result.body);
  }

  @override
  Future<Uint8List> decrypt(
    String deviceId,
    int messageType,
    Uint8List body,
  ) async {
    await _requireOpen();
    return bridge.signalDecrypt(
      remoteDeviceId: deviceId,
      messageType: messageType,
      body: body,
    );
  }

  @override
  Future<void> forget(String deviceId) async {
    await _requireOpen();
    await bridge.signalForget(remoteDeviceId: deviceId);
  }

  @override
  Future<Uint8List> sealLocal(Uint8List plaintext, String context) async {
    await _requireOpen();
    return bridge.encryptMessage(
      sessionKey: _storageKey!,
      plaintext: plaintext,
      aad: utf8.encode('meya-local-v1|$context'),
    );
  }

  @override
  Future<Uint8List> openLocal(Uint8List sealed, String context) async {
    await _requireOpen();
    return bridge.decryptMessage(
      sessionKey: _storageKey!,
      envelope: sealed,
      aad: utf8.encode('meya-local-v1|$context'),
    );
  }
}
