import 'package:flutter/material.dart';

import '../database/contact_repository.dart';
import '../database/meya_database.dart';
import '../services/meya_e2ee.dart';
import '../services/meya_profile_service.dart';
import '../services/meya_status_service.dart';
import 'calendar_page.dart';
import 'call_page.dart';
import 'chat_page.dart';
import 'media_widgets.dart';
import 'safety_number_page.dart';
import 'status_page.dart';
import '../l10n/meya_strings.dart';

/// Details and actions for one trusted MEYA contact.
class ContactPage extends StatefulWidget {
  final MeyaDatabase database;
  final Contact contact;

  const ContactPage({super.key, required this.database, required this.contact});

  @override
  State<ContactPage> createState() => _ContactPageState();
}

class _ContactPageState extends State<ContactPage> {
  ContactProfile? _profile;
  MeyaStatus? _status;

  MeyaDatabase get database => widget.database;
  Contact get contact => widget.contact;

  String get _name {
    final shared = _profile?.name.trim() ?? '';
    if (shared.isNotEmpty) return shared;
    return contact.displayName.trim().isEmpty
        ? tr('MEYA contact')
        : contact.displayName.trim();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final profile = await MeyaProfileService.instance.profileOf(contact.contactId);
    final status = await MeyaStatusService.instance.statusOf(contact.contactId);
    if (!mounted) return;
    setState(() {
      _profile = profile;
      _status = status;
    });
  }

  void _scheduleCall(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => ScheduleCallPage(database: database, contact: contact),
      ),
    );
  }

  void _openChat(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => ChatPage(database: database, contact: contact),
      ),
    );
  }

  Future<void> _confirmRemove(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.tr('Remove {0}?', [_name])),
        content: Text(
          context.tr('They will be removed from your People list on this device. To connect again, you will need to scan their QR code in person.'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.tr('Cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
              foregroundColor: Theme.of(dialogContext).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(context.tr('Remove')),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    try {
      final repository = ContactRepository(database);
      final deviceId = await repository.getDeviceIdForContact(contact.contactId);
      if (deviceId != null) {
        try {
          await MeyaE2ee.instance.forget(deviceId);
        } catch (_) {
          // The contact is still removed; a later pairing pins a fresh key.
        }
      }
      await repository.deleteContact(contact.contactId);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('{0} was removed.', [_name]))),
      );
      Navigator.pop(context, true);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('Could not remove {0}: {1}', [_name, error]))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(_name)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          children: [
            Center(
              child: SizedBox(
                width: 88,
                height: 88,
                child: ClipOval(
                  child: _profile?.photo != null
                      ? EncryptedImage(
                          attachment: _profile!.photo!,
                          width: 88,
                          height: 88,
                        )
                      : Container(
                          color: colorScheme.primary.withValues(alpha: 0.12),
                          alignment: Alignment.center,
                          child: Text(
                            _name.substring(0, 1).toUpperCase(),
                            style: TextStyle(
                              color: colorScheme.primary,
                              fontSize: 34,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _name,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.verified_user_outlined,
                    size: 18, color: colorScheme.primary),
                const SizedBox(width: 6),
                Text(
                  context.tr('Connected in person with a QR code'),
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
            if ((_profile?.about ?? '').isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                _profile!.about,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, height: 1.4),
              ),
            ],
            if (_status != null) ...[
              const SizedBox(height: 16),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.auto_awesome_outlined),
                  title: Text(context.tr('Status')),
                  subtitle: Text(
                    [
                      _status!.emoji,
                      _status!.text,
                      if (_status!.text.isEmpty && _status!.media != null)
                        _status!.isVideo ? context.tr('Video') : context.tr('Photo'),
                    ].where((part) => part.isNotEmpty).join(' '),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          StatusViewerPage(
                            stories: [StatusStory(status: _status!, name: _name, mine: false)],
                          ),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    icon: Icons.chat_bubble_outline,
                    label: context.tr('Message'),
                    onTap: () => _openChat(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.call_outlined,
                    label: context.tr('Voice call'),
                    onTap: () => startCallWith(context, contact, video: false),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.videocam_outlined,
                    label: context.tr('Video call'),
                    onTap: () => startCallWith(context, contact, video: true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _scheduleCall(context),
                icon: const Icon(Icons.event_outlined),
                label: Text(context.tr('Schedule a call')),
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.verified_user_outlined),
              title: Text(context.tr('Verify encryption')),
              subtitle: Text(context.tr('Compare safety numbers with {0}', [_name])),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) =>
                      SafetyNumberPage(database: database, contact: contact),
                ),
              ),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.person_remove_outlined,
                  color: colorScheme.error),
              title: Text(
                context.tr('Remove contact'),
                style: TextStyle(color: colorScheme.error),
              ),
              subtitle: Text(context.tr('Remove this person from your People list')),
              onTap: () => _confirmRemove(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 88),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: colorScheme.primary, size: 28),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
