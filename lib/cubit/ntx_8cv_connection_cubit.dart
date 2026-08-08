import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutter_midi_command/flutter_midi_command.dart';
import 'package:nt_helper/domain/ntx_8cv/ntx_8cv_midi_connection.dart';
import 'package:nt_helper/domain/ntx_8cv/ntx_8cv_sysex.dart';

/// The connection phases shown by the independent NTX-8CV add-on.
enum Ntx8cvConnectionStatus { disconnected, connecting, connected, failed }

extension on Ntx8cvConnectionStatus {
  String get label => switch (this) {
    Ntx8cvConnectionStatus.disconnected => 'Disconnected',
    Ntx8cvConnectionStatus.connecting => 'Connecting',
    Ntx8cvConnectionStatus.connected => 'Connected',
    Ntx8cvConnectionStatus.failed => 'Failed',
  };
}

/// Immutable presentation state for the NTX-8CV endpoint connection.
class Ntx8cvConnectionState {
  const Ntx8cvConnectionState({
    this.inputDevices = const [],
    this.outputDevices = const [],
    this.selectedInputDevice,
    this.selectedOutputDevice,
    this.deviceId = 0,
    this.deviceIdText = '0',
    this.deviceIdError,
    this.status = Ntx8cvConnectionStatus.disconnected,
    this.statusMessage,
    this.deviceInformation,
    this.isLoadingEndpoints = true,
    this.isReacquiringAfterReboot = false,
  });

  final List<Ntx8cvMidiEndpoint> inputDevices;
  final List<Ntx8cvMidiEndpoint> outputDevices;
  final Ntx8cvMidiEndpoint? selectedInputDevice;
  final Ntx8cvMidiEndpoint? selectedOutputDevice;
  final int deviceId;
  final String deviceIdText;
  final String? deviceIdError;
  final Ntx8cvConnectionStatus status;
  final String? statusMessage;
  final Ntx8cvDeviceInformation? deviceInformation;
  final bool isLoadingEndpoints;
  final bool isReacquiringAfterReboot;

  bool get isConnected => status == Ntx8cvConnectionStatus.connected;
  bool get isConnecting => status == Ntx8cvConnectionStatus.connecting;
  bool get isBusy => isConnecting || isReacquiringAfterReboot;
  bool get canConnect =>
      !isLoadingEndpoints &&
      !isConnecting &&
      selectedInputDevice != null &&
      selectedOutputDevice != null &&
      deviceIdError == null;

  String get statusLabel =>
      isReacquiringAfterReboot ? 'Reconnecting' : status.label;

  Ntx8cvConnectionState copyWith({
    List<Ntx8cvMidiEndpoint>? inputDevices,
    List<Ntx8cvMidiEndpoint>? outputDevices,
    Ntx8cvMidiEndpoint? selectedInputDevice,
    bool clearSelectedInputDevice = false,
    Ntx8cvMidiEndpoint? selectedOutputDevice,
    bool clearSelectedOutputDevice = false,
    int? deviceId,
    String? deviceIdText,
    String? deviceIdError,
    bool clearDeviceIdError = false,
    Ntx8cvConnectionStatus? status,
    String? statusMessage,
    bool clearStatusMessage = false,
    Ntx8cvDeviceInformation? deviceInformation,
    bool clearDeviceInformation = false,
    bool? isLoadingEndpoints,
    bool? isReacquiringAfterReboot,
  }) {
    return Ntx8cvConnectionState(
      inputDevices: inputDevices ?? this.inputDevices,
      outputDevices: outputDevices ?? this.outputDevices,
      selectedInputDevice: clearSelectedInputDevice
          ? null
          : selectedInputDevice ?? this.selectedInputDevice,
      selectedOutputDevice: clearSelectedOutputDevice
          ? null
          : selectedOutputDevice ?? this.selectedOutputDevice,
      deviceId: deviceId ?? this.deviceId,
      deviceIdText: deviceIdText ?? this.deviceIdText,
      deviceIdError: clearDeviceIdError
          ? null
          : deviceIdError ?? this.deviceIdError,
      status: status ?? this.status,
      statusMessage: clearStatusMessage
          ? null
          : statusMessage ?? this.statusMessage,
      deviceInformation: clearDeviceInformation
          ? null
          : deviceInformation ?? this.deviceInformation,
      isLoadingEndpoints: isLoadingEndpoints ?? this.isLoadingEndpoints,
      isReacquiringAfterReboot:
          isReacquiringAfterReboot ?? this.isReacquiringAfterReboot,
    );
  }
}

