import 'dart:async';

import 'package:async/async.dart';
import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_midi_command/flutter_midi_command.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:nt_helper/db/daos/metadata_dao.dart'; // Added
import 'package:nt_helper/db/daos/presets_dao.dart'; // Added
import 'package:nt_helper/db/database.dart'; // Added
import 'package:nt_helper/domain/disting_midi_manager.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'package:nt_helper/domain/i_disting_midi_manager.dart';
import 'package:nt_helper/domain/mock_disting_midi_manager.dart';
import 'package:nt_helper/domain/offline_disting_midi_manager.dart';
import 'package:nt_helper/domain/parameter_update_queue.dart';
import 'package:nt_helper/models/cpu_usage.dart';
import 'package:nt_helper/models/packed_mapping_data.dart';
import 'package:nt_helper/models/package_file.dart';
import 'package:nt_helper/models/plugin_info.dart';
import 'package:nt_helper/models/routing_information.dart';
import 'package:nt_helper/models/firmware_version.dart';
import 'package:nt_helper/util/extensions.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:collection/collection.dart'; // Add collection package import

part 'disting_cubit.freezed.dart';

part 'disting_state.dart';

// A helper class to track each parameter's polling state.
class _PollingTask {
  bool active = true;
  int noChangeCount = 0;

  _PollingTask();
}

// Retry request types for background parameter retry queue
enum _ParameterRetryType {
  info,
  enumStrings,
  mappings,
  valueStrings,
}

// Retry request data structure for background parameter retry queue
class _ParameterRetryRequest {
  final int slotIndex;
  final int paramIndex;
  final _ParameterRetryType type;

  _ParameterRetryRequest({
    required this.slotIndex,
    required this.paramIndex,
    required this.type,
  });
}

class DistingCubit extends Cubit<DistingState> {
  final AppDatabase database; // Renamed from _database to make it public
  late final MetadataDao _metadataDao; // Added
  final Future<SharedPreferences> _prefs;

  // Modified constructor
  DistingCubit(this.database)
      : _prefs = SharedPreferences.getInstance(),
        super(const DistingState.initial()) {
    _metadataDao =
        database.metadataDao; // Initialize DAO using public database field

    // Initialize CPU usage stream
    _cpuUsageController = StreamController<CpuUsage>.broadcast(
      onListen: _startCpuUsagePolling,
      onCancel: _checkStopCpuUsagePolling,
    );
  }

  MidiCommand _midiCommand = MidiCommand();
  CancelableOperation<void>? _programSlotUpdate;
  CancelableOperation<void>?
      _moveVerificationOperation; // Add verification operation tracker
  // Keep track of the offline manager instance when offline
  OfflineDistingMidiManager? _offlineManager;
  final Map<int, DateTime> _lastAnomalyRefreshAttempt = {};

  // Parameter update queue for consolidated parameter changes
  ParameterUpdateQueue? _parameterQueue;

  // CPU Usage Streaming
  late final StreamController<CpuUsage> _cpuUsageController;
  Timer? _cpuUsageTimer;
  static const Duration _cpuUsagePollingInterval = Duration(seconds: 10);

  /// Stream of CPU usage updates that polls every 10 seconds when listeners are active
  Stream<CpuUsage> get cpuUsageStream => _cpuUsageController.stream;

  // Added: Store last known online connection details
  MidiDevice? _lastOnlineInputDevice;
  MidiDevice? _lastOnlineOutputDevice;
  int? _lastOnlineSysExId;

  @override
  Future<void> close() {
    disting()?.dispose();
    _offlineManager?.dispose(); // Dispose offline manager too
    _parameterQueue?.dispose(); // Dispose parameter queue
    _midiCommand.dispose();

    // Dispose CPU usage streaming resources
    _cpuUsageTimer?.cancel();
    _cpuUsageController.close();

    return super.close();
  }

  Future<void> initialize() async {
    // Check for offline capability first
    bool canWorkOffline = false; // Default to false
    try {
      canWorkOffline = await _metadataDao.hasCachedAlgorithms();
    } catch (e, stackTrace) {
      debugPrintStack(stackTrace: stackTrace);
      // Proceed with canWorkOffline as false
    }

    final prefs = await _prefs;
    final savedInputDeviceName = prefs.getString('selectedInputMidiDevice');
    final savedOutputDeviceName = prefs.getString('selectedOutputMidiDevice');
    final savedSysExId = prefs.getInt('selectedSysExId');

    if (savedOutputDeviceName != null &&
        savedInputDeviceName != null &&
        savedSysExId != null) {
      // Try to connect to the saved device
      final devices = await _midiCommand.devices;
      final MidiDevice? savedInputDevice = devices
          ?.where((device) => device.name == savedInputDeviceName)
          .firstOrNull;

      final MidiDevice? savedOutputDevice = devices
          ?.where((device) => device.name == savedOutputDeviceName)
          .firstOrNull;

      if (savedInputDevice != null && savedOutputDevice != null) {
        await connectToDevices(
            savedInputDevice, savedOutputDevice, savedSysExId);
      } else {
        // Saved prefs exist, but devices not found now.
        final devices = await _fetchDeviceLists(); // Use helper
        emit(DistingState.selectDevice(
          inputDevices: devices['input'] ?? [],
          outputDevices: devices['output'] ?? [],
          canWorkOffline: canWorkOffline, // Pass the flag
        ));
      }
    } else {
      // No saved settings found, load devices and show selection
      final devices = await _fetchDeviceLists(); // Use helper
      emit(DistingState.selectDevice(
        inputDevices: devices['input'] ?? [],
        outputDevices: devices['output'] ?? [],
        canWorkOffline: canWorkOffline, // Pass the flag
      ));
    }
  }

  Future<void> onDemo() async {
    // --- Create Mock Manager and Fetch State ---
    final mockManager = MockDistingMidiManager();
    final distingVersion =
        await mockManager.requestVersionString() ?? "Demo Error";
    final presetName =
        await mockManager.requestPresetName() ?? "Demo Preset Error";
    final algorithms = await _fetchMockAlgorithms(mockManager);
    final unitStrings = await mockManager.requestUnitStrings() ?? [];
    final numSlots = await mockManager.requestNumAlgorithmsInPreset() ?? 0;
    final slots = await fetchSlots(
        numSlots, mockManager); // Use fetchSlots with mockManager

    // Debug: Check slots immediately after fetching
    debugPrint("[Cubit onDemo] fetchSlots returned ${slots.length} slots.");
    for (int i = 0; i < slots.length; i++) {
      final s = slots[i];
      debugPrint(
          "[Cubit onDemo] Slot $i ('${s.algorithm.name}'): Params=${s.parameters.length}, Vals=${s.values.length}, Enums=${s.enums.length}, Maps=${s.mappings.length}, ValStrs=${s.valueStrings.length}");
    }

    // --- Emit the State ---
    emit(DistingState.synchronized(
      disting: mockManager,
      // Use the created mock manager instance
      distingVersion: distingVersion,
      firmwareVersion: FirmwareVersion(distingVersion),
      presetName: presetName,
      algorithms: algorithms,
      slots: slots,
      unitStrings: unitStrings,
      demo: true,
    ));

    // Create parameter queue for demo manager
    _createParameterQueue();
  }

  // Helper to determine if an algorithm is a factory algorithm (lowercase GUID)
  // vs community plugin (any uppercase letters in GUID)
  bool _isFactoryAlgorithm(String guid) {
    return guid == guid.toLowerCase();
  }

  // Helper to fetch algorithm info with prioritization (factory first, then community)
  Future<List<AlgorithmInfo>> _fetchAlgorithmsWithPriority(
      IDistingMidiManager manager,
      {bool enableBackgroundCommunityLoading = false}) async {
    final numAlgorithms = await manager.requestNumberOfAlgorithms() ?? 0;
    debugPrint("[Cubit] Found $numAlgorithms total algorithms to process");

    if (enableBackgroundCommunityLoading) {
      // Optimized approach: only fetch factory algorithms synchronously
      return _fetchFactoryAlgorithmsAndStartBackgroundLoading(
          manager, numAlgorithms);
    } else {
      // Original approach: fetch all algorithms synchronously with prioritization
      return _fetchAllAlgorithmsSynchronously(manager, numAlgorithms);
    }
  }

  // Optimized method: fetch factory algorithms quickly, queue slow ones for background
  Future<List<AlgorithmInfo>> _fetchFactoryAlgorithmsAndStartBackgroundLoading(
      IDistingMidiManager manager, int numAlgorithms) async {
    final List<AlgorithmInfo> factoryResults = [];
    final List<int> backgroundIndices = [];

    debugPrint(
        "[Cubit] Starting optimized fetch with $numAlgorithms algorithms - using short timeouts to identify fast factory algorithms");

    // Quick pass with short timeout to catch fast-responding factory algorithms
    for (int i = 0; i < numAlgorithms; i++) {
      try {
        // Use very short timeout - factory algorithms should respond quickly
        final algorithmInfo = await manager.requestAlgorithmInfo(i).timeout(
              const Duration(milliseconds: 200),
              onTimeout: () => null,
            );

        if (algorithmInfo != null && _isFactoryAlgorithm(algorithmInfo.guid)) {
          factoryResults.add(algorithmInfo);
          debugPrint("[Cubit] Quick factory algorithm: ${algorithmInfo.name}");
        } else if (algorithmInfo != null) {
          // Got response but it's a community plugin - queue for background
          backgroundIndices.add(i);
          debugPrint("[Cubit] Community plugin queued: ${algorithmInfo.name}");
        } else {
          // Timed out - likely a community plugin that's not loaded, queue for background
          backgroundIndices.add(i);
        }
      } catch (e) {
        // Error - queue for background retry
        backgroundIndices.add(i);
        debugPrint("[Cubit] Algorithm $i error, queued for background: $e");
      }
    }

    debugPrint(
        "[Cubit] Quick sync complete: ${factoryResults.length} factory algorithms loaded, ${backgroundIndices.length} queued for background");

    // Start background loading for community plugins and timed-out algorithms
    if (backgroundIndices.isNotEmpty) {
      _loadCommunityPluginsInBackground(
          manager, backgroundIndices, List.from(factoryResults));
    }

    return factoryResults;
  }

  // Original method: fetch all algorithms with full categorization pass
  Future<List<AlgorithmInfo>> _fetchAllAlgorithmsSynchronously(
      IDistingMidiManager manager, int numAlgorithms) async {
    final List<int> factoryIndices = [];
    final List<int> communityIndices = [];

    // First pass: categorize algorithms by requesting basic info
    for (int i = 0; i < numAlgorithms; i++) {
      try {
        final algorithmInfo = await manager.requestAlgorithmInfo(i);
        if (algorithmInfo != null) {
          if (_isFactoryAlgorithm(algorithmInfo.guid)) {
            factoryIndices.add(i);
          } else {
            communityIndices.add(i);
          }
        }
      } catch (e) {
        debugPrint("Error categorizing algorithm $i: $e");
        // If we can't determine, treat as community (lower priority)
        communityIndices.add(i);
      }
    }

    final List<AlgorithmInfo> results = [];

    // Fetch factory algorithms first (higher priority)
    for (int i in factoryIndices) {
      try {
        final algorithmInfo = await manager.requestAlgorithmInfo(i);
        if (algorithmInfo != null) {
          results.add(algorithmInfo);
        }
      } catch (e) {
        debugPrint("Error fetching factory algorithm $i: $e");
      }
    }

    // Synchronous community algorithm loading
    for (int i in communityIndices) {
      try {
        final algorithmInfo = await manager.requestAlgorithmInfo(i);
        if (algorithmInfo != null) {
          results.add(algorithmInfo);
        }
      } catch (e) {
        debugPrint("Error fetching community algorithm $i: $e");
      }
    }

    return results;
  }

  // Background loading of ALL algorithms with prioritization and state merging
  Future<void> _loadAllAlgorithmsInBackground(
      IDistingMidiManager manager, int numAlgorithms) async {
    debugPrint(
        "[Cubit] Starting background loading for all $numAlgorithms algorithms");

    final List<AlgorithmInfo> factoryResults = [];
    final List<AlgorithmInfo> communityResults = [];

    // Load all algorithms with prioritization (factory first, then community)
    for (int i = 0; i < numAlgorithms; i++) {
      try {
        final algorithmInfo = await manager.requestAlgorithmInfo(i);
        if (algorithmInfo != null) {
          if (_isFactoryAlgorithm(algorithmInfo.guid)) {
            factoryResults.add(algorithmInfo);

            // Update state immediately when we get factory algorithms
            final currentState = state;
            if (currentState is DistingStateSynchronized &&
                !currentState.offline) {
              final currentAlgorithms = [
                ...factoryResults,
                ...communityResults
              ];
              emit(currentState.copyWith(algorithms: currentAlgorithms));
              debugPrint(
                  "[Cubit] Updated state with factory algorithm: ${algorithmInfo.name} (${factoryResults.length} factory total)");
            }
          } else {
            communityResults.add(algorithmInfo);

            // Update state when we get community plugins too
            final currentState = state;
            if (currentState is DistingStateSynchronized &&
                !currentState.offline) {
              final currentAlgorithms = [
                ...factoryResults,
                ...communityResults
              ];
              emit(currentState.copyWith(algorithms: currentAlgorithms));
              debugPrint(
                  "[Cubit] Updated state with community plugin: ${algorithmInfo.name} (${communityResults.length} community total)");
            }
          }
        }
      } catch (e) {
        debugPrint("[Cubit] Failed to load algorithm at index $i: $e");
        // Continue with next algorithm
      }
    }

    final totalLoaded = factoryResults.length + communityResults.length;
    debugPrint(
        "[Cubit] Background algorithm loading complete: ${factoryResults.length} factory + ${communityResults.length} community = $totalLoaded total");
  }

