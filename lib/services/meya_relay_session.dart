import 'dart:async';

import 'package:flutter/foundation.dart';

import 'device_identity_service.dart';
import 'meya_relay_service.dart';
import 'relay_transport.dart';
import 'supabase_relay_transport.dart';

class MeyaRelaySession {
  MeyaRelaySession._();

  static final MeyaRelaySession instance = MeyaRelaySession._();

  /// Supabase when configured at build time, otherwise the self-hosted relay.
  RelayTransport _relay = SupabaseRelayTransport.configured
      ? SupabaseRelayTransport()
      : MeyaRelayService();

  /// Replaces the connection with a stand-in (tests only).
  @visibleForTesting
  set transportForTesting(RelayTransport transport) => _relay = transport;
  final Set<void Function(Map<String, dynamic>)> _messageListeners = {};
  final Set<void Function(Object)> _errorListeners = {};
  final Set<void Function()> _doneListeners = {};
  final Set<void Function()> _connectedListeners = {};
  final Set<String> _pendingAcknowledgements = {};

  Future<void>? _startFuture;

  /// While true, a dropped connection is retried with growing pauses
  /// (1 s, 2 s, 4 s … up to 30 s).
  bool _keepConnected = false;
  Timer? _retryTimer;
  int _retryAttempt = 0;

  bool get isConnected => _relay.isConnected;

  void addMessageListener(void Function(Map<String, dynamic>) listener) {
    _messageListeners.add(listener);
  }

  void removeMessageListener(void Function(Map<String, dynamic>) listener) {
    _messageListeners.remove(listener);
  }

  void addErrorListener(void Function(Object) listener) {
    _errorListeners.add(listener);
  }

  void removeErrorListener(void Function(Object) listener) {
    _errorListeners.remove(listener);
  }

  void addDoneListener(void Function() listener) {
    _doneListeners.add(listener);
  }

  void removeDoneListener(void Function() listener) {
    _doneListeners.remove(listener);
  }

  /// Called every time the relay (re)connects, e.g. to send queued messages.
  void addConnectedListener(void Function() listener) {
    _connectedListeners.add(listener);
  }

  void removeConnectedListener(void Function() listener) {
    _connectedListeners.remove(listener);
  }

  /// Connects now and reconnects automatically until [stop].
  Future<void> keepConnected() async {
    _keepConnected = true;
    _retryTimer?.cancel();
    try {
      await start();
    } catch (error) {
      _scheduleReconnect();
      rethrow;
    }
  }

  /// Something is waiting on the relay (a push arrived, or MEYA came back
  /// to the screen): reconnect and fetch it now. A connection kept open in
  /// the background can be dead without anything noticing, in which case
  /// [keepConnected] alone would do nothing, so the connection is renewed.
  Future<void> wake() async {
    _keepConnected = true;
    _retryTimer?.cancel();
    if (_startFuture == null) {
      try {
        await _relay.disconnect();
      } catch (error) {
        debugPrint('MEYA relay: closing the old connection failed ($error).');
      }
    }
    try {
      await start();
    } catch (error) {
      _scheduleReconnect();
      rethrow;
    }
  }

  void _scheduleReconnect() {
    if (!_keepConnected || _relay.isConnected) return;
    if (_retryTimer?.isActive ?? false) return;
    final seconds = 1 << _retryAttempt.clamp(0, 5);
    _retryAttempt++;
    _retryTimer = Timer(Duration(seconds: seconds.clamp(1, 30)), () async {
      try {
        await start();
      } catch (error) {
        debugPrint('MEYA relay: reconnect failed ($error).');
        _scheduleReconnect();
      }
    });
  }

  void _notifyConnected() {
    _retryAttempt = 0;
    for (final listener in _connectedListeners.toList()) {
      try {
        listener();
      } catch (error) {
        debugPrint('MEYA session connected listener failed: $error');
      }
    }
  }

  Future<void> start() async {
    if (_relay.isConnected) {
      _flushPendingAcknowledgements();
      return;
    }

    final existingStart = _startFuture;
    if (existingStart != null) {
      await existingStart;
      return;
    }

    final future = _connect();
    _startFuture = future;
    try {
      await future;
      _flushPendingAcknowledgements();
      _notifyConnected();
    } finally {
      if (identical(_startFuture, future)) {
        _startFuture = null;
      }
    }
  }

  Future<void> _connect() async {
    final deviceId = await DeviceIdentityService.getDeviceId();
    if (deviceId == null || deviceId.isEmpty) {
      throw StateError('MEYA device ID is not available.');
    }

    await DeviceIdentityService.ensureRelaySigningKeyPair();
    await _relay.connect(
      deviceId: deviceId,
      onMessage: _dispatchMessage,
      onError: _dispatchError,
      onDone: _dispatchDone,
    );
  }

