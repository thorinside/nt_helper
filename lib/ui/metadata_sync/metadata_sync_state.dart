part of 'metadata_sync_cubit.dart';

@freezed
class MetadataSyncState with _$MetadataSyncState {
  // Initial state, ready to start
  const factory MetadataSyncState.idle() = Idle;

  // Sync is in progress
  const factory MetadataSyncState.syncing({
    required double progress, // 0.0 to 1.0
    required String message,
  }) = Syncing;

  // Sync completed successfully
  const factory MetadataSyncState.success(String message) = Success;

  // Sync failed
  const factory MetadataSyncState.failure(String error) = Failure;
}
