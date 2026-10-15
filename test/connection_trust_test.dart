import 'dart:convert';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meya/database/connection_request_repository.dart';
import 'package:meya/database/contact_repository.dart';
import 'package:meya/database/meya_database.dart';
import 'package:meya/services/meya_connection_service.dart';
import 'package:meya/services/meya_e2ee.dart';
import 'package:meya/services/meya_pairing_service.dart';

const localDeviceId = 'device-local';
const peerDeviceId = 'device-peer';
const attackerDeviceId = 'device-attacker';
const requestId = '${localDeviceId}_identity-local';

/// Stand-in for the Rust encryption engine (covered by its own Rust tests).
class FakeE2ee implements E2eeOperations {
  final pinned = <String, String>{};
  final sessions = <String, String>{};
  bool failStartSession = false;

  @override
  String? get identityKeyBase64 => 'local-public-key';

  @override
  Future<String> open() async => 'local-public-key';

  @override
  Future<void> pinIdentity(String deviceId, String identityKeyBase64) async {
    final existing = pinned[deviceId];
    if (existing != null && existing != identityKeyBase64) {
      throw StateError('identity already pinned');
    }
    pinned[deviceId] = identityKeyBase64;
  }

  @override
  Future<String> createPreKeyBundle() async => 'bundle-json';

  @override
  Future<void> startSession(String deviceId, String bundleJson) async {
    if (failStartSession) throw StateError('bad bundle');
    sessions[deviceId] = bundleJson;
  }

  @override
  Future<bool> hasSession(String deviceId) async => sessions.containsKey(deviceId);

  @override
  Future<E2eeCiphertext> encrypt(String deviceId, Uint8List plaintext) async =>
      E2eeCiphertext(messageType: 2, body: plaintext);

  @override
  Future<Uint8List> decrypt(String deviceId, int type, Uint8List body) async =>
      body;

  @override
  Future<void> forget(String deviceId) async {
    pinned.remove(deviceId);
    sessions.remove(deviceId);
  }

  @override
  Future<Uint8List> sealLocal(Uint8List plaintext, String context) async =>
      plaintext;

  @override
  Future<Uint8List> openLocal(Uint8List sealed, String context) async => sealed;
}

Map<String, dynamic> envelope({
  required String senderDeviceId,
  required Map<String, dynamic> payload,
  String id = 'envelope-1',
}) {
  return {
    'type': 'Envelope',
    'envelope': {
      'id': id,
      'sender_device_id': senderDeviceId,
      'recipient_device_id': localDeviceId,
      'payload': base64Encode(utf8.encode(jsonEncode(payload))),
    },
  };
}

Map<String, dynamic> acceptedResponse({
  String id = requestId,
  String publicKey = 'peer-public-key',
}) {
  return {
    'type': 'connection_response',
    'request_id': id,
    'status': 'accepted',
    'identity_id': 'identity-peer',
    'username': 'peer',
    'name': 'Peer',
    'identity_public_key': publicKey,
    'device_id': peerDeviceId,
    'pre_key_bundle': 'bundle-from-peer',
  };
}

