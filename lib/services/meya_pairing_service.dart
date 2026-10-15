import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'device_identity_service.dart';
import 'meya_relay_session.dart';

class MeyaPairingService {
  MeyaPairingService._();

  static final MeyaPairingService instance = MeyaPairingService._();

  /// Sends a connection request under [requestId], which must be the ID the
  /// caller already stored for the outgoing request. The reply carries this
  /// ID back, and it is how the reply is matched to the scanned QR identity.
  Future<void> sendConnectionRequest({
    required String requestId,
    required String recipientDeviceId,
    required String identityId,
    required String username,
    required String identityPublicKey,
    required String name,
  }) async {
    final senderDeviceId = await DeviceIdentityService.getDeviceId();

    if (senderDeviceId == null || senderDeviceId.isEmpty) {
      throw StateError('MEYA device ID is not available.');
    }

    final request = buildConnectionRequest(
      requestId: requestId,
      senderDeviceId: senderDeviceId,
      identityId: identityId,
      username: username,
      identityPublicKey: identityPublicKey,
      name: name,
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
        },
      },
    );
  }

  @visibleForTesting
  static Map<String, String> buildConnectionRequest({
    required String requestId,
    required String senderDeviceId,
    required String identityId,
    required String username,
    required String identityPublicKey,
    required String name,
  }) {
    if (requestId.isEmpty) {
      throw ArgumentError.value(requestId, 'requestId', 'must not be empty');
    }

    return {
      'type': 'connection_request',
      'request_id': requestId,
      'sender_device_id': senderDeviceId,
      'sender_identity_id': identityId,
      'sender_username': username,
      'sender_name': name,
      'sender_identity_public_key': identityPublicKey,
    };
  }
}
