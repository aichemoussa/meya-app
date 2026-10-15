import 'package:flutter/material.dart';

import '../services/account_security_service.dart';
import '../theme/meya_theme.dart';
import '../l10n/meya_strings.dart';

class CreatePasscodePage extends StatefulWidget {
  final Future<void> Function(String passcode) onPasscodeCreated;

  const CreatePasscodePage({
    super.key,
    required this.onPasscodeCreated,
  });

  @override
  State<CreatePasscodePage> createState() => _CreatePasscodePageState();
}

class _CreatePasscodePageState extends State<CreatePasscodePage> {
  final _formKey = GlobalKey<FormState>();
  final _passcodeController = TextEditingController();
  final _confirmationController = TextEditingController();

  bool _obscurePasscode = true;
  bool _obscureConfirmation = true;
  bool _saving = false;

  @override
  void dispose() {
    _passcodeController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  Future<void> _createPasscode() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _saving = true;
    });

    await AccountSecurityService.savePasscode(_passcodeController.text);

    await widget.onPasscodeCreated(_passcodeController.text);

    if (!mounted) {
      return;
    }

    setState(() {
      _saving = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('Create your passcode')),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 32),
            children: [
              Text(
                context.tr('Protect your MEYA account'),
                style: TextStyle(
                  color: context.meya.text,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                context.tr('Create a passcode that will be used to protect access to your MEYA account.'),
                style: TextStyle(
                  color: context.meya.muted,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                context.tr('Passcode'),
                style: TextStyle(
                  color: context.meya.text,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _passcodeController,
                obscureText: _obscurePasscode,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: InputDecoration(
                  hintText: context.tr('Enter 4 to 6 digits'),
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
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return context.tr('Please create a passcode');
                  }

                  if (!RegExp(r'^\d{4,6}$').hasMatch(value)) {
                    return context.tr('Use 4 to 6 digits');
                  }

                  return null;
                },
              ),
              const SizedBox(height: 16),
              Text(
                context.tr('Confirm passcode'),
                style: TextStyle(
                  color: context.meya.text,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _confirmationController,
                obscureText: _obscureConfirmation,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: InputDecoration(
                  hintText: context.tr('Enter the passcode again'),
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        _obscureConfirmation = !_obscureConfirmation;
                      });
                    },
                    icon: Icon(
                      _obscureConfirmation
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return context.tr('Please confirm your passcode');
                  }

                  if (value != _passcodeController.text) {
                    return context.tr('Passcodes do not match');
                  }

                  return null;
                },
              ),
              const SizedBox(height: 12),
              Text(
                context.tr('Your passcode is stored securely on this device.'),
                style: TextStyle(
                  color: context.meya.muted,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: _saving ? null : _createPasscode,
                  style: FilledButton.styleFrom(
                    backgroundColor: context.meya.navy,
                    foregroundColor: context.meya.onNavy,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          context.tr('Create account'),
                          style: TextStyle(
                            fontSize: 17,
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
