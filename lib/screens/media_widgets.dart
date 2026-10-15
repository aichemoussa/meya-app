import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:fc_native_video_thumbnail/fc_native_video_thumbnail.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:video_player/video_player.dart';

import '../services/meya_blob_store.dart';
import '../services/meya_media_settings.dart';
import '../services/meya_message_service.dart';
import '../theme/meya_theme.dart';
import '../l10n/meya_strings.dart';
import 'video_recorder_page.dart';

/// A photo, video or file chosen by the person, ready to encrypt and send.
class PickedMedia {
  /// 'image', 'video' or 'file'.
  final String kind;
  final Uint8List bytes;
  final String mime;
  final String name;

  /// JPEG preview for videos.
  final Uint8List? thumbnail;

  const PickedMedia({
    required this.kind,
    required this.bytes,
    required this.mime,
    required this.name,
    this.thumbnail,
  });
}

String mimeForName(String name) {
  final lower = name.toLowerCase();
  final dot = lower.lastIndexOf('.');
  final extension = dot < 0 ? '' : lower.substring(dot + 1);
  return switch (extension) {
    'jpg' || 'jpeg' => 'image/jpeg',
    'png' => 'image/png',
    'webp' => 'image/webp',
    'gif' => 'image/gif',
    'heic' => 'image/heic',
    'mp4' || 'm4v' => 'video/mp4',
    'mov' => 'video/quicktime',
    '3gp' => 'video/3gpp',
    'webm' => 'video/webm',
    'm4a' => 'audio/mp4',
    'mp3' => 'audio/mpeg',
    'pdf' => 'application/pdf',
    'txt' => 'text/plain',
    'doc' => 'application/msword',
    'docx' =>
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'xls' => 'application/vnd.ms-excel',
    'xlsx' =>
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'ppt' => 'application/vnd.ms-powerpoint',
    'pptx' =>
      'application/vnd.openxmlformats-officedocument.presentationml.presentation',
    'zip' => 'application/zip',
    _ => 'application/octet-stream',
  };
}

String formatBytes(int bytes) {
  if (bytes < 1024) return tr('{0} B', [bytes]);
  if (bytes < 1024 * 1024) return tr('{0} KB', [(bytes / 1024).toStringAsFixed(0)]);
  if (bytes < 1024 * 1024 * 1024) {
    return tr('{0} MB', [(bytes / (1024 * 1024)).toStringAsFixed(1)]);
  }
  return tr('{0} GB', [(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)]);
}

/// Chooses photos, videos and files, applying the Storage & Media settings.
class MeyaMediaPicker {
  static final ImagePicker _imagePicker = ImagePicker();

  static void _checkSize(int length) {
    if (length > MeyaMessageService.maxAttachmentBytes) {
      throw StateError(
        tr('This file is too large. MEYA can send files up to {0} MB.', [MeyaMessageService.maxAttachmentBytes ~/ (1024 * 1024)]),
      );
    }
  }

  static Future<PickedMedia?> photo({required bool camera}) async {
    final settings = MeyaMediaSettings.instance;
    final image = await _imagePicker.pickImage(
      source: camera ? ImageSource.camera : ImageSource.gallery,
      maxWidth: settings.photoMaxSide,
      maxHeight: settings.photoMaxSide,
      imageQuality: settings.photoJpegQuality,
    );
    if (image == null) return null;
    final bytes = await image.readAsBytes();
    _checkSize(bytes.length);
    final name = image.name.isEmpty ? 'photo.jpg' : image.name;
    return PickedMedia(
      kind: 'image',
      bytes: bytes,
      mime: image.mimeType ?? mimeForName(name),
      name: name,
    );
  }

  /// Records a video inside MEYA (see [VideoRecorderPage]).
  static Future<PickedMedia?> recordVideo(BuildContext context) async {
    final file = await Navigator.of(context).push<XFile>(
      MaterialPageRoute(builder: (_) => const VideoRecorderPage()),
    );
    if (file == null) return null;
    try {
      return await _fromVideo(file);
    } finally {
      // The recording is now encrypted in MEYA; remove the plain copy.
      unawaited(File(file.path).delete().catchError((_) => File(file.path)));
    }
  }

