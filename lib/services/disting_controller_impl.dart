import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/domain/i_disting_midi_manager.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'package:nt_helper/services/disting_controller.dart';

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
  Future<void> moveAlgorithm(int sourceSlotIndex, int destSlotIndex) async {
    _validateSlotIndex(sourceSlotIndex);
    _validateSlotIndex(destSlotIndex);
    if (sourceSlotIndex == destSlotIndex) return;

    final state = _getSynchronizedState();
    final algoToMove = state.slots[sourceSlotIndex].algorithm;
    if (algoToMove == null) {
      throw StateError('Source slot $sourceSlotIndex is empty.');
    }

    if (destSlotIndex < sourceSlotIndex) {
      throw UnimplementedError(
          "moveAlgorithm needs robust implementation using cubit's up/down methods, mapping slot index to algorithm index correctly, or a dedicated cubit method.");
    } else {
      throw UnimplementedError(
          "moveAlgorithm needs robust implementation using cubit's up/down methods, mapping slot index to algorithm index correctly, or a dedicated cubit method.");
    }
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
  Future<void> setSlotName(int slotIndex, String name) async {
    final state = _getSynchronizedState();
    _validateSlotIndex(slotIndex);

    final Slot slotData = state.slots[slotIndex];

    final int actualAlgorithmIndex = slotData.algorithm.algorithmIndex;

    _distingCubit.renameSlot(actualAlgorithmIndex, name);
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
}
