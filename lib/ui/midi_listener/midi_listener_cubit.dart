import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutter_midi_command/flutter_midi_command.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../services/debug_service.dart';
import 'midi_detection_engine.dart';

part 'midi_listener_cubit.freezed.dart';
part 'midi_listener_state.dart';

class MidiListenerCubit extends Cubit<MidiListenerState> {
  final MidiCommand _midiCommand = MidiCommand();
  final DebugService _debugService = DebugService();
  StreamSubscription<MidiPacket>? _midiSubscription;
  StreamSubscription<String>? _midiSetupSubscription;

  final MidiDetectionEngine _detectionEngine = MidiDetectionEngine();
  bool _isDetecting = false;

  MidiListenerCubit() : super(const MidiListenerState.initial());

  /// Enable detection processing. Call when a mapping editor opens.
  void startDetecting() {
    _isDetecting = true;
  }

  /// Disable detection processing. Call when a mapping editor closes.
  void stopDetecting() {
    _isDetecting = false;
    _detectionEngine.reset();
  }

  void _debugLog(String message) {
    _debugService.addLocalMessage('[MidiListener] $message');
  }

  Future<List<MidiDevice>?> discoverDevices() async {
    await _midiCommand.startBluetoothCentral();
    final devices = await _midiCommand.devices;

    if (devices != null) {
      final filtered = devices
          .where(
            (value) => !value.name.toLowerCase().contains('disting'),
          )
          .toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      _debugLog('Discovered ${filtered.length} devices: ${filtered.map((d) => d.name).join(', ')}');
      emit(
        MidiListenerState.data(
          devices: filtered,
          isConnected: false,
        ),
      );
    } else {
      _debugLog('Discovered devices: null');
    }
    _startMidiSetupListener();

    return devices;
  }

  void _startMidiSetupListener() {
    _midiSetupSubscription?.cancel();
    _midiSetupSubscription =
        _midiCommand.onMidiSetupChanged?.listen((_) => _refreshDevices());
    _debugLog('MIDI setup listener started');
  }

  Future<void> _refreshDevices() async {
    final devices = await _midiCommand.devices;
    if (devices == null) {
      _debugLog('Refresh devices: null');
      return;
    }

    final filtered = devices
        .where((d) => !d.name.toLowerCase().contains('disting'))
        .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    _debugLog('Refreshed devices: ${filtered.length} found (${filtered.map((d) => d.name).join(', ')})');

    final currentState = state;
    if (currentState is Data) {
      // Check if the currently-connected device disappeared
      final selected = currentState.selectedDevice;
      final deviceDisappeared = selected != null &&
          !filtered.any((d) => d.name == selected.name);

      if (deviceDisappeared) {
        _debugLog('Device disappeared: ${selected.name}, disconnecting');
        // Disconnect gracefully
        await _midiSubscription?.cancel();
        _midiSubscription = null;
        _midiCommand.disconnectDevice(selected);
        _detectionEngine.reset();
        emit(MidiListenerState.data(devices: filtered));
      } else {
        emit(currentState.copyWith(devices: filtered));
      }
    } else {
      emit(MidiListenerState.data(devices: filtered));
    }
  }

  Future<void> connectToDevice(MidiDevice device) async {
    _debugLog('Connecting to device: ${device.name}');
    // Cancel old subscription if needed
    await _midiSubscription?.cancel();

    // Disconnect old selected device if any
    final currentState = state;
    if (currentState is Data) {
      if (currentState.selectedDevice != null) {
        _midiCommand.disconnectDevice(currentState.selectedDevice!);
      }
    }

    // Disconnect the target device in case it's still connected from a
    // previous session (native side survives hot restart)
    _midiCommand.disconnectDevice(device);

    // Subscribe to the broadcast stream before connecting (stream already exists)
    final stream = _midiCommand.onMidiDataReceived;
    _debugLog('onMidiDataReceived stream: ${stream == null ? "NULL" : "available"}');
    _midiSubscription = stream?.listen(
      (packet) {
        _debugLog('RAW: ${packet.data.length} bytes from ${packet.device.name}');
        _handleMidiData(packet);
      },
      onError: (Object error, StackTrace stackTrace) {
        _debugLog('Stream error: $error');
      },
      onDone: () {
        _debugLog('Stream done (closed)');
      },
      cancelOnError: false,
    );
    _debugLog('Subscription: ${_midiSubscription == null ? "NULL" : "active"}');

    // Connect — awaiting is safe now that we disconnected first
    await _midiCommand.connectToDevice(device);
    _debugLog('connectToDevice completed for ${device.name}');

    // Update the state with selected device & isConnected
    if (currentState is Data) {
      emit(currentState.copyWith(selectedDevice: device, isConnected: true));
    } else {
      // If it wasn't in the data state, just create one
      emit(
        MidiListenerState.data(
          devices: [device],
          selectedDevice: device,
          isConnected: true,
        ),
      );
    }
  }

