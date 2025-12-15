part of 'disting_cubit.dart';

mixin _DistingCubitAlgorithmOps on _DistingCubitBase {
  CancelableOperation<void>? _moveVerificationOperation;
  CancelableOperation<void>? _addAlgorithmVerificationOperation;

  String _deriveOptimisticAlgorithmNameForAdd({
    required String algorithmGuid,
    required String baseName,
    required List<Slot> existingSlots,
  }) {
    final used = <int>{};

    for (final slot in existingSlots) {
      final a = slot.algorithm;
      if (a.guid != algorithmGuid) continue;

      if (a.name == baseName) {
        used.add(1);
        continue;
      }

      final match = RegExp('^${RegExp.escape(baseName)}\\((\\d+)\\)\$')
          .firstMatch(a.name);
      if (match == null) continue;
      final n = int.tryParse(match.group(1) ?? '');
      if (n != null && n >= 2) {
        used.add(n);
      }
    }

    if (!used.contains(1)) return baseName;

    var i = 2;
    while (used.contains(i)) {
      i++;
    }
    return '$baseName($i)';
  }

  Slot _createPlaceholderSlotForAdd({
    required int slotIndex,
    required AlgorithmInfo algorithm,
    required List<Slot> existingSlots,
  }) {
    final displayName = _deriveOptimisticAlgorithmNameForAdd(
      algorithmGuid: algorithm.guid,
      baseName: algorithm.name,
      existingSlots: existingSlots,
    );

    return Slot(
      algorithm: Algorithm(
        algorithmIndex: slotIndex,
        guid: algorithm.guid,
        name: displayName,
        specifications: algorithm.specifications
            .map((s) => s.defaultValue)
            .toList(),
      ),
      routing: RoutingInfo(
        algorithmIndex: slotIndex,
        routingInfo: List.filled(6, 0),
      ),
      pages: ParameterPages(algorithmIndex: slotIndex, pages: const []),
      parameters: const [],
      values: const [],
      enums: const [],
      mappings: const [],
      valueStrings: const [],
    );
  }

  Future<void> onAlgorithmSelectedImpl(
    AlgorithmInfo algorithm,
    List<int> specifications,
  ) async {
    switch (state) {
      case DistingStateInitial():
      case DistingStateSelectDevice():
      case DistingStateConnected():
        break;
      case DistingStateSynchronized syncstate:
        final disting = syncstate.disting;
        List<int> specsToSend = specifications;

        // *** Adjust for offline: Use stored default specs if offline ***
        if (syncstate.offline) {
          final storedAlgoInfo = syncstate.algorithms.firstWhereOrNull(
            (a) => a.guid == algorithm.guid,
          );
          if (storedAlgoInfo != null) {
            specsToSend = storedAlgoInfo.specifications
                .map((s) => s.defaultValue)
                .toList();
          } else {}
        }

        // An algorithm can only be added to the next empty slot, so we can be
        // optimistic and only reconcile the newly-added slot.
        final newSlotIndex = syncstate.slots.length;

        // 1) Optimistic placeholder slot for instant UI feedback
        final placeholder = _createPlaceholderSlotForAdd(
          slotIndex: newSlotIndex,
          algorithm: algorithm,
          existingSlots: syncstate.slots,
        );
        final expectedPlaceholderName = placeholder.algorithm.name;
        emit(
          syncstate.copyWith(
            slots: [...syncstate.slots, placeholder],
            loading: false,
          ),
        );

        // 2) Send the add algorithm request
        try {
          await disting.requestAddAlgorithm(algorithm, specsToSend);
        } catch (e, stackTrace) {
          debugPrintStack(stackTrace: stackTrace);
          // Roll back optimistic slot if still present
          final st = state;
          if (st is DistingStateSynchronized &&
              st.slots.length == syncstate.slots.length + 1) {
            emit(st.copyWith(slots: List<Slot>.from(st.slots)..removeLast()));
          }
          return;
        }

        // 3) Verification/reconciliation: fetch only the new slot and correct if needed.
        _addAlgorithmVerificationOperation?.cancel();
        _addAlgorithmVerificationOperation = CancelableOperation.fromFuture(
          Future.delayed(const Duration(milliseconds: 700), () async {
            final current = state;
            if (current is! DistingStateSynchronized) return;

            // Only proceed if the state still reflects our optimistic add.
            if (current.slots.length != newSlotIndex + 1) return;
            if (current.slots[newSlotIndex].algorithm.guid != algorithm.guid) {
              return;
            }
            if (current.slots[newSlotIndex].algorithm.name !=
                expectedPlaceholderName) {
              return;
            }

            // Retry fetching just the new slot a few times; the module may need a moment.
            Slot? fetched;
            for (final delay in const [
              Duration(milliseconds: 0),
              Duration(milliseconds: 400),
              Duration(milliseconds: 900),
            ]) {
              if (delay != Duration.zero) {
                await Future.delayed(delay);
              }
              try {
                fetched = await fetchSlot(disting, newSlotIndex);
                break;
              } catch (_) {
                // Try again
              }
            }

            if (fetched != null) {
              final verified = state;
              if (verified is! DistingStateSynchronized) return;
              if (verified.slots.length != newSlotIndex + 1) return;
              final updatedSlots =
                  updateSlot(newSlotIndex, verified.slots, (_) => fetched!);
              emit(verified.copyWith(slots: updatedSlots, loading: false));
              return;
            }

            // If we couldn't fetch the new slot, reconcile minimally via slot count.
            try {
              final actualCount = await disting.requestNumAlgorithmsInPreset();
              if (actualCount == syncstate.slots.length) {
                // Device didn't add: remove placeholder.
                final verified = state;
                if (verified is! DistingStateSynchronized) return;
                if (verified.slots.length == syncstate.slots.length + 1) {
                  emit(
                    verified.copyWith(
                      slots: List<Slot>.from(verified.slots)..removeLast(),
                      loading: false,
                    ),
                  );
                }
              }
            } catch (_) {
              // If even verification fails, do nothing; user can manual refresh.
            }
          }),
          onCancel: () {},
        );
        break;
    }
  }

  Future<void> onRemoveAlgorithmImpl(int algorithmIndex) async {
    switch (state) {
      case DistingStateInitial():
      case DistingStateSelectDevice():
      case DistingStateConnected():
        break;
      case DistingStateSynchronized syncstate:
        // Cancel any pending verification from a previous operation
        _moveVerificationOperation?.cancel();

        // 1. Optimistic Update - Remove the slot and fix indices
        List<Slot> optimisticSlots = List.from(syncstate.slots);
        optimisticSlots.removeAt(algorithmIndex);

        // Fix algorithm indices for all slots after the removed one
        for (int i = algorithmIndex; i < optimisticSlots.length; i++) {
          optimisticSlots[i] = _fixAlgorithmIndex(optimisticSlots[i], i);
        }

        // Emit optimistic state
        emit(syncstate.copyWith(slots: optimisticSlots, loading: false));

        // 2. Manager Request
        final disting = requireDisting();
        // Don't await here, let it run in the background
        disting.requestRemoveAlgorithm(algorithmIndex).catchError((e, s) {
          // Refresh immediately on error
          _refreshStateFromManager(delay: Duration.zero);
        });

        // 3. Verification
        _moveVerificationOperation = CancelableOperation.fromFuture(
          Future.delayed(const Duration(seconds: 2), () async {
            // Check if state is still synchronized before proceeding
            if (state is! DistingStateSynchronized) return;
            final verificationState = state as DistingStateSynchronized;

            // Only verify if the current state still matches the optimistic one we emitted
            final eq = const DeepCollectionEquality();
            if (!eq.equals(verificationState.slots, optimisticSlots)) {
              return;
            }

            try {
              // Check if the number of algorithms matches our optimistic state
              final actualNumAlgorithms =
                  await disting.requestNumAlgorithmsInPreset() ?? 0;
              if (actualNumAlgorithms != optimisticSlots.length) {
                await _refreshStateFromManager(delay: Duration.zero);
                return;
              }

              // Verify GUIDs and Names for remaining slots
              bool mismatchDetected = false;
              for (int i = 0; i < optimisticSlots.length; i++) {
                final actualAlgorithm = await disting.requestAlgorithmGuid(i);
                final optimisticAlgorithm = optimisticSlots[i].algorithm;

                if (actualAlgorithm == null ||
                    actualAlgorithm.guid != optimisticAlgorithm.guid ||
                    actualAlgorithm.name != optimisticAlgorithm.name) {
                  mismatchDetected = true;
                  break;
                }
              }

              if (mismatchDetected) {
                await _refreshStateFromManager(delay: Duration.zero);
              } else {}
            } catch (e, stackTrace) {
              debugPrintStack(stackTrace: stackTrace);
              await _refreshStateFromManager(delay: Duration.zero);
            }
          }),
          onCancel: () {},
        );
        break;
    }
  }

  Future<int> moveAlgorithmUpImpl(int algorithmIndex) async {
    final currentState = state;
    if (currentState is! DistingStateSynchronized) return algorithmIndex;
    if (algorithmIndex == 0) return 0;

    // Cancel any pending verification from a previous move
    _moveVerificationOperation?.cancel();

    final syncstate = currentState;
    final slots = syncstate.slots;

    // 1. Optimistic Update
    // Identify the two slots involved in the swap
    final slotToMove = slots[algorithmIndex];
    final slotToSwapWith = slots[algorithmIndex - 1];

    // Create corrected versions with updated internal indices
    final correctedMovedSlot = _fixAlgorithmIndex(
      slotToMove,
      algorithmIndex - 1,
    );
    final correctedSwappedSlot = _fixAlgorithmIndex(
      slotToSwapWith,
      algorithmIndex,
    );

    // Build the new list with only the swapped slots corrected and reordered
    List<Slot> optimisticSlotsCorrected = List.from(slots); // Start with a copy
    optimisticSlotsCorrected[algorithmIndex - 1] =
        correctedMovedSlot; // Moved slot goes to the upper position
    optimisticSlotsCorrected[algorithmIndex] =
        correctedSwappedSlot; // Swapped slot goes to the lower position

    // Emit optimistic state
    emit(syncstate.copyWith(slots: optimisticSlotsCorrected, loading: false));

    // 2. Manager Request
    final disting = requireDisting();
    // Don't await here, let it run in the background
    disting.requestMoveAlgorithmUp(algorithmIndex).catchError((e, s) {
      // Optionally trigger a full refresh on error?
      _refreshStateFromManager(delay: Duration.zero);
    });

    // 3. Verification
    _moveVerificationOperation = CancelableOperation.fromFuture(
      Future.delayed(const Duration(seconds: 2), () async {
        // Check if state is still synchronized before proceeding
        if (state is! DistingStateSynchronized) return;
        final verificationState = state as DistingStateSynchronized;

        // Only verify if the current state *still* matches the optimistic one we emitted.
        // If it changed due to user interaction or another update, the verification is moot.
        // Use a deep equality check for the slots.
        final eq = const DeepCollectionEquality();
        if (!eq.equals(verificationState.slots, optimisticSlotsCorrected)) {
          return;
        }

        try {
          // --- Verification: Check GUIDs and Names ---
          bool mismatchDetected = false;
          for (int i = 0; i < optimisticSlotsCorrected.length; i++) {
            final actualAlgorithm = await disting.requestAlgorithmGuid(i);
            final optimisticAlgorithm = optimisticSlotsCorrected[i].algorithm;

            // Compare GUID and Name
            if (actualAlgorithm == null ||
                actualAlgorithm.guid != optimisticAlgorithm.guid ||
                actualAlgorithm.name != optimisticAlgorithm.name) {
              mismatchDetected = true;
              break; // No need to check further
            }
          }
          // --- End Verification ---

          if (mismatchDetected) {
            // If mismatch, only fetch the actual slots, keep other metadata.
            final actualSlots = await fetchSlots(
              optimisticSlotsCorrected.length,
              disting,
            );

            emit(
              DistingState.synchronized(
                disting: verificationState.disting,
                // Keep manager and other state
                distingVersion: verificationState.distingVersion,
                firmwareVersion: verificationState.firmwareVersion,
                presetName: verificationState.presetName,
                // Use existing preset name
                algorithms: verificationState.algorithms,
                slots: actualSlots,
                // Use actual slots
                unitStrings: verificationState.unitStrings,
                inputDevice: verificationState.inputDevice,
                outputDevice: verificationState.outputDevice,
                screenshot: verificationState.screenshot,
                loading: false,
                demo: verificationState.demo,
                offline: verificationState.offline,
              ),
            );
          } else {}
        } catch (e, stackTrace) {
          debugPrintStack(stackTrace: stackTrace);
          _refreshStateFromManager(delay: Duration.zero);
        }
      }),
      onCancel: () {},
    );

    // 4. Return optimistic index
    return algorithmIndex - 1;
  }

  Future<int> moveAlgorithmDownImpl(int algorithmIndex) async {
    final currentState = state;
    if (currentState is! DistingStateSynchronized) return algorithmIndex;
    final syncstate = currentState;
    final slots = syncstate.slots;
    if (algorithmIndex >= slots.length - 1) return algorithmIndex;

    // Cancel any pending verification from a previous move
    _moveVerificationOperation?.cancel();

    // 1. Optimistic Update
    // Identify the two slots involved in the swap
    final slotToMove = slots[algorithmIndex];
    final slotToSwapWith = slots[algorithmIndex + 1];

    // Create corrected versions with updated internal indices
    final correctedMovedSlot = _fixAlgorithmIndex(
      slotToMove,
      algorithmIndex + 1,
    );
    final correctedSwappedSlot = _fixAlgorithmIndex(
      slotToSwapWith,
      algorithmIndex,
    );

    // Build the new list with only the swapped slots corrected and reordered
    List<Slot> optimisticSlotsCorrected = List.from(slots); // Start with a copy
    optimisticSlotsCorrected[algorithmIndex] =
        correctedSwappedSlot; // Swapped slot goes to the upper position
    optimisticSlotsCorrected[algorithmIndex + 1] =
        correctedMovedSlot; // Moved slot goes to the lower position

    // Emit optimistic state
    emit(syncstate.copyWith(slots: optimisticSlotsCorrected, loading: false));

    // 2. Manager Request
    final disting = requireDisting();
    // Don't await here, let it run in the background
    disting.requestMoveAlgorithmDown(algorithmIndex).catchError((e, s) {
      _refreshStateFromManager(delay: Duration.zero);
    });

    // 3. Verification
    _moveVerificationOperation = CancelableOperation.fromFuture(
      Future.delayed(const Duration(seconds: 2), () async {
        if (state is! DistingStateSynchronized) return;
        final verificationState = state as DistingStateSynchronized;

        final eq = const DeepCollectionEquality();
        if (!eq.equals(verificationState.slots, optimisticSlotsCorrected)) {
          return;
        }

        try {
          // --- Verification: Check GUIDs and Names ---
          bool mismatchDetected = false;
          for (int i = 0; i < optimisticSlotsCorrected.length; i++) {
            final actualAlgorithm = await disting.requestAlgorithmGuid(i);
            final optimisticAlgorithm = optimisticSlotsCorrected[i].algorithm;

            // Compare GUID and Name
            if (actualAlgorithm == null ||
                actualAlgorithm.guid != optimisticAlgorithm.guid ||
                actualAlgorithm.name != optimisticAlgorithm.name) {
              mismatchDetected = true;
              break; // No need to check further
            }
          }
          // --- End Verification ---

          if (mismatchDetected) {
            // If mismatch, only fetch the actual slots, keep other metadata.
            final actualSlots = await fetchSlots(
              optimisticSlotsCorrected.length,
              disting,
            );

            emit(
              DistingState.synchronized(
                disting: verificationState.disting,
                // Keep manager and other state
                distingVersion: verificationState.distingVersion,
                firmwareVersion: verificationState.firmwareVersion,
                presetName: verificationState.presetName,
                // Use existing preset name
                algorithms: verificationState.algorithms,
                slots: actualSlots,
                // Use actual slots
                unitStrings: verificationState.unitStrings,
                inputDevice: verificationState.inputDevice,
                outputDevice: verificationState.outputDevice,
                screenshot: verificationState.screenshot,
                loading: false,
                demo: verificationState.demo,
                offline: verificationState.offline,
              ),
            );
          } else {}
        } catch (e, stackTrace) {
          debugPrintStack(stackTrace: stackTrace);
          _refreshStateFromManager(delay: Duration.zero);
        }
      }),
      onCancel: () {},
    );

    // 4. Return optimistic index
    return algorithmIndex + 1;
  }
}
