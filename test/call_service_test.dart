import 'package:flutter_test/flutter_test.dart';
import 'package:meya/database/meya_database.dart';
import 'package:meya/services/meya_call_service.dart';

class FakeEngine extends CallEngine {
  final calls = <String>[];
  String? receivedOffer;
  String? receivedAnswer;
  bool closed = false;

  @override
  Future<String> offer({required bool video}) async {
    calls.add('offer video=$video');
    return 'OFFER-SDP';
  }

  @override
  Future<String> answer(String offer, {required bool video}) async {
    receivedOffer = offer;
    return 'ANSWER-SDP';
  }

  @override
  Future<void> acceptAnswer(String answer) async => receivedAnswer = answer;

  @override
  Future<void> setMuted(bool muted) async => calls.add('muted=$muted');

  @override
  Future<void> setCameraOff(bool off) async => calls.add('cameraOff=$off');

  @override
  Future<void> switchCamera() async => calls.add('switch');

  @override
  Future<void> setSpeaker(bool on) async => calls.add('speaker=$on');

  @override
  Future<void> close() async => closed = true;
}

Contact contactNamed(String id) => Contact(
      contactId: id,
      identityId: 'identity-$id',
      displayName: 'Ana $id',
      identityPublicKey: 'key',
      trustState: 'trusted',
      createdAt: '2026-10-14T00:00:00Z',
      updatedAt: '2026-10-14T00:00:00Z',
      isRevoked: false,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final calls = MeyaCallService.instance;
  final ana = contactNamed('1');
  final bob = contactNamed('2');
  late List<(Contact, Map<String, Object>)> sent;
  late List<FakeEngine> engines;
  late int incoming;
  late List<Contact> missed;

  Map<String, Object> lastSent() => sent.last.$2;

  Future<void> receive(Contact from, Map<String, dynamic> content) =>
      calls.handleSignal(from, 'device-${from.contactId}', {
        'sent_at': DateTime.now().toUtc().toIso8601String(),
        ...content,
      });

  setUp(() {
    sent = [];
    engines = [];
    incoming = 0;
    missed = [];
    calls.resetForTesting();
    MeyaCallService.ringTimeout = const Duration(seconds: 45);
    calls.configure(
      send: (contact, fields) async => sent.add((contact, fields)),
      createEngine: () {
        final engine = FakeEngine();
        engines.add(engine);
        return engine;
      },
    );
    calls.onIncoming = () => incoming++;
    calls.onMissed = missed.add;
  });

  tearDown(calls.resetForTesting);

  test('an outgoing call is offered, answered, connected and ended', () async {
    await calls.startCall(ana, video: true);
    expect(calls.phase, CallPhase.outgoing);
    expect(engines.single.calls, contains('offer video=true'));
    expect(lastSent()['kind'], 'call_offer');
    expect(lastSent()['sdp'], 'OFFER-SDP');
    expect(lastSent()['video'], true);
    final callId = lastSent()['call_id'] as String;
    expect(callId, hasLength(32));

    await receive(ana, {
      'kind': 'call_answer',
      'call_id': callId,
      'sdp': 'ANSWER-SDP',
    });
    expect(calls.phase, CallPhase.connecting);
    expect(engines.single.receivedAnswer, 'ANSWER-SDP');

    engines.single.onConnection!(true);
    expect(calls.phase, CallPhase.active);
    expect(calls.connectedAt, isNotNull);

    await calls.hangUp();
    expect(calls.phase, CallPhase.ended);
    expect(calls.endReason, CallEndReason.ended);
    expect(engines.single.closed, isTrue);
    expect(lastSent(), {'kind': 'call_end', 'call_id': callId, 'reason': 'ended'});
  });

  test('an incoming call rings, is accepted and answered', () async {
    await receive(ana, {
      'kind': 'call_offer',
      'call_id': 'abc',
      'video': false,
      'sdp': 'OFFER-SDP',
    });
    expect(calls.phase, CallPhase.incoming);
    expect(calls.contact, ana);
    expect(incoming, 1);
    expect(engines, isEmpty, reason: 'no camera or microphone until accepted');

    await calls.accept();
    expect(engines.single.receivedOffer, 'OFFER-SDP');
    expect(lastSent(), {'kind': 'call_answer', 'call_id': 'abc', 'sdp': 'ANSWER-SDP'});
    expect(calls.phase, CallPhase.connecting);
  });

  test('declining tells the caller', () async {
    await receive(ana, {
      'kind': 'call_offer',
      'call_id': 'abc',
      'video': true,
      'sdp': 'OFFER-SDP',
    });
    await calls.decline();
    expect(calls.phase, CallPhase.ended);
    expect(lastSent(), {'kind': 'call_end', 'call_id': 'abc', 'reason': 'declined'});
  });

  test('a second caller gets busy and the first call carries on', () async {
    await calls.startCall(ana, video: false);
    await receive(bob, {
      'kind': 'call_offer',
      'call_id': 'other',
      'video': false,
      'sdp': 'OFFER-SDP',
    });
    expect(calls.contact, ana);
    expect(calls.phase, CallPhase.outgoing);
    expect(sent.last.$1, bob);
    expect(lastSent(), {'kind': 'call_end', 'call_id': 'other', 'reason': 'busy'});
  });

  test('signals from someone else or for another call are ignored', () async {
    await calls.startCall(ana, video: false);
    final callId = lastSent()['call_id'] as String;
    await receive(bob, {'kind': 'call_answer', 'call_id': callId, 'sdp': 'X'});
    await receive(ana, {'kind': 'call_end', 'call_id': 'wrong', 'reason': 'ended'});
    expect(calls.phase, CallPhase.outgoing);
    expect(engines.single.receivedAnswer, isNull);
  });

  test('the caller hanging up while it rings is a missed call', () async {
    await receive(ana, {
      'kind': 'call_offer',
      'call_id': 'abc',
      'video': false,
      'sdp': 'OFFER-SDP',
    });
    await receive(ana, {'kind': 'call_end', 'call_id': 'abc', 'reason': 'cancelled'});
    expect(calls.phase, CallPhase.ended);
    expect(missed, [ana]);
  });

  test('an offer that waited too long in the relay does not ring', () async {
    await calls.handleSignal(ana, 'device-1', {
      'kind': 'call_offer',
      'call_id': 'old',
      'video': false,
      'sdp': 'OFFER-SDP',
      'sent_at': DateTime.now()
          .toUtc()
          .subtract(const Duration(minutes: 5))
          .toIso8601String(),
    });
    expect(calls.phase, CallPhase.idle);
    expect(incoming, 0);
    expect(missed, [ana]);
  });

  test('an unanswered call stops ringing after the timeout', () async {
    MeyaCallService.ringTimeout = const Duration(milliseconds: 50);
    await calls.startCall(ana, video: false);
    final callId = lastSent()['call_id'] as String;
    await Future<void>.delayed(const Duration(milliseconds: 150));
    expect(calls.phase, CallPhase.ended);
    expect(calls.endReason, CallEndReason.missed);
    expect(lastSent(), {'kind': 'call_end', 'call_id': callId, 'reason': 'missed'});
  });

  test('a failed connection ends the call on both sides', () async {
    await calls.startCall(ana, video: false);
    final callId = lastSent()['call_id'] as String;
    await receive(ana, {'kind': 'call_answer', 'call_id': callId, 'sdp': 'A'});
    engines.single.onConnection!(false);
    await Future<void>.delayed(Duration.zero);
    expect(calls.endReason, CallEndReason.failed);
    expect(lastSent()['reason'], 'failed');
  });

  test('mute, camera and speaker reach the engine', () async {
    await calls.startCall(ana, video: true);
    expect(calls.speakerOn, isTrue, reason: 'video calls start on speaker');
    await calls.toggleMute();
    await calls.toggleCamera();
    await calls.toggleSpeaker();
    await calls.switchCamera();
    expect(engines.single.calls,
        containsAll(['muted=true', 'cameraOff=true', 'speaker=false', 'switch']));
  });
}
