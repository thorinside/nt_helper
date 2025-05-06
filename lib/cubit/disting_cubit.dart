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
import 'package:nt_helper/domain/mock_disting_midi_manager.dart';
import 'package:nt_helper/domain/offline_disting_midi_manager.dart';
import 'package:nt_helper/models/packed_mapping_data.dart';
import 'package:nt_helper/models/routing_information.dart';
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

class DistingCubit extends Cubit<DistingState> {
  final AppDatabase _database; // Added
  late final MetadataDao _metadataDao; // Added
  final Future<SharedPreferences> _prefs;

  // Modified constructor
  DistingCubit(this._database)
      : _prefs = SharedPreferences.getInstance(),
        super(const DistingState.initial()) {
    _metadataDao = _database.metadataDao; // Initialize DAO
  }

  MidiCommand _midiCommand = MidiCommand();
  CancelableOperation<void>? _programSlotUpdate;
  CancelableOperation<void>?
      _moveVerificationOperation; // Add verification operation tracker
  // Keep track of the offline manager instance when offline
  OfflineDistingMidiManager? _offlineManager;

  // Added: Store last known online connection details
  MidiDevice? _lastOnlineInputDevice;
  MidiDevice? _lastOnlineOutputDevice;
  int? _lastOnlineSysExId;

