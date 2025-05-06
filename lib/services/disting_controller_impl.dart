import 'package:collection/collection.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/domain/i_disting_midi_manager.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'package:nt_helper/services/disting_controller.dart';

class DistingControllerImpl implements DistingController {
  final DistingCubit _distingCubit;
  final int maxSlots = 32; // Define maxSlots consistently

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
    _validateSlotIndex(slotIndex); // Validates 0 <= slotIndex < maxSlots

    // state.slots is List<Slot?>, directly access by slotIndex
    final Slot? slotData = state.slots[slotIndex];

    if (slotData == null || slotData.algorithm == null) {
      throw ArgumentError('Slot $slotIndex is empty and has no parameters.');
    }

    if (parameterNumber < 0 || parameterNumber >= slotData.parameters.length) {
      throw ArgumentError(
          'Invalid parameter index: $parameterNumber for slot $slotIndex. Algorithm "${slotData.algorithm!.name}" has ${slotData.parameters.length} parameters (0 to ${slotData.parameters.length - 1}).');
    }
  }

  @override
  Future<String> getCurrentPresetName() async {
    return _getSynchronizedState().presetName;
  }

  @override
  Future<void> setCurrentPresetName(String name) async {
    await _getManager().requestSetPresetName(name);
    // The cubit might listen to MIDI responses and update its state, or a refresh might be needed.
    // For now, assume the manager call is sufficient for the device, and cubit handles state update.
  }

  @override
  Future<Algorithm?> getAlgorithmInSlot(int slotIndex) async {
    _validateSlotIndex(slotIndex);
    final state = _getSynchronizedState();
    // state.slots is List<Slot?> directly indexed by slotIndex
    return state.slots[slotIndex]?.algorithm;
  }

  @override
  Future<List<ParameterInfo>> getParametersForSlot(int slotIndex) async {
    _validateSlotIndex(slotIndex);
    final state = _getSynchronizedState();
    final slot = state.slots[slotIndex];
    return slot?.parameters ?? [];
  }

  @override
  Future<void> loadAlgorithmIntoSlot(int slotIndex, Algorithm algorithm) async {
    final state = _getSynchronizedState();
    _validateSlotIndex(slotIndex);

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

    if (slot != null && slot.algorithm != null) {
      // Corrected to use IDistingMidiManager method
      // The cubit's onRemoveAlgorithm(slotIndex) might be a higher-level abstraction to use.
      // Let's assume direct manager call is intended if cubit doesn't expose this directly for *slotIndex*.
      // The cubit's onRemoveAlgorithm takes `algorithmId` (preset index), not slot index.
      // So, mapping slot.algorithm.algorithmIndex is correct for the manager.
      await _getManager()
          .requestRemoveAlgorithm(slot.algorithm!.algorithmIndex);
    }
  }

  @override
  Future<void> moveAlgorithm(int sourceSlotIndex, int destSlotIndex) async {
    _validateSlotIndex(sourceSlotIndex);
    _validateSlotIndex(destSlotIndex);
    if (sourceSlotIndex == destSlotIndex) return;

    // This logic was present before recent edits and uses cubit methods
    // that presumably call manager.requestMoveAlgorithmUp/Down internally.
    // This relies on the cubit to manage the sequence of MIDI commands.
    final state = _getSynchronizedState();
    final algoToMove = state.slots[sourceSlotIndex]?.algorithm;
    if (algoToMove == null) {
      throw StateError('Source slot $sourceSlotIndex is empty.');
    }
    int currentPresetIndex = algoToMove.algorithmIndex;

    // Determine target preset index based on algorithms in between
    // This is complex; for now, using the cubit's simpler slot-based move if available
    // Or, if cubit only has moveUp/Down by *preset index*, this needs careful mapping.

    // The previous version used _distingCubit.moveAlgorithmUp/Down directly with slotIndex.
    // This was likely an error in the original if those cubit methods expected algorithmIndex.
    // Given the IDistingMidiManager methods, a direct move is complex.
    // For now, to fix linter errors, I'll assume a more abstract cubit call or mark as complex.
    // The `_getManager().moveAlgorithm` was definitely wrong.

    // Simplification: The Disting EX itself moves by *slot number* typically.
    // The sysex for move is `move_algorithm(algorithm_id, new_slot_number)`
    // Let's assume IDistingMidiManager should have a `requestMoveAlgorithmToSlot(algorithmIndex, newSlotIndex)`.
    // Since it doesn't, this method in controller is hard to implement correctly without it.
    // I will use the up/down methods as that's what the manager provides, via cubit if possible.
    // This logic is from a previous version of the file that seemed to work with cubit methods.
    if (destSlotIndex < sourceSlotIndex) {
      int currentEffectiveSlot = sourceSlotIndex;
      while (currentEffectiveSlot > destSlotIndex) {
        // Need to map currentEffectiveSlot to its algorithmIndex for manager calls
        // This is getting too complex for a quick fix. Will assume cubit handles it.
        // If DistingCubit.moveAlgorithmUp(slotIndex) exists and does the right thing:
        // await _distingCubit.moveAlgorithmUp(currentEffectiveSlot);
        // For now, let's throw to indicate this needs proper implementation.
        throw UnimplementedError(
            "moveAlgorithm needs robust implementation using cubit or manager's up/down by algorithmIndex");
        // currentEffectiveSlot--;
      }
    } else {
      int currentEffectiveSlot = sourceSlotIndex;
      while (currentEffectiveSlot < destSlotIndex) {
        // await _distingCubit.moveAlgorithmDown(currentEffectiveSlot);
        throw UnimplementedError(
            "moveAlgorithm needs robust implementation using cubit or manager's up/down by algorithmIndex");
        // currentEffectiveSlot++;
      }
    }
  }

  @override
  Future<void> updateParameterValue(
      int slotIndex, int parameterNumber, dynamic value) async {
    final state = _getSynchronizedState();
    _validateParameterNumber(slotIndex, parameterNumber, state);

    final Slot slotData = state.slots[slotIndex]!;
    final ParameterInfo paramInfo = slotData.parameters[parameterNumber];

    int intValue;
    if (value is int) {
      intValue = value;
    } else if (value is double) {
      intValue = value.round(); // Use round for doubles
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
      // Ensure we iterate up to maxSlots if state.slots can be shorter,
      // or ensure state.slots always has maxSlots items (null for empty).
      // Assuming state.slots.length is maxSlots based on current cubit behavior.
      slotAlgorithms[i] = state.slots[i]?.algorithm;
    }
    return slotAlgorithms;
  }

  @override
  Future<int?> getParameterValue(int slotIndex, int parameterNumber) async {
    final state = _getSynchronizedState();
    // _validateParameterNumber also calls _validateSlotIndex
    _validateParameterNumber(slotIndex, parameterNumber, state);

    // If validation passed, slotData and slotData.algorithm are guaranteed to be non-null
    final Slot slotData = state.slots[slotIndex]!;
    final Algorithm algorithm = slotData.algorithm!;

    // IDistingMidiManager.requestParameterValue expects the algorithm's index within the preset
    final int actualAlgorithmIndex = algorithm.algorithmIndex;

    try {
      final ParameterValue? paramValueResponse = await _getManager()
          .requestParameterValue(actualAlgorithmIndex, parameterNumber);
      return paramValueResponse?.value;
    } catch (e) {
      // Log or handle MIDI communication errors if necessary
      // For now, returning null signifies failure to fetch or an error during fetch
      print(
          'Error fetching parameter value for slot $slotIndex, param $parameterNumber (algoIndex $actualAlgorithmIndex): $e');
      return null;
    }
  }

  @override
  Future<void> setSlotName(int slotIndex, String name) async {
    final state = _getSynchronizedState();
    _validateSlotIndex(slotIndex);

    // Ensure the slot is not empty
    final Slot? slotData = state.slots[slotIndex];
    if (slotData == null || slotData.algorithm == null) {
      throw StateError('Cannot set name for empty slot $slotIndex.');
    }

    // Get the algorithm index for the MIDI manager
    final int actualAlgorithmIndex = slotData.algorithm!.algorithmIndex;

    // Call the manager method
    await _getManager().requestSendSlotName(actualAlgorithmIndex, name);

    // Note: The cubit state might not reflect this change immediately
    // unless it specifically listens for slot name confirmations or refreshes.
  }

  @override
  Future<void> newPreset() async {
    _getSynchronizedState(); // Check if synchronized before sending command
    await _getManager().requestNewPreset();
    // The cubit should ideally react to this command or subsequent MIDI events
    // to transition its state back to maybe a 'loading' or empty synchronized state.
  }

  @override
  Future<void> savePreset() async {
    _getSynchronizedState(); // Check if synchronized before sending command
    // The manager method takes an optional 'option' parameter, defaulting is fine for now.
    await _getManager().requestSavePreset();
  }
}
