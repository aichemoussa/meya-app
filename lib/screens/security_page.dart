import 'package:flutter/material.dart';
import '../services/account_security_service.dart';
import '../theme/meya_theme.dart';
import '../l10n/meya_strings.dart';
import 'confirm_passcode.dart';
import 'forgot_passcode_page.dart' show formatWait;
import 'recovery_code_page.dart';

class SecurityPage extends StatefulWidget {
  const SecurityPage({super.key});

  @override
  State<SecurityPage> createState() => _SecurityPageState();
}

class _SecurityPageState extends State<SecurityPage> {
  bool _appLock = false;
  bool _hasRecoveryCode = false;
  bool _screenshotProtection = true;
  bool _securityNotifications = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final appLock = await AccountSecurityService.isAppLockEnabled();
    final hasCode = await AccountSecurityService.hasRecoveryCode();
    if (!mounted) return;
    setState(() {
      _appLock = appLock;
      _hasRecoveryCode = hasCode;
    });
  }

  /// Asks for the passcode, then makes a new recovery code and shows it once.
  Future<void> _newRecoveryCode() async {
    final go = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.tr('Create a new recovery code?')),
        content: Text(
          _hasRecoveryCode
              ? context.tr('Your old code stops working. You will see the new code once.')
              : context.tr('You will see the code once. Write it down on paper.'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.tr('Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(context.tr('Continue')),
          ),
        ],
      ),
    );
    if (go != true || !mounted) return;
    if (!await confirmPasscode(context) || !mounted) return;

    final code = await AccountSecurityService.createRecoveryCode();
    if (!mounted) return;
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => RecoveryCodePage(
          code: code,
          onDone: () => Navigator.pop(context),
        ),
      ),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('Security'))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          children: [
            Text(
              context.tr('Your security'),
              style: TextStyle(
                color: context.meya.text,
                fontSize: 28,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              context.tr('Protect your MEYA app and control how your private information is accessed.'),
              style: TextStyle(color: context.meya.muted, fontSize: 15, height: 1.5),
            ),
            const SizedBox(height: 28),
            _SecuritySectionTitle(title: context.tr('App protection')),
            const SizedBox(height: 10),
            _SecuritySwitch(
              title: context.tr('App lock'),
              subtitle: context.tr('Ask for your passcode when you come back to MEYA after 30 seconds away.'),
              value: _appLock,
              onChanged: (value) {
                setState(() => _appLock = value);
                AccountSecurityService.setAppLockEnabled(value);
              },
            ),
            const SizedBox(height: 12),
            _SecuritySwitch(
              title: context.tr('Biometric unlock'),
              subtitle: context.tr('Coming soon'),
              value: false,
              enabled: false,
              onChanged: (_) {},
            ),
            const SizedBox(height: 24),
            _SecuritySectionTitle(title: context.tr('Messages & screen')),
            const SizedBox(height: 10),
            _SecuritySwitch(
              title: context.tr('Screenshot protection'),
              subtitle: context.tr('Reduce the ability to capture MEYA screens.'),
              value: _screenshotProtection,
              onChanged: (value) {
                setState(() {
                  _screenshotProtection = value;
                });
              },
            ),
            const SizedBox(height: 12),
            _SecuritySwitch(
              title: context.tr('Security notifications'),
              subtitle: context.tr('Notify you when important security events occur.'),
              value: _securityNotifications,
              onChanged: (value) {
                setState(() {
                  _securityNotifications = value;
                });
              },
            ),
            const SizedBox(height: 24),
            _SecuritySectionTitle(title: context.tr('Account security')),
            const SizedBox(height: 10),
            _SecurityAction(
              icon: Icons.password_outlined,
              title: context.tr('Change passcode'),
              subtitle: context.tr('Change the passcode that protects MEYA.'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ChangePasscodePage(),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _SecurityAction(
              icon: Icons.vpn_key_outlined,
              title: context.tr('Recovery code'),
              subtitle: _hasRecoveryCode
                  ? context.tr('Create a new code. The old one stops working.')
                  : context.tr('Not set up. Create one so you can reset a forgotten passcode.'),
              onTap: _newRecoveryCode,
            ),
            const SizedBox(height: 12),
            _SecurityAction(
              icon: Icons.devices_outlined,
              title: context.tr('Trusted devices'),
              subtitle: context.tr('Review devices associated with your MEYA account.'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TrustedDevicesPage(),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _SecurityAction(
              icon: Icons.key_outlined,
              title: context.tr('Encryption'),
              subtitle: context.tr('Learn how MEYA protects private conversations.'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EncryptionInfoPage(),
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

/// Changes the passcode. The current passcode is required, and wrong tries
/// count towards the same waiting time as the unlock screen.
class ChangePasscodePage extends StatefulWidget {
  const ChangePasscodePage({super.key});

  @override
  State<ChangePasscodePage> createState() => _ChangePasscodePageState();
}

class _ChangePasscodePageState extends State<ChangePasscodePage> {
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _saving = false;
  String? _currentError;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _currentError = null);
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    final result =
        await AccountSecurityService.checkPasscode(_currentController.text);
    if (!mounted) return;
    if (!result.ok) {
      _currentController.clear();
      setState(() {
        _saving = false;
        _currentError = result.isLocked
            ? context.tr('Too many wrong tries. Try again in {0}.', [formatWait(result.lockedFor!)])
            : context.tr('Your current passcode is not right.');
      });
      return;
    }

    await AccountSecurityService.savePasscode(_newController.text);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(context.tr('Passcode changed.'))));
    Navigator.pop(context);
  }

  Widget _field(
    TextEditingController controller,
    String label,
    String? Function(String?) validator, {
    String? error,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          obscureText: true,
          maxLength: 6,
          decoration: InputDecoration(labelText: label, errorText: error),
          validator: validator,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('Change passcode'))),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 32),
            children: [
              Text(
                context.tr('Change the passcode that protects MEYA.'),
                style: TextStyle(color: context.meya.muted, fontSize: 15, height: 1.5),
              ),
              const SizedBox(height: 24),
              _field(
                _currentController,
                context.tr('Current passcode'),
                (value) => value == null || value.isEmpty
                    ? context.tr('Enter your passcode.')
                    : null,
                error: _currentError,
              ),
              _field(_newController, context.tr('New passcode'), (value) {
                if (value == null || value.isEmpty) {
                  return context.tr('Please create a passcode');
                }
                if (!RegExp(r'^\d{4,6}$').hasMatch(value)) {
                  return context.tr('Use 4 to 6 digits');
                }
                return null;
              }),
              _field(_confirmController, context.tr('Confirm passcode'), (value) {
                if (value == null || value.isEmpty) {
                  return context.tr('Please confirm your passcode');
                }
                if (value != _newController.text) {
                  return context.tr('Passcodes do not match');
                }
                return null;
              }),
              const SizedBox(height: 12),
              SizedBox(
                height: 56,
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: context.meya.navy,
                    foregroundColor: context.meya.onNavy,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    context.tr('Save passcode'),
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
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

class TrustedDevicesPage extends StatelessWidget {
  const TrustedDevicesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('Trusted devices'))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          children: [
            Text(
              context.tr('Your devices'),
              style: TextStyle(
                color: context.meya.text,
                fontSize: 26,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              context.tr('Review devices that are authorized to access your MEYA account.'),
              style: TextStyle(color: context.meya.muted, fontSize: 15, height: 1.5),
            ),
            const SizedBox(height: 24),
            _DeviceCard(
              icon: Icons.phone_android_outlined,
              title: context.tr('Current device'),
              subtitle: context.tr('This device'),
              current: true,
              onRemove: null,
            ),
            const SizedBox(height: 12),
            Text(
              context.tr('Additional device management will be connected when MEYA accounts and server-side sessions are implemented.'),
              style: TextStyle(color: context.meya.muted, fontSize: 14, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

class EncryptionInfoPage extends StatelessWidget {
  const EncryptionInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('Encryption'))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: context.meya.card,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Icon(Icons.lock_outline, color: context.meya.navy, size: 42),
            ),
            const SizedBox(height: 24),
            Text(
              context.tr('Private by design'),
              style: TextStyle(
                color: context.meya.text,
                fontSize: 26,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              context.tr('MEYA is being designed around privacy, limited data retention and secure communication.'),
              style: TextStyle(color: context.meya.muted, fontSize: 15, height: 1.5),
            ),
            const SizedBox(height: 24),
            _EncryptionCard(
              icon: Icons.lock_outline,
              title: context.tr('Encrypted data'),
              description: context.tr('Sensitive information should be protected both when stored and when transmitted.'),
            ),
            const SizedBox(height: 12),
            _EncryptionCard(
              icon: Icons.key_outlined,
              title: context.tr('Secure keys'),
              description: context.tr('Cryptographic keys should be protected using appropriate platform security mechanisms.'),
            ),
            const SizedBox(height: 12),
            _EncryptionCard(
              icon: Icons.visibility_off_outlined,
              title: context.tr('Limited retention'),
              description: context.tr('MEYA is designed to avoid retaining unnecessary personal information.'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SecuritySectionTitle extends StatelessWidget {
  final String title;

  const _SecuritySectionTitle({required this.title});

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

class _SecuritySwitch extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _SecuritySwitch({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.enabled = true,
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
                      color: enabled ? context.meya.text : context.meya.muted,
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
              onChanged: enabled ? onChanged : null,
              activeThumbColor: context.meya.onNavy,
              activeTrackColor: context.meya.navy,
            ),
          ],
        ),
      ),
    );
  }
}

class _SecurityAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SecurityAction({
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

class _DeviceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool current;
  final VoidCallback? onRemove;

  const _DeviceCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.current,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.meya.card,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: context.meya.surface,
              borderRadius: BorderRadius.circular(16),
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
                  style: TextStyle(color: context.meya.muted, fontSize: 14),
                ),
              ],
            ),
          ),
          if (current)
            Text(
              context.tr('Current'),
              style: TextStyle(
                color: context.meya.navy,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            )
          else if (onRemove != null)
            IconButton(
              onPressed: onRemove,
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
    );
  }
}

class _EncryptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _EncryptionCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.meya.card,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: context.meya.surface,
              borderRadius: BorderRadius.circular(14),
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
                const SizedBox(height: 6),
                Text(
                  description,
                  style: TextStyle(
                    color: context.meya.muted,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
