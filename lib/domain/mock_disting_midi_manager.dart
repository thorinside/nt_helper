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
    // --- Berlin School Pluck Voice Algorithms ---
    final availableAlgorithms = <AlgorithmInfo>[
      AlgorithmInfo(
        algorithmIndex: 0,
        guid: "clkd",
        name: "Clock divider",
        specifications: [],
      ),
      AlgorithmInfo(
        algorithmIndex: 1,
        guid: "spsq",
        name: "Step Sequencer",
        specifications: [],
      ),
      AlgorithmInfo(
        algorithmIndex: 2,
        guid: "vcow",
        name: "VCO (Wavetable)",
        specifications: [],
      ),
      AlgorithmInfo(
        algorithmIndex: 3,
        guid: "env2",
        name: "Envelope (AR/AD)",
        specifications: [],
      ),
      AlgorithmInfo(
        algorithmIndex: 4,
        guid: "dels",
        name: "Delay (Stereo)",
        specifications: [],
      ),
    ];

    // --- Define Demo Slot 0: Clock Divider ---
    final List<ParameterInfo> clockDividerParams = <ParameterInfo>[
      ParameterInfo(
        algorithmIndex: 0,
        parameterNumber: 0,
        name: "Channels",
        min: 1,
        max: 8,
        defaultValue: 4,
        unit: 0,
        powerOfTen: 0,
      ),
      ParameterInfo(
        algorithmIndex: 0,
        parameterNumber: 1,
        name: "Clock input",
        min: 1,
        max: _ioEnumMax,
        defaultValue: 1,
        unit: 1,
        powerOfTen: 0,
      ),
      ParameterInfo(
        algorithmIndex: 0,
        parameterNumber: 2,
        name: "Reset input",
        min: 0,
        max: _ioEnumMax,
        defaultValue: 0,
        unit: 1,
        powerOfTen: 0,
      ),
      ParameterInfo(
        algorithmIndex: 0,
        parameterNumber: 3,
        name: "Clock 1 output",
        min: 1,
        max: _ioEnumMax,
        defaultValue: 13,
        unit: 1,
        powerOfTen: 0,
      ),
      ParameterInfo(
        algorithmIndex: 0,
        parameterNumber: 4,
        name: "Clock 2 output",
        min: 1,
        max: _ioEnumMax,
        defaultValue: 14,
        unit: 1,
        powerOfTen: 0,
      ),
    ];
    final List<ParameterValue> clockDividerValues = <ParameterValue>[
      ParameterValue(algorithmIndex: 0, parameterNumber: 0, value: 4), // 4 channels
      ParameterValue(algorithmIndex: 0, parameterNumber: 1, value: 1), // Clock input from Input 1
      ParameterValue(algorithmIndex: 0, parameterNumber: 2, value: 0), // No reset input
      ParameterValue(algorithmIndex: 0, parameterNumber: 3, value: 13), // Clock 1 to Output 1
      ParameterValue(algorithmIndex: 0, parameterNumber: 4, value: 14), // Clock 2 to Output 2
    ];
    // Clock Divider enums are now generated inline in the Slot creation
    final List<Mapping> clockDividerMappings = List<Mapping>.generate(
      clockDividerParams.length,
      (_) => Mapping.filler(),
    );
    final List<ParameterValueString> clockDividerValueStrings =
        List<ParameterValueString>.generate(
          clockDividerParams.length,
          (_) => ParameterValueString.filler(),
        );
    final ParameterPages clockDividerPages = ParameterPages(
      algorithmIndex: 0,
      pages: [
        ParameterPage(name: "Setup", parameters: [0, 1]), // Channels, Clock input
        ParameterPage(name: "Common", parameters: [2]), // Reset input
        ParameterPage(name: "Outputs", parameters: [3, 4]), // Clock outputs
      ],
    );
    final List<ParameterEnumStrings> clockDividerEnums = [
      ParameterEnumStrings.filler(), // Channels (not enum)
      ParameterEnumStrings(algorithmIndex: 0, parameterNumber: 1, values: _ioEnumValues), // Clock input
      ParameterEnumStrings(algorithmIndex: 0, parameterNumber: 2, values: ["None", ..._ioEnumValues]), // Reset input (can be None)
      ParameterEnumStrings(algorithmIndex: 0, parameterNumber: 3, values: _ioEnumValues), // Clock 1 output
      ParameterEnumStrings(algorithmIndex: 0, parameterNumber: 4, values: _ioEnumValues), // Clock 2 output
    ];

    final Slot clockSlot = Slot(
      algorithm: Algorithm(algorithmIndex: 0, guid: "clkd", name: "Clock divider"),
      routing: RoutingInfo.filler(),
      pages: clockDividerPages,
      parameters: clockDividerParams,
      values: clockDividerValues,
      enums: clockDividerEnums,
      mappings: clockDividerMappings,
      valueStrings: clockDividerValueStrings,
    );

    // --- Define Demo Slot 1: Step Sequencer (Berlin School Pattern) ---
    final List<ParameterInfo> seqParams = <ParameterInfo>[
      ParameterInfo(
        algorithmIndex: 1,
        parameterNumber: 0,
        name: "Sequence",
        min: 1,
        max: 16,
        defaultValue: 1,
        unit: 0,
        powerOfTen: 0,
      ),
      ParameterInfo(
        algorithmIndex: 1,
        parameterNumber: 1,
        name: "Start",
        min: 1,
        max: 16,
        defaultValue: 1,
        unit: 0,
        powerOfTen: 0,
      ),
      ParameterInfo(
        algorithmIndex: 1,
        parameterNumber: 2,
        name: "End",
        min: 1,
        max: 16,
        defaultValue: 8,
        unit: 0,
        powerOfTen: 0,
      ),
      ParameterInfo(
        algorithmIndex: 1,
        parameterNumber: 3,
        name: "Clock input",
        min: 1,
        max: _ioEnumMax,
        defaultValue: 13,
        unit: 1,
        powerOfTen: 0,
      ), // From Clock Divider Clock 1
      ParameterInfo(
        algorithmIndex: 1,
        parameterNumber: 4,
        name: "Reset input",
        min: 0,
        max: _ioEnumMax,
        defaultValue: 0,
        unit: 1,
        powerOfTen: 0,
      ),
      ParameterInfo(
        algorithmIndex: 1,
        parameterNumber: 5,
        name: "CV output",
        min: 1,
        max: _ioEnumMax,
        defaultValue: 15,
        unit: 1,
        powerOfTen: 0,
      ), // CV to VCO
      ParameterInfo(
        algorithmIndex: 1,
        parameterNumber: 6,
        name: "Gate output",
        min: 1,
        max: _ioEnumMax,
        defaultValue: 16,
        unit: 1,
        powerOfTen: 0,
      ), // Gate to Envelope
    ];
    final List<ParameterValue> seqValues = <ParameterValue>[
      ParameterValue(algorithmIndex: 1, parameterNumber: 0, value: 1), // Sequence 1
      ParameterValue(algorithmIndex: 1, parameterNumber: 1, value: 1), // Start at step 1
      ParameterValue(algorithmIndex: 1, parameterNumber: 2, value: 8), // End at step 8
      ParameterValue(algorithmIndex: 1, parameterNumber: 3, value: 13), // Clock from Output 1 (Clock Divider)
      ParameterValue(algorithmIndex: 1, parameterNumber: 4, value: 0), // No reset
      ParameterValue(algorithmIndex: 1, parameterNumber: 5, value: 15), // CV to Output 3 (VCO)
      ParameterValue(algorithmIndex: 1, parameterNumber: 6, value: 16), // Gate to Output 4 (Env)
    ];
    final List<ParameterEnumStrings> seqEnums = <ParameterEnumStrings>[
      ParameterEnumStrings.filler(), // Sequence (not enum)
      ParameterEnumStrings.filler(), // Start (not enum)
      ParameterEnumStrings.filler(), // End (not enum)
      ParameterEnumStrings(algorithmIndex: 1, parameterNumber: 3, values: _ioEnumValues), // Clock input
      ParameterEnumStrings(algorithmIndex: 1, parameterNumber: 4, values: ["None", ..._ioEnumValues]), // Reset input (can be None)
      ParameterEnumStrings(algorithmIndex: 1, parameterNumber: 5, values: _ioEnumValues), // CV output
      ParameterEnumStrings(algorithmIndex: 1, parameterNumber: 6, values: _ioEnumValues), // Gate output
    ];
    final ParameterPages seqPages = ParameterPages(
      algorithmIndex: 1,
      pages: [
        ParameterPage(name: "Sequence", parameters: [0, 1, 2]), // Sequence, Start, End
        ParameterPage(name: "Routing", parameters: [3, 4, 5, 6]), // Clock input, Reset input, CV output, Gate output
      ],
    );
    final List<Mapping> seqMappings = List<Mapping>.generate(
      seqParams.length,
      (_) => Mapping.filler(),
    );
    final List<ParameterValueString> seqValueStrings =
        List<ParameterValueString>.generate(
          seqParams.length,
          (_) => ParameterValueString.filler(),
        );
    final Slot sequencerSlot = Slot(
      algorithm: Algorithm(
        algorithmIndex: 1,
        guid: "seq ",
        name: "Step Sequencer",
      ),
      routing: RoutingInfo.filler(),
      pages: seqPages,
      parameters: seqParams,
      values: seqValues,
      enums: seqEnums,
      mappings: seqMappings,
      valueStrings: seqValueStrings,
    );

    // --- Define Demo Slot 2: VCO (Wavetable) ---
    final List<ParameterInfo> vcoParams = <ParameterInfo>[
      ParameterInfo(
        algorithmIndex: 2,
        parameterNumber: 0,
        name: "Wavetable",
        min: 0,
        max: 99,
        defaultValue: 15,
        unit: 0,
        powerOfTen: 0,
      ),
      ParameterInfo(
        algorithmIndex: 2,
        parameterNumber: 1,
        name: "Root note",
        min: 0,
        max: 127,
        defaultValue: 60,
        unit: 0,
        powerOfTen: 0,
      ), // C4
      ParameterInfo(
        algorithmIndex: 2,
        parameterNumber: 2,
        name: "Fine tune",
        min: -100,
        max: 100,
        defaultValue: 0,
        unit: 0,
        powerOfTen: 0,
      ),
      ParameterInfo(
        algorithmIndex: 2,
        parameterNumber: 3,
        name: "CV input",
        min: 1,
        max: _ioEnumMax,
        defaultValue: 15,
        unit: 1,
        powerOfTen: 0,
      ), // From Sequencer CV
      ParameterInfo(
        algorithmIndex: 2,
        parameterNumber: 4,
        name: "Audio output",
        min: 1,
        max: _ioEnumMax,
        defaultValue: 17,
        unit: 1,
        powerOfTen: 0,
      ), // To Envelope
    ];
    final List<ParameterValue> vcoValues = <ParameterValue>[
      ParameterValue(algorithmIndex: 2, parameterNumber: 0, value: 15), // Wavetable 15 (analog-style)
      ParameterValue(algorithmIndex: 2, parameterNumber: 1, value: 60), // C4 root note
      ParameterValue(algorithmIndex: 2, parameterNumber: 2, value: 0), // No fine tune
      ParameterValue(algorithmIndex: 2, parameterNumber: 3, value: 15), // CV from Sequencer (Output 3)
      ParameterValue(algorithmIndex: 2, parameterNumber: 4, value: 17), // Audio to Output 5 (Envelope)
    ];
    // VCO enums, mappings and value strings are now generated in the Slot creation above
    final ParameterPages vcoPages = ParameterPages(
      algorithmIndex: 2,
      pages: [
        ParameterPage(name: "Wavetable", parameters: [0, 1, 2]), // Wavetable, Root note, Fine tune
        ParameterPage(name: "Routing", parameters: [3, 4]), // CV input, Audio output
      ],
    );
    final List<ParameterEnumStrings> vcoEnums = [
      ParameterEnumStrings.filler(), // Wavetable (not enum - numeric selection)
      ParameterEnumStrings.filler(), // Root note (not enum - MIDI note number)
      ParameterEnumStrings.filler(), // Fine tune (not enum - cents)
      ParameterEnumStrings(algorithmIndex: 2, parameterNumber: 3, values: _ioEnumValues), // CV input
      ParameterEnumStrings(algorithmIndex: 2, parameterNumber: 4, values: _ioEnumValues), // Audio output
    ];

    final Slot vcoSlot = Slot(
      algorithm: Algorithm(
        algorithmIndex: 2,
        guid: "vcow",
        name: "VCO (Wavetable)",
      ),
      routing: RoutingInfo.filler(),
      pages: vcoPages,
      parameters: vcoParams,
      values: vcoValues,
      enums: vcoEnums,
      mappings: List<Mapping>.generate(vcoParams.length, (_) => Mapping.filler()),
      valueStrings: List<ParameterValueString>.generate(vcoParams.length, (_) => ParameterValueString.filler()),
    );

    // Add Envelope and Delay slots (simplified for demo)
    final List<ParameterInfo> envParams = <ParameterInfo>[
      ParameterInfo(
        algorithmIndex: 3,
        parameterNumber: 0,
        name: "Attack time",
        min: 0,
        max: 1000,
        defaultValue: 10,
        unit: 0,
        powerOfTen: 0,
      ),
      ParameterInfo(
        algorithmIndex: 3,
        parameterNumber: 1,
        name: "Release time",
        min: 0,
        max: 1000,
        defaultValue: 200,
        unit: 0,
        powerOfTen: 0,
      ),
      ParameterInfo(
        algorithmIndex: 3,
        parameterNumber: 2,
        name: "Trigger input",
        min: 1,
        max: _ioEnumMax,
        defaultValue: 16,
        unit: 1,
        powerOfTen: 0,
      ), // From Sequencer Gate
      ParameterInfo(
        algorithmIndex: 3,
        parameterNumber: 3,
        name: "CV output",
        min: 1,
        max: _ioEnumMax,
        defaultValue: 18,
        unit: 1,
        powerOfTen: 0,
      ), // To VCA or Filter
    ];

    final List<ParameterValue> envValues = <ParameterValue>[
      ParameterValue(algorithmIndex: 3, parameterNumber: 0, value: 10), // Fast attack
      ParameterValue(algorithmIndex: 3, parameterNumber: 1, value: 200), // Medium release
      ParameterValue(algorithmIndex: 3, parameterNumber: 2, value: 16), // Gate from Sequencer
      ParameterValue(algorithmIndex: 3, parameterNumber: 3, value: 18), // CV to modulation
    ];

    final ParameterPages envPages = ParameterPages(
      algorithmIndex: 3,
      pages: [
        ParameterPage(name: "Envelope", parameters: [0, 1]), // Attack, Release
        ParameterPage(name: "Routing", parameters: [2, 3]), // Trigger input, CV output
      ],
    );

    final List<ParameterEnumStrings> envEnums = [
      ParameterEnumStrings.filler(), // Attack time (not enum - milliseconds)
      ParameterEnumStrings.filler(), // Release time (not enum - milliseconds)
      ParameterEnumStrings(algorithmIndex: 3, parameterNumber: 2, values: _ioEnumValues), // Trigger input
      ParameterEnumStrings(algorithmIndex: 3, parameterNumber: 3, values: _ioEnumValues), // CV output
    ];

    final Slot envelopeSlot = Slot(
      algorithm: Algorithm(algorithmIndex: 3, guid: "env2", name: "Envelope (AR/AD)"),
      routing: RoutingInfo.filler(),
      pages: envPages,
      parameters: envParams,
      values: envValues,
      enums: envEnums,
      mappings: List<Mapping>.generate(envParams.length, (_) => Mapping.filler()),
      valueStrings: List<ParameterValueString>.generate(envParams.length, (_) => ParameterValueString.filler()),
    );
    
    final List<ParameterInfo> delayParams = <ParameterInfo>[
      ParameterInfo(
        algorithmIndex: 4,
        parameterNumber: 0,
        name: "Time",
        min: 1,
        max: 3000,
        defaultValue: 250,
        unit: 0,
        powerOfTen: 0,
      ), // ms
      ParameterInfo(
        algorithmIndex: 4,
        parameterNumber: 1,
        name: "Feedback",
        min: 0,
        max: 100,
        defaultValue: 35,
        unit: 1,
        powerOfTen: 0,
      ), // %
      ParameterInfo(
        algorithmIndex: 4,
        parameterNumber: 2,
        name: "Mix",
        min: 0,
        max: 100,
        defaultValue: 25,
        unit: 1,
        powerOfTen: 0,
      ), // %
      ParameterInfo(
        algorithmIndex: 4,
        parameterNumber: 3,
        name: "Left input",
        min: 1,
        max: _ioEnumMax,
        defaultValue: 17,
        unit: 1,
        powerOfTen: 0,
      ), // From VCO
      ParameterInfo(
        algorithmIndex: 4,
        parameterNumber: 4,
        name: "Left output",
        min: 1,
        max: _ioEnumMax,
        defaultValue: 19,
        unit: 1,
        powerOfTen: 0,
      ), // Final output left
      ParameterInfo(
        algorithmIndex: 4,
        parameterNumber: 5,
        name: "Right output",
        min: 1,
        max: _ioEnumMax,
        defaultValue: 20,
        unit: 1,
        powerOfTen: 0,
      ), // Final output right
    ];

    final List<ParameterValue> delayValues = <ParameterValue>[
      ParameterValue(algorithmIndex: 4, parameterNumber: 0, value: 250), // 1/4 note at 120 BPM
      ParameterValue(algorithmIndex: 4, parameterNumber: 1, value: 35), // Medium feedback
      ParameterValue(algorithmIndex: 4, parameterNumber: 2, value: 25), // Subtle mix
      ParameterValue(algorithmIndex: 4, parameterNumber: 3, value: 17), // From VCO
      ParameterValue(algorithmIndex: 4, parameterNumber: 4, value: 19), // Left out
      ParameterValue(algorithmIndex: 4, parameterNumber: 5, value: 20), // Right out
    ];

    final ParameterPages delayPages = ParameterPages(
      algorithmIndex: 4,
      pages: [
        ParameterPage(name: "Delay", parameters: [0, 1, 2]), // Time, Feedback, Mix
        ParameterPage(name: "Routing", parameters: [3, 4, 5]), // Left input, Left output, Right output
      ],
    );

    final List<ParameterEnumStrings> delayEnums = [
      ParameterEnumStrings.filler(), // Time (not enum - milliseconds)
      ParameterEnumStrings.filler(), // Feedback (not enum - percentage)
      ParameterEnumStrings.filler(), // Mix (not enum - percentage)
      ParameterEnumStrings(algorithmIndex: 4, parameterNumber: 3, values: _ioEnumValues), // Left input
      ParameterEnumStrings(algorithmIndex: 4, parameterNumber: 4, values: _ioEnumValues), // Left output
      ParameterEnumStrings(algorithmIndex: 4, parameterNumber: 5, values: _ioEnumValues), // Right output
    ];

    final Slot delaySlot = Slot(
      algorithm: Algorithm(algorithmIndex: 4, guid: "dels", name: "Delay (Stereo)"),
      routing: RoutingInfo.filler(),
      pages: delayPages,
      parameters: delayParams,
      values: delayValues,
      enums: delayEnums,
      mappings: List<Mapping>.generate(delayParams.length, (_) => Mapping.filler()),
      valueStrings: List<ParameterValueString>.generate(delayParams.length, (_) => ParameterValueString.filler()),
    );

    // --- Assign to State Object ---
    _state.availableAlgorithms = availableAlgorithms;
    _state.presetSlots = [clockSlot, sequencerSlot, vcoSlot, envelopeSlot, delaySlot];
    _state.unitStrings = ["", "%", "Hz", "dB", "°", "V/Oct"]; // Example units
    _state.presetName = "Berlin School Pluck";
    _state.versionString = "Demo v1.0";

    // Debug print lengths
    debugPrint(
      "[Mock Init] Clock Divider Slot: params=${clockSlot.parameters.length}, vals=${clockSlot.values.length}, enums=${clockSlot.enums.length}, maps=${clockSlot.mappings.length}, strs=${clockSlot.valueStrings.length}",
    );
    debugPrint(
      "[Mock Init] Sequencer Slot: params=${sequencerSlot.parameters.length}, vals=${sequencerSlot.values.length}, enums=${sequencerSlot.enums.length}, maps=${sequencerSlot.mappings.length}, strs=${sequencerSlot.valueStrings.length}",
    );
    debugPrint(
      "[Mock Init] VCO Slot: params=${vcoSlot.parameters.length}, vals=${vcoSlot.values.length}, enums=${vcoSlot.enums.length}, maps=${vcoSlot.mappings.length}, strs=${vcoSlot.valueStrings.length}",
    );
    debugPrint(
      "[Mock Init] Berlin School Pluck Voice: ${_state.presetSlots.length} slots total",
    );
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
    int algorithmIndex,
  ) async {
    // Return the AllParameterValues object containing the list of values
    if (algorithmIndex >= 0 && algorithmIndex < _state.presetSlots.length) {
      return AllParameterValues(
        algorithmIndex: algorithmIndex,
        values: _state.presetSlots[algorithmIndex].values,
      );
    }
    debugPrint(
      "[Mock] requestAllParameterValues: Invalid index $algorithmIndex",
    );
    return null;
  }

  @override
  Future<ParameterEnumStrings?> requestParameterEnumStrings(
    int algorithmIndex,
    int parameterNumber,
  ) async {
    // Return actual enums from the stored Slot data
    if (algorithmIndex >= 0 && algorithmIndex < _state.presetSlots.length) {
      if (parameterNumber >= 0 &&
          parameterNumber < _state.presetSlots[algorithmIndex].enums.length) {
        return _state.presetSlots[algorithmIndex].enums[parameterNumber];
      }
    }
    debugPrint(
      "[Mock] requestParameterEnumStrings: Invalid index $algorithmIndex / $parameterNumber",
    );
    return ParameterEnumStrings.filler();
  }

  @override
  Future<Mapping?> requestMappings(
    int algorithmIndex,
    int parameterNumber,
  ) async {
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
      "[Mock] requestMappings: Algo $algorithmIndex, Param $parameterNumber -> Returning ${result.packedMappingData.isMapped() ? 'Mapped' : 'Filler'}",
    );
    return result;
  }

  @override
  Future<NumParameters?> requestNumberOfParameters(int algorithmIndex) async {
    // Return the actual number of parameters for the slot at this index
    if (algorithmIndex >= 0 && algorithmIndex < _state.presetSlots.length) {
      return NumParameters(
        algorithmIndex: algorithmIndex,
        numParameters: _state.presetSlots[algorithmIndex].parameters.length,
      );
    }
    debugPrint(
      "[Mock] requestNumberOfParameters: Invalid index $algorithmIndex",
    );
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
    int algorithmIndex,
    int parameterNumber,
  ) async {
    if (algorithmIndex >= 0 && algorithmIndex < _state.presetSlots.length) {
      if (parameterNumber >= 0 &&
          parameterNumber <
              _state.presetSlots[algorithmIndex].parameters.length) {
        return _state.presetSlots[algorithmIndex].parameters[parameterNumber];
      }
    }
    debugPrint(
      "[Mock] requestParameterInfo: Invalid index $algorithmIndex / $parameterNumber",
    );
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
    int algorithmIndex,
    int parameterNumber,
  ) async {
    // Return based on the current algo at that index
    if (algorithmIndex >= 0 && algorithmIndex < _state.presetSlots.length) {
      // Return value from the actual slot data
      if (parameterNumber >= 0 &&
          parameterNumber < _state.presetSlots[algorithmIndex].values.length) {
        return _state.presetSlots[algorithmIndex].values[parameterNumber];
      }
    }
    debugPrint(
      "[Mock] requestParameterValue: Invalid index $algorithmIndex / $parameterNumber",
    );
    return null;
  }

  @override
  Future<ParameterValueString?> requestParameterValueString(
    int algorithmIndex,
    int parameterNumber,
  ) async {
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
      "[Mock] requestParameterValueString: Invalid index $algorithmIndex / $parameterNumber",
    );
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
    AlgorithmInfo algorithm,
    List<int> specifications,
  ) async {
    // No-op
  }

  @override
  Future<void> requestLoadPlugin(String guid) async {
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
            algorithm: _state.presetSlots[algorithmIndex].algorithm.copyWith(
              algorithmIndex: algorithmIndex,
            ),
          );
      _state.presetSlots[algorithmIndex + 1] = _state
          .presetSlots[algorithmIndex + 1]
          .copyWith(
            algorithm: _state.presetSlots[algorithmIndex + 1].algorithm
                .copyWith(algorithmIndex: algorithmIndex + 1),
          );
      debugPrint(
        "[Mock] State after move down: ${_state.presetSlots.map((s) => '${s.algorithm.name}(${s.algorithm.algorithmIndex})').toList()}",
      );
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
            algorithm: _state.presetSlots[algorithmIndex].algorithm.copyWith(
              algorithmIndex: algorithmIndex,
            ),
          );
      _state.presetSlots[algorithmIndex - 1] = _state
          .presetSlots[algorithmIndex - 1]
          .copyWith(
            algorithm: _state.presetSlots[algorithmIndex - 1].algorithm
                .copyWith(algorithmIndex: algorithmIndex - 1),
          );
      debugPrint(
        "[Mock] State after move up: ${_state.presetSlots.map((s) => '${s.algorithm.name}(${s.algorithm.algorithmIndex})').toList()}",
      );
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
    int algorithmIndex,
    int parameterNumber,
    PackedMappingData data,
  ) async {
    // No-op
  }

  @override
  Future<void> requestSetDisplayMode(DisplayMode displayMode) async {
    // No-op
  }

  @override
  Future<void> requestSetRealTimeClock(int unixTimeSeconds) async {
    // No-op
  }

  @override
  Future<void> requestSetFocus(int algorithmIndex, int parameterNumber) async {
    // No-op
  }

  @override
  Future<void> requestSetMapping(
    int algorithmIndex,
    int parameterNumber,
    PackedMappingData data,
  ) async {
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
    int algorithmIndex,
    int parameterNumber,
    int value,
  ) async {
    // Update the value in the internal state if valid
    if (algorithmIndex >= 0 && algorithmIndex < _state.presetSlots.length) {
      if (parameterNumber >= 0 &&
          parameterNumber < _state.presetSlots[algorithmIndex].values.length) {
        final currentSlot = _state.presetSlots[algorithmIndex];
        final valueIndex = currentSlot.values.indexWhere(
          (pv) => pv.parameterNumber == parameterNumber,
        );

        if (valueIndex != -1) {
          final currentParamValue = currentSlot.values[valueIndex];
          final updatedValues = List<ParameterValue>.from(currentSlot.values);
          updatedValues[valueIndex] = ParameterValue(
            algorithmIndex: currentParamValue.algorithmIndex,
            parameterNumber: currentParamValue.parameterNumber,
            value: value, // Use the new value
          );

          final updatedSlot = currentSlot.copyWith(
            values: updatedValues,
          ); // Assuming Slot has copyWith
          _state.presetSlots[algorithmIndex] = updatedSlot;
          debugPrint(
            "[Mock] setParameterValue: Algo $algorithmIndex, Param $parameterNumber = $value",
          );
        } else {
          debugPrint(
            "[Mock] setParameterValue: Error finding value index for Param $parameterNumber",
          );
        }
      } else {
        debugPrint(
          "[Mock] setParameterValue: Invalid parameterNumber $parameterNumber",
        );
      }
    } else {
      debugPrint(
        "[Mock] setParameterValue: Invalid algorithmIndex $algorithmIndex",
      );
    }
  }

  @override
  Future<void> setParameterString(
    int algorithmIndex,
    int parameterNumber,
    String value,
  ) async {
    // Update the string value in the internal state if valid
    if (algorithmIndex >= 0 && algorithmIndex < _state.presetSlots.length) {
      if (parameterNumber >= 0 &&
          parameterNumber <
              _state.presetSlots[algorithmIndex].valueStrings.length) {
        final currentSlot = _state.presetSlots[algorithmIndex];
        final valueIndex = currentSlot.valueStrings.indexWhere(
          (pv) => pv.parameterNumber == parameterNumber,
        );

        if (valueIndex != -1) {
          final currentParamValueString = currentSlot.valueStrings[valueIndex];
          final updatedValueStrings = List<ParameterValueString>.from(
            currentSlot.valueStrings,
          );
          updatedValueStrings[valueIndex] = ParameterValueString(
            algorithmIndex: currentParamValueString.algorithmIndex,
            parameterNumber: currentParamValueString.parameterNumber,
            value: value, // Use the new string value
          );

          final updatedSlot = currentSlot.copyWith(
            valueStrings: updatedValueStrings,
          ); // Assuming Slot has copyWith
          _state.presetSlots[algorithmIndex] = updatedSlot;
          debugPrint(
            "[Mock] setParameterString: Algo $algorithmIndex, Param $parameterNumber = '$value'",
          );
        } else {
          debugPrint(
            "[Mock] setParameterString: Error finding value string index for Param $parameterNumber",
          );
        }
      } else {
        debugPrint(
          "[Mock] setParameterString: Invalid parameterNumber $parameterNumber",
        );
      }
    } else {
      debugPrint(
        "[Mock] setParameterString: Invalid algorithmIndex $algorithmIndex",
      );
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
    String path,
    Uint8List data,
    int position, {
    bool createAlways = false,
  }) => throw UnsupportedError('Not supported in mock');

  @override
  Future<SdCardStatus?> requestDirectoryCreate(String path) =>
      throw UnsupportedError('Not supported in mock');

  @override
  Future<void> requestSclFile(String filePath) =>
      throw UnsupportedError('Not supported in mock');

  @override
  Future<void> requestKbmFile(String filePath) =>
      throw UnsupportedError('Not supported in mock');

  @override
  Future<CpuUsage?> requestCpuUsage() async {
    throw UnsupportedError("CPU Usage is not available in mock mode.");
  }

  @override
  Future<void> backupPlugins(
    String backupDirectory, {
    void Function(double progress, String currentFile)? onProgress,
  }) async {
    // Mock backup - simulate progress
    final mockFiles = [
      '/programs/lua/example.lua',
      '/programs/three_pot/test.3pot',
      '/programs/plug-ins/plugin.o',
    ];

    for (int i = 0; i < mockFiles.length; i++) {
      await Future.delayed(const Duration(milliseconds: 500));
      onProgress?.call(
        (i + 1) / mockFiles.length,
        'Downloaded ${mockFiles[i]}',
      );
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
