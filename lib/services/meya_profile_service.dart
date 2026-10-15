import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../database/contact_repository.dart';
import '../database/meya_database.dart';
import 'meya_account_storage.dart';
import 'meya_e2ee.dart';
import 'meya_message_service.dart';
import 'profile_photo_service.dart';

/// What a contact shared about themselves.
class ContactProfile {
  final String name;
  final String about;
  final AttachmentRef? photo;

  const ContactProfile({required this.name, required this.about, this.photo});
}

/// Shares this person's name, About and photo with their connections
/// (end-to-end encrypted) and keeps what connections share.
class MeyaProfileService {
  MeyaProfileService._();

  static final MeyaProfileService instance = MeyaProfileService._();

  MeyaDatabase? _database;
  E2eeOperations _e2ee = MeyaE2ee.instance;
  final StreamController<String> _changes = StreamController.broadcast();

  /// Emits a contact ID when that contact's profile changes.
  Stream<String> get changes => _changes.stream;

  void configure({required MeyaDatabase database}) {
    _database = database;
  }

  @visibleForTesting
  void configureForTesting({
    required MeyaDatabase database,
    required E2eeOperations e2ee,
  }) {
    _database = database;
    _e2ee = e2ee;
  }

  MeyaDatabase get _db {
    final database = _database;
    if (database == null) throw StateError('MEYA profiles are not configured.');
    return database;
  }

  static String _safe(String value) =>
      value.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');

  Future<File> _file(String contactId) async {
    final base = await getApplicationSupportDirectory();
    final directory = Directory(p.join(base.path, 'meya_profiles'));
    await directory.create(recursive: true);
    return File(p.join(directory.path, '${_safe(contactId)}.bin'));
  }

  /// Sends the current profile to every contact with encryption set up, or
  /// only to [only]. Returns how many people received it.
  Future<int> share({Contact? only}) async {
    final user = await MeyaAccountStorage.loadUser();
    if (user == null) return 0;
    final about = await MeyaAccountStorage.loadAbout();
    final photoPath = await ProfilePhotoService.getPhotoPath();
    final messages = MeyaMessageService.instance;

    AttachmentRef? photo;
    if (photoPath != null) {
      try {
        final bytes = await File(photoPath).readAsBytes();
        if (bytes.length <= MeyaMessageService.maxAttachmentBytes) {
          photo = await messages.encryptMedia(
            bytes,
            mime: 'image/jpeg',
            name: 'profile.jpg',
          );
        }
      } catch (error) {
        debugPrint('MEYA profile: photo not shared ($error).');
      }
    }

    final contacts = only != null
        ? [only]
        : await ContactRepository(_db).getTrustedContacts();
    var sent = 0;
    for (final contact in contacts) {
      if (!await messages.canMessage(contact)) continue;
      try {
        await messages.sendSilent(
          contact,
          {
            'kind': 'profile',
            'name': user.name,
            'username': user.username,
            'about': about,
            'has_photo': photo != null,
          },
          media: photo,
        );
        sent++;
      } catch (error) {
        debugPrint('MEYA profile: not sent to ${contact.contactId} ($error).');
      }
    }
    return sent;
  }

  /// Called by the messaging service for `profile` content.
  Future<void> handleIncoming(
    Contact contact,
    String senderDeviceId,
    Map<String, dynamic> content,
  ) async {
    final name = content['name'];
    final about = content['about'];
    if (name is! String || about is! String) return;
    final cleanName = name.trim();
    if (cleanName.isEmpty || cleanName.length > 80 || about.length > 400) return;

    final media = content['media'];
    AttachmentRef? photo;
    if (media is Map<String, dynamic>) {
      photo = AttachmentRef.fromContent(media, senderDeviceId);
      if (photo != null && !photo.mime.startsWith('image/')) photo = null;
    }

    final json = {
      'name': cleanName,
      'about': about,
      if (photo != null) 'photo': {...photo.toContent(), 'owner': photo.owner},
    };
    final sealed = await _e2ee.sealLocal(
      Uint8List.fromList(utf8.encode(jsonEncode(json))),
      'profile-${contact.contactId}',
    );
    await (await _file(contact.contactId)).writeAsBytes(sealed, flush: true);

    // Show the name they chose rather than their MEYA ID.
    await (_db.update(_db.contacts)
          ..where((c) => c.contactId.equals(contact.contactId)))
        .write(ContactsCompanion(displayName: Value(cleanName)));
    _changes.add(contact.contactId);
  }

  Future<ContactProfile?> profileOf(String contactId) async {
    final file = await _file(contactId);
    if (!await file.exists()) return null;
    try {
      final plain =
          await _e2ee.openLocal(await file.readAsBytes(), 'profile-$contactId');
      final json = jsonDecode(utf8.decode(plain));
      if (json is! Map<String, dynamic>) return null;
      final photoJson = json['photo'];
      AttachmentRef? photo;
      if (photoJson is Map<String, dynamic> && photoJson['owner'] is String) {
        photo = AttachmentRef.fromContent(photoJson, photoJson['owner'] as String);
      }
      return ContactProfile(
        name: json['name'] is String ? json['name'] as String : '',
        about: json['about'] is String ? json['about'] as String : '',
        photo: photo,
      );
    } catch (error) {
      debugPrint('MEYA profile: a stored profile could not be opened.');
      return null;
    }
  }

  Future<void> deleteAll() async {
    final base = await getApplicationSupportDirectory();
    final directory = Directory(p.join(base.path, 'meya_profiles'));
    if (await directory.exists()) await directory.delete(recursive: true);
  }
}
