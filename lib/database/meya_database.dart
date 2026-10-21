import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'database_encryption.dart';

part 'meya_database.g.dart';

class Accounts extends Table {
  TextColumn get accountId => text()();
  TextColumn get identityId => text().nullable()();
  TextColumn get meyaId => text().unique()();
  TextColumn get name => text()();
  TextColumn get username => text().unique()();
  TextColumn get createdAt => text()();
  TextColumn get identityPublicKey => text()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {accountId};
}

class Devices extends Table {
  TextColumn get deviceId => text()();
  TextColumn get accountId => text().references(Accounts, #accountId)();
  TextColumn get createdAt => text()();
  TextColumn get devicePublicKey => text()();
  TextColumn get certificateSignature => text().nullable()();
  BoolColumn get isTrusted => boolean().withDefault(const Constant(true))();
  BoolColumn get isRevoked => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {deviceId};
}

class Contacts extends Table {
  TextColumn get contactId => text()();
  TextColumn get identityId => text().unique()();
  TextColumn get displayName => text()();
  TextColumn get identityPublicKey => text()();
  TextColumn get trustState => text().withDefault(const Constant('trusted'))();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();
  BoolColumn get isRevoked => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {contactId};
}

class ContactDevices extends Table {
  TextColumn get deviceId => text()();
  TextColumn get contactId => text().references(Contacts, #contactId)();
  TextColumn get devicePublicKey => text()();
  TextColumn get certificateSignature => text()();
  BlobColumn get keyPackage => blob()();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();
  BoolColumn get isRevoked => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {deviceId};
}

class ConnectionRequests extends Table {
  TextColumn get requestId => text()();
  TextColumn get senderIdentityId => text()();
  TextColumn get senderDeviceId => text()();
  TextColumn get senderUsername => text()();
  TextColumn get senderIdentityPublicKey => text()();
  TextColumn get recipientDeviceId => text()();

  /// For outgoing requests: the identity ID and identity public key read from
  /// the scanned QR code. A response is trusted only if it matches both.
  TextColumn get recipientIdentityId => text().nullable()();
  TextColumn get recipientIdentityPublicKey => text().nullable()();

  TextColumn get status => text().withDefault(const Constant('pending'))();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();

  @override
  Set<Column> get primaryKey => {requestId};
}

class Conversations extends Table {
  TextColumn get conversationId => text()();
  TextColumn get type => text()();
  TextColumn get mlsGroupId => text().unique()();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  IntColumn get unreadCount => integer().withDefault(const Constant(0))();

