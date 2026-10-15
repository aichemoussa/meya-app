import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../database/meya_database.dart';
import '../l10n/meya_strings.dart';
import '../legal/meya_legal.dart';
import '../services/meya_message_service.dart';
import '../theme/meya_theme.dart';

/// Reports a contact. MEYA cannot read conversations, so a report contains
/// only what the person chooses to include, and it is sent from their own
/// email app where they can read it first.
class ReportPage extends StatefulWidget {
  final Contact contact;
  final List<ChatMessageView> messages;

  const ReportPage({super.key, required this.contact, required this.messages});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  static const _reasons = [
    'Harassment or bullying',
    'Threats or violence',
    'Spam or scam',
    'Impersonation',
    'Sexual content',
    'Something else',
  ];

  String _reason = _reasons.first;
  bool _includeMessages = false;
  bool _block = true;
  final _details = TextEditingController();
  bool _working = false;

  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  /// The last messages from the reported person, newest last.
  List<ChatMessageView> get _evidence => [
        for (final message in widget.messages)
          if (!message.isMine && !message.isDeleted) message,
      ].reversed.take(10).toList().reversed.toList();

  Future<void> _submit() async {
    setState(() => _working = true);
    final lines = <String>[
      'MEYA report',
      'Reported person: ${widget.contact.displayName} (MEYA ID ${widget.contact.identityId})',
      'Reason: $_reason',
      if (_details.text.trim().isNotEmpty) 'Details: ${_details.text.trim()}',
      if (_includeMessages) ...[
        '',
        'Messages included by the reporter:',
        for (final message in _evidence)
          '[${message.createdAt.toUtc().toIso8601String()}] ${message.preview}',
      ],
    ];
    final uri = Uri(
      scheme: 'mailto',
      path: meyaReportEmail,
      query: _encode({
        'subject': 'MEYA report: $_reason',
        'body': lines.join('\n'),
      }),
    );

    if (_block) {
      try {
        await MeyaMessageService.instance.block(widget.contact);
      } catch (error) {
        debugPrint('MEYA report: block failed ($error).');
      }
    }

    var opened = false;
    try {
      opened = await launchUrl(uri);
    } catch (error) {
      debugPrint('MEYA report: no email app ($error).');
    }
    if (!mounted) return;
    setState(() => _working = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          opened
              ? context.tr('Your email app has the report ready. Check it, then send it.')
              : context.tr('No email app was found to send the report.'),
        ),
      ),
    );
    if (opened) Navigator.pop(context);
  }

  // mailto needs %20 rather than + for spaces.
  static String _encode(Map<String, String> values) => values.entries
      .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
      .join('&');

  @override
  Widget build(BuildContext context) {
    final colors = context.meya;
    final name = widget.contact.displayName;

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('Report {0}', [name]))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            Text(
              context.tr('MEYA cannot read your conversations. A report contains only what you choose below, and you send it from your own email app.'),
              style: TextStyle(color: colors.muted, height: 1.4),
            ),
            const SizedBox(height: 16),
            Semantics(
              header: true,
              child: Text(
                context.tr('What happened?'),
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
            ),
            RadioGroup<String>(
              groupValue: _reason,
              onChanged: (value) {
                if (value != null) setState(() => _reason = value);
              },
              child: Column(
                children: [
                  for (final reason in _reasons)
                    RadioListTile<String>(
                      value: reason,
                      title: Text(context.tr(reason)),
                    ),
                ],
              ),
            ),
            TextField(
              controller: _details,
              maxLines: 4,
              maxLength: 1000,
              decoration: InputDecoration(
                labelText: context.tr('Details (optional)'),
              ),
            ),
            SwitchListTile(
              value: _includeMessages,
              onChanged: _evidence.isEmpty
                  ? null
                  : (value) => setState(() => _includeMessages = value),
              title: Text(context.tr('Include their last messages')),
              subtitle: Text(
                context.tr('Up to 10 messages {0} sent you. Photos and files are not included.', [name]),
              ),
            ),
            SwitchListTile(
              value: _block,
              onChanged: (value) => setState(() => _block = value),
              title: Text(context.tr('Also block {0}', [name])),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _working ? null : _submit,
              icon: const Icon(Icons.flag_outlined),
              label: Text(context.tr('Prepare report')),
            ),
          ],
        ),
      ),
    );
  }
}
