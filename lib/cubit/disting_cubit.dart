import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutter_midi_command/flutter_midi_command.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:nt_helper/domain/disting_midi_manager.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'disting_cubit.freezed.dart';
part 'disting_state.dart';

class DistingCubit extends Cubit<DistingState> {
  DistingCubit()
      : _prefs = SharedPreferences.getInstance(),
        super(DistingState.initial(midiCommand: MidiCommand()));

  final Future<SharedPreferences> _prefs;

  @override
  Future<void> close() {
    disting()?.dispose();
    return super.close();
  }

  Future<void> initialize() async {
    final prefs = await _prefs;
    final savedDeviceName = prefs.getString('selectedMidiDevice');
    final savedSysExId = prefs.getInt('selectedSysExId');

    if (savedDeviceName != null && savedSysExId != null) {
      // Try to connect to the saved device
      final devices = await state.midiCommand.devices;
      final MidiDevice? savedDevice = devices
          ?.where((device) => device.name == savedDeviceName)
          .firstOrNull;

      if (savedDevice != null) {
        await connectToDevice(savedDevice, savedSysExId);
      } else {
        emit(DistingState.selectDevice(
          midiCommand: state.midiCommand,
          devices: devices!,
        ));
      }
    } else {
      // Load devices if no saved settings are found
      loadDevices();
    }
  }

  Future<void> loadDevices() async {
    try {
      // Transition to a loading state if needed
      emit(DistingState.initial(midiCommand: state.midiCommand));

      // Fetch available MIDI devices asynchronously
      final devices = await state.midiCommand.devices;

      // Transition to the select device state
      emit(DistingState.selectDevice(
        midiCommand: state.midiCommand,
        devices: devices!,
      ));
    } catch (e) {
      // Handle error state if necessary
    }
  }

  Future<void> connectToDevice(MidiDevice device, int sysExId) async {
    try {
      // Connect to the selected device
      await state.midiCommand.connectToDevice(device);

      // Save the device name and SysEx ID to persistent storage
      final prefs = await _prefs;
      await prefs.setString('selectedMidiDevice', device.name);
      await prefs.setInt('selectedSysExId', sysExId);

      final disting = DistingMidiManager(
          midiCommand: state.midiCommand, device: device, sysExId: sysExId);

      // Transition to the connected state
      emit(DistingState.connected(
        midiCommand: state.midiCommand,
        device: device,
        sysExId: sysExId,
        disting: disting,
      ));
      synchronizeDevice();
    } catch (e) {
      // Handle error state if necessary
    }
  }

  Future<void> synchronizeDevice() async {
    try {
      if (state is! DistingStateConnected) {
        throw Exception("Device is not connected.");
      }

      final connectedState = state as DistingStateConnected;

      final disting = requireDisting();

      final numAlgorithms = (await disting.requestNumberOfAlgorithms())!;
      final algorithms = [
        for (int i = 0; i < numAlgorithms; i++)
          (await disting.requestAlgorithmInfo(i))!
      ];
      final numAlgorithmsInPreset =
          (await disting.requestNumAlgorithmsInPreset())!;
      final distingVersion = await disting.requestVersionString() ?? "";
      final presetName = await disting.requestPresetName() ?? "";

      List<Slot> slots = await fetchSlots(numAlgorithmsInPreset, disting);

      // Transition to the synchronizing state
      emit(DistingState.synchronized(
        midiCommand: connectedState.midiCommand,
        device: connectedState.device,
        sysExId: connectedState.sysExId,
        disting: connectedState.disting,
        distingVersion: distingVersion,
        patchName: presetName,
        algorithms: algorithms,
        slots: slots,
        unitStrings: await disting.requestUnitStrings() ?? [],
      ));
    } catch (e) {
      // Handle error state if necessary
    }
  }

  Future<List<Slot>> fetchSlots(
      int numAlgorithmsInPreset, DistingMidiManager disting) async {
    final slotsFutures =
        List.generate(numAlgorithmsInPreset, (algorithmIndex) async {
      int numParametersInAlgorithm =
          (await disting.requestNumberOfParameters(algorithmIndex))!
              .numParameters;
      return Slot(
        algorithmGuid: (await disting.requestAlgorithmGuid(algorithmIndex))!,
        parameters: [
          for (int parameterNumber = 0;
              parameterNumber < numParametersInAlgorithm;
              parameterNumber++)
            await disting.requestParameterInfo(
                    algorithmIndex, parameterNumber) ??
                ParameterInfo.filler()
        ],
        values:
            (await disting.requestAllParameterValues(algorithmIndex))!.values,
        enums: [
          for (int parameterNumber = 0;
              parameterNumber < numParametersInAlgorithm;
              parameterNumber++)
            await disting.requestParameterEnumStrings(
                    algorithmIndex, parameterNumber) ??
                ParameterEnumStrings.filler()
        ],
        mappings: [
          for (int parameterNumber = 0;
              parameterNumber < numParametersInAlgorithm;
              parameterNumber++)
            await disting.requestMappings(algorithmIndex, parameterNumber) ??
                Mapping.filler()
        ],
        valueStrings: [
          for (int parameterNumber = 0;
              parameterNumber < numParametersInAlgorithm;
              parameterNumber++)
            await disting.requestParameterValueString(
                    algorithmIndex, parameterNumber) ??
                ParameterValueString.filler()
        ],
      );
    });

    // Finish off the requests
    final slots = await Future.wait(slotsFutures);
    return slots;
  }

