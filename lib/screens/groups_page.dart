import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../database/contact_repository.dart';
import '../database/group_repository.dart';
import '../database/meya_database.dart';
import '../l10n/meya_strings.dart';
import '../services/meya_group_service.dart';
import '../services/meya_message_service.dart';
import '../theme/meya_theme.dart';
import 'chat_page.dart';
import 'media_widgets.dart';

/// Your private groups.
class GroupsPage extends StatefulWidget {
  final MeyaDatabase database;

  const GroupsPage({super.key, required this.database});

  @override
  State<GroupsPage> createState() => _GroupsPageState();
}

class _GroupsPageState extends State<GroupsPage> {
  final _groups = MeyaGroupService.instance;
  final List<StreamSubscription<String>> _subscriptions = [];
  List<(MeyaGroup, int members, Conversation? conversation)> _rows = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _subscriptions
      ..add(_groups.changes.listen((_) => _load()))
      ..add(MeyaMessageService.instance.changes.listen((id) {
        if (id.startsWith('group_')) _load();
      }));
    _load();
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }

  Future<void> _load() async {
    final states = await MeyaMessageService.instance.conversationStates();
    final rows = <(MeyaGroup, int, Conversation?)>[];
    for (final group in await _groups.groups()) {
      rows.add((
        group,
        (await _groups.members(group.groupId)).length,
        states[GroupRepository.conversationIdFor(group.groupId)],
      ));
    }
    if (!mounted) return;
    setState(() {
      _rows = rows;
      _loading = false;
    });
  }

  Future<void> _newGroup() async {
    final groupId = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => NewGroupPage(database: widget.database)),
    );
    await _load();
    if (groupId == null || !mounted) return;
    _open(groupId);
  }

  void _open(String groupId) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => GroupChatPage(database: widget.database, groupId: groupId),
      ),
    ).then((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.meya;
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('Groups'))),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _newGroup,
        icon: const Icon(Icons.group_add_outlined),
        label: Text(context.tr('New group')),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _rows.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.groups_outlined, size: 64, color: colors.muted),
                          const SizedBox(height: 16),
                          Text(
                            context.tr('No groups yet'),
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            context.tr('Create a group with your MEYA connections. Every message is end-to-end encrypted for each member.'),
                            textAlign: TextAlign.center,
                            style: TextStyle(color: colors.muted, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(0, 8, 0, 96),
                    itemCount: _rows.length,
                    separatorBuilder: (_, _) => const Divider(height: 1, indent: 72),
                    itemBuilder: (context, index) {
                      final (group, count, conversation) = _rows[index];
                      final unread = conversation?.unreadCount ?? 0;
                      return ListTile(
                        leading: GroupAvatar(name: group.name),
                        title: Text(group.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text(
                          group.isActive
                              ? context.tr('{0} members', [count])
                              : context.tr('You are no longer in this group'),
                        ),
                        trailing: unread > 0
                            ? Badge(label: Text('$unread'))
                            : const Icon(Icons.chevron_right),
                        onTap: () => _open(group.groupId),
                      );
                    },
                  ),
      ),
    );
  }
}

class GroupAvatar extends StatelessWidget {
  final String name;
  final double radius;

  const GroupAvatar({super.key, required this.name, this.radius = 24});

  @override
  Widget build(BuildContext context) {
    final letters = name.trim().isEmpty ? '#' : name.trim().characters.first.toUpperCase();
    return CircleAvatar(
      radius: radius,
      backgroundColor: context.meya.navy,
      foregroundColor: context.meya.onNavy,
      child: Text(letters, style: TextStyle(fontSize: radius * 0.8, fontWeight: FontWeight.w700)),
    );
  }
}

/// Lets you pick connections. Returns the chosen contacts, or null.
Future<List<Contact>?> pickConnections(
  BuildContext context,
  MeyaDatabase database, {
  Set<String> excludeDeviceIds = const {},
  required String title,
}) async {
  final repository = ContactRepository(database);
  final messages = MeyaMessageService.instance;
  final choices = <(Contact, String)>[];
  for (final contact in await repository.getTrustedContacts()) {
    final deviceId = await repository.getDeviceIdForContact(contact.contactId);
    if (deviceId == null || excludeDeviceIds.contains(deviceId)) continue;
    if (!await messages.canMessage(contact)) continue;
    choices.add((contact, deviceId));
  }
  if (!context.mounted) return null;
  return Navigator.push<List<Contact>>(
    context,
    MaterialPageRoute(builder: (_) => _PickConnectionsPage(title: title, choices: choices)),
  );
}

