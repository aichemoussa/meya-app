import 'package:flutter/material.dart';

import '../database/meya_database.dart';
import '../services/meya_message_service.dart';
import 'people_page.dart';
import '../theme/meya_theme.dart';
import '../l10n/meya_strings.dart';

class PrivacyPage extends StatefulWidget {
  final MeyaDatabase database;

  const PrivacyPage({super.key, required this.database});

  @override
  State<PrivacyPage> createState() => _PrivacyPageState();
}

class _PrivacyPageState extends State<PrivacyPage> {
  bool _allowConnectionRequests = true;
  bool _showOnlineStatus = true;
  bool _showReadReceipts = MeyaMessageService.instance.readReceipts;
  bool _showTypingIndicator = true;
  bool _allowProfilePhotoFromConnections = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('Privacy'))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          children: [
            Text(
              context.tr('Your privacy'),
              style: TextStyle(
                color: context.meya.text,
                fontSize: 28,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              context.tr(
                'Control how people in your private MEYA space can find and interact with you.',
              ),
              style: TextStyle(
                color: context.meya.muted,
                fontSize: 15,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            _SectionTitle(title: context.tr('Connections')),
            const SizedBox(height: 10),
            _PrivacySwitch(
              title: context.tr('Connection requests'),
              subtitle: context.tr(
                'Allow people to send you connection requests.',
              ),
              value: _allowConnectionRequests,
              onChanged: (value) {
                setState(() {
                  _allowConnectionRequests = value;
                });
              },
            ),
            const SizedBox(height: 12),
            _PrivacySwitch(
              title: context.tr('Online status'),
              subtitle: context.tr(
                'Let your connections see when you are online.',
              ),
              value: _showOnlineStatus,
              onChanged: (value) {
                setState(() {
                  _showOnlineStatus = value;
                });
              },
            ),
            const SizedBox(height: 24),
            _SectionTitle(title: context.tr('Conversations')),
            const SizedBox(height: 10),
            _PrivacySwitch(
              title: context.tr('Read receipts'),
              subtitle: context.tr(
                'Let people know when you have read their messages. When off, you will not see when they have read yours either.',
              ),
              value: _showReadReceipts,
              onChanged: (value) {
                setState(() {
                  _showReadReceipts = value;
                });
                MeyaMessageService.instance.setReadReceipts(value);
              },
            ),
            const SizedBox(height: 12),
            _PrivacySwitch(
              title: context.tr('Typing indicator'),
              subtitle: context.tr('Let people know when you are typing.'),
              value: _showTypingIndicator,
              onChanged: (value) {
                setState(() {
                  _showTypingIndicator = value;
                });
              },
            ),
            const SizedBox(height: 24),
            _SectionTitle(title: context.tr('Profile')),
            const SizedBox(height: 10),
            _PrivacySwitch(
              title: context.tr('Profile photo visibility'),
              subtitle: context.tr(
                'Allow your connections to see your profile photo.',
              ),
              value: _allowProfilePhotoFromConnections,
              onChanged: (value) {
                setState(() {
                  _allowProfilePhotoFromConnections = value;
                });
              },
            ),
            const SizedBox(height: 24),
            _PrivacyAction(
              icon: Icons.block_outlined,
              title: context.tr('Blocked people'),
              subtitle: context.tr('Manage people you have blocked.'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BlockedPeoplePage(),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _PrivacyAction(
              icon: Icons.people_outline,
              title: context.tr('Connections'),
              subtitle: context.tr('Review and manage your MEYA connections.'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PeoplePage(database: widget.database),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class BlockedPeoplePage extends StatefulWidget {
  const BlockedPeoplePage({super.key});

  @override
  State<BlockedPeoplePage> createState() => _BlockedPeoplePageState();
}

class _BlockedPeoplePageState extends State<BlockedPeoplePage> {
  List<Contact>? _blocked;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    List<Contact> blocked;
    try {
      blocked = await MeyaMessageService.instance.blockedContacts();
    } catch (_) {
      blocked = [];
    }
    if (mounted) setState(() => _blocked = blocked);
  }

  Future<void> _unblock(Contact contact) async {
    await MeyaMessageService.instance.unblock(contact);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.tr('{0} is unblocked.', [contact.displayName])),
      ),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final blocked = _blocked;
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('Blocked people'))),
      body: SafeArea(
        child: blocked == null
            ? const Center(child: CircularProgressIndicator())
            : blocked.isNotEmpty
            ? ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  for (final contact in blocked)
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.block_outlined),
                        title: Text(contact.displayName),
                        trailing: TextButton(
                          onPressed: () => _unblock(contact),
                          child: Text(context.tr('Unblock')),
                        ),
                      ),
                    ),
                ],
              )
            : Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          color: context.meya.card,
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: Icon(
                          Icons.block_outlined,
                          color: context.meya.navy,
                          size: 42,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        context.tr('No blocked people'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: context.meya.text,
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        context.tr('People you block will appear here.'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: context.meya.muted,
                          fontSize: 15,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        color: context.meya.muted,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _PrivacySwitch extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _PrivacySwitch({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.meya.card,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 12, 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: context.meya.text,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: context.meya.muted,
                      fontSize: 14,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: context.meya.onNavy,
              activeTrackColor: context.meya.navy,
            ),
          ],
        ),
      ),
    );
  }
}

class _PrivacyAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _PrivacyAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.meya.card,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: context.meya.surface,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, color: context.meya.navy),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: context.meya.text,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: context.meya.muted,
                        fontSize: 14,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: context.meya.muted),
            ],
          ),
        ),
      ),
    );
  }
}
