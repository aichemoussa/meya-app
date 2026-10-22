import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meya/database/account_repository.dart';
import 'package:meya/database/connection_request_repository.dart';
import 'package:meya/database/contact_repository.dart';
import 'package:meya/database/meya_database.dart';
import 'package:meya/services/meya_connection_service.dart';
import 'package:meya/services/meya_invite_service.dart';
import 'package:meya/services/meya_pairing_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'connection_trust_test.dart' show FakeE2ee;

const inviterDevice = 'device-inviter';
const joinerDevice = 'device-joiner';

const invite = MeyaInvite(
  identityId: 'identity-inviter',
  identityPublicKey: 'inviter+key/with=base64',
  deviceId: inviterDevice,
  token: 'abcdefghijklmnopqrstuv',
);

Map<String, dynamic> envelope(Map<String, dynamic> payload) => {
      'type': 'Envelope',
      'envelope': {
        'id': 'envelope-1',
        'sender_device_id': joinerDevice,
        'recipient_device_id': inviterDevice,
        'payload': base64Encode(utf8.encode(jsonEncode(payload))),
      },
    };

void main() {
  group('invite links', () {
    test('a link reads back exactly what it carries', () {
      final link = MeyaInviteService.linkFor(invite);
      expect(link, startsWith('https://meya-app.pages.dev/i#'));

      final read = MeyaInviteService.parse(link)!;
      expect(read.identityId, invite.identityId);
      expect(read.identityPublicKey, invite.identityPublicKey);
      expect(read.deviceId, invite.deviceId);
      expect(read.token, invite.token);
    });

    test('the in-app form of the link works too', () {
      final https = MeyaInviteService.linkFor(invite);
      final app = https.replaceFirst(
        MeyaInviteService.linkBase,
        MeyaInviteService.appLinkBase,
      );
      expect(MeyaInviteService.parse(app)!.token, invite.token);
    });

    test('a link carries no name, and its data stays after #', () {
      final link = MeyaInviteService.linkFor(invite);
      final uri = Uri.parse(link);
      // Browsers never send the fragment to the website.
      expect(uri.path, '/i');
      expect(uri.query, isEmpty);
      expect(uri.fragment, isNotEmpty);
    });

    test('anything else is not an invite', () {
      for (final link in [
        '',
        'https://meya-app.pages.dev/i#',
        'https://meya-app.pages.dev/i#not-base64!!',
        'https://example.com/i#${base64Url.encode(utf8.encode('MEYA|L1|a|b|c|abcdefghijklmnop'))}',
        'https://meya-app.pages.dev/i#${base64Url.encode(utf8.encode('MEYA|L2|a|b|c|abcdefghijklmnop'))}',
        // Token too short.
        'https://meya-app.pages.dev/i#${base64Url.encode(utf8.encode('MEYA|L1|a|b|c|short'))}',
      ]) {
        expect(MeyaInviteService.parse(link), isNull, reason: link);
      }
    });
  });

  group('one-time tokens', () {
    late DateTime clock;

    setUp(() {
      FlutterSecureStorage.setMockInitialValues({});
      clock = DateTime.utc(2026, 10, 22, 12);
      MeyaInviteService.instance.now = () => clock;
    });

    tearDown(() => MeyaInviteService.instance.now = DateTime.now);

    Future<String> newToken() async => (await MeyaInviteService.instance.create(
          identityId: 'i',
          identityPublicKey: 'k',
          deviceId: 'd',
        ))
            .token;

    test('a token works once', () async {
      final token = await newToken();
      expect(await MeyaInviteService.instance.consume(token), isTrue);
      expect(await MeyaInviteService.instance.consume(token), isFalse);
    });

    test('a token expires after 7 days', () async {
      final token = await newToken();
      clock = clock.add(const Duration(days: 7, minutes: 1));
      expect(await MeyaInviteService.instance.consume(token), isFalse);
    });

    test('an unknown token is refused', () async {
      await newToken();
      expect(
        await MeyaInviteService.instance.consume('zzzzzzzzzzzzzzzzzzzzzz'),
        isFalse,
      );
    });

    test('only the newest invites are kept', () async {
      final first = await newToken();
      for (var i = 0; i < MeyaInviteService.maxOpenInvites; i++) {
        clock = clock.add(const Duration(seconds: 1));
        await newToken();
      }
      expect(await MeyaInviteService.instance.consume(first), isFalse);
    });

    test('tokens are stored only as hashes', () async {
      final token = await newToken();
      final stored = await const FlutterSecureStorage().readAll();
      expect(stored.values.join(), isNot(contains(token)));
    });
  });

  group('connecting with a link', () {
    late MeyaDatabase database;
    late List<Map<String, dynamic>> sent;
    late List<String> linked;
    late List<String> events;
    late Set<String> validTokens;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      database = MeyaDatabase.forTesting(NativeDatabase.memory());
      await AccountRepository(database).createAccount(
        accountId: 'identity-inviter',
        identityId: 'identity-inviter',
        meyaId: 'MEYA-1',
        name: 'Inviter',
        username: 'inviter',
        createdAt: 't',
        identityPublicKey: 'inviter-key',
      );
      sent = [];
      linked = [];
      events = [];
      validTokens = {invite.token};

      MeyaConnectionService.instance.configureForTesting(
        database: database,
        localDeviceIdProvider: () async => inviterDevice,
        e2ee: FakeE2ee(),
        send: (message) async => sent.add(message),
        consumeInvite: (token) async => validTokens.remove(token),
        markConnectedByLink: (identityId) async => linked.add(identityId),
        onIncomingRequest: () => events.add('invitation'),
        onConnectedByLink: () => events.add('connected'),
      );
    });

    tearDown(() => database.close());

    Map<String, dynamic> request(String? token, {String id = 'req_1'}) =>
        MeyaPairingService.buildConnectionRequest(
          requestId: id,
          senderDeviceId: joinerDevice,
          identityId: 'identity-joiner',
          identityPublicKey: 'joiner-key',
          inviteToken: token,
        );

    test('a request with a valid token is accepted at once', () async {
      await MeyaConnectionService.instance
          .handleRelayMessage(envelope(request(invite.token)));

      final contact = await ContactRepository(database)
          .getContactByIdentityId('identity-joiner');
      expect(contact, isNotNull);
      expect(contact!.trustState, 'trusted');
      expect(
        (await ConnectionRequestRepository(database).getRequestById('req_1'))!
            .status,
        'accepted',
      );
      expect(linked, ['identity-joiner']);
      expect(events, ['connected']);

      // The accepted reply, with the pre-key bundle, went to the joiner.
      final reply = sent.single['envelope'] as Map<String, dynamic>;
      expect(reply['recipient_device_id'], joinerDevice);
      final payload = jsonDecode(utf8.decode(base64Decode(reply['payload'] as String)));
      expect(payload['status'], 'accepted');
      expect(payload['pre_key_bundle'], 'bundle-json');
    });

    test('a used or unknown token leaves a normal invitation', () async {
      await MeyaConnectionService.instance
          .handleRelayMessage(envelope(request('wrong-token-wrong-token')));

      expect(
        (await ConnectionRequestRepository(database).getRequestById('req_1'))!
            .status,
        'pending',
      );
      expect(await ContactRepository(database).getContacts(), isEmpty);
      expect(sent, isEmpty);
      expect(events, ['invitation']);
    });

    test('a token cannot be used twice', () async {
      await MeyaConnectionService.instance
          .handleRelayMessage(envelope(request(invite.token)));
      await MeyaConnectionService.instance
          .handleRelayMessage(envelope(request(invite.token, id: 'req_2')));

      expect(
        (await ConnectionRequestRepository(database).getRequestById('req_2'))!
            .status,
        'pending',
      );
      expect(events, ['connected', 'invitation']);
    });

    test('a request without a token still needs accepting', () async {
      await MeyaConnectionService.instance
          .handleRelayMessage(envelope(request(null)));

      expect(sent, isEmpty);
      expect(events, ['invitation']);
    });

    test('the token is not sent when there is none', () {
      expect(request(null).containsKey('invite_token'), isFalse);
      expect(request(invite.token)['invite_token'], invite.token);
    });
  });
}
