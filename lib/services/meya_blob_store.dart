import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../bridge/api.dart' as bridge;

/// Encrypts attachment files with their own random key (AES-256-GCM in the
/// Rust core). The key only ever travels inside an end-to-end encrypted
/// message, so the relay and anyone with access to the files on disk see
/// only ciphertext.
abstract class BlobCipher {
  Future<Uint8List> seal(Uint8List key, Uint8List plaintext, String blobId);
  Future<Uint8List> open(Uint8List key, Uint8List ciphertext, String blobId);
}

class RustBlobCipher implements BlobCipher {
  const RustBlobCipher();

  static List<int> _aad(String blobId) => 'meya-blob-v1|$blobId'.codeUnits;

  @override
  Future<Uint8List> seal(Uint8List key, Uint8List plaintext, String blobId) =>
      bridge.encryptMessage(
        sessionKey: key,
        plaintext: plaintext,
        aad: _aad(blobId),
      );

  @override
  Future<Uint8List> open(Uint8List key, Uint8List ciphertext, String blobId) =>
      bridge.decryptMessage(
        sessionKey: key,
        envelope: ciphertext,
        aad: _aad(blobId),
      );
}

/// Stores encrypted attachment files (photos, videos, files, status media)
/// and reassembles the pieces they travel in through the relay.
///
/// Everything in here is ciphertext. Files are named by who sent them
/// ('local' for this device) and a random blob ID.
class MeyaBlobStore {
  MeyaBlobStore._();

  static final MeyaBlobStore instance = MeyaBlobStore._();

  /// Size of one piece sent through the relay. The relay accepts envelopes
  /// up to 1 MiB; 640 KiB of data stays below that after base64 and JSON.
  static const int chunkBytes = 640 * 1024;

  /// Largest encrypted attachment accepted (100 MiB): three minutes of
  /// 720p video or a large document.
  static const int maxChunks = 160;
  static const int maxBlobBytes = chunkBytes * maxChunks;

  static final RegExp _blobIdPattern = RegExp(r'^[0-9a-f]{32}$');

  Directory? _root;
  Directory? _testRoot;

  @visibleForTesting
  void useDirectoryForTesting(Directory directory) {
    _testRoot = directory;
    _root = null;
  }

  static bool isValidBlobId(String value) => _blobIdPattern.hasMatch(value);

  static String newBlobId() {
    final random = Random.secure();
    return List<int>.generate(16, (_) => random.nextInt(256))
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
  }

  static Uint8List newKey() {
    final random = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(32, (_) => random.nextInt(256)),
    );
  }

  static String _safe(String value) =>
      value.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');

  Future<Directory> _directory() async {
    final existing = _root;
    if (existing != null) return existing;
    final base = _testRoot ?? await getApplicationSupportDirectory();
    final directory = Directory(p.join(base.path, 'meya_blobs'));
    await directory.create(recursive: true);
    _root = directory;
    return directory;
  }

  Future<File> _file(String owner, String blobId) async {
    final directory = await _directory();
    return File(p.join(directory.path, '${_safe(owner)}_$blobId.bin'));
  }

  Future<Directory> _partsDirectory(String owner, String blobId) async {
    final directory = await _directory();
    return Directory(
      p.join(directory.path, 'incoming', '${_safe(owner)}_$blobId'),
    );
  }

  Future<bool> exists(String owner, String blobId) async =>
      (await _file(owner, blobId)).exists();

  Future<void> write(String owner, String blobId, Uint8List ciphertext) async {
    final file = await _file(owner, blobId);
    await file.writeAsBytes(ciphertext, flush: true);
  }

  Future<Uint8List> read(String owner, String blobId) async =>
      (await _file(owner, blobId)).readAsBytes();

  Future<void> delete(String owner, String blobId) async {
    final file = await _file(owner, blobId);
    if (await file.exists()) await file.delete();
  }

  /// Splits [ciphertext] into the pieces sent through the relay.
  static List<Uint8List> split(Uint8List ciphertext) {
    final chunks = <Uint8List>[];
    for (var start = 0; start < ciphertext.length; start += chunkBytes) {
      final end = min(start + chunkBytes, ciphertext.length);
      chunks.add(Uint8List.sublistView(ciphertext, start, end));
    }
    return chunks;
  }

  /// Saves one received piece. Returns true once every piece has arrived
  /// and the file has been put back together.
  Future<bool> addChunk({
    required String owner,
    required String blobId,
    required int index,
    required int count,
    required Uint8List data,
  }) async {
    if (!isValidBlobId(blobId) ||
        count < 1 ||
        count > maxChunks ||
        index < 0 ||
        index >= count ||
        data.isEmpty ||
        data.length > chunkBytes) {
      throw StateError('Invalid attachment piece.');
    }
    if (await exists(owner, blobId)) return true;

    final parts = await _partsDirectory(owner, blobId);
    await parts.create(recursive: true);
    await File(p.join(parts.path, '$index')).writeAsBytes(data, flush: true);

    final present = await parts
        .list()
        .where((entity) => entity is File)
        .length;
    if (present < count) return false;

    final builder = BytesBuilder(copy: false);
    for (var i = 0; i < count; i++) {
      final part = File(p.join(parts.path, '$i'));
      if (!await part.exists()) return false;
      builder.add(await part.readAsBytes());
    }
    await write(owner, blobId, builder.takeBytes());
    await parts.delete(recursive: true);
    return true;
  }

  /// Total size of stored attachments, in bytes.
  Future<int> totalBytes() async {
    final directory = await _directory();
    var total = 0;
    await for (final entity in directory.list(recursive: true)) {
      if (entity is File) total += await entity.length();
    }
    return total;
  }

  /// Deletes attachments older than [age]. Messages stay; their media then
  /// shows as no longer on this device.
  Future<int> deleteOlderThan(Duration age) async {
    final directory = await _directory();
    final cutoff = DateTime.now().subtract(age);
    var deleted = 0;
    await for (final entity in directory.list(recursive: true)) {
      if (entity is File && (await entity.lastModified()).isBefore(cutoff)) {
        await entity.delete();
        deleted++;
      }
    }
    return deleted;
  }

  Future<void> deleteAll() async {
    final directory = await _directory();
    if (await directory.exists()) await directory.delete(recursive: true);
    _root = null;
  }
}

/// Decrypted copies needed to play a video or open a file in another app.
/// They live in the cache folder and are removed as soon as possible.
class MeyaTempFiles {
  static Future<Directory> _directory() async {
    final base = await getTemporaryDirectory();
    final directory = Directory(p.join(base.path, 'meya_open'));
    await directory.create(recursive: true);
    return directory;
  }

  static Future<File> write(String name, Uint8List bytes) async {
    final directory = await _directory();
    final safe = name.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final file = File(p.join(directory.path, safe.isEmpty ? 'file' : safe));
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  static Future<int> totalBytes() async {
    final directory = await _directory();
    var total = 0;
    await for (final entity in directory.list(recursive: true)) {
      if (entity is File) total += await entity.length();
    }
    return total;
  }

  static Future<void> clear() async {
    final directory = await _directory();
    if (await directory.exists()) await directory.delete(recursive: true);
  }
}
