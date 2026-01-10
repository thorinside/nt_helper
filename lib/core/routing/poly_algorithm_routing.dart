import 'package:flutter/foundation.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'algorithm_routing.dart';
import 'models/port.dart';

/// Configuration data for polyphonic algorithm routing.
///
/// Defines the properties needed to configure polyphonic routing behavior,
/// including the number of voices and gate/CV requirements.
@immutable
class PolyAlgorithmConfig {
  /// Number of polyphonic voices supported by this algorithm
  final int voiceCount;

  /// Whether this algorithm requires gate inputs for each voice
  final bool requiresGateInputs;

  /// Whether this algorithm uses virtual CV ports for modulation
  final bool usesVirtualCvPorts;

  /// Number of virtual CV ports to generate per voice
  final int virtualCvPortsPerVoice;

  /// Optional explicit gate bus assignments for poly algorithms that follow
  /// the Disting NT polysynth pattern (Gate + N CVs on consecutive busses).
  ///
  /// Each entry is the selected bus for Gate N (0 means 'None').
  /// Only non-zero (connected) gates will produce CV input ports.
  final List<int>? gateInputs;

  /// Optional CV counts for each gate (same indexing as [gateInputs]).
  /// Determines how many CV inputs are available on consecutive busses
  /// immediately after the gate bus for that gate. If omitted, defaults to 0.
  final List<int>? gateCvCounts;

  /// Base name prefix for generated ports
  final String portNamePrefix;

  /// Additional algorithm-specific properties
  final Map<String, dynamic> algorithmProperties;

  const PolyAlgorithmConfig({
    required this.voiceCount,
    this.requiresGateInputs = true,
    this.usesVirtualCvPorts = true,
    this.virtualCvPortsPerVoice = 2,
    this.gateInputs,
    this.gateCvCounts,
    this.portNamePrefix = 'Voice',
    this.algorithmProperties = const {},
  });
}

/// Concrete implementation of AlgorithmRouting for polyphonic routing.
///
/// This class handles polyphonic routing with gate input and virtual CV ports
/// based on algorithm properties. It dynamically generates ports based on the
/// number of voices and routing requirements of the polyphonic algorithm.
///
/// Each voice typically includes:
/// - Audio input/output ports
/// - Gate input for triggering
/// - CV inputs for modulation (if enabled)
///
/// Example usage:
/// ```dart
/// final config = PolyAlgorithmConfig(
///   voiceCount: 4,
///   requiresGateInputs: true,
///   usesVirtualCvPorts: true,
/// );
///
/// final polyRouting = PolyAlgorithmRouting(config: config);
/// final inputPorts = polyRouting.generateInputPorts();
/// ```
class PolyAlgorithmRouting extends CachedAlgorithmRouting {
  /// Configuration for this polyphonic routing instance
  final PolyAlgorithmConfig config;

  /// Creates a new PolyAlgorithmRouting instance.
  ///
  /// Parameters:
  /// - [config]: Configuration defining the polyphonic routing behavior
  /// - [validator]: Optional port compatibility validator (uses default if not provided)
  /// - [initialState]: Optional initial routing state
  PolyAlgorithmRouting({
    required this.config,
    super.validator,
    super.initialState,
  }) : super(algorithmUuid: config.algorithmProperties['algorithmUuid'] as String?);