class _PickConnectionsPage extends StatefulWidget {
  final String title;
  final List<(Contact, String)> choices;

  const _PickConnectionsPage({required this.title, required this.choices});

  @override
  State<_PickConnectionsPage> createState() => _PickConnectionsPageState();
}

class _PickConnectionsPageState extends State<_PickConnectionsPage> {
  final Set<String> _chosen = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: SafeArea(
        child: widget.choices.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    context.tr('No one to add. Connect with people by scanning their QR code first.'),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            : ListView(
                children: [
                  for (final (contact, _) in widget.choices)
                    CheckboxListTile(
                      value: _chosen.contains(contact.contactId),
                      onChanged: (value) => setState(() {
                        if (value == true) {
                          _chosen.add(contact.contactId);
                        } else {
                          _chosen.remove(contact.contactId);
                        }
                      }),
                      title: Text(contact.displayName),
                      secondary: CircleAvatar(
                        child: Text(
                          contact.displayName.trim().isEmpty
                              ? '?'
                              : contact.displayName.trim().characters.first.toUpperCase(),
                        ),
                      ),
                    ),
                ],
              ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: FilledButton(
            onPressed: _chosen.isEmpty
                ? null
                : () => Navigator.pop(context, [
                      for (final (contact, _) in widget.choices)
                        if (_chosen.contains(contact.contactId)) contact,
                    ]),
            child: Text(context.tr('Add {0}', [_chosen.length])),
          ),
        ),
      ),
    );
  }
}

/// Name a new group and choose its first members.
class NewGroupPage extends StatefulWidget {
  final MeyaDatabase database;

  const NewGroupPage({super.key, required this.database});

  @override
  State<NewGroupPage> createState() => _NewGroupPageState();
}

class _NewGroupPageState extends State<NewGroupPage> {
  final _name = TextEditingController();
  List<Contact> _members = [];
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _choose() async {
    final chosen = await pickConnections(
      context,
      widget.database,
      title: context.tr('Choose members'),
    );
    if (chosen != null && mounted) setState(() => _members = chosen);
  }

  Future<void> _create() async {
    setState(() => _saving = true);
    try {
      final groupId = await MeyaGroupService.instance.create(_name.text, _members);
      if (mounted) Navigator.pop(context, groupId);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final ready = _name.text.trim().isNotEmpty && _members.isNotEmpty && !_saving;
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('New group'))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextField(
              controller: _name,
              maxLength: MeyaGroupService.maxNameLength,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: context.tr('Group name'),
                hintText: context.tr('For example: Family'),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _choose,
              icon: const Icon(Icons.person_add_alt_1_outlined),
              label: Text(
                _members.isEmpty
                    ? context.tr('Choose members')
                    : context.tr('{0} chosen · change', [_members.length]),
              ),
            ),
            const SizedBox(height: 8),
            for (final contact in _members)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.person_outline),
                title: Text(contact.displayName),
              ),
            const SizedBox(height: 16),
            Text(
              context.tr('You will be the admin. You can make other members admins too: admins can rename the group, add or remove people and introduce members who are not connected with each other.'),
              style: TextStyle(color: context.meya.muted, height: 1.4),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: FilledButton(
            onPressed: ready ? _create : null,
            child: _saving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(context.tr('Create group')),
          ),
        ),
      ),
    );
  }
}

/// A group conversation.
class GroupChatPage extends StatefulWidget {
  final MeyaDatabase database;
  final String groupId;

  const GroupChatPage({super.key, required this.database, required this.groupId});

  @override
  State<GroupChatPage> createState() => _GroupChatPageState();
}

class _GroupChatPageState extends State<GroupChatPage> {
  static const Duration _minVoiceDuration = Duration(milliseconds: 700);

  final _service = MeyaMessageService.instance;
  final _groups = MeyaGroupService.instance;
  final _composer = TextEditingController();
  final _scroll = ScrollController();
  final _recorder = AudioRecorder();
  final _player = AudioPlayer();
  final List<StreamSubscription<Object?>> _subscriptions = [];

  MeyaGroup? _group;
  Map<String, String> _names = {};
  List<ChatMessageView> _messages = [];
  bool _loading = true;
  bool _sending = false;
  bool _hasText = false;
  bool _recording = false;
  String? _recordingPath;
  DateTime? _recordingStarted;
  Duration _recorded = Duration.zero;
  Timer? _recordTimer;
  String? _playingId;

