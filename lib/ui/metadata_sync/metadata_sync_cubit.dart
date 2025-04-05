import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:nt_helper/db/database.dart';
import 'package:nt_helper/db/daos/metadata_dao.dart';
import 'package:nt_helper/db/daos/presets_dao.dart';
import 'package:nt_helper/domain/disting_midi_manager.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'package:nt_helper/models/packed_mapping_data.dart';
import 'package:nt_helper/services/metadata_sync_service.dart';

part 'metadata_sync_state.dart';
part 'metadata_sync_cubit.freezed.dart';

class MetadataSyncCubit extends Cubit<MetadataSyncState> {
  final IDistingMidiManager? _distingManager;
  final AppDatabase _database;
  late final MetadataSyncService _metadataSyncService;
  late final MetadataDao _metadataDao;
  late final PresetsDao _presetsDao;

  // Cancellation flag for metadata sync
  bool _isMetadataSyncCancelled = false;

  MetadataSyncCubit(
    this._distingManager,
    this._database,
  ) : super(const MetadataSyncState.idle()) {
    _metadataDao = _database.metadataDao;
    _presetsDao = _database.presetsDao;
    if (_distingManager != null) {
      _metadataSyncService = MetadataSyncService(_distingManager!, _database);
    }
  }

  // --- Metadata Sync Methods ---

  Future<void> startMetadataSync() async {
    if (state.maybeMap(syncingMetadata: (_) => true, orElse: () => false))
      return;
    if (_distingManager == null) {
      emit(const MetadataSyncState.metadataSyncFailure(
          "Cannot sync: Disting connection not available."));
      return;
    }

    _isMetadataSyncCancelled = false; // Reset cancellation flag

    emit(const MetadataSyncState.syncingMetadata(
      progress: 0.0,
      mainMessage: "Initializing sync...",
      subMessage: "Preparing...",
    ));

    bool errorOccurred = false;
    String finalMessage = "Metadata sync completed successfully.";

    await _metadataSyncService.syncAllAlgorithmMetadata(
      onProgress: (progress, processed, total, mainMsg, subMsg) {
        if (!isClosed && !_isMetadataSyncCancelled) {
          emit(MetadataSyncState.syncingMetadata(
            progress: progress,
            mainMessage: mainMsg,
            subMessage: subMsg,
            algorithmsProcessed: processed,
            totalAlgorithms: total,
          ));
        }
      },
      onError: (error) {
        if (!_isMetadataSyncCancelled) {
          errorOccurred = true;
          finalMessage = "Metadata Sync Failed: $error";
        }
      },
      isCancelled: () => _isMetadataSyncCancelled,
    );

    if (!isClosed) {
      if (_isMetadataSyncCancelled) {
        emit(const MetadataSyncState.metadataSyncFailure(
            "Metadata sync cancelled by user."));
      } else if (errorOccurred) {
        emit(MetadataSyncState.metadataSyncFailure(finalMessage));
      } else {
        emit(MetadataSyncState.metadataSyncSuccess(finalMessage));
      }
    }
  }

  void cancelMetadataSync() {
    if (state.maybeMap(syncingMetadata: (_) => true, orElse: () => false)) {
      _isMetadataSyncCancelled = true;
      print("[MetadataSyncCubit] Metadata sync cancellation requested.");
    }
  }

  // --- Preset Management Methods ---

  Future<void> saveCurrentPreset() async {
    if (_distingManager == null) {
      emit(const MetadataSyncState.presetSaveFailure(
          "Cannot save: Disting connection not available."));
      return;
    }
    if (state.maybeMap(
        savingPreset: (_) => true,
        loadingPreset: (_) => true,
        orElse: () => false)) {
      return; // Prevent concurrent operations
    }

    emit(const MetadataSyncState.savingPreset());
    try {
      // TODO: Implement logic to fetch full preset details from _distingManager
      // This involves fetching name, num slots, then fetching each slot's data
      // (algo guid, parameters, values, mappings etc.) similar to DistingCubit.fetchSlots
      // For now, we'll just simulate success/failure

      // Placeholder: Fetch name and assume 1 slot for simulation
      final name =
          await _distingManager!.requestPresetName() ?? "Unnamed Preset";
      await Future.delayed(Duration(seconds: 1)); // Simulate work

      // Placeholder: Create dummy preset details
      final now = DateTime.now();
      final dummyDetails = FullPresetDetails(
        preset: PresetEntry(id: 0, name: name, lastModified: now),
        slots: [], // Add dummy SlotSaveData if needed for testing
      );

      await _presetsDao.saveFullPreset(dummyDetails);

      emit(
          MetadataSyncState.presetSaveSuccess("Preset '$name' saved locally."));
    } catch (e, stacktrace) {
      print("Error saving preset: $e\n$stacktrace");
      emit(MetadataSyncState.presetSaveFailure(
          "Failed to save preset: ${e.toString()}"));
    }
  }