  @override
  List<Port> generateInputPorts() {
    final ports = <Port>[];

    // If explicit gate inputs are provided (either directly or via algorithmProperties),
    // follow the gate + CV-per-gate pattern.
    List<int>? gateInputsFromProps;
    List<int>? gateCvCountsFromProps;
    final props = config.algorithmProperties;
    if (config.gateInputs == null && props.containsKey('gateInputs')) {
      final raw = props['gateInputs'];
      if (raw is List) {
        gateInputsFromProps = raw
            .map((e) => (e is num) ? e.toInt() : 0)
            .toList();
      }
    }
    if (config.gateCvCounts == null && props.containsKey('gateCvCounts')) {
      final raw = props['gateCvCounts'];
      if (raw is List) {
        gateCvCountsFromProps = raw
            .map((e) => (e is num) ? e.toInt() : 0)
            .toList();
      }
    }

    final effectiveGateInputs = config.gateInputs ?? gateInputsFromProps;
    final effectiveGateCvCounts = config.gateCvCounts ?? gateCvCountsFromProps;
    final hasGateDrivenSpec =
        (effectiveGateInputs != null && effectiveGateInputs.isNotEmpty) &&
        config.requiresGateInputs;
    if (hasGateDrivenSpec) {
      final gateInputs =
          effectiveGateInputs; // Non-null due to hasGateDrivenSpec
      final gateCvCounts = effectiveGateCvCounts ?? const [];

      for (int gateIndex = 0; gateIndex < gateInputs.length; gateIndex++) {
        final gateNumber = gateIndex + 1; // 1-based
        final gateBus = gateInputs[gateIndex];

        // Only connected gates (bus > 0) produce Gate and CV ports
        if (gateBus > 0) {
          // Gate input port with algorithm UUID for uniqueness
          final algUuid =
              config.algorithmProperties['algorithmUuid'] as String?;
          final gatePortId = algUuid != null
              ? '${algUuid}_gate_$gateNumber'
              : 'poly_gate_in_$gateNumber';

          ports.add(
            Port(
              id: gatePortId,
              name: 'Gate $gateNumber',
              type: PortType.cv, // All gate/trigger signals are CV (Story 7.5)
              direction: PortDirection.input,
              description: 'Gate/trigger input for gate $gateNumber',
              // Direct properties
              isPolyVoice: true,
              voiceNumber: gateNumber,
              busValue: gateBus,
            ),
          );

          // CV inputs for this connected gate, on consecutive busses after the gate bus
          final cvCount = gateIndex < gateCvCounts.length
              ? gateCvCounts[gateIndex]
              : 0;
          for (int cv = 0; cv < cvCount; cv++) {
            final cvNumber = cv + 1;
            final algUuid =
                config.algorithmProperties['algorithmUuid'] as String?;
            final cvPortId = algUuid != null
                ? '${algUuid}_gate_${gateNumber}_cv_$cvNumber'
                : 'poly_gate_${gateNumber}_cv_$cvNumber';
            final cvBus = gateBus + cvNumber; // Bus mapping rule

            ports.add(
              Port(
                id: cvPortId,
                name: 'Gate $gateNumber CV$cvNumber',
                type: PortType.cv,
                direction: PortDirection.input,
                description: 'CV input $cvNumber for gate $gateNumber',
                // Direct properties
                isPolyVoice: true,
                voiceNumber: gateNumber,
                busValue: cvBus,
              ),
            );
          }
        }
      }
    }

    // Append any extra declared inputs (e.g., Wave input, Pitchbend input, Audio input)
    final extras = props['extraInputs'];
    if (extras is List) {
      for (final item in extras) {
        if (item is Map) {
          final port = buildPortFromDeclaration(
            item,
            direction: PortDirection.input,
            defaultId: 'extra_${ports.length + 1}',
            defaultName: 'Extra Input',
            defaultType: PortType.cv,
          ).copyWith(isVirtualCV: item['isVirtualCV'] == true);

          ports.add(port);
        }
      }
    }

    return ports;
  }

  @override
  List<Port> generateOutputPorts() {
    final ports = <Port>[];

    // If outputs are explicitly defined in algorithm properties, use them.
    final outputs = config.algorithmProperties['outputs'];
    if (outputs is List && outputs.isNotEmpty) {
      for (final item in outputs) {
        if (item is Map) {
          final port = buildPortFromDeclaration(
            item,
            direction: PortDirection.output,
            defaultId: 'out_${ports.length + 1}',
            defaultName: 'Output',
            defaultType: PortType.audio,
            includeOutputMode: true,
          ).copyWith(
            channelNumber: coerceInt(item['channel']),
            isStereoChannel: item['channel'] != null,
            stereoSide: item['channel']?.toString(),
            isPolyVoice: item['voiceNumber'] != null,
            voiceNumber: coerceInt(item['voiceNumber']),
          );

          ports.add(port);
        }
      }
      return ports;
    }

    // No declared outputs; return empty and let higher layers decide or provide outputs via properties
    return ports;
  }

