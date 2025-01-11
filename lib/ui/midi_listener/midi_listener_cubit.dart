import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutter_midi_command/flutter_midi_command.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:nt_helper/util/extensions.dart';

part 'midi_listener_cubit.freezed.dart';
part 'midi_listener_state.dart';

class MidiListenerCubit extends Cubit<MidiListenerState> {
  final MidiCommand _midiCommand = MidiCommand();
  StreamSubscription<MidiPacket>? _midiSubscription;

  static const int kThreshold = 10;
  int _lastCC = -1;
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
              .takeWhile(
                (value) => !value.name.toLowerCase().contains('disting'),
              )
              .toList(),
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
    state.maybeMap(
        data: (d) =>
            d.selectedDevice.let((it) => _midiCommand.disconnectDevice(it)),
        orElse: () {});

    // Connect
    await _midiCommand.connectToDevice(device);

    // Listen for events
    _midiSubscription =
        _midiCommand.onMidiDataReceived?.listen(_handleMidiData);

    // Update the state with selected device & isConnected
    state.maybeMap(
      data: (dataState) {
        emit(
          dataState.copyWith(
            selectedDevice: device,
            isConnected: true,
          ),
        );
      },
      orElse: () {
        // If it wasn't in the data state, just create one
        emit(
          MidiListenerState.data(
            devices: [device],
            selectedDevice: device,
            isConnected: true,
          ),
        );
      },
    );
  }

  void _handleMidiData(MidiPacket packet) {
    final data = packet.data; // e.g. [0xB0 + channel, CC, value]
    if (data.isNotEmpty && (data[0] & 0xF0) == 0xB0 && data.length > 2) {
      final channel = data[0] & 0x0F; // 0..15
      final ccNumber = data[1];

      // Check consecutive hits
      if (ccNumber == _lastCC) {
        _consecutiveCount++;
      } else {
        _lastCC = ccNumber;
        _consecutiveCount = 1;
      }

      // Update lastDetectedCc and lastDetectedChannel in the state
      state.maybeMap(
        data: (dataState) {
          emit(
            dataState.copyWith(
              lastDetectedCc: ccNumber,
              lastDetectedChannel: channel,
              lastDetectedTime: DateTime.timestamp(),
            ),
          );
        },
        orElse: () {},
      );

      // If we reached kThreshold
      if (_consecutiveCount >= kThreshold) {
        // e.g. do something special or emit an event
        // For instance: "Found repeated CC on the same channel"
        // This is optional logic.
      }
    }
  }

  @override
  Future<void> close() async {
    await _midiSubscription?.cancel();
    return super.close();
  }
}
