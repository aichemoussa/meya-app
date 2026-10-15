import 'package:flutter/material.dart';

import '../l10n/meya_strings.dart';
import '../services/meya_sound_settings.dart';
import '../theme/meya_theme.dart';

/// Call ringtone and notification sound. Choosing a sound only saves it;
/// the play button previews it.
class SoundsPage extends StatefulWidget {
  const SoundsPage({super.key});

  @override
  State<SoundsPage> createState() => _SoundsPageState();
}

class _SoundsPageState extends State<SoundsPage> {
  final _settings = MeyaSoundSettings.instance;

  @override
  void dispose() {
    _settings.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.meya;

    return ListenableBuilder(
      listenable: _settings,
      builder: (context, _) => Scaffold(
        appBar: AppBar(title: Text(context.tr('Sounds'))),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            children: [
              _SoundPicker(
                key: const Key('call-ringtone'),
                icon: Icons.ring_volume_outlined,
                label: context.tr('Call ringtone'),
                help: context.tr('Plays when someone calls you.'),
                sounds: MeyaSoundSettings.ringtones,
                selected: _settings.ringtone,
                playingId: _settings.playingId,
                onChanged: _choose(_settings.setRingtone),
                onPreview: _togglePreview,
              ),
              const SizedBox(height: 24),
              _SoundPicker(
                key: const Key('notification-sound'),
                icon: Icons.notifications_active_outlined,
                label: context.tr('Notification sound'),
                help: context.tr('Plays when a new message arrives.'),
                sounds: MeyaSoundSettings.notificationSounds,
                selected: _settings.notification,
                playingId: _settings.playingId,
                onChanged: _choose(_settings.setNotification),
                onPreview: _togglePreview,
              ),
              const SizedBox(height: 24),
              Text(
                context.tr('Sounds by BigSoundBank, free to use (CC0 public domain).'),
                style: TextStyle(color: colors.muted, height: 1.4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Saves the choice quietly, stopping any preview of the old sound.
  ValueChanged<MeyaSound> _choose(Future<void> Function(MeyaSound) save) =>
      (sound) {
        _settings.stop();
        save(sound);
      };

  void _togglePreview(MeyaSound sound) {
    if (_settings.playingId == sound.id) {
      _settings.stop();
    } else {
      _settings.play(sound);
    }
  }
}

class _SoundPicker extends StatelessWidget {
  final IconData icon;
  final String label;
  final String help;
  final List<MeyaSound> sounds;
  final MeyaSound selected;
  final String? playingId;
  final ValueChanged<MeyaSound> onChanged;
  final ValueChanged<MeyaSound> onPreview;

  const _SoundPicker({
    super.key,
    required this.icon,
    required this.label,
    required this.help,
    required this.sounds,
    required this.selected,
    required this.playingId,
    required this.onChanged,
    required this.onPreview,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.meya;
    final playing = playingId == selected.id;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: DropdownMenu<MeyaSound>(
                initialSelection: selected,
                expandedInsets: EdgeInsets.zero,
                leadingIcon: Icon(icon),
                label: Text(label),
                requestFocusOnTap: false,
                menuHeight: 360,
                onSelected: (sound) {
                  if (sound != null) onChanged(sound);
                },
                dropdownMenuEntries: [
                  for (final sound in sounds)
                    DropdownMenuEntry<MeyaSound>(value: sound, label: sound.name),
                ],
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              tooltip: playing ? context.tr('Stop') : context.tr('Play'),
              icon: Icon(playing ? Icons.stop : Icons.play_arrow),
              onPressed: () => onPreview(selected),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(help, style: TextStyle(color: colors.muted, height: 1.4)),
      ],
    );
  }
}
