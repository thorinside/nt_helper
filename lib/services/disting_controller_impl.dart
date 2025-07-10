import 'dart:typed_data'; // Added for Uint8List
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart'
    show Algorithm, ParameterInfo, ParameterValue;
import 'package:nt_helper/domain/i_disting_midi_manager.dart';
import 'package:nt_helper/services/disting_controller.dart';
import 'package:nt_helper/models/cpu_usage.dart';

class DistingControllerImpl implements DistingController {
  final DistingCubit _distingCubit;
  static const int maxSlots =
      32; // Define maxSlots consistently, make static const

  DistingControllerImpl(this._distingCubit);

  /// Helper to get the synchronized state or throw if not available.
  DistingStateSynchronized _getSynchronizedState() {
    final state = _distingCubit.state;
    if (state is DistingStateSynchronized) {
      return state;
    } else {
      throw StateError(
          'Disting is not in a synchronized state. Current state: ${state.runtimeType}');
    }
  }

  /// Helper to get the underlying MIDI manager.
  IDistingMidiManager _getManager() {
    return _distingCubit.requireDisting();
  }

  /// Helper to validate a slot index.
  void _validateSlotIndex(int index) {
    if (index < 0 || index >= maxSlots) {
      throw ArgumentError(
          'Invalid slot index: $index. Must be between 0 and ${maxSlots - 1}.');
    }
  }

  /// Helper to validate a parameter number within a slot.
  void _validateParameterNumber(
      int slotIndex, int parameterNumber, DistingStateSynchronized state) {
    _validateSlotIndex(slotIndex);

    final Slot slotData = state.slots[slotIndex];

    if (parameterNumber < 0 || parameterNumber >= slotData.parameters.length) {
      throw ArgumentError(
          'Invalid parameter index: $parameterNumber for slot $slotIndex. Algorithm "${slotData.algorithm.name}" has ${slotData.parameters.length} parameters (0 to ${slotData.parameters.length - 1}).');
    }
  }

  @override
  Future<String> getCurrentPresetName() async {
    return _getSynchronizedState().presetName;
  }

  @override
  Future<void> setPresetName(String name) async {
    _distingCubit.renamePreset(name);
    return Future.value();
  }

  @override
  Future<Algorithm?> getAlgorithmInSlot(int slotIndex) async {
    _validateSlotIndex(slotIndex);
    final state = _getSynchronizedState();
    return state.slots[slotIndex].algorithm;
  }

  @override
  Future<List<ParameterInfo>> getParametersForSlot(int slotIndex) async {
    _validateSlotIndex(slotIndex);
    final state = _getSynchronizedState();
    final Slot slot = state.slots[slotIndex];
    return slot.parameters;
  }

  @override
  Future<void> addAlgorithm(Algorithm algorithm) async {
    final state = _getSynchronizedState();
    final algorithmInfo = state.algorithms
        .firstWhereOrNull((info) => info.guid == algorithm.guid);

    if (algorithmInfo == null) {
      throw ArgumentError(
          'Algorithm with GUID ${algorithm.guid} not found in the list of available algorithms.');
    }
    final specs =
        algorithmInfo.specifications.map((s) => s.defaultValue).toList();
    await _distingCubit.onAlgorithmSelected(algorithmInfo, specs);
  }

  @override
  Future<void> clearSlot(int slotIndex) async {
    _validateSlotIndex(slotIndex);
    final state = _getSynchronizedState();
    final slot = state.slots[slotIndex];

    await _distingCubit.onRemoveAlgorithm(slot.algorithm.algorithmIndex);
  }

  @override
  Future<void> moveAlgorithmUp(int slotIndex) async {
    _validateSlotIndex(slotIndex);
    await _distingCubit.moveAlgorithmUp(slotIndex);
  }

  @override
  Future<void> moveAlgorithmDown(int slotIndex) async {
    _validateSlotIndex(slotIndex);
    await _distingCubit.moveAlgorithmDown(slotIndex);
  }

  @override
  Future<void> updateParameterValue(
      int slotIndex, int parameterNumber, dynamic value) async {
    final state = _getSynchronizedState();
    _validateParameterNumber(slotIndex, parameterNumber, state);

    final Slot slotData = state.slots[slotIndex];
    final ParameterInfo paramInfo = slotData.parameters[parameterNumber];

    final int intValue;
    if (value is int) {
      intValue = value;
    } else if (value is double) {
      intValue = value.round();
    } else if (value is String) {
      intValue = int.tryParse(value) ??
          (throw ArgumentError('Cannot parse String "$value" to int.'));
    } else {
      throw ArgumentError(
          'Invalid value type: ${value.runtimeType}. Expected int, double, or parsable String.');
    }

    if (intValue < paramInfo.min || intValue > paramInfo.max) {
      throw ArgumentError(
          'Value $intValue for parameter "${paramInfo.name}" (index $parameterNumber) in slot $slotIndex is out of range (min: ${paramInfo.min}, max: ${paramInfo.max}).');
    }

    await _distingCubit.updateParameterValue(
        algorithmIndex: slotData.algorithm.algorithmIndex,
        parameterNumber: parameterNumber,
        value: intValue,
        userIsChangingTheValue: false);
  }

