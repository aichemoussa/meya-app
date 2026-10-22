import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meya/database/contact_repository.dart';
import 'package:meya/database/meya_database.dart';
import 'package:meya/services/meya_message_service.dart';
import 'package:meya/services/meya_pairing_service.dart';

import 'message_service_test.dart' show MarkingE2ee, localDevice, peerDevice;

void main() {
  late MeyaDatabase database;
  late MarkingE2ee e2ee;
  late List<Map<String, dynamic>> sent;
  late Contact peer;

  setUp(() async {
    database = MeyaDatabase.forTesting(NativeDatabase.memory());
    e2ee = MarkingE2ee()..sessions.add(peerDevice);
    sent = [];
    MeyaMessageService.instance.configureForTesting(
      database: database,
      e2ee: e2ee,
      localDeviceId: () async => localDevice,
      send: (message) async => sent.add(message),
    );
    final contacts = ContactRepository(database);
    peer = await contacts.upsertTrustedContact(
      contactId: 'contact_peer',
      identityId: 'peer',
      displayName: 'Grandma',
      identityPublicKey: 'peer-key',
      updatedAt: 't',
    );
    await contacts.upsertContactDevice(
      contactId: 'contact_peer',
      deviceId: peerDevice,
      identityPublicKey: 'peer-key',
    );
  });

  tearDown(() => database.close());

  Object? notifyOf(Map<String, dynamic> message) =>
      (message['envelope'] as Map<String, dynamic>)['notify'];

  group('wake-up hints', () {
    test('a shown message wakes the other phone', () async {
      await MeyaMessageService.instance.sendText(peer, 'Hello');
      expect(notifyOf(sent.single), 'message');
    });

    test('a call offer wakes the other phone as a call', () async {
      await MeyaMessageService.instance
          .sendSilent(peer, {'kind': 'call_offer', 'call_id': 'c1'});
      expect(notifyOf(sent.single), 'call');
    });

    test('silent updates never wake a phone', () async {
      for (final kind in ['call_end', 'profile', 'call_answer', 'receipt', 'edit']) {
        sent.clear();
        await MeyaMessageService.instance.sendSilent(peer, {'kind': kind});
        expect(notifyOf(sent.single), isNull, reason: kind);
      }
    });

    test('a new status or reaction wakes the other phone as activity', () async {
      await MeyaMessageService.instance.sendSilent(peer, {'kind': 'status'});
      await MeyaMessageService.instance
          .sendSilent(peer, {'kind': 'reaction', 'target': 'm1', 'emoji': '❤️'});
      expect(sent.map(notifyOf), ['activity', 'activity']);
    });

    test('removing a reaction does not wake a phone', () async {
      await MeyaMessageService.instance
          .sendSilent(peer, {'kind': 'reaction', 'target': 'm1', 'emoji': ''});
      expect(notifyOf(sent.single), isNull);
    });

    test('receipts never wake a phone', () async {
      final content = utf8.encode(
        jsonEncode({'v': 1, 'kind': 'text', 'id': 'm1', 'text': 'Hi'}),
      );
      await MeyaMessageService.instance.handleIncoming(peerDevice, {
        'type': 'chat',
        'v': 1,
        'message_type': 2,
        'body': base64Encode(
          // MarkingE2ee's ciphertext format.
          Uint8List.fromList([0xEE, ...content.map((b) => b ^ 0x5A)]),
        ),
      });
      await Future<void>.delayed(Duration.zero);
      // The delivered receipt went out, unmarked.
      expect(sent, isNotEmpty);
      for (final message in sent) {
        expect(notifyOf(message), isNull);
      }
    });

    test('the invitation hint is on the envelope, not inside the request', () {
      // sendConnectionRequest adds notify: 'invite' to the envelope only.
      final request = MeyaPairingService.buildConnectionRequest(
        requestId: 'req_1',
        senderDeviceId: localDevice,
        identityId: 'identity-local',
        identityPublicKey: 'key',
      );
      expect(request.containsKey('notify'), isFalse);
    });
  });

  group('notification text', () {
    test('an incoming message names the contact and previews it', () async {
      final events = <IncomingMessage>[];
      final subscription =
          MeyaMessageService.instance.incoming.listen(events.add);
      addTearDown(subscription.cancel);

      final content = utf8.encode(
        jsonEncode({'v': 1, 'kind': 'text', 'id': 'm1', 'text': 'Lunch?'}),
      );
      await MeyaMessageService.instance.handleIncoming(peerDevice, {
        'type': 'chat',
        'v': 1,
        'message_type': 2,
        'body': base64Encode(
          Uint8List.fromList([0xEE, ...content.map((b) => b ^ 0x5A)]),
        ),
      });
      await Future<void>.delayed(Duration.zero);

      expect(events.single.title, 'Grandma');
      expect(events.single.body, 'Lunch?');
      expect(events.single.conversationId, 'direct_contact_peer');
    });

    test('a reaction to my own message is announced, not to theirs', () async {
      Map<String, dynamic> wire(Map<String, Object> content) {
        final bytes = utf8.encode(jsonEncode({'v': 1, ...content}));
        return {
          'type': 'chat',
          'v': 1,
          'message_type': 2,
          'body': base64Encode(
            Uint8List.fromList([0xEE, ...bytes.map((b) => b ^ 0x5A)]),
          ),
        };
      }

      // One message of mine, one of theirs.
      await MeyaMessageService.instance.sendText(peer, 'Mine');
      final mine = (await MeyaMessageService.instance.history(peer)).single.id;
      await MeyaMessageService.instance.handleIncoming(
        peerDevice,
        wire({'kind': 'text', 'id': 'theirs', 'text': 'Theirs'}),
      );

      final events = <IncomingMessage>[];
      final subscription =
          MeyaMessageService.instance.incoming.listen(events.add);
      addTearDown(subscription.cancel);

      for (final target in [mine, 'theirs']) {
        await MeyaMessageService.instance.handleIncoming(
          peerDevice,
          wire({'kind': 'reaction', 'id': 'r-$target', 'target': target, 'emoji': '❤️'}),
        );
      }
      await Future<void>.delayed(Duration.zero);

      expect(events.single.title, 'Grandma');
      expect(events.single.body, 'Reacted ❤️ to your message');
    });

    test('previews say what kind of message it is', () {
      String preview(String kind, [Map<String, dynamic> extra = const {}]) =>
          MeyaMessageService.previewOf(kind, {'kind': kind, ...extra});

      expect(preview('text', {'text': '  Hi  '}), 'Hi');
      expect(preview('voice'), 'Voice message');
      expect(preview('image'), 'Photo');
      expect(preview('image', {'text': 'Look'}), 'Look');
      expect(preview('video'), 'Video');
      expect(preview('file', {'media': {'name': 'menu.pdf'}}), 'menu.pdf');
      expect(preview('file'), 'File');
      expect(preview('call_invite'), 'Planned call');
      expect(preview('unknown'), '');
    });
  });
}
