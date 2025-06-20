import 'dart:async';
// import 'dart:math'; // Remove unused

import 'package:nt_helper/db/daos/presets_dao.dart'; // Re-add PresetsDao import
// import 'package:nt_helper/db/database.dart'; // Remove unused

import 'package:nt_helper/domain/i_disting_midi_manager.dart'
    show IDistingMidiManager;
import 'package:nt_helper/models/packed_mapping_data.dart';
// import 'package:nt_helper/models/routing_information.dart';
// import 'package:collection/collection.dart';
import 'package:nt_helper/cubit/disting_cubit.dart'; // Added import for Slot, etc.
import 'package:flutter/foundation.dart'; // Remove unused
import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'package:nt_helper/models/cpu_usage.dart';
import 'package:nt_helper/models/sd_card_file_system.dart';

/// Mock implementation for demo mode or testing.
class MockDistingMidiManager implements IDistingMidiManager {
  // --- Consolidated Mock State ---
  late _MockState _state; // Use a single state object

  // --- Internal State for Demo (within _MockState now) ---
  // List<AlgorithmInfo> _availableAlgorithms = [];
  // List<Slot> _presetSlots = [];
  // List<String> _unitStrings = [];
  // String _presetName = "Demo Preset";
  // String _versionString = "Demo v1.0";
  // Store IO enum values for reuse
  static final List<String> _ioEnumValues = [
    ...List.generate(12, (i) => "Input ${i + 1}"),
    ...List.generate(8, (i) => "Output ${i + 1}"),
    ...List.generate(8, (i) => "Aux ${i + 1}"),
  ];
  static const int _ioEnumMax = 27; // 12 + 8 + 8 - 1

  MockDistingMidiManager() {
    _state = _MockState(); // Initialize the state object
    _initializeMockData(); // Populate the detailed demo data within _state
  }

