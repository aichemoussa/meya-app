import 'dart:convert';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meya/database/contact_repository.dart';
import 'package:meya/database/meya_database.dart';
import 'package:meya/database/message_repository.dart';
import 'package:meya/services/meya_e2ee.dart';
import 'package:meya/services/meya_message_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Marks "ciphertext" so tests can read what was sent. Real encryption is
/// covered by the Rust engine's tests.
class MarkingE2ee implements E2eeOperations {
  static Uint8List mark(Uint8List data) =>
      Uint8List.fromList([0xEE, ...data.map((b) => b ^ 0x5A)]);
  static Uint8List unmark(Uint8List data) {
    if (data.isEmpty || data.first != 0xEE) throw StateError('not ciphertext');
    return Uint8List.fromList(data.skip(1).map((b) => b ^ 0x5A).toList());
  }

  @override
  String? get identityKeyBase64 => 'local-key';
  @override
  Future<String> open() async => 'local-key';
  @override
  Future<void> pinIdentity(String deviceId, String key) async {}
  @override
  Future<String> createPreKeyBundle() async => 'bundle';
  @override
  Future<void> startSession(String deviceId, String bundle) async {}
  @override
  Future<bool> hasSession(String deviceId) async => true;
  @override
  Future<E2eeCiphertext> encrypt(String deviceId, Uint8List plaintext) async =>
      E2eeCiphertext(messageType: 2, body: mark(plaintext));
  @override
  Future<Uint8List> decrypt(String deviceId, int type, Uint8List body) async =>
      unmark(body);
  @override
  Future<void> forget(String deviceId) async {}
  @override
  Future<Uint8List> sealLocal(Uint8List plaintext, String context) async =>
      mark(plaintext);
  @override
  Future<Uint8List> openLocal(Uint8List sealed, String context) async =>
      unmark(sealed);
}

const me = 'device-me';
const ana = 'device-ana';
const bob = 'device-bob';

