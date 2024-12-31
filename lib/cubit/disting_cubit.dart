import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutter_midi_command/flutter_midi_command.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:nt_helper/domain/disting_midi_manager.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'package:nt_helper/domain/request_key.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'disting_cubit.freezed.dart';
part 'disting_state.dart';

class DistingCubit extends Cubit<DistingState> {
  DistingCubit()
      : _prefs = SharedPreferences.getInstance(),
        super(DistingState.initial(midiCommand: MidiCommand()));

  final Future<SharedPreferences> _prefs;
  late final StreamSubscription? _subscription;
  int numAlgorithmsInPreset = -1;

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
              _handleNumAlgorithms(state, event);
              break;
            case DistingNTRespMessageType.respAlgorithmInfo:
              _handleAlgorithmInfo(state, event);
              break;
            case DistingNTRespMessageType.respMessage:
              _handleMessage(state, event);
              break;
            case DistingNTRespMessageType.respScreenshot:
              // TODO: Handle this case.
              throw UnimplementedError();
            case DistingNTRespMessageType.respAlgorithmGuid:
              _handleAlgorithmGuid(state, event);
              break;
            case DistingNTRespMessageType.respPresetName:
              _handlePresetName(state, event);
              break;
            case DistingNTRespMessageType.respNumParameters:
              _handleNumParameters(event, state);
              break;
            case DistingNTRespMessageType.respParameterInfo:
              _handleParameterInfo(state, event);
              break;
            case DistingNTRespMessageType.respAllParameterValues:
              throw UnimplementedError();
            case DistingNTRespMessageType.respParameterValue:
              _handleParameterValue(state, event);
              break;
            case DistingNTRespMessageType.respUnitStrings:
              _handleUnitStrings(state, event);
              break;
            case DistingNTRespMessageType.respEnumStrings:
              _handleEnumStrings(state, event);
              break;
            case DistingNTRespMessageType.respMapping:
              _handleMapping(state, event);
              break;
            case DistingNTRespMessageType.respParameterValueString:
              _handleParameterValueString(state, event);
              break;
            case DistingNTRespMessageType.respNumAlgorithmsInPreset:
              numAlgorithmsInPreset = event.value;
              _handleNumAlgorithmsInPreset(event, state);
              break;
            case DistingNTRespMessageType.respRouting:
              _handleParameterValueString(state, event);
              break;
            case DistingNTRespMessageType.unknown:
              throw UnimplementedError();
          }
        },
      );

      // // Transition to the connected state
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

  void _handleParameterValueString(
      DistingStateSynchronized state, MapEntry<RequestKey, dynamic> event) {
    emit(state.copyWith(
        slots: updateSlot(
            event.key.algorithmIndex!,
            state.slots,
            (slot) => slot.copyWith(
                    valueStrings: replaceInList(
                  slot.valueStrings,
                  event.value,
                  index: event.key.parameterNumber!,
                )))));
  }

  void _handleMapping(
      DistingStateSynchronized state, MapEntry<RequestKey, dynamic> event) {
    emit(state.copyWith(
        slots: updateSlot(
            event.key.algorithmIndex!,
            state.slots,
            (slot) => slot.copyWith(
                    mappings: replaceInList(
                  slot.mappings,
                  event.value,
                  index: event.key.parameterNumber!,
                )))));
  }

  void _handleEnumStrings(
      DistingStateSynchronized state, MapEntry<RequestKey, dynamic> event) {
    emit(state.copyWith(
        slots: updateSlot(
            event.key.algorithmIndex!,
            state.slots,
            (slot) => slot.copyWith(
                    enums: replaceInList(
                  slot.enums,
                  event.value,
                  index: event.key.parameterNumber!,
                )))));
  }

  void _handleUnitStrings(
      DistingStateSynchronized state, MapEntry<RequestKey, dynamic> event) {
    emit(state.copyWith(unitStrings: event.value));
  }

  void _handleParameterValue(
    DistingStateSynchronized state,
    MapEntry<RequestKey, dynamic> event,
  ) {
    emit(state.copyWith(
        slots: updateSlot(
            event.value.algorithmIndex!,
            state.slots,
            (slot) => slot.copyWith(
                    values: replaceInList(
                  slot.values,
                  event.value,
                  index: event.value.parameterNumber,
                )))));
  }

  void _handleParameterInfo(
      DistingStateSynchronized state, MapEntry<RequestKey, dynamic> event) {
    emit(state.copyWith(
        complete: state.complete ? true : event.key.algorithmIndex == (numAlgorithmsInPreset - 1),
        slots: updateSlot(
            event.key.algorithmIndex!,
            state.slots,
            (slot) => slot.copyWith(
                    parameters: replaceInList(
                  slot.parameters,
                  event.value,
                  index: event.key.parameterNumber!,
                )))));

    fetchParameterValue(event.key.algorithmIndex!, event.key.parameterNumber!);
    fetchParameterValueString(event.key.algorithmIndex!, event.key.parameterNumber!);
    fetchParameterEnumStrings(event.key.algorithmIndex!, event.key.parameterNumber!);
  }

  void _handleNumParameters(
      MapEntry<RequestKey, dynamic> event, DistingStateSynchronized state) {
    var numberOfParameters = (event.value as NumParameters).numParameters;

    emit(state.copyWith(
        slots: updateSlot(
            event.key.algorithmIndex!,
            state.slots,
            (slot) => slot.copyWith(
                parameters:
                    List.filled(numberOfParameters, ParameterInfo.filler()),
                values: List.filled(
                  numberOfParameters,
                  ParameterValue.filler(),
                ),
                valueStrings: List.filled(
                    numberOfParameters, ParameterValueString.filler()),
                mappings: List.filled(numberOfParameters, Mapping.filler()),
                enums: List.filled(
                  numberOfParameters,
                  ParameterEnumStrings.filler(),
                )))));

    fetchParameterInfos(event.key.algorithmIndex!, numberOfParameters);
  }

  void _handlePresetName(
      DistingStateSynchronized state, MapEntry<RequestKey, dynamic> event) {
    emit(state.copyWith(patchName: event.value));
  }

  void _handleAlgorithmGuid(
      DistingStateSynchronized state, MapEntry<RequestKey, dynamic> event) {
    emit(state.copyWith(
        slots: updateSlot(event.key.algorithmIndex!, state.slots,
            (slot) => slot.copyWith(algorithmGuid: event.value))));
  }

  void _handleMessage(
      DistingStateSynchronized state, MapEntry<RequestKey, dynamic> event) {
    emit(state.copyWith(distingVersion: event.value));
  }

  void _handleAlgorithmInfo(
      DistingStateSynchronized state, MapEntry<RequestKey, dynamic> event) {
    emit(state.copyWith(
        algorithms: replaceInList(
      state.algorithms,
      event.value,
      index: event.key.algorithmIndex!,
    )));
  }

  void _handleNumAlgorithms(
      DistingStateSynchronized state, MapEntry<RequestKey, dynamic> event) {
    emit(state.copyWith(
        algorithms: List.filled(event.value, AlgorithmInfo.filler())));
    fetchAlgorithmInfo(event.value);
  }

  void _handleNumAlgorithmsInPreset(
      MapEntry<RequestKey, dynamic> event, DistingStateSynchronized state) {
    var numAlgorithmsInPreset = event.value;
    emit(state.copyWith(
        slots: List.generate(
            numAlgorithmsInPreset,
            (index) => Slot(
                  algorithmGuid: AlgorithmGuid(algorithmIndex: index, guid: ""),
                  parameters: [],
                  values: [],
                  enums: [],
                  mappings: [],
                  valueStrings: [],
                ))));
    fetchSlots(numAlgorithmsInPreset);
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
    }
  }

  void fetchParameterValue(int algorithmIndex, int parameterNumber) {
    final disting = requireDisting();
    disting.requestParameterValue(algorithmIndex, parameterNumber);
  }

  void fetchParameterValueString(int algorithmIndex, int parameterNumber) {
    final disting = requireDisting();
    disting.requestParameterValueString(algorithmIndex, parameterNumber);
  }

  void fetchParameterEnumStrings(int algorithmIndex, int parameterNumber) {
    final disting = requireDisting();
    disting.requestParameterEnumStrings(algorithmIndex, parameterNumber);
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

  void updateParameterValue({required int algorithmIndex, required int parameterNumber, required int value}) {
    final disting = requireDisting();
    disting.setParameterValue(algorithmIndex, parameterNumber, value);
    disting.requestParameterValue(algorithmIndex, parameterNumber);
    disting.requestParameterValueString(algorithmIndex, parameterNumber);
  }

  @override
  void onChange(Change<DistingState> change) {
    super.onChange(change);
  }

  void wakeDevice() {
    final disting = requireDisting();
    disting.requestWake();
  }

  void refresh() {
    if (state is DistingStateSynchronized) {
      emit((state as DistingStateSynchronized).copyWith(complete: false));
    }
    fetchAlgorithms();
  }

  void onAddAlgorithm() {
    if (state is DistingStateSynchronized) {
      emit((state as DistingStateSynchronized).copyWith(selectAlgorithm: true));
    }
  }

  void onAlgorithmSelected(AlgorithmInfo algorithm, List<int> specifications) {
    if (state is DistingStateSynchronized) {
      emit((state as DistingStateSynchronized).copyWith(selectAlgorithm: false));

      final disting = requireDisting();
      disting.requestAddAlgorithm(algorithm, specifications);

      emit((state as DistingStateSynchronized).copyWith(complete: false));
      fetchAlgorithms();
    }
  }
}
