import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../database/meya_database.dart';
import 'meya_sound_settings.dart';

/// Where a live call is.
enum CallPhase { idle, outgoing, incoming, connecting, active, ended }

/// Why a call ended. Sent to the other person as `reason` in `call_end`.
enum CallEndReason { ended, cancelled, declined, busy, missed, failed }

/// The media side of a call (microphone, camera and the peer connection).
/// [WebRtcCallEngine] is the real one; tests use a fake.
abstract class CallEngine {
  /// Called with true once audio/video flows, false if the connection fails.
  void Function(bool connected)? onConnection;

  /// Opens the microphone (and camera) and returns an offer to send.
  Future<String> offer({required bool video});

  /// Opens the microphone (and camera) for [offer] and returns the answer.
  Future<String> answer(String offer, {required bool video});

  Future<void> acceptAnswer(String answer);
  Future<void> setMuted(bool muted);
  Future<void> setCameraOff(bool off);
  Future<void> switchCamera();
  Future<void> setSpeaker(bool on);
  Future<void> close();
}

typedef CallSignalSender = Future<void> Function(
  Contact contact,
  Map<String, Object> fields,
);

/// Live voice and video calls with one contact at a time.
///
/// Signalling (`call_offer`, `call_answer`, `call_end`) travels as silent,
/// end-to-end encrypted MEYA messages. The offer and answer carry the
/// WebRTC DTLS fingerprints, so the media stream is encrypted between the
/// two phones and cannot be redirected by the relay.
class MeyaCallService extends ChangeNotifier {
  MeyaCallService._();

  static final MeyaCallService instance = MeyaCallService._();

  /// How long a call rings before it counts as missed.
  static Duration ringTimeout = const Duration(seconds: 45);

  /// How long an accepted call may take to connect.
  static Duration connectTimeout = const Duration(seconds: 30);

  static const _kinds = {'call_offer', 'call_answer', 'call_end'};

  CallSignalSender? _send;
  CallEngine Function()? _createEngine;

  /// Shows the call screen for an incoming call.
  void Function()? onIncoming;

  /// Tells the person they missed a call.
  void Function(Contact contact)? onMissed;

  CallPhase _phase = CallPhase.idle;
  Contact? _contact;
  String? _callId;
  bool _video = false;
  String? _remoteOffer;
  CallEngine? _engine;
  DateTime? _connectedAt;
  CallEndReason? _endReason;
  bool _muted = false;
  bool _cameraOff = false;
  bool _speakerOn = false;
  Timer? _timer;
  Timer? _resetTimer;

  CallPhase get phase => _phase;
  Contact? get contact => _contact;
  bool get video => _video;
  bool get muted => _muted;
  bool get cameraOff => _cameraOff;
  bool get speakerOn => _speakerOn;
  DateTime? get connectedAt => _connectedAt;
  CallEndReason? get endReason => _endReason;
  CallEngine? get engine => _engine;

  /// True while a call is ringing or in progress.
  bool get inCall => _phase != CallPhase.idle && _phase != CallPhase.ended;

  void configure({
    required CallSignalSender send,
    required CallEngine Function() createEngine,
  }) {
    _send = send;
    _createEngine = createEngine;
  }

  static bool handles(Object? kind) => _kinds.contains(kind);

  /// Calls [contact]. Throws [StateError] if a call is already going on.
  Future<void> startCall(Contact contact, {required bool video}) async {
    if (inCall) throw StateError('A call is already in progress.');
    _begin(CallPhase.outgoing, contact, _newCallId(), video);
    final callId = _callId!;
    try {
      final engine = _attachEngine();
      final offer = await engine.offer(video: video);
      if (_callId != callId || _phase != CallPhase.outgoing) return;
      await _send!(contact, {
        'kind': 'call_offer',
        'call_id': callId,
        'video': video,
        'sdp': offer,
      });
      if (_callId != callId) return;
      _timer = Timer(ringTimeout, () {
        if (_callId == callId && _phase == CallPhase.outgoing) {
          _signalEnd(CallEndReason.missed);
        }
      });
    } catch (error) {
      debugPrint('MEYA call: could not start ($error).');
      if (_callId == callId) await _signalEnd(CallEndReason.failed);
    }
  }

  Future<void> accept() async {
    if (_phase != CallPhase.incoming) return;
    final callId = _callId!;
    _timer?.cancel();
    await MeyaSoundSettings.instance.stopRinging();
    _setPhase(CallPhase.connecting);
    try {
      final engine = _attachEngine();
      final answer = await engine.answer(_remoteOffer!, video: _video);
      if (_callId != callId) return;
      await _send!(_contact!, {
        'kind': 'call_answer',
        'call_id': callId,
        'sdp': answer,
      });
      _startConnectTimer(callId);
    } catch (error) {
      debugPrint('MEYA call: could not answer ($error).');
      if (_callId == callId) await _signalEnd(CallEndReason.failed);
    }
  }

  Future<void> decline() async {
    if (_phase == CallPhase.incoming) await _signalEnd(CallEndReason.declined);
  }

  /// Ends the call whatever its state.
  Future<void> hangUp() async {
    if (!inCall) return;
    await _signalEnd(
      _phase == CallPhase.outgoing
          ? CallEndReason.cancelled
          : CallEndReason.ended,
    );
  }

  Future<void> toggleMute() async {
    _muted = !_muted;
    notifyListeners();
    await _engine?.setMuted(_muted);
  }

  Future<void> toggleCamera() async {
    _cameraOff = !_cameraOff;
    notifyListeners();
    await _engine?.setCameraOff(_cameraOff);
  }

