import 'package:flutter/foundation.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'algorithm_routing.dart';
import 'models/routing_state.dart';
import 'models/port.dart';
import 'models/connection.dart';

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
class PolyAlgorithmRouting extends AlgorithmRouting {
  /// Configuration for this polyphonic routing instance
  final PolyAlgorithmConfig config;
  
  /// Current routing state
  RoutingState _state;
  
  /// Cached input ports to avoid regeneration
  List<Port>? _cachedInputPorts;
  
  /// Cached output ports to avoid regeneration  
  List<Port>? _cachedOutputPorts;

  /// Creates a new PolyAlgorithmRouting instance.
  /// 
  /// Parameters:
  /// - [config]: Configuration defining the polyphonic routing behavior
  /// - [validator]: Optional port compatibility validator (uses default if not provided)
  /// - [initialState]: Optional initial routing state
  PolyAlgorithmRouting({
    required this.config,
    super.validator,
    RoutingState? initialState,
  }) : _state = initialState ?? const RoutingState() {
    debugPrint(
      'PolyAlgorithmRouting: Initialized with ${config.voiceCount} voices, '
      'gates: ${config.requiresGateInputs}, CV: ${config.usesVirtualCvPorts}'
    );
  }

  @override
  RoutingState get state => _state;

  @override
  List<Port> get inputPorts => _cachedInputPorts ??= generateInputPorts();

  @override
  List<Port> get outputPorts => _cachedOutputPorts ??= generateOutputPorts();

