import 'package:bloc/bloc.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/db/daos/metadata_dao.dart';
import 'package:nt_helper/db/daos/presets_dao.dart';
import 'package:nt_helper/db/database.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart'
    show AlgorithmInfo, Specification;
import 'package:nt_helper/domain/i_disting_midi_manager.dart'
    show IDistingMidiManager;
import 'package:nt_helper/services/metadata_sync_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'metadata_sync_cubit.freezed.dart';
part 'metadata_sync_state.dart';

class MetadataSyncCubit extends Cubit<MetadataSyncState> {
  final AppDatabase _database;
  final DistingCubit? _distingCubit;
  late final MetadataDao _metadataDao;
  late final PresetsDao _presetsDao;

  // Cancellation flag for metadata sync
  bool _isMetadataSyncCancelled = false;

  // Cancellation flag for template injection
  bool _isInjectionCancelled = false;

  // Checkpoint keys for SharedPreferences
  static const String _checkpointAlgorithmName =
      'metadata_sync_checkpoint_name';
  static const String _checkpointAlgorithmIndex =
      'metadata_sync_checkpoint_index';

  MetadataSyncCubit(this._database, [this._distingCubit])
    : super(const MetadataSyncState.idle()) {
    _metadataDao = _database.metadataDao;
    _presetsDao = _database.presetsDao;
  }

  // --- Metadata Sync Methods ---

  Future<void> startMetadataSync(
    IDistingMidiManager manager, {
    int? resumeFromIndex,
  }) async {
    if (switch (state) {
      SyncingMetadata() => true,
      _ => false,
    }) {
      return;
    }

    _isMetadataSyncCancelled = false; // Reset cancellation flag

    // Pause CPU monitoring during sync to prevent interference
    _distingCubit?.pauseCpuMonitoring();

    emit(
      const MetadataSyncState.syncingMetadata(
        progress: 0.0,
        mainMessage: "Initializing sync...",
        subMessage: "Preparing...",
      ),
    );

    bool errorOccurred = false;
    String finalMessage = "Metadata sync completed successfully.";

    final syncService = MetadataSyncService(manager, _database);

    await syncService.syncAllAlgorithmMetadata(
      resumeFromIndex: resumeFromIndex,
      onProgress: (progress, processed, total, mainMsg, subMsg) {
        if (!isClosed && !_isMetadataSyncCancelled) {
          emit(
            MetadataSyncState.syncingMetadata(
              progress: progress,
              mainMessage: mainMsg,
              subMessage: subMsg,
              algorithmsProcessed: processed,
              totalAlgorithms: total,
            ),
          );
        }
      },
      onError: (error) {
        if (!_isMetadataSyncCancelled) {
          errorOccurred = true;
          finalMessage = "Metadata Sync Failed: $error";
        }
      },
      onCheckpoint: (algorithmName, algorithmIndex) async {
        await _saveCheckpoint(algorithmName, algorithmIndex);
      },
      isCancelled: () => _isMetadataSyncCancelled,
    );

    // Clear checkpoint on successful completion
    if (!errorOccurred && !_isMetadataSyncCancelled) {
      await _clearCheckpoint();
    }

    // Always resume CPU monitoring when sync completes, regardless of outcome
    _distingCubit?.resumeCpuMonitoring();

    if (!isClosed) {
      if (_isMetadataSyncCancelled) {
        emit(
          const MetadataSyncState.metadataSyncFailure(
            "Metadata sync cancelled by user.",
          ),
        );
      } else if (errorOccurred) {
        emit(MetadataSyncState.metadataSyncFailure(finalMessage));
      } else {
        emit(MetadataSyncState.metadataSyncSuccess(finalMessage));
        await loadLocalData();
      }
    }
  }

  void cancelInjection() {
    _isInjectionCancelled = true;
  }

