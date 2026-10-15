import 'package:drift/drift.dart';

import 'meya_database.dart';

/// Stores encrypted messages. Message text is never stored in plaintext:
/// [Message.encryptedEnvelope] holds the end-to-end ciphertext and
/// [Message.localDisplayCiphertext] a copy sealed with the local storage key.
class MessageRepository {
  final MeyaDatabase database;

  MessageRepository(this.database);

  static String conversationIdFor(String contactId) => 'direct_$contactId';

  Future<String> ensureDirectConversation(String contactId) async {
    final conversationId = conversationIdFor(contactId);
    final existing = await (database.select(database.conversations)
          ..where((c) => c.conversationId.equals(conversationId))
          ..limit(1))
        .getSingleOrNull();

    if (existing == null) {
      final now = DateTime.now().toUtc().toIso8601String();
      await database.into(database.conversations).insert(
            ConversationsCompanion.insert(
              conversationId: conversationId,
              type: 'direct',
              mlsGroupId: conversationId,
              createdAt: now,
              updatedAt: now,
            ),
          );
    }
    return conversationId;
  }

  Future<bool> exists(String messageId) async {
    final row = await (database.select(database.messages)
          ..where((m) => m.messageId.equals(messageId))
          ..limit(1))
        .getSingleOrNull();
    return row != null;
  }

  Future<void> insert({
    required String messageId,
    required String conversationId,
    required String senderDeviceId,
    required String createdAt,
    required Uint8List wireCiphertext,
    required Uint8List localSealed,
    required String deliveryState,
  }) async {
    await database.into(database.messages).insert(
          MessagesCompanion.insert(
            messageId: messageId,
            conversationId: conversationId,
            senderDeviceId: senderDeviceId,
            createdAt: createdAt,
            encryptedEnvelope: wireCiphertext,
            localDisplayCiphertext: Value(localSealed),
            deliveryState: Value(deliveryState),
          ),
        );
  }

  Future<void> updateDeliveryState(String messageId, String state) async {
    await (database.update(database.messages)
          ..where((m) => m.messageId.equals(messageId)))
        .write(MessagesCompanion(deliveryState: Value(state)));
  }

  Future<List<Message>> listMessages(String conversationId) {
    return (database.select(database.messages)
          ..where((m) => m.conversationId.equals(conversationId))
          ..orderBy([
            (m) => OrderingTerm(expression: m.createdAt),
          ]))
        .get();
  }

  /// Delivery states in order; a receipt can only move a message forward.
  static const deliveryOrder = [
    'queued',
    'sending',
    'failed',
    'sent',
    'delivered',
    'read',
  ];

  /// Moves [messageId] to [state] unless it is already further along.
  Future<bool> advanceDeliveryState(String messageId, String state) async {
    final row = await get(messageId);
    if (row == null) return false;
    final current = deliveryOrder.indexOf(row.deliveryState);
    final next = deliveryOrder.indexOf(state);
    if (next < 0 || next <= current) return false;
    await updateDeliveryState(messageId, state);
    return true;
  }

  Future<Message?> get(String messageId) {
    return (database.select(database.messages)
          ..where((m) => m.messageId.equals(messageId))
          ..limit(1))
        .getSingleOrNull();
  }

  Future<Conversation?> conversation(String conversationId) {
    return (database.select(database.conversations)
          ..where((c) => c.conversationId.equals(conversationId))
          ..limit(1))
        .getSingleOrNull();
  }

  Future<List<Conversation>> conversations() =>
      database.select(database.conversations).get();

  Future<void> updateConversation(
    String conversationId,
    ConversationsCompanion values,
  ) async {
    await (database.update(database.conversations)
          ..where((c) => c.conversationId.equals(conversationId)))
        .write(values);
  }

  Future<void> incrementUnread(String conversationId) async {
    await database.customUpdate(
      'UPDATE conversations SET unread_count = unread_count + 1, '
      'updated_at = ? WHERE conversation_id = ?',
      variables: [
        Variable.withString(DateTime.now().toUtc().toIso8601String()),
        Variable.withString(conversationId),
      ],
      updates: {database.conversations},
    );
  }

  /// Marks incoming messages read and returns the IDs that were unread.
  Future<List<String>> markRead(
    String conversationId,
    String localDeviceId,
  ) async {
    final unread = await (database.select(database.messages)
          ..where((m) =>
              m.conversationId.equals(conversationId) &
              m.isRead.equals(false) &
              m.senderDeviceId.equals(localDeviceId).not()))
        .get();
    if (unread.isNotEmpty) {
      await (database.update(database.messages)
            ..where((m) => m.messageId.isIn(unread.map((m) => m.messageId))))
          .write(const MessagesCompanion(isRead: Value(true)));
    }
    await updateConversation(
      conversationId,
      const ConversationsCompanion(
        unreadCount: Value(0),
        markedUnread: Value(false),
      ),
    );
    return [for (final row in unread) row.messageId];
  }

  Future<void> setFlags(
    String messageId, {
    bool? starred,
    bool? pinned,
    bool? deleted,
    String? editedAt,
    Uint8List? sealed,
  }) async {
    await (database.update(database.messages)
          ..where((m) => m.messageId.equals(messageId)))
        .write(MessagesCompanion(
      isStarred: starred == null ? const Value.absent() : Value(starred),
      isPinned: pinned == null ? const Value.absent() : Value(pinned),
      isDeleted: deleted == null ? const Value.absent() : Value(deleted),
      editedAt: editedAt == null ? const Value.absent() : Value(editedAt),
      localDisplayCiphertext:
          sealed == null ? const Value.absent() : Value(sealed),
    ));
  }

  Future<void> delete(String messageId) async {
    await (database.delete(database.reactions)
          ..where((r) => r.messageId.equals(messageId)))
        .go();
    await (database.delete(database.messages)
          ..where((m) => m.messageId.equals(messageId)))
        .go();
  }

  Future<void> setReaction(
    String messageId,
    String reactorDeviceId,
    String emoji,
  ) async {
    if (emoji.isEmpty) {
      await (database.delete(database.reactions)
            ..where((r) =>
                r.messageId.equals(messageId) &
                r.reactorDeviceId.equals(reactorDeviceId)))
          .go();
      return;
    }
    await database.into(database.reactions).insertOnConflictUpdate(
          ReactionsCompanion.insert(
            messageId: messageId,
            reactorDeviceId: reactorDeviceId,
            emoji: emoji,
            updatedAt: DateTime.now().toUtc().toIso8601String(),
          ),
        );
  }

  Future<List<Reaction>> reactionsFor(Iterable<String> messageIds) {
    return (database.select(database.reactions)
          ..where((r) => r.messageId.isIn(messageIds)))
        .get();
  }

  Future<void> clearReactions(String messageId) async {
    await (database.delete(database.reactions)
          ..where((r) => r.messageId.equals(messageId)))
        .go();
  }
}
