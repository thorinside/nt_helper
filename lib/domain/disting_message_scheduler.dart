// disting_message_scheduler_v2.dart – drop‑in replacement with device + sysExId
// -----------------------------------------------------------------------------
//  • SAME import list, enum, and external types as the legacy scheduler.
//  • Adds **inputDevice**, **outputDevice**, and **sysExId** constructor
//    parameters so Windows (separate MIDI in/out) is supported and incoming
//    messages can be filtered by sysExId.
//  • Supports multi‑in‑flight requests and per‑request overrides for timeout &
//    retryDelay; also global defaults.
//  • **UPDATED**: now relies on `decodeDistingNTSysEx` from
//    `disting_nt_sysex.dart` and the `RequestKey.matches()` helper, so the
//    scheduler ignores messages from other devices *and* other SysEx IDs.
// -----------------------------------------------------------------------------

/*
 * Imports – kept in the exact order of the original file.
 */
import 'dart:async';
import 'dart:collection';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_midi_command/flutter_midi_command.dart';

// Domain classes -------------------------------------------------------------
import 'package:nt_helper/domain/request_key.dart';
import 'package:nt_helper/domain/sysex/response_factory.dart';
import 'package:nt_helper/domain/sysex/sysex_parser.dart'; // kept for API‑compat

// -----------------------------------------------------------------------------
// Response expectation enum (unchanged)
// -----------------------------------------------------------------------------

enum ResponseExpectation {
  required, // Must get a response or throw TimeoutException
  optional, // OK to get null (no response)
  none, // Fire‑and‑forget
}

// -----------------------------------------------------------------------------
// Internal helper – one outstanding request
// -----------------------------------------------------------------------------

class _ScheduledRequest {
  _ScheduledRequest({
    required this.packet,
    required this.key,
    required this.expectation,
    required this.completer,
    required this.timeout,
    required this.maxRetries,
    required this.retryDelay,
  });

  final Uint8List packet;
  final RequestKey key;
  final ResponseExpectation expectation;
  final Completer<dynamic> completer; // dynamic → cast when completing
  final Duration timeout;
  final int maxRetries;
  final Duration retryDelay;

  int _attempt = 0;
  Timer? _timeoutTimer;

  void resetTimer(void Function() onTimeout) {
    _timeoutTimer?.cancel();
    if (expectation != ResponseExpectation.none) {
      _timeoutTimer = Timer(timeout, onTimeout);
    }
  }

  void dispose() => _timeoutTimer?.cancel();
}

// -----------------------------------------------------------------------------
//  DistingMessageScheduler – multi in‑flight capable + device/sysEx filtering
// -----------------------------------------------------------------------------

class DistingMessageScheduler {
  DistingMessageScheduler({
    required MidiCommand midiCommand,
    required MidiDevice inputDevice,
    required MidiDevice outputDevice,
    required int sysExId,
    this.maxOutstanding = 1,
    this.messageInterval = const Duration(milliseconds: 50),
    defaultTimeout = const Duration(milliseconds: 300),
    this.defaultRetryDelay = Duration.zero,
  })  : effectiveTimeout = Duration(
            milliseconds: max(200, defaultTimeout.inMilliseconds as int) *
                maxOutstanding),
        _midi = midiCommand,
        _inputDevice = inputDevice,
        _outputDevice = outputDevice,
        _sysExId = sysExId {
    _subscription = _midi.onMidiDataReceived?.listen(_handleIncomingPacket);
  }

  // MIDI driver & device handles ------------------------------------------------
  final MidiCommand _midi;
  final MidiDevice _inputDevice;
  final MidiDevice _outputDevice;

  // Distinguish multiple NTs on the same bus -----------------------------------
  final int _sysExId;

  // Concurrency / pacing configuration -----------------------------------------
  final int maxOutstanding; // raise to enable concurrency
  final Duration messageInterval;
  final Duration effectiveTimeout;
  final Duration defaultRetryDelay;

  // Incoming MIDI stream sub ----------------------------------------------------
  StreamSubscription? _subscription;

  // Outbound queue & in‑flight map ---------------------------------------------
  final Queue<_ScheduledRequest> _queue = Queue();
  final Map<RequestKey, _ScheduledRequest> _inFlight = {};

