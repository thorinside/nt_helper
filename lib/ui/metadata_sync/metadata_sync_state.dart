part of 'metadata_sync_cubit.dart';

@freezed
class MetadataSyncState with _$MetadataSyncState {
  // Initial state, ready to start
  const factory MetadataSyncState.idle() = Idle;

  // Sync is in progress
  const factory MetadataSyncState.syncing({
    required double progress, // 0.0 to 1.0
    required String mainMessage, // e.g., "Processing Algorithm X (15/128)"
    required String subMessage, // e.g., "Adding to preset..."
    int? algorithmsProcessed, // Keep for progress calculation
    int? totalAlgorithms, // Keep for progress calculation
  }) = Syncing;

  // Sync completed successfully
  const factory MetadataSyncState.success(String message) = Success;

  // Sync failed
  const factory MetadataSyncState.failure(String error) = Failure;

  // NEW: State for viewing cached data
  const factory MetadataSyncState.viewingData({
    required List<AlgorithmEntry> algorithms,
    required Map<String, int> parameterCounts,
  }) = ViewingData;
}
