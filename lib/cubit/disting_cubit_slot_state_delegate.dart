part of 'disting_cubit.dart';

class _SlotStateDelegate {
  _SlotStateDelegate(this._cubit);

  final DistingCubit _cubit;

  // Output mode usage tracking
  // Maps slot index -> parameter number -> list of affected parameters
  final Map<int, Map<int, List<int>>> _outputModeUsageMap = {};

  // Track which output mode parameters we've already queried to avoid duplicates
  final Map<int, Set<int>> _queriedOutputModeParameters = {};

  Map<int, List<int>> outputModeMapForSlot(int slotIndex) {
    return _outputModeUsageMap[slotIndex] ?? const {};
  }

  void setOutputModeUsageMapForSlot(
    int slotIndex,
    Map<int, List<int>> outputModeMap,
  ) {
    _outputModeUsageMap[slotIndex] = outputModeMap;
    _queriedOutputModeParameters[slotIndex] =
        outputModeMap.keys.toSet();
  }

  Future<void> ensureOutputModeUsageFromDb({
    required int slotIndex,
    required String algorithmGuid,
  }) async {
    if (_outputModeUsageMap[slotIndex]?.isNotEmpty == true) {
      return;
    }

    try {
      final dbOutputModeUsage =
          await _cubit._metadataDao.getOutputModeUsageForAlgorithm(algorithmGuid);
      if (dbOutputModeUsage.isNotEmpty) {
        _outputModeUsageMap[slotIndex] = dbOutputModeUsage;
      }
    } catch (e) {
      // Silently ignore database errors - output mode is optional
    }
  }

  // State update methods for retry results
  Future<void> updateSlotParameterInfo(
    int slotIndex,
    int paramIndex,
    ParameterInfo info,
  ) async {
    final currentState = _cubit.state;
    if (currentState is! DistingStateSynchronized ||
        slotIndex >= currentState.slots.length) {
      return;
    }

    final slot = currentState.slots[slotIndex];
    if (paramIndex >= slot.parameters.length) {
      return;
    }

    final updatedParameters = List<ParameterInfo>.from(slot.parameters);
    updatedParameters[paramIndex] = info;

    final updatedSlot = slot.copyWith(parameters: updatedParameters);
    final updatedSlots = List<Slot>.from(currentState.slots);
    updatedSlots[slotIndex] = updatedSlot;

    _cubit._emitState(currentState.copyWith(slots: updatedSlots));

    // Automatically query output mode usage if parameter has isOutputMode flag
    if (info.isOutputMode && info.parameterNumber >= 0) {
      await _queryOutputModeUsage(slotIndex, info.parameterNumber);
    }
  }

  /// Query output mode usage for a parameter with isOutputMode flag.
  /// Uses debounce logic to avoid duplicate queries during sync operations.
  Future<void> _queryOutputModeUsage(
    int slotIndex,
    int parameterNumber,
  ) async {
    final currentState = _cubit.state;
    if (currentState is! DistingStateSynchronized) {
      return;
    }

    // Check if we've already queried this parameter
    final queriedParams = _queriedOutputModeParameters[slotIndex] ?? {};
    if (queriedParams.contains(parameterNumber)) {
      return; // Already queried, skip
    }

    try {
      final disting = currentState.disting;
      final outputModeUsage = await disting.requestOutputModeUsage(
        slotIndex,
        parameterNumber,
      );

      if (outputModeUsage != null) {
        // Store the output mode usage data
        final slotMap = _outputModeUsageMap[slotIndex] ?? {};
        slotMap[outputModeUsage.parameterNumber] =
            outputModeUsage.affectedParameterNumbers;
        _outputModeUsageMap[slotIndex] = slotMap;

        // Mark as queried
        queriedParams.add(parameterNumber);
        _queriedOutputModeParameters[slotIndex] = queriedParams;

        // Update the slot with the new outputModeMap and emit state change
        // This ensures the routing editor gets the modeParameterNumber for output ports
        final refreshedState = _cubit.state;
        if (refreshedState is DistingStateSynchronized &&
            slotIndex < refreshedState.slots.length) {
          final currentSlot = refreshedState.slots[slotIndex];
          final updatedSlot = currentSlot.copyWith(
            outputModeMap: _outputModeUsageMap[slotIndex] ?? {},
          );
          final updatedSlots = List<Slot>.from(refreshedState.slots);
          updatedSlots[slotIndex] = updatedSlot;
          _cubit._emitState(refreshedState.copyWith(slots: updatedSlots));
        }
      }
    } catch (e) {
      // Silently fail - output mode usage is optional data
    }
  }

