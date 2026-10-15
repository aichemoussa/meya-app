import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../database/account_repository.dart';
import '../database/meya_database.dart';
import '../l10n/meya_strings.dart';
import '../services/safety_number.dart';
import '../theme/meya_theme.dart';

/// Shows the safety number with a contact, lets the two people scan each
/// other's code, and remembers that the contact was verified.
class SafetyNumberPage extends StatefulWidget {
  final MeyaDatabase database;
  final Contact contact;

  const SafetyNumberPage({
    super.key,
    required this.database,
    required this.contact,
  });

  @override
  State<SafetyNumberPage> createState() => _SafetyNumberPageState();
}

class _SafetyNumberPageState extends State<SafetyNumberPage> {
  String? _number;
  String? _error;
  bool _verified = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final account = await AccountRepository(widget.database).getActiveAccount();
      if (account == null) throw StateError('No account');
      final number = SafetyNumber.compute(
        localKeyBase64: account.identityPublicKey,
        localId: account.identityId ?? account.accountId,
        remoteKeyBase64: widget.contact.identityPublicKey,
        remoteId: widget.contact.identityId,
      );
      final verified = await SafetyNumber.isVerified(widget.contact);
      if (!mounted) return;
      setState(() {
        _number = number;
        _verified = verified;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = context.tr('The safety number could not be shown: {0}', [error]));
    }
  }

  Future<void> _setVerified(bool verified) async {
    await SafetyNumber.setVerified(widget.contact, verified);
    if (mounted) setState(() => _verified = verified);
  }

  Future<void> _scan() async {
    final scanned = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const _SafetyScannerPage()),
    );
    if (scanned == null || !mounted) return;
    final theirs = SafetyNumber.fromQr(scanned);
    final match = theirs != null && theirs == _number;
    if (match) await _setVerified(true);
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(
          match ? Icons.verified_user : Icons.gpp_bad_outlined,
          color: match ? Colors.green : Theme.of(context).colorScheme.error,
          size: 48,
        ),
        title: Text(match ? context.tr('Verified') : context.tr('The numbers do not match')),
        content: Text(
          match
              ? context.tr('Your conversation with {0} is end-to-end encrypted with the right keys.', [widget.contact.displayName])
              : theirs == null
                  ? context.tr('That is not a MEYA safety number code.')
                  : context.tr('Do not trust this conversation yet. Make sure you scanned {0}\'s code for this chat, then try again in person.', [widget.contact.displayName]),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(context.tr('OK')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.meya;
    final number = _number;
    final name = widget.contact.displayName;

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('Verify encryption'))),
      body: SafeArea(
        child: _error != null
            ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!)))
            : number == null
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                    children: [
                      if (_verified)
                        Card(
                          color: Colors.green.withValues(alpha: 0.12),
                          child: ListTile(
                            leading: const Icon(Icons.verified_user, color: Colors.green),
                            title: Text(context.tr('You have verified {0}', [name])),
                          ),
                        ),
                      const SizedBox(height: 8),
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          color: Colors.white,
                          child: QrImageView(
                            data: SafetyNumber.qrData(number),
                            size: 200,
                            semanticsLabel: context.tr('Safety number QR code'),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Semantics(
                        label: context.tr('Safety number: {0}', [SafetyNumber.groups(number).join(' ')]),
                        excludeSemantics: true,
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 14,
                          runSpacing: 10,
                          children: [
                            for (final group in SafetyNumber.groups(number))
                              Text(
                                group,
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 22,
                                  letterSpacing: 2,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        context.tr('To check that nobody is in the middle, meet {0} or call them, and compare these numbers, or scan the code on their phone. If they match, your messages and calls are encrypted with the right keys.', [name]),
                        style: TextStyle(color: colors.muted, height: 1.45),
                      ),
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        onPressed: _scan,
                        icon: const Icon(Icons.qr_code_scanner),
                        label: Text(context.tr('Scan their code')),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: () => _setVerified(!_verified),
                        child: Text(
                          _verified
                              ? context.tr('Clear verification')
                              : context.tr('Mark as verified'),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}

class _SafetyScannerPage extends StatefulWidget {
  const _SafetyScannerPage();

  @override
  State<_SafetyScannerPage> createState() => _SafetyScannerPageState();
}

class _SafetyScannerPageState extends State<_SafetyScannerPage> {
  final _controller = MobileScannerController();
  bool _done = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('Scan their code'))),
      body: MobileScanner(
        controller: _controller,
        onDetect: (capture) {
          if (_done) return;
          for (final barcode in capture.barcodes) {
            final value = barcode.rawValue;
            if (value != null) {
              _done = true;
              Navigator.pop(context, value);
              return;
            }
          }
        },
      ),
    );
  }
}
