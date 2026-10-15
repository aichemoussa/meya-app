import 'package:flutter/material.dart';

import '../database/meya_database.dart';
import '../l10n/meya_strings.dart';
import '../services/account_security_service.dart';
import '../services/meya_account_reset.dart';
import '../theme/meya_theme.dart';
import 'recovery_code_page.dart';

/// "5:00" or "1:00:00": how long until a code can be tried again.
String formatWait(Duration wait) {
  final seconds = wait.inSeconds + (wait.inMilliseconds % 1000 > 0 ? 1 : 0);
  final h = seconds ~/ 3600;
  final m = (seconds % 3600) ~/ 60;
  final s = seconds % 60;
  final ss = s.toString().padLeft(2, '0');
  return h > 0 ? '$h:${m.toString().padLeft(2, '0')}:$ss' : '$m:$ss';
}

/// What to do when the passcode is forgotten: reset it with the recovery
/// code (the account stays), or erase this phone's MEYA data and start over.
/// Pops with `true` when the passcode was reset.
class ForgotPasscodePage extends StatelessWidget {
  final MeyaDatabase database;

  /// Called after everything was erased.
  final VoidCallback onErased;

  const ForgotPasscodePage({
    super.key,
    required this.database,
    required this.onErased,
  });

  Future<void> _erase(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.tr('Delete your MEYA account from this phone?')),
        content: Text(
          context.tr('This permanently deletes your messages, contacts, photos, videos, files, status, calendar and encryption keys from this phone. It cannot be undone. People you talked to keep what they already received.'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.tr('Cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: dialogContext.meya.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(context.tr('Delete everything')),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    await MeyaAccountReset.deleteEverything(database);
    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
    onErased();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.meya;

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('Forgot your passcode?'))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 32),
          children: [
            Icon(Icons.lock_reset_rounded, size: 48, color: colors.navy),
            const SizedBox(height: 16),
            Text(
              context.tr('MEYA keeps no email address or phone number, so nobody can reset your passcode for you. Use your recovery code, or erase this phone\'s MEYA data and start again.'),
              style: TextStyle(color: colors.text, fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 28),
            SizedBox(
              height: 56,
              child: FilledButton.icon(
                onPressed: () async {
                  final reset = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(builder: (_) => const RecoveryResetPage()),
                  );
                  if (reset == true && context.mounted) {
                    Navigator.pop(context, true);
                  }
                },
                icon: const Icon(Icons.vpn_key_outlined),
                label: Text(context.tr('Use my recovery code')),
                style: FilledButton.styleFrom(
                  backgroundColor: colors.navy,
                  foregroundColor: colors.onNavy,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 56,
              child: OutlinedButton.icon(
                onPressed: () => _erase(context),
                icon: Icon(Icons.delete_forever_outlined, color: colors.error),
                label: Text(
                  context.tr('Erase everything and start over'),
                  style: TextStyle(color: colors.error),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: colors.error),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Step 1: type the recovery code. Step 2: choose a new passcode. Then a new
/// recovery code is shown, because a used code is never reused.
class RecoveryResetPage extends StatefulWidget {
  const RecoveryResetPage({super.key});

  @override
  State<RecoveryResetPage> createState() => _RecoveryResetPageState();
}

class _RecoveryResetPageState extends State<RecoveryResetPage> {
  final _code = TextEditingController();
  final _passcode = TextEditingController();
  final _confirmation = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _hasCode = true;
  bool _verified = false;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    AccountSecurityService.hasRecoveryCode().then((has) {
      if (mounted) setState(() => _hasCode = has);
    });
  }

  @override
  void dispose() {
    _code.dispose();
    _passcode.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (_code.text.trim().isEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await AccountSecurityService.checkRecoveryCode(_code.text);
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (result.ok) {
        _verified = true;
      } else if (result.isLocked) {
        _error = context.tr('Too many wrong tries. Try again in {0}.', [formatWait(result.lockedFor!)]);
      } else {
        _error = context.tr('That recovery code is not right.');
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    await AccountSecurityService.savePasscode(_passcode.text);
    final newCode = await AccountSecurityService.createRecoveryCode();
    if (!mounted) return;
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => RecoveryCodePage(
          code: newCode,
          onDone: () => Navigator.pop(context),
        ),
      ),
    );
    if (mounted) Navigator.pop(context, true);
  }

  Widget _field(
    TextEditingController controller,
    String label,
    String? Function(String?) validator,
  ) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: TextFormField(
          controller: controller,
          obscureText: true,
          keyboardType: TextInputType.number,
          maxLength: 6,
          decoration: InputDecoration(labelText: label),
          validator: validator,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final colors = context.meya;

    return Scaffold(
      appBar: AppBar(
        title: Text(_verified
            ? context.tr('Choose a new passcode')
            : context.tr('Enter your recovery code')),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 32),
          children: [
            if (!_hasCode) ...[
              Text(
                context.tr('No recovery code was set up on this phone. You can erase everything and start over instead.'),
                style: TextStyle(color: colors.text, fontSize: 16, height: 1.5),
              ),
            ] else if (!_verified) ...[
              Text(
                context.tr('Type the 24-character code you wrote down when you set up MEYA. Capitals and dashes do not matter.'),
                style: TextStyle(color: colors.muted, fontSize: 15, height: 1.5),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _code,
                autofocus: true,
                autocorrect: false,
                enableSuggestions: false,
                textCapitalization: TextCapitalization.characters,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 20,
                  letterSpacing: 2,
                ),
                decoration: InputDecoration(labelText: context.tr('Recovery code')),
                onSubmitted: (_) => _verify(),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    _error!,
                    style: TextStyle(color: colors.error, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                height: 56,
                child: FilledButton(
                  onPressed: _busy ? null : _verify,
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.navy,
                    foregroundColor: colors.onNavy,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _busy
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(context.tr('Continue')),
                ),
              ),
            ] else
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _field(_passcode, context.tr('New passcode'), (value) {
                      if (value == null || value.isEmpty) {
                        return context.tr('Please create a passcode');
                      }
                      if (!RegExp(r'^\d{4,6}$').hasMatch(value)) {
                        return context.tr('Use 4 to 6 digits');
                      }
                      return null;
                    }),
                    _field(_confirmation, context.tr('Confirm passcode'), (value) {
                      if (value == null || value.isEmpty) {
                        return context.tr('Please confirm your passcode');
                      }
                      if (value != _passcode.text) {
                        return context.tr('Passcodes do not match');
                      }
                      return null;
                    }),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 56,
                      child: FilledButton(
                        onPressed: _busy ? null : _save,
                        style: FilledButton.styleFrom(
                          backgroundColor: colors.navy,
                          foregroundColor: colors.onNavy,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(context.tr('Save passcode')),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
