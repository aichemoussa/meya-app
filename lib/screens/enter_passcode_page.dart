import 'dart:async';

import 'package:flutter/material.dart';
import '../database/meya_database.dart';
import '../services/account_security_service.dart';
import '../theme/meya_theme.dart';
import '../l10n/meya_strings.dart';
import 'forgot_passcode_page.dart';

class EnterPasscodePage extends StatefulWidget {
  final Future<void> Function() onUnlocked;

  /// With a [database] the screen offers "Forgot passcode?" (reset with the
  /// recovery code, or erase everything).
  final MeyaDatabase? database;

  /// Called after everything on the phone was erased from "Forgot passcode?".
  final VoidCallback? onErased;

  const EnterPasscodePage({
    super.key,
    required this.onUnlocked,
    this.database,
    this.onErased,
  });

  @override
  State<EnterPasscodePage> createState() => _EnterPasscodePageState();
}

class _EnterPasscodePageState extends State<EnterPasscodePage> {
  final _passcodeController = TextEditingController();

  bool _obscurePasscode = true;
  bool _isChecking = false;
  String? _errorMessage;
  Duration _lockLeft = Duration.zero;
  Timer? _lockTimer;

  bool get _locked => _lockLeft > Duration.zero;

  @override
  void initState() {
    super.initState();
    AccountSecurityService.lockRemaining().then(_startLock);
  }

  @override
  void dispose() {
    _lockTimer?.cancel();
    _passcodeController.dispose();
    super.dispose();
  }

  /// Counts the waiting time down, so the screen unlocks by itself.
  void _startLock(Duration remaining) {
    _lockTimer?.cancel();
    if (!mounted) return;
    setState(() => _lockLeft = remaining);
    if (remaining <= Duration.zero) return;
    _lockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final left = _lockLeft - const Duration(seconds: 1);
      if (!mounted) return;
      if (left <= Duration.zero) {
        timer.cancel();
        setState(() {
          _lockLeft = Duration.zero;
          _errorMessage = null;
        });
      } else {
        setState(() => _lockLeft = left);
      }
    });
  }

  Future<void> _forgot() async {
    final database = widget.database;
    if (database == null) return;
    final reset = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ForgotPasscodePage(
          database: database,
          onErased: () {
            widget.onErased?.call();
          },
        ),
      ),
    );
    if (reset == true && mounted) {
      _startLock(Duration.zero);
      setState(() => _errorMessage = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('Passcode changed. Enter it to unlock.'))),
      );
    }
  }

  Future<void> _unlock() async {
    final passcode = _passcodeController.text.trim();

    if (_locked) return;

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

    final result = await AccountSecurityService.checkPasscode(passcode);

    if (!mounted) {
      return;
    }

    if (!result.ok) {
      setState(() {
        _isChecking = false;
        _errorMessage = context.tr('Incorrect passcode. Try again.');
      });
      _passcodeController.clear();
      if (result.isLocked) _startLock(result.lockedFor!);
      return;
    }

    await widget.onUnlocked();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.meya.surface,
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
                  fillColor: context.meya.card,
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
              if (_errorMessage != null || _locked) ...[
                const SizedBox(height: 12),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    _locked
                        ? context.tr('Too many wrong tries. Try again in {0}.', [formatWait(_lockLeft)])
                        : _errorMessage!,
                    style: TextStyle(
                      color: context.meya.error,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isChecking || _locked ? null : _unlock,
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
              if (widget.database != null) ...[
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _forgot,
                  child: Text(context.tr('Forgot passcode?')),
                ),
              ],
              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }
}