  void cancelMetadataSync() {
    final wasCancelled = switch (state) {
      SyncingMetadata() => true,
      SavingPreset() => true,
      DeletingPreset() => true,
      _ => false,
    };

    if (wasCancelled) {
      _isMetadataSyncCancelled = true;

      // Resume CPU monitoring when cancelling
      _distingCubit?.resumeCpuMonitoring();

      // Emit cancelled state immediately for better UX
      emit(
        const MetadataSyncState.metadataSyncFailure("Sync cancelled by user."),
      );

      // Load local data to return to normal state
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!isClosed) {
          loadLocalData();
        }
      });
    }
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
      final FullPresetDetails? detailsToSave = await manager
          .requestCurrentPresetDetails();

      if (detailsToSave == null) {
        throw Exception(
          "Failed to retrieve current preset details from the manager.",
        );
      }

      final name = detailsToSave.preset.name; // Get name for success message

      // 2. Save to Database using the details obtained from the manager
      await _presetsDao.saveFullPreset(detailsToSave);

      emit(
        MetadataSyncState.presetSaveSuccess("Preset '$name' saved locally."),
      );
      // Reload data after successful save
      loadLocalData();
    } catch (e) {
      emit(
        MetadataSyncState.presetSaveFailure(
          "Failed to save preset: ${e.toString()}",
        ),
      );
    }
  }

  Future<void> loadPresetToDevice(
    FullPresetDetails preset,
    IDistingMidiManager manager,
  ) async {
    emit(const MetadataSyncState.loadingPreset());
    if (kDebugMode) {}
    try {
      // 0. Clear the current preset on the device
      if (kDebugMode) {}
      await manager.requestNewPreset();
      await Future.delayed(
        const Duration(milliseconds: 200),
      ); // Allow time to process

      // 1. Add all algorithms first
      if (kDebugMode) {}
      for (int i = 0; i < preset.slots.length; i++) {
        final slot = preset.slots[i];
        final algorithmGuid = slot.algorithm.guid;
        if (kDebugMode) {}

        // Fetch full details to get specifications and AlgorithmInfo fields
        final algoDetails = await _metadataDao.getFullAlgorithmDetails(
          algorithmGuid,
        );
        if (algoDetails == null) {
          throw Exception(
            "Algorithm metadata for GUID '$algorithmGuid' not found locally. Cannot add slot ${i + 1}.",
          );
        }
        if (kDebugMode) {}

        // Prepare AlgorithmInfo and default specifications
        final algorithmInfo = AlgorithmInfo(
          algorithmIndex: i, // Use the target slot index
          guid: algoDetails.algorithm.guid,
          name: algoDetails.algorithm.name, // Use the canonical name
          specifications: algoDetails.specifications
              .map(
                (spec) => Specification(
                  name: spec.name,
                  min: spec.minValue,
                  max: spec.maxValue,
                  defaultValue: spec.defaultValue,
                  type: spec.type,
                ),
              )
              .toList(),
        );
        final defaultSpecifications = algoDetails.specifications
            .map((s) => s.defaultValue)
            .toList();

        if (kDebugMode) {}
        await manager.requestAddAlgorithm(algorithmInfo, defaultSpecifications);
        // Add delay after adding each algorithm
        await Future.delayed(const Duration(milliseconds: 150));
      }

      // 2. Set parameters and mappings for each slot
      if (kDebugMode) {}
      for (int i = 0; i < preset.slots.length; i++) {
        final slot = preset.slots[i];
        final algorithmGuid = slot.algorithm.guid; // Needed again for metadata
        if (kDebugMode) {}

        // Send the slot name to the device
        await manager.requestSendSlotName(i, slot.algorithm.name);

        // Fetch metadata again to get parameter names for logging
        final algoDetails = await _metadataDao.getFullAlgorithmDetails(
          algorithmGuid,
        );
        if (algoDetails == null) {
          continue; // Skip configuration for this slot if metadata missing
        }

        // 2a. Send Parameter Values
        if (kDebugMode) {}
        for (final paramEntry in slot.parameterValues.entries) {
          final parameterNumber = paramEntry.key;
          final value = paramEntry.value;

          // Find parameter name for logging (optional, but helpful)
          final paramMetadata = algoDetails.parameters.firstWhereOrNull(
            (p) => p.parameter.parameterNumber == parameterNumber,
          );
          paramMetadata?.parameter.name ?? 'Unnamed';

          // NOTE: ParameterAccess check removed as access level isn't stored
          // in ParameterEntry from the database.

          if (kDebugMode) {}
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
        if (kDebugMode) {}
        for (final mappingEntry in slot.mappings.entries) {
          final parameterNumber = mappingEntry.key;
          final mappingData = mappingEntry.value;

          if (kDebugMode) {}
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
      if (kDebugMode) {}
      await manager.requestSetPresetName(presetName);
      await Future.delayed(
        const Duration(milliseconds: 50),
      ); // Short delay after name set

      // 2e. Save the preset to finish the process
      await manager.requestSavePreset();

      // 3. Add a final delay after all commands are sent
      await Future.delayed(const Duration(milliseconds: 100));

      emit(
        MetadataSyncState.presetLoadSuccess(
          "Preset '${preset.preset.name}' sent to device.",
        ),
      );
      // Reload local data after success to ensure UI is in ViewingLocalData state
      await loadLocalData();
    } catch (e) {
      emit(
        MetadataSyncState.presetLoadFailure(
          "Error sending preset: ${e.toString()}",
        ),
      );
    }
  }

  Future<void> loadLocalData() async {
    final isBusy = switch (state) {
      SyncingMetadata() => true,
      SavingPreset() => true,
      LoadingPreset() => true,
      _ => false,
    };
    // Allow proceeding if the state IS deletingPreset, because we want to load data *after* deletion.
    if (isBusy &&
        !switch (state) {
          DeletingPreset() => true,
          _ => false,
        }) {
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

      // Check for checkpoint after loading data
      final hasCheckpoint = await _hasCheckpoint();

      if (hasCheckpoint) {
        await _checkForCheckpoint();
        // Don't emit ViewingLocalData yet - let CheckpointFound state show first
      } else {
        emit(
          MetadataSyncState.viewingLocalData(
            algorithms: algorithms,
            parameterCounts: parameterCounts,
            presets: presets,
          ),
        );
      }
    } catch (e) {
      emit(
        MetadataSyncState.failure("Failed to load local data: ${e.toString()}"),
      );
    }
  }

  // Check if there's a checkpoint
  Future<bool> _hasCheckpoint() async {
    final prefs = await SharedPreferences.getInstance();
    final algorithmName = prefs.getString(_checkpointAlgorithmName);
    final algorithmIndex = prefs.getInt(_checkpointAlgorithmIndex);
    return algorithmName != null && algorithmIndex != null;
  }

  // Check if there's a checkpoint and emit CheckpointFound state if so
  Future<void> _checkForCheckpoint() async {
    final prefs = await SharedPreferences.getInstance();
    final algorithmName = prefs.getString(_checkpointAlgorithmName);
    final algorithmIndex = prefs.getInt(_checkpointAlgorithmIndex);

    if (algorithmName != null && algorithmIndex != null) {
      emit(
        MetadataSyncState.checkpointFound(
          algorithmName: algorithmName,
          algorithmIndex: algorithmIndex,
        ),
      );
    }
  }

  // Save checkpoint
  Future<void> _saveCheckpoint(String algorithmName, int algorithmIndex) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_checkpointAlgorithmName, algorithmName);
    await prefs.setInt(_checkpointAlgorithmIndex, algorithmIndex);
  }

  // Clear checkpoint
  Future<void> _clearCheckpoint() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_checkpointAlgorithmName);
    await prefs.remove(_checkpointAlgorithmIndex);
  }

  // Resume from checkpoint
  void resumeFromCheckpoint() {
    if (state is CheckpointFound) {
      emit(const MetadataSyncState.idle());
    }
  }

  // Decline checkpoint and clear it, then load normal data
  Future<void> declineCheckpoint() async {
    await _clearCheckpoint();
    // Load local data normally after declining checkpoint
    await _loadLocalDataOnly();
  }

  // Load data without checkpoint check
  Future<void> _loadLocalDataOnly() async {
    emit(const MetadataSyncState.loadingPreset());

    try {
      final results = await Future.wait([
        _metadataDao.getAllAlgorithms(),
        _metadataDao.getAlgorithmParameterCounts(),
        _presetsDao.getAllPresets(),
      ]);

      final algorithms = results[0] as List<AlgorithmEntry>;
      final parameterCounts = results[1] as Map<String, int>;
      final presets = results[2] as List<PresetEntry>;

      emit(
        MetadataSyncState.viewingLocalData(
          algorithms: algorithms,
          parameterCounts: parameterCounts,
          presets: presets,
        ),
      );
    } catch (e) {
      emit(
        MetadataSyncState.failure("Failed to load local data: ${e.toString()}"),
      );
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

  Future<void> togglePresetTemplate(int presetId, bool isTemplate) async {
    try {
      await _presetsDao.toggleTemplateStatus(presetId, isTemplate);

      // Optimistically update the state without full reload
      if (state is ViewingLocalData) {
        final currentState = state as ViewingLocalData;
        final updatedPresets = currentState.presets.map((preset) {
          if (preset.id == presetId) {
            // Create a new PresetEntry with updated isTemplate flag
            return PresetEntry(
              id: preset.id,
              name: preset.name,
              lastModified: DateTime.now(), // Updated timestamp
              isTemplate: isTemplate,
            );
          }
          return preset;
        }).toList();

        emit(
          MetadataSyncState.viewingLocalData(
            algorithms: currentState.algorithms,
            parameterCounts: currentState.parameterCounts,
            presets: updatedPresets,
          ),
        );
      }
    } catch (e) {
      emit(
        MetadataSyncState.failure(
          "Error toggling template status: ${e.toString()}",
        ),
      );
    }
  }

  Future<void> syncNewAlgorithmsOnly(IDistingMidiManager manager) async {
    if (switch (state) {
      SyncingMetadata() => true,
      _ => false,
    }) {
      return;
    }

    _isMetadataSyncCancelled = false; // Reset cancellation flag

    // Pause CPU monitoring during sync to prevent interference
    _distingCubit?.pauseCpuMonitoring();

    emit(
      const MetadataSyncState.syncingMetadata(
        progress: 0.0,
        mainMessage: "Checking for new algorithms...",
        subMessage: "Comparing device and local lists...",
      ),
    );

    bool errorOccurred = false;
    String finalMessage = "Incremental sync completed successfully.";

    final syncService = MetadataSyncService(manager, _database);

    await syncService.syncNewAlgorithmsOnly(
      onProgress: (progress, processed, total, mainMsg, subMsg) {
        if (!isClosed && !_isMetadataSyncCancelled) {
          emit(
            MetadataSyncState.syncingMetadata(
              progress: progress,
              mainMessage: mainMsg,
              subMessage: subMsg,
              algorithmsProcessed: processed,
              totalAlgorithms: total,
            ),
          );
        }
      },
      onError: (error) {
        if (!_isMetadataSyncCancelled) {
          errorOccurred = true;
          finalMessage = "Incremental Sync Failed: $error";
        }
      },
      isCancelled: () => _isMetadataSyncCancelled,
    );

    // Always resume CPU monitoring when sync completes, regardless of outcome
    _distingCubit?.resumeCpuMonitoring();

    if (!isClosed) {
      if (_isMetadataSyncCancelled) {
        emit(
          const MetadataSyncState.metadataSyncFailure(
            "Incremental sync cancelled by user.",
          ),
        );
      } else if (errorOccurred) {
        emit(MetadataSyncState.metadataSyncFailure(finalMessage));
      } else {
        emit(MetadataSyncState.metadataSyncSuccess(finalMessage));
        await loadLocalData();
      }
    }
  }

  Future<void> rescanSingleAlgorithm(
    IDistingMidiManager manager,
    String algorithmGuid,
  ) async {
    emit(
      const MetadataSyncState.syncingMetadata(
        progress: 0.0,
        mainMessage: "Rescanning algorithm...",
        subMessage: "Preparing...",
      ),
    );

    try {
      // Find the algorithm info from the database
      final algorithm = await _metadataDao.getAlgorithmByGuid(algorithmGuid);
      if (algorithm == null) {
        throw Exception("Algorithm not found in database");
      }

      // Get all algorithm info to find the one we need
      final numAlgoTypes = await manager.requestNumberOfAlgorithms();
      if (numAlgoTypes == null) {
        throw Exception("Failed to get algorithm count from device");
      }

      AlgorithmInfo? targetAlgoInfo;
      for (int i = 0; i < numAlgoTypes; i++) {
        final algoInfo = await manager.requestAlgorithmInfo(i);
        if (algoInfo?.guid == algorithmGuid) {
          targetAlgoInfo = algoInfo;
          break;
        }
      }

      if (targetAlgoInfo == null) {
        throw Exception("Algorithm not found on device");
      }

      emit(
        MetadataSyncState.syncingMetadata(
          progress: 0.5,
          mainMessage: targetAlgoInfo.name,
          subMessage: "Starting rescan...",
        ),
      );

      // Use the metadata sync service to rescan
      final syncService = MetadataSyncService(manager, _database);
      await syncService.rescanSingleAlgorithm(targetAlgoInfo);

      emit(
        const MetadataSyncState.metadataSyncSuccess(
          "Algorithm rescanned successfully",
        ),
      );

      // Reload data to show updated parameter count
      await loadLocalData();
    } catch (e) {
      emit(
        MetadataSyncState.metadataSyncFailure("Failed to rescan algorithm: $e"),
      );

      // Return to data view after error
      Future.delayed(const Duration(seconds: 2), () {
        if (!isClosed) {
          loadLocalData();
        }
      });
    }
  }

  /// Injects a template preset into the current device preset by appending
  /// its algorithms to the end without clearing the existing preset.
  ///
  /// This method:
  /// - Validates that current preset + template slots ≤ 32
  /// - Adds each template algorithm sequentially via requestAddAlgorithm()
  /// - Sets parameter values and mappings for each injected slot
  /// - Does NOT call requestNewPreset() (preserves current preset)
  /// - Does NOT call requestSavePreset() (lets user save manually)
  ///
  /// Throws [Exception] if slot limit would be exceeded.
  /// Emits loading/success/failure states to UI.
  Future<void> injectTemplateToDevice(
    FullPresetDetails template,
    IDistingMidiManager manager,
  ) async {
    _isInjectionCancelled = false; // Reset cancellation flag
    emit(const MetadataSyncState.loadingPreset());

    try {
      // Check for empty template
      if (template.slots.isEmpty) {
        throw Exception('Cannot inject empty template');
      }

      // Check for cancellation early
      if (_isInjectionCancelled) {
        throw Exception(
          'Injection cancelled. Preset may be partially modified.',
        );
      }

      // Validate that all template algorithms have metadata
      for (int i = 0; i < template.slots.length; i++) {
        final slot = template.slots[i];
        final algorithmGuid = slot.algorithm.guid;
        final algoDetails = await _metadataDao.getFullAlgorithmDetails(
          algorithmGuid,
        );
        if (algoDetails == null) {
          throw Exception(
            'Template missing algorithm metadata. '
            'Sync algorithms first.',
          );
        }
      }

      // Validate slot limit before starting injection
      int currentSlotCount = 0;
      try {
        currentSlotCount = await manager.requestNumAlgorithmsInPreset() ?? 0;
      } catch (e) {
        // In offline/demo mode, assume empty preset
        currentSlotCount = 0;
      }
      final templateSlotCount = template.slots.length;
      final totalSlots = currentSlotCount + templateSlotCount;

      if (totalSlots > 32) {
        throw Exception(
          'Cannot inject: Would exceed 32 slot limit '
          '(current: $currentSlotCount, template: $templateSlotCount)',
        );
      }

      // Track the starting slot index for parameter/mapping application
      final startingSlotIndex = currentSlotCount;

      // Add all algorithms first (sequentially, not in parallel)
      for (int i = 0; i < template.slots.length; i++) {
        // Check for cancellation between algorithms
        if (_isInjectionCancelled) {
          throw Exception(
            'Injection cancelled after adding $i of ${template.slots.length} algorithms. '
            'Preset may be partially modified.',
          );
        }

        final slot = template.slots[i];
        final algorithmGuid = slot.algorithm.guid;

        try {
          // Fetch full details to get specifications and AlgorithmInfo fields
          final algoDetails = await _metadataDao.getFullAlgorithmDetails(
            algorithmGuid,
          );
          if (algoDetails == null) {
            throw Exception(
              "Algorithm metadata for GUID '$algorithmGuid' not found locally. "
              "Cannot add template slot ${i + 1}.",
            );
          }

          // Prepare AlgorithmInfo and default specifications
          // Use startingSlotIndex + i as the target slot index
          final targetSlotIndex = startingSlotIndex + i;
          final algorithmInfo = AlgorithmInfo(
            algorithmIndex: targetSlotIndex,
            guid: algoDetails.algorithm.guid,
            name: algoDetails.algorithm.name,
            specifications: algoDetails.specifications
                .map(
                  (spec) => Specification(
                    name: spec.name,
                    min: spec.minValue,
                    max: spec.maxValue,
                    defaultValue: spec.defaultValue,
                    type: spec.type,
                  ),
                )
                .toList(),
          );
          final defaultSpecifications = algoDetails.specifications
              .map((s) => s.defaultValue)
              .toList();

          await manager.requestAddAlgorithm(algorithmInfo, defaultSpecifications);
          // Add delay after adding each algorithm
          await Future.delayed(const Duration(milliseconds: 150));
        } catch (algorithmError) {
          // Report partial injection failure with specific algorithm that failed
          throw Exception(
            'Failed to inject algorithm "${slot.algorithm.name}" '
            '(${i + 1} of ${template.slots.length}). '
            'Preset may be partially modified. '
            'Error: ${algorithmError.toString()}',
          );
        }
      }

      // Set parameters and mappings for each injected slot
      for (int i = 0; i < template.slots.length; i++) {
        final slot = template.slots[i];
        final targetSlotIndex = startingSlotIndex + i;
        final algorithmGuid = slot.algorithm.guid;
        if (kDebugMode) {}

        // Send the slot name to the device
        await manager.requestSendSlotName(targetSlotIndex, slot.algorithm.name);

        // Fetch metadata again to get parameter names for logging
        final algoDetails = await _metadataDao.getFullAlgorithmDetails(
          algorithmGuid,
        );
        if (algoDetails == null) {
          continue; // Skip configuration for this slot if metadata missing
        }

        // Send Parameter Values
        if (kDebugMode) {}
        for (final paramEntry in slot.parameterValues.entries) {
          final parameterNumber = paramEntry.key;
          final value = paramEntry.value;

          // Find parameter name for logging (optional, but helpful)
          final paramMetadata = algoDetails.parameters.firstWhereOrNull(
            (p) => p.parameter.parameterNumber == parameterNumber,
          );
          paramMetadata?.parameter.name ?? 'Unnamed';

          if (kDebugMode) {}
          // Use setParameterValue
          await manager.setParameterValue(
            targetSlotIndex,
            parameterNumber,
            value,
          );
          // Optional small delay between parameter sends
          await Future.delayed(const Duration(milliseconds: 20));
        }

        // Send Mappings
        if (kDebugMode) {}
        for (final mappingEntry in slot.mappings.entries) {
          final parameterNumber = mappingEntry.key;
          final mappingData = mappingEntry.value;

          if (kDebugMode) {}
          // Use requestSetMapping
          await manager.requestSetMapping(
            targetSlotIndex,
            parameterNumber,
            mappingData,
          );
          // Optional small delay
          await Future.delayed(const Duration(milliseconds: 20));
        }
      }

      // Add a final delay after all commands are sent
      await Future.delayed(const Duration(milliseconds: 100));

      emit(
        MetadataSyncState.presetLoadSuccess(
          "Template '${template.preset.name}' injected to device. "
          "Save manually when ready.",
        ),
      );
      // Reload local data after success to ensure UI is in ViewingLocalData state
      await loadLocalData();
    } catch (e) {

      // Provide specific error messages based on exception type
      String errorMessage;

      // Check for connection-related errors
      if (e.toString().contains('connection') ||
          e.toString().contains('Connection') ||
          e.toString().contains('disconnect') ||
          e.toString().contains('MIDI') ||
          e.toString().contains('timeout')) {
        errorMessage =
          'Connection lost during injection. Preset may be partially modified. '
          'Reconnect your device and check the preset.';
      } else if (e.toString().contains('metadata') ||
                 e.toString().contains('not found locally')) {
        errorMessage =
          'Template missing algorithm metadata. '
          'Go to Settings > Sync Algorithms to download latest metadata.';
      } else {
        errorMessage = "Error injecting template: ${e.toString()}";
      }

      emit(MetadataSyncState.presetLoadFailure(errorMessage));
    }
  }
}
