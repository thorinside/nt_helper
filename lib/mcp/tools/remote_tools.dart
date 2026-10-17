import 'dart:async';
import 'dart:convert';

import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/models/remote_action.dart';

/// Tool caller lifetime around the existing remote UI authority.
/// Gestures never retain holds across calls and never imply hardware readback.
final class RemoteTools {
  RemoteTools(this._cubit);

  final DistingCubit _cubit;
  _RemoteGesture? _active;
  bool _disposed = false;

  static const gestureDeadline = Duration(seconds: 6);
  static const cleanupDeadline = Duration(seconds: 2);

  Future<String> remoteState(Map<String, dynamic> arguments) async {
    if (arguments.isNotEmpty) {
      return jsonEncode({
        'success': false,
        'error': 'remote_state takes no arguments.',
      });
    }
    final state = _cubit.remoteControlState;
    return jsonEncode({
      'success': true,
      'available': !_disposed && state.available,
      'unavailable_reason': _disposed
          ? 'Tool caller is disposed.'
          : state.unavailableReason,
      'busy': state.sessionId != null || _active != null,
      'capabilities': {
        'push_indices': [0, 1, 2, 3, 4, 5, 6, 7, 8],
        'encoder_indices': [0, 1],
        'pot_indices': [0, 1, 2],
        'pot_range': [0, 4095],
        'max_actions': 32,
        'max_encoder_delta': 1024,
        'max_total_encoder_ticks': 2048,
        'max_wait_ms': 1000,
        'max_total_wait_ms': 2000,
        'gesture_deadline_ms': gestureDeadline.inMilliseconds,
        'cleanup_deadline_ms': cleanupDeadline.inMilliseconds,
        'holds_across_calls': false,
      },
      'controls': {
        'buttons': {'1': 0, '2': 1, '3': 2, '4': 3},
        'pot_pushes': {'left': 4, 'center': 5, 'right': 6},
        'encoder_pushes': {'left': 7, 'right': 8},
        'pots': {'left': 0, 'center': 1, 'right': 2},
        'encoders': {'left': 0, 'right': 1},
      },
      'commanded': {
        'pot_values': state.potValues,
        'held_controls': state.heldControls.toList()..sort(),
        'pending_release_controls': state.pendingReleaseControls.toList()
          ..sort(),
        'pending': state.pending,
        'error': state.error,
      },
      'hardware_reported': null,
      'acknowledged': false,
    });
  }

  Future<String> remoteControl(Map<String, dynamic> arguments) async {
    final List<Object> actions;
    try {
      actions = _parse(arguments);
    } catch (error) {
      return jsonEncode({'success': false, 'error': '$error'});
    }
    if (_disposed) return _failure('Tool caller is disposed.');
    if (_active != null || _cubit.remoteControlState.sessionId != null) {
      return _failure('Remote control is busy in another gesture or UI host.');
    }
    final gesture = _RemoteGesture();
    _active = gesture;
    Object? failure;
    Object? cleanupFailure;
    var completed = 0;
    Timer? deadline;
    try {
      gesture.session = _cubit.openRemoteSession();
      gesture.connectionId = _cubit.remoteControlState.connectionId;
      deadline = Timer(gestureDeadline, () {
        gesture.cancel('Remote gesture deadline exceeded.');
        unawaited(_cleanup(gesture).catchError((Object _) {}));
      });
      for (final action in actions) {
        gesture.check();
        final work = action is Duration
            ? Future<void>.delayed(action)
            : _cubit.sendRemoteAction(gesture.session!, action as RemoteAction);
        await Future.any<void>([work, gesture.cancelled.future]);
        gesture.check();
        if (_cubit.remoteControlState.sessionId != gesture.session) {
          throw StateError('The remote connection or host session was lost.');
        }
        completed++;
      }
    } catch (error) {
      failure = error;
    } finally {
      deadline?.cancel();
      try {
        await _cleanup(gesture);
      } catch (error) {
        cleanupFailure = error;
      }
      if (identical(_active, gesture)) _active = null;
    }
    return jsonEncode({
      'success': failure == null && cleanupFailure == null,
      'actions_completed': completed,
      'delivery': 'transport_send_only',
      'acknowledged': false,
      'hardware_reported': null,
      'release_status': cleanupFailure == null
          ? (gesture.session == null ? 'not_needed' : 'cleanup_completed')
          : 'unknown',
      if (failure != null) 'error': '$failure',
      if (cleanupFailure != null)
        'cleanup_error': 'Device release is unknown. $cleanupFailure',
    });
  }

