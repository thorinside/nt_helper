import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:nt_helper/db/database.dart';
import 'package:nt_helper/db/daos/metadata_dao.dart';
import 'package:nt_helper/db/daos/presets_dao.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart'
    show AlgorithmInfo, Specification;
import 'package:nt_helper/domain/i_disting_midi_manager.dart'
    show IDistingMidiManager;
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
    if (switch (state) { SyncingMetadata() => true, _ => false }) {
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
    _isMetadataSyncCancelled = switch (state) {
      SyncingMetadata() => true,
      _ => false,
    };
  }

  // --- Preset Management Methods ---

  Future<void> saveCurrentPreset(IDistingMidiManager manager) async {
    if (switch (state) {
      SavingPreset() => true,
      LoadingPreset() => true,
      _ => false,
    }) {
      return;
    }

    emit(const MetadataSyncState.savingPreset());
    try {
      // 1. Fetch full preset details directly from the manager (online or offline)
      final FullPresetDetails? detailsToSave =
          await manager.requestCurrentPresetDetails();

      if (detailsToSave == null) {
        throw Exception(
            "Failed to retrieve current preset details from the manager.");
      }

      final name = detailsToSave.preset.name; // Get name for success message
      debugPrint(
          " >> saveCurrentPreset: Fetched details for preset '$name' (ID: ${detailsToSave.preset.id}) with ${detailsToSave.slots.length} slots from manager.");

      // 2. Save to Database using the details obtained from the manager
      debugPrint("Saving preset to database...");
      await _presetsDao.saveFullPreset(detailsToSave);

      emit(
          MetadataSyncState.presetSaveSuccess("Preset '$name' saved locally."));
      // Reload data after successful save
      loadLocalData();
    } catch (e, stacktrace) {
      debugPrint("Error saving preset: $e\n$stacktrace");
      emit(MetadataSyncState.presetSaveFailure(
          "Failed to save preset: ${e.toString()}"));
    }
  }

  Future<void> loadPresetToDevice(
      FullPresetDetails preset, IDistingMidiManager manager) async {
    emit(const MetadataSyncState.loadingPreset());
    if (kDebugMode) {
      debugPrint(
          "loadPresetToDevice: Starting load for preset '${preset.preset.name}'");
    }
    try {
      // 0. Clear the current preset on the device
      if (kDebugMode) {
        debugPrint("  -> Sending New Preset command to clear device state...");
      }
      await manager.requestNewPreset();
      await Future.delayed(
          const Duration(milliseconds: 200)); // Allow time to process

      // 1. Add all algorithms first
      if (kDebugMode) {
        debugPrint(
            "  -> Adding ${preset.slots.length} algorithms to the device...");
      }
      for (int i = 0; i < preset.slots.length; i++) {
        final slot = preset.slots[i];
        final algorithmGuid = slot.algorithm.guid;
        if (kDebugMode) {
          debugPrint(
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
          debugPrint(
              "    -> Found local metadata for '${algoDetails.algorithm.name}'");
        }

        // Prepare AlgorithmInfo and default specifications
        final algorithmInfo = AlgorithmInfo(
          algorithmIndex: i, // Use the target slot index
          guid: algoDetails.algorithm.guid,
          name: algoDetails.algorithm.name, // Use the canonical name
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
          debugPrint(
              "    -> Sending Add Algorithm command for slot $i with GUID $algorithmGuid and ${defaultSpecifications.length} specs.");
        }
        await manager.requestAddAlgorithm(algorithmInfo, defaultSpecifications);
        // Add delay after adding each algorithm
        await Future.delayed(const Duration(milliseconds: 150));
      }

      // 2. Set parameters and mappings for each slot
      if (kDebugMode) {
        debugPrint("  -> Setting parameters and mappings for all slots...");
      }
      for (int i = 0; i < preset.slots.length; i++) {
        final slot = preset.slots[i];
        final algorithmGuid = slot.algorithm.guid; // Needed again for metadata
        if (kDebugMode) {
          debugPrint("  -> Configuring Slot ${i + 1} (GUID: $algorithmGuid)");
        }

        // Send the slot name to the device
        await manager.requestSendSlotName(i, slot.algorithm.name);

        // Fetch metadata again to get parameter names for logging
        final algoDetails =
            await _metadataDao.getFullAlgorithmDetails(algorithmGuid);
        if (algoDetails == null) {
          debugPrint(
              "Warning: Metadata for GUID '$algorithmGuid' not found during parameter/mapping phase for slot ${i + 1}. Skipping.");
          continue; // Skip configuration for this slot if metadata missing
        }

        // 2a. Send Parameter Values
        if (kDebugMode) {
          debugPrint(
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
            debugPrint(
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
          debugPrint(
              "    -> Preparing to send ${slot.mappings.length} mappings for slot $i");
        }
        for (final mappingEntry in slot.mappings.entries) {
          final parameterNumber = mappingEntry.key;
          final mappingData = mappingEntry.value;

          if (kDebugMode) {
            debugPrint(
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
      }

      // 2d. Set the preset name on the device
      final presetName = preset.preset.name.trim();
      if (kDebugMode) {
        debugPrint("  -> Setting preset name on device to: '$presetName'");
      }
      await manager.requestSetPresetName(presetName);
      await Future.delayed(
          const Duration(milliseconds: 50)); // Short delay after name set

      // 2e. Save the preset to finish the process
      await manager.requestSavePreset();

      // 3. Add a final delay after all commands are sent
      await Future.delayed(const Duration(milliseconds: 100));

      emit(MetadataSyncState.presetLoadSuccess(
          "Preset '${preset.preset.name}' sent to device."));
      // Reload local data after success to ensure UI is in ViewingLocalData state
      await loadLocalData();
    } catch (e, stacktrace) {
      debugPrint("Error loading preset to device: $e\n$stacktrace");
      emit(MetadataSyncState.presetLoadFailure(
          "Error sending preset: ${e.toString()}"));
    }
  }

  Future<void> loadLocalData() async {
    final isBusy = switch (state) {
      SyncingMetadata() => true,
      SavingPreset() => true,
      LoadingPreset() => true,
      _ => false
    };
    // Allow proceeding if the state IS deletingPreset, because we want to load data *after* deletion.
    if (isBusy && !switch (state) { DeletingPreset() => true, _ => false }) {
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
      debugPrint('Error loading local data: $e\n$stacktrace');
      emit(MetadataSyncState.failure(
          "Failed to load local data: ${e.toString()}"));
    }
  }

  void reset() {
    _isMetadataSyncCancelled = false; // Ensure cancelled is reset
    emit(const MetadataSyncState.idle());
  }

  Future<void> deletePreset(int presetId) async {
    emit(const MetadataSyncState.deletingPreset());
    try {
      await _presetsDao.deletePreset(presetId);
      await loadLocalData(); // Reload data after deletion
    } catch (e) {
      emit(MetadataSyncState.presetDeleteFailure("Error deleting preset: $e"));
    }
  }
}
