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
  late final PresetsDao _presetsDao; // Added PresetsDao
  final Future<SharedPreferences> _prefs;

  // Modified constructor
  DistingCubit(this._database)
      : _prefs = SharedPreferences.getInstance(),
        super(const DistingState.initial()) {
    _metadataDao = _database.metadataDao; // Initialize DAO
    _presetsDao = _database.presetsDao; // Initialize PresetsDao
  }

  MidiCommand _midiCommand = MidiCommand();
  CancelableOperation<void>? _programSlotUpdate;
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
    // --- Define Standard I/O Enum Values ---
    final List<String> ioEnumValues = [
      ...List.generate(12, (i) => "Input ${i + 1}"),
      ...List.generate(8, (i) => "Output ${i + 1}"),
      ...List.generate(8, (i) => "Aux ${i + 1}"),
    ];
    const int ioEnumMax = 27; // 12 + 8 + 8 - 1

    // --- Define Demo Algorithms ---
    final List<AlgorithmInfo> demoAlgorithms = <AlgorithmInfo>[
      AlgorithmInfo(
          algorithmIndex: 0,
          guid: "clk ",
          name: "Clock",
          numSpecifications: 0,
          specifications: []),
      AlgorithmInfo(
          algorithmIndex: 1,
          guid: "seq ",
          name: "Step Sequencer",
          numSpecifications: 0,
          specifications: []),
      AlgorithmInfo(
          algorithmIndex: 2,
          guid: "sine",
          name: "Sine Oscillator",
          numSpecifications: 0,
          specifications: []),
    ];

    // --- Define Demo Slot 0: Clock ---
    final List<ParameterInfo> clockParams = <ParameterInfo>[
      ParameterInfo(
          algorithmIndex: 0,
          parameterNumber: 0,
          name: "BPM",
          min: 20,
          max: 300,
          defaultValue: 120,
          unit: 0,
          powerOfTen: 0),
      ParameterInfo(
          algorithmIndex: 0,
          parameterNumber: 1,
          name: "Multiplier",
          min: 0,
          max: 4,
          defaultValue: 2,
          unit: 1,
          powerOfTen: 0), // Enum unit
      ParameterInfo(
          algorithmIndex: 0,
          parameterNumber: 2,
          name: "Swing",
          min: 0,
          max: 100,
          defaultValue: 50,
          unit: 1,
          powerOfTen: 0), // % unit
      ParameterInfo(
          algorithmIndex: 0,
          parameterNumber: 3,
          name: "Clock In",
          min: 0,
          max: ioEnumMax,
          defaultValue: 0,
          unit: 1,
          powerOfTen: 0), // Input 1
      ParameterInfo(
          algorithmIndex: 0,
          parameterNumber: 4,
          name: "Reset In",
          min: 0,
          max: ioEnumMax,
          defaultValue: 1,
          unit: 1,
          powerOfTen: 0), // Input 2
      ParameterInfo(
          algorithmIndex: 0,
          parameterNumber: 5,
          name: "Clock Out",
          min: 0,
          max: ioEnumMax,
          defaultValue: 12,
          unit: 1,
          powerOfTen: 0), // Output 1
      ParameterInfo(
          algorithmIndex: 0,
          parameterNumber: 6,
          name: "Bypass",
          min: 0,
          max: 1,
          defaultValue: 0,
          unit: 1,
          powerOfTen: 0), // Enum unit
    ];
    final List<ParameterValue> clockValues = <ParameterValue>[
      ParameterValue(algorithmIndex: 0, parameterNumber: 0, value: 120),
      ParameterValue(algorithmIndex: 0, parameterNumber: 1, value: 2), // x1
      ParameterValue(algorithmIndex: 0, parameterNumber: 2, value: 50),
      ParameterValue(
          algorithmIndex: 0, parameterNumber: 3, value: 0), // Input 1
      ParameterValue(
          algorithmIndex: 0, parameterNumber: 4, value: 1), // Input 2
      ParameterValue(
          algorithmIndex: 0, parameterNumber: 5, value: 12), // Output 1
      ParameterValue(algorithmIndex: 0, parameterNumber: 6, value: 0), // Off
    ];
    final List<ParameterEnumStrings> clockEnums = <ParameterEnumStrings>[
      ParameterEnumStrings.filler(), // BPM
      ParameterEnumStrings(
          algorithmIndex: 0,
          parameterNumber: 1,
          values: ["/4", "/2", "x1", "x2", "x4"]), // Multiplier
      ParameterEnumStrings.filler(), // Swing
      ParameterEnumStrings(
          algorithmIndex: 0,
          parameterNumber: 3,
          values: ioEnumValues), // Clock In
      ParameterEnumStrings(
          algorithmIndex: 0,
          parameterNumber: 4,
          values: ioEnumValues), // Reset In
      ParameterEnumStrings(
          algorithmIndex: 0,
          parameterNumber: 5,
          values: ioEnumValues), // Clock Out
      ParameterEnumStrings(
          algorithmIndex: 0,
          parameterNumber: 6,
          values: ["Off", "On"]), // Bypass
    ];
    final ParameterPages clockPages = ParameterPages(algorithmIndex: 0, pages: [
      ParameterPage(name: "Timing", parameters: [0, 1]),
      ParameterPage(name: "Feel", parameters: [2]),
      ParameterPage(name: "Routing", parameters: [3, 4, 5]),
      ParameterPage(name: "Algorithm", parameters: [6]),
    ]);
    // Explicitly typed lists for mappings and valueStrings
    final List<Mapping> clockMappings =
        List<Mapping>.generate(clockParams.length, (_) => Mapping.filler());
    final List<ParameterValueString> clockValueStrings =
        List<ParameterValueString>.generate(
            clockParams.length, (_) => ParameterValueString.filler());
    final Slot clockSlot = Slot(
      algorithm: Algorithm(algorithmIndex: 0, guid: "clk ", name: "Clock"),
      routing: RoutingInfo.filler(),
      pages: clockPages,
      parameters: clockParams,
      values: clockValues,
      enums: clockEnums,
      mappings: clockMappings,
      valueStrings: clockValueStrings,
    );

    // --- Define Demo Slot 1: Step Sequencer ---
    final List<ParameterInfo> seqParams = <ParameterInfo>[
      ParameterInfo(
          algorithmIndex: 1,
          parameterNumber: 0,
          name: "Steps",
          min: 1,
          max: 16,
          defaultValue: 8,
          unit: 0,
          powerOfTen: 0),
      ParameterInfo(
          algorithmIndex: 1,
          parameterNumber: 1,
          name: "Gate Length",
          min: 0,
          max: 100,
          defaultValue: 50,
          unit: 1,
          powerOfTen: 0), // %
      ParameterInfo(
          algorithmIndex: 1,
          parameterNumber: 2,
          name: "Direction",
          min: 0,
          max: 3,
          defaultValue: 0,
          unit: 1,
          powerOfTen: 0), // Enum
      ParameterInfo(
          algorithmIndex: 1,
          parameterNumber: 3,
          name: "Sequence Length",
          min: 1,
          max: 16,
          defaultValue: 8,
          unit: 0,
          powerOfTen: 0),
      ParameterInfo(
          algorithmIndex: 1,
          parameterNumber: 4,
          name: "CV Out",
          min: 0,
          max: ioEnumMax,
          defaultValue: 12,
          unit: 1,
          powerOfTen: 0), // Output 1
      ParameterInfo(
          algorithmIndex: 1,
          parameterNumber: 5,
          name: "Gate Out",
          min: 0,
          max: ioEnumMax,
          defaultValue: 13,
          unit: 1,
          powerOfTen: 0), // Output 2
      ParameterInfo(
          algorithmIndex: 1,
          parameterNumber: 6,
          name: "Clock In",
          min: 0,
          max: ioEnumMax,
          defaultValue: 0,
          unit: 1,
          powerOfTen: 0), // Input 1
      ParameterInfo(
          algorithmIndex: 1,
          parameterNumber: 7,
          name: "Reset In",
          min: 0,
          max: ioEnumMax,
          defaultValue: 1,
          unit: 1,
          powerOfTen: 0), // Input 2
      ParameterInfo(
          algorithmIndex: 1,
          parameterNumber: 8,
          name: "Bypass",
          min: 0,
          max: 1,
          defaultValue: 0,
          unit: 1,
          powerOfTen: 0), // Enum
    ];
    final List<ParameterValue> seqValues = <ParameterValue>[
      ParameterValue(algorithmIndex: 1, parameterNumber: 0, value: 8),
      ParameterValue(algorithmIndex: 1, parameterNumber: 1, value: 50),
      ParameterValue(algorithmIndex: 1, parameterNumber: 2, value: 0), // Fwd
      ParameterValue(algorithmIndex: 1, parameterNumber: 3, value: 8),
      ParameterValue(
          algorithmIndex: 1, parameterNumber: 4, value: 12), // Output 1
      ParameterValue(
          algorithmIndex: 1, parameterNumber: 5, value: 13), // Output 2
      ParameterValue(
          algorithmIndex: 1, parameterNumber: 6, value: 0), // Input 1
      ParameterValue(
          algorithmIndex: 1, parameterNumber: 7, value: 1), // Input 2
      ParameterValue(algorithmIndex: 1, parameterNumber: 8, value: 0), // Off
    ];
    final List<ParameterEnumStrings> seqEnums = <ParameterEnumStrings>[
      ParameterEnumStrings.filler(), // Steps
      ParameterEnumStrings.filler(), // Gate Length
      ParameterEnumStrings(
          algorithmIndex: 1,
          parameterNumber: 2,
          values: ["Fwd", "Rev", "Png", "Rnd"]), // Direction
      ParameterEnumStrings.filler(), // Sequence Length
      ParameterEnumStrings(
          algorithmIndex: 1,
          parameterNumber: 4,
          values: ioEnumValues), // CV Out
      ParameterEnumStrings(
          algorithmIndex: 1,
          parameterNumber: 5,
          values: ioEnumValues), // Gate Out
      ParameterEnumStrings(
          algorithmIndex: 1,
          parameterNumber: 6,
          values: ioEnumValues), // Clock In
      ParameterEnumStrings(
          algorithmIndex: 1,
          parameterNumber: 7,
          values: ioEnumValues), // Reset In
      ParameterEnumStrings(
          algorithmIndex: 1,
          parameterNumber: 8,
          values: ["Off", "On"]), // Bypass
    ];
    final ParameterPages seqPages = ParameterPages(algorithmIndex: 1, pages: [
      ParameterPage(name: "Sequence", parameters: [0, 3, 2]),
      ParameterPage(name: "Output", parameters: [1, 4, 5]),
      ParameterPage(name: "Routing", parameters: [6, 7]),
      ParameterPage(name: "Algorithm", parameters: [8]),
    ]);
    // Explicitly typed lists
    final List<Mapping> seqMappings =
        List<Mapping>.generate(seqParams.length, (_) => Mapping.filler());
    final List<ParameterValueString> seqValueStrings =
        List<ParameterValueString>.generate(
            seqParams.length, (_) => ParameterValueString.filler());
    final Slot sequencerSlot = Slot(
      algorithm:
          Algorithm(algorithmIndex: 1, guid: "seq ", name: "Step Sequencer"),
      routing: RoutingInfo.filler(),
      pages: seqPages,
      parameters: seqParams,
      values: seqValues,
      enums: seqEnums,
      mappings: seqMappings,
      valueStrings: seqValueStrings,
    );

    // --- Define Demo Slot 2: Sine Oscillator ---
    final List<ParameterInfo> sineParams = <ParameterInfo>[
      ParameterInfo(
          algorithmIndex: 2,
          parameterNumber: 0,
          name: "Frequency",
          min: 0,
          max: 8000,
          defaultValue: 440,
          unit: 2,
          powerOfTen: 0), // Hz unit
      ParameterInfo(
          algorithmIndex: 2,
          parameterNumber: 1,
          name: "Level",
          min: -96,
          max: 0,
          defaultValue: -6,
          unit: 3,
          powerOfTen: 0), // dB unit
      ParameterInfo(
          algorithmIndex: 2,
          parameterNumber: 2,
          name: "Phase",
          min: 0,
          max: 360,
          defaultValue: 0,
          unit: 4,
          powerOfTen: 0), // Degree unit
      ParameterInfo(
          algorithmIndex: 2,
          parameterNumber: 3,
          name: "Octave",
          min: -2,
          max: 2,
          defaultValue: 0,
          unit: 0,
          powerOfTen: 0),
      ParameterInfo(
          algorithmIndex: 2,
          parameterNumber: 4,
          name: "CV In (V/Oct)",
          min: 0,
          max: ioEnumMax,
          defaultValue: 0,
          unit: 1,
          powerOfTen: 0), // Input 1
      ParameterInfo(
          algorithmIndex: 2,
          parameterNumber: 5,
          name: "Gate In",
          min: 0,
          max: ioEnumMax,
          defaultValue: 1,
          unit: 1,
          powerOfTen: 0), // Input 2
      ParameterInfo(
          algorithmIndex: 2,
          parameterNumber: 6,
          name: "Audio Out L",
          min: 0,
          max: ioEnumMax,
          defaultValue: 12,
          unit: 1,
          powerOfTen: 0), // Output 1
      ParameterInfo(
          algorithmIndex: 2,
          parameterNumber: 7,
          name: "Audio Out R",
          min: 0,
          max: ioEnumMax,
          defaultValue: 13,
          unit: 1,
          powerOfTen: 0), // Output 2
      ParameterInfo(
          algorithmIndex: 2,
          parameterNumber: 8,
          name: "Bypass",
          min: 0,
          max: 1,
          defaultValue: 0,
          unit: 1,
          powerOfTen: 0), // Enum unit
    ];
    final List<ParameterValue> sineValues = <ParameterValue>[
      ParameterValue(algorithmIndex: 2, parameterNumber: 0, value: 440),
      ParameterValue(algorithmIndex: 2, parameterNumber: 1, value: -6),
      ParameterValue(algorithmIndex: 2, parameterNumber: 2, value: 0),
      ParameterValue(algorithmIndex: 2, parameterNumber: 3, value: 0),
      ParameterValue(
          algorithmIndex: 2, parameterNumber: 4, value: 0), // Input 1
      ParameterValue(
          algorithmIndex: 2, parameterNumber: 5, value: 1), // Input 2
      ParameterValue(
          algorithmIndex: 2, parameterNumber: 6, value: 12), // Output 1
      ParameterValue(
          algorithmIndex: 2, parameterNumber: 7, value: 13), // Output 2
      ParameterValue(algorithmIndex: 2, parameterNumber: 8, value: 0), // Off
    ];
    final List<ParameterEnumStrings> sineEnums =
        List<ParameterEnumStrings>.generate(sineParams.length, (i) {
      if (i >= 4 && i <= 7) {
        return ParameterEnumStrings(
            algorithmIndex: 2, parameterNumber: i, values: ioEnumValues);
      }
      if (i == 8) {
        return ParameterEnumStrings(
            algorithmIndex: 2,
            parameterNumber: 8,
            values: ["Off", "On"]); // Bypass
      }
      return ParameterEnumStrings.filler();
    });
    final ParameterPages sinePages = ParameterPages(algorithmIndex: 2, pages: [
      ParameterPage(name: "Pitch", parameters: [0, 3]),
      ParameterPage(name: "Shape", parameters: [1, 2]),
      ParameterPage(name: "Routing", parameters: [4, 5, 6, 7]),
      ParameterPage(name: "Algorithm", parameters: [8]),
    ]);
    // Explicitly typed lists
    final List<Mapping> sineMappings =
        List<Mapping>.generate(sineParams.length, (_) => Mapping.filler());
    final List<ParameterValueString> sineValueStrings =
        List<ParameterValueString>.generate(
            sineParams.length, (_) => ParameterValueString.filler());
    final Slot sineSlot = Slot(
      algorithm:
          Algorithm(algorithmIndex: 2, guid: "sine", name: "Sine Oscillator"),
      routing: RoutingInfo.filler(),
      pages: sinePages,
      parameters: sineParams,
      values: sineValues,
      enums: sineEnums,
      mappings: sineMappings,
      valueStrings: sineValueStrings,
    );

    // --- Emit the State ---
    emit(DistingState.synchronized(
      disting: MockDistingMidiManager(),
      distingVersion: "Demo v1.0",
      presetName: "Screech",
      algorithms: demoAlgorithms,
      slots: [clockSlot, sequencerSlot, sineSlot],
      unitStrings: ["", "%", "Hz", "dB", "°", "V/Oct"],
      // Keep existing units, enum unit (1) is handled internally
      demo: true,
    ));
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

  Future<void> loadPresetOffline(FullPresetDetails presetDetails) async {
    final currentState = state;
    if (!(currentState is DistingStateSynchronized && currentState.offline)) {
      print("Error: Cannot load preset offline when not in offline mode.");
      return;
    }
    if (_offlineManager == null) {
      print("Error: Offline manager not initialized.");
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
    if (kDebugMode) {
      print("value = $value, userChanging = $userIsChangingTheValue");
    }

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
    final currentState = state;
    if (currentState is! DistingStateSynchronized) return algorithmIndex;
    if (algorithmIndex == 0) return 0;

    final disting = requireDisting();
    await disting.requestMoveAlgorithmUp(algorithmIndex);
    await _refreshStateFromManager(); // Refresh state from manager
    return algorithmIndex - 1; // Assume manager updated index correctly
  }

  Future<int> moveAlgorithmDown(int algorithmIndex) async {
    final currentState = state;
    if (currentState is! DistingStateSynchronized) return algorithmIndex;
    if (algorithmIndex >= currentState.slots.length - 1) return algorithmIndex;

    final disting = requireDisting();
    await disting.requestMoveAlgorithmDown(algorithmIndex);
    await _refreshStateFromManager(); // Refresh state from manager
    return algorithmIndex + 1; // Assume manager updated index correctly
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
        print("Error: Cannot load device preset while offline.");
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
    final slotsFutures =
        List.generate(numAlgorithmsInPreset, (algorithmIndex) async {
      return await fetchSlot(disting, algorithmIndex);
    });

    // Finish off the requests
    final slots = await Future.wait(slotsFutures);
    return slots;
  }

  Future<Slot> fetchSlot(
      IDistingMidiManager disting, int algorithmIndex) async {
    int numParametersInAlgorithm =
        (await disting.requestNumberOfParameters(algorithmIndex))!
            .numParameters;
    var parameters = [
      for (int parameterNumber = 0;
          parameterNumber < numParametersInAlgorithm;
          parameterNumber++)
        await disting.requestParameterInfo(algorithmIndex, parameterNumber) ??
            ParameterInfo.filler()
    ];
    var parameterPages = await disting.requestParameterPages(algorithmIndex) ??
        ParameterPages.filler();

    var visibleParameters = parameterPages.pages.expand(
      (element) {
        return element.parameters;
      },
    );

    var parameterValues =
        (await disting.requestAllParameterValues(algorithmIndex))!.values;
    var enums = <ParameterEnumStrings>[];
    for (int i = 0; i < numParametersInAlgorithm; i++) {
      ParameterEnumStrings? fetchedEnums;
      // Only fetch enums if visible on a page (optimization)
      final isVisible =
          parameterPages.pages.any((page) => page.parameters.contains(i));

      if (isVisible) {
        fetchedEnums =
            await disting.requestParameterEnumStrings(algorithmIndex, i);
      }
      // Add the result from the manager (could be I/O, custom, or filler)
      enums.add(fetchedEnums ?? ParameterEnumStrings.filler());
    }
    var mappings = [
      for (int parameterNumber = 0;
          parameterNumber < numParametersInAlgorithm;
          parameterNumber++)
        visibleParameters.contains(parameterNumber)
            ? await disting.requestMappings(algorithmIndex, parameterNumber) ??
                Mapping.filler()
            : Mapping.filler()
    ];
    var routing = await disting.requestRoutingInformation(algorithmIndex) ??
        RoutingInfo.filler();
    var valueStrings = [
      for (int parameterNumber = 0;
          parameterNumber < numParametersInAlgorithm;
          parameterNumber++)
        if ([13, 14, 17].contains(parameters[parameterNumber].unit) &&
            visibleParameters.contains(parameterNumber))
          await disting.requestParameterValueString(
                  algorithmIndex, parameterNumber) ??
              ParameterValueString.filler()
        else
          ParameterValueString.filler()
    ];
    return Slot(
      algorithm: (await disting.requestAlgorithmGuid(algorithmIndex))!,
      pages: parameterPages,
      parameters: parameters,
      values: parameterValues,
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
