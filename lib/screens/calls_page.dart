import 'package:flutter/material.dart';

import '../database/call_log_repository.dart';
import '../database/meya_database.dart';
import '../l10n/meya_strings.dart';
import '../theme/meya_theme.dart';
import 'calendar_page.dart';
import 'call_page.dart';
import 'contact_avatar.dart';

/// Calls made, received and missed on this phone, with the calendar of
/// planned calls one tap away.
class CallsPage extends StatefulWidget {
  final MeyaDatabase database;

  const CallsPage({super.key, required this.database});

  @override
  State<CallsPage> createState() => _CallsPageState();
}

class _CallsPageState extends State<CallsPage> {
  late final CallLogRepository _log = CallLogRepository(widget.database);
  late final Stream<List<CallLogEntry>> _calls = _log.watch();

  void _open(Widget page) => Navigator.push(
        context,
        MaterialPageRoute<void>(builder: (_) => page),
      );

  Future<void> _clear() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.tr('Clear the call log?')),
        content: Text(
          context.tr('This removes the list of calls from this phone only.'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.tr('Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(context.tr('Clear')),
          ),
        ],
      ),
    );
    if (confirmed == true) await _log.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('Calls')),
        actions: [
          IconButton(
            tooltip: context.tr('Calendar'),
            icon: const Icon(Icons.calendar_month_outlined),
            onPressed: () => _open(CalendarPage(database: widget.database)),
          ),
          PopupMenuButton<String>(
            onSelected: (_) => _clear(),
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'clear',
                child: Text(context.tr('Clear call log')),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _open(ScheduleCallPage(database: widget.database)),
        icon: const Icon(Icons.event_outlined),
        label: Text(context.tr('Schedule a call')),
      ),
      body: StreamBuilder<List<CallLogEntry>>(
        stream: _calls,
        builder: (context, snapshot) {
          final calls = snapshot.data;
          return ListView(
            padding: const EdgeInsets.only(bottom: 96),
            children: [
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: context.meya.card,
                  child: Icon(Icons.calendar_month_outlined, color: context.meya.navy),
                ),
                title: Text(context.tr('Calendar')),
                subtitle: Text(context.tr('Plan calls with your people')),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _open(CalendarPage(database: widget.database)),
              ),
              const Divider(),
              if (calls == null)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (calls.isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(32, 48, 32, 0),
                  child: Column(
                    children: [
                      Icon(Icons.call_outlined, size: 42, color: context.meya.muted),
                      const SizedBox(height: 12),
                      Text(
                        context.tr('No calls yet'),
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        context.tr('Calls you make and receive appear here.'),
                        textAlign: TextAlign.center,
                        style: TextStyle(color: context.meya.muted),
                      ),
                    ],
                  ),
                )
              else
                for (final entry in calls) _CallRow(entry: entry),
            ],
          );
        },
      ),
    );
  }
}

class _CallRow extends StatelessWidget {
  final CallLogEntry entry;

  const _CallRow({required this.entry});

  static String _when(BuildContext context, DateTime time) {
    final localizations = MaterialLocalizations.of(context);
    final clock = localizations.formatTimeOfDay(
      TimeOfDay.fromDateTime(time),
      alwaysUse24HourFormat: MediaQuery.of(context).alwaysUse24HourFormat,
    );
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(time.year, time.month, time.day);
    if (day == today) return clock;
    if (day == today.subtract(const Duration(days: 1))) {
      return '${context.tr('Yesterday')} $clock';
    }
    return '${localizations.formatShortDate(time)} $clock';
  }

  static String _length(int seconds) {
    final minutes = seconds ~/ 60;
    final rest = (seconds % 60).toString().padLeft(2, '0');
    return minutes >= 60
        ? '${minutes ~/ 60}:${(minutes % 60).toString().padLeft(2, '0')}:$rest'
        : '$minutes:$rest';
  }

  @override
  Widget build(BuildContext context) {
    final call = entry.call;
    final contact = entry.contact;
    final colors = context.meya;
    final name = contact == null || contact.displayName.trim().isEmpty
        ? context.tr('MEYA contact')
        : contact.displayName.trim();

    final (IconData icon, String label) = switch (call.outcome) {
      'declined' => (Icons.call_end, context.tr('Declined')),
      'answered' => call.outgoing
          ? (Icons.call_made, context.tr('Outgoing call'))
          : (Icons.call_received, context.tr('Incoming call')),
      _ => call.outgoing
          ? (Icons.call_made, context.tr('No answer'))
          : (Icons.call_missed, context.tr('Missed call')),
    };
    final alert = entry.missed;
    final details = [
      label,
      _when(context, entry.startedAt),
      if (call.durationSeconds > 0) _length(call.durationSeconds),
    ].join(' · ');

    return ListTile(
      leading: contact == null
          ? CircleAvatar(child: Text(name.characters.first.toUpperCase()))
          : ContactAvatar(contactId: contact.contactId, name: name),
      title: Text(
        name,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: alert ? colors.error : null,
        ),
      ),
      subtitle: Row(
        children: [
          Icon(icon, size: 16, color: alert ? colors.error : colors.muted),
          const SizedBox(width: 6),
          Expanded(child: Text(details, overflow: TextOverflow.ellipsis)),
        ],
      ),
      trailing: contact == null
          ? null
          : IconButton(
              tooltip: call.video ? context.tr('Video call') : context.tr('Voice call'),
              icon: Icon(call.video ? Icons.videocam_outlined : Icons.call_outlined),
              color: colors.navy,
              onPressed: () => startCallWith(context, contact, video: call.video),
            ),
    );
  }
}
