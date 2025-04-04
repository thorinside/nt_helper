import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:nt_helper/db/database.dart';
import 'package:nt_helper/domain/disting_midi_manager.dart';
import 'package:nt_helper/services/metadata_sync_service.dart';

part 'metadata_sync_state.dart';
part 'metadata_sync_cubit.freezed.dart';

class MetadataSyncCubit extends Cubit<MetadataSyncState> {
  final IDistingMidiManager _distingManager;
  final AppDatabase _database;
  late final MetadataSyncService _syncService;

  MetadataSyncCubit(this._distingManager, this._database)
      : super(const MetadataSyncState.idle()) {
    _syncService = MetadataSyncService(_distingManager, _database);
  }

  Future<void> startSync() async {
    if (state is Syncing) return; // Prevent concurrent syncs

    emit(const MetadataSyncState.syncing(
        progress: 0.0, message: "Starting sync..."));

    try {
      await _syncService.syncAllAlgorithmMetadata(
        onProgress: (progress, message) {
          if (state is Syncing) {
            emit(MetadataSyncState.syncing(
                progress: progress, message: message));
          }
        },
        onError: (error) {
          print("Error reported via callback: $error");
        },
      );
      if (state is Syncing) {
        emit(const MetadataSyncState.success(
            "Metadata synchronization complete!"));
      }
    } catch (e) {
      if (state is Syncing) {
        emit(MetadataSyncState.failure("Sync failed: ${e.toString()}"));
      }
    }
  }

  void reset() {
    emit(const MetadataSyncState.idle());
  }
}
