import 'package:flutter/material.dart';

import '../database/account_repository.dart';
import '../database/contact_repository.dart';
import '../database/meya_database.dart';
import 'contact_avatar.dart';
import 'contact_page.dart';
import 'invite_share.dart';
import 'qr_scanner_page.dart';
import '../l10n/meya_strings.dart';

class PeoplePage extends StatefulWidget {
  final MeyaDatabase database;

  const PeoplePage({super.key, required this.database});

  @override
  State<PeoplePage> createState() => _PeoplePageState();
}

class _PeoplePageState extends State<PeoplePage> {
  late final ContactRepository _repository;
  late final AccountRepository _accountRepository;

  List<Contact> _contacts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();

    _repository = ContactRepository(widget.database);
    _accountRepository = AccountRepository(widget.database);

    _loadContacts();
  }

  Future<void> _loadContacts() async {
    final account = await _accountRepository.getActiveAccount();
    final contacts = await _repository.getContacts();

    final localIdentityId = account?.accountId;

    final trustedContacts = contacts.where((contact) {
      final isTrusted = contact.trustState == 'trusted';
      final isNotSelf =
          localIdentityId == null || contact.identityId != localIdentityId;

      return isTrusted && isNotSelf;
    }).toList();

    if (!mounted) {
      return;
    }

    setState(() {
      _contacts = trustedContacts;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('People')),
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: context.tr('Add person'),
            onPressed: () => _openAddPerson(context),
            icon: const Icon(Icons.person_add_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadContacts,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            children: [
              if (_loading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_contacts.isEmpty)
                _EmptyPeople(colorScheme: colorScheme)
              else
                ..._contacts.map(
                  (contact) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _PersonTile(
                      contact: contact,
                      colorScheme: colorScheme,
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => ContactPage(
                              database: widget.database,
                              contact: contact,
                            ),
                          ),
                        );
                        await _loadContacts();
                      },
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openAddPerson(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    context.tr('Add a person'),
                    style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    context.tr('Scan their MEYA QR code to start a secure connection.'),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface
                          .withValues(alpha: 0.65),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.qr_code_2_outlined),
                  title: Text(context.tr('Scan a MEYA QR code')),
                  subtitle: Text(context.tr('Connect with someone nearby')),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    Navigator.pop(sheetContext);

                    await Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            MeyaQrScannerPage(database: widget.database),
                      ),
                    );

                    await _loadContacts();
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.share_outlined),
                  title: Text(context.tr('Share an invite link')),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    shareInviteLink(context, widget.database);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _EmptyPeople extends StatelessWidget {
  final ColorScheme colorScheme;

  const _EmptyPeople({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 8),
        Icon(
          Icons.people_outline,
          size: 42,
          color: colorScheme.onSurface.withValues(alpha: 0.28),
        ),
        const SizedBox(height: 12),
        Text(
          context.tr('No people yet'),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface.withValues(alpha: 0.65),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          context.tr('When you connect with someone, they will appear here.'),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            height: 1.4,
            color: colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}

class _PersonTile extends StatelessWidget {
  final Contact contact;
  final ColorScheme colorScheme;
  final VoidCallback onTap;

  const _PersonTile({
    required this.contact,
    required this.colorScheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = contact.displayName.trim().isEmpty
        ? context.tr('MEYA contact')
        : contact.displayName.trim();

    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.16),
          ),
        ),
        child: Row(
          children: [
            ContactAvatar(
              contactId: contact.contactId,
              name: displayName,
              radius: 25,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    context.tr('Trusted connection'),
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurface.withValues(alpha: 0.58),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: colorScheme.onSurface.withValues(alpha: 0.45),
            ),
          ],
        ),
      ),
      ),
    );
  }
}
