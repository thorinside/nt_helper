import 'dart:async';
import 'dart:typed_data';

import 'package:bloc/bloc.dart';
import 'package:flutter_midi_command/flutter_midi_command.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:nt_helper/domain/disting_midi_manager.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'package:nt_helper/models/packed_mapping_data.dart';
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

      devices?.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );

      // Transition to the select device state
      emit(DistingState.selectDevice(
        midiCommand: state.midiCommand,
        devices: devices!,
      ));
    } catch (e) {
      // Handle error state if necessary
    }
  }

  Future<void> updateScreenshot() async {
    final disting = requireDisting();
    await disting.requestWake();
    final screenshot = await disting.encodeTakeScreenshot();
    switch (state) {
      case DistingStateSynchronized syncstate:
        emit(syncstate.copyWith(screenshot: screenshot));
        break;
      default:
      // Handle other cases or errors
    }
  }

  Future<void> disconnect() async {
    if (state is DistingStateSynchronized) {
      final device = (state as DistingStateSynchronized).device;
      state.midiCommand.disconnectDevice(device);
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

  Future<void> cancelSync() async {
    await disconnect();
    loadDevices();
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
      var unitStrings = await disting.requestUnitStrings() ?? [];

      List<Slot> slots = await fetchSlots(numAlgorithmsInPreset, disting);

      // Transition to the synchronizing state
      emit(DistingState.synchronized(
        midiCommand: connectedState.midiCommand,
        device: connectedState.device,
        sysExId: connectedState.sysExId,
        disting: connectedState.disting,
        distingVersion: distingVersion,
        presetName: presetName,
        algorithms: algorithms,
        slots: slots,
        unitStrings: unitStrings,
      ));
    } catch (e) {
      // Handle error state if necessary
    }
  }

  Future<List<Slot>> fetchSlots(
      int numAlgorithmsInPreset, DistingMidiManager disting) async {
    final slotsFutures =
        List.generate(numAlgorithmsInPreset, (algorithmIndex) async {
      return await fetchSlot(disting, algorithmIndex);
    });

    // Finish off the requests
    final slots = await Future.wait(slotsFutures);
    return slots;
  }

  Future<Slot> fetchSlot(DistingMidiManager disting, int algorithmIndex) async {
    int numParametersInAlgorithm =
        (await disting.requestNumberOfParameters(algorithmIndex))!
            .numParameters;
    var parameters = [
      for (int parameterNumber = 0;
          parameterNumber < numParametersInAlgorithm;
          parameterNumber++)
        await disting.requestParameterInfo(algorithmIndex, parameterNumber) ??
            ParameterInfo.filler()
    ];
    var parameterValues =
        (await disting.requestAllParameterValues(algorithmIndex))!.values;
    var enums = [
      for (int parameterNumber = 0;
          parameterNumber < numParametersInAlgorithm;
          parameterNumber++)
        if (parameters[parameterNumber].unit == 1)
          await disting.requestParameterEnumStrings(
                  algorithmIndex, parameterNumber) ??
              ParameterEnumStrings.filler()
        else
          ParameterEnumStrings.filler()
    ];
    var mappings = [
      for (int parameterNumber = 0;
          parameterNumber < numParametersInAlgorithm;
          parameterNumber++)
        await disting.requestMappings(algorithmIndex, parameterNumber) ??
            Mapping.filler()
    ];
    var valueStrings = [
      for (int parameterNumber = 0;
          parameterNumber < numParametersInAlgorithm;
          parameterNumber++)
        if ([13, 14, 17].contains(parameters[parameterNumber].unit))
          await disting.requestParameterValueString(
                  algorithmIndex, parameterNumber) ??
              ParameterValueString.filler()
        else
          ParameterValueString.filler()
    ];
    return Slot(
      algorithmGuid: (await disting.requestAlgorithmGuid(algorithmIndex))!,
      parameters: parameters,
      values: parameterValues,
      enums: enums,
      mappings: mappings,
      valueStrings: valueStrings,
    );
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
      final state = (this.state as DistingStateSynchronized);

      disting.setParameterValue(
        algorithmIndex,
        parameterNumber,
        value,
      );

      // Special case for switching programs in 3pot algorithms
      if (_isThreePotProgram(state, algorithmIndex, parameterNumber)) {
        final updatedSlot = await fetchSlot(disting, algorithmIndex);

        emit(state.copyWith(
          slots: updateSlot(
            algorithmIndex,
            state.slots,
            (slot) {
              return updatedSlot;
            },
          ),
        ));
        return;
      }

      if (!userIsChangingTheValue) {
        final newValue = await disting.requestParameterValue(
          algorithmIndex,
          parameterNumber,
        );

        final state = (this.state as DistingStateSynchronized);

        var valueStrings = [
          for (int parameterNumber = 0;
              parameterNumber < state.slots[algorithmIndex].valueStrings.length;
              parameterNumber++)
            if ([13, 14, 17].contains(
                state.slots[algorithmIndex].parameters[parameterNumber].unit))
              await disting.requestParameterValueString(
                      algorithmIndex, parameterNumber) ??
                  ParameterValueString.filler()
            else
              ParameterValueString.filler()
        ];

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
                  valueStrings: valueStrings);
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

      final presetName = await disting.requestPresetName() ?? "";

      emit((state as DistingStateSynchronized).copyWith(
        presetName: presetName,
        slots: await fetchSlots(numAlgorithmsInPreset, disting),
      ));
    }
  }

  Future<void> onAlgorithmSelected(
      AlgorithmInfo algorithm, List<int> specifications) async {
    if (state is DistingStateSynchronized) {
      final disting = requireDisting();
      await disting.requestAddAlgorithm(algorithm, specifications);

      await Future.delayed(Duration(milliseconds: 100));

      // Add a slot at the end of the slots list, and then ask to update that
      // slot. The rest should remain the same, so we don't have to update
      // everything.
      var slots = List<Slot>.from((state as DistingStateSynchronized).slots);
      slots.add(await fetchSlot(disting, slots.length));
      emit((state as DistingStateSynchronized).copyWith(slots: slots));
    }
  }

  Future<void> onRemoveAlgorithm(int algorithmIndex) async {
    if (state is DistingStateSynchronized) {
      final disting = requireDisting();
      await disting.requestRemoveAlgorithm(algorithmIndex);

      // Just remove the slot from state since the message
      // succeeded, filter the slot out of the list, the index in the list
      // will be the same as algorithmIndex
      // Emit the new state with the updated slots
      var slots = List<Slot>.from((state as DistingStateSynchronized).slots);
      slots.removeAt(algorithmIndex);
      emit((state as DistingStateSynchronized).copyWith(slots: slots));

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
          .copyWith(presetName: await disting.requestPresetName() ?? ""));
    }
  }

  void save() async {
    final disting = requireDisting();
    disting.requestSavePreset();
  }

  Future<int> moveAlgorithmUp(int algorithmIndex) async {
    if (algorithmIndex == 0) return 0;

    final disting = requireDisting();
    await disting.requestMoveAlgorithmUp(algorithmIndex);
    await Future.delayed(Duration(milliseconds: 50));

    var slots = List<Slot>.from((state as DistingStateSynchronized).slots);
    var slot = slots.removeAt(algorithmIndex);
    slots.insert(algorithmIndex - 1, slot);
    emit((state as DistingStateSynchronized).copyWith(slots: slots));

    refresh();

    return algorithmIndex - 1;
  }

  Future<int> moveAlgorithmDown(int algorithmIndex) async {
    final disting = requireDisting();
    await disting.requestMoveAlgorithmDown(algorithmIndex);
    await Future.delayed(Duration(milliseconds: 50));

    var slots = List<Slot>.from((state as DistingStateSynchronized).slots);

    // If we are not on the last slot, move the slot to the next space in the list
    if (algorithmIndex == slots.length) return algorithmIndex;

    var slot = slots.removeAt(algorithmIndex);
    slots.insert(algorithmIndex + 1, slot);
    emit((state as DistingStateSynchronized).copyWith(slots: slots));

    refresh();

    return algorithmIndex + 1;
  }

  void wakeDevice() async {
    final disting = requireDisting();
    disting.requestWake();
  }

  void closeScreenshot() {
    switch (state) {
      case DistingStateSynchronized syncstate:
        emit(syncstate.copyWith(screenshot: null));
        break;
      default:
      // Handle other cases or errors
    }
  }

  Future<void> newPreset() async {
    switch (state) {
      case DistingStateSynchronized syncstate:
        final disting = requireDisting();

        await disting.requestNewPreset();

        await Future.delayed(Duration(milliseconds: 100));

        final numAlgorithmsInPreset =
            (await disting.requestNumAlgorithmsInPreset())!;
        final presetName = await disting.requestPresetName() ?? "";

        List<Slot> slots = await fetchSlots(numAlgorithmsInPreset, disting);

        // Transition to the synchronizing state
        emit(
          syncstate.copyWith(
            presetName: presetName,
            slots: slots,
          ),
        );

        break;
      default:
      // Handle other cases or errors
    }
  }

  Future<void> loadPreset(String name, bool append) async {
    switch (state) {
      case DistingStateSynchronized syncstate:
        final disting = requireDisting();

        await disting.requestLoadPreset(name, append);

        await Future.delayed(Duration(milliseconds: 100));

        final numAlgorithmsInPreset =
            (await disting.requestNumAlgorithmsInPreset())!;
        final presetName = await disting.requestPresetName() ?? "";

        List<Slot> slots = await fetchSlots(numAlgorithmsInPreset, disting);

        emit(
          syncstate.copyWith(
            presetName: presetName,
            slots: slots,
          ),
        );

        break;
      default:
      // Handle other cases or errors
    }
  }

  Future<void> saveMapping(
      int algorithmIndex, int parameterNumber, PackedMappingData data) async {
    switch (state) {
      case DistingStateSynchronized syncstate:
        final disting = requireDisting();

        await disting.requestSetMapping(algorithmIndex, parameterNumber, data);

        await Future.delayed(Duration(milliseconds: 100));

        emit(
          syncstate.copyWith(
            slots: updateSlot(
              algorithmIndex,
              syncstate.slots,
              (slot) {
                return slot.copyWith(
                  mappings: replaceInList(
                    slot.mappings,
                    Mapping(
                        algorithmIndex: algorithmIndex,
                        parameterNumber: parameterNumber,
                        packedMappingData: data,
                        version: 1),
                    index: parameterNumber,
                  ),
                );
              },
            ),
          ),
        );
        break;
      default:
      // Handle other cases or errors
    }
  }

  bool _isThreePotProgram(DistingStateSynchronized state, int algorithmIndex,
          int parameterNumber) =>
      (state.slots[algorithmIndex].parameters[parameterNumber].name ==
          "Program") &&
      ("spin" == state.slots[algorithmIndex].algorithmGuid.guid);
}