  /// Cancellation invalidates the Cubit token immediately, before awaiting.
  Future<void> cancelRemoteControl() async {
    final gesture = _active;
    if (gesture == null) return;
    gesture.cancel('Remote gesture cancelled by its caller.');
    await _cleanup(gesture);
  }

  Future<void> dispose() async {
    _disposed = true;
    await cancelRemoteControl();
  }

  Future<void> _cleanup(_RemoteGesture gesture) =>
      gesture.cleanup ??= () async {
        final session = gesture.session;
        if (session != null) {
          await _cubit.closeRemoteSession(session).timeout(cleanupDeadline);
          final state = _cubit.remoteControlState;
          if (!state.available || state.connectionId != gesture.connectionId) {
            throw StateError(
              'Remote connection lost; device release is unknown.',
            );
          }
          if (state.pendingReleaseControls.isNotEmpty) {
            throw StateError(
              'Remote holds still require release; device release is unknown.',
            );
          }
          if (state.sessionId != null && state.sessionId != session) {
            throw StateError('Remote host changed; device release is unknown.');
          }
        }
      }();

  String _failure(String message) =>
      jsonEncode({'success': false, 'error': message});

  List<Object> _parse(Map<String, dynamic> arguments) {
    if (arguments.keys.any((key) => key != 'actions')) {
      throw const FormatException('Only actions is accepted.');
    }
    final raw = arguments['actions'];
    if (raw is! List || raw.isEmpty || raw.length > 32) {
      throw const FormatException('actions must contain 1 to 32 actions.');
    }
    var totalWait = 0;
    var totalTicks = 0;
    final result = <Object>[];
    for (final item in raw) {
      if (item is! Map || item.keys.any((key) => key is! String)) {
        throw const FormatException('Each action must be an object.');
      }
      final type = item['type'];
      final keys = switch (type) {
        'push' || 'release' => {'type', 'index'},
        'encoder_turn' => {'type', 'index', 'delta'},
        'pot_turn' => {'type', 'index', 'value'},
        'wait' => {'type', 'duration_ms'},
        _ => throw const FormatException('Unknown remote action type.'),
      };
      if (item.length != keys.length ||
          item.keys.any((key) => !keys.contains(key))) {
        throw const FormatException('Action fields do not match its type.');
      }
      int integer(String key) {
        final value = item[key];
        if (value is! int) throw FormatException('$key must be an integer.');
        return value;
      }

      if (type == 'wait') {
        final milliseconds = integer('duration_ms');
        if (milliseconds < 0 || milliseconds > 1000) {
          throw const FormatException('Each wait must be 0 to 1000 ms.');
        }
        totalWait += milliseconds;
        result.add(Duration(milliseconds: milliseconds));
      } else {
        final index = integer('index');
        final action = switch (type) {
          'push' => RemotePush(index),
          'release' => RemoteRelease(index),
          'encoder_turn' => RemoteEncoderTurn(index, integer('delta')),
          'pot_turn' => RemotePotTurn(index, integer('value')),
          _ => throw const FormatException('Unknown action.'),
        };
        action.validate();
        if (action case RemoteEncoderTurn(:final delta)) {
          if (delta.abs() > 1024) {
            throw const FormatException('Encoder delta exceeds 1024 ticks.');
          }
          totalTicks += delta.abs();
        }
        result.add(action);
      }
    }
    if (totalWait > 2000 || totalTicks > 2048) {
      throw const FormatException(
        'Gesture exceeds 2000 ms wait or 2048 encoder ticks.',
      );
    }
    return result;
  }
}

final class _RemoteGesture {
  String? session;
  int? connectionId;
  final cancelled = Completer<void>();
  String? cancellationReason;
  Future<void>? cleanup;

  void cancel(String reason) {
    cancellationReason ??= reason;
    if (!cancelled.isCompleted) cancelled.complete();
  }

  void check() {
    if (cancellationReason != null) throw StateError(cancellationReason!);
  }
}