  // Background loading of community plugins with single retry and state merging
  Future<void> _loadCommunityPluginsInBackground(IDistingMidiManager manager,
      List<int> communityIndices, List<AlgorithmInfo> baseResults) async {
    debugPrint(
        "[Cubit] Starting background community plugin loading for ${communityIndices.length} plugins");

    final List<AlgorithmInfo> communityResults = [];

    for (int i in communityIndices) {
      try {
        // Single attempt to fetch community plugin
        final algorithmInfo = await manager.requestAlgorithmInfo(i);
        if (algorithmInfo != null) {
          communityResults.add(algorithmInfo);
          debugPrint(
              "[Cubit] Successfully loaded community plugin: ${algorithmInfo.name} (${algorithmInfo.guid})");
        }
      } catch (e) {
        debugPrint(
            "[Cubit] Failed to load community plugin at index $i (single attempt): $e");
        // Move on to next plugin - no retry
      }
    }

    // Merge results and update state if still synchronized
    if (communityResults.isNotEmpty) {
      final mergedResults = [...baseResults, ...communityResults];
      debugPrint(
          "[Cubit] Background loading complete. Merging ${communityResults.length} community plugins with ${baseResults.length} factory algorithms");

      // Only update state if we're still in synchronized mode and not offline
      final currentState = state;
      if (currentState is DistingStateSynchronized && !currentState.offline) {
        emit(currentState.copyWith(algorithms: mergedResults));
        debugPrint(
            "[Cubit] State updated with ${mergedResults.length} total algorithms");
      }
    } else {
      debugPrint(
          "[Cubit] No community plugins successfully loaded in background");
    }
  }

  // Helper to fetch AlgorithmInfo list from mock/offline manager
  Future<List<AlgorithmInfo>> _fetchMockAlgorithms(
      IDistingMidiManager manager) async {
    return _fetchAlgorithmsWithPriority(manager);
  }

  Future<void> loadDevices() async {
    try {
      // Transition to a loading state if needed
      emit(const DistingState.initial());

      // Fetch devices using the helper
      final devices = await _fetchDeviceLists(); // Call helper

      // Re-check offline capability here for manual refresh accuracy
      final bool canWorkOffline = await _metadataDao.hasCachedAlgorithms();

      // Transition to the select device state
      emit(DistingState.selectDevice(
        inputDevices: devices['input'] ?? [],
        outputDevices: devices['output'] ?? [],
        canWorkOffline: canWorkOffline, // Pass the flag here
      ));
    } catch (e, stackTrace) {
      debugPrintStack(stackTrace: stackTrace);
      // Emit default state on error
      emit(const DistingState.selectDevice(
        inputDevices: [],
        outputDevices: [],
        canWorkOffline: false,
      ));
    }
  }

  Future<Uint8List?> getHardwareScreenshot() async {
    final disting = requireDisting();
    await disting.requestWake();
    final screenshot = await disting.encodeTakeScreenshot();
    return screenshot;
  }

  Future<void> updateScreenshot() async {
    final disting = requireDisting();
    await disting.requestWake();
    final screenshot = await disting.encodeTakeScreenshot();
    switch (state) {
      case DistingStateSynchronized syncstate:
        emit(syncstate.copyWith(screenshot: screenshot));
        break;
      default:
      // Handle other cases or errors
    }
  }

  /// Gets the current CPU usage information from the Disting device.
  /// Returns null if the device is not connected or if the request fails.
  /// Only works when connected to a physical device (not in offline or demo mode).
  Future<CpuUsage?> getCpuUsage() async {
    final currentState = state;
    if (currentState is! DistingStateSynchronized) {
      debugPrint("[Cubit] Cannot get CPU usage: Not in synchronized state.");
      return null;
    }

    if (currentState.offline || currentState.demo) {
      debugPrint(
          "[Cubit] Cannot get CPU usage: Device is offline or in demo mode.");
      return null;
    }

    try {
      final disting = requireDisting();
      await disting.requestWake();
      final cpuUsage = await disting.requestCpuUsage();
      return cpuUsage;
    } catch (e, stackTrace) {
      debugPrint("Error getting CPU usage: $e");
      debugPrintStack(stackTrace: stackTrace);
      return null;
    }
  }

  void disconnect() {
    switch (state) {
      case DistingStateInitial():
      case DistingStateSelectDevice():
        break;
      case DistingStateConnected connectedState:
        connectedState.disting.dispose();
        break;
      case DistingStateSynchronized syncstate:
        syncstate.disting.dispose();
        break;
    }
    _midiCommand.dispose();
    _midiCommand = MidiCommand();
  }

  // Private helper to perform the full synchronization and emit the state
  Future<void> _performSyncAndEmit() async {
    final currentState = state;
    MidiDevice? inputDevice; // Variables to hold devices from state
    MidiDevice? outputDevice;

    if (currentState is DistingStateConnected) {
      inputDevice = currentState.inputDevice;
      outputDevice = currentState.outputDevice;
    } else if (currentState is DistingStateSynchronized &&
        !currentState.offline) {
      inputDevice = currentState.inputDevice;
      outputDevice = currentState.outputDevice;
    } else {
      debugPrint("[Cubit] Cannot sync: Invalid state or offline.");
      return;
    }

    // Now state is confirmed, get manager
    final IDistingMidiManager distingManager = requireDisting();

    try {
      // --- Fetch ALL data from device REGARDLESS ---
      debugPrint("[Cubit] _performSyncAndEmit: Fetching full device state...");

      // Start background algorithm loading (slots will have their own algorithm info)
      List<AlgorithmInfo> algorithms = [];
      int numInPreset = 0;
      try {
        final numAlgorithms =
            await distingManager.requestNumberOfAlgorithms() ?? 0;
        numInPreset = await distingManager.requestNumAlgorithmsInPreset() ?? 0;

        debugPrint(
            "[Cubit] Found $numAlgorithms total algorithms, $numInPreset in preset");

        // Start background loading for ALL algorithms (slots contain their own algorithm info for UI)
        if (numAlgorithms > 0) {
          _loadAllAlgorithmsInBackground(distingManager, numAlgorithms);
        }

        debugPrint(
            "[Cubit] Background algorithm loading started, continuing with device sync");
      } catch (e, stackTrace) {
        debugPrint("Error starting algorithm background loading: $e");
        debugPrintStack(stackTrace: stackTrace);
      }

      final distingVersion = await distingManager.requestVersionString() ?? "";
      final presetName = await distingManager.requestPresetName() ?? "Default";
      var unitStrings = await distingManager.requestUnitStrings() ?? [];
      List<Slot> slots = await fetchSlots(numInPreset, distingManager);
      debugPrint("[Cubit] _performSyncAndEmit: Fetched ${slots.length} slots.");

      // --- Emit final synchronized state --- (Ensure offline is false)
      emit(DistingState.synchronized(
        disting: distingManager,
        distingVersion: distingVersion,
        firmwareVersion: FirmwareVersion(distingVersion),
        presetName: presetName,
        algorithms: algorithms,
        slots: slots,
        unitStrings: unitStrings,
        inputDevice: inputDevice,
        outputDevice: outputDevice,
        loading: false,
        offline: false,
      ));

      // Start background retry processing for any failed parameter requests
      if (_parameterRetryQueue.isNotEmpty) {
        debugPrint(
            '[Cubit] Starting background retry processing for ${_parameterRetryQueue.length} failed requests');
        _processParameterRetryQueue(distingManager).catchError((e) {
          debugPrint('[Cubit] Background retry processing failed: $e');
        });
      }
    } catch (e, stackTrace) {
      debugPrint("Error during synchronization: $e");
      debugPrintStack(stackTrace: stackTrace);
      // Do NOT store connection details if sync fails
      await loadDevices();
    }
  }

  Future<void> connectToDevices(
      MidiDevice inputDevice, MidiDevice outputDevice, int sysExId) async {
    // Get the potentially existing manager AND devices from the CURRENT state
    final currentState = state;
    MidiDevice? existingInputDevice;
    MidiDevice? existingOutputDevice;
    if (currentState is DistingStateConnected) {
      existingInputDevice = currentState.inputDevice;
      existingOutputDevice = currentState.outputDevice;
    } else if (currentState is DistingStateSynchronized) {
      existingInputDevice = currentState.inputDevice;
      existingOutputDevice = currentState.outputDevice;
    }
    final existingManager = disting(); // Get manager separately

    try {
      // Disconnect and dispose any existing managers first
      if (existingManager != null) {
        // Explicitly disconnect devices using devices read from the state
        if (existingInputDevice != null) {
          _midiCommand.disconnectDevice(existingInputDevice);
        }
        // Avoid disconnecting same device twice
        if (existingOutputDevice != null &&
            existingOutputDevice.id != existingInputDevice?.id) {
          _midiCommand.disconnectDevice(existingOutputDevice);
        }
        existingManager.dispose(); // Dispose the old manager
      }
      _offlineManager?.dispose(); // Explicitly dispose offline if it exists
      _offlineManager = null;

      // Connect to the selected device
      await _midiCommand.connectToDevice(inputDevice);
      if (inputDevice != outputDevice) {
        await _midiCommand.connectToDevice(outputDevice);
      }
      final prefs = await _prefs;
      await prefs.setString('selectedInputMidiDevice', inputDevice.name);
      await prefs.setString('selectedOutputMidiDevice', outputDevice.name);
      await prefs.setInt('selectedSysExId', sysExId);

      // Create the NEW online manager
      final newDistingManager = DistingMidiManager(
          midiCommand: _midiCommand,
          inputDevice: inputDevice,
          outputDevice: outputDevice,
          sysExId: sysExId);

      // Emit Connected state WITH the new manager AND devices
      emit(DistingState.connected(
        disting: newDistingManager,
        inputDevice: inputDevice, // Store connected devices
        outputDevice: outputDevice,
        offline: false,
      ));

      // Create parameter queue for the new manager
      _createParameterQueue();

      // Store these details as the last successful ONLINE connection
      // BEFORE starting the full sync.
      _lastOnlineInputDevice = inputDevice;
      _lastOnlineOutputDevice = outputDevice;
      _lastOnlineSysExId = sysExId; // Use the parameter passed to this method

      // Synchronize device clock with system time
      try {
        final now = DateTime.now();
        final currentUnixTime = now.millisecondsSinceEpoch ~/ 1000 + now.timeZoneOffset.inSeconds;
        await newDistingManager.requestSetRealTimeClock(currentUnixTime);
        debugPrint(
            "[DistingCubit] Device clock synchronized to $currentUnixTime (local time adjusted)");
      } catch (e) {
        debugPrint("[DistingCubit] Failed to synchronize device clock: $e");
        // Continue with connection even if clock sync fails
      }

      await _performSyncAndEmit(); // Sync with the new connection
    } catch (e, stackTrace) {
      debugPrint("Error connecting or initial sync: ${e.toString()}");
      debugPrintStack(stackTrace: stackTrace);
      // Clear last connection details if connection/sync fails
      _lastOnlineInputDevice = null;
      _lastOnlineOutputDevice = null;
      _lastOnlineSysExId = null;
      // Attempt to clean up MIDI connection on error too
      try {
        _midiCommand.disconnectDevice(inputDevice);
        if (inputDevice != outputDevice) {
          _midiCommand.disconnectDevice(outputDevice);
        }
      } catch (disconnectError) {
        debugPrint("Error during MIDI disconnect cleanup: $disconnectError");
      }
      await loadDevices();
    }
  }

  // --- Offline Mode Handling ---

  Future<void> goOffline() async {
    final currentState = state;
    if (currentState is DistingStateSynchronized && currentState.offline) {
      return; // Already offline
    }

    // Get devices and manager from CURRENT state before changing it
    MidiDevice? currentInputDevice;
    MidiDevice? currentOutputDevice;
    IDistingMidiManager? currentManager = disting(); // Get current manager

    if (currentState is DistingStateConnected) {
      currentInputDevice = currentState.inputDevice;
      currentOutputDevice = currentState.outputDevice;
    } else if (currentState is DistingStateSynchronized) {
      currentInputDevice = currentState.inputDevice;
      currentOutputDevice = currentState.outputDevice;
    }

    debugPrint("[DistingCubit] Entering offline mode...");
    emit(DistingState.connected(
        disting: MockDistingMidiManager(), loading: true));

    try {
      // Disconnect existing MIDI connection IF devices were present
      if (currentManager != null) {
        // Check if there *was* a manager
        if (currentInputDevice != null) {
          debugPrint(
              "[DistingCubit] Disconnecting input device ${currentInputDevice.name}...");
          _midiCommand.disconnectDevice(currentInputDevice);
        }
        if (currentOutputDevice != null &&
            currentOutputDevice.id != currentInputDevice?.id) {
          debugPrint(
              "[DistingCubit] Disconnecting output device ${currentOutputDevice.name}...");
          _midiCommand.disconnectDevice(currentOutputDevice);
        }
        currentManager.dispose(); // Dispose the old manager (online or offline)
      }
      _offlineManager
          ?.dispose(); // Ensure offline is disposed if manager wasn't it

      // Create and initialize the offline manager
      _offlineManager = OfflineDistingMidiManager(database);
      await _offlineManager!.initializeFromDb(null);
      final version =
          await _offlineManager!.requestVersionString() ?? "Offline";
      final units = await _offlineManager!.requestUnitStrings() ?? [];
      final availableAlgorithmsInfo = await _fetchOfflineAlgorithms();
      final presetName =
          await _offlineManager!.requestPresetName() ?? "Offline Preset";
      final numAlgorithmsInPreset =
          await _offlineManager!.requestNumAlgorithmsInPreset() ?? 0;
      final List<Slot> initialSlots =
          await fetchSlots(numAlgorithmsInPreset, _offlineManager!);

      debugPrint("[DistingCubit] Emitting offline synchronized state.");
      // Emit state WITHOUT devices or custom names map
      emit(DistingState.synchronized(
        disting: _offlineManager!,
        // Use offline manager
        distingVersion: version,
        firmwareVersion: FirmwareVersion(version),
        presetName: presetName,
        algorithms: availableAlgorithmsInfo,
        slots: initialSlots,
        unitStrings: units,
        inputDevice: null,
        // No devices when offline
        outputDevice: null,
        offline: true,
        loading: false,
      ));

      // Create parameter queue for offline manager
      _createParameterQueue();
    } catch (e, stackTrace) {
      debugPrint("Error initializing offline mode: $e");
      debugPrintStack(stackTrace: stackTrace);
      await loadDevices();
    }
  }