/// Owns NTX-8CV endpoint discovery, identity validation, and connection state.
///
/// It is intentionally independent from [DistingCubit]. It opens only the
/// selected NTX-8CV endpoints and creates a session scoped to their selected
/// SysEx device ID.
class Ntx8cvConnectionCubit extends Cubit<Ntx8cvConnectionState> {
  Ntx8cvConnectionCubit({
    Ntx8cvMidiConnection? midiConnection,
    Ntx8cvConnectionStore? store,
    this.sessionTimeout = const Duration(seconds: 1),
    this.rebootReconnectDelay = const Duration(seconds: 1),
    this.rebootReconnectPollInterval = const Duration(milliseconds: 500),
    this.rebootReconnectTimeout = const Duration(seconds: 15),
  }) : _midiConnection = midiConnection ?? NativeNtx8cvMidiConnection(),
       _store = store ?? SharedPreferencesNtx8cvConnectionStore(),
       super(const Ntx8cvConnectionState());

  final Ntx8cvMidiConnection _midiConnection;
  final Ntx8cvConnectionStore _store;
  final Duration sessionTimeout;

  /// Waits briefly for the selected device to restart before its endpoints are
  /// reacquired. It is configurable so fixture-based tests do not need a
  /// physical NTX-8CV reboot delay.
  final Duration rebootReconnectDelay;

  /// How often endpoint discovery and identity validation are retried while a
  /// rebooted NTX-8CV is returning.
  final Duration rebootReconnectPollInterval;

  /// Maximum time spent reacquiring and revalidating the selected NTX-8CV
  /// after the one reboot command has been sent.
  final Duration rebootReconnectTimeout;
  StreamSubscription<MidiSetupChange>? _setupSubscription;
  Ntx8cvMidiTransport? _transport;
  Ntx8cvSession? _session;
  Ntx8cvMidiEndpoint? _activeInputDevice;
  Ntx8cvMidiEndpoint? _activeOutputDevice;
  String? _desiredInputDeviceName;
  String? _desiredInputDeviceId;
  String? _desiredOutputDeviceName;
  String? _desiredOutputDeviceId;
  bool _initialized = false;

