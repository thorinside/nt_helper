// disting_message_scheduler.dart - Simple Sequential Scheduler
// -----------------------------------------------------------------------------
// Redesigned for reliability and performance:
// • Simple state machine: idle → sending → waiting → idle
// • Sequential processing: one request at a time
// • Single timer approach: no complex timer chains
// • Immediate processing when idle
// • Retains device filtering and sysEx ID support
// -----------------------------------------------------------------------------

import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter_midi_command/flutter_midi_command.dart';

// Domain classes
import 'package:nt_helper/domain/request_key.dart';
import 'package:nt_helper/domain/sysex/response_factory.dart';
import 'package:nt_helper/domain/sysex/sysex_parser.dart';

// -----------------------------------------------------------------------------
// Response expectation enum
// -----------------------------------------------------------------------------

enum ResponseExpectation {
  required, // Must get a response or throw TimeoutException
  optional, // OK to get null (no response)
  none, // Fire-and-forget
}

// -----------------------------------------------------------------------------
// Scheduler state
// -----------------------------------------------------------------------------

enum _SchedulerState {
  idle,
  sending,
  waitingForResponse,
}

// -----------------------------------------------------------------------------
// Internal request representation
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
  final Completer<dynamic> completer;
  final Duration timeout;
  final int maxRetries;
  final Duration retryDelay;

  int attemptCount = 0;
  Timer? timeoutTimer;

  void startTimeout(void Function() onTimeout) {
    timeoutTimer?.cancel();
    if (expectation != ResponseExpectation.none) {
      timeoutTimer = Timer(timeout, onTimeout);
    }
  }

  void dispose() => timeoutTimer?.cancel();
}

// -----------------------------------------------------------------------------
// Simple Sequential Message Scheduler
// -----------------------------------------------------------------------------

class DistingMessageScheduler {
  DistingMessageScheduler({
    required MidiCommand midiCommand,
    required MidiDevice inputDevice,
    required MidiDevice outputDevice,
    required int sysExId,
    this.messageInterval = const Duration(milliseconds: 50),
    this.defaultTimeout = const Duration(milliseconds: 300),
    this.defaultMaxRetries = 4,
    this.defaultRetryDelay = Duration.zero,
  })  : _midi = midiCommand,
        _inputDevice = inputDevice,
        _outputDevice = outputDevice,
        _sysExId = sysExId {
    _subscription = _midi.onMidiDataReceived?.listen(_handleIncomingPacket);
  }

  // MIDI and device configuration
  final MidiCommand _midi;
  final MidiDevice _inputDevice;
  final MidiDevice _outputDevice;
  final int _sysExId;

  // Timing configuration
  final Duration messageInterval;
  final Duration defaultTimeout;
  final int defaultMaxRetries;
  final Duration defaultRetryDelay;

  // State management
  _SchedulerState _state = _SchedulerState.idle;
  final Queue<_ScheduledRequest> _queue = Queue();
  _ScheduledRequest? _currentRequest;
  Timer? _nextProcessTimer;
  StreamSubscription? _subscription;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  Future<T?> sendRequest<T>(
    Uint8List packet,
    RequestKey key, {
    ResponseExpectation responseExpectation = ResponseExpectation.required,
    int? maxRetries,
    Duration? timeout,
    Duration? retryDelay,
  }) {
    final completer = Completer<T?>();
    final request = _ScheduledRequest(
      packet: packet,
      key: key,
      expectation: responseExpectation,
      completer: completer,
      timeout: timeout ?? defaultTimeout,
      maxRetries: maxRetries ?? defaultMaxRetries,
      retryDelay: retryDelay ?? defaultRetryDelay,
    );

    _queue.add(request);

    // Process immediately if idle
    if (_state == _SchedulerState.idle) {
      _processNext();
    }

    return completer.future;
  }

  void dispose() {
    _subscription?.cancel();
    _nextProcessTimer?.cancel();
    _currentRequest?.dispose();

    // Fail all pending requests
    for (final request in _queue) {
      if (!request.completer.isCompleted) {
        request.completer.completeError(StateError('Scheduler disposed'));
      }
    }
    _queue.clear();
  }

