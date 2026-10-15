import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meya/database/contact_repository.dart';
import 'package:meya/database/meya_database.dart';
import 'package:meya/services/meya_blob_store.dart';
import 'package:meya/services/meya_calendar_service.dart';
import 'package:meya/services/meya_e2ee.dart';
import 'package:meya/services/meya_message_service.dart';
import 'package:meya/services/meya_status_service.dart';

/// Marks ciphertext so tests can tell it apart from plaintext. Real
/// encryption is covered by the Rust engine's own tests.
class MarkingE2ee implements E2eeOperations {
  final sessions = <String>{};

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
  Future<void> startSession(String deviceId, String bundle) async =>
      sessions.add(deviceId);
  @override
  Future<bool> hasSession(String deviceId) async => sessions.contains(deviceId);
  @override
  Future<E2eeCiphertext> encrypt(String deviceId, Uint8List plaintext) async =>
      E2eeCiphertext(messageType: 2, body: mark(plaintext));
  @override
  Future<Uint8List> decrypt(String deviceId, int type, Uint8List body) async =>
      unmark(body);
  @override
  Future<void> forget(String deviceId) async => sessions.remove(deviceId);
  @override
  Future<Uint8List> sealLocal(Uint8List plaintext, String context) async =>
      mark(plaintext);
  @override
  Future<Uint8List> openLocal(Uint8List sealed, String context) async =>
      unmark(sealed);
}

/// Stand-in for AES-256-GCM: authenticated by a fixed tag, keyed XOR.
class FakeBlobCipher implements BlobCipher {
  @override
  Future<Uint8List> seal(Uint8List key, Uint8List plaintext, String blobId) async {
    final out = Uint8List(plaintext.length + 4);
    for (var i = 0; i < plaintext.length; i++) {
      out[i] = plaintext[i] ^ key[i % key.length];
    }
    out.setRange(plaintext.length, out.length, [1, 2, 3, 4]);
    return out;
  }

  @override
  Future<Uint8List> open(Uint8List key, Uint8List ciphertext, String blobId) async {
    final length = ciphertext.length - 4;
    if (length < 0 ||
        !const [1, 2, 3, 4].asMap().entries.every(
              (e) => ciphertext[length + e.key] == e.value,
            )) {
      throw StateError('tampered');
    }
    final out = Uint8List(length);
    for (var i = 0; i < length; i++) {
      out[i] = ciphertext[i] ^ key[i % key.length];
    }
    return out;
  }
}

const localDevice = 'device-local';
const peerDevice = 'device-peer';

Map<String, dynamic> payloadOf(Map<String, dynamic> sent) {
  final envelope = sent['envelope'] as Map<String, dynamic>;
  return jsonDecode(utf8.decode(base64Decode(envelope['payload'] as String)))
      as Map<String, dynamic>;
}

Map<String, dynamic> contentOf(Map<String, dynamic> sent) {
  final payload = payloadOf(sent);
  return jsonDecode(
    utf8.decode(MarkingE2ee.unmark(base64Decode(payload['body'] as String))),
  ) as Map<String, dynamic>;
}

Map<String, dynamic> chatFromPeer(Map<String, Object?> content) => {
      'type': 'chat',
      'v': 1,
      'message_type': 2,
      'body': base64Encode(
        MarkingE2ee.mark(Uint8List.fromList(utf8.encode(jsonEncode(content)))),
      ),
    };

