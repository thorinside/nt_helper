import 'dart:async';

import 'package:async/async.dart';
import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_midi_command/flutter_midi_command.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:nt_helper/domain/disting_midi_manager.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'package:nt_helper/models/packed_mapping_data.dart';
import 'package:nt_helper/models/routing_information.dart';
import 'package:nt_helper/util/extensions.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'disting_cubit.freezed.dart';
part 'disting_state.dart';

// A helper class to track each parameter’s polling state.
class _PollingTask {
  bool active = true;
  int noChangeCount = 0;

  _PollingTask();
}

class DistingCubit extends Cubit<DistingState> {
  DistingCubit()
      : _prefs = SharedPreferences.getInstance(),
        super(DistingState.initial());

  final Future<SharedPreferences> _prefs;
  MidiCommand _midiCommand = MidiCommand();
  CancelableOperation<void>? _programSlotUpdate;

  @override
  Future<void> close() {
    disting()?.dispose();
    return super.close();
  }

  Future<void> initialize() async {
    final prefs = await _prefs;
    final savedInputDeviceName = prefs.getString('selectedInputMidiDevice');
    final savedOutputDeviceName = prefs.getString('selectedOutputMidiDevice');
    final savedSysExId = prefs.getInt('selectedSysExId');

    if (savedOutputDeviceName != null &&
        savedInputDeviceName != null &&
        savedSysExId != null) {
      // Try to connect to the saved device
      final devices = await _midiCommand.devices;
      final MidiDevice? savedInputDevice = devices
          ?.where((device) => device.name == savedInputDeviceName)
          .firstOrNull;

      final MidiDevice? savedOutputDevice = devices
          ?.where((device) => device.name == savedOutputDeviceName)
          .firstOrNull;

      if (savedInputDevice != null && savedOutputDevice != null) {
        await connectToDevices(
            savedInputDevice, savedOutputDevice, savedSysExId);
      } else {
        emit(DistingState.selectDevice(
          inputDevices:
              devices?.where((it) => it.inputPorts.isNotEmpty).toList() ?? [],
          outputDevices:
              devices?.where((it) => it.outputPorts.isNotEmpty).toList() ?? [],
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
      emit(DistingState.initial());

      // Fetch available MIDI devices asynchronously
      final devices = await _midiCommand.devices;

      devices?.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );

      // Transition to the select device state
      emit(DistingState.selectDevice(
        inputDevices:
            devices?.where((it) => it.inputPorts.isNotEmpty).toList() ?? [],
        outputDevices:
            devices?.where((it) => it.outputPorts.isNotEmpty).toList() ?? [],
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

  void disconnect() {
    switch (state) {
      case DistingStateConnected connectedState:
        connectedState.disting.dispose();
        break;
      case DistingStateSynchronized syncstate:
        syncstate.disting.dispose();
        break;
    }
    _midiCommand.dispose();
    _midiCommand = MidiCommand();
  }

  Future<void> connectToDevices(
      MidiDevice inputDevice, MidiDevice outputDevice, int sysExId) async {
    try {
      // Connect to the selected device
      await _midiCommand.connectToDevice(inputDevice);
      if (inputDevice != outputDevice) {
        await _midiCommand.connectToDevice(outputDevice);
      }

      // Save the device name and SysEx ID to persistent storage
      final prefs = await _prefs;
      await prefs.setString('selectedInputMidiDevice', inputDevice.name);
      await prefs.setString('selectedOutputMidiDevice', outputDevice.name);
      await prefs.setInt('selectedSysExId', sysExId);

      final disting = DistingMidiManager(
          midiCommand: _midiCommand,
          inputDevice: inputDevice,
          outputDevice: outputDevice,
          sysExId: sysExId);

      // Transition to the connected state
      emit(DistingState.connected(
        disting: disting,
      ));
      synchronizeDevice();
    } catch (e) {
      // Handle error state if necessary
      if (kDebugMode) {
        print("Error connecting: ${e.toString()}");
      }
      debugPrintStack();
    }
  }

  Future<void> cancelSync() async {
    disconnect();
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
    var routing = await disting.requestRoutingInformation(algorithmIndex) ??
        RoutingInfo.filler();
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
    var parameterPages = await disting.requestParameterPages(algorithmIndex) ??
        ParameterPages.filler();
    return Slot(
      algorithm: (await disting.requestAlgorithmGuid(algorithmIndex))!,
      pages: parameterPages,
      parameters: parameters,
      values: parameterValues,
      enums: enums,
      mappings: mappings,
      valueStrings: valueStrings,
      routing: routing,
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
    if (kDebugMode) {
      print("value = $value, userChanging = $userIsChangingTheValue");
    }

    switch (state) {
      case DistingStateSynchronized syncstate:
        var disting = requireDisting();

        disting.setParameterValue(
          algorithmIndex,
          parameterNumber,
          value,
        );

        if (!userIsChangingTheValue) {
          // Special case for switching programs
          if (_isProgramParameter(syncstate, algorithmIndex, parameterNumber)) {
            _programSlotUpdate?.cancel();

            _programSlotUpdate = CancelableOperation.fromFuture(Future.delayed(
              Duration(seconds: 2),
              () async {
                final updatedSlot = await fetchSlot(disting, algorithmIndex);

                emit(syncstate.copyWith(
                  slots: updateSlot(
                    algorithmIndex,
                    syncstate.slots,
                    (slot) {
                      return updatedSlot;
                    },
                  ),
                ));
              },
            ));
          }

          final newValue = await disting.requestParameterValue(
            algorithmIndex,
            parameterNumber,
          );

          final state = (this.state as DistingStateSynchronized);

          var valueStrings = [
            for (int parameterNumber = 0;
                parameterNumber <
                    state.slots[algorithmIndex].valueStrings.length;
                parameterNumber++)
              if ([13, 14, 17].contains(
                  state.slots[algorithmIndex].parameters[parameterNumber].unit))
                await disting.requestParameterValueString(
                        algorithmIndex, parameterNumber) ??
                    ParameterValueString.filler()
              else
                ParameterValueString.filler()
          ];

          final routings = !([
            13,
            14,
            17,
          ].contains(
                  state.slots[algorithmIndex].parameters[parameterNumber].unit))
              ? await disting.requestRoutingInformation(algorithmIndex)
              : state.slots[algorithmIndex].routing;

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
                    routing: routings ?? state.slots[algorithmIndex].routing,
                    valueStrings: valueStrings);
              },
            ),
          ));
        }
    }
  }

  void refresh({Duration delay = const Duration(milliseconds: 250)}) async {
    await Future.delayed(delay);

    switch (state) {
      case DistingStateSynchronized state:
        var disting = state.disting;

        emit(state.copyWith(loading: true));

        final numAlgorithmsInPreset =
            (await disting.requestNumAlgorithmsInPreset())!;

        final presetName = await disting.requestPresetName() ?? "";

        emit(state.copyWith(
          loading: false,
          presetName: presetName,
          slots: await fetchSlots(numAlgorithmsInPreset, disting),
        ));

        break;
    }
  }

  Future<void> onAlgorithmSelected(
    AlgorithmInfo algorithm,
    List<int> specifications,
  ) async {
    switch (state) {
      case DistingStateSynchronized syncstate:
        final disting = syncstate.disting;
        await disting.requestAddAlgorithm(algorithm, specifications);

        int currentNumAlgorithms = syncstate.slots.length;

        // Wait until number of algorithms in preset changes
        await _waitForSlotCountChange(disting, currentNumAlgorithms);

        // Add a slot at the end of the slots list, and then ask to update that
        // slot. The rest should remain the same, so we don't have to update
        // everything.
        var slots = List<Slot>.from((state as DistingStateSynchronized).slots);
        slots.add(await fetchSlot(disting, slots.length));
        emit((state as DistingStateSynchronized).copyWith(slots: slots));
    }
  }

  Future<void> _waitForSlotCountChange(
      DistingMidiManager disting, int currentNumAlgorithms) async {
    // Wait until number of algorithms in preset changes
    var startTime = DateTime.timestamp();
    while ((await disting.requestNumAlgorithmsInPreset()) ==
            currentNumAlgorithms &&
        DateTime.timestamp().difference(startTime) < Duration(seconds: 10)) {
      await Future.delayed(Duration(milliseconds: 150));
    }
  }

  Future<void> onRemoveAlgorithm(int algorithmIndex) async {
    switch (state) {
      case DistingStateSynchronized syncstate:
        final disting = requireDisting();
        await disting.requestRemoveAlgorithm(algorithmIndex);

        int currentNumAlgorithms = syncstate.slots.length;

        // Wait until number of algorithms in preset changes
        await _waitForSlotCountChange(disting, currentNumAlgorithms);

        var slots = List<Slot>.from(syncstate.slots);

        var updatedSlots = [
          ...slots.sublist(0, algorithmIndex),
          ...slots.sublist(algorithmIndex + 1).mapIndexed((index, element) =>
              _fixAlgorithmIndex(element, algorithmIndex + index))
        ];

        emit((state as DistingStateSynchronized).copyWith(slots: updatedSlots));
    }
  }

  void onFocusParameter({
    required int algorithmIndex,
    required int parameterNumber,
  }) {
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

    var slots = List<Slot>.from((state as DistingStateSynchronized).slots);
    var slot = slots.removeAt(algorithmIndex);
    var otherSlot = slots.removeAt(algorithmIndex - 1);

    otherSlot = _fixAlgorithmIndex(otherSlot, algorithmIndex);
    slot = _fixAlgorithmIndex(slot, algorithmIndex - 1);

    slots.insert(algorithmIndex - 1, slot);
    slots.insert(algorithmIndex, otherSlot);
    emit((state as DistingStateSynchronized).copyWith(slots: slots));

    return algorithmIndex - 1;
  }

  Future<int> moveAlgorithmDown(int algorithmIndex) async {
    final disting = requireDisting();
    await disting.requestMoveAlgorithmDown(algorithmIndex);

    var slots = List<Slot>.from((state as DistingStateSynchronized).slots);

    // If we are not on the last slot, move the slot to the next space in the list
    if (algorithmIndex == slots.length) return algorithmIndex;

    var slot = slots.removeAt(algorithmIndex);
    var otherSlot = slots.removeAt(algorithmIndex);

    otherSlot = _fixAlgorithmIndex(otherSlot, algorithmIndex);
    slot = _fixAlgorithmIndex(slot, algorithmIndex + 1);

    slots.insert(algorithmIndex, slot);
    slots.insert(algorithmIndex, otherSlot);
    emit((state as DistingStateSynchronized).copyWith(slots: slots));

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

        await _refreshPreset(disting, syncstate);

        break;
      default:
      // Handle other cases or errors
    }
  }

  Future<void> loadPreset(String name, bool append) async {
    switch (state) {
      case DistingStateSynchronized syncstate:
        final disting = requireDisting();

        emit(
          syncstate.copyWith(
            loading: true,
          ),
        );

        await disting.requestLoadPreset(name, append);

        await _refreshPreset(disting, syncstate);

        break;
      default:
      // Handle other cases or errors
    }
  }

  Future<void> _refreshPreset(
    DistingMidiManager disting,
    DistingStateSynchronized state, {
    Duration delay = const Duration(milliseconds: 250),
  }) async {
    await Future.delayed(delay);

    final numAlgorithmsInPreset =
        (await disting.requestNumAlgorithmsInPreset())!;
    final presetName = await disting.requestPresetName() ?? "";

    List<Slot> slots = await fetchSlots(numAlgorithmsInPreset, disting);

    emit(
      state.copyWith(
        loading: false,
        presetName: presetName,
        slots: slots,
      ),
    );
  }

  Future<void> saveMapping(
      int algorithmIndex, int parameterNumber, PackedMappingData data) async {
    switch (state) {
      case DistingStateSynchronized syncstate:
        final disting = requireDisting();

        await disting.requestSetMapping(algorithmIndex, parameterNumber, data);

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
                        packedMappingData: data),
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

  void renameSlot(int algorithmIndex, String newName) async {
    switch (state) {
      case DistingStateSynchronized syncstate:
        final disting = requireDisting();
        await disting.requestSendSlotName(algorithmIndex, newName);
        await Future.delayed(Duration(milliseconds: 100));
        final slot = await fetchSlot(requireDisting(), algorithmIndex);
        emit(syncstate.copyWith(
            slots: updateSlot(algorithmIndex, syncstate.slots, (_) => slot)));
    }
  }

  List<RoutingInformation> buildRoutingInformation() {
    switch (state) {
      case DistingStateSynchronized syncstate:
        return syncstate.slots
            .where((slot) => slot.routing.algorithmIndex != -1)
            .map((slot) => RoutingInformation(
                algorithmIndex: slot.routing.algorithmIndex,
                routingInfo: slot.routing.routingInfo,
                algorithmName: (slot.algorithm.name.isNotEmpty)
                    ? slot.algorithm.name
                    : syncstate.algorithms
                        .firstWhere(
                          (element) => element.guid == slot.algorithm.guid,
                        )
                        .name))
            .toList();
      default:
        return [];
    }
  }

  bool _isProgramParameter(DistingStateSynchronized state, int algorithmIndex,
          int parameterNumber) =>
      (state.slots[algorithmIndex].parameters[parameterNumber].name ==
          "Program") &&
      (("spin" == state.slots[algorithmIndex].algorithm.guid) ||
          ("lua " == state.slots[algorithmIndex].algorithm.guid));

  Slot _fixAlgorithmIndex(Slot slot, int algorithmIndex) {
    // Run through all of the parts of the slot and replace the algorithm index
    // with the new one.
    return Slot(
      algorithm: slot.algorithm,
      routing: RoutingInfo(
          algorithmIndex: algorithmIndex,
          routingInfo: slot.routing.routingInfo),
      pages: ParameterPages(
          algorithmIndex: algorithmIndex, pages: slot.pages.pages),
      parameters: slot.parameters
          .map((parameter) => ParameterInfo(
              algorithmIndex: algorithmIndex,
              parameterNumber: parameter.parameterNumber,
              min: parameter.min,
              max: parameter.max,
              defaultValue: parameter.defaultValue,
              unit: parameter.unit,
              name: parameter.name,
              powerOfTen: parameter.powerOfTen))
          .toList(),
      values: slot.values
          .map((value) => ParameterValue(
              algorithmIndex: algorithmIndex,
              parameterNumber: value.parameterNumber,
              value: value.value))
          .toList(),
      enums: slot.enums
          .map((enums) => ParameterEnumStrings(
              algorithmIndex: algorithmIndex,
              parameterNumber: enums.parameterNumber,
              values: enums.values))
          .toList(),
      mappings: slot.mappings
          .map((mapping) => Mapping(
                algorithmIndex: algorithmIndex,
                parameterNumber: mapping.parameterNumber,
                packedMappingData: mapping.packedMappingData,
              ))
          .toList(),
      valueStrings: slot.valueStrings
          .map((valueStrings) => ParameterValueString(
              algorithmIndex: algorithmIndex,
              parameterNumber: valueStrings.parameterNumber,
              value: valueStrings.value))
          .toList(),
    );
  }

  void setDisplayMode(DisplayMode displayMode) {
    requireDisting().let((disting) {
      disting.requestWake();
      disting.requestSetDisplayMode(displayMode);
    });
  }

  List<MappedParameter> buildMappedParameterList() {
    switch (state) {
      case DistingStateSynchronized syncstate:
        // return a list of parameters that have active mappings
        // from the state.
        return syncstate.slots.fold(
          List<MappedParameter>.empty(growable: true),
          (acc, slot) {
            acc.addAll(slot.mappings
                .where((mapping) => mapping.packedMappingData.isMapped())
                .map(
              (mapping) {
                var parameterNumber = mapping.parameterNumber;
                return MappedParameter(
                  parameter: slot.parameters[parameterNumber],
                  value: slot.values[parameterNumber],
                  enums: slot.enums[parameterNumber],
                  valueString: slot.valueStrings[parameterNumber],
                  mapping: mapping,
                  algorithm: slot.algorithm,
                );
              },
            ).toList());
            return acc;
          },
        );
      default:
        return [];
    }
  }

  // Map to hold an active polling task for each mapped parameter,
  // keyed by a composite key (e.g. "algorithmIndex_parameterNumber").
  final Map<String, _PollingTask> _pollingTasks = {};

  // Starts polling for each mapped parameter.
  void startPollingMappedParameters() {
    stopPollingMappedParameters(); // Clear any previous tasks.
    if (state is! DistingStateSynchronized) return;
    final mappedParams = buildMappedParameterList();
    for (final param in mappedParams) {
      final key =
          '${param.parameter.algorithmIndex}_${param.parameter.parameterNumber}';
      _pollingTasks[key] = _PollingTask();
      _pollIndividualParameter(param, key);
    }
  }

  // Stops all polling tasks.
  void stopPollingMappedParameters() {
    _pollingTasks.clear();
  }

  // Polls a single mapped parameter recursively.
  Future<void> _pollIndividualParameter(
      MappedParameter mapped, String key) async {
    // If the task has been cancelled or state is not synchronized, stop.
    final task = _pollingTasks[key];
    if (task == null || !task.active || state is! DistingStateSynchronized) {
      return;
    }

    // Define intervals and threshold.
    const Duration fastInterval = Duration(milliseconds: 100);
    const Duration slowInterval = Duration(milliseconds: 1000);
    const int fastToSlowThreshold = 3;

    try {
      final disting = requireDisting();
      // Request the current parameter value.
      final newValue = await disting.requestParameterValue(
        mapped.parameter.algorithmIndex,
        mapped.parameter.parameterNumber,
      );
      if (newValue == null) return;

      final currentState = state;
      if (currentState is DistingStateSynchronized) {
        final currentSlot = currentState.slots[mapped.parameter.algorithmIndex];
        final currentValue =
            currentSlot.values[mapped.parameter.parameterNumber];
        if (newValue.value != currentValue.value) {
          // A change was detected: update state and reset no-change count.
          final updatedSlots = updateSlot(
            mapped.parameter.algorithmIndex,
            currentState.slots,
            (slot) => slot.copyWith(
              values: replaceInList(
                slot.values,
                newValue,
                index: mapped.parameter.parameterNumber,
              ),
            ),
          );
          emit(currentState.copyWith(slots: updatedSlots));
          task.noChangeCount = 0;
          // Continue polling quickly.
          await Future.delayed(fastInterval);
        } else {
          // No change: increment counter and choose interval.
          task.noChangeCount++;
          final delay = (task.noChangeCount >= fastToSlowThreshold)
              ? slowInterval
              : fastInterval;
          await Future.delayed(delay);
        }
      }
    } catch (e) {
      // In case of an error, wait a bit before retrying.
      await Future.delayed(slowInterval);
    }

    // Continue polling this parameter if it’s still active.
    if (_pollingTasks.containsKey(key)) {
      _pollIndividualParameter(mapped, key);
    }
  }
}
