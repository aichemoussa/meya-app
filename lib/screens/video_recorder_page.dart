import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../l10n/meya_strings.dart';

/// Records a video inside MEYA, so Android cannot close MEYA while the
/// phone's camera app is open. Returns the recorded file, or null.
class VideoRecorderPage extends StatefulWidget {
  static const maxDuration = Duration(minutes: 3);

  const VideoRecorderPage({super.key});

  @override
  State<VideoRecorderPage> createState() => _VideoRecorderPageState();
}

class _VideoRecorderPageState extends State<VideoRecorderPage>
    with WidgetsBindingObserver {
  List<CameraDescription> _cameras = [];
  int _cameraIndex = 0;
  CameraController? _controller;
  String? _error;
  bool _recording = false;
  bool _busy = false;
  Duration _elapsed = Duration.zero;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _start();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      if (_recording) {
        _stop();
      } else {
        controller.dispose();
        _controller = null;
      }
    } else if (state == AppLifecycleState.resumed && _controller == null) {
      _open(_cameras[_cameraIndex]);
    }
  }

  Future<void> _start() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() => _error = context.tr('No camera found on this device.'));
        return;
      }
      final back = _cameras.indexWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
      );
      _cameraIndex = back < 0 ? 0 : back;
      await _open(_cameras[_cameraIndex]);
    } on CameraException catch (error) {
      _fail(error);
    }
  }

  Future<void> _open(CameraDescription camera) async {
    final old = _controller;
    _controller = null;
    if (mounted) setState(() {});
    await old?.dispose();
    // 720p keeps three minutes of video well under MEYA's size limit.
    final controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: true,
    );
    try {
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _error = null;
      });
    } on CameraException catch (error) {
      await controller.dispose();
      _fail(error);
    }
  }

  void _fail(CameraException error) {
    if (!mounted) return;
    final denied = error.code.contains('Denied') ||
        error.code.contains('denied') ||
        error.code.contains('Restricted');
    setState(() {
      _error = denied
          ? context.tr('MEYA needs the camera and microphone to record. Allow them in the phone settings.')
          : context.tr('The camera could not start: {0}', [error.description ?? error.code]);
    });
  }

  Future<void> _record() async {
    final controller = _controller;
    if (controller == null || _busy) return;
    _busy = true;
    try {
      await controller.startVideoRecording();
      _elapsed = Duration.zero;
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        setState(() => _elapsed += const Duration(seconds: 1));
        if (_elapsed >= VideoRecorderPage.maxDuration) _stop();
      });
      setState(() => _recording = true);
    } on CameraException catch (error) {
      _fail(error);
    } finally {
      _busy = false;
    }
  }

  Future<void> _stop() async {
    final controller = _controller;
    if (controller == null || !_recording || _busy) return;
    _busy = true;
    _ticker?.cancel();
    try {
      final file = await controller.stopVideoRecording();
      if (mounted) Navigator.pop(context, file);
    } on CameraException catch (error) {
      setState(() => _recording = false);
      _fail(error);
    } finally {
      _busy = false;
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2 || _recording) return;
    _cameraIndex = (_cameraIndex + 1) % _cameras.length;
    await _open(_cameras[_cameraIndex]);
  }

  String _clock(Duration value) {
    final minutes = value.inMinutes.toString().padLeft(2, '0');
    final seconds = (value.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final remaining = VideoRecorderPage.maxDuration - _elapsed;

    return PopScope(
      canPop: !_recording,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          title: Text(context.tr('Record a video')),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
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
                          : CameraPreview(controller),
                ),
              ),
              Semantics(
                liveRegion: true,
                child: Text(
                  _recording
                      ? context.tr('{0} · {1} left', [_clock(_elapsed), _clock(remaining)])
                      : context.tr('Up to 3 minutes'),
                  style: TextStyle(
                    color: _recording ? Colors.redAccent : Colors.white70,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    const SizedBox(width: 56),
                    Semantics(
                      button: true,
                      label: _recording
                          ? context.tr('Stop recording')
                          : context.tr('Start recording'),
                      excludeSemantics: true,
                      child: GestureDetector(
                        onTap: controller == null
                            ? null
                            : (_recording ? _stop : _record),
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                          ),
                          alignment: Alignment.center,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: _recording ? 30 : 62,
                            height: _recording ? 30 : 62,
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(
                                _recording ? 6 : 31,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: context.tr('Switch camera'),
                      iconSize: 32,
                      color: Colors.white,
                      onPressed: _cameras.length > 1 && !_recording
                          ? _switchCamera
                          : null,
                      icon: const Icon(Icons.cameraswitch),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
