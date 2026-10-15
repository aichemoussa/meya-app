import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/contact_repository.dart';
import '../database/meya_database.dart';
import '../database/message_repository.dart';
import 'device_identity_service.dart';
import 'meya_blob_store.dart';
import 'meya_e2ee.dart';
import 'meya_relay_session.dart';
import '../l10n/meya_strings.dart';

/// An encrypted attachment (photo, video, file or status media).
class AttachmentRef {
  final String blobId;

  /// The file's own AES-256 key. Only ever stored inside encrypted content.
  final Uint8List key;
  final String mime;
  final String name;
  final int size;

  /// 'local' for files sent from this device, otherwise the sender's device.
  final String owner;

  /// A small JPEG preview (videos), sent inside the encrypted message.
  final Uint8List? thumbnail;

  /// Largest preview accepted from a contact.
  static const int maxThumbnailBytes = 64 * 1024;

  const AttachmentRef({
    required this.blobId,
    required this.key,
    required this.mime,
    required this.name,
    required this.size,
    required this.owner,
    this.thumbnail,
  });

  Map<String, Object> toContent() => {
        'blob_id': blobId,
        'key': base64Encode(key),
        'mime': mime,
        'name': name,
        'size': size,
        if (thumbnail != null) 'thumb': base64Encode(thumbnail!),
      };

  /// Reads attachment fields from decrypted content; null when malformed.
  static AttachmentRef? fromContent(Map<String, dynamic> content, String owner) {
    final blobId = content['blob_id'];
    final key = content['key'];
    final mime = content['mime'];
    final size = content['size'];
    final name = content['name'];
    if (blobId is! String || !MeyaBlobStore.isValidBlobId(blobId)) return null;
    if (key is! String || mime is! String || size is! int) return null;
    final Uint8List keyBytes;
    try {
      keyBytes = base64Decode(key);
    } catch (_) {
      return null;
    }
    if (keyBytes.length != 32 || size < 0) return null;
    Uint8List? thumbnail;
    final thumb = content['thumb'];
    if (thumb is String && thumb.length <= maxThumbnailBytes * 4 ~/ 3 + 4) {
      try {
        thumbnail = base64Decode(thumb);
      } catch (_) {
        thumbnail = null;
      }
    }
    return AttachmentRef(
      blobId: blobId,
      key: keyBytes,
      mime: mime,
      name: name is String && name.isNotEmpty ? name : 'file',
      size: size,
      owner: owner,
      thumbnail: thumbnail,
    );
  }
}

/// A planned call, shared with the other person through an encrypted
/// message.
class CallPlan {
  final String eventId;
  final String title;
  final DateTime start;
  final int durationMinutes;

  /// 'voice' or 'video'.
  final String callType;
  final String note;

  const CallPlan({
    required this.eventId,
    required this.title,
    required this.start,
    required this.durationMinutes,
    required this.callType,
    required this.note,
  });

  Map<String, Object> toContent() => {
        'event_id': eventId,
        'title': title,
        'start': start.toUtc().toIso8601String(),
        'duration_min': durationMinutes,
        'call_type': callType,
        'note': note,
      };

  static CallPlan? fromContent(Map<String, dynamic> content) {
    final eventId = content['event_id'];
    final title = content['title'];
    final start = content['start'];
    final duration = content['duration_min'];
    final callType = content['call_type'];
    final note = content['note'];
    if (eventId is! String || eventId.isEmpty || eventId.length > 64) {
      return null;
    }
    if (title is! String || start is! String || duration is! int) return null;
    if (callType != 'voice' && callType != 'video') return null;
    final parsed = DateTime.tryParse(start);
    if (parsed == null || duration < 5 || duration > 24 * 60) return null;
    return CallPlan(
      eventId: eventId,
      title: title.length > 120 ? title.substring(0, 120) : title,
      start: parsed.toLocal(),
      durationMinutes: duration,
      callType: callType as String,
      note: note is String
          ? (note.length > 500 ? note.substring(0, 500) : note)
          : '',
    );
  }
}

/// One message as shown in a conversation.
/// The message a reply quotes, as it was when the reply was written.
class ChatReply {
  final String id;
  final String kind;
  final String text;
  final bool isMine;

  const ChatReply({
    required this.id,
    required this.kind,
    required this.text,
    required this.isMine,
  });
}

class ChatMessageView {
  final String id;

  /// text, voice, image, video, file, call_invite, call_cancel or deleted.
  final String kind;
  final String text;
  final bool isMine;
  final DateTime createdAt;

  /// queued, sending, sent, delivered, read, failed (mine) or received.
  final String state;

  /// Voice messages only: the recording (AAC in MP4) and its length.
  final Uint8List? audio;
  final int durationMs;

  /// Photos, videos and files.
  final AttachmentRef? attachment;

  /// Call invitations and cancellations.
  final CallPlan? call;

  final ChatReply? reply;
  final bool forwarded;
  final bool edited;
  final bool starred;
  final bool pinned;

  /// Emoji → number of people who reacted with it.
  final Map<String, int> reactions;

  /// This device's own reaction, if any.
  final String? myReaction;

  const ChatMessageView({
    required this.id,
    required this.kind,
    required this.text,
    required this.isMine,
    required this.createdAt,
    required this.state,
    this.audio,
    this.durationMs = 0,
    this.attachment,
    this.call,
    this.reply,
    this.forwarded = false,
    this.edited = false,
    this.starred = false,
    this.pinned = false,
    this.reactions = const {},
    this.myReaction,
  });

  bool get isDeleted => kind == 'deleted';

  /// A short description for quotes, search results and the chats list.
  String get preview => switch (kind) {
        'voice' => tr('Voice message'),
        'image' => text.isEmpty ? tr('Photo') : text,
        'video' => text.isEmpty ? tr('Video') : text,
        'file' => attachment?.name ?? tr('File'),
        'deleted' => tr('This message was deleted'),
        _ => text,
      };
}

