import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../database/contact_repository.dart';
import '../database/meya_database.dart';
import '../services/meya_status_service.dart';
import '../theme/meya_theme.dart';
import 'media_widgets.dart';
import '../l10n/meya_strings.dart';

String _when(BuildContext context, DateTime time) {
  final localizations = MaterialLocalizations.of(context);
  return '${localizations.formatShortMonthDay(time)} '
      '${localizations.formatTimeOfDay(TimeOfDay.fromDateTime(time))}';
}

String _ago(DateTime time) {
  final difference = DateTime.now().difference(time);
  if (difference.inMinutes < 1) return tr('Just now');
  if (difference.inMinutes < 60) return tr('{0} min ago', [difference.inMinutes]);
  if (difference.inHours < 24) return tr('{0} h ago', [difference.inHours]);
  return tr('{0} d ago', [difference.inDays]);
}

/// Your status and the statuses of your connections.
class StatusHubPage extends StatefulWidget {
  final MeyaDatabase database;

  const StatusHubPage({super.key, required this.database});

  @override
  State<StatusHubPage> createState() => _StatusHubPageState();
}

class _StatusHubPageState extends State<StatusHubPage> {
  final _service = MeyaStatusService.instance;
  StreamSubscription<void>? _subscription;
  MeyaStatus? _own;
  List<MeyaStatus> _others = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _subscription = _service.changes.listen((_) => _load());
    _load();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final own = await _service.loadOwn();
    final others = await _service.contactStatuses();
    if (!mounted) return;
    setState(() {
      _own = own;
      _others = others;
      _loading = false;
    });
  }

  Future<void> _compose() async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => StatusComposerPage(
          database: widget.database,
          current: _own,
        ),
      ),
    );
    await _load();
  }

  void _view(MeyaStatus status, {required bool mine}) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => StatusViewerPage(status: status, mine: mine),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.meya;
    final own = _own;

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('Status'))),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _compose,
        icon: const Icon(Icons.edit_outlined),
        label: Text(own == null ? context.tr('New status') : context.tr('Update status')),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      context.tr('My status'),
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: own == null
                        ? ListTile(
                            leading: const CircleAvatar(child: Icon(Icons.add)),
                            title: Text(context.tr('Add a status')),
                            subtitle: Text(
                              context.tr('Text, a photo or a video for your connections'),
                            ),
                            onTap: _compose,
                          )
                        : _StatusTile(
                            status: own,
                            title: context.tr('You'),
                            onTap: () => _view(own, mine: true),
                          ),
                  ),
                  const SizedBox(height: 24),
                  Semantics(
                    header: true,
                    child: Text(
                      context.tr('From your connections'),
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_others.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        context.tr('No recent statuses.'),
                        style: TextStyle(color: colors.muted),
                      ),
                    )
                  else
                    Card(
                      child: Column(
                        children: [
                          for (final status in _others)
                            _StatusTile(
                              status: status,
                              title: status.contactName ?? context.tr('MEYA contact'),
                              onTap: () => _view(status, mine: false),
                            ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                  Text(
                    context.tr('Statuses are end-to-end encrypted and sent only to the people you choose.'),
                    style: TextStyle(color: colors.muted, height: 1.4),
                  ),
                ],
              ),
      ),
    );
  }
}

class _StatusTile extends StatelessWidget {
  final MeyaStatus status;
  final String title;
  final VoidCallback onTap;

  const _StatusTile({
    required this.status,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.meya;
    final media = status.media;
    final summary = [
      if (status.emoji.isNotEmpty) status.emoji,
      if (status.text.isNotEmpty) status.text,
      if (status.text.isEmpty && media != null)
        status.isVideo ? context.tr('Video') : context.tr('Photo'),
    ].join(' ');

    return ListTile(
      onTap: onTap,
      leading: SizedBox(
        width: 48,
        height: 48,
        child: ClipOval(
          child: media != null && !status.isVideo
              ? EncryptedImage(attachment: media, width: 48, height: 48)
              : Container(
                  color: colors.navy,
                  alignment: Alignment.center,
                  child: Icon(
                    status.isVideo ? Icons.play_arrow : Icons.short_text,
                    color: colors.onNavy,
                  ),
                ),
        ),
      ),
      title: Text(title),
      subtitle: Text(
        '$summary\n${_ago(status.postedAt)}',
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
      isThreeLine: true,
      trailing: const Icon(Icons.chevron_right),
    );
  }
}

/// Shows one status full screen.
class StatusViewerPage extends StatelessWidget {
  final MeyaStatus status;
  final bool mine;

  const StatusViewerPage({super.key, required this.status, required this.mine});

  @override
  Widget build(BuildContext context) {
    final media = status.media;
    final text = [status.emoji, status.text].where((s) => s.isNotEmpty).join(' ');
    final expires = status.expiresAt;

    return Scaffold(
      appBar: AppBar(
        title: Text(mine ? context.tr('My status') : status.contactName ?? context.tr('Status')),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (media != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: status.isVideo
                    ? AspectRatio(
                        aspectRatio: 16 / 9,
                        child: Material(
                          color: context.meya.navy,
                          child: InkWell(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) => VideoPlayerPage(
                                  attachment: media,
                                  caption: text,
                                ),
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.play_circle_fill,
                                size: 64,
                                color: context.meya.onNavy,
                                semanticLabel: context.tr('Play video'),
                              ),
                            ),
                          ),
                        ),
                      )
                    : GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => PhotoViewerPage(
                              attachment: media,
                              caption: text,
                            ),
                          ),
                        ),
                        child: EncryptedImage(
                          attachment: media,
                          fit: BoxFit.cover,
                          height: 320,
                        ),
                      ),
              ),
            if (text.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(text, style: const TextStyle(fontSize: 22, height: 1.35)),
            ],
            const SizedBox(height: 16),
            Text(
              expires == null
                  ? context.tr('Posted {0}', [_ago(status.postedAt)])
                  : context.tr('Posted {0} · disappears {1}', [_ago(status.postedAt), _when(context, expires)]),
              style: TextStyle(color: context.meya.muted),
            ),
          ],
        ),
      ),
    );
  }
}

