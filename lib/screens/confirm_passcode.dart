import 'package:flutter/material.dart';

import '../l10n/meya_strings.dart';
import '../services/account_security_service.dart';
import 'forgot_passcode_page.dart' show formatWait;

/// Asks for the current passcode before something sensitive (such as making
/// a new recovery code). Returns true only when the passcode was right.
/// Wrong tries count towards the same waiting time as the unlock screen.
Future<bool> confirmPasscode(BuildContext context) async {
  final controller = TextEditingController();
  String? error;
  var busy = false;

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(context.tr('Confirm your passcode')),
        content: TextField(
          controller: controller,
          autofocus: true,
          obscureText: true,
          keyboardType: TextInputType.number,
          maxLength: 6,
          decoration: InputDecoration(
            labelText: context.tr('Passcode'),
            errorText: error,
            counterText: '',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.tr('Cancel')),
          ),
          FilledButton(
            onPressed: busy
                ? null
                : () async {
                    setState(() => busy = true);
                    final result =
                        await AccountSecurityService.checkPasscode(controller.text);
                    if (!context.mounted) return;
                    if (result.ok) {
                      Navigator.pop(dialogContext, true);
                      return;
                    }
                    controller.clear();
                    setState(() {
                      busy = false;
                      error = result.isLocked
                          ? context.tr('Too many wrong tries. Try again in {0}.', [formatWait(result.lockedFor!)])
                          : context.tr('Incorrect passcode. Try again.');
                    });
                  },
            child: Text(context.tr('Continue')),
          ),
        ],
      ),
    ),
  );
  controller.dispose();
  return confirmed == true;
}