  static Future<PickedMedia?> video() async {
    final video = await _imagePicker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: VideoRecorderPage.maxDuration,
    );
    if (video == null) return null;
    return _fromVideo(video);
  }

  static Future<PickedMedia> _fromVideo(XFile video) async {
    final length = await video.length();
    _checkSize(length);
    final bytes = await video.readAsBytes();
    final name = video.name.isEmpty ? 'video.mp4' : video.name;
    return PickedMedia(
      kind: 'video',
      bytes: bytes,
      mime: video.mimeType ?? mimeForName(name),
      name: name,
      thumbnail: await videoThumbnail(video.path),
    );
  }

  /// A small JPEG of the video's first frame, or null if none can be made.
  static Future<Uint8List?> videoThumbnail(String path) async {
    if (path.isEmpty) return null;
    try {
      final bytes = await FcNativeVideoThumbnail().saveThumbnailToBytes(
        srcFile: path,
        width: 480,
        height: 480,
        format: 'jpeg',
        quality: 70,
      );
      if (bytes == null || bytes.length > AttachmentRef.maxThumbnailBytes) {
        return null;
      }
      return bytes;
    } catch (error) {
      debugPrint('MEYA media: no video thumbnail ($error).');
      return null;
    }
  }

  static Future<PickedMedia?> file() async {
    final picked = await FilePicker.pickFile();
    if (picked == null) return null;
    final length = picked.lengthSync() ?? await picked.length();
    if (length == null) throw StateError(tr('This file could not be read.'));
    _checkSize(length);
    final bytes = await picked.readAsBytes();
    final mime = mimeForName(picked.name);
    return PickedMedia(
      kind: mime.startsWith('image/')
          ? 'image'
          : mime.startsWith('video/')
              ? 'video'
              : 'file',
      bytes: bytes,
      mime: mime,
      name: picked.name,
      thumbnail: mime.startsWith('video/') && picked.path != null
          ? await videoThumbnail(picked.path!)
          : null,
    );
  }
}

/// Shows an encrypted photo, decrypting it in memory.
class EncryptedImage extends StatefulWidget {
  final AttachmentRef attachment;
  final BoxFit fit;
  final double? width;
  final double? height;

  const EncryptedImage({
    super.key,
    required this.attachment,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
  });

  @override
  State<EncryptedImage> createState() => _EncryptedImageState();
}

class _EncryptedImageState extends State<EncryptedImage> {
  Future<Uint8List?>? _bytes;
  StreamSubscription<String>? _arrivals;

  @override
  void initState() {
    super.initState();
    _bytes = _load();
    _arrivals = MeyaMessageService.instance.mediaArrived.listen((blobId) {
      if (blobId == widget.attachment.blobId && mounted) {
        setState(() => _bytes = _load());
      }
    });
  }

  @override
  void dispose() {
    _arrivals?.cancel();
    super.dispose();
  }

  Future<Uint8List?> _load() async {
    final service = MeyaMessageService.instance;
    if (!await service.hasAttachment(widget.attachment)) return null;
    return service.openAttachment(widget.attachment);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: _bytes,
      builder: (context, snapshot) {
        final bytes = snapshot.data;
        if (bytes != null) {
          return Image.memory(
            bytes,
            fit: widget.fit,
            width: widget.width,
            height: widget.height,
            gaplessPlayback: true,
            semanticLabel: context.tr('Photo'),
          );
        }
        return SizedBox(
          width: widget.width,
          height: widget.height ?? 180,
          child: Center(
            child: snapshot.connectionState == ConnectionState.done
                ? MediaPendingLabel(
                    failed: snapshot.hasError,
                    color: context.meya.muted,
                  )
                : const CircularProgressIndicator(),
          ),
        );
      },
    );
  }
}

class MediaPendingLabel extends StatelessWidget {
  final bool failed;
  final Color color;

  const MediaPendingLabel({super.key, required this.failed, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          failed ? Icons.broken_image_outlined : Icons.downloading_outlined,
          color: color,
        ),
        const SizedBox(height: 6),
        Text(
          failed ? context.tr('Could not open') : context.tr('Receiving…'),
          style: TextStyle(color: color, fontSize: 13),
        ),
      ],
    );
  }
}

/// Full-screen view of an encrypted photo, with pinch to zoom.
class PhotoViewerPage extends StatelessWidget {
  final AttachmentRef attachment;
  final String caption;

