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
import 'package:nt_helper/domain/disting_nt_sysex.dart';
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

typedef CcCallback = void Function(int channel, int cc, int value);

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

  /// Stopwatch to measure round-trip time from send to response
  final Stopwatch stopwatch = Stopwatch();

  void startTimeout(void Function() onTimeout) {
    timeoutTimer?.cancel();
    if (expectation != ResponseExpectation.none) {
      timeoutTimer = Timer(timeout, onTimeout);
    }
  }

  void dispose() => timeoutTimer?.cancel();
}

// -----------------------------------------------------------------------------
// Response Demultiplexer
// -----------------------------------------------------------------------------

class _ActiveHandler {
  _ActiveHandler({required this.key, required this.onMatch});

  final RequestKey key;
  final void Function(DistingNTParsedMessage) onMatch;
}

class _ExpiredHandler {
  _ExpiredHandler({required this.key, required this.expiredAt});

  final RequestKey key;
  final DateTime expiredAt;
}

class _ResponseDemux {
  _ActiveHandler? _activeHandler;
  final List<_ExpiredHandler> _expiredHandlers = [];
  final List<void Function(DistingNTParsedMessage)> _observers = [];

  int staleResponsesAbsorbed = 0;
  int unmatchedResponsesDiscarded = 0;

  int get expiredHandlerCount => _expiredHandlers.length;

  static const int _maxExpiredHandlers = 20;
  static const Duration _expiredHandlerMaxAge = Duration(seconds: 30);

  void registerActive(RequestKey key, void Function(DistingNTParsedMessage) onMatch) {
    _activeHandler = _ActiveHandler(key: key, onMatch: onMatch);
  }

  void expireActive() {
    final handler = _activeHandler;
    if (handler != null) {
      _activeHandler = null;
      _expiredHandlers.add(
        _ExpiredHandler(key: handler.key, expiredAt: DateTime.now()),
      );
    }
  }

  void addObserver(void Function(DistingNTParsedMessage) observer) {
    _observers.add(observer);
  }

  void removeObserver(void Function(DistingNTParsedMessage) observer) {
    _observers.remove(observer);
  }

  void dispatch(DistingNTParsedMessage parsed) {
    // 1. Notify all passive observers before any matching
    for (final observer in _observers) {
      try {
        observer(parsed);
      } catch (_) {
      }
    }

    // 2. Check active handler first — active request always takes priority
    if (_activeHandler != null && _activeHandler!.key.matches(parsed)) {
      final handler = _activeHandler!;
      _activeHandler = null;
      handler.onMatch(parsed);
      return;
    }

    // 3. Check expired handlers (oldest first) — absorb stale responses
    final expiredMatch = _expiredHandlers.indexWhere(
      (h) => h.key.matchesStrict(parsed),
    );
    if (expiredMatch != -1) {
      _expiredHandlers.removeAt(expiredMatch);
      staleResponsesAbsorbed++;
      return;
    }

    // 4. No match — discard cleanly
    unmatchedResponsesDiscarded++;

    // Lazy cleanup of old expired handlers
    _cleanupExpiredHandlers();
  }

  void _cleanupExpiredHandlers() {
    if (_expiredHandlers.isEmpty) return;

    final now = DateTime.now();
    _expiredHandlers.removeWhere(
      (h) => now.difference(h.expiredAt) > _expiredHandlerMaxAge,
    );

    // Cap the list size
    while (_expiredHandlers.length > _maxExpiredHandlers) {
      _expiredHandlers.removeAt(0);
    }
  }

  void clear() {
    _activeHandler = null;
    _expiredHandlers.clear();
  }
}

// -----------------------------------------------------------------------------
// RTT Statistics per message type
// -----------------------------------------------------------------------------

class _RttStats {
  int count = 0;
  int timeouts = 0;
  Duration total = Duration.zero;
  Duration min = const Duration(days: 1);
  Duration max = Duration.zero;
  Duration? last;

  void record(Duration rtt) {
    count++;
    total += rtt;
    last = rtt;
    if (rtt < min) min = rtt;
    if (rtt > max) max = rtt;
  }

  void recordTimeout() {
    timeouts++;
  }

