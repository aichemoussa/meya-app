import 'package:flutter/material.dart';

import '../l10n/meya_strings.dart';
import '../theme/meya_theme.dart';

/// Shows a recovery code once. The code has already been created (and any
/// older one replaced), so the person cannot leave until they confirm that
/// they have written it down.
class RecoveryCodePage extends StatefulWidget {
  /// The code in groups, e.g. `ABCD-EFGH-...`.
  final String code;

  /// Called when the person confirms and taps Continue.
  final VoidCallback onDone;

  const RecoveryCodePage({super.key, required this.code, required this.onDone});

  @override
  State<RecoveryCodePage> createState() => _RecoveryCodePageState();
}

class _RecoveryCodePageState extends State<RecoveryCodePage> {
  bool _written = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.meya;
    final groups = widget.code.split('-');

    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(context.tr('Your recovery code')),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 32),
            children: [
              Icon(Icons.vpn_key_outlined, size: 44, color: colors.navy),
              const SizedBox(height: 16),
              Text(
                context.tr('Write this code on paper and keep it somewhere safe, away from your phone. It is the only way to reset a forgotten passcode and keep your account. MEYA cannot show it again.'),
                style: TextStyle(color: colors.text, fontSize: 16, height: 1.5),
              ),
              const SizedBox(height: 24),
              Semantics(
                label: '${context.tr('Recovery code')}: ${widget.code.replaceAll('-', ' ').split('').join(' ')}',
                excludeSemantics: true,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
                  decoration: BoxDecoration(
                    color: colors.card,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: colors.navy, width: 2),
                  ),
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 18,
                    runSpacing: 12,
                    children: [
                      for (final group in groups)
                        Text(
                          group,
                          style: TextStyle(
                            color: colors.text,
                            fontFamily: 'monospace',
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 3,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning_amber_rounded, color: colors.error, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      context.tr('Do not take a screenshot or save it on your phone.'),
                      style: TextStyle(color: colors.muted, fontSize: 14, height: 1.4),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              CheckboxListTile(
                value: _written,
                onChanged: (value) => setState(() => _written = value ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                title: Text(context.tr('I have written it down')),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 56,
                child: FilledButton(
                  onPressed: _written ? widget.onDone : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.navy,
                    foregroundColor: colors.onNavy,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    context.tr('Continue'),
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