  @override
  bool validateConnection(Port source, Port destination) {
    // Virtual CV connections need special handling
    if (_isVirtualCvPort(source) || _isVirtualCvPort(destination)) {
      if (!_validateVirtualCvConnection(source, destination)) {
        return false;
      }
    }
    // For other connections, use base validation
    else if (!super.validateConnection(source, destination)) {
      return false;
    }

    // Additional polyphonic-specific validation
    if (_isPolyVoicePort(source) && _isPolyVoicePort(destination)) {
      // Voice-to-voice connections should be between same voice numbers
      final sourceVoice = _getVoiceNumber(source);
      final destVoice = _getVoiceNumber(destination);

      if (sourceVoice != null &&
          destVoice != null &&
          sourceVoice != destVoice) {
        return false;
      }
    }

    return true;
  }

  /// Validates virtual CV connections
  bool _validateVirtualCvConnection(Port source, Port destination) {
    // Virtual CV ports should only connect to CV or audio ports
    // Note: In Eurorack, all signals are voltage-based, so CV and audio are compatible
    if (_isVirtualCvPort(source)) {
      return destination.type == PortType.cv ||
          destination.type == PortType.audio;
    }

    if (_isVirtualCvPort(destination)) {
      return source.type == PortType.cv ||
          source.type == PortType.audio;
    }

    return true;
  }

  /// Checks if a port belongs to a polyphonic voice
  bool _isPolyVoicePort(Port port) {
    return port.isPolyVoice;
  }

  /// Gets the voice number from a polyphonic voice port
  int? _getVoiceNumber(Port port) {
    return port.voiceNumber;
  }

  /// Checks if a port is a virtual CV port
  bool _isVirtualCvPort(Port port) {
    return port.isVirtualCV;
  }

  /// Updates the voice count and regenerates ports
  void updateVoiceCount(int newVoiceCount) {
    if (newVoiceCount != config.voiceCount) {
      // Clear cached ports to force regeneration
      // Note: Config is immutable, so this only clears caches for when
      // a new instance would be created with different config
      clearPortCaches();
    }
  }

  /// Determines if this routing implementation can handle the given slot.
  ///
  /// Returns true if the algorithm GUID starts with 'py' (polysynth algorithms)
  /// or is 'gran' (Granulator algorithm).
  static bool canHandle(Slot slot) {
    final guid = slot.algorithm.guid;
    return guid.startsWith('py') || guid == 'gran';
  }

