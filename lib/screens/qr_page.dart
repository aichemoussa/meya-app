import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../services/device_identity_service.dart';
import '../services/meya_e2ee.dart';
import 'invite_share.dart';
import '../services/meya_relay_session.dart';
import '../theme/meya_theme.dart';
import '../l10n/meya_strings.dart';

/// Shows this device's MEYA QR code.
///
/// The QR code only needs local identity data, so it is shown immediately.
/// The relay connection (needed to *receive* the connection request) is
/// started in parallel and its state is shown separately, with a retry.
class MeyaQrPage extends StatefulWidget {
  final String name;
  final String username;
  final String identityId;
  final String identityPublicKey;

  const MeyaQrPage({
    super.key,
    required this.name,
    required this.username,
    required this.identityId,
    required this.identityPublicKey,
  });

  @override
  State<MeyaQrPage> createState() => _MeyaQrPageState();
}

enum _RelayState { connecting, connected, failed }

class _MeyaQrPageState extends State<MeyaQrPage> {
  late final Future<String?> _payload = _buildPayload();
  _RelayState _relayState = _RelayState.connecting;
  String? _relayError;

  @override
  void initState() {
    super.initState();
    _connectRelay();
  }

  Future<String?> _buildPayload() async {
    final deviceId = await DeviceIdentityService.getOrCreateDeviceId();
    if (deviceId.isEmpty) {
      return null;
    }
    // The QR code carries this device's end-to-end encryption identity key.
    final identityKey = await MeyaE2ee.instance.open();

    // '|' separates the QR fields, so it must never appear inside a field.
    String clean(String value) => value.replaceAll('|', ' ').trim();

    return 'MEYA|5|${clean(widget.identityId)}|${clean(widget.username)}|'
        '${clean(widget.name)}|${clean(identityKey)}|$deviceId';
  }

  bool _sharing = false;

  /// Makes a one-time invite link and opens the phone's share sheet.
  Future<void> _shareInvite() async {
    setState(() => _sharing = true);
    try {
      await shareInviteLinkFor(widget.identityId);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('Could not share the link: {0}', [error]))),
      );
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  Future<void> _connectRelay() async {
    setState(() {
      _relayState = _RelayState.connecting;
      _relayError = null;
    });

    try {
      await MeyaRelaySession.instance.start();
      if (!mounted) return;
      setState(() => _relayState = _RelayState.connected);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _relayState = _RelayState.failed;
        _relayError = error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('My QR'))),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 36),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 280,
                  height: 280,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: FutureBuilder<String?>(
                    future: _payload,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState != ConnectionState.done) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final payload = snapshot.data;
                      if (snapshot.hasError || payload == null) {
                        return Center(
                          child: Text(
                            context.tr('Your MEYA device identity is not available. Restart MEYA and try again.'),
                            textAlign: TextAlign.center,
                          ),
                        );
                      }

                      return Semantics(
                        label: context.tr('Your MEYA QR code'),
                        child: QrImageView(
                          data: payload,
                          version: QrVersions.auto,
                          size: 244,
                          backgroundColor: Colors.white,
                          // Fixed brand colours on white in every theme, so
                          // the code always scans reliably.
                          eyeStyle: QrEyeStyle(
                            eyeShape: QrEyeShape.square,
                            color: MeyaPalette.light.navy,
                          ),
                          dataModuleStyle: QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.square,
                            color: MeyaPalette.light.text,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 18),
                // Right under the code, so it is seen without scrolling.
                FilledButton.icon(
                  onPressed: _sharing ? null : _shareInvite,
                  icon: const Icon(Icons.share_outlined),
                  label: Text(context.tr('Share an invite link')),
                ),
                const SizedBox(height: 18),
                _RelayStatus(
                  state: _relayState,
                  error: _relayError,
                  onRetry: _connectRelay,
                ),
                const SizedBox(height: 22),
                Text(
                  widget.name,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: context.meya.text,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '@${widget.username}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: context.meya.muted,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  context.tr('Show this QR code to a person you trust to begin MEYA device pairing.'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: context.meya.muted,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  context.tr('This QR code starts a connection request. The other person must accept before you become MEYA contacts.'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: context.meya.muted,
                    fontSize: 12,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RelayStatus extends StatelessWidget {
  final _RelayState state;
  final String? error;
  final VoidCallback onRetry;

  const _RelayStatus({
    required this.state,
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    switch (state) {
      case _RelayState.connecting:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 10),
            Text(context.tr('Connecting to the MEYA relay…')),
          ],
        );
      case _RelayState.connected:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: context.meya.success, size: 20),
            SizedBox(width: 8),
            Text(context.tr('Ready to receive connection requests')),
          ],
        );
      case _RelayState.failed:
        return Column(
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, color: context.meya.error, size: 20),
                SizedBox(width: 8),
                Flexible(
                  child: Text(
                    context.tr('Not connected to the MEYA relay. Requests cannot arrive yet.'),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            if (error != null) ...[
              const SizedBox(height: 6),
              SelectableText(
                error!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: context.meya.muted),
              ),
            ],
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(context.tr('Try again')),
            ),
          ],
        );
    }
  }
}
