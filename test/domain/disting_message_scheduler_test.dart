import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_midi_command/flutter_midi_command.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nt_helper/domain/disting_message_scheduler.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'package:nt_helper/domain/request_key.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockMidiCommand extends Mock implements MidiCommand {}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

const int _testSysExId = 0x00;

MidiDevice _makeDevice(String id) => MidiDevice(id, 'Test Device', 'native', true);

/// Builds a valid Disting NT SysEx response frame.
Uint8List _buildSysEx(
  DistingNTRespMessageType type,
  List<int> payload, {
  int sysExId = _testSysExId,
}) {
  return Uint8List.fromList([
    0xF0,
    0x00, 0x21, 0x27, // Expert Sleepers manufacturer ID
    0x6D, // Disting NT prefix
    sysExId,
    type.value,
    ...payload,
    0xF7,
  ]);
}

/// Creates a scheduler wired to a broadcast [StreamController] so tests can
/// inject incoming MIDI packets.
({
  DistingMessageScheduler scheduler,
  StreamController<MidiPacket> incoming,
  MidiDevice device,
  MockMidiCommand midi,
}) _createScheduler({
  Duration messageInterval = Duration.zero,
  Duration defaultTimeout = const Duration(milliseconds: 200),
  int defaultMaxRetries = 1,
}) {
  final midi = MockMidiCommand();
  final incoming = StreamController<MidiPacket>.broadcast();
  final device = _makeDevice('test-device');

  when(() => midi.onMidiDataReceived).thenAnswer((_) => incoming.stream);
  when(() => midi.sendData(any(), deviceId: any(named: 'deviceId')))
      .thenAnswer((_) {});

  final scheduler = DistingMessageScheduler(
    midiCommand: midi,
    inputDevice: device,
    outputDevice: device,
    sysExId: _testSysExId,
    messageInterval: messageInterval,
    defaultTimeout: defaultTimeout,
    defaultMaxRetries: defaultMaxRetries,
  );

  return (
    scheduler: scheduler,
    incoming: incoming,
    device: device,
    midi: midi,
  );
}

/// Injects a SysEx response into the scheduler's incoming stream.
void _injectResponse(
  StreamController<MidiPacket> incoming,
  MidiDevice device,
  DistingNTRespMessageType type,
  List<int> payload, {
  int sysExId = _testSysExId,
}) {
  final data = _buildSysEx(type, payload, sysExId: sysExId);
  incoming.add(MidiPacket(data, 0, device));
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUpAll(() {
    registerFallbackValue(Uint8List(0));
  });

  group('DistingMessageScheduler', () {
    late DistingMessageScheduler scheduler;
    late StreamController<MidiPacket> incoming;
    late MidiDevice device;

    setUp(() {
      final setup = _createScheduler();
      scheduler = setup.scheduler;
      incoming = setup.incoming;
      device = setup.device;
    });

    tearDown(() {
      scheduler.dispose();
      incoming.close();
    });

    test('basic request/response cycle — happy path', () async {
      final key = RequestKey(
        sysExId: _testSysExId,
        messageType: DistingNTRespMessageType.respNumAlgorithms,
      );

      final future = scheduler.sendRequest(
        _buildSysEx(DistingNTRespMessageType.respNumAlgorithms, []),
        key,
      );

      // Inject response on next microtask
      await Future.microtask(() {});
      _injectResponse(
        incoming,
        device,
        DistingNTRespMessageType.respNumAlgorithms,
        [0x00, 0x00, 0x08], // 8 algorithms
      );

      final result = await future;
      expect(result, isNotNull);
    });

    test('unexpected message discarded — current request still completes', () async {
      final key = RequestKey(
        sysExId: _testSysExId,
        messageType: DistingNTRespMessageType.respNumAlgorithms,
      );

      final future = scheduler.sendRequest(
        _buildSysEx(DistingNTRespMessageType.respNumAlgorithms, []),
        key,
      );

      await Future.microtask(() {});

      // Inject an unexpected message (different type)
      _injectResponse(
        incoming,
        device,
        DistingNTRespMessageType.respPresetName,
        [0x41, 0x42, 0x43, 0x00], // "ABC"
      );

      // Now inject the correct response
      _injectResponse(
        incoming,
        device,
        DistingNTRespMessageType.respNumAlgorithms,
        [0x00, 0x00, 0x08],
      );

      final result = await future;
      expect(result, isNotNull);

      final diag = scheduler.getDiagnostics();
      expect(diag['unmatchedResponsesDiscarded'], 1);
    });

    test('stale response absorbed by expired handler', () async {
      // Send request A that will time out (maxRetries = 1)
      final keyA = RequestKey(
        sysExId: _testSysExId,
        messageType: DistingNTRespMessageType.respNumAlgorithms,
      );

      final futureA = scheduler.sendRequest(
        _buildSysEx(DistingNTRespMessageType.respNumAlgorithms, []),
        keyA,
        responseExpectation: ResponseExpectation.optional,
        maxRetries: 1,
        timeout: const Duration(milliseconds: 50),
      );

      // Wait for timeout
      final resultA = await futureA;
      expect(resultA, isNull); // Timed out as optional → null

      // Now send request B with same key
      final keyB = RequestKey(
        sysExId: _testSysExId,
        messageType: DistingNTRespMessageType.respNumAlgorithms,
      );

      final futureB = scheduler.sendRequest(
        _buildSysEx(DistingNTRespMessageType.respNumAlgorithms, []),
        keyB,
      );

      await Future.microtask(() {});

      // Inject A's late response — active handler (B) is checked first and
      // consumes it, so B completes with value 4.
      _injectResponse(
        incoming,
        device,
        DistingNTRespMessageType.respNumAlgorithms,
        [0x00, 0x00, 0x04], // 4 algorithms (A's late response, consumed by B)
      );

      // Inject B's actual response — with B already complete, this is absorbed
      // by A's expired handler.
      _injectResponse(
        incoming,
        device,
        DistingNTRespMessageType.respNumAlgorithms,
        [0x00, 0x00, 0x08], // 8 algorithms (B's response, absorbed by A's expired handler)
      );

      final resultB = await futureB;
      expect(resultB, isNotNull);
      expect(resultB, isA<int>());
      expect(resultB, 4);

      // Allow the second stream event (absorbed by A's expired handler) to be
      // delivered before checking diagnostics.
      await Future.microtask(() {});

      final diag = scheduler.getDiagnostics();
      expect(diag['staleResponsesAbsorbed'], 1);
    });

    test('FIFO drain — multiple same-key timeouts drain expired handlers', () async {
      // Time out 2 requests with same key
      for (var i = 0; i < 2; i++) {
        final key = RequestKey(
          sysExId: _testSysExId,
          messageType: DistingNTRespMessageType.respNumAlgorithms,
        );
        final future = scheduler.sendRequest(
          _buildSysEx(DistingNTRespMessageType.respNumAlgorithms, []),
          key,
          responseExpectation: ResponseExpectation.optional,
          maxRetries: 1,
          timeout: const Duration(milliseconds: 50),
        );
        await future; // Wait for timeout
      }

      // Send a third request
      final key = RequestKey(
        sysExId: _testSysExId,
        messageType: DistingNTRespMessageType.respNumAlgorithms,
      );
      final future = scheduler.sendRequest(
        _buildSysEx(DistingNTRespMessageType.respNumAlgorithms, []),
        key,
      );

      await Future.microtask(() {});

      // Inject 3 responses: active handler matches the 1st, remaining 2 absorbed by expired handlers
      for (var i = 0; i < 3; i++) {
        _injectResponse(
          incoming,
          device,
          DistingNTRespMessageType.respNumAlgorithms,
          [0x00, 0x00, i],
        );
      }

      final result = await future;
      expect(result, isNotNull);
      expect(result, isA<int>());
      expect(result, 0);

      // Allow remaining stream events (stale responses absorbed by expired
      // handlers) to be delivered before checking diagnostics.
      await Future.microtask(() {});
      await Future.microtask(() {});

      final diag = scheduler.getDiagnostics();
      expect(diag['staleResponsesAbsorbed'], 2);
    });

    test('fire-and-forget completes immediately without handler registration', () async {
      final key = RequestKey(
        sysExId: _testSysExId,
        messageType: DistingNTRespMessageType.respNumAlgorithms,
      );

      final result = await scheduler.sendRequest(
        _buildSysEx(DistingNTRespMessageType.respNumAlgorithms, []),
        key,
        responseExpectation: ResponseExpectation.none,
      );

      expect(result, isNull);
    });

    test('optional timeout returns null (not error)', () async {
      final key = RequestKey(
        sysExId: _testSysExId,
        messageType: DistingNTRespMessageType.respNumAlgorithms,
      );

      final result = await scheduler.sendRequest(
        _buildSysEx(DistingNTRespMessageType.respNumAlgorithms, []),
        key,
        responseExpectation: ResponseExpectation.optional,
        maxRetries: 1,
        timeout: const Duration(milliseconds: 50),
      );

      expect(result, isNull);
    });

    test('retry persists handler — handler not moved to expired during retries', () async {
      final key = RequestKey(
        sysExId: _testSysExId,
        messageType: DistingNTRespMessageType.respNumAlgorithms,
      );

      final future = scheduler.sendRequest(
        _buildSysEx(DistingNTRespMessageType.respNumAlgorithms, []),
        key,
        maxRetries: 10,
        timeout: const Duration(milliseconds: 50),
      );

      // Wait for first retry timeout
      await Future.delayed(const Duration(milliseconds: 70));

      // Now inject a response — should still match the active handler
      _injectResponse(
        incoming,
        device,
        DistingNTRespMessageType.respNumAlgorithms,
        [0x00, 0x00, 0x08],
      );

      final result = await future;
      expect(result, isNotNull);

      // No expired handlers should have been created (handler persisted)
      final diag = scheduler.getDiagnostics();
      expect(diag['staleResponsesAbsorbed'], 0);
      expect(diag['expiredHandlerCount'], 0);
    });

    test('consecutive timeout recovery — auto-reset after 3 consecutive timeouts', () async {
      final setup = _createScheduler(defaultMaxRetries: 1);
      final sched = setup.scheduler;
      final inc = setup.incoming;

      addTearDown(() {
        sched.dispose();
        inc.close();
      });

      // Cause 3 consecutive timeouts
      for (var i = 0; i < 3; i++) {
        final key = RequestKey(
          sysExId: _testSysExId,
          messageType: DistingNTRespMessageType.respNumAlgorithms,
        );
        final future = sched.sendRequest(
          _buildSysEx(DistingNTRespMessageType.respNumAlgorithms, []),
          key,
          responseExpectation: ResponseExpectation.optional,
          maxRetries: 1,
          timeout: const Duration(milliseconds: 50),
        );
        await future;
      }

      // After 3 consecutive timeouts, _resetInternalState() was called.
      // Verify scheduler still functions: send a request and respond to it.
      final key = RequestKey(
        sysExId: _testSysExId,
        messageType: DistingNTRespMessageType.respNumAlgorithms,
      );
      final future = sched.sendRequest(
        _buildSysEx(DistingNTRespMessageType.respNumAlgorithms, []),
        key,
        responseExpectation: ResponseExpectation.optional,
        maxRetries: 1,
        timeout: const Duration(milliseconds: 500),
      );

      // Allow the scheduler to process and re-subscribe
      await Future.delayed(const Duration(milliseconds: 20));
      _injectResponse(
        inc,
        setup.device,
        DistingNTRespMessageType.respNumAlgorithms,
        [0x00, 0x00, 0x08],
      );

      final result = await future;
      expect(result, isNotNull);
    });

    test('expired handler cleanup — handlers older than 30s are removed', () async {
      // This tests the lazy cleanup in _cleanupExpiredHandlers.
      // We can't easily simulate 30s passage, so we test the cap at 20 entries.
      final setup = _createScheduler(defaultMaxRetries: 1);
      final sched = setup.scheduler;
      final inc = setup.incoming;

      addTearDown(() {
        sched.dispose();
        inc.close();
      });

      // Create 25 expired handlers by timing out 25 requests
      for (var i = 0; i < 25; i++) {
        final key = RequestKey(
          sysExId: _testSysExId,
          messageType: DistingNTRespMessageType.respNumAlgorithms,
        );
        final future = sched.sendRequest(
          _buildSysEx(DistingNTRespMessageType.respNumAlgorithms, []),
          key,
          responseExpectation: ResponseExpectation.optional,
          maxRetries: 1,
          timeout: const Duration(milliseconds: 20),
        );
        await future;
      }

      // Trigger cleanup by dispatching an unmatched message
      _injectResponse(
        inc,
        setup.device,
        DistingNTRespMessageType.respPresetName,
        [0x41, 0x00],
      );

      await Future.microtask(() {});

      final diag = sched.getDiagnostics();
      // Expired handler count should be capped at 20
      expect(diag['expiredHandlerCount'] as int, lessThanOrEqualTo(20));
    });

    test('dispose while requests pending — all completers get errors', () async {
      final setup = _createScheduler();
      final sched = setup.scheduler;

      // Queue up multiple requests
      final futures = <Future>[];
      for (var i = 0; i < 3; i++) {
        final key = RequestKey(
          sysExId: _testSysExId,
          messageType: DistingNTRespMessageType.respNumAlgorithms,
        );
        futures.add(
          sched.sendRequest(
            _buildSysEx(DistingNTRespMessageType.respNumAlgorithms, []),
            key,
          ),
        );
      }

      // Dispose immediately
      sched.dispose();
      setup.incoming.close();

      // All futures should complete with errors
      for (final future in futures) {
        expect(future, throwsA(isA<StateError>()));
      }
    });

    test('message observer receives all messages', () async {
      final observed = <DistingNTRespMessageType>[];
      scheduler.addMessageObserver((msg) => observed.add(msg.messageType));

      final key = RequestKey(
        sysExId: _testSysExId,
        messageType: DistingNTRespMessageType.respNumAlgorithms,
      );

      final future = scheduler.sendRequest(
        _buildSysEx(DistingNTRespMessageType.respNumAlgorithms, []),
        key,
      );

      await Future.microtask(() {});

      // Inject unexpected message + correct response
      _injectResponse(
        incoming,
        device,
        DistingNTRespMessageType.respPresetName,
        [0x41, 0x00],
      );
      _injectResponse(
        incoming,
        device,
        DistingNTRespMessageType.respNumAlgorithms,
        [0x00, 0x00, 0x08],
      );

      await future;

      // Observer should have seen both messages
      expect(observed, [
        DistingNTRespMessageType.respPresetName,
        DistingNTRespMessageType.respNumAlgorithms,
      ]);
    });
  });
}
