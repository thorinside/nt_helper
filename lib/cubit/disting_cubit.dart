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
        super(DistingState.initial()) {
    _metadataDao = _database.metadataDao; // Initialize DAO
  }

  MidiCommand _midiCommand = MidiCommand();
  CancelableOperation<void>? _programSlotUpdate;

  @override
  Future<void> close() {
    disting()?.dispose();
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
      emit(DistingState.initial());

      // Fetch devices using the helper
      final devices = await _fetchDeviceLists();

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
    if (currentState is DistingStateConnected) {
      if (currentState.pendingOfflinePresetToSync != null) {
        return;
      }
    }

    if (!(currentState is DistingStateSynchronized || currentState is DistingStateConnected)) {
      return;
    }

    final disting = requireDisting();

    try {
      // --- Fetch ALL data from device REGARDLESS ---
      debugPrint("[Cubit] _performSyncAndEmit: Fetching full device state...");
      final numAlgorithms = (await disting.requestNumberOfAlgorithms()) ?? 0;
      final algorithms = numAlgorithms > 0
          ? await Future.wait([
              for (int i = 0; i < numAlgorithms; i++)
                disting.requestAlgorithmInfo(i)
            ]).then((results) => results.whereType<AlgorithmInfo>().toList())
          : <AlgorithmInfo>[];

      final numAlgorithmsInPreset =
          (await disting.requestNumAlgorithmsInPreset()) ?? 0;
      final distingVersion = await disting.requestVersionString() ?? "";
      final presetName = await disting.requestPresetName() ?? "Default";
      var unitStrings = await disting.requestUnitStrings() ?? [];
      List<Slot> slots = await fetchSlots(numAlgorithmsInPreset, disting);
      debugPrint("[Cubit] _performSyncAndEmit: Fetched ${slots.length} slots.");

      // --- Emit final synchronized state ---
      emit(DistingState.synchronized(
        disting: disting,
        distingVersion: distingVersion,
        presetName: presetName,
        algorithms: algorithms,
        slots: slots,
        unitStrings: unitStrings,
        loading: false, // Ensure loading is false
      ));
    } catch (e, stackTrace) {
      debugPrint("Error during synchronization: $e");
      debugPrintStack(stackTrace: stackTrace);
      await loadDevices();
    }
  }

  Future<void> connectToDevices(
      MidiDevice inputDevice, MidiDevice outputDevice, int sysExId) async {
    try {
      // Connect to the selected device
      await _midiCommand.connectToDevice(inputDevice);
      if (inputDevice != outputDevice) {
        await _midiCommand.connectToDevice(outputDevice);
      }

      // Save the device name and SysEx ID to persistent storage
      final prefs = await _prefs;
      await prefs.setString('selectedInputMidiDevice', inputDevice.name);
      await prefs.setString('selectedOutputMidiDevice', outputDevice.name);
      await prefs.setInt('selectedSysExId', sysExId);

      final disting = DistingMidiManager(
          midiCommand: _midiCommand,
          inputDevice: inputDevice,
          outputDevice: outputDevice,
          sysExId: sysExId);

      // --- Check for pending offline data FIRST ---
      final pendingData = await _checkForOfflinePreset();
      if (pendingData != null) {
        debugPrint("[Cubit] _performSyncAndEmit: Found pending offline data.");
      }

      // Emit Connected state to show the spinner
      emit(DistingState.connected(
          disting: disting, pendingOfflinePresetToSync: pendingData));

      // Perform the sync process
      await _performSyncAndEmit();
    } catch (e, stackTrace) {
      debugPrint("Error connecting or initial sync: ${e.toString()}");
      debugPrintStack(stackTrace: stackTrace);
      await loadDevices();
    }
  }