  // Debounce token for queue pumping -------------------------------------------
  Timer? _pumpToken;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  Future<T?> sendRequest<T>(
    Uint8List packet,
    RequestKey key, {
    ResponseExpectation responseExpectation = ResponseExpectation.required,
    int maxRetries = 4,
    Duration? timeout,
    Duration? retryDelay,
  }) {
    final completer = Completer<T?>();
    final req = _ScheduledRequest(
      packet: packet,
      key: key,
      expectation: responseExpectation,
      completer: completer,
      timeout: timeout ?? effectiveTimeout,
      maxRetries: maxRetries,
      retryDelay: retryDelay ?? defaultRetryDelay,
    );

    _queue.add(req);
    _pump();
    return completer.future;
  }

  void dispose() {
    _subscription?.cancel();
    _pumpToken?.cancel();

    // Fail everything still pending -------------------------------------------
    for (final r in _queue) {
      if (!r.completer.isCompleted) {
        r.completer.completeError(StateError('Scheduler disposed'));
      }
    }
    for (final r in _inFlight.values) {
      if (!r.completer.isCompleted) {
        r.completer.completeError(StateError('Scheduler disposed'));
      }
      r.dispose();
    }
    _queue.clear();
    _inFlight.clear();
  }

  // ---------------------------------------------------------------------------
  // Queue helpers
  // ---------------------------------------------------------------------------

  void _pump() {
    // Debounce to next micro‑task ------------------------------------------------
    _pumpToken ??= Timer(Duration.zero, () {
      _pumpToken = null;
      _drain();
    });
  }

  void _drain() {
    while (_inFlight.length < maxOutstanding && _queue.isNotEmpty) {
      final req = _queue.removeFirst();
      _sendInitial(req);
    }
  }

  void _sendInitial(_ScheduledRequest req) {
    // On Windows we have separate out device; supply deviceId when sending.
    _midi.sendData(req.packet, deviceId: _outputDevice.id);

    if (req.expectation != ResponseExpectation.none) {
      _inFlight[req.key] = req;
      req.resetTimer(() => _onTimeout(req));
    } else {
      if (!req.completer.isCompleted) req.completer.complete(null);
    }

    // respect messageInterval between sends -------------------------------------
    Timer(messageInterval, _pump);
  }

  void _retrySend(_ScheduledRequest req) {
    _midi.sendData(req.packet, deviceId: _outputDevice.id);
    req.resetTimer(() => _onTimeout(req));
    Timer(messageInterval, _pump);
  }

  void _onTimeout(_ScheduledRequest req) {
    req._attempt++;
    if (req._attempt > req.maxRetries) {
      _inFlight.remove(req.key);
      if (req.expectation == ResponseExpectation.required) {
        req.completer
            .completeError(TimeoutException('No response', req.timeout));
      } else {
        req.completer.complete(null);
      }
      req.dispose();
      _pump();
      return;
    }

    // Retry after the specified delay ------------------------------------------
    if (req.retryDelay == Duration.zero) {
      _retrySend(req);
    } else {
      Timer(req.retryDelay, () => _retrySend(req));
    }
  }

  // ---------------------------------------------------------------------------
  // Incoming MIDI handling (Parser swapped to `decodeDistingNTSysEx`)
  // ---------------------------------------------------------------------------

  void _handleIncomingPacket(dynamic packet) {
    // Filter by device (Windows has separate in/out IDs) -----------------------
    if (packet is MidiPacket) {
      if (packet.device.id != _inputDevice.id) return;
      _handleIncoming(packet.data);
    } else if (packet is Uint8List) {
      _handleIncoming(packet);
    }
  }

  void _handleIncoming(Uint8List raw) {
    final parsed = decodeDistingNTSysEx(raw);
    if (parsed == null) return;
    if (parsed.sysExId != _sysExId) return; // other NT on the bus

    // Locate owning request -----------------------------------------------------
    RequestKey? matchedKey;
    _ScheduledRequest? matchedReq;
    for (final entry in _inFlight.entries) {
      if (entry.key.matches(parsed)) {
        matchedKey = entry.key;
        matchedReq = entry.value;
        break;
      }
    }
    if (matchedReq == null) return; // unsolicited or timed‑out

    _inFlight.remove(matchedKey);
    matchedReq.dispose();

    final response =
        ResponseFactory.fromMessageType(parsed.messageType, parsed.payload);

    if (response != null) {
      try {
        matchedReq.completer.complete(response.parse());
      } catch (_) {
        // Fallback to the raw response object if `.parse()` throws.
        matchedReq.completer.complete(response);
      }
    } else {
      // No parser – treat according to expectation.
      if (matchedReq.expectation == ResponseExpectation.optional) {
        matchedReq.completer.complete(null);
      } else {
        matchedReq.completer
            .completeError(StateError('Unhandled response type'));
      }
    }

    _pump(); // free slot for next request
  }
}
