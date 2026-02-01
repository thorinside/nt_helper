import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutter_midi_command/flutter_midi_command.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'midi_detection_engine.dart';

part 'midi_listener_cubit.freezed.dart';
part 'midi_listener_state.dart';

class MidiListenerCubit extends Cubit<MidiListenerState> {
  final MidiCommand _midiCommand = MidiCommand();
  StreamSubscription<MidiPacket>? _midiSubscription;

  final MidiDetectionEngine _detectionEngine = MidiDetectionEngine();

  MidiListenerCubit() : super(const MidiListenerState.initial());

  Future<List<MidiDevice>?> discoverDevices() async {
    await _midiCommand.startBluetoothCentral();
    final devices = await _midiCommand.devices;

    if (devices != null) {
      // Emit a data state with the discovered devices
      emit(
        MidiListenerState.data(
          devices: devices
              .where(
                (value) => !value.name.toLowerCase().contains('disting'),
              )
              .toList()
            ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase())),
          isConnected: false,
        ),
      );
    }
    return devices;
  }

  Future<void> connectToDevice(MidiDevice device) async {
    // Cancel old subscription if needed
    await _midiSubscription?.cancel();

    // Disconnect old device as well
    final currentState = state;
    if (currentState is Data) {
      if (currentState.selectedDevice != null) {
        _midiCommand.disconnectDevice(currentState.selectedDevice!);
      }
    }

    // Connect
    await _midiCommand.connectToDevice(device);

    // Listen for events
    _midiSubscription = _midiCommand.onMidiDataReceived?.listen(
      _handleMidiData,
    );

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
    // Cancel subscription
    await _midiSubscription?.cancel();
    _midiSubscription = null;

    // Disconnect device
    final currentState = state;
    if (currentState is Data) {
      if (currentState.selectedDevice != null) {
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
    final data = packet.data;
    if (data.isEmpty || data.length < 3) return;

    final statusByte = data[0];
    final messageType = statusByte & 0xF0;
    final channel = statusByte & 0x0F;

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