  void _dispatchMessage(Map<String, dynamic> message) {
    if (message['type'] == 'TurnServers') {
      final waiting = _iceWaiter;
      _iceWaiter = null;
      final servers = message['ice_servers'];
      if (waiting != null && !waiting.isCompleted) {
        waiting.complete(
          servers is List
              ? [for (final s in servers) if (s is Map) s.cast<String, dynamic>()]
              : const [],
        );
      }
      return;
    }
    for (final listener in _messageListeners.toList()) {
      try {
        listener(message);
      } catch (error, stackTrace) {
        debugPrint('MEYA session message listener failed: $error');
        debugPrintStack(stackTrace: stackTrace);
        _dispatchError(error);
      }
    }
  }

  void _dispatchError(Object error) {
    _scheduleReconnect();
    for (final listener in _errorListeners.toList()) {
      try {
        listener(error);
      } catch (listenerError, stackTrace) {
        debugPrint('MEYA session error listener failed: $listenerError');
        debugPrintStack(stackTrace: stackTrace);
      }
    }
  }

  void _dispatchDone() {
    _scheduleReconnect();
    for (final listener in _doneListeners.toList()) {
      try {
        listener();
      } catch (error, stackTrace) {
        debugPrint('MEYA session done listener failed: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
    }
  }

  Future<void> sendWhenConnected({required Map<String, dynamic> message}) async {
    await start();
    if (!_relay.isConnected) {
      throw StateError('MEYA relay is not authenticated.');
    }
    await _relay.send(message);
  }

  Future<void> send(Map<String, dynamic> message) {
    if (!_relay.isConnected) {
      throw StateError('MEYA relay is not authenticated.');
    }
    return _relay.send(message);
  }

  void acknowledge(String envelopeId) {
    if (envelopeId.isEmpty) {
      return;
    }
    _pendingAcknowledgements.add(envelopeId);
    _flushPendingAcknowledgements();
  }

  bool _flushing = false;

  Future<void> _flushPendingAcknowledgements() async {
    if (_flushing || !_relay.isConnected || _pendingAcknowledgements.isEmpty) {
      return;
    }
    _flushing = true;
    try {
      await _flushAcknowledgements();
    } finally {
      _flushing = false;
    }
  }

  Future<void> _flushAcknowledgements() async {
    for (final envelopeId in _pendingAcknowledgements.toList()) {
      try {
        await _relay.send({
          'type': 'Ack',
          'envelope_id': envelopeId,
        });
        _pendingAcknowledgements.remove(envelopeId);
      } catch (error) {
        _dispatchError(error);
        return;
      }
    }
  }

  Completer<List<Map<String, dynamic>>>? _iceWaiter;

  /// The last call servers and until when they may be reused. TURN
  /// credentials last four hours; STUN-only answers (no TURN configured, or
  /// asked too often) are kept briefly so a later call can still get TURN.
  List<Map<String, dynamic>>? _iceCache;
  DateTime _iceCacheUntil = DateTime.fromMillisecondsSinceEpoch(0);
  Future<List<Map<String, dynamic>>>? _iceFetch;

  static bool _hasTurn(List<Map<String, dynamic>> servers) => servers.any(
        (server) => [
          if (server['urls'] is List) ...server['urls'] as List else server['urls'],
        ].any((url) => url is String && url.startsWith('turn')),
      );

  /// Fetches call servers ahead of time so a call does not wait for them.
  Future<void> prefetchIceServers() async {
    try {
      await requestIceServers();
    } catch (_) {}
  }

  /// STUN and TURN servers for a call. The relay asks Cloudflare for
  /// short-lived TURN credentials; empty when offline or not answered.
  Future<List<Map<String, dynamic>>> requestIceServers({
    Duration timeout = const Duration(seconds: 5),
  }) {
    final cached = _iceCache;
    if (cached != null && DateTime.now().isBefore(_iceCacheUntil)) {
      return Future.value(cached);
    }
    return _iceFetch ??= _fetchIceServers(timeout).whenComplete(() {
      _iceFetch = null;
    });
  }

  Future<List<Map<String, dynamic>>> _fetchIceServers(Duration timeout) async {
    if (!_relay.isConnected) return _iceCache ?? const [];
    final waiter = _iceWaiter ??= Completer<List<Map<String, dynamic>>>();
    try {
      await _relay.send({'type': 'TurnRequest'});
      final servers =
          await waiter.future.timeout(timeout, onTimeout: () => const []);
      if (servers.isNotEmpty) {
        _iceCache = servers;
        _iceCacheUntil = DateTime.now().add(
          _hasTurn(servers)
              ? const Duration(hours: 3, minutes: 30)
              : const Duration(minutes: 1),
        );
      }
      return servers.isNotEmpty ? servers : _iceCache ?? const [];
    } catch (error) {
      debugPrint('MEYA relay: no ICE servers ($error).');
      return _iceCache ?? const [];
    } finally {
      if (identical(_iceWaiter, waiter)) _iceWaiter = null;
    }
  }

  Future<void> stop() {
    _keepConnected = false;
    _retryTimer?.cancel();
    return _relay.disconnect();
  }
}
