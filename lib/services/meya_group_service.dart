import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart';

import '../database/account_repository.dart';
import '../database/contact_repository.dart';
import '../database/group_repository.dart';
import '../database/meya_database.dart';
import '../l10n/meya_strings.dart';
import 'device_identity_service.dart';
import 'meya_e2ee.dart';
import 'meya_message_service.dart';

/// Private groups.
///
/// There is no group key and no server-side group: every message is sent to
/// each member separately over that member's own end-to-end encrypted
/// session (pairwise fan-out). The admin, the person who created the group,
/// announces its name and members, and only from people they verified in
/// person (their own MEYA connections), with each member's identity key.
///
/// Members who are not connected with each other are introduced through the
/// admin: one of them sends a one-time pre-key bundle to the admin, who
/// forwards it. libsignal only accepts the bundle if it is signed by the
/// identity key the admin announced, so the admin vouches for who is who,
/// and nobody else (the relay included) can read or change the messages.
///
/// Silent messages (sent over existing sessions, never shown):
///   group_update  admin -> each member: name, admin, revision, members
///   group_intro   member -> admin {to, bundle}; admin -> member {from, bundle}
///   group_leave   member -> admin: please remove me
class MeyaGroupService {
  MeyaGroupService._();

  static final MeyaGroupService instance = MeyaGroupService._();

  static const int maxMembers = 32;
  static const int maxNameLength = 60;

  MeyaDatabase? _database;
  E2eeOperations _e2ee = MeyaE2ee.instance;
  Future<String?> Function() _localDeviceId = DeviceIdentityService.getDeviceId;

  final StreamController<String> _changes = StreamController.broadcast();

  /// Introductions already sent in this run, so repeated updates do not
  /// create a new session each time.
  final Set<String> _introduced = {};

  /// A group ID whenever a group or its members change.
  Stream<String> get changes => _changes.stream;

  static const kinds = ['group_update', 'group_intro', 'group_leave'];

  void configure({required MeyaDatabase database}) {
    _database = database;
  }

  @visibleForTesting
  void configureForTesting({
    required MeyaDatabase database,
    required E2eeOperations e2ee,
    required Future<String?> Function() localDeviceId,
  }) {
    _database = database;
    _e2ee = e2ee;
    _localDeviceId = localDeviceId;

  }

  MeyaDatabase get _db {
    final database = _database;
    if (database == null) {
      throw StateError('MEYA group service is not configured.');
    }
    return database;
  }

  GroupRepository get _groups => GroupRepository(_db);

  Future<String> _myDevice() async {
    final id = await _localDeviceId();
    if (id == null || id.isEmpty) {
      throw StateError(tr('This device has no MEYA device ID.'));
    }
    return id;
  }

  Future<GroupMemberInfo> _me() async {
    final account = await AccountRepository(_db).getActiveAccount();
    if (account == null) throw StateError(tr('No MEYA account on this phone.'));
    return GroupMemberInfo(
      deviceId: await _myDevice(),
      identityId: account.identityId ?? account.accountId,
      name: account.name.trim().isEmpty ? '@${account.username}' : account.name,
      identityPublicKey: await _e2ee.open(),
    );
  }

  Future<GroupMemberInfo?> _memberFromContact(Contact contact) async {
    if (contact.trustState != 'trusted' || contact.isRevoked) return null;
    final deviceId =
        await ContactRepository(_db).getDeviceIdForContact(contact.contactId);
    if (deviceId == null) return null;
    return GroupMemberInfo(
      deviceId: deviceId,
      identityId: contact.identityId,
      name: contact.displayName,
      identityPublicKey: contact.identityPublicKey,
    );
  }

  static List<GroupMemberInfo> _infos(List<GroupMember> rows) => [
        for (final row in rows)
          GroupMemberInfo(
            deviceId: row.deviceId,
            identityId: row.identityId,
            name: row.displayName,
            identityPublicKey: row.identityPublicKey,
          ),
      ];

