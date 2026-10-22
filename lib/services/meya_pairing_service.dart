import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../database/account_repository.dart';
import '../database/connection_request_repository.dart';
import '../database/meya_database.dart';
import 'device_identity_service.dart';
import 'meya_e2ee.dart';
import 'meya_relay_session.dart';

class MeyaPairingService {
  MeyaPairingService._();

  static final MeyaPairingService instance = MeyaPairingService._();

  /// Connection requests and responses travel through the relay without
  /// end-to-end encryption (there is no session yet), so they carry no name
  /// or username. Names are shared afterwards, encrypted, with the profile.
  ///
  /// MEYA 1.0.6 and earlier reject a request or response without a username,
  /// so this neutral value is sent in its place. Newer versions ignore it.
  static const legacyUsernamePlaceholder = 'new-contact';

  /// Sends a connection request under [requestId], which must be the ID the
  /// caller already stored for the outgoing request. The reply carries this
  /// ID back, and it is how the reply is matched to the scanned QR identity.
  Future<void> sendConnectionRequest({
    required String requestId,
    required String recipientDeviceId,
    required String identityId,
    required String identityPublicKey,
    String? inviteToken,
  }) async {
    final senderDeviceId = await DeviceIdentityService.getDeviceId();

    if (senderDeviceId == null || senderDeviceId.isEmpty) {
      throw StateError('MEYA device ID is not available.');
    }

    final request = buildConnectionRequest(
      requestId: requestId,
      senderDeviceId: senderDeviceId,
      identityId: identityId,
      identityPublicKey: identityPublicKey,
      inviteToken: inviteToken,
    );

    final requestBytes = utf8.encode(jsonEncode(request));
    final encodedPayload = base64Encode(requestBytes);

    await MeyaRelaySession.instance.sendWhenConnected(
      message: {
        'type': 'Send',
        'envelope': {
          'id': request['request_id'],
          'sender_device_id': senderDeviceId,
          'recipient_device_id': recipientDeviceId,
          'payload': encodedPayload,
          // Wakes the other phone (see MeyaMessageService._envelope).
          'notify': 'invite',
        },
      },
    );
  }

  @visibleForTesting
  static Map<String, String> buildConnectionRequest({
    required String requestId,
    required String senderDeviceId,
    required String identityId,
    required String identityPublicKey,
    String? inviteToken,
  }) {
    if (requestId.isEmpty) {
      throw ArgumentError.value(requestId, 'requestId', 'must not be empty');
    }

    return {
      'type': 'connection_request',
      'request_id': requestId,
      'sender_device_id': senderDeviceId,
      'sender_identity_id': identityId,
      'sender_username': legacyUsernamePlaceholder,
      'sender_identity_public_key': identityPublicKey,
      // From an invite link: lets the other phone accept automatically.
      'invite_token': ?inviteToken,
    };
  }

  /// Starts a connection with the device whose identity was read from a QR
  /// code or an invite link: trusts exactly that identity key for that
  /// device, records the outgoing request and sends it.
  ///
  /// Throws a [PairingException] whose message is English text for `tr`.
  Future<void> startConnection({
    required MeyaDatabase database,
    required String recipientIdentityId,
    required String recipientIdentityPublicKey,
    required String recipientDeviceId,
    String? inviteToken,
  }) async {
    final account = await AccountRepository(database).getActiveAccount();
    final localIdentityId = account?.identityId;
    if (account == null) {
      throw const PairingException(
        'Your MEYA account is not available on this device.',
      );
    }

    final String localIdentityPublicKey;
    try {
      localIdentityPublicKey = await MeyaE2ee.instance.open();
    } catch (error) {
      throw PairingException('MEYA encryption could not start: {0}', '$error');
    }

    if (localIdentityId == null ||
        localIdentityId.isEmpty ||
        account.username.isEmpty ||
        localIdentityPublicKey.isEmpty) {
      throw const PairingException('Your MEYA identity is not ready yet.');
    }

    final senderDeviceId = await DeviceIdentityService.getDeviceId();
    if (senderDeviceId == null || senderDeviceId.isEmpty) {
      throw const PairingException(
        'Your MEYA device identity is not available.',
      );
    }
    if (senderDeviceId == recipientDeviceId) {
      throw const PairingException(
        'You cannot send a connection request to this device.',
      );
    }

    // A fresh ID for every scan. A fixed ID (device + identity) collided with
    // the earlier, already accepted connection between the same two people,
    // so a new scan was silently ignored by the other phone and the relay.
    final random = Random.secure();
    final requestId =
        'req_${List<int>.generate(16, (_) => random.nextInt(256)).map((b) => b.toRadixString(16).padLeft(2, '0')).join()}';

    try {
      // Trust exactly the identity key read from the QR code or link for
      // that device. Fails if a different key was trusted for it before.
      await MeyaE2ee.instance.pinIdentity(
        recipientDeviceId,
        recipientIdentityPublicKey,
      );

      await ConnectionRequestRepository(database).createOutgoingRequest(
        requestId: requestId,
        senderIdentityId: localIdentityId,
        senderDeviceId: senderDeviceId,
        senderUsername: account.username,
        senderIdentityPublicKey: localIdentityPublicKey,
        recipientDeviceId: recipientDeviceId,
        recipientIdentityId: recipientIdentityId,
        recipientIdentityPublicKey: recipientIdentityPublicKey,
        createdAt: DateTime.now().toUtc().toIso8601String(),
      );

      await sendConnectionRequest(
        requestId: requestId,
        recipientDeviceId: recipientDeviceId,
        identityId: localIdentityId,
        identityPublicKey: localIdentityPublicKey,
        inviteToken: inviteToken,
      );
    } catch (error) {
      throw PairingException(
        'Could not send connection request: {0}',
        '$error',
      );
    }
  }
}

/// Why a connection could not be started. [message] is English text with
/// an optional `{0}` filled with [detail]; show it with `tr`.
class PairingException implements Exception {
  final String message;
  final String? detail;

  const PairingException(this.message, [this.detail]);

  @override
  String toString() =>
      detail == null ? message : message.replaceAll('{0}', detail!);
}
