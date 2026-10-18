import 'dart:convert';
import 'dart:typed_data';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meya/database/contact_repository.dart';
import 'package:meya/database/group_repository.dart';
import 'package:meya/database/meya_database.dart';
import 'package:meya/services/meya_e2ee.dart';
import 'package:meya/services/meya_group_service.dart';
import 'package:meya/services/meya_message_service.dart';

/// Stand-in engine: marks ciphertext and tracks sessions and pinned keys.
/// Real encryption is covered by the Rust engine's own tests.
class FakeE2ee implements E2eeOperations {
  final String key;
  final sessions = <String>{};
  final pinned = <String, String>{};

  FakeE2ee(this.key);

  static Uint8List mark(Uint8List data) =>
      Uint8List.fromList([0xEE, ...data.map((b) => b ^ 0x5A)]);
  static Uint8List unmark(Uint8List data) {
    if (data.isEmpty || data.first != 0xEE) throw StateError('not ciphertext');
    return Uint8List.fromList(data.skip(1).map((b) => b ^ 0x5A).toList());
  }

  @override
  String? get identityKeyBase64 => key;
  @override
  Future<String> open() async => key;
  @override
  Future<void> pinIdentity(String deviceId, String identityKey) async {
    final existing = pinned[deviceId];
    if (existing != null && existing != identityKey) {
      throw StateError('a different key is pinned');
    }
    pinned[deviceId] = identityKey;
  }

  /// The bundle names the identity that signed it, so the receiving side
  /// can check it against the pinned key the way libsignal does.
  @override
  Future<String> createPreKeyBundle() async => 'bundle-signed-by:$key';
  @override
  Future<void> startSession(String deviceId, String bundle) async {
    if (bundle != 'bundle-signed-by:${pinned[deviceId]}') {
      throw StateError('bundle identity does not match the pinned key');
    }
    sessions.add(deviceId);
  }

  @override
  Future<bool> hasSession(String deviceId) async => sessions.contains(deviceId);
  @override
  Future<E2eeCiphertext> encrypt(String deviceId, Uint8List plaintext) async {
    if (!sessions.contains(deviceId)) throw StateError('no session');
    return E2eeCiphertext(messageType: 2, body: mark(plaintext));
  }

  @override
  Future<Uint8List> decrypt(String deviceId, int type, Uint8List body) async {
    // A first message on a new session establishes it on this side too.
    if (pinned.containsKey(deviceId)) sessions.add(deviceId);
    return unmark(body);
  }

  @override
  Future<void> forget(String deviceId) async => sessions.remove(deviceId);
  @override
  Future<Uint8List> sealLocal(Uint8List plaintext, String context) async =>
      mark(plaintext);
  @override
  Future<Uint8List> openLocal(Uint8List sealed, String context) async =>
      unmark(sealed);
}

class Phone {
  final String name;
  final String device;
  final MeyaDatabase db;
  final FakeE2ee e2ee;

  Phone(this.name, this.device)
      : db = MeyaDatabase.forTesting(NativeDatabase.memory()),
        e2ee = FakeE2ee('key-$name');

  String get identity => 'id-$name';
}