  @override
  List<Connection> get connections => _state.connections;

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
        gateInputsFromProps = raw.map((e) => (e is num) ? e.toInt() : 0).toList();
      }
    }
    if (config.gateCvCounts == null && props.containsKey('gateCvCounts')) {
      final raw = props['gateCvCounts'];
      if (raw is List) {
        gateCvCountsFromProps = raw.map((e) => (e is num) ? e.toInt() : 0).toList();
      }
    }

    final effectiveGateInputs = config.gateInputs ?? gateInputsFromProps;
    final effectiveGateCvCounts = config.gateCvCounts ?? gateCvCountsFromProps;
    final hasGateDrivenSpec = (effectiveGateInputs != null && effectiveGateInputs.isNotEmpty);
    if (hasGateDrivenSpec) {
      final gateInputs = effectiveGateInputs; // Non-null due to hasGateDrivenSpec
      final gateCvCounts = effectiveGateCvCounts ?? const [];

      for (int gateIndex = 0; gateIndex < gateInputs.length; gateIndex++) {
        final gateNumber = gateIndex + 1; // 1-based
        final gateBus = gateInputs[gateIndex];

        // Only connected gates (bus > 0) produce Gate and CV ports
        if (gateBus > 0) {
          // Gate input port with algorithm UUID for uniqueness
          final algUuid = config.algorithmProperties['algorithmUuid'] as String?;
          final gatePortId = algUuid != null 
              ? '${algUuid}_gate_$gateNumber'
              : 'poly_gate_in_$gateNumber';
          
          ports.add(Port(
            id: gatePortId,
            name: 'Gate $gateNumber',
            type: PortType.gate,
            direction: PortDirection.input,
            description: 'Gate/trigger input for gate $gateNumber',
            // Direct properties
            isPolyVoice: true,
            voiceNumber: gateNumber,
            busValue: gateBus,
          ));

          // CV inputs for this connected gate, on consecutive busses after the gate bus
          final cvCount = gateIndex < gateCvCounts.length ? gateCvCounts[gateIndex] : 0;
          for (int cv = 0; cv < cvCount; cv++) {
            final cvNumber = cv + 1;
            final algUuid = config.algorithmProperties['algorithmUuid'] as String?;
            final cvPortId = algUuid != null
                ? '${algUuid}_gate_${gateNumber}_cv_$cvNumber'
                : 'poly_gate_${gateNumber}_cv_$cvNumber';
            final cvBus = gateBus + cvNumber;  // Bus mapping rule
            
            ports.add(Port(
              id: cvPortId,
              name: 'Gate $gateNumber CV$cvNumber',
              type: PortType.cv,
              direction: PortDirection.input,
              description: 'CV input $cvNumber for gate $gateNumber',
              // Direct properties
              isPolyVoice: true,
              voiceNumber: gateNumber,
              busValue: cvBus,
            ));
          }
        }
      }
    }

    // Append any extra declared inputs (e.g., Wave input, Pitchbend input, Audio input)
    final extras = props['extraInputs'];
    if (extras is List) {
      for (final item in extras) {
        if (item is Map) {
          final id = item['id']?.toString() ?? 'extra_${ports.length + 1}';
          final name = item['name']?.toString() ?? 'Extra Input';
          final typeStr = item['type']?.toString().toLowerCase();
          final type = _parsePortType(typeStr) ?? PortType.cv;
          ports.add(Port(
            id: id,
            name: name,
            type: type,
            direction: PortDirection.input,
            description: item['description']?.toString(),
            // Direct properties
            busValue: item['busValue'] as int?,
            busParam: item['busParam']?.toString(),
            parameterNumber: item['parameterNumber'] as int?,
            isVirtualCV: item['isVirtualCV'] == true,
          ));
        }
      }
    }
    
    debugPrint('PolyAlgorithmRouting: Generated ${ports.length} input ports');
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
          final id = item['id']?.toString() ?? 'out_${ports.length + 1}';
          final name = item['name']?.toString() ?? 'Output';
          final typeStr = item['type']?.toString().toLowerCase();
          final type = _parsePortType(typeStr) ?? PortType.audio;
          // Determine output mode if available
          OutputMode? outputMode;
          if (item['outputMode'] != null) {
            final modeStr = item['outputMode'].toString().toLowerCase();
            if (modeStr == 'replace') {
              outputMode = OutputMode.replace;
            } else if (modeStr == 'add') {
              outputMode = OutputMode.add;
            }
          }
          
          ports.add(Port(
            id: id,
            name: name,
            type: type,
            direction: PortDirection.output,
            description: item['description']?.toString(),
            outputMode: outputMode,
            // Direct properties
            busValue: item['busValue'] as int?,
            busParam: item['busParam']?.toString(),
            parameterNumber: item['parameterNumber'] as int?,
            channelNumber: item['channel'] as int?,
            isStereoChannel: item['channel'] != null,
            stereoSide: item['channel']?.toString(),
          ));
        }
      }
      debugPrint('PolyAlgorithmRouting: Generated ${ports.length} output ports (declared)');
      return ports;
    }

    // No declared outputs; return empty and let higher layers decide or provide outputs via properties
    debugPrint('PolyAlgorithmRouting: No declared outputs found (returning none)');
    return ports;
  }

  PortType? _parsePortType(String? name) {
    switch (name) {
      case 'audio':
        return PortType.audio;
      case 'cv':
        return PortType.cv;
      case 'gate':
        return PortType.gate;
      case 'clock':
        return PortType.clock;
    }
    return null;
  }

  @override
  bool validateConnection(Port source, Port destination) {
    // Gate connections have special rules that override base validation
    if (source.type == PortType.gate || destination.type == PortType.gate) {
      if (!_validateGateConnection(source, destination)) {
        return false;
      }
    }
    // Virtual CV connections need special handling
    else if (_isVirtualCvPort(source) || _isVirtualCvPort(destination)) {
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
      
      if (sourceVoice != null && destVoice != null && sourceVoice != destVoice) {
        debugPrint(
          'PolyAlgorithmRouting: Cross-voice connection attempted between '
          'voice $sourceVoice and voice $destVoice'
        );
        return false;
      }
    }
    
    return true;
  }
  
  @override
  void updateState(RoutingState newState) {
    _state = newState;
    
    // Clear port caches if ports have changed
    if (_state.inputPorts.isNotEmpty || _state.outputPorts.isNotEmpty) {
      _cachedInputPorts = null;
      _cachedOutputPorts = null;
    }
    
    debugPrint('PolyAlgorithmRouting: State updated');
  }
  
  /// Validates gate-specific connections
  bool _validateGateConnection(Port source, Port destination) {
    // Gate outputs can connect to gate inputs
    if (source.type == PortType.gate && destination.type == PortType.gate) {
      return source.isOutput && destination.isInput;
    }
    
    // Gate signals can also trigger CV inputs (gate-to-CV conversion)
    if (source.type == PortType.gate && destination.type == PortType.cv) {
      return source.isOutput && destination.isInput;
    }
    
    // Clock signals can trigger gates
    if (source.type == PortType.clock && destination.type == PortType.gate) {
      return source.isOutput && destination.isInput;
    }
    
    return false;
  }
  
  /// Validates virtual CV connections
  bool _validateVirtualCvConnection(Port source, Port destination) {
    // Virtual CV ports should only connect to CV or audio ports
    if (_isVirtualCvPort(source)) {
      return destination.type == PortType.cv || 
             destination.type == PortType.audio ||
             destination.type == PortType.gate;
    }
    
    if (_isVirtualCvPort(destination)) {
      return source.type == PortType.cv || 
             source.type == PortType.audio ||
             source.type == PortType.gate;
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
      _cachedInputPorts = null;
      _cachedOutputPorts = null;
      
      debugPrint(
        'PolyAlgorithmRouting: Voice count updated from ${config.voiceCount} to $newVoiceCount'
      );
    }
  }
  
  @override
  void dispose() {
    super.dispose();
    _cachedInputPorts = null;
    _cachedOutputPorts = null;
    debugPrint('PolyAlgorithmRouting: Disposed');
  }
  
  /// Determines if this routing implementation can handle the given slot.
  /// 
  /// Returns true if the algorithm GUID starts with 'py' (polysynth algorithms).
  static bool canHandle(Slot slot) {
    return slot.algorithm.guid.startsWith('py');
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
    final algId = algorithmUuid ?? 'algo_${slot.algorithm.guid}_${DateTime.now().millisecondsSinceEpoch}';
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
      if (paramName.startsWith('Gate input ') || 
          (paramName.startsWith('Gate ') && paramName.contains(' CV count'))) {
        continue;
      }
      
      // Skip unconnected parameters (bus value 0 means "None")
      if (busValue == 0) continue;
      
      // Get parameter number for unique ID generation
      final paramInfo = paramsByName[paramName];
      final paramNumber = paramInfo?.parameterNumber ?? 0;
      
      // Determine if this is an input or output based on parameter name
      final lowerName = paramName.toLowerCase();
      final isOutput = lowerName.contains('output') && !lowerName.contains('mode');
      
      // Infer port type from parameter name
      String portType = 'audio';
      if (lowerName.contains('cv') || lowerName.contains('pitchbend') || lowerName.contains('wave')) {
        portType = 'cv';
      } else if (lowerName.contains('gate') || lowerName.contains('reset') || lowerName.contains('trigger')) {
        portType = 'gate';
      } else if (lowerName.contains('clock')) {
        portType = 'clock';
      }
      
      final port = {
        'id': '${algId}_param_$paramNumber',  // Unique ID with algorithm UUID and parameter number
        'name': paramName,
        'type': portType,
        'busParam': paramName,
        'busValue': busValue,
        'parameterNumber': paramNumber,
      };
      
      if (isOutput) {
        // Add channel metadata for stereo outputs
        if (lowerName.contains('left')) {
          port['channel'] = 'left';
        } else if (lowerName.contains('right')) {
          port['channel'] = 'right';
        } else if (lowerName.contains('mono')) {
          port['channel'] = 'mono';
        }
        
        // Apply output mode if available
        if (modeParameters != null) {
          // Look for corresponding mode parameter (e.g., "Output 1 mode" for "Output 1")
          final modeName = '$paramName mode';
          if (modeParameters.containsKey(modeName)) {
            final modeValue = modeParameters[modeName];
            // 0 = Add, 1 = Replace
            if (modeValue == 1) {
              port['outputMode'] = 'replace';
            } else {
              port['outputMode'] = 'add';
            }
          }
        }
        
        // Store mode parameter number if available
        if (modeParametersWithNumbers != null) {
          final modeName = '$paramName mode';
          if (modeParametersWithNumbers.containsKey(modeName)) {
            port['modeParameterNumber'] = modeParametersWithNumbers[modeName]!.parameterNumber;
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
    
    // Create configuration for poly routing
    final config = PolyAlgorithmConfig(
      voiceCount: voiceCount,
      requiresGateInputs: true,
      usesVirtualCvPorts: false,  // Real CV ports based on gate configuration
      gateInputs: gateInputs,
      gateCvCounts: gateCvCounts,
      algorithmProperties: {
        'algorithmGuid': slot.algorithm.guid,
        'algorithmName': slot.algorithm.name,
        'algorithmUuid': algId,  // Use the ensured algorithm ID
        'extraInputs': inputPorts,  // Non-gate routing inputs
        'outputs': outputPorts,      // All output routing parameters
        'gateInputs': gateInputs,  // Store for gate port generation
        'gateCvCounts': gateCvCounts,  // Store for CV port generation
      },
    );
    
    return PolyAlgorithmRouting(config: config);
  }
}
