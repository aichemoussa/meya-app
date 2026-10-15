import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../database/account_repository.dart';
import '../database/connection_request_repository.dart';
import '../database/contact_repository.dart';
import '../database/meya_database.dart';
import 'device_identity_service.dart';
import 'meya_e2ee.dart';
import 'meya_relay_service.dart';
import 'meya_relay_session.dart';

/// Handles pairing (connection requests and responses) and routes encrypted
/// chat envelopes to the messaging service.
///
/// Pairing with end-to-end encryption:
/// 1. A scans B's QR code (identity key + device ID) and pins B's identity.
/// 2. A sends a connection request carrying A's identity key.
/// 3. B accepts: pins A's identity, creates a one-time pre-key bundle and
///    replies with it.
/// 4. A checks that the reply matches the scanned QR identity and starts the
///    session from the bundle (libsignal verifies the bundle signatures and
///    that its identity equals the pinned one), then sends a first encrypted
///    message so B also has the session.
class MeyaConnectionService {
  MeyaConnectionService._();

  static final MeyaConnectionService instance = MeyaConnectionService._();

  MeyaDatabase? _database;
  void Function(String username)? _onIncomingRequest;
  void Function(String message)? _onSecurityWarning;
  Future<void> Function(String senderDeviceId, Map<String, dynamic> payload)?
      _onChat;
  Future<void> Function(String deviceId)? _onSessionStarted;
  Future<void> Function(String senderDeviceId, Map<String, dynamic> payload)?
      _onBlob;
  E2eeOperations _e2ee = MeyaE2ee.instance;
  Future<String?> Function() _localDeviceIdProvider =
      DeviceIdentityService.getDeviceId;
  void Function(String envelopeId) _acknowledge =
      MeyaRelaySession.instance.acknowledge;

  void configure({
    required MeyaDatabase database,
    void Function(String username)? onIncomingRequest,
    void Function(String message)? onSecurityWarning,
    Future<void> Function(String senderDeviceId, Map<String, dynamic> payload)?
        onChat,
    Future<void> Function(String senderDeviceId, Map<String, dynamic> payload)?
        onBlob,
    Future<void> Function(String deviceId)? onSessionStarted,
  }) {
    _database = database;
    _onIncomingRequest = onIncomingRequest;
    _onSecurityWarning = onSecurityWarning;
    _onChat = onChat;
    _onBlob = onBlob;
    _onSessionStarted = onSessionStarted;
  }

  /// Test-only hook to replace platform services that are unavailable in
  /// unit tests (secure storage, the Rust engine and the live relay).
  @visibleForTesting
  void configureForTesting({
    required MeyaDatabase database,
    required Future<String?> Function() localDeviceIdProvider,
    required E2eeOperations e2ee,
    void Function(String envelopeId)? acknowledge,
    void Function(String username)? onIncomingRequest,
    void Function(String message)? onSecurityWarning,
    Future<void> Function(String senderDeviceId, Map<String, dynamic> payload)?
        onChat,
    Future<void> Function(String deviceId)? onSessionStarted,
  }) {
    _database = database;
    _localDeviceIdProvider = localDeviceIdProvider;
    _e2ee = e2ee;
    _acknowledge = acknowledge ?? (_) {};
    _onIncomingRequest = onIncomingRequest;
    _onSecurityWarning = onSecurityWarning;
    _onChat = onChat;
    _onSessionStarted = onSessionStarted;
  }

  Future<void> handleRelayMessage(Map<String, dynamic> message) async {
    final database = _database;
    if (database == null || message['type'] != 'Envelope') {
      return;
    }

    final envelope = message['envelope'];
    if (envelope is! Map<String, dynamic>) {
      return;
    }

    final envelopeId = envelope['id'];
    if (envelopeId is! String || envelopeId.isEmpty) {
      return;
    }

    // The relay authenticates the sending device, so this is the only sender
    // identifier that can be relied on. Values inside the payload are not.
    final envelopeSenderDeviceId = envelope['sender_device_id'];

    try {
      if (envelopeSenderDeviceId is! String || envelopeSenderDeviceId.isEmpty) {
        return;
      }

      final payload = MeyaRelayService.decodeJsonPayload(envelope);
      final type = payload['type'];

      if (type == 'connection_request') {
        await _handleConnectionRequest(
          database,
          payload,
          envelopeSenderDeviceId,
        );
      } else if (type == 'connection_response') {
        await _handleConnectionResponse(
          database,
          payload,
          envelopeSenderDeviceId,
        );
      } else if (type == 'chat') {
        await _onChat?.call(envelopeSenderDeviceId, payload);
      } else if (type == 'blob') {
        await _onBlob?.call(envelopeSenderDeviceId, payload);
      }
    } catch (error) {
      debugPrint('MEYA connection: rejected relay envelope ($error).');
    } finally {
      _acknowledge(envelopeId);
    }
  }