  String get _conversationId => GroupRepository.conversationIdFor(widget.groupId);

  @override
  void initState() {
    super.initState();
    _service.activeConversationId = _conversationId;
    _subscriptions
      ..add(_service.changes.listen((id) {
        if (id == _conversationId) _reload();
      }))
      ..add(_service.mediaArrived.listen((_) => _reload()))
      ..add(_groups.changes.listen((id) {
        if (id == widget.groupId) _reload();
      }))
      ..add(_player.onPlayerComplete.listen((_) {
        if (mounted) setState(() => _playingId = null);
      }));
    _composer.addListener(() {
      final hasText = _composer.text.trim().isNotEmpty;
      if (hasText != _hasText) setState(() => _hasText = hasText);
    });
    _reload();
  }

  @override
  void dispose() {
    if (_service.activeConversationId == _conversationId) {
      _service.activeConversationId = null;
    }
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _recordTimer?.cancel();
    if (_recording) _recorder.cancel().catchError((_) {});
    _deleteRecordingFile();
    _recorder.dispose();
    _player.dispose();
    _composer.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    final group = await _groups.group(widget.groupId);
    final names = await _groups.memberNames(widget.groupId);
    final messages = await _service.historyFor(_conversationId);
    await _service.markGroupRead(widget.groupId);
    if (!mounted) return;
    final atBottom = !_scroll.hasClients ||
        _scroll.position.pixels >= _scroll.position.maxScrollExtent - 80;
    setState(() {
      _group = group;
      _names = names;
      _messages = messages;
      _loading = false;
    });
    if (atBottom) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
      });
    }
  }

  bool get _canWrite => _group?.isActive ?? false;

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _sendText() async {
    final text = _composer.text;
    if (text.trim().isEmpty || _sending) return;
    setState(() => _sending = true);
    _composer.clear();
    try {
      await _service.sendGroupText(widget.groupId, text);
    } catch (error) {
      _composer.text = text;
      _showError(context.tr('Not sent: {0}', [error]));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _attach() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (value, icon, label) in [
              ('gallery_photo', Icons.photo_library_outlined, context.tr('Photo from gallery')),
              ('camera_photo', Icons.photo_camera_outlined, context.tr('Take a photo')),
              ('gallery_video', Icons.video_library_outlined, context.tr('Video from gallery')),
              ('camera_video', Icons.videocam_outlined, context.tr('Record a video')),
              ('file', Icons.attach_file, context.tr('File')),
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
    setState(() => _sending = true);
    try {
      await _service.sendGroupAttachment(
        widget.groupId,
        kind: media.kind,
        bytes: media.bytes,
        mime: media.mime,
        name: media.name,
        thumbnail: media.thumbnail,
      );
    } catch (error) {
      _showError(context.tr('Not sent: {0}', [error]));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _startRecording() async {
    if (_recording || _sending || !_canWrite) return;
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
    final duration =
        started == null ? Duration.zero : DateTime.now().difference(started);
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
      await _service.sendGroupVoice(
        widget.groupId,
        audio,
        durationMs: clamped.inMilliseconds,
      );
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

  void _deleteRecordingFile() {
    final path = _recordingPath;
    _recordingPath = null;
    if (path == null) return;
    try {
      final file = File(path);
      if (file.existsSync()) file.deleteSync();
    } catch (_) {}
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
      await _player.play(BytesSource(audio));
      if (mounted) setState(() => _playingId = message.id);
    } catch (error) {
      _showError(context.tr('Could not play this voice message: {0}', [error]));
    }
  }

  void _openAttachment(ChatMessageView message) {
    final attachment = message.attachment;
    if (attachment == null) return;
    switch (message.kind) {
      case 'image':
        Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => PhotoViewerPage(attachment: attachment, caption: message.text),
          ),
        );
      case 'video':
        _player.stop();
        Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => VideoPlayerPage(attachment: attachment, caption: message.text),
          ),
        );
      default:
        openAttachmentExternally(context, attachment);
    }
  }

  String _time(DateTime time) =>
      MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(time));

  void _openInfo() {
    Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => GroupInfoPage(database: widget.database, groupId: widget.groupId),
      ),
    ).then((deleted) {
      if (!mounted) return;
      if (deleted == true) {
        Navigator.pop(context);
      } else {
        _reload();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final group = _group;
    final colors = context.meya;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: InkWell(
          onTap: group == null ? null : _openInfo,
          child: Row(
            children: [
              GroupAvatar(name: group?.name ?? '', radius: 18),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(group?.name ?? context.tr('Group'), overflow: TextOverflow.ellipsis),
                    Text(
                      context.tr('{0} members', [_names.length]),
                      style: TextStyle(fontSize: 13, color: colors.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            tooltip: context.tr('Group info'),
            icon: const Icon(Icons.info_outline),
            onPressed: group == null ? null : _openInfo,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _messages.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Text(
                              context.tr('Messages in this group are end-to-end encrypted for each member.'),
                              textAlign: TextAlign.center,
                              style: TextStyle(color: colors.muted),
                            ),
                          ),
                        )
                      : ListView.builder(
                          controller: _scroll,
                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final message = _messages[index];
                            final sender = message.senderDeviceId == null
                                ? null
                                : _names[message.senderDeviceId] ?? context.tr('Former member');
                            return Align(
                              alignment: message.isMine
                                  ? AlignmentDirectional.centerEnd
                                  : AlignmentDirectional.centerStart,
                              child: ChatBubble(
                                message: message,
                                senderName: sender,
                                contactName: sender ?? '',
                                time: _time(message.createdAt),
                                playing: _playingId == message.id,
                                highlighted: false,
                                onTogglePlay: () => _togglePlay(message),
                                onOpen: () => _openAttachment(message),
                                onSave: message.attachment == null
                                    ? null
                                    : () => saveAttachmentToDevice(context, message.attachment!),
                                onActions: () {},
                                onReply: null,
                                onReact: (_) {},
                                onQuoteTap: null,
                                onRetry: () => _service.retryPending(),
                              ),
                            );
                          },
                        ),
            ),
            if (!_canWrite && !_loading)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  context.tr('You are no longer in this group'),
                  style: TextStyle(color: colors.muted),
                ),
              )
            else if (_recording)
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: context.tr('Cancel'),
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _finishRecording(send: false),
                    ),
                    Icon(Icons.fiber_manual_record, size: 14, color: Theme.of(context).colorScheme.error),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${_recorded.inMinutes}:${(_recorded.inSeconds % 60).toString().padLeft(2, '0')}',
                      ),
                    ),
                    IconButton.filled(
                      tooltip: context.tr('Send'),
                      icon: const Icon(Icons.send),
                      onPressed: () => _finishRecording(send: true),
                    ),
                  ],
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: context.tr('Attach'),
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: _sending ? null : _attach,
                    ),
                    Expanded(
                      child: TextField(
                        controller: _composer,
                        minLines: 1,
                        maxLines: 5,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          hintText: context.tr('Message'),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    _hasText
                        ? IconButton.filled(
                            tooltip: context.tr('Send'),
                            icon: const Icon(Icons.send),
                            onPressed: _sending ? null : _sendText,
                          )
                        : IconButton(
                            tooltip: context.tr('Record a voice message'),
                            icon: const Icon(Icons.mic_none),
                            onPressed: _sending ? null : _startRecording,
                          ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Members and settings of a group.
class GroupInfoPage extends StatefulWidget {
  final MeyaDatabase database;
  final String groupId;

  const GroupInfoPage({super.key, required this.database, required this.groupId});

  @override
  State<GroupInfoPage> createState() => _GroupInfoPageState();
}

class _GroupInfoPageState extends State<GroupInfoPage> {
  final _groups = MeyaGroupService.instance;
  StreamSubscription<String>? _subscription;
  MeyaGroup? _group;
  List<GroupMember> _members = [];
  Set<String> _admins = {};
  bool _isAdmin = false;
  String? _me;

  @override
  void initState() {
    super.initState();
    _subscription = _groups.changes.listen((id) {
      if (id == widget.groupId) _load();
    });
    _load();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final group = await _groups.group(widget.groupId);
    final members = await _groups.members(widget.groupId);
    final me = await MeyaMessageService.instance.localDeviceId();
    final admins = group == null ? <String>{} : await _groups.admins(group);
    if (!mounted) return;
    setState(() {
      _group = group;
      _members = members;
      _me = me;
      _admins = admins;
      _isAdmin = group != null && group.isActive && admins.contains(me);
    });
  }

  Future<void> _memberAction(GroupMember member, String action) async {
    switch (action) {
      case 'admin':
        await _run(() => _groups.setAdmin(widget.groupId, member.deviceId, true));
      case 'member':
        await _run(() => _groups.setAdmin(widget.groupId, member.deviceId, false));
      case 'remove':
        await _remove(member);
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
      }
    }
    await _load();
  }

  Future<void> _rename() async {
    final controller = TextEditingController(text: _group?.name ?? '');
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.tr('Group name')),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: MeyaGroupService.maxNameLength,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(context.tr('Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: Text(context.tr('Save')),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null) return;
    await _run(() => _groups.rename(widget.groupId, name));
  }

  Future<void> _add() async {
    final chosen = await pickConnections(
      context,
      widget.database,
      title: context.tr('Add members'),
      excludeDeviceIds: {for (final m in _members) m.deviceId},
    );
    if (chosen == null || chosen.isEmpty) return;
    await _run(() => _groups.addMembers(widget.groupId, chosen));
  }

  Future<void> _remove(GroupMember member) async {
    final confirmed = await _confirm(
      context.tr('Remove {0} from the group?', [member.displayName]),
      context.tr('Remove'),
    );
    if (confirmed) await _run(() => _groups.removeMember(widget.groupId, member.deviceId));
  }

  Future<bool> _confirm(String title, String action, {String? body}) async =>
      await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(title),
          content: body == null ? null : Text(body),
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
      ) ??
      false;

  Future<void> _leave() async {
    final confirmed = await _confirm(
      context.tr('Leave this group?'),
      context.tr('Leave'),
      body: _group?.adminDeviceId == _me
          ? context.tr('Another member becomes the admin. You keep the messages already on this phone.')
          : context.tr('You keep the messages already on this phone.'),
    );
    if (confirmed) await _run(() => _groups.leave(widget.groupId));
  }

  Future<void> _delete() async {
    final confirmed = await _confirm(
      context.tr('Delete this group from your phone?'),
      context.tr('Delete'),
      body: context.tr('Its messages are deleted from this phone. Other members keep theirs.'),
    );
    if (!confirmed) return;
    await _run(() => _groups.delete(widget.groupId));
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final group = _group;
    final colors = context.meya;
    if (group == null) {
      return Scaffold(appBar: AppBar(), body: const SizedBox());
    }
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('Group info'))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          children: [
            Center(child: GroupAvatar(name: group.name, radius: 40)),
            const SizedBox(height: 12),
            Center(
              child: Text(
                group.name,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
            ),
            Center(
              child: Text(
                context.tr('{0} members', [_members.length]),
                style: TextStyle(color: colors.muted),
              ),
            ),
            const SizedBox(height: 16),
            if (_isAdmin) ...[
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: Text(context.tr('Rename group')),
                onTap: _rename,
              ),
              ListTile(
                leading: const Icon(Icons.person_add_alt_1_outlined),
                title: Text(context.tr('Add members')),
                onTap: _add,
              ),
              const Divider(),
            ],
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text(
                context.tr('Members'),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            for (final member in _members)
              ListTile(
                leading: CircleAvatar(
                  child: Text(
                    member.displayName.trim().isEmpty
                        ? '?'
                        : member.displayName.trim().characters.first.toUpperCase(),
                  ),
                ),
                title: Text(member.deviceId == _me ? context.tr('You') : member.displayName),
                subtitle: _admins.contains(member.deviceId)
                    ? Text(context.tr('Admin'))
                    : null,
                // Nobody but the owner can remove the owner or take away
                // their admin role (the owner hands over by leaving).
                trailing: _isAdmin &&
                        member.deviceId != _me &&
                        member.deviceId != group.adminDeviceId
                    ? PopupMenuButton<String>(
                        onSelected: (action) => _memberAction(member, action),
                        itemBuilder: (_) => [
                          PopupMenuItem(
                            value: _admins.contains(member.deviceId) ? 'member' : 'admin',
                            child: Text(
                              _admins.contains(member.deviceId)
                                  ? context.tr('Remove as admin')
                                  : context.tr('Make admin'),
                            ),
                          ),
                          PopupMenuItem(
                            value: 'remove',
                            child: Text(context.tr('Remove')),
                          ),
                        ],
                      )
                    : null,
              ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Text(
                context.tr('Each message is end-to-end encrypted separately for every member. Members who are not connected with each other are introduced through the admin.'),
                style: TextStyle(color: colors.muted, height: 1.4),
              ),
            ),
            if (group.isActive)
              ListTile(
                leading: Icon(Icons.logout, color: Theme.of(context).colorScheme.error),
                title: Text(
                  context.tr('Leave group'),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                onTap: _leave,
              ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
              title: Text(
                context.tr('Delete group from this phone'),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              onTap: _delete,
            ),
          ],
        ),
      ),
    );
  }
}