  Future<void> disconnectDevice() async {
    _debugLog('Disconnecting device');
    // Cancel subscription
    await _midiSubscription?.cancel();
    _midiSubscription = null;

    // Disconnect device
    final currentState = state;
    if (currentState is Data) {
      if (currentState.selectedDevice != null) {
        _debugLog('Disconnected from ${currentState.selectedDevice!.name}');
        _midiCommand.disconnectDevice(currentState.selectedDevice!);
      }
      // Update the state to show disconnected
      emit(
        currentState.copyWith(
          selectedDevice: null,
          isConnected: false,
          lastDetectedType: null,
          lastDetectedChannel: null,
          lastDetectedCc: null,
          lastDetectedNote: null,
          lastDetectedTime: null,
        ),
      );
    }

    // Reset detection engine
    _detectionEngine.reset();
  }

  void _handleMidiData(MidiPacket packet) {
    if (!_isDetecting) return;

    final data = packet.data;
    if (data.isEmpty || data.length < 3) {
      _debugLog('Short packet dropped: ${data.length} bytes from ${packet.device.name}');
      return;
    }

    final statusByte = data[0];
    final messageType = statusByte & 0xF0;
    final channel = statusByte & 0x0F;

    final typeLabel = switch (messageType) {
      0xB0 => 'CC',
      0x90 => 'NoteOn',
      0x80 => 'NoteOff',
      _ => '0x${messageType.toRadixString(16).toUpperCase()}',
    };
    _debugLog('Packet: status=0x${statusByte.toRadixString(16).toUpperCase()} '
        'type=$typeLabel ch=$channel data=[${data.skip(1).map((b) => b.toString()).join(', ')}]');

    DetectionResult? result;

    if (messageType == 0xB0) {
      // CC message
      result = _detectionEngine.processCc(channel, data[1], data[2]);
    } else if (messageType == 0x90) {
      // Note On (velocity 0 = Note Off)
      final note = data[1];
      final velocity = data[2];
      result = velocity == 0
          ? _detectionEngine.processNoteOff(channel, note)
          : _detectionEngine.processNoteOn(channel, note);
    } else if (messageType == 0x80) {
      // Note Off
      result = _detectionEngine.processNoteOff(channel, data[1]);
    }

    if (result != null) {
      _emitDetectionResult(result);
    } else if (messageType == 0xB0 || messageType == 0x90 || messageType == 0x80) {
      _debugLog('Sub-threshold activity: $typeLabel ch=$channel');
      // Sub-threshold: emit state update with null detection (preserves activity indication)
      final currentState = state;
      if (currentState is Data) {
        emit(currentState.copyWith(
          lastDetectedType: null,
          lastDetectedChannel: null,
          lastDetectedCc: null,
          lastDetectedNote: null,
          lastDetectedTime: DateTime.timestamp(),
        ));
      }
    }
  }

  void _emitDetectionResult(DetectionResult result) {
    _debugLog('Detected: type=${result.type.name} ch=${result.channel} number=${result.number}');
    final currentState = state;
    if (currentState is Data) {
      final isCcType = result.type == MidiEventType.cc ||
          result.type == MidiEventType.cc14BitLowFirst ||
          result.type == MidiEventType.cc14BitHighFirst;

      emit(currentState.copyWith(
        lastDetectedType: result.type,
        lastDetectedChannel: result.channel,
        lastDetectedCc: isCcType ? result.number : null,
        lastDetectedNote: !isCcType ? result.number : null,
        lastDetectedTime: DateTime.timestamp(),
      ));
    }
  }

  @override
  Future<void> close() async {
    await _midiSetupSubscription?.cancel();
    await _midiSubscription?.cancel();
    // Disconnect device if we are managing it locally (though this cubit might not know)
    final currentState = state;
    if (currentState is Data) {
      if (currentState.selectedDevice != null) {
        _midiCommand.disconnectDevice(currentState.selectedDevice!);
      }
    }
    return super.close();
  }
}
