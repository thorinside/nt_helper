part of 'disting_cubit.dart';

mixin _DistingCubitSlotOps on _DistingCubitBase {
  final Map<int, CancelableOperation<void>> _renameSlotVerificationOperations =
      {};

  void renameSlotImpl(int algorithmIndex, String newName) async {
    final currentState = state;
    if (currentState is DistingStateSynchronized) {
      if (algorithmIndex < 0 || algorithmIndex >= currentState.slots.length) {
        return;
      }

      final trimmed = newName.trim();
      if (trimmed.isEmpty) return;

      final slot = currentState.slots[algorithmIndex];
      final currentAlgorithm = slot.algorithm;
      if (trimmed == currentAlgorithm.name) return;

      // 1) Optimistic update for instant UI response
      final optimisticAlgorithm = Algorithm(
        algorithmIndex: currentAlgorithm.algorithmIndex,
        guid: currentAlgorithm.guid,
        name: trimmed,
        specifications: currentAlgorithm.specifications,
      );
      final optimisticSlots = updateSlot(
        algorithmIndex,
        currentState.slots,
        (s) => s.copyWith(algorithm: optimisticAlgorithm),
      );
      emit(currentState.copyWith(slots: optimisticSlots, loading: false));

      // 2) Send request in background
      final disting = requireDisting();
      disting.requestSendSlotName(algorithmIndex, trimmed).catchError((e, s) {
        // If send fails, let the verification pass reconcile state.
      });

      // 3) Verification: read back just this slot's Algorithm and correct if needed.
      _renameSlotVerificationOperations[algorithmIndex]?.cancel();
      _renameSlotVerificationOperations[algorithmIndex] =
          CancelableOperation.fromFuture(
            Future.delayed(const Duration(milliseconds: 750), () async {
              if (state is! DistingStateSynchronized) return;
              final verificationState = state as DistingStateSynchronized;

              // Only proceed if the slot still exists and still matches our optimistic edit.
              if (algorithmIndex < 0 ||
                  algorithmIndex >= verificationState.slots.length) {
                return;
              }

              final currentSlot = verificationState.slots[algorithmIndex];
              if (currentSlot.algorithm.guid != currentAlgorithm.guid) return;
              if (currentSlot.algorithm.name != trimmed) return;

              final actual = await disting.requestAlgorithmGuid(algorithmIndex);
              if (actual == null) return;

              // If the device accepted it, the name should match. Otherwise, correct locally.
              if (actual.name != trimmed) {
                final correctedSlots = updateSlot(
                  algorithmIndex,
                  verificationState.slots,
                  (s) => s.copyWith(algorithm: actual),
                );
                emit(verificationState.copyWith(slots: correctedSlots));
              }
            }),
            onCancel: () {},
          );
    }
  }
}