void main() {
  late MeyaDatabase database;
  late MarkingE2ee e2ee;
  late List<Map<String, dynamic>> sent;
  late Contact peer;
  late Directory directory;
  final cipher = FakeBlobCipher();
  final service = MeyaMessageService.instance;

  setUp(() async {
    database = MeyaDatabase.forTesting(NativeDatabase.memory());
    e2ee = MarkingE2ee();
    sent = [];
    directory = await Directory.systemTemp.createTemp('meya_test_');
    MeyaBlobStore.instance.useDirectoryForTesting(directory);
    service.configureForTesting(
      database: database,
      e2ee: e2ee,
      localDeviceId: () async => localDevice,
      send: (message) async => sent.add(message),
      cipher: cipher,
    );

    final contacts = ContactRepository(database);
    peer = await contacts.upsertTrustedContact(
      contactId: 'contact_peer',
      identityId: 'peer',
      displayName: 'Peer',
      identityPublicKey: 'peer-key',
      updatedAt: 't',
    );
    await contacts.upsertContactDevice(
      contactId: 'contact_peer',
      deviceId: peerDevice,
      identityPublicKey: 'peer-key',
    );
    e2ee.sessions.add(peerDevice);
  });

  tearDown(() async {
    await database.close();
    await directory.delete(recursive: true);
  });

  group('attachments', () {
    test('a photo travels as encrypted pieces, then the message with its key',
        () async {
      final photo = Uint8List.fromList(
        List<int>.generate(MeyaBlobStore.chunkBytes * 2 + 10, (i) => i % 251),
      );

      await service.sendAttachment(
        peer,
        kind: 'image',
        bytes: photo,
        mime: 'image/jpeg',
        name: 'photo.jpg',
        caption: 'Hello',
      );

      final kinds = sent.map((m) => payloadOf(m)['type']).toList();
      expect(kinds, ['blob', 'blob', 'blob', 'chat']);
      for (final piece in sent.take(3)) {
        expect(piece['envelope']['recipient_device_id'], peerDevice);
        expect(
          base64Decode(payloadOf(piece)['data'] as String).length,
          lessThanOrEqualTo(MeyaBlobStore.chunkBytes),
        );
      }
      // The relay never sees the picture or its key outside encryption.
      final relayed = sent.map((m) => m['envelope']['payload']).join();
      expect(relayed, isNot(contains(base64Encode(photo.sublist(0, 30)))));
      final content = contentOf(sent.last);
      expect(content['kind'], 'image');
      expect(content['text'], 'Hello');

      final history = await service.history(peer);
      expect(history.single.kind, 'image');
      expect(history.single.text, 'Hello');
      final attachment = history.single.attachment!;
      expect(attachment.owner, 'local');
      service.clearMemoryCache();
      expect(await service.openAttachment(attachment), photo);
    });

    test('a received photo opens once every piece has arrived', () async {
      final photo = Uint8List.fromList(
        List<int>.generate(MeyaBlobStore.chunkBytes + 99, (i) => (i * 7) % 256),
      );
      final key = MeyaBlobStore.newKey();
      final blobId = MeyaBlobStore.newBlobId();
      final ciphertext = await cipher.seal(key, photo, blobId);
      final pieces = MeyaBlobStore.split(ciphertext);

      await service.handleIncoming(
        peerDevice,
        chatFromPeer({
          'v': 1,
          'kind': 'image',
          'id': 'img1',
          'blob_id': blobId,
          'key': base64Encode(key),
          'mime': 'image/jpeg',
          'name': 'photo.jpg',
          'size': photo.length,
        }),
      );
      final attachment = (await service.history(peer)).single.attachment!;
      expect(attachment.owner, peerDevice);
      expect(await service.hasAttachment(attachment), isFalse);

      for (var i = 0; i < pieces.length; i++) {
        await service.handleBlobChunk(peerDevice, {
          'type': 'blob',
          'blob_id': blobId,
          'index': i,
          'count': pieces.length,
          'data': base64Encode(pieces[i]),
        });
      }
      expect(await service.hasAttachment(attachment), isTrue);
      expect(await service.openAttachment(attachment), photo);
    });

    test('pieces from an unknown device are dropped', () async {
      final blobId = MeyaBlobStore.newBlobId();
      await service.handleBlobChunk('device-stranger', {
        'blob_id': blobId,
        'index': 0,
        'count': 1,
        'data': base64Encode([1, 2, 3]),
      });
      expect(await MeyaBlobStore.instance.exists('device-stranger', blobId),
          isFalse);
    });

    test('a file above the size limit is refused before anything is sent',
        () async {
      await expectLater(
        service.sendAttachment(
          peer,
          kind: 'file',
          bytes: Uint8List(MeyaMessageService.maxAttachmentBytes + 1),
          mime: 'application/pdf',
          name: 'big.pdf',
        ),
        throwsStateError,
      );
      expect(sent, isEmpty);
    });

    test('a piece with a forged blob ID is rejected', () async {
      await expectLater(
        MeyaBlobStore.instance.addChunk(
          owner: peerDevice,
          blobId: '../../etc',
          index: 0,
          count: 1,
          data: Uint8List.fromList([1]),
        ),
        throwsStateError,
      );
    });
  });

  group('status', () {
    setUp(() {
      MeyaStatusService.instance.configureForTesting(
        database: database,
        e2ee: e2ee,
        directory: directory,
      );
      service.setSilentHandler('status', MeyaStatusService.instance.handleIncoming);
      service.setSilentHandler(
        'status_clear',
        MeyaStatusService.instance.handleIncoming,
      );
    });

    test('posting sends the status, encrypted, to each connection', () async {
      final failed = await MeyaStatusService.instance.post(
        text: 'On holiday',
        emoji: '✨',
        visibility: 'all',
      );

      expect(failed, isEmpty);
      expect(sent, hasLength(1));
      final content = contentOf(sent.single);
      expect(content['kind'], 'status');
      expect(content['text'], 'On holiday');
      expect((await MeyaStatusService.instance.loadOwn())!.text, 'On holiday');
      // Status updates are not shown as chat messages.
      expect(await service.history(peer), isEmpty);
    });

    test('"Only me" sends nothing', () async {
      await MeyaStatusService.instance.post(
        text: 'Private',
        emoji: '',
        visibility: 'only_me',
      );
      expect(sent, isEmpty);
    });

    test('a received status is shown until it is cleared', () async {
      await service.handleIncoming(
        peerDevice,
        chatFromPeer({
          'v': 1,
          'kind': 'status',
          'id': 's1',
          'status_id': 'abc',
          'text': 'At the beach',
          'emoji': '🌿',
          'posted_at': DateTime.now().toUtc().toIso8601String(),
          'expires_at':
              DateTime.now().add(const Duration(hours: 24)).toUtc().toIso8601String(),
        }),
      );
      final statuses = await MeyaStatusService.instance.contactStatuses();
      expect(statuses.single.text, 'At the beach');
      expect(statuses.single.contactName, 'Peer');

      await service.handleIncoming(
        peerDevice,
        chatFromPeer({'v': 1, 'kind': 'status_clear', 'id': 's2'}),
      );
      expect(await MeyaStatusService.instance.contactStatuses(), isEmpty);
    });

    test('an expired status is not shown', () async {
      await service.handleIncoming(
        peerDevice,
        chatFromPeer({
          'v': 1,
          'kind': 'status',
          'id': 's1',
          'status_id': 'old',
          'text': 'Yesterday',
          'emoji': '',
          'posted_at': DateTime.now()
              .subtract(const Duration(days: 2))
              .toUtc()
              .toIso8601String(),
          'expires_at': DateTime.now()
              .subtract(const Duration(days: 1))
              .toUtc()
              .toIso8601String(),
        }),
      );
      expect(await MeyaStatusService.instance.contactStatuses(), isEmpty);
    });
  });

  group('calendar', () {
    setUp(() {
      MeyaCalendarService.instance.configureForTesting(
        e2ee: e2ee,
        directory: directory,
      );
      service.setCallPlanHandler(MeyaCalendarService.instance.handleIncoming);
    });

    test('scheduling saves the call and invites the other person', () async {
      final start = DateTime.now().add(const Duration(days: 1));
      await MeyaCalendarService.instance.schedule(
        contact: peer,
        title: 'Catch up',
        start: start,
        durationMinutes: 30,
        callType: 'video',
      );

      final events = await MeyaCalendarService.instance.upcoming();
      expect(events.single.plan.title, 'Catch up');
      expect(events.single.createdByMe, isTrue);
      final content = contentOf(sent.single);
      expect(content['kind'], 'call_invite');
      expect(content['call_type'], 'video');
      expect((await service.history(peer)).single.kind, 'call_invite');
    });

    test('an invitation from a contact is added, and their cancel applies',
        () async {
      final plan = {
        'event_id': 'e1',
        'title': 'Family call',
        'start': DateTime.now().add(const Duration(hours: 3)).toUtc().toIso8601String(),
        'duration_min': 45,
        'call_type': 'voice',
        'note': '',
      };
      await service.handleIncoming(
        peerDevice,
        chatFromPeer({'v': 1, 'kind': 'call_invite', 'id': 'c1', ...plan}),
      );
      var events = await MeyaCalendarService.instance.events();
      expect(events.single.contactName, 'Peer');
      expect(events.single.cancelled, isFalse);

      await service.handleIncoming(
        peerDevice,
        chatFromPeer({'v': 1, 'kind': 'call_cancel', 'id': 'c2', ...plan}),
      );
      events = await MeyaCalendarService.instance.events();
      expect(events.single.cancelled, isTrue);
    });
  });
}