  /// Creates a PolyAlgorithmRouting instance from a slot.
  ///
  /// Extracts gate configuration following the CV/Gate Setup specification:
  /// - Up to 6 gates, each with a bus assignment (0 = None)
  /// - Each gate has a CV count (0-11)
  /// - CVs follow immediately after gate bus (e.g., gate on bus 1, CVs on buses 2-3)
  ///
  /// All other routing parameters are converted to regular input/output ports.
  ///
  /// Parameters:
  /// - [slot]: The slot containing algorithm and parameter information
  /// - [ioParameters]: Pre-extracted routing parameters (bus assignments)
  /// - [modeParameters]: Pre-extracted mode parameters (Add/Replace modes)
  /// - [modeParametersWithNumbers]: Mode parameters with their parameter numbers
  /// - [algorithmUuid]: Optional UUID for the algorithm instance
  static PolyAlgorithmRouting createFromSlot(
    Slot slot, {
    required Map<String, int> ioParameters,
    Map<String, int>? modeParameters,
    Map<String, ({int parameterNumber, int value})>? modeParametersWithNumbers,
    String? algorithmUuid,
  }) {
    // Ensure we have a valid algorithm UUID
    final algId =
        algorithmUuid ??
        'algo_${slot.algorithm.guid}_${DateTime.now().millisecondsSinceEpoch}';
    // Extract gate configuration per CV/Gate Setup spec
    final gateInputs = <int>[];
    final gateCvCounts = <int>[];

    // Process all 6 possible gates
    for (int i = 1; i <= 6; i++) {
      // Gate input bus (0 = None, 1-28 = bus assignment)
      final gateBus = ioParameters['Gate input $i'] ?? 0;
      gateInputs.add(gateBus);

      // CV count for this gate (only relevant if gate is connected)
      final cvCount = ioParameters['Gate $i CV count'] ?? 0;
      gateCvCounts.add(cvCount);
      if (gateBus > 0 || cvCount > 0) {}
    }

    // Trim trailing unconnected gates
    while (gateInputs.isNotEmpty && gateInputs.last == 0) {
      gateInputs.removeLast();
      gateCvCounts.removeLast();
    }

    // Process remaining routing parameters as regular ports
    final inputPorts = <Map<String, Object?>>[];
    final outputPorts = <Map<String, Object?>>[];

    // Find parameter info for each io parameter to get parameter numbers
    final paramsByName = <String, ParameterInfo>{
      for (final p in slot.parameters) p.name: p,
    };

    for (final entry in ioParameters.entries) {
      final paramName = entry.key;
      final busValue = entry.value;

      // Skip gate-specific parameters (handled above)
      // Also skip Poly CV configuration parameters that aren't actual ports
      if (paramName.startsWith('Gate input ') ||
          (paramName.startsWith('Gate ') && paramName.contains(' CV count')) ||
          paramName == 'First output' ||
          paramName == 'Voices' ||
          paramName == 'Gate outputs' ||
          paramName == 'Pitch outputs' ||
          paramName == 'Velocity outputs') {
        continue;
      }

      // Get parameter info to access I/O flags
      final paramInfo = paramsByName[paramName];
      if (paramInfo == null) continue;

      // Use I/O flags from hardware metadata to determine direction
      final isOutput = paramInfo.isOutput;
      final isInput = paramInfo.isInput;

      // Skip parameters that are not I/O parameters (no I/O flags set)
      if (!isOutput && !isInput) continue;

      final paramNumber = paramInfo.parameterNumber;

      // Determine port type from isAudio flag (cosmetic only - affects port color)
      String portType = paramInfo.isAudio ? 'audio' : 'cv';

      final port = {
        'id':
            '${algId}_param_$paramNumber', // Unique ID with algorithm UUID and parameter number
        'name': paramName,
        'type': portType,
        'busParam': paramName,
        'busValue': int.tryParse(busValue.toString()),
        'parameterNumber': int.tryParse(paramNumber.toString()),
      };

      if (isOutput) {
        // Add channel metadata for stereo outputs (still uses name pattern - not I/O related)
        final lowerName = paramName.toLowerCase();
        if (lowerName.contains('left')) {
          port['channel'] = 'left';
        } else if (lowerName.contains('right')) {
          port['channel'] = 'right';
        } else if (lowerName.contains('mono')) {
          port['channel'] = 'mono';
        }

        // Determine output mode from hardware data (Story 7.6)
        // Use outputModeMap from SysEx 0x55 responses instead of pattern matching
        int? modeParameterNumber;
        String? outputMode;

        // Check if this output parameter is controlled by any mode parameter
        // by iterating through the output mode map
        for (final entry in slot.outputModeMap.entries) {
          final sourceParam = entry.key;  // Mode control parameter number
          final affectedParams = entry.value;  // List of affected output parameters

          if (affectedParams.contains(paramNumber)) {
            // This output is controlled by a mode parameter
            modeParameterNumber = sourceParam;

            // Get the current value of the mode parameter (0 = Add, 1 = Replace)
            final modeValue = AlgorithmRouting.getParameterValueByNumber(
              slot,
              sourceParam,
              defaultValue: 0,
            );

            outputMode = (modeValue == 1) ? 'replace' : 'add';
            break; // Found the mode parameter for this output
          }
        }

        // Apply output mode to port if found
        if (outputMode != null) {
          port['outputMode'] = outputMode;
        }

        // Store mode parameter number if found
        if (modeParameterNumber != null) {
          port['modeParameterNumber'] = modeParameterNumber;
        }

        // Fallback for offline/mock mode when no outputModeMap data (Story 7.6 AC-6)
        // When ioFlags == 0, use pattern matching as temporary fallback
        if (slot.outputModeMap.isEmpty && modeParameters != null) {
          // Offline mode fallback: use pattern matching temporarily
          final List<String> possibleModeNames = [
            '$paramName mode',
            '${paramName.split(' ').first} mode',
            'Output mode',
          ];

          for (final name in possibleModeNames) {
            if (modeParameters.containsKey(name)) {
              final modeValue = modeParameters[name];
              port['outputMode'] = (modeValue == 1) ? 'replace' : 'add';

              // Also try to get the parameter number for offline mode
              if (modeParametersWithNumbers != null &&
                  modeParametersWithNumbers.containsKey(name)) {
                final modeInfo = modeParametersWithNumbers[name];
                port['modeParameterNumber'] = modeInfo!.parameterNumber;
              }
              break;
            }
          }
        }

        outputPorts.add(port);
      } else {
        inputPorts.add(port);
      }
    }

    // Get voice count if available
    int voiceCount = 1;
    final maxVoices = AlgorithmRouting.getParameterValue(slot, 'Max voices');
    if (maxVoices > 0) {
      voiceCount = maxVoices;
    } else {
      final voices = AlgorithmRouting.getParameterValue(slot, 'Voices');
      if (voices > 0) voiceCount = voices;
    }

    // Determine if this algorithm actually has gate inputs
    final hasGateInputs = gateInputs.any((bus) => bus > 0);

    // Check if this algorithm uses the Poly CV output pattern
    // (has "First output", "Gate outputs", "Pitch outputs", "Velocity outputs" parameters)
    final firstOutput = AlgorithmRouting.getParameterValue(
      slot,
      'First output',
    );
    final gateOutputsParam = slot.parameters.firstWhere(
      (p) => p.name == 'Gate outputs',
      orElse: () => ParameterInfo.filler(),
    );
    final hasPolyCvOutputPattern =
        firstOutput > 0 && gateOutputsParam.parameterNumber >= 0;

    if (hasPolyCvOutputPattern) {
      // Handle Poly CV output pattern
      // Get boolean parameters (these are checkboxes, so 1 = enabled, 0 = disabled)
      final gateOutputs = AlgorithmRouting.getParameterValue(
        slot,
        'Gate outputs',
      );
      final pitchOutputs = AlgorithmRouting.getParameterValue(
        slot,
        'Pitch outputs',
      );
      final velocityOutputs = AlgorithmRouting.getParameterValue(
        slot,
        'Velocity outputs',
      );

      // Get ES-5 parameters for gate routing
      final es5ExpanderValue = AlgorithmRouting.getParameterValue(
        slot,
        'ES-5 Expander',
      );
      final es5OutputValue = AlgorithmRouting.getParameterValue(
        slot,
        'ES-5 Output',
      );

      // Get ES-5 Expander parameter number for UI toggle synchronization
      final es5ExpanderParam = slot.parameters.firstWhere(
        (p) => p.name == 'ES-5 Expander',
        orElse: () => ParameterInfo.filler(),
      );
      final es5ExpanderParamNumber = es5ExpanderParam.parameterNumber >= 0
          ? es5ExpanderParam.parameterNumber
          : null;

      final useEs5ForGates = es5ExpanderValue > 0 && gateOutputs > 0;

      // Generate output ports for each voice
      for (int voice = 0; voice < voiceCount; voice++) {
        // Voice numbering is 1-based for display
        final voiceNum = voice + 1;

        if (gateOutputs > 0) {
          // Get Gate mode if available
          String? gateMode;
          if (modeParameters != null &&
              modeParameters.containsKey('Gate mode')) {
            gateMode = modeParameters['Gate mode'] == 1 ? 'replace' : 'add';
          }

          if (useEs5ForGates) {
            // ES-5 MODE: Gates route to ES-5 expander ports
            final es5Port = es5OutputValue + voice;

            // Handle edge case: If voice count > 8, clip to ES-5 port range (1-8)
            if (es5Port <= 8) {
              final portMap = <String, dynamic>{
                'id': '${algId}_gate_output_$voiceNum',
                'name': 'Voice $voiceNum Gate → ES-5 $es5Port',
                'type': 'gate',
                'busParam': 'es5_direct', // Special marker for ES-5 routing
                'channel':
                    es5Port, // ES-5 port number (using 'channel' key for Port.fromJson)
                'parameterNumber': 0,
                'voiceNumber': voiceNum,
              };

              if (gateMode != null) {
                portMap['outputMode'] = gateMode;
              }

              // Only include es5ExpanderParamNumber if valid
              if (es5ExpanderParamNumber != null) {
                portMap['es5ExpanderParamNumber'] = es5ExpanderParamNumber;
              }

              outputPorts.add(portMap);
            } else {}
          } else {
            // NORMAL MODE: Gates use normal bus allocation
            // Bus calculation: firstOutput + (voice * total_outputs_per_voice) + offset_within_voice
            int outputsPerVoice = 0;
            if (gateOutputs > 0) outputsPerVoice++;
            if (pitchOutputs > 0) outputsPerVoice++;
            if (velocityOutputs > 0) outputsPerVoice++;

            final currentBus = firstOutput + (voice * outputsPerVoice);

            outputPorts.add({
              'id': '${algId}_gate_output_$voiceNum',
              'name': 'Gate output $voiceNum',
              'type': 'gate',
              'busValue': currentBus,
              'busParam': 'Gate output',
              'parameterNumber': 0,
              'voiceNumber': voiceNum,
              'outputMode': gateMode,
            });
          }
        }

        // Pitch and Velocity CVs ALWAYS use normal bus allocation
        // (ES-5 does not affect CV outputs)
        // Bus allocation: Each voice occupies totalOutputsPerVoice buses
        // Calculate total outputs per voice for proper bus allocation
        int totalOutputsPerVoice = 0;
        if (gateOutputs > 0) totalOutputsPerVoice++;
        if (pitchOutputs > 0) totalOutputsPerVoice++;
        if (velocityOutputs > 0) totalOutputsPerVoice++;

        int cvBusOffset = 0;
        // When gates use normal buses, CVs come after gates within this voice's allocation
        // When gates use ES-5, CVs start from firstOutput (gates don't consume buses)
        if (!useEs5ForGates && gateOutputs > 0) {
          cvBusOffset = 1; // Skip gate bus within this voice's bus allocation
        }

        final cvBaseBus =
            firstOutput + (voice * totalOutputsPerVoice) + cvBusOffset;
        int currentCvOffset = 0;

        if (pitchOutputs > 0) {
          // Get Pitch mode if available
          String? pitchMode;
          if (modeParameters != null &&
              modeParameters.containsKey('Pitch mode')) {
            pitchMode = modeParameters['Pitch mode'] == 1 ? 'replace' : 'add';
          }

          outputPorts.add({
            'id': '${algId}_pitch_output_$voiceNum',
            'name': 'Pitch output $voiceNum',
            'type': 'cv',
            'busValue': cvBaseBus + currentCvOffset,
            'busParam': 'Pitch output',
            'parameterNumber': 0,
            'voiceNumber': voiceNum,
            'outputMode': pitchMode,
          });

          currentCvOffset++;
        }

        if (velocityOutputs > 0) {
          // Get Velocity mode if available
          String? velocityMode;
          if (modeParameters != null &&
              modeParameters.containsKey('Velocity mode')) {
            velocityMode = modeParameters['Velocity mode'] == 1
                ? 'replace'
                : 'add';
          }

          outputPorts.add({
            'id': '${algId}_velocity_output_$voiceNum',
            'name': 'Velocity output $voiceNum',
            'type': 'cv',
            'busValue': cvBaseBus + currentCvOffset,
            'busParam': 'Velocity output',
            'parameterNumber': 0,
            'voiceNumber': voiceNum,
            'outputMode': velocityMode,
          });

          currentCvOffset++;
        }
      }
    }

    // Create configuration for poly routing
    final config = PolyAlgorithmConfig(
      voiceCount: voiceCount,
      requiresGateInputs: hasGateInputs,
      usesVirtualCvPorts: false, // Real CV ports based on gate configuration
      gateInputs: gateInputs.isNotEmpty ? gateInputs : null,
      gateCvCounts: gateCvCounts.isNotEmpty ? gateCvCounts : null,
      algorithmProperties: {
        'algorithmGuid': slot.algorithm.guid,
        'algorithmName': slot.algorithm.name,
        'algorithmUuid': algId, // Use the ensured algorithm ID
        'extraInputs': inputPorts, // Non-gate routing inputs
        'outputs': outputPorts, // All output routing parameters
        'gateInputs': gateInputs, // Store for gate port generation
        'gateCvCounts': gateCvCounts, // Store for CV port generation
      },
    );

    return PolyAlgorithmRouting(config: config);
  }
}
