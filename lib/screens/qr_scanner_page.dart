import 'dart:math';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../database/connection_request_repository.dart';
import '../database/meya_database.dart';
import '../services/device_identity_service.dart';
import '../services/meya_e2ee.dart';
import '../services/meya_pairing_service.dart';
import '../theme/meya_theme.dart';
import '../l10n/meya_strings.dart';

class MeyaQrScannerPage extends StatefulWidget {
  final MeyaDatabase database;

  const MeyaQrScannerPage({super.key, required this.database});

  @override
  State<MeyaQrScannerPage> createState() => _MeyaQrScannerPageState();
}

class _MeyaQrScannerPageState extends State<MeyaQrScannerPage> {
  final MobileScannerController _controller = MobileScannerController();

  final ImagePicker _imagePicker = ImagePicker();

  bool _handled = false;
  bool _importingImage = false;

  Future<Account?> _getLocalAccount() async {
    return (widget.database.select(widget.database.accounts)
          ..where((account) => account.isActive.equals(true))
          ..limit(1))
        .getSingleOrNull();
  }

  Future<void> _importQrImage() async {
    if (_handled || _importingImage) {
      return;
    }

    setState(() {
      _importingImage = true;
    });

    try {
      final image = await _imagePicker.pickImage(source: ImageSource.gallery);

      if (image == null) {
        return;
      }

      final capture = await MobileScannerPlatform.instance.analyzeImage(
        image.path,
        formats: const [BarcodeFormat.qrCode],
      );

      if (capture == null || capture.barcodes.isEmpty) {
        if (!mounted) {
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('No MEYA QR code was found in that image.')),
          ),
        );

        return;
      }

      for (final barcode in capture.barcodes) {
        final value = barcode.rawValue;

        if (value != null && value.isNotEmpty) {
          await _handleQr(value);

          if (_handled) {
            break;
          }
        }
      }

      if (!_handled && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('That QR code is not a valid MEYA code.')),
          ),
        );
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('Could not read the QR image: {0}', [error]))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _importingImage = false;
        });
      }
    }
  }

  Future<void> _handleQr(String value) async {
    if (_handled) {
      return;
    }

    final parts = value.split('|');

    if (parts.length != 7 || parts[0] != 'MEYA') {
      return;
    }

    if (parts[1] != '5') {
      _handled = true;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.tr('This QR code was made by an older version of MEYA. Ask the other person to update MEYA and show their QR code again.'),
            ),
          ),
        );
      }
      Future<void>.delayed(const Duration(seconds: 3), () => _handled = false);
      return;
    }

    final identityId = parts[2].trim();
    final username = parts[3].trim();
    final displayName = parts[4].trim();
    final identityPublicKey = parts[5].trim();
    final recipientDeviceId = parts[6].trim();

    if (identityId.isEmpty ||
        username.isEmpty ||
        identityPublicKey.isEmpty ||
        recipientDeviceId.isEmpty) {
      return;
    }

    final localAccount = await _getLocalAccount();

    if (localAccount == null) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('Your MEYA account is not available on this device.')),
        ),
      );

      return;
    }

    final localIdentityId = localAccount.identityId;
    final localUsername = localAccount.username;
    final String localIdentityPublicKey;
    try {
      localIdentityPublicKey = await MeyaE2ee.instance.open();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('MEYA encryption could not start: {0}', [error]))),
      );
      return;
    }

    if (localIdentityId == null ||
        localIdentityId.isEmpty ||
        localUsername.isEmpty ||
        localIdentityPublicKey.isEmpty) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('Your MEYA identity is not ready yet.'))),
      );

      return;
    }

    final senderDeviceId = await DeviceIdentityService.getDeviceId();

    if (senderDeviceId == null || senderDeviceId.isEmpty) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('Your MEYA device identity is not available.')),
        ),
      );

      return;
    }

    if (senderDeviceId == recipientDeviceId) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('You cannot send a connection request to this device.')),
        ),
      );

      return;
    }

    _handled = true;

    // A fresh ID for every scan. A fixed ID (device + identity) collided with
    // the earlier, already accepted connection between the same two people,
    // so a new scan was silently ignored by the other phone and the relay.
    final random = Random.secure();
    final requestId = 'req_${List<int>.generate(16, (_) => random.nextInt(256)).map((b) => b.toRadixString(16).padLeft(2, '0')).join()}';

    final repository = ConnectionRequestRepository(widget.database);

    try {
      // Trust exactly the identity key shown in this QR code for that device.
      // Fails if a different key was trusted for it before.
      await MeyaE2ee.instance.pinIdentity(recipientDeviceId, identityPublicKey);

      await repository.createOutgoingRequest(
        requestId: requestId,
        senderIdentityId: localIdentityId,
        senderDeviceId: senderDeviceId,
        senderUsername: localUsername,
        senderIdentityPublicKey: localIdentityPublicKey,
        recipientDeviceId: recipientDeviceId,
        recipientIdentityId: identityId,
        recipientIdentityPublicKey: identityPublicKey,
        createdAt: DateTime.now().toUtc().toIso8601String(),
      );

      await MeyaPairingService.instance.sendConnectionRequest(
        requestId: requestId,
        recipientDeviceId: recipientDeviceId,
        identityId: localIdentityId,
        username: localUsername,
        identityPublicKey: localIdentityPublicKey,
        name: localAccount.name,
      );
    } catch (error) {
      _handled = false;

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('Could not send connection request: {0}', [error]))),
      );

      return;
    }

    if (!mounted) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: context.meya.surface,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.person_add_alt_1_outlined,
                  color: context.meya.navy,
                  size: 36,
                ),
                const SizedBox(height: 16),
                Text(
                  context.tr('Connection request sent'),
                  style: TextStyle(
                    color: context.meya.text,
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '@$username',
                  style: TextStyle(
                    color: context.meya.muted,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  context.tr('Your request has been sent. This person must accept it before they become a MEYA contact.'),
                  style: TextStyle(
                    color: context.meya.muted,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      Navigator.pop(context);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: context.meya.navy,
                      foregroundColor: context.meya.onNavy,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: Text(
                      context.tr('Done'),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('Scan QR code')),
        actions: [
          IconButton(
            tooltip: context.tr('Import QR image'),
            onPressed: _importingImage ? null : _importQrImage,
            icon: _importingImage
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.photo_library_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            MobileScanner(
              controller: _controller,
              onDetect: (capture) {
                for (final barcode in capture.barcodes) {
                  final value = barcode.rawValue;

                  if (value != null) {
                    _handleQr(value);

                    if (_handled) {
                      break;
                    }
                  }
                }
              },
            ),
            Center(
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 3),
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
            ),
            Positioned(
              left: 28,
              right: 28,
              bottom: 28,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.68),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  context.tr('Scan another MEYA QR code, or tap the photo icon above to import a QR image.'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