  // Schema v9: chat list controls.
  BoolColumn get isMuted => boolean().withDefault(const Constant(false))();
  BoolColumn get markedUnread => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {conversationId};
}

class ConversationParticipants extends Table {
  TextColumn get participantId => text()();
  TextColumn get conversationId =>
      text().references(Conversations, #conversationId)();
  TextColumn get identityId => text()();
  TextColumn get deviceId => text()();
  TextColumn get contactId =>
      text().nullable().references(Contacts, #contactId)();
  BoolColumn get isLocal => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {participantId};
}

class Messages extends Table {
  TextColumn get messageId => text()();
  TextColumn get conversationId =>
      text().references(Conversations, #conversationId)();
  TextColumn get senderDeviceId => text()();
  TextColumn get createdAt => text()();
  BlobColumn get encryptedEnvelope => blob()();
  BlobColumn get localDisplayCiphertext => blob().nullable()();
  TextColumn get deliveryState =>
      text().withDefault(const Constant('queued'))();
  BoolColumn get isRead => boolean().withDefault(const Constant(false))();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();

  // Schema v9: local message state. Edits and deletions replace the sealed
  // content; these flags only record that it happened.
  BoolColumn get isStarred => boolean().withDefault(const Constant(false))();
  BoolColumn get isPinned => boolean().withDefault(const Constant(false))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  TextColumn get editedAt => text().nullable()();

  @override
  Set<Column> get primaryKey => {messageId};
}

class Attachments extends Table {
  TextColumn get attachmentId => text()();
  TextColumn get messageId =>
      text().nullable().references(Messages, #messageId)();
  TextColumn get encryptedStorageReference => text()();
  BlobColumn get encryptedMetadata => blob()();
  IntColumn get sizeBytes => integer()();
  TextColumn get mediaType => text()();
  TextColumn get transferState =>
      text().withDefault(const Constant('pending'))();
  TextColumn get integrityHash => text()();

  @override
  Set<Column> get primaryKey => {attachmentId};
}

/// Emoji reactions, one per person per message.
class Reactions extends Table {
  TextColumn get messageId => text()();
  TextColumn get reactorDeviceId => text()();
  TextColumn get emoji => text()();
  TextColumn get updatedAt => text()();

  @override
  Set<Column> get primaryKey => {messageId, reactorDeviceId};
}

/// A private group. Messages are sent to every member separately over each
/// person's own end-to-end encrypted session; only admins change its name
/// and members. [adminDeviceId] is the owner (the person who created the
/// group, or whoever it was handed to): always an admin, never removable.
class MeyaGroups extends Table {
  TextColumn get groupId => text()();
  TextColumn get name => text()();
  TextColumn get adminDeviceId => text()();
  IntColumn get revision => integer().withDefault(const Constant(0))();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();

  /// False once this device left or was removed. History stays readable.
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {groupId};
}

/// Members of a group, as announced by its admin, with the identity key the
/// admin verified in person. This device is listed too.
class GroupMembers extends Table {
  TextColumn get groupId => text().references(MeyaGroups, #groupId)();
  TextColumn get deviceId => text()();
  TextColumn get identityId => text()();
  TextColumn get displayName => text()();
  TextColumn get identityPublicKey => text()();
  TextColumn get addedAt => text()();

  /// An admin besides the owner: may rename the group, add and remove
  /// people, and make others admins.
  BoolColumn get isAdmin => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {groupId, deviceId};
}

/// Encrypted control messages (receipts, reactions, edits, deletions, pins)
/// waiting for the relay. The fields are sealed with the local storage key.
class Outbox extends Table {
  TextColumn get outboxId => text()();
  TextColumn get contactId => text()();
  BlobColumn get sealedFields => blob()();
  TextColumn get createdAt => text()();
  IntColumn get attempts => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {outboxId};
}

@DriftDatabase(
  tables: [
    Accounts,
    Devices,
    Contacts,
    ContactDevices,
    ConnectionRequests,
    Conversations,
    ConversationParticipants,
    Messages,
    Attachments,
    Reactions,
    Outbox,
    MeyaGroups,
    GroupMembers,
  ],
)
class MeyaDatabase extends _$MeyaDatabase {
  static const schemaVersionValue = 11;

  MeyaDatabase() : super(_openConnection());

  MeyaDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => schemaVersionValue;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) async {
      await migrator.createAll();
    },
    onUpgrade: (migrator, from, to) async {
      if (from < 1 || to > schemaVersion || from >= to) {
        throw StateError('unsupported_database_upgrade:$from:$to');
      }

      if (from < 2 && to >= 2) {
        await migrator.addColumn(accounts, accounts.identityId);
        await migrator.addColumn(devices, devices.certificateSignature);
        await migrator.addColumn(devices, devices.isRevoked);
      }

      if (from < 3 && to >= 3) {
        await migrator.createTable(contacts);
        await migrator.createTable(conversations);
        await _ensureMessagesTable(migrator);
        await migrator.createTable(attachments);
        await migrator.createTable(conversationParticipants);
      }

      if (from < 4 && to >= 4) {
        await migrator.createTable(contactDevices);
      }

      if (from < 5 && to >= 5) {
        await _addLocalDisplayCiphertextIfMissing(migrator);
      }

      if (from < 6 && to >= 6) {
        await migrator.createTable(connectionRequests);
      }

      if (from < 7 && to >= 7) {
        await backfillAccountIdentityIds();
      }

      if (from < 8 && to >= 8) {
        await migrator.addColumn(
          connectionRequests,
          connectionRequests.recipientIdentityId,
        );
        await migrator.addColumn(
          connectionRequests,
          connectionRequests.recipientIdentityPublicKey,
        );
      }

      if (from < 9 && to >= 9) {
        for (final (table, columns) in <(TableInfo, List<GeneratedColumn>)>[
          (conversations, [conversations.isMuted, conversations.markedUnread]),
          (
            messages,
            [
              messages.isStarred,
              messages.isPinned,
              messages.isDeleted,
              messages.editedAt,
            ]
          ),
        ]) {
          if (!await _hasTable(table.actualTableName)) {
            await migrator.createTable(table);
            continue;
          }
          for (final column in columns) {
            if (!await _hasColumn(table.actualTableName, column.name)) {
              await migrator.addColumn(table, column);
            }
          }
        }
        await migrator.createTable(reactions);
        await migrator.createTable(outbox);
      }

      if (from < 10 && to >= 10) {
        await migrator.createTable(meyaGroups);
        await migrator.createTable(groupMembers);
      }

      if (from < 11 && to >= 11) {
        // Upgrades from before 10 have just created the table with it.
        if (!await _hasColumn(
          groupMembers.actualTableName,
          groupMembers.isAdmin.name,
        )) {
          await migrator.addColumn(groupMembers, groupMembers.isAdmin);
        }
      }
    },
    beforeOpen: (_) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  /// Accounts created before schema v7 never had `identity_id` set, which
  /// blocked QR pairing on the scanning device. The QR code and the
  /// connection service already use the account ID as the identity ID, so the
  /// backfill keeps every identifier that was already shared with contacts.
  Future<void> backfillAccountIdentityIds() async {
    await customStatement(
      "UPDATE accounts SET identity_id = account_id "
      "WHERE identity_id IS NULL OR identity_id = ''",
    );
  }

  Future<void> _ensureMessagesTable(Migrator migrator) async {
    await migrator.database.customStatement('''
      CREATE TABLE IF NOT EXISTS "messages" (
        "message_id" TEXT NOT NULL PRIMARY KEY,
        "conversation_id" TEXT NOT NULL
          REFERENCES "conversations" ("conversation_id"),
        "sender_device_id" TEXT NOT NULL,
        "created_at" TEXT NOT NULL,
        "encrypted_envelope" BLOB NOT NULL,
        "delivery_state" TEXT NOT NULL DEFAULT 'queued',
        "is_read" INTEGER NOT NULL DEFAULT 0
          CHECK ("is_read" IN (0, 1)),
        "retry_count" INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  Future<bool> _hasTable(String name) async => (await customSelect(
        "SELECT name FROM sqlite_master WHERE type = 'table' AND name = ?",
        variables: [Variable.withString(name)],
      ).get())
          .isNotEmpty;

  Future<bool> _hasColumn(String table, String column) async =>
      (await customSelect('PRAGMA table_info("$table")').get())
          .any((row) => row.data['name'] == column);

  Future<void> _addLocalDisplayCiphertextIfMissing(Migrator migrator) async {
    final columns = await migrator.database
        .customSelect('PRAGMA table_info("messages")')
        .get();

    final exists = columns.any(
      (row) => row.data['name'] == 'local_display_ciphertext',
    );

    if (!exists) {
      await migrator.addColumn(messages, messages.localDisplayCiphertext);
    }
  }

  static QueryExecutor _openConnection() {
    return LazyDatabase(() async {
      final directory = await getApplicationDocumentsDirectory();

      final file = File(p.join(directory.path, 'meya.sqlite'));

      // The whole database is encrypted with a key from secure storage.
      final key = await MeyaDatabaseEncryption.loadKey();
      MeyaDatabaseEncryption.prepare(file, key);
      final unlock = MeyaDatabaseEncryption.keyPragma(key);
      return NativeDatabase.createInBackground(
        file,
        setup: (database) => database.execute(unlock),
      );
    });
  }
}
