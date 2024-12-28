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
  late final StreamSubscription? _subscription;

  @override
  Future<void> close() {
    // TODO: implement close
    _subscription?.cancel();
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
      disting.startListening();
      _subscription = disting.decodedMessages.listen(
        (event) {
          if (this.state is! DistingStateSynchronized) return;

          final state = this.state as DistingStateSynchronized;

          switch (event.key.messageType) {
            case DistingNTRespMessageType.respNumAlgorithms:
              fetchAlgorithmInfo(event.value);
              break;
            case DistingNTRespMessageType.respAlgorithmInfo:
              emit(state.copyWith(
                  algorithms: replaceOrExtend(state.algorithms, event.value,
                      index: event.key.algorithmIndex!, filler: AlgorithmInfo.filler())));
              break;
            case DistingNTRespMessageType.respMessage:
              emit(state.copyWith(distingVersion: event.value));
              break;
            case DistingNTRespMessageType.respScreenshot:
              // TODO: Handle this case.
              throw UnimplementedError();
            case DistingNTRespMessageType.respAlgorithmGuid:
              emit(state.copyWith(
                  slots: updateSlot(event.key.algorithmIndex!, state.slots,
                      (slot) => slot.copyWith(algorithmGuid: event.value))));
              break;
            case DistingNTRespMessageType.respPresetName:
              emit(state.copyWith(patchName: event.value));
              break;
            case DistingNTRespMessageType.respNumParameters:
              fetchParameterInfos(event.key.algorithmIndex!,
                  (event.value as NumParameters).numParameters);
              break;
            case DistingNTRespMessageType.respParameterInfo:
              emit(state.copyWith(
                  slots: updateSlot(
                      event.key.algorithmIndex!,
                      state.slots,
                      (slot) => slot.copyWith(
                              parameters: replaceOrExtend(
                            slot.parameters,
                            event.value,
                            index: event.key.parameterNumber!,
                            filler: ParameterInfo.filler(),
                          )))));
              break;
            case DistingNTRespMessageType.respAllParameterValues:
              throw UnimplementedError();
            case DistingNTRespMessageType.respParameterValue:
              emit(state.copyWith(
                  slots: updateSlot(
                      event.key.algorithmIndex!,
                      state.slots,
                      (slot) => slot.copyWith(
                              values: replaceOrExtend(
                            slot.values,
                            event.value,
                            index: event.key.parameterNumber!,
                            filler: ParameterValue.filler(),
                          )))));
              break;
            case DistingNTRespMessageType.respUnitStrings:
              emit(state.copyWith(unitStrings: event.value));
              break;
            case DistingNTRespMessageType.respEnumStrings:
              emit(state.copyWith(
                  slots: updateSlot(
                      event.key.algorithmIndex!,
                      state.slots,
                      (slot) => slot.copyWith(
                          enums: replaceOrExtend(slot.enums, event.value,
                              index: event.key.parameterNumber!,
                              filler: ParameterEnumStrings.filler())))));
              break;
            case DistingNTRespMessageType.respMapping:
              emit(state.copyWith(
                  slots: updateSlot(
                      event.key.algorithmIndex!,
                      state.slots,
                      (slot) => slot.copyWith(
                              mappings: replaceOrExtend(
                            slot.mappings,
                            event.value,
                            index: event.key.parameterNumber!,
                            filler: Mapping.filler(),
                          )))));
              break;
            case DistingNTRespMessageType.respParameterValueString:
              emit(state.copyWith(
                  slots: updateSlot(
                      event.key.algorithmIndex!,
                      state.slots,
                      (slot) => slot.copyWith(
                              valueStrings: replaceOrExtend(
                            slot.valueStrings,
                            event.value,
                            index: event.key.parameterNumber!,
                            filler: ParameterValueString.filler(),
                          )))));
              break;
            case DistingNTRespMessageType.respNumAlgorithmsInPreset:
              var numAlgorithmsInPreset = event.value;
              emit(state.copyWith(
                  slots: List.generate(
                      numAlgorithmsInPreset,
                      (index) => Slot(
                            algorithmGuid: AlgorithmGuid(
                                algorithmIndex: index, guid: "guid"),
                            parameters: [],
                            values: [],
                            enums: [],
                            mappings: [],
                            valueStrings: [],
                          ))));
              fetchSlots(numAlgorithmsInPreset);
              break;
            case DistingNTRespMessageType.respRouting:
              emit(state.copyWith(
                  slots: updateSlot(
                      event.key.algorithmIndex!,
                      state.slots,
                          (slot) => slot.copyWith(
                          valueStrings: replaceOrExtend(
                            slot.valueStrings,
                            event.value,
                            index: event.key.parameterNumber!,
                            filler: ParameterValueString.filler(),
                          )))));
              break;
            case DistingNTRespMessageType.unknown:
              throw UnimplementedError();
          }
        },
      );

      // Transition to the connected state
      emit(DistingState.connected(
        midiCommand: state.midiCommand,
        device: device,
        sysExId: sysExId,
        disting: disting,
      ));
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

      // Begin to synchronize with the device
      fetchDistingVersion(connectedState.device);
      fetchPresetName(connectedState.device);
      fetchAlgorithms();

      // Transition to the synchronizing state
      emit(DistingState.synchronized(
        midiCommand: connectedState.midiCommand,
        device: connectedState.device,
        sysExId: connectedState.sysExId,
        disting: connectedState.disting,
        distingVersion: "",
        patchName: "",
        algorithms: [],
        slots: [],
        unitStrings: [],
      ));
    } catch (e) {
      // Handle error state if necessary
    }
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

  void fetchDistingVersion(MidiDevice device) async {
    requireDisting().requestVersionString();
  }

  void fetchPresetName(MidiDevice device) async {
    requireDisting().requestPresetName();
  }

  void fetchAlgorithms() async {
    final disting = requireDisting();
    disting.requestNumberOfAlgorithms();
    disting.requestNumAlgorithmsInPreset();
    disting.requestUnitStrings();
  }

  void fetchAlgorithmInfo(int numAlgorithms) {
    final disting = requireDisting();
    for (int i = 0; i < numAlgorithms; i++) {
      disting.requestAlgorithmInfo(i);
    }
  }

  void fetchSlots(int numAlgorithmsInPreset) {
    for (int i = 0; i < numAlgorithmsInPreset; i++) {
      fetchSlot(i);
    }
  }

  void fetchSlot(int algorithmIndex) {
    final disting = requireDisting();
    disting.requestNumberOfParameters(algorithmIndex);
    disting.requestAlgorithmGuid(algorithmIndex);
  }

  void fetchUnitStrings() async {
    final disting = requireDisting();
    disting.requestUnitStrings();
  }

  void fetchParameterInfos(int algorithmIndex, int numberOfParameters) {
    final disting = requireDisting();
    for (int parameterNumber = 0;
    parameterNumber < numberOfParameters;
    parameterNumber++) {
      disting.requestParameterInfo(algorithmIndex, parameterNumber);
      disting.requestParameterValue(algorithmIndex, parameterNumber);
      disting.requestParameterValueString(algorithmIndex, parameterNumber);
      disting.requestParameterEnumStrings(algorithmIndex, parameterNumber);
    }
  }

  List<T> replaceOrExtend<T>(
      List<T> original,
      T element, {
        required int index,
        required T filler,
      }) {
    if (index < 0) {
      throw RangeError.index(index, original, "index cannot be negative");
    }

    // Create a copy of the original list
    List<T> result = List<T>.from(original);

    // Extend the list if needed
    if (index >= result.length) {
      result.addAll(List<T>.generate(index - result.length + 1, (_) => filler));
    }

    // Replace the element at the given index
    result[index] = element;

    return result;
  }

  // List<T> insertInto<T>(
  //     List<T> original,
  //     T element, {
  //       required int index,
  //       required T filler,
  //     }) {
  //   // Validate the index
  //   if (index < 0) {
  //     throw RangeError.index(index, original, "index cannot be negative");
  //   }
  //
  //   // Create a copy of the original list
  //   List<T> extendedList = List<T>.from(original);
  //
  //   // Extend the list if needed
  //   if (index >= extendedList.length) {
  //     extendedList.addAll(
  //       List<T>.generate(index - extendedList.length, (_) => filler),
  //     );
  //   }
  //
  //   // Insert the element
  //   extendedList.insert(index, element);
  //
  //   return extendedList;
  // }

  @override
  void onChange(Change<DistingState> change) {
    print(
        "_____________________________________________________________________");
    print(change);
    print(
        "_____________________________________________________________________");
    super.onChange(change);
  }

  List<Slot> updateSlot(int algorithmIndex, List<Slot> slots,
      Slot Function(Slot) updateFunction) {
    return [
      ...slots.sublist(0, algorithmIndex),
      updateFunction(slots[algorithmIndex]),
      ...slots.sublist(algorithmIndex + 1),
    ];
  }
}