/// Handles content that is not shown in a conversation (status updates,
/// profile updates).
typedef SilentHandler = Future<void> Function(
  Contact contact,
  String senderDeviceId,
  Map<String, dynamic> content,
);

typedef CallPlanHandler = Future<void> Function(
  Contact contact,
  String kind,
  CallPlan plan,
);

/// Sends and receives end-to-end encrypted messages.
///
/// Relay payloads (the relay only ever sees ciphertext):
///   {"type": "chat", "v": 1, "message_type": 2|3, "body": base64}
///       a Signal (Triple Ratchet) message;
///   {"type": "blob", "v": 1, "blob_id", "index", "count", "data": base64}
///       one piece of an attachment encrypted with its own random key.
///
/// The decrypted content of a chat message is JSON with a "kind":
///   text, voice, image, video, file   shown in the conversation;
///   call_invite, call_cancel          shown and added to the calendar;
///   status, status_clear, profile     status and profile updates;
///   session_init                      starts the session, not shown.
/// Attachment keys travel only inside these encrypted messages.
class MeyaMessageService {
  /// Largest voice recording accepted (bytes of audio). The relay accepts
  /// envelopes up to 1 MiB; base64 twice plus JSON stays well below that.
  static const int maxVoiceBytes = 500 * 1024;

  /// Longest voice recording offered by the recorder.
  static const Duration maxVoiceDuration = Duration(minutes: 2);

  /// Largest photo, video or file (encryption adds 29 bytes).
  static const int maxAttachmentBytes = MeyaBlobStore.maxBlobBytes - 64;

  static const Set<String> shownKinds = {
    'text',
    'voice',
    'image',
    'video',
    'file',
    'call_invite',
    'call_cancel',
  };

  MeyaMessageService._();

  static final MeyaMessageService instance = MeyaMessageService._();

  MeyaDatabase? _database;
  E2eeOperations _e2ee = MeyaE2ee.instance;
  BlobCipher _cipher = const RustBlobCipher();
  Future<String?> Function() _localDeviceId = DeviceIdentityService.getDeviceId;
  Future<void> Function(Map<String, dynamic> message) _send =
      (message) => MeyaRelaySession.instance.sendWhenConnected(message: message);

  final Map<String, SilentHandler> _silentHandlers = {};
  CallPlanHandler? _onCallPlan;

  final StreamController<String> _changes = StreamController.broadcast();
  final StreamController<String> _mediaArrived = StreamController.broadcast();
  final StreamController<String> _received = StreamController.broadcast();
  final Map<String, Uint8List> _plainCache = {};

  /// Control messages: not shown, they change messages already shown.
  static const Set<String> controlKinds = {
    'receipt',
    'reaction',
    'edit',
    'delete',
    'pin',
  };

  /// The conversation open on screen. Its incoming messages are read at once.
  String? activeConversationId;

  static const _readReceiptsKey = 'meya_read_receipts';
  bool _readReceipts = true;
  bool _retrying = false;

  /// When off, this device sends no read receipts and shows none.
  bool get readReceipts => _readReceipts;

