// Draws the MEYA app icons from the logo painter, so the icons and the logo
// inside the app always match. Run after changing the logo:
//
//   flutter test tool/generate_app_icons_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meya/theme/meya_logo.dart';

const _white = Color(0xFFFFFFFF);

/// Draws the 512-unit artwork at [artwork] × [size] on [background].
Future<void> _write(
  String path,
  int size, {
  required double artwork,
  Color? background,
  double cornerRadius = 0,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final full = Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble());
  if (background != null) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(full, Radius.circular(cornerRadius * size)),
      Paint()..color = background,
    );
  }
  final logo = size * artwork;
  canvas.translate((size - logo) / 2, (size - logo) / 2);
  const MeyaLogoPainter().paint(canvas, Size.square(logo));
  final image = await recorder.endRecording().toImage(size, size);
  final png = await image.toByteData(format: ui.ImageByteFormat.png);
  final file = File(path);
  await file.parent.create(recursive: true);
  await file.writeAsBytes(png!.buffer.asUint8List());
}

void main() {
  testWidgets('generate app icons', (tester) async {
    await tester.runAsync(() async {
      const res = 'android/app/src/main/res';
      const densities = {
        'mdpi': 1.0,
        'hdpi': 1.5,
        'xhdpi': 2.0,
        'xxhdpi': 3.0,
        'xxxhdpi': 4.0,
      };
      for (final MapEntry(key: density, value: scale) in densities.entries) {
        // Android 7 and older: a white rounded square.
        await _write(
          '$res/mipmap-$density/ic_launcher.png',
          (48 * scale).round(),
          artwork: 0.8,
          background: _white,
          cornerRadius: 0.22,
        );
        // Android 8+: the mark alone on a 108 dp layer whose middle 66 dp
        // stay visible whatever shape the launcher cuts.
        await _write(
          '$res/mipmap-$density/ic_launcher_foreground.png',
          (108 * scale).round(),
          artwork: 0.62,
        );
      }

      // iOS: full squares without transparency (iOS rounds the corners).
      const ios = 'ios/Runner/Assets.xcassets/AppIcon.appiconset';
      const iosIcons = {
        '20x20@1x': 20, '20x20@2x': 40, '20x20@3x': 60,
        '29x29@1x': 29, '29x29@2x': 58, '29x29@3x': 87,
        '40x40@1x': 40, '40x40@2x': 80, '40x40@3x': 120,
        '60x60@2x': 120, '60x60@3x': 180,
        '76x76@1x': 76, '76x76@2x': 152,
        '83.5x83.5@2x': 167,
        '1024x1024@1x': 1024,
      };
      for (final MapEntry(key: name, value: size) in iosIcons.entries) {
        await _write('$ios/Icon-App-$name.png', size,
            artwork: 0.8, background: _white);
      }

      // Web.
      await _write('web/favicon.png', 32, artwork: 0.95);
      for (final size in [192, 512]) {
        await _write('web/icons/Icon-$size.png', size,
            artwork: 0.8, background: _white, cornerRadius: 0.22);
        await _write('web/icons/Icon-maskable-$size.png', size,
            artwork: 0.62, background: _white);
      }

      // A preview of the largest icon for review.
      await _write('assets/brand/meya-icon-1024.png', 1024,
          artwork: 0.8, background: _white, cornerRadius: 0.22);
    });
  });
}
