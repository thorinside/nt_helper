part of 'disting_cubit.dart';

final class _RemoteConnectionScope {
  _RemoteConnectionScope(this.id, this.manager);

  final int id;
  final IDistingMidiManager manager;
  Future<void> tail = Future<void>.value();
  DistingRequestCancellation cancellation = DistingRequestCancellation();
  final Set<int> sentPushes = {};
  int pending = 0;
}

final class _RemoteHostSession {
  _RemoteHostSession(this.id, this.connection);

  final String id;
  final _RemoteConnectionScope connection;
  final DistingRequestCancellation cancellation = DistingRequestCancellation();
  final Set<int> held = {};
}

/// Owns local input and the single active popup/overlay session. Remote work has
/// its own lifetime and queue; it never depends on memory queries or samples.
final class _RemoteDelegate {
  _RemoteDelegate(this._cubit);

  final DistingCubit _cubit;
  final _states = StreamController<RemoteControlState>.broadcast();
  RemoteControlState _state = RemoteControlState(
    unavailableReason:
        'Remote control requires a synchronized live connection.',
  );
  _RemoteConnectionScope? _connection;
  _RemoteHostSession? _session;
  IDistingMidiManager? _retiredManager;
  List<int> _pots = [2048, 2048, 2048];
  String? _reason = 'Remote control requires a synchronized live connection.';
  String? _error;
  int _connectionSequence = 0;
  int _sessionSequence = 0;
  bool _disposed = false;
  bool _closing = false;

  RemoteControlState get state {
    _synchronize(_cubit.state);
    return _state;
  }

  Stream<RemoteControlState> get stateStream => _states.stream;

  String openSession() {
    if (_closing || _disposed) {
      throw StateError('Remote control is unavailable during shutdown.');
    }
    _synchronize(_cubit.state);
    if (_reason != null) throw StateError(_reason!);
    final previous = _session;
    if (previous != null) {
      // Cleanup is serialized ahead of the replacement host's inputs. Its
      // errors are published, even if the old host no longer awaits them.
      unawaited(closeSession(previous.id).catchError((Object _) {}));
    }
    final connection = _connection!;
    final session = _RemoteHostSession(
      '${connection.id}:${++_sessionSequence}',
      connection,
    );
    _session = session;
    _publish();
    return session.id;
  }

  Future<void> send(String sessionId, RemoteAction action) async {
    action.validate();
    final session = _requireSession(sessionId);
    switch (action) {
      case RemotePush(:final index):
        if (!session.held.add(index)) return;
      case RemoteRelease(:final index):
        if (!session.held.remove(index)) return;
      case RemotePotTurn(:final index, :final value):
        if (_pots[index] == value) return;
        _pots[index] = value;
      case RemoteEncoderTurn(:final delta):
        if (delta == 0) return;
    }

    final connection = session.connection;
    connection.pending++;
    _publish();
    try {
      await _serialize(connection, () async {
        _requireSession(session.id);
        await (connection.manager as RemoteControlWriter).requestRemoteAction(
          action,
          cancellation: session.cancellation,
        );
        // A push may have been sent immediately before host closure. Record it
        // on the original connection even when that host has been invalidated,
        // so the queued cleanup can release it rather than losing the race.
        if (_isCurrent(connection)) {
          switch (action) {
            case RemotePush(:final index):
              connection.sentPushes.add(index);
            case RemoteRelease(:final index):
              connection.sentPushes.remove(index);
            default:
              break;
          }
        }
      });
    } catch (error) {
      if (identical(_session, session) &&
          !session.cancellation.isCancelled &&
          _isCurrent(connection) &&
          error is! DistingRequestCancelledException) {
        _error =
            'Remote input could not be sent; device state is unknown. $error';
        session.held.clear();
        session.cancellation.cancel();
      }
      rethrow;
    } finally {
      connection.pending--;
      if (_isCurrent(connection)) _publish();
    }
  }

  Future<void> adjustPot(String sessionId, int index, int adjustment) async {
    RemotePotTurn(index, 0).validate();
    _requireSession(sessionId);
    return send(
      sessionId,
      RemotePotTurn(index, (_pots[index] + adjustment).clamp(0, 4095)),
    );
  }

  /// Invalidates host callbacks immediately, cancels its queued actions, and
  /// releases only pushes sent through the still-valid original transport.
  Future<void> closeSession(String sessionId) async {
    _synchronize(_cubit.state);
    final session = _session;
    if (session == null || session.id != sessionId) return;
    _session = null;
    session.held.clear();
    session.cancellation.cancel();
    final connection = session.connection;
    final cancellation = connection.cancellation;
    connection.pending++;
    _publish();
    try {
      await _serialize(connection, () async {
        for (final index in connection.sentPushes.toList()) {
          if (!_isCurrent(connection) || cancellation.isCancelled) return;
          await (connection.manager as RemoteControlWriter).requestRemoteAction(
            RemoteRelease(index),
            cancellation: cancellation,
          );
          connection.sentPushes.remove(index);
        }
      });
    } catch (error) {
      if (_isCurrent(connection) &&
          error is! DistingRequestCancelledException) {
        _error =
            'Remote cleanup could not be sent; device release is unknown. $error';
      }
      rethrow;
    } finally {
      connection.pending--;
      if (_isCurrent(connection)) _publish();
    }
  }

