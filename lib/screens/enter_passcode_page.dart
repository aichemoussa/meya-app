import 'package:flutter/material.dart';
import '../services/account_security_service.dart';
import '../theme/meya_theme.dart';
import '../l10n/meya_strings.dart';

class EnterPasscodePage extends StatefulWidget {
  final Future<void> Function() onUnlocked;

  const EnterPasscodePage({
    super.key,
    required this.onUnlocked,
  });

  @override
  State<EnterPasscodePage> createState() => _EnterPasscodePageState();
}

class _EnterPasscodePageState extends State<EnterPasscodePage> {
  final _passcodeController = TextEditingController();

  bool _obscurePasscode = true;
  bool _isChecking = false;
  String? _errorMessage;

  @override
  void dispose() {
    _passcodeController.dispose();
    super.dispose();
  }

  Future<void> _unlock() async {
    final passcode = _passcodeController.text.trim();

    if (passcode.isEmpty) {
      setState(() {
        _errorMessage = context.tr('Enter your passcode.');
      });
      return;
    }

    setState(() {
      _isChecking = true;
      _errorMessage = null;
    });

    final valid = await AccountSecurityService.verifyPasscode(passcode);

    if (!mounted) {
      return;
    }

    if (!valid) {
      setState(() {
        _isChecking = false;
        _errorMessage = context.tr('Incorrect passcode. Try again.');
      });
      _passcodeController.clear();
      return;
    }

    await widget.onUnlocked();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.meya.card,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const Spacer(flex: 2),
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: context.meya.navy,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  Icons.lock_outline_rounded,
                  color: context.meya.onNavy,
                  size: 40,
                ),
              ),
              const SizedBox(height: 28),
              Text(
                context.tr('Welcome back'),
                style: TextStyle(
                  color: context.meya.text,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                context.tr('Enter your passcode to access your space.'),
                style: TextStyle(
                  color: context.meya.muted,
                  fontSize: 15,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _passcodeController,
                obscureText: _obscurePasscode,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  letterSpacing: 8,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  hintText: '••••',
                  counterText: '',
                  filled: true,
                  fillColor: context.meya.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        _obscurePasscode = !_obscurePasscode;
                      });
                    },
                    icon: Icon(
                      _obscurePasscode
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    color: context.meya.navy,
                  ),
                ),
                onSubmitted: (_) => _unlock(),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  style: TextStyle(
                    color: context.meya.error,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isChecking ? null : _unlock,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.meya.navy,
                    foregroundColor: context.meya.onNavy,
                    elevation: 0,
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
                            valueColor:
                                AlwaysStoppedAnimation<Color>(context.meya.onNavy),
                          ),
                        )
                      : Text(
                          context.tr('Unlock'),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }
}