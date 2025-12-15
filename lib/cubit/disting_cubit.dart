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
import 'package:nt_helper/domain/video/video_stream_state.dart';
import 'package:nt_helper/domain/video/usb_video_manager.dart';

part 'disting_cubit.freezed.dart';

part 'disting_state.dart';

// A helper class to track each parameter's polling state.
class _PollingTask {
  bool active = true;
  int noChangeCount = 0;

  _PollingTask();
}

// Retry request types for background parameter retry queue
enum _ParameterRetryType { info, enumStrings, mappings, valueStrings }

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
  FirmwareVersion? _lastKnownFirmwareVersion;

  CancelableOperation<void>? _renamePresetVerificationOperation;
  final Map<int, CancelableOperation<void>> _renameSlotVerificationOperations =
      {};

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

  // MIDI setup change subscription for auto-detecting device connections
  StreamSubscription<String>? _midiSetupSubscription;

  // Simple program refresh queue with retry
  Timer? _programRefreshTimer;
  int? _programRefreshSlot;
  int _programRefreshRetries = 0;

  // Parameter refresh debounce timer (300ms)
  Timer? _parameterRefreshTimer;
  static const Duration _parameterRefreshDebounceDelay = Duration(
    milliseconds: 300,
  );

  CancelableOperation<void>?
  _moveVerificationOperation; // Add verification operation tracker
  // Keep track of the offline manager instance when offline
  OfflineDistingMidiManager? _offlineManager;
  final Map<int, DateTime> _lastAnomalyRefreshAttempt = {};

  // Parameter update queue for consolidated parameter changes
  ParameterUpdateQueue? _parameterQueue;

  // Output mode usage tracking
  // Maps slot index -> parameter number -> list of affected parameters
  final Map<int, Map<int, List<int>>> _outputModeUsageMap = {};
  // Track which output mode parameters we've already queried to avoid duplicates
  final Map<int, Set<int>> _queriedOutputModeParameters = {};

  // CPU Usage Streaming
  late final StreamController<CpuUsage> _cpuUsageController;
  Timer? _cpuUsageTimer;
  StreamSubscription<VideoStreamState>? _videoStateSubscription;
  static const Duration _cpuUsagePollingInterval = Duration(seconds: 10);

  /// Stream of CPU usage updates that polls every 10 seconds when listeners are active
  Stream<CpuUsage> get cpuUsageStream => _cpuUsageController.stream;

  // Video Streaming
  UsbVideoManager? _videoManager;

  /// Stream of video state updates from the cubit's state
  Stream<VideoStreamState?> get videoStreamState => stream.map(
    (state) => state.maybeWhen(
      synchronized:
          (
            disting,
            distingVersion,
            firmwareVersion,
            presetName,
            algorithms,
            slots,
            unitStrings,
            inputDevice,
            outputDevice,
            loading,
            offline,
            screenshot,
            demo,
            videoStream,
          ) => videoStream,
      orElse: () => null,
    ),
  );

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

    // Cancel timers
    _programRefreshTimer?.cancel();
    _parameterRefreshTimer?.cancel();

    // Cancel MIDI setup listener
    _midiSetupSubscription?.cancel();

    // Dispose CPU usage streaming resources
    _cpuUsageTimer?.cancel();
    _cpuUsageController.close();

    // Dispose video streaming resources
    _videoStateSubscription?.cancel();
    _videoManager?.dispose();

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
          savedInputDevice,
          savedOutputDevice,
          savedSysExId,
        );
      } else {
        // Saved prefs exist, but devices not found now.
        final devices = await _fetchDeviceLists(); // Use helper
        emit(
          DistingState.selectDevice(
            inputDevices: devices['input'] ?? [],
            outputDevices: devices['output'] ?? [],
            canWorkOffline: canWorkOffline, // Pass the flag
          ),
        );
        // Start listening for MIDI device connection changes
        _startMidiSetupListener();
      }
    } else {
      // No saved settings found, load devices and show selection
      final devices = await _fetchDeviceLists(); // Use helper
      emit(
        DistingState.selectDevice(
          inputDevices: devices['input'] ?? [],
          outputDevices: devices['output'] ?? [],
          canWorkOffline: canWorkOffline, // Pass the flag
        ),
      );
      // Start listening for MIDI device connection changes
      _startMidiSetupListener();
    }
  }

  Future<void> onDemo() async {
    // Stop listening for MIDI setup changes when entering demo mode
    _stopMidiSetupListener();

    // --- Create Mock Manager and Fetch State ---
    final mockManager = MockDistingMidiManager();
    final distingVersion =
        await mockManager.requestVersionString() ?? "Demo Error";
    final firmwareVersion = FirmwareVersion(distingVersion);
    _lastKnownFirmwareVersion = firmwareVersion;
    final presetName =
        await mockManager.requestPresetName() ?? "Demo Preset Error";
    final algorithms = await _fetchMockAlgorithms(mockManager);
    final unitStrings = await mockManager.requestUnitStrings() ?? [];
    final numSlots = await mockManager.requestNumAlgorithmsInPreset() ?? 0;
    final slots = await fetchSlots(
      numSlots,
      mockManager,
    ); // Use fetchSlots with mockManager

    // Debug: Check slots immediately after fetching
    for (int i = 0; i < slots.length; i++) {
      slots[i];
    }

    // --- Emit the State ---
    emit(
      DistingState.synchronized(
        disting: mockManager,
        // Use the created mock manager instance
        distingVersion: distingVersion,
        firmwareVersion: firmwareVersion,
        presetName: presetName,
        algorithms: algorithms,
        slots: slots,
        unitStrings: unitStrings,
        demo: true,
      ),
    );

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
    IDistingMidiManager manager, {
    bool enableBackgroundCommunityLoading = false,
  }) async {
    final numAlgorithms = await manager.requestNumberOfAlgorithms() ?? 0;

    if (enableBackgroundCommunityLoading) {
      // Optimized approach: only fetch factory algorithms synchronously
      return _fetchFactoryAlgorithmsAndStartBackgroundLoading(
        manager,
        numAlgorithms,
      );
    } else {
      // Original approach: fetch all algorithms synchronously with prioritization
      return _fetchAllAlgorithmsSynchronously(manager, numAlgorithms);
    }
  }

  // Optimized method: fetch factory algorithms quickly, queue slow ones for background
  Future<List<AlgorithmInfo>> _fetchFactoryAlgorithmsAndStartBackgroundLoading(
    IDistingMidiManager manager,
    int numAlgorithms,
  ) async {
    final List<AlgorithmInfo> factoryResults = [];
    final List<int> backgroundIndices = [];

    // Quick pass with short timeout to catch fast-responding factory algorithms
    for (int i = 0; i < numAlgorithms; i++) {
      try {
        // Use very short timeout - factory algorithms should respond quickly
        final algorithmInfo = await manager
            .requestAlgorithmInfo(i)
            .timeout(const Duration(milliseconds: 200), onTimeout: () => null);

        if (algorithmInfo != null && _isFactoryAlgorithm(algorithmInfo.guid)) {
          factoryResults.add(algorithmInfo);
        } else if (algorithmInfo != null) {
          // Got response but it's a community plugin - queue for background
          backgroundIndices.add(i);
        } else {
          // Timed out - likely a community plugin that's not loaded, queue for background
          backgroundIndices.add(i);
        }
      } catch (e) {
        // Error - queue for background retry
        backgroundIndices.add(i);
      }
    }

    // Start background loading for community plugins and timed-out algorithms
    if (backgroundIndices.isNotEmpty) {
      _loadCommunityPluginsInBackground(
        manager,
        backgroundIndices,
        List.from(factoryResults),
      );
    }

    return factoryResults;
  }

  // Original method: fetch all algorithms with full categorization pass
  Future<List<AlgorithmInfo>> _fetchAllAlgorithmsSynchronously(
    IDistingMidiManager manager,
    int numAlgorithms,
  ) async {
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
        // Intentionally empty
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
        // Intentionally empty
      }
    }

    return results;
  }

  // Background loading of ALL algorithms with prioritization and state merging
  Future<void> _loadAllAlgorithmsInBackground(
    IDistingMidiManager manager,
    int numAlgorithms,
  ) async {
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
                ...communityResults,
              ];
              emit(currentState.copyWith(algorithms: currentAlgorithms));
            }
          } else {
            communityResults.add(algorithmInfo);

            // Update state when we get community plugins too
            final currentState = state;
            if (currentState is DistingStateSynchronized &&
                !currentState.offline) {
              final currentAlgorithms = [
                ...factoryResults,
                ...communityResults,
              ];
              emit(currentState.copyWith(algorithms: currentAlgorithms));
            }
          }
        }
      } catch (e) {
        // Continue with next algorithm
      }
    }

    factoryResults.length + communityResults.length;
  }

  // Background loading of community plugins with single retry and state merging
  Future<void> _loadCommunityPluginsInBackground(
    IDistingMidiManager manager,
    List<int> communityIndices,
    List<AlgorithmInfo> baseResults,
  ) async {
    final List<AlgorithmInfo> communityResults = [];

    for (int i in communityIndices) {
      try {
        // Single attempt to fetch community plugin
        final algorithmInfo = await manager.requestAlgorithmInfo(i);
        if (algorithmInfo != null) {
          communityResults.add(algorithmInfo);
        }
      } catch (e) {
        // Move on to next plugin - no retry
      }
    }

    // Merge results and update state if still synchronized
    if (communityResults.isNotEmpty) {
      final mergedResults = [...baseResults, ...communityResults];

      // Only update state if we're still in synchronized mode and not offline
      final currentState = state;
      if (currentState is DistingStateSynchronized && !currentState.offline) {
        emit(currentState.copyWith(algorithms: mergedResults));
      }
    } else {}
  }

  // Helper to fetch AlgorithmInfo list from mock/offline manager
  Future<List<AlgorithmInfo>> _fetchMockAlgorithms(
    IDistingMidiManager manager,
  ) async {
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
      emit(
        DistingState.selectDevice(
          inputDevices: devices['input'] ?? [],
          outputDevices: devices['output'] ?? [],
          canWorkOffline: canWorkOffline, // Pass the flag here
        ),
      );

      // Start listening for MIDI device connection changes
      _startMidiSetupListener();
    } catch (e, stackTrace) {
      debugPrintStack(stackTrace: stackTrace);
      // Emit default state on error
      emit(
        const DistingState.selectDevice(
          inputDevices: [],
          outputDevices: [],
          canWorkOffline: false,
        ),
      );

      // Still start listening even on error
      _startMidiSetupListener();
    }
  }

  /// Starts listening for MIDI setup changes (device connections/disconnections).
  /// Automatically refreshes device list when changes are detected.
  void _startMidiSetupListener() {
    // Cancel any existing subscription to avoid duplicates
    _midiSetupSubscription?.cancel();
    _midiSetupSubscription = null;

    // Subscribe to MIDI setup changes
    _midiSetupSubscription = _midiCommand.onMidiSetupChanged?.listen((_) {
      // Only refresh if we're still in the device selection state
      if (state is DistingStateInitial || state is DistingStateSelectDevice) {
        loadDevices();
      }
    });
  }

  /// Stops listening for MIDI setup changes.
  void _stopMidiSetupListener() {
    _midiSetupSubscription?.cancel();
    _midiSetupSubscription = null;
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
      return null;
    }

    if (currentState.offline || currentState.demo) {
      return null;
    }

    try {
      final disting = requireDisting();
      await disting.requestWake();
      final cpuUsage = await disting.requestCpuUsage();
      return cpuUsage;
    } catch (e, stackTrace) {
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
      return;
    }

    // Now state is confirmed, get manager
    final IDistingMidiManager distingManager = requireDisting();

    try {
      // --- Fetch ALL data from device REGARDLESS ---

      // Start background algorithm loading (slots will have their own algorithm info)
      List<AlgorithmInfo> algorithms = [];
      int numInPreset = 0;
      try {
        final numAlgorithms =
            await distingManager.requestNumberOfAlgorithms() ?? 0;
        numInPreset = await distingManager.requestNumAlgorithmsInPreset() ?? 0;

        // Start background loading for ALL algorithms (slots contain their own algorithm info for UI)
        if (numAlgorithms > 0) {
          _loadAllAlgorithmsInBackground(distingManager, numAlgorithms);
        }
      } catch (e, stackTrace) {
        debugPrintStack(stackTrace: stackTrace);
      }

      final distingVersion = await distingManager.requestVersionString() ?? "";
      final firmwareVersion = FirmwareVersion(distingVersion);
      _lastKnownFirmwareVersion = firmwareVersion;
      final presetName = await distingManager.requestPresetName() ?? "Default";
      var unitStrings = await distingManager.requestUnitStrings() ?? [];
      List<Slot> slots = await fetchSlots(
        numInPreset,
        distingManager,
      );

      // --- Emit final synchronized state --- (Ensure offline is false)
      emit(
        DistingState.synchronized(
          disting: distingManager,
          distingVersion: distingVersion,
          firmwareVersion: firmwareVersion,
          presetName: presetName,
          algorithms: algorithms,
          slots: slots,
          unitStrings: unitStrings,
          inputDevice: inputDevice,
          outputDevice: outputDevice,
          loading: false,
          offline: false,
        ),
      );

      // Start background retry processing for any failed parameter requests
      if (_parameterRetryQueue.isNotEmpty) {
        _processParameterRetryQueue(distingManager).catchError((e) {});
      }
    } catch (e, stackTrace) {
      debugPrintStack(stackTrace: stackTrace);
      // Do NOT store connection details if sync fails
      await loadDevices();
    }
  }

  Future<void> connectToDevices(
    MidiDevice inputDevice,
    MidiDevice outputDevice,
    int sysExId,
  ) async {
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

    // Stop listening for MIDI setup changes while connecting
    _stopMidiSetupListener();

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
        sysExId: sysExId,
      );

      // Emit Connected state WITH the new manager AND devices
      emit(
        DistingState.connected(
          disting: newDistingManager,
          inputDevice: inputDevice, // Store connected devices
          outputDevice: outputDevice,
          offline: false,
        ),
      );

      // Create parameter queue for the new manager
      _createParameterQueue();

      // Store these details as the last successful ONLINE connection
      // BEFORE starting the full sync.
      _lastOnlineInputDevice = inputDevice;
      _lastOnlineOutputDevice = outputDevice;
      _lastOnlineSysExId = sysExId; // Use the parameter passed to this method

      // Synchronize device clock with system time
      try {
        // Use local time for RTC since the device filesystem expects local timestamps
        final now = DateTime.now();
        final localUnixTime =
            now.millisecondsSinceEpoch ~/ 1000 - now.timeZoneOffset.inSeconds;
        await newDistingManager.requestSetRealTimeClock(localUnixTime);
      } catch (e) {
        // Continue with connection even if clock sync fails
      }

      await _performSyncAndEmit(); // Sync with the new connection
    } catch (e, stackTrace) {
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
        // Intentionally empty
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

    // Stop listening for MIDI setup changes when going offline
    _stopMidiSetupListener();

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

    emit(
      DistingState.connected(disting: MockDistingMidiManager(), loading: true),
    );

    try {
      // Disconnect existing MIDI connection IF devices were present
      if (currentManager != null) {
        // Check if there *was* a manager
        if (currentInputDevice != null) {
          _midiCommand.disconnectDevice(currentInputDevice);
        }
        if (currentOutputDevice != null &&
            currentOutputDevice.id != currentInputDevice?.id) {
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
      final firmwareVersion = FirmwareVersion(version);
      _lastKnownFirmwareVersion = firmwareVersion;
      final units = await _offlineManager!.requestUnitStrings() ?? [];
      final availableAlgorithmsInfo = await _fetchOfflineAlgorithms();
      final presetName =
          await _offlineManager!.requestPresetName() ?? "Offline Preset";
      final numAlgorithmsInPreset =
          await _offlineManager!.requestNumAlgorithmsInPreset() ?? 0;
      final List<Slot> initialSlots = await fetchSlots(
        numAlgorithmsInPreset,
        _offlineManager!,
      );

      // Emit state WITHOUT devices or custom names map
      emit(
        DistingState.synchronized(
          disting: _offlineManager!,
          // Use offline manager
          distingVersion: version,
          firmwareVersion: firmwareVersion,
          presetName: presetName,
          algorithms: availableAlgorithmsInfo,
          slots: initialSlots,
          unitStrings: units,
          inputDevice: null,
          // No devices when offline
          outputDevice: null,
          offline: true,
          loading: false,
        ),
      );

      // Create parameter queue for offline manager
      _createParameterQueue();
    } catch (e, stackTrace) {
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

    // Dispose offline manager first
    _offlineManager?.dispose();
    _offlineManager = null;

    // Check if we have details from the last online session
    if (_lastOnlineInputDevice != null &&
        _lastOnlineOutputDevice != null &&
        _lastOnlineSysExId != null) {
      try {
        // Attempt direct connection using stored details
        await connectToDevices(
          _lastOnlineInputDevice!,
          _lastOnlineOutputDevice!,
          _lastOnlineSysExId!,
        ); // Use stored details
        // If connectToDevices succeeds, it will emit the connected/synchronized state
        return; // Successfully reconnected
      } catch (e) {
        // Clear potentially stale details if reconnection failed
        _lastOnlineInputDevice = null;
        _lastOnlineOutputDevice = null;
        _lastOnlineSysExId = null;
        // Fall through to loadDevices below
      }
    }

    // If no last connection details or direct reconnect failed, load devices normally
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
      return;
    }
    if (_offlineManager == null) {
      return;
    }

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

      // 4. Emit the new synchronized state, still marked offline
      emit(
        DistingState.synchronized(
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
        ),
      );
    } catch (e, stackTrace) {
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
        availableAlgorithmsInfo.add(
          AlgorithmInfo(
            guid: details.algorithm.guid,
            name: details.algorithm.name,
            algorithmIndex: -1,
            specifications: details.specifications
                .map(
                  (specEntry) => Specification(
                    name: specEntry.name,
                    min: specEntry.minValue,
                    max: specEntry.maxValue,
                    defaultValue: specEntry.defaultValue,
                    type: specEntry.type,
                  ),
                )
                .toList(),
          ),
        );
      }
      availableAlgorithmsInfo.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
      return availableAlgorithmsInfo;
    } catch (e, stackTrace) {
      debugPrintStack(stackTrace: stackTrace);
      return []; // Return empty on error
    }
  }

  /// Refreshes the state from the current manager (online or offline).
  /// By default, performs a fast refresh of preset data only.
  /// Set [fullRefresh] to true to also re-download the algorithm library (online only).
  Future<void> refresh({bool fullRefresh = false}) async {
    final currentState = state;
    if (currentState is DistingStateSynchronized) {
      if (fullRefresh && !currentState.offline) {
        // Full refresh: re-download everything including algorithm library (online only)
        await _performSyncAndEmit();
      } else {
        // Fast refresh: only update preset from manager (works in both online and offline)
        await _refreshStateFromManager();

        // Check if we should refresh algorithms in the background (online only)
        if (!currentState.offline && _shouldRefreshAlgorithms(currentState)) {
          _refreshAlgorithmsInBackground();
        }
      }
    } else {
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
          final algorithms = await _fetchAlgorithmsWithPriority(
            distingManager,
            enableBackgroundCommunityLoading: true,
          );

          // Only update if state is still synchronized and algorithms changed
          final newState = state;
          if (newState is DistingStateSynchronized &&
              !newState.offline &&
              algorithms.length != newState.algorithms.length) {
            emit(newState.copyWith(algorithms: algorithms));
          }
        } catch (e, stackTrace) {
          debugPrintStack(stackTrace: stackTrace);
          // Don't update state on algorithm fetch failure during background refresh
        }
      } catch (e, stackTrace) {
        debugPrintStack(stackTrace: stackTrace);
        // Don't emit error state for background refresh failures
      }
    }();
  }

  // Public method to trigger algorithm list refresh from UI
  void refreshAlgorithms() {
    _refreshAlgorithmsInBackground();
  }

  /// Sends rescan plugins command to hardware and refreshes algorithm list.
  /// Used by the Add Algorithm screen's manual rescan button.
  Future<void> rescanPlugins() async {
    final disting = requireDisting();
    await disting.requestRescanPlugins();
    _refreshAlgorithmsInBackground();
  }

  // Handle parameter string updates from the queue
  void _onParameterStringUpdated(
    int algorithmIndex,
    int parameterNumber,
    String value,
  ) {
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
      final updatedValueStrings = List<ParameterValueString>.from(
        currentSlot.valueStrings,
      );
      updatedValueStrings[parameterNumber] = ParameterValueString(
        algorithmIndex: algorithmIndex,
        parameterNumber: parameterNumber,
        value: value,
      );

      final updatedSlot = currentSlot.copyWith(
        valueStrings: updatedValueStrings,
      );
      final updatedSlots = List<Slot>.from(currentState.slots);
      updatedSlots[algorithmIndex] = updatedSlot;

      emit(currentState.copyWith(slots: updatedSlots));
    } catch (e, stackTrace) {
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

  List<T> replaceInList<T>(List<T> original, T element, {required int index}) {
    if (index < 0 || index > original.length) {
      throw RangeError.index(index, original, "index out of bounds");
    }

    return [
      ...original.sublist(0, index),
      element,
      ...original.sublist(index + 1),
    ];
  }

  List<Slot> updateSlot(
    int algorithmIndex,
    List<Slot> slots,
    Slot Function(Slot) updateFunction,
  ) {
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
      switch (state) {
        case DistingStateInitial():
        case DistingStateSelectDevice():
        case DistingStateConnected():
          break;
        case DistingStateSynchronized syncstate:
          requireDisting();

          // Always queue the parameter update for sending to device
          final currentSlot = syncstate.slots[algorithmIndex];
          final needsStringUpdate =
              parameterNumber < currentSlot.parameters.length &&
              [
                13,
                14,
                17,
              ].contains(currentSlot.parameters[parameterNumber].unit);

          _parameterQueue?.updateParameter(
            algorithmIndex: algorithmIndex,
            parameterNumber: parameterNumber,
            value: value,
            needsStringUpdate: needsStringUpdate,
            isRealTimeUpdate: userIsChangingTheValue,
          );

          if (userIsChangingTheValue) {
            // Optimistic update during slider movement - just update the UI
            // Preserve isDisabled state from current value
            final currentValue = currentSlot.values.elementAtOrNull(
              parameterNumber,
            );
            final newValue = ParameterValue(
              algorithmIndex: algorithmIndex,
              parameterNumber: parameterNumber,
              value: value,
              isDisabled: currentValue?.isDisabled ?? false,
            );

            emit(
              syncstate.copyWith(
                slots: updateSlot(algorithmIndex, syncstate.slots, (slot) {
                  return slot.copyWith(
                    values: replaceInList(
                      slot.values,
                      newValue,
                      index: parameterNumber,
                    ),
                  );
                }),
              ),
            );
          } else {
            // When user releases slider - do minimal additional processing

            // Special case for switching programs
            if (_isProgramParameter(
              syncstate,
              algorithmIndex,
              parameterNumber,
            )) {
              _queueProgramRefresh(algorithmIndex);
            }

            // Anomaly Check - using the value we're setting
            if (parameterNumber < currentSlot.parameters.length) {
              final parameterInfo = currentSlot.parameters.elementAt(
                parameterNumber,
              );
              if (value < parameterInfo.min || value > parameterInfo.max) {
                _refreshSlotAfterAnomaly(algorithmIndex);
                return; // Return early as the slot will be refreshed
              }
            }

            // Update UI with the final value immediately (optimistic)
            // Preserve isDisabled state from current value
            final currentValue = currentSlot.values.elementAtOrNull(
              parameterNumber,
            );
            final newValue = ParameterValue(
              algorithmIndex: algorithmIndex,
              parameterNumber: parameterNumber,
              value: value,
              isDisabled: currentValue?.isDisabled ?? false,
            );

            emit(
              syncstate.copyWith(
                slots: updateSlot(algorithmIndex, syncstate.slots, (slot) {
                  return slot.copyWith(
                    values: replaceInList(
                      slot.values,
                      newValue,
                      index: parameterNumber,
                    ),
                  );
                }),
              ),
            );

            // The parameter queue will handle:
            // 1. Sending the parameter value to device
            // 2. Querying parameter string if needed
            // 3. Rate limiting and consolidation

            // Trigger a debounced refresh to re-sync state after the user lets go
            // Skip if we're already doing a full program refresh (which includes all values)
            if (!_isProgramParameter(
              syncstate,
              algorithmIndex,
              parameterNumber,
            )) {
              scheduleParameterRefresh(algorithmIndex);
            }
          }
      }
    } finally {
      // Always release semaphore to allow retry queue to proceed
      _releaseCommandSemaphore();
    }
  }

  /// Schedules a debounced parameter refresh (requestAllParameterValues).
  /// If a refresh is already scheduled, the existing timer is cancelled and restarted.
  /// This ensures only one refresh request is sent after a batch of parameter edits.
  /// The actual refresh occurs 300ms after the last call to this method.
  void scheduleParameterRefresh(int algorithmIndex) {
    final syncState = state;
    if (syncState is! DistingStateSynchronized) {
      return; // Only schedule refresh when synchronized
    }

    // Cancel any pending timer
    _parameterRefreshTimer?.cancel();

    // Schedule a new refresh after the debounce delay
    _parameterRefreshTimer = Timer(_parameterRefreshDebounceDelay, () async {
      final manager = disting();
      if (manager != null) {
        final allParameterValues = await manager.requestAllParameterValues(
          algorithmIndex,
        );

        if (allParameterValues != null) {
          // Get current state (might have changed since timer was scheduled)
          final currentState = state;
          if (currentState is DistingStateSynchronized) {
            // Update the slot with the refreshed parameter values
            final currentSlot = currentState.slots[algorithmIndex];
            final updatedSlot = currentSlot.copyWith(
              values: allParameterValues.values,
            );

            // Create new slots list with the updated slot
            final updatedSlots = List<Slot>.from(currentState.slots);
            updatedSlots[algorithmIndex] = updatedSlot;

            // Emit the updated state
            emit(currentState.copyWith(slots: updatedSlots));
          }
        }
      }
      _parameterRefreshTimer = null; // Clear timer reference
    });
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
          } else {}
        }

        // Send the add algorithm request
        await disting.requestAddAlgorithm(algorithm, specsToSend);

          // Optimistic update: fetch just the new slot that was added
          try {
            final newSlotIndex =
                syncstate.slots.length; // New slot will be at the end
            final newSlot = await fetchSlot(
              disting,
              newSlotIndex,
            );

            // Update state with the new slot appended
            final updatedSlots = [...syncstate.slots, newSlot];
            emit(syncstate.copyWith(slots: updatedSlots, loading: false));
        } catch (e, stackTrace) {
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
              return;
            }

            try {
              // Check if the number of algorithms matches our optimistic state
              final actualNumAlgorithms =
                  await disting.requestNumAlgorithmsInPreset() ?? 0;
              if (actualNumAlgorithms != optimisticSlots.length) {
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
                  break;
                }
              }

              if (mismatchDetected) {
                await _refreshStateFromManager(delay: Duration.zero);
              } else {}
            } catch (e, stackTrace) {
              debugPrintStack(stackTrace: stackTrace);
              await _refreshStateFromManager(delay: Duration.zero);
            }
          }),
          onCancel: () {},
        );
        break;
    }
  }

  void renamePreset(String newName) async {
    final currentState = state;
    if (currentState is DistingStateSynchronized) {
      final trimmed = newName.trim();
      if (trimmed.isEmpty || trimmed == currentState.presetName) return;

      // 1) Optimistic update for instant UI response
      emit(currentState.copyWith(presetName: trimmed, loading: false));

      // 2) Send request in background (works for online + offline managers)
      final disting = currentState.disting;
      disting.requestSetPresetName(trimmed).catchError((e, s) {
        // If rename fails, fall back to device truth via a lightweight read.
        _renamePresetVerificationOperation?.cancel();
        _renamePresetVerificationOperation = CancelableOperation.fromFuture(
          Future.delayed(const Duration(milliseconds: 250), () async {
            if (state is! DistingStateSynchronized) return;
            final verificationState = state as DistingStateSynchronized;
            final actual = await disting.requestPresetName();
            if (actual == null) return;
            if (verificationState.presetName != actual) {
              emit(verificationState.copyWith(presetName: actual));
            }
          }),
          onCancel: () {},
        );
      });

      // 3) Verification (lightweight): read name back and correct if needed.
      _renamePresetVerificationOperation?.cancel();
      _renamePresetVerificationOperation = CancelableOperation.fromFuture(
        Future.delayed(const Duration(milliseconds: 500), () async {
          if (state is! DistingStateSynchronized) return;
          final verificationState = state as DistingStateSynchronized;
          if (verificationState.presetName != trimmed) return;

          final actual = await disting.requestPresetName();
          if (actual == null) return;
          if (actual != trimmed) {
            emit(verificationState.copyWith(presetName: actual));
          }
        }),
        onCancel: () {},
      );
    }
  }

  Future<int> moveAlgorithmUp(int algorithmIndex) async {
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
    final correctedMovedSlot = _fixAlgorithmIndex(
      slotToMove,
      algorithmIndex - 1,
    );
    final correctedSwappedSlot = _fixAlgorithmIndex(
      slotToSwapWith,
      algorithmIndex,
    );

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
      // Optionally trigger a full refresh on error?
      _refreshStateFromManager(
        delay: Duration.zero,
      ); // Refresh immediately on error
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
          return;
        }

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
              break; // No need to check further
            }
          }
          // --- End Verification ---

          if (mismatchDetected) {
            // If mismatch, only fetch the actual slots, keep other metadata.
            final actualSlots = await fetchSlots(
              optimisticSlotsCorrected.length,
              disting,
            );

            emit(
              DistingState.synchronized(
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
              ),
            );
          } else {}
        } catch (e, stackTrace) {
          debugPrintStack(stackTrace: stackTrace);
          // Optionally trigger a full refresh on verification error?
          // Avoid emitting potentially stale state on error. A full refresh might be safer.
          _refreshStateFromManager(delay: Duration.zero);
        }
      }),
      onCancel: () {},
    );

    // 4. Return optimistic index
    return algorithmIndex - 1;
  }

  Future<int> moveAlgorithmDown(int algorithmIndex) async {
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
    final correctedMovedSlot = _fixAlgorithmIndex(
      slotToMove,
      algorithmIndex + 1,
    );
    final correctedSwappedSlot = _fixAlgorithmIndex(
      slotToSwapWith,
      algorithmIndex,
    );

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
      _refreshStateFromManager(
        delay: Duration.zero,
      ); // Refresh immediately on error
    });

    // 3. Verification
    _moveVerificationOperation = CancelableOperation.fromFuture(
      Future.delayed(const Duration(seconds: 2), () async {
        if (state is! DistingStateSynchronized) return;
        final verificationState = state as DistingStateSynchronized;

        final eq = const DeepCollectionEquality();
        if (!eq.equals(verificationState.slots, optimisticSlotsCorrected)) {
          return;
        }

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
              break; // No need to check further
            }
          }
          // --- End Verification ---

          if (mismatchDetected) {
            // If mismatch, only fetch the actual slots, keep other metadata.
            final actualSlots = await fetchSlots(
              optimisticSlotsCorrected.length,
              disting,
            );

            emit(
              DistingState.synchronized(
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
              ),
            );
          } else {}
        } catch (e, stackTrace) {
          debugPrintStack(stackTrace: stackTrace);
          _refreshStateFromManager(delay: Duration.zero);
        }
      }),
      onCancel: () {},
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
    int algorithmIndex,
    int parameterNumber,
    PackedMappingData data,
  ) async {
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
      if (algorithmIndex < 0 || algorithmIndex >= currentState.slots.length) {
        return;
      }

      final trimmed = newName.trim();
      if (trimmed.isEmpty) return;

      final slot = currentState.slots[algorithmIndex];
      final currentAlgorithm = slot.algorithm;
      if (trimmed == currentAlgorithm.name) return;

      // 1) Optimistic update for instant UI response
      final optimisticAlgorithm = Algorithm(
        algorithmIndex: currentAlgorithm.algorithmIndex,
        guid: currentAlgorithm.guid,
        name: trimmed,
        specifications: currentAlgorithm.specifications,
      );
      final optimisticSlots = updateSlot(
        algorithmIndex,
        currentState.slots,
        (s) => s.copyWith(algorithm: optimisticAlgorithm),
      );
      emit(currentState.copyWith(slots: optimisticSlots, loading: false));

      // 2) Send request in background
      final disting = requireDisting();
      disting.requestSendSlotName(algorithmIndex, trimmed).catchError((e, s) {
        // If send fails, let the verification pass reconcile state.
      });

      // 3) Verification: read back just this slot's Algorithm and correct if needed.
      _renameSlotVerificationOperations[algorithmIndex]?.cancel();
      _renameSlotVerificationOperations[algorithmIndex] =
          CancelableOperation.fromFuture(
            Future.delayed(const Duration(milliseconds: 750), () async {
              if (state is! DistingStateSynchronized) return;
              final verificationState = state as DistingStateSynchronized;

              // Only proceed if the slot still exists and still matches our optimistic edit.
              if (algorithmIndex < 0 ||
                  algorithmIndex >= verificationState.slots.length) {
                return;
              }

              final currentSlot = verificationState.slots[algorithmIndex];
              if (currentSlot.algorithm.guid != currentAlgorithm.guid) return;
              if (currentSlot.algorithm.name != trimmed) return;

              final actual = await disting.requestAlgorithmGuid(algorithmIndex);
              if (actual == null) return;

              // If the device accepted it, the name should match. Otherwise, correct locally.
              if (actual.name != trimmed) {
                final correctedSlots = updateSlot(
                  algorithmIndex,
                  verificationState.slots,
                  (s) => s.copyWith(algorithm: actual),
                );
                emit(verificationState.copyWith(slots: correctedSlots));
              }
            }),
            onCancel: () {},
          );
    }
  }

  /// Sets the performance page assignment for a parameter.
  ///
  /// - [slotIndex]: Slot index (0-31)
  /// - [parameterNumber]: Parameter number within the algorithm
  /// - [perfPageIndex]: Performance page index (0-15, where 0 = not assigned)
  ///
  /// Uses optimistic update pattern:
  /// 1. Update local state immediately for instant UI feedback
  /// 2. Send update to hardware
  /// 3. Verify by reading back specific parameter mapping
  /// 4. If mismatch, hardware value wins and UI updates again
  Future<void> setPerformancePageMapping(
    int slotIndex,
    int parameterNumber,
    int perfPageIndex,
  ) async {
    final currentState = state;
    if (currentState is! DistingStateSynchronized) {
      return;
    }

    if (slotIndex >= currentState.slots.length) {
      return;
    }

    final disting = requireDisting();

    // 1. Optimistic Update - Update local state immediately
    final slot = currentState.slots[slotIndex];

    if (parameterNumber >= slot.mappings.length) {
      return;
    }

    final originalMapping = slot.mappings[parameterNumber];
    final optimisticMapping = Mapping(
      algorithmIndex: originalMapping.algorithmIndex,
      parameterNumber: originalMapping.parameterNumber,
      packedMappingData: originalMapping.packedMappingData.copyWith(
        perfPageIndex: perfPageIndex,
      ),
    );

    // Emit optimistic state immediately for instant UI feedback
    emit(
      currentState.copyWith(
        slots: updateSlot(slotIndex, currentState.slots, (slot) {
          return slot.copyWith(
            mappings: replaceInList(
              slot.mappings,
              optimisticMapping,
              index: parameterNumber,
            ),
          );
        }),
      ),
    );

    // 2. Send update to hardware (non-blocking)
    disting
        .setPerformancePageMapping(slotIndex, parameterNumber, perfPageIndex)
        .catchError((e, s) {
          debugPrintStack(stackTrace: s);
        });

    // 3. Verify by reading back the specific parameter mapping with retry
    const maxRetries = 4; // Try up to 4 times
    const baseDelay = Duration(milliseconds: 100);
    bool verified = false;

    for (int attempt = 0; attempt < maxRetries && !verified; attempt++) {
      try {
        // Exponential backoff: 100ms, 200ms, 400ms, 800ms
        final delay = baseDelay * (1 << attempt);
        await Future.delayed(delay);

        final actualMapping = await disting.requestMappings(
          slotIndex,
          parameterNumber,
        );

        if (actualMapping == null) {
          continue; // Retry
        }

        // 4. If hardware value differs from optimistic value, hardware wins
        if (actualMapping.packedMappingData.perfPageIndex !=
            optimisticMapping.packedMappingData.perfPageIndex) {
          // Check if this is the last attempt
          if (attempt == maxRetries - 1) {
            // Last attempt - accept hardware value as final

            // Update UI with actual hardware value
            final verificationState = state;
            if (verificationState is DistingStateSynchronized) {
              emit(
                verificationState.copyWith(
                  slots: updateSlot(slotIndex, verificationState.slots, (slot) {
                    return slot.copyWith(
                      mappings: replaceInList(
                        slot.mappings,
                        actualMapping,
                        index: parameterNumber,
                      ),
                    );
                  }),
                ),
              );
            }
            verified = true;
          } else {
            // Not the last attempt - retry to see if hardware catches up
            continue;
          }
        } else {
          // Hardware matches optimistic value - success!
          verified = true;
        }
      } catch (e, stackTrace) {
        debugPrintStack(stackTrace: stackTrace);

        if (attempt == maxRetries - 1) {
          // Last attempt failed - log error
        }
      }
    }

    if (!verified) {
      // Revert to original mapping since we couldn't verify the change
      final revertState = state;
      if (revertState is DistingStateSynchronized) {
        emit(
          revertState.copyWith(
            slots: updateSlot(slotIndex, revertState.slots, (slot) {
              return slot.copyWith(
                mappings: replaceInList(
                  slot.mappings,
                  originalMapping,
                  index: parameterNumber,
                ),
              );
            }),
          ),
        );
      }
    }
  }

  // --- Helper Methods ---

  // Helper to refresh state from the current manager (online or offline)
  Future<void> _refreshStateFromManager({
    Duration delay = const Duration(milliseconds: 50), // Shorter default delay
  }) async {
    final currentState = state;
    if (currentState is! DistingStateSynchronized) {
      return;
    }

    emit(currentState.copyWith(loading: true)); // Show loading
    await Future.delayed(delay);

    final disting = currentState.disting; // Could be online or offline

    try {
      final numAlgorithmsInPreset =
          (await disting.requestNumAlgorithmsInPreset()) ?? 0;
      final presetName = await disting.requestPresetName() ?? "Error";
      List<Slot> slots = await fetchSlots(
        numAlgorithmsInPreset,
        disting,
      );

      emit(
        currentState.copyWith(
          loading: false,
          presetName: presetName,
          slots: slots,
          // Keep other fields like disting, version, algorithms, units, offline status
        ),
      );
    } catch (e, stackTrace) {
      debugPrintStack(stackTrace: stackTrace);
      emit(currentState.copyWith(loading: false)); // Stop loading on error
    }
  }

  List<RoutingInformation> buildRoutingInformation() {
    switch (state) {
      case DistingStateSynchronized syncstate:
        return syncstate.slots
            .where((slot) => slot.routing.algorithmIndex != -1)
            .map(
              (slot) => RoutingInformation(
                algorithmIndex: slot.routing.algorithmIndex,
                routingInfo: slot.routing.routingInfo,
                algorithmName: (slot.algorithm.name.isNotEmpty)
                    ? slot.algorithm.name
                    : syncstate.algorithms
                          .firstWhere(
                            (element) => element.guid == slot.algorithm.guid,
                          )
                          .name,
              ),
            )
            .toList();
      default:
        return [];
    }
  }

  bool _isProgramParameter(
    DistingStateSynchronized state,
    int algorithmIndex,
    int parameterNumber,
  ) =>
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
        routingInfo: slot.routing.routingInfo,
      ),
      pages: ParameterPages(
        algorithmIndex: algorithmIndex,
        pages: slot.pages.pages,
      ),
      parameters: slot.parameters
          .map(
            (parameter) => ParameterInfo(
              algorithmIndex: algorithmIndex,
              parameterNumber: parameter.parameterNumber,
              min: parameter.min,
              max: parameter.max,
              defaultValue: parameter.defaultValue,
              unit: parameter.unit,
              name: parameter.name,
              powerOfTen: parameter.powerOfTen,
              ioFlags: parameter.ioFlags,
            ),
          )
          .toList(),
      values: slot.values
          .map(
            (value) => ParameterValue(
              algorithmIndex: algorithmIndex,
              parameterNumber: value.parameterNumber,
              value: value.value,
              isDisabled: value.isDisabled,
            ),
          )
          .toList(),
      enums: slot.enums
          .map(
            (enums) => ParameterEnumStrings(
              algorithmIndex: algorithmIndex,
              parameterNumber: enums.parameterNumber,
              values: enums.values,
            ),
          )
          .toList(),
      mappings: slot.mappings
          .map(
            (mapping) => Mapping(
              algorithmIndex: algorithmIndex,
              parameterNumber: mapping.parameterNumber,
              packedMappingData: mapping.packedMappingData,
            ),
          )
          .toList(),
      valueStrings: slot.valueStrings
          .map(
            (valueStrings) => ParameterValueString(
              algorithmIndex: algorithmIndex,
              parameterNumber: valueStrings.parameterNumber,
              value: valueStrings.value,
            ),
          )
          .toList(),
      outputModeMap: slot.outputModeMap,
    );
  }

  // Simple program refresh queue with retry logic
  void _queueProgramRefresh(int algorithmIndex) {
    // Cancel existing timer if any
    _programRefreshTimer?.cancel();

    // Store the slot to refresh and reset retry counter
    _programRefreshSlot = algorithmIndex;
    _programRefreshRetries = 0;

    // Start new timer with 2 second delay to give hardware time to load the new program
    _programRefreshTimer = Timer(const Duration(seconds: 2), () {
      _executeProgramRefresh();
    });
  }

  Future<void> _executeProgramRefresh() async {
    final slotIndex = _programRefreshSlot;
    if (slotIndex == null) return;

    final currentState = state;
    if (currentState is! DistingStateSynchronized) {
      _programRefreshTimer = null;
      _programRefreshSlot = null;
      return;
    }

    try {
      final disting = requireDisting();
      final updatedSlot = await fetchSlot(
        disting,
        slotIndex,
      );

      // Check if state is still synchronized
      final newState = state;
      if (newState is! DistingStateSynchronized) {
        return;
      }

      // Update the slot in the state
      emit(
        newState.copyWith(
          slots: updateSlot(slotIndex, newState.slots, (slot) => updatedSlot),
        ),
      );

      // Clear the queue
      _programRefreshTimer = null;
      _programRefreshSlot = null;
      _programRefreshRetries = 0;
    } catch (e, stackTrace) {
      // Retry with exponential backoff if we haven't exceeded max retries
      if (_programRefreshRetries < 3) {
        _programRefreshRetries++;
        final delaySeconds = _programRefreshRetries; // 1s, 2s, 3s

        _programRefreshTimer = Timer(
          Duration(seconds: delaySeconds),
          _executeProgramRefresh,
        );
      } else {
        debugPrintStack(stackTrace: stackTrace);

        // Clear the queue
        _programRefreshTimer = null;
        _programRefreshSlot = null;
        _programRefreshRetries = 0;
      }
    }
  }

  void setDisplayMode(DisplayMode displayMode) {
    requireDisting().let((disting) {
      disting.requestWake();
      disting.requestSetDisplayMode(displayMode);
    });
  }

  /// Reboots the Disting NT module.
  /// This will cause the module to restart as if power cycled.
  Future<void> reboot() async {
    final disting = requireDisting();
    await disting.requestReboot();
  }

  /// Remounts the SD card file system.
  /// This refreshes the file system without a full reboot.
  Future<void> remountSd() async {
    final disting = requireDisting();
    await disting.requestRemountSd();
  }

  static List<MappedParameter> buildMappedParameterList(DistingState state) {
    switch (state) {
      case DistingStateSynchronized():
        // return a list of parameters that have performance page assignments
        // from the state.
        return state.slots.fold(List<MappedParameter>.empty(growable: true), (
          acc,
          slot,
        ) {
          acc.addAll(
            slot.mappings
                .where(
                  (mapping) =>
                      mapping.parameterNumber != -1 &&
                      mapping.packedMappingData.isPerformance(),
                )
                .map((mapping) {
                  var parameterNumber = mapping.parameterNumber;
                  return MappedParameter(
                    parameter: slot.parameters[parameterNumber],
                    value: slot.values[parameterNumber],
                    enums: slot.enums[parameterNumber],
                    valueString: slot.valueStrings[parameterNumber],
                    mapping: mapping,
                    algorithm: slot.algorithm,
                  );
                })
                .toList(),
          );
          return acc;
        });
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
    final mappedParams = buildMappedParameterList(state);
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
    MappedParameter mapped,
    String key,
  ) async {
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
        _refreshSlotAfterAnomaly(mapped.parameter.algorithmIndex);
        // Unlike in updateParameterValue, we don't return early here.
        // The polling loop will continue, and the refresh will eventually correct the state.
      }
      // End Anomaly Check

      final currentState = state;
      if (currentState is DistingStateSynchronized) {
        // Add boundary checks before accessing slots and values
        if (mapped.parameter.algorithmIndex >= currentState.slots.length) {
          _pollingTasks.remove(key); // Remove task to stop polling
          return;
        }
        final currentSlot = currentState.slots[mapped.parameter.algorithmIndex];
        // Check if parameter number is still valid
        if (mapped.parameter.parameterNumber >= currentSlot.values.length) {
          _pollingTasks.remove(key); // Remove task to stop polling
          return;
        }
        final currentValue =
            currentSlot.values[mapped.parameter.parameterNumber];
        if (newValue.value != currentValue.value ||
            newValue.isDisabled != currentValue.isDisabled) {
          // A change was detected (value or disabled state): update state and reset no-change count.
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
        .where(
          (p) =>
              p.name.toLowerCase().contains("output") &&
              p.min == 0 &&
              p.max == 28,
        )
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
    int numAlgorithmsInPreset,
    IDistingMidiManager disting,
  ) async {
    final stopwatch = Stopwatch()..start();

    final slotsFutures = List.generate(numAlgorithmsInPreset, (
      algorithmIndex,
    ) async {
      return await fetchSlot(disting, algorithmIndex);
    });

    // Finish off the requests
    final slots = await Future.wait(slotsFutures);
    stopwatch.elapsedMilliseconds;
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
  }

  // Acquire semaphore for active commands (blocks retry queue)
  void _acquireCommandSemaphore() {
    _activeCommandCount++;
    if (_activeCommandCount == 1) {}
  }

  // Release semaphore for active commands (allows retry queue)
  void _releaseCommandSemaphore() {
    _activeCommandCount--;
    if (_activeCommandCount == 0) {
      if (!_commandSemaphore.isCompleted) {
        _commandSemaphore.complete();
      }
    }
    if (_activeCommandCount < 0) {
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
        Future.delayed(const Duration(seconds: 5)),
        // Timeout to prevent deadlock
      ]);

      // Brief yield to check again
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  // Process the retry queue in the background with low priority
  Future<void> _processParameterRetryQueue(IDistingMidiManager disting) async {
    if (_parameterRetryQueue.isEmpty) return;

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
          await Future.delayed(const Duration(seconds: 1));
        }

        // Wait again before the actual retry request to ensure no commands started
        await _waitForCommandSemaphore();

        // Additional micro-yield to event loop before each request
        await Future.delayed(Duration.zero);

        switch (request.type) {
          case _ParameterRetryType.info:
            final info = await disting.requestParameterInfo(
              request.slotIndex,
              request.paramIndex,
            );
            if (info != null) {
              await _updateSlotParameterInfo(
                request.slotIndex,
                request.paramIndex,
                info,
              );
            }
            break;
          case _ParameterRetryType.enumStrings:
            final enums = await disting.requestParameterEnumStrings(
              request.slotIndex,
              request.paramIndex,
            );
            if (enums != null) {
              await _updateSlotParameterEnums(
                request.slotIndex,
                request.paramIndex,
                enums,
              );
            }
            break;
          case _ParameterRetryType.mappings:
            final mappings = await disting.requestMappings(
              request.slotIndex,
              request.paramIndex,
            );
            if (mappings != null) {
              await _updateSlotParameterMappings(
                request.slotIndex,
                request.paramIndex,
                mappings,
              );
            }
            break;
          case _ParameterRetryType.valueStrings:
            final valueStrings = await disting.requestParameterValueString(
              request.slotIndex,
              request.paramIndex,
            );
            if (valueStrings != null) {
              await _updateSlotParameterValueStrings(
                request.slotIndex,
                request.paramIndex,
                valueStrings,
              );
            }
            break;
        }
      } catch (e) {
        // Add extra delay after failures to avoid overwhelming the device
        await Future.delayed(const Duration(milliseconds: 200));
      }
    }
  }

  // State update methods for retry results
  Future<void> _updateSlotParameterInfo(
    int slotIndex,
    int paramIndex,
    ParameterInfo info,
  ) async {
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

    // Automatically query output mode usage if parameter has isOutputMode flag
    if (info.isOutputMode) {
      await _queryOutputModeUsage(slotIndex, paramIndex);
    }
  }

  /// Query output mode usage for a parameter with isOutputMode flag.
  /// Uses debounce logic to avoid duplicate queries during sync operations.
  Future<void> _queryOutputModeUsage(int slotIndex, int paramIndex) async {
    final currentState = state;
    if (currentState is! DistingStateSynchronized) {
      return;
    }

    // Check if we've already queried this parameter
    final queriedParams = _queriedOutputModeParameters[slotIndex] ?? {};
    if (queriedParams.contains(paramIndex)) {
      return; // Already queried, skip
    }

    try {
      final disting = currentState.disting;
      final outputModeUsage = await disting.requestOutputModeUsage(
        slotIndex,
        paramIndex,
      );

      if (outputModeUsage != null) {
        // Store the output mode usage data
        final slotMap = _outputModeUsageMap[slotIndex] ?? {};
        slotMap[paramIndex] = outputModeUsage.affectedParameterNumbers;
        _outputModeUsageMap[slotIndex] = slotMap;

        // Mark as queried
        queriedParams.add(paramIndex);
        _queriedOutputModeParameters[slotIndex] = queriedParams;

        // Update the slot with the new outputModeMap and emit state change
        // This ensures the routing editor gets the modeParameterNumber for output ports
        final refreshedState = state;
        if (refreshedState is DistingStateSynchronized &&
            slotIndex < refreshedState.slots.length) {
          final currentSlot = refreshedState.slots[slotIndex];
          final updatedSlot = currentSlot.copyWith(
            outputModeMap: _outputModeUsageMap[slotIndex] ?? {},
          );
          final updatedSlots = List<Slot>.from(refreshedState.slots);
          updatedSlots[slotIndex] = updatedSlot;
          emit(refreshedState.copyWith(slots: updatedSlots));
        }
      }
    } catch (e) {
      // Silently fail - output mode usage is optional data
    }
  }

  /// Get output mode usage data for a parameter.
  /// Returns list of affected parameter numbers, or null if not available.
  List<int>? getOutputModeUsage(int slotIndex, int paramIndex) {
    return _outputModeUsageMap[slotIndex]?[paramIndex];
  }

  /// Get all output mode usage data for a slot.
  Map<int, List<int>>? getSlotOutputModeUsage(int slotIndex) {
    return _outputModeUsageMap[slotIndex];
  }

  Future<void> _updateSlotParameterEnums(
    int slotIndex,
    int paramIndex,
    ParameterEnumStrings enums,
  ) async {
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
    int slotIndex,
    int paramIndex,
    Mapping mappings,
  ) async {
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
    int slotIndex,
    int paramIndex,
    ParameterValueString valueStrings,
  ) async {
    final currentState = state;
    if (currentState is! DistingStateSynchronized ||
        slotIndex >= currentState.slots.length) {
      return;
    }

    final slot = currentState.slots[slotIndex];
    if (paramIndex >= slot.valueStrings.length) {
      return;
    }

    final updatedValueStrings = List<ParameterValueString>.from(
      slot.valueStrings,
    );
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
    Stopwatch().start();

    /* ------------------------------------------------------------------ *
   * 1-2.  Pages  |  #Parameters  |  Algorithm GUID  |  All Values      *
   * ------------------------------------------------------------------ */
    // Fetch essential info first (these usually don't timeout)
    final essentialResults = await Future.wait([
      disting.requestParameterPages(algorithmIndex),
      disting.requestNumberOfParameters(algorithmIndex),
      disting.requestAlgorithmGuid(algorithmIndex),
    ]);

    final pages =
        (essentialResults[0] as ParameterPages?) ??
        ParameterPages(algorithmIndex: algorithmIndex, pages: []);
    final numParams =
        (essentialResults[1] as NumParameters?)?.numParameters ?? 0;
    final guid = essentialResults[2] as Algorithm?;

    final currentState = state;
    final firmware = currentState is DistingStateSynchronized
        ? currentState.firmwareVersion
        : _lastKnownFirmwareVersion;

    // Try to get parameter values with retry and longer timeout
    List<ParameterValue> allValues;
    try {
      final paramValuesResult = await disting.requestAllParameterValues(
        algorithmIndex,
      );
      allValues =
          paramValuesResult?.values ??
          List<ParameterValue>.generate(
            numParams,
            (_) => ParameterValue.filler(),
          );
    } catch (e) {
      try {
        // Retry with a longer timeout - give it more time to respond
        await Future.delayed(
          const Duration(milliseconds: 500),
        ); // Brief pause before retry
        final retryResult = await disting.requestAllParameterValues(
          algorithmIndex,
        );
        allValues =
            retryResult?.values ??
            List<ParameterValue>.generate(
              numParams,
              (_) => ParameterValue.filler(),
            );
      } catch (retryError) {
        allValues = List<ParameterValue>.generate(
          numParams,
          (_) => ParameterValue.filler(),
        );
      }
    }

    /* Visible-parameter set (built from pages) */
    final visible = pages.pages.expand((p) => p.parameters).toSet();

    /* ------------------------------------------------------------------ *
   * 3. Parameter-info phase (throttled)                                *
   * ------------------------------------------------------------------ */
    final parameters = List<ParameterInfo>.filled(
      numParams,
      ParameterInfo.filler(),
    );
    await _forEachLimited(
      Iterable<int>.generate(numParams).where((i) => visible.contains(i)),
      (param) async {
        try {
          final info = await disting.requestParameterInfo(
            algorithmIndex,
            param,
          );
          parameters[param] = info ?? ParameterInfo.filler();
          if (info == null) {
            _queueParameterRetry(
              _ParameterRetryRequest(
                slotIndex: algorithmIndex,
                paramIndex: param,
                type: _ParameterRetryType.info,
              ),
            );
          }
        } catch (e) {
          parameters[param] = ParameterInfo.filler();
          _queueParameterRetry(
            _ParameterRetryRequest(
              slotIndex: algorithmIndex,
              paramIndex: param,
              type: _ParameterRetryType.info,
            ),
          );
        }
      },
    );

    /* Pre-calculate which params are enumerated / mappable / string */
    bool isEnum(int i) => parameters[i].unit == 1;
    bool isString(int i) => const {13, 14, 17}.contains(parameters[i].unit);
    bool isMappable(int i) => parameters[i].unit != -1;

    /* ------------------------------------------------------------------ *
   * 4. Enums, Mappings, Value-Strings  (all throttled in parallel)     *
   * ------------------------------------------------------------------ */
    final enums = List<ParameterEnumStrings>.filled(
      numParams,
      ParameterEnumStrings.filler(),
    );
    final mappings = List<Mapping>.filled(numParams, Mapping.filler());
    final valueStrings = List<ParameterValueString>.filled(
      numParams,
      ParameterValueString.filler(),
    );

    // Skip enum strings for known buggy algorithm/parameter combinations
    // Macro Oscillator (maco) param 1 (Model) causes firmware to send truncated
    // SysEx that can corrupt the MIDI stream
    bool shouldSkipEnumStrings(int param) {
      return firmware?.isExactly('1.12.0') == true &&
          guid?.guid == 'maco' &&
          param == 1;
    }

    await Future.wait([
      // Enums
      _forEachLimited(
        Iterable<int>.generate(
          numParams,
        ).where((i) => visible.contains(i) && isEnum(i) && !shouldSkipEnumStrings(i)),
        (param) async {
          try {
            final enumResult = await disting.requestParameterEnumStrings(
              algorithmIndex,
              param,
            );
            enums[param] = enumResult ?? ParameterEnumStrings.filler();
            if (enumResult == null) {
              _queueParameterRetry(
                _ParameterRetryRequest(
                  slotIndex: algorithmIndex,
                  paramIndex: param,
                  type: _ParameterRetryType.enumStrings,
                ),
              );
            }
          } catch (e) {
            enums[param] = ParameterEnumStrings.filler();
            _queueParameterRetry(
              _ParameterRetryRequest(
                slotIndex: algorithmIndex,
                paramIndex: param,
                type: _ParameterRetryType.enumStrings,
              ),
            );
          }
        },
      ),
      // Mappings
      _forEachLimited(
        Iterable<int>.generate(
          numParams,
        ).where((i) => visible.contains(i) && isMappable(i)),
        (param) async {
          try {
            final mappingResult = await disting.requestMappings(
              algorithmIndex,
              param,
            );
            mappings[param] = mappingResult ?? Mapping.filler();
            if (mappingResult == null) {
              _queueParameterRetry(
                _ParameterRetryRequest(
                  slotIndex: algorithmIndex,
                  paramIndex: param,
                  type: _ParameterRetryType.mappings,
                ),
              );
            }
          } catch (e) {
            mappings[param] = Mapping.filler();
            _queueParameterRetry(
              _ParameterRetryRequest(
                slotIndex: algorithmIndex,
                paramIndex: param,
                type: _ParameterRetryType.mappings,
              ),
            );
          }
        },
      ),
      // Value strings
      _forEachLimited(
        Iterable<int>.generate(
          numParams,
        ).where((i) => visible.contains(i) && isString(i)),
        (param) async {
          try {
            final valueStringResult = await disting.requestParameterValueString(
              algorithmIndex,
              param,
            );
            valueStrings[param] =
                valueStringResult ?? ParameterValueString.filler();
            if (valueStringResult == null) {
              _queueParameterRetry(
                _ParameterRetryRequest(
                  slotIndex: algorithmIndex,
                  paramIndex: param,
                  type: _ParameterRetryType.valueStrings,
                ),
              );
            }
          } catch (e) {
            valueStrings[param] = ParameterValueString.filler();
            _queueParameterRetry(
              _ParameterRetryRequest(
                slotIndex: algorithmIndex,
                paramIndex: param,
                type: _ParameterRetryType.valueStrings,
              ),
            );
          }
        },
      ),
    ]);

    /* ------------------------------------------------------------------ *
   * 5. Assemble the Slot                                               *
   * ------------------------------------------------------------------ */

    // Pre-populate output mode usage from database if not already populated
    // This ensures mode parameters are available even if isOutputMode flag isn't set
    if (_outputModeUsageMap[algorithmIndex] == null ||
        _outputModeUsageMap[algorithmIndex]!.isEmpty) {
      final algorithmGuid = guid?.guid;
      if (algorithmGuid != null) {
        try {
          final dbOutputModeUsage =
              await _metadataDao.getOutputModeUsageForAlgorithm(algorithmGuid);
          if (dbOutputModeUsage.isNotEmpty) {
            _outputModeUsageMap[algorithmIndex] = dbOutputModeUsage;
          }
        } catch (e) {
          // Silently ignore database errors - output mode is optional
        }
      }
    }

    return Slot(
      algorithm:
          guid ??
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
      outputModeMap: _outputModeUsageMap[algorithmIndex] ?? {},
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
    final updatedSlots = await Future.wait(
      currentState.slots.map(
        (slot) async => slot.copyWith(
          routing:
              await disting.requestRoutingInformation(
                slot.algorithm.algorithmIndex,
              ) ??
              slot.routing,
        ),
      ),
    );

    emit(currentState.copyWith(slots: updatedSlots));
  }

  Future<void> _refreshSlotAfterAnomaly(int algorithmIndex) async {
    await Future.delayed(const Duration(seconds: 1));

    final syncState = state;
    if (syncState is! DistingStateSynchronized) {
      return;
    }

    final now = DateTime.now();
    final lastAttempt = _lastAnomalyRefreshAttempt[algorithmIndex];
    if (lastAttempt != null &&
        now.difference(lastAttempt) < const Duration(seconds: 10)) {
      return;
    }
    _lastAnomalyRefreshAttempt[algorithmIndex] = now;

    try {
      final disting = requireDisting();
      final Slot updatedSlot = await fetchSlot(
        disting,
        algorithmIndex,
      );
      final currentState = state as DistingStateSynchronized;
      final newSlots = List<Slot>.from(currentState.slots);
      newSlots[algorithmIndex] = updatedSlot;
      emit(currentState.copyWith(slots: newSlots));
    } catch (e, stackTrace) {
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
        label: "Error scanning SD card presets",
        stackTrace: stack,
      );
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
        label: "Error scanning directory $path",
        stackTrace: stack,
      );
    }

    return presets;
  }

  /// Scans the SD card on the connected disting for .json files.
  /// Returns a sorted list of relative paths (e.g., "presets/my_preset.json").
  /// Only available if firmware has SD card support.
  Future<List<String>> fetchSdCardPresets() async {
    final currentState = state;

    if (currentState is! DistingStateSynchronized || currentState.offline) {
      return [];
    }

    if (!FirmwareVersion(currentState.distingVersion).hasSdCardSupport) {
      return [];
    }

    return scanSdCardPresets(); // Reuse the existing private method
  }

  /// Scans for Lua script plugins in the /programs/lua directory.
  /// Returns a sorted list of .lua files found.
  Future<List<PluginInfo>> fetchLuaPlugins() async {
    final currentState = state;

    if (currentState is! DistingStateSynchronized || currentState.offline) {
      return [];
    }

    if (!FirmwareVersion(currentState.distingVersion).hasSdCardSupport) {
      return [];
    }

    return _scanPluginDirectory(PluginType.lua);
  }

  /// Scans for 3pot plugins in the /programs/3pot directory.
  /// Returns a sorted list of .3pot files found.
  Future<List<PluginInfo>> fetch3potPlugins() async {
    final currentState = state;

    if (currentState is! DistingStateSynchronized || currentState.offline) {
      return [];
    }

    if (!FirmwareVersion(currentState.distingVersion).hasSdCardSupport) {
      return [];
    }

    return _scanPluginDirectory(PluginType.threePot);
  }

  /// Scans for C++ plugins in the /programs/plug-ins directory.
  /// Returns a sorted list of .o files found.
  Future<List<PluginInfo>> fetchCppPlugins() async {
    final currentState = state;

    if (currentState is! DistingStateSynchronized || currentState.offline) {
      return [];
    }

    if (!FirmwareVersion(currentState.distingVersion).hasSdCardSupport) {
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
      final pluginInfos = await _scanDirectoryForPlugins(
        pluginType.directory,
        pluginType,
      );
      plugins.addAll(pluginInfos);
    } catch (e, stack) {
      debugPrintStack(stackTrace: stack);
    }

    // Sort by name
    plugins.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    return plugins;
  }

  /// Recursively scans a directory for plugin files of a specific type.
  Future<List<PluginInfo>> _scanDirectoryForPlugins(
    String path,
    PluginType pluginType,
  ) async {
    final plugins = <PluginInfo>[];
    final disting = requireDisting();

    try {
      final listing = await disting.requestDirectoryListing(path);
      if (listing != null) {
        for (final entry in listing.entries) {
          final newPath = path.endsWith('/')
              ? '$path${entry.name}'
              : '$path/${entry.name}';
          if (entry.isDirectory) {
            // Recursively scan subdirectories
            plugins.addAll(await _scanDirectoryForPlugins(newPath, pluginType));
          } else if (entry.name.toLowerCase().endsWith(
            pluginType.extension.toLowerCase(),
          )) {
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
                  lastModified = DateTime(
                    year,
                    month,
                    day,
                    hour,
                    minute,
                    second,
                  );
                }
              }
            } catch (e) {
              // If date conversion fails, just use null
            }

            plugins.add(
              PluginInfo(
                name: entry.name,
                path: newPath,
                type: pluginType,
                sizeBytes: entry.size,
                lastModified: lastModified,
              ),
            );
          }
        }
      }
    } catch (e, stack) {
      debugPrintStack(stackTrace: stack);
    }

    return plugins;
  }

  /// Refreshes parameter strings for a specific slot only
  Future<void> refreshSlotParameterStrings(int algorithmIndex) async {
    final currentState = state;
    if (currentState is! DistingStateSynchronized) {
      return;
    }

    if (algorithmIndex < 0 || algorithmIndex >= currentState.slots.length) {
      return;
    }

    final disting = requireDisting();
    final currentSlot = currentState.slots[algorithmIndex];

    try {
      // Only update parameter strings for string-type parameters (units 13, 14, 17)
      var updatedValueStrings = List<ParameterValueString>.from(
        currentSlot.valueStrings,
      );

      for (
        int parameterNumber = 0;
        parameterNumber < currentSlot.parameters.length;
        parameterNumber++
      ) {
        final parameter = currentSlot.parameters[parameterNumber];
        if ([13, 14, 17].contains(parameter.unit)) {
          final newValueString = await disting.requestParameterValueString(
            algorithmIndex,
            parameterNumber,
          );
          if (newValueString != null) {
            updatedValueStrings[parameterNumber] = newValueString;
          }
        }
      }

      // Update the slot with new parameter strings
      final updatedSlot = currentSlot.copyWith(
        valueStrings: updatedValueStrings,
      );
      final updatedSlots = List<Slot>.from(currentState.slots);
      updatedSlots[algorithmIndex] = updatedSlot;

      emit(currentState.copyWith(slots: updatedSlots));
    } catch (e, stackTrace) {
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  /// Refreshes a single slot's data from the module
  Future<void> refreshSlot(int algorithmIndex) async {
    final syncState = state;
    if (syncState is! DistingStateSynchronized) {
      return;
    }

    try {
      final disting = requireDisting();
      final Slot updatedSlot = await fetchSlot(
        disting,
        algorithmIndex,
      );
      final currentState = state as DistingStateSynchronized;
      final newSlots = List<Slot>.from(currentState.slots);
      newSlots[algorithmIndex] = updatedSlot;
      emit(currentState.copyWith(slots: newSlots));
    } catch (e, stackTrace) {
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

            emit(
              state.copyWith(
                slots: updateSlot(algorithmIndex, state.slots, (slot) {
                  return slot.copyWith(
                    valueStrings: replaceInList(
                      slot.valueStrings,
                      newValueString,
                      index: parameterNumber,
                    ),
                  );
                }),
              ),
            );
          }
          break;
      }
    } finally {
      // Always release semaphore to allow retry queue to proceed
      _releaseCommandSemaphore();
    }
  }

  /// Starts the USB video stream from the Disting NT device
  Future<void> startVideoStream() async {
    final currentState = state;
    if (currentState is! DistingStateSynchronized) {
      return;
    }

    // Initialize video manager if not already created
    _videoManager ??= UsbVideoManager();
    await _videoManager!.initialize();

    // Subscribe to video state changes and update cubit state
    _videoStateSubscription?.cancel();
    _videoStateSubscription = _videoManager!.stateStream.listen((videoState) {
      if (state is DistingStateSynchronized) {
        final syncState = state as DistingStateSynchronized;
        emit(syncState.copyWith(videoStream: videoState));
      }
    });

    // Try to auto-connect to Disting NT or any available USB camera
    await _videoManager!.autoConnect();
  }

  /// Stops the USB video stream
  Future<void> stopVideoStream() async {
    _videoStateSubscription?.cancel();
    _videoStateSubscription = null;
    await _videoManager?.disconnect();

    final currentState = state;
    if (currentState is DistingStateSynchronized) {
      emit(currentState.copyWith(videoStream: null));
    }
  }

  /// Gets the current video stream state
  VideoStreamState? get currentVideoState => _videoManager?.currentState;

  /// Gets the video manager for direct stream access
  UsbVideoManager? get videoManager => _videoManager;

  // CPU Usage Streaming
  void _startCpuUsagePolling() {
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
      debugPrintStack(stackTrace: stackTrace);
      // Don't add error to stream, just log it
    }
  }

  /// Temporarily pause CPU usage polling (useful during sync operations)
  void pauseCpuMonitoring() {
    _cpuUsageTimer?.cancel();
    _cpuUsageTimer = null;
  }

  /// Resume CPU usage polling if there are listeners
  void resumeCpuMonitoring() {
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

    // Send the delete command (fire-and-forget)
    await disting.requestFileDelete(plugin.path);
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
    final String targetPath;
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

    // Ensure the parent directory of the final target path exists before uploading
    final disting = requireDisting();
    await disting.requestWake();
    final parentPath = targetPath.substring(0, targetPath.lastIndexOf('/'));
    await _ensureDirectoryExists(parentPath, disting);

    // For C++ plugins (.o files), check if the plugin is currently in use
    // by any algorithm in the preset. If so, follow reference implementation
    // workflow: save preset, create blank preset to release plugin locks.
    String? savedPresetName;
    if (extension == 'o') {
      final isPluginInUse = _isPluginInUseByPreset(targetPath, currentState);
      if (isPluginInUse) {
        savedPresetName = currentState.presetName;
        await disting.requestNewPreset();
      }
    }

    // Upload in 512-byte chunks (matching JavaScript tool behavior)
    const chunkSize = 512;
    int uploadPos = 0;

    while (uploadPos < fileData.length) {
      final remainingBytes = fileData.length - uploadPos;
      final currentChunkSize = remainingBytes < chunkSize
          ? remainingBytes
          : chunkSize;
      final chunk = fileData.sublist(uploadPos, uploadPos + currentChunkSize);

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
        throw Exception("Upload failed at position $uploadPos: $e");
      }
    }

    // For C++ plugins (.o files), complete the workflow:
    // - Always rescan plugins to make the new one available
    // - If we did the preset dance (plugin was in use), reload the original preset
    if (extension == 'o') {
      try {
        // Brief delay to allow hardware to finish file operations
        await Future.delayed(const Duration(milliseconds: 200));
        await disting.requestRescanPlugins();

        // Only reload preset if we did the preset dance (plugin was in use)
        if (savedPresetName != null) {
          final presetPath = '/presets/$savedPresetName.json';
          await disting.requestLoadPreset(presetPath, false);
        }
      } catch (e) {
        // Fire-and-forget: log but don't block on rescan/reload errors
        debugPrint('Post-install operations failed (non-blocking): $e');
      }
    }

    // Refresh state from manager to pick up any changes
    await _refreshStateFromManager();
  }

  /// Uploads a single chunk of file data.
  /// This mirrors the JavaScript tool's chunked upload implementation.
  Future<void> _uploadChunk(
    String targetPath,
    Uint8List chunkData,
    int position,
  ) async {
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
        "Chunk upload failed: ${result?.message ?? 'Unknown error'}",
      );
    }
  }

  /// Checks if the plugin at the given path is currently in use by any
  /// algorithm in the preset.
  ///
  /// Returns true if any slot contains an algorithm whose source file
  /// matches the target path.
  bool _isPluginInUseByPreset(
    String targetPath,
    DistingStateSynchronized currentState,
  ) {
    // Find all algorithm GUIDs that correspond to plugins with this filename
    final matchingGuids = currentState.algorithms
        .where((algo) => algo.isPlugin && algo.filename == targetPath)
        .map((algo) => algo.guid)
        .toSet();

    if (matchingGuids.isEmpty) {
      // Plugin not in the available algorithms list (new plugin being installed)
      return false;
    }

    // Check if any slot uses one of these GUIDs
    return currentState.slots.any(
      (slot) => matchingGuids.contains(slot.algorithm.guid),
    );
  }

  /// Ensures the specified directory exists on the SD card, creating it if necessary.
  /// Handles parent directory creation as well.
  Future<void> _ensureDirectoryExists(
    String directoryPath,
    IDistingMidiManager disting,
  ) async {
    // Check if directory already exists
    final listing = await disting.requestDirectoryListing(directoryPath);

    // If we got a non-null listing with entries, or an empty listing that could be
    // a valid empty directory, we need to distinguish from error responses.
    // The DirectoryListingResponse parser returns an empty DirectoryListing when
    // status != 0x00 (error case). Since we can't distinguish between an empty
    // directory and an error response from the listing alone, we treat empty
    // listings as "directory doesn't exist" to handle first-time installations.
    // This is safe because:
    // 1. If directory exists but is empty, creating it again is a no-op (handled by device)
    // 2. If directory doesn't exist (error response), we correctly create it
    if (listing != null && listing.entries.isNotEmpty) {
      return;
    }

    // Directory doesn't exist - need to create it
    // First ensure parent directory exists
    final parentPath = directoryPath.substring(
      0,
      directoryPath.lastIndexOf('/'),
    );
    if (parentPath.isNotEmpty) {
      await _ensureDirectoryExists(parentPath, disting);
    }

    // Now create this directory
    final result = await disting.requestDirectoryCreate(directoryPath);

    if (result == null || !result.success) {
      throw Exception(
        "Failed to create directory '$directoryPath': ${result?.message ?? 'Unknown error'}",
      );
    }
  }

  /// Forces a Lua script reload while preserving all parameter state.
  /// This is specifically designed for development mode where a script file
  /// has been modified and needs to be reloaded without losing user settings.
  ///
  /// The process: Program=0 (unload) → Program=currentValue (reload) → restore all state
  Future<void> forceReloadLuaScriptWithStatePreservation(
    int algorithmIndex,
    int programParameterNumber,
    int currentProgramValue,
  ) async {
    final currentState = state;
    if (currentState is! DistingStateSynchronized) {
      throw Exception('Cannot reload script: Disting not synchronized');
    }

    if (algorithmIndex >= currentState.slots.length) {
      throw Exception('Algorithm index $algorithmIndex out of range');
    }

    final currentSlot = currentState.slots[algorithmIndex];
    final disting = currentState.disting;

    try {
      // 1. CAPTURE CURRENT STATE
      final savedValues = List<ParameterValue>.from(currentSlot.values);
      final savedMappings = List<Mapping>.from(currentSlot.mappings);
      final savedValueStrings = List<ParameterValueString>.from(
        currentSlot.valueStrings,
      );
      // Note: Routing restoration may require additional research for programmatic setting

      // 2. FORCE SCRIPT UNLOAD (Program = 0)
      await disting.setParameterValue(
        algorithmIndex,
        programParameterNumber,
        0,
      );
      await Future.delayed(
        const Duration(milliseconds: 200),
      ); // Allow hardware to process

      // 3. RELOAD TARGET SCRIPT (Program = currentProgramValue)
      await disting.setParameterValue(
        algorithmIndex,
        programParameterNumber,
        currentProgramValue,
      );
      await Future.delayed(
        const Duration(milliseconds: 300),
      ); // Allow script to initialize

      // 4. RESTORE ALL PARAMETER VALUES (except Program parameter)
      for (final paramValue in savedValues) {
        if (paramValue.parameterNumber != programParameterNumber) {
          await disting.setParameterValue(
            algorithmIndex,
            paramValue.parameterNumber,
            paramValue.value,
          );
          // Small delay between parameters to avoid overwhelming hardware
          await Future.delayed(const Duration(milliseconds: 10));
        }
      }

      // 5. RESTORE STRING PARAMETERS
      for (final stringValue in savedValueStrings) {
        if (stringValue.parameterNumber != programParameterNumber) {
          await disting.setParameterString(
            algorithmIndex,
            stringValue.parameterNumber,
            stringValue.value,
          );
          await Future.delayed(const Duration(milliseconds: 10));
        }
      }

      // 6. RESTORE MIDI/CV MAPPINGS
      for (final mapping in savedMappings) {
        if (mapping.parameterNumber != programParameterNumber) {
          await disting.requestSetMapping(
            algorithmIndex,
            mapping.parameterNumber,
            mapping.packedMappingData,
          );
          await Future.delayed(const Duration(milliseconds: 10));
        }
      }
    } catch (e) {
      // On error, refresh the slot to ensure UI is in sync with hardware
      await _refreshSlotAfterAnomaly(algorithmIndex);
      rethrow;
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

    try {
      await disting.backupPlugins(backupDirectory, onProgress: onProgress);
    } catch (e) {
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
      } catch (e) {
        final errorMsg = "Failed to install ${file.filename}: $e";
        onFileError?.call(file.filename, errorMsg);
      }
    }
  }

  /// Install a single file to a specific path on the SD card
  Future<void> installFileToPath(
    String targetPath,
    Uint8List fileData, {
    Function(double)? onProgress,
  }) async {
    final disting = requireDisting();
    await disting.requestWake();

    // Upload in 512-byte chunks (matching existing implementation)
    const chunkSize = 512;
    int uploadPos = 0;

    while (uploadPos < fileData.length) {
      final remainingBytes = fileData.length - uploadPos;
      final currentChunkSize = remainingBytes < chunkSize
          ? remainingBytes
          : chunkSize;
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
  }

  /// Load a plugin using the dedicated 0x38 Load Plugin SysEx command
  /// and refresh the specific algorithm info with updated specifications
  Future<AlgorithmInfo?> loadPlugin(String guid) async {
    final currentState = state;
    if (currentState is! DistingStateSynchronized) {
      return null;
    }

    final disting = requireDisting();

    // Find the algorithm by GUID
    final algorithmIndex = currentState.algorithms.indexWhere(
      (algo) => algo.guid == guid,
    );

    if (algorithmIndex == -1) {
      return null;
    }

    final algorithm = currentState.algorithms[algorithmIndex];

    // Check if it's already loaded
    if (algorithm.isLoaded) {
      return algorithm;
    }

    try {
      // 1. Send load plugin command
      await disting.requestLoadPlugin(guid);

      // Wait a bit
      await Future.delayed(const Duration(milliseconds: 1000));

      // 2. Request updated info for just this algorithm
      final updatedInfo = await disting.requestAlgorithmInfo(algorithmIndex);

      if (updatedInfo != null && updatedInfo.isLoaded) {
        // 3. Update only this algorithm in the state
        final updatedAlgorithms = List<AlgorithmInfo>.from(
          currentState.algorithms,
        );
        updatedAlgorithms[algorithmIndex] = updatedInfo;

        emit(currentState.copyWith(algorithms: updatedAlgorithms));
        return updatedInfo;
      } else {
        // Loading failed - either couldn't get info or plugin didn't load
        return null;
      }
    } catch (e, stackTrace) {
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