// ADDING BACK the cancelSync method
  Future<void> cancelSync() async {
    disconnect(); // Disconnect MIDI
    await loadDevices(); // Go back to device selection
  }

  /// Refreshes the entire state from the Disting device.
  Future<void> refresh() async {
    debugPrint("[Cubit] Refresh requested.");
    final currentState = state;
    if (currentState is DistingStateSynchronized) {
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
      return (state as DistingStateSynchronized).disting;
    }
    throw Exception("Device is not connected.");
  }

  IDistingMidiManager? disting() {
    if (state is DistingStateConnected) {
      return (state as DistingStateConnected).disting;
    }
    if (state is DistingStateSynchronized) {
      return (state as DistingStateSynchronized).disting;
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
        _saveOfflineState(); // Save after potential state change
    }
  }

  Future<void> onAlgorithmSelected(
    AlgorithmInfo algorithm,
    List<int> specifications,
  ) async {
    switch (state) {
      case DistingStateSynchronized syncstate:
        final disting = syncstate.disting; // Could be OfflineDistingMidiManager
        await disting.requestAddAlgorithm(algorithm, specifications);

        // Refresh state from manager - fetchSlot will be called via refresh
        refresh(); // <--- THIS is the problem in offline mode
        _saveOfflineState(); // Save after adding
        break;
    }
  }

  Future<void> onRemoveAlgorithm(int algorithmIndex) async {
    switch (state) {
      case DistingStateSynchronized syncstate:
        final disting = requireDisting();
        await disting.requestRemoveAlgorithm(algorithmIndex);

        // Get the current slots
        var slots = List<Slot>.from(syncstate.slots);

        // Remove the slot at the specified index
        if (algorithmIndex >= 0 && algorithmIndex < slots.length) {
          slots.removeAt(algorithmIndex);
        }

        // Fix indices for remaining slots
        var updatedSlots = slots
            .mapIndexed((index, element) => _fixAlgorithmIndex(
                    element, index) // Use index directly after removal
                )
            .toList();

        emit(syncstate.copyWith(slots: updatedSlots));
        _saveOfflineState(); // Save after removing
        break;
    }
  }

  void onFocusParameter({
    required int algorithmIndex,
    required int parameterNumber,
  }) {
    final disting = requireDisting();
    disting.requestSetFocus(algorithmIndex, parameterNumber);
  }

  void renamePreset(String newName) async {
    final currentState = state;
    if (currentState is DistingStateSynchronized) {
      // Prevent renaming when offline
      if (currentState.offline) {
        debugPrint("[Cubit] Ignoring renamePreset call while offline.");
        return;
      }

      final disting = currentState.disting;
      disting.requestSetPresetName(newName);

      await Future.delayed(Duration(milliseconds: 250));
      emit((state as DistingStateSynchronized)
          .copyWith(presetName: await disting.requestPresetName() ?? ""));
      _saveOfflineState(); // Save after renaming
    }
  }

  void save() async {
    final disting = requireDisting();
    disting.requestSavePreset();
  }

  Future<int> moveAlgorithmUp(int algorithmIndex) async {
    if (algorithmIndex == 0) return 0;

    final disting = requireDisting();
    await disting.requestMoveAlgorithmUp(algorithmIndex);

    // Manually update the slots list immediately
    var slots = List<Slot>.from((state as DistingStateSynchronized).slots);
    var slot = slots.removeAt(algorithmIndex);
    var otherSlot = slots.removeAt(algorithmIndex - 1);

    // Fix indices before inserting back
    otherSlot = _fixAlgorithmIndex(otherSlot, algorithmIndex);
    slot = _fixAlgorithmIndex(slot, algorithmIndex - 1);

    slots.insert(algorithmIndex - 1, slot);
    slots.insert(algorithmIndex, otherSlot);
    emit((state as DistingStateSynchronized).copyWith(slots: slots));

    _saveOfflineState(); // Save after moving

    return algorithmIndex - 1;
  }

  Future<int> moveAlgorithmDown(int algorithmIndex) async {
    // Check bounds based on current state before calling manager
    if (state is! DistingStateSynchronized) return algorithmIndex;
    final syncState = state as DistingStateSynchronized;
    if (algorithmIndex >= syncState.slots.length - 1) return algorithmIndex;

    final disting = requireDisting();
    await disting.requestMoveAlgorithmDown(algorithmIndex);

    // Manually update the slots list immediately
    var slots = List<Slot>.from((state as DistingStateSynchronized).slots);

    var slot = slots.removeAt(algorithmIndex);
    // The item originally after the moved item is now at algorithmIndex
    var otherSlot = slots.removeAt(algorithmIndex);

    // Fix indices before inserting back
    // The one originally after moves to the original index
    otherSlot = _fixAlgorithmIndex(otherSlot, algorithmIndex);
    // The moved item goes to the next index
    slot = _fixAlgorithmIndex(slot, algorithmIndex + 1);

    // Insert the other slot first (at the original index)
    slots.insert(algorithmIndex, otherSlot);
    // Then insert the moved slot after it
    slots.insert(algorithmIndex + 1, slot);

    emit((state as DistingStateSynchronized).copyWith(slots: slots));

    _saveOfflineState(); // Save after moving

    return algorithmIndex + 1;
  }

  void wakeDevice() async {
    final disting = requireDisting();
    disting.requestWake();
  }

  void closeScreenshot() {
    switch (state) {
      case DistingStateSynchronized syncstate:
        emit(syncstate.copyWith(screenshot: null));
        break;
      default:
      // Handle other cases or errors
    }
  }

  Future<void> newPreset() async {
    switch (state) {
      case DistingStateSynchronized syncstate:
        final disting = requireDisting();

        await disting.requestNewPreset();

        await _refreshPreset(disting, syncstate);

        break;
      default:
      // Handle other cases or errors
    }
  }

  Future<void> loadPreset(String name, bool append) async {
    switch (state) {
      case DistingStateSynchronized syncstate:
        final disting = requireDisting();

        emit(
          syncstate.copyWith(
            loading: true,
          ),
        );

        await disting.requestLoadPreset(name, append);

        await _refreshPreset(disting, syncstate);

        break;
      default:
      // Handle other cases or errors
    }
  }

  Future<void> _refreshPreset(
    IDistingMidiManager disting,
    DistingStateSynchronized state, {
    Duration delay = const Duration(milliseconds: 250),
  }) async {
    await Future.delayed(delay);

    final numAlgorithmsInPreset =
        (await disting.requestNumAlgorithmsInPreset())!;
    final presetName = await disting.requestPresetName() ?? "";

    List<Slot> slots = await fetchSlots(numAlgorithmsInPreset, disting);

    emit(
      state.copyWith(
        loading: false,
        presetName: presetName,
        slots: slots,
      ),
    );
  }

  Future<void> saveMapping(
      int algorithmIndex, int parameterNumber, PackedMappingData data) async {
    switch (state) {
      case DistingStateSynchronized syncstate:
        final disting = requireDisting();

        await disting.requestSetMapping(algorithmIndex, parameterNumber, data);

        emit(
          syncstate.copyWith(
            slots: updateSlot(
              algorithmIndex,
              syncstate.slots,
              (slot) {
                return slot.copyWith(
                  mappings: replaceInList(
                    slot.mappings,
                    Mapping(
                        algorithmIndex: algorithmIndex,
                        parameterNumber: parameterNumber,
                        packedMappingData: data),
                    index: parameterNumber,
                  ),
                );
              },
            ),
          ),
        );
        _saveOfflineState(); // Save after mapping change
        break;
      default:
      // Handle other cases or errors
    }
  }

  void renameSlot(int algorithmIndex, String newName) async {
    switch (state) {
      case DistingStateSynchronized syncstate:
        final disting = requireDisting();
        await disting.requestSendSlotName(algorithmIndex, newName);
        await Future.delayed(Duration(milliseconds: 100));
        final slot = await fetchSlot(requireDisting(), algorithmIndex);
        emit(syncstate.copyWith(
            slots: updateSlot(algorithmIndex, syncstate.slots, (_) => slot)));
        _saveOfflineState(); // Save after slot rename
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

  Future<void> workOffline() async {
    // Create the offline manager instance
    final offlineManager = OfflineDistingMidiManager(_database);
    // Define the name for the offline state preset
    const String offlinePresetName = "__OFFLINE_INTERNAL_STATE__";

    try {
      // --- Load previous offline state --- (New)
      final presetsDao = _database.presetsDao;
      debugPrint(
          "[Offline Cubit] Attempting to load state for preset: $offlinePresetName");
      PresetEntry? savedPresetEntry =
          await presetsDao.getPresetByName(offlinePresetName);
      debugPrint(
          "[Offline Cubit] Found preset entry: ${savedPresetEntry?.id} (${savedPresetEntry?.name})");
      FullPresetDetails? savedDetails;
      if (savedPresetEntry != null) {
        debugPrint(
            "[Offline Cubit] Loading full details for preset ID: ${savedPresetEntry.id}");
        savedDetails =
            await presetsDao.getFullPresetDetails(savedPresetEntry.id);
        debugPrint(
            "[Offline Cubit] Loaded details: Slots=${savedDetails?.slots.length ?? 'null'}");
      } else {
        debugPrint("[Offline Cubit] No saved preset entry found.");
      }
      // Initialize the manager with loaded state (or empty if none found)
      debugPrint("[Offline Cubit] Initializing manager with loaded details...");
      await offlineManager.initializeFromDb(savedDetails);

      // --- Fetch basic offline info --- (Uses manager's internal state now)
      final version = await offlineManager.requestVersionString() ?? "Offline";
      final presetName =
          await offlineManager.requestPresetName() ?? offlinePresetName;
      final allCachedAlgorithms = await _metadataDao.getAllAlgorithmsWithParameters();
      // Map cached entries to AlgorithmInfo for the state's algorithm list
      final availableAlgorithmsInfo = allCachedAlgorithms.map((entry) {
        return AlgorithmInfo(
          guid: entry.guid,
          name: entry.name,
          numSpecifications: entry.numSpecifications,
          algorithmIndex: -1,
          // No meaningful live index
          specifications: [], // Not fetching detailed specs here
        );
      }).toList();

      final units = await offlineManager.requestUnitStrings() ?? [];

      // --- Build initial slots from loaded/initialized manager state --- (New)
      final initialSlotCount =
          await offlineManager.requestNumAlgorithmsInPreset() ?? 0;
      final List<Slot> initialSlots = [];
      for (int i = 0; i < initialSlotCount; i++) {
        // Use the standard fetchSlot method, it will call the offlineManager
        initialSlots.add(await fetchSlot(offlineManager, i));
      }

      emit(DistingState.synchronized(
        disting: offlineManager,
        // Use the offline manager
        distingVersion: version,
        presetName: presetName,
        algorithms: availableAlgorithmsInfo,
        // Full list from cache
        slots: initialSlots,
        // Start with empty slots
        unitStrings: units,
        offline: true,
        // Mark as offline
        demo: false,
      ));
    } catch (e, stackTrace) {
      debugPrint("Error initializing offline mode: $e");
      debugPrintStack(stackTrace: stackTrace);
      // Optionally emit an error state or fall back to device selection
      loadDevices(); // Fallback to device selection on error
    }
  }

// Helper method to fetch and sort devices
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

// Gets the list of available algorithms, either from the device or cache.
  Future<List<AlgorithmInfo>> getAvailableAlgorithms() async {
    final currentState = state;
    if (currentState is DistingStateSynchronized) {
      if (currentState.offline) {
        // Offline: Fetch from database and map
        try {
          final cachedEntries = await _metadataDao.getAllAlgorithmsWithParameters();
          // Map AlgorithmEntry to AlgorithmInfo
          return cachedEntries.map((entry) {
            return AlgorithmInfo(
              guid: entry.guid,
              name: entry.name,
              numSpecifications: entry.numSpecifications,
              // Database doesn't store live index or specific spec values easily
              algorithmIndex: -1,
              // Indicate invalid index for offline context
              specifications: [], // Specs aren't stored directly this way
            );
          }).toList();
        } catch (e, stackTrace) {
          debugPrint("Error fetching cached algorithms: $e");
          debugPrintStack(stackTrace: stackTrace);
          return []; // Return empty on error
        }
      } else {
        // Online: Return algorithms from state (already sorted by device)
        return currentState.algorithms;
      }
    } else {
      // Not synchronized, return empty list
      return [];
    }
  }

// Helper to save the current offline state to the DB
  Future<void> _saveOfflineState() async {
    debugPrint("[Offline Cubit] Attempting to save offline state...");
    final currentState = state;
    if (currentState is DistingStateSynchronized && currentState.offline) {
      final manager = currentState.disting;
      if (manager is OfflineDistingMidiManager) {
        try {
          final presetDetails = await manager.getCurrentPresetDetails();
          debugPrint(
              "[Offline Cubit] State to save: Preset='${presetDetails.preset.name}', Slots=${presetDetails.slots.length}");
          final presetsDao = _database.presetsDao;
          await presetsDao.saveFullPreset(presetDetails);
          debugPrint(
              "[Offline] Saved offline state to DB for preset: ${presetDetails.preset.name}");
        } catch (e, stackTrace) {
          debugPrint("[Offline] Error saving offline state: $e");
          debugPrintStack(stackTrace: stackTrace);
        }
      }
    }
  }

// Helper to check for the saved offline state
  Future<FullPresetDetails?> _checkForOfflinePreset() async {
    const String offlinePresetName = "__OFFLINE_INTERNAL_STATE__";
    try {
      final presetsDao = _database.presetsDao;
      final savedPresetEntry =
          await presetsDao.getPresetByName(offlinePresetName);
      if (savedPresetEntry != null) {
        debugPrint(
            "[Cubit] Found saved offline state preset: ${savedPresetEntry.id}");
        return await presetsDao.getFullPresetDetails(savedPresetEntry.id);
      }
    } catch (e, stackTrace) {
      debugPrint("[Cubit] Error checking for offline preset: $e");
      debugPrintStack(stackTrace: stackTrace);
    }
    return null;
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

  Future<void> applyOfflinePresetToDevice() async {
    debugPrint("[Cubit] applyOfflinePresetToDevice called");
    final currentState = state;
    if (currentState is! DistingStateConnected ||
        currentState.offline ||
        currentState.pendingOfflinePresetToSync == null) {
      debugPrint("[Cubit] Cannot apply offline preset: Invalid state.");
      return;
    }

    final liveManager = currentState.disting;
    final FullPresetDetails offlinePreset =
        currentState.pendingOfflinePresetToSync!;
    const String offlinePresetDbKey = "__OFFLINE_INTERNAL_STATE__";

    try {
      emit(currentState.copyWith(loading: true)); // Show loading indicator

      // 1. Start with a new preset on the device
      debugPrint("[ApplyOffline] Sending NewPreset request...");
      await liveManager.requestNewPreset();
      await Future.delayed(
          const Duration(milliseconds: 500)); // Wait for device

      // 2. Add algorithms in order
      debugPrint(
          "[ApplyOffline] Adding ${offlinePreset.slots.length} algorithms...");
      for (final offlineSlot in offlinePreset.slots) {
        // Find the corresponding AlgorithmInfo from the live device's list
        AlgorithmInfo algoInfo = AlgorithmInfo.filler().copyWith(
            name: offlineSlot.algorithm.name,
            numSpecifications: offlineSlot.algorithm.numSpecifications,
            guid: offlineSlot.algorithm.guid);

        debugPrint(
            "[ApplyOffline] Adding algorithm: ${algoInfo.name} (GUID: ${algoInfo.guid})");
        await liveManager.requestAddAlgorithm(
            algoInfo, []); // TODO: Use default specifications
        await Future.delayed(
            const Duration(milliseconds: 250)); // Wait between adds
      }

      // Wait briefly after adding all algorithms
      await Future.delayed(const Duration(milliseconds: 500));

      // 3. Set parameter values
      debugPrint("[ApplyOffline] Setting parameter values...");
      for (int slotIndex = 0;
          slotIndex < offlinePreset.slots.length;
          slotIndex++) {
        final offlineSlot = offlinePreset.slots[slotIndex];
        for (final paramEntry in offlineSlot.parameterValues.entries) {
          final paramNum = paramEntry.key;
          final paramValue = paramEntry.value;
          await liveManager.setParameterValue(slotIndex, paramNum, paramValue);
          // Maybe add a tiny delay here if needed, but often bulk setting is okay
          // await Future.delayed(const Duration(milliseconds: 5));
        }
        debugPrint("[ApplyOffline] ... values set for slot $slotIndex");
      }

      // --- Optional: Set Mappings, Routing, Names ---
      debugPrint("[ApplyOffline] Setting mappings...");
      for (int slotIndex = 0;
          slotIndex < offlinePreset.slots.length;
          slotIndex++) {
        final offlineSlot = offlinePreset.slots[slotIndex];
        for (final mappingEntry in offlineSlot.mappings.entries) {
          await liveManager.requestSetMapping(
              slotIndex, mappingEntry.key, mappingEntry.value);
        }
        if (offlineSlot.slot.customName != null) {
          await liveManager.requestSendSlotName(
              slotIndex, offlineSlot.slot.customName!);
        }
        // TODO: Apply routing if requestSetRouting implemented
      }

      // 4. Clean up: Delete the offline preset from DB
      try {
        final presetsDao = _database.presetsDao;
        final entryToDelete =
            await presetsDao.getPresetByName(offlinePresetDbKey);
        if (entryToDelete != null) {
          await presetsDao.deletePreset(entryToDelete.id);
          debugPrint(
              "[ApplyOffline] Deleted internal offline state preset from DB.");
        }
      } catch (e) {
        debugPrint(
            "[ApplyOffline] Failed to delete internal offline state preset: $e");
      }

      // 5. Refresh the UI state from the device
      debugPrint("[ApplyOffline] Refreshing state from device...");
      await Future.delayed(
          const Duration(milliseconds: 250)); // Give device a moment
      await refresh(); // MODIFIED: Call refresh() instead of synchronizeDevice()
    } catch (e, stackTrace) {
      debugPrint("[ApplyOffline] Error applying offline preset: $e");
      debugPrintStack(stackTrace: stackTrace);
      // Emit state without loading and clear pending flag in case of error during apply
      final currentState = state;
      if (currentState is DistingStateSynchronized) {
        emit(currentState.copyWith(loading: false));
      } else {
        await loadDevices(); // Fallback to device selection
      }
    }
  }

  Future<void> discardOfflinePreset() async {
    debugPrint("[Cubit] discardOfflinePreset called");
    const String offlinePresetName = "__OFFLINE_INTERNAL_STATE__";
    final currentState = state; // Need current state to modify it

    try {
      final presetsDao = _database.presetsDao;
      final savedPresetEntry =
          await presetsDao.getPresetByName(offlinePresetName);
      if (savedPresetEntry != null) {
        await presetsDao.deletePreset(savedPresetEntry.id);
        debugPrint(
            "[Cubit] Deleted offline preset from DB: ID ${savedPresetEntry.id}");
      } else {
        debugPrint("[Cubit] No offline preset found in DB to delete.");
      }

      // After discarding, just re-emit the CURRENT state but clear the flag
      if (currentState is DistingStateConnected) {
        debugPrint(
            "[Cubit] Discard successful, re-emitting synchronized state with pending flag cleared.");
        emit(currentState.copyWith(pendingOfflinePresetToSync: null));
      } else {
        // Should not happen if dialog was shown
        debugPrint(
            "[Cubit] Discard called but state was not Synchronized. Ignoring.");
      }
    } catch (e, stackTrace) {
      debugPrint("[Cubit] Error deleting offline preset: $e");
      debugPrintStack(stackTrace: stackTrace);
      // If delete failed, still try to clear the flag from the UI state
      if (currentState is DistingStateConnected) {
        debugPrint(
            "[Cubit] Discard DB delete failed, but still clearing pending flag from UI state.");
        emit(currentState.copyWith(pendingOfflinePresetToSync: null));
      } else {
        await loadDevices();
      }
    }
  }
}
