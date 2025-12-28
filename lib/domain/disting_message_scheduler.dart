// disting_message_scheduler.dart - Simple Sequential Scheduler
// -----------------------------------------------------------------------------
// Redesigned for reliability and performance:
// • Simple state machine: idle → sending → waiting → idle
// • Sequential processing: one request at a time
// • Single timer approach: no complex timer chains
// • Immediate processing when idle
// • Retains device filtering and sysEx ID support
// • Auto-recovery from MIDI stream corruption
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

enum _SchedulerState { idle, sending, waitingForResponse }

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
    Duration messageInterval = const Duration(milliseconds: 50),
    Duration defaultTimeout = const Duration(milliseconds: 1000),
    this.defaultMaxRetries = 5,
    Duration defaultRetryDelay = Duration.zero,
  }) : _midi = midiCommand,
       _inputDevice = inputDevice,
       _outputDevice = outputDevice,
       _sysExId = sysExId,
       messageInterval = _normalizeDuration(messageInterval),
       defaultTimeout = _normalizeDuration(defaultTimeout),
       defaultRetryDelay = _normalizeDuration(defaultRetryDelay) {
    _subscription = _midi.onMidiDataReceived?.listen(
      _handleIncomingPacket,
      onError: _handleSubscriptionError,
      onDone: _handleSubscriptionDone,
      cancelOnError: false,
    );
    if (_subscription == null) {
      _subscriptionActive = false;
    }
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
  Timer? _retryTimer;
  Timer? _streamRecoveryTimer;
  StreamSubscription? _subscription;

  // Diagnostic counters
  int _totalPacketsReceived = 0;
  int _sysexPacketsReceived = 0;
  int _nonSysexPacketsReceived = 0;
  int _packetsFromWrongDevice = 0;
  DateTime? _lastPacketTime;
  bool _subscriptionActive = true;
  String? _lastSubscriptionError;

  // Consecutive timeout tracking for stream health detection
  int _consecutiveTimeouts = 0;
  static const int _maxConsecutiveTimeoutsBeforeRecovery = 3;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  static Duration _normalizeDuration(Duration duration) {
    if (duration.isNegative) {
      return Duration.zero;
    }
    return duration;
  }

  /// Returns diagnostic information about the scheduler's MIDI stream health.
  Map<String, dynamic> getDiagnostics() {
    final now = DateTime.now();
    final timeSinceLastPacket = _lastPacketTime != null
        ? now.difference(_lastPacketTime!).inMilliseconds
        : -1;

    return {
      'subscriptionActive': _subscriptionActive,
      'lastSubscriptionError': _lastSubscriptionError,
      'totalPacketsReceived': _totalPacketsReceived,
      'sysexPacketsReceived': _sysexPacketsReceived,
      'nonSysexPacketsReceived': _nonSysexPacketsReceived,
      'packetsFromWrongDevice': _packetsFromWrongDevice,
      'timeSinceLastPacketMs': timeSinceLastPacket,
      'currentState': _state.name,
      'queueLength': _queue.length,
      'hasCurrentRequest': _currentRequest != null,
      'currentRequestCompleted': _currentRequest?.completer.isCompleted ?? false,
    };
  }

  /// Attempts to re-establish the MIDI subscription if it's dead.
  void tryReconnectSubscription() {
    _subscription?.cancel();
    _subscriptionActive = false;

    _subscription = _midi.onMidiDataReceived?.listen(
      _handleIncomingPacket,
      onError: _handleSubscriptionError,
      onDone: _handleSubscriptionDone,
      cancelOnError: false,
    );

    if (_subscription != null) {
      _subscriptionActive = true;
      _lastSubscriptionError = null;
    }
  }

  /// Forces a full MIDI device disconnect/reconnect cycle.
  /// This is used to recover from corrupted MIDI state caused by rogue
  /// non-SysEx bytes that break CoreMIDI/flutter_midi_command.
  Future<void> forceDeviceReconnect() async {
    // Cancel current subscription
    _subscription?.cancel();
    _subscriptionActive = false;

    // Disconnect the device
    try {
      _midi.disconnectDevice(_inputDevice);

      // Brief delay to let the system settle
      await Future.delayed(const Duration(milliseconds: 500));

      // Reconnect the device
      _midi.connectToDevice(_inputDevice);

      // Re-establish subscription
      await Future.delayed(const Duration(milliseconds: 200));
      _subscription = _midi.onMidiDataReceived?.listen(
        _handleIncomingPacket,
        onError: _handleSubscriptionError,
        onDone: _handleSubscriptionDone,
        cancelOnError: false,
      );

      if (_subscription != null) {
        _subscriptionActive = true;
        _lastSubscriptionError = null;
        // Reset diagnostic counters
        _totalPacketsReceived = 0;
        _sysexPacketsReceived = 0;
        _nonSysexPacketsReceived = 0;
        _packetsFromWrongDevice = 0;
      }
    } catch (e) {
      // Recovery failed - will be retried on next timeout
    }
  }

  void _handleSubscriptionError(Object error, StackTrace stackTrace) {
    _subscriptionActive = false;
    _lastSubscriptionError = error.toString();
  }

  void _handleSubscriptionDone() {
    _subscriptionActive = false;
  }

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
      timeout: _normalizeDuration(timeout ?? defaultTimeout),
      maxRetries: maxRetries ?? defaultMaxRetries,
      retryDelay: _normalizeDuration(retryDelay ?? defaultRetryDelay),
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
    _retryTimer?.cancel();
    _streamRecoveryTimer?.cancel();
    final current = _currentRequest;
    if (current != null && !current.completer.isCompleted) {
      current.completer.completeError(StateError('Scheduler disposed'));
    }
    current?.dispose();
    _currentRequest = null;
    _state = _SchedulerState.idle;

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
    _retryTimer?.cancel();
    _retryTimer = null;

    final request = _currentRequest;
    if (request == null || request.completer.isCompleted) {
      _finishCurrentRequest();
      return;
    }
    request.attemptCount++;

    // Send the message
    try {
      _midi.sendData(request.packet, deviceId: _outputDevice.id);
    } catch (e) {
      _handleSendFailure(request, e);
      return;
    }

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
    final request = _currentRequest;

    // Guard against race conditions where response arrived just before timeout
    if (request == null || request.completer.isCompleted) {
      _consecutiveTimeouts = 0;
      _finishCurrentRequest();
      return;
    }

    if (request.attemptCount >= request.maxRetries) {
      // Out of retries
      _consecutiveTimeouts++;

      // Check if we need to attempt stream recovery
      if (_consecutiveTimeouts >= _maxConsecutiveTimeoutsBeforeRecovery) {
        forceDeviceReconnect();
        _consecutiveTimeouts = 0;
      }

      if (request.expectation == ResponseExpectation.required) {
        request.completer.completeError(
          TimeoutException(
            'No response after ${request.attemptCount} attempts',
            request.timeout,
          ),
        );
      } else {
        request.completer.complete(null);
      }
      _finishCurrentRequest();
    } else {
      // Retry after delay
      _state = _SchedulerState.sending;

      if (request.retryDelay == Duration.zero) {
        _sendCurrentRequest();
      } else {
        _retryTimer = Timer(request.retryDelay, _sendCurrentRequest);
      }
    }
  }

  void _handleSendFailure(_ScheduledRequest request, Object error) {
    if (request.completer.isCompleted) {
      _finishCurrentRequest();
      return;
    }

    if (request.attemptCount >= request.maxRetries) {
      request.completer.completeError(
        StateError('Failed to send request after ${request.attemptCount} attempts: $error'),
      );
      _finishCurrentRequest();
      return;
    }

    _state = _SchedulerState.sending;
    if (request.retryDelay == Duration.zero) {
      _sendCurrentRequest();
    } else {
      _retryTimer = Timer(request.retryDelay, _sendCurrentRequest);
    }
  }

  void _finishCurrentRequest() {
    _currentRequest?.dispose();
    _currentRequest = null;
    _state = _SchedulerState.idle;
    _retryTimer?.cancel();
    _retryTimer = null;

    // Schedule next request after message interval
    if (_queue.isNotEmpty) {
      _nextProcessTimer = Timer(messageInterval, _processNext);
    }
  }

  // ---------------------------------------------------------------------------
  // Incoming message handling
  // ---------------------------------------------------------------------------

  /// Extracts SysEx messages (F0...F7) from a raw MIDI packet.
  /// Returns an empty list if no valid SysEx is found.
  /// This handles cases where rogue MIDI messages (Program Change, Pitchwheel)
  /// are prepended to or mixed with SysEx data by the MIDI library.
  List<Uint8List> _extractSysExMessages(Uint8List raw) {
    final messages = <Uint8List>[];
    int searchStart = 0;

    while (searchStart < raw.length) {
      final startIndex = raw.indexOf(0xF0, searchStart);
      if (startIndex == -1) {
        break;
      }

      final endIndex = raw.indexOf(0xF7, startIndex);
      if (endIndex == -1) {
        break;
      }

      messages.add(raw.sublist(startIndex, endIndex + 1));
      searchStart = endIndex + 1;
    }

    return messages;
  }

  void _handleIncomingPacket(dynamic packet) {
    _totalPacketsReceived++;
    _lastPacketTime = DateTime.now();

    if (packet is MidiPacket) {
      if (packet.device.id != _inputDevice.id) {
        _packetsFromWrongDevice++;
        return;
      }
      _handleIncoming(packet.data);
    } else if (packet is Uint8List) {
      _handleIncoming(packet);
    }
  }

  void _handleIncoming(Uint8List raw) {
    // Extract SysEx messages from packet, filtering out any rogue MIDI bytes.
    // Some plugins/algorithms send Program Change or Pitchwheel messages that
    // may be combined with SysEx responses by the MIDI library.
    final sysexMessages = _extractSysExMessages(raw);
    if (sysexMessages.isEmpty) {
      _nonSysexPacketsReceived++;

      // CRITICAL: If we receive non-SysEx bytes while waiting for a response,
      // this is a strong signal that the MIDI stream is corrupted.
      // Some plugins send rogue MIDI messages that corrupt CoreMIDI/flutter_midi_command state.
      if (_state == _SchedulerState.waitingForResponse) {
        _scheduleStreamRecovery();
      }
      return;
    }

    _sysexPacketsReceived++;
    _cancelStreamRecovery();

    for (final sysex in sysexMessages) {
      if (_tryHandleSysEx(sysex)) {
        break;
      }
    }
  }

  void _scheduleStreamRecovery() {
    // Only schedule if not already scheduled
    if (_streamRecoveryTimer?.isActive ?? false) {
      return;
    }

    // Wait a bit to see if more rogue bytes come, then attempt recovery
    _streamRecoveryTimer = Timer(const Duration(milliseconds: 500), () {
      forceDeviceReconnect();
    });
  }

  void _cancelStreamRecovery() {
    _streamRecoveryTimer?.cancel();
    _streamRecoveryTimer = null;
  }

  bool _tryHandleSysEx(Uint8List sysex) {
    try {
      final parsed = decodeDistingNTSysEx(sysex);
      if (parsed == null) {
        return false;
      }

      if (parsed.sysExId != _sysExId) {
        return false;
      }

      final request = _currentRequest;
      if (request == null ||
          _state != _SchedulerState.waitingForResponse ||
          request.completer.isCompleted) {
        return false;
      }

      if (!request.key.matches(parsed)) {
        return false;
      }

      // Successfully matched a response - reset consecutive timeout counter
      _consecutiveTimeouts = 0;

      // Parse and complete the response
      final response = ResponseFactory.fromMessageType(
        parsed.messageType,
        parsed.payload,
      );

      if (response != null) {
        try {
          final parsedResponse = response.parse();
          request.completer.complete(parsedResponse);
        } catch (e) {
          // If parsing fails, complete with error instead of raw response to avoid type mismatches
          if (request.expectation == ResponseExpectation.optional) {
            request.completer.complete(null);
          } else {
            request.completer.completeError(
              StateError(
                'Failed to parse response: ${response.runtimeType} - $e',
              ),
            );
          }
        }
      } else {
        // No parser available
        if (request.expectation == ResponseExpectation.optional) {
          request.completer.complete(null);
        } else {
          request.completer.completeError(
            StateError('Unhandled response type: ${parsed.messageType}'),
          );
        }
      }

      _finishCurrentRequest();
      return true;
    } catch (e) {
      // Catch any unexpected exceptions to prevent scheduler from getting stuck.
      // The timeout will eventually clean up the current request.
    }
    return false;
  }
}
