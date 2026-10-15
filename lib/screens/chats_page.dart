import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../database/account_repository.dart';
import '../database/contact_repository.dart';
import '../database/meya_database.dart';
import '../database/message_repository.dart';
import '../l10n/meya_strings.dart';
import '../services/meya_message_service.dart';
import 'chat_page.dart';

/// One row of the chats list.
class _ChatSummary {
  final Contact contact;
  final ChatMessageView? last;
  final Conversation? state;

  const _ChatSummary(this.contact, this.last, this.state);

  int get unread => state?.unreadCount ?? 0;
  bool get muted => state?.isMuted ?? false;
  bool get archived => state?.isArchived ?? false;
  bool get markedUnread => state?.markedUnread ?? false;
  bool get hasUnread => unread > 0 || markedUnread;
}

/// Conversations, newest first, with unread counts, mute and archive.
class ChatsPage extends StatefulWidget {
  final MeyaDatabase database;

  /// Opened from "Archived" to show only archived chats.
  final bool archived;

  /// Starts a new chat (provided by the app shell).
  final Future<void> Function(BuildContext context)? onNewChat;

  const ChatsPage({
    super.key,
    required this.database,
    this.archived = false,
    this.onNewChat,
  });

  @override
  State<ChatsPage> createState() => _ChatsPageState();
}

