import 'dart:async';

import 'package:flutter/material.dart';

import '../database/contact_repository.dart';
import '../database/meya_database.dart';
import '../services/meya_calendar_service.dart';
import '../services/meya_message_service.dart';
import '../theme/meya_theme.dart';
import 'call_page.dart';
import 'chat_page.dart';
import '../l10n/meya_strings.dart';

/// "Mon, Oct 14 · 15:00 – 15:30", in the phone's language and clock format.
String formatCallTime(BuildContext context, DateTime start, int minutes) {
  final localizations = MaterialLocalizations.of(context);
  final use24h = MediaQuery.alwaysUse24HourFormatOf(context);
  final end = start.add(Duration(minutes: minutes));
  String time(DateTime t) => localizations.formatTimeOfDay(
        TimeOfDay.fromDateTime(t),
        alwaysUse24HourFormat: use24h,
      );
  return '${localizations.formatMediumDate(start)} · ${time(start)} – ${time(end)}';
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Month calendar with the calls planned with MEYA contacts.
class CalendarPage extends StatefulWidget {
  final MeyaDatabase database;

  const CalendarPage({super.key, required this.database});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  final _calendar = MeyaCalendarService.instance;
  late DateTime _month;
  late DateTime _selected;
  List<CalendarEvent> _events = [];
  StreamSubscription<void>? _subscription;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
    _selected = DateTime(now.year, now.month, now.day);
    _subscription = _calendar.changes.listen((_) => _load());
    _load();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final events = await _calendar.events();
    if (!mounted) return;
    setState(() => _events = events);
  }

  List<CalendarEvent> _eventsOn(DateTime day) {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    return _events
        .where((e) => e.start.isBefore(end) && e.end.isAfter(start))
        .toList();
  }

  void _changeMonth(int delta) {
    setState(() => _month = DateTime(_month.year, _month.month + delta));
  }

  Future<void> _schedule() async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => ScheduleCallPage(
          database: widget.database,
          initialDay: _selected,
        ),
      ),
    );
    await _load();
  }

  Future<Contact?> _contactOf(CalendarEvent event) =>
      ContactRepository(widget.database).getContactById(event.contactId);

  Future<void> _join(CalendarEvent event) async {
    final contact = await _contactOf(event);
    if (contact == null || !mounted) return;
    await startCallWith(
      context,
      contact,
      video: event.plan.callType == 'video',
    );
  }

  Future<void> _cancel(CalendarEvent event) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(event.createdByMe ? context.tr('Cancel this call?') : context.tr('Decline this call?')),
        content: Text(context.tr('{0} will be told in an encrypted message.', [event.contactName])),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.tr('Keep')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(event.createdByMe ? context.tr('Cancel call') : context.tr('Decline')),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _calendar.cancel(event, await _contactOf(event));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('Cancelled here, but {0} could not be told yet: {1}', [event.contactName, error]))),
      );
    }
  }

  Future<void> _openChat(CalendarEvent event) async {
    final contact = await _contactOf(event);
    if (contact == null || !mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => ChatPage(database: widget.database, contact: contact),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);
    final dayEvents = _eventsOn(_selected);

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('Calendar'))),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _schedule,
        icon: const Icon(Icons.add),
        label: Text(context.tr('Schedule a call')),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          tooltip: context.tr('Previous month'),
                          onPressed: () => _changeMonth(-1),
                          icon: const Icon(Icons.chevron_left),
                        ),
                        Expanded(
                          child: Semantics(
                            header: true,
                            liveRegion: true,
                            child: Text(
                              localizations.formatMonthYear(_month),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: context.tr('Next month'),
                          onPressed: () => _changeMonth(1),
                          icon: const Icon(Icons.chevron_right),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _MonthGrid(
                      month: _month,
                      selected: _selected,
                      hasEvents: (day) =>
                          _eventsOn(day).any((e) => !e.cancelled),
                      onSelect: (day) => setState(() => _selected = day),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Semantics(
              header: true,
              child: Text(
                localizations.formatFullDate(_selected),
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 8),
            if (dayEvents.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  context.tr('No calls planned on this day.'),
                  style: TextStyle(color: context.meya.muted),
                ),
              ),
            for (final event in dayEvents)
              _EventCard(
                event: event,
                onCancel: () => _cancel(event),
                onRemove: () => _calendar.remove(event),
                onMessage: () => _openChat(event),
                onJoin: () => _join(event),
              ),
            const SizedBox(height: 16),
            Text(
              context.tr('Planned calls are shared end-to-end encrypted with the other person. When it is time, tap Join call to start the call. You can also call any time from a chat.'),
              style: TextStyle(color: context.meya.muted, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthGrid extends StatelessWidget {
  final DateTime month;
  final DateTime selected;
  final bool Function(DateTime day) hasEvents;
  final ValueChanged<DateTime> onSelect;

  const _MonthGrid({
    required this.month,
    required this.selected,
    required this.hasEvents,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);
    final firstWeekday = localizations.firstDayOfWeekIndex; // 0 = Sunday
    final weekdayNames = localizations.narrowWeekdays;
    final first = DateTime(month.year, month.month);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final offset = (first.weekday % 7 - firstWeekday + 7) % 7;
    final today = DateTime.now();
    final colors = context.meya;

    final cells = <Widget>[
      for (var i = 0; i < 7; i++)
        ExcludeSemantics(
          child: Center(
            child: Text(
              weekdayNames[(firstWeekday + i) % 7],
              style: TextStyle(color: colors.muted, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      for (var i = 0; i < offset; i++) const SizedBox.shrink(),
      for (var d = 1; d <= daysInMonth; d++)
        Builder(
          builder: (context) {
            final day = DateTime(month.year, month.month, d);
            final isSelected = _sameDay(day, selected);
            final isToday = _sameDay(day, today);
            final events = hasEvents(day);
            return Semantics(
              selected: isSelected,
              button: true,
              label: events
                  ? context.tr('{0}, calls planned', [localizations.formatFullDate(day)])
                  : localizations.formatFullDate(day),
              excludeSemantics: true,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => onSelect(day),
                child: Container(
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.navy : null,
                    borderRadius: BorderRadius.circular(12),
                    border: isToday && !isSelected
                        ? Border.all(color: colors.navy, width: 1.5)
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$d',
                        style: TextStyle(
                          color: isSelected ? colors.onNavy : colors.text,
                          fontWeight:
                              isToday ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: events
                              ? (isSelected ? colors.onNavy : colors.navy)
                              : Colors.transparent,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
    ];

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1,
      children: cells,
    );
  }
}

class _EventCard extends StatelessWidget {
  final CalendarEvent event;
  final VoidCallback onCancel;
  final VoidCallback onRemove;
  final VoidCallback onMessage;
  final VoidCallback onJoin;

  const _EventCard({
    required this.event,
    required this.onCancel,
    required this.onRemove,
    required this.onMessage,
    required this.onJoin,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.meya;
    final past = event.end.isBefore(DateTime.now());
    // The call can be joined from 15 minutes before it starts until it ends.
    final joinable = !event.cancelled &&
        !past &&
        DateTime.now().isAfter(
          event.start.subtract(const Duration(minutes: 15)),
        );
    final status = event.cancelled
        ? context.tr('Cancelled')
        : past
            ? context.tr('Finished')
            : event.createdByMe
                ? context.tr('You planned this call')
                : context.tr('{0} planned this call', [event.contactName]);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  event.plan.callType == 'video'
                      ? Icons.videocam_outlined
                      : Icons.call_outlined,
                  color: event.cancelled ? colors.muted : colors.navy,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    event.plan.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      decoration:
                          event.cancelled ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              formatCallTime(context, event.start, event.plan.durationMinutes),
              style: TextStyle(color: colors.text),
            ),
            Text(
              context.tr('With {0} · {1}', [event.contactName, status]),
              style: TextStyle(color: colors.muted),
            ),
            if (event.plan.note.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(event.plan.note),
            ],
            Wrap(
              spacing: 4,
              children: [
                if (joinable)
                  FilledButton.icon(
                    onPressed: onJoin,
                    icon: Icon(
                      event.plan.callType == 'video'
                          ? Icons.videocam
                          : Icons.call,
                    ),
                    label: Text(context.tr('Join call')),
                  ),
                TextButton.icon(
                  onPressed: onMessage,
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: Text(context.tr('Message')),
                ),
                if (!event.cancelled && !past)
                  TextButton.icon(
                    onPressed: onCancel,
                    icon: const Icon(Icons.event_busy_outlined),
                    label: Text(event.createdByMe ? context.tr('Cancel call') : context.tr('Decline')),
                  )
                else
                  TextButton.icon(
                    onPressed: onRemove,
                    icon: const Icon(Icons.delete_outline),
                    label: Text(context.tr('Remove')),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Plans a voice or video call with a contact and sends them the invitation.
class ScheduleCallPage extends StatefulWidget {
  final MeyaDatabase database;
  final Contact? contact;
  final DateTime? initialDay;

  const ScheduleCallPage({
    super.key,
    required this.database,
    this.contact,
    this.initialDay,
  });

  @override
  State<ScheduleCallPage> createState() => _ScheduleCallPageState();
}

class _ScheduleCallPageState extends State<ScheduleCallPage> {
  final _title = TextEditingController();
  final _note = TextEditingController();
  List<Contact> _contacts = [];
  Contact? _contact;
  late DateTime _day;
  TimeOfDay _time = const TimeOfDay(hour: 10, minute: 0);
  int _duration = 30;
  String _callType = 'video';
  bool _saving = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final initial = widget.initialDay;
    _day = initial == null || initial.isBefore(DateTime(now.year, now.month, now.day))
        ? DateTime(now.year, now.month, now.day)
        : initial;
    // Next full hour, so the default is never in the past.
    final nextHour = now.add(const Duration(hours: 1));
    _time = TimeOfDay(hour: nextHour.hour, minute: 0);
    if (_sameDay(_day, now) && nextHour.day != now.day) {
      _day = DateTime(nextHour.year, nextHour.month, nextHour.day);
    }
    _contact = widget.contact;
    _loadContacts();
  }

  @override
  void dispose() {
    _title.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _loadContacts() async {
    final all = await ContactRepository(widget.database).getTrustedContacts();
    final reachable = <Contact>[];
    for (final contact in all) {
      if (await MeyaMessageService.instance.canMessage(contact)) {
        reachable.add(contact);
      }
    }
    if (!mounted) return;
    setState(() {
      _contacts = reachable;
      if (_contact != null &&
          !reachable.any((c) => c.contactId == _contact!.contactId)) {
        _contact = null;
      }
      _contact ??= reachable.length == 1 ? reachable.first : null;
      _loading = false;
    });
  }

  DateTime get _start =>
      DateTime(_day.year, _day.month, _day.day, _time.hour, _time.minute);

  Future<void> _pickDay() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _day,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 2, now.month, now.day),
    );
    if (picked != null) setState(() => _day = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _save() async {
    final contact = _contact;
    if (contact == null) {
      _show(context.tr('Choose who the call is with.'));
      return;
    }
    if (_start.isBefore(DateTime.now())) {
      _show(context.tr('Choose a time in the future.'));
      return;
    }
    setState(() => _saving = true);
    try {
      await MeyaCalendarService.instance.schedule(
        contact: contact,
        title: _title.text,
        start: _start,
        durationMinutes: _duration,
        callType: _callType,
        note: _note.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('Call planned. {0} was invited.', [contact.displayName]))),
      );
      Navigator.pop(context);
    } catch (error) {
      _show(context.tr('The call is in your calendar, but the invitation was not sent: {0}', [error]));
      if (mounted) setState(() => _saving = false);
    }
  }

  void _show(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('Schedule a call'))),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                children: [
                  if (_contacts.isEmpty)
                    Text(
                      context.tr('Nobody to invite yet. Encrypted messaging must be set up with a contact before you can plan a call.'),
                      style: TextStyle(color: context.meya.muted, height: 1.4),
                    )
                  else
                    DropdownButtonFormField<String>(
                      initialValue: _contact?.contactId,
                      decoration: InputDecoration(labelText: context.tr('With')),
                      items: [
                        for (final contact in _contacts)
                          DropdownMenuItem(
                            value: contact.contactId,
                            child: Text(contact.displayName),
                          ),
                      ],
                      onChanged: (id) => setState(() {
                        _contact =
                            _contacts.firstWhere((c) => c.contactId == id);
                      }),
                    ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _title,
                    maxLength: 120,
                    decoration: InputDecoration(
                      labelText: context.tr('Title (optional)'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    segments: [
                      ButtonSegment(
                        value: 'video',
                        icon: Icon(Icons.videocam_outlined),
                        label: Text(context.tr('Video call')),
                      ),
                      ButtonSegment(
                        value: 'voice',
                        icon: Icon(Icons.call_outlined),
                        label: Text(context.tr('Voice call')),
                      ),
                    ],
                    selected: {_callType},
                    onSelectionChanged: (value) =>
                        setState(() => _callType = value.first),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.calendar_today_outlined),
                          title: Text(context.tr('Date')),
                          subtitle: Text(localizations.formatFullDate(_day)),
                          onTap: _pickDay,
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.schedule_outlined),
                          title: Text(context.tr('Time')),
                          subtitle: Text(
                            localizations.formatTimeOfDay(
                              _time,
                              alwaysUse24HourFormat:
                                  MediaQuery.alwaysUse24HourFormatOf(context),
                            ),
                          ),
                          onTap: _pickTime,
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.timelapse_outlined),
                          title: Text(context.tr('Length')),
                          trailing: DropdownButton<int>(
                            value: _duration,
                            underline: const SizedBox.shrink(),
                            items: [
                              for (final minutes in const [15, 30, 45, 60, 90, 120])
                                DropdownMenuItem(
                                  value: minutes,
                                  child: Text(
                                    minutes < 60
                                        ? context.tr('{0} min', [minutes])
                                        : minutes % 60 == 0
                                            ? context.tr('{0} h', [minutes ~/ 60])
                                            : context.tr('{0} h {1} min', [minutes ~/ 60, minutes % 60]),
                                  ),
                                ),
                            ],
                            onChanged: (value) =>
                                setState(() => _duration = value ?? 30),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _note,
                    maxLength: 500,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: context.tr('Note (optional)'),
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 56,
                    child: FilledButton.icon(
                      onPressed: _saving || _contacts.isEmpty ? null : _save,
                      icon: const Icon(Icons.send_outlined),
                      label: Text(context.tr('Plan and invite')),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