void main() {
  final service = MeyaMessageService.instance;
  late MeyaDatabase database;
  late List<Map<String, dynamic>> sent;
  late bool online;
  late Contact anaContact;
  late Contact bobContact;

  /// The decrypted content of everything sent, in order.
  List<Map<String, dynamic>> sentContents() => [
        for (final message in sent)
          if (message['envelope'] is Map)
            () {
              final payload = jsonDecode(utf8.decode(base64Decode(
                (message['envelope'] as Map)['payload'] as String,
              ))) as Map<String, dynamic>;
              if (payload['type'] != 'chat') return <String, dynamic>{};
              return jsonDecode(utf8.decode(MarkingE2ee.unmark(
                base64Decode(payload['body'] as String),
              ))) as Map<String, dynamic>;
            }(),
      ];

  List<Map<String, dynamic>> sentOfKind(String kind) =>
      sentContents().where((content) => content['kind'] == kind).toList();

  Future<void> receive(String from, Map<String, Object?> content) =>
      service.handleIncoming(from, {
        'type': 'chat',
        'v': 1,
        'message_type': 2,
        'body': base64Encode(MarkingE2ee.mark(
          Uint8List.fromList(utf8.encode(jsonEncode({'v': 1, ...content}))),
        )),
      });

  Future<ChatMessageView> only(Contact contact) async =>
      (await service.history(contact)).single;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await service.loadSettings();
    database = MeyaDatabase.forTesting(NativeDatabase.memory());
    sent = [];
    online = true;
    service.activeConversationId = null;
    service.configureForTesting(
      database: database,
      e2ee: MarkingE2ee(),
      localDeviceId: () async => me,
      send: (message) async {
        if (!online) throw StateError('relay offline');
        sent.add(message);
      },
    );
    final contacts = ContactRepository(database);
    for (final (id, device, name) in [
      ('contact_ana', ana, 'Ana'),
      ('contact_bob', bob, 'Bob'),
    ]) {
      await contacts.upsertTrustedContact(
        contactId: id,
        identityId: id,
        displayName: name,
        identityPublicKey: '$id-key',
        updatedAt: 't',
      );
      await contacts.upsertContactDevice(
        contactId: id,
        deviceId: device,
        identityPublicKey: '$id-key',
      );
    }
    anaContact = (await contacts.getContactById('contact_ana'))!;
    bobContact = (await contacts.getContactById('contact_bob'))!;
  });

  tearDown(() => database.close());

  group('delivery states', () {
    test('a received message is acknowledged as delivered', () async {
      await receive(ana, {'kind': 'text', 'id': 'm1', 'text': 'Salut'});
      await pumpEventQueue();
      final receipts = sentOfKind('receipt');
      expect(receipts.single['status'], 'delivered');
      expect(receipts.single['ids'], ['m1']);
    });

    test('receipts move my message to delivered, then read', () async {
      await service.sendText(anaContact, 'Hello');
      final id = (await only(anaContact)).id;
      expect((await only(anaContact)).state, 'sent');

      await receive(ana, {'kind': 'receipt', 'id': 'r1', 'status': 'delivered', 'ids': [id]});
      expect((await only(anaContact)).state, 'delivered');
      await receive(ana, {'kind': 'receipt', 'id': 'r2', 'status': 'read', 'ids': [id]});
      expect((await only(anaContact)).state, 'read');

      // A late "delivered" never moves it back.
      await receive(ana, {'kind': 'receipt', 'id': 'r3', 'status': 'delivered', 'ids': [id]});
      expect((await only(anaContact)).state, 'read');
    });

    test('receipts from someone else are ignored', () async {
      await service.sendText(anaContact, 'Hello');
      final id = (await only(anaContact)).id;
      await receive(bob, {'kind': 'receipt', 'id': 'r1', 'status': 'read', 'ids': [id]});
      expect((await only(anaContact)).state, 'sent');
    });

    test('with read receipts off, none are sent and none are shown', () async {
      await service.setReadReceipts(false);
      await service.sendText(anaContact, 'Hello');
      final id = (await only(anaContact)).id;
      await receive(ana, {'kind': 'receipt', 'id': 'r1', 'status': 'read', 'ids': [id]});
      expect((await only(anaContact)).state, 'delivered');

      await receive(ana, {'kind': 'text', 'id': 'm2', 'text': 'Hi'});
      sent.clear();
      await service.markConversationRead(anaContact);
      await pumpEventQueue();
      expect(sentOfKind('receipt').where((r) => r['status'] == 'read'), isEmpty);
    });

    test('opening the chat marks it read and sends a read receipt', () async {
      await receive(ana, {'kind': 'text', 'id': 'm1', 'text': 'One'});
      await receive(ana, {'kind': 'text', 'id': 'm2', 'text': 'Two'});
      final id = MessageRepository.conversationIdFor('contact_ana');
      expect((await service.conversationStates())[id]!.unreadCount, 2);

      await pumpEventQueue();
      sent.clear();
      await service.markConversationRead(anaContact);
      await pumpEventQueue();
      expect((await service.conversationStates())[id]!.unreadCount, 0);
      final read = sentOfKind('receipt').single;
      expect(read['status'], 'read');
      expect(read['ids'], unorderedEquals(['m1', 'm2']));
    });

    test('messages in the open chat do not count as unread', () async {
      service.activeConversationId =
          MessageRepository.conversationIdFor('contact_ana');
      await receive(ana, {'kind': 'text', 'id': 'm1', 'text': 'One'});
      final id = MessageRepository.conversationIdFor('contact_ana');
      expect((await service.conversationStates())[id]!.unreadCount, 0);
    });
  });

  group('offline', () {
    test('reactions made offline wait in the outbox and go out later',
        () async {
      await receive(ana, {'kind': 'text', 'id': 'm1', 'text': 'Hi'});
      await pumpEventQueue();
      online = false;
      await service.react(anaContact, 'm1', '❤️');
      expect(await database.select(database.outbox).get(), hasLength(1));

      online = true;
      sent.clear();
      await service.retryPending();
      expect(sentOfKind('reaction').single['emoji'], '❤️');
      expect(await database.select(database.outbox).get(), isEmpty);
    });

    test('a resent message arrives only once', () async {
      await receive(ana, {'kind': 'text', 'id': 'm1', 'text': 'Hi'});
      await receive(ana, {'kind': 'text', 'id': 'm1', 'text': 'Hi'});
      expect(await service.history(anaContact), hasLength(1));
    });
  });

  group('reactions, replies, pins and favourites', () {
    test('reactions from both people are counted', () async {
      await receive(ana, {'kind': 'text', 'id': 'm1', 'text': 'Hi'});
      await service.react(anaContact, 'm1', '👍');
      await receive(ana, {'kind': 'reaction', 'id': 'x', 'target': 'm1', 'emoji': '👍'});
      var message = await only(anaContact);
      expect(message.reactions, {'👍': 2});
      expect(message.myReaction, '👍');

      await service.react(anaContact, 'm1', '');
      message = await only(anaContact);
      expect(message.reactions, {'👍': 1});
      expect(message.myReaction, isNull);
    });

    test('a reaction to a message in another chat is ignored', () async {
      await receive(ana, {'kind': 'text', 'id': 'm1', 'text': 'Hi'});
      await receive(bob, {'kind': 'reaction', 'id': 'x', 'target': 'm1', 'emoji': '😂'});
      expect((await only(anaContact)).reactions, isEmpty);
    });

    test('a reply quotes the original message', () async {
      await receive(ana, {'kind': 'text', 'id': 'm1', 'text': 'Dinner at 8?'});
      final original = await only(anaContact);
      await service.sendText(
        anaContact,
        'Yes!',
        extra: await service.replyTo(anaContact, original),
      );
      final reply = (await service.history(anaContact)).last;
      expect(reply.reply!.id, 'm1');
      expect(reply.reply!.text, 'Dinner at 8?');
      expect(reply.reply!.isMine, isFalse);

      // Ana replies to my message: the quote shows as mine.
      await receive(ana, {
        'kind': 'text',
        'id': 'm3',
        'text': 'Great',
        'reply_to': {'id': reply.id, 'kind': 'text', 'text': 'Yes!', 'author': me},
      });
      expect((await service.history(anaContact)).last.reply!.isMine, isTrue);
    });

    test('pins are shared, favourites stay on this phone', () async {
      await receive(ana, {'kind': 'text', 'id': 'm1', 'text': 'Address: 12 Rue X'});
      sent.clear();
      await service.setPinned(anaContact, 'm1', true);
      await service.setStarred('m1', true);
      final message = await only(anaContact);
      expect(message.pinned, isTrue);
      expect(message.starred, isTrue);
      expect(sentOfKind('pin').single['pinned'], isTrue);
      expect(sentContents().where((c) => c['kind'] == 'star'), isEmpty);
      expect((await service.starredMessages()).single.$2.id, 'm1');
    });
  });

  group('editing and deleting', () {
    test('I can edit my message and Ana sees the edit', () async {
      await service.sendText(anaContact, 'See you at 7');
      final id = (await only(anaContact)).id;
      await service.editMessage(anaContact, id, 'See you at 8');
      final message = await only(anaContact);
      expect(message.text, 'See you at 8');
      expect(message.edited, isTrue);
      expect(sentOfKind('edit').single, containsPair('text', 'See you at 8'));
    });

    test('Ana cannot edit or delete my message', () async {
      await service.sendText(anaContact, 'Mine');
      final id = (await only(anaContact)).id;
      await receive(ana, {'kind': 'edit', 'id': 'e1', 'target': id, 'text': 'Hacked'});
      await receive(ana, {'kind': 'delete', 'id': 'd1', 'target': id});
      final message = await only(anaContact);
      expect(message.text, 'Mine');
      expect(message.isDeleted, isFalse);
    });

    test('Ana can edit and delete her own message', () async {
      await receive(ana, {'kind': 'text', 'id': 'm1', 'text': 'Typo'});
      await receive(ana, {'kind': 'edit', 'id': 'e1', 'target': 'm1', 'text': 'Fixed'});
      expect((await only(anaContact)).text, 'Fixed');
      await receive(ana, {'kind': 'delete', 'id': 'd1', 'target': 'm1'});
      final message = await only(anaContact);
      expect(message.isDeleted, isTrue);
      expect(message.text, isNot(contains('Fixed')));
    });

    test('deleting for everyone leaves a marker; for me removes it', () async {
      await service.sendText(anaContact, 'Oops');
      final id = (await only(anaContact)).id;
      await service.deleteForEveryone(anaContact, id);
      expect((await only(anaContact)).isDeleted, isTrue);
      expect(sentOfKind('delete').single['target'], id);

      await service.deleteForMe(id);
      expect(await service.history(anaContact), isEmpty);
    });

    test('I cannot delete Ana\'s message for everyone', () async {
      await receive(ana, {'kind': 'text', 'id': 'm1', 'text': 'Hi'});
      expect(
        () => service.deleteForEveryone(anaContact, 'm1'),
        throwsStateError,
      );
    });
  });

  group('forward, search, block and chat list', () {
    test('forwarding sends a copy marked as forwarded', () async {
      await receive(ana, {'kind': 'text', 'id': 'm1', 'text': 'Recipe: …'});
      await service.forward(await only(anaContact), bobContact);
      final copy = await only(bobContact);
      expect(copy.text, 'Recipe: …');
      expect(copy.forwarded, isTrue);
      expect(copy.isMine, isTrue);
    });

    test('search finds text in every chat but not deleted messages', () async {
      await receive(ana, {'kind': 'text', 'id': 'm1', 'text': 'Birthday on Sunday'});
      await receive(bob, {'kind': 'text', 'id': 'm2', 'text': 'sunday lunch?'});
      await receive(bob, {'kind': 'text', 'id': 'm3', 'text': 'Sunday gone'});
      await receive(bob, {'kind': 'delete', 'id': 'd', 'target': 'm3'});

      final results = await service.search('SUNDAY');
      expect(results.map((r) => r.$2.id), unorderedEquals(['m1', 'm2']));
      final inBob = await service.search('sunday', contact: bobContact);
      expect(inBob.single.$2.id, 'm2');
    });

    test('a blocked person\'s messages are dropped until unblocked', () async {
      await service.block(anaContact);
      await receive(ana, {'kind': 'text', 'id': 'm1', 'text': 'Hi'});
      expect(await service.history(anaContact), isEmpty);
      expect((await service.blockedContacts()).single.contactId, 'contact_ana');

      await service.unblock(anaContact);
      await receive(ana, {'kind': 'text', 'id': 'm2', 'text': 'Hi again'});
      expect(await service.history(anaContact), hasLength(1));
    });

    test('mute, archive and mark as unread are remembered', () async {
      await service.setMuted(anaContact, true);
      await service.setArchived(anaContact, true);
      await service.setMarkedUnread(anaContact, true);
      final id = MessageRepository.conversationIdFor('contact_ana');
      final state = (await service.conversationStates())[id]!;
      expect(state.isMuted, isTrue);
      expect(state.isArchived, isTrue);
      expect(state.markedUnread, isTrue);
      expect(await service.isMuted(id), isTrue);

      await service.markConversationRead(anaContact);
      expect((await service.conversationStates())[id]!.markedUnread, isFalse);
    });
  });
}
