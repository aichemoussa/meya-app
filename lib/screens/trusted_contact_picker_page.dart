import 'package:flutter/material.dart';

import '../database/account_repository.dart';
import '../database/contact_repository.dart';
import '../database/meya_database.dart';
import 'qr_scanner_page.dart';
import '../theme/meya_theme.dart';
import '../l10n/meya_strings.dart';

class TrustedContactPickerPage extends StatefulWidget {
  final MeyaDatabase database;

  const TrustedContactPickerPage({
    super.key,
    required this.database,
  });

  @override
  State<TrustedContactPickerPage> createState() =>
      _TrustedContactPickerPageState();
}

class _TrustedContactPickerPageState
    extends State<TrustedContactPickerPage> {

  late final TextEditingController _searchController;
  late final ContactRepository _contactRepository;
  late final AccountRepository _accountRepository;

  List<Contact> _contacts = [];
  String _query = '';
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _contactRepository = ContactRepository(widget.database);
    _accountRepository = AccountRepository(widget.database);
    _loadContacts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadContacts() async {
    try {
      final account = await _accountRepository.getActiveAccount();
      final contacts = await _contactRepository.getContacts();
      final localIdentityId = account?.identityId ?? account?.accountId;

      final trustedContacts = contacts.where((contact) {
        return contact.trustState == 'trusted' &&
            !contact.isRevoked &&
            contact.identityId != localIdentityId;
      }).toList();

      if (!mounted) return;

      setState(() {
        _contacts = trustedContacts;
        _loading = false;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = context.tr('Your contacts could not be loaded. Please try again.');
      });
    }
  }

  List<Contact> get _filteredContacts {
    final query = _query.trim().toLowerCase();

    if (query.isEmpty) return _contacts;

    return _contacts.where((contact) {
      return contact.displayName.toLowerCase().contains(query) ||
          contact.identityId.toLowerCase().contains(query);
    }).toList();
  }

  Future<void> _scanQrCode() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MeyaQrScannerPage(database: widget.database),
      ),
    );

    if (mounted) {
      await _loadContacts();
    }
  }

  void _selectContact(Contact contact) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(contact.displayName),
        content: Text(
          context.tr('This contact is trusted. Secure conversation setup is not available yet, so MEYA has not created a conversation or sent a message.'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredContacts = _filteredContacts;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('New Chat')),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildError()
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.tr('Your trusted contacts'),
                              style: TextStyle(
                                color: context.meya.text,
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              context.tr('Choose someone you have already connected with on MEYA.'),
                              style: TextStyle(
                                color: context.meya.muted,
                                fontSize: 14,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _searchController,
                              onChanged: (value) {
                                setState(() => _query = value);
                              },
                              decoration: InputDecoration(
                                hintText: context.tr('Search trusted contacts'),
                                prefixIcon: const Icon(Icons.search),
                                suffixIcon: _query.isEmpty
                                    ? null
                                    : IconButton(
                                        tooltip: context.tr('Clear search'),
                                        onPressed: () {
                                          _searchController.clear();
                                          setState(() => _query = '');
                                        },
                                        icon: const Icon(Icons.clear),
                                      ),
                                filled: true,
                                fillColor: context.meya.card,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: filteredContacts.isEmpty
                            ? _buildEmptyState()
                            : ListView.separated(
                                padding: const EdgeInsets.fromLTRB(
                                  20, 4, 20, 16,
                                ),
                                itemCount: filteredContacts.length,
                                separatorBuilder: (context, index) =>
                                    const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final contact = filteredContacts[index];
                                  final displayName =
                                      contact.displayName.trim().isEmpty
                                          ? context.tr('MEYA contact')
                                          : contact.displayName.trim();

                                  return ListTile(
                                    contentPadding:
                                        const EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: 6,
                                    ),
                                    leading: CircleAvatar(
                                      backgroundColor: context.meya.surface,
                                      foregroundColor: context.meya.navy,
                                      child: Text(
                                        displayName[0].toUpperCase(),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      displayName,
                                      style: TextStyle(
                                        color: context.meya.text,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    subtitle: Text(
                                      context.tr('Trusted contact'),
                                      style: TextStyle(color: context.meya.muted),
                                    ),
                                    trailing: Icon(
                                      Icons.chevron_right,
                                      color: context.meya.navy,
                                    ),
                                    onTap: () => _selectContact(contact),
                                  );
                                },
                              ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                        child: OutlinedButton.icon(
                          onPressed: _scanQrCode,
                          icon: const Icon(Icons.qr_code_scanner),
                          label: Text(context.tr('Connect using a QR code')),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: context.meya.navy,
                            side: BorderSide(color: context.meya.blue),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final searching = _query.trim().isNotEmpty;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              searching ? Icons.search_off : Icons.people_outline,
              size: 48,
              color: context.meya.muted,
            ),
            const SizedBox(height: 16),
            Text(
              searching
                  ? context.tr('No matching contacts')
                  : context.tr('No trusted contacts yet'),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.meya.text,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              searching
                  ? context.tr('Try another name or identity ID.')
                  : context.tr('Connect with someone using their MEYA QR code. They will not become trusted without the invitation process.'),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.meya.muted,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 44, color: context.meya.muted),
            const SizedBox(height: 12),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: context.meya.text),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                setState(() {
                  _loading = true;
                  _error = null;
                });
                _loadContacts();
              },
              style: FilledButton.styleFrom(backgroundColor: context.meya.navy),
              child: Text(context.tr('Try again')),
            ),
          ],
        ),
      ),
    );
  }
}
