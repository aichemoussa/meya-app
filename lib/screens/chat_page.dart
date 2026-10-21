import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../database/contact_repository.dart';
import '../database/meya_database.dart';
import '../database/message_repository.dart';
import '../services/meya_message_service.dart';
import '../services/safety_number.dart';
import 'calendar_page.dart';
import 'call_page.dart';
import 'contact_avatar.dart';
import 'media_widgets.dart';
import 'qr_scanner_page.dart';
import 'report_page.dart';
import '../l10n/meya_strings.dart';

/// End-to-end encrypted conversation with one contact.
class ChatPage extends StatefulWidget {
  final MeyaDatabase database;
  final Contact contact;

  const ChatPage({super.key, required this.database, required this.contact});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  static const Duration _minVoiceDuration = Duration(milliseconds: 700);

  final _service = MeyaMessageService.instance;
  final _composer = TextEditingController();
  final _scroll = ScrollController();
  final _recorder = AudioRecorder();
  final _player = AudioPlayer();

  StreamSubscription<String>? _subscription;
  StreamSubscription<void>? _playerDone;
  List<ChatMessageView> _messages = [];
  bool _loading = true;
  bool _canMessage = false;
  bool _sending = false;
  bool _hasText = false;

  // Voice recording state.
  bool _recording = false;
  String? _recordingPath;
  DateTime? _recordingStarted;
  Duration _recorded = Duration.zero;
  Timer? _recordTimer;

  // Which voice message is playing, if any.
  String? _playingId;

  // Reply, edit and search state.
  ChatMessageView? _replyingTo;
  ChatMessageView? _editing;
  bool _searching = false;
  final _searchField = TextEditingController();
  List<ChatMessageView> _searchResults = [];
  String? _highlightId;
  int _pinIndex = 0;
  bool _muted = false;
  bool _archived = false;
  bool _verified = false;
  final Map<String, GlobalKey> _keys = {};

  String get _name => widget.contact.displayName.trim().isEmpty
      ? tr('MEYA contact')
      : widget.contact.displayName.trim();

  String get _conversationId =>
      MessageRepository.conversationIdFor(widget.contact.contactId);

