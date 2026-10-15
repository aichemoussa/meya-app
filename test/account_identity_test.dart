import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meya/database/account_repository.dart';
import 'package:meya/database/connection_request_repository.dart';
import 'package:meya/database/meya_database.dart';

/// The connection_requests table as it existed at schema versions 6 and 7.
const connectionRequestsV7Sql = '''
  CREATE TABLE connection_requests (
    request_id TEXT NOT NULL PRIMARY KEY,
    sender_identity_id TEXT NOT NULL,
    sender_device_id TEXT NOT NULL,
    sender_username TEXT NOT NULL,
    sender_identity_public_key TEXT NOT NULL,
    recipient_device_id TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending',
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
  )
''';

void main() {
  test('new accounts are created with an identity ID', () async {
    final database = MeyaDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);

    await AccountRepository(database).createAccount(
      accountId: 'account-1',
      identityId: 'account-1',
      meyaId: 'MEYA-000000000001',
      name: 'Test',
      username: 'Tester',
      createdAt: DateTime.now().toUtc().toIso8601String(),
      identityPublicKey: 'public-key',
    );

    final account = await AccountRepository(database).getAccountById(
      'account-1',
    );
    expect(account!.identityId, 'account-1');
    expect(account.username, 'tester');
  });

  test('createAccount rejects an empty identity ID', () async {
    final database = MeyaDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);

    expect(
      () => AccountRepository(database).createAccount(
        accountId: 'account-1',
        identityId: '',
        meyaId: 'MEYA-000000000001',
        name: 'Test',
        username: 'tester',
        createdAt: DateTime.now().toUtc().toIso8601String(),
        identityPublicKey: 'public-key',
      ),
      throwsArgumentError,
    );
  });

  test('upgrading from schema 6 backfills missing identity IDs', () async {
    final database = MeyaDatabase.forTesting(
      NativeDatabase.memory(
        setup: (raw) {
          // The accounts table as it existed at schema version 6.
          raw.execute('''
            CREATE TABLE accounts (
              account_id TEXT NOT NULL PRIMARY KEY,
              identity_id TEXT NULL,
              meya_id TEXT NOT NULL UNIQUE,
              name TEXT NOT NULL,
              username TEXT NOT NULL UNIQUE,
              created_at TEXT NOT NULL,
              identity_public_key TEXT NOT NULL,
              is_active INTEGER NOT NULL DEFAULT 1
                CHECK (is_active IN (0, 1))
            )
          ''');
          raw.execute('''
            INSERT INTO accounts (account_id, identity_id, meya_id, name,
              username, created_at, identity_public_key)
            VALUES
              ('legacy-1', NULL, 'MEYA-1', 'One', 'one', 't', 'k1'),
              ('legacy-2', '', 'MEYA-2', 'Two', 'two', 't', 'k2'),
              ('kept-3', 'existing-id', 'MEYA-3', 'Three', 'three', 't', 'k3')
          ''');
          raw.execute(connectionRequestsV7Sql);
          raw.execute('PRAGMA user_version = 6');
        },
      ),
    );
    addTearDown(database.close);

    final repository = AccountRepository(database);
    expect((await repository.getAccountById('legacy-1'))!.identityId,
        'legacy-1');
    expect((await repository.getAccountById('legacy-2'))!.identityId,
        'legacy-2');
    expect((await repository.getAccountById('kept-3'))!.identityId,
        'existing-id');
  });

  test('upgrading from schema 7 keeps requests and adds QR identity columns',
      () async {
    final database = MeyaDatabase.forTesting(
      NativeDatabase.memory(
        setup: (raw) {
          raw.execute(connectionRequestsV7Sql);
          raw.execute('''
            INSERT INTO connection_requests (request_id, sender_identity_id,
              sender_device_id, sender_username, sender_identity_public_key,
              recipient_device_id, status, created_at, updated_at)
            VALUES ('request-1', 'identity-a', 'device-a', 'a', 'key-a',
              'device-b', 'pending', 't', 't')
          ''');
          raw.execute('PRAGMA user_version = 7');
        },
      ),
    );
    addTearDown(database.close);

    final request = await ConnectionRequestRepository(
      database,
    ).getRequestById('request-1');
    expect(request, isNotNull);
    expect(request!.status, 'pending');
    expect(request.recipientIdentityId, isNull);
    expect(request.recipientIdentityPublicKey, isNull);
  });
}
