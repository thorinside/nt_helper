import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_midi_command/flutter_midi_command.dart';

// Domain classes
import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'package:nt_helper/domain/request_key.dart';

/// Indicates whether a request expects a response or not,
/// and how to handle timeouts/no-response.
enum ResponseExpectation {
  /// Must get a response or we eventually throw a `TimeoutException`.
  required,

  /// We might get a response. If not, that's okay (we return `null`).
  optional,

  /// No response is expected at all.
  none,
}

class _ScheduledRequest<T> {
  final Uint8List sysExMessage;
  final RequestKey requestKey;
  final Completer<T?> completer;

  /// How we handle responses/timeouts (required, optional, none).
  final ResponseExpectation responseExpectation;

  /// Timeout for each attempt.
  final Duration timeout;

  /// Maximum number of send attempts for `required` messages.
  final int maxRetries;

  /// How long to wait between attempts (if a retry is needed).
  final Duration retryDelay;

  /// How many attempts have been made so far.
  int attemptCount = 0;

  /// A timer that tracks the response timeout for the **current** attempt.
  Timer? timeoutTimer;

  _ScheduledRequest({
    required this.sysExMessage,
    required this.requestKey,
    required this.completer,
    required this.responseExpectation,
    required this.timeout,
    required this.maxRetries,
    required this.retryDelay,
  });
}

class DistingMessageScheduler {
  final MidiCommand midiCommand;
  final MidiDevice inputDevice;
  final MidiDevice outputDevice;
  final int sysExId;

  /// Default amount of time to wait for a response (if `required` or `optional`).
  final Duration defaultTimeout;

  /// Interval between sending different queued requests (rate limiting).
  final Duration messageInterval;

  /// The default number of retries for `required` messages.
  final int defaultMaxRetries;

  /// If a retry is needed (because of a timeout), how long to wait before re-sending?
  final Duration defaultRetryDelay;

  StreamSubscription<MidiPacket>? _subscription;

  /// Queue of scheduled requests.
  final Queue<_ScheduledRequest> _queue = Queue();

  /// The request currently being processed.
  _ScheduledRequest? _currentRequest;

  /// Whether we’re in the middle of sending a request and waiting for the next step.
  bool _isSending = false;

  DistingMessageScheduler({
    required this.midiCommand,
    required this.inputDevice,
    required this.outputDevice,
    required this.sysExId,
    this.defaultTimeout = const Duration(milliseconds: 400),
    this.messageInterval = const Duration(milliseconds: 50),
    this.defaultMaxRetries = 5,
    this.defaultRetryDelay = const Duration(milliseconds: 120),
  }) {
    // Start listening for incoming MIDI data.
    _subscription = midiCommand.onMidiDataReceived?.listen(_handleIncomingMidi);
  }

  /// Dispose/stop the scheduler.
  void dispose() {
    midiCommand.teardown();

    _subscription?.cancel();

    // Clean up the current request's timer if any.
    _currentRequest?.timeoutTimer?.cancel();

    // Cancel any timers in the queue.
    while (_queue.isNotEmpty) {
      _queue.removeFirst().timeoutTimer?.cancel();
    }
  }

  /// Enqueue a SysEx message to be sent. Returns a Future that completes when:
  ///
  /// - If `responseExpectation == ResponseExpectation.none`:
  ///   The Future completes immediately after the message is sent (plus rate-limit delay).
  /// - If `responseExpectation == ResponseExpectation.optional`:
  ///   The Future completes with the decoded response **if** it arrives before [timeout].
  ///   Otherwise, it completes with `null`.
  /// - If `responseExpectation == ResponseExpectation.required`:
  ///   We attempt up to [maxRetries] times. If we never receive a response in time,
  ///   we throw a `TimeoutException`.
  ///
  /// [timeout] is per-attempt, not total. Each retry gets its own timer.
  Future<T?> sendRequest<T>(
    Uint8List sysExMessage,
    RequestKey requestKey, {
    ResponseExpectation responseExpectation = ResponseExpectation.required,
    Duration? timeout,
    int? maxRetries,
    Duration? retryDelay,
  }) {
    final completer = Completer<T?>();
    final req = _ScheduledRequest<T>(
      sysExMessage: sysExMessage,
      requestKey: requestKey,
      completer: completer,
      responseExpectation: responseExpectation,
      timeout: timeout ?? defaultTimeout,
      maxRetries: maxRetries ?? defaultMaxRetries,
      retryDelay: retryDelay ?? defaultRetryDelay,
    );

    _queue.add(req);
    _tryProcessNext();
    return completer.future;
  }

  /// Internal method to process the next request in the queue, if we aren’t
  /// already busy.
  void _tryProcessNext() {
    if (_isSending || _currentRequest != null || _queue.isEmpty) {
      return;
    }

    _currentRequest = _queue.removeFirst();
    _isSending = true;

    // Start the first attempt.
    _startAttempt();
  }

