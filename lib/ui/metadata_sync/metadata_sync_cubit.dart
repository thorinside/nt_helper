import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:nt_helper/db/database.dart';
import 'package:nt_helper/db/daos/metadata_dao.dart';
import 'package:nt_helper/db/daos/presets_dao.dart';
import 'package:nt_helper/domain/disting_midi_manager.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'package:nt_helper/models/packed_mapping_data.dart';
import 'package:nt_helper/services/metadata_sync_service.dart';
import 'package:collection/collection.dart';

part 'metadata_sync_state.dart';
part 'metadata_sync_cubit.freezed.dart';

class MetadataSyncCubit extends Cubit<MetadataSyncState> {
  final AppDatabase _database;
  late final MetadataDao _metadataDao;
  late final PresetsDao _presetsDao;

  // Cancellation flag for metadata sync
  bool _isMetadataSyncCancelled = false;

  MetadataSyncCubit(
    this._database,
  ) : super(const MetadataSyncState.idle()) {
    _metadataDao = _database.metadataDao;
    _presetsDao = _database.presetsDao;
  }

  // --- Metadata Sync Methods ---

  Future<void> startMetadataSync(IDistingMidiManager manager) async {
    if (state.maybeMap(syncingMetadata: (_) => true, orElse: () => false))
      return;

    _isMetadataSyncCancelled = false; // Reset cancellation flag

    emit(const MetadataSyncState.syncingMetadata(
      progress: 0.0,
      mainMessage: "Initializing sync...",
      subMessage: "Preparing...",
    ));

    bool errorOccurred = false;
    String finalMessage = "Metadata sync completed successfully.";

    final syncService = MetadataSyncService(manager, _database);

    await syncService.syncAllAlgorithmMetadata(
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
        await loadLocalData();
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

  Future<void> saveCurrentPreset(IDistingMidiManager manager) async {
    if (state.maybeMap(
        savingPreset: (_) => true,
        loadingPreset: (_) => true,
        orElse: () => false)) {
      return; // Prevent concurrent operations
    }

    emit(const MetadataSyncState.savingPreset());
    try {
      // 1. Fetch Name
      final rawName = await manager.requestPresetName() ?? "Unnamed Preset";
      final name = rawName.trim(); // Trim the name

      // *** Name check removed - DAO will handle upsert based on name ***

      // 2. Fetch Number of Slots
      final numSlots = await manager.requestNumAlgorithmsInPreset();
      if (kDebugMode)
        print(" >> saveCurrentPreset: Device reported $numSlots slots.");
      if (numSlots == null) {
        throw Exception("Failed to get number of algorithms in preset.");
      }

      // 3. Fetch Each Slot's Details FIRST
      final List<FullPresetSlot> fullSlots = [];
      for (int i = 0; i < numSlots; i++) {
        if (kDebugMode) {
          print(
              "  -> saveCurrentPreset: Entering FOR loop iteration i = $i"); // Keep this
        }
        if (kDebugMode) print("  >> About to call _fetchPresetSlotDetails($i)");
        final slotDetails = await _fetchPresetSlotDetails(i, manager);
        fullSlots.add(slotDetails);
        if (kDebugMode)
          print(
              "    >> Added slot $i. fullSlots length now: ${fullSlots.length}");
      }

      // 4. Assemble Preset Data AFTER fetching slots
      final now = DateTime.now();
      final presetEntry = PresetEntry(id: 0, name: name, lastModified: now);
      // Use the populated fullSlots list here
      final detailsToSave =
          FullPresetDetails(preset: presetEntry, slots: fullSlots);

      if (kDebugMode)
        print(
            " >> saveCurrentPreset: Assembled FullPresetDetails with ${detailsToSave.slots.length} slots BEFORE saving."); // Updated print message

      // 5. Save to Database
      if (kDebugMode) {
        print("Saving preset to database...");
      }
      await _presetsDao.saveFullPreset(detailsToSave);

      emit(
          MetadataSyncState.presetSaveSuccess("Preset '$name' saved locally."));
      // Reload data after successful save
      loadLocalData();
    } catch (e, stacktrace) {
      print("Error saving preset: $e\n$stacktrace");
      // *** Reverted error handling - Keep generic message ***
      emit(MetadataSyncState.presetSaveFailure(
          "Failed to save preset: ${e.toString()}"));
    }
  }

  Future<void> loadPresetToDevice(
      FullPresetDetails preset, IDistingMidiManager manager) async {
    emit(const MetadataSyncState.loadingPreset());
    if (kDebugMode) {
      print(
          "loadPresetToDevice: Starting load for preset '${preset.preset.name}'");
    }
    try {
      // 0. Clear the current preset on the device
      if (kDebugMode) {
        print("  -> Sending New Preset command to clear device state...");
      }
      await manager.requestNewPreset();
      await Future.delayed(
          const Duration(milliseconds: 200)); // Allow time to process

      // 1. Add all algorithms first
      if (kDebugMode) {
        print("  -> Adding ${preset.slots.length} algorithms to the device...");
      }
      for (int i = 0; i < preset.slots.length; i++) {
        final slot = preset.slots[i];
        final algorithmGuid = slot.algorithm.guid;
        if (kDebugMode) {
          print(
              "  -> Preparing to add Algorithm ${i + 1}: GUID $algorithmGuid");
        }

        // Fetch full details to get specifications and AlgorithmInfo fields
        final algoDetails =
            await _metadataDao.getFullAlgorithmDetails(algorithmGuid);
        if (algoDetails == null) {
          throw Exception(
              "Algorithm metadata for GUID '$algorithmGuid' not found locally. Cannot add slot ${i + 1}.");
        }
        if (kDebugMode) {
          print(
              "    -> Found local metadata for '${algoDetails.algorithm.name}'");
        }

        // Prepare AlgorithmInfo and default specifications
        final algorithmInfo = AlgorithmInfo(
          algorithmIndex: i, // Use the target slot index
          guid: algoDetails.algorithm.guid,
          name: algoDetails.algorithm.name, // Use the canonical name
          numSpecifications: algoDetails.specifications.length,
          specifications: algoDetails.specifications
              .map((spec) => Specification(
                    name: spec.name,
                    min: spec.minValue,
                    max: spec.maxValue,
                    defaultValue: spec.defaultValue,
                    type: spec.type,
                  ))
              .toList(),
        );
        final defaultSpecifications =
            algoDetails.specifications.map((s) => s.defaultValue).toList();

        if (kDebugMode) {
          print(
              "    -> Sending Add Algorithm command for slot $i with GUID $algorithmGuid and ${defaultSpecifications.length} specs.");
        }
        await manager.requestAddAlgorithm(algorithmInfo, defaultSpecifications);
        // Add delay after adding each algorithm
        await Future.delayed(const Duration(milliseconds: 150));
      }

      // 2. Set parameters and mappings for each slot
      if (kDebugMode) {
        print("  -> Setting parameters and mappings for all slots...");
      }
      for (int i = 0; i < preset.slots.length; i++) {
        final slot = preset.slots[i];
        final algorithmGuid = slot.algorithm.guid; // Needed again for metadata
        if (kDebugMode) {
          print("  -> Configuring Slot ${i + 1} (GUID: $algorithmGuid)");
        }

        // Fetch metadata again to get parameter names for logging
        final algoDetails =
            await _metadataDao.getFullAlgorithmDetails(algorithmGuid);
        if (algoDetails == null) {
          print(
              "Warning: Metadata for GUID '$algorithmGuid' not found during parameter/mapping phase for slot ${i + 1}. Skipping.");
          continue; // Skip configuration for this slot if metadata missing
        }

        // 2a. Send Parameter Values
        if (kDebugMode) {
          print(
              "    -> Preparing to send ${slot.parameterValues.length} parameter values for slot $i");
        }
        for (final paramEntry in slot.parameterValues.entries) {
          final parameterNumber = paramEntry.key;
          final value = paramEntry.value;

          // Find parameter name for logging (optional, but helpful)
          final paramMetadata = algoDetails.parameters.firstWhereOrNull(
            (p) => p.parameter.parameterNumber == parameterNumber,
          );
          final paramName = paramMetadata?.parameter.name ?? 'Unnamed';

          // NOTE: ParameterAccess check removed as access level isn't stored
          // in ParameterEntry from the database.

          if (kDebugMode) {
            print(
                "    -> Sending Param $parameterNumber ($paramName) = $value for slot $i");
          }
          // Use setParameterValue
          await manager.setParameterValue(
            i, // slotIndex (use loop index)
            parameterNumber,
            value,
          );
          // Optional small delay between parameter sends
          await Future.delayed(const Duration(milliseconds: 20));
        }

        // 2b. Send Mappings
        if (kDebugMode) {
          print(
              "    -> Preparing to send ${slot.mappings.length} mappings for slot $i");
        }
        for (final mappingEntry in slot.mappings.entries) {
          final parameterNumber = mappingEntry.key;
          final mappingData = mappingEntry.value;

          if (kDebugMode) {
            print(
                "    -> Sending Mapping for Param $parameterNumber in slot $i: CV(${mappingData.cvInput}), MIDI(${mappingData.isMidiEnabled ? mappingData.midiCC : 'Off'}), I2C(${mappingData.isI2cEnabled ? mappingData.i2cCC : 'Off'})");
          }
          // Use requestSetMapping
          await manager.requestSetMapping(
            i, // slotIndex (use loop index)
            parameterNumber,
            mappingData,
          );
          // Optional small delay
          await Future.delayed(const Duration(milliseconds: 20));
        }

        // 2c. Routing - Removed as FullPresetSlot doesn't contain routing info
        // and a direct sendRouting method is unavailable.
        if (kDebugMode) {
          print("    -> Routing configuration for slot $i skipped.");
        }
      } // End loop for setting params/mappings

      // 2d. Set the preset name on the device
      final presetName = preset.preset.name.trim();
      if (kDebugMode) {
        print("  -> Setting preset name on device to: '$presetName'");
      }
      await manager.requestSetPresetName(presetName);
      await Future.delayed(
          const Duration(milliseconds: 50)); // Short delay after name set

      // 3. Add a final delay after all commands are sent
      await Future.delayed(const Duration(milliseconds: 100));

      // 4. Verification (Optional but recommended)
      // TODO: Request some key values back from the device to confirm.

      emit(MetadataSyncState.presetLoadSuccess(
          "Preset '${preset.preset.name}' sent to device."));
      // Reload local data after success to ensure UI is in ViewingLocalData state
      await loadLocalData();
    } catch (e, stacktrace) {
      // Corrected print statement syntax
      print("Error loading preset to device: $e\n$stacktrace");
      emit(MetadataSyncState.presetLoadFailure(
          "Error sending preset: ${e.toString()}"));
    }
  }

  Future<void> loadLocalData() async {
    final isBusy = state.maybeMap(
        syncingMetadata: (_) => true,
        savingPreset: (_) => true,
        loadingPreset: (_) => true,
        // deletingPreset: (_) => true, // Allow loading even if deleting just finished
        orElse: () => false);
    // Allow proceeding if the state IS deletingPreset, because we want to load data *after* deletion.
    if (isBusy &&
        !state.maybeMap(deletingPreset: (_) => true, orElse: () => false)) {
      return;
    }

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
  Future<FullPresetSlot> _fetchPresetSlotDetails(
      int slotIndex, IDistingMidiManager manager) async {
    // Manager is passed in, assume not null

    // Fetch Algorithm GUID and Name (use passed manager)
    final algoGuidResult = await manager.requestAlgorithmGuid(slotIndex);
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
        await manager.requestAllParameterValues(slotIndex);
    final parameterValues = paramValuesResult?.values ?? [];
    // Convert list to map required by FullPresetSlot
    final parameterValuesMap = <int, int>{};
    for (final pVal in parameterValues) {
      parameterValuesMap[pVal.parameterNumber] = pVal.value;
    }

    // Fetch Mappings
    final numParamsResult = await manager.requestNumberOfParameters(slotIndex);
    final numParams = numParamsResult?.numParameters ?? 0;
    final Map<int, PackedMappingData> mappingsMap = {};
    for (int pNum = 0; pNum < numParams; pNum++) {
      final mappingResult = await manager.requestMappings(slotIndex, pNum);
      // Only store if it's a valid mapping (not filler/default)
      if (mappingResult != null && mappingResult.packedMappingData.isMapped()) {
        mappingsMap[pNum] = mappingResult.packedMappingData;
      }
    }

    // Fetch Routing Info
    // Assuming requestRoutingInformation returns RoutingInfo which has List<int> routingInfo
    final routingInfoResult =
        await manager.requestRoutingInformation(slotIndex);
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

  Future<void> deletePreset(int presetId) async {
    emit(const MetadataSyncState.deletingPreset());
    try {
      await _presetsDao.deletePreset(presetId);
      // Ensure we wait for data loading to finish
      await loadLocalData();
    } catch (e) {
      emit(MetadataSyncState.presetDeleteFailure("Error deleting preset: $e"));
    }
  }
}
