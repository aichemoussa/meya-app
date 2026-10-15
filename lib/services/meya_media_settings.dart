import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'meya_blob_store.dart';

enum PhotoQuality { standard, high }

/// How long received and sent media stay on this device.
enum KeepMedia { forever, oneYear, threeMonths, oneMonth }

extension KeepMediaDuration on KeepMedia {
  Duration? get duration => switch (this) {
        KeepMedia.forever => null,
        KeepMedia.oneYear => const Duration(days: 365),
        KeepMedia.threeMonths => const Duration(days: 90),
        KeepMedia.oneMonth => const Duration(days: 30),
      };
}

/// Storage & Media settings, stored on this device.
class MeyaMediaSettings extends ChangeNotifier {
  MeyaMediaSettings._();

  static final MeyaMediaSettings instance = MeyaMediaSettings._();

  static const _qualityKey = 'meya_photo_quality';
  static const _keepKey = 'meya_keep_media';

  PhotoQuality _photoQuality = PhotoQuality.standard;
  KeepMedia _keepMedia = KeepMedia.forever;

  PhotoQuality get photoQuality => _photoQuality;
  KeepMedia get keepMedia => _keepMedia;

  /// Longest side of a photo after sending, in pixels.
  double get photoMaxSide =>
      _photoQuality == PhotoQuality.high ? 3000 : 1600;

  /// JPEG quality used when sending photos.
  int get photoJpegQuality => _photoQuality == PhotoQuality.high ? 92 : 80;

  Future<void> load() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      _photoQuality = PhotoQuality.values.firstWhere(
        (value) => value.name == preferences.getString(_qualityKey),
        orElse: () => PhotoQuality.standard,
      );
      _keepMedia = KeepMedia.values.firstWhere(
        (value) => value.name == preferences.getString(_keepKey),
        orElse: () => KeepMedia.forever,
      );
    } catch (error) {
      debugPrint('MEYA media settings: using defaults ($error).');
    }
    notifyListeners();
  }

  Future<void> setPhotoQuality(PhotoQuality value) async {
    _photoQuality = value;
    notifyListeners();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_qualityKey, value.name);
  }

  Future<void> setKeepMedia(KeepMedia value) async {
    _keepMedia = value;
    notifyListeners();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_keepKey, value.name);
    await applyKeepMedia();
  }

  /// Removes media older than the chosen period. Runs at start-up and
  /// whenever the setting changes.
  Future<int> applyKeepMedia() async {
    final age = _keepMedia.duration;
    if (age == null) return 0;
    try {
      return await MeyaBlobStore.instance.deleteOlderThan(age);
    } catch (error) {
      debugPrint('MEYA media settings: clean-up failed ($error).');
      return 0;
    }
  }
}
