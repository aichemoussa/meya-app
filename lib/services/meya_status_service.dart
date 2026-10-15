import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../database/contact_repository.dart';
import '../database/meya_database.dart';
import 'meya_e2ee.dart';
import 'meya_message_service.dart';
import '../l10n/meya_strings.dart';

/// A status: text with an optional emoji, photo or video.
class MeyaStatus {
  final String statusId;
  final String text;
  final String emoji;
  final AttachmentRef? media;
  final DateTime postedAt;
  final DateTime? expiresAt;

  /// Own status only: 'all', 'selected' or 'only_me', and who received it.
  final String visibility;
  final List<String> audienceContactIds;

  /// Received statuses only.
  final String? contactId;
  final String? contactName;

  const MeyaStatus({
    required this.statusId,
    required this.text,
    required this.emoji,
    required this.media,
    required this.postedAt,
    required this.expiresAt,
    this.visibility = 'all',
    this.audienceContactIds = const [],
    this.contactId,
    this.contactName,
  });

  bool get isExpired =>
      expiresAt != null && DateTime.now().isAfter(expiresAt!);

  bool get isVideo => media?.mime.startsWith('video/') ?? false;

  Map<String, Object?> toJson() => {
        'status_id': statusId,
        'text': text,
        'emoji': emoji,
        if (media != null) 'media': {...media!.toContent(), 'owner': media!.owner},
        'posted_at': postedAt.toUtc().toIso8601String(),
        'expires_at': expiresAt?.toUtc().toIso8601String(),
        'visibility': visibility,
        'audience': audienceContactIds,
        'contact_id': contactId,
        'contact_name': contactName,
      };

  static MeyaStatus? fromJson(Map<String, dynamic> json, {String? owner}) {
    final statusId = json['status_id'];
    final text = json['text'];
    final emoji = json['emoji'];
    final posted = DateTime.tryParse('${json['posted_at']}');
    if (statusId is! String || statusId.isEmpty || statusId.length > 64) {
      return null;
    }
    if (text is! String || emoji is! String || posted == null) return null;
    final expiresRaw = json['expires_at'];
    final expires =
        expiresRaw is String ? DateTime.tryParse(expiresRaw)?.toLocal() : null;

    AttachmentRef? media;
    final mediaJson = json['media'];
    if (mediaJson is Map<String, dynamic>) {
      final mediaOwner = owner ?? mediaJson['owner'];
      if (mediaOwner is String) {
        media = AttachmentRef.fromContent(mediaJson, mediaOwner);
      }
      if (media == null) return null;
      final mime = media.mime;
      if (!mime.startsWith('image/') && !mime.startsWith('video/')) return null;
    }

    final audience = json['audience'];
    return MeyaStatus(
      statusId: statusId,
      text: text.length > 200 ? text.substring(0, 200) : text,
      emoji: emoji.length > 16 ? '' : emoji,
      media: media,
      postedAt: posted.toLocal(),
      expiresAt: expires,
      visibility: json['visibility'] is String ? json['visibility'] : 'all',
      audienceContactIds:
          audience is List ? audience.whereType<String>().toList() : const [],
      contactId: json['contact_id'] is String ? json['contact_id'] : null,
      contactName: json['contact_name'] is String ? json['contact_name'] : null,
    );
  }
}

/// Posts this person's status to their connections and keeps the statuses
/// they receive. Statuses travel end-to-end encrypted, one copy per contact,
/// and are stored sealed with this device's storage key.
class MeyaStatusService {
  MeyaStatusService._();

  static final MeyaStatusService instance = MeyaStatusService._();

  static const Duration defaultExpiry = Duration(hours: 24);

  MeyaDatabase? _database;
  E2eeOperations _e2ee = MeyaE2ee.instance;
  Directory? _testRoot;
  final StreamController<void> _changes = StreamController.broadcast();

  Stream<void> get changes => _changes.stream;

  void configure({required MeyaDatabase database}) {
    _database = database;
  }

  @visibleForTesting
  void configureForTesting({
    required MeyaDatabase database,
    required E2eeOperations e2ee,
    required Directory directory,
  }) {
    _database = database;
    _e2ee = e2ee;
    _testRoot = directory;
  }

  MeyaDatabase get _db {
    final database = _database;
    if (database == null) throw StateError(tr('MEYA status is not configured.'));
    return database;
  }

  Future<Directory> _directory() async {
    final base = _testRoot ?? await getApplicationSupportDirectory();
    final directory = Directory(p.join(base.path, 'meya_status'));
    await directory.create(recursive: true);
    return directory;
  }

  static String _safe(String value) =>
      value.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');

  Future<File> _ownFile() async =>
      File(p.join((await _directory()).path, 'own.bin'));

  Future<File> _contactFile(String contactId) async =>
      File(p.join((await _directory()).path, 'contact_${_safe(contactId)}.bin'));

  Future<void> _writeSealed(File file, Map<String, Object?> json, String context) async {
    final sealed = await _e2ee.sealLocal(
      Uint8List.fromList(utf8.encode(jsonEncode(json))),
      context,
    );
    await file.writeAsBytes(sealed, flush: true);
  }

  Future<Map<String, dynamic>?> _readSealed(File file, String context) async {
    if (!await file.exists()) return null;
    try {
      final plain = await _e2ee.openLocal(await file.readAsBytes(), context);
      final json = jsonDecode(utf8.decode(plain));
      return json is Map<String, dynamic> ? json : null;
    } catch (error) {
      debugPrint('MEYA status: a stored status could not be opened.');
      return null;
    }
  }

  // ------------------------------------------------------------------ own

  Future<MeyaStatus?> loadOwn() async {
    final json = await _readSealed(await _ownFile(), 'status-own');
    if (json == null) return null;
    final status = MeyaStatus.fromJson(json);
    if (status == null || status.isExpired) return null;
    return status;
  }

