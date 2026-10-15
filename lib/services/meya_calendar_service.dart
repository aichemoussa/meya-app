import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../database/meya_database.dart';
import 'meya_e2ee.dart';
import 'meya_message_service.dart';
import '../l10n/meya_strings.dart';

/// A planned call in the MEYA calendar.
class CalendarEvent {
  final CallPlan plan;
  final String contactId;
  final String contactName;
  final bool createdByMe;
  final bool cancelled;

  const CalendarEvent({
    required this.plan,
    required this.contactId,
    required this.contactName,
    required this.createdByMe,
    required this.cancelled,
  });

  DateTime get start => plan.start;
  DateTime get end => plan.start.add(Duration(minutes: plan.durationMinutes));

  CalendarEvent copyWith({bool? cancelled, CallPlan? plan}) => CalendarEvent(
        plan: plan ?? this.plan,
        contactId: contactId,
        contactName: contactName,
        createdByMe: createdByMe,
        cancelled: cancelled ?? this.cancelled,
      );

  Map<String, Object> toJson() => {
        ...plan.toContent(),
        'contact_id': contactId,
        'contact_name': contactName,
        'mine': createdByMe,
        'cancelled': cancelled,
      };

  static CalendarEvent? fromJson(Map<String, dynamic> json) {
    final plan = CallPlan.fromContent(json);
    final contactId = json['contact_id'];
    final contactName = json['contact_name'];
    if (plan == null || contactId is! String || contactName is! String) {
      return null;
    }
    return CalendarEvent(
      plan: plan,
      contactId: contactId,
      contactName: contactName,
      createdByMe: json['mine'] == true,
      cancelled: json['cancelled'] == true,
    );
  }
}

/// Keeps planned calls on this device (sealed with the local storage key)
/// and shares them with the other person through encrypted messages.
class MeyaCalendarService {
  MeyaCalendarService._();

  static final MeyaCalendarService instance = MeyaCalendarService._();

  E2eeOperations _e2ee = MeyaE2ee.instance;
  Directory? _testRoot;
  final StreamController<void> _changes = StreamController.broadcast();
  List<CalendarEvent>? _cache;

  Stream<void> get changes => _changes.stream;

  @visibleForTesting
  void configureForTesting({
    required E2eeOperations e2ee,
    required Directory directory,
  }) {
    _e2ee = e2ee;
    _testRoot = directory;
    _cache = null;
  }

  Future<File> _file() async {
    final base = _testRoot ?? await getApplicationSupportDirectory();
    final directory = Directory(p.join(base.path, 'meya_calendar'));
    await directory.create(recursive: true);
    return File(p.join(directory.path, 'events.bin'));
  }

  Future<List<CalendarEvent>> events() async {
    final cached = _cache;
    if (cached != null) return List.of(cached);
    final file = await _file();
    var events = <CalendarEvent>[];
    if (await file.exists()) {
      try {
        final plain = await _e2ee.openLocal(await file.readAsBytes(), 'calendar');
        final json = jsonDecode(utf8.decode(plain));
        if (json is List) {
          events = json
              .whereType<Map<String, dynamic>>()
              .map(CalendarEvent.fromJson)
              .whereType<CalendarEvent>()
              .toList();
        }
      } catch (error) {
        debugPrint('MEYA calendar: stored events could not be opened.');
      }
    }
    events.sort((a, b) => a.start.compareTo(b.start));
    _cache = events;
    return List.of(events);
  }

  Future<void> _save(List<CalendarEvent> events) async {
    events.sort((a, b) => a.start.compareTo(b.start));
    final sealed = await _e2ee.sealLocal(
      Uint8List.fromList(
        utf8.encode(jsonEncode(events.map((e) => e.toJson()).toList())),
      ),
      'calendar',
    );
    await (await _file()).writeAsBytes(sealed, flush: true);
    _cache = events;
    _changes.add(null);
  }

  Future<void> _upsert(CalendarEvent event) async {
    final events = await this.events();
    events.removeWhere((e) => e.plan.eventId == event.plan.eventId);
    events.add(event);
    await _save(events);
  }

  /// Events on [day] (local time), including ones that started before.
  Future<List<CalendarEvent>> eventsOn(DateTime day) async {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    return (await events())
        .where((e) => e.start.isBefore(end) && e.end.isAfter(start))
        .toList();
  }

  Future<List<CalendarEvent>> upcoming({int limit = 5}) async {
    final now = DateTime.now();
    return (await events())
        .where((e) => !e.cancelled && e.end.isAfter(now))
        .take(limit)
        .toList();
  }

  /// Plans a call with [contact] and sends them the invitation.
  Future<CalendarEvent> schedule({
    required Contact contact,
    required String title,
    required DateTime start,
    required int durationMinutes,
    required String callType,
    String note = '',
  }) async {
    final plan = CallPlan(
      eventId: MeyaMessageService.newId(),
      title: title.trim().isEmpty ? tr('Call with {0}', [contact.displayName]) : title.trim(),
      start: start,
      durationMinutes: durationMinutes,
      callType: callType,
      note: note.trim(),
    );
    final event = CalendarEvent(
      plan: plan,
      contactId: contact.contactId,
      contactName: contact.displayName,
      createdByMe: true,
      cancelled: false,
    );
    await _upsert(event);
    await MeyaMessageService.instance.sendCallPlan(contact, plan);
    return event;
  }

  Future<void> cancel(CalendarEvent event, Contact? contact) async {
    await _upsert(event.copyWith(cancelled: true));
    if (contact != null) {
      await MeyaMessageService.instance.sendCallCancel(contact, event.plan);
    }
  }

  /// Removes an event from this device only.
  Future<void> remove(CalendarEvent event) async {
    final events = await this.events();
    events.removeWhere((e) => e.plan.eventId == event.plan.eventId);
    await _save(events);
  }

  /// Called by the messaging service when a contact plans or cancels a call.
  Future<void> handleIncoming(Contact contact, String kind, CallPlan plan) async {
    final existing = (await events())
        .where((e) => e.plan.eventId == plan.eventId)
        .firstOrNull;
    // Only the person who created an event may change it.
    if (existing != null && existing.contactId != contact.contactId) return;
    if (existing != null && existing.createdByMe) {
      // The other person can decline a call planned by this person.
      if (kind == 'call_cancel') {
        await _upsert(existing.copyWith(cancelled: true));
      }
      return;
    }
    await _upsert(
      CalendarEvent(
        plan: plan,
        contactId: contact.contactId,
        contactName: contact.displayName,
        createdByMe: false,
        cancelled: kind == 'call_cancel',
      ),
    );
  }

  Future<void> deleteAll() async {
    final file = await _file();
    if (await file.exists()) await file.delete();
    _cache = null;
  }
}
