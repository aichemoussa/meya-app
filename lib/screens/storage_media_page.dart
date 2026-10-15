import 'package:flutter/material.dart';

import '../services/meya_account_reset.dart';
import '../services/meya_blob_store.dart';
import '../services/meya_media_settings.dart';
import '../services/meya_message_service.dart';
import '../theme/meya_theme.dart';
import 'media_widgets.dart';
import '../l10n/meya_strings.dart';

/// Storage use and media options.
class StorageMediaPage extends StatefulWidget {
  const StorageMediaPage({super.key});

  @override
  State<StorageMediaPage> createState() => _StorageMediaPageState();
}

class _StorageMediaPageState extends State<StorageMediaPage> {
  final _settings = MeyaMediaSettings.instance;
  int? _total;
  int? _media;
  int? _openCopies;
  bool _working = false;

  @override
  void initState() {
    super.initState();
    _measure();
  }

  Future<void> _measure() async {
    final results = await Future.wait([
      MeyaAccountReset.appDataBytes(),
      MeyaBlobStore.instance.totalBytes(),
      MeyaTempFiles.totalBytes(),
    ]);
    if (!mounted) return;
    setState(() {
      _total = results[0];
      _media = results[1];
      _openCopies = results[2];
    });
  }

  String _size(int? bytes) => bytes == null ? context.tr('Measuring…') : formatBytes(bytes);

  static String _keepLabel(KeepMedia value) => switch (value) {
        KeepMedia.forever => tr('Forever'),
        KeepMedia.oneYear => tr('1 year'),
        KeepMedia.threeMonths => tr('3 months'),
        KeepMedia.oneMonth => tr('1 month'),
      };

  Future<void> _chooseKeep() async {
    final selected = await showModalBottomSheet<KeepMedia>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: RadioGroup<KeepMedia>(
          groupValue: _settings.keepMedia,
          onChanged: (value) => Navigator.pop(sheetContext, value),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final value in KeepMedia.values)
                RadioListTile<KeepMedia>(
                  value: value,
                  title: Text(_keepLabel(value)),
                ),
            ],
          ),
        ),
      ),
    );
    if (selected == null || selected == _settings.keepMedia) return;
    if (selected != KeepMedia.forever) {
      final confirmed = await _confirm(
        context.tr('Keep media for {0}?', [_keepLabel(selected).toLowerCase()]),
        context.tr('Photos, videos and files older than this are deleted from this phone now and from now on. Messages stay; their media will show as no longer on this phone.'),
        context.tr('Delete older media'),
      );
      if (!confirmed) return;
    }
    setState(() => _working = true);
    await _settings.setKeepMedia(selected);
    MeyaMessageService.instance.clearMemoryCache();
    if (!mounted) return;
    setState(() => _working = false);
    await _measure();
  }

  Future<bool> _confirm(String title, String body, String action) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.tr('Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(action),
          ),
        ],
      ),
    );
    return result == true;
  }

  Future<void> _clearOpenCopies() async {
    setState(() => _working = true);
    await MeyaTempFiles.clear();
    MeyaMessageService.instance.clearMemoryCache();
    if (!mounted) return;
    setState(() => _working = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.tr('Temporary copies cleared.'))),
    );
    await _measure();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.meya;

    return ListenableBuilder(
      listenable: _settings,
      builder: (context, _) => Scaffold(
        appBar: AppBar(title: Text(context.tr('Storage & Media'))),
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: _measure,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              children: [
                _Heading(context.tr('Storage')),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.storage_outlined),
                        title: Text(context.tr('MEYA on this phone')),
                        trailing: Text(_size(_total)),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.perm_media_outlined),
                        title: Text(context.tr('Photos, videos and files')),
                        subtitle: Text(context.tr('Stored encrypted')),
                        trailing: Text(_size(_media)),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.cleaning_services_outlined),
                        title: Text(context.tr('Temporary copies')),
                        subtitle: Text(
                          context.tr('Made when you play a video or open a file in another app'),
                        ),
                        trailing: Text(_size(_openCopies)),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: OutlinedButton(
                            onPressed: _working ? null : _clearOpenCopies,
                            child: Text(context.tr('Clear temporary copies')),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _Heading(context.tr('Sending')),
                Card(
                  child: RadioGroup<PhotoQuality>(
                    groupValue: _settings.photoQuality,
                    onChanged: (value) {
                      if (value != null) _settings.setPhotoQuality(value);
                    },
                    child: Column(
                      children: [
                        RadioListTile<PhotoQuality>(
                          value: PhotoQuality.standard,
                          title: Text(context.tr('Standard photo quality')),
                          subtitle: Text(context.tr('Faster to send, uses less space')),
                        ),
                        Divider(height: 1),
                        RadioListTile<PhotoQuality>(
                          value: PhotoQuality.high,
                          title: Text(context.tr('HD photo quality')),
                          subtitle: Text(context.tr('Sharper photos, larger files')),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  context.tr('Photos, videos and files can be up to {0} MB. Videos can be up to 3 minutes.', [MeyaMessageService.maxAttachmentBytes ~/ (1024 * 1024)]),
                  style: TextStyle(color: colors.muted, height: 1.4),
                ),
                const SizedBox(height: 24),
                _Heading(context.tr('Keeping media')),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.auto_delete_outlined),
                    title: Text(context.tr('Keep media on this phone')),
                    subtitle: Text(_keepLabel(_settings.keepMedia)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _working ? null : _chooseKeep,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  context.tr('Media arrives with each message and is stored encrypted. MEYA never saves your photos to the phone\'s gallery unless you choose Save.'),
                  style: TextStyle(color: colors.muted, height: 1.4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  final String text;

  const _Heading(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Semantics(
        header: true,
        child: Text(
          text,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