  /// Posts a new status. Returns the names of people it could not be sent
  /// to (for example because encryption is not set up with them yet).
  Future<List<String>> post({
    required String text,
    required String emoji,
    Uint8List? mediaBytes,
    String? mediaMime,
    required String visibility,
    List<String> selectedContactIds = const [],
    Duration? expiry = defaultExpiry,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty && emoji.isEmpty && mediaBytes == null) {
      throw StateError(tr('Add some text, an emoji, a photo or a video.'));
    }
    if (mediaBytes != null &&
        mediaBytes.length > MeyaMessageService.maxAttachmentBytes) {
      throw StateError(tr('This photo or video is too large for a status.'));
    }

    final previous = await loadOwn();
    final messages = MeyaMessageService.instance;
    AttachmentRef? media;
    if (mediaBytes != null) {
      final mime = mediaMime ?? 'image/jpeg';
      media = await messages.encryptMedia(
        mediaBytes,
        mime: mime,
        name: mime.startsWith('video/') ? 'status.mp4' : 'status.jpg',
      );
    }

    final contacts = await _audience(visibility, selectedContactIds);
    final now = DateTime.now();
    final status = MeyaStatus(
      statusId: MeyaMessageService.newId(),
      text: trimmed,
      emoji: emoji,
      media: media,
      postedAt: now,
      expiresAt: expiry == null ? null : now.add(expiry),
      visibility: visibility,
      audienceContactIds: contacts.map((c) => c.contactId).toList(),
    );
    await _writeSealed(await _ownFile(), status.toJson(), 'status-own');

    // People who saw the previous status but are not in the new audience.
    if (previous != null) {
      final removed = previous.audienceContactIds
          .where((id) => !status.audienceContactIds.contains(id))
          .toList();
      await _sendClear(removed);
    }

    final failed = <String>[];
    for (final contact in contacts) {
      try {
        await messages.sendSilent(
          contact,
          {
            'kind': 'status',
            'status_id': status.statusId,
            'text': status.text,
            'emoji': status.emoji,
            'posted_at': status.postedAt.toUtc().toIso8601String(),
            if (status.expiresAt != null)
              'expires_at': status.expiresAt!.toUtc().toIso8601String(),
          },
          media: media,
        );
      } catch (error) {
        debugPrint('MEYA status: not sent to ${contact.contactId} ($error).');
        failed.add(contact.displayName);
      }
    }
    _changes.add(null);
    return failed;
  }

  Future<void> clearOwn() async {
    final previous = await loadOwn();
    final file = await _ownFile();
    if (await file.exists()) await file.delete();
    if (previous != null) await _sendClear(previous.audienceContactIds);
    _changes.add(null);
  }

  Future<void> _sendClear(List<String> contactIds) async {
    if (contactIds.isEmpty) return;
    final contacts = await ContactRepository(_db).getTrustedContacts();
    for (final contact in contacts) {
      if (!contactIds.contains(contact.contactId)) continue;
      try {
        await MeyaMessageService.instance
            .sendSilent(contact, {'kind': 'status_clear'});
      } catch (error) {
        debugPrint('MEYA status: clear not sent ($error).');
      }
    }
  }

  Future<List<Contact>> _audience(
    String visibility,
    List<String> selectedContactIds,
  ) async {
    if (visibility == 'only_me') return const [];
    final contacts = await ContactRepository(_db).getTrustedContacts();
    final messages = MeyaMessageService.instance;
    final result = <Contact>[];
    for (final contact in contacts) {
      if (visibility == 'selected' &&
          !selectedContactIds.contains(contact.contactId)) {
        continue;
      }
      if (await messages.canMessage(contact)) result.add(contact);
    }
    return result;
  }

  // ------------------------------------------------------------- received

  /// Called by the messaging service for `status` and `status_clear`.
  Future<void> handleIncoming(
    Contact contact,
    String senderDeviceId,
    Map<String, dynamic> content,
  ) async {
    final file = await _contactFile(contact.contactId);
    if (content['kind'] == 'status_clear') {
      if (await file.exists()) await file.delete();
      _changes.add(null);
      return;
    }

    final status = MeyaStatus.fromJson(content, owner: senderDeviceId);
    if (status == null) {
      debugPrint('MEYA status: malformed status was dropped.');
      return;
    }
    final stored = MeyaStatus(
      statusId: status.statusId,
      text: status.text,
      emoji: status.emoji,
      media: status.media,
      postedAt: status.postedAt,
      expiresAt: status.expiresAt,
      contactId: contact.contactId,
      contactName: contact.displayName,
    );
    await _writeSealed(file, stored.toJson(), 'status-${contact.contactId}');
    _changes.add(null);
  }

  /// Current statuses from contacts, newest first.
  Future<List<MeyaStatus>> contactStatuses() async {
    final contacts = await ContactRepository(_db).getTrustedContacts();
    final statuses = <MeyaStatus>[];
    for (final contact in contacts) {
      final status = await statusOf(contact.contactId);
      if (status != null) statuses.add(status);
    }
    statuses.sort((a, b) => b.postedAt.compareTo(a.postedAt));
    return statuses;
  }

  Future<MeyaStatus?> statusOf(String contactId) async {
    final file = await _contactFile(contactId);
    final json = await _readSealed(file, 'status-$contactId');
    final status = json == null ? null : MeyaStatus.fromJson(json);
    if (status == null) return null;
    if (status.isExpired) {
      await file.delete();
      return null;
    }
    return status;
  }

  Future<void> deleteAll() async {
    final directory = await _directory();
    if (await directory.exists()) await directory.delete(recursive: true);
  }
}
