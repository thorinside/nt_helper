import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:nt_helper/cubit/ntx_8cv_connection_cubit.dart';
import 'package:nt_helper/domain/ntx_8cv/ntx_8cv_sysex.dart';

/// The released NTX-8CV setting that selects its eight-channel block.
const int kNtx8cvChannelGroupSettingId = 0x00;

/// The released NTX-8CV setting that enables its ES-5 output use.
const int kNtx8cvEs5EnabledSettingId = 0x01;

/// The first of the eight released per-audio-channel enable settings.
///
/// The Expert Sleepers configuration tool identifies settings `0x04` through
/// `0x0B` as the enable flags for audio channels 1 through 8, respectively.
const int kNtx8cvFirstAudioChannelEnabledSettingId = 0x04;

/// The upstream NT expansion-mode setting. It is probed before it is writable.
const int kNtx8cvExpansionModeSettingId = 0x1B;

/// The three owner-supported NT expansion modes and their protocol values.
enum Ntx8cvExpansionMode {
  cv8x8(0, '8x8 CV'),
  audio1x8_32bit(1, '1x8 32bit Audio'),
  audio2x8_16bit(2, '2x8 16bit Audio');

  const Ntx8cvExpansionMode(this.value, this.label);

  final int value;
  final String label;

  static Ntx8cvExpansionMode? fromValue(int value) {
    for (final mode in values) {
      if (mode.value == value) return mode;
    }
    return null;
  }
}

/// The eight individually configurable NTX-8CV audio channels.
///
/// These settings are applicable only while the device-confirmed expansion
/// mode is one of the audio modes. Their setting IDs come directly from the
/// released NTX-8CV configuration tool's `Enable audio channel` controls.
enum Ntx8cvAudioChannel {
  channel1,
  channel2,
  channel3,
  channel4,
  channel5,
  channel6,
  channel7,
  channel8;

  int get number => index + 1;
  int get settingId => kNtx8cvFirstAudioChannelEnabledSettingId + index;
  String get label => 'Audio channel $number';
}

/// The released Channel Group values, each selecting one eight-channel block.
enum Ntx8cvChannelGroup {
  channels1To8(0, '1–8'),
  channels9To16(1, '9–16'),
  channels17To24(2, '17–24'),
  channels25To32(3, '25–32'),
  channels33To40(4, '33–40'),
  channels41To48(5, '41–48'),
  channels49To56(6, '49–56'),
  channels57To64(7, '57–64');

  const Ntx8cvChannelGroup(this.value, this.label);

  final int value;
  final String label;

  static Ntx8cvChannelGroup? fromValue(int value) {
    for (final group in values) {
      if (group.value == value) return group;
    }
    return null;
  }
}

enum Ntx8cvSetting { channelGroup, es5Enabled, expansionMode }

extension on Ntx8cvSetting {
  int get id => switch (this) {
    Ntx8cvSetting.channelGroup => kNtx8cvChannelGroupSettingId,
    Ntx8cvSetting.es5Enabled => kNtx8cvEs5EnabledSettingId,
    Ntx8cvSetting.expansionMode => kNtx8cvExpansionModeSettingId,
  };

  String get label => switch (this) {
    Ntx8cvSetting.channelGroup => 'Channel Group',
    Ntx8cvSetting.es5Enabled => 'ES-5',
    Ntx8cvSetting.expansionMode => 'NT expansion mode',
  };
}

/// The confirmed and attempted state of one NTX-8CV setting.
///
/// An attempted value is deliberately not folded into [confirmedValue]: no
/// write acknowledgement exists, so only a matching readback can confirm it.
class Ntx8cvSettingChange {
  const Ntx8cvSettingChange({
    this.confirmedValue,
    this.attemptedValue,
    this.isLoading = false,
    this.isWriting = false,
    this.message,
  });

  final int? confirmedValue;
  final int? attemptedValue;
  final bool isLoading;
  final bool isWriting;
  final String? message;

  bool get hasPendingChange => attemptedValue != null;

