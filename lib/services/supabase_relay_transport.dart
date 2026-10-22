import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'device_identity_service.dart';
import 'meya_secure_storage.dart';
import 'relay_transport.dart';

/// Reaches other phones through Supabase instead of the self-hosted relay.
///
/// Envelopes (already end-to-end encrypted) go into the `envelopes` table;
/// row-level security lets a phone send only as itself and read only what is
/// addressed to it. Supabase Realtime announces new rows; the phone then
/// fetches and handles them, and deletes each one once handled.
///
/// Configure with
///   --dart-define=MEYA_SUPABASE_URL=https://<project>.supabase.co
///   --dart-define=MEYA_SUPABASE_KEY=<publishable key>
class SupabaseRelayTransport implements RelayTransport {
  static const url = String.fromEnvironment('MEYA_SUPABASE_URL');
  static const publishableKey = String.fromEnvironment('MEYA_SUPABASE_KEY');

  static bool get configured => url.isNotEmpty && publishableKey.isNotEmpty;

  static bool _initialized = false;

  /// Set once the server turns out not to have the `notify` column yet.
  static bool _noNotifyColumn = false;

  RealtimeChannel? _channel;
  String? _deviceId;
  bool _connected = false;
  void Function(Map<String, dynamic>)? _onMessage;
  void Function(Object)? _onError;
  void Function()? _onDone;

  /// Envelopes handed over but not yet acknowledged, so a refetch does not
  /// hand them over twice.
  final Set<String> _inFlight = {};
  bool _fetching = false;
  bool _fetchAgain = false;

  SupabaseClient get _client => Supabase.instance.client;

  @override
  bool get isConnected => _connected;