  double get avgMs => count > 0 ? total.inMicroseconds / count / 1000 : 0;
  double get minMs => count > 0 ? min.inMicroseconds / 1000 : 0;
  double get maxMs => count > 0 ? max.inMicroseconds / 1000 : 0;
  double get lastMs => last != null ? last!.inMicroseconds / 1000 : 0;

  Map<String, dynamic> toJson() => {
        'count': count,
        'timeouts': timeouts,
        'avgMs': avgMs.toStringAsFixed(2),
        'minMs': minMs.toStringAsFixed(2),
        'maxMs': maxMs.toStringAsFixed(2),
        'lastMs': lastMs.toStringAsFixed(2),
      };
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
  StreamSubscription? _subscription;

  // Response demultiplexer
  final _ResponseDemux _demux = _ResponseDemux();

  // CC callback for receiving MIDI CC messages from the device
  CcCallback? _ccCallback;

  void setCcCallback(CcCallback callback) {
    _ccCallback = callback;
  }

  void clearCcCallback() {
    _ccCallback = null;
  }

  // Diagnostic counters
  int _totalPacketsReceived = 0;
  int _sysexPacketsReceived = 0;
  int _nonSysexPacketsReceived = 0;
  int _packetsFromWrongDevice = 0;
  DateTime? _lastPacketTime;
  bool _subscriptionActive = true;
  String? _lastSubscriptionError;

  // RTT (Round-Trip Time) tracking - overall stats
  int _totalRequestsCompleted = 0;
  int _totalRequestsTimedOut = 0;
  Duration _totalRtt = Duration.zero;
  Duration _minRtt = const Duration(days: 1); // Start high
  Duration _maxRtt = Duration.zero;
  Duration? _lastRtt;

  // RTT tracking per message type
  final Map<DistingNTRespMessageType, _RttStats> _rttByMessageType = {};

  // Track slow Algorithm Info requests by algorithm index (for debugging)
  static const Duration _slowThreshold = Duration(milliseconds: 50);
  final Map<int, Duration> _slowAlgorithmInfoByIndex = {};

  // Consecutive timeout tracking for stream health detection
  int _consecutiveTimeouts = 0;
  static const int _maxConsecutiveTimeoutsBeforeRecovery = 3;

  // Track if device connection is suspected broken (to skip risky disconnect)
  bool _deviceConnectionSuspectedBroken = false;

  // SysEx buffering for handling split messages (common on Windows)
  final List<int> _sysExBuffer = [];
  bool _isBufferingSysEx = false;

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

