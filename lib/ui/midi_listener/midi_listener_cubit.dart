import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutter_midi_command/flutter_midi_command.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'midi_listener_cubit.freezed.dart';
part 'midi_listener_state.dart';

class MidiListenerCubit extends Cubit<MidiListenerState> {
  final MidiCommand _midiCommand = MidiCommand();
  StreamSubscription<MidiPacket>? _midiSubscription;

  static const int kThreshold = 10;
  // Keep track of the last full event signature to detect consecutive identical events
  ({MidiEventType type, int channel, int number})? _lastEventSignature;
  int _consecutiveCount = 0;

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

    // Reset consecutive count and signature
    _consecutiveCount = 0;
    _lastEventSignature = null;
  }

  void _handleMidiData(MidiPacket packet) {
    final data = packet.data;
    // Basic validation: need at least 3 bytes for most channel messages
    if (data.isEmpty || data.length < 3) return;

    final statusByte = data[0];
    final messageType = statusByte & 0xF0; // 0x90, 0x80, 0xB0 etc.
    final channel = statusByte & 0x0F; // 0-15

    // --- Declare variables to hold detected info ---
    MidiEventType? detectedType;
    int? detectedCc;
    int? detectedNote;
    int? detectedNumber; // Generic number (CC or Note) for signature

    // --- Parse the message ---
    // CC Message (0xB0)
    if (messageType == 0xB0) {
      detectedType = MidiEventType.cc;
      detectedCc = data[1]; // CC number
      detectedNumber = detectedCc;
      //
    }
    // Note On Message (0x90)
    else if (messageType == 0x90) {
      int note = data[1];
      int velocity = data[2];
      // Treat Note On with velocity 0 as Note Off
      detectedType = (velocity == 0)
          ? MidiEventType.noteOff
          : MidiEventType.noteOn;
      detectedNote = note;
      detectedNumber = detectedNote;
      //
    }
    // Note Off Message (0x80)
    else if (messageType == 0x80) {
      detectedType = MidiEventType.noteOff;
      detectedNote = data[1]; // Note number
      // data[2] is velocity, which we ignore for detection logic
      detectedNumber = detectedNote;
      //
    }

    // --- Process if a relevant message was detected ---
    if (detectedType != null && detectedNumber != null) {
      final currentEventSignature = (
        type: detectedType,
        channel: channel,
        number: detectedNumber,
      );

      // Check consecutive hits
      if (currentEventSignature == _lastEventSignature) {
        _consecutiveCount++;
      } else {
        _lastEventSignature = currentEventSignature;
        _consecutiveCount = 1;
      }

      // Determine if the threshold is met for this event type
      // Note: Notes always meet threshold >= 1
      final bool thresholdMet =
          (detectedType == MidiEventType.cc &&
              _consecutiveCount >= kThreshold) ||
          (detectedType != MidiEventType.cc /* i.e., Note On/Off */ );

      // Update the state
      final currentState = state;
      if (currentState is Data) {
        // --- Debug Print Start ---
        // --- Debug Print End ---

        // Set fields only if threshold is met, otherwise null
        final nextState = currentState.copyWith(
          lastDetectedType: thresholdMet ? detectedType : null,
          lastDetectedChannel: thresholdMet ? channel : null,
          lastDetectedCc: thresholdMet ? detectedCc : null,
          lastDetectedNote: thresholdMet ? detectedNote : null,
          lastDetectedTime: DateTime.timestamp(),
        );

        // --- Debug Print Start ---
        if (thresholdMet) {
        } else {}
        // --- Debug Print End ---

        emit(nextState);

        // Reset count and signature ONLY if the threshold was met
        if (thresholdMet) {
          _consecutiveCount = 0;
          _lastEventSignature = null;
        }
      } else {}
    } else {
      // Optionally log ignored message types
      //
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