  Future<void> _handleConnectionRequest(
    MeyaDatabase database,
    Map<String, dynamic> payload,
    String envelopeSenderDeviceId,
  ) async {
    final requestId = payload['request_id'];
    final senderIdentityId = payload['sender_identity_id'];
    final senderDeviceId = payload['sender_device_id'];
    final senderUsername = payload['sender_username'];
    final senderName = payload['sender_name'];
    final senderIdentityPublicKey = payload['sender_identity_public_key'];

    if (requestId is! String ||
        senderIdentityId is! String ||
        senderDeviceId is! String ||
        senderUsername is! String ||
        senderIdentityPublicKey is! String ||
        requestId.isEmpty ||
        senderIdentityId.isEmpty ||
        senderUsername.isEmpty ||
        senderIdentityPublicKey.isEmpty) {
      return;
    }

    // A device may only send requests in its own name.
    if (senderDeviceId != envelopeSenderDeviceId) {
      _warn('A connection request was rejected because its sender could not be confirmed.');
      return;
    }

    final localDeviceId = await _localDeviceIdProvider();
    if (localDeviceId == null || localDeviceId.isEmpty) {
      return;
    }

    final repository = ConnectionRequestRepository(database);
    final isNew = await repository.createIncomingRequest(
      requestId: requestId,
      senderIdentityId: senderIdentityId,
      senderDeviceId: senderDeviceId,
      senderUsername: senderUsername,
      senderIdentityPublicKey: senderIdentityPublicKey,
      recipientDeviceId: localDeviceId,
      createdAt: DateTime.now().toUtc().toIso8601String(),
    );

    // Only announce requests that actually appear in Invitations.
    if (!isNew) {
      debugPrint('MEYA connection: duplicate connection request ignored.');
      return;
    }

    _onIncomingRequest?.call(
      senderName is String && senderName.trim().isNotEmpty
          ? senderName.trim()
          : '@$senderUsername',
    );
  }

  Future<void> _handleConnectionResponse(
    MeyaDatabase database,
    Map<String, dynamic> payload,
    String envelopeSenderDeviceId,
  ) async {
    final requestId = payload['request_id'];
    final status = payload['status'];

    if (requestId is! String ||
        requestId.isEmpty ||
        (status != 'accepted' && status != 'declined')) {
      return;
    }

    final localDeviceId = await _localDeviceIdProvider();
    if (localDeviceId == null || localDeviceId.isEmpty) {
      return;
    }

    final requests = ConnectionRequestRepository(database);
    final request = await requests.getRequestById(requestId);

    // Only a reply to a request this device sent, that is still pending, and
    // that comes from the exact device the request was sent to is accepted.
    if (request == null ||
        request.status != 'pending' ||
        request.senderDeviceId != localDeviceId ||
        request.recipientDeviceId != envelopeSenderDeviceId) {
      _warn('An unexpected connection response was ignored.');
      return;
    }

    if (status == 'declined') {
      await requests.updateStatus(requestId: requestId, status: 'declined');
      return;
    }

    final identityId = payload['identity_id'];
    final username = payload['username'];
    final name = payload['name'];
    final publicKey = payload['identity_public_key'];
    final bundle = payload['pre_key_bundle'];

    if (identityId is! String ||
        username is! String ||
        name is! String ||
        publicKey is! String ||
        identityId.isEmpty ||
        username.isEmpty ||
        publicKey.isEmpty) {
      return;
    }

    // The reply must come from the identity whose QR code was scanned, with
    // the exact identity key shown in that QR code. Otherwise a different
    // key could be substituted on the way.
    final expectedIdentityId = request.recipientIdentityId;
    final expectedPublicKey = request.recipientIdentityPublicKey;

    if (expectedIdentityId == null ||
        expectedIdentityId.isEmpty ||
        expectedPublicKey == null ||
        expectedPublicKey.isEmpty) {
      _warn(
        'This connection request was created by an older version of MEYA. '
        'Scan the QR code of @$username again.',
      );
      return;
    }

    if (identityId != expectedIdentityId || publicKey != expectedPublicKey) {
      _warn(
        'The reply from @$username does not match the QR code you scanned. '
        'The connection was not trusted.',
      );
      return;
    }

    if (bundle is! String || bundle.isEmpty) {
      _warn(
        '@$username uses an older version of MEYA without encrypted messaging. '
        'Ask them to update MEYA, then connect again.',
      );
      return;
    }

    // Start the end-to-end encrypted session. libsignal checks the bundle's
    // signatures and that its identity equals the identity pinned from the QR.
    try {
      await _e2ee.startSession(envelopeSenderDeviceId, bundle);
    } catch (error) {
      _warn(
        'A secure session with @$username could not be established. '
        'The connection was not trusted.',
      );
      debugPrint('MEYA connection: session setup failed ($error).');
      return;
    }

    final contactId = 'contact_$identityId';
    try {
      await database.transaction(() async {
        final contacts = ContactRepository(database);
        await contacts.upsertTrustedContact(
          contactId: contactId,
          identityId: identityId,
          displayName: name.trim().isEmpty ? '@$username' : name.trim(),
          identityPublicKey: publicKey,
          updatedAt: DateTime.now().toUtc().toIso8601String(),
        );
        await contacts.upsertContactDevice(
          contactId: contactId,
          deviceId: envelopeSenderDeviceId,
          identityPublicKey: publicKey,
        );
        await requests.updateStatus(requestId: requestId, status: 'accepted');
      });
    } on IdentityKeyChangedException {
      _warn(
        'The identity key of @$username has changed. The connection was not '
        'trusted. Verify this person again in person.',
      );
      return;
    }

    try {
      await _onSessionStarted?.call(envelopeSenderDeviceId);
    } catch (error) {
      debugPrint('MEYA connection: first encrypted message failed ($error).');
    }
  }