    final avgRttMs = _totalRequestsCompleted > 0
        ? (_totalRtt.inMicroseconds / _totalRequestsCompleted / 1000).toStringAsFixed(2)
        : 'N/A';

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
      // RTT statistics
      'rttRequestsCompleted': _totalRequestsCompleted,
      'rttRequestsTimedOut': _totalRequestsTimedOut,
      'rttLastMs': _lastRtt?.inMicroseconds != null
          ? (_lastRtt!.inMicroseconds / 1000).toStringAsFixed(2)
          : 'N/A',
      'rttAvgMs': avgRttMs,
      'rttMinMs': _totalRequestsCompleted > 0
          ? (_minRtt.inMicroseconds / 1000).toStringAsFixed(2)
          : 'N/A',
      'rttMaxMs': _totalRequestsCompleted > 0
          ? (_maxRtt.inMicroseconds / 1000).toStringAsFixed(2)
          : 'N/A',
      // Response demux diagnostics
      'staleResponsesAbsorbed': _demux.staleResponsesAbsorbed,
      'unmatchedResponsesDiscarded': _demux.unmatchedResponsesDiscarded,
      'expiredHandlerCount': _demux.expiredHandlerCount,
    };
  }

  /// Returns RTT statistics broken down by message type.
  Map<String, Map<String, dynamic>> getRttStatsByMessageType() {
    final result = <String, Map<String, dynamic>>{};
    for (final entry in _rttByMessageType.entries) {
      result[entry.key.name] = entry.value.toJson();
    }
    return result;
  }

  /// Returns slow Algorithm Info requests by algorithm index.
  /// Only includes requests that exceeded the slow threshold (50ms).
  /// Returns map of algorithmIndex -> duration in milliseconds.
  Map<int, double> getSlowAlgorithmInfo() {
    return _slowAlgorithmInfoByIndex.map(
      (index, duration) => MapEntry(index, duration.inMicroseconds / 1000),
    );
  }

  /// Records an RTT measurement for both overall and per-message-type stats.
  void _recordRtt(
    Duration rtt,
    DistingNTRespMessageType messageType, {
    int? libraryIndex,
  }) {
    // Update overall stats
    _totalRequestsCompleted++;
    _totalRtt += rtt;
    _lastRtt = rtt;
    if (rtt < _minRtt) _minRtt = rtt;
    if (rtt > _maxRtt) _maxRtt = rtt;

    // Update per-message-type stats
    _rttByMessageType.putIfAbsent(messageType, () => _RttStats());
    _rttByMessageType[messageType]!.record(rtt);

    // Track slow Algorithm Info requests by library index
    if (messageType == DistingNTRespMessageType.respAlgorithmInfo &&
        libraryIndex != null &&
        rtt > _slowThreshold) {
      // Keep the slowest time for each library index
      final existing = _slowAlgorithmInfoByIndex[libraryIndex];
      if (existing == null || rtt > existing) {
        _slowAlgorithmInfoByIndex[libraryIndex] = rtt;
      }
    }
  }

  /// Records a timeout for stats tracking.
  void _recordTimeout(DistingNTRespMessageType? messageType) {
    _totalRequestsTimedOut++;
    // Track timeout per message type if known
    if (messageType != null) {
      _rttByMessageType.putIfAbsent(messageType, () => _RttStats());
      _rttByMessageType[messageType]!.recordTimeout();
    }
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

  /// Resets internal MIDI state without full disconnect/reconnect.
  /// Clears buffers, resets counters, and re-subscribes to the stream.
  /// Does NOT affect the current request - caller is responsible for that.
  void _resetInternalState() {
    // Clear any partial SysEx data
    _sysExBuffer.clear();
    _isBufferingSysEx = false;

    // Reset consecutive timeout counter
    _consecutiveTimeouts = 0;

    // Re-establish subscription
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
      _totalPacketsReceived = 0;
      _sysexPacketsReceived = 0;
      _nonSysexPacketsReceived = 0;
      _packetsFromWrongDevice = 0;
    }
  }

  /// Forces a full MIDI device disconnect/reconnect cycle.
  /// This is used to recover from corrupted MIDI state caused by rogue
  /// non-SysEx bytes that break CoreMIDI/flutter_midi_command.
  Future<void> forceDeviceReconnect() async {
    // Cancel current subscription first (safe operation)
    _subscription?.cancel();
    _subscriptionActive = false;

    // On Windows (and some other platforms), input and output are separate devices
    // and both need to be disconnected/reconnected.
    //
    // IMPORTANT: If we suspect the device connection is broken (e.g., device was
    // unplugged), we skip the disconnect call entirely. Calling disconnectDevice
    // on an invalid handle can crash the native MIDI library on Windows.

    if (!_deviceConnectionSuspectedBroken) {
      // Try to disconnect, but wrap in defensive try-catch.
      // On Windows, disconnecting an already-invalid handle can crash.
      try {
        _midi.disconnectDevice(_inputDevice);
      } catch (e) {
        // Disconnect failed - device likely already disconnected
        _deviceConnectionSuspectedBroken = true;
      }

      if (_outputDevice.id != _inputDevice.id) {
        try {
          _midi.disconnectDevice(_outputDevice);
        } catch (e) {
          // Disconnect failed - device likely already disconnected
          _deviceConnectionSuspectedBroken = true;
        }
      }
    }

    // Brief delay to let the system settle
    await Future.delayed(const Duration(milliseconds: 500));

    // Try to reconnect the devices
    try {
      _midi.connectToDevice(_inputDevice);
      if (_outputDevice.id != _inputDevice.id) {
        _midi.connectToDevice(_outputDevice);
      }
      // If reconnect succeeded, clear the broken flag
      _deviceConnectionSuspectedBroken = false;
    } catch (e) {
      // Reconnect failed - device may not be available
      _deviceConnectionSuspectedBroken = true;
      return; // Don't try to set up subscription if reconnect failed
    }

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
  }

  void _handleSubscriptionError(Object error, StackTrace stackTrace) {
    _subscriptionActive = false;
    _lastSubscriptionError = error.toString();
  }

  void _handleSubscriptionDone() {
    _subscriptionActive = false;
  }

  /// Adds a passive observer that receives ALL parsed Disting NT SysEx messages,
  /// regardless of whether they match a pending request.
  void addMessageObserver(void Function(DistingNTParsedMessage) observer) {
    _demux.addObserver(observer);
  }

  /// Removes a previously added message observer.
  void removeMessageObserver(void Function(DistingNTParsedMessage) observer) {
    _demux.removeObserver(observer);
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
    _demux.clear();
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

    // If device is suspected broken, fail immediately instead of trying to send.
    // This prevents flooding the native layer with failed send attempts.
    if (_deviceConnectionSuspectedBroken) {
      _handleSendFailure(
        request,
        StateError('Device connection is broken - cannot send'),
      );
      return;
    }

    request.attemptCount++;

    // Start/restart stopwatch for RTT measurement
    request.stopwatch.reset();
    request.stopwatch.start();

    // Register handler with demux BEFORE sending (first attempt only).
    // Handler persists across retries — only moved to expired on final timeout.
    if (request.attemptCount == 1 &&
        request.expectation != ResponseExpectation.none) {
      _demux.registerActive(request.key, (parsed) {
        _onResponseMatched(request, parsed);
      });
    }

    // Send the message
    try {
      _midi.sendData(request.packet, deviceId: _outputDevice.id);
    } catch (e) {
      request.stopwatch.stop();
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

  /// Called by the demux when a response matches the active handler.
  void _onResponseMatched(_ScheduledRequest request, DistingNTParsedMessage parsed) {
    // Guard against race conditions
    if (request.completer.isCompleted) {
      _finishCurrentRequest();
      return;
    }

    // Cancel timeout timer since we got a response
    request.timeoutTimer?.cancel();

    // Reset consecutive timeout counter
    _consecutiveTimeouts = 0;

    // Record RTT measurement
    request.stopwatch.stop();
    final rtt = request.stopwatch.elapsed;
    _recordRtt(
      rtt,
      parsed.messageType,
      libraryIndex: request.key.libraryIndex,
    );

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
      if (request.expectation == ResponseExpectation.optional) {
        request.completer.complete(null);
      } else {
        request.completer.completeError(
          StateError('Unhandled response type: ${parsed.messageType}'),
        );
      }
    }

    _finishCurrentRequest();
  }

  void _onTimeout() {
    final request = _currentRequest;

    // Clear any partial SysEx buffer on timeout to prevent stale data
    if (_isBufferingSysEx) {
      _sysExBuffer.clear();
      _isBufferingSysEx = false;
    }

    // Guard against race conditions where response arrived just before timeout
    if (request == null || request.completer.isCompleted) {
      _consecutiveTimeouts = 0;
      _finishCurrentRequest();
      return;
    }

    if (request.attemptCount >= request.maxRetries) {
      // Out of retries — expire the handler so late responses get absorbed
      _demux.expireActive();

      // Record timeout for stats
      request.stopwatch.stop();
      _recordTimeout(request.key.messageType);
      _consecutiveTimeouts++;

      // Auto-recovery: after consecutive timeouts, reset MIDI state (buffers, subscription)
      // This is lighter than full disconnect/reconnect and handles most buffer corruption.
      if (_consecutiveTimeouts >= _maxConsecutiveTimeoutsBeforeRecovery) {
        _resetInternalState();
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
      // Retry after delay — handler persists across retries
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
      _demux.expireActive();
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
    // Clear SysEx buffer to avoid stale data affecting next request
    _sysExBuffer.clear();
    _isBufferingSysEx = false;
    _retryTimer = null;

    // Schedule next request after message interval
    if (_queue.isNotEmpty) {
      _nextProcessTimer?.cancel();
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
      if (startIndex == -1) break;

      final endIndex = raw.indexOf(0xF7, startIndex);
      if (endIndex == -1) break;

      // Per MIDI spec, a new F0 cancels any in-progress SysEx.
      int actualStart = startIndex;
      for (int i = startIndex + 1; i < endIndex; i++) {
        if (raw[i] == 0xF0) actualStart = i;
      }

      messages.add(raw.sublist(actualStart, endIndex + 1));
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
    // Handle SysEx buffering for split messages (common on Windows with large SysEx)
    final hasF0 = raw.contains(0xF0);
    final hasF7 = raw.contains(0xF7);

    // If we're currently buffering a SysEx message
    if (_isBufferingSysEx) {
      if (hasF0 && (!hasF7 || raw.indexOf(0xF0) < raw.indexOf(0xF7))) {
        // New F0 arrives before any F7 — interrupts our buffered SysEx.
        // Discard buffer and fall through to process this packet normally.
        _sysExBuffer.clear();
        _isBufferingSysEx = false;
      } else if (raw.isNotEmpty && raw[0] >= 0x80 && raw[0] != 0xF7 && !hasF0) {
        // Non-SysEx status byte (CC, Note, etc.) — dispatch CCs, skip rest
        _dispatchCcMessages(raw);
        _nonSysexPacketsReceived++;
        return;
      } else {
        // SysEx continuation data (data bytes < 0x80, or F7 terminator)
        _sysExBuffer.addAll(raw);
        if (hasF7) {
          _isBufferingSysEx = false;
          final completeMessage = Uint8List.fromList(_sysExBuffer);
          _sysExBuffer.clear();
          _sysexPacketsReceived++;
          _processExtractedSysEx(_extractSysExMessages(completeMessage));

          // Check for a trailing F0 (start of next split SysEx)
          final lastF7 = completeMessage.lastIndexOf(0xF7);
          if (lastF7 < completeMessage.length - 1) {
            final trailing = completeMessage.sublist(lastF7 + 1);
            if (trailing.contains(0xF0)) {
              final trailingF0 = trailing.indexOf(0xF0);
              _sysExBuffer.addAll(trailing.sublist(trailingF0));
              _isBufferingSysEx = true;
            }
          }
          return;
        }
        return;
      }
    }

    // Check if this starts a new SysEx that might be split
    if (hasF0 && !hasF7) {
      // Dispatch any CC messages that precede the SysEx start
      final f0Index = raw.indexOf(0xF0);
      if (f0Index > 0) {
        _dispatchCcMessages(Uint8List.sublistView(raw, 0, f0Index));
      }
      // Start of a split SysEx message
      _isBufferingSysEx = true;
      _sysExBuffer.clear();
      _sysExBuffer.addAll(raw.sublist(f0Index));
      return;
    }

    // Extract SysEx messages from packet, filtering out any rogue MIDI bytes.
    // Some plugins/algorithms send Program Change or Pitchwheel messages that
    // may be combined with SysEx responses by the MIDI library.
    final sysexMessages = _extractSysExMessages(raw);
    if (sysexMessages.isEmpty) {
      _dispatchCcMessages(raw);
      _nonSysexPacketsReceived++;
      return;
    }

    _sysexPacketsReceived++;

    // Dispatch CC messages from any non-SysEx bytes in the packet.
    // CC bytes may precede or follow the SysEx data.
    _dispatchCcMessages(raw);

    // Check for trailing split SysEx start after the last complete message
    final lastMsgEnd = raw.lastIndexOf(0xF7);
    if (lastMsgEnd < raw.length - 1) {
      final trailing = raw.sublist(lastMsgEnd + 1);
      if (trailing.contains(0xF0)) {
        final trailingF0 = trailing.indexOf(0xF0);
        _isBufferingSysEx = true;
        _sysExBuffer.clear();
        _sysExBuffer.addAll(trailing.sublist(trailingF0));
      }
    }

    _processExtractedSysEx(sysexMessages);
  }

  void _dispatchCcMessages(Uint8List raw) {
    final callback = _ccCallback;
    if (callback == null) return;
    for (int i = 0; i < raw.length; i++) {
      final byte = raw[i];
      if (byte & 0xF0 == 0xB0 && i + 2 < raw.length) {
        final data1 = raw[i + 1];
        final data2 = raw[i + 2];
        if (data1 < 0x80 && data2 < 0x80) {
          callback(byte & 0x0F, data1, data2);
          i += 2;
        }
      }
    }
  }

  void _processExtractedSysEx(List<Uint8List> sysexMessages) {
    for (final sysex in sysexMessages) {
      _dispatchSysEx(sysex);
    }
  }

  void _dispatchSysEx(Uint8List sysex) {
    try {
      final parsed = decodeDistingNTSysEx(sysex);
      if (parsed == null) return;
      if (parsed.sysExId != _sysExId) return;

      _demux.dispatch(parsed);
    } catch (e) {
      // Catch any unexpected exceptions to prevent scheduler from getting stuck.
    }
  }
}