void main() {
  // Three phones in one test: separate in-memory databases on purpose.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late Phone amina, bilal, chloe;
  late List<(String from, Map<String, dynamic> message)> network;

  Future<void> use(Phone phone) async {
    final messages = MeyaMessageService.instance;
    messages.configureForTesting(
      database: phone.db,
      e2ee: phone.e2ee,
      localDeviceId: () async => phone.device,
      send: (message) async => network.add((phone.device, message)),
    );
    final groups = MeyaGroupService.instance;
    groups.configureForTesting(
      database: phone.db,
      e2ee: phone.e2ee,
      localDeviceId: () async => phone.device,
    );
    for (final kind in MeyaGroupService.kinds) {
      messages.setSilentHandler(kind, groups.handleIncoming);
    }
    messages.setSilentHandler('session_init', (contact, deviceId, _) async {
      await groups.sessionStarted(deviceId);
    });
  }

  Phone byDevice(String device) =>
      [amina, bilal, chloe].firstWhere((p) => p.device == device);

  /// Delivers everything in flight, including whatever that triggers.
  Future<void> deliverAll() async {
    var guard = 0;
    while (network.isNotEmpty) {
      if (++guard > 500) fail('message loop');
      final (from, message) = network.removeAt(0);
      final envelope = message['envelope'] as Map<String, dynamic>;
      final to = byDevice(envelope['recipient_device_id'] as String);
      final payload = jsonDecode(utf8.decode(base64Decode(envelope['payload'])))
          as Map<String, dynamic>;
      await use(to);
      if (payload['type'] == 'chat') {
        await MeyaMessageService.instance.handleIncoming(from, payload);
      } else {
        await MeyaMessageService.instance.handleBlobChunk(from, payload);
      }
    }
  }

  Future<Contact> connect(Phone owner, Phone other) async {
    final contacts = ContactRepository(owner.db);
    final contact = await contacts.upsertTrustedContact(
      contactId: 'contact_${other.identity}',
      identityId: other.identity,
      displayName: other.name,
      identityPublicKey: other.e2ee.key,
      updatedAt: 't',
    );
    await contacts.upsertContactDevice(
      contactId: contact.contactId,
      deviceId: other.device,
      identityPublicKey: other.e2ee.key,
    );
    owner.e2ee.pinned[other.device] = other.e2ee.key;
    owner.e2ee.sessions.add(other.device);
    return contact;
  }

  setUp(() async {
    network = [];
    amina = Phone('Amina', 'device-aaaa');
    bilal = Phone('Bilal', 'device-bbbb');
    chloe = Phone('Chloe', 'device-cccc');
    for (final phone in [amina, bilal, chloe]) {
      await phone.db.into(phone.db.accounts).insert(
            AccountsCompanion.insert(
              accountId: phone.identity,
              meyaId: 'meya-${phone.name}',
              name: phone.name,
              username: phone.name.toLowerCase(),
              createdAt: 't',
              identityPublicKey: phone.e2ee.key,
            ),
          );
    }
    // Amina knows both; Bilal and Chloe only know Amina.
    await connect(amina, bilal);
    await connect(amina, chloe);
    await connect(bilal, amina);
    await connect(chloe, amina);
  });

  tearDown(() async {
    for (final phone in [amina, bilal, chloe]) {
      await phone.db.close();
    }
  });

  Future<String> createFamily() async {
    await use(amina);
    final contacts = await ContactRepository(amina.db).getTrustedContacts();
    final groupId = await MeyaGroupService.instance.create('Family', contacts);
    await deliverAll();
    return groupId;
  }

  Future<List<ChatMessageView>> historyOn(Phone phone, String groupId) async {
    await use(phone);
    return MeyaMessageService.instance
        .historyFor(GroupRepository.conversationIdFor(groupId));
  }

  test('creating a group reaches every member, and members who were not '
      'connected are introduced through the admin', () async {
    final groupId = await createFamily();

    for (final phone in [amina, bilal, chloe]) {
      final group = await GroupRepository(phone.db).group(groupId);
      expect(group?.name, 'Family', reason: phone.name);
      expect(group?.adminDeviceId, amina.device);
      expect(await GroupRepository(phone.db).members(groupId), hasLength(3));
    }
    // Bilal and Chloe now have a session with each other.
    expect(bilal.e2ee.sessions, contains(chloe.device));
    expect(chloe.e2ee.sessions, contains(bilal.device));
    // ...but they are not each other's connections.
    expect(await ContactRepository(bilal.db).getTrustedContacts(), hasLength(1));
  });

  test('a group message is encrypted for each member and shown with the '
      'sender name', () async {
    final groupId = await createFamily();

    await use(bilal);
    await MeyaMessageService.instance.sendGroupText(groupId, 'Dinner at 8?');
    // One envelope per other member, none in plaintext.
    expect(network, hasLength(2));
    for (final (_, message) in network) {
      final envelope = message['envelope'] as Map<String, dynamic>;
      expect(utf8.decode(base64Decode(envelope['payload'])), isNot(contains('Dinner')));
    }
    await deliverAll();

    for (final phone in [amina, chloe]) {
      final history = await historyOn(phone, groupId);
      expect(history.single.text, 'Dinner at 8?', reason: phone.name);
      expect(history.single.senderDeviceId, bilal.device);
      expect(history.single.isMine, isFalse);
    }
    final mine = await historyOn(bilal, groupId);
    expect(mine.single.isMine, isTrue);
    expect(mine.single.state, 'sent');
  });

  test('messages from people outside the group are dropped', () async {
    final groupId = await createFamily();
    final outsider = Phone('Dan', 'device-dddd');
    addTearDown(outsider.db.close);
    // Chloe knows Dan, but Dan is not in the group.
    await connect(chloe, outsider);

    await use(chloe);
    final content = utf8.encode(jsonEncode({
      'v': 1,
      'kind': 'text',
      'id': 'forged1',
      'text': 'Let me in',
      'group': groupId,
    }));
    await MeyaMessageService.instance.handleIncoming(outsider.device, {
      'type': 'chat',
      'v': 1,
      'message_type': 2,
      'body': base64Encode(FakeE2ee.mark(Uint8List.fromList(content))),
    });
    expect(await historyOn(chloe, groupId), isEmpty);
  });

  test('only the admin can change the group', () async {
    final groupId = await createFamily();

    // Bilal pretends to be admin and renames the group for Chloe.
    await use(chloe);
    final chloeKnowsBilal =
        await ContactRepository(chloe.db).getContactByDeviceId(bilal.device);
    await MeyaGroupService.instance.handleIncoming(chloeKnowsBilal!, bilal.device, {
      'kind': 'group_update',
      'group': groupId,
      'name': 'Hijacked',
      'admin': bilal.device,
      'revision': 99,
      'members': [],
    });
    expect((await GroupRepository(chloe.db).group(groupId))?.name, 'Family');

    await use(bilal);
    expect(
      () => MeyaGroupService.instance.rename(groupId, 'Mine now'),
      throwsStateError,
    );
  });

  test('someone met only through a group cannot send direct messages',
      () async {
    await createFamily();
    await use(chloe);
    final content = utf8.encode(
      jsonEncode({'v': 1, 'kind': 'text', 'id': 'direct1', 'text': 'Hi, just us'}),
    );
    await MeyaMessageService.instance.handleIncoming(bilal.device, {
      'type': 'chat',
      'v': 1,
      'message_type': 2,
      'body': base64Encode(FakeE2ee.mark(Uint8List.fromList(content))),
    });
    final rows = await chloe.db.select(chloe.db.messages).get();
    expect(rows.where((m) => m.messageId == 'direct1'), isEmpty);
  });

  test('a removed member stops receiving and the rest carry on', () async {
    final groupId = await createFamily();

    await use(amina);
    await MeyaGroupService.instance.removeMember(groupId, chloe.device);
    await deliverAll();
    expect((await GroupRepository(chloe.db).group(groupId))?.isActive, isFalse);

    await use(bilal);
    await MeyaMessageService.instance.sendGroupText(groupId, 'Just us two now');
    await deliverAll();
    expect(await historyOn(chloe, groupId), isEmpty);
    expect((await historyOn(amina, groupId)).single.text, 'Just us two now');
  });

  test('leaving: a member asks the admin, the admin removes them', () async {
    final groupId = await createFamily();

    await use(bilal);
    await MeyaGroupService.instance.leave(groupId);
    await deliverAll();

    expect((await GroupRepository(bilal.db).group(groupId))?.isActive, isFalse);
    final members = await GroupRepository(amina.db).members(groupId);
    expect(members.map((m) => m.deviceId), isNot(contains(bilal.device)));
    final chloeView = await GroupRepository(chloe.db).members(groupId);
    expect(chloeView.map((m) => m.deviceId), isNot(contains(bilal.device)));
  });

  test('when the admin leaves, the next member becomes admin', () async {
    final groupId = await createFamily();

    await use(amina);
    await MeyaGroupService.instance.leave(groupId);
    await deliverAll();

    for (final phone in [bilal, chloe]) {
      final group = await GroupRepository(phone.db).group(groupId);
      expect(group?.isActive, isTrue, reason: phone.name);
      expect(group?.adminDeviceId, isNot(amina.device));
      expect(await GroupRepository(phone.db).members(groupId), hasLength(2));
    }
    expect((await GroupRepository(amina.db).group(groupId))?.isActive, isFalse);
  });
}