/// Creates or replaces your status.
class StatusComposerPage extends StatefulWidget {
  final MeyaDatabase database;
  final MeyaStatus? current;

  const StatusComposerPage({super.key, required this.database, this.current});

  @override
  State<StatusComposerPage> createState() => _StatusComposerPageState();
}

class _StatusComposerPageState extends State<StatusComposerPage> {
  static const _emojis = ['🙂', '😊', '🤍', '✨', '🌿', '☕', '💬', '🔒', '🎉', '✈️'];

  final _text = TextEditingController();
  String _emoji = '';
  PickedMedia? _media;
  String _visibility = 'all';
  List<String> _selected = [];
  Duration? _expiry = MeyaStatusService.defaultExpiry;
  bool _posting = false;

  @override
  void initState() {
    super.initState();
    final current = widget.current;
    if (current != null) {
      _text.text = current.text;
      _emoji = current.emoji;
      _visibility = current.visibility;
      _selected = List.of(current.audienceContactIds);
    }
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _pickMedia() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (value, icon, label) in [
              ('gallery_photo', Icons.photo_outlined, context.tr('Photo from gallery')),
              ('camera_photo', Icons.photo_camera_outlined, context.tr('Take a photo')),
              ('gallery_video', Icons.video_library_outlined, context.tr('Video from gallery')),
              ('camera_video', Icons.videocam_outlined, context.tr('Record a video')),
            ])
              ListTile(
                leading: Icon(icon),
                title: Text(label),
                onTap: () => Navigator.pop(sheetContext, value),
              ),
          ],
        ),
      ),
    );
    if (choice == null) return;
    try {
      final media = switch (choice) {
        'gallery_photo' => await MeyaMediaPicker.photo(camera: false),
        'camera_photo' => await MeyaMediaPicker.photo(camera: true),
        'gallery_video' => await MeyaMediaPicker.video(),
        _ => await MeyaMediaPicker.recordVideo(context),
      };
      if (media != null && mounted) setState(() => _media = media);
    } catch (error) {
      _show('$error');
    }
  }

  Future<void> _chooseVisibility() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: RadioGroup<String>(
          groupValue: _visibility,
          onChanged: (value) => Navigator.pop(sheetContext, value),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile(value: 'all', title: Text(context.tr('All my connections'))),
              RadioListTile(value: 'selected', title: Text(context.tr('Selected people'))),
              RadioListTile(value: 'only_me', title: Text(context.tr('Only me'))),
            ],
          ),
        ),
      ),
    );
    if (result == null) return;
    if (result == 'selected') {
      final picked = await _choosePeople();
      if (picked == null) return;
      setState(() {
        _visibility = 'selected';
        _selected = picked;
      });
    } else {
      setState(() => _visibility = result);
    }
  }

  Future<List<String>?> _choosePeople() async {
    final contacts =
        await ContactRepository(widget.database).getTrustedContacts();
    if (!mounted) return null;
    final chosen = Set<String>.of(_selected);
    return showDialog<List<String>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(context.tr('Who can see it?')),
          content: SizedBox(
            width: double.maxFinite,
            child: contacts.isEmpty
                ? Text(context.tr('You have no connections yet.'))
                : ListView(
                    shrinkWrap: true,
                    children: [
                      for (final contact in contacts)
                        CheckboxListTile(
                          value: chosen.contains(contact.contactId),
                          title: Text(contact.displayName),
                          onChanged: (value) => setDialogState(() {
                            if (value == true) {
                              chosen.add(contact.contactId);
                            } else {
                              chosen.remove(contact.contactId);
                            }
                          }),
                        ),
                    ],
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(context.tr('Cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, chosen.toList()),
              child: Text(context.tr('Done')),
            ),
          ],
        ),
      ),
    );
  }

  String get _visibilityLabel => switch (_visibility) {
        'selected' => context.tr('Selected people ({0})', [_selected.length]),
        'only_me' => context.tr('Only me'),
        _ => context.tr('All my connections'),
      };

  String get _expiryLabel => switch (_expiry?.inHours) {
        null => context.tr('Never'),
        24 => context.tr('24 hours'),
        _ => context.tr('7 days'),
      };

  Future<void> _chooseExpiry() async {
    final result = await showModalBottomSheet<int>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: RadioGroup<int>(
          groupValue: _expiry?.inHours ?? 0,
          onChanged: (value) => Navigator.pop(sheetContext, value),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile(value: 24, title: Text(context.tr('24 hours'))),
              RadioListTile(value: 168, title: Text(context.tr('7 days'))),
              RadioListTile(value: 0, title: Text(context.tr('Never'))),
            ],
          ),
        ),
      ),
    );
    if (result == null) return;
    setState(() => _expiry = result == 0 ? null : Duration(hours: result));
  }

  Future<void> _post() async {
    setState(() => _posting = true);
    try {
      final media = _media;
      final failed = await MeyaStatusService.instance.post(
        text: _text.text,
        emoji: _emoji,
        mediaBytes: media?.bytes,
        mediaMime: media?.mime,
        visibility: _visibility,
        selectedContactIds: _selected,
        expiry: _expiry,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            failed.isEmpty
                ? context.tr('Status posted.')
                : context.tr('Status posted, but not yet sent to {0}.', [failed.join(', ')]),
          ),
        ),
      );
      Navigator.pop(context);
    } catch (error) {
      _show('$error');
      if (mounted) setState(() => _posting = false);
    }
  }

  Future<void> _remove() async {
    setState(() => _posting = true);
    await MeyaStatusService.instance.clearOwn();
    if (!mounted) return;
    Navigator.pop(context);
  }

  void _show(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.meya;
    final media = _media;
    final Uint8List? preview = media?.kind == 'image' ? media!.bytes : null;

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('Your status'))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            TextField(
              controller: _text,
              maxLength: 200,
              maxLines: 4,
              minLines: 2,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: context.tr('What would you like to share?'),
              ),
            ),
            const SizedBox(height: 8),
            Text(context.tr('Emoji'), style: TextStyle(color: colors.muted)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final emoji in _emojis)
                  Semantics(
                    selected: emoji == _emoji,
                    button: true,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () =>
                          setState(() => _emoji = emoji == _emoji ? '' : emoji),
                      child: Container(
                        width: 48,
                        height: 48,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: emoji == _emoji ? colors.blue : colors.card,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(emoji, style: const TextStyle(fontSize: 23)),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            if (media == null)
              OutlinedButton.icon(
                onPressed: _pickMedia,
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: Text(context.tr('Add a photo or video')),
              )
            else
              Card(
                child: Column(
                  children: [
                    if (preview != null)
                      ClipRRect(
                        borderRadius:
                            const BorderRadius.vertical(top: Radius.circular(16)),
                        child: Image.memory(
                          preview,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          semanticLabel: context.tr('Selected photo'),
                        ),
                      ),
                    ListTile(
                      leading: Icon(media.kind == 'video'
                          ? Icons.movie_outlined
                          : Icons.photo_outlined),
                      title: Text(media.kind == 'video' ? context.tr('Video') : context.tr('Photo')),
                      subtitle: Text(formatBytes(media.bytes.length)),
                      trailing: IconButton(
                        tooltip: context.tr('Remove'),
                        icon: const Icon(Icons.close),
                        onPressed: () => setState(() => _media = null),
                      ),
                    ),
                  ],
                ),
              ),
            if (widget.current?.media != null && media == null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  context.tr('Posting replaces your current status, including its photo or video.'),
                  style: TextStyle(color: colors.muted),
                ),
              ),
            const SizedBox(height: 16),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.visibility_outlined),
                    title: Text(context.tr('Who can see it')),
                    subtitle: Text(_visibilityLabel),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _chooseVisibility,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.timer_outlined),
                    title: Text(context.tr('Disappears after')),
                    subtitle: Text(_expiryLabel),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _chooseExpiry,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 56,
              child: FilledButton(
                onPressed: _posting ? null : _post,
                child: _posting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      )
                    : Text(context.tr('Post status')),
              ),
            ),
            if (widget.current != null) ...[
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _posting ? null : _remove,
                child: Text(context.tr('Remove my status')),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