  Future<void> loadSettings() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      _readReceipts = preferences.getBool(_readReceiptsKey) ?? true;
    } catch (error) {
      debugPrint('MEYA chat settings: using defaults ($error).');
    }
  }

  Future<void> setReadReceipts(bool value) async {
    _readReceipts = value;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_readReceiptsKey, value);
  }

  /// Emits a conversation ID whenever that conversation changes.
  Stream<String> get changes => _changes.stream;

  /// Emits a conversation ID when a new message from a contact is saved.
  Stream<String> get received => _received.stream;

  /// Emits a blob ID when an attachment has fully arrived.
  Stream<String> get mediaArrived => _mediaArrived.stream;

  void configure({required MeyaDatabase database}) {
    _database = database;
  }

  /// Registers who handles a content kind that is not shown in chats.
  void setSilentHandler(String kind, SilentHandler handler) {
    _silentHandlers[kind] = handler;
  }

  void setCallPlanHandler(CallPlanHandler handler) {
    _onCallPlan = handler;
  }

  @visibleForTesting
  void configureForTesting({
    required MeyaDatabase database,
    required E2eeOperations e2ee,
    required Future<String?> Function() localDeviceId,
    required Future<void> Function(Map<String, dynamic> message) send,
    BlobCipher? cipher,
  }) {
    _database = database;
    _e2ee = e2ee;
    _localDeviceId = localDeviceId;
    _send = send;
    if (cipher != null) _cipher = cipher;
    _silentHandlers.clear();
    _onCallPlan = null;
    _plainCache.clear();
  }

  MeyaDatabase get _db {
    final database = _database;
    if (database == null) {
      throw StateError(tr('MEYA messaging is not configured.'));
    }
    return database;
  }

  static String newId() {
    final random = Random.secure();
    return List<int>.generate(16, (_) => random.nextInt(256))
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
  }

  /// True when an encrypted session exists with this contact's device.
  Future<bool> canMessage(Contact contact) async {
    final deviceId =
        await ContactRepository(_db).getDeviceIdForContact(contact.contactId);
    if (deviceId == null) return false;
    try {
      return await _e2ee.hasSession(deviceId);
    } catch (_) {
      return false;
    }
  }

  Future<(String deviceId, String localDeviceId)> _devices(
    Contact contact,
  ) async {
    final deviceId = await ContactRepository(_db)
        .getDeviceIdForContact(contact.contactId);
    if (deviceId == null) {
      throw StateError(
        tr('Encrypted messaging is not set up with this person yet. Scan their QR code again.'),
      );
    }
    final localDeviceId = await _localDeviceId();
    if (localDeviceId == null || localDeviceId.isEmpty) {
      throw StateError(tr('This device has no MEYA device ID.'));
    }
    return (deviceId, localDeviceId);
  }

  // ------------------------------------------------------------------ send

  /// [extra] carries `reply_to` and `forwarded` (see [replyFields]).
  Future<void> sendText(
    Contact contact,
    String text, {
    Map<String, Object> extra = const {},
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    await _sendContent(contact, {'kind': 'text', 'text': trimmed, ...extra});
  }

  Future<void> sendVoice(
    Contact contact,
    Uint8List audio, {
    required int durationMs,
    String mime = 'audio/mp4',
    Map<String, Object> extra = const {},
  }) async {
    if (audio.isEmpty) {
      throw StateError(tr('The voice message is empty.'));
    }
    if (audio.length > maxVoiceBytes) {
      throw StateError(
        tr('This voice message is too long. Keep it under {0} minutes.', [maxVoiceDuration.inMinutes]),
      );
    }
    await _sendContent(contact, {
      'kind': 'voice',
      'audio': base64Encode(audio),
      'mime': mime,
      'duration_ms': durationMs,
      ...extra,
    });
  }

  /// Sends a photo ('image'), video ('video') or any file ('file').
  Future<void> sendAttachment(
    Contact contact, {
    required String kind,
    required Uint8List bytes,
    required String mime,
    required String name,
    String caption = '',
    Uint8List? thumbnail,
    Map<String, Object> extra = const {},
  }) async {
    if (kind != 'image' && kind != 'video' && kind != 'file') {
      throw ArgumentError.value(kind, 'kind');
    }
    if (bytes.isEmpty) throw StateError(tr('The file is empty.'));
    if (bytes.length > maxAttachmentBytes) {
      throw StateError(
        tr('This file is too large. MEYA can send files up to {0} MB.', [maxAttachmentBytes ~/ (1024 * 1024)]),
      );
    }

    final attachment = await _encryptToStore(bytes, mime: mime, name: name);
    final ciphertext =
        await MeyaBlobStore.instance.read('local', attachment.blobId);

    await _sendContent(
      contact,
      {
        'kind': kind,
        ...attachment.toContent(),
        if (thumbnail != null &&
            thumbnail.length <= AttachmentRef.maxThumbnailBytes)
          'thumb': base64Encode(thumbnail),
        ...extra,
        if (caption.trim().isNotEmpty) 'text': caption.trim(),
      },
      beforeSend: (from, to) => sendBlob(
        from: from,
        to: to,
        blobId: attachment.blobId,
        ciphertext: ciphertext,
      ),
    );
  }

  /// Encrypts [bytes] with a fresh key and keeps the ciphertext on this
  /// device. Used for chat attachments and status media.
  Future<AttachmentRef> _encryptToStore(
    Uint8List bytes, {
    required String mime,
    required String name,
  }) async {
    final blobId = MeyaBlobStore.newBlobId();
    final key = MeyaBlobStore.newKey();
    final ciphertext = await _cipher.seal(key, bytes, blobId);
    await MeyaBlobStore.instance.write('local', blobId, ciphertext);
    _plainCache[blobId] = bytes;
    return AttachmentRef(
      blobId: blobId,
      key: key,
      mime: mime,
      name: name,
      size: bytes.length,
      owner: 'local',
    );
  }

  Future<AttachmentRef> encryptMedia(
    Uint8List bytes, {
    required String mime,
    required String name,
  }) =>
      _encryptToStore(bytes, mime: mime, name: name);

  /// Sends the encrypted pieces of an attachment to one device.
  Future<void> sendBlob({
    required String from,
    required String to,
    required String blobId,
    required Uint8List ciphertext,
  }) async {
    final chunks = MeyaBlobStore.split(ciphertext);
    for (var index = 0; index < chunks.length; index++) {
      final payload = jsonEncode({
        'type': 'blob',
        'v': 1,
        'blob_id': blobId,
        'index': index,
        'count': chunks.length,
        'data': base64Encode(chunks[index]),
      });
      await _send({
        'type': 'Send',
        'envelope': {
          // Unique per recipient: the relay ignores repeated envelope IDs.
          'id': '${blobId}_${index}_$to',
          'sender_device_id': from,
          'recipient_device_id': to,
          'payload': base64Encode(utf8.encode(payload)),
        },
      });
    }
  }

  Future<void> sendCallPlan(Contact contact, CallPlan plan) =>
      _sendContent(contact, {'kind': 'call_invite', ...plan.toContent()});

  Future<void> sendCallCancel(Contact contact, CallPlan plan) =>
      _sendContent(contact, {'kind': 'call_cancel', ...plan.toContent()});

  /// Sends content that is not shown in the conversation (status updates).
  Future<void> sendSilent(
    Contact contact,
    Map<String, Object> fields, {
    AttachmentRef? media,
  }) async {
    final (deviceId, localDeviceId) = await _devices(contact);
    if (media != null) {
      final ciphertext = await MeyaBlobStore.instance.read('local', media.blobId);
      await sendBlob(
        from: localDeviceId,
        to: deviceId,
        blobId: media.blobId,
        ciphertext: ciphertext,
      );
    }
    final id = newId();
    final content = Uint8List.fromList(
      utf8.encode(
        jsonEncode({
          'v': 1,
          ...fields,
          if (media != null) 'media': media.toContent(),
          'id': id,
          'sent_at': DateTime.now().toUtc().toIso8601String(),
        }),
      ),
    );
    final ciphertext = await _e2ee.encrypt(deviceId, content);
    await _send(_envelope(id, localDeviceId, deviceId, ciphertext));
  }

  Future<void> _sendContent(
    Contact contact,
    Map<String, Object> fields, {
    Future<void> Function(String from, String to)? beforeSend,
  }) async {
    final database = _db;
    final (deviceId, localDeviceId) = await _devices(contact);

    final messageId = newId();
    final now = DateTime.now().toUtc().toIso8601String();
    final content = Uint8List.fromList(
      utf8.encode(
        jsonEncode({
          'v': 1,
          ...fields,
          'id': messageId,
          'sent_at': now,
        }),
      ),
    );

    final ciphertext = await _e2ee.encrypt(deviceId, content);
    final sealed = await _e2ee.sealLocal(content, messageId);
    final conversationId =
        await MessageRepository(database).ensureDirectConversation(contact.contactId);

    await MessageRepository(database).insert(
      messageId: messageId,
      conversationId: conversationId,
      senderDeviceId: localDeviceId,
      createdAt: now,
      wireCiphertext: ciphertext.body,
      localSealed: sealed,
      deliveryState: 'sending',
    );
    _changes.add(conversationId);

    try {
      await beforeSend?.call(localDeviceId, deviceId);
      await _send(_envelope(messageId, localDeviceId, deviceId, ciphertext));
      await MessageRepository(database).advanceDeliveryState(messageId, 'sent');
    } catch (error) {
      // Offline or the relay dropped: [retryPending] sends it again when the
      // relay reconnects. The message ID stays the same, so the other phone
      // never shows it twice.
      debugPrint('MEYA chat: queued for retry ($error).');
      await MessageRepository(database).updateDeliveryState(messageId, 'queued');
    }
    _changes.add(conversationId);
  }

  /// Sends a control message (receipt, reaction, edit, deletion or pin).
  /// While offline it waits in the encrypted outbox for [retryPending].
  Future<void> _sendControl(Contact contact, Map<String, Object> fields) async {
    try {
      await sendSilent(contact, fields);
    } catch (error) {
      final id = newId();
      final sealed = await _e2ee.sealLocal(
        Uint8List.fromList(utf8.encode(jsonEncode(fields))),
        'outbox:$id',
      );
      await _db.into(_db.outbox).insert(
            OutboxCompanion.insert(
              outboxId: id,
              contactId: contact.contactId,
              sealedFields: sealed,
              createdAt: DateTime.now().toUtc().toIso8601String(),
            ),
          );
    }
  }

  /// Sends everything that could not go out while offline: queued control
  /// messages first, then messages that are still queued or failed.
  /// Called whenever the relay (re)connects.
  Future<int> retryPending() async {
    if (_retrying) return 0;
    _retrying = true;
    var sentCount = 0;
    try {
      final database = _db;
      final contacts = ContactRepository(database);

      final waiting = await (database.select(database.outbox)
            ..orderBy([(o) => OrderingTerm(expression: o.createdAt)]))
          .get();
      for (final item in waiting) {
        final contact = await contacts.getContactById(item.contactId);
        try {
          if (contact == null || contact.trustState != 'trusted') {
            throw StateError('contact gone');
          }
          final fields = jsonDecode(utf8.decode(
            await _e2ee.openLocal(item.sealedFields, 'outbox:${item.outboxId}'),
          )) as Map<String, dynamic>;
          await sendSilent(contact, fields.cast<String, Object>());
          await (database.delete(database.outbox)
                ..where((o) => o.outboxId.equals(item.outboxId)))
              .go();
          sentCount++;
        } catch (error) {
          if (contact == null || item.attempts >= 20) {
            await (database.delete(database.outbox)
                  ..where((o) => o.outboxId.equals(item.outboxId)))
                .go();
          } else {
            await (database.update(database.outbox)
                  ..where((o) => o.outboxId.equals(item.outboxId)))
                .write(OutboxCompanion(attempts: Value(item.attempts + 1)));
            return sentCount; // Still offline: try again on the next connect.
          }
        }
      }

      final localDeviceId = await _localDeviceId();
      final pending = await (database.select(database.messages)
            ..where((m) =>
                m.senderDeviceId.equals(localDeviceId ?? '') &
                m.deliveryState.isIn(['queued', 'sending', 'failed']) &
                m.isDeleted.equals(false))
            ..orderBy([(m) => OrderingTerm(expression: m.createdAt)]))
          .get();
      for (final row in pending) {
        final contactId = row.conversationId.replaceFirst('direct_', '');
        final contact = await contacts.getContactById(contactId);
        if (contact == null || row.localDisplayCiphertext == null) continue;
        if (row.deliveryState == 'failed' && row.retryCount >= 5) continue;
        try {
          await _resend(contact, row);
          sentCount++;
        } catch (error) {
          await (database.update(database.messages)
                ..where((m) => m.messageId.equals(row.messageId)))
              .write(MessagesCompanion(
            retryCount: Value(row.retryCount + 1),
            deliveryState: Value(row.retryCount + 1 >= 5 ? 'failed' : 'queued'),
          ));
          _changes.add(row.conversationId);
          return sentCount;
        }
      }
      return sentCount;
    } finally {
      _retrying = false;
    }
  }

  /// Sends a stored message again with the same ID, re-encrypted.
  Future<void> _resend(Contact contact, Message row) async {
    final (deviceId, localDeviceId) = await _devices(contact);
    final content = await _e2ee.openLocal(
      row.localDisplayCiphertext!,
      row.messageId,
    );
    final decoded = jsonDecode(utf8.decode(content));
    if (decoded is Map<String, dynamic>) {
      final attachment = AttachmentRef.fromContent(decoded, 'local');
      if (attachment != null &&
          await MeyaBlobStore.instance.exists('local', attachment.blobId)) {
        await sendBlob(
          from: localDeviceId,
          to: deviceId,
          blobId: attachment.blobId,
          ciphertext:
              await MeyaBlobStore.instance.read('local', attachment.blobId),
        );
      }
    }
    final ciphertext = await _e2ee.encrypt(deviceId, content);
    await _send(_envelope(row.messageId, localDeviceId, deviceId, ciphertext));
    await MessageRepository(_db).advanceDeliveryState(row.messageId, 'sent');
    _changes.add(row.conversationId);
  }

  /// Retries one message now (the "tap to retry" on a failed message).
  Future<void> retryMessage(Contact contact, String messageId) async {
    final row = await MessageRepository(_db).get(messageId);
    if (row == null) return;
    await (_db.update(_db.messages)..where((m) => m.messageId.equals(messageId)))
        .write(const MessagesCompanion(retryCount: Value(0)));
    try {
      await _resend(contact, row);
    } catch (error) {
      await MessageRepository(_db).updateDeliveryState(messageId, 'queued');
      _changes.add(row.conversationId);
      rethrow;
    }
  }

  /// Sent automatically by the person who scanned the QR code, right after
  /// the session starts, so the other person can reply straight away.
  Future<void> sendSessionInit(String deviceId) async {
    final localDeviceId = await _localDeviceId();
    if (localDeviceId == null || localDeviceId.isEmpty) return;

    final id = newId();
    final content = Uint8List.fromList(
      utf8.encode(jsonEncode({'v': 1, 'kind': 'session_init', 'id': id})),
    );
    final ciphertext = await _e2ee.encrypt(deviceId, content);
    await _send(_envelope(id, localDeviceId, deviceId, ciphertext));
  }

  Map<String, dynamic> _envelope(
    String id,
    String from,
    String to,
    E2eeCiphertext ciphertext,
  ) {
    final payload = jsonEncode({
      'type': 'chat',
      'v': 1,
      'message_type': ciphertext.messageType,
      'body': base64Encode(ciphertext.body),
    });
    return {
      'type': 'Send',
      'envelope': {
        'id': id,
        'sender_device_id': from,
        'recipient_device_id': to,
        'payload': base64Encode(utf8.encode(payload)),
      },
    };
  }

  // --------------------------------------------------------------- receive

  /// Handles one piece of an attachment from [senderDeviceId].
  Future<void> handleBlobChunk(
    String senderDeviceId,
    Map<String, dynamic> payload,
  ) async {
    final contact =
        await ContactRepository(_db).getContactByDeviceId(senderDeviceId);
    if (contact == null) {
      debugPrint('MEYA media: piece from an unknown device was dropped.');
      return;
    }
    final blobId = payload['blob_id'];
    final index = payload['index'];
    final count = payload['count'];
    final data = payload['data'];
    if (blobId is! String || index is! int || count is! int || data is! String) {
      debugPrint('MEYA media: malformed piece was dropped.');
      return;
    }
    final complete = await MeyaBlobStore.instance.addChunk(
      owner: senderDeviceId,
      blobId: blobId,
      index: index,
      count: count,
      data: base64Decode(data),
    );
    if (complete) {
      _mediaArrived.add(blobId);
      _changes.add(MessageRepository.conversationIdFor(contact.contactId));
    }
  }

  /// Handles a `chat` payload from [senderDeviceId] (authenticated by the
  /// relay). Unknown senders and undecryptable messages are dropped.
  Future<void> handleIncoming(
    String senderDeviceId,
    Map<String, dynamic> payload,
  ) async {
    final database = _db;
    final contact =
        await ContactRepository(database).getContactByDeviceId(senderDeviceId);
    if (contact == null) {
      debugPrint('MEYA chat: message from an unknown device was dropped.');
      return;
    }

    final messageType = payload['message_type'];
    final body = payload['body'];
    if (messageType is! int || body is! String) {
      debugPrint('MEYA chat: malformed message was dropped.');
      return;
    }

    final plaintext = await _e2ee.decrypt(
      senderDeviceId,
      messageType,
      base64Decode(body),
    );

    final content = jsonDecode(utf8.decode(plaintext));
    if (content is! Map<String, dynamic>) return;

    final kind = content['kind'];
    final conversationId =
        MessageRepository.conversationIdFor(contact.contactId);
    if (kind == 'session_init') {
      // The session now exists on this side too: let open screens refresh.
      _changes.add(conversationId);
      await _silentHandlers['session_init']?.call(
        contact,
        senderDeviceId,
        content,
      );
      return;
    }
    if (controlKinds.contains(kind)) {
      await _handleControl(contact, senderDeviceId, content);
      return;
    }
    final silent = _silentHandlers[kind];
    if (silent != null) {
      await silent(contact, senderDeviceId, content);
      return;
    }

    final id = content['id'];
    if (id is! String || id.isEmpty || id.length > 64) return;
    if (!_isValidShownContent(kind, content, senderDeviceId)) return;

    final messages = MessageRepository(database);
    if (await messages.exists(id)) return;

    await messages.ensureDirectConversation(contact.contactId);
    final sealed = await _e2ee.sealLocal(plaintext, id);
    await messages.insert(
      messageId: id,
      conversationId: conversationId,
      senderDeviceId: senderDeviceId,
      createdAt: DateTime.now().toUtc().toIso8601String(),
      wireCiphertext: base64Decode(body),
      localSealed: sealed,
      deliveryState: 'received',
    );

    if (kind == 'call_invite' || kind == 'call_cancel') {
      final plan = CallPlan.fromContent(content);
      if (plan != null) await _onCallPlan?.call(contact, kind as String, plan);
    }

    if (activeConversationId == conversationId) {
      await markConversationRead(contact);
    } else {
      await messages.incrementUnread(conversationId);
    }
    // Delivered receipts are always sent: they reveal nothing beyond what the
    // relay already knows. Read receipts follow the privacy setting.
    unawaited(_sendControl(contact, {
      'kind': 'receipt',
      'status': 'delivered',
      'ids': [id],
    }));
    _changes.add(conversationId);
    _received.add(conversationId);
  }

  /// Applies a receipt, reaction, edit, deletion or pin from [contact].
  /// Each one must refer to a message in the conversation with [contact];
  /// edits and deletions must come from the message's author.
  Future<void> _handleControl(
    Contact contact,
    String senderDeviceId,
    Map<String, dynamic> content,
  ) async {
    final repository = MessageRepository(_db);
    final conversationId =
        MessageRepository.conversationIdFor(contact.contactId);
    final localDeviceId = await _localDeviceId();

    Future<Message?> target() async {
      final id = content['target'];
      if (id is! String || id.isEmpty || id.length > 64) return null;
      final row = await repository.get(id);
      if (row == null || row.conversationId != conversationId) return null;
      return row;
    }

    switch (content['kind']) {
      case 'receipt':
        final ids = content['ids'];
        var status = content['status'];
        if (ids is! List || (status != 'delivered' && status != 'read')) return;
        // With read receipts off, the other person's read receipts are not
        // shown either.
        if (status == 'read' && !_readReceipts) status = 'delivered';
        var changed = false;
        for (final id in ids.take(500)) {
          if (id is! String) continue;
          final row = await repository.get(id);
          if (row == null ||
              row.conversationId != conversationId ||
              row.senderDeviceId != localDeviceId) {
            continue;
          }
          changed |= await repository.advanceDeliveryState(id, status as String);
        }
        if (changed) _changes.add(conversationId);
      case 'reaction':
        final row = await target();
        final emoji = content['emoji'];
        if (row == null || emoji is! String || emoji.length > 16) return;
        await repository.setReaction(row.messageId, senderDeviceId, emoji);
        _changes.add(conversationId);
      case 'pin':
        final row = await target();
        final pinned = content['pinned'];
        if (row == null || pinned is! bool) return;
        await repository.setFlags(row.messageId, pinned: pinned);
        _changes.add(conversationId);
      case 'edit':
        final row = await target();
        final text = content['text'];
        if (row == null ||
            row.senderDeviceId != senderDeviceId ||
            row.isDeleted ||
            text is! String ||
            text.trim().isEmpty) {
          return;
        }
        await _applyEdit(row, text.trim());
        _changes.add(conversationId);
      case 'delete':
        final row = await target();
        if (row == null || row.senderDeviceId != senderDeviceId) return;
        await _applyDelete(row);
        _changes.add(conversationId);
    }
  }

  Future<Map<String, dynamic>?> _openContent(Message row) async {
    final sealed = row.localDisplayCiphertext;
    if (sealed == null) return null;
    final decoded =
        jsonDecode(utf8.decode(await _e2ee.openLocal(sealed, row.messageId)));
    return decoded is Map<String, dynamic> ? decoded : null;
  }

  Future<void> _applyEdit(Message row, String text) async {
    final content = await _openContent(row);
    if (content == null) return;
    final kind = content['kind'];
    if (kind != 'text' && kind != 'image' && kind != 'video' && kind != 'file') {
      return;
    }
    content['text'] = text;
    content['edited'] = true;
    final sealed = await _e2ee.sealLocal(
      Uint8List.fromList(utf8.encode(jsonEncode(content))),
      row.messageId,
    );
    await MessageRepository(_db).setFlags(
      row.messageId,
      sealed: sealed,
      editedAt: DateTime.now().toUtc().toIso8601String(),
    );
  }

  /// Replaces the message with a "deleted" marker and removes its media.
  Future<void> _applyDelete(Message row) async {
    final content = await _openContent(row);
    if (content != null) {
      final owner = row.senderDeviceId == await _localDeviceId()
          ? 'local'
          : row.senderDeviceId;
      final attachment = AttachmentRef.fromContent(content, owner);
      if (attachment != null) {
        await MeyaBlobStore.instance.delete(owner, attachment.blobId);
        _plainCache.remove(attachment.blobId);
      }
    }
    final sealed = await _e2ee.sealLocal(
      Uint8List.fromList(
        utf8.encode(jsonEncode({'v': 1, 'kind': 'deleted', 'id': row.messageId})),
      ),
      row.messageId,
    );
    final repository = MessageRepository(_db);
    await repository.setFlags(
      row.messageId,
      sealed: sealed,
      deleted: true,
      pinned: false,
      starred: false,
    );
    await repository.clearReactions(row.messageId);
  }

  static bool _isValidShownContent(
    Object? kind,
    Map<String, dynamic> content,
    String owner,
  ) {
    switch (kind) {
      case 'text':
        return content['text'] is String;
      case 'voice':
        final audio = content['audio'];
        return audio is String && audio.isNotEmpty;
      case 'image':
      case 'video':
      case 'file':
        return AttachmentRef.fromContent(content, owner) != null;
      case 'call_invite':
      case 'call_cancel':
        return CallPlan.fromContent(content) != null;
      default:
        return false;
    }
  }

  Future<List<ChatMessageView>> history(Contact contact) async {
    final database = _db;
    final localDeviceId = await _localDeviceId();
    final repository = MessageRepository(database);
    final rows = await repository.listMessages(
      MessageRepository.conversationIdFor(contact.contactId),
    );

    final reactionsByMessage = <String, List<Reaction>>{};
    for (final reaction
        in await repository.reactionsFor(rows.map((row) => row.messageId))) {
      reactionsByMessage.putIfAbsent(reaction.messageId, () => []).add(reaction);
    }

    final views = <ChatMessageView>[];
    for (final row in rows) {
      final sealed = row.localDisplayCiphertext;
      if (sealed == null) continue;
      try {
        final content = jsonDecode(
          utf8.decode(await _e2ee.openLocal(sealed, row.messageId)),
        );
        if (content is! Map<String, dynamic>) continue;
        final kind = content['kind'];
        if (kind is! String) continue;
        final isMine = row.senderDeviceId == localDeviceId;
        final owner = isMine ? 'local' : row.senderDeviceId;
        final text = content['text'];

        final counts = <String, int>{};
        String? mine;
        for (final reaction in reactionsByMessage[row.messageId] ?? const []) {
          counts[reaction.emoji] = (counts[reaction.emoji] ?? 0) + 1;
          if (reaction.reactorDeviceId == localDeviceId) mine = reaction.emoji;
        }

        ChatReply? reply;
        final quoted = content['reply_to'];
        if (quoted is Map<String, dynamic> &&
            quoted['id'] is String &&
            quoted['kind'] is String) {
          final quotedText = quoted['text'];
          reply = ChatReply(
            id: quoted['id'] as String,
            kind: quoted['kind'] as String,
            text: quotedText is String ? quotedText : '',
            // The author is a device ID as seen by the sender of the reply.
            isMine: quoted['author'] == localDeviceId,
          );
        }

        ChatMessageView view({
          required String kind,
          required String text,
          Uint8List? audio,
          int durationMs = 0,
          AttachmentRef? attachment,
          CallPlan? call,
        }) =>
            ChatMessageView(
              id: row.messageId,
              kind: kind,
              text: text,
              isMine: isMine,
              createdAt:
                  DateTime.tryParse(row.createdAt)?.toLocal() ?? DateTime.now(),
              state: row.deliveryState,
              audio: audio,
              durationMs: durationMs,
              attachment: attachment,
              call: call,
              reply: reply,
              forwarded: content['forwarded'] == true,
              edited: row.editedAt != null || content['edited'] == true,
              starred: row.isStarred,
              pinned: row.isPinned,
              reactions: counts,
              myReaction: mine,
            );

        switch (kind) {
          case 'deleted':
            views.add(view(kind: 'deleted', text: tr('This message was deleted')));
          case 'voice':
            final audio = content['audio'];
            if (audio is! String) continue;
            final duration = content['duration_ms'];
            views.add(view(
              kind: 'voice',
              text: tr('Voice message'),
              audio: base64Decode(audio),
              durationMs: duration is int ? duration : 0,
            ));
          case 'image':
          case 'video':
          case 'file':
            final attachment = AttachmentRef.fromContent(content, owner);
            if (attachment == null) continue;
            views.add(view(
              kind: kind,
              text: text is String ? text : '',
              attachment: attachment,
            ));
          case 'call_invite':
          case 'call_cancel':
            final plan = CallPlan.fromContent(content);
            if (plan == null) continue;
            views.add(view(kind: kind, text: plan.title, call: plan));
          case 'text':
            if (text is! String) continue;
            views.add(view(kind: 'text', text: text));
        }
      } catch (error) {
        debugPrint('MEYA chat: a stored message could not be opened.');
      }
    }
    return views;
  }

  /// True when the attachment's encrypted file is on this device.
  Future<bool> hasAttachment(AttachmentRef ref) =>
      MeyaBlobStore.instance.exists(ref.owner, ref.blobId);

  /// Decrypts an attachment into memory.
  Future<Uint8List> openAttachment(AttachmentRef ref) async {
    final cached = _plainCache[ref.blobId];
    if (cached != null) return cached;
    final ciphertext = await MeyaBlobStore.instance.read(ref.owner, ref.blobId);
    final plaintext = await _cipher.open(ref.key, ciphertext, ref.blobId);
    if (plaintext.length <= 8 * 1024 * 1024) {
      if (_plainCache.length >= 24) {
        _plainCache.remove(_plainCache.keys.first);
      }
      _plainCache[ref.blobId] = plaintext;
    }
    return plaintext;
  }

  void clearMemoryCache() => _plainCache.clear();

  // ---------------------------------------------------------------- actions

  /// Fields that make a message a reply to [quoted].
  static Map<String, Object> replyFields(
    ChatMessageView quoted,
    String quotedAuthorDeviceId,
  ) {
    final text = quoted.preview;
    return {
      'reply_to': {
        'id': quoted.id,
        'kind': quoted.kind,
        'text': text.length > 140 ? '${text.substring(0, 140)}…' : text,
        'author': quotedAuthorDeviceId,
      },
    };
  }

  /// Fields for a reply to [quoted] in the conversation with [contact].
  Future<Map<String, Object>> replyTo(
    Contact contact,
    ChatMessageView quoted,
  ) async {
    final author = quoted.isMine
        ? await _localDeviceId() ?? ''
        : await ContactRepository(_db).getDeviceIdForContact(contact.contactId) ??
            '';
    return replyFields(quoted, author);
  }

  /// Marks the conversation read and, if allowed, tells the other person.
  Future<void> markConversationRead(Contact contact) async {
    final localDeviceId = await _localDeviceId();
    if (localDeviceId == null) return;
    final conversationId =
        MessageRepository.conversationIdFor(contact.contactId);
    final ids = await MessageRepository(_db).markRead(conversationId, localDeviceId);
    if (ids.isNotEmpty && _readReceipts) {
      for (var start = 0; start < ids.length; start += 200) {
        unawaited(_sendControl(contact, {
          'kind': 'receipt',
          'status': 'read',
          'ids': ids.sublist(start, min(start + 200, ids.length)),
        }));
      }
    }
    if (ids.isNotEmpty) _changes.add(conversationId);
  }

  /// Reacts to a message; an empty [emoji] removes this device's reaction.
  Future<void> react(Contact contact, String messageId, String emoji) async {
    final localDeviceId = await _localDeviceId();
    if (localDeviceId == null) return;
    await MessageRepository(_db).setReaction(messageId, localDeviceId, emoji);
    _changes.add(MessageRepository.conversationIdFor(contact.contactId));
    await _sendControl(contact, {
      'kind': 'reaction',
      'target': messageId,
      'emoji': emoji,
    });
  }

  /// Changes the text (or caption) of one of this device's messages.
  Future<void> editMessage(Contact contact, String messageId, String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    final row = await MessageRepository(_db).get(messageId);
    if (row == null || row.isDeleted) return;
    if (row.senderDeviceId != await _localDeviceId()) {
      throw StateError(tr('You can only edit your own messages.'));
    }
    await _applyEdit(row, trimmed);
    _changes.add(row.conversationId);
    await _sendControl(contact, {
      'kind': 'edit',
      'target': messageId,
      'text': trimmed,
    });
  }

  /// Deletes one of this device's messages on both phones.
  Future<void> deleteForEveryone(Contact contact, String messageId) async {
    final row = await MessageRepository(_db).get(messageId);
    if (row == null) return;
    if (row.senderDeviceId != await _localDeviceId()) {
      throw StateError(tr('You can only delete your own messages for everyone.'));
    }
    await _applyDelete(row);
    _changes.add(row.conversationId);
    await _sendControl(contact, {'kind': 'delete', 'target': messageId});
  }

  /// Deletes a message from this phone only.
  Future<void> deleteForMe(String messageId) async {
    final repository = MessageRepository(_db);
    final row = await repository.get(messageId);
    if (row == null) return;
    final content = await _openContent(row).catchError((_) => null);
    if (content != null) {
      final owner = row.senderDeviceId == await _localDeviceId()
          ? 'local'
          : row.senderDeviceId;
      final attachment = AttachmentRef.fromContent(content, owner);
      if (attachment != null) {
        await MeyaBlobStore.instance.delete(owner, attachment.blobId);
        _plainCache.remove(attachment.blobId);
      }
    }
    await repository.delete(messageId);
    _changes.add(row.conversationId);
  }

  /// Pins or unpins a message for both people.
  Future<void> setPinned(Contact contact, String messageId, bool pinned) async {
    await MessageRepository(_db).setFlags(messageId, pinned: pinned);
    _changes.add(MessageRepository.conversationIdFor(contact.contactId));
    await _sendControl(contact, {
      'kind': 'pin',
      'target': messageId,
      'pinned': pinned,
    });
  }

  /// Adds or removes a message from Favourites (this phone only).
  Future<void> setStarred(String messageId, bool starred) async {
    final repository = MessageRepository(_db);
    await repository.setFlags(messageId, starred: starred);
    final row = await repository.get(messageId);
    if (row != null) _changes.add(row.conversationId);
  }

  /// Sends a copy of [message] to [to], marked as forwarded.
  Future<void> forward(ChatMessageView message, Contact to) async {
    const extra = <String, Object>{'forwarded': true};
    switch (message.kind) {
      case 'text':
        await sendText(to, message.text, extra: extra);
      case 'voice':
        await sendVoice(to, message.audio!, durationMs: message.durationMs, extra: extra);
      case 'image':
      case 'video':
      case 'file':
        final attachment = message.attachment!;
        await sendAttachment(
          to,
          kind: message.kind,
          bytes: await openAttachment(attachment),
          mime: attachment.mime,
          name: attachment.name,
          caption: message.text,
          thumbnail: attachment.thumbnail,
          extra: extra,
        );
      default:
        throw StateError(tr('This message cannot be forwarded.'));
    }
  }

  // ----------------------------------------------------------- chat list

  Future<void> setMuted(Contact contact, bool muted) async {
    final id = MessageRepository.conversationIdFor(contact.contactId);
    await MessageRepository(_db).ensureDirectConversation(contact.contactId);
    await MessageRepository(_db)
        .updateConversation(id, ConversationsCompanion(isMuted: Value(muted)));
    _changes.add(id);
  }

  Future<void> setArchived(Contact contact, bool archived) async {
    final id = MessageRepository.conversationIdFor(contact.contactId);
    await MessageRepository(_db).ensureDirectConversation(contact.contactId);
    await MessageRepository(_db).updateConversation(
      id,
      ConversationsCompanion(isArchived: Value(archived)),
    );
    _changes.add(id);
  }

  Future<void> setMarkedUnread(Contact contact, bool unread) async {
    final id = MessageRepository.conversationIdFor(contact.contactId);
    await MessageRepository(_db).ensureDirectConversation(contact.contactId);
    await MessageRepository(_db).updateConversation(
      id,
      ConversationsCompanion(markedUnread: Value(unread)),
    );
    _changes.add(id);
  }

  /// True when new messages from [contact] should make no sound.
  Future<bool> isMuted(String conversationId) async =>
      (await MessageRepository(_db).conversation(conversationId))?.isMuted ??
      false;

  /// Conversation state for the chats list, by conversation ID.
  Future<Map<String, Conversation>> conversationStates() async => {
        for (final conversation in await MessageRepository(_db).conversations())
          conversation.conversationId: conversation,
      };

  // --------------------------------------------------------- block, search

  /// Blocks [contact]: their messages and calls are dropped from now on.
  Future<void> block(Contact contact) async {
    await ContactRepository(_db).updateTrustState(
      contactId: contact.contactId,
      trustState: 'blocked',
    );
    _changes.add(MessageRepository.conversationIdFor(contact.contactId));
  }

  Future<void> unblock(Contact contact) async {
    await ContactRepository(_db).updateTrustState(
      contactId: contact.contactId,
      trustState: 'trusted',
    );
    _changes.add(MessageRepository.conversationIdFor(contact.contactId));
  }

  Future<List<Contact>> blockedContacts() async => [
        for (final contact in await ContactRepository(_db).getContacts())
          if (contact.trustState == 'blocked') contact,
      ];

  /// Messages containing [query] (text, captions and file names), newest
  /// first. Searches one conversation when [contact] is given. Everything is
  /// decrypted on this phone; nothing leaves it.
  Future<List<(Contact, ChatMessageView)>> search(
    String query, {
    Contact? contact,
  }) async {
    final needle = query.trim().toLowerCase();
    if (needle.isEmpty) return [];
    final contacts = contact != null
        ? [contact]
        : await ContactRepository(_db).getContacts();
    final results = <(Contact, ChatMessageView)>[];
    for (final person in contacts) {
      for (final message in await history(person)) {
        if (message.isDeleted) continue;
        final haystack = [
          message.text,
          message.attachment?.name ?? '',
        ].join('\n').toLowerCase();
        if (haystack.contains(needle)) results.add((person, message));
      }
    }
    results.sort((a, b) => b.$2.createdAt.compareTo(a.$2.createdAt));
    return results;
  }

  /// Favourite messages from every conversation, newest first.
  Future<List<(Contact, ChatMessageView)>> starredMessages() async {
    final results = <(Contact, ChatMessageView)>[];
    for (final person in await ContactRepository(_db).getContacts()) {
      for (final message in await history(person)) {
        if (message.starred) results.add((person, message));
      }
    }
    results.sort((a, b) => b.$2.createdAt.compareTo(a.$2.createdAt));
    return results;
  }
}
