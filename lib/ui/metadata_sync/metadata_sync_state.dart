part of 'metadata_sync_cubit.dart';

@freezed
sealed class MetadataSyncState with _$MetadataSyncState {
  // Initial state, ready to start
  const factory MetadataSyncState.idle() = Idle;

  // --- Metadata Sync Specific States ---
  const factory MetadataSyncState.syncingMetadata({
    required double progress, // 0.0 to 1.0
    required String mainMessage, // e.g., "Processing Algorithm X (15/128)"
    required String subMessage, // e.g., "Adding to preset..."
    int? algorithmsProcessed, // Keep for progress calculation
    int? totalAlgorithms, // Keep for progress calculation
  }) = SyncingMetadata;
  const factory MetadataSyncState.checkpointFound({
    required String algorithmName,
    required int algorithmIndex,
  }) = CheckpointFound;
  const factory MetadataSyncState.metadataSyncSuccess(String message) =
      MetadataSyncSuccess;
  const factory MetadataSyncState.metadataSyncFailure(String error) =
      MetadataSyncFailure;

  // --- Preset Management Specific States ---
  const factory MetadataSyncState.savingPreset() = SavingPreset;
  const factory MetadataSyncState.loadingPreset() = LoadingPreset;
  const factory MetadataSyncState.presetSaveSuccess(String message) =
      PresetSaveSuccess;
  const factory MetadataSyncState.presetSaveFailure(String error) =
      PresetSaveFailure;
  const factory MetadataSyncState.presetLoadSuccess(String message) =
      PresetLoadSuccess;
  const factory MetadataSyncState.presetLoadFailure(String error) =
      PresetLoadFailure;

  // NEW: Preset Deletion States
  const factory MetadataSyncState.deletingPreset() = DeletingPreset;
  const factory MetadataSyncState.presetDeleteSuccess(String message) =
      PresetDeleteSuccess;
  const factory MetadataSyncState.presetDeleteFailure(String error) =
      PresetDeleteFailure;

  // --- Viewing Local Data State ---
  const factory MetadataSyncState.viewingLocalData({
    required List<AlgorithmEntry> algorithms,
    required Map<String, int> parameterCounts,
    required List<PresetEntry> presets,
  }) = ViewingLocalData;

  // Generic failure for operations other than sync/save/load (e.g. loading failure)
  const factory MetadataSyncState.failure(String error) = Failure;
}
