import 'dart:convert';
import 'dart:math';

import '../database/account_repository.dart';
import '../database/meya_database.dart';
import 'device_identity_service.dart';

class MeyaAccountService {
  final AccountRepository repository;

  MeyaAccountService(this.repository);

  Future<Account?> loadActiveAccount() {
    return repository.getActiveAccount();
  }

  Future<Account> createAccount({
    required String name,
    required String username,
  }) async {
    final accountId = _generateId();
    final meyaId = _generateMeyaId();
    final createdAt = DateTime.now().toUtc().toIso8601String();

    await DeviceIdentityService.getOrCreateDeviceId();
    await DeviceIdentityService.ensureIdentityKeyPair();
    await DeviceIdentityService.ensureRelaySigningKeyPair();

    final identityPublicKey =
        await DeviceIdentityService.getIdentityPublicKey();

    if (identityPublicKey == null || identityPublicKey.isEmpty) {
      throw StateError('MEYA identity public key was not created.');
    }

    // The identity ID is the stable identifier other people's devices store
    // for this account. It matches the value already shown in the QR code
    // (the account ID), so existing QR payloads stay valid.
    await repository.createAccount(
      accountId: accountId,
      identityId: accountId,
      meyaId: meyaId,
      name: name,
      username: username,
      createdAt: createdAt,
      identityPublicKey: identityPublicKey,
    );

    return (await repository.getAccountById(accountId))!;
  }

  String _generateId() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64UrlEncode(bytes).replaceAll('=', '');
  }

  String _generateMeyaId() {
    final random = Random.secure();
    final number = List<int>.generate(
      12,
      (_) => random.nextInt(10),
    ).join();
    return 'MEYA-$number';
  }
}