  void onDistingStateWillChange(DistingState next) => _synchronize(next);

  /// Called before disposing or replacing a transport, not after its teardown.
  void clearConnection() {
    _retiredManager = _physicalManager(_cubit.state);
    _detach();
    _reason = 'Remote control requires a synchronized live connection.';
    _publish();
  }

  Future<void> dispose() async {
    if (_disposed || _closing) return;
    _closing = true;
    final session = _session;
    if (session != null) {
      try {
        await closeSession(session.id);
      } catch (_) {
        // Failure is already observable; shutdown cannot assert device release.
      }
    }
    clearConnection();
    _disposed = true;
    _closing = false;
    _reason = 'Remote control is unavailable after disposal.';
    _publish();
    await _states.close();
  }

  void _synchronize(DistingState next) {
    if (_disposed) return;
    final manager = _physicalManager(next);
    if (!identical(manager, _retiredManager)) _retiredManager = null;
    if (manager != null && identical(manager, _retiredManager)) return;
    if (!identical(manager, _connection?.manager)) {
      _detach();
      if (manager != null) {
        _connection = _RemoteConnectionScope(++_connectionSequence, manager);
        _pots = [2048, 2048, 2048];
        _error = null;
      }
    }
    _reason = _unavailableReason(next);
    final connection = _connection;
    if (_reason != null) {
      _session?.cancellation.cancel();
      _session = null;
      connection?.cancellation.cancel();
      connection?.sentPushes.clear();
    } else if (connection != null && connection.cancellation.isCancelled) {
      connection.cancellation = DistingRequestCancellation();
    }
    _publish();
  }

  IDistingMidiManager? _physicalManager(DistingState state) => switch (state) {
    DistingStateSynchronized(
      disting: final manager,
      offline: false,
      demo: false,
    ) =>
      manager,
    _ => null,
  };

  String? _unavailableReason(DistingState state) {
    if (state is! DistingStateSynchronized) {
      return 'Remote control requires a synchronized live connection.';
    }
    if (state.demo) return 'Remote control is unavailable in demo mode.';
    if (state.offline) return 'Remote control is unavailable in offline mode.';
    if (!state.firmwareVersion.hasRemoteControl) {
      return 'Remote control requires recognized firmware 1.19 or later.';
    }
    if (state.disting is! RemoteControlWriter) {
      return 'This connection does not support live remote writes.';
    }
    return null;
  }

  _RemoteHostSession _requireSession(String id) {
    if (_closing || _disposed) {
      throw StateError('Remote control is unavailable during shutdown.');
    }
    _synchronize(_cubit.state);
    final session = _session;
    if (_reason != null) throw StateError(_reason!);
    if (session == null ||
        session.id != id ||
        session.cancellation.isCancelled) {
      throw StateError('The remote host session is no longer active.');
    }
    return session;
  }

  bool _isCurrent(_RemoteConnectionScope connection) =>
      !_disposed && identical(_connection, connection) && _reason == null;

  Future<void> _serialize(
    _RemoteConnectionScope connection,
    Future<void> Function() action,
  ) {
    final operation = connection.tail.then((_) => action());
    connection.tail = operation.then<void>((_) {}, onError: (Object _) {});
    return operation;
  }

  void _detach() {
    final connection = _connection;
    final session = _session;
    _connection = null;
    _session = null;
    session?.cancellation.cancel();
    connection?.cancellation.cancel();
  }

  void _publish() {
    final next = RemoteControlState(
      connectionId: _connection?.id,
      sessionId: _session?.cancellation.isCancelled == false
          ? _session?.id
          : null,
      unavailableReason: _closing
          ? 'Remote control is unavailable during shutdown.'
          : _reason,
      heldControls: _session?.held ?? const {},
      potValues: _pots,
      pending: (_connection?.pending ?? 0) > 0,
      error: _error,
    );
    if (next.connectionId == _state.connectionId &&
        next.sessionId == _state.sessionId &&
        next.unavailableReason == _state.unavailableReason &&
        setEquals(next.heldControls, _state.heldControls) &&
        listEquals(next.potValues, _state.potValues) &&
        next.pending == _state.pending &&
        next.error == _state.error) {
      return;
    }
    _state = next;
    if (!_states.isClosed) _states.add(next);
  }
}
