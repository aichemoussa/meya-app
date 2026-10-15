import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../database/account_repository.dart';
import '../database/contact_repository.dart';
import '../database/meya_database.dart';
import '../services/device_identity_service.dart';
import '../services/meya_account_reset.dart';
import '../services/meya_e2ee.dart';
import '../theme/meya_theme.dart';
import '../l10n/meya_strings.dart';

/// Groups key bytes as "1A2B 3C4D …" so two people can compare them.
String keyFingerprint(String base64Key) {
  try {
    final bytes = base64Decode(base64Key);
    final hex = bytes
        .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
        .join();
    final groups = <String>[];
    for (var i = 0; i < hex.length; i += 4) {
      groups.add(hex.substring(i, i + 4 > hex.length ? hex.length : i + 4));
    }
    return groups.join(' ');
  } catch (_) {
    return base64Key;
  }
}

/// Account details for this phone, signing out and deleting the account.
class AccountPage extends StatefulWidget {
  final MeyaDatabase database;

  /// Called after signing out or deleting; returns to the welcome screen.
  final VoidCallback onSignedOut;

  const AccountPage({
    super.key,
    required this.database,
    required this.onSignedOut,
  });

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  Account? _account;
  String? _deviceId;
  String? _identityKey;
  int _connections = 0;
  bool _loading = true;
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final account = await AccountRepository(widget.database).getActiveAccount();
    final deviceId = await DeviceIdentityService.getDeviceId();
    String? key;
    try {
      key = await MeyaE2ee.instance.open();
    } catch (_) {
      key = null;
    }
    final contacts = await ContactRepository(widget.database).getTrustedContacts(
      excludeIdentityId: account?.identityId,
    );
    if (!mounted) return;
    setState(() {
      _account = account;
      _deviceId = deviceId;
      _identityKey = key;
      _connections = contacts.length;
      _loading = false;
    });
  }

  String _date(String iso) {
    final parsed = DateTime.tryParse(iso);
    if (parsed == null) return iso;
    return MaterialLocalizations.of(context).formatFullDate(parsed.toLocal());
  }

  void _copy(String label, String value) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.tr('{0} copied.', [label]))),
    );
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.tr('Sign out of MEYA?')),
        content: Text(
          context.tr('Your account, messages and keys stay on this phone. You will need your passcode to sign in again. While signed out, new messages wait on the relay.'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.tr('Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(context.tr('Sign out')),
          ),
        ],
      ),
    );
    if (confirmed == true) widget.onSignedOut();
  }

  Future<void> _delete() async {
    final account = _account;
    if (account == null) return;
    final typed = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(context.tr('Delete your MEYA account from this phone?')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr('This permanently deletes your messages, contacts, photos, videos, files, status, calendar and encryption keys from this phone. It cannot be undone. People you talked to keep what they already received.'),
              ),
              const SizedBox(height: 16),
              Text(context.tr('To confirm, type your MEYA ID: {0}', [account.username])),
              const SizedBox(height: 8),
              TextField(
                controller: typed,
                autocorrect: false,
                onChanged: (_) => setDialogState(() {}),
                decoration: const InputDecoration(prefixText: '@'),
              ),
            ],
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
              onPressed: typed.text.trim().toLowerCase() == account.username
                  ? () => Navigator.pop(dialogContext, true)
                  : null,
              child: Text(context.tr('Delete everything')),
            ),
          ],
        ),
      ),
    );
    typed.dispose();
    if (confirmed != true) return;

    setState(() => _deleting = true);
    await MeyaAccountReset.deleteEverything(widget.database);
    if (!mounted) return;
    widget.onSignedOut();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.meya;
    final account = _account;

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('Account'))),
      body: SafeArea(
        child: _loading || _deleting
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    if (_deleting) ...[
                      const SizedBox(height: 16),
                      Text(context.tr('Deleting your account from this phone…')),
                    ],
                  ],
                ),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                children: [
                  if (account == null)
                    Text(context.tr('No account is signed in on this phone.'))
                  else ...[
                    Card(
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.person_outline),
                            title: Text(context.tr('Name')),
                            subtitle: Text(account.name),
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.alternate_email),
                            title: Text(context.tr('MEYA ID')),
                            subtitle: Text('@${account.username}'),
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.badge_outlined),
                            title: Text(context.tr('Account number')),
                            subtitle: Text(account.meyaId),
                            trailing: IconButton(
                              tooltip: context.tr('Copy account number'),
                              icon: const Icon(Icons.copy_outlined),
                              onPressed: () =>
                                  _copy(context.tr('Account number'), account.meyaId),
                            ),
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.event_outlined),
                            title: Text(context.tr('Created')),
                            subtitle: Text(_date(account.createdAt)),
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.people_outline),
                            title: Text(context.tr('Connections')),
                            subtitle: Text('$_connections'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Semantics(
                      header: true,
                      child: Text(
                        context.tr('This phone'),
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Card(
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.phone_android_outlined),
                            title: Text(context.tr('Device ID')),
                            subtitle: Text(_deviceId ?? context.tr('Not created yet')),
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.key_outlined),
                            title: Text(context.tr('Your encryption key')),
                            subtitle: Text(
                              _identityKey == null
                                  ? context.tr('Not available')
                                  : keyFingerprint(_identityKey!),
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                height: 1.5,
                              ),
                            ),
                            isThreeLine: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.tr('Your MEYA account lives only on this phone. There is no password reset and no copy on a server, so keep your passcode safe. Moving to a new phone is not available yet.'),
                      style: TextStyle(color: colors.muted, height: 1.4),
                    ),
                    const SizedBox(height: 24),
                    OutlinedButton.icon(
                      onPressed: _signOut,
                      icon: const Icon(Icons.logout),
                      label: Text(context.tr('Sign out')),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colors.error,
                        side: BorderSide(color: colors.error),
                      ),
                      onPressed: _delete,
                      icon: const Icon(Icons.delete_forever_outlined),
                      label: Text(context.tr('Delete account from this phone')),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}