  /// Attempts to send the current request, set up the timer, etc.
  void _startAttempt() {
    final current = _currentRequest!;
    current.attemptCount++;

    // Send the SysEx data
    midiCommand.sendData(current.sysExMessage, deviceId: outputDevice.id);
    if (kDebugMode) {
      print('Sent SysEx (attempt ${current.attemptCount}): '
          '${current.sysExMessage.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join(' ')} ${_currentRequest?.requestKey}');
    }

    // If no response expected → complete immediately (after the rate-limit delay).
    if (current.responseExpectation == ResponseExpectation.none) {
      // Complete now
      current.completer.complete(null);
      // After sending, wait [messageInterval] before sending the next queued request.
      Timer(messageInterval, () {
        _cleanupCurrentRequest();
        _tryProcessNext();
      });
      return;
    }

    // If `required` or `optional`, we set up a timeout timer for this attempt.
    current.timeoutTimer?.cancel();
    current.timeoutTimer = Timer(current.timeout, () {
      if (!current.completer.isCompleted) {
        if (current.responseExpectation == ResponseExpectation.required) {
          // Are we out of retries?
          if (current.attemptCount >= current.maxRetries) {
            // Fail with an error
            current.completer.completeError(
              TimeoutException(
                'No response after ${current.attemptCount} attempt(s), giving up.',
                current.timeout,
              ),
            );
            _cleanupCurrentRequest();
            _tryProcessNext();
          } else {
            // We can try again
            print(
                'No response in time, retrying (attempt ${current.attemptCount + 1})...');
            _scheduleRetry(current.retryDelay);
          }
        } else {
          // `optional` → if no response by now, just yield null
          current.completer.complete(null);
          _cleanupCurrentRequest();
          _tryProcessNext();
        }
      }
    });

    // Rate limit: wait [messageInterval] before we allow the next request in the queue to proceed.
    // But we do NOT free the queue here, because we’re waiting for a response or a timeout.
    // The queue remains blocked until success or final failure for `required`, or until the timer
    // completes for `optional`.
  }

  /// Schedules the next retry attempt after [delay].
  void _scheduleRetry(Duration delay) {
    final current = _currentRequest!;
    // Wait [delay], then re-send the request.
    Timer(delay, () {
      // Ensure the request is still current (hasn't completed in the meantime).
      if (_currentRequest == current && !current.completer.isCompleted) {
        _startAttempt();
      }
    });
  }

  /// Cleans up the current request (cancels timers, sets state to idle).
  void _cleanupCurrentRequest() {
    _currentRequest?.timeoutTimer?.cancel();
    _currentRequest = null;
    _isSending = false;
  }

  /// Handles incoming MIDI data. If it matches the `requestKey` of our
  /// current request, we complete that request’s future successfully.
  void _handleIncomingMidi(MidiPacket packet) {
    final data = packet.data;
    final parsedMessage = DistingNT.decodeDistingNTSysEx(data);
    if (parsedMessage == null) return;
    if (parsedMessage.sysExId != sysExId) return;

    // Build a RequestKey from the incoming message so we know which request it matches.
    final incomingKey = RequestKey(
      sysExId: sysExId,
      messageType: parsedMessage.messageType,
      algorithmIndex: (parsedMessage.payload is HasAlgorithmIndex)
          ? (parsedMessage.payload as HasAlgorithmIndex).algorithmIndex
          : null,
      parameterNumber: (parsedMessage.payload is HasParameterNumber)
          ? (parsedMessage.payload as HasParameterNumber).parameterNumber
          : null,
    );

    // If it's the currently active request, fulfill it.
    if (_currentRequest != null && _currentRequest!.requestKey == incomingKey) {
      final current = _currentRequest!;
      final decodedResponse = _decodeResponse(parsedMessage);

      if (!current.completer.isCompleted) {
        current.completer.complete(decodedResponse);
      }
      _cleanupCurrentRequest();
      _tryProcessNext();
    } else {
      // Possibly an unsolicited message or it doesn't match the current request.
      // You can handle or ignore accordingly.
    }
  }

  dynamic _decodeResponse(DistingNTParsedMessage parsedMessage) {
    // Extract relevant details from the parsed message
    final messageType = parsedMessage.messageType;
    final payload = parsedMessage.payload;

    try {
      // Handle response types and decode accordingly
      switch (messageType) {
        case DistingNTRespMessageType.respNumAlgorithms:
          return DistingNT.decodeNumberOfAlgorithms(payload);

        case DistingNTRespMessageType.respNumAlgorithmsInPreset:
          return DistingNT.decodeNumberOfAlgorithmsInPreset(payload);

        case DistingNTRespMessageType.respAlgorithmInfo:
          return DistingNT.decodeAlgorithmInfo(payload);

        case DistingNTRespMessageType.respPresetName:
          return DistingNT.decodeMessage(payload);

        case DistingNTRespMessageType.respNumParameters:
          return DistingNT.decodeNumParameters(payload);

        case DistingNTRespMessageType.respParameterInfo:
          return DistingNT.decodeParameterInfo(payload);

        case DistingNTRespMessageType.respAllParameterValues:
          return DistingNT.decodeAllParameterValues(payload);

        case DistingNTRespMessageType.respParameterValue:
          return DistingNT.decodeParameterValue(payload);

        case DistingNTRespMessageType.respParameterValueString:
          return DistingNT.decodeParameterValueString(payload);

        case DistingNTRespMessageType.respEnumStrings:
          return DistingNT.decodeEnumStrings(payload);

        case DistingNTRespMessageType.respMapping:
          return DistingNT.decodeMapping(payload);

        case DistingNTRespMessageType.respRouting:
          return DistingNT.decodeRoutingInformation(payload);

        case DistingNTRespMessageType.respMessage:
          return DistingNT.decodeMessage(payload);

        case DistingNTRespMessageType.respAlgorithm:
          return DistingNT.decodeAlgorithm(payload);

        case DistingNTRespMessageType.respUnitStrings:
          return DistingNT.decodeStrings(payload);

        case DistingNTRespMessageType.respScreenshot:
          return DistingNT.decodeBitmap(payload);

        case DistingNTRespMessageType.respParameterPages:
          return DistingNT.decodeParameterPages(payload);

        default:
          if (kDebugMode) {
            print("Unknown or unsupported message type: $messageType");
          }
          return null; // Unhandled message type
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error decoding response: $e in $parsedMessage");
      }
      return null;
    }
  }
}
