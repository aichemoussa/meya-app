import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A sound bundled with MEYA. The names are proper names and stay the same
/// in every language.
class MeyaSound {
  final String id;
  final String name;

  /// Path inside `assets/`, as `AssetSource` expects it.
  final String asset;

  const MeyaSound(this.id, this.name, this.asset);
}

/// Call ringtone and notification sound, stored on this device.
///
/// The sounds are MP3 files from BigSoundBank, released under CC0 (public
/// domain), so they play on every platform; see assets/sounds/SOURCES.txt.
class MeyaSoundSettings extends ChangeNotifier {
  MeyaSoundSettings._();

  static final MeyaSoundSettings instance = MeyaSoundSettings._();

  static const _ringtoneKey = 'meya_call_ringtone';
  static const _notificationKey = 'meya_notification_sound';

  static const List<MeyaSound> ringtones = [
    MeyaSound('phone_ring', 'Phone Ring', 'sounds/ringtones/phone_ring.mp3'),
    MeyaSound('landline', 'Landline', 'sounds/ringtones/landline.mp3'),
    MeyaSound('retro_bell', 'Retro Bell', 'sounds/ringtones/retro_bell.mp3'),
    MeyaSound('socotel', 'Socotel', 'sounds/ringtones/socotel.mp3'),
    MeyaSound('soft_ring', 'Soft Ring', 'sounds/ringtones/soft_ring.mp3'),
    MeyaSound('phone_booth', 'Phone Booth', 'sounds/ringtones/phone_booth.mp3'),
    MeyaSound('digital_pager', 'Digital Pager', 'sounds/ringtones/digital_pager.mp3'),
    MeyaSound('pager_beeps', 'Pager Beeps', 'sounds/ringtones/pager_beeps.mp3'),
    MeyaSound('dreamcatcher', 'Dreamcatcher', 'sounds/ringtones/dreamcatcher.mp3'),
    MeyaSound('butterfly', 'Butterfly', 'sounds/ringtones/butterfly.mp3'),
  ];

  static const List<MeyaSound> notificationSounds = [
    MeyaSound('lisa_1', 'Bloom', 'sounds/notifications/lisa_1.mp3'),
    MeyaSound('lisa_2', 'Glint', 'sounds/notifications/lisa_2.mp3'),
    MeyaSound('lisa_3', 'Pebble', 'sounds/notifications/lisa_3.mp3'),
    MeyaSound('lisa_4', 'Ripple', 'sounds/notifications/lisa_4.mp3'),
    MeyaSound('lisa_5', 'Spark', 'sounds/notifications/lisa_5.mp3'),
    MeyaSound('marie_1', 'Chirp', 'sounds/notifications/marie_1.mp3'),
    MeyaSound('marie_2', 'Drop', 'sounds/notifications/marie_2.mp3'),
    MeyaSound('marie_3', 'Ping', 'sounds/notifications/marie_3.mp3'),
    MeyaSound('marie_4', 'Twinkle', 'sounds/notifications/marie_4.mp3'),
    MeyaSound('dream', 'Dream', 'sounds/notifications/dream.mp3'),
  ];

  MeyaSound _ringtone = ringtones.first;
  MeyaSound _notification = notificationSounds.first;
  AudioPlayer? _player;
  String? _playingId;

  MeyaSound get ringtone => _ringtone;
  MeyaSound get notification => _notification;

  /// The sound being played, if any.
  String? get playingId => _playingId;

  static MeyaSound _find(List<MeyaSound> sounds, String? id) =>
      sounds.firstWhere((sound) => sound.id == id, orElse: () => sounds.first);

  Future<void> load() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      _ringtone = _find(ringtones, preferences.getString(_ringtoneKey));
      _notification =
          _find(notificationSounds, preferences.getString(_notificationKey));
    } catch (error) {
      debugPrint('MEYA sound settings: using defaults ($error).');
    }
    notifyListeners();
  }

  Future<void> setRingtone(MeyaSound sound) async {
    _ringtone = sound;
    notifyListeners();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_ringtoneKey, sound.id);
  }

  Future<void> setNotification(MeyaSound sound) async {
    _notification = sound;
    notifyListeners();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_notificationKey, sound.id);
  }

  /// Plays [sound], replacing whatever was playing. With [loop] it repeats
  /// until [stop] is called.
  Future<void> play(MeyaSound sound, {bool loop = false}) async {
    try {
      final player = _player ??= _createPlayer();
      await player.stop();
      await player.setReleaseMode(loop ? ReleaseMode.loop : ReleaseMode.stop);
      _playingId = sound.id;
      notifyListeners();
      await player.play(AssetSource(sound.asset));
    } catch (error) {
      debugPrint('MEYA sound: could not play ${sound.id} ($error).');
      _playingId = null;
      notifyListeners();
    }
  }

  /// Plays the chosen notification sound, e.g. when a message arrives.
  /// Stays quiet while a call is ringing.
  Future<void> playNotification() async {
    if (_ringing) return;
    await play(_notification);
  }

  bool _ringing = false;

  /// Rings with the chosen ringtone until [stopRinging].
  Future<void> startRinging() async {
    _ringing = true;
    await play(_ringtone, loop: true);
  }

  Future<void> stopRinging() async {
    if (!_ringing) return;
    _ringing = false;
    await stop();
  }

  Future<void> stop() async {
    _playingId = null;
    notifyListeners();
    try {
      await _player?.stop();
    } on MissingPluginException {
      // No audio plugin (tests).
    }
  }

  AudioPlayer _createPlayer() {
    final player = AudioPlayer();
    player.onPlayerComplete.listen((_) {
      _playingId = null;
      notifyListeners();
    });
    return player;
  }
}