  void _warn(String message) {
    debugPrint('MEYA security: $message');
    _onSecurityWarning?.call(message);
  }

  Future<void> acceptRequest(String requestId) async {
    final database = _database;
    if (database == null) {
      throw StateError('MEYA connection service is not configured.');
    }

    final request =
        await ConnectionRequestRepository(database).getRequestById(requestId);
    if (request == null || request.status != 'pending') {
      throw StateError('MEYA connection request is no longer pending.');
    }

    final account = await AccountRepository(database).getActiveAccount();
    final localDeviceId = await _localDeviceIdProvider();

    if (account == null || localDeviceId == null || localDeviceId.isEmpty) {
      throw StateError('MEYA account or device identity is unavailable.');
    }

    final localIdentityKey = await _e2ee.open();

    // Trust the requester's identity on this device (fails if a different
    // key is already trusted for that device), then prepare a one-time
    // bundle so they can start the encrypted session.
    await _e2ee.pinIdentity(
      request.senderDeviceId,
      request.senderIdentityPublicKey,
    );
    final bundle = await _e2ee.createPreKeyBundle();

    final now = DateTime.now().toUtc().toIso8601String();
    final contactId = 'contact_${request.senderIdentityId}';

    // Throws IdentityKeyChangedException if this person is already a contact
    // with a different key; the request then stays pending.
    await database.transaction(() async {
      final contacts = ContactRepository(database);
      await contacts.upsertTrustedContact(
        contactId: contactId,
        identityId: request.senderIdentityId,
        displayName: request.senderUsername,
        identityPublicKey: request.senderIdentityPublicKey,
        updatedAt: now,
      );
      await contacts.upsertContactDevice(
        contactId: contactId,
        deviceId: request.senderDeviceId,
        identityPublicKey: request.senderIdentityPublicKey,
      );

      await ConnectionRequestRepository(database).accept(requestId);
    });

    await _sendResponse(
      buildConnectionResponse(
        requestId: requestId,
        status: 'accepted',
        account: account,
        deviceId: localDeviceId,
        identityPublicKey: localIdentityKey,
        preKeyBundle: bundle,
      ),
      requestId: requestId,
      recipientDeviceId: request.senderDeviceId,
      deviceId: localDeviceId,
    );
  }

  Future<void> declineRequest(String requestId) async {
    final database = _database;
    if (database == null) {
      throw StateError('MEYA connection service is not configured.');
    }

    final request =
        await ConnectionRequestRepository(database).getRequestById(requestId);
    if (request == null || request.status != 'pending') {
      throw StateError('MEYA connection request is no longer pending.');
    }

    await ConnectionRequestRepository(database).decline(requestId);

    final account = await AccountRepository(database).getActiveAccount();
    final localDeviceId = await _localDeviceIdProvider();

    if (account == null || localDeviceId == null || localDeviceId.isEmpty) {
      return;
    }

    await _sendResponse(
      buildConnectionResponse(
        requestId: requestId,
        status: 'declined',
        account: account,
        deviceId: localDeviceId,
      ),
      requestId: requestId,
      recipientDeviceId: request.senderDeviceId,
      deviceId: localDeviceId,
    );
  }

  Future<void> _sendResponse(
    Map<String, String> payload, {
    required String requestId,
    required String recipientDeviceId,
    required String deviceId,
  }) async {
    final bytes = utf8.encode(jsonEncode(payload));
    final envelopeId = '${deviceId}_${requestId}_${payload['status']}';

    await MeyaRelaySession.instance.sendWhenConnected(
      message: {
        'type': 'Send',
        'envelope': {
          'id': envelopeId,
          'sender_device_id': deviceId,
          'recipient_device_id': recipientDeviceId,
          'payload': base64Encode(bytes),
        },
      },
    );
  }

  @visibleForTesting
  static Map<String, String> buildConnectionResponse({
    required String requestId,
    required String status,
    required Account account,
    required String deviceId,
    String? identityPublicKey,
    String? preKeyBundle,
  }) {
    return {
      'type': 'connection_response',
      'request_id': requestId,
      'status': status,
      'identity_id': account.identityId ?? account.accountId,
      'username': account.username,
      'name': account.name,
      'identity_public_key': identityPublicKey ?? account.identityPublicKey,
      'device_id': deviceId,
      'pre_key_bundle': ?preKeyBundle,
    };
  }
}
