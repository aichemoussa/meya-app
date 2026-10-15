import 'package:flutter/material.dart';

import '../database/account_repository.dart';
import '../database/meya_database.dart';
import 'enter_passcode_page.dart';
import 'qr_scanner_page.dart';
import '../theme/meya_theme.dart';
import '../l10n/meya_strings.dart';

class LoginPage extends StatefulWidget {
  final MeyaDatabase database;
  final Future<void> Function(Account account) onUnlocked;

  const LoginPage({
    super.key,
    required this.database,
    required this.onUnlocked,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();

  bool _isChecking = false;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isChecking = true;
      _errorMessage = null;
    });

    final username = _usernameController.text.trim().toLowerCase();
    final database = MeyaDatabase();
    final repository = AccountRepository(database);

    try {
      final account = await repository.getAccountByUsername(username);

      if (!mounted) {
        await database.close();
        return;
      }

      if (account == null) {
        setState(() {
          _isChecking = false;
          _errorMessage = context.tr('This MEYA ID is not available on this device. Use your trusted device to connect the account.');
        });
        await database.close();
        return;
      }

      setState(() {
        _isChecking = false;
      });

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EnterPasscodePage(
            database: database,
            onErased: () {
              final messenger = ScaffoldMessenger.of(context);
              final message = context.tr('Everything on this phone was erased. You can create a new account.');
              Navigator.of(context).popUntil((route) => route.isFirst);
              messenger.showSnackBar(SnackBar(content: Text(message)));
            },
            onUnlocked: () async {
              await repository.activateAccount(account.accountId);
              await widget.onUnlocked(account);
            },
          ),
        ),
      );

      await database.close();
    } catch (_) {
      await database.close();

      if (!mounted) {
        return;
      }

      setState(() {
        _isChecking = false;
        _errorMessage = context.tr('Unable to access your MEYA account. Please try again.');
      });
    }
  }

  void _openQrScanner() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MeyaQrScannerPage(database: widget.database)),
    );
  }

  void _connectExistingDevice() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.meya.card,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: context.meya.surface,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    Icons.qr_code_scanner_rounded,
                    color: context.meya.navy,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  context.tr('Connect an existing device'),
                  style: TextStyle(
                    color: context.meya.text,
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  context.tr('Use your trusted MEYA device to securely connect this device. QR pairing will be added to this flow with MEYA identity verification.'),
                  style: TextStyle(
                    color: context.meya.muted,
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(sheetContext);

                      if (mounted) {
                        _openQrScanner();
                      }
                    },
                    icon: const Icon(Icons.qr_code_scanner_rounded),
                    label: Text(
                      context.tr('Scan QR code'),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: context.meya.navy,
                      foregroundColor: context.meya.onNavy,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _createAccount() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.meya.card,
      appBar: AppBar(
        backgroundColor: context.meya.card,
        foregroundColor: context.meya.navy,
        elevation: 0,
        title: Text(
          context.tr('Log in'),
          style: TextStyle(color: context.meya.text, fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(28, 20, 28, 36),
            children: [
              const SizedBox(height: 18),
              Center(
                child: Semantics(
                  label: 'MEYA',
                  image: true,
                  child: Container(
                    width: 78,
                    height: 78,
                    decoration: BoxDecoration(
                      color: context.meya.navy,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Center(
                      child: Text(
                        'M',
                        style: TextStyle(
                          color: context.meya.onNavy,
                          fontSize: 42,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 26),
              Text(
                context.tr('Welcome back'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: context.meya.text,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                context.tr('Sign in to your MEYA space using your existing identity.'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: context.meya.muted,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _usernameController,
                textInputAction: TextInputAction.done,
                autocorrect: false,
                enableSuggestions: false,
                decoration: InputDecoration(
                  labelText: context.tr('MEYA ID'),
                  hintText: 'yourname',
                  prefixText: '@',
                  filled: true,
                  fillColor: context.meya.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: context.meya.navy,
                      width: 1.5,
                    ),
                  ),
                  labelStyle: TextStyle(color: context.meya.muted),
                ),
                validator: (value) {
                  final username = value?.trim() ?? '';

                  if (username.isEmpty) {
                    return context.tr('Enter your MEYA ID');
                  }

                  if (username.length < 3) {
                    return context.tr('Use at least 3 characters');
                  }

                  return null;
                },
                onFieldSubmitted: (_) => _continue(),
              ),
              const SizedBox(height: 12),
              Text(
                context.tr('Your MEYA ID identifies your private identity. It is not a password.'),
                style: TextStyle(
                  color: context.meya.muted,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 14),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: context.meya.error,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  onPressed: _isChecking ? null : _continue,
                  style: FilledButton.styleFrom(
                    backgroundColor: context.meya.navy,
                    foregroundColor: context.meya.onNavy,
                    disabledBackgroundColor: context.meya.navy.withValues(
                      alpha: 0.55,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isChecking
                      ? SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              context.meya.onNavy,
                            ),
                          ),
                        )
                      : Text(
                          context.tr('Continue'),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: Divider(color: context.meya.text.withValues(alpha: 0.12)),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14),
                    child: Text(
                      'or',
                      style: TextStyle(color: context.meya.muted, fontSize: 14),
                    ),
                  ),
                  Expanded(
                    child: Divider(color: context.meya.text.withValues(alpha: 0.12)),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: _connectExistingDevice,
                icon: const Icon(Icons.qr_code_2_rounded),
                label: Text(
                  context.tr('Connect an existing device'),
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: context.meya.navy,
                  minimumSize: const Size.fromHeight(52),
                  side: BorderSide(color: context.meya.navy, width: 1.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                context.tr('Have your existing MEYA device nearby? You will eventually be able to verify and transfer your identity securely using QR pairing.'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: context.meya.muted,
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 28),
              Center(
                child: TextButton(
                  onPressed: _createAccount,
                  child: Text(
                    context.tr('Create a new MEYA account'),
                    style: TextStyle(
                      color: context.meya.navy,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