  Ntx8cvSettingChange copyWith({
    int? confirmedValue,
    bool clearConfirmedValue = false,
    int? attemptedValue,
    bool clearAttemptedValue = false,
    bool? isLoading,
    bool? isWriting,
    String? message,
    bool clearMessage = false,
  }) {
    return Ntx8cvSettingChange(
      confirmedValue: clearConfirmedValue
          ? null
          : confirmedValue ?? this.confirmedValue,
      attemptedValue: clearAttemptedValue
          ? null
          : attemptedValue ?? this.attemptedValue,
      isLoading: isLoading ?? this.isLoading,
      isWriting: isWriting ?? this.isWriting,
      message: clearMessage ? null : message ?? this.message,
    );
  }
}

/// Presentation state for the device-confirmed NTX-8CV settings.
class Ntx8cvSettingsState {
  const Ntx8cvSettingsState({
    this.channelGroup = const Ntx8cvSettingChange(),
    this.es5 = const Ntx8cvSettingChange(),
    this.mode = const Ntx8cvSettingChange(),
    this.audioChannels = const [
      Ntx8cvSettingChange(),
      Ntx8cvSettingChange(),
      Ntx8cvSettingChange(),
      Ntx8cvSettingChange(),
      Ntx8cvSettingChange(),
      Ntx8cvSettingChange(),
      Ntx8cvSettingChange(),
      Ntx8cvSettingChange(),
    ],
    this.modeCapabilityEvidenced = false,
    this.modeRebootRequired = false,
    this.isRebooting = false,
    this.rebootMessage,
  });

  final Ntx8cvSettingChange channelGroup;
  final Ntx8cvSettingChange es5;
  final Ntx8cvSettingChange mode;

  /// One device-confirmed/pending state for each [Ntx8cvAudioChannel].
  final List<Ntx8cvSettingChange> audioChannels;

  /// True only after the current session read setting `0x1B` with a value in
  /// `0..2`. A timeout is absence of evidence, not proof of unsupported
  /// firmware.
  final bool modeCapabilityEvidenced;

  /// A confirmed mode change is stored but needs a reboot to take effect.
  final bool modeRebootRequired;

  /// True while the selected device is being rebooted and revalidated.
  final bool isRebooting;

  /// A failed reboot or post-reboot refresh explanation for the user.
  final String? rebootMessage;

  Ntx8cvChannelGroup? get confirmedChannelGroup =>
      channelGroup.confirmedValue == null
      ? null
      : Ntx8cvChannelGroup.fromValue(channelGroup.confirmedValue!);

  Ntx8cvChannelGroup? get attemptedChannelGroup =>
      channelGroup.attemptedValue == null
      ? null
      : Ntx8cvChannelGroup.fromValue(channelGroup.attemptedValue!);

  bool get isLoadingChannelGroup => channelGroup.isLoading;
  bool get isWritingChannelGroup => channelGroup.isWriting;
  String? get channelGroupMessage => channelGroup.message;
  bool get hasPendingChannelGroupChange => channelGroup.hasPendingChange;

  bool? get confirmedEs5Enabled => switch (es5.confirmedValue) {
    0 => false,
    1 => true,
    _ => null,
  };

  bool? get attemptedEs5Enabled => switch (es5.attemptedValue) {
    0 => false,
    1 => true,
    _ => null,
  };

  bool get isLoadingEs5 => es5.isLoading;
  bool get isWritingEs5 => es5.isWriting;
  String? get es5Message => es5.message;
  bool get hasPendingEs5Change => es5.hasPendingChange;

  Ntx8cvExpansionMode? get confirmedMode => mode.confirmedValue == null
      ? null
      : Ntx8cvExpansionMode.fromValue(mode.confirmedValue!);

  Ntx8cvExpansionMode? get attemptedMode => mode.attemptedValue == null
      ? null
      : Ntx8cvExpansionMode.fromValue(mode.attemptedValue!);

  bool get isLoadingMode => mode.isLoading;
  bool get isWritingMode => mode.isWriting;
  String? get modeMessage => mode.message;
  bool get hasPendingModeChange => mode.hasPendingChange;

  Ntx8cvSettingChange audioChannelChange(Ntx8cvAudioChannel channel) =>
      audioChannels[channel.index];

  bool? confirmedAudioChannelEnabled(Ntx8cvAudioChannel channel) =>
      _enabledValue(audioChannelChange(channel).confirmedValue);