  Future<void> goOnline() async {
    final currentState = state;
    if (!(currentState is DistingStateSynchronized && currentState.offline)) {
      // Only proceed if currently offline and synchronized
      // If already online or in a different state, loadDevices handles it
      await loadDevices();
      return;
    }
    debugPrint("[DistingCubit] Going online...");

    // Dispose offline manager first
    _offlineManager?.dispose();
    _offlineManager = null;

    // Check if we have details from the last online session
    if (_lastOnlineInputDevice != null &&
        _lastOnlineOutputDevice != null &&
        _lastOnlineSysExId != null) {
      debugPrint(
          "Attempting to reconnect using last known online connection...");
      try {
        // Attempt direct connection using stored details
        await connectToDevices(
            _lastOnlineInputDevice!,
            _lastOnlineOutputDevice!,
            _lastOnlineSysExId!); // Use stored details
        // If connectToDevices succeeds, it will emit the connected/synchronized state
        return; // Successfully reconnected
      } catch (e) {
        debugPrint(
            "Failed to reconnect using last known details: $e. Falling back to device selection.");
        // Clear potentially stale details if reconnection failed
        _lastOnlineInputDevice = null;
        _lastOnlineOutputDevice = null;
        _lastOnlineSysExId = null;
        // Fall through to loadDevices below
      }
    }

    // If no last connection details or direct reconnect failed, load devices normally
    debugPrint("No valid last connection details, proceeding to loadDevices.");
    disconnect(); // Ensure any residual MIDI connection is closed
    await loadDevices(); // Go back to device selection / auto-connect
  }

  Future<void> cancelSync() async {
    disconnect();
    await loadDevices();
  }

  Future<void> loadPresetOffline(FullPresetDetails presetDetails) async {
    final currentState = state;
    if (!(currentState is DistingStateSynchronized && currentState.offline)) {
      debugPrint("Error: Cannot load preset offline when not in offline mode.");
      return;
    }
    if (_offlineManager == null) {
      debugPrint("Error: Offline manager not initialized.");
      return;
    }

    debugPrint(
        "[DistingCubit] Loading preset offline: ${presetDetails.preset.name}");
    emit(currentState.copyWith(loading: true)); // Show loading

    try {
      // 1. Tell the offline manager to load the preset
      await _offlineManager!.initializeFromDb(presetDetails);

      // 2. Fetch the updated state FROM the manager
      final presetName = await _offlineManager!.requestPresetName() ?? "Error";
      final numAlgorithmsInPreset =
          await _offlineManager!.requestNumAlgorithmsInPreset() ?? 0;
      final slots = await fetchSlots(numAlgorithmsInPreset, _offlineManager!);

      // 3. Re-fetch metadata (algorithms and units don't change)
      final availableAlgorithmsInfo = await _fetchOfflineAlgorithms();
      final units = await _offlineManager!.requestUnitStrings() ?? [];
      final version =
          await _offlineManager!.requestVersionString() ?? "Offline";

      debugPrint(
          "[DistingCubit] Emitting updated offline state with loaded preset: $presetName");
      // 4. Emit the new synchronized state, still marked offline
      emit(DistingState.synchronized(
        disting: _offlineManager!,
        distingVersion: version,
        firmwareVersion: FirmwareVersion(version),
        presetName: presetName,
        algorithms: availableAlgorithmsInfo,
        slots: slots,
        unitStrings: units,
        offline: true,
        // Remain offline
        loading: false,
        screenshot: currentState.screenshot,
        // Preserve screenshot if any
        demo: currentState.demo, // Preserve demo status if any
      ));
    } catch (e, stackTrace) {
      debugPrint("Error loading preset offline: $e");
      debugPrintStack(stackTrace: stackTrace);
      emit(currentState.copyWith(loading: false)); // Stop loading on error
    }
  }

  // Helper to fetch algorithm metadata for offline mode
  Future<List<AlgorithmInfo>> _fetchOfflineAlgorithms() async {
    try {
      final allBasicAlgoEntries = await _metadataDao.getAllAlgorithms();
      final List<AlgorithmInfo> availableAlgorithmsInfo = [];

      final detailedFutures = allBasicAlgoEntries.map((basicEntry) async {
        return await _metadataDao.getFullAlgorithmDetails(basicEntry.guid);
      }).toList();

      final detailedResults = await Future.wait(detailedFutures);

      for (final details in detailedResults.whereType<FullAlgorithmDetails>()) {
        availableAlgorithmsInfo.add(AlgorithmInfo(
          guid: details.algorithm.guid,
          name: details.algorithm.name,
          algorithmIndex: -1,
          specifications: details.specifications
              .map((specEntry) => Specification(
                    name: specEntry.name,
                    min: specEntry.minValue,
                    max: specEntry.maxValue,
                    defaultValue: specEntry.defaultValue,
                    type: specEntry.type,
                  ))
              .toList(),
        ));
      }
      availableAlgorithmsInfo
          .sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return availableAlgorithmsInfo;
    } catch (e, stackTrace) {
      debugPrint("Error fetching offline algorithms metadata: $e");
      debugPrintStack(stackTrace: stackTrace);
      return []; // Return empty on error
    }
  }

  /// Refreshes the state from the Disting device (ONLINE ONLY).
  /// By default, performs a fast refresh of preset data only.
  /// Set [fullRefresh] to true to also re-download the algorithm library.
  Future<void> refresh({bool fullRefresh = false}) async {
    debugPrint("[Cubit] Refresh requested (fullRefresh: $fullRefresh).");
    final currentState = state;
    if (currentState is DistingStateSynchronized) {
      // *** Add check for offline mode ***
      if (currentState.offline) {
        debugPrint("[Cubit] Cannot refresh while offline.");
        return;
      }

      if (fullRefresh) {
        // Full refresh: re-download everything including algorithm library
        await _performSyncAndEmit();
      } else {
        // Fast refresh: only update preset data, then optionally refresh algorithms in background
        await _refreshStateFromManager();

        // Check if we should refresh algorithms in the background
        if (_shouldRefreshAlgorithms(currentState)) {
          _refreshAlgorithmsInBackground();
        }
      }
    } else {
      debugPrint("[Cubit] Cannot refresh: Not in Synchronized state.");
      // Optionally handle error or do nothing
    }
  }

  // Helper to create parameter queue for current manager
  void _createParameterQueue() {
    final manager = disting();
    if (manager != null) {
      _parameterQueue?.dispose();
      _parameterQueue = ParameterUpdateQueue(
        midiManager: manager,
        onParameterStringUpdated: _onParameterStringUpdated,
      );
      debugPrint('[DistingCubit] Created parameter update queue');
    }
  }

  // Helper to determine if algorithm library should be refreshed
  bool _shouldRefreshAlgorithms(DistingStateSynchronized currentState) {
    // For now, be conservative and only refresh algorithms if the list is empty
    // In the future, we could add more sophisticated logic like checking timestamps,
    // firmware version changes, or comparing algorithm counts
    return currentState.algorithms.isEmpty;
  }

  // Background refresh of algorithm library without blocking the UI
  void _refreshAlgorithmsInBackground() {
    debugPrint("[Cubit] Starting background algorithm refresh...");

    // Run asynchronously without awaiting
    () async {
      try {
        final currentState = state;
        if (currentState is! DistingStateSynchronized || currentState.offline) {
          return; // State changed, abort
        }

        final distingManager = requireDisting();

        // Fetch algorithm info in the background with prioritization
        try {
          final algorithms = await _fetchAlgorithmsWithPriority(distingManager,
              enableBackgroundCommunityLoading: true);

          // Only update if state is still synchronized and algorithms changed
          final newState = state;
          if (newState is DistingStateSynchronized &&
              !newState.offline &&
              algorithms.length != newState.algorithms.length) {
            debugPrint(
                "[Cubit] Background algorithm refresh completed, updating state with ${algorithms.length} algorithms.");
            emit(newState.copyWith(algorithms: algorithms));
          }
        } catch (e, stackTrace) {
          debugPrint(
              "Error during background algorithm refresh (continuing normally): $e");
          debugPrintStack(stackTrace: stackTrace);
          // Don't update state on algorithm fetch failure during background refresh
        }
      } catch (e, stackTrace) {
        debugPrint("Error during background algorithm refresh: $e");
        debugPrintStack(stackTrace: stackTrace);
        // Don't emit error state for background refresh failures
      }
    }();
  }

