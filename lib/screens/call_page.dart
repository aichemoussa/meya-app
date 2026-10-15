import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../database/meya_database.dart';
import '../l10n/meya_strings.dart';
import '../services/meya_call_service.dart';
import '../services/webrtc_call_engine.dart';

/// Starts a call with [contact] and shows the call screen. Shows a message
/// instead if a call is already going on.
Future<void> startCallWith(
  BuildContext context,
  Contact contact, {
  required bool video,
}) async {
  final calls = MeyaCallService.instance;
  if (calls.inCall) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.tr('You are already in a call.'))),
    );
    return;
  }
  unawaited(calls.startCall(contact, video: video));
  await Navigator.of(context).push(CallPage.route());
}

/// The screen for a ringing, connecting or ongoing call. Closes itself
/// shortly after the call ends.
class CallPage extends StatefulWidget {
  const CallPage({super.key});

  static const routeName = '/call';

  static Route<void> route() => MaterialPageRoute<void>(
        settings: const RouteSettings(name: routeName),
        fullscreenDialog: true,
        builder: (_) => const CallPage(),
      );

  @override
  State<CallPage> createState() => _CallPageState();
}

class _CallPageState extends State<CallPage> {
  final _calls = MeyaCallService.instance;
  Timer? _clock;
  Timer? _close;

  @override
  void initState() {
    super.initState();
    _calls.addListener(_onChange);
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_calls.phase == CallPhase.active) setState(() {});
    });
    _onChange();
  }

  @override
  void dispose() {
    _calls.removeListener(_onChange);
    _clock?.cancel();
    _close?.cancel();
    super.dispose();
  }

  void _onChange() {
    final phase = _calls.phase;
    if ((phase == CallPhase.ended || phase == CallPhase.idle) &&
        _close == null) {
      _close = Timer(const Duration(milliseconds: 1500), () {
        if (mounted) Navigator.of(context).maybePop();
      });
    }
    if (mounted) setState(() {});
  }

  String _status(BuildContext context) {
    switch (_calls.phase) {
      case CallPhase.outgoing:
        return context.tr('Calling…');
      case CallPhase.incoming:
        return _calls.video
            ? context.tr('Video call')
            : context.tr('Voice call');
      case CallPhase.connecting:
        return context.tr('Connecting…');
      case CallPhase.active:
        final since = _calls.connectedAt ?? DateTime.now();
        final seconds = DateTime.now().difference(since).inSeconds;
        final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
        return '$minutes:${(seconds % 60).toString().padLeft(2, '0')}';
      case CallPhase.ended:
      case CallPhase.idle:
        return switch (_calls.endReason) {
          CallEndReason.declined => context.tr('Declined'),
          CallEndReason.busy => context.tr('Busy'),
          CallEndReason.missed => context.tr('No answer'),
          CallEndReason.failed => context.tr('Call failed'),
          _ => context.tr('Call ended'),
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    final contact = _calls.contact;
    final name = contact?.displayName ?? '';
    final engine = _calls.engine;
    final showVideo = _calls.video &&
        engine is WebRtcCallEngine &&
        _calls.phase != CallPhase.ended;

    return PopScope(
      canPop: !_calls.inCall,
      child: Scaffold(
        backgroundColor: const Color(0xFF0D1B2A),
        body: Stack(
          fit: StackFit.expand,
          children: [
            if (showVideo)
              ValueListenableBuilder<int>(
                valueListenable: engine.videoChanged,
                builder: (context, _, _) => RTCVideoView(
                  engine.remoteRenderer,
                  objectFit:
                      RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                ),
              ),
            SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 32),
                  if (!showVideo || _calls.phase != CallPhase.active) ...[
                    CircleAvatar(
                      radius: 48,
                      backgroundColor: Colors.white24,
                      child: Text(
                        name.isEmpty ? '?' : name.substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          fontSize: 40,
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Text(
                    name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      shadows: [Shadow(blurRadius: 6)],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      _status(context),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        shadows: [Shadow(blurRadius: 6)],
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.lock_outline,
                          size: 14, color: Colors.white70),
                      const SizedBox(width: 4),
                      Text(
                        context.tr('End-to-end encrypted'),
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                  const Spacer(),
                  if (showVideo && !_calls.cameraOff)
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: Padding(
                        padding: const EdgeInsetsDirectional.only(
                          end: 16,
                          bottom: 16,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: SizedBox(
                            width: 110,
                            height: 160,
                            child: RTCVideoView(
                              engine.localRenderer,
                              mirror: true,
                              objectFit: RTCVideoViewObjectFit
                                  .RTCVideoViewObjectFitCover,
                            ),
                          ),
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                    child: _calls.phase == CallPhase.incoming
                        ? _IncomingButtons(calls: _calls)
                        : _CallButtons(calls: _calls),
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

class _IncomingButtons extends StatelessWidget {
  final MeyaCallService calls;

  const _IncomingButtons({required this.calls});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _RoundButton(
          icon: Icons.call_end,
          label: context.tr('Decline'),
          color: const Color(0xFFD32F2F),
          onPressed: calls.decline,
        ),
        _RoundButton(
          icon: calls.video ? Icons.videocam : Icons.call,
          label: context.tr('Accept'),
          color: const Color(0xFF2E7D32),
          onPressed: calls.accept,
        ),
      ],
    );
  }
}

class _CallButtons extends StatelessWidget {
  final MeyaCallService calls;

  const _CallButtons({required this.calls});

  @override
  Widget build(BuildContext context) {
    final live = calls.inCall;
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 18,
      runSpacing: 16,
      children: [
        _RoundButton(
          icon: calls.muted ? Icons.mic_off : Icons.mic,
          label: calls.muted ? context.tr('Unmute') : context.tr('Mute'),
          selected: calls.muted,
          onPressed: live ? calls.toggleMute : null,
        ),
        _RoundButton(
          icon: Icons.volume_up,
          label: context.tr('Speaker'),
          selected: calls.speakerOn,
          onPressed: live ? calls.toggleSpeaker : null,
        ),
        if (calls.video) ...[
          _RoundButton(
            icon: calls.cameraOff ? Icons.videocam_off : Icons.videocam,
            label: calls.cameraOff
                ? context.tr('Camera on')
                : context.tr('Camera off'),
            selected: calls.cameraOff,
            onPressed: live ? calls.toggleCamera : null,
          ),
          _RoundButton(
            icon: Icons.cameraswitch,
            label: context.tr('Switch camera'),
            onPressed: live && !calls.cameraOff ? calls.switchCamera : null,
          ),
        ],
        _RoundButton(
          icon: Icons.call_end,
          label: context.tr('End call'),
          color: const Color(0xFFD32F2F),
          onPressed: live ? calls.hangUp : null,
        ),
      ],
    );
  }
}

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final bool selected;
  final VoidCallback? onPressed;

  const _RoundButton({
    required this.icon,
    required this.label,
    this.color,
    this.selected = false,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final background =
        color ?? (selected ? Colors.white : Colors.white.withValues(alpha: 0.18));
    final foreground =
        color != null ? Colors.white : (selected ? Colors.black : Colors.white);
    return SizedBox(
      width: 76,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            button: true,
            toggled: color == null ? selected : null,
            label: label,
            excludeSemantics: true,
            child: Material(
              color: onPressed == null
                  ? background.withValues(alpha: 0.4)
                  : background,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onPressed,
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child: Icon(icon, color: foreground, size: 30),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
