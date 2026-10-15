import 'package:drift/drift.dart';

import 'meya_database.dart';

class ConnectionRequestRepository {
  final MeyaDatabase database;

  ConnectionRequestRepository(this.database);

  Future<ConnectionRequest?> getRequestById(String requestId) {
    return (database.select(database.connectionRequests)
          ..where((request) => request.requestId.equals(requestId))
          ..limit(1))
        .getSingleOrNull();
  }

  Future<ConnectionRequest?> getPendingRequestByIdentityId(String identityId) {
    return (database.select(database.connectionRequests)
          ..where(
            (request) =>
                request.senderIdentityId.equals(identityId) &
                request.status.equals('pending'),
          )
          ..limit(1))
        .getSingleOrNull();
  }

  Future<List<ConnectionRequest>> getIncomingPendingRequests(
    String localDeviceId,
  ) {
    return (database.select(database.connectionRequests)
          ..where(
            (request) =>
                request.recipientDeviceId.equals(localDeviceId) &
                request.status.equals('pending'),
          )
          ..orderBy([
            (request) => OrderingTerm(
              expression: request.createdAt,
              mode: OrderingMode.desc,
            ),
          ]))
        .get();
  }

  Future<List<ConnectionRequest>> getOutgoingPendingRequests(
    String localDeviceId,
  ) {
    return (database.select(database.connectionRequests)
          ..where(
            (request) =>
                request.senderDeviceId.equals(localDeviceId) &
                request.status.equals('pending'),
          )
          ..orderBy([
            (request) => OrderingTerm(
              expression: request.createdAt,
              mode: OrderingMode.desc,
            ),
          ]))
        .get();
  }

  Future<void> createOutgoingRequest({
    required String requestId,
    required String senderIdentityId,
    required String senderDeviceId,
    required String senderUsername,
    required String senderIdentityPublicKey,
    required String recipientDeviceId,
    required String recipientIdentityId,
    required String recipientIdentityPublicKey,
    required String createdAt,
  }) async {
    if (recipientIdentityId.isEmpty || recipientIdentityPublicKey.isEmpty) {
      throw ArgumentError(
        'An outgoing request must record the scanned identity and key.',
      );
    }

    final existing = await getRequestById(requestId);

    // An accepted connection is final. Any other earlier attempt is replaced
    // by this scan, so the expected identity always reflects the latest QR.
    if (existing != null && existing.status == 'accepted') {
      return;
    }

    await database
        .into(database.connectionRequests)
        .insertOnConflictUpdate(
          ConnectionRequestsCompanion.insert(
            requestId: requestId,
            senderIdentityId: senderIdentityId,
            senderDeviceId: senderDeviceId,
            senderUsername: senderUsername,
            senderIdentityPublicKey: senderIdentityPublicKey,
            recipientDeviceId: recipientDeviceId,
            recipientIdentityId: Value(recipientIdentityId),
            recipientIdentityPublicKey: Value(recipientIdentityPublicKey),
            status: const Value('pending'),
            createdAt: createdAt,
            updatedAt: createdAt,
          ),
        );
  }

  /// Returns true when the request is new, false when it was already known.
  Future<bool> createIncomingRequest({
    required String requestId,
    required String senderIdentityId,
    required String senderDeviceId,
    required String senderUsername,
    required String senderIdentityPublicKey,
    required String recipientDeviceId,
    required String createdAt,
  }) async {
    final existing = await getRequestById(requestId);

    if (existing != null) {
      return false;
    }

    await database
        .into(database.connectionRequests)
        .insert(
          ConnectionRequestsCompanion.insert(
            requestId: requestId,
            senderIdentityId: senderIdentityId,
            senderDeviceId: senderDeviceId,
            senderUsername: senderUsername,
            senderIdentityPublicKey: senderIdentityPublicKey,
            recipientDeviceId: recipientDeviceId,
            status: const Value('pending'),
            createdAt: createdAt,
            updatedAt: createdAt,
          ),
        );
    return true;
  }

  Future<void> updateStatus({
    required String requestId,
    required String status,
  }) async {
    await (database.update(
      database.connectionRequests,
    )..where((request) => request.requestId.equals(requestId))).write(
      ConnectionRequestsCompanion(
        status: Value(status),
        updatedAt: Value(DateTime.now().toUtc().toIso8601String()),
      ),
    );
  }

  Future<void> accept(String requestId) {
    return updateStatus(requestId: requestId, status: 'accepted');
  }

  Future<void> decline(String requestId) {
    return updateStatus(requestId: requestId, status: 'declined');
  }
}
