import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meya/services/meya_relay_session.dart';
import 'package:meya/services/relay_transport.dart';

/// Records what the session asks of the connection.
class FakeTransport implements RelayTransport {
  final calls = <String>[];
  bool connected = false;

  @override
  bool get isConnected => connected;

  @override
  Future<void> connect({
    required String deviceId,
    required void Function(Map<String, dynamic> message) onMessage,
    void Function(Object error)? onError,
    void Function()? onDone,
  }) async {
    calls.add('connect');
    connected = true;
  }

  @override
  Future<void> disconnect() async {
    calls.add('disconnect');
    connected = false;
  }

  @override
  Future<void> send(Map<String, dynamic> message) async {}
}

void main() {
  late FakeTransport transport;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({
      'meya_device_id': 'device-local',
      'meya_relay_signing_private_key': 'cHJpdmF0ZQ==',
      'meya_relay_signing_public_key': 'cHVibGlj',
    });
    transport = FakeTransport();
    MeyaRelaySession.instance.transportForTesting = transport;
  });

  test('a connection that looks alive is left as it is by keepConnected',
      () async {
    transport.connected = true;
    await MeyaRelaySession.instance.keepConnected();
    expect(transport.calls, isEmpty);
  });

  test('wake renews a connection that looks alive, so waiting messages '
      'are fetched even if it had silently died', () async {
    transport.connected = true;
    await MeyaRelaySession.instance.wake();
    expect(transport.calls, ['disconnect', 'connect']);
    expect(transport.isConnected, isTrue);
  });

  test('wake connects when there was no connection', () async {
    await MeyaRelaySession.instance.wake();
    expect(transport.calls, ['disconnect', 'connect']);
    expect(transport.isConnected, isTrue);
  });
}