  /// The session for the currently identity-validated NTX-8CV, if any.
  ///
  /// Later settings operations can only use this session while [state] is
  /// connected, keeping all commands scoped to the selected endpoints and ID.
  Ntx8cvSession? get session => state.isConnected ? _session : null;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    try {
      final saved = await _store.load();
      _desiredInputDeviceName = saved.inputDeviceName;
      _desiredInputDeviceId = saved.inputDeviceId;
      _desiredOutputDeviceName = saved.outputDeviceName;
      _desiredOutputDeviceId = saved.outputDeviceId;
      emit(
        state.copyWith(
          deviceId: saved.deviceId,
          deviceIdText: '${saved.deviceId}',
          clearDeviceIdError: true,
        ),
      );
      _setupSubscription = _midiConnection.setupChanges?.listen((_) {
        unawaited(refreshEndpoints());
      });
      await refreshEndpoints();
    } catch (_) {
      emit(
        state.copyWith(
          status: Ntx8cvConnectionStatus.failed,
          statusMessage:
              'Could not load NTX-8CV MIDI endpoints. Refresh and try again.',
          isLoadingEndpoints: false,
          clearDeviceInformation: true,
        ),
      );
    }
  }

  /// Refreshes the available input and output endpoint lists.
  Future<void> refreshEndpoints() async {
    try {
      final devices = await _midiConnection.listDevices();
      final inputDevices = devices.where((device) => device.hasInput).toList()
        ..sort(_compareDevices);
      final outputDevices = devices.where((device) => device.hasOutput).toList()
        ..sort(_compareDevices);

      var inputDevice = _resolveSavedDevice(
        inputDevices,
        deviceId: _desiredInputDeviceId,
        deviceName: _desiredInputDeviceName,
      );
      var outputDevice = _resolveSavedDevice(
        outputDevices,
        deviceId: _desiredOutputDeviceId,
        deviceName: _desiredOutputDeviceName,
      );

      if (inputDevice == null &&
          outputDevice == null &&
          _hasNoSavedEndpointPreference) {
        final automaticInput = _singleNtx8cvEndpoint(inputDevices);
        final automaticOutput = _singleNtx8cvEndpoint(outputDevices);
        if (automaticInput != null && automaticOutput != null) {
          inputDevice = automaticInput;
          outputDevice = automaticOutput;
          _rememberInputDevice(inputDevice);
          _rememberOutputDevice(outputDevice);
          unawaited(_persistSelection());
        }
      }

      final activeTargetIsMissing =
          _transport != null && (inputDevice == null || outputDevice == null);
      if (activeTargetIsMissing) {
        await _closeActiveConnection();
      }

      emit(
        state.copyWith(
          inputDevices: List.unmodifiable(inputDevices),
          outputDevices: List.unmodifiable(outputDevices),
          selectedInputDevice: inputDevice,
          clearSelectedInputDevice: inputDevice == null,
          selectedOutputDevice: outputDevice,
          clearSelectedOutputDevice: outputDevice == null,
          status: activeTargetIsMissing
              ? Ntx8cvConnectionStatus.disconnected
              : state.status,
          statusMessage: activeTargetIsMissing
              ? 'The selected NTX-8CV was disconnected. Reconnect it to retry.'
              : null,
          clearStatusMessage:
              !activeTargetIsMissing &&
              state.status != Ntx8cvConnectionStatus.failed,
          clearDeviceInformation: activeTargetIsMissing,
          isLoadingEndpoints: false,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: Ntx8cvConnectionStatus.failed,
          statusMessage: 'Could not refresh NTX-8CV MIDI endpoints.',
          isLoadingEndpoints: false,
          clearDeviceInformation: true,
        ),
      );
    }
  }

  Future<void> selectInputDevice(Ntx8cvMidiEndpoint? device) async {
    if (_sameDevice(state.selectedInputDevice, device)) return;
    await _disconnectForTargetChange();
    if (device == null) {
      _desiredInputDeviceName = null;
      _desiredInputDeviceId = null;
    } else {
      _rememberInputDevice(device);
    }
    emit(
      state.copyWith(
        selectedInputDevice: device,
        clearSelectedInputDevice: device == null,
        status: Ntx8cvConnectionStatus.disconnected,
        clearStatusMessage: true,
        clearDeviceInformation: true,
      ),
    );
    await _persistSelection();
  }

  Future<void> selectOutputDevice(Ntx8cvMidiEndpoint? device) async {
    if (_sameDevice(state.selectedOutputDevice, device)) return;
    await _disconnectForTargetChange();
    if (device == null) {
      _desiredOutputDeviceName = null;
      _desiredOutputDeviceId = null;
    } else {
      _rememberOutputDevice(device);
    }
    emit(
      state.copyWith(
        selectedOutputDevice: device,
        clearSelectedOutputDevice: device == null,
        status: Ntx8cvConnectionStatus.disconnected,
        clearStatusMessage: true,
        clearDeviceInformation: true,
      ),
    );
    await _persistSelection();
  }

  /// Updates the persistent device ID only for decimal values from 0 through
  /// 126. Address 127 is never saved because it is transient Any addressing.
  Future<void> setDeviceIdText(String text) async {
    final value = int.tryParse(text);
    if (value == null || value < 0 || value > 126) {
      emit(
        state.copyWith(
          deviceIdText: text,
          deviceIdError: 'Enter a decimal device ID from 0 to 126.',
        ),
      );
      return;
    }

    if (value != state.deviceId) {
      await _disconnectForTargetChange();
    }
    emit(
      state.copyWith(
        deviceId: value,
        deviceIdText: text,
        clearDeviceIdError: true,
        status: value == state.deviceId
            ? state.status
            : Ntx8cvConnectionStatus.disconnected,
        clearStatusMessage: value != state.deviceId,
        clearDeviceInformation: value != state.deviceId,
      ),
    );
    await _persistSelection();
  }

  /// Opens the selected endpoints and accepts a connection only after a
  /// complete NTX-8CV device-information response validates its identity.
  Future<void> connect() async {
    if (!_initialized) await initialize();
    if (!state.canConnect) return;

    final inputDevice = state.selectedInputDevice!;
    final outputDevice = state.selectedOutputDevice!;
    final deviceId = state.deviceId;
    await _closeActiveConnection();
    emit(
      state.copyWith(
        status: Ntx8cvConnectionStatus.connecting,
        clearStatusMessage: true,
        clearDeviceInformation: true,
      ),
    );

    try {
      final transport = await _midiConnection.open(
        inputDevice: inputDevice,
        outputDevice: outputDevice,
      );
      _transport = transport;
      _activeInputDevice = inputDevice;
      _activeOutputDevice = outputDevice;
      final session = Ntx8cvSession(
        transport: transport,
        deviceId: deviceId,
        timeout: sessionTimeout,
      );
      _session = session;
      final deviceInformation = await session.requestDeviceInformation();
      if (!identical(_transport, transport)) return;
      emit(
        state.copyWith(
          status: Ntx8cvConnectionStatus.connected,
          deviceInformation: deviceInformation,
          clearStatusMessage: true,
          isReacquiringAfterReboot: false,
        ),
      );
    } catch (error) {
      final stillConnecting = state.isConnecting;
      await _closeActiveConnection();
      if (!isClosed && stillConnecting) {
        emit(
          state.copyWith(
            status: Ntx8cvConnectionStatus.failed,
            statusMessage: _connectionFailureMessage(error),
            clearDeviceInformation: true,
          ),
        );
      }
    }
  }

  /// Reboots only the current identity-validated NTX-8CV, then reacquires its
  /// selected endpoints and validates a fresh device-information response.
  ///
  /// The protocol has no reboot acknowledgement. A `true` result means the
  /// command was sent and the selected target subsequently reconnected and
  /// passed identity validation. This never sends the reboot command again.
  Future<bool> rebootAndReconnect() async {
    final session = _session;
    if (!state.isConnected || session == null) return false;

    emit(
      state.copyWith(
        status: Ntx8cvConnectionStatus.connecting,
        statusMessage: 'Rebooting the selected NTX-8CV, then reconnecting.',
        clearDeviceInformation: true,
        isReacquiringAfterReboot: true,
      ),
    );

    try {
      await session.reboot();
    } catch (_) {
      await _closeActiveConnection();
      if (!isClosed) {
        emit(
          state.copyWith(
            status: Ntx8cvConnectionStatus.failed,
            statusMessage:
                'Could not send the reboot command to the selected NTX-8CV.',
            clearDeviceInformation: true,
            isReacquiringAfterReboot: false,
          ),
        );
      }
      return false;
    }

    // The command is scoped to the session that was created for the selected
    // endpoint pair and device ID. Do not continue if another action replaced
    // that session while the send was in flight.
    if (!identical(_session, session)) {
      if (!isClosed) {
        emit(state.copyWith(isReacquiringAfterReboot: false));
      }
      return false;
    }

    await _closeActiveConnection();
    if (isClosed) return false;
    emit(
      state.copyWith(
        status: Ntx8cvConnectionStatus.disconnected,
        statusMessage: 'Reacquiring the selected NTX-8CV after reboot.',
        clearDeviceInformation: true,
      ),
    );

    if (rebootReconnectDelay > Duration.zero) {
      await Future<void>.delayed(rebootReconnectDelay);
    }
    if (isClosed) return false;

    final stopwatch = Stopwatch()..start();
    while (!isClosed) {
      await refreshEndpoints();
      if (isClosed) return false;

      if (state.canConnect) {
        await connect();
        if (state.isConnected) return true;
      }

      if (stopwatch.elapsed >= rebootReconnectTimeout) break;
      emit(
        state.copyWith(
          status: Ntx8cvConnectionStatus.disconnected,
          statusMessage: 'Waiting for the NTX-8CV to return after reboot.',
          clearDeviceInformation: true,
        ),
      );

      final remaining = rebootReconnectTimeout - stopwatch.elapsed;
      final delay = rebootReconnectPollInterval < remaining
          ? rebootReconnectPollInterval
          : remaining;
      if (delay > Duration.zero) await Future<void>.delayed(delay);
    }

    if (!isClosed) {
      emit(
        state.copyWith(
          status: Ntx8cvConnectionStatus.failed,
          statusMessage:
              'NTX-8CV did not return after reboot. Check its MIDI connection.',
          clearDeviceInformation: true,
          isReacquiringAfterReboot: false,
        ),
      );
    }
    return false;
  }

  Future<void> disconnect() async {
    await _closeActiveConnection();
    if (!isClosed) {
      emit(
        state.copyWith(
          status: Ntx8cvConnectionStatus.disconnected,
          clearStatusMessage: true,
          clearDeviceInformation: true,
          isReacquiringAfterReboot: false,
        ),
      );
    }
  }

  @override
  Future<void> close() async {
    await _setupSubscription?.cancel();
    await _closeActiveConnection();
    return super.close();
  }

  bool get _hasNoSavedEndpointPreference =>
      _desiredInputDeviceName == null &&
      _desiredInputDeviceId == null &&
      _desiredOutputDeviceName == null &&
      _desiredOutputDeviceId == null;

  Future<void> _disconnectForTargetChange() async {
    if (_transport != null) await _closeActiveConnection();
  }

  Future<void> _closeActiveConnection() async {
    final session = _session;
    final transport = _transport;
    final inputDevice = _activeInputDevice;
    final outputDevice = _activeOutputDevice;
    _session = null;
    _transport = null;
    _activeInputDevice = null;
    _activeOutputDevice = null;

    await session?.close();
    if (transport != null && inputDevice != null && outputDevice != null) {
      try {
        await _midiConnection.close(
          transport: transport,
          inputDevice: inputDevice,
          outputDevice: outputDevice,
        );
      } catch (_) {
        // A missing USB device may fail to close natively; it is already
        // disconnected from this add-on's state.
      }
    }
  }

  Future<void> _persistSelection() async {
    try {
      await _store.save(
        Ntx8cvSavedConnection(
          inputDeviceName: _desiredInputDeviceName,
          inputDeviceId: _desiredInputDeviceId,
          outputDeviceName: _desiredOutputDeviceName,
          outputDeviceId: _desiredOutputDeviceId,
          deviceId: state.deviceId,
        ),
      );
    } catch (_) {
      // Persistence is best effort; connection and identity validation remain
      // local and do not depend on saved endpoint names.
    }
  }

  void _rememberInputDevice(Ntx8cvMidiEndpoint device) {
    _desiredInputDeviceName = device.name;
    _desiredInputDeviceId = device.id;
  }

  void _rememberOutputDevice(Ntx8cvMidiEndpoint device) {
    _desiredOutputDeviceName = device.name;
    _desiredOutputDeviceId = device.id;
  }

  static Ntx8cvMidiEndpoint? _resolveSavedDevice(
    List<Ntx8cvMidiEndpoint> devices, {
    required String? deviceId,
    required String? deviceName,
  }) {
    if (deviceId != null) {
      for (final device in devices) {
        if (device.id == deviceId) return device;
      }
    }
    if (deviceName == null) return null;
    final namedDevices = devices.where((device) => device.name == deviceName);
    return namedDevices.length == 1 ? namedDevices.single : null;
  }

  static Ntx8cvMidiEndpoint? _singleNtx8cvEndpoint(
    List<Ntx8cvMidiEndpoint> devices,
  ) {
    final matches = devices.where(
      (device) => device.name.trim().toLowerCase() == 'ntx-8cv',
    );
    return matches.length == 1 ? matches.single : null;
  }

  static bool _sameDevice(
    Ntx8cvMidiEndpoint? first,
    Ntx8cvMidiEndpoint? second,
  ) => first?.id == second?.id;

  static int _compareDevices(
    Ntx8cvMidiEndpoint first,
    Ntx8cvMidiEndpoint second,
  ) {
    final nameOrder = first.name.toLowerCase().compareTo(
      second.name.toLowerCase(),
    );
    return nameOrder != 0 ? nameOrder : first.id.compareTo(second.id);
  }

  static String _connectionFailureMessage(Object error) {
    if (error is Ntx8cvTimeoutException) {
      return 'The selected endpoint did not return valid NTX-8CV device information. Check the MIDI input, output, and device ID.';
    }
    return 'Could not connect to the selected NTX-8CV. Check the MIDI endpoints and try again.';
  }
}
