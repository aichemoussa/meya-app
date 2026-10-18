import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import '../database/contact_repository.dart';
import '../database/meya_database.dart';
import '../services/meya_blob_store.dart';
import '../services/meya_message_service.dart';
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
    final stories = mine
        ? [StatusStory(status: status, name: tr('My status'), mine: true)]
        : [
            for (final other in _others)
              StatusStory(
                status: other,
                name: other.contactName ?? tr('MEYA contact'),
                mine: false,
              ),
          ];
    final start = mine ? 0 : _others.indexOf(status);
    Navigator.push(
      context,
      PageRouteBuilder<void>(
        opaque: false,
        transitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (_, _, _) => StatusViewerPage(
          stories: stories,
          initialIndex: start < 0 ? 0 : start,
        ),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
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

/// One entry in the full-screen status viewer.
class StatusStory {
  final MeyaStatus status;
  final String name;
  final bool mine;

  const StatusStory({required this.status, required this.name, required this.mine});
}

/// Shows statuses full screen, one after another, like stories: tap the
/// right side for the next one, the left side for the previous one, hold to
/// pause, swipe down to close.
class StatusViewerPage extends StatefulWidget {
  final List<StatusStory> stories;
  final int initialIndex;

  const StatusViewerPage({super.key, required this.stories, this.initialIndex = 0});

  @override
  State<StatusViewerPage> createState() => _StatusViewerPageState();
}

class _StatusViewerPageState extends State<StatusViewerPage>
    with SingleTickerProviderStateMixin {
  static const Duration _photoDuration = Duration(seconds: 6);

  late final AnimationController _progress;
  late int _index;
  VideoPlayerController? _video;
  File? _videoFile;
  bool _videoFailed = false;
  bool _paused = false;
  double _dragOffset = 0;

  StatusStory get _story => widget.stories[_index];

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, widget.stories.length - 1);
    _progress = AnimationController(vsync: this)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) _next();
      });
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _show();
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _progress.dispose();
    _disposeVideo();
    super.dispose();
  }

  void _disposeVideo() {
    _video?.dispose();
    _video = null;
    final file = _videoFile;
    _videoFile = null;
    if (file != null) file.delete().catchError((_) => file);
  }

  Future<void> _show() async {
    _progress.stop();
    _progress.value = 0;
    _disposeVideo();
    _videoFailed = false;
    final status = _story.status;
    final media = status.media;
    if (media == null || !status.isVideo) {
      _progress.duration = _photoDuration;
      if (!_paused) _progress.forward();
      setState(() {});
      return;
    }

    setState(() {});
    final index = _index;
    try {
      final service = MeyaMessageService.instance;
      if (!await service.hasAttachment(media)) {
        throw StateError('not arrived');
      }
      final bytes = await service.openAttachment(media);
      final file = await MeyaTempFiles.write('${media.blobId}_${media.name}', bytes);
      final controller = VideoPlayerController.file(file);
      await controller.initialize();
      if (!mounted || index != _index) {
        await controller.dispose();
        await file.delete();
        return;
      }
      _video = controller;
      _videoFile = file;
      final length = controller.value.duration;
      _progress.duration = length > Duration.zero ? length : _photoDuration;
      if (!_paused) {
        await controller.play();
        _progress.forward();
      }
      setState(() {});
    } catch (_) {
      if (!mounted || index != _index) return;
      _videoFailed = true;
      _progress.duration = _photoDuration;
      if (!_paused) _progress.forward();
      setState(() {});
    }
  }

  void _next() {
    if (_index < widget.stories.length - 1) {
      _index++;
      _show();
    } else {
      Navigator.maybePop(context);
    }
  }

  void _previous() {
    if (_index > 0) {
      _index--;
    }
    _show();
  }

  void _pause() {
    _paused = true;
    _progress.stop();
    _video?.pause();
    setState(() {});
  }

  void _resume() {
    _paused = false;
    _progress.forward();
    _video?.play();
    setState(() {});
  }

  Widget _media(BuildContext context) {
    final status = _story.status;
    final media = status.media;
    final text = [status.emoji, status.text].where((s) => s.isNotEmpty).join(' ');

    if (media == null) {
      // Text status: big centred text on a colour picked from the status ID,
      // so each one keeps its own colour.
      const palettes = [
        [Color(0xFF0F2A4A), Color(0xFF2E5C8A)],
        [Color(0xFF5B2A86), Color(0xFFB0458C)],
        [Color(0xFF0E6B5C), Color(0xFF2FA58C)],
        [Color(0xFF8A3B12), Color(0xFFD9822B)],
        [Color(0xFF263238), Color(0xFF546E7A)],
      ];
      final colors = palettes[status.statusId.hashCode.abs() % palettes.length];
      return DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: text.characters.length < 40 ? 36 : 26,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ),
        ),
      );
    }

    if (!status.isVideo) {
      return SizedBox.expand(
        child: EncryptedImage(attachment: media, fit: BoxFit.contain),
      );
    }

    final video = _video;
    if (video != null) {
      return Center(
        child: AspectRatio(
          aspectRatio: video.value.aspectRatio,
          child: VideoPlayer(video),
        ),
      );
    }
    return Center(
      child: _videoFailed
          ? Text(
              context.tr('This video has not fully arrived yet.'),
              style: const TextStyle(color: Colors.white),
            )
          : const CircularProgressIndicator(color: Colors.white),
    );
  }

  @override
  Widget build(BuildContext context) {
    final story = _story;
    final status = story.status;
    final caption = status.media == null
        ? ''
        : [status.emoji, status.text].where((s) => s.isNotEmpty).join(' ');
    final expires = status.expiresAt;
    final width = MediaQuery.sizeOf(context).width;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: (details) {
          if (details.globalPosition.dx < width / 3) {
            _previous();
          } else {
            _next();
          }
        },
        onLongPressStart: (_) => _pause(),
        onLongPressEnd: (_) => _resume(),
        onVerticalDragUpdate: (details) {
          setState(() => _dragOffset = (_dragOffset + details.delta.dy).clamp(0, 400));
        },
        onVerticalDragEnd: (details) {
          if (_dragOffset > 120 || (details.primaryVelocity ?? 0) > 700) {
            Navigator.maybePop(context);
          } else {
            setState(() => _dragOffset = 0);
          }
        },
        child: Transform.translate(
          offset: Offset(0, _dragOffset),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Semantics(
                label: status.media == null
                    ? null
                    : status.isVideo
                        ? context.tr('Video')
                        : context.tr('Photo'),
                child: _media(context),
              ),
              // Shade so the header and caption stay readable.
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 140,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x99000000), Color(0x00000000)],
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                  child: Column(
                    children: [
                      AnimatedBuilder(
                        animation: _progress,
                        builder: (context, _) => Row(
                          children: [
                            for (var i = 0; i < widget.stories.length; i++)
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 2),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(2),
                                    child: LinearProgressIndicator(
                                      minHeight: 3,
                                      value: i < _index
                                          ? 1
                                          : i == _index
                                              ? _progress.value
                                              : 0,
                                      backgroundColor: Colors.white24,
                                      valueColor: const AlwaysStoppedAnimation(Colors.white),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const SizedBox(width: 4),
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: Colors.white24,
                            foregroundColor: Colors.white,
                            child: Text(
                              story.name.trim().isEmpty
                                  ? '?'
                                  : story.name.trim().characters.first.toUpperCase(),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  story.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                                Text(
                                  expires == null || !story.mine
                                      ? _ago(status.postedAt)
                                      : context.tr('Posted {0} · disappears {1}', [_ago(status.postedAt), _when(context, expires)]),
                                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          if (_paused)
                            const Padding(
                              padding: EdgeInsets.only(right: 4),
                              child: Icon(Icons.pause, color: Colors.white),
                            ),
                          IconButton(
                            tooltip: context.tr('Close'),
                            color: Colors.white,
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.maybePop(context),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (caption.isNotEmpty)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [Color(0xB3000000), Color(0x00000000)],
                      ),
                    ),
                    child: SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
                        child: Text(
                          caption,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white, fontSize: 17, height: 1.4),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
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
