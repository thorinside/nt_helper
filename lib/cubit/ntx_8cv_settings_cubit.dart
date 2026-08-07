import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:nt_helper/cubit/ntx_8cv_connection_cubit.dart';
import 'package:nt_helper/domain/ntx_8cv/ntx_8cv_sysex.dart';

/// The released NTX-8CV setting that enables its ES-5 output use.
const int kNtx8cvEs5EnabledSettingId = 0x01;

/// Presentation state for the device-confirmed ES-5 setting.
class Ntx8cvSettingsState {
  const Ntx8cvSettingsState({
    this.confirmedEs5Enabled,
    this.attemptedEs5Enabled,
    this.isLoadingEs5 = false,
    this.isWritingEs5 = false,
    this.es5Message,
  });

  /// The value most recently read from the selected NTX-8CV.
  final bool? confirmedEs5Enabled;

  /// A value being written or left unconfirmed after a failed write.
  final bool? attemptedEs5Enabled;
  final bool isLoadingEs5;
  final bool isWritingEs5;
  final String? es5Message;

  bool get hasPendingEs5Change => attemptedEs5Enabled != null;

  Ntx8cvSettingsState copyWith({
    bool? confirmedEs5Enabled,
    bool clearConfirmedEs5Enabled = false,
    bool? attemptedEs5Enabled,
    bool clearAttemptedEs5Enabled = false,
    bool? isLoadingEs5,
    bool? isWritingEs5,
    String? es5Message,
    bool clearEs5Message = false,
  }) {
    return Ntx8cvSettingsState(
      confirmedEs5Enabled: clearConfirmedEs5Enabled
          ? null
          : confirmedEs5Enabled ?? this.confirmedEs5Enabled,
      attemptedEs5Enabled: clearAttemptedEs5Enabled
          ? null
          : attemptedEs5Enabled ?? this.attemptedEs5Enabled,
      isLoadingEs5: isLoadingEs5 ?? this.isLoadingEs5,
      isWritingEs5: isWritingEs5 ?? this.isWritingEs5,
      es5Message: clearEs5Message ? null : es5Message ?? this.es5Message,
    );
  }
}

/// Loads and changes settings for the currently identity-validated NTX-8CV.
///
/// This cubit owns device-confirmed setting state, not MIDI endpoints. It
/// listens to [Ntx8cvConnectionCubit] so it can only issue setting requests
/// through the session that is currently scoped to the selected device.
class Ntx8cvSettingsCubit extends Cubit<Ntx8cvSettingsState> {
  Ntx8cvSettingsCubit({required Ntx8cvConnectionCubit connectionCubit})
    : _connectionCubit = connectionCubit,
      super(const Ntx8cvSettingsState()) {
    _connectionSubscription = _connectionCubit.stream.listen(
      _handleConnectionState,
    );
    _handleConnectionState(_connectionCubit.state);
  }

  final Ntx8cvConnectionCubit _connectionCubit;
  late final StreamSubscription<Ntx8cvConnectionState> _connectionSubscription;
  Ntx8cvSession? _activeSession;
  String? _targetKey;

  /// Changes ES-5 use immediately, but commits it to presentation state only
  /// after a read of setting `0x01` returns the attempted value.
  Future<void> setEs5Enabled(bool enabled) async {
    final session = _currentSession;
    if (session == null ||
        state.confirmedEs5Enabled == null ||
        state.isLoadingEs5 ||
        state.isWritingEs5 ||
        state.hasPendingEs5Change ||
        state.confirmedEs5Enabled == enabled) {
      return;
    }
    await _writeEs5Enabled(session, enabled);
  }

  /// Explicitly resends the retained, unconfirmed ES-5 change to the current
  /// identity-validated NTX-8CV. This method never reconnects or retries on
  /// its own, so a retry always uses the currently selected endpoints and ID.
  Future<void> retryEs5Change() async {
    final session = _currentSession;
    final attemptedValue = state.attemptedEs5Enabled;
    if (session == null ||
        attemptedValue == null ||
        state.isLoadingEs5 ||
        state.isWritingEs5) {
      return;
    }
    await _writeEs5Enabled(session, attemptedValue);
  }

