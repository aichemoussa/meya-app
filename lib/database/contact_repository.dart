import 'package:drift/drift.dart';

import 'meya_database.dart';

/// Thrown when a known contact presents a different identity public key.
class IdentityKeyChangedException implements Exception {
  final String identityId;
  final String storedPublicKey;
  final String receivedPublicKey;

  const IdentityKeyChangedException({
    required this.identityId,
    required this.storedPublicKey,
    required this.receivedPublicKey,
  });

  @override
  String toString() =>
      'The identity key for this MEYA contact has changed. '
      'The contact must be verified again before it can be trusted.';
}

class ContactRepository {
  final MeyaDatabase database;

  ContactRepository(this.database);

  Future<Contact?> getContactByIdentityId(String identityId) {
    return (database.select(database.contacts)
          ..where((contact) => contact.identityId.equals(identityId))
          ..limit(1))
        .getSingleOrNull();
  }

  Future<Contact?> getContactById(String contactId) {
    return (database.select(database.contacts)
          ..where((contact) => contact.contactId.equals(contactId))
          ..limit(1))
        .getSingleOrNull();
  }

  /// Trusted, non-revoked contacts, excluding this device's own identity.
  Future<List<Contact>> getTrustedContacts({String? excludeIdentityId}) async {
    final contacts = await getContacts();
    return contacts
        .where(
          (contact) =>
              contact.trustState == 'trusted' &&
              !contact.isRevoked &&
              (excludeIdentityId == null ||
                  contact.identityId != excludeIdentityId),
        )
        .toList();
  }

  /// Records the relay device ID used to reach a contact, with the identity
  /// key trusted for it.
  Future<void> upsertContactDevice({
    required String contactId,
    required String deviceId,
    required String identityPublicKey,
  }) async {
    final now = DateTime.now().toUtc().toIso8601String();
    await database.into(database.contactDevices).insertOnConflictUpdate(
          ContactDevicesCompanion.insert(
            deviceId: deviceId,
            contactId: contactId,
            devicePublicKey: identityPublicKey,
            certificateSignature: '',
            keyPackage: Uint8List(0),
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  Future<String?> getDeviceIdForContact(String contactId) async {
    final device = await (database.select(database.contactDevices)
          ..where(
            (d) => d.contactId.equals(contactId) & d.isRevoked.equals(false),
          )
          ..limit(1))
        .getSingleOrNull();
    return device?.deviceId;
  }

  Future<Contact?> getContactByDeviceId(String deviceId) async {
    final device = await (database.select(database.contactDevices)
          ..where((d) => d.deviceId.equals(deviceId) & d.isRevoked.equals(false))
          ..limit(1))
        .getSingleOrNull();
    if (device == null) return null;
    final contact = await getContactById(device.contactId);
    if (contact == null || contact.isRevoked || contact.trustState != 'trusted') {
      return null;
    }
    return contact;
  }

  /// Removes a contact from this device, together with rows that point to it.
  Future<void> deleteContact(String contactId) async {
    await database.transaction(() async {
      await (database.delete(database.contactDevices)
            ..where((device) => device.contactId.equals(contactId)))
          .go();
      await (database.update(database.conversationParticipants)
            ..where((participant) => participant.contactId.equals(contactId)))
          .write(const ConversationParticipantsCompanion(contactId: Value(null)));
      await (database.delete(database.contacts)
            ..where((contact) => contact.contactId.equals(contactId)))
          .go();
    });
  }

  Future<List<Contact>> getContacts() {
    return (database.select(database.contacts)..orderBy([
          (contact) => OrderingTerm(
            expression: contact.displayName,
            mode: OrderingMode.asc,
          ),
        ]))
        .get();
  }

  Future<Contact> createPendingContact({
    required String contactId,
    required String identityId,
    required String displayName,
    required String identityPublicKey,
    required String createdAt,
  }) async {
    await database
        .into(database.contacts)
        .insert(
          ContactsCompanion.insert(
            contactId: contactId,
            identityId: identityId,
            displayName: displayName,
            identityPublicKey: identityPublicKey,
            trustState: const Value('pending'),
            createdAt: createdAt,
            updatedAt: createdAt,
            isRevoked: const Value(false),
          ),
        );

    return (await getContactById(contactId))!;
  }

  Future<void> updateTrustState({
    required String contactId,
    required String trustState,
  }) async {
    await (database.update(
      database.contacts,
    )..where((contact) => contact.contactId.equals(contactId))).write(
      ContactsCompanion(
        trustState: Value(trustState),
        updatedAt: Value(DateTime.now().toUtc().toIso8601String()),
      ),
    );
  }
  Future<Contact> upsertTrustedContact({
    required String contactId,
    required String identityId,
    required String displayName,
    required String identityPublicKey,
    required String updatedAt,
  }) async {
    final existing = await getContactByIdentityId(identityId);

    if (existing == null) {
      await database.into(database.contacts).insert(
            ContactsCompanion.insert(
              contactId: contactId,
              identityId: identityId,
              displayName: displayName,
              identityPublicKey: identityPublicKey,
              trustState: const Value('trusted'),
              createdAt: updatedAt,
              updatedAt: updatedAt,
              isRevoked: const Value(false),
            ),
          );
    } else {
      // A trusted identity key must never be replaced silently. A different
      // key for the same identity requires an explicit re-verification flow.
      //
      // Exception: contacts paired before end-to-end encryption existed have
      // no device record and never had an encryption key. A new in-person QR
      // pairing (or an explicitly accepted request) may upgrade them.
      final hasEncryptedDevice = await (database.select(database.contactDevices)
            ..where((d) => d.contactId.equals(existing.contactId))
            ..limit(1))
          .getSingleOrNull();
      if (hasEncryptedDevice != null &&
          existing.identityPublicKey != identityPublicKey) {
        throw IdentityKeyChangedException(
          identityId: identityId,
          storedPublicKey: existing.identityPublicKey,
          receivedPublicKey: identityPublicKey,
        );
      }

      await (database.update(database.contacts)
            ..where((contact) => contact.contactId.equals(existing.contactId)))
          .write(
        ContactsCompanion(
          displayName: Value(displayName),
          identityPublicKey: Value(identityPublicKey),
          trustState: const Value('trusted'),
          updatedAt: Value(updatedAt),
          isRevoked: const Value(false),
        ),
      );
    }

    return (await getContactByIdentityId(identityId))!;
  }

}