  Future<void> loadPresetToDevice(int presetId) async {
    if (_distingManager == null) {
      emit(const MetadataSyncState.presetLoadFailure(
          "Cannot load: Disting connection not available."));
      return;
    }
    if (state.maybeMap(
        savingPreset: (_) => true,
        loadingPreset: (_) => true,
        orElse: () => false)) {
      return; // Prevent concurrent operations
    }

    emit(const MetadataSyncState.loadingPreset());
    try {
      final presetDetails = await _presetsDao.getFullPresetDetails(presetId);
      if (presetDetails == null) {
        throw Exception("Preset with ID $presetId not found locally.");
      }

      // TODO: Implement logic to send preset to device via _distingManager
      // 1. Send NewPreset
      // 2. Loop through presetDetails.slots:
      //    a. Get default specs for algo GUID from _metadataDao
      //    b. Send AddAlgorithm with default specs
      // 3. Wait briefly
      // 4. Loop through slots again:
      //    a. Set Parameter Values
      //    b. Set Mappings (optional)
      //    c. Set Slot Name (optional)
      // 5. Set Preset Name

      await Future.delayed(Duration(seconds: 2)); // Simulate work

      emit(MetadataSyncState.presetLoadSuccess(
          "Preset '${presetDetails.preset.name}' loaded to device."));
    } catch (e, stacktrace) {
      print("Error loading preset to device: $e\n$stacktrace");
      emit(MetadataSyncState.presetLoadFailure(
          "Failed to load preset to device: ${e.toString()}"));
    }
  }

  Future<void> loadLocalData() async {
    final isBusy = state.maybeMap(
        syncingMetadata: (_) => true,
        savingPreset: (_) => true,
        loadingPreset: (_) => true,
        orElse: () => false);
    if (isBusy) return;

    // Use a generic loading state or specific one?
    // Let's reuse loadingPreset for simplicity for now.
    emit(const MetadataSyncState.loadingPreset()); // Indicate general loading

    try {
      // Fetch both metadata and presets
      final results = await Future.wait([
        _metadataDao.getAllAlgorithms(),
        _metadataDao.getAlgorithmParameterCounts(),
        _presetsDao.getAllPresets(),
      ]);

      final algorithms = results[0] as List<AlgorithmEntry>;
      final parameterCounts = results[1] as Map<String, int>;
      final presets = results[2] as List<PresetEntry>;

      emit(MetadataSyncState.viewingLocalData(
        algorithms: algorithms,
        parameterCounts: parameterCounts,
        presets: presets,
      ));
    } catch (e, stacktrace) {
      print('Error loading local data: $e\n$stacktrace');
      emit(MetadataSyncState.failure(
          "Failed to load local data: ${e.toString()}"));
    }
  }

  void reset() {
    _isMetadataSyncCancelled = false; // Ensure cancelled is reset
    emit(const MetadataSyncState.idle());
  }

  // Helper method to fetch data for a single slot needed for saving
  Future<FullPresetSlot> _fetchPresetSlotDetails(int slotIndex) async {
    // Ensure manager exists (already checked in caller, but good practice)
    if (_distingManager == null) throw Exception("Disting manager is null");

    // Fetch Algorithm GUID and Name (which includes custom name if set)
    final algoGuidResult =
        await _distingManager!.requestAlgorithmGuid(slotIndex);
    final guid = algoGuidResult?.guid;
    // Use the name from the returned Algorithm object as the potential custom name
    final String? customName = algoGuidResult?.name;

    if (guid == null) {
      throw Exception("Failed to get algorithm GUID for slot $slotIndex.");
    }

    // Fetch AlgorithmEntry from Metadata DB (needed for FullPresetSlot structure)
    // We still need the base algorithm info (like numSpecifications if required by DAO)
    // Let's assume we just need the GUID for saving, but need the entry for structure.
    // A method like `getAlgorithmByGuid` might be better if available.
    final algoMetadata = await _metadataDao.getFullAlgorithmDetails(guid);
    if (algoMetadata == null) {
      throw Exception(
          "Algorithm metadata for GUID '$guid' not found in local DB. Please sync metadata first.");
    }
    final algorithmEntry = algoMetadata.algorithm; // Base algorithm info

    // Fetch Parameter Values
    final paramValuesResult =
        await _distingManager!.requestAllParameterValues(slotIndex);
    final parameterValues = paramValuesResult?.values ?? [];
    // Convert list to map required by FullPresetSlot
    final parameterValuesMap = <int, int>{};
    for (final pVal in parameterValues) {
      parameterValuesMap[pVal.parameterNumber] = pVal.value;
    }

    // Fetch Mappings
    final numParamsResult =
        await _distingManager!.requestNumberOfParameters(slotIndex);
    final numParams = numParamsResult?.numParameters ?? 0;
    final Map<int, PackedMappingData> mappingsMap = {};
    for (int pNum = 0; pNum < numParams; pNum++) {
      final mappingResult =
          await _distingManager!.requestMappings(slotIndex, pNum);
      // Only store if it's a valid mapping (not filler/default)
      if (mappingResult != null && mappingResult.packedMappingData.isMapped()) {
        mappingsMap[pNum] = mappingResult.packedMappingData;
      }
    }

    // Fetch Routing Info
    // Assuming requestRoutingInformation returns RoutingInfo which has List<int> routingInfo
    final routingInfoResult =
        await _distingManager!.requestRoutingInformation(slotIndex);
    final routingInfoList = routingInfoResult?.routingInfo ?? [];

    // Create PresetSlotEntry (ID and PresetID are set by DAO on insert)
    // Use the fetched customName here
    final presetSlotEntry = PresetSlotEntry(
      id: 0, // Ignored by DAO insert
      presetId: 0, // Ignored by DAO insert
      slotIndex: slotIndex,
      algorithmGuid: guid,
      customName: customName, // Use name from AlgorithmGuid result
    );

    // Assemble and return
    return FullPresetSlot(
      slot: presetSlotEntry,
      algorithm: algorithmEntry, // Pass the base AlgorithmEntry
      parameterValues: parameterValuesMap,
      mappings: mappingsMap,
      routingInfo: routingInfoList,
    );
  }
}