  bool? attemptedAudioChannelEnabled(Ntx8cvAudioChannel channel) =>
      _enabledValue(audioChannelChange(channel).attemptedValue);

  bool isLoadingAudioChannel(Ntx8cvAudioChannel channel) =>
      audioChannelChange(channel).isLoading;

  bool isWritingAudioChannel(Ntx8cvAudioChannel channel) =>
      audioChannelChange(channel).isWriting;

  bool hasPendingAudioChannelChange(Ntx8cvAudioChannel channel) =>
      audioChannelChange(channel).hasPendingChange;

  bool get hasAudioChannelOperationInProgress =>
      audioChannels.any((change) => change.isLoading || change.isWriting);

  bool get isBusy =>
      isRebooting ||
      channelGroup.isLoading ||
      channelGroup.isWriting ||
      es5.isLoading ||
      es5.isWriting ||
      mode.isLoading ||
      mode.isWriting ||
      hasAudioChannelOperationInProgress;

  bool get hasSettingOperationInProgress =>
      channelGroup.isLoading ||
      channelGroup.isWriting ||
      es5.isLoading ||
      es5.isWriting ||
      mode.isLoading ||
      mode.isWriting ||
      hasAudioChannelOperationInProgress;

  Ntx8cvSettingsState copyWith({
    Ntx8cvSettingChange? channelGroup,
    Ntx8cvSettingChange? es5,
    Ntx8cvSettingChange? mode,
    List<Ntx8cvSettingChange>? audioChannels,
    bool? modeCapabilityEvidenced,
    bool? modeRebootRequired,
    bool? isRebooting,
    String? rebootMessage,
    bool clearRebootMessage = false,
  }) {
    return Ntx8cvSettingsState(
      channelGroup: channelGroup ?? this.channelGroup,
      es5: es5 ?? this.es5,
      mode: mode ?? this.mode,
      audioChannels: audioChannels ?? this.audioChannels,
      modeCapabilityEvidenced:
          modeCapabilityEvidenced ?? this.modeCapabilityEvidenced,
      modeRebootRequired: modeRebootRequired ?? this.modeRebootRequired,
      isRebooting: isRebooting ?? this.isRebooting,
      rebootMessage: clearRebootMessage
          ? null
          : rebootMessage ?? this.rebootMessage,
    );
  }

  Ntx8cvSettingChange changeFor(Ntx8cvSetting setting) => switch (setting) {
    Ntx8cvSetting.channelGroup => channelGroup,
    Ntx8cvSetting.es5Enabled => es5,
    Ntx8cvSetting.expansionMode => mode,
  };

  Ntx8cvSettingsState withAudioChannelChange(
    Ntx8cvAudioChannel channel,
    Ntx8cvSettingChange change,
  ) {
    final updatedChanges = List<Ntx8cvSettingChange>.of(audioChannels)
      ..[channel.index] = change;
    return copyWith(audioChannels: List.unmodifiable(updatedChanges));
  }

  Ntx8cvSettingsState withChange(
    Ntx8cvSetting setting,
    Ntx8cvSettingChange change, {
    bool? modeCapabilityEvidenced,
    bool? modeRebootRequired,
  }) => switch (setting) {
    Ntx8cvSetting.channelGroup => copyWith(
      channelGroup: change,
      modeCapabilityEvidenced: modeCapabilityEvidenced,
      modeRebootRequired: modeRebootRequired,
    ),
    Ntx8cvSetting.es5Enabled => copyWith(
      es5: change,
      modeCapabilityEvidenced: modeCapabilityEvidenced,
      modeRebootRequired: modeRebootRequired,
    ),
    Ntx8cvSetting.expansionMode => copyWith(
      mode: change,
      modeCapabilityEvidenced: modeCapabilityEvidenced,
      modeRebootRequired: modeRebootRequired,
    ),
  };

  static bool? _enabledValue(int? value) => switch (value) {
    0 => false,
    1 => true,
    _ => null,
  };
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
  Ntx8cvSession? _refreshSession;
  Future<void>? _refreshFuture;
  String? _targetKey;