  // ---------------------------------------------------------------------------
  // Core processing logic
  // ---------------------------------------------------------------------------

  void _processNext() {
    // Cancel any pending timer
    _nextProcessTimer?.cancel();
    _nextProcessTimer = null;

    if (_state != _SchedulerState.idle || _queue.isEmpty) {
      return;
    }

    _currentRequest = _queue.removeFirst();
    _state = _SchedulerState.sending;

    _sendCurrentRequest();
  }

  void _sendCurrentRequest() {
    final request = _currentRequest!;
    request.attemptCount++;

    debugPrint('Sending SysEx (attempt ${request.attemptCount}): '
        '${request.packet.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')} ${request.key}');

    // Send the message
    _midi.sendData(request.packet, deviceId: _outputDevice.id);

    if (request.expectation == ResponseExpectation.none) {
      // Fire-and-forget: complete immediately and schedule next
      request.completer.complete(null);
      _finishCurrentRequest();
    } else {
      // Wait for response
      _state = _SchedulerState.waitingForResponse;
      request.startTimeout(() => _onTimeout());
    }
  }

  void _onTimeout() {
    final request = _currentRequest!;

    if (request.attemptCount >= request.maxRetries) {
      // Out of retries
      if (request.expectation == ResponseExpectation.required) {
        request.completer.completeError(TimeoutException(
            'No response after ${request.attemptCount} attempts',
            request.timeout));
      } else {
        request.completer.complete(null);
      }
      _finishCurrentRequest();
    } else {
      // Retry after delay
      debugPrint('Timeout, retrying (attempt ${request.attemptCount + 1})...');
      _state = _SchedulerState.sending;

      if (request.retryDelay == Duration.zero) {
        _sendCurrentRequest();
      } else {
        Timer(request.retryDelay, _sendCurrentRequest);
      }
    }
  }

  void _finishCurrentRequest() {
    _currentRequest?.dispose();
    _currentRequest = null;
    _state = _SchedulerState.idle;

    // Schedule next request after message interval
    if (_queue.isNotEmpty) {
      _nextProcessTimer = Timer(messageInterval, _processNext);
    }
  }

  // ---------------------------------------------------------------------------
  // Incoming message handling
  // ---------------------------------------------------------------------------

  void _handleIncomingPacket(dynamic packet) {
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
    if (parsed.sysExId != _sysExId) return;

    final request = _currentRequest;
    if (request == null ||
        _state != _SchedulerState.waitingForResponse ||
        request.completer.isCompleted) {
      debugPrint("Received SysEx but no matching request pending");
      return;
    }

    if (!request.key.matches(parsed)) {
      debugPrint("Received SysEx doesn't match pending request");
      debugPrint("  Expected: ${request.key}");
      debugPrint("  Received: ${parsed.messageType}");
      return;
    }

    debugPrint(
        'Received matching SysEx: ${parsed.rawBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}');

    // Parse and complete the response
    final response =
        ResponseFactory.fromMessageType(parsed.messageType, parsed.payload);

    if (response != null) {
      try {
        final parsed = response.parse();
        request.completer.complete(parsed);
      } catch (e) {
        // If parsing fails, complete with error instead of raw response to avoid type mismatches
        debugPrint(
            '[DistingMessageScheduler] Parsing failed for ${response.runtimeType}: $e');
        if (request.expectation == ResponseExpectation.optional) {
          request.completer.complete(null);
        } else {
          request.completer.completeError(StateError(
              'Failed to parse response: ${response.runtimeType} - $e'));
        }
      }
    } else {
      // No parser available
      if (request.expectation == ResponseExpectation.optional) {
        request.completer.complete(null);
      } else {
        request.completer.completeError(
            StateError('Unhandled response type: ${parsed.messageType}'));
      }
    }

    _finishCurrentRequest();
  }
}