  @override
  Future<void> updateParameterString(
      int slotIndex, int parameterNumber, String value) async {
    final state = _getSynchronizedState();
    _validateParameterNumber(slotIndex, parameterNumber, state);

    final Slot slotData = state.slots[slotIndex];

    await _distingCubit.updateParameterString(
        algorithmIndex: slotData.algorithm.algorithmIndex,
        parameterNumber: parameterNumber,
        value: value);
  }

  @override
  Future<Map<int, Algorithm?>> getAllSlots() async {
    final state = _getSynchronizedState();
    final Map<int, Algorithm?> slotAlgorithms = {};
    for (int i = 0; i < state.slots.length; i++) {
      slotAlgorithms[i] = state.slots[i].algorithm;
    }
    return slotAlgorithms;
  }

  @override
  Future<int?> getParameterValue(int slotIndex, int parameterNumber) async {
    final state = _getSynchronizedState();
    _validateParameterNumber(slotIndex, parameterNumber, state);

    final Slot slotData = state.slots[slotIndex];
    final Algorithm algorithm = slotData.algorithm;

    final int actualAlgorithmIndex = algorithm.algorithmIndex;

    try {
      final ParameterValue? paramValueResponse = await _getManager()
          .requestParameterValue(actualAlgorithmIndex, parameterNumber);
      return paramValueResponse?.value;
    } catch (e) {
      debugPrint(
          'Error fetching parameter value for slot $slotIndex, param $parameterNumber (algoIndex $actualAlgorithmIndex): $e');
      return null;
    }
  }

  @override
  Future<String?> getParameterStringValue(int slotIndex, int parameterNumber) async {
    final state = _getSynchronizedState();
    _validateParameterNumber(slotIndex, parameterNumber, state);

    final Slot slotData = state.slots[slotIndex];

    try {
      // Access the parameter string value directly from the slot's valueStrings
      // This is separate from the parameter value and is used for text-based parameters
      // like those in the Notes algorithm
      if (parameterNumber < slotData.valueStrings.length) {
        return slotData.valueStrings[parameterNumber].value;
      }
      
      return null;
    } catch (e) {
      debugPrint(
          'Error fetching parameter string value for slot $slotIndex, param $parameterNumber: $e');
      return null;
    }
  }

  @override
  Future<void> setSlotName(int slotIndex, String name) async {
    final state = _getSynchronizedState();
    _validateSlotIndex(slotIndex);

    final Slot slotData = state.slots[slotIndex];

    final int actualAlgorithmIndex = slotData.algorithm.algorithmIndex;

    _distingCubit.renameSlot(actualAlgorithmIndex, name);
  }

  @override
  Future<String?> getSlotName(int slotIndex) async {
    final state = _getSynchronizedState();
    _validateSlotIndex(slotIndex);

    final Slot slotData = state.slots[slotIndex];
    
    // Check if slot is empty
    if (slotData.algorithm.guid.isEmpty) {
      return null;
    }

    // Return the custom name if set, otherwise return the algorithm's default name
    // The actual implementation may need to check for custom names stored in the state
    // For now, return the algorithm name as a placeholder
    return slotData.algorithm.name.isNotEmpty ? slotData.algorithm.name : null;
  }

  @override
  Future<void> newPreset() async {
    await _distingCubit.newPreset();
  }

  @override
  Future<void> savePreset() async {
    _getSynchronizedState();
    await _getManager().requestSavePreset();
  }

  @override
  Future<Uint8List?> getModuleScreenshot() async {
    // Assuming DistingCubit has a method like getHardwareScreenshot
    // that handles connection checks and returns null if unavailable.
    try {
      // _getSynchronizedState(); // Determine if sync state is strictly needed for a screenshot
      return await _distingCubit.getHardwareScreenshot();
    } catch (e) {
      debugPrint('Error in getModuleScreenshot: ${e.toString()}');
      return null; // Ensure null is returned on any error
    }
  }

  @override
  Future<void> refreshSlot(int slotIndex) async {
    _validateSlotIndex(slotIndex);
    _getSynchronizedState();
    await _distingCubit.refreshSlot(slotIndex);
  }

  @override
  Future<CpuUsage?> getCpuUsage() async {
    try {
      _getSynchronizedState(); // Ensure we're in sync state
      return await _getManager().requestCpuUsage();
    } catch (e) {
      debugPrint('Error fetching CPU usage: ${e.toString()}');
      return null; // Return null on any error
    }
  }
}