  /// Changes Channel Group immediately, but commits it to presentation state
  /// only after a same-setting read returns the attempted value.
  Future<void> setChannelGroup(Ntx8cvChannelGroup group) =>
      _setSetting(Ntx8cvSetting.channelGroup, group.value);

  /// Changes ES-5 use immediately, but commits it to presentation state only
  /// after a same-setting read returns the attempted value.
  Future<void> setEs5Enabled(bool enabled) =>
      _setSetting(Ntx8cvSetting.es5Enabled, enabled ? 1 : 0);

  /// Changes the NT expansion mode immediately after a successful capability
  /// probe. The three [Ntx8cvExpansionMode] values map to protocol `0..2`.
  Future<void> setExpansionMode(Ntx8cvExpansionMode mode) =>
      _setSetting(Ntx8cvSetting.expansionMode, mode.value);

  /// Changes one supported audio channel only after the device-confirmed Mode
  /// establishes that audio channels apply to this selected NTX-8CV.
  Future<void> setAudioChannelEnabled(
    Ntx8cvAudioChannel channel,
    bool enabled,
  ) => _setAudioChannel(channel, enabled ? 1 : 0);

  /// Explicitly resends one retained, unconfirmed audio-channel change.
  /// Reconnecting or refreshing never invokes this automatically.
  Future<void> retryAudioChannelChange(Ntx8cvAudioChannel channel) =>
      _retryAudioChannel(channel);

  /// Reads the current device-confirmed settings without sending any writes.
  /// A retained pending change is deliberately not retried or overwritten.
  Future<void> refresh() async {
    final session = _currentSession;
    if (session == null || state.isBusy) return;
    await _refreshSettings(session);
  }

  /// Explicitly resends the retained, unconfirmed Channel Group change to the
  /// current identity-validated NTX-8CV. It never reconnects or retries on
  /// its own.
  Future<void> retryChannelGroupChange() =>
      _retrySetting(Ntx8cvSetting.channelGroup);

  /// Explicitly resends the retained, unconfirmed ES-5 change to the current
  /// identity-validated NTX-8CV. It never reconnects or retries on its own.
  Future<void> retryEs5Change() => _retrySetting(Ntx8cvSetting.es5Enabled);

  /// Explicitly resends the retained, unconfirmed Mode change to the current
  /// identity-validated NTX-8CV. Matching readback is still required.
  Future<void> retryModeChange() => _retrySetting(Ntx8cvSetting.expansionMode);

  /// Reboots the currently connected NTX-8CV once, then waits for its selected
  /// endpoint pair to be revalidated and all non-pending settings to refresh.
  /// No confirmation dialog or automatic resend is involved.
  Future<void> reboot() async {
    if (_currentSession == null || state.isBusy) return;

    emit(state.copyWith(isRebooting: true, clearRebootMessage: true));
    final reconnected = await _connectionCubit.rebootAndReconnect();
    if (isClosed) return;

    if (!reconnected) {
      emit(
        state.copyWith(
          isRebooting: false,
          rebootMessage:
              'Could not complete the NTX-8CV reboot and refresh. Check the '
              'selected MIDI endpoints and reconnect the device.',
        ),
      );
      return;
    }

    final session = await _waitForCurrentSession();
    if (session == null) {
      emit(
        state.copyWith(
          isRebooting: false,
          rebootMessage:
              'The NTX-8CV disconnected before its settings could refresh '
              'after reboot.',
        ),
      );
      return;
    }

    await _refreshFor(session);
    if (!_isActiveSession(session)) return;
    emit(
      state.copyWith(
        isRebooting: false,
        modeRebootRequired: false,
        clearRebootMessage: true,
      ),
    );
  }

  Future<void> _setSetting(Ntx8cvSetting setting, int value) async {
    final change = state.changeFor(setting);
    if (change.hasPendingChange ||
        change.confirmedValue == null ||
        change.confirmedValue == value ||
        state.isBusy ||
        (setting == Ntx8cvSetting.expansionMode &&
            !state.modeCapabilityEvidenced)) {
      return;
    }
    await _writeSetting(setting, value);
  }

  Future<void> _retrySetting(Ntx8cvSetting setting) async {
    final attemptedValue = state.changeFor(setting).attemptedValue;
    if (attemptedValue == null ||
        state.isBusy ||
        (setting == Ntx8cvSetting.expansionMode &&
            !state.modeCapabilityEvidenced)) {
      return;
    }
    await _writeSetting(setting, attemptedValue);
  }