  Future<void> toggleSpeaker() async {
    _speakerOn = !_speakerOn;
    notifyListeners();
    await _engine?.setSpeaker(_speakerOn);
  }

  Future<void> switchCamera() async => _engine?.switchCamera();

  /// Handles `call_offer`, `call_answer` and `call_end` from [contact].
  Future<void> handleSignal(
    Contact contact,
    String senderDeviceId,
    Map<String, dynamic> content,
  ) async {
    final kind = content['kind'];
    final callId = content['call_id'];
    if (callId is! String || callId.isEmpty || callId.length > 64) return;

    switch (kind) {
      case 'call_offer':
        final sdp = content['sdp'];
        final video = content['video'];
        if (sdp is! String || video is! bool) return;
        await _onOffer(contact, callId, sdp, video, content['sent_at']);
      case 'call_answer':
        final sdp = content['sdp'];
        if (sdp is! String || !_isCurrent(contact, callId)) return;
        if (_phase != CallPhase.outgoing) return;
        _timer?.cancel();
        _setPhase(CallPhase.connecting);
        try {
          await _engine!.acceptAnswer(sdp);
          _startConnectTimer(callId);
        } catch (error) {
          debugPrint('MEYA call: bad answer ($error).');
          await _signalEnd(CallEndReason.failed);
        }
      case 'call_end':
        if (!_isCurrent(contact, callId)) return;
        final reason = CallEndReason.values.firstWhere(
          (value) => value.name == content['reason'],
          orElse: () => CallEndReason.ended,
        );
        final wasRinging = _phase == CallPhase.incoming;
        await _finish(reason);
        if (wasRinging) onMissed?.call(contact);
    }
  }

  Future<void> _onOffer(
    Contact contact,
    String callId,
    String sdp,
    bool video,
    Object? sentAt,
  ) async {
    // An offer that waited in the relay longer than a ring is a missed call.
    final sent = sentAt is String ? DateTime.tryParse(sentAt) : null;
    if (sent != null && DateTime.now().toUtc().difference(sent) > ringTimeout) {
      onMissed?.call(contact);
      return;
    }
    if (inCall) {
      await _sendQuietly(contact, {
        'kind': 'call_end',
        'call_id': callId,
        'reason': CallEndReason.busy.name,
      });
      return;
    }
    _begin(CallPhase.incoming, contact, callId, video);
    _remoteOffer = sdp;
    _timer = Timer(ringTimeout, () async {
      if (_callId == callId && _phase == CallPhase.incoming) {
        await _signalEnd(CallEndReason.missed);
        onMissed?.call(contact);
      }
    });
    unawaited(MeyaSoundSettings.instance.startRinging());
    onIncoming?.call();
  }

  bool _isCurrent(Contact contact, String callId) =>
      inCall && _callId == callId && _contact?.contactId == contact.contactId;

  void _begin(CallPhase phase, Contact contact, String callId, bool video) {
    _resetTimer?.cancel();
    _timer?.cancel();
    _phase = phase;
    _contact = contact;
    _callId = callId;
    _video = video;
    _remoteOffer = null;
    _connectedAt = null;
    _endReason = null;
    _muted = false;
    _cameraOff = false;
    _speakerOn = video;
    notifyListeners();
  }

  CallEngine _attachEngine() {
    final engine = _createEngine!();
    final callId = _callId;
    engine.onConnection = (connected) {
      if (_callId != callId || !inCall) return;
      if (connected) {
        _timer?.cancel();
        _connectedAt ??= DateTime.now();
        _setPhase(CallPhase.active);
      } else {
        _signalEnd(CallEndReason.failed);
      }
    };
    _engine = engine;
    return engine;
  }

  void _startConnectTimer(String callId) {
    _timer?.cancel();
    _timer = Timer(connectTimeout, () {
      if (_callId == callId && _phase == CallPhase.connecting) {
        _signalEnd(CallEndReason.failed);
      }
    });
  }

  /// Tells the other person the call is over, then ends it here.
  Future<void> _signalEnd(CallEndReason reason) async {
    final contact = _contact;
    final callId = _callId;
    await _finish(reason);
    if (contact != null && callId != null) {
      await _sendQuietly(contact, {
        'kind': 'call_end',
        'call_id': callId,
        'reason': reason.name,
      });
    }
  }

  Future<void> _finish(CallEndReason reason) async {
    if (!inCall) return;
    _timer?.cancel();
    final engine = _engine;
    _engine = null;
    _endReason = reason;
    _setPhase(CallPhase.ended);
    await MeyaSoundSettings.instance.stopRinging();
    try {
      await engine?.close();
    } catch (error) {
      debugPrint('MEYA call: close failed ($error).');
    }
    final callId = _callId;
    _resetTimer = Timer(const Duration(seconds: 2), () {
      if (_callId == callId && _phase == CallPhase.ended) {
        _phase = CallPhase.idle;
        _contact = null;
        _callId = null;
        notifyListeners();
      }
    });
  }

  Future<void> _sendQuietly(Contact contact, Map<String, Object> fields) async {
    try {
      await _send?.call(contact, fields);
    } catch (error) {
      debugPrint('MEYA call: could not send ${fields['kind']} ($error).');
    }
  }

  void _setPhase(CallPhase phase) {
    _phase = phase;
    notifyListeners();
  }

  static String _newCallId() {
    final random = Random.secure();
    return List.generate(16, (_) => random.nextInt(256))
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
  }

  /// Returns to idle immediately. For tests.
  @visibleForTesting
  void resetForTesting() {
    _timer?.cancel();
    _resetTimer?.cancel();
    _phase = CallPhase.idle;
    _contact = null;
    _callId = null;
    _engine = null;
    onIncoming = null;
    onMissed = null;
  }
}
