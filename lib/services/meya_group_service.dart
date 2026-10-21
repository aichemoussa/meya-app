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
/// session (pairwise fan-out). Admins announce its name and members, and add
/// only people they verified in person (their own MEYA connections), with
/// each member's identity key.
///
/// The owner (the person who created the group) is always an admin and can
/// make other members admins. Any admin can rename the group, add and remove
/// people and make others admins; nobody but the owner can remove the owner
/// or hand the group over.
///
/// Members who are not connected with each other are introduced through the
/// admin who announced the change: one of them sends a one-time pre-key
/// bundle to that admin, who forwards it. libsignal only accepts the bundle
/// if it is signed by the identity key the admin announced, so admins vouch
/// for who is who, and nobody else (the relay included) can read or change
/// the messages.
///
/// Silent messages (sent over existing sessions, never shown):
///   group_update  admin -> each member: name, admin (owner), admins,
///                 revision, members
///   group_intro   member -> admin {to, bundle}; admin -> member {from, bundle}
///   group_leave   member -> admins: please remove me
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
            isAdmin: row.isAdmin,
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

  /// The devices allowed to change [group]: the owner and every admin.
  Future<Set<String>> admins(MeyaGroup group) async => {
        group.adminDeviceId,
        for (final member in await _groups.members(group.groupId))
          if (member.isAdmin) member.deviceId,
      };

  Future<bool> isAdmin(MeyaGroup group) async =>
      (await admins(group)).contains(await _localDeviceId());

  Future<bool> isOwner(MeyaGroup group) async =>
      group.adminDeviceId == await _localDeviceId();

  /// The display names of a group's members by device, for message bubbles.
  Future<Map<String, String>> memberNames(String groupId) async => {
        for (final member in await _groups.members(groupId))
          member.deviceId: member.displayName,
      };

  // ------------------------------------------------------- admin actions

  /// Creates a group with some of your connections. You are its owner.
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
    final group = await _groups.group(groupId);
    if (group != null && group.adminDeviceId == deviceId) {
      throw StateError(tr('Only the group admin can change the group.'));
    }
    final before = _infos(await _groups.members(groupId));
    final removed = before.where((m) => m.deviceId == deviceId).toList();
    final after = before.where((m) => m.deviceId != deviceId).toList();
    await _change(groupId, members: after, alsoTell: removed);
  }

  /// Makes a member an admin, or an admin a member again. The owner always
  /// stays an admin.
  Future<void> setAdmin(String groupId, String deviceId, bool admin) async {
    final group = await _groups.group(groupId);
    if (group != null && group.adminDeviceId == deviceId) {
      throw StateError(tr('Only the group admin can change the group.'));
    }
    final members = [
      for (final member in _infos(await _groups.members(groupId)))
        member.deviceId == deviceId ? member.withAdmin(admin) : member,
    ];
    await _change(groupId, members: members);
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

  /// Leaves the group. If you are the owner, the group is handed to the
  /// earliest admin to join (or, with no other admin, the earliest member).
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
          final next = rest.firstWhere((m) => m.isAdmin, orElse: () => rest.first);
          await _groups.save(
            groupId: groupId,
            name: group.name,
            adminDeviceId: next.deviceId,
            revision: group.revision + 1,
            members: _infos(rest),
            isActive: false,
          );
          await _announce(groupId, from: me);
        }
      } else {
        // Any admin can remove you; ask them all in case some are offline.
        for (final admin in await admins(group)) {
          if (admin == me) continue;
          try {
            await _sendTo(admin, {'kind': 'group_leave', 'group': groupId});
          } catch (error) {
            debugPrint('MEYA group: leave not sent to one admin ($error).');
          }
        }
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
      'admins': [
        for (final m in members)
          if (m.isAdmin || m.deviceId == group.adminDeviceId) m.deviceId,
      ],
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
    // Older versions send only the owner.
    final listed = content['admins'];
    final announcedAdmins = <String>{
      admin,
      if (listed is List) ...listed.whereType<String>(),
    };
    final existing = await _groups.group(groupId);
    if (existing == null) {
      // A new group: only from someone you verified in person, who must be
      // one of its admins.
      if (contact.trustState != 'trusted' ||
          !announcedAdmins.contains(senderDeviceId)) {
        return;
      }
    } else {
      // Changes come from a current admin; only the owner hands over.
      if (!(await admins(existing)).contains(senderDeviceId)) return;
      if (revision <= existing.revision) return;
      if (admin != existing.adminDeviceId &&
          senderDeviceId != existing.adminDeviceId) {
        return;
      }
    }

    final members = <GroupMemberInfo>[];
    for (final item in list.take(maxMembers)) {
      final info = GroupMemberInfo.fromContent(item);
      if (info != null && members.every((m) => m.deviceId != info.deviceId)) {
        members.add(info.withAdmin(announcedAdmins.contains(info.deviceId)));
      }
    }
    final me = await _myDevice();
    final stillIn = members.any((m) => m.deviceId == me);
    // The owner stays in the group unless they hand it over themselves.
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
    if (stillIn) await _introduce(groupId, via: senderDeviceId);
  }

  String _cleanNameOr(String name, String fallback) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return fallback;
    return trimmed.length > maxNameLength
        ? trimmed.substring(0, maxNameLength)
        : trimmed;
  }

  /// For each member this device has no session with, the one of the pair
  /// with the smaller device ID sends a pre-key bundle through [via], the
  /// admin who announced the change (they have a session with everyone).
  Future<void> _introduce(String groupId, {required String via}) async {
    final group = await _groups.group(groupId);
    if (group == null || !group.isActive) return;
    final me = await _myDevice();
    if (via == me) return;
    for (final member in await _groups.members(groupId)) {
      final other = member.deviceId;
      if (other == me || other == via) continue;
      if (await _hasSession(other)) continue;
      if (me.compareTo(other) > 0) continue; // They introduce themselves.
      if (!_introduced.add('$groupId|$me|$other')) continue;
      try {
        await _e2ee.pinIdentity(other, member.identityPublicKey);
        await _rememberMember(member);
        final bundle = await _e2ee.createPreKeyBundle();
        await _sendTo(via, {
          'kind': 'group_intro',
          'group': groupId,
          'to': other,
          'bundle': bundle,
        });
      } catch (error) {
        _introduced.remove('$groupId|$me|$other');
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
    final groupAdmins = await admins(group);

    final to = content['to'];
    if (to is String && groupAdmins.contains(me)) {
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
    if (from is! String || !groupAdmins.contains(senderDeviceId)) return;
    final member = await _groups.member(groupId, from);
    if (member == null || from == me) return;
    // libsignal accepts the bundle only if it is signed by the identity key
    // the admins announced for this member.
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