  // Handle parameter string updates from the queue
  void _onParameterStringUpdated(
      int algorithmIndex, int parameterNumber, String value) {
    final currentState = state;
    if (currentState is! DistingStateSynchronized) return;

    if (algorithmIndex < 0 || algorithmIndex >= currentState.slots.length) {
      return;
    }

    final currentSlot = currentState.slots[algorithmIndex];
    if (parameterNumber < 0 ||
        parameterNumber >= currentSlot.valueStrings.length) {
      return;
    }

    try {
      // Update the parameter string in the UI
      final updatedValueStrings =
          List<ParameterValueString>.from(currentSlot.valueStrings);
      updatedValueStrings[parameterNumber] = ParameterValueString(
        algorithmIndex: algorithmIndex,
        parameterNumber: parameterNumber,
        value: value,
      );

      final updatedSlot =
          currentSlot.copyWith(valueStrings: updatedValueStrings);
      final updatedSlots = List<Slot>.from(currentState.slots);
      updatedSlots[algorithmIndex] = updatedSlot;

      emit(currentState.copyWith(slots: updatedSlots));

      debugPrint(
          '[DistingCubit] Updated parameter string UI for $algorithmIndex:$parameterNumber = "$value"');
    } catch (e, stackTrace) {
      debugPrint('[DistingCubit] Error updating parameter string UI: $e');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  IDistingMidiManager requireDisting() {
    final d = disting();
    if (d == null) {
      throw Exception("Disting not connected");
    }
    return d;
  }

  IDistingMidiManager? disting() {
    return switch (state) {
      DistingStateConnected(disting: final d) => d,
      DistingStateSynchronized(disting: final d) => d,
      _ => null,
    };
  }

  List<T> replaceInList<T>(
    List<T> original,
    T element, {
    required int index,
  }) {
    if (index < 0 || index > original.length) {
      throw RangeError.index(index, original, "index out of bounds");
    }

    return [
      ...original.sublist(0, index),
      element,
      ...original.sublist(index + 1)
    ];
  }

  List<Slot> updateSlot(int algorithmIndex, List<Slot> slots,
      Slot Function(Slot) updateFunction) {
    return [
      ...slots.sublist(0, algorithmIndex),
      updateFunction(slots[algorithmIndex]),
      ...slots.sublist(algorithmIndex + 1),
    ];
  }

  Future<void> updateParameterValue({
    required int algorithmIndex,
    required int parameterNumber,
    required int value,
    required bool userIsChangingTheValue,
  }) async {
    // Acquire semaphore to block retry queue during user parameter updates
    _acquireCommandSemaphore();

    try {
      debugPrint("value = $value, userChanging = $userIsChangingTheValue");

      switch (state) {
        case DistingStateInitial():
        case DistingStateSelectDevice():
        case DistingStateConnected():
          break;
        case DistingStateSynchronized syncstate:
          var disting = requireDisting();

          // Always queue the parameter update for sending to device
          final currentSlot = syncstate.slots[algorithmIndex];
          final needsStringUpdate =
              parameterNumber < currentSlot.parameters.length &&
                  [13, 14, 17]
                      .contains(currentSlot.parameters[parameterNumber].unit);

          _parameterQueue?.updateParameter(
            algorithmIndex: algorithmIndex,
            parameterNumber: parameterNumber,
            value: value,
            needsStringUpdate: needsStringUpdate,
          );

          if (userIsChangingTheValue) {
            // Optimistic update during slider movement - just update the UI
            final newValue = ParameterValue(
              algorithmIndex: algorithmIndex,
              parameterNumber: parameterNumber,
              value: value,
            );

            emit(syncstate.copyWith(
              slots: updateSlot(
                algorithmIndex,
                syncstate.slots,
                (slot) {
                  return slot.copyWith(
                    values: replaceInList(
                      slot.values,
                      newValue,
                      index: parameterNumber,
                    ),
                  );
                },
              ),
            ));
          } else {
            // When user releases slider - do minimal additional processing

            // Special case for switching programs
            if (_isProgramParameter(
                syncstate, algorithmIndex, parameterNumber)) {
              _programSlotUpdate?.cancel();

              _programSlotUpdate =
                  CancelableOperation.fromFuture(Future.delayed(
                Duration(seconds: 2),
                () async {
                  final updatedSlot = await fetchSlot(disting, algorithmIndex);

                  emit(syncstate.copyWith(
                    slots: updateSlot(
                      algorithmIndex,
                      syncstate.slots,
                      (slot) {
                        return updatedSlot;
                      },
                    ),
                  ));
                },
              ));
            }

            // Anomaly Check - using the value we're setting
            if (parameterNumber < currentSlot.parameters.length) {
              final parameterInfo =
                  currentSlot.parameters.elementAt(parameterNumber);
              if (value < parameterInfo.min || value > parameterInfo.max) {
                debugPrint(
                    "Out-of-bounds data for device: algo $algorithmIndex, param $parameterNumber, value $value, expected ${parameterInfo.min}-${parameterInfo.max}");
                _refreshSlotAfterAnomaly(algorithmIndex);
                return; // Return early as the slot will be refreshed
              }
            }

            // Update UI with the final value immediately (optimistic)
            final newValue = ParameterValue(
              algorithmIndex: algorithmIndex,
              parameterNumber: parameterNumber,
              value: value,
            );

            emit(syncstate.copyWith(
              slots: updateSlot(
                algorithmIndex,
                syncstate.slots,
                (slot) {
                  return slot.copyWith(
                    values: replaceInList(
                      slot.values,
                      newValue,
                      index: parameterNumber,
                    ),
                  );
                },
              ),
            ));

            // The parameter queue will handle:
            // 1. Sending the parameter value to device
            // 2. Querying parameter string if needed
            // 3. Rate limiting and consolidation
          }
      }
    } finally {
      // Always release semaphore to allow retry queue to proceed
      _releaseCommandSemaphore();
    }
  }

  Future<void> onAlgorithmSelected(
    AlgorithmInfo algorithm,
    List<int> specifications,
  ) async {
    switch (state) {
      case DistingStateInitial():
      case DistingStateSelectDevice():
      case DistingStateConnected():
        break;
      case DistingStateSynchronized syncstate:
        final disting = syncstate.disting;
        List<int> specsToSend = specifications;

        // *** Adjust for offline: Use stored default specs if offline ***
        if (syncstate.offline) {
          final storedAlgoInfo = syncstate.algorithms.firstWhereOrNull(
            (a) => a.guid == algorithm.guid,
          );
          if (storedAlgoInfo != null) {
            specsToSend = storedAlgoInfo.specifications
                .map((s) => s.defaultValue)
                .toList();
            debugPrint(
                "[Offline Cubit] Using stored default specifications for ${algorithm.name}: $specsToSend");
          } else {
            debugPrint(
                "[Offline Cubit] Warning: Could not find stored AlgorithmInfo for ${algorithm.name}. Using passed specifications.");
          }
        }

        // Send the add algorithm request
        await disting.requestAddAlgorithm(algorithm, specsToSend);

        // Optimistic update: fetch just the new slot that was added
        try {
          final newSlotIndex =
              syncstate.slots.length; // New slot will be at the end
          final newSlot = await fetchSlot(disting, newSlotIndex);

          // Update state with the new slot appended
          final updatedSlots = [...syncstate.slots, newSlot];
          emit(syncstate.copyWith(slots: updatedSlots, loading: false));

          debugPrint(
              "[Cubit] Added algorithm '${algorithm.name}' to slot $newSlotIndex");
        } catch (e, stackTrace) {
          debugPrint("Error fetching new slot after adding algorithm: $e");
          debugPrintStack(stackTrace: stackTrace);
          // Fall back to full refresh on error
          await _refreshStateFromManager();
        }
        break;
    }
  }

  Future<void> onRemoveAlgorithm(int algorithmIndex) async {
    switch (state) {
      case DistingStateInitial():
      case DistingStateSelectDevice():
      case DistingStateConnected():
        break;
      case DistingStateSynchronized syncstate:
        // Cancel any pending verification from a previous operation
        _moveVerificationOperation?.cancel();

        // 1. Optimistic Update - Remove the slot and fix indices
        List<Slot> optimisticSlots = List.from(syncstate.slots);
        optimisticSlots.removeAt(algorithmIndex);

        // Fix algorithm indices for all slots after the removed one
        for (int i = algorithmIndex; i < optimisticSlots.length; i++) {
          optimisticSlots[i] = _fixAlgorithmIndex(optimisticSlots[i], i);
        }

        // Emit optimistic state
        emit(syncstate.copyWith(slots: optimisticSlots, loading: false));

        // 2. Manager Request
        final disting = requireDisting();
        // Don't await here, let it run in the background
        disting.requestRemoveAlgorithm(algorithmIndex).catchError((e, s) {
          debugPrint("Error sending remove algorithm request: $e");
          // Refresh immediately on error
          _refreshStateFromManager(delay: Duration.zero);
        });

        // 3. Verification
        _moveVerificationOperation = CancelableOperation.fromFuture(
          Future.delayed(const Duration(seconds: 2), () async {
            // Check if state is still synchronized before proceeding
            if (state is! DistingStateSynchronized) return;
            final verificationState = state as DistingStateSynchronized;

            // Only verify if the current state still matches the optimistic one we emitted
            final eq = const DeepCollectionEquality();
            if (!eq.equals(verificationState.slots, optimisticSlots)) {
              debugPrint(
                  "[Cubit Remove Verify] State changed before verification completed. Skipping verification.");
              return;
            }

            debugPrint(
                "[Cubit Remove Verify] Verifying optimistic removal of algorithm at index $algorithmIndex...");
            try {
              // Check if the number of algorithms matches our optimistic state
              final actualNumAlgorithms =
                  await disting.requestNumAlgorithmsInPreset() ?? 0;
              if (actualNumAlgorithms != optimisticSlots.length) {
                debugPrint(
                    "[Cubit Remove Verify] Algorithm count mismatch. Expected: ${optimisticSlots.length}, Actual: $actualNumAlgorithms");
                await _refreshStateFromManager(delay: Duration.zero);
                return;
              }

              // Verify GUIDs and Names for remaining slots
              bool mismatchDetected = false;
              for (int i = 0; i < optimisticSlots.length; i++) {
                final actualAlgorithm = await disting.requestAlgorithmGuid(i);
                final optimisticAlgorithm = optimisticSlots[i].algorithm;

                if (actualAlgorithm == null ||
                    actualAlgorithm.guid != optimisticAlgorithm.guid ||
                    actualAlgorithm.name != optimisticAlgorithm.name) {
                  mismatchDetected = true;
                  debugPrint(
                      "[Cubit Remove Verify] Mismatch detected at index $i. Expected: '${optimisticAlgorithm.name}' (GUID: ${optimisticAlgorithm.guid}), Actual: '${actualAlgorithm?.name ?? 'NULL'}' (GUID: ${actualAlgorithm?.guid ?? 'NULL'})");
                  break;
                }
              }

              if (mismatchDetected) {
                debugPrint(
                    "[Cubit Remove Verify] Optimistic state INCORRECT based on GUID/Name check. Reverting to actual state.");
                await _refreshStateFromManager(delay: Duration.zero);
              } else {
                debugPrint("[Cubit Remove Verify] Optimistic state CORRECT.");
              }
            } catch (e, stackTrace) {
              debugPrint("[Cubit Remove Verify] Error during verification: $e");
              debugPrintStack(stackTrace: stackTrace);
              await _refreshStateFromManager(delay: Duration.zero);
            }
          }),
          onCancel: () =>
              debugPrint("[Cubit Remove Verify] Verification cancelled."),
        );
        break;
    }
  }

  void renamePreset(String newName) async {
    final currentState = state;
    if (currentState is DistingStateSynchronized) {
      final disting = currentState.disting;
      // Allow renaming offline, OfflineDistingMidiManager handles it
      disting.requestSetPresetName(newName);

      await Future.delayed(
          const Duration(milliseconds: 50)); // Shorter delay okay?
      await _refreshStateFromManager(); // Refresh state from manager
    }
  }

  Future<int> moveAlgorithmUp(int algorithmIndex) async {
    debugPrint("moveAlgorithmUp $algorithmIndex");

    final currentState = state;
    if (currentState is! DistingStateSynchronized) return algorithmIndex;
    if (algorithmIndex == 0) return 0;

    // Cancel any pending verification from a previous move
    _moveVerificationOperation?.cancel();

    final syncstate = currentState;
    final slots = syncstate.slots;

    // 1. Optimistic Update
    // Identify the two slots involved in the swap
    final slotToMove = slots[algorithmIndex];
    final slotToSwapWith = slots[algorithmIndex - 1];

    // Create corrected versions with updated internal indices
    final correctedMovedSlot =
        _fixAlgorithmIndex(slotToMove, algorithmIndex - 1);
    final correctedSwappedSlot =
        _fixAlgorithmIndex(slotToSwapWith, algorithmIndex);

    // Build the new list with only the swapped slots corrected and reordered
    List<Slot> optimisticSlotsCorrected = List.from(slots); // Start with a copy
    optimisticSlotsCorrected[algorithmIndex - 1] =
        correctedMovedSlot; // Moved slot goes to the upper position
    optimisticSlotsCorrected[algorithmIndex] =
        correctedSwappedSlot; // Swapped slot goes to the lower position

    // Emit optimistic state
    emit(syncstate.copyWith(slots: optimisticSlotsCorrected, loading: false));

    // 2. Manager Request
    final disting = requireDisting();
    // Don't await here, let it run in the background
    disting.requestMoveAlgorithmUp(algorithmIndex).catchError((e, s) {
      debugPrint("Error sending move up request: $e");
      // Optionally trigger a full refresh on error?
      _refreshStateFromManager(
          delay: Duration.zero); // Refresh immediately on error
    });

    // 3. Verification
    _moveVerificationOperation = CancelableOperation.fromFuture(
      Future.delayed(const Duration(seconds: 2), () async {
        // Check if state is still synchronized before proceeding
        if (state is! DistingStateSynchronized) return;
        final verificationState = state as DistingStateSynchronized;

        // Only verify if the current state *still* matches the optimistic one we emitted.
        // If it changed due to user interaction or another update, the verification is moot.
        // Use a deep equality check for the slots.
        final eq = const DeepCollectionEquality();
        if (!eq.equals(verificationState.slots, optimisticSlotsCorrected)) {
          debugPrint(
              "[Cubit Move Verify] State changed before verification completed. Skipping verification.");
          return;
        }

        debugPrint(
            "[Cubit Move Verify] Verifying optimistic move up for index $algorithmIndex...");
        try {
          // --- Verification: Check GUIDs and Names ---
          bool mismatchDetected = false;
          for (int i = 0; i < optimisticSlotsCorrected.length; i++) {
            final actualAlgorithm = await disting.requestAlgorithmGuid(i);
            final optimisticAlgorithm = optimisticSlotsCorrected[i].algorithm;

            // Compare GUID and Name
            if (actualAlgorithm == null ||
                actualAlgorithm.guid != optimisticAlgorithm.guid ||
                actualAlgorithm.name != optimisticAlgorithm.name) {
              mismatchDetected = true;
              debugPrint(
                  "[Cubit Move Verify] Mismatch detected at index $i. Expected: '${optimisticAlgorithm.name}' (GUID: ${optimisticAlgorithm.guid}), Actual: '${actualAlgorithm?.name ?? 'NULL'}' (GUID: ${actualAlgorithm?.guid ?? 'NULL'})");
              break; // No need to check further
            }
          }
          // --- End Verification ---

          if (mismatchDetected) {
            debugPrint(
                "[Cubit Move Verify] Optimistic state INCORRECT based on GUID/Name check. Reverting to actual state.");
            // If mismatch, only fetch the actual slots, keep other metadata.
            final actualSlots =
                await fetchSlots(optimisticSlotsCorrected.length, disting);

            emit(DistingState.synchronized(
              disting: verificationState.disting,
              // Keep manager and other state
              distingVersion: verificationState.distingVersion,
              firmwareVersion: verificationState.firmwareVersion,
              presetName: verificationState.presetName,
              // Use existing preset name
              algorithms: verificationState.algorithms,
              slots: actualSlots,
              // Use actual slots
              unitStrings: verificationState.unitStrings,
              inputDevice: verificationState.inputDevice,
              outputDevice: verificationState.outputDevice,
              screenshot: verificationState.screenshot,
              loading: false,
              demo: verificationState.demo,
              offline: verificationState.offline,
            ));
          } else {
            debugPrint("[Cubit Move Verify] Optimistic state CORRECT.");
          }
        } catch (e, stackTrace) {
          debugPrint("[Cubit Move Verify] Error during verification: $e");
          debugPrintStack(stackTrace: stackTrace);
          // Optionally trigger a full refresh on verification error?
          // Avoid emitting potentially stale state on error. A full refresh might be safer.
          _refreshStateFromManager(delay: Duration.zero);
        }
      }),
      onCancel: () => debugPrint("[Cubit Move Verify] Verification cancelled."),
    );

    // 4. Return optimistic index
    return algorithmIndex - 1;
  }

  Future<int> moveAlgorithmDown(int algorithmIndex) async {
    debugPrint("moveAlgorithmDown $algorithmIndex");

    final currentState = state;
    if (currentState is! DistingStateSynchronized) return algorithmIndex;
    final syncstate = currentState;
    final slots = syncstate.slots;
    if (algorithmIndex >= slots.length - 1) return algorithmIndex;

    // Cancel any pending verification from a previous move
    _moveVerificationOperation?.cancel();

    // 1. Optimistic Update
    // Identify the two slots involved in the swap
    final slotToMove = slots[algorithmIndex];
    final slotToSwapWith = slots[algorithmIndex + 1];

    // Create corrected versions with updated internal indices
    final correctedMovedSlot =
        _fixAlgorithmIndex(slotToMove, algorithmIndex + 1);
    final correctedSwappedSlot =
        _fixAlgorithmIndex(slotToSwapWith, algorithmIndex);

    // Build the new list with only the swapped slots corrected and reordered
    List<Slot> optimisticSlotsCorrected = List.from(slots); // Start with a copy
    optimisticSlotsCorrected[algorithmIndex] =
        correctedSwappedSlot; // Swapped slot goes to the upper position
    optimisticSlotsCorrected[algorithmIndex + 1] =
        correctedMovedSlot; // Moved slot goes to the lower position

    // Emit optimistic state
    emit(syncstate.copyWith(slots: optimisticSlotsCorrected, loading: false));

    // 2. Manager Request
    final disting = requireDisting();
    // Don't await here, let it run in the background
    disting.requestMoveAlgorithmDown(algorithmIndex).catchError((e, s) {
      debugPrint("Error sending move down request: $e");
      _refreshStateFromManager(
          delay: Duration.zero); // Refresh immediately on error
    });

    // 3. Verification
    _moveVerificationOperation = CancelableOperation.fromFuture(
      Future.delayed(const Duration(seconds: 2), () async {
        if (state is! DistingStateSynchronized) return;
        final verificationState = state as DistingStateSynchronized;

        final eq = const DeepCollectionEquality();
        if (!eq.equals(verificationState.slots, optimisticSlotsCorrected)) {
          debugPrint(
              "[Cubit Move Verify] State changed before verification completed. Skipping verification.");
          return;
        }

        debugPrint(
            "[Cubit Move Verify] Verifying optimistic move down for index $algorithmIndex...");
        try {
          // --- Verification: Check GUIDs and Names ---
          bool mismatchDetected = false;
          for (int i = 0; i < optimisticSlotsCorrected.length; i++) {
            final actualAlgorithm = await disting.requestAlgorithmGuid(i);
            final optimisticAlgorithm = optimisticSlotsCorrected[i].algorithm;

            // Compare GUID and Name
            if (actualAlgorithm == null ||
                actualAlgorithm.guid != optimisticAlgorithm.guid ||
                actualAlgorithm.name != optimisticAlgorithm.name) {
              mismatchDetected = true;
              debugPrint(
                  "[Cubit Move Verify] Mismatch detected at index $i. Expected: '${optimisticAlgorithm.name}' (GUID: ${optimisticAlgorithm.guid}), Actual: '${actualAlgorithm?.name ?? 'NULL'}' (GUID: ${actualAlgorithm?.guid ?? 'NULL'})");
              break; // No need to check further
            }
          }
          // --- End Verification ---

          if (mismatchDetected) {
            debugPrint(
                "[Cubit Move Verify] Optimistic state INCORRECT based on GUID/Name check. Reverting to actual state.");
            // If mismatch, only fetch the actual slots, keep other metadata.
            final actualSlots =
                await fetchSlots(optimisticSlotsCorrected.length, disting);

            emit(DistingState.synchronized(
              disting: verificationState.disting,
              // Keep manager and other state
              distingVersion: verificationState.distingVersion,
              firmwareVersion: verificationState.firmwareVersion,
              presetName: verificationState.presetName,
              // Use existing preset name
              algorithms: verificationState.algorithms,
              slots: actualSlots,
              // Use actual slots
              unitStrings: verificationState.unitStrings,
              inputDevice: verificationState.inputDevice,
              outputDevice: verificationState.outputDevice,
              screenshot: verificationState.screenshot,
              loading: false,
              demo: verificationState.demo,
              offline: verificationState.offline,
            ));
          } else {
            debugPrint("[Cubit Move Verify] Optimistic state CORRECT.");
          }
        } catch (e, stackTrace) {
          debugPrint("[Cubit Move Verify] Error during verification: $e");
          debugPrintStack(stackTrace: stackTrace);
          _refreshStateFromManager(delay: Duration.zero);
        }
      }),
      onCancel: () => debugPrint("[Cubit Move Verify] Verification cancelled."),
    );

    // 4. Return optimistic index
    return algorithmIndex + 1;
  }

  Future<void> newPreset() async {
    final currentState = state;
    if (currentState is DistingStateSynchronized) {
      final disting = requireDisting();
      await disting.requestNewPreset();
      await _refreshStateFromManager(); // Use helper
    } else {
      // Handle other cases or errors
    }
  }

  Future<void> loadPreset(String name, bool append) async {
    final currentState = state;
    if (currentState is DistingStateSynchronized) {
      // Prevent online load preset when offline
      if (currentState.offline) {
        debugPrint("Error: Cannot load device preset while offline.");
        return;
      }
      final disting = requireDisting();

      emit(currentState.copyWith(loading: true));

      await disting.requestLoadPreset(name, append);

      // Use the common refresh helper
      await _refreshStateFromManager();
    } else {
      // Handle other cases or errors
    }
  }

  Future<void> saveMapping(
      int algorithmIndex, int parameterNumber, PackedMappingData data) async {
    switch (state) {
      case DistingStateSynchronized _:
        final disting = requireDisting();
        await disting.requestSetMapping(algorithmIndex, parameterNumber, data);
        await _refreshStateFromManager(); // Refresh state from manager
        break;
      default:
      // Handle other cases or errors
    }
  }

  void renameSlot(int algorithmIndex, String newName) async {
    final currentState = state;
    if (currentState is DistingStateSynchronized) {
      final disting = requireDisting();
      // Send the name update to the manager (online or offline)
      await disting.requestSendSlotName(algorithmIndex, newName);

      // Trigger a refresh to get the updated name from the manager
      await _refreshStateFromManager();
    }
  }

  // --- Helper Methods ---

  // Helper to refresh state from the current manager (online or offline)
  Future<void> _refreshStateFromManager({
    Duration delay = const Duration(milliseconds: 50), // Shorter default delay
  }) async {
    final currentState = state;
    if (currentState is! DistingStateSynchronized) {
      debugPrint("[Cubit] Cannot refresh state: Not in Synchronized state.");
      return;
    }

    emit(currentState.copyWith(loading: true)); // Show loading
    await Future.delayed(delay);

    final disting = currentState.disting; // Could be online or offline

    try {
      final numAlgorithmsInPreset =
          (await disting.requestNumAlgorithmsInPreset()) ?? 0;
      final presetName = await disting.requestPresetName() ?? "Error";
      List<Slot> slots = await fetchSlots(numAlgorithmsInPreset, disting);

      emit(currentState.copyWith(
        loading: false,
        presetName: presetName,
        slots: slots,
        // Keep other fields like disting, version, algorithms, units, offline status
      ));
    } catch (e, stackTrace) {
      debugPrint("Error refreshing state from manager: $e");
      debugPrintStack(stackTrace: stackTrace);
      emit(currentState.copyWith(loading: false)); // Stop loading on error
    }
  }

  List<RoutingInformation> buildRoutingInformation() {
    switch (state) {
      case DistingStateSynchronized syncstate:
        return syncstate.slots
            .where((slot) => slot.routing.algorithmIndex != -1)
            .map((slot) => RoutingInformation(
                algorithmIndex: slot.routing.algorithmIndex,
                routingInfo: slot.routing.routingInfo,
                algorithmName: (slot.algorithm.name.isNotEmpty)
                    ? slot.algorithm.name
                    : syncstate.algorithms
                        .firstWhere(
                          (element) => element.guid == slot.algorithm.guid,
                        )
                        .name))
            .toList();
      default:
        return [];
    }
  }

  bool _isProgramParameter(DistingStateSynchronized state, int algorithmIndex,
          int parameterNumber) =>
      (state.slots[algorithmIndex].parameters[parameterNumber].name ==
          "Program") &&
      (("spin" == state.slots[algorithmIndex].algorithm.guid) ||
          ("lua " == state.slots[algorithmIndex].algorithm.guid));

  Slot _fixAlgorithmIndex(Slot slot, int algorithmIndex) {
    // Run through all of the parts of the slot and replace the algorithm index
    // with the new one by manually constructing new objects.
    return Slot(
      algorithm: slot.algorithm.copyWith(algorithmIndex: algorithmIndex),
      routing: RoutingInfo(
          algorithmIndex: algorithmIndex,
          routingInfo: slot.routing.routingInfo),
      pages: ParameterPages(
          algorithmIndex: algorithmIndex, pages: slot.pages.pages),
      parameters: slot.parameters
          .map((parameter) => ParameterInfo(
              algorithmIndex: algorithmIndex,
              parameterNumber: parameter.parameterNumber,
              min: parameter.min,
              max: parameter.max,
              defaultValue: parameter.defaultValue,
              unit: parameter.unit,
              name: parameter.name,
              powerOfTen: parameter.powerOfTen))
          .toList(),
      values: slot.values
          .map((value) => ParameterValue(
              algorithmIndex: algorithmIndex,
              parameterNumber: value.parameterNumber,
              value: value.value))
          .toList(),
      enums: slot.enums
          .map((enums) => ParameterEnumStrings(
              algorithmIndex: algorithmIndex,
              parameterNumber: enums.parameterNumber,
              values: enums.values))
          .toList(),
      mappings: slot.mappings
          .map((mapping) => Mapping(
                algorithmIndex: algorithmIndex,
                parameterNumber: mapping.parameterNumber,
                packedMappingData: mapping.packedMappingData,
              ))
          .toList(),
      valueStrings: slot.valueStrings
          .map((valueStrings) => ParameterValueString(
              algorithmIndex: algorithmIndex,
              parameterNumber: valueStrings.parameterNumber,
              value: valueStrings.value))
          .toList(),
    );
  }

  void setDisplayMode(DisplayMode displayMode) {
    requireDisting().let((disting) {
      disting.requestWake();
      disting.requestSetDisplayMode(displayMode);
    });
  }

  List<MappedParameter> buildMappedParameterList() {
    switch (state) {
      case DistingStateSynchronized syncstate:
        // return a list of parameters that have active mappings
        // from the state.
        return syncstate.slots.fold(
          List<MappedParameter>.empty(growable: true),
          (acc, slot) {
            acc.addAll(slot.mappings
                .where((mapping) =>
                    mapping.parameterNumber != -1 &&
                    mapping.packedMappingData.isMapped())
                .map(
              (mapping) {
                var parameterNumber = mapping.parameterNumber;
                return MappedParameter(
                  parameter: slot.parameters[parameterNumber],
                  value: slot.values[parameterNumber],
                  enums: slot.enums[parameterNumber],
                  valueString: slot.valueStrings[parameterNumber],
                  mapping: mapping,
                  algorithm: slot.algorithm,
                );
              },
            ).toList());
            return acc;
          },
        );
      default:
        return [];
    }
  }

// Map to hold an active polling task for each mapped parameter,
// keyed by a composite key (e.g. "algorithmIndex_parameterNumber").
  final Map<String, _PollingTask> _pollingTasks = {};

// Starts polling for each mapped parameter.
  void startPollingMappedParameters() {
    stopPollingMappedParameters(); // Clear any previous tasks.
    if (state is! DistingStateSynchronized) return;
    final mappedParams = buildMappedParameterList();
    for (final param in mappedParams) {
      final key =
          '${param.parameter.algorithmIndex}_${param.parameter.parameterNumber}';
      _pollingTasks[key] = _PollingTask();
      _pollIndividualParameter(param, key);
    }
  }

// Stops all polling tasks.
  void stopPollingMappedParameters() {
    _pollingTasks.clear();
  }

// Polls a single mapped parameter recursively.
  Future<void> _pollIndividualParameter(
      MappedParameter mapped, String key) async {
    // If the task has been cancelled or state is not synchronized, stop.
    final task = _pollingTasks[key];
    if (task == null || !task.active || state is! DistingStateSynchronized) {
      return;
    }

    // Define intervals and threshold.
    const Duration fastInterval = Duration(milliseconds: 100);
    const Duration slowInterval = Duration(milliseconds: 1000);
    const int fastToSlowThreshold = 3;

    try {
      final disting = requireDisting();
      // Request the current parameter value.
      final newValue = await disting.requestParameterValue(
        mapped.parameter.algorithmIndex,
        mapped.parameter.parameterNumber,
      );
      if (newValue == null) return;

      // Anomaly Check
      if (newValue.value < mapped.parameter.min ||
          newValue.value > mapped.parameter.max) {
        debugPrint(
            "Out-of-bounds data from device (polling): algo ${mapped.parameter.algorithmIndex}, param ${mapped.parameter.parameterNumber}, value ${newValue.value}, expected ${mapped.parameter.min}-${mapped.parameter.max}");
        _refreshSlotAfterAnomaly(mapped.parameter.algorithmIndex);
        // Unlike in updateParameterValue, we don't return early here.
        // The polling loop will continue, and the refresh will eventually correct the state.
      }
      // End Anomaly Check

      final currentState = state;
      if (currentState is DistingStateSynchronized) {
        // Add boundary checks before accessing slots and values
        if (mapped.parameter.algorithmIndex >= currentState.slots.length) {
          debugPrint(
              "[Polling] Slot index ${mapped.parameter.algorithmIndex} is out of bounds after potential refresh. Stopping poll for this parameter.");
          _pollingTasks.remove(key); // Remove task to stop polling
          return;
        }
        final currentSlot = currentState.slots[mapped.parameter.algorithmIndex];
        // Check if parameter number is still valid
        if (mapped.parameter.parameterNumber >= currentSlot.values.length) {
          debugPrint(
              "[Polling] Parameter number ${mapped.parameter.parameterNumber} out of bounds for slot ${mapped.parameter.algorithmIndex} after potential refresh. Stopping poll for this parameter.");
          _pollingTasks.remove(key); // Remove task to stop polling
          return;
        }
        final currentValue =
            currentSlot.values[mapped.parameter.parameterNumber];
        if (newValue.value != currentValue.value) {
          // A change was detected: update state and reset no-change count.
          final updatedSlots = updateSlot(
            mapped.parameter.algorithmIndex,
            currentState.slots,
            (slot) => slot.copyWith(
              values: replaceInList(
                slot.values,
                newValue,
                index: mapped.parameter.parameterNumber,
              ),
            ),
          );
          emit(currentState.copyWith(slots: updatedSlots));
          task.noChangeCount = 0;
          // Continue polling quickly.
          await Future.delayed(fastInterval);
        } else {
          // No change: increment counter and choose interval.
          task.noChangeCount++;
          final delay = (task.noChangeCount >= fastToSlowThreshold)
              ? slowInterval
              : fastInterval;
          await Future.delayed(delay);
        }
      }
    } catch (e) {
      // In case of an error, wait a bit before retrying.
      await Future.delayed(slowInterval);
    }

    // Continue polling this parameter if it's still active.
    if (_pollingTasks.containsKey(key)) {
      _pollIndividualParameter(mapped, key);
    }
  }

  Future<void> resetOutputs(Slot slot, int outputIndex) async {
    final disting = requireDisting();

    slot.parameters
        .where((p) =>
            p.name.toLowerCase().contains("output") &&
            p.min == 0 &&
            p.max == 28)
        .forEach(
          (p) => disting.setParameterValue(
            p.algorithmIndex,
            p.parameterNumber,
            outputIndex,
          ),
        );
    refresh();
  }

  Future<List<Slot>> fetchSlots(
      int numAlgorithmsInPreset, IDistingMidiManager disting) async {
    final stopwatch = Stopwatch()..start();
    debugPrint(
        "[fetchSlots] Starting: Requesting $numAlgorithmsInPreset slots...");

    final slotsFutures =
        List.generate(numAlgorithmsInPreset, (algorithmIndex) async {
      return await fetchSlot(disting, algorithmIndex);
    });

    // Finish off the requests
    final slots = await Future.wait(slotsFutures);
    final totalTime = stopwatch.elapsedMilliseconds;
    debugPrint(
        "[fetchSlots] COMPLETED: Fetched ${slots.length} slots in ${totalTime}ms (avg ${totalTime ~/ (numAlgorithmsInPreset > 0 ? numAlgorithmsInPreset : 1)}ms per slot)");
    return slots;
  }

  /// Concurrency limit for per-parameter calls.
  /// Tune this — 4-6 usually keeps the module happy without stalling.
  static const int kParallel = 4;

  // Background retry queue for failed parameter requests
  final List<_ParameterRetryRequest> _parameterRetryQueue = [];

  // Semaphore to ensure retry queue has lower priority than active commands
  int _activeCommandCount = 0;
  final _commandSemaphore = Completer<void>();

  // Background retry for failed parameter requests
  void _queueParameterRetry(_ParameterRetryRequest request) {
    _parameterRetryQueue.add(request);
    debugPrint(
        '[fetchSlot] Queued for background retry: ${request.type} for slot ${request.slotIndex} param ${request.paramIndex}');
  }

  // Acquire semaphore for active commands (blocks retry queue)
  void _acquireCommandSemaphore() {
    _activeCommandCount++;
    if (_activeCommandCount == 1) {
      debugPrint('[Cubit] Active command started - retry queue will wait');
    }
  }

  // Release semaphore for active commands (allows retry queue)
  void _releaseCommandSemaphore() {
    _activeCommandCount--;
    if (_activeCommandCount == 0) {
      debugPrint('[Cubit] No active commands - retry queue can proceed');
      if (!_commandSemaphore.isCompleted) {
        _commandSemaphore.complete();
      }
    }
    if (_activeCommandCount < 0) {
      debugPrint(
          '[Cubit] Warning: Command semaphore count went negative, resetting to 0');
      _activeCommandCount = 0;
    }
  }

  // Wait for semaphore to be available (no active commands)
  Future<void> _waitForCommandSemaphore() async {
    while (_activeCommandCount > 0) {
      final completer = Completer<void>();
      if (_activeCommandCount == 0) break;

      // Wait for active commands to complete or timeout after reasonable period
      await Future.any([
        completer.future,
        Future.delayed(const Duration(seconds: 5))
        // Timeout to prevent deadlock
      ]);

      // Brief yield to check again
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  // Process the retry queue in the background with low priority
  Future<void> _processParameterRetryQueue(IDistingMidiManager disting) async {
    if (_parameterRetryQueue.isEmpty) return;

    debugPrint(
        '[Cubit] Starting low-priority background retry for ${_parameterRetryQueue.length} failed parameter requests');

    final retryList = List.from(_parameterRetryQueue);
    _parameterRetryQueue.clear();

    // Add initial delay to let any pending operations complete
    await Future.delayed(const Duration(seconds: 2));

    for (int i = 0; i < retryList.length; i++) {
      final request = retryList[i];

      // Wait for semaphore - only proceed when no active commands
      await _waitForCommandSemaphore();

      try {
        // Longer delay between retries to maintain low priority
        await Future.delayed(const Duration(milliseconds: 500));

        // Periodically yield to event loop for longer pauses to allow user operations
        if (i > 0 && i % 3 == 0) {
          debugPrint(
              '[Cubit] Background retry yielding to user operations (processed $i/${retryList.length})');
          await Future.delayed(const Duration(seconds: 1));
        }

        // Wait again before the actual retry request to ensure no commands started
        await _waitForCommandSemaphore();

        // Additional micro-yield to event loop before each request
        await Future.delayed(Duration.zero);

        switch (request.type) {
          case _ParameterRetryType.info:
            final info = await disting.requestParameterInfo(
                request.slotIndex, request.paramIndex);
            if (info != null) {
              await _updateSlotParameterInfo(
                  request.slotIndex, request.paramIndex, info);
              debugPrint(
                  '[Cubit] Background retry succeeded: parameter info for slot ${request.slotIndex} param ${request.paramIndex}');
            }
            break;
          case _ParameterRetryType.enumStrings:
            final enums = await disting.requestParameterEnumStrings(
                request.slotIndex, request.paramIndex);
            if (enums != null) {
              await _updateSlotParameterEnums(
                  request.slotIndex, request.paramIndex, enums);
              debugPrint(
                  '[Cubit] Background retry succeeded: enum strings for slot ${request.slotIndex} param ${request.paramIndex}');
            }
            break;
          case _ParameterRetryType.mappings:
            final mappings = await disting.requestMappings(
                request.slotIndex, request.paramIndex);
            if (mappings != null) {
              await _updateSlotParameterMappings(
                  request.slotIndex, request.paramIndex, mappings);
              debugPrint(
                  '[Cubit] Background retry succeeded: mappings for slot ${request.slotIndex} param ${request.paramIndex}');
            }
            break;
          case _ParameterRetryType.valueStrings:
            final valueStrings = await disting.requestParameterValueString(
                request.slotIndex, request.paramIndex);
            if (valueStrings != null) {
              await _updateSlotParameterValueStrings(
                  request.slotIndex, request.paramIndex, valueStrings);
              debugPrint(
                  '[Cubit] Background retry succeeded: value strings for slot ${request.slotIndex} param ${request.paramIndex}');
            }
            break;
        }
      } catch (e) {
        debugPrint(
            '[Cubit] Background retry failed for ${request.type} slot ${request.slotIndex} param ${request.paramIndex}: $e');
        // Add extra delay after failures to avoid overwhelming the device
        await Future.delayed(const Duration(milliseconds: 200));
      }
    }

    debugPrint(
        '[Cubit] Low-priority background parameter retry processing complete');
  }

  // State update methods for retry results
  Future<void> _updateSlotParameterInfo(
      int slotIndex, int paramIndex, ParameterInfo info) async {
    final currentState = state;
    if (currentState is! DistingStateSynchronized ||
        slotIndex >= currentState.slots.length) {
      return;
    }

    final slot = currentState.slots[slotIndex];
    if (paramIndex >= slot.parameters.length) {
      return;
    }

    final updatedParameters = List<ParameterInfo>.from(slot.parameters);
    updatedParameters[paramIndex] = info;

    final updatedSlot = slot.copyWith(parameters: updatedParameters);
    final updatedSlots = List<Slot>.from(currentState.slots);
    updatedSlots[slotIndex] = updatedSlot;

    emit(currentState.copyWith(slots: updatedSlots));
  }

  Future<void> _updateSlotParameterEnums(
      int slotIndex, int paramIndex, ParameterEnumStrings enums) async {
    final currentState = state;
    if (currentState is! DistingStateSynchronized ||
        slotIndex >= currentState.slots.length) {
      return;
    }

    final slot = currentState.slots[slotIndex];
    if (paramIndex >= slot.enums.length) {
      return;
    }

    final updatedEnums = List<ParameterEnumStrings>.from(slot.enums);
    updatedEnums[paramIndex] = enums;

    final updatedSlot = slot.copyWith(enums: updatedEnums);
    final updatedSlots = List<Slot>.from(currentState.slots);
    updatedSlots[slotIndex] = updatedSlot;

    emit(currentState.copyWith(slots: updatedSlots));
  }

  Future<void> _updateSlotParameterMappings(
      int slotIndex, int paramIndex, Mapping mappings) async {
    final currentState = state;
    if (currentState is! DistingStateSynchronized ||
        slotIndex >= currentState.slots.length) {
      return;
    }

    final slot = currentState.slots[slotIndex];
    if (paramIndex >= slot.mappings.length) {
      return;
    }

    final updatedMappings = List<Mapping>.from(slot.mappings);
    updatedMappings[paramIndex] = mappings;

    final updatedSlot = slot.copyWith(mappings: updatedMappings);
    final updatedSlots = List<Slot>.from(currentState.slots);
    updatedSlots[slotIndex] = updatedSlot;

    emit(currentState.copyWith(slots: updatedSlots));
  }

  Future<void> _updateSlotParameterValueStrings(
      int slotIndex, int paramIndex, ParameterValueString valueStrings) async {
    final currentState = state;
    if (currentState is! DistingStateSynchronized ||
        slotIndex >= currentState.slots.length) {
      return;
    }

    final slot = currentState.slots[slotIndex];
    if (paramIndex >= slot.valueStrings.length) {
      return;
    }

    final updatedValueStrings =
        List<ParameterValueString>.from(slot.valueStrings);
    updatedValueStrings[paramIndex] = valueStrings;

    final updatedSlot = slot.copyWith(valueStrings: updatedValueStrings);
    final updatedSlots = List<Slot>.from(currentState.slots);
    updatedSlots[slotIndex] = updatedSlot;

    emit(currentState.copyWith(slots: updatedSlots));
  }

  Future<Slot> fetchSlot(
    IDistingMidiManager disting,
    int algorithmIndex,
  ) async {
    final sw = Stopwatch()..start();
    debugPrint('[fetchSlot] start slot $algorithmIndex');

    /* ------------------------------------------------------------------ *
   * 1-2.  Pages  |  #Parameters  |  Algorithm GUID  |  All Values      *
   * ------------------------------------------------------------------ */
    // Fetch essential info first (these usually don't timeout)
    final essentialResults = await Future.wait([
      disting.requestParameterPages(algorithmIndex),
      disting.requestNumberOfParameters(algorithmIndex),
      disting.requestAlgorithmGuid(algorithmIndex),
    ]);

    final pages = (essentialResults[0] as ParameterPages?) ??
        ParameterPages(algorithmIndex: algorithmIndex, pages: []);
    final numParams =
        (essentialResults[1] as NumParameters?)?.numParameters ?? 0;
    final guid = essentialResults[2] as Algorithm?;

    // Try to get parameter values with retry and longer timeout
    List<ParameterValue> allValues;
    try {
      final paramValuesResult =
          await disting.requestAllParameterValues(algorithmIndex);
      allValues = paramValuesResult?.values ??
          List<ParameterValue>.generate(
              numParams, (_) => ParameterValue.filler());
      debugPrint('[fetchSlot] Got parameter values for slot $algorithmIndex');
    } catch (e) {
      debugPrint(
          '[fetchSlot] Parameter values failed for slot $algorithmIndex: $e - retrying with longer timeout');
      try {
        // Retry with a longer timeout - give it more time to respond
        await Future.delayed(
            const Duration(milliseconds: 500)); // Brief pause before retry
        final retryResult =
            await disting.requestAllParameterValues(algorithmIndex);
        allValues = retryResult?.values ??
            List<ParameterValue>.generate(
                numParams, (_) => ParameterValue.filler());
        debugPrint(
            '[fetchSlot] Parameter values retry succeeded for slot $algorithmIndex');
      } catch (retryError) {
        debugPrint(
            '[fetchSlot] Parameter values retry also failed for slot $algorithmIndex: $retryError - using default values');
        allValues = List<ParameterValue>.generate(
            numParams, (_) => ParameterValue.filler());
      }
    }

    debugPrint('[fetchSlot] meta finished in ${sw.elapsedMilliseconds} ms');

    /* Visible-parameter set (built from pages) */
    final visible = pages.pages.expand((p) => p.parameters).toSet();

    /* ------------------------------------------------------------------ *
   * 3. Parameter-info phase (throttled)                                *
   * ------------------------------------------------------------------ */
    final parameters =
        List<ParameterInfo>.filled(numParams, ParameterInfo.filler());
    await _forEachLimited(
      Iterable<int>.generate(numParams).where((i) => visible.contains(i)),
      (param) async {
        try {
          final info =
              await disting.requestParameterInfo(algorithmIndex, param);
          parameters[param] = info ?? ParameterInfo.filler();
          if (info == null) {
            _queueParameterRetry(_ParameterRetryRequest(
              slotIndex: algorithmIndex,
              paramIndex: param,
              type: _ParameterRetryType.info,
            ));
          }
        } catch (e) {
          debugPrint(
              '[fetchSlot] Parameter info failed for slot $algorithmIndex param $param: $e - queuing for retry');
          parameters[param] = ParameterInfo.filler();
          _queueParameterRetry(_ParameterRetryRequest(
            slotIndex: algorithmIndex,
            paramIndex: param,
            type: _ParameterRetryType.info,
          ));
        }
      },
    );
    debugPrint('[fetchSlot] ParameterInfo ${sw.elapsedMilliseconds} ms');

    /* Pre-calculate which params are enumerated / mappable / string */
    bool isEnum(int i) => parameters[i].unit == 1;
    bool isString(int i) => const {13, 14, 17}.contains(parameters[i].unit);
    bool isMappable(int i) =>
        parameters[i].unit != 0 && parameters[i].unit != -1;

    /* ------------------------------------------------------------------ *
   * 4. Enums, Mappings, Value-Strings  (all throttled in parallel)     *
   * ------------------------------------------------------------------ */
    final enums = List<ParameterEnumStrings>.filled(
        numParams, ParameterEnumStrings.filler());
    final mappings = List<Mapping>.filled(numParams, Mapping.filler());
    final valueStrings = List<ParameterValueString>.filled(
        numParams, ParameterValueString.filler());

    await Future.wait([
      // Enums
      _forEachLimited(
        Iterable<int>.generate(numParams)
            .where((i) => visible.contains(i) && isEnum(i)),
        (param) async {
          try {
            final enumResult = await disting.requestParameterEnumStrings(
                algorithmIndex, param);
            enums[param] = enumResult ?? ParameterEnumStrings.filler();
            if (enumResult == null) {
              _queueParameterRetry(_ParameterRetryRequest(
                slotIndex: algorithmIndex,
                paramIndex: param,
                type: _ParameterRetryType.enumStrings,
              ));
            }
          } catch (e) {
            debugPrint(
                '[fetchSlot] Enum strings failed for slot $algorithmIndex param $param: $e - queuing for retry');
            enums[param] = ParameterEnumStrings.filler();
            _queueParameterRetry(_ParameterRetryRequest(
              slotIndex: algorithmIndex,
              paramIndex: param,
              type: _ParameterRetryType.enumStrings,
            ));
          }
        },
      ),
      // Mappings
      _forEachLimited(
        Iterable<int>.generate(numParams)
            .where((i) => visible.contains(i) && isMappable(i)),
        (param) async {
          try {
            final mappingResult =
                await disting.requestMappings(algorithmIndex, param);
            mappings[param] = mappingResult ?? Mapping.filler();
            if (mappingResult == null) {
              _queueParameterRetry(_ParameterRetryRequest(
                slotIndex: algorithmIndex,
                paramIndex: param,
                type: _ParameterRetryType.mappings,
              ));
            }
          } catch (e) {
            debugPrint(
                '[fetchSlot] Mappings failed for slot $algorithmIndex param $param: $e - queuing for retry');
            mappings[param] = Mapping.filler();
            _queueParameterRetry(_ParameterRetryRequest(
              slotIndex: algorithmIndex,
              paramIndex: param,
              type: _ParameterRetryType.mappings,
            ));
          }
        },
      ),
      // Value strings
      _forEachLimited(
        Iterable<int>.generate(numParams)
            .where((i) => visible.contains(i) && isString(i)),
        (param) async {
          try {
            final valueStringResult = await disting.requestParameterValueString(
                algorithmIndex, param);
            valueStrings[param] =
                valueStringResult ?? ParameterValueString.filler();
            if (valueStringResult == null) {
              _queueParameterRetry(_ParameterRetryRequest(
                slotIndex: algorithmIndex,
                paramIndex: param,
                type: _ParameterRetryType.valueStrings,
              ));
            }
          } catch (e) {
            debugPrint(
                '[fetchSlot] Value strings failed for slot $algorithmIndex param $param: $e - queuing for retry');
            valueStrings[param] = ParameterValueString.filler();
            _queueParameterRetry(_ParameterRetryRequest(
              slotIndex: algorithmIndex,
              paramIndex: param,
              type: _ParameterRetryType.valueStrings,
            ));
          }
        },
      ),
    ]);
    debugPrint('[fetchSlot] Detail fetches ${sw.elapsedMilliseconds} ms');

    /* ------------------------------------------------------------------ *
   * 5. Assemble the Slot                                               *
   * ------------------------------------------------------------------ */
    debugPrint('[fetchSlot] done in ${sw.elapsedMilliseconds} ms');

    return Slot(
      algorithm: guid ??
          Algorithm(
            algorithmIndex: algorithmIndex,
            guid: 'ERROR',
            name: 'Error fetching Algorithm',
          ),
      pages: pages,
      parameters: parameters,
      values: allValues,
      enums: enums,
      mappings: mappings,
      valueStrings: valueStrings,
      routing: RoutingInfo.filler(), // unchanged – still skipped
    );
  }

/* ---------------------------------------------------------------------- *
 * Helper – run tasks with a concurrency cap                              *
 * ---------------------------------------------------------------------- */

  /// Runs [worker] for every element in [items], but never more than
  /// [parallel] tasks are in-flight at once.
  ///
  /// Uses a "batch" strategy: kick off up to [parallel] futures,
  /// `await Future.wait`, then move on to the next batch.  Simpler and
  /// avoids the need for isCompleted / whenComplete gymnastics.
  Future<void> _forEachLimited<T>(
    Iterable<T> items,
    Future<void> Function(T) worker, {
    int parallel = kParallel,
  }) async {
    final iterator = items.iterator;

    while (true) {
      // Collect up to [parallel] tasks for this batch.
      final batch = <Future<void>>[];
      for (var i = 0; i < parallel && iterator.moveNext(); i++) {
        batch.add(worker(iterator.current));
      }

      if (batch.isEmpty) break; // no more work
      await Future.wait(batch); // wait for the batch to finish
    }
  }

  // Helper method to fetch and sort devices (Reinstated)
  Future<Map<String, List<MidiDevice>>> _fetchDeviceLists() async {
    final devices = await _midiCommand.devices;
    devices?.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    return {
      'input': devices?.where((it) => it.inputPorts.isNotEmpty).toList() ?? [],
      'output':
          devices?.where((it) => it.outputPorts.isNotEmpty).toList() ?? [],
    };
  }

  Future<void> refreshRouting() async {
    final disting = requireDisting();
    final currentState = state;
    if (currentState is! DistingStateSynchronized) return;

    // For each slot, update the routing information
    final updatedSlots = await Future.wait(currentState.slots.map(
        (slot) async => slot.copyWith(
            routing: await disting
                    .requestRoutingInformation(slot.algorithm.algorithmIndex) ??
                slot.routing)));

    emit(currentState.copyWith(slots: updatedSlots));
  }

  Future<void> _refreshSlotAfterAnomaly(int algorithmIndex) async {
    await Future.delayed(const Duration(seconds: 1));

    if (state is! DistingStateSynchronized) {
      return;
    }

    final now = DateTime.now();
    final lastAttempt = _lastAnomalyRefreshAttempt[algorithmIndex];
    if (lastAttempt != null &&
        now.difference(lastAttempt) < const Duration(seconds: 10)) {
      debugPrint(
          "[Anomaly Refresh] Skipping refresh for slot $algorithmIndex, last attempt was too recent.");
      return;
    }
    _lastAnomalyRefreshAttempt[algorithmIndex] = now;

    debugPrint(
        "[Anomaly Refresh] Triggering refresh for slot $algorithmIndex due to data anomaly.");

    try {
      final disting = requireDisting();
      final Slot updatedSlot = await fetchSlot(disting, algorithmIndex);
      final currentState = state as DistingStateSynchronized;
      final newSlots = List<Slot>.from(currentState.slots);
      newSlots[algorithmIndex] = updatedSlot;
      emit(currentState.copyWith(slots: newSlots));
    } catch (e, stackTrace) {
      debugPrint("[Anomaly Refresh] Error refreshing slot $algorithmIndex: $e");
      debugPrintStack(stackTrace: stackTrace);
      // Optionally, clear the timestamp to allow immediate retry if fetch failed
      // _lastAnomalyRefreshAttempt.remove(algorithmIndex);
    }
  }

  Future<List<String>> scanSdCardPresets() async {
    final presets = <String>{};
    final disting = requireDisting();
    await disting.requestWake();

    try {
      final rootListing = await disting.requestDirectoryListing('/');
      if (rootListing != null) {
        for (final entry in rootListing.entries) {
          if (entry.isDirectory &&
              entry.name.toLowerCase().contains('presets')) {
            final presetPaths = await _scanDirectory('/${entry.name}');
            presets.addAll(presetPaths);
          }
        }
      }
    } catch (e, stack) {
      debugPrintStack(
          label: "Error scanning SD card presets", stackTrace: stack);
    }

    return presets.toList()..sort();
  }

  Future<Set<String>> _scanDirectory(String path) async {
    final presets = <String>{};
    final disting = requireDisting();

    try {
      final listing = await disting.requestDirectoryListing(path);
      if (listing != null) {
        for (final entry in listing.entries) {
          final newPath = '$path/${entry.name}';
          if (entry.isDirectory) {
            presets.addAll(await _scanDirectory(newPath));
          } else if (entry.name.toLowerCase().endsWith('.json')) {
            presets.add(newPath);
          }
        }
      }
    } catch (e, stack) {
      debugPrintStack(
          label: "Error scanning directory $path", stackTrace: stack);
    }

    return presets;
  }

  /// Scans the SD card on the connected disting for .json files.
  /// Returns a sorted list of relative paths (e.g., "presets/my_preset.json").
  /// Only available if firmware has SD card support.
  Future<List<String>> fetchSdCardPresets() async {
    final currentState = state;

    if (currentState is! DistingStateSynchronized || currentState.offline) {
      debugPrint(
          "[DistingCubit] Cannot fetch SD card presets: Not synchronized or offline.");
      return [];
    }

    if (!FirmwareVersion(currentState.distingVersion).hasSdCardSupport) {
      debugPrint(
          "[DistingCubit] Firmware does not support SD card operations.");
      return [];
    }

    return scanSdCardPresets(); // Reuse the existing private method
  }

  /// Scans for Lua script plugins in the /programs/lua directory.
  /// Returns a sorted list of .lua files found.
  Future<List<PluginInfo>> fetchLuaPlugins() async {
    final currentState = state;

    if (currentState is! DistingStateSynchronized || currentState.offline) {
      debugPrint(
          "[DistingCubit] Cannot fetch Lua plugins: Not synchronized or offline.");
      return [];
    }

    if (!FirmwareVersion(currentState.distingVersion).hasSdCardSupport) {
      debugPrint(
          "[DistingCubit] Firmware does not support SD card operations.");
      return [];
    }

    return _scanPluginDirectory(PluginType.lua);
  }

  /// Scans for 3pot plugins in the /programs/3pot directory.
  /// Returns a sorted list of .3pot files found.
  Future<List<PluginInfo>> fetch3potPlugins() async {
    final currentState = state;

    if (currentState is! DistingStateSynchronized || currentState.offline) {
      debugPrint(
          "[DistingCubit] Cannot fetch 3pot plugins: Not synchronized or offline.");
      return [];
    }

    if (!FirmwareVersion(currentState.distingVersion).hasSdCardSupport) {
      debugPrint(
          "[DistingCubit] Firmware does not support SD card operations.");
      return [];
    }

    return _scanPluginDirectory(PluginType.threePot);
  }

  /// Scans for C++ plugins in the /programs/plug-ins directory.
  /// Returns a sorted list of .o files found.
  Future<List<PluginInfo>> fetchCppPlugins() async {
    final currentState = state;

    if (currentState is! DistingStateSynchronized || currentState.offline) {
      debugPrint(
          "[DistingCubit] Cannot fetch C++ plugins: Not synchronized or offline.");
      return [];
    }

    if (!FirmwareVersion(currentState.distingVersion).hasSdCardSupport) {
      debugPrint(
          "[DistingCubit] Firmware does not support SD card operations.");
      return [];
    }

    return _scanPluginDirectory(PluginType.cpp);
  }

  /// Helper method to scan a specific directory for files with a given extension.
  Future<List<PluginInfo>> _scanPluginDirectory(PluginType pluginType) async {
    final plugins = <PluginInfo>[];
    final disting = requireDisting();
    await disting.requestWake();

    try {
      debugPrint(
          "[DistingCubit] Scanning for ${pluginType.displayName} plugins in ${pluginType.directory}");
      final pluginInfos =
          await _scanDirectoryForPlugins(pluginType.directory, pluginType);
      plugins.addAll(pluginInfos);
    } catch (e, stack) {
      debugPrint(
          "Error scanning ${pluginType.directory} for ${pluginType.extension} files: $e");
      debugPrintStack(stackTrace: stack);
    }

    // Sort by name
    plugins
        .sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return plugins;
  }

  /// Recursively scans a directory for plugin files of a specific type.
  Future<List<PluginInfo>> _scanDirectoryForPlugins(
      String path, PluginType pluginType) async {
    final plugins = <PluginInfo>[];
    final disting = requireDisting();

    try {
      final listing = await disting.requestDirectoryListing(path);
      if (listing != null) {
        for (final entry in listing.entries) {
          final newPath =
              path.endsWith('/') ? '$path${entry.name}' : '$path/${entry.name}';
          if (entry.isDirectory) {
            // Recursively scan subdirectories
            plugins.addAll(await _scanDirectoryForPlugins(newPath, pluginType));
          } else if (entry.name
              .toLowerCase()
              .endsWith(pluginType.extension.toLowerCase())) {
            // Convert DOS date/time to DateTime if available
            DateTime? lastModified;
            try {
              if (entry.date != 0 && entry.time != 0) {
                final year = 1980 + (entry.date >> 9);
                final month = ((entry.date >> 5) & 0xF);
                final day = entry.date & 0x1F;
                final hour = entry.time >> 11;
                final minute = (entry.time >> 5) & 0x3F;
                final second = 2 * (entry.time & 0x1F);

                if (year > 1980 &&
                    month > 0 &&
                    month <= 12 &&
                    day > 0 &&
                    day <= 31) {
                  lastModified =
                      DateTime(year, month, day, hour, minute, second);
                }
              }
            } catch (e) {
              // If date conversion fails, just use null
              debugPrint("Failed to convert date/time for ${entry.name}: $e");
            }

            plugins.add(PluginInfo(
              name: entry.name,
              path: newPath,
              type: pluginType,
              sizeBytes: entry.size,
              lastModified: lastModified,
            ));
          }
        }
      }
    } catch (e, stack) {
      debugPrint(
          "Error scanning directory $path for ${pluginType.extension} files: $e");
      debugPrintStack(stackTrace: stack);
    }

    return plugins;
  }

  /// Refreshes parameter strings for a specific slot only
  Future<void> refreshSlotParameterStrings(int algorithmIndex) async {
    final currentState = state;
    if (currentState is! DistingStateSynchronized) {
      debugPrint(
          "[Cubit] Cannot refresh slot parameter strings: Not in synchronized state.");
      return;
    }

    if (algorithmIndex < 0 || algorithmIndex >= currentState.slots.length) {
      debugPrint(
          "[Cubit] Cannot refresh slot parameter strings: Invalid algorithm index $algorithmIndex");
      return;
    }

    final disting = requireDisting();
    final currentSlot = currentState.slots[algorithmIndex];

    try {
      // Only update parameter strings for string-type parameters (units 13, 14, 17)
      var updatedValueStrings =
          List<ParameterValueString>.from(currentSlot.valueStrings);

      for (int parameterNumber = 0;
          parameterNumber < currentSlot.parameters.length;
          parameterNumber++) {
        final parameter = currentSlot.parameters[parameterNumber];
        if ([13, 14, 17].contains(parameter.unit)) {
          final newValueString = await disting.requestParameterValueString(
              algorithmIndex, parameterNumber);
          if (newValueString != null) {
            updatedValueStrings[parameterNumber] = newValueString;
          }
        }
      }

      // Update the slot with new parameter strings
      final updatedSlot =
          currentSlot.copyWith(valueStrings: updatedValueStrings);
      final updatedSlots = List<Slot>.from(currentState.slots);
      updatedSlots[algorithmIndex] = updatedSlot;

      emit(currentState.copyWith(slots: updatedSlots));

      debugPrint(
          "[Cubit] Refreshed parameter strings for slot $algorithmIndex");
    } catch (e, stackTrace) {
      debugPrint(
          "[Cubit] Error refreshing parameter strings for slot $algorithmIndex: $e");
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  /// Refreshes a single slot's data from the module
  Future<void> refreshSlot(int algorithmIndex) async {
    if (state is! DistingStateSynchronized) {
      return;
    }

    try {
      final disting = requireDisting();
      final Slot updatedSlot = await fetchSlot(disting, algorithmIndex);
      final currentState = state as DistingStateSynchronized;
      final newSlots = List<Slot>.from(currentState.slots);
      newSlots[algorithmIndex] = updatedSlot;
      emit(currentState.copyWith(slots: newSlots));
    } catch (e, stackTrace) {
      debugPrint("[DistingCubit] Error refreshing slot $algorithmIndex: $e");
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> updateParameterString({
    required int algorithmIndex,
    required int parameterNumber,
    required String value,
  }) async {
    // Acquire semaphore to block retry queue during user parameter string updates
    _acquireCommandSemaphore();

    try {
      switch (state) {
        case DistingStateInitial():
        case DistingStateSelectDevice():
        case DistingStateConnected():
          break;
        case DistingStateSynchronized _:
          var disting = requireDisting();

          await disting.setParameterString(
            algorithmIndex,
            parameterNumber,
            value,
          );

          // Refresh the parameter value string to reflect the change
          final newValueString = await disting.requestParameterValueString(
            algorithmIndex,
            parameterNumber,
          );

          if (newValueString != null) {
            final state = (this.state as DistingStateSynchronized);

            emit(state.copyWith(
              slots: updateSlot(
                algorithmIndex,
                state.slots,
                (slot) {
                  return slot.copyWith(
                    valueStrings: replaceInList(
                      slot.valueStrings,
                      newValueString,
                      index: parameterNumber,
                    ),
                  );
                },
              ),
            ));
          }
          break;
      }
    } finally {
      // Always release semaphore to allow retry queue to proceed
      _releaseCommandSemaphore();
    }
  }

  // CPU Usage Streaming
  void _startCpuUsagePolling() {
    debugPrint("[Cubit] Starting CPU usage polling...");

    // Cancel any existing timer
    _cpuUsageTimer?.cancel();

    // Start polling immediately, then every 10 seconds
    _pollCpuUsageOnce();
    _cpuUsageTimer = Timer.periodic(_cpuUsagePollingInterval, (_) {
      _pollCpuUsageOnce();
    });
  }

  void _checkStopCpuUsagePolling() {
    // Use a small delay to check if there are still listeners
    // This prevents stopping polling when one listener cancels but others remain
    Timer(const Duration(milliseconds: 100), () {
      if (!_cpuUsageController.hasListener) {
        debugPrint("[Cubit] Stopping CPU usage polling - no listeners.");
        _cpuUsageTimer?.cancel();
        _cpuUsageTimer = null;
      }
    });
  }

  Future<void> _pollCpuUsageOnce() async {
    try {
      final cpuUsage = await getCpuUsage();
      if (cpuUsage != null && !_cpuUsageController.isClosed) {
        _cpuUsageController.add(cpuUsage);
      }
    } catch (e, stackTrace) {
      debugPrint("Error polling CPU usage: $e");
      debugPrintStack(stackTrace: stackTrace);
      // Don't add error to stream, just log it
    }
  }

  /// Temporarily pause CPU usage polling (useful during sync operations)
  void pauseCpuMonitoring() {
    debugPrint("[Cubit] Pausing CPU usage polling for sync operation...");
    _cpuUsageTimer?.cancel();
    _cpuUsageTimer = null;
  }

  /// Resume CPU usage polling if there are listeners
  void resumeCpuMonitoring() {
    debugPrint("[Cubit] Resuming CPU usage polling after sync operation...");
    if (_cpuUsageController.hasListener && _cpuUsageTimer == null) {
      _startCpuUsagePolling();
    }
  }

  /// Sends a delete command for a plugin file on the SD card.
  /// This is a fire-and-forget operation that assumes success.
  /// Only works when connected to a physical device (not offline/demo mode).
  Future<void> deletePlugin(PluginInfo plugin) async {
    final currentState = state;
    if (currentState is! DistingStateSynchronized || currentState.offline) {
      throw Exception("Cannot delete plugin: Not synchronized or offline.");
    }

    if (!FirmwareVersion(currentState.distingVersion).hasSdCardSupport) {
      throw Exception("Firmware does not support SD card operations.");
    }

    final disting = requireDisting();
    await disting.requestWake();

    debugPrint(
        "[DistingCubit] Sending delete command for plugin: ${plugin.name} at ${plugin.path}");

    // Send the delete command (fire-and-forget)
    await disting.requestFileDelete(plugin.path);

    debugPrint("[DistingCubit] Delete command sent for plugin: ${plugin.name}");
  }

  /// Uploads a plugin file to the appropriate directory on the SD card.
  /// Files are uploaded in 512-byte chunks to stay within SysEx message limits.
  /// Only works when connected to a physical device (not offline/demo mode).
  Future<void> installPlugin(
    String fileName,
    Uint8List fileData, {
    Function(double)? onProgress,
  }) async {
    final currentState = state;
    if (currentState is! DistingStateSynchronized || currentState.offline) {
      throw Exception("Cannot install plugin: Not synchronized or offline.");
    }

    if (!FirmwareVersion(currentState.distingVersion).hasSdCardSupport) {
      throw Exception("Firmware does not support SD card operations.");
    }

    // Determine the target directory based on file extension
    final extension = fileName.toLowerCase().split('.').last;
    String targetDirectory;
    switch (extension) {
      case 'lua':
        targetDirectory = '/programs/lua';
        break;
      case '3pot':
        targetDirectory = '/programs/three_pot';
        break;
      case 'o':
        targetDirectory = '/programs/plug-ins';
        break;
      default:
        throw Exception("Unsupported plugin file type: .$extension");
    }

    // Handle paths that already contain directory structure
    String targetPath;
    if (fileName.contains('/')) {
      // Check if the fileName already starts with the expected directory structure
      final expectedPrefix = targetDirectory.substring(1); // Remove leading /
      if (fileName.startsWith(expectedPrefix)) {
        // The fileName already contains the full path structure, use it as-is
        targetPath = '/$fileName';
      } else {
        // The fileName contains directories but not the expected prefix
        targetPath = '$targetDirectory/$fileName';
      }
    } else {
      // Simple filename without directory structure
      targetPath = '$targetDirectory/$fileName';
    }
    final disting = requireDisting();
    await disting.requestWake();

    debugPrint(
        "[DistingCubit] Starting upload of $fileName (${fileData.length} bytes) to $targetPath");

    // Upload in 512-byte chunks (matching JavaScript tool behavior)
    const chunkSize = 512;
    int uploadPos = 0;

    while (uploadPos < fileData.length) {
      final remainingBytes = fileData.length - uploadPos;
      final currentChunkSize =
          remainingBytes < chunkSize ? remainingBytes : chunkSize;
      final chunk = fileData.sublist(uploadPos, uploadPos + currentChunkSize);

      debugPrint(
          "[DistingCubit] Uploading chunk at position $uploadPos, size $currentChunkSize");

      try {
        await _uploadChunk(targetPath, chunk, uploadPos);
        uploadPos += currentChunkSize;

        // Report progress
        final progress = uploadPos / fileData.length;
        onProgress?.call(progress);

        // Small delay between chunks to avoid overwhelming the device
        if (uploadPos < fileData.length) {
          await Future.delayed(const Duration(milliseconds: 50));
        }
      } catch (e) {
        debugPrint(
            "[DistingCubit] Error uploading chunk at position $uploadPos: $e");
        throw Exception("Upload failed at position $uploadPos: $e");
      }
    }

    debugPrint("[DistingCubit] Successfully uploaded $fileName to $targetPath");
  }

  /// Uploads a single chunk of file data.
  /// This mirrors the JavaScript tool's chunked upload implementation.
  Future<void> _uploadChunk(
      String targetPath, Uint8List chunkData, int position) async {
    final disting = requireDisting();

    // Use chunked upload with position (first chunk creates the file)
    final createAlways = position == 0;
    final result = await disting.requestFileUploadChunk(
      targetPath,
      chunkData,
      position,
      createAlways: createAlways,
    );

    if (result == null || !result.success) {
      throw Exception(
          "Chunk upload failed: ${result?.message ?? 'Unknown error'}");
    }
  }

  /// Backs up all plugins from the Disting NT to a local directory.
  /// Maintains the directory structure (/programs/lua, /programs/three_pot, /programs/plug-ins).
  Future<void> backupPlugins(
    String backupDirectory, {
    void Function(double progress, String currentFile)? onProgress,
  }) async {
    final currentState = state;
    if (currentState is! DistingStateSynchronized || currentState.offline) {
      throw Exception("Cannot backup plugins: Not synchronized or offline.");
    }

    if (!FirmwareVersion(currentState.distingVersion).hasSdCardSupport) {
      throw Exception("Firmware does not support SD card operations.");
    }

    final disting = requireDisting();
    await disting.requestWake();

    debugPrint("[DistingCubit] Starting plugin backup to $backupDirectory");

    try {
      await disting.backupPlugins(
        backupDirectory,
        onProgress: onProgress,
      );
      debugPrint("[DistingCubit] Plugin backup completed successfully");
    } catch (e) {
      debugPrint("[DistingCubit] Plugin backup failed: $e");
      rethrow;
    }
  }

  /// Install multiple files from a preset package in batch
  Future<void> installPackageFiles(
    List<PackageFile> files,
    Map<String, Uint8List> fileData, {
    Function(String fileName, int completed, int total)? onFileStart,
    Function(String fileName, double progress)? onFileProgress,
    Function(String fileName)? onFileComplete,
    Function(String fileName, String error)? onFileError,
  }) async {
    final currentState = state;
    if (currentState is! DistingStateSynchronized || currentState.offline) {
      throw Exception("Cannot install package: Not synchronized or offline.");
    }

    if (!FirmwareVersion(currentState.distingVersion).hasSdCardSupport) {
      throw Exception("Firmware does not support SD card operations.");
    }

    final filesToInstall = files.where((f) => f.shouldInstall).toList();
    debugPrint(
        "[DistingCubit] Installing ${filesToInstall.length} files from package");

    for (int i = 0; i < filesToInstall.length; i++) {
      final file = filesToInstall[i];
      final data = fileData[file.relativePath];

      if (data == null) {
        onFileError?.call(file.filename, 'File data not found');
        continue;
      }

      try {
        onFileStart?.call(file.filename, i + 1, filesToInstall.length);

        // Install the file directly to its target path
        await installFileToPath(
          file.targetPath,
          data,
          onProgress: (progress) =>
              onFileProgress?.call(file.filename, progress),
        );

        onFileComplete?.call(file.filename);
        debugPrint("[DistingCubit] Successfully installed ${file.targetPath}");
      } catch (e) {
        final errorMsg = "Failed to install ${file.filename}: $e";
        debugPrint("[DistingCubit] $errorMsg");
        onFileError?.call(file.filename, errorMsg);
      }
    }

    debugPrint("[DistingCubit] Package installation completed");
  }

  /// Install a single file to a specific path on the SD card
  Future<void> installFileToPath(
    String targetPath,
    Uint8List fileData, {
    Function(double)? onProgress,
  }) async {
    final disting = requireDisting();
    await disting.requestWake();

    debugPrint(
        "[DistingCubit] Installing file to $targetPath (${fileData.length} bytes)");

    // Upload in 512-byte chunks (matching existing implementation)
    const chunkSize = 512;
    int uploadPos = 0;

    while (uploadPos < fileData.length) {
      final remainingBytes = fileData.length - uploadPos;
      final currentChunkSize =
          remainingBytes < chunkSize ? remainingBytes : chunkSize;
      final chunk = fileData.sublist(uploadPos, uploadPos + currentChunkSize);

      try {
        await _uploadChunk(targetPath, chunk, uploadPos);
        uploadPos += currentChunkSize;

        // Report progress
        final progress = uploadPos / fileData.length;
        onProgress?.call(progress);

        // Small delay between chunks
        if (uploadPos < fileData.length) {
          await Future.delayed(const Duration(milliseconds: 50));
        }
      } catch (e) {
        throw Exception("Upload failed at position $uploadPos: $e");
      }
    }

    debugPrint("[DistingCubit] Successfully installed file to $targetPath");
  }

  /// Load a plugin using the dedicated 0x38 Load Plugin SysEx command
  /// and refresh the specific algorithm info with updated specifications
  Future<AlgorithmInfo?> loadPlugin(String guid) async {
    final currentState = state;
    if (currentState is! DistingStateSynchronized) {
      debugPrint("[LoadPlugin] Cannot load plugin: not in synchronized state");
      return null;
    }

    final disting = requireDisting();
    
    // Find the algorithm by GUID
    final algorithmIndex = currentState.algorithms
        .indexWhere((algo) => algo.guid == guid);
    
    if (algorithmIndex == -1) {
      debugPrint("[LoadPlugin] Algorithm with GUID $guid not found");
      return null;
    }

    final algorithm = currentState.algorithms[algorithmIndex];
    
    // Check if it's already loaded
    if (algorithm.isLoaded) {
      debugPrint("[LoadPlugin] Algorithm ${algorithm.name} is already loaded");
      return algorithm;
    }

    debugPrint("[LoadPlugin] Loading plugin: ${algorithm.name} (${algorithm.guid})");

    try {
      // 1. Send load plugin command
      await disting.requestLoadPlugin(guid);
      
      // 2. Request updated info for just this algorithm
      final updatedInfo = await disting.requestAlgorithmInfo(algorithmIndex);
      
      if (updatedInfo != null) {
        debugPrint("[LoadPlugin] Successfully loaded ${updatedInfo.name} with ${updatedInfo.numSpecifications} specifications");
        
        // 3. Update only this algorithm in the state
        final updatedAlgorithms = List<AlgorithmInfo>.from(currentState.algorithms);
        updatedAlgorithms[algorithmIndex] = updatedInfo;
        
        emit(currentState.copyWith(algorithms: updatedAlgorithms));
        return updatedInfo;
      } else {
        debugPrint("[LoadPlugin] Failed to get updated algorithm info for ${algorithm.name}");
        return null;
      }
    } catch (e, stackTrace) {
      debugPrint("[LoadPlugin] Error loading plugin ${algorithm.name}: $e");
      debugPrintStack(stackTrace: stackTrace);
      return null;
    }
  }
}

extension DistingCubitGetters on DistingCubit {
  IDistingMidiManager? disting() {
    return switch (state) {
      DistingStateConnected(disting: final d) => d,
      DistingStateSynchronized(disting: final d) => d,
      _ => null,
    };
  }

  IDistingMidiManager requireDisting() {
    final d = disting();
    if (d == null) {
      throw Exception("Disting not connected");
    }
    return d;
  }
}