  @override
  Future<void> close() {
    disting()?.dispose();
    _offlineManager?.dispose(); // Dispose offline manager too
    _midiCommand.dispose();
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
    // // --- Define Standard I/O Enum Values --- // Removed - Moved to Mock Manager
    // final List<String> ioEnumValues = [
    //   ...List.generate(12, (i) => "Input ${i + 1}"),
    //   ...List.generate(8, (i) => "Output ${i + 1}"),
    //   ...List.generate(8, (i) => "Aux ${i + 1}"),
    // ];
    // const int ioEnumMax = 27; // 12 + 8 + 8 - 1

    // // --- Define Demo Algorithms --- // Removed - Moved to Mock Manager
    // final List<AlgorithmInfo> demoAlgorithms = <AlgorithmInfo>[
    //   AlgorithmInfo(
    //       algorithmIndex: 0,
    //       guid: "clk ",
    //       name: "Clock",
    //       numSpecifications: 0,
    //       specifications: []),
    //   AlgorithmInfo(
    //       algorithmIndex: 1,
    //       guid: "seq ",
    //       name: "Step Sequencer",
    //       numSpecifications: 0,
    //       specifications: []),
    //   AlgorithmInfo(
    //       algorithmIndex: 2,
    //       guid: "sine",
    //       name: "Sine Oscillator",
    //       numSpecifications: 0,
    //       specifications: []),
    // ];

    // // --- Define Demo Slot 0: Clock --- // Removed - Moved to Mock Manager
    // final List<ParameterInfo> clockParams = <ParameterInfo>[
    //   ParameterInfo(
    //       algorithmIndex: 0,
    //       parameterNumber: 0,
    //       name: "BPM",
    //       min: 20,
    //       max: 300,
    //       defaultValue: 120,
    //       unit: 0,
    //       powerOfTen: 0),
    //   // ... other clock params ...
    // ];
    // final List<ParameterValue> clockValues = <ParameterValue>[
    //    ParameterValue(algorithmIndex: 0, parameterNumber: 0, value: 120),
    //    // ... other clock values ...
    // ];
    // final List<ParameterEnumStrings> clockEnums = <ParameterEnumStrings>[
    //   ParameterEnumStrings.filler(), // BPM
    //   // ... other clock enums ...
    // ];
    // final ParameterPages clockPages = ParameterPages(algorithmIndex: 0, pages: [
    //   ParameterPage(name: "Timing", parameters: [0, 1]),
    //   // ... other clock pages ...
    // ]);
    // final List<Mapping> clockMappings =
    //     List<Mapping>.generate(clockParams.length, (_) => Mapping.filler());
    // final List<ParameterValueString> clockValueStrings =
    //     List<ParameterValueString>.generate(
    //         clockParams.length, (_) => ParameterValueString.filler());
    // final Slot clockSlot = Slot(
    //   algorithm: Algorithm(algorithmIndex: 0, guid: "clk ", name: "Clock"),
    //   routing: RoutingInfo.filler(),
    //   pages: clockPages,
    //   parameters: clockParams,
    //   values: clockValues,
    //   enums: clockEnums,
    //   mappings: clockMappings,
    //   valueStrings: clockValueStrings,
    // );

    // // --- Define Demo Slot 1: Step Sequencer --- // Removed - Moved to Mock Manager
    // // ... similar definitions for sequencer ...
    // final Slot sequencerSlot = Slot(
    //   algorithm:
    //       Algorithm(algorithmIndex: 1, guid: "seq ", name: "Step Sequencer"),
    //   routing: RoutingInfo.filler(),
    //   pages: seqPages,
    //   parameters: seqParams,
    //   values: seqValues,
    //   enums: seqEnums,
    //   mappings: seqMappings,
    //   valueStrings: seqValueStrings,
    // );

    // // --- Define Demo Slot 2: Sine Oscillator --- // Removed - Moved to Mock Manager
    // // ... similar definitions for sine ...
    // final Slot sineSlot = Slot(
    //   algorithm:
    //       Algorithm(algorithmIndex: 2, guid: "sine", name: "Sine Oscillator"),
    //   routing: RoutingInfo.filler(),
    //   pages: sinePages,
    //   parameters: sineParams,
    //   values: sineValues,
    //   enums: sineEnums,
    //   mappings: sineMappings,
    //   valueStrings: sineValueStrings,
    // );

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
      disting: mockManager, // Use the created mock manager instance
      distingVersion: distingVersion,
      presetName: presetName,
      algorithms: algorithms,
      slots: slots,
      unitStrings: unitStrings,
      demo: true,
    ));
  }

  // Helper to fetch AlgorithmInfo list from mock/offline manager
  Future<List<AlgorithmInfo>> _fetchMockAlgorithms(
      IDistingMidiManager manager) async {
    final numAlgorithms = await manager.requestNumberOfAlgorithms() ?? 0;
    final List<Future<AlgorithmInfo?>> futures = [];
    for (int i = 0; i < numAlgorithms; i++) {
      futures.add(manager.requestAlgorithmInfo(i));
    }
    final results = await Future.wait(futures);
    return results.whereType<AlgorithmInfo>().toList();
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

      final numAlgorithms =
          (await distingManager.requestNumberOfAlgorithms()) ?? 0;
      final algorithms = numAlgorithms > 0
          ? await Future.wait([
              for (int i = 0; i < numAlgorithms; i++)
                distingManager.requestAlgorithmInfo(i)
            ]).then((results) => results.whereType<AlgorithmInfo>().toList())
          : <AlgorithmInfo>[];
      final numAlgorithmsInPreset =
          (await distingManager.requestNumAlgorithmsInPreset()) ?? 0;
      final distingVersion = await distingManager.requestVersionString() ?? "";
      final presetName = await distingManager.requestPresetName() ?? "Default";
      var unitStrings = await distingManager.requestUnitStrings() ?? [];
      List<Slot> slots =
          await fetchSlots(numAlgorithmsInPreset, distingManager);
      debugPrint("[Cubit] _performSyncAndEmit: Fetched ${slots.length} slots.");

      // --- Emit final synchronized state --- (Ensure offline is false)
      emit(DistingState.synchronized(
        disting: distingManager,
        distingVersion: distingVersion,
        presetName: presetName,
        algorithms: algorithms,
        slots: slots,
        unitStrings: unitStrings,
        inputDevice: inputDevice,
        outputDevice: outputDevice,
        loading: false,
        offline: false,
      ));
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

      // Store these details as the last successful ONLINE connection
      // BEFORE starting the full sync.
      _lastOnlineInputDevice = inputDevice;
      _lastOnlineOutputDevice = outputDevice;
      _lastOnlineSysExId = sysExId; // Use the parameter passed to this method

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
      _offlineManager = OfflineDistingMidiManager(_database);
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
        disting: _offlineManager!, // Use offline manager
        distingVersion: version,
        presetName: presetName,
        algorithms: availableAlgorithmsInfo,
        slots: initialSlots,
        unitStrings: units,
        inputDevice: null, // No devices when offline
        outputDevice: null,
        offline: true,
        loading: false,
      ));
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
        presetName: presetName,
        algorithms: availableAlgorithmsInfo,
        slots: slots,
        unitStrings: units,
        offline: true, // Remain offline
        loading: false,
        screenshot: currentState.screenshot, // Preserve screenshot if any
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
          numSpecifications: details.algorithm.numSpecifications,
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

  /// Refreshes the entire state from the Disting device (ONLINE ONLY).
  Future<void> refresh() async {
    debugPrint("[Cubit] Refresh requested.");
    final currentState = state;
    if (currentState is DistingStateSynchronized) {
      // *** Add check for offline mode ***
      if (currentState.offline) {
        debugPrint("[Cubit] Cannot refresh while offline.");
        return;
      }
      // Proceed with online refresh
      await _performSyncAndEmit(); // Call the helper
    } else {
      debugPrint("[Cubit] Cannot refresh: Not in Synchronized state.");
      // Optionally handle error or do nothing
    }
  }

  IDistingMidiManager requireDisting() {
    if (state is DistingStateConnected) {
      return (state as DistingStateConnected).disting;
    }
    if (state is DistingStateSynchronized) {
      // Return offline manager if offline, otherwise online manager
      final syncState = (state as DistingStateSynchronized);
      return syncState.offline ? _offlineManager! : syncState.disting;
    }
    throw Exception("Device is not connected or synchronized.");
  }

  IDistingMidiManager? disting() {
    if (state is DistingStateConnected) {
      return (state as DistingStateConnected).disting;
    }
    if (state is DistingStateSynchronized) {
      final syncState = (state as DistingStateSynchronized);
      return syncState.offline ? _offlineManager : syncState.disting;
    }
    return null;
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

  void updateParameterValue({
    required int algorithmIndex,
    required int parameterNumber,
    required int value,
    required bool userIsChangingTheValue,
  }) async {
    debugPrint("value = $value, userChanging = $userIsChangingTheValue");

    switch (state) {
      case DistingStateInitial():
      case DistingStateSelectDevice():
      case DistingStateConnected():
        break;
      case DistingStateSynchronized syncstate:
        var disting = requireDisting();

        disting.setParameterValue(
          algorithmIndex,
          parameterNumber,
          value,
        );

        if (!userIsChangingTheValue) {
          // Special case for switching programs
          if (_isProgramParameter(syncstate, algorithmIndex, parameterNumber)) {
            _programSlotUpdate?.cancel();

            _programSlotUpdate = CancelableOperation.fromFuture(Future.delayed(
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

          final newValue = await disting.requestParameterValue(
            algorithmIndex,
            parameterNumber,
          );

          final state = (this.state as DistingStateSynchronized);

          var valueStrings = [
            for (int parameterNumber = 0;
                parameterNumber <
                    state.slots[algorithmIndex].valueStrings.length;
                parameterNumber++)
              if ([13, 14, 17].contains(
                  state.slots[algorithmIndex].parameters[parameterNumber].unit))
                await disting.requestParameterValueString(
                        algorithmIndex, parameterNumber) ??
                    ParameterValueString.filler()
              else
                ParameterValueString.filler()
          ];

          final routings = !([
            13,
            14,
            17,
          ].contains(
                  state.slots[algorithmIndex].parameters[parameterNumber].unit))
              ? await disting.requestRoutingInformation(algorithmIndex)
              : state.slots[algorithmIndex].routing;

          emit(state.copyWith(
            slots: updateSlot(
              algorithmIndex,
              state.slots,
              (slot) {
                return slot.copyWith(
                    values: replaceInList(
                      slot.values,
                      newValue!,
                      index: parameterNumber,
                    ),
                    routing: routings ?? state.slots[algorithmIndex].routing,
                    valueStrings: valueStrings);
              },
            ),
          ));
        }
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

        await disting.requestAddAlgorithm(algorithm, specsToSend);

        // Refresh state from manager
        await _refreshStateFromManager(); // Use helper to refresh
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
        final disting = requireDisting();
        await disting.requestRemoveAlgorithm(algorithmIndex);

        // Refresh state from manager
        await _refreshStateFromManager(); // Use helper to refresh
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
              disting:
                  verificationState.disting, // Keep manager and other state
              distingVersion: verificationState.distingVersion,
              presetName:
                  verificationState.presetName, // Use existing preset name
              algorithms: verificationState.algorithms,
              slots: actualSlots, // Use actual slots
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
              disting:
                  verificationState.disting, // Keep manager and other state
              distingVersion: verificationState.distingVersion,
              presetName:
                  verificationState.presetName, // Use existing preset name
              algorithms: verificationState.algorithms,
              slots: actualSlots, // Use actual slots
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
      case DistingStateSynchronized syncstate:
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

      final currentState = state;
      if (currentState is DistingStateSynchronized) {
        final currentSlot = currentState.slots[mapped.parameter.algorithmIndex];
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
    debugPrint(
        "[Cubit] fetchSlots: Requesting $numAlgorithmsInPreset slots...");
    final slotsFutures =
        List.generate(numAlgorithmsInPreset, (algorithmIndex) async {
      return await fetchSlot(disting, algorithmIndex);
    });

    // Finish off the requests
    final slots = await Future.wait(slotsFutures);
    debugPrint("[Cubit] fetchSlots: Fetched ${slots.length} slots.");
    return slots;
  }

  Future<Slot> fetchSlot(
      IDistingMidiManager disting, int algorithmIndex) async {
    // Safely get number of parameters, default to 0 if null
    final numParamsResult =
        await disting.requestNumberOfParameters(algorithmIndex);
    final int numParametersInAlgorithm = numParamsResult?.numParameters ?? 0;

    var parameters = <ParameterInfo>[];
    if (numParametersInAlgorithm > 0) {
      parameters = [
        for (int parameterNumber = 0;
            parameterNumber < numParametersInAlgorithm;
            parameterNumber++)
          await disting.requestParameterInfo(algorithmIndex, parameterNumber) ??
              ParameterInfo.filler()
      ];
    } // else parameters remains empty

    var parameterPages = await disting.requestParameterPages(algorithmIndex) ??
        ParameterPages.filler();

    var visibleParameters = parameterPages.pages.expand(
      (element) {
        return element.parameters;
      },
    );

    // Safely get parameter values, default to empty list if null or no params
    final allValuesResult =
        await disting.requestAllParameterValues(algorithmIndex);
    final parameterValues = allValuesResult?.values ??
        List<ParameterValue>.generate(
            numParametersInAlgorithm,
            // Use filler without arguments
            (i) => ParameterValue.filler());

    var enums = <ParameterEnumStrings>[];
    // Ensure loop condition respects potentially 0 parameters
    for (int i = 0; i < numParametersInAlgorithm; i++) {
      ParameterEnumStrings? fetchedEnums;
      // Only fetch enums if visible on a page AND if the parameter unit is 1 (Enum)
      final isVisible =
          parameterPages.pages.any((page) => page.parameters.contains(i));
      // Check parameters list bounds before accessing unit
      final isEnum = (i < parameters.length) ? parameters[i].unit == 1 : false;

      if (isVisible && isEnum) {
        fetchedEnums =
            await disting.requestParameterEnumStrings(algorithmIndex, i);
      }
      // Add the result from the manager (could be I/O, custom, or filler)
      enums.add(fetchedEnums ?? ParameterEnumStrings.filler());
    }

    var mappings = <Mapping>[];
    // Ensure loop condition respects potentially 0 parameters
    for (int parameterNumber = 0;
        parameterNumber < numParametersInAlgorithm;
        parameterNumber++) {
      mappings.add(visibleParameters.contains(parameterNumber)
          ? await disting.requestMappings(algorithmIndex, parameterNumber) ??
              Mapping.filler()
          : Mapping.filler());
    }

    var routing = await disting.requestRoutingInformation(algorithmIndex) ??
        RoutingInfo.filler();

    var valueStrings = <ParameterValueString>[];
    // Ensure loop condition respects potentially 0 parameters
    for (int parameterNumber = 0;
        parameterNumber < numParametersInAlgorithm;
        parameterNumber++) {
      // Check parameters list bounds before accessing unit
      final paramInfo = (parameterNumber < parameters.length)
          ? parameters[parameterNumber]
          : null;
      // Use -1 or another value that won't match if paramInfo is null or unit is missing
      final unit = paramInfo?.unit ?? -1;

      // Check if the parameter's unit indicates it might be a string (13, 14, 17)
      // and if it's meant to be visible.
      if ([13, 14, 17].contains(unit) &&
          visibleParameters.contains(parameterNumber)) {
        // --- Debug Logging: Log BEFORE requesting ---
        // Log the details of the parameter for which we are about to request a string value.
        debugPrint(
            "[fetchSlot Debug] Requesting string for AlgoIndex: $algorithmIndex, ParamNum: $parameterNumber, Unit: $unit");
        // --- End Debug Logging ---

        // Request the actual string value from the manager (device or offline cache).
        final stringResult = await disting.requestParameterValueString(
            algorithmIndex, parameterNumber);

        // --- Debug Logging: Log AFTER receiving ---
        // Log the details again, including the string value that was actually received.
        // This helps verify if the junk data is present in the received value.
        debugPrint(
            "[fetchSlot Debug] Received string for AlgoIndex: $algorithmIndex, ParamNum: $parameterNumber, Unit: $unit, Value: '${stringResult?.value ?? 'NULL'}'");
        // --- End Debug Logging ---

        // Add the received string (or a filler if the request failed) to the list.
        valueStrings.add(stringResult ?? ParameterValueString.filler());
      } else {
        // If it's not a string unit or not visible, add a filler.
        valueStrings.add(ParameterValueString.filler());
      }
    }

    // Safely get algorithm GUID, default to filler if null
    final algorithmGuid = await disting.requestAlgorithmGuid(algorithmIndex);

    // Debug print before returning
    debugPrint(
        "[Cubit] fetchSlot($algorithmIndex): GUID=${algorithmGuid?.guid}, Name=${algorithmGuid?.name}, Params=${parameters.length}, Vals=${parameterValues.length}, Enums=${enums.length}, Maps=${mappings.length}, ValStrs=${valueStrings.length}");

    return Slot(
      // Use a default constructed Algorithm if guid is null
      algorithm: algorithmGuid ??
          Algorithm(
              algorithmIndex: algorithmIndex,
              guid: "ERROR",
              name: "Error fetching Algorithm"),
      pages: parameterPages,
      parameters: parameters, // Already handled if numParams was 0
      values: parameterValues, // Already handled if result was null
      enums: enums,
      mappings: mappings,
      valueStrings: valueStrings,
      routing: routing,
    );
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
}
