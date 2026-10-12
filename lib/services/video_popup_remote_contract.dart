import 'package:flutter/services.dart';
import 'package:nt_helper/models/remote_action.dart';
import 'package:nt_helper/models/remote_control_state.dart';

/// The same codec-safe contract is used by both existing popup adapters.
abstract final class VideoPopupRemoteContract {
  static const acquire = 'remoteAcquire';
  static const read = 'remoteRead';
  static const open = 'remoteOpen';
  static const action = 'remoteAction';
  static const close = 'remoteClose';
  static const detach = 'remoteDetach';

  static Map<String, dynamic> map(Object? value) {
    if (value is! Map || value.keys.any((key) => key is! String)) {
      throw const FormatException('Remote payload must be a map.');
    }
    return Map<String, dynamic>.from(value);
  }

  static String host(Map<String, dynamic> data) {
    final host = data['hostId'];
    if (host is! String || host.isEmpty || host.length > 128) {
      throw const FormatException('Invalid remote host identity.');
    }
    return host;
  }

  static Map<String, Object> encodeAction(RemoteAction action) => {
    'type': switch (action) {
      RemotePush() => 'push',
      RemoteRelease() => 'release',
      RemoteEncoderTurn() => 'encoder',
      RemotePotTurn() => 'pot',
    },
    'index': action.index,
    if (action case RemoteEncoderTurn(:final delta)) 'value': delta,
    if (action case RemotePotTurn(:final value)) 'value': value,
  };

  static int integer(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value is! int) throw FormatException('Invalid remote $key.');
    return value;
  }

  static RemoteAction decodeAction(Object? payload) {
    final data = map(payload);
    final index = integer(data, 'index');
    final action = switch (data['type']) {
      'push' => RemotePush(index),
      'release' => RemoteRelease(index),
      'encoder' => RemoteEncoderTurn(index, integer(data, 'value')),
      'pot' => RemotePotTurn(index, integer(data, 'value')),
      _ => throw const FormatException('Unknown remote action.'),
    };
    action.validate();
    return action;
  }

  static Map<String, Object?> snapshot(
    RemoteControlState state,
    String hostId,
    int revision,
    String? session,
  ) => {
    'hostId': hostId,
    'revision': revision,
    'connectionId': state.connectionId,
    'sessionId': session == state.sessionId ? session : null,
    'unavailableReason':
        state.unavailableReason ??
        (state.sessionId != null && session != state.sessionId
            ? 'Remote control is active in another video host.'
            : null),
    'heldControls': session == state.sessionId
        ? state.heldControls.toList()
        : <int>[],
    'potValues': state.potValues,
    'pending': state.pending,
    'error': state.error,
  };

  static RemoteControlState decodeSnapshot(Object? payload) {
    final data = map(payload);
    host(data);
    integer(data, 'revision');
    final pots = data['potValues'];
    final holds = data['heldControls'];
    if (pots is! List ||
        pots.length != 3 ||
        pots.any((v) => v is! int || v < 0 || v > 4095) ||
        holds is! List ||
        holds.any((v) => v is! int || v < 0 || v > 8) ||
        data['pending'] is! bool ||
        (data['connectionId'] != null && data['connectionId'] is! int) ||
        (data['sessionId'] != null && data['sessionId'] is! String) ||
        (data['unavailableReason'] != null &&
            data['unavailableReason'] is! String) ||
        (data['error'] != null && data['error'] is! String)) {
      throw const FormatException('Invalid remote state.');
    }
    return RemoteControlState(
      connectionId: data['connectionId'] as int?,
      sessionId: data['sessionId'] as String?,
      unavailableReason: data['unavailableReason'] as String?,
      heldControls: holds.cast<int>().toSet(),
      potValues: pots.cast<int>(),
      pending: data['pending'] as bool,
      error: data['error'] as String?,
    );
  }

  static PlatformException failure(Object error, {Object? details}) =>
      PlatformException(
        code: 'remote_failed',
        message: '$error',
        details: details,
      );
}
