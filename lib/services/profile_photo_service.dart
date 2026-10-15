import 'dart:io';


import 'meya_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class ProfilePhotoService {
  static const _storage = meyaSecureStorage;
  static const _photoPathKey = 'meya_profile_photo_path';

  static final ImagePicker _picker = ImagePicker();

  static Future<String?> getPhotoPath() async {
    final path = await _storage.read(key: _photoPathKey);

    if (path == null || path.isEmpty) {
      return null;
    }

    final file = File(path);

    if (!await file.exists()) {
      await _storage.delete(key: _photoPathKey);
      return null;
    }

    return path;
  }

  static Future<String?> pickFromGallery() async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      // Small enough to share with contacts quickly.
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (image == null) {
      return null;
    }

    return _saveImage(image);
  }

  static Future<String?> takePhoto() async {
    final image = await _picker.pickImage(
      source: ImageSource.camera,
      // Small enough to share with contacts quickly.
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (image == null) {
      return null;
    }

    return _saveImage(image);
  }

  static Future<String?> _saveImage(XFile image) async {
    final directory = await getApplicationDocumentsDirectory();
    final profileDirectory = Directory(
      '${directory.path}${Platform.pathSeparator}profile',
    );

    if (!await profileDirectory.exists()) {
      await profileDirectory.create(recursive: true);
    }

    final extension = _fileExtension(image.path);
    final destination = File(
      '${profileDirectory.path}${Platform.pathSeparator}profile_photo$extension',
    );

    final previousPath = await _storage.read(key: _photoPathKey);

    if (previousPath != null &&
        previousPath.isNotEmpty &&
        previousPath != destination.path) {
      final previousFile = File(previousPath);

      if (await previousFile.exists()) {
        await previousFile.delete();
      }
    }

    final sourceFile = File(image.path);
    await sourceFile.copy(destination.path);

    await _storage.write(key: _photoPathKey, value: destination.path);

    return destination.path;
  }

  static Future<void> removePhoto() async {
    final path = await _storage.read(key: _photoPathKey);

    if (path != null && path.isNotEmpty) {
      final file = File(path);

      if (await file.exists()) {
        await file.delete();
      }
    }

    await _storage.delete(key: _photoPathKey);
  }

  static String _fileExtension(String path) {
    final normalized = path.toLowerCase();

    if (normalized.endsWith('.png')) {
      return '.png';
    }

    if (normalized.endsWith('.webp')) {
      return '.webp';
    }

    if (normalized.endsWith('.heic')) {
      return '.heic';
    }

    return '.jpg';
  }
}