  Future<void> _setAudioChannel(Ntx8cvAudioChannel channel, int value) async {
    final change = state.audioChannelChange(channel);
    if (!_audioChannelsApply ||
        change.hasPendingChange ||
        change.confirmedValue == null ||
        change.confirmedValue == value ||
        state.isBusy) {
      return;
    }
    await _writeAudioChannel(channel, value);
  }

  Future<void> _retryAudioChannel(Ntx8cvAudioChannel channel) async {
    final attemptedValue = state.audioChannelChange(channel).attemptedValue;
    if (!_audioChannelsApply || attemptedValue == null || state.isBusy) return;
    await _writeAudioChannel(channel, attemptedValue);
  }

  Future<void> _writeAudioChannel(Ntx8cvAudioChannel channel, int value) async {
    final session = _currentSession;
    if (session == null) return;

    emit(
      state.withAudioChannelChange(
        channel,
        state
            .audioChannelChange(channel)
            .copyWith(
              attemptedValue: value,
              isWriting: true,
              clearMessage: true,
            ),
      ),
    );
    try {
      await session.writeAndConfirmSetting(
        settingId: channel.settingId,
        value: value,
      );
      if (!_isActiveSession(session)) return;
      emit(
        state.withAudioChannelChange(
          channel,
          state
              .audioChannelChange(channel)
              .copyWith(
                confirmedValue: value,
                clearAttemptedValue: true,
                isWriting: false,
                clearMessage: true,
              ),
        ),
      );
    } catch (error) {
      if (!_isActiveSession(session)) return;
      emit(
        state.withAudioChannelChange(
          channel,
          state
              .audioChannelChange(channel)
              .copyWith(
                isWriting: false,
                message: _audioWriteFailureMessage(channel, error),
              ),
        ),
      );
    }
  }

