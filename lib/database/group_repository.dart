import 'package:drift/drift.dart';

import 'meya_database.dart';

/// One member of a group, as announced by the group's admin.
class GroupMemberInfo {
  final String deviceId;
  final String identityId;
  final String name;
  final String identityPublicKey;

  const GroupMemberInfo({
    required this.deviceId,
    required this.identityId,
    required this.name,
    required this.identityPublicKey,
  });

  Map<String, Object> toContent() => {
        'device': deviceId,
        'identity': identityId,
        'name': name,
        'key': identityPublicKey,
      };

  static GroupMemberInfo? fromContent(Object? value) {
    if (value is! Map) return null;
    final device = value['device'];
    final identity = value['identity'];
    final name = value['name'];
    final key = value['key'];
    if (device is! String ||
        identity is! String ||
        name is! String ||
        key is! String ||
        !RegExp(r'^[A-Za-z0-9_-]{8,128}$').hasMatch(device) ||
        identity.isEmpty ||
        identity.length > 128 ||
        key.isEmpty ||
        key.length > 256) {
      return null;
    }
    final trimmed = name.trim();
    return GroupMemberInfo(
      deviceId: device,
      identityId: identity,
      name: trimmed.length > 80 ? trimmed.substring(0, 80) : trimmed,
      identityPublicKey: key,
    );
  }
}

/// Stores groups and their members.
class GroupRepository {
  final MeyaDatabase database;

  GroupRepository(this.database);

  static String conversationIdFor(String groupId) => 'group_$groupId';

  /// Groups this device belongs (or belonged) to, most recently changed first.
  Future<List<MeyaGroup>> groups() => (database.select(database.meyaGroups)
        ..orderBy([
          (g) => OrderingTerm(expression: g.isActive, mode: OrderingMode.desc),
          (g) => OrderingTerm(expression: g.updatedAt, mode: OrderingMode.desc),
        ]))
      .get();

  Future<MeyaGroup?> group(String groupId) =>
      (database.select(database.meyaGroups)
            ..where((g) => g.groupId.equals(groupId))
            ..limit(1))
          .getSingleOrNull();

  Future<List<GroupMember>> members(String groupId) =>
      (database.select(database.groupMembers)
            ..where((m) => m.groupId.equals(groupId))
            ..orderBy([(m) => OrderingTerm(expression: m.displayName)]))
          .get();

  Future<GroupMember?> member(String groupId, String deviceId) =>
      (database.select(database.groupMembers)
            ..where((m) => m.groupId.equals(groupId) & m.deviceId.equals(deviceId))
            ..limit(1))
          .getSingleOrNull();

  /// Active groups that list [deviceId] as a member.
  Future<List<MeyaGroup>> activeGroupsWith(String deviceId) async {
    final rows = await (database.select(database.groupMembers)
          ..where((m) => m.deviceId.equals(deviceId)))
        .get();
    final result = <MeyaGroup>[];
    for (final row in rows) {
      final found = await group(row.groupId);
      if (found != null && found.isActive) result.add(found);
    }
    return result;
  }

  /// Saves the group and replaces its member list. Members already listed
  /// keep the time they joined.
  Future<void> save({
    required String groupId,
    required String name,
    required String adminDeviceId,
    required int revision,
    required List<GroupMemberInfo> members,
    required bool isActive,
  }) async {
    final now = DateTime.now().toUtc().toIso8601String();
    await database.transaction(() async {
      final existing = await group(groupId);
      await database.into(database.meyaGroups).insertOnConflictUpdate(
            MeyaGroupsCompanion.insert(
              groupId: groupId,
              name: name,
              adminDeviceId: adminDeviceId,
              revision: Value(revision),
              createdAt: existing?.createdAt ?? now,
              updatedAt: now,
              isActive: Value(isActive),
            ),
          );
      final joined = {
        for (final row in await this.members(groupId)) row.deviceId: row.addedAt,
      };
      await (database.delete(database.groupMembers)
            ..where((m) => m.groupId.equals(groupId)))
          .go();
      for (final member in members) {
        await database.into(database.groupMembers).insert(
              GroupMembersCompanion.insert(
                groupId: groupId,
                deviceId: member.deviceId,
                identityId: member.identityId,
                displayName: member.name,
                identityPublicKey: member.identityPublicKey,
                addedAt: joined[member.deviceId] ?? now,
              ),
            );
      }
    });
  }

  Future<void> setActive(String groupId, bool active) async {
    await (database.update(database.meyaGroups)
          ..where((g) => g.groupId.equals(groupId)))
        .write(MeyaGroupsCompanion(
      isActive: Value(active),
      updatedAt: Value(DateTime.now().toUtc().toIso8601String()),
    ));
  }

  /// Ensures the conversation that holds this group's messages exists.
  Future<String> ensureConversation(String groupId) async {
    final conversationId = conversationIdFor(groupId);
    final existing = await (database.select(database.conversations)
          ..where((c) => c.conversationId.equals(conversationId))
          ..limit(1))
        .getSingleOrNull();
    if (existing == null) {
      final now = DateTime.now().toUtc().toIso8601String();
      await database.into(database.conversations).insert(
            ConversationsCompanion.insert(
              conversationId: conversationId,
              type: 'group',
              mlsGroupId: conversationId,
              createdAt: now,
              updatedAt: now,
            ),
          );
    }
    return conversationId;
  }

  /// Deletes the group, its members and its messages from this device.
  Future<void> delete(String groupId) async {
    final conversationId = conversationIdFor(groupId);
    await database.transaction(() async {
      final ids = (await (database.select(database.messages)
                ..where((m) => m.conversationId.equals(conversationId)))
              .get())
          .map((m) => m.messageId)
          .toList();
      await (database.delete(database.attachments)
            ..where((a) => a.messageId.isIn(ids)))
          .go();
      await (database.delete(database.reactions)
            ..where((r) => r.messageId.isIn(ids)))
          .go();
      await (database.delete(database.messages)
            ..where((m) => m.conversationId.equals(conversationId)))
          .go();
      await (database.delete(database.conversationParticipants)
            ..where((p) => p.conversationId.equals(conversationId)))
          .go();
      await (database.delete(database.conversations)
            ..where((c) => c.conversationId.equals(conversationId)))
          .go();
      await (database.delete(database.groupMembers)
            ..where((m) => m.groupId.equals(groupId)))
          .go();
      await (database.delete(database.meyaGroups)
            ..where((g) => g.groupId.equals(groupId)))
          .go();
    });
  }
}
