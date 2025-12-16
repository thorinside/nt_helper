part of 'disting_cubit.dart';

class _LuaReloadDelegate {
  _LuaReloadDelegate(this._cubit);

  final DistingCubit _cubit;

  /// Forces a Lua script reload while preserving all parameter state.
  /// This is specifically designed for development mode where a script file
  /// has been modified and needs to be reloaded without losing user settings.
  ///
  /// The process: Program=0 (unload) → Program=currentValue (reload) → restore all state
  Future<void> forceReloadLuaScriptWithStatePreservation(
    int algorithmIndex,
    int programParameterNumber,
    int currentProgramValue,
  ) async {
    final currentState = _cubit.state;
    if (currentState is! DistingStateSynchronized) {
      throw Exception('Cannot reload script: Disting not synchronized');
    }

    if (algorithmIndex >= currentState.slots.length) {
      throw Exception('Algorithm index $algorithmIndex out of range');
    }

    final currentSlot = currentState.slots[algorithmIndex];
    final disting = currentState.disting;

    try {
      // 1. CAPTURE CURRENT STATE
      final savedValues = List<ParameterValue>.from(currentSlot.values);
      final savedMappings = List<Mapping>.from(currentSlot.mappings);
      final savedValueStrings = List<ParameterValueString>.from(
        currentSlot.valueStrings,
      );
      // Note: Routing restoration may require additional research for programmatic setting

      // 2. FORCE SCRIPT UNLOAD (Program = 0)
      await disting.setParameterValue(
        algorithmIndex,
        programParameterNumber,
        0,
      );
      await Future.delayed(
        const Duration(milliseconds: 200),
      ); // Allow hardware to process

      // 3. RELOAD TARGET SCRIPT (Program = currentProgramValue)
      await disting.setParameterValue(
        algorithmIndex,
        programParameterNumber,
        currentProgramValue,
      );
      await Future.delayed(
        const Duration(milliseconds: 300),
      ); // Allow script to initialize

      // 4. RESTORE ALL PARAMETER VALUES (except Program parameter)
      for (final paramValue in savedValues) {
        if (paramValue.parameterNumber != programParameterNumber) {
          await disting.setParameterValue(
            algorithmIndex,
            paramValue.parameterNumber,
            paramValue.value,
          );
          // Small delay between parameters to avoid overwhelming hardware
          await Future.delayed(const Duration(milliseconds: 10));
        }
      }

      // 5. RESTORE STRING PARAMETERS
      for (final stringValue in savedValueStrings) {
        if (stringValue.parameterNumber != programParameterNumber) {
          await disting.setParameterString(
            algorithmIndex,
            stringValue.parameterNumber,
            stringValue.value,
          );
          await Future.delayed(const Duration(milliseconds: 10));
        }
      }

      // 6. RESTORE MIDI/CV MAPPINGS
      for (final mapping in savedMappings) {
        if (mapping.parameterNumber != programParameterNumber) {
          await disting.requestSetMapping(
            algorithmIndex,
            mapping.parameterNumber,
            mapping.packedMappingData,
          );
          await Future.delayed(const Duration(milliseconds: 10));
        }
      }
    } catch (e) {
      // On error, refresh the slot to ensure UI is in sync with hardware
      await _cubit._refreshSlotAfterAnomaly(algorithmIndex);
      rethrow;
    }
  }
}

