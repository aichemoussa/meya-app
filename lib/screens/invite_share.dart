import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../database/account_repository.dart';
import '../database/meya_database.dart';
import '../l10n/meya_strings.dart';
import '../services/device_identity_service.dart';
import '../services/meya_e2ee.dart';
import '../services/meya_invite_service.dart';

const _share = MethodChannel('meya/share');

/// Makes a one-time invite link for this phone and opens the phone's share
/// sheet (WhatsApp, Telegram, Gmail, SMS...). Used wherever people add
/// someone: People, New chat and My QR.
Future<void> shareInviteLink(BuildContext context, MeyaDatabase database) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    final account = await AccountRepository(database).getActiveAccount();
    final identityId = account?.identityId;
    if (identityId == null || identityId.isEmpty) {
      messenger.showSnackBar(SnackBar(
        content: Text(tr('Your MEYA identity is not ready yet.')),
      ));
      return;
    }
    await shareInviteLinkFor(identityId);
  } catch (error) {
    messenger.showSnackBar(SnackBar(
      content: Text(tr('Could not share the link: {0}', [error])),
    ));
  }
}

/// [shareInviteLink] when the identity ID is already known.
Future<void> shareInviteLinkFor(String identityId) async {
  final deviceId = await DeviceIdentityService.getOrCreateDeviceId();
  final identityKey = await MeyaE2ee.instance.open();
  final invite = await MeyaInviteService.instance.create(
    identityId: identityId,
    identityPublicKey: identityKey,
    deviceId: deviceId,
  );
  await _share.invokeMethod<void>('shareText', {
    'title': tr('Share an invite link'),
    'text': tr(
      'Connect with me on MEYA, a private messenger. Open this link on your phone. It works once and expires in 7 days: {0}',
      [MeyaInviteService.linkFor(invite)],
    ),
  });
}