  String _cleanName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) throw StateError(tr('Give the group a name.'));
    return trimmed.length > maxNameLength
        ? trimmed.substring(0, maxNameLength)
        : trimmed;
  }

  // ------------------------------------------------------------- reading

  Future<List<MeyaGroup>> groups() => _groups.groups();

  Future<MeyaGroup?> group(String groupId) => _groups.group(groupId);

  Future<List<GroupMember>> members(String groupId) => _groups.members(groupId);

  Future<bool> isAdmin(MeyaGroup group) async =>
      group.adminDeviceId == await _localDeviceId();

  /// The display names of a group's members by device, for message bubbles.
  Future<Map<String, String>> memberNames(String groupId) async => {
        for (final member in await _groups.members(groupId))
          member.deviceId: member.displayName,
      };

  // ------------------------------------------------------- admin actions

  /// Creates a group with some of your connections. You are its admin.
  Future<String> create(String name, List<Contact> contacts) async {
    final cleanName = _cleanName(name);
    if (contacts.isEmpty) throw StateError(tr('Choose at least one person.'));
    if (contacts.length + 1 > maxMembers) {
      throw StateError(tr('A group can have up to {0} people.', [maxMembers]));
    }
    final me = await _me();
    final members = <GroupMemberInfo>[me];
    for (final contact in contacts) {
      final info = await _memberFromContact(contact);
      if (info == null) {
        throw StateError(
          tr('Encrypted messaging is not set up with {0} yet.', [contact.displayName]),
        );
      }
      if (members.every((m) => m.deviceId != info.deviceId)) members.add(info);
    }

    final groupId = MeyaMessageService.newId();
    await _groups.save(
      groupId: groupId,
      name: cleanName,
      adminDeviceId: me.deviceId,
      revision: 1,
      members: members,
      isActive: true,
    );
    await _groups.ensureConversation(groupId);
    _changes.add(groupId);
    await _announce(groupId);
    return groupId;
  }

  Future<void> rename(String groupId, String name) =>
      _change(groupId, name: _cleanName(name));

  Future<void> addMembers(String groupId, List<Contact> contacts) async {
    final current = _infos(await _groups.members(groupId));
    for (final contact in contacts) {
      final info = await _memberFromContact(contact);
      if (info == null) continue;
      if (current.every((m) => m.deviceId != info.deviceId)) current.add(info);
    }
    if (current.length > maxMembers) {
      throw StateError(tr('A group can have up to {0} people.', [maxMembers]));
    }
    await _change(groupId, members: current);
  }

  Future<void> removeMember(String groupId, String deviceId) async {
    final before = _infos(await _groups.members(groupId));
    final removed = before.where((m) => m.deviceId == deviceId).toList();
    final after = before.where((m) => m.deviceId != deviceId).toList();
    await _change(groupId, members: after, alsoTell: removed);
  }

  Future<void> _change(
    String groupId, {
    String? name,
    List<GroupMemberInfo>? members,
    List<GroupMemberInfo> alsoTell = const [],
  }) async {
    final group = await _groups.group(groupId);
    if (group == null || !group.isActive) {
      throw StateError(tr('You are no longer in this group.'));
    }
    if (!await isAdmin(group)) {
      throw StateError(tr('Only the group admin can change the group.'));
    }
    await _groups.save(
      groupId: groupId,
      name: name ?? group.name,
      adminDeviceId: group.adminDeviceId,
      revision: group.revision + 1,
      members: members ?? _infos(await _groups.members(groupId)),
      isActive: true,
    );
    _changes.add(groupId);
    await _announce(groupId, alsoTell: alsoTell);
  }

  /// Leaves the group. If you are the admin, the next member (the earliest
  /// to join) becomes admin first.
  Future<void> leave(String groupId) async {
    final group = await _groups.group(groupId);
    if (group == null) return;
    final me = await _myDevice();
    if (group.isActive) {
      final rest = (await _groups.members(groupId))
          .where((m) => m.deviceId != me)
          .toList()
        ..sort((a, b) => a.addedAt.compareTo(b.addedAt));
      if (group.adminDeviceId == me) {
        if (rest.isNotEmpty) {
          await _groups.save(
            groupId: groupId,
            name: group.name,
            adminDeviceId: rest.first.deviceId,
            revision: group.revision + 1,
            members: _infos(rest),
            isActive: false,
          );
          await _announce(groupId, from: me);
        }
      } else {
        await _sendTo(group.adminDeviceId, {'kind': 'group_leave', 'group': groupId});
      }
    }
    await _groups.setActive(groupId, false);
    _changes.add(groupId);
  }

  /// Leaves (if still in it) and deletes the group from this phone.
  Future<void> delete(String groupId) async {
    final group = await _groups.group(groupId);
    if (group != null && group.isActive) await leave(groupId);
    await _groups.delete(groupId);
    _changes.add(groupId);
  }

  /// Sends the current group state to every member (and [alsoTell]).
  Future<void> _announce(
    String groupId, {
    List<GroupMemberInfo> alsoTell = const [],
    String? from,
  }) async {
    final group = await _groups.group(groupId);
    if (group == null) return;
    final members = _infos(await _groups.members(groupId));
    final me = from ?? await _myDevice();
    final update = <String, Object>{
      'kind': 'group_update',
      'group': groupId,
      'name': group.name,
      'admin': group.adminDeviceId,
      'revision': group.revision,
      'members': [for (final m in members) m.toContent()],
    };
    for (final member in [...members, ...alsoTell]) {
      if (member.deviceId == me) continue;
      try {
        await _sendTo(member.deviceId, update);
      } catch (error) {
        debugPrint('MEYA group: update not delivered to one member ($error).');
      }
    }
  }

  Future<void> _sendTo(String deviceId, Map<String, Object> fields) async {
    final contact = await ContactRepository(_db).getContactByDeviceId(deviceId);
    if (contact == null) throw StateError('no session with this member');
    await MeyaMessageService.instance.sendSilent(contact, fields);
  }

  // ------------------------------------------------------------ incoming

  /// Silent handler for group_update, group_intro and group_leave.
  Future<void> handleIncoming(
    Contact contact,
    String senderDeviceId,
    Map<String, dynamic> content,
  ) async {
    final groupId = content['group'];
    if (groupId is! String || groupId.isEmpty || groupId.length > 64) return;
    try {
      switch (content['kind']) {
        case 'group_update':
          await _onUpdate(contact, senderDeviceId, groupId, content);
        case 'group_intro':
          await _onIntro(senderDeviceId, groupId, content);
        case 'group_leave':
          await _onLeave(senderDeviceId, groupId);
      }
    } catch (error) {
      debugPrint('MEYA group: ${content['kind']} not applied ($error).');
    }
  }

  Future<void> _onUpdate(
    Contact contact,
    String senderDeviceId,
    String groupId,
    Map<String, dynamic> content,
  ) async {
    final name = content['name'];
    final admin = content['admin'];
    final revision = content['revision'];
    final list = content['members'];
    if (name is! String || admin is! String || revision is! int || list is! List) {
      return;
    }
    final existing = await _groups.group(groupId);
    if (existing == null) {
      // A new group: only from someone you verified in person, who must be
      // its admin.
      if (contact.trustState != 'trusted' || admin != senderDeviceId) return;
    } else {
      // Changes come from the current admin (who may hand over to another).
      if (senderDeviceId != existing.adminDeviceId) return;
      if (revision <= existing.revision) return;
    }

    final members = <GroupMemberInfo>[];
    for (final item in list.take(maxMembers)) {
      final info = GroupMemberInfo.fromContent(item);
      if (info != null && members.every((m) => m.deviceId != info.deviceId)) {
        members.add(info);
      }
    }
    final me = await _myDevice();
    final stillIn = members.any((m) => m.deviceId == me);
    if (!members.any((m) => m.deviceId == admin) && admin != senderDeviceId) {
      return;
    }
    if (existing == null && !stillIn) return;

    await _groups.save(
      groupId: groupId,
      name: _cleanNameOr(name, existing?.name ?? tr('Group')),
      adminDeviceId: admin,
      revision: revision,
      members: stillIn ? members : _infos(await _groups.members(groupId)),
      isActive: stillIn,
    );
    await _groups.ensureConversation(groupId);
    _changes.add(groupId);
    if (stillIn) await _introduce(groupId);
  }

  String _cleanNameOr(String name, String fallback) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return fallback;
    return trimmed.length > maxNameLength
        ? trimmed.substring(0, maxNameLength)
        : trimmed;
  }

  /// For each member this device has no session with, the one of the pair
  /// with the smaller device ID sends a pre-key bundle through the admin.
  Future<void> _introduce(String groupId) async {
    final group = await _groups.group(groupId);
    if (group == null || !group.isActive) return;
    final me = await _myDevice();
    if (group.adminDeviceId == me) return; // The admin knows everyone.
    for (final member in await _groups.members(groupId)) {
      final other = member.deviceId;
      if (other == me || other == group.adminDeviceId) continue;
      if (await _hasSession(other)) continue;
      if (me.compareTo(other) > 0) continue; // They introduce themselves.
      if (!_introduced.add('$groupId|$other')) continue;
      try {
        await _e2ee.pinIdentity(other, member.identityPublicKey);
        await _rememberMember(member);
        final bundle = await _e2ee.createPreKeyBundle();
        await _sendTo(group.adminDeviceId, {
          'kind': 'group_intro',
          'group': groupId,
          'to': other,
          'bundle': bundle,
        });
      } catch (error) {
        _introduced.remove('$groupId|$other');
        debugPrint('MEYA group: introduction not sent ($error).');
      }
    }
  }

  Future<bool> _hasSession(String deviceId) async {
    final contact = await ContactRepository(_db).getContactByDeviceId(deviceId);
    if (contact == null) return false;
    try {
      return await _e2ee.hasSession(deviceId);
    } catch (_) {
      return false;
    }
  }

  /// Records a group member as a contact reachable only inside groups,
  /// unless they are already a contact. Refuses a changed identity key.
  Future<void> _rememberMember(GroupMember member) async {
    final contacts = ContactRepository(_db);
    final existing = await contacts.getContactByIdentityId(member.identityId);
    if (existing != null) {
      if (existing.identityPublicKey != member.identityPublicKey) {
        throw IdentityKeyChangedException(
          identityId: member.identityId,
          storedPublicKey: existing.identityPublicKey,
          receivedPublicKey: member.identityPublicKey,
        );
      }
      await contacts.upsertContactDevice(
        contactId: existing.contactId,
        deviceId: member.deviceId,
        identityPublicKey: member.identityPublicKey,
      );
      return;
    }
    final now = DateTime.now().toUtc().toIso8601String();
    final contactId = 'contact_${member.identityId}';
    await _db.into(_db.contacts).insert(
          ContactsCompanion.insert(
            contactId: contactId,
            identityId: member.identityId,
            displayName: member.displayName,
            identityPublicKey: member.identityPublicKey,
            trustState: const Value('group'),
            createdAt: now,
            updatedAt: now,
          ),
        );
    await contacts.upsertContactDevice(
      contactId: contactId,
      deviceId: member.deviceId,
      identityPublicKey: member.identityPublicKey,
    );
  }

  Future<void> _onIntro(
    String senderDeviceId,
    String groupId,
    Map<String, dynamic> content,
  ) async {
    final group = await _groups.group(groupId);
    if (group == null || !group.isActive) return;
    final bundle = content['bundle'];
    if (bundle is! String || bundle.isEmpty || bundle.length > 16384) return;
    final me = await _myDevice();

    final to = content['to'];
    if (to is String && group.adminDeviceId == me) {
      // As admin: pass it on, between two members of this group only.
      if (await _groups.member(groupId, senderDeviceId) == null) return;
      if (await _groups.member(groupId, to) == null) return;
      await _sendTo(to, {
        'kind': 'group_intro',
        'group': groupId,
        'from': senderDeviceId,
        'bundle': bundle,
      });
      return;
    }

    final from = content['from'];
    if (from is! String || senderDeviceId != group.adminDeviceId) return;
    final member = await _groups.member(groupId, from);
    if (member == null || from == me) return;
    // libsignal accepts the bundle only if it is signed by the identity key
    // the admin announced for this member.
    await _e2ee.pinIdentity(from, member.identityPublicKey);
    await _rememberMember(member);
    await _e2ee.startSession(from, bundle);
    await MeyaMessageService.instance.sendSessionInit(from);
    await MeyaMessageService.instance.catchUpGroupMember(from);
    _changes.add(groupId);
  }

  Future<void> _onLeave(String senderDeviceId, String groupId) async {
    final group = await _groups.group(groupId);
    if (group == null || !group.isActive || !await isAdmin(group)) return;
    if (await _groups.member(groupId, senderDeviceId) == null) return;
    await removeMember(groupId, senderDeviceId);
  }

  /// A session with [deviceId] just started (the other side of an
  /// introduction): send the messages they missed.
  Future<void> sessionStarted(String deviceId) async {
    if ((await _groups.activeGroupsWith(deviceId)).isEmpty) return;
    await MeyaMessageService.instance.catchUpGroupMember(deviceId);
    for (final group in await _groups.activeGroupsWith(deviceId)) {
      _changes.add(group.groupId);
    }
  }
}
