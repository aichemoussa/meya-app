import 'dart:convert';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meya/database/contact_repository.dart';
import 'package:meya/database/meya_database.dart';
import 'package:meya/services/meya_e2ee.dart';
import 'package:meya/services/meya_message_service.dart';

/// Stand-in engine that marks ciphertext so the tests can tell it apart from
/// plaintext. Real encryption is covered by the Rust engine's own tests.
class MarkingE2ee implements E2eeOperations {
  final sessions = <String>{};

  static Uint8List _mark(Uint8List data) =>
      Uint8List.fromList([0xEE, ...data.map((b) => b ^ 0x5A)]);
  static Uint8List _unmark(Uint8List data) {
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
      E2eeCiphertext(messageType: 2, body: _mark(plaintext));
  @override
  Future<Uint8List> decrypt(String deviceId, int type, Uint8List body) async =>
      _unmark(body);
  @override
  Future<void> forget(String deviceId) async => sessions.remove(deviceId);
  @override
  Future<Uint8List> sealLocal(Uint8List plaintext, String context) async =>
      _mark(plaintext);
  @override
  Future<Uint8List> openLocal(Uint8List sealed, String context) async =>
      _unmark(sealed);
}

const localDevice = 'device-local';
const peerDevice = 'device-peer';

void main() {
  late MeyaDatabase database;
  late MarkingE2ee e2ee;
  late List<Map<String, dynamic>> sent;
  late Contact peer;

  setUp(() async {
    database = MeyaDatabase.forTesting(NativeDatabase.memory());
    e2ee = MarkingE2ee();
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
      displayName: 'Peer',
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

  Map<String, dynamic> incoming(String id, String text) {
    final content = utf8.encode(
      jsonEncode({'v': 1, 'kind': 'text', 'id': id, 'text': text}),
    );
    return {
      'type': 'chat',
      'v': 1,
      'message_type': 2,
      'body': base64Encode(MarkingE2ee._mark(Uint8List.fromList(content))),
    };
  }

  test('cannot message a contact without an encrypted session', () async {
    expect(await MeyaMessageService.instance.canMessage(peer), isFalse);
    e2ee.sessions.add(peerDevice);
    expect(await MeyaMessageService.instance.canMessage(peer), isTrue);
  });

  test('sending encrypts, relays ciphertext and keeps an encrypted copy',
      () async {
    e2ee.sessions.add(peerDevice);

    await MeyaMessageService.instance.sendText(peer, '  Bonjour  ');

    expect(sent, hasLength(1));
    final envelope = sent.single['envelope'] as Map<String, dynamic>;
    expect(envelope['recipient_device_id'], peerDevice);
    final relayPayload = utf8.decode(base64Decode(envelope['payload']));
    expect(relayPayload, isNot(contains('Bonjour')));
    expect(jsonDecode(relayPayload)['type'], 'chat');

    final stored = await database.select(database.messages).get();
    expect(stored.single.deliveryState, 'sent');
    expect(utf8.decode(stored.single.localDisplayCiphertext!, allowMalformed: true),
        isNot(contains('Bonjour')));

    final history = await MeyaMessageService.instance.history(peer);
    expect(history.single.text, 'Bonjour');
    expect(history.single.isMine, isTrue);
  });

  test('a send while offline is queued, then retried with the same ID',
      () async {
    e2ee.sessions.add(peerDevice);
    var online = false;
    MeyaMessageService.instance.configureForTesting(
      database: database,
      e2ee: e2ee,
      localDeviceId: () async => localDevice,
      send: (message) async {
        if (!online) throw StateError('relay offline');
        sent.add(message);
      },
    );

    await MeyaMessageService.instance.sendText(peer, 'hello');
    var stored = await database.select(database.messages).get();
    expect(stored.single.deliveryState, 'queued');

    online = true;
    expect(await MeyaMessageService.instance.retryPending(), 1);
    stored = await database.select(database.messages).get();
    expect(stored.single.deliveryState, 'sent');
    final envelope = sent.single['envelope'] as Map<String, dynamic>;
    expect(envelope['id'], stored.single.messageId);
  });

  test('incoming message from a contact is stored and shown', () async {
    await MeyaMessageService.instance.handleIncoming(
      peerDevice,
      incoming('m1', 'Salut'),
    );

    final history = await MeyaMessageService.instance.history(peer);
    expect(history.single.text, 'Salut');
    expect(history.single.isMine, isFalse);
  });

  test('duplicate incoming message is stored once', () async {
    await MeyaMessageService.instance.handleIncoming(peerDevice, incoming('m1', 'Salut'));
    await MeyaMessageService.instance.handleIncoming(peerDevice, incoming('m1', 'Salut'));

    expect(await MeyaMessageService.instance.history(peer), hasLength(1));
  });

  test('message from an unknown device is dropped', () async {
    await MeyaMessageService.instance.handleIncoming(
      'device-stranger',
      incoming('m1', 'Hi'),
    );

    expect(await database.select(database.messages).get(), isEmpty);
  });

  test('undecryptable message is rejected, not stored', () async {
    await expectLater(
      MeyaMessageService.instance.handleIncoming(peerDevice, {
        'type': 'chat',
        'v': 1,
        'message_type': 2,
        'body': base64Encode([1, 2, 3]),
      }),
      throwsStateError,
    );
    expect(await database.select(database.messages).get(), isEmpty);
  });

  test('session start message is not shown in the conversation', () async {
    final content = utf8.encode(
      jsonEncode({'v': 1, 'kind': 'session_init', 'id': 's1'}),
    );
    await MeyaMessageService.instance.handleIncoming(peerDevice, {
      'type': 'chat',
      'v': 1,
      'message_type': 3,
      'body': base64Encode(MarkingE2ee._mark(Uint8List.fromList(content))),
    });

    expect(await database.select(database.messages).get(), isEmpty);
  });

  test('voice message is encrypted, relayed and plays back from history',
      () async {
    e2ee.sessions.add(peerDevice);
    final audio = Uint8List.fromList(List<int>.generate(4000, (i) => i % 251));

    await MeyaMessageService.instance.sendVoice(peer, audio, durationMs: 3200);

    expect(sent, hasLength(1));
    final envelope = sent.single['envelope'] as Map<String, dynamic>;
    final relayPayload = utf8.decode(base64Decode(envelope['payload']));
    expect(relayPayload, isNot(contains(base64Encode(audio))));

    final history = await MeyaMessageService.instance.history(peer);
    expect(history.single.kind, 'voice');
    expect(history.single.audio, audio);
    expect(history.single.durationMs, 3200);
    expect(history.single.isMine, isTrue);
  });

  test('incoming voice message is stored and shown', () async {
    final audio = Uint8List.fromList([1, 2, 3, 4, 5]);
    final content = utf8.encode(
      jsonEncode({
        'v': 1,
        'kind': 'voice',
        'id': 'v1',
        'audio': base64Encode(audio),
        'mime': 'audio/mp4',
        'duration_ms': 1500,
      }),
    );
    await MeyaMessageService.instance.handleIncoming(peerDevice, {
      'type': 'chat',
      'v': 1,
      'message_type': 2,
      'body': base64Encode(MarkingE2ee._mark(Uint8List.fromList(content))),
    });

    final history = await MeyaMessageService.instance.history(peer);
    expect(history.single.kind, 'voice');
    expect(history.single.audio, audio);
    expect(history.single.durationMs, 1500);
    expect(history.single.isMine, isFalse);
  });

  test('voice message over the size limit is refused before sending',
      () async {
    e2ee.sessions.add(peerDevice);
    final tooBig = Uint8List(MeyaMessageService.maxVoiceBytes + 1);

    await expectLater(
      MeyaMessageService.instance.sendVoice(peer, tooBig, durationMs: 1000),
      throwsStateError,
    );
    expect(sent, isEmpty);
    expect(await database.select(database.messages).get(), isEmpty);
  });
}
