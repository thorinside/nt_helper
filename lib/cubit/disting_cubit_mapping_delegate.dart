part of 'disting_cubit.dart';

class _MappingDelegate {
  _MappingDelegate(this._cubit);

  final DistingCubit _cubit;

  Future<void> saveMapping(
    int algorithmIndex,
    int parameterNumber,
    PackedMappingData data,
  ) async {
    switch (_cubit.state) {
      case DistingStateSynchronized _:
        final disting = _cubit.requireDisting();
        await disting.requestSetMapping(algorithmIndex, parameterNumber, data);
        await _cubit._refreshStateFromManager(); // Refresh state from manager
        break;
      default:
      // Handle other cases or errors
    }
  }

  /// Sets the performance page assignment for a parameter.
  ///
  /// - [slotIndex]: Slot index (0-31)
  /// - [parameterNumber]: Parameter number within the algorithm
  /// - [perfPageIndex]: Performance page index (0-30, where 0 = not assigned)
  ///
  /// Uses optimistic update pattern:
  /// 1. Update local state immediately for instant UI feedback
  /// 2. Send update to hardware
  /// 3. Verify by reading back specific parameter mapping
  /// 4. If mismatch, hardware value wins and UI updates again
  Future<void> setPerformancePageMapping(
    int slotIndex,
    int parameterNumber,
    int perfPageIndex,
  ) async {
    final currentState = _cubit.state;
    if (currentState is! DistingStateSynchronized) {
      return;
    }

    if (slotIndex >= currentState.slots.length) {
      return;
    }

    final disting = _cubit.requireDisting();

    // 1. Optimistic Update - Update local state immediately
    final slot = currentState.slots[slotIndex];

    if (parameterNumber >= slot.mappings.length) {
      return;
    }

    final originalMapping = slot.mappings[parameterNumber];
    final optimisticMapping = Mapping(
      algorithmIndex: originalMapping.algorithmIndex,
      parameterNumber: originalMapping.parameterNumber,
      packedMappingData: originalMapping.packedMappingData.copyWith(
        perfPageIndex: perfPageIndex,
      ),
    );

    // Emit optimistic state immediately for instant UI feedback
    _cubit._emitState(
      currentState.copyWith(
        slots: _cubit.updateSlot(slotIndex, currentState.slots, (slot) {
          return slot.copyWith(
            mappings: _cubit.replaceInList(
              slot.mappings,
              optimisticMapping,
              index: parameterNumber,
            ),
          );
        }),
      ),
    );

    // 2. Send update to hardware (non-blocking)
    disting
        .setPerformancePageMapping(slotIndex, parameterNumber, perfPageIndex)
        .catchError((e, s) {
          debugPrintStack(stackTrace: s);
        });

    // 3. Verify by reading back the specific parameter mapping with retry
    const maxRetries = 4; // Try up to 4 times
    const baseDelay = Duration(milliseconds: 100);
    bool verified = false;

    for (int attempt = 0; attempt < maxRetries && !verified; attempt++) {
      try {
        // Exponential backoff: 100ms, 200ms, 400ms, 800ms
        final delay = baseDelay * (1 << attempt);
        await Future.delayed(delay);

        final actualMapping = await disting.requestMappings(
          slotIndex,
          parameterNumber,
        );

        if (actualMapping == null) {
          continue; // Retry
        }

        // 4. If hardware value differs from optimistic value, hardware wins
        if (actualMapping.packedMappingData.perfPageIndex !=
            optimisticMapping.packedMappingData.perfPageIndex) {
          // Check if this is the last attempt
          if (attempt == maxRetries - 1) {
            // Last attempt - accept hardware value as final

            // Update UI with actual hardware value
            final verificationState = _cubit.state;
            if (verificationState is DistingStateSynchronized) {
              _cubit._emitState(
                verificationState.copyWith(
                  slots: _cubit.updateSlot(
                    slotIndex,
                    verificationState.slots,
                    (slot) {
                      return slot.copyWith(
                        mappings: _cubit.replaceInList(
                          slot.mappings,
                          actualMapping,
                          index: parameterNumber,
                        ),
                      );
                    },
                  ),
                ),
              );
            }
            verified = true;
          } else {
            // Not the last attempt - retry to see if hardware catches up
            continue;
          }
        } else {
          // Hardware matches optimistic value - success!
          verified = true;
        }
      } catch (e, stackTrace) {
        debugPrintStack(stackTrace: stackTrace);

        if (attempt == maxRetries - 1) {
          // Last attempt failed - log error
        }
      }
    }

    if (!verified) {
      // Revert to original mapping since we couldn't verify the change
      final revertState = _cubit.state;
      if (revertState is DistingStateSynchronized) {
        _cubit._emitState(
          revertState.copyWith(
            slots: _cubit.updateSlot(slotIndex, revertState.slots, (slot) {
              return slot.copyWith(
                mappings: _cubit.replaceInList(
                  slot.mappings,
                  originalMapping,
                  index: parameterNumber,
                ),
              );
            }),
          ),
        );
      }
    }
  }
}