  DistingMidiManager requireDisting() {
    if (state is DistingStateConnected) {
      return (state as DistingStateConnected).disting;
    }
    if (state is DistingStateSynchronized) {
      return (state as DistingStateSynchronized).disting;
    }
    throw Exception("Device is not connected.");
  }

  DistingMidiManager? disting() {
    if (state is DistingStateConnected) {
      return (state as DistingStateConnected).disting;
    }
    if (state is DistingStateSynchronized) {
      return (state as DistingStateSynchronized).disting;
    }
    return null;
  }

  List<T> replaceInList<T>(
    List<T> original,
    T element, {
    required int index,
  }) {
    if (index < 0 || index > original.length) {
      throw RangeError.index(index, original, "index out of bounds");
    }

    return [
      ...original.sublist(0, index),
      element,
      ...original.sublist(index + 1)
    ];
  }

  List<Slot> updateSlot(int algorithmIndex, List<Slot> slots,
      Slot Function(Slot) updateFunction) {
    return [
      ...slots.sublist(0, algorithmIndex),
      updateFunction(slots[algorithmIndex]),
      ...slots.sublist(algorithmIndex + 1),
    ];
  }

  void updateParameterValue({
    required int algorithmIndex,
    required int parameterNumber,
    required int value,
    required bool userIsChangingTheValue,
  }) async {
    if (state is DistingStateSynchronized) {
      var disting = requireDisting();
      disting.setParameterValue(
        algorithmIndex,
        parameterNumber,
        value,
      );

      if (!userIsChangingTheValue) {
        final newValue = await disting.requestParameterValue(
          algorithmIndex,
          parameterNumber,
        );
        final newValueString = await disting.requestParameterValueString(
          algorithmIndex,
          parameterNumber,
        );

        final state = (this.state as DistingStateSynchronized);

        emit(state.copyWith(
          slots: updateSlot(
            algorithmIndex,
            state.slots,
            (slot) {
              return slot.copyWith(
                  values: replaceInList(
                    slot.values,
                    newValue!,
                    index: parameterNumber,
                  ),
                  valueStrings: replaceInList(
                    slot.valueStrings,
                    newValueString ?? ParameterValueString.filler(),
                    index: parameterNumber,
                  ));
            },
          ),
        ));
      }
    }
  }

  void refresh() async {
    if (state is DistingStateSynchronized) {
      var disting = requireDisting();
      final numAlgorithmsInPreset =
          (await disting.requestNumAlgorithmsInPreset())!;

      emit((state as DistingStateSynchronized).copyWith(
        slots: await fetchSlots(numAlgorithmsInPreset, disting),
      ));
    }
  }

  void onAlgorithmSelected(
      AlgorithmInfo algorithm, List<int> specifications) async {
    if (state is DistingStateSynchronized) {
      final disting = requireDisting();
      disting.requestAddAlgorithm(algorithm, specifications);

      // Sleep for 50ms
      await Future.delayed(Duration(milliseconds: 50));

      refresh();
    }
  }

  void onRemoveAlgorithm(int algorithmIndex) async {
    if (state is DistingStateSynchronized) {
      final disting = requireDisting();
      disting.requestRemoveAlgorithm(algorithmIndex);

      // Sleep for 50ms
      await Future.delayed(Duration(milliseconds: 50));
      refresh();
    }
  }

  void onFocusParameter(
      {required int algorithmIndex, required int parameterNumber}) {
    final disting = requireDisting();
    disting.requestSetFocus(algorithmIndex, parameterNumber);
  }

  void renamePreset(String newName) async {
    if (state is DistingStateSynchronized) {
      final disting = requireDisting();
      disting.requestSetPresetName(newName);

      await Future.delayed(Duration(milliseconds: 250));
      emit((state as DistingStateSynchronized)
          .copyWith(patchName: await disting.requestPresetName() ?? ""));
    }
  }

  void save() async {
    final disting = requireDisting();
    disting.requestSavePreset();
  }

  void moveAlgorithmUp(int algorithmIndex) async {
    final disting = requireDisting();
    disting.requestMoveAlgorithmUp(algorithmIndex);
    await Future.delayed(Duration(milliseconds: 50));

    refresh();
  }

  void moveAlgorithmDown(int algorithmIndex) async {
    final disting = requireDisting();
    disting.requestMoveAlgorithmDown(algorithmIndex);
    await Future.delayed(Duration(milliseconds: 50));

    refresh();
  }

  void wakeDevice() async {
    final disting = requireDisting();
    disting.requestWake();
  }
}