  Future<void> _writeSetting(Ntx8cvSetting setting, int value) async {
    final session = _currentSession;
    if (session == null) return;

    emit(
      state.withChange(
        setting,
        state
            .changeFor(setting)
            .copyWith(
              attemptedValue: value,
              isWriting: true,
              clearMessage: true,
            ),
      ),
    );
    try {
      await session.writeAndConfirmSetting(settingId: setting.id, value: value);
      if (!_isActiveSession(session)) return;
      emit(
        state.withChange(
          setting,
          state
              .changeFor(setting)
              .copyWith(
                confirmedValue: value,
                clearAttemptedValue: true,
                isWriting: false,
                clearMessage: true,
              ),
          modeRebootRequired: setting == Ntx8cvSetting.expansionMode
              ? true
              : null,
        ),
      );
    } catch (_) {
      if (!_isActiveSession(session)) return;
      emit(
        state.withChange(
          setting,
          state
              .changeFor(setting)
              .copyWith(
                isWriting: false,
                message:
                    'The ${setting.label} change was not confirmed by device '
                    'readback. The actual device state is uncertain.',
              ),
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
      if (!isClosed && state.hasSettingOperationInProgress) {
        emit(_stateForInterruptedConnection());
      }
      return;
    }
    if (identical(session, _activeSession)) return;

    _activeSession = session;
    // A prior probe applies to the old session. Reads below must evidence the
    // mode capability again before this session permits a Mode write or retry.
    emit(
      state.copyWith(
        modeCapabilityEvidenced: false,
        audioChannels: _audioChannelsForNewSession(),
      ),
    );
    unawaited(_refreshFor(session));
  }

  /// Clears confirmations that belong to a changed target while retaining an
  /// explicit attempted value for a user-directed retry on the new target.
  Ntx8cvSettingsState _stateForChangedTarget() {
    Ntx8cvSettingChange retainedChange(
      Ntx8cvSettingChange change,
      String label,
    ) {
      if (!change.hasPendingChange) return const Ntx8cvSettingChange();
      return Ntx8cvSettingChange(
        attemptedValue: change.attemptedValue,
        message:
            'The NTX-8CV target changed before the $label change could be '
            'confirmed. The actual device state is uncertain. Retry send will '
            'use the current selected connection and device ID.',
      );
    }

    return Ntx8cvSettingsState(
      channelGroup: retainedChange(state.channelGroup, 'Channel Group'),
      es5: retainedChange(state.es5, 'ES-5'),
      mode: retainedChange(state.mode, 'Mode'),
      audioChannels: List.unmodifiable([
        for (final channel in Ntx8cvAudioChannel.values)
          retainedChange(state.audioChannelChange(channel), channel.label),
      ]),
      rebootMessage: state.rebootMessage,
    );
  }

  Ntx8cvSettingsState _stateForInterruptedConnection() {
    Ntx8cvSettingChange interruptedChange(
      Ntx8cvSettingChange change,
      String label,
    ) {
      if (!change.isWriting && !change.isLoading) return change;
      final wasWriting = change.isWriting;
      return change.copyWith(
        isLoading: false,
        isWriting: false,
        message: wasWriting
            ? 'The NTX-8CV disconnected before the $label change could be '
                  'confirmed. The actual device state is uncertain.'
            : 'The NTX-8CV disconnected before the device-confirmed $label '
                  'value could be read.',
      );
    }

    return Ntx8cvSettingsState(
      channelGroup: interruptedChange(state.channelGroup, 'Channel Group'),
      es5: interruptedChange(state.es5, 'ES-5'),
      mode: interruptedChange(state.mode, 'NT expansion mode'),
      audioChannels: List.unmodifiable([
        for (final channel in Ntx8cvAudioChannel.values)
          interruptedChange(state.audioChannelChange(channel), channel.label),
      ]),
      modeRebootRequired: state.modeRebootRequired,
      isRebooting: state.isRebooting,
      rebootMessage: state.rebootMessage,
    );
  }

  Future<Ntx8cvSession?> _waitForCurrentSession() async {
    // Cubit stream listeners receive the revalidated connection state
    // asynchronously. Give that listener two event turns to bind the new
    // session and begin its shared refresh rather than starting a duplicate.
    for (var attempt = 0; attempt < 2; attempt++) {
      final session = _currentSession;
      if (session != null) return session;
      await Future<void>.delayed(Duration.zero);
    }
    return _currentSession;
  }

  Future<void> _refreshFor(Ntx8cvSession session) {
    if (identical(_refreshSession, session) && _refreshFuture != null) {
      return _refreshFuture!;
    }
    _refreshSession = session;
    final refresh = _refreshSettings(session);
    _refreshFuture = refresh;
    return refresh;
  }

  Future<void> _refreshSettings(Ntx8cvSession session) async {
    // Do not read an ES-5, audio-channel, or Channel Group setting whose
    // attempted value is pending: leaving that value untouched makes reconnect
    // a recovery step, never an implicit confirmation or resend. A Mode probe
    // is always safe and is required to enable a Mode retry for this newly
    // validated session.
    if (!state.es5.hasPendingChange) {
      await _readSetting(session, Ntx8cvSetting.es5Enabled);
    }
    if (!_isActiveSession(session)) return;
    await _readSetting(session, Ntx8cvSetting.expansionMode);
    if (!_isActiveSession(session)) return;
    for (final channel in Ntx8cvAudioChannel.values) {
      if (!state.hasPendingAudioChannelChange(channel)) {
        await _readAudioChannel(session, channel);
      }
      if (!_isActiveSession(session)) return;
    }
    if (!state.channelGroup.hasPendingChange) {
      await _readSetting(session, Ntx8cvSetting.channelGroup);
    }
  }

  Future<void> _readAudioChannel(
    Ntx8cvSession session,
    Ntx8cvAudioChannel channel,
  ) async {
    emit(
      state.withAudioChannelChange(
        channel,
        state
            .audioChannelChange(channel)
            .copyWith(isLoading: true, clearMessage: true),
      ),
    );
    try {
      final response = await session.readSetting(settingId: channel.settingId);
      if (!_isActiveSession(session)) return;
      if (response.value != 0 && response.value != 1) {
        throw StateError(
          '${channel.label} has invalid value ${response.value}.',
        );
      }
      emit(
        state.withAudioChannelChange(
          channel,
          state
              .audioChannelChange(channel)
              .copyWith(
                confirmedValue: response.value,
                isLoading: false,
                clearMessage: true,
              ),
        ),
      );
    } catch (error) {
      if (!_isActiveSession(session)) return;
      emit(
        state.withAudioChannelChange(
          channel,
          state
              .audioChannelChange(channel)
              .copyWith(
                isLoading: false,
                message: _audioReadFailureMessage(channel, error),
              ),
        ),
      );
    }
  }

  Future<void> _readSetting(
    Ntx8cvSession session,
    Ntx8cvSetting setting,
  ) async {
    emit(
      state.withChange(
        setting,
        state.changeFor(setting).copyWith(isLoading: true, clearMessage: true),
        modeCapabilityEvidenced: setting == Ntx8cvSetting.expansionMode
            ? false
            : null,
      ),
    );
    try {
      final response = await session.readSetting(settingId: setting.id);
      if (!_isActiveSession(session)) return;
      if (!_isValidValue(setting, response.value)) {
        throw StateError(
          '${setting.label} setting has invalid value ${response.value}.',
        );
      }
      emit(
        state.withChange(
          setting,
          state
              .changeFor(setting)
              .copyWith(
                confirmedValue: response.value,
                isLoading: false,
                clearMessage: true,
              ),
          modeCapabilityEvidenced: setting == Ntx8cvSetting.expansionMode
              ? true
              : null,
        ),
      );
    } catch (_) {
      if (!_isActiveSession(session)) return;
      emit(
        state.withChange(
          setting,
          state
              .changeFor(setting)
              .copyWith(
                isLoading: false,
                message: switch (setting) {
                  Ntx8cvSetting.expansionMode =>
                    'Mode capability was not evidenced. The NTX-8CV did not '
                        'return a valid Mode setting value.',
                  Ntx8cvSetting.channelGroup =>
                    'Could not read the device-confirmed Channel Group setting. '
                        'Check the NTX-8CV connection and reconnect to try again.',
                  Ntx8cvSetting.es5Enabled =>
                    'Could not read the device-confirmed ES-5 setting. Check '
                        'the NTX-8CV connection and reconnect to try again.',
                },
              ),
          modeCapabilityEvidenced: setting == Ntx8cvSetting.expansionMode
              ? false
              : null,
        ),
      );
    }
  }

  bool _isValidValue(Ntx8cvSetting setting, int value) => switch (setting) {
    Ntx8cvSetting.channelGroup => Ntx8cvChannelGroup.fromValue(value) != null,
    Ntx8cvSetting.es5Enabled => value == 0 || value == 1,
    Ntx8cvSetting.expansionMode => Ntx8cvExpansionMode.fromValue(value) != null,
  };

  String _audioWriteFailureMessage(Ntx8cvAudioChannel channel, Object error) {
    final reason = switch (error) {
      Ntx8cvTimeoutException() => 'timed out waiting for device readback',
      Ntx8cvMalformedResponseException() =>
        'received a malformed device response',
      StateError() => 'received mismatched device readback',
      _ => 'was not confirmed by device readback',
    };
    return 'The ${channel.label} change $reason. The actual device state is '
        'uncertain.';
  }

  String _audioReadFailureMessage(Ntx8cvAudioChannel channel, Object error) {
    final reason = switch (error) {
      Ntx8cvTimeoutException() => 'timed out',
      Ntx8cvMalformedResponseException() => 'received a malformed response',
      _ => 'failed',
    };
    return 'Could not read the device-confirmed ${channel.label} setting: '
        '$reason. Check the NTX-8CV connection and reconnect to try again.';
  }

  bool get _audioChannelsApply =>
      !state.modeRebootRequired &&
      switch (state.confirmedMode) {
        Ntx8cvExpansionMode.audio1x8_32bit ||
        Ntx8cvExpansionMode.audio2x8_16bit => true,
        _ => false,
      };

  List<Ntx8cvSettingChange> _audioChannelsForNewSession() => List.unmodifiable([
    for (final channel in Ntx8cvAudioChannel.values)
      state.hasPendingAudioChannelChange(channel)
          ? state
                .audioChannelChange(channel)
                .copyWith(clearConfirmedValue: true)
          : const Ntx8cvSettingChange(),
  ]);

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
