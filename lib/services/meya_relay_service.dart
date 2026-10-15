import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'device_identity_service.dart';
import 'relay_transport.dart';

class MeyaRelayService implements RelayTransport {
  static const String _relayUrl = String.fromEnvironment('MEYA_RELAY_URL');
  static const Duration _authenticationTimeout = Duration(seconds: 12);
  static const Duration _connectTimeout = Duration(seconds: 10);

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  bool _authenticated = false;

  @override
  Future<void> connect({
    required String deviceId,
    required void Function(Map<String, dynamic> message) onMessage,
    void Function(Object error)? onError,
    void Function()? onDone,
  }) async {
    await disconnect();
    final uri = _secureRelayUri(deviceId);
    debugPrint('MEYA relay: connecting to ${uri.scheme}://${uri.host}:${uri.port}${uri.path}');
    final channel = WebSocketChannel.connect(uri);
    _channel = channel;
    final authenticated = Completer<void>();
    var authenticationStarted = false;

    try {
      try {
        await channel.ready.timeout(_connectTimeout);
      } on TimeoutException {
        throw StateError(
          'Could not reach the MEYA relay at ${uri.host}:${uri.port} '
          'within ${_connectTimeout.inSeconds} seconds.',
        );
      } catch (error) {
        if (error is StateError) rethrow;
        throw StateError(
          'Could not reach the MEYA relay at ${uri.host}:${uri.port}: $error',
        );
      }
      _subscription = channel.stream.listen(
        (message) {
          try {
            final decoded = _decodeMessage(message);
            if (decoded == null) {
              return;
            }

            if (!_authenticated) {
              final type = decoded['type'];
              if (type == 'Challenge') {
                if (authenticationStarted) {
                  throw StateError(
                    'Relay sent more than one authentication challenge.',
                  );
                }
                authenticationStarted = true;
                _answerChallenge(deviceId, decoded, channel).catchError((
                  Object error,
                ) {
                  if (!authenticated.isCompleted) {
                    authenticated.completeError(error);
                  }
                });
                return;
              }
              if (type == 'Authenticated') {
                if (decoded['device_id'] != deviceId) {
                  throw StateError(
                    'Relay authenticated a different device ID.',
                  );
                }
                _authenticated = true;
                if (!authenticated.isCompleted) {
                  authenticated.complete();
                }
                return;
              }
              if (type == 'Error') {
                throw StateError(
                  'Relay rejected authentication: ${decoded['error'] ?? 'unknown error'}',
                );
              }
              throw StateError(
                'Unexpected relay message before authentication.',
              );
            }

            if (decoded['type'] == 'Challenge' ||
                decoded['type'] == 'Authenticated') {
              throw StateError(
                'Unexpected relay authentication message after authentication.',
              );
            }
            onMessage(decoded);
          } catch (error, stackTrace) {
            if (!authenticated.isCompleted) {
              authenticated.completeError(error, stackTrace);
            }
            onError?.call(error);
          }
        },
        onError: (Object error, StackTrace stackTrace) {
          if (!authenticated.isCompleted) {
            authenticated.completeError(error, stackTrace);
          }
          onError?.call(error);
        },
        onDone: () {
          _authenticated = false;
          _channel = null;
          _subscription = null;
          if (!authenticated.isCompleted) {
            authenticated.completeError(
              StateError('Relay disconnected before authentication completed.'),
            );
          }
          onDone?.call();
        },
        cancelOnError: false,
      );

      await authenticated.future.timeout(_authenticationTimeout);
      debugPrint('MEYA relay: authenticated connection established.');
    } catch (error) {
      await disconnect();
      debugPrint('MEYA relay: connection or authentication failed: $error');
      rethrow;
    }
  }

