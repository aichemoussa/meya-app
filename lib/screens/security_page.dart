import 'package:flutter/material.dart';
import '../theme/meya_theme.dart';
import '../l10n/meya_strings.dart';

class SecurityPage extends StatefulWidget {
  const SecurityPage({super.key});

  @override
  State<SecurityPage> createState() => _SecurityPageState();
}

class _SecurityPageState extends State<SecurityPage> {
  bool _appLock = false;
  bool _biometricUnlock = false;
  bool _screenshotProtection = true;
  bool _securityNotifications = true;

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
              subtitle: context.tr('Require a security check when opening MEYA.'),
              value: _appLock,
              onChanged: (value) {
                setState(() {
                  _appLock = value;

                  if (!value) {
                    _biometricUnlock = false;
                  }
                });
              },
            ),
            const SizedBox(height: 12),
            _SecuritySwitch(
              title: context.tr('Biometric unlock'),
              subtitle: context.tr('Use your device biometrics to unlock MEYA.'),
              value: _biometricUnlock,
              enabled: _appLock,
              onChanged: (value) {
                setState(() {
                  _biometricUnlock = value;
                });
              },
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
              title: context.tr('Change security PIN'),
              subtitle: context.tr('Create or change the PIN used to protect MEYA.'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SecurityPinPage(),
                  ),
                );
              },
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

class SecurityPinPage extends StatefulWidget {
  const SecurityPinPage({super.key});

  @override
  State<SecurityPinPage> createState() => _SecurityPinPageState();
}

class _SecurityPinPageState extends State<SecurityPinPage> {
  final _pinController = TextEditingController();
  final _confirmController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _pinController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _savePin() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(context.tr('Security PIN saved.'))));

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('Security PIN'))),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 32),
            children: [
              Text(
                context.tr('Protect MEYA with a PIN'),
                style: TextStyle(
                  color: context.meya.text,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                context.tr('Your PIN can be used as an additional layer of protection for the app.'),
                style: TextStyle(color: context.meya.muted, fontSize: 15, height: 1.5),
              ),
              const SizedBox(height: 28),
              Text(
                context.tr('New PIN'),
                style: TextStyle(
                  color: context.meya.text,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _pinController,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 6,
                decoration: InputDecoration(
                  hintText: context.tr('Enter a PIN of 4 to 6 digits'),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return context.tr('Enter a PIN');
                  }

                  if (value.length < 4 || value.length > 6) {
                    return context.tr('Use 4 to 6 digits');
                  }

                  if (int.tryParse(value) == null) {
                    return context.tr('Use numbers only');
                  }

                  return null;
                },
              ),
              const SizedBox(height: 16),
              Text(
                context.tr('Confirm PIN'),
                style: TextStyle(
                  color: context.meya.text,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _confirmController,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 6,
                decoration: InputDecoration(
                  hintText: context.tr('Enter the PIN again'),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return context.tr('Confirm your PIN');
                  }

                  if (value != _pinController.text) {
                    return context.tr('PINs do not match');
                  }

                  return null;
                },
              ),
              const SizedBox(height: 28),
              SizedBox(
                height: 56,
                child: FilledButton(
                  onPressed: _savePin,
                  style: FilledButton.styleFrom(
                    backgroundColor: context.meya.navy,
                    foregroundColor: context.meya.onNavy,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    context.tr('Save PIN'),
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
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