  const PhotoViewerPage({
    super.key,
    required this.attachment,
    this.caption = '',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: context.tr('Save to device'),
            icon: const Icon(Icons.download_outlined),
            onPressed: () => saveAttachmentToDevice(context, attachment),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: InteractiveViewer(
                maxScale: 5,
                child: Center(
                  child: EncryptedImage(
                    attachment: attachment,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            if (caption.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  caption,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Plays an encrypted video. A decrypted copy exists in the cache folder
/// only while the player is open.
class VideoPlayerPage extends StatefulWidget {
  final AttachmentRef attachment;
  final String caption;

  const VideoPlayerPage({
    super.key,
    required this.attachment,
    this.caption = '',
  });

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  VideoPlayerController? _controller;
  File? _file;
  String? _error;

  @override
  void initState() {
    super.initState();
    _open();
  }

  Future<void> _open() async {
    try {
      final service = MeyaMessageService.instance;
      if (!await service.hasAttachment(widget.attachment)) {
        throw StateError(context.tr('This video has not fully arrived yet.'));
      }
      final bytes = await service.openAttachment(widget.attachment);
      final file = await MeyaTempFiles.write(
        '${widget.attachment.blobId}_${widget.attachment.name}',
        bytes,
      );
      final controller = VideoPlayerController.file(file);
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        await file.delete();
        return;
      }
      setState(() {
        _file = file;
        _controller = controller;
      });
      await controller.play();
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    final file = _file;
    if (file != null) {
      file.delete().catchError((_) => file);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: context.tr('Save to device'),
            icon: const Icon(Icons.download_outlined),
            onPressed: () => saveAttachmentToDevice(context, widget.attachment),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: _error != null
              ? Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white),
                  ),
                )
              : controller == null
                  ? const CircularProgressIndicator()
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AspectRatio(
                          aspectRatio: controller.value.aspectRatio,
                          child: VideoPlayer(controller),
                        ),
                        VideoProgressIndicator(
                          controller,
                          allowScrubbing: true,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        ValueListenableBuilder<VideoPlayerValue>(
                          valueListenable: controller,
                          builder: (context, value, _) => IconButton(
                            iconSize: 48,
                            color: Colors.white,
                            tooltip: value.isPlaying ? context.tr('Pause') : context.tr('Play'),
                            icon: Icon(
                              value.isPlaying
                                  ? Icons.pause_circle_filled
                                  : Icons.play_circle_fill,
                            ),
                            onPressed: () => value.isPlaying
                                ? controller.pause()
                                : controller.play(),
                          ),
                        ),
                        if (widget.caption.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              widget.caption,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
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

void _snack(BuildContext context, String message) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

/// Opens a received file in another app. The decrypted copy is written to
/// the cache folder, which Storage & Media can clear.
Future<void> openAttachmentExternally(
  BuildContext context,
  AttachmentRef attachment,
) async {
  try {
    final service = MeyaMessageService.instance;
    if (!await service.hasAttachment(attachment)) {
      _snack(context, tr('This file has not fully arrived yet.'));
      return;
    }
    final bytes = await service.openAttachment(attachment);
    final file = await MeyaTempFiles.write(
      '${attachment.blobId}_${attachment.name}',
      bytes,
    );
    final result = await OpenFilex.open(file.path, type: attachment.mime);
    if (result.type != ResultType.done) {
      if (!context.mounted) return;
      _snack(context, tr('No app on this phone can open this file. Use Save to keep a copy.'));
    }
  } catch (error) {
    if (!context.mounted) return;
    _snack(context, tr('Could not open the file: {0}', [error]));
  }
}

/// Saves a decrypted copy where the person chooses.
Future<void> saveAttachmentToDevice(
  BuildContext context,
  AttachmentRef attachment,
) async {
  try {
    final service = MeyaMessageService.instance;
    if (!await service.hasAttachment(attachment)) {
      _snack(context, tr('This file has not fully arrived yet.'));
      return;
    }
    final bytes = await service.openAttachment(attachment);
    final path = await FilePicker.saveFile(
      dialogTitle: tr('Save a copy'),
      fileName: attachment.name,
      bytes: bytes,
    );
    if (!context.mounted) return;
    if (path != null) {
      _snack(context, tr('Saved. This copy is not encrypted by MEYA.'));
    }
  } catch (error) {
    if (!context.mounted) return;
    _snack(context, tr('Could not save the file: {0}', [error]));
  }
}

/// A video's preview picture with a play button on top.
class VideoThumbnail extends StatelessWidget {
  final Uint8List bytes;
  final double width;
  final double height;
  final String label;

  /// Shown in the corner, e.g. the file size.
  final String? caption;

  const VideoThumbnail({
    super.key,
    required this.bytes,
    required this.label,
    this.width = 220,
    this.height = 220,
    this.caption,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: label,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: width,
          height: height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.memory(
                bytes,
                fit: BoxFit.cover,
                gaplessPlayback: true,
                excludeFromSemantics: true,
                errorBuilder: (_, _, _) =>
                    const ColoredBox(color: Colors.black54),
              ),
              const ColoredBox(color: Color(0x33000000)),
              const Center(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Color(0x99000000),
                    shape: BoxShape.circle,
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(10),
                    child: Icon(Icons.play_arrow, color: Colors.white, size: 40),
                  ),
                ),
              ),
              if (caption != null)
                PositionedDirectional(
                  end: 8,
                  bottom: 8,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0x99000000),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      child: Text(
                        caption!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
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