void main() {
  late MeyaDatabase database;
  late ConnectionRequestRepository requests;
  late ContactRepository contacts;
  late List<String> acknowledged;
  late List<String> warnings;
  late FakeE2ee e2ee;
  late List<String> sessionStarts;

  setUp(() async {
    database = MeyaDatabase.forTesting(NativeDatabase.memory());
    requests = ConnectionRequestRepository(database);
    contacts = ContactRepository(database);
    acknowledged = [];
    warnings = [];
    e2ee = FakeE2ee();
    sessionStarts = [];

    MeyaConnectionService.instance.configureForTesting(
      database: database,
      localDeviceIdProvider: () async => localDeviceId,
      e2ee: e2ee,
      acknowledge: acknowledged.add,
      onSecurityWarning: warnings.add,
      onSessionStarted: (deviceId) async => sessionStarts.add(deviceId),
    );
  });

  tearDown(() async {
    await database.close();
  });

  Future<void> createOutgoingRequest({
    String scannedIdentityId = 'identity-peer',
    String scannedPublicKey = 'peer-public-key',
  }) {
    return requests.createOutgoingRequest(
      requestId: requestId,
      senderIdentityId: 'identity-local',
      senderDeviceId: localDeviceId,
      senderUsername: 'local',
      senderIdentityPublicKey: 'local-public-key',
      recipientDeviceId: peerDeviceId,
      recipientIdentityId: scannedIdentityId,
      recipientIdentityPublicKey: scannedPublicKey,
      createdAt: DateTime.now().toUtc().toIso8601String(),
    );
  }

  group('connection responses', () {
    test('valid response from the requested device creates a trusted contact',
        () async {
      await createOutgoingRequest();

      await MeyaConnectionService.instance.handleRelayMessage(
        envelope(senderDeviceId: peerDeviceId, payload: acceptedResponse()),
      );

      final contact = await contacts.getContactByIdentityId('identity-peer');
      expect(contact, isNotNull);
      expect(contact!.trustState, 'trusted');
      expect(contact.identityPublicKey, 'peer-public-key');
      expect((await requests.getRequestById(requestId))!.status, 'accepted');
      expect(acknowledged, ['envelope-1']);

      // The encrypted session was started with the replying device, the
      // device was recorded, and the first encrypted message was triggered.
      expect(e2ee.sessions[peerDeviceId], 'bundle-from-peer');
      expect(
        await contacts.getDeviceIdForContact(contact.contactId),
        peerDeviceId,
      );
      expect(sessionStarts, [peerDeviceId]);
    });

    test('reply without a pre-key bundle is not trusted', () async {
      await createOutgoingRequest();
      final payload = acceptedResponse()..remove('pre_key_bundle');

      await MeyaConnectionService.instance.handleRelayMessage(
        envelope(senderDeviceId: peerDeviceId, payload: payload),
      );

      expect(await contacts.getContacts(), isEmpty);
      expect((await requests.getRequestById(requestId))!.status, 'pending');
      expect(warnings.single, contains('older version'));
      expect(e2ee.sessions, isEmpty);
    });

    test('reply whose session cannot be started is not trusted', () async {
      await createOutgoingRequest();
      e2ee.failStartSession = true;

      await MeyaConnectionService.instance.handleRelayMessage(
        envelope(senderDeviceId: peerDeviceId, payload: acceptedResponse()),
      );

      expect(await contacts.getContacts(), isEmpty);
      expect((await requests.getRequestById(requestId))!.status, 'pending');
      expect(warnings.single, contains('secure session'));
      expect(sessionStarts, isEmpty);
    });

    test('chat envelopes are routed to the chat handler and acknowledged',
        () async {
      final routed = <String>[];
      MeyaConnectionService.instance.configureForTesting(
        database: database,
        localDeviceIdProvider: () async => localDeviceId,
        e2ee: e2ee,
        acknowledge: acknowledged.add,
        onChat: (sender, payload) async => routed.add('$sender:${payload['body']}'),
      );

      await MeyaConnectionService.instance.handleRelayMessage(
        envelope(
          id: 'chat-1',
          senderDeviceId: peerDeviceId,
          payload: {'type': 'chat', 'v': 1, 'message_type': 2, 'body': 'QUJD'},
        ),
      );

      expect(routed, ['$peerDeviceId:QUJD']);
      expect(acknowledged, ['chat-1']);
    });

    test('response without a matching request is ignored', () async {
      await MeyaConnectionService.instance.handleRelayMessage(
        envelope(senderDeviceId: peerDeviceId, payload: acceptedResponse()),
      );

      expect(await contacts.getContacts(), isEmpty);
      expect(warnings, isNotEmpty);
      expect(acknowledged, ['envelope-1']);
    });

    test('response from a different device is ignored', () async {
      await createOutgoingRequest();

      await MeyaConnectionService.instance.handleRelayMessage(
        envelope(senderDeviceId: attackerDeviceId, payload: acceptedResponse()),
      );

      expect(await contacts.getContacts(), isEmpty);
      expect((await requests.getRequestById(requestId))!.status, 'pending');
    });

    test('response to an incoming request is ignored', () async {
      await requests.createIncomingRequest(
        requestId: requestId,
        senderIdentityId: 'identity-peer',
        senderDeviceId: peerDeviceId,
        senderUsername: 'peer',
        senderIdentityPublicKey: 'peer-public-key',
        recipientDeviceId: localDeviceId,
        createdAt: DateTime.now().toUtc().toIso8601String(),
      );

      await MeyaConnectionService.instance.handleRelayMessage(
        envelope(senderDeviceId: peerDeviceId, payload: acceptedResponse()),
      );

      expect(await contacts.getContacts(), isEmpty);
      expect((await requests.getRequestById(requestId))!.status, 'pending');
    });

    test('response for an already answered request is ignored', () async {
      await createOutgoingRequest();
      await requests.decline(requestId);

      await MeyaConnectionService.instance.handleRelayMessage(
        envelope(senderDeviceId: peerDeviceId, payload: acceptedResponse()),
      );

      expect(await contacts.getContacts(), isEmpty);
      expect((await requests.getRequestById(requestId))!.status, 'declined');
    });

    test('unknown status values are ignored', () async {
      await createOutgoingRequest();
      final payload = acceptedResponse()..['status'] = 'trusted';

      await MeyaConnectionService.instance.handleRelayMessage(
        envelope(senderDeviceId: peerDeviceId, payload: payload),
      );

      expect(await contacts.getContacts(), isEmpty);
      expect((await requests.getRequestById(requestId))!.status, 'pending');
    });

    test('a changed identity key never replaces a trusted key', () async {
      await contacts.upsertTrustedContact(
        contactId: 'contact_identity-peer',
        identityId: 'identity-peer',
        displayName: 'Peer',
        identityPublicKey: 'original-public-key',
        updatedAt: DateTime.now().toUtc().toIso8601String(),
      );
      await contacts.upsertContactDevice(
        contactId: 'contact_identity-peer',
        deviceId: peerDeviceId,
        identityPublicKey: 'original-public-key',
      );
      // The QR code itself showed the new key, so only the stored-contact
      // protection can stop the replacement.
      await createOutgoingRequest(scannedPublicKey: 'replacement-public-key');

      await MeyaConnectionService.instance.handleRelayMessage(
        envelope(
          senderDeviceId: peerDeviceId,
          payload: acceptedResponse(publicKey: 'replacement-public-key'),
        ),
      );

      final contact = await contacts.getContactByIdentityId('identity-peer');
      expect(contact!.identityPublicKey, 'original-public-key');
      expect((await requests.getRequestById(requestId))!.status, 'pending');
      expect(warnings.single, contains('identity key'));
    });

    test('malformed payload is acknowledged without changing state', () async {
      await createOutgoingRequest();

      await MeyaConnectionService.instance.handleRelayMessage({
        'type': 'Envelope',
        'envelope': {
          'id': 'envelope-bad',
          'sender_device_id': peerDeviceId,
          'recipient_device_id': localDeviceId,
          'payload': 'not base64 !!',
        },
      });

      expect(await contacts.getContacts(), isEmpty);
      expect(acknowledged, ['envelope-bad']);
    });
  });

  group('QR identity binding', () {
    test('reply with a key different from the scanned QR is rejected',
        () async {
      await createOutgoingRequest(scannedPublicKey: 'key-from-qr');

      await MeyaConnectionService.instance.handleRelayMessage(
        envelope(
          senderDeviceId: peerDeviceId,
          payload: acceptedResponse(publicKey: 'substituted-key'),
        ),
      );

      expect(await contacts.getContacts(), isEmpty);
      expect((await requests.getRequestById(requestId))!.status, 'pending');
      expect(warnings.single, contains('does not match the QR code'));
    });

    test('reply from an identity different from the scanned QR is rejected',
        () async {
      await createOutgoingRequest(scannedIdentityId: 'identity-someone-else');

      await MeyaConnectionService.instance.handleRelayMessage(
        envelope(senderDeviceId: peerDeviceId, payload: acceptedResponse()),
      );

      expect(await contacts.getContacts(), isEmpty);
      expect((await requests.getRequestById(requestId))!.status, 'pending');
    });

    test('request saved without a QR identity cannot be accepted', () async {
      await database
          .into(database.connectionRequests)
          .insert(
            ConnectionRequestsCompanion.insert(
              requestId: requestId,
              senderIdentityId: 'identity-local',
              senderDeviceId: localDeviceId,
              senderUsername: 'local',
              senderIdentityPublicKey: 'local-public-key',
              recipientDeviceId: peerDeviceId,
              createdAt: 't',
              updatedAt: 't',
            ),
          );

      await MeyaConnectionService.instance.handleRelayMessage(
        envelope(senderDeviceId: peerDeviceId, payload: acceptedResponse()),
      );

      expect(await contacts.getContacts(), isEmpty);
      expect(warnings.single, contains('Scan the QR code'));
    });

    test('an outgoing request must record the scanned identity', () {
      expect(
        () => requests.createOutgoingRequest(
          requestId: requestId,
          senderIdentityId: 'identity-local',
          senderDeviceId: localDeviceId,
          senderUsername: 'local',
          senderIdentityPublicKey: 'local-public-key',
          recipientDeviceId: peerDeviceId,
          recipientIdentityId: 'identity-peer',
          recipientIdentityPublicKey: '',
          createdAt: 't',
        ),
        throwsArgumentError,
      );
    });

    test('scanning again refreshes a pending request', () async {
      await createOutgoingRequest(scannedPublicKey: 'old-key');
      await createOutgoingRequest(scannedPublicKey: 'peer-public-key');

      final request = await requests.getRequestById(requestId);
      expect(request!.recipientIdentityPublicKey, 'peer-public-key');
      expect(request.status, 'pending');
    });

    test('scanning again never reopens an accepted request', () async {
      await createOutgoingRequest();
      await requests.accept(requestId);
      await createOutgoingRequest(scannedPublicKey: 'other-key');

      final request = await requests.getRequestById(requestId);
      expect(request!.status, 'accepted');
      expect(request.recipientIdentityPublicKey, 'peer-public-key');
    });
  });

  group('two-device pairing exchange', () {
    test('request ID survives the round trip and the contact is trusted',
        () async {
      final phoneB = MeyaDatabase.forTesting(NativeDatabase.memory());
      addTearDown(phoneB.close);

      const phoneAId = localDeviceId;
      const phoneBId = peerDeviceId;
      const exchangeId = '${phoneAId}_identity-peer';

      // Phone A scans Phone B's QR code and stores the outgoing request.
      await requests.createOutgoingRequest(
        requestId: exchangeId,
        senderIdentityId: 'identity-local',
        senderDeviceId: phoneAId,
        senderUsername: 'local',
        senderIdentityPublicKey: 'local-public-key',
        recipientDeviceId: phoneBId,
        recipientIdentityId: 'identity-peer',
        recipientIdentityPublicKey: 'peer-public-key',
        createdAt: 't',
      );
      final requestPayload = MeyaPairingService.buildConnectionRequest(
        requestId: exchangeId,
        senderDeviceId: phoneAId,
        identityId: 'identity-local',
        username: 'local',
        identityPublicKey: 'local-public-key',
        name: 'Local',
      );

      // Phone B receives the request.
      MeyaConnectionService.instance.configureForTesting(
        database: phoneB,
        localDeviceIdProvider: () async => phoneBId,
        e2ee: FakeE2ee(),
      );
      await MeyaConnectionService.instance.handleRelayMessage(
        envelope(senderDeviceId: phoneAId, payload: requestPayload),
      );
      final received = await ConnectionRequestRepository(phoneB)
          .getIncomingPendingRequests(phoneBId);
      expect(received.single.requestId, exchangeId);

      // Phone B accepts; its reply is built exactly as the app builds it.
      final responsePayload = MeyaConnectionService.buildConnectionResponse(
        requestId: received.single.requestId,
        status: 'accepted',
        account: const Account(
          accountId: 'identity-peer',
          identityId: 'identity-peer',
          meyaId: 'MEYA-2',
          name: 'Peer',
          username: 'peer',
          createdAt: 't',
          identityPublicKey: 'peer-public-key',
          isActive: true,
        ),
        deviceId: phoneBId,
        preKeyBundle: 'bundle-from-peer',
      );

      // Phone A receives the reply.
      MeyaConnectionService.instance.configureForTesting(
        database: database,
        localDeviceIdProvider: () async => phoneAId,
        e2ee: e2ee,
        onSecurityWarning: warnings.add,
      );
      await MeyaConnectionService.instance.handleRelayMessage(
        envelope(senderDeviceId: phoneBId, payload: responsePayload),
      );

      final contact = await contacts.getContactByIdentityId('identity-peer');
      expect(contact, isNotNull);
      expect(contact!.identityPublicKey, 'peer-public-key');
      expect((await requests.getRequestById(exchangeId))!.status, 'accepted');
      expect(warnings, isEmpty);
    });
  });

  group('connection requests', () {
    Map<String, dynamic> request({required String senderDeviceId}) => {
      'type': 'connection_request',
      'request_id': '${senderDeviceId}_identity-peer',
      'sender_device_id': senderDeviceId,
      'sender_identity_id': 'identity-peer',
      'sender_username': 'peer',
      'sender_name': 'Peer',
      'sender_identity_public_key': 'peer-public-key',
    };

    test('request is stored when the payload matches the relay sender',
        () async {
      await MeyaConnectionService.instance.handleRelayMessage(
        envelope(
          senderDeviceId: peerDeviceId,
          payload: request(senderDeviceId: peerDeviceId),
        ),
      );

      final pending = await requests.getIncomingPendingRequests(localDeviceId);
      expect(pending, hasLength(1));
      expect(pending.single.senderDeviceId, peerDeviceId);
    });

    test('request claiming another device is rejected', () async {
      await MeyaConnectionService.instance.handleRelayMessage(
        envelope(
          senderDeviceId: attackerDeviceId,
          payload: request(senderDeviceId: peerDeviceId),
        ),
      );

      expect(
        await requests.getIncomingPendingRequests(localDeviceId),
        isEmpty,
      );
      expect(warnings, isNotEmpty);
    });

    test('a new scan after an earlier accepted connection shows a new invitation',
        () async {
      final announced = <String>[];
      MeyaConnectionService.instance.configureForTesting(
        database: database,
        localDeviceIdProvider: () async => localDeviceId,
        e2ee: e2ee,
        acknowledge: acknowledged.add,
        onSecurityWarning: warnings.add,
        onIncomingRequest: announced.add,
      );

      final first = request(senderDeviceId: peerDeviceId);
      await MeyaConnectionService.instance.handleRelayMessage(
        envelope(senderDeviceId: peerDeviceId, payload: first),
      );
      await requests.accept(first['request_id'] as String);

      // The same request again is not announced: it would not appear in
      // Invitations, because it was already answered.
      await MeyaConnectionService.instance.handleRelayMessage(
        envelope(senderDeviceId: peerDeviceId, payload: first),
      );
      expect(announced, hasLength(1));

      // A new scan carries a new request ID and shows up as a new invitation.
      await MeyaConnectionService.instance.handleRelayMessage(
        envelope(
          senderDeviceId: peerDeviceId,
          payload: {...first, 'request_id': 'req_second_scan'},
        ),
      );
      expect(announced, hasLength(2));
      final pending = await requests.getIncomingPendingRequests(localDeviceId);
      expect(pending.single.requestId, 'req_second_scan');
    });
  });

  group('contact repository', () {
    test('a contact paired before encryption can be upgraded by re-pairing',
        () async {
      // Legacy contact: trusted, but no encrypted device record.
      await contacts.upsertTrustedContact(
        contactId: 'contact_identity-peer',
        identityId: 'identity-peer',
        displayName: 'Peer',
        identityPublicKey: 'old-x25519-key',
        updatedAt: DateTime.now().toUtc().toIso8601String(),
      );
      await createOutgoingRequest();

      await MeyaConnectionService.instance.handleRelayMessage(
        envelope(senderDeviceId: peerDeviceId, payload: acceptedResponse()),
      );

      final contact = await contacts.getContactByIdentityId('identity-peer');
      expect(contact!.identityPublicKey, 'peer-public-key');
      expect(await contacts.getDeviceIdForContact(contact.contactId), peerDeviceId);
      expect(warnings, isEmpty);
    });

    test('upsert refuses to replace an existing identity key', () async {
      await contacts.upsertTrustedContact(
        contactId: 'contact_identity-peer',
        identityId: 'identity-peer',
        displayName: 'Peer',
        identityPublicKey: 'original-public-key',
        updatedAt: DateTime.now().toUtc().toIso8601String(),
      );
      await contacts.upsertContactDevice(
        contactId: 'contact_identity-peer',
        deviceId: peerDeviceId,
        identityPublicKey: 'original-public-key',
      );

      expect(
        () => contacts.upsertTrustedContact(
          contactId: 'contact_identity-peer',
          identityId: 'identity-peer',
          displayName: 'Peer',
          identityPublicKey: 'replacement-public-key',
          updatedAt: DateTime.now().toUtc().toIso8601String(),
        ),
        throwsA(isA<IdentityKeyChangedException>()),
      );
    });
  });
}