class _ChatsPageState extends State<ChatsPage> {
  final _service = MeyaMessageService.instance;
  List<_ChatSummary> _chats = [];
  bool _loading = true;
  StreamSubscription<String>? _subscription;

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
    final account = await AccountRepository(widget.database).getActiveAccount();
    final contacts = await ContactRepository(widget.database).getTrustedContacts(
      excludeIdentityId: account?.identityId ?? account?.accountId,
    );
    final states = await _service.conversationStates();
    final chats = <_ChatSummary>[];
    for (final contact in contacts) {
      ChatMessageView? last;
      try {
        final history = await _service.history(contact);
        if (history.isNotEmpty) last = history.last;
      } catch (_) {
        // A conversation that cannot be read still appears, without preview.
      }
      chats.add(_ChatSummary(
        contact,
        last,
        states[MessageRepository.conversationIdFor(contact.contactId)],
      ));
    }
    chats.sort((a, b) {
      final timeA = a.last?.createdAt;
      final timeB = b.last?.createdAt;
      if (timeA == null && timeB == null) {
        return a.contact.displayName
            .toLowerCase()
            .compareTo(b.contact.displayName.toLowerCase());
      }
      if (timeA == null) return 1;
      if (timeB == null) return -1;
      return timeB.compareTo(timeA);
    });
    if (!mounted) return;
    setState(() {
      _chats = chats;
      _loading = false;
    });
  }

  String _preview(_ChatSummary chat) {
    final message = chat.last;
    if (message == null) return context.tr('No messages yet');
    final prefix = message.isMine && !message.isDeleted ? context.tr('You: ') : '';
    final body = switch (message.kind) {
      'voice' => context.tr('🎤 Voice message'),
      'image' => message.text.isEmpty ? context.tr('📷 Photo') : '📷 ${message.text}',
      'video' => message.text.isEmpty ? context.tr('🎬 Video') : '🎬 ${message.text}',
      'file' => '📎 ${message.attachment?.name ?? 'File'}',
      'call_invite' => context.tr('📅 Call planned'),
      'call_cancel' => context.tr('📅 Call cancelled'),
      _ => message.preview,
    };
    return '$prefix$body';
  }

  String _time(DateTime time) {
    final now = DateTime.now();
    if (time.year == now.year && time.month == now.month && time.day == now.day) {
      return MaterialLocalizations.of(context).formatTimeOfDay(
        TimeOfDay.fromDateTime(time),
        alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
      );
    }
    return MaterialLocalizations.of(context).formatShortMonthDay(time);
  }

  Future<void> _open(Contact contact) async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => ChatPage(database: widget.database, contact: contact),
      ),
    );
    await _load();
  }

  Future<void> _actions(_ChatSummary chat) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (value, icon, label) in [
              chat.hasUnread
                  ? ('read', Icons.mark_chat_read_outlined, context.tr('Mark as read'))
                  : ('unread', Icons.mark_chat_unread_outlined, context.tr('Mark as unread')),
              chat.muted
                  ? ('unmute', Icons.notifications_active_outlined, context.tr('Unmute'))
                  : ('mute', Icons.notifications_off_outlined, context.tr('Mute notifications')),
              chat.archived
                  ? ('unarchive', Icons.unarchive_outlined, context.tr('Unarchive'))
                  : ('archive', Icons.archive_outlined, context.tr('Archive')),
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
    final contact = chat.contact;
    switch (choice) {
      case 'read':
        await _service.markConversationRead(contact);
      case 'unread':
        await _service.setMarkedUnread(contact, true);
      case 'mute':
        await _service.setMuted(contact, true);
      case 'unmute':
        await _service.setMuted(contact, false);
      case 'archive':
        await _service.setArchived(contact, true);
      case 'unarchive':
        await _service.setArchived(contact, false);
    }
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final visible = [
      for (final chat in _chats)
        if (chat.archived == widget.archived) chat,
    ];
    final archivedCount = _chats.where((chat) => chat.archived).length;
    final archivedUnread =
        _chats.where((chat) => chat.archived && chat.hasUnread).length;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.archived ? context.tr('Archived') : context.tr('Chats')),
        actions: [
          if (!widget.archived) ...[
            IconButton(
              tooltip: context.tr('Search messages'),
              icon: const Icon(Icons.search),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => MessageSearchPage(database: widget.database),
                ),
              ),
            ),
            IconButton(
              tooltip: context.tr('Favourites'),
              icon: const Icon(Icons.star_outline),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => MessageSearchPage(
                    database: widget.database,
                    favourites: true,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
      floatingActionButton: widget.archived || widget.onNewChat == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () async {
                await widget.onNewChat!(context);
                await _load();
              },
              icon: const Icon(Icons.add),
              label: Text(context.tr('New Chat')),
            ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                  children: [
                    if (!widget.archived && archivedCount > 0)
                      ListTile(
                        leading: const Icon(Icons.archive_outlined),
                        title: Text(context.tr('Archived')),
                        trailing: Text(
                          archivedUnread > 0
                              ? context.tr('{0} unread', [archivedUnread])
                              : '$archivedCount',
                        ),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => ChatsPage(
                                database: widget.database,
                                archived: true,
                              ),
                            ),
                          );
                          await _load();
                        },
                      ),
                    if (visible.isEmpty) ...[
                      const SizedBox(height: 48),
                      Icon(
                        widget.archived
                            ? Icons.archive_outlined
                            : Icons.chat_bubble_outline,
                        size: 48,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.archived
                            ? context.tr('No archived chats')
                            : context.tr('No conversations yet'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (!widget.archived) ...[
                        const SizedBox(height: 10),
                        Text(
                          context.tr('Add someone you trust by scanning their MEYA QR code. They will appear here.'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.5,
                            color: colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ] else
                      for (final chat in visible)
                        _ChatRow(
                          chat: chat,
                          preview: _preview(chat),
                          time: chat.last == null ? null : _time(chat.last!.createdAt),
                          onTap: () => _open(chat.contact),
                          onLongPress: () => _actions(chat),
                        ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _ChatRow extends StatelessWidget {
  final _ChatSummary chat;
  final String preview;
  final String? time;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _ChatRow({
    required this.chat,
    required this.preview,
    required this.time,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final name = chat.contact.displayName.trim().isEmpty
        ? context.tr('MEYA contact')
        : chat.contact.displayName.trim();
    final unreadLabel = chat.unread > 0
        ? context.tr('{0} unread', [chat.unread])
        : chat.markedUnread
            ? context.tr('Marked as unread')
            : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        child: Semantics(
          onLongPressHint: context.tr('Show chat options'),
          customSemanticsActions: {
            CustomSemanticsAction(label: context.tr('Chat options')): onLongPress,
          },
          child: ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            leading: CircleAvatar(
              radius: 24,
              backgroundColor: colorScheme.primary.withValues(alpha: 0.12),
              child: Text(
                name.substring(0, 1).toUpperCase(),
                style: TextStyle(
                  color: colorScheme.primary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            title: Row(
              children: [
                Flexible(
                  child: Text(
                    name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                if (chat.muted) ...[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.notifications_off_outlined,
                    size: 16,
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                    semanticLabel: context.tr('Muted'),
                  ),
                ],
              ],
            ),
            subtitle: Text(
              preview,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: chat.hasUnread
                  ? const TextStyle(fontWeight: FontWeight.w600)
                  : null,
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (time != null)
                  Text(
                    time!,
                    style: TextStyle(
                      fontSize: 12,
                      color: chat.hasUnread
                          ? colorScheme.primary
                          : colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                if (unreadLabel != null) ...[
                  const SizedBox(height: 4),
                  Semantics(
                    label: unreadLabel,
                    excludeSemantics: true,
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 22),
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: chat.muted
                            ? colorScheme.onSurface.withValues(alpha: 0.45)
                            : colorScheme.primary,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Text(
                        chat.unread > 0 ? '${chat.unread}' : '',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: colorScheme.onPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            onTap: onTap,
            onLongPress: onLongPress,
          ),
        ),
      ),
    );
  }
}

/// Searches every conversation, or lists Favourites. Decryption and
/// matching happen on this phone only.
class MessageSearchPage extends StatefulWidget {
  final MeyaDatabase database;
  final bool favourites;

  const MessageSearchPage({
    super.key,
    required this.database,
    this.favourites = false,
  });

  @override
  State<MessageSearchPage> createState() => _MessageSearchPageState();
}

class _MessageSearchPageState extends State<MessageSearchPage> {
  final _query = TextEditingController();
  List<(Contact, ChatMessageView)> _results = [];
  bool _busy = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    if (widget.favourites) _loadFavourites();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    super.dispose();
  }

  Future<void> _loadFavourites() async {
    setState(() => _busy = true);
    final results = await MeyaMessageService.instance.starredMessages();
    if (!mounted) return;
    setState(() {
      _results = results;
      _busy = false;
    });
  }

  void _search(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      setState(() => _busy = true);
      final results = await MeyaMessageService.instance.search(value);
      if (!mounted || value != _query.text) return;
      setState(() {
        _results = results;
        _busy = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: widget.favourites
            ? Text(context.tr('Favourites'))
            : TextField(
                controller: _query,
                autofocus: true,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: context.tr('Search messages'),
                  border: InputBorder.none,
                  filled: false,
                ),
                onChanged: _search,
              ),
      ),
      body: SafeArea(
        child: _busy && _results.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : _results.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        widget.favourites
                            ? context.tr('No favourites yet. Long-press a message and choose Add to favourites.')
                            : _query.text.trim().isEmpty
                                ? context.tr('Search words in all your chats. Searching happens on this phone only.')
                                : context.tr('No messages found.'),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: _results.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final (contact, message) = _results[index];
                      return ListTile(
                        leading: Icon(
                          message.starred ? Icons.star : Icons.chat_bubble_outline,
                        ),
                        title: Text(
                          message.preview,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          '${contact.displayName} · ${localizations.formatShortDate(message.createdAt)}',
                        ),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => ChatPage(
                              database: widget.database,
                              contact: contact,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