  /// Get output mode usage data for a parameter.
  /// Returns list of affected parameter numbers, or null if not available.
  List<int>? getOutputModeUsage(int slotIndex, int parameterNumber) {
    return _outputModeUsageMap[slotIndex]?[parameterNumber];
  }

  /// Get all output mode usage data for a slot.
  Map<int, List<int>>? getSlotOutputModeUsage(int slotIndex) {
    return _outputModeUsageMap[slotIndex];
  }

  Future<void> updateSlotParameterEnums(
    int slotIndex,
    int paramIndex,
    ParameterEnumStrings enums,
  ) async {
    final currentState = _cubit.state;
    if (currentState is! DistingStateSynchronized ||
        slotIndex >= currentState.slots.length) {
      return;
    }

    final slot = currentState.slots[slotIndex];
    if (paramIndex >= slot.enums.length) {
      return;
    }

    final updatedEnums = List<ParameterEnumStrings>.from(slot.enums);
    updatedEnums[paramIndex] = enums;

    final updatedSlot = slot.copyWith(enums: updatedEnums);
    final updatedSlots = List<Slot>.from(currentState.slots);
    updatedSlots[slotIndex] = updatedSlot;

    _cubit._emitState(currentState.copyWith(slots: updatedSlots));
  }

  Future<void> updateSlotParameterMappings(
    int slotIndex,
    int paramIndex,
    Mapping mappings,
  ) async {
    final currentState = _cubit.state;
    if (currentState is! DistingStateSynchronized ||
        slotIndex >= currentState.slots.length) {
      return;
    }

    final slot = currentState.slots[slotIndex];
    if (paramIndex >= slot.mappings.length) {
      return;
    }

    final updatedMappings = List<Mapping>.from(slot.mappings);
    updatedMappings[paramIndex] = mappings;

    final updatedSlot = slot.copyWith(mappings: updatedMappings);
    final updatedSlots = List<Slot>.from(currentState.slots);
    updatedSlots[slotIndex] = updatedSlot;

    _cubit._emitState(currentState.copyWith(slots: updatedSlots));
  }

  Future<void> updateSlotParameterValueStrings(
    int slotIndex,
    int paramIndex,
    ParameterValueString valueStrings,
  ) async {
    final currentState = _cubit.state;
    if (currentState is! DistingStateSynchronized ||
        slotIndex >= currentState.slots.length) {
      return;
    }

    final slot = currentState.slots[slotIndex];
    if (paramIndex >= slot.valueStrings.length) {
      return;
    }

    final updatedValueStrings = List<ParameterValueString>.from(
      slot.valueStrings,
    );
    updatedValueStrings[paramIndex] = valueStrings;

    final updatedSlot = slot.copyWith(valueStrings: updatedValueStrings);
    final updatedSlots = List<Slot>.from(currentState.slots);
    updatedSlots[slotIndex] = updatedSlot;

    _cubit._emitState(currentState.copyWith(slots: updatedSlots));
  }

  Future<void> refreshRouting() async {
    final disting = _cubit.requireDisting();
    final currentState = _cubit.state;
    if (currentState is! DistingStateSynchronized) return;

    // For each slot, update the routing information
    final updatedSlots = await Future.wait(
      currentState.slots.map(
        (slot) async => slot.copyWith(
          routing:
              await disting.requestRoutingInformation(
                slot.algorithm.algorithmIndex,
              ) ??
              slot.routing,
        ),
      ),
    );

    _cubit._emitState(currentState.copyWith(slots: updatedSlots));
  }
}