  Future<void> _answerChallenge(
    String deviceId,
    Map<String, dynamic> challenge,
    WebSocketChannel channel,
  ) async {
    final challengeDeviceId = challenge['device_id'];
    final nonce = challenge['nonce'];
    final registrationRequired = challenge['registration_required'];

    if (challengeDeviceId != deviceId ||
        nonce is! String ||
        nonce.isEmpty ||
        registrationRequired is! bool) {
      throw StateError('Relay authentication challenge is invalid.');
    }

    await DeviceIdentityService.ensureRelaySigningKeyPair();
    final publicKey = await DeviceIdentityService.getRelaySigningPublicKey();
    if (publicKey == null || publicKey.isEmpty) {
      throw StateError('MEYA relay signing public key is unavailable.');
    }

    final payload = utf8.encode(
      'MEYA relay authentication v1\n$deviceId\n$nonce',
    );
    final signature =
        await DeviceIdentityService.signRelayAuthenticationPayload(payload);

    if (registrationRequired) {
      channel.sink.add(
        jsonEncode({
          'type': 'Register',
          'public_key': publicKey,
          'signature': base64Encode(signature),
        }),
      );
    } else {
      channel.sink.add(
        jsonEncode({
          'type': 'Authenticate',
          'signature': base64Encode(signature),
        }),
      );
    }
  }

  @override
  Future<void> disconnect() async {
    _authenticated = false;
    final subscription = _subscription;
    _subscription = null;
    try {
      await subscription?.cancel().timeout(const Duration(seconds: 2));
    } catch (_) {}
    final channel = _channel;
    _channel = null;
    // Closing a socket that never finished connecting can wait forever, so
    // never let cleanup block the caller (or hide the original error).
    try {
      await channel?.sink.close().timeout(const Duration(seconds: 2));
    } catch (_) {}
  }

  @override
  Future<void> send(Map<String, dynamic> message) async {
    final channel = _channel;
    if (channel == null || !_authenticated) {
      throw StateError('MEYA relay is not authenticated.');
    }
    channel.sink.add(jsonEncode(message));
  }

  @override
  bool get isConnected => _channel != null && _authenticated;

  static Uri _secureRelayUri(String deviceId) {
    if (_relayUrl.isEmpty) {
      throw StateError('MEYA_RELAY_URL is required.');
    }

    final configuredUri = Uri.tryParse(_relayUrl);
    if (configuredUri == null || !configuredUri.hasAuthority) {
      throw StateError('MEYA_RELAY_URL must be an absolute WebSocket URL.');
    }

    final isSecure = configuredUri.scheme == 'wss';
    final isAllowedLocalDebug =
        kDebugMode &&
        configuredUri.scheme == 'ws' &&
        configuredUri.host == '127.0.0.1' &&
        configuredUri.port == 8787 &&
        configuredUri.path == '/v1/ws' &&
        configuredUri.userInfo.isEmpty &&
        configuredUri.query.isEmpty &&
        configuredUri.fragment.isEmpty;

    if (!isSecure && !isAllowedLocalDebug) {
      throw StateError(
        'MEYA_RELAY_URL must use wss://, except for the exact local debug endpoint ws://127.0.0.1:8787/v1/ws.',
      );
    }

    return configuredUri.replace(
      queryParameters: {
        ...configuredUri.queryParameters,
        'device_id': deviceId,
      },
    );
  }

  static Map<String, dynamic>? _decodeMessage(dynamic message) {
    if (message is String) {
      final decoded = jsonDecode(message);
      return decoded is Map<String, dynamic> ? decoded : null;
    }
    if (message is List<int>) {
      final decoded = jsonDecode(utf8.decode(message));
      return decoded is Map<String, dynamic> ? decoded : null;
    }
    return null;
  }

  static List<int> decodeEnvelopePayload(Map<String, dynamic> envelope) {
    final payload = envelope['payload'];
    if (payload is! String || payload.isEmpty) {
      throw StateError('MEYA envelope payload is missing or invalid.');
    }
    try {
      return base64Decode(payload);
    } on FormatException {
      throw StateError('MEYA envelope payload is not valid base64.');
    }
  }

  static Map<String, dynamic> decodeJsonPayload(Map<String, dynamic> envelope) {
    final bytes = decodeEnvelopePayload(envelope);
    final decoded = jsonDecode(utf8.decode(bytes));
    if (decoded is! Map<String, dynamic>) {
      throw StateError('MEYA envelope payload is not a JSON object.');
    }
    return decoded;
  }
}
