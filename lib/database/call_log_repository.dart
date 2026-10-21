import 'package:drift/drift.dart';

import 'meya_database.dart';

/// One call in the Calls tab, with the contact it was with.
class CallLogEntry {
  final CallLog call;
  final Contact? contact;

  const CallLogEntry(this.call, this.contact);

  /// Rang here and nobody answered (declining is not missing).
  bool get missed =>
      !call.outgoing && call.outcome != 'answered' && call.outcome != 'declined';
  DateTime get startedAt => DateTime.parse(call.startedAt).toLocal();
}

/// Stores the calls made, received and missed on this phone. Only on this
/// phone: the other person keeps their own list.
class CallLogRepository {
  final MeyaDatabase database;

  CallLogRepository(this.database);

  /// Keeps the list to a sensible size.
  static const int maxEntries = 500;

  Future<void> add({
    required String callId,
    required String contactId,
    required bool outgoing,
    required bool video,
    required DateTime startedAt,
    required int durationSeconds,
    required String outcome,
  }) async {
    await database.into(database.callLogs).insertOnConflictUpdate(
          CallLogsCompanion.insert(
            callId: callId,
            contactId: contactId,
            outgoing: outgoing,
            video: video,
            startedAt: startedAt.toUtc().toIso8601String(),
            durationSeconds: Value(durationSeconds),
            outcome: outcome,
          ),
        );
    final old = await (database.select(database.callLogs)
          ..orderBy([(c) => OrderingTerm.desc(c.startedAt)])
          ..limit(1000000, offset: maxEntries))
        .get();
    if (old.isNotEmpty) {
      await (database.delete(database.callLogs)
            ..where((c) => c.callId.isIn(old.map((e) => e.callId))))
          .go();
    }
  }

  /// Newest first, updating whenever a call is added or the list cleared.
  Stream<List<CallLogEntry>> watch() {
    final query = database.select(database.callLogs).join([
      leftOuterJoin(
        database.contacts,
        database.contacts.contactId.equalsExp(database.callLogs.contactId),
      ),
    ])
      ..orderBy([OrderingTerm.desc(database.callLogs.startedAt)]);
    return query.watch().map(
          (rows) => [
            for (final row in rows)
              CallLogEntry(
                row.readTable(database.callLogs),
                row.readTableOrNull(database.contacts),
              ),
          ],
        );
  }

  Future<void> clear() => database.delete(database.callLogs).go();
}