  void _initializeMockData() {
    // --- Define Demo Algorithms ---
    final availableAlgorithms = <AlgorithmInfo>[
      AlgorithmInfo(
          algorithmIndex: 0, guid: "clk ", name: "Clock", specifications: []),
      AlgorithmInfo(
          algorithmIndex: 1,
          guid: "seq ",
          name: "Step Sequencer",
          specifications: []),
      AlgorithmInfo(
          algorithmIndex: 2,
          guid: "sine",
          name: "Sine Oscillator",
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
          powerOfTen: 0), // %
      ParameterInfo(
          algorithmIndex: 0,
          parameterNumber: 3,
          name: "Clock In",
          min: 0,
          max: _ioEnumMax,
          defaultValue: 0,
          unit: 1,
          powerOfTen: 0), // Input 1
      ParameterInfo(
          algorithmIndex: 0,
          parameterNumber: 4,
          name: "Reset In",
          min: 0,
          max: _ioEnumMax,
          defaultValue: 1,
          unit: 1,
          powerOfTen: 0), // Input 2
      ParameterInfo(
          algorithmIndex: 0,
          parameterNumber: 5,
          name: "Clock Out",
          min: 0,
          max: _ioEnumMax,
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
          values: _ioEnumValues), // Clock In
      ParameterEnumStrings(
          algorithmIndex: 0,
          parameterNumber: 4,
          values: _ioEnumValues), // Reset In
      ParameterEnumStrings(
          algorithmIndex: 0,
          parameterNumber: 5,
          values: _ioEnumValues), // Clock Out
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
          max: _ioEnumMax,
          defaultValue: 12,
          unit: 1,
          powerOfTen: 0), // Output 1
      ParameterInfo(
          algorithmIndex: 1,
          parameterNumber: 5,
          name: "Gate Out",
          min: 0,
          max: _ioEnumMax,
          defaultValue: 13,
          unit: 1,
          powerOfTen: 0), // Output 2
      ParameterInfo(
          algorithmIndex: 1,
          parameterNumber: 6,
          name: "Clock In",
          min: 0,
          max: _ioEnumMax,
          defaultValue: 0,
          unit: 1,
          powerOfTen: 0), // Input 1
      ParameterInfo(
          algorithmIndex: 1,
          parameterNumber: 7,
          name: "Reset In",
          min: 0,
          max: _ioEnumMax,
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
          values: _ioEnumValues), // CV Out
      ParameterEnumStrings(
          algorithmIndex: 1,
          parameterNumber: 5,
          values: _ioEnumValues), // Gate Out
      ParameterEnumStrings(
          algorithmIndex: 1,
          parameterNumber: 6,
          values: _ioEnumValues), // Clock In
      ParameterEnumStrings(
          algorithmIndex: 1,
          parameterNumber: 7,
          values: _ioEnumValues), // Reset In
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
          max: _ioEnumMax,
          defaultValue: 0,
          unit: 1,
          powerOfTen: 0), // Input 1
      ParameterInfo(
          algorithmIndex: 2,
          parameterNumber: 5,
          name: "Gate In",
          min: 0,
          max: _ioEnumMax,
          defaultValue: 1,
          unit: 1,
          powerOfTen: 0), // Input 2
      ParameterInfo(
          algorithmIndex: 2,
          parameterNumber: 6,
          name: "Audio Out L",
          min: 0,
          max: _ioEnumMax,
          defaultValue: 12,
          unit: 1,
          powerOfTen: 0), // Output 1
      ParameterInfo(
          algorithmIndex: 2,
          parameterNumber: 7,
          name: "Audio Out R",
          min: 0,
          max: _ioEnumMax,
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
            algorithmIndex: 2, parameterNumber: i, values: _ioEnumValues);
      }
      if (i == 8) {
        return ParameterEnumStrings(
            algorithmIndex: 2, parameterNumber: 8, values: ["Off", "On"]);
      } // Bypass
      return ParameterEnumStrings.filler();
    });
    final ParameterPages sinePages = ParameterPages(algorithmIndex: 2, pages: [
      ParameterPage(name: "Pitch", parameters: [0, 3]),
      ParameterPage(name: "Shape", parameters: [1, 2]),
      ParameterPage(name: "Routing", parameters: [4, 5, 6, 7]),
      ParameterPage(name: "Algorithm", parameters: [8]),
    ]);
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

    // --- Assign to State Object ---
    _state.availableAlgorithms = availableAlgorithms;
    _state.presetSlots = [clockSlot, sequencerSlot, sineSlot];
    _state.unitStrings = ["", "%", "Hz", "dB", "°", "V/Oct"]; // Example units
    _state.presetName = "Demo Preset";
    _state.versionString = "Demo v1.0";

    // Debug print lengths
    debugPrint(
        "[Mock Init] Clock Slot: params=${clockSlot.parameters.length}, vals=${clockSlot.values.length}, enums=${clockSlot.enums.length}, maps=${clockSlot.mappings.length}, strs=${clockSlot.valueStrings.length}");
    debugPrint(
        "[Mock Init] Seq Slot: params=${sequencerSlot.parameters.length}, vals=${sequencerSlot.values.length}, enums=${sequencerSlot.enums.length}, maps=${sequencerSlot.mappings.length}, strs=${sequencerSlot.valueStrings.length}");
    debugPrint(
        "[Mock Init] Sine Slot: params=${sineSlot.parameters.length}, vals=${sineSlot.values.length}, enums=${sineSlot.enums.length}, maps=${sineSlot.mappings.length}, strs=${sineSlot.valueStrings.length}");
    debugPrint(
        "[Mock Init] State assigned: slots=${_state.presetSlots.length}");
  }

  @override
  void dispose() {
    // No-op
  }

  @override
  Future<Uint8List?> encodeTakeScreenshot() async {
    // Return null or placeholder image data
    return null;
  }

  @override
  Future<Algorithm?> requestAlgorithmGuid(int algorithmIndex) async {
    if (algorithmIndex >= 0 && algorithmIndex < _state.presetSlots.length) {
      // Ensure the returned algorithm's index matches the requested index,
      // as the internal state should have been updated by move operations.
      // Return the Algorithm part of the Slot
      return _state.presetSlots[algorithmIndex].algorithm;
    }
    debugPrint("[Mock] requestAlgorithmGuid: Invalid index $algorithmIndex");
    return null;
  }

  @override
  Future<AlgorithmInfo?> requestAlgorithmInfo(int index) async {
    if (index >= 0 && index < _state.availableAlgorithms.length) {
      return _state.availableAlgorithms[index];
    }
    debugPrint("[Mock] requestAlgorithmInfo: Invalid index $index");
    return null;
  }

  @override
  Future<AllParameterValues?> requestAllParameterValues(
      int algorithmIndex) async {
    // Return the AllParameterValues object containing the list of values
    if (algorithmIndex >= 0 && algorithmIndex < _state.presetSlots.length) {
      return AllParameterValues(
          algorithmIndex: algorithmIndex,
          values: _state.presetSlots[algorithmIndex].values);
    }
    debugPrint(
        "[Mock] requestAllParameterValues: Invalid index $algorithmIndex");
    return null;
  }

  @override
  Future<ParameterEnumStrings?> requestParameterEnumStrings(
      int algorithmIndex, int parameterNumber) async {
    // Return actual enums from the stored Slot data
    if (algorithmIndex >= 0 && algorithmIndex < _state.presetSlots.length) {
      if (parameterNumber >= 0 &&
          parameterNumber < _state.presetSlots[algorithmIndex].enums.length) {
        return _state.presetSlots[algorithmIndex].enums[parameterNumber];
      }
    }
    debugPrint(
        "[Mock] requestParameterEnumStrings: Invalid index $algorithmIndex / $parameterNumber");
    return ParameterEnumStrings.filler();
  }

  @override
  Future<Mapping?> requestMappings(
      int algorithmIndex, int parameterNumber) async {
    // Return actual mapping from the stored Slot data
    Mapping? result = Mapping.filler(); // Default to filler
    if (algorithmIndex >= 0 && algorithmIndex < _state.presetSlots.length) {
      if (parameterNumber >= 0 &&
          parameterNumber <
              _state.presetSlots[algorithmIndex].mappings.length) {
        result = _state.presetSlots[algorithmIndex].mappings[parameterNumber];
      }
    }
    debugPrint(
        "[Mock] requestMappings: Algo $algorithmIndex, Param $parameterNumber -> Returning ${result.packedMappingData.isMapped() ? 'Mapped' : 'Filler'}");
    return result;
  }

  @override
  Future<NumParameters?> requestNumberOfParameters(int algorithmIndex) async {
    // Return the actual number of parameters for the slot at this index
    if (algorithmIndex >= 0 && algorithmIndex < _state.presetSlots.length) {
      return NumParameters(
          algorithmIndex: algorithmIndex,
          numParameters: _state.presetSlots[algorithmIndex].parameters.length);
    }
    debugPrint(
        "[Mock] requestNumberOfParameters: Invalid index $algorithmIndex");
    return null;
  }

  @override
  Future<int?> requestNumAlgorithmsInPreset() async {
    return _state.presetSlots.length;
  }

  @override
  Future<int?> requestNumberOfAlgorithms() async {
    return _state.availableAlgorithms.length;
  }

  @override
  Future<ParameterInfo?> requestParameterInfo(
      int algorithmIndex, int parameterNumber) async {
    if (algorithmIndex >= 0 && algorithmIndex < _state.presetSlots.length) {
      if (parameterNumber >= 0 &&
          parameterNumber <
              _state.presetSlots[algorithmIndex].parameters.length) {
        return _state.presetSlots[algorithmIndex].parameters[parameterNumber];
      }
    }
    debugPrint(
        "[Mock] requestParameterInfo: Invalid index $algorithmIndex / $parameterNumber");
    return null;
  }

  @override
  Future<ParameterPages?> requestParameterPages(int algorithmIndex) async {
    if (algorithmIndex >= 0 && algorithmIndex < _state.presetSlots.length) {
      return _state.presetSlots[algorithmIndex].pages;
    }
    debugPrint("[Mock] requestParameterPages: Invalid index $algorithmIndex");
    return null;
  }

  @override
  Future<ParameterValue?> requestParameterValue(
      int algorithmIndex, int parameterNumber) async {
    // Return based on the current algo at that index
    if (algorithmIndex >= 0 && algorithmIndex < _state.presetSlots.length) {
      // Return value from the actual slot data
      if (parameterNumber >= 0 &&
          parameterNumber < _state.presetSlots[algorithmIndex].values.length) {
        return _state.presetSlots[algorithmIndex].values[parameterNumber];
      }
    }
    debugPrint(
        "[Mock] requestParameterValue: Invalid index $algorithmIndex / $parameterNumber");
    return null;
  }

  @override
  Future<ParameterValueString?> requestParameterValueString(
      int algorithmIndex, int parameterNumber) async {
    if (algorithmIndex >= 0 && algorithmIndex < _state.presetSlots.length) {
      if (parameterNumber >= 0 &&
          parameterNumber <
              _state.presetSlots[algorithmIndex].valueStrings.length) {
        final valueString =
            _state.presetSlots[algorithmIndex].valueStrings[parameterNumber];
        // Return stored value string if not empty, otherwise filler
        return valueString.value.isNotEmpty
            ? valueString
            : ParameterValueString.filler();
      }
    }
    debugPrint(
        "[Mock] requestParameterValueString: Invalid index $algorithmIndex / $parameterNumber");
    return ParameterValueString.filler();
  }

  @override
  Future<String?> requestPresetName() async {
    return _state.presetName;
  }

  @override
  Future<RoutingInfo?> requestRoutingInformation(int algorithmIndex) async {
    return RoutingInfo.filler();
  }

  @override
  Future<List<String>?> requestUnitStrings() async {
    return _state.unitStrings;
  }

  @override
  Future<String?> requestVersionString() async {
    return _state.versionString;
  }

  @override
  Future<void> requestAddAlgorithm(
      AlgorithmInfo algorithm, List<int> specifications) async {
    // No-op
  }

  @override
  Future<void> requestLoadPreset(String name, bool append) async {
    // No-op for mock
    debugPrint("[Mock] requestLoadPreset: name=$name, append=$append");
    return;
  }

  @override
  Future<void> requestMoveAlgorithmDown(int algorithmIndex) async {
    debugPrint("[Mock] requestMoveAlgorithmDown: index $algorithmIndex");
    if (algorithmIndex >= 0 && algorithmIndex < _state.presetSlots.length - 1) {
      // Swap full Slot objects in the list
      final temp = _state.presetSlots[algorithmIndex];
      _state.presetSlots[algorithmIndex] =
          _state.presetSlots[algorithmIndex + 1];
      _state.presetSlots[algorithmIndex + 1] = temp;

      // Update the internal algorithmIndex property of the Algorithm object within the swapped Slots
      _state.presetSlots[algorithmIndex] = _state.presetSlots[algorithmIndex]
          .copyWith(
              algorithm: _state.presetSlots[algorithmIndex].algorithm
                  .copyWith(algorithmIndex: algorithmIndex));
      _state.presetSlots[algorithmIndex + 1] =
          _state.presetSlots[algorithmIndex + 1].copyWith(
              algorithm: _state.presetSlots[algorithmIndex + 1].algorithm
                  .copyWith(algorithmIndex: algorithmIndex + 1));
      debugPrint(
          "[Mock] State after move down: ${_state.presetSlots.map((s) => '${s.algorithm.name}(${s.algorithm.algorithmIndex})').toList()}");
    } else {
      debugPrint("[Mock] Invalid index for move down.");
    }
  }

  @override
  Future<void> requestMoveAlgorithmUp(int algorithmIndex) async {
    debugPrint("[Mock] requestMoveAlgorithmUp: index $algorithmIndex");
    if (algorithmIndex > 0 && algorithmIndex < _state.presetSlots.length) {
      // Swap full Slot objects in the list
      final temp = _state.presetSlots[algorithmIndex];
      _state.presetSlots[algorithmIndex] =
          _state.presetSlots[algorithmIndex - 1];
      _state.presetSlots[algorithmIndex - 1] = temp;

      // Update the internal algorithmIndex property of the Algorithm object within the swapped Slots
      _state.presetSlots[algorithmIndex] = _state.presetSlots[algorithmIndex]
          .copyWith(
              algorithm: _state.presetSlots[algorithmIndex].algorithm
                  .copyWith(algorithmIndex: algorithmIndex));
      _state.presetSlots[algorithmIndex - 1] =
          _state.presetSlots[algorithmIndex - 1].copyWith(
              algorithm: _state.presetSlots[algorithmIndex - 1].algorithm
                  .copyWith(algorithmIndex: algorithmIndex - 1));
      debugPrint(
          "[Mock] State after move up: ${_state.presetSlots.map((s) => '${s.algorithm.name}(${s.algorithm.algorithmIndex})').toList()}");
    } else {
      debugPrint("[Mock] Invalid index for move up.");
    }
  }

  @override
  Future<void> requestNewPreset() async {
    // No-op
  }

  @override
  Future<void> requestRemoveAlgorithm(int algorithmIndex) async {
    // No-op
  }

  @override
  Future<void> requestSavePreset({int? option}) async {
    // No-op for mock
    debugPrint("[Mock] requestSavePreset: option=$option");
    return;
  }

  @override
  Future<void> requestSendSlotName(int algorithmIndex, String newName) async {
    // No-op
  }

  Future<void> requestSetCVMapping(
      int algorithmIndex, int parameterNumber, PackedMappingData data) async {
    // No-op
  }

  @override
  Future<void> requestSetDisplayMode(DisplayMode displayMode) async {
    // No-op
  }

  @override
  Future<void> requestSetFocus(int algorithmIndex, int parameterNumber) async {
    // No-op
  }

  @override
  Future<void> requestSetMapping(
      int algorithmIndex, int parameterNumber, PackedMappingData data) async {
    // No-op
  }

  @override
  Future<void> requestSetPresetName(String newName) async {
    _state.presetName = newName;
    debugPrint("[Mock] requestSetPresetName: newName=$newName");
  }

  @override
  Future<void> requestWake() async {
    // No-op in mock mode
  }

  @override
  Future<void> setParameterValue(
      int algorithmIndex, int parameterNumber, int value) async {
    // Update the value in the internal state if valid
    if (algorithmIndex >= 0 && algorithmIndex < _state.presetSlots.length) {
      if (parameterNumber >= 0 &&
          parameterNumber < _state.presetSlots[algorithmIndex].values.length) {
        final currentSlot = _state.presetSlots[algorithmIndex];
        final valueIndex = currentSlot.values
            .indexWhere((pv) => pv.parameterNumber == parameterNumber);

        if (valueIndex != -1) {
          final currentParamValue = currentSlot.values[valueIndex];
          final updatedValues = List<ParameterValue>.from(currentSlot.values);
          updatedValues[valueIndex] = ParameterValue(
              algorithmIndex: currentParamValue.algorithmIndex,
              parameterNumber: currentParamValue.parameterNumber,
              value: value // Use the new value
              );

          final updatedSlot = currentSlot.copyWith(
              values: updatedValues); // Assuming Slot has copyWith
          _state.presetSlots[algorithmIndex] = updatedSlot;
          debugPrint(
              "[Mock] setParameterValue: Algo $algorithmIndex, Param $parameterNumber = $value");
        } else {
          debugPrint(
              "[Mock] setParameterValue: Error finding value index for Param $parameterNumber");
        }
      } else {
        debugPrint(
            "[Mock] setParameterValue: Invalid parameterNumber $parameterNumber");
      }
    } else {
      debugPrint(
          "[Mock] setParameterValue: Invalid algorithmIndex $algorithmIndex");
    }
  }

  @override
  Future<void> setParameterString(
      int algorithmIndex, int parameterNumber, String value) async {
    // Update the string value in the internal state if valid
    if (algorithmIndex >= 0 && algorithmIndex < _state.presetSlots.length) {
      if (parameterNumber >= 0 &&
          parameterNumber <
              _state.presetSlots[algorithmIndex].valueStrings.length) {
        final currentSlot = _state.presetSlots[algorithmIndex];
        final valueIndex = currentSlot.valueStrings
            .indexWhere((pv) => pv.parameterNumber == parameterNumber);

        if (valueIndex != -1) {
          final currentParamValueString = currentSlot.valueStrings[valueIndex];
          final updatedValueStrings =
              List<ParameterValueString>.from(currentSlot.valueStrings);
          updatedValueStrings[valueIndex] = ParameterValueString(
              algorithmIndex: currentParamValueString.algorithmIndex,
              parameterNumber: currentParamValueString.parameterNumber,
              value: value // Use the new string value
              );

          final updatedSlot = currentSlot.copyWith(
              valueStrings: updatedValueStrings); // Assuming Slot has copyWith
          _state.presetSlots[algorithmIndex] = updatedSlot;
          debugPrint(
              "[Mock] setParameterString: Algo $algorithmIndex, Param $parameterNumber = '$value'");
        } else {
          debugPrint(
              "[Mock] setParameterString: Error finding value string index for Param $parameterNumber");
        }
      } else {
        debugPrint(
            "[Mock] setParameterString: Invalid parameterNumber $parameterNumber");
      }
    } else {
      debugPrint(
          "[Mock] setParameterString: Invalid algorithmIndex $algorithmIndex");
    }
  }

  @override
  Future<String?> executeLua(String luaScript) async {
    debugPrint("[Mock] executeLua: script='$luaScript'");
    // Return a mock response
    return "Mock Lua execution result for: ${luaScript.substring(0, luaScript.length > 20 ? 20 : luaScript.length)}...";
  }

  @override
  Future<String?> installLua(int algorithmIndex, String luaScript) async {
    debugPrint("[Mock] installLua: algo=$algorithmIndex, script='$luaScript'");
    // Return a mock response
    return "Mock Lua installed in slot $algorithmIndex";
  }

  @override
  Future<FullPresetDetails?> requestCurrentPresetDetails() =>
      throw UnsupportedError('Not supported in mock');

  @override
  Future<DirectoryListing?> requestDirectoryListing(String path) =>
      throw UnsupportedError('Not supported in mock');

  @override
  Future<SdCardStatus?> requestFileDelete(String path) =>
      throw UnsupportedError('Not supported in mock');

  @override
  Future<Uint8List?> requestFileDownload(String path) =>
      throw UnsupportedError('Not supported in mock');

  @override
  Future<SdCardStatus?> requestFileRename(String fromPath, String toPath) =>
      throw UnsupportedError('Not supported in mock');

  @override
  Future<SdCardStatus?> requestFileUpload(String path, Uint8List data) =>
      throw UnsupportedError('Not supported in mock');

  @override
  Future<SdCardStatus?> requestFileUploadChunk(
          String path, Uint8List data, int position,
          {bool createAlways = false}) =>
      throw UnsupportedError('Not supported in mock');

  @override
  Future<CpuUsage?> requestCpuUsage() async {
    throw UnsupportedError("CPU Usage is not available in mock mode.");
  }

  @override
  Future<void> backupPlugins(String backupDirectory,
      {void Function(double progress, String currentFile)? onProgress}) async {
    // Mock backup - simulate progress
    final mockFiles = [
      '/programs/lua/example.lua',
      '/programs/three_pot/test.3pot',
      '/programs/plug-ins/plugin.o',
    ];

    for (int i = 0; i < mockFiles.length; i++) {
      await Future.delayed(const Duration(milliseconds: 500));
      onProgress?.call(
          (i + 1) / mockFiles.length, 'Downloaded ${mockFiles[i]}');
    }
  }
}

// --- Private State Class ---
class _MockState {
  List<AlgorithmInfo> availableAlgorithms = [];
  List<Slot> presetSlots = [];
  List<String> unitStrings = [];
  String presetName = "Demo Preset";
  String versionString = "Demo v1.0";
}
