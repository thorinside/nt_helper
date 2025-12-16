part of 'disting_cubit.dart';

class _SlotMaintenanceDelegate {
  _SlotMaintenanceDelegate(this._cubit);

  final DistingCubit _cubit;

  final Map<int, DateTime> _lastAnomalyRefreshAttempt = {};

  Slot fixAlgorithmIndex(Slot slot, int algorithmIndex) {
    // Run through all of the parts of the slot and replace the algorithm index
    // with the new one by manually constructing new objects.
    return Slot(
      algorithm: slot.algorithm.copyWith(algorithmIndex: algorithmIndex),
      routing: RoutingInfo(
        algorithmIndex: algorithmIndex,
        routingInfo: slot.routing.routingInfo,
      ),
      pages: ParameterPages(
        algorithmIndex: algorithmIndex,
        pages: slot.pages.pages,
      ),
      parameters: slot.parameters
          .map(
            (parameter) => ParameterInfo(
              algorithmIndex: algorithmIndex,
              parameterNumber: parameter.parameterNumber,
              min: parameter.min,
              max: parameter.max,
              defaultValue: parameter.defaultValue,
              unit: parameter.unit,
              name: parameter.name,
              powerOfTen: parameter.powerOfTen,
              ioFlags: parameter.ioFlags,
            ),
          )
          .toList(),
      values: slot.values
          .map(
            (value) => ParameterValue(
              algorithmIndex: algorithmIndex,
              parameterNumber: value.parameterNumber,
              value: value.value,
              isDisabled: value.isDisabled,
            ),
          )
          .toList(),
      enums: slot.enums
          .map(
            (enums) => ParameterEnumStrings(
              algorithmIndex: algorithmIndex,
              parameterNumber: enums.parameterNumber,
              values: enums.values,
            ),
          )
          .toList(),
      mappings: slot.mappings
          .map(
            (mapping) => Mapping(
              algorithmIndex: algorithmIndex,
              parameterNumber: mapping.parameterNumber,
              packedMappingData: mapping.packedMappingData,
            ),
          )
          .toList(),
      valueStrings: slot.valueStrings
          .map(
            (valueStrings) => ParameterValueString(
              algorithmIndex: algorithmIndex,
              parameterNumber: valueStrings.parameterNumber,
              value: valueStrings.value,
            ),
          )
          .toList(),
      outputModeMap: slot.outputModeMap,
    );
  }

  Future<void> refreshSlot(int algorithmIndex) async {
    final syncState = _cubit.state;
    if (syncState is! DistingStateSynchronized) {
      return;
    }

    try {
      final disting = _cubit.requireDisting();
      final Slot updatedSlot = await _cubit.fetchSlot(
        disting,
        algorithmIndex,
      );
      final currentState = _cubit.state as DistingStateSynchronized;
      final newSlots = List<Slot>.from(currentState.slots);
      newSlots[algorithmIndex] = updatedSlot;
      _cubit._emitState(currentState.copyWith(slots: newSlots));
    } catch (e, stackTrace) {
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> refreshSlotAfterAnomaly(int algorithmIndex) async {
    await Future.delayed(const Duration(seconds: 1));

    final syncState = _cubit.state;
    if (syncState is! DistingStateSynchronized) {
      return;
    }

    final now = DateTime.now();
    final lastAttempt = _lastAnomalyRefreshAttempt[algorithmIndex];
    if (lastAttempt != null &&
        now.difference(lastAttempt) < const Duration(seconds: 10)) {
      return;
    }
    _lastAnomalyRefreshAttempt[algorithmIndex] = now;

    try {
      final disting = _cubit.requireDisting();
      final Slot updatedSlot = await _cubit.fetchSlot(
        disting,
        algorithmIndex,
      );
      final currentState = _cubit.state as DistingStateSynchronized;
      final newSlots = List<Slot>.from(currentState.slots);
      newSlots[algorithmIndex] = updatedSlot;
      _cubit._emitState(currentState.copyWith(slots: newSlots));
    } catch (e, stackTrace) {
      debugPrintStack(stackTrace: stackTrace);
      // Optionally, clear the timestamp to allow immediate retry if fetch failed
      // _lastAnomalyRefreshAttempt.remove(algorithmIndex);
    }
  }

  Future<void> resetOutputs(Slot slot, int outputIndex) async {
    final disting = _cubit.requireDisting();

    slot.parameters
        .where(
          (p) =>
              p.name.toLowerCase().contains("output") &&
              p.min == 0 &&
              p.max == 28,
        )
        .forEach(
          (p) => disting.setParameterValue(
            p.algorithmIndex,
            p.parameterNumber,
            outputIndex,
          ),
        );
    _cubit.refresh();
  }
}
