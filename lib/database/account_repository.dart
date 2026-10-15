import 'package:drift/drift.dart';

import 'meya_database.dart';

class AccountRepository {
  final MeyaDatabase database;

  AccountRepository(this.database);

  Future<Account?> getActiveAccount() {
    return (database.select(database.accounts)
          ..where((account) => account.isActive.equals(true))
          ..limit(1))
        .getSingleOrNull();
  }

  Future<Account?> getAccountById(String accountId) {
    return (database.select(database.accounts)
          ..where((account) => account.accountId.equals(accountId))
          ..limit(1))
        .getSingleOrNull();
  }

  Future<Account?> getAccountByUsername(String username) {
    return (database.select(database.accounts)
          ..where((account) => account.username.equals(username.toLowerCase()))
          ..limit(1))
        .getSingleOrNull();
  }

  Future<void> createAccount({
    required String accountId,
    required String identityId,
    required String meyaId,
    required String name,
    required String username,
    required String createdAt,
    required String identityPublicKey,
  }) async {
    if (identityId.isEmpty) {
      throw ArgumentError.value(identityId, 'identityId', 'must not be empty');
    }

    await database
        .into(database.accounts)
        .insert(
          AccountsCompanion.insert(
            accountId: accountId,
            identityId: Value(identityId),
            meyaId: meyaId,
            name: name,
            username: username.toLowerCase(),
            createdAt: createdAt,
            identityPublicKey: identityPublicKey,
          ),
        );
  }

  Future<void> updateAccountProfile({
    required String accountId,
    required String name,
    required String username,
  }) async {
    await (database.update(
      database.accounts,
    )..where((account) => account.accountId.equals(accountId))).write(
      AccountsCompanion(
        name: Value(name),
        username: Value(username.toLowerCase()),
      ),
    );
  }

  Future<void> updateIdentityPublicKey({
    required String accountId,
    required String identityPublicKey,
  }) async {
    await (database.update(database.accounts)
          ..where((account) => account.accountId.equals(accountId)))
        .write(AccountsCompanion(identityPublicKey: Value(identityPublicKey)));
  }

  Future<void> deactivateAllAccounts() async {
    await database
        .update(database.accounts)
        .write(const AccountsCompanion(isActive: Value(false)));
  }

  Future<void> activateAccount(String accountId) async {
    await database.transaction(() async {
      await deactivateAllAccounts();

      await (database.update(database.accounts)
            ..where((account) => account.accountId.equals(accountId)))
          .write(const AccountsCompanion(isActive: Value(true)));
    });
  }
}