  /// Saves this phone's push token, so the server can wake it with an empty
  /// push when something it should see arrives.
  static Future<void> registerPushToken(String deviceId, String token) async {
    await _ensureInitialized();
    if (Supabase.instance.client.auth.currentSession == null) return;
    await Supabase.instance.client.from('push_tokens').upsert({
      'device_id': deviceId,
      'token': token,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  /// For a push received while MEYA is closed: the waiting envelopes that
  /// should alert, as (envelope ID, sender device ID, 'message' | 'invite' |
  /// 'call'). Nothing is decrypted, handled or deleted here; MEYA does that
  /// when it opens.
  static Future<List<(String, String, String)>> pendingAlerts(
    String deviceId,
  ) async {
    await _ensureInitialized();
    if (Supabase.instance.client.auth.currentSession == null) return const [];
    final rows = await Supabase.instance.client
        .from('envelopes')
        .select('id, sender_device_id, notify')
        .eq('recipient_device_id', deviceId)
        .not('notify', 'is', null)
        .order('created_at')
        .limit(50);
    return [
      for (final row in rows)
        (
          row['id'] as String,
          row['sender_device_id'] as String,
          row['notify'] as String,
        ),
    ];
  }

  static Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await Supabase.initialize(
      url: url,
      anonKey: publishableKey,
      authOptions: const FlutterAuthClientOptions(
        localStorage: _SecureSessionStorage(),
      ),
      // By default Supabase closes the live connection as soon as MEYA goes
      // to the background, so nothing arrives (and nothing can be notified)
      // until it is opened again. Keep it open until the phone itself
      // closes it; MeyaRelaySession reconnects when MEYA resumes.
      realtimeLifecycleOptions: const RealtimeLifecycleOptions.manual(),
    );
    _initialized = true;
  }

  @override
  Future<void> connect({
    required String deviceId,
    required void Function(Map<String, dynamic> message) onMessage,
    void Function(Object error)? onError,
    void Function()? onDone,
  }) async {
    await disconnect();
    _deviceId = deviceId;
    _onMessage = onMessage;
    _onError = onError;
    _onDone = onDone;

    await _ensureInitialized();
    final auth = _client.auth;
    if (auth.currentSession == null) {
      // No email or phone number: the device's own key identifies it.
      await auth.signInAnonymously();
    }
    await _bindDevice(deviceId);

    final ready = Completer<void>();
    final channel = _client
        .channel('envelopes:$deviceId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'envelopes',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'recipient_device_id',
            value: deviceId,
          ),
          // Large rows may arrive without their payload, so the row is
          // fetched rather than read from the event.
          callback: (_) => _fetchPending(),
        );
    _channel = channel;
    channel.subscribe((status, error) {
      switch (status) {
        case RealtimeSubscribeStatus.subscribed:
          _connected = true;
          if (!ready.isCompleted) ready.complete();
          _fetchPending();
        case RealtimeSubscribeStatus.channelError:
        case RealtimeSubscribeStatus.timedOut:
          final failure = error ?? StateError('Supabase realtime $status');
          if (!ready.isCompleted) {
            ready.completeError(failure);
          } else if (_connected) {
            _connected = false;
            _onError?.call(failure);
          }
        case RealtimeSubscribeStatus.closed:
          if (_connected) {
            _connected = false;
            _onDone?.call();
          }
      }
    });

    try {
      await ready.future.timeout(const Duration(seconds: 15));
      debugPrint('MEYA relay: connected through Supabase.');
    } catch (error) {
      await disconnect();
      rethrow;
    }
  }

  /// Proves this phone owns [deviceId] by signing with its relay key.
  Future<void> _bindDevice(String deviceId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw StateError('Supabase sign-in failed.');
    await DeviceIdentityService.ensureRelaySigningKeyPair();
    final publicKey = await DeviceIdentityService.getRelaySigningPublicKey();
    if (publicKey == null || publicKey.isEmpty) {
      throw StateError('MEYA relay signing public key is unavailable.');
    }
    final signature = await DeviceIdentityService.signRelayAuthenticationPayload(
      utf8.encode('MEYA supabase binding v1\n$deviceId\n$userId'),
    );
    final response = await _client.functions.invoke(
      'register-device',
      body: {
        'device_id': deviceId,
        'public_key': publicKey,
        'signature': base64Encode(signature),
      },
    );
    if (response.status != 200) {
      throw StateError('MEYA device registration failed (${response.status}).');
    }
  }

  /// Hands over every envelope waiting for this phone, oldest first.
  Future<void> _fetchPending() async {
    if (_fetching) {
      _fetchAgain = true;
      return;
    }
    _fetching = true;
    try {
      do {
        _fetchAgain = false;
        final rows = await _client
            .from('envelopes')
            .select('id, sender_device_id, recipient_device_id, payload')
            .eq('recipient_device_id', _deviceId!)
            .order('created_at')
            .limit(100);
        for (final row in rows) {
          final id = row['id'] as String;
          if (!_inFlight.add(id)) continue;
          _onMessage?.call({
            'type': 'Envelope',
            'envelope': {
              'id': id,
              'sender_device_id': row['sender_device_id'],
              'recipient_device_id': row['recipient_device_id'],
              'payload': row['payload'],
            },
          });
        }
        if (rows.length == 100) _fetchAgain = true;
      } while (_fetchAgain && _connected);
    } catch (error) {
      debugPrint('MEYA relay: fetching envelopes failed ($error).');
      _onError?.call(error);
    } finally {
      _fetching = false;
    }
  }

  @override
  Future<void> send(Map<String, dynamic> message) async {
    if (!_connected) throw StateError('MEYA relay is not authenticated.');
    switch (message['type']) {
      case 'Send':
        final envelope = message['envelope'] as Map<String, dynamic>;
        try {
          final notify = envelope['notify'];
          final row = {
            'id': envelope['id'],
            'sender_device_id': envelope['sender_device_id'],
            'recipient_device_id': envelope['recipient_device_id'],
            'payload': envelope['payload'],
          };
          try {
            await _client.from('envelopes').insert({
              ...row,
              if (notify is String && !_noNotifyColumn) 'notify': notify,
            });
          } on PostgrestException catch (error) {
            // A server without wake-up pushes yet has no `notify` column:
            // send without it rather than failing the message.
            if (error.code != 'PGRST204') rethrow;
            _noNotifyColumn = true;
            await _client.from('envelopes').insert(row);
          }
        } on PostgrestException catch (error) {
          // Already waiting for the recipient (a retry): nothing to do.
          if (error.code != '23505') rethrow;
        }
      case 'Ack':
        final id = message['envelope_id'] as String;
        await _client
            .from('envelopes')
            .delete()
            .eq('recipient_device_id', _deviceId!)
            .eq('id', id);
        _inFlight.remove(id);
      case 'TurnRequest':
        final response = await _client.functions.invoke('turn-credentials');
        final data = response.data;
        _onMessage?.call({
          'type': 'TurnServers',
          'ice_servers': data is Map ? data['ice_servers'] : null,
        });
      default:
        throw ArgumentError('Unknown relay message ${message['type']}');
    }
  }

  @override
  Future<void> disconnect() async {
    _connected = false;
    _inFlight.clear();
    final channel = _channel;
    _channel = null;
    if (channel != null) {
      try {
        await _client.removeChannel(channel);
      } catch (_) {}
    }
  }
}

/// Keeps the Supabase sign-in in secure storage instead of plain app
/// preferences, so it is never readable by other apps or copied in backups.
class _SecureSessionStorage extends LocalStorage {
  const _SecureSessionStorage();

  static const _key = 'meya_supabase_session';

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> hasAccessToken() => meyaSecureStorage.containsKey(key: _key);

  @override
  Future<String?> accessToken() => meyaSecureStorage.read(key: _key);

  @override
  Future<void> removePersistedSession() => meyaSecureStorage.delete(key: _key);

  @override
  Future<void> persistSession(String persistSessionString) =>
      meyaSecureStorage.write(key: _key, value: persistSessionString);
}