  @override
  void initState() {
    super.initState();
    _service.activeConversationId = _conversationId;
    _subscription = _service.changes.listen((conversationId) {
      if (conversationId == _conversationId) _reload();
    });
    _composer.addListener(() {
      final hasText = _composer.text.trim().isNotEmpty;
      if (hasText != _hasText) setState(() => _hasText = hasText);
    });
    _playerDone = _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _playingId = null);
    });
    _reload();
  }

  @override
  void dispose() {
    if (_service.activeConversationId == _conversationId) {
      _service.activeConversationId = null;
    }
    _searchField.dispose();
    _subscription?.cancel();
    _playerDone?.cancel();
    _recordTimer?.cancel();
    if (_recording) {
      _recorder.cancel().catchError((_) {});
    }
    _deleteRecordingFile();
    _recorder.dispose();
    _player.dispose();
    _composer.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    final firstLoad = _loading;
    final canMessage = await _service.canMessage(widget.contact);
    final messages = await _service.history(widget.contact);
    final state = (await _service.conversationStates())[_conversationId];
    final verified = await SafetyNumber.isVerified(widget.contact);
    if (!mounted) return;
    final atBottom = !_scroll.hasClients ||
        _scroll.position.pixels >= _scroll.position.maxScrollExtent - 80;
    final grew = messages.length > _messages.length;
    setState(() {
      _canMessage = canMessage;
      _messages = messages;
      _muted = state?.isMuted ?? false;
      _archived = state?.isArchived ?? false;
      _verified = verified;
      _loading = false;
      if (_searching) _searchResults = _filter(_searchField.text);
    });
    if (firstLoad) unawaited(_service.markConversationRead(widget.contact));
    if (firstLoad || (grew && atBottom)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) {
          _scroll.jumpTo(_scroll.position.maxScrollExtent);
        }
      });
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _send() async {
    final text = _composer.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() => _sending = true);
    try {
      final editing = _editing;
      if (editing != null) {
        await _service.editMessage(widget.contact, editing.id, text);
      } else {
        await _service.sendText(widget.contact, text, extra: await _replyExtra());
      }
      _composer.clear();
      if (mounted) {
        setState(() {
          _replyingTo = null;
          _editing = null;
        });
      }
    } catch (error) {
      _showError(context.tr('Message not sent: {0}', [error]));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  // ---------------------------------------------------------- attachments

  Future<void> _showAttachMenu() async {
    if (!_canMessage || _recording) return;
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
              ('file', Icons.attach_file, context.tr('File or document')),
              ('call', Icons.event_outlined, context.tr('Schedule a call')),
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
    if (choice == null || !mounted) return;

    if (choice == 'call') {
      await Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => ScheduleCallPage(
            database: widget.database,
            contact: widget.contact,
          ),
        ),
      );
      return;
    }

    PickedMedia? media;
    try {
      media = switch (choice) {
        'gallery_photo' => await MeyaMediaPicker.photo(camera: false),
        'camera_photo' => await MeyaMediaPicker.photo(camera: true),
        'gallery_video' => await MeyaMediaPicker.video(),
        'camera_video' => await MeyaMediaPicker.recordVideo(context),
        _ => await MeyaMediaPicker.file(),
      };
    } catch (error) {
      _showError('$error');
      return;
    }
    if (media == null || !mounted) return;

    final caption = await _confirmAttachment(media);
    if (caption == null || !mounted) return;

    try {
      // The message appears straight away as "Sending…"; large files can
      // take a moment to go through the relay.
      await _service.sendAttachment(
        widget.contact,
        kind: media.kind,
        bytes: media.bytes,
        mime: media.mime,
        name: media.name,
        caption: caption,
        thumbnail: media.thumbnail,
        extra: await _replyExtra(),
      );
      if (mounted) setState(() => _replyingTo = null);
    } catch (error) {
      _showError(context.tr('Not sent: {0}', [error]));
    }
  }

  /// Shows what is about to be sent. Returns the caption, or null to cancel.
  Future<String?> _confirmAttachment(PickedMedia media) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(switch (media.kind) {
          'image' => context.tr('Send photo'),
          'video' => context.tr('Send video'),
          _ => context.tr('Send file'),
        }),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (media.kind == 'image')
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(
                  media.bytes,
                  height: 180,
                  fit: BoxFit.cover,
                  semanticLabel: context.tr('Photo to send'),
                ),
              )
            else if (media.kind == 'video' && media.thumbnail != null)
              VideoThumbnail(
                bytes: media.thumbnail!,
                height: 180,
                label: context.tr('Video to send'),
              )
            else
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  media.kind == 'video'
                      ? Icons.movie_outlined
                      : Icons.insert_drive_file_outlined,
                ),
                title: Text(media.name, overflow: TextOverflow.ellipsis),
                subtitle: Text(formatBytes(media.bytes.length)),
              ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLength: 500,
              decoration: InputDecoration(hintText: context.tr('Add a caption')),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(context.tr('Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: Text(context.tr('Send')),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  void _openAttachment(ChatMessageView message) {
    final attachment = message.attachment;
    if (attachment == null) return;
    switch (message.kind) {
      case 'image':
        Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => PhotoViewerPage(
              attachment: attachment,
              caption: message.text,
            ),
          ),
        );
      case 'video':
        _player.stop();
        Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => VideoPlayerPage(
              attachment: attachment,
              caption: message.text,
            ),
          ),
        );
      default:
        openAttachmentExternally(context, attachment);
    }
  }

  // ---------------------------------------------------------------- voice

  Future<void> _startRecording() async {
    if (_recording || _sending || !_canMessage) return;

    try {
      if (!await _recorder.hasPermission()) {
        _showError(
          context.tr('MEYA needs microphone access to record a voice message. You can allow it in your phone settings.'),
        );
        return;
      }

      await _player.stop();
      final directory = await getTemporaryDirectory();
      final path = p.join(
        directory.path,
        'meya_voice_${DateTime.now().microsecondsSinceEpoch}.m4a',
      );

      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 24000,
          sampleRate: 16000,
          numChannels: 1,
        ),
        path: path,
      );

      _recordTimer?.cancel();
      _recordTimer = Timer.periodic(const Duration(milliseconds: 250), (_) {
        final started = _recordingStarted;
        if (started == null || !mounted) return;
        final elapsed = DateTime.now().difference(started);
        setState(() => _recorded = elapsed);
        if (elapsed >= MeyaMessageService.maxVoiceDuration) {
          _finishRecording(send: true);
        }
      });

      setState(() {
        _recording = true;
        _recordingPath = path;
        _recordingStarted = DateTime.now();
        _recorded = Duration.zero;
        _playingId = null;
      });
    } catch (error) {
      _showError(context.tr('Could not start recording: {0}', [error]));
    }
  }

  Future<void> _finishRecording({required bool send}) async {
    if (!_recording) return;
    _recordTimer?.cancel();
    _recordTimer = null;

    final started = _recordingStarted;
    final duration = started == null
        ? Duration.zero
        : DateTime.now().difference(started);

    setState(() {
      _recording = false;
      _recordingStarted = null;
      if (send) _sending = true;
    });

    try {
      if (!send) {
        await _recorder.cancel();
        return;
      }

      final path = await _recorder.stop() ?? _recordingPath;
      if (duration < _minVoiceDuration || path == null) {
        _showError(context.tr('Voice message too short. Tap the microphone, speak, then tap Send.'));
        return;
      }

      final audio = await File(path).readAsBytes();
      final clamped = duration > MeyaMessageService.maxVoiceDuration
          ? MeyaMessageService.maxVoiceDuration
          : duration;
      await _service.sendVoice(
        widget.contact,
        audio,
        durationMs: clamped.inMilliseconds,
        extra: await _replyExtra(),
      );
      if (mounted) setState(() => _replyingTo = null);
    } catch (error) {
      _showError(context.tr('Voice message not sent: {0}', [error]));
    } finally {
      _deleteRecordingFile();
      if (mounted) {
        setState(() {
          _sending = false;
          _recorded = Duration.zero;
        });
      }
    }
  }

  /// The recording is only kept on disk while it is being made; the copy in
  /// the conversation is stored encrypted like every other message.
  void _deleteRecordingFile() {
    final path = _recordingPath;
    _recordingPath = null;
    if (path == null) return;
    try {
      final file = File(path);
      if (file.existsSync()) file.deleteSync();
    } catch (_) {
      // Temporary folder; the system cleans it up if this fails.
    }
  }

  Future<void> _togglePlay(ChatMessageView message) async {
    final audio = message.audio;
    if (audio == null || _recording) return;

    try {
      if (_playingId == message.id) {
        await _player.stop();
        if (mounted) setState(() => _playingId = null);
        return;
      }
      await _player.stop();
      // Played from memory, so no unencrypted copy is written to storage.
      await _player.play(BytesSource(audio));
      if (mounted) setState(() => _playingId = message.id);
    } catch (error) {
      _showError(context.tr('Could not play this voice message: {0}', [error]));
    }
  }

  // -------------------------------------------------------------- actions

  static const quickReactions = ['👍', '❤️', '😂', '😮', '😢', '🙏', '🎉', '👏'];

  Future<Map<String, Object>> _replyExtra() async {
    final quoted = _replyingTo;
    if (quoted == null) return const {};
    return _service.replyTo(widget.contact, quoted);
  }

  void _startReply(ChatMessageView message) {
    if (message.isDeleted || !_canMessage) return;
    setState(() {
      _editing = null;
      _replyingTo = message;
    });
  }

  void _startEdit(ChatMessageView message) {
    setState(() {
      _replyingTo = null;
      _editing = message;
      _composer.text = message.text;
      _composer.selection =
          TextSelection.collapsed(offset: _composer.text.length);
    });
  }

  Future<void> _run(Future<void> Function() action, String failure) async {
    try {
      await action();
    } catch (error) {
      _showError(context.tr(failure, [error]));
    }
  }

  Future<void> _react(ChatMessageView message, String emoji) => _run(
        () => _service.react(
          widget.contact,
          message.id,
          message.myReaction == emoji ? '' : emoji,
        ),
        'Reaction not sent: {0}',
      );

  /// Long-press menu for a message.
  Future<void> _showActions(ChatMessageView message) async {
    if (message.isDeleted) {
      final remove = await showModalBottomSheet<bool>(
        context: context,
        builder: (sheetContext) => SafeArea(
          child: ListTile(
            leading: const Icon(Icons.delete_outline),
            title: Text(context.tr('Delete for me')),
            onTap: () => Navigator.pop(sheetContext, true),
          ),
        ),
      );
      if (remove == true) {
        await _run(() => _service.deleteForMe(message.id), 'Not deleted: {0}');
      }
      return;
    }

    final canEdit = message.isMine &&
        (message.kind == 'text' ||
            message.kind == 'image' ||
            message.kind == 'video' ||
            message.kind == 'file');
    final canForward = !message.kind.startsWith('call_');
    final unsent = message.isMine &&
        (message.state == 'failed' || message.state == 'queued');

    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_canMessage)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    children: [
                      for (final emoji in quickReactions)
                        Semantics(
                          button: true,
                          selected: message.myReaction == emoji,
                          label: context.tr('React with {0}', [emoji]),
                          excludeSemantics: true,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(24),
                            onTap: () => Navigator.pop(sheetContext, 'react:$emoji'),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: message.myReaction == emoji
                                  ? BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primaryContainer,
                                      shape: BoxShape.circle,
                                    )
                                  : null,
                              child: Text(emoji, style: const TextStyle(fontSize: 28)),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              for (final (value, icon, label, show) in [
                ('retry', Icons.refresh, context.tr('Send again'), unsent),
                ('reply', Icons.reply, context.tr('Reply'), _canMessage),
                ('copy', Icons.copy, context.tr('Copy text'), message.text.isNotEmpty && message.kind != 'voice'),
                ('forward', Icons.forward, context.tr('Forward'), canForward),
                ('pin', message.pinned ? Icons.push_pin : Icons.push_pin_outlined,
                    message.pinned ? context.tr('Unpin') : context.tr('Pin'), _canMessage),
                ('star', message.starred ? Icons.star : Icons.star_border,
                    message.starred ? context.tr('Remove from favourites') : context.tr('Add to favourites'), true),
                ('edit', Icons.edit_outlined, context.tr('Edit'), canEdit && _canMessage),
                ('delete', Icons.delete_outline, context.tr('Delete'), true),
              ])
                if (show)
                  ListTile(
                    leading: Icon(icon),
                    title: Text(label),
                    onTap: () => Navigator.pop(sheetContext, value),
                  ),
            ],
          ),
        ),
      ),
    );
    if (choice == null || !mounted) return;

    if (choice.startsWith('react:')) {
      await _react(message, choice.substring(6));
      return;
    }
    switch (choice) {
      case 'retry':
        await _run(
          () => _service.retryMessage(widget.contact, message.id),
          'Still not sent: {0}',
        );
      case 'reply':
        _startReply(message);
      case 'copy':
        await Clipboard.setData(ClipboardData(text: message.text));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.tr('Copied.'))),
          );
        }
      case 'forward':
        await _forward(message);
      case 'pin':
        await _run(
          () => _service.setPinned(widget.contact, message.id, !message.pinned),
          'Not pinned: {0}',
        );
      case 'star':
        await _run(
          () => _service.setStarred(message.id, !message.starred),
          'Not saved: {0}',
        );
      case 'edit':
        _startEdit(message);
      case 'delete':
        await _delete(message);
    }
  }

  Future<void> _delete(ChatMessageView message) async {
    final choice = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.tr('Delete message?')),
        content: Text(
          message.isMine
              ? context.tr('Delete for everyone removes it from {0}\'s phone too.', [_name])
              : context.tr('This removes the message from this phone only.'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(context.tr('Cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, 'me'),
            child: Text(context.tr('Delete for me')),
          ),
          if (message.isMine && _canMessage)
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, 'everyone'),
              child: Text(context.tr('Delete for everyone')),
            ),
        ],
      ),
    );
    if (choice == 'me') {
      await _run(() => _service.deleteForMe(message.id), 'Not deleted: {0}');
    } else if (choice == 'everyone') {
      await _run(
        () => _service.deleteForEveryone(widget.contact, message.id),
        'Not deleted: {0}',
      );
    }
  }

  Future<void> _forward(ChatMessageView message) async {
    final contacts = await ContactRepository(widget.database).getTrustedContacts();
    if (!mounted) return;
    final target = await showModalBottomSheet<Contact>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.7,
          ),
          child: ListView(
            shrinkWrap: true,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  context.tr('Forward to'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              for (final contact in contacts)
                ListTile(
                  leading: ContactAvatar(
                    contactId: contact.contactId,
                    name: contact.displayName,
                    radius: 20,
                  ),
                  title: Text(contact.displayName),
                  onTap: () => Navigator.pop(sheetContext, contact),
                ),
            ],
          ),
        ),
      ),
    );
    if (target == null || !mounted) return;
    await _run(() async {
      await _service.forward(message, target);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('Forwarded to {0}.', [target.displayName]))),
        );
      }
    }, 'Not forwarded: {0}');
  }

  /// Scrolls to a message and highlights it briefly.
  Future<void> _jumpTo(String messageId) async {
    final index = _messages.indexWhere((m) => m.id == messageId);
    if (index < 0) {
      _showError(context.tr('That message is no longer in this chat.'));
      return;
    }
    setState(() => _highlightId = messageId);
    if (_scroll.hasClients) {
      // Rough position first (items are built lazily), then exact.
      final fraction = _messages.length <= 1 ? 0.0 : index / (_messages.length - 1);
      await _scroll.animateTo(
        _scroll.position.maxScrollExtent * fraction,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));
      final target = _keys[messageId]?.currentContext;
      if (target != null && target.mounted) {
        await Scrollable.ensureVisible(
          target,
          alignment: 0.4,
          duration: const Duration(milliseconds: 200),
        );
      }
    }
    Future<void>.delayed(const Duration(seconds: 2), () {
      if (mounted && _highlightId == messageId) {
        setState(() => _highlightId = null);
      }
    });
  }

  List<ChatMessageView> _filter(String query) {
    final needle = query.trim().toLowerCase();
    if (needle.isEmpty) return [];
    return [
      for (final message in _messages.reversed)
        if (!message.isDeleted &&
            '${message.text}\n${message.attachment?.name ?? ''}'
                .toLowerCase()
                .contains(needle))
          message,
    ];
  }

  Future<void> _menu(String choice) async {
    switch (choice) {
      case 'search':
        setState(() {
          _searching = true;
          _searchResults = [];
          _searchField.clear();
        });
      case 'mute':
        await _run(() => _service.setMuted(widget.contact, !_muted), 'Not changed: {0}');
      case 'archive':
        await _run(
          () => _service.setArchived(widget.contact, !_archived),
          'Not changed: {0}',
        );
        if (mounted && !_archived) Navigator.pop(context);
      case 'block':
        await _confirmBlock();
      case 'report':
        await Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => ReportPage(
              contact: widget.contact,
              messages: _messages,
            ),
          ),
        );
    }
  }

  Future<void> _confirmBlock() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.tr('Block {0}?', [_name])),
        content: Text(context.tr('Blocked people cannot message or call you. They are not told. You can unblock them in Privacy.')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.tr('Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(context.tr('Block')),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _run(() => _service.block(widget.contact), 'Not blocked: {0}');
    if (mounted) Navigator.pop(context);
  }

  // ---------------------------------------------------------------- misc

  Future<void> _scanToSetUp() async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => MeyaQrScannerPage(database: widget.database),
      ),
    );
    await _reload();
  }

  String _time(DateTime time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final pinned = [for (final m in _messages) if (m.pinned) m];
    final pin = pinned.isEmpty ? null : pinned[_pinIndex % pinned.length];

    return Scaffold(
      appBar: _searching
          ? AppBar(
              leading: IconButton(
                tooltip: context.tr('Close search'),
                icon: const Icon(Icons.close),
                onPressed: () => setState(() {
                  _searching = false;
                  _searchResults = [];
                }),
              ),
              title: TextField(
                controller: _searchField,
                autofocus: true,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: context.tr('Search this chat'),
                  border: InputBorder.none,
                  filled: false,
                ),
                onChanged: (value) =>
                    setState(() => _searchResults = _filter(value)),
              ),
            )
          : AppBar(
              titleSpacing: 0,
              title: Row(
                children: [
                  ContactAvatar(
                    contactId: widget.contact.contactId,
                    name: _name,
                    radius: 18,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(_name, overflow: TextOverflow.ellipsis),
                            ),
                            if (_muted) ...[
                              const SizedBox(width: 4),
                              Icon(
                                Icons.notifications_off_outlined,
                                size: 16,
                                semanticLabel: context.tr('Muted'),
                              ),
                            ],
                          ],
                        ),
                        Row(
                          children: [
                            Icon(
                                _verified ? Icons.verified_user : Icons.lock_outline,
                                size: 12,
                                color: colorScheme.primary),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                _verified
                                    ? context.tr('Verified · end-to-end encrypted')
                                    : context.tr('End-to-end encrypted'),
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colorScheme.onSurface
                                      .withValues(alpha: 0.65),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  tooltip: context.tr('Voice call'),
                  icon: const Icon(Icons.call_outlined),
                  onPressed: _canMessage
                      ? () => startCallWith(context, widget.contact, video: false)
                      : null,
                ),
                IconButton(
                  tooltip: context.tr('Video call'),
                  icon: const Icon(Icons.videocam_outlined),
                  onPressed: _canMessage
                      ? () => startCallWith(context, widget.contact, video: true)
                      : null,
                ),
                PopupMenuButton<String>(
                  tooltip: context.tr('More options'),
                  onSelected: _menu,
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'search',
                      child: Text(context.tr('Search')),
                    ),
                    PopupMenuItem(
                      value: 'mute',
                      child: Text(
                        _muted ? context.tr('Unmute') : context.tr('Mute notifications'),
                      ),
                    ),
                    PopupMenuItem(
                      value: 'archive',
                      child: Text(
                        _archived ? context.tr('Unarchive') : context.tr('Archive'),
                      ),
                    ),
                    PopupMenuItem(
                      value: 'block',
                      child: Text(context.tr('Block')),
                    ),
                    PopupMenuItem(
                      value: 'report',
                      child: Text(context.tr('Report')),
                    ),
                  ],
                ),
              ],
            ),
      body: SafeArea(
        child: Column(
          children: [
            if (!_loading && !_canMessage)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('Set up encrypted messaging with {0}', [_name]),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onErrorContainer,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      context.tr('You connected before encryption was added. Meet in person: {0} opens My QR, and you scan it. It takes a few seconds and your chat history stays.', [_name]),
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        color: colorScheme.onErrorContainer,
                      ),
                    ),
                    const SizedBox(height: 10),
                    FilledButton.icon(
                      onPressed: _scanToSetUp,
                      icon: const Icon(Icons.qr_code_scanner),
                      label: Text(context.tr('Scan their QR code')),
                    ),
                  ],
                ),
              ),
            if (pin != null && !_searching)
              Material(
                color: colorScheme.surfaceContainerHigh,
                child: InkWell(
                  onTap: () {
                    _jumpTo(pin.id);
                    if (pinned.length > 1) setState(() => _pinIndex++);
                  },
                  child: Semantics(
                    button: true,
                    label: context.tr('Pinned message: {0}', [pin.preview]),
                    excludeSemantics: true,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                      child: Row(
                        children: [
                          Icon(Icons.push_pin, size: 18, color: colorScheme.primary),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  pinned.length > 1
                                      ? context.tr('Pinned {0} of {1}', [
                                          _pinIndex % pinned.length + 1,
                                          pinned.length,
                                        ])
                                      : context.tr('Pinned'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: colorScheme.primary,
                                  ),
                                ),
                                Text(
                                  pin.preview,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            Expanded(
              child: _searching && _searchField.text.trim().isNotEmpty
                  ? _searchResults.isEmpty
                      ? Center(child: Text(context.tr('No messages found.')))
                      : ListView.separated(
                          itemCount: _searchResults.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final message = _searchResults[index];
                            final who = message.isMine ? context.tr('You') : _name;
                            return ListTile(
                              title: Text(
                                message.preview,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text('$who · ${_dateTime(message.createdAt)}'),
                              onTap: () {
                                setState(() => _searching = false);
                                WidgetsBinding.instance.addPostFrameCallback(
                                  (_) => _jumpTo(message.id),
                                );
                              },
                            );
                          },
                        )
                  : _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _messages.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 32),
                                child: Text(
                                  context.tr('No messages with {0} yet.', [_name]),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: colorScheme.onSurface
                                        .withValues(alpha: 0.6),
                                  ),
                                ),
                              ),
                            )
                          : ListView.builder(
                              controller: _scroll,
                              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                              itemCount: _messages.length,
                              itemBuilder: (context, index) {
                                final message = _messages[index];
                                final previous =
                                    index == 0 ? null : _messages[index - 1];
                                final newDay = previous == null ||
                                    !_sameDay(previous.createdAt, message.createdAt);
                                return Column(
                                  key: _keys.putIfAbsent(message.id, GlobalKey.new),
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    if (newDay) _DayLabel(_day(message.createdAt)),
                                    ChatBubble(
                                      message: message,
                                      contactName: _name,
                                      time: _time(message.createdAt),
                                      playing: _playingId == message.id,
                                      highlighted: _highlightId == message.id,
                                      onTogglePlay: () => _togglePlay(message),
                                      onOpen: () => _openAttachment(message),
                                      onSave: message.attachment == null
                                          ? null
                                          : () => saveAttachmentToDevice(
                                                context,
                                                message.attachment!,
                                              ),
                                      onActions: () => _showActions(message),
                                      onReply: _canMessage
                                          ? () => _startReply(message)
                                          : null,
                                      onReact: (emoji) => _react(message, emoji),
                                      onQuoteTap: message.reply == null
                                          ? null
                                          : () => _jumpTo(message.reply!.id),
                                      onRetry: () => _run(
                                        () => _service.retryMessage(
                                          widget.contact,
                                          message.id,
                                        ),
                                        'Still not sent: {0}',
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
            ),
            if (_replyingTo != null || _editing != null)
              _ComposerContext(
                title: _editing != null
                    ? context.tr('Editing message')
                    : context.tr('Replying to {0}', [
                        _replyingTo!.isMine ? context.tr('yourself') : _name,
                      ]),
                text: (_editing ?? _replyingTo)!.preview,
                icon: _editing != null ? Icons.edit_outlined : Icons.reply,
                onClose: () => setState(() {
                  if (_editing != null) _composer.clear();
                  _editing = null;
                  _replyingTo = null;
                }),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: _recording
                  ? _RecordingBar(
                      elapsed: _recorded,
                      limit: MeyaMessageService.maxVoiceDuration,
                      onDelete: () => _finishRecording(send: false),
                      onSend: () => _finishRecording(send: true),
                    )
                  : Row(
                      children: [
                        IconButton(
                          tooltip: context.tr('Attach a photo, video, file or call'),
                          onPressed: _canMessage && !_sending && _editing == null
                              ? _showAttachMenu
                              : null,
                          icon: const Icon(Icons.add_circle_outline),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _composer,
                            enabled: _canMessage && !_sending,
                            minLines: 1,
                            maxLines: 5,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: InputDecoration(
                              hintText: _canMessage
                                  ? context.tr('Message')
                                  : context.tr('Encrypted messaging not set up yet'),
                            ),
                            onSubmitted: (_) => _send(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (_sending)
                          const IconButton.filled(
                            onPressed: null,
                            icon: SizedBox(
                              width: 20,
                              height: 20,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        else if (_hasText || _editing != null)
                          IconButton.filled(
                            tooltip: _editing != null
                                ? context.tr('Save edit')
                                : context.tr('Send'),
                            onPressed: _canMessage ? _send : null,
                            icon: Icon(_editing != null ? Icons.check : Icons.send),
                          )
                        else
                          IconButton.filled(
                            tooltip: context.tr('Record a voice message'),
                            onPressed: _canMessage ? _startRecording : null,
                            icon: const Icon(Icons.mic),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _day(DateTime time) {
    final now = DateTime.now();
    if (_sameDay(time, now)) return context.tr('Today');
    if (_sameDay(time, now.subtract(const Duration(days: 1)))) {
      return context.tr('Yesterday');
    }
    return MaterialLocalizations.of(context).formatMediumDate(time);
  }

  String _dateTime(DateTime time) => '${_day(time)} ${_time(time)}';
}

String _formatDuration(Duration duration) {
  final minutes = duration.inMinutes;
  final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}

class _RecordingBar extends StatelessWidget {
  final Duration elapsed;
  final Duration limit;
  final VoidCallback onDelete;
  final VoidCallback onSend;

  const _RecordingBar({
    required this.elapsed,
    required this.limit,
    required this.onDelete,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        IconButton(
          tooltip: context.tr('Delete recording'),
          onPressed: onDelete,
          icon: Icon(Icons.delete_outline, color: colorScheme.error),
        ),
        const SizedBox(width: 4),
        Icon(Icons.fiber_manual_record, size: 14, color: colorScheme.error),
        const SizedBox(width: 8),
        Expanded(
          child: Semantics(
            liveRegion: true,
            child: Text(
              context.tr('Recording {0} / {1}', [_formatDuration(elapsed), _formatDuration(limit)]),
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ),
        IconButton.filled(
          tooltip: context.tr('Send voice message'),
          onPressed: onSend,
          icon: const Icon(Icons.send),
        ),
      ],
    );
  }
}

class _DayLabel extends StatelessWidget {
  final String text;

  const _DayLabel(this.text);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Semantics(
      header: true,
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 10),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(text, style: const TextStyle(fontSize: 13)),
        ),
      ),
    );
  }
}

/// "Replying to …" or "Editing message" above the text field.
class _ComposerContext extends StatelessWidget {
  final String title;
  final String text;
  final IconData icon;
  final VoidCallback onClose;

  const _ComposerContext({
    required this.title,
    required this.text,
    required this.icon,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 0),
      padding: const EdgeInsets.fromLTRB(12, 6, 4, 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
        border: BorderDirectional(
          start: BorderSide(color: colorScheme.primary, width: 4),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.primary,
                  ),
                ),
                Text(text, maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          IconButton(
            tooltip: context.tr('Cancel'),
            onPressed: onClose,
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }
}

/// One message in a conversation (direct or group).
class ChatBubble extends StatelessWidget {
  final ChatMessageView message;
  final String contactName;
  final String time;
  final bool playing;
  final bool highlighted;
  final VoidCallback onTogglePlay;
  final VoidCallback onOpen;
  final VoidCallback? onSave;
  final VoidCallback onActions;
  final VoidCallback? onReply;
  final ValueChanged<String> onReact;
  final VoidCallback? onQuoteTap;
  final VoidCallback onRetry;

  /// The author's name, shown on others' messages in group conversations.
  final String? senderName;

  const ChatBubble({
    super.key,
    this.senderName,
    required this.message,
    required this.contactName,
    required this.time,
    required this.playing,
    required this.highlighted,
    required this.onTogglePlay,
    required this.onOpen,
    required this.onSave,
    required this.onActions,
    required this.onReply,
    required this.onReact,
    required this.onQuoteTap,
    required this.onRetry,
  });

  /// Tick icon and spoken description of the delivery state.
  (IconData, String)? _status(BuildContext context) {
    if (!message.isMine || message.isDeleted) return null;
    return switch (message.state) {
      'queued' || 'sending' => (Icons.schedule, context.tr('Waiting to send')),
      'failed' => (Icons.error_outline, context.tr('Not sent. Tap to try again')),
      'delivered' => (Icons.done_all, context.tr('Delivered')),
      'read' => (Icons.done_all, context.tr('Read')),
      _ => (Icons.done, context.tr('Sent')),
    };
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final mine = message.isMine;
    final background = mine ? colorScheme.primary : colorScheme.surfaceContainerHighest;
    final foreground = mine ? colorScheme.onPrimary : colorScheme.onSurface;
    final status = _status(context);

    final Widget content;
    if (message.isDeleted) {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.block, size: 16, color: foreground.withValues(alpha: 0.8)),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              mine
                  ? context.tr('You deleted this message')
                  : context.tr('This message was deleted'),
              style: TextStyle(
                color: foreground.withValues(alpha: 0.85),
                fontStyle: FontStyle.italic,
                fontSize: 15,
              ),
            ),
          ),
        ],
      );
    } else if (message.kind == 'voice') {
      final length = _formatDuration(
        Duration(milliseconds: message.durationMs),
      );
      content = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: playing ? context.tr('Stop voice message') : context.tr('Play voice message'),
            onPressed: message.audio == null ? null : onTogglePlay,
            icon: Icon(
              playing ? Icons.stop_circle_outlined : Icons.play_circle_fill,
              color: foreground,
              size: 32,
            ),
          ),
          const SizedBox(width: 4),
          Icon(Icons.mic, size: 16, color: foreground.withValues(alpha: 0.8)),
          const SizedBox(width: 4),
          Text(
            context.tr('Voice message · {0}', [length]),
            style: TextStyle(color: foreground, fontSize: 15),
          ),
        ],
      );
    } else if (message.kind == 'image' && message.attachment != null) {
      content = _Captioned(
        caption: message.text,
        color: foreground,
        child: Semantics(
          button: true,
          label: context.tr('Photo. Opens full screen'),
          child: GestureDetector(
            onTap: onOpen,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: EncryptedImage(
                attachment: message.attachment!,
                width: 220,
                height: 220,
              ),
            ),
          ),
        ),
      );
    } else if (message.kind == 'video' &&
        message.attachment?.thumbnail != null) {
      final attachment = message.attachment!;
      content = _Captioned(
        caption: message.text,
        color: foreground,
        child: Semantics(
          button: true,
          label: context.tr('Video, {0}. Plays full screen', [formatBytes(attachment.size)]),
          excludeSemantics: true,
          child: GestureDetector(
            onTap: onOpen,
            child: VideoThumbnail(
              bytes: attachment.thumbnail!,
              label: context.tr('Video'),
              caption: formatBytes(attachment.size),
            ),
          ),
        ),
      );
    } else if (message.kind == 'video' || message.kind == 'file') {
      final attachment = message.attachment!;
      final isVideo = message.kind == 'video';
      content = _Captioned(
        caption: message.text,
        color: foreground,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: isVideo ? context.tr('Play video') : context.tr('Open file'),
              onPressed: onOpen,
              icon: Icon(
                isVideo
                    ? Icons.play_circle_fill
                    : Icons.insert_drive_file_outlined,
                color: foreground,
                size: 32,
              ),
            ),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isVideo ? context.tr('Video') : attachment.name,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: foreground,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    formatBytes(attachment.size),
                    style: TextStyle(
                      color: foreground.withValues(alpha: 0.8),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            if (onSave != null)
              IconButton(
                tooltip: context.tr('Save a copy to this phone'),
                onPressed: onSave,
                icon: Icon(Icons.download_outlined, color: foreground),
              ),
          ],
        ),
      );
    } else if (message.call != null) {
      final call = message.call!;
      final cancelled = message.kind == 'call_cancel';
      content = Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            cancelled ? Icons.event_busy_outlined : Icons.event_available_outlined,
            color: foreground,
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cancelled
                      ? context.tr('Call cancelled')
                      : call.callType == 'video'
                          ? context.tr('Video call planned')
                          : context.tr('Voice call planned'),
                  style: TextStyle(
                    color: foreground,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  call.title,
                  style: TextStyle(color: foreground, fontSize: 15),
                ),
                Text(
                  formatCallTime(context, call.start, call.durationMinutes),
                  style: TextStyle(
                    color: foreground.withValues(alpha: 0.85),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    } else {
      content = Align(
        alignment: AlignmentDirectional.centerStart,
        child: Text(
          message.text,
          style: TextStyle(color: foreground, fontSize: 16, height: 1.35),
        ),
      );
    }

    final reply = message.reply;
    final bubble = Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
        border: highlighted
            ? Border.all(color: colorScheme.tertiary, width: 3)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (senderName != null && !mine)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  senderName!,
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          if (message.forwarded)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.forward, size: 14, color: foreground.withValues(alpha: 0.8)),
                    const SizedBox(width: 4),
                    Text(
                      context.tr('Forwarded'),
                      style: TextStyle(
                        color: foreground.withValues(alpha: 0.8),
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (reply != null)
            GestureDetector(
              onTap: onQuoteTap,
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
                decoration: BoxDecoration(
                  color: foreground.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: BorderDirectional(
                    start: BorderSide(color: foreground, width: 3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reply.isMine ? context.tr('You') : contactName,
                      style: TextStyle(
                        color: foreground,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      reply.text,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: foreground, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          content,
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (message.pinned) ...[
                Icon(Icons.push_pin, size: 12, color: foreground.withValues(alpha: 0.75)),
                const SizedBox(width: 4),
              ],
              if (message.starred) ...[
                Icon(Icons.star, size: 12, color: foreground.withValues(alpha: 0.75)),
                const SizedBox(width: 4),
              ],
              if (message.edited && !message.isDeleted) ...[
                Text(
                  context.tr('Edited'),
                  style: TextStyle(
                    color: foreground.withValues(alpha: 0.75),
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(width: 4),
              ],
              Text(
                time,
                style: TextStyle(
                  color: foreground.withValues(alpha: 0.75),
                  fontSize: 11,
                ),
              ),
              if (status != null) ...[
                const SizedBox(width: 4),
                Icon(
                  status.$1,
                  size: 15,
                  color: message.state == 'read'
                      ? (mine ? const Color(0xFF7FDBFF) : colorScheme.primary)
                      : message.state == 'failed'
                          ? colorScheme.errorContainer
                          : foreground.withValues(alpha: 0.75),
                ),
              ],
            ],
          ),
        ],
      ),
    );

    final reactions = message.reactions.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Screen-reader summary plus actions that do not need a long-press.
    final summary = [
      if (message.forwarded) context.tr('Forwarded'),
      if (reply != null)
        context.tr('Reply to {0}: {1}', [
          reply.isMine ? context.tr('you') : contactName,
          reply.text,
        ]),
      mine ? context.tr('You') : contactName,
      message.preview,
      time,
      ?status?.$2,
      if (message.edited) context.tr('Edited'),
      if (message.pinned) context.tr('Pinned'),
      for (final entry in reactions) '${entry.key} ${entry.value}',
    ].join('. ');

    return Semantics(
      label: summary,
      onLongPressHint: context.tr('Show message options'),
      customSemanticsActions: {
        if (onReply != null)
          CustomSemanticsAction(label: context.tr('Reply')): onReply!,
        CustomSemanticsAction(label: context.tr('Message options')): onActions,
        if (message.state == 'failed' && mine)
          CustomSemanticsAction(label: context.tr('Send again')): onRetry,
      },
      child: GestureDetector(
        onLongPress: onActions,
        onTap: message.state == 'failed' && mine ? onRetry : null,
        // Swipe right to reply, as in most messengers.
        onHorizontalDragEnd: onReply == null || message.isDeleted
            ? null
            : (details) {
                final velocity = details.primaryVelocity ?? 0;
                final towardsCenter =
                    Directionality.of(context) == TextDirection.rtl
                        ? velocity < -300
                        : velocity > 300;
                if (towardsCenter) onReply!();
              },
        child: Align(
          alignment:
              mine ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width * 0.78,
            ),
            child: Column(
              crossAxisAlignment:
                  mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                ExcludeSemantics(child: bubble),
                if (reactions.isNotEmpty)
                  Transform.translate(
                    offset: const Offset(0, -6),
                    child: Wrap(
                      spacing: 4,
                      children: [
                        for (final entry in reactions)
                          Semantics(
                            button: true,
                            selected: message.myReaction == entry.key,
                            label: context.tr('{0} reacted {1}. Tap to change your reaction', [
                              entry.value,
                              entry.key,
                            ]),
                            excludeSemantics: true,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => onReact(entry.key),
                              child: Container(
                                constraints: const BoxConstraints(minHeight: 32, minWidth: 40),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: message.myReaction == entry.key
                                      ? colorScheme.primaryContainer
                                      : colorScheme.surfaceContainerHigh,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: colorScheme.surface,
                                    width: 2,
                                  ),
                                ),
                                child: Text(
                                  entry.value > 1
                                      ? '${entry.key} ${entry.value}'
                                      : entry.key,
                                  style: const TextStyle(fontSize: 15),
                                ),
                              ),
                            ),
                          ),
                      ],
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

class _Captioned extends StatelessWidget {
  final String caption;
  final Color color;
  final Widget child;

  const _Captioned({
    required this.caption,
    required this.color,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (caption.isEmpty) return child;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        child,
        const SizedBox(height: 6),
        Text(caption, style: TextStyle(color: color, fontSize: 15, height: 1.35)),
      ],
    );
  }
}
