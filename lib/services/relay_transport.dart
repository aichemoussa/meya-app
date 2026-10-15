/// How MEYA reaches other phones: the self-hosted relay (WebSocket) or
/// Supabase. Both carry the same end-to-end encrypted envelopes and speak
/// the same messages:
///   out: {type: Send, envelope}, {type: Ack, envelope_id}, {type: TurnRequest}
///   in:  {type: Envelope, envelope}, {type: TurnServers, ice_servers}
abstract class RelayTransport {
  bool get isConnected;

  Future<void> connect({
    required String deviceId,
    required void Function(Map<String, dynamic> message) onMessage,
    void Function(Object error)? onError,
    void Function()? onDone,
  });

  /// Completes when the message has been handed over; throws when it could
  /// not be (offline), so the caller can queue it.
  Future<void> send(Map<String, dynamic> message);

  Future<void> disconnect();
}
