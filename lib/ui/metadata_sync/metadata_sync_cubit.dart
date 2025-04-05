import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:nt_helper/db/database.dart';
import 'package:nt_helper/db/daos/metadata_dao.dart';
import 'package:nt_helper/domain/disting_midi_manager.dart';
import 'package:nt_helper/services/metadata_sync_service.dart';

part 'metadata_sync_state.dart';
part 'metadata_sync_cubit.freezed.dart';

class MetadataSyncCubit extends Cubit<MetadataSyncState> {
  final IDistingMidiManager? _distingManager;
  final AppDatabase _database;
  late final MetadataSyncService _metadataSyncService;
  late final MetadataDao _metadataDao;

  // Cancellation flag
  bool _isCancelled = false;

  MetadataSyncCubit(
    this._distingManager,
    this._database,
  ) : super(const MetadataSyncState.idle()) {
    _metadataDao = _database.metadataDao;
    if (_distingManager != null) {
      _metadataSyncService = MetadataSyncService(_distingManager!, _database);
    }
  }

  Future<void> startSync() async {
    if (state.maybeMap(syncing: (_) => true, orElse: () => false)) return;
    if (_distingManager == null) {
      emit(const MetadataSyncState.failure(
          "Cannot sync: Disting connection not available."));
      return;
    }

    _isCancelled = false; // Reset cancellation flag at the start

    emit(const MetadataSyncState.syncing(
      progress: 0.0,
      mainMessage: "Initializing sync...",
      subMessage: "Preparing...",
      algorithmsProcessed: 0,
      totalAlgorithms: 0,
    ));

    bool errorOccurred = false;
    String finalMessage = "Sync completed successfully.";

    await _metadataSyncService.syncAllAlgorithmMetadata(
      onProgress: (progress, processed, total, mainMsg, subMsg) {
        if (!isClosed && !_isCancelled) {
          // Only emit if not cancelled
          emit(MetadataSyncState.syncing(
            progress: progress,
            mainMessage: mainMsg,
            subMessage: subMsg,
            algorithmsProcessed: processed,
            totalAlgorithms: total,
          ));
        }
      },
      onError: (error) {
        if (!_isCancelled) {
          // Only track error if not cancelled
          errorOccurred = true;
          finalMessage = error;
        }
      },
      // Pass the cancellation check callback
      isCancelled: () => _isCancelled,
    );

    // Emit final state
    if (!isClosed) {
      if (_isCancelled) {
        emit(const MetadataSyncState.failure("Sync cancelled by user."));
      } else if (errorOccurred) {
        emit(MetadataSyncState.failure(finalMessage));
      } else {
        emit(MetadataSyncState.success(finalMessage));
      }
    }
  }

  // Method to request cancellation
  void cancelSync() {
    if (state.maybeMap(syncing: (_) => true, orElse: () => false)) {
      _isCancelled = true;
      // Optionally emit a specific "Cancelling..." state immediately
      // emit(state.copyWith(subMessage: "Cancelling...")); // Need copyWith from freezed
      print("[MetadataSyncCubit] Cancellation requested.");
    }
  }

  Future<void> viewSyncedData() async {
    final isSyncing = state.maybeMap(syncing: (_) => true, orElse: () => false);
    if (isSyncing) return;

    emit(const MetadataSyncState.syncing(
      progress: 0.0,
      mainMessage: "Loading Synced Data",
      subMessage: "Please wait...",
    ));

    try {
      final results = await Future.wait([
        _metadataDao.getAllAlgorithms(),
        _metadataDao.getAlgorithmParameterCounts(),
      ]);

      final algorithms = results[0] as List<AlgorithmEntry>;
      final parameterCounts = results[1] as Map<String, int>;

      if (algorithms.isEmpty) {
        emit(const MetadataSyncState.failure(
            "No algorithm metadata found in the database."));
      } else {
        emit(MetadataSyncState.viewingData(
          algorithms: algorithms,
          parameterCounts: parameterCounts,
        ));
      }
    } catch (e, stacktrace) {
      print('Error loading synced data: $e\n$stacktrace');
      emit(MetadataSyncState.failure(
          "Failed to load data from DB: ${e.toString()}"));
    }
  }

  void reset() {
    _isCancelled = false; // Ensure cancelled is reset
    emit(const MetadataSyncState.idle());
  }
}