  Future<void> _writeEs5Enabled(Ntx8cvSession session, bool enabled) async {
    emit(
      state.copyWith(
        attemptedEs5Enabled: enabled,
        isWritingEs5: true,
        clearEs5Message: true,
      ),
    );
    try {
      await session.writeAndConfirmSetting(
        settingId: kNtx8cvEs5EnabledSettingId,
        value: enabled ? 1 : 0,
      );
      if (!_isActiveSession(session)) return;
      emit(
        state.copyWith(
          confirmedEs5Enabled: enabled,
          clearAttemptedEs5Enabled: true,
          isWritingEs5: false,
          clearEs5Message: true,
        ),
      );
    } catch (_) {
      if (!_isActiveSession(session)) return;
      emit(
        state.copyWith(
          isWritingEs5: false,
          es5Message:
              'The ES-5 change was not confirmed by device readback. The '
              'actual device state is uncertain.',
        ),
      );
    }
  }

  @override
  Future<void> close() async {
    await _connectionSubscription.cancel();
    return super.close();
  }

  void _handleConnectionState(Ntx8cvConnectionState connectionState) {
    final targetKey = _connectionTargetKey(connectionState);
    if (targetKey != null && targetKey != _targetKey) {
      final hasPreviousTarget = _targetKey != null;
      _targetKey = targetKey;
      _activeSession = null;
      if (!isClosed) {
        emit(
          hasPreviousTarget
              ? _stateForChangedTarget()
              : const Ntx8cvSettingsState(),
        );
      }
    }

    final session = _connectionCubit.session;
    if (session == null) {
      _activeSession = null;
      if (state.isWritingEs5 && !isClosed) {
        emit(
          state.copyWith(
            isWritingEs5: false,
            es5Message:
                'The NTX-8CV disconnected before the ES-5 change could be '
                'confirmed. The actual device state is uncertain.',
          ),
        );
      }
      return;
    }
    if (identical(session, _activeSession)) return;

    _activeSession = session;
    if (!state.hasPendingEs5Change) {
      unawaited(_readEs5Enabled(session));
    }
  }

  /// Clears a confirmation that belongs to a different selected target while
  /// retaining an explicit pending change for a user-directed retry.
  Ntx8cvSettingsState _stateForChangedTarget() {
    final attemptedValue = state.attemptedEs5Enabled;
    return Ntx8cvSettingsState(
      attemptedEs5Enabled: attemptedValue,
      es5Message: attemptedValue == null
          ? null
          : 'The NTX-8CV target changed before the ES-5 change could be '
                'confirmed. The actual device state is uncertain. Retry send '
                'will use the current selected connection and device ID.',
    );
  }

  Future<void> _readEs5Enabled(Ntx8cvSession session) async {
    emit(state.copyWith(isLoadingEs5: true, clearEs5Message: true));
    try {
      final response = await session.readSetting(
        settingId: kNtx8cvEs5EnabledSettingId,
      );
      if (!_isActiveSession(session)) return;
      if (response.value != 0 && response.value != 1) {
        throw StateError('ES-5 setting has invalid value ${response.value}.');
      }
      emit(
        state.copyWith(
          confirmedEs5Enabled: response.value == 1,
          isLoadingEs5: false,
          clearEs5Message: true,
        ),
      );
    } catch (_) {
      if (!_isActiveSession(session)) return;
      emit(
        state.copyWith(
          isLoadingEs5: false,
          es5Message:
              'Could not read the device-confirmed ES-5 setting. Check the '
              'NTX-8CV connection and reconnect to try again.',
        ),
      );
    }
  }

  Ntx8cvSession? get _currentSession {
    final session = _connectionCubit.session;
    return identical(session, _activeSession) ? session : null;
  }

  bool _isActiveSession(Ntx8cvSession session) =>
      !isClosed &&
      identical(session, _activeSession) &&
      identical(session, _connectionCubit.session);

  static String? _connectionTargetKey(Ntx8cvConnectionState state) {
    final inputId = state.selectedInputDevice?.id;
    final outputId = state.selectedOutputDevice?.id;
    if (inputId == null || outputId == null) return null;
    return '$inputId:$outputId:${state.deviceId}';
  }
}
