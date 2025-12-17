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
    if (currentState is DistingStateSynchronized) {
      final trimmed = newName.trim();
      if (trimmed.isEmpty || trimmed == currentState.presetName) return;

      // 1) Optimistic update for instant UI response
      emit(currentState.copyWith(presetName: trimmed, loading: false));

      // 2) Send request in background (works for online + offline managers)
      final disting = currentState.disting;
      disting.requestSetPresetName(trimmed).catchError((e, s) {
        // If rename fails, fall back to device truth via a lightweight read.
        _renamePresetVerificationOperation?.cancel();
        _renamePresetVerificationOperation = CancelableOperation.fromFuture(
          Future.delayed(const Duration(milliseconds: 250), () async {
            if (state is! DistingStateSynchronized) return;
            final verificationState = state as DistingStateSynchronized;
            final actual = await disting.requestPresetName();
            if (actual == null) return;
            if (verificationState.presetName != actual) {
              emit(verificationState.copyWith(presetName: actual));
            }
          }),
          onCancel: () {},
        );
      });

      // 3) Verification (lightweight): read name back and correct if needed.
      _renamePresetVerificationOperation?.cancel();
      _renamePresetVerificationOperation = CancelableOperation.fromFuture(
        Future.delayed(const Duration(milliseconds: 500), () async {
          if (state is! DistingStateSynchronized) return;
          final verificationState = state as DistingStateSynchronized;
          if (verificationState.presetName != trimmed) return;

          final actual = await disting.requestPresetName();
          if (actual == null) return;
          if (actual != trimmed) {
            emit(verificationState.copyWith(presetName: actual));
          }
        }),
        onCancel: () {},
      );
    }
  }
}
