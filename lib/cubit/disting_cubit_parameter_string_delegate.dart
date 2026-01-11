part of 'disting_cubit.dart';

class _ParameterStringDelegate {
  _ParameterStringDelegate(this._cubit);

  final DistingCubit _cubit;

  void onParameterStringUpdated(
    int algorithmIndex,
    int parameterNumber,
    String value,
  ) {
    final currentState = _cubit.state;
    if (currentState is! DistingStateSynchronized) return;

    if (algorithmIndex < 0 || algorithmIndex >= currentState.slots.length) {
      return;
    }

    final currentSlot = currentState.slots[algorithmIndex];
    if (parameterNumber < 0 ||
        parameterNumber >= currentSlot.valueStrings.length) {
      return;
    }

    try {
      // Update the parameter string in the UI
      final updatedValueStrings = List<ParameterValueString>.from(
        currentSlot.valueStrings,
      );
      updatedValueStrings[parameterNumber] = ParameterValueString(
        algorithmIndex: algorithmIndex,
        parameterNumber: parameterNumber,
        value: value,
      );

      final updatedSlot = currentSlot.copyWith(
        valueStrings: updatedValueStrings,
      );
      final updatedSlots = List<Slot>.from(currentState.slots);
      updatedSlots[algorithmIndex] = updatedSlot;

      _cubit._emitState(currentState.copyWith(slots: updatedSlots));
    } catch (e, stackTrace) {
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  /// Refreshes parameter strings for a specific slot only
  Future<void> refreshSlotParameterStrings(int algorithmIndex) async {
    final currentState = _cubit.state;
    if (currentState is! DistingStateSynchronized) {
      return;
    }

    if (algorithmIndex < 0 || algorithmIndex >= currentState.slots.length) {
      return;
    }

    final disting = _cubit.requireDisting();
    final currentSlot = currentState.slots[algorithmIndex];

    try {
      // Only update parameter strings for string-type parameters
      var updatedValueStrings = List<ParameterValueString>.from(
        currentSlot.valueStrings,
      );

      for (
        int parameterNumber = 0;
        parameterNumber < currentSlot.parameters.length;
        parameterNumber++
      ) {
        final parameter = currentSlot.parameters[parameterNumber];
        if (ParameterEditorRegistry.isStringTypeUnit(parameter.unit)) {
          final newValueString = await disting.requestParameterValueString(
            algorithmIndex,
            parameterNumber,
          );
          if (newValueString != null) {
            updatedValueStrings[parameterNumber] = newValueString;
          }
        }
      }

      // Update the slot with new parameter strings
      final updatedSlot = currentSlot.copyWith(
        valueStrings: updatedValueStrings,
      );
      final updatedSlots = List<Slot>.from(currentState.slots);
      updatedSlots[algorithmIndex] = updatedSlot;

      _cubit._emitState(currentState.copyWith(slots: updatedSlots));
    } catch (e, stackTrace) {
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> updateParameterString({
    required int algorithmIndex,
    required int parameterNumber,
    required String value,
  }) async {
    // Acquire semaphore to block retry queue during user parameter string updates
    _cubit._parameterFetchDelegate.acquireCommandSemaphore();

    try {
      switch (_cubit.state) {
        case DistingStateInitial():
        case DistingStateSelectDevice():
        case DistingStateConnected():
          break;
        case DistingStateSynchronized _:
          var disting = _cubit.requireDisting();

          await disting.setParameterString(
            algorithmIndex,
            parameterNumber,
            value,
          );

          // Refresh the parameter value string to reflect the change
          final newValueString = await disting.requestParameterValueString(
            algorithmIndex,
            parameterNumber,
          );

          if (newValueString != null) {
            final state = (_cubit.state as DistingStateSynchronized);

            _cubit._emitState(
              state.copyWith(
                slots: _cubit.updateSlot(algorithmIndex, state.slots, (slot) {
                  return slot.copyWith(
                    valueStrings: _cubit.replaceInList(
                      slot.valueStrings,
                      newValueString,
                      index: parameterNumber,
                    ),
                  );
                }),
              ),
            );
          }
          break;
      }
    } finally {
      // Always release semaphore to allow retry queue to proceed
      _cubit._parameterFetchDelegate.releaseCommandSemaphore();
    }
  }
}

