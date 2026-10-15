import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import 'meya_call_service.dart';
import 'meya_relay_session.dart';

/// The real call media: microphone, camera and a WebRTC peer connection.
///
/// Offers and answers are sent complete (all network candidates included),
/// so one encrypted message each way is enough to connect.
class WebRtcCallEngine extends CallEngine {
  /// Extra STUN servers, comma separated, used when the relay gives none.
  /// Override with `--dart-define=MEYA_STUN_URLS=stun:your.server:3478`.
  static const _stunUrls = String.fromEnvironment(
    'MEYA_STUN_URLS',
    defaultValue: 'stun:stun.cloudflare.com:3478',
  );

  /// A fixed TURN server, for self-hosting (e.g. coturn). Normally the relay
  /// hands out short-lived Cloudflare TURN credentials instead.
  static const _turnUrl = String.fromEnvironment('MEYA_TURN_URL');
  static const _turnUser = String.fromEnvironment('MEYA_TURN_USERNAME');
  static const _turnPassword = String.fromEnvironment('MEYA_TURN_PASSWORD');

  /// Where call servers come from; the relay by default. Tests replace it.
  static Future<List<Map<String, dynamic>>> Function() iceServerProvider =
      MeyaRelaySession.instance.requestIceServers;

  /// STUN/TURN servers for this call. TURN carries the call when the two
  /// phones cannot reach each other directly (many mobile networks); the
  /// media stays end-to-end encrypted (DTLS-SRTP) either way.
  static Future<Map<String, dynamic>> _configuration() async {
    var servers = <Map<String, dynamic>>[];
    try {
      servers = await iceServerProvider();
    } catch (error) {
      debugPrint('MEYA call: relay gave no call servers ($error).');
    }
    // Port 53 can time out on some networks; without trickle ICE it would
    // delay every call, so it is left out.
    servers = [
      for (final server in servers)
        {
          ...server,
          'urls': [
            for (final url in (server['urls'] is List
                ? server['urls'] as List
                : [server['urls']]))
              if (url is String && !url.contains(':53?') && !url.endsWith(':53'))
                url,
          ],
        },
    ].where((server) => (server['urls'] as List).isNotEmpty).toList();
    return {
      'iceServers': [
        ...servers,
        if (servers.isEmpty)
          for (final url in _stunUrls.split(','))
            if (url.trim().isNotEmpty) {'urls': url.trim()},
        if (_turnUrl.isNotEmpty)
          {
            'urls': _turnUrl,
            'username': _turnUser,
            'credential': _turnPassword,
          },
      ],
      'sdpSemantics': 'unified-plan',
    };
  }

  static const _gatherTimeout = Duration(seconds: 4);
  static const _disconnectGrace = Duration(seconds: 10);

  final RTCVideoRenderer localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer remoteRenderer = RTCVideoRenderer();

  /// Bumped when a video stream appears, so the call screen redraws.
  final ValueNotifier<int> videoChanged = ValueNotifier(0);

  RTCPeerConnection? _connection;
  MediaStream? _local;
  Timer? _disconnectTimer;
  bool _closed = false;


  @override
  Future<String> offer({required bool video}) async {
    final connection = await _open(video: video);
    final offer = await connection.createOffer();
    return _setLocalAndGather(connection, offer);
  }

  @override
  Future<String> answer(String offer, {required bool video}) async {
    final connection = await _open(video: video);
    await connection.setRemoteDescription(RTCSessionDescription(offer, 'offer'));
    final answer = await connection.createAnswer();
    return _setLocalAndGather(connection, answer);
  }

  @override
  Future<void> acceptAnswer(String answer) async {
    await _connection!
        .setRemoteDescription(RTCSessionDescription(answer, 'answer'));
  }

  Future<RTCPeerConnection> _open({required bool video}) async {
    await localRenderer.initialize();
    await remoteRenderer.initialize();

    final local = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': video
          ? {
              'facingMode': 'user',
              'width': {'ideal': 1280},
              'height': {'ideal': 720},
            }
          : false,
    });
    _local = local;
    if (video) localRenderer.srcObject = local;

    final connection = await createPeerConnection(await _configuration());
    _connection = connection;
    for (final track in local.getTracks()) {
      await connection.addTrack(track, local);
    }
    connection.onTrack = (event) {
      if (_closed || event.streams.isEmpty) return;
      remoteRenderer.srcObject = event.streams.first;
      videoChanged.value++;
    };
    connection.onConnectionState = _onState;
    await setSpeaker(video);
    return connection;
  }

  Future<String> _setLocalAndGather(
    RTCPeerConnection connection,
    RTCSessionDescription description,
  ) async {
    final gathered = Completer<void>();
    connection.onIceGatheringState = (state) {
      if (state == RTCIceGatheringState.RTCIceGatheringStateComplete &&
          !gathered.isCompleted) {
        gathered.complete();
      }
    };
    await connection.setLocalDescription(description);
    // Send whatever has been found after a few seconds rather than wait
    // for slow or unreachable STUN servers.
    await gathered.future.timeout(_gatherTimeout, onTimeout: () {});
    final complete = await connection.getLocalDescription();
    return (complete ?? description).sdp!;
  }

  void _onState(RTCPeerConnectionState state) {
    switch (state) {
      case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
        _disconnectTimer?.cancel();
        onConnection?.call(true);
      case RTCPeerConnectionState.RTCPeerConnectionStateDisconnected:
        // Often recovers by itself (e.g. Wi-Fi to mobile data).
        _disconnectTimer ??= Timer(_disconnectGrace, () {
          if (!_closed) onConnection?.call(false);
        });
      case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
        onConnection?.call(false);
      default:
        break;
    }
  }

  @override
  Future<void> setMuted(bool muted) async {
    for (final track in _local?.getAudioTracks() ?? <MediaStreamTrack>[]) {
      track.enabled = !muted;
    }
  }

  @override
  Future<void> setCameraOff(bool off) async {
    for (final track in _local?.getVideoTracks() ?? <MediaStreamTrack>[]) {
      track.enabled = !off;
    }
  }

  @override
  Future<void> switchCamera() async {
    final tracks = _local?.getVideoTracks() ?? <MediaStreamTrack>[];
    if (tracks.isNotEmpty) await Helper.switchCamera(tracks.first);
  }

  @override
  Future<void> setSpeaker(bool on) async {
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS)) {
      return;
    }
    try {
      await Helper.setSpeakerphoneOn(on);
    } catch (error) {
      debugPrint('MEYA call: speaker switch failed ($error).');
    }
  }

  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    _disconnectTimer?.cancel();
    for (final track in _local?.getTracks() ?? <MediaStreamTrack>[]) {
      await track.stop();
    }
    await _local?.dispose();
    await _connection?.close();
    await _connection?.dispose();
    localRenderer.srcObject = null;
    remoteRenderer.srcObject = null;
    await localRenderer.dispose();
    await remoteRenderer.dispose();
    videoChanged.dispose();
  }
}
