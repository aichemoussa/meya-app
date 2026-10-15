import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meya/screens/sounds_page.dart';
import 'package:meya/services/meya_sound_settings.dart';
import 'package:meya/theme/meya_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('MEYA offers 10 ringtones and 10 notification sounds', () {
    for (final sounds in [
      MeyaSoundSettings.ringtones,
      MeyaSoundSettings.notificationSounds,
    ]) {
      expect(sounds, hasLength(10));
      expect(sounds.map((s) => s.id).toSet(), hasLength(10));
    }
  });

  test('every sound is a bundled MP3 file, playable on Android and iOS', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    for (final sound in [
      ...MeyaSoundSettings.ringtones,
      ...MeyaSoundSettings.notificationSounds,
    ]) {
      final file = File('assets/${sound.asset}');
      expect(file.existsSync(), isTrue, reason: sound.asset);
      expect(sound.asset, endsWith('.mp3'));
      final head = file.readAsBytesSync().take(3).toList();
      final id3 = String.fromCharCodes(head) == 'ID3';
      final frameSync = head[0] == 0xFF && (head[1] & 0xE0) == 0xE0;
      expect(id3 || frameSync, isTrue, reason: sound.asset);
      final folder = sound.asset.substring(0, sound.asset.lastIndexOf('/') + 1);
      expect(pubspec, contains('- assets/$folder'), reason: sound.asset);
    }
  });

  test('choices are remembered, unknown ones fall back to the first', () async {
    SharedPreferences.setMockInitialValues({});
    final settings = MeyaSoundSettings.instance;
    await settings.load();
    expect(settings.ringtone, MeyaSoundSettings.ringtones.first);

    await settings.setRingtone(MeyaSoundSettings.ringtones[4]);
    await settings.setNotification(MeyaSoundSettings.notificationSounds[7]);
    await settings.load();
    expect(settings.ringtone.id, 'soft_ring');
    expect(settings.notification.id, 'marie_3');

    SharedPreferences.setMockInitialValues({
      'meya_call_ringtone': 'removed-sound',
    });
    await settings.load();
    expect(settings.ringtone, MeyaSoundSettings.ringtones.first);
  });

  testWidgets('sounds page shows both drop-down lists', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await MeyaSoundSettings.instance.load();
    await tester.pumpWidget(MaterialApp(
      theme: buildMeyaTheme(MeyaPalette.light),
      home: const SoundsPage(),
    ));

    expect(find.byType(DropdownMenu<MeyaSound>), findsNWidgets(2));
    expect(find.text('Call ringtone'), findsWidgets);
    expect(find.text('Notification sound'), findsWidgets);

    await tester.tap(find.byType(DropdownMenu<MeyaSound>).first);
    await tester.pumpAndSettle();
    for (final sound in MeyaSoundSettings.ringtones) {
      expect(find.text(sound.name), findsWidgets, reason: sound.name);
    }
  });
}
