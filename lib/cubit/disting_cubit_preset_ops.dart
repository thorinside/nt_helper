part of 'disting_cubit.dart';

mixin _DistingCubitPresetOps on _DistingCubitBase {
  CancelableOperation<void>? _renamePresetVerificationOperation;

  Future<void> newPresetImpl() async {
    final currentState = state;
    if (currentState is DistingStateSynchronized) {
      final disting = requireDisting();
      await disting.requestNewPreset();
      await _refreshStateFromManager();
    }
  }

  Future<void> loadPresetImpl(String name, bool append) async {
    final currentState = state;
    if (currentState is DistingStateSynchronized) {
      // Prevent online load preset when offline
      if (currentState.offline) {
        return;
      }
      final disting = requireDisting();

      emit(currentState.copyWith(loading: true));

      await disting.requestLoadPreset(name, append);

      await _refreshStateFromManager();
    }
  }

  void renamePresetImpl(String newName) async {
    final currentState = state;
    if (currentState is! DistingStateSynchronized) return;

    final trimmed = newName.trim();
    // 1. Basic validation: no empty names, and no-op if name is unchanged
    if (trimmed.isEmpty || trimmed == currentState.presetName) return;

    // 2. Hardware limit: max 31 chars (plus null terminator).
    // We truncate to ensure the hardware doesn't reject or behave unpredictably.
    final finalName = trimmed.length > 31 ? trimmed.substring(0, 31) : trimmed;

    // 3. Final check: if truncation resulted in the same name, skip the write.
    if (finalName == currentState.presetName) return;

    // Optimistic update
    emit(currentState.copyWith(
      presetName: finalName,
      isDirty: true,
    ));

    final disting = currentState.disting;
    disting.requestSetPresetName(finalName).then((_) {
      disting.requestSavePreset().catchError((_) {});
    }, onError: (e, s) {
      // Revert to device truth if the request failed
      _renamePresetVerificationOperation?.cancel();
      _renamePresetVerificationOperation = CancelableOperation.fromFuture(
        Future.delayed(const Duration(milliseconds: 250), () async {
          final syncState = state;
          if (syncState is! DistingStateSynchronized) return;
          final actual = await disting.requestPresetName();
          final latestState = state;
          if (actual != null &&
              latestState is DistingStateSynchronized &&
              latestState.presetName != actual) {
            emit(latestState.copyWith(presetName: actual));
          }
        }),
        onCancel: () {},
      );
    });

    // Verification loop to ensure the name actually took
    _renamePresetVerificationOperation?.cancel();
    _renamePresetVerificationOperation = CancelableOperation.fromFuture(
      Future.delayed(const Duration(milliseconds: 500), () async {
        final syncState = state;
        if (syncState is! DistingStateSynchronized) return;
        final actual = await disting.requestPresetName();
        final latestState = state;
        if (actual != null &&
            latestState is DistingStateSynchronized &&
            latestState.presetName != actual) {
          emit(latestState.copyWith(presetName: actual));
        }
      }),
      onCancel: () {},
    );
  }
}
