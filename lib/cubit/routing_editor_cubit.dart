import 'dart:async';
import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/core/routing/models/algorithm_routing_metadata.dart';
import 'package:nt_helper/services/algorithm_metadata_service.dart';
import 'package:nt_helper/models/algorithm_metadata.dart' show AlgorithmMetadata;
import 'package:nt_helper/core/routing/routing_service_locator.dart';
import 'package:nt_helper/core/routing/routing_factory.dart';
import 'package:nt_helper/core/routing/algorithm_routing.dart' as core_routing;
import 'package:nt_helper/core/routing/models/port.dart' as core_port;
import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'package:nt_helper/models/algorithm_connection.dart';
import 'package:nt_helper/models/physical_connection.dart';
import 'package:nt_helper/core/routing/services/algorithm_connection_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'routing_editor_cubit.freezed.dart';
part 'routing_editor_state.dart';

/// Cubit that manages the state of the routing editor.
/// 
/// Watches the DistingCubit's synchronized state and processes routing 
/// information into a visual representation for the routing canvas.
class RoutingEditorCubit extends Cubit<RoutingEditorState> {
  final DistingCubit _distingCubit;
  final Future<SharedPreferences> _prefs;
  final AlgorithmConnectionService _algorithmConnectionService;
  StreamSubscription<DistingState>? _distingStateSubscription;

  RoutingEditorCubit(this._distingCubit, {AlgorithmConnectionService? algorithmConnectionService}) 
      : _prefs = SharedPreferences.getInstance(),
        _algorithmConnectionService = algorithmConnectionService ?? AlgorithmConnectionService(),
        super(const RoutingEditorState.initial()) {
    _initializeStateWatcher();
    _loadPersistedState();
  }

  /// Initialize watching the disting cubit state changes
  void _initializeStateWatcher() {
    _distingStateSubscription = _distingCubit.stream.listen((distingState) {
      _processDistingState(distingState);
    });
    
    // Process current state if already synchronized
    final currentState = _distingCubit.state;
    _processDistingState(currentState);
  }

  /// Process incoming DistingState and update routing editor state accordingly
  void _processDistingState(DistingState distingState) {
    distingState.when(
      initial: () => emit(const RoutingEditorState.initial()),
      selectDevice: (inputDevices, outputDevices, canWorkOffline) => 
          emit(const RoutingEditorState.disconnected()),
      connected: (disting, inputDevice, outputDevice, offline, loading) => 
          emit(const RoutingEditorState.connecting()),
      synchronized: (disting, distingVersion, firmwareVersion, presetName, 
          algorithms, slots, unitStrings, inputDevice, outputDevice, 
          loading, offline, screenshot, demo, videoStream) {
        _processSynchronizedState(slots);
      },
    );
  }

  /// Extract routing data from synchronized state and build visual representation.
  /// 
  /// This method implements performance optimization by only being called when the 
  /// DistingCubit's synchronized state changes, ensuring physical connection discovery 
  /// only runs when algorithm parameters or slots change, not on every UI rebuild.
  void _processSynchronizedState(List<Slot> slots) {
    try {
      // Create physical hardware ports
      final physicalInputs = _createPhysicalInputPorts();
      final physicalOutputs = _createPhysicalOutputPorts(); 
      
      // Build algorithm representations with ports determined by AlgorithmRouting
      final algorithms = <RoutingAlgorithm>[];
      final allPhysicalConnections = <PhysicalConnection>[];
      final RoutingFactory factory = RoutingServiceLocator.routingFactory;
      
      // Generate UUIDs for each algorithm instance
      final algorithmUuids = <String>[];
      for (int i = 0; i < slots.length; i++) {
        // Use a combination of slot index and algorithm guid as a stable identifier
        // This will remain stable during the session
        algorithmUuids.add('algo_${i}_${slots[i].algorithm.guid}');
      }
      
      for (int i = 0; i < slots.length; i++) {
        final slot = slots[i];
        final algorithmUuid = algorithmUuids[i];

        // Build metadata for this slot purely from slot parameters (data-driven)
        final metadata = _buildMetadataForSlot(slot);

        // Create routing and generate ports
        core_routing.AlgorithmRouting routing;
        try {
          routing = factory.createValidatedRouting(metadata);
        } catch (_) {
          // If metadata fails validation, fall back to a minimal node with no ports
          routing = factory.createRouting(metadata);
        }

        final inputPorts = routing.inputPorts;
        final outputPorts = routing.outputPorts;

        final routingAlgorithm = RoutingAlgorithm(
          index: i,
          algorithm: slot.algorithm,
          // Convert core ports to UI model ports
          inputPorts: inputPorts
              .map((p) => Port(
                    id: p.id,
                    name: p.name,
                    type: _toUiPortType(p.type),
                    direction: PortDirection.input,
                    busNumber: _getBusNumberForPort(p, slot),
                    parameterName: p.metadata?['busParam'] as String?,
                  ))
              .toList(),
          outputPorts: outputPorts
              .map((p) => Port(
                    id: p.id,
                    name: p.name,
                    type: _toUiPortType(p.type),
                    direction: PortDirection.output,
                    busNumber: _getBusNumberForPort(p, slot),
                    parameterName: p.metadata?['busParam'] as String?,
                  ))
              .toList(),
        );
        algorithms.add(routingAlgorithm);
        
        // Discover physical connections for this algorithm
        final algorithmPhysicalConnections = _createPhysicalConnectionsForAlgorithm(routing, slot, i);
        allPhysicalConnections.addAll(algorithmPhysicalConnections);
      }
      
      // Sort all physical connections globally for stable presentation:
      // 1. By algorithm index
      // 2. By connection type (input connections first)
      // 3. By source port ID, then target port ID
      allPhysicalConnections.sort((a, b) {
        // First, sort by algorithm index
        final algorithmComparison = a.algorithmIndex.compareTo(b.algorithmIndex);
        if (algorithmComparison != 0) {
          return algorithmComparison;
        }
        // Within same algorithm, input connections before output connections
        if (a.isInputConnection != b.isInputConnection) {
          return a.isInputConnection ? -1 : 1;
        }
        // Within same connection type, sort by source port ID
        final sourceComparison = a.sourcePortId.compareTo(b.sourcePortId);
        if (sourceComparison != 0) {
          return sourceComparison;
        }
        // If source ports are same, sort by target port ID
        return a.targetPortId.compareTo(b.targetPortId);
      });
      
      // Build connections directly from parameter bus assignments
      final algorithmConnections = _buildConnectionsFromBusAssignments(slots, algorithmUuids, algorithms);
      
      // No user connections for now - will be handled by AlgorithmRouting hierarchy
      final connections = <Connection>[];

      emit(RoutingEditorState.loaded(
        physicalInputs: physicalInputs,
        physicalOutputs: physicalOutputs,
        algorithms: algorithms,
        connections: connections,
        physicalConnections: allPhysicalConnections,
        algorithmConnections: algorithmConnections,
        isHardwareSynced: true,
        lastSyncTime: DateTime.now(),
      ));

      // Initialize default buses after loading (fire and forget)
      initializeDefaultBuses();
    } catch (e) {
      debugPrint('Error processing synchronized state: $e');
      emit(RoutingEditorState.error('Failed to process routing data: $e'));
    }
  }

  /// Discover algorithm-to-algorithm connections from slots.
  /// 
  /// Uses the AlgorithmConnectionService to identify connections between
  /// algorithm slots based on shared bus assignments.
  List<AlgorithmConnection> _discoverAlgorithmConnections(List<Slot> slots) {
    try {
      debugPrint('RoutingEditorCubit: Discovering algorithm connections for ${slots.length} slots');
      final connections = _algorithmConnectionService.discoverAlgorithmConnections(slots);
      debugPrint('RoutingEditorCubit: Found ${connections.length} algorithm connections');
      return connections;
    } catch (e) {
      debugPrint('RoutingEditorCubit: Error discovering algorithm connections: $e');
      // Return empty list on error to avoid breaking the state emission
      return [];
    }
  }
  
  /// Build connections directly from parameter bus assignments
  List<AlgorithmConnection> _buildConnectionsFromBusAssignments(
    List<Slot> slots,
    List<String> algorithmUuids,
    List<RoutingAlgorithm> algorithms,
  ) {
    debugPrint('_buildConnectionsFromBusAssignments called with ${slots.length} slots');
    final connections = <AlgorithmConnection>[];
    
    // Map bus number to list of (algorithm index, parameter, is output)
    final busMap = <int, List<({int algoIndex, String portId, String paramName, bool isOutput})>>{};
    
    for (int i = 0; i < slots.length; i++) {
      final slot = slots[i];
      final algorithmUuid = algorithmUuids[i];
      final algorithm = algorithms[i];
      
      debugPrint('Processing slot $i: ${slot.algorithm.name}, ${slot.parameters.length} parameters');
      
      // Get current parameter values
      final valueByParam = <int, int>{
        for (final v in slot.values) v.parameterNumber: v.value,
      };
      
      // Check each parameter to see if it's a routing parameter with a bus assignment
      for (final param in slot.parameters) {
        // Bus parameters are identified by:
        // - unit == 1 (enum type)
        // - min is 0 or 1
        // - max is 27 or 28
        final isBusParameter = param.unit == 1 && 
            (param.min == 0 || param.min == 1) &&
            (param.max == 27 || param.max == 28);
        
        // Debug: show parameters that look like they might be bus parameters
        if (param.name.toLowerCase().contains('input') || param.name.toLowerCase().contains('output')) {
          debugPrint('Checking param ${param.name}: unit=${param.unit}, min=${param.min}, max=${param.max}, isBus=$isBusParameter');
        }
        
        if (!isBusParameter) continue;
        
        debugPrint('Found bus parameter: ${param.name} (param ${param.parameterNumber})');
        
        final value = valueByParam[param.parameterNumber] ?? param.defaultValue;
        if (value < 1 || value > 28) continue; // Not connected to a bus
        
        final paramNameLower = param.name.toLowerCase();
        final isOutput = paramNameLower.contains('output') && !paramNameLower.contains('mode');
        final isInput = !isOutput; // If it's a bus param and not output, it's input
        
        {
          // Find the corresponding port in the algorithm
          final portId = isOutput 
              ? algorithm.outputPorts.firstWhere(
                  (p) => p.parameterName == param.name,
                  orElse: () => algorithm.outputPorts.first,
                ).id
              : algorithm.inputPorts.firstWhere(
                  (p) => p.parameterName == param.name,
                  orElse: () => algorithm.inputPorts.first,
                ).id;
          
          busMap.putIfAbsent(value, () => []).add((
            algoIndex: i,
            portId: portId,
            paramName: param.name,
            isOutput: isOutput,
          ));
          
          debugPrint('Bus $value: ${isOutput ? "Output" : "Input"} ${param.name} from algo $i (port $portId)');
        }
      }
    }
    
    // Create connections for each bus
    for (final entry in busMap.entries) {
      final busNumber = entry.key;
      final ports = entry.value;
      
      final outputs = ports.where((p) => p.isOutput).toList();
      final inputs = ports.where((p) => !p.isOutput).toList();
      
      // Connect each output to each input on the same bus
      for (final output in outputs) {
        for (final input in inputs) {
          if (output.algoIndex != input.algoIndex) {
            final connection = AlgorithmConnection.withGeneratedId(
              sourceAlgorithmIndex: output.algoIndex,
              sourcePortId: output.portId,
              targetAlgorithmIndex: input.algoIndex,
              targetPortId: input.portId,
              busNumber: busNumber,
              connectionType: _inferConnectionType(output.paramName, input.paramName),
              edgeLabel: 'Bus $busNumber',
            );
            connections.add(connection);
            debugPrint('Created connection: Algo ${output.algoIndex} ${output.paramName} -> Algo ${input.algoIndex} ${input.paramName} via bus $busNumber');
          }
        }
      }
    }
    
    return connections;
  }
  
  /// Infer connection type from port names
  AlgorithmConnectionType _inferConnectionType(String outputName, String inputName) {
    final lowerOut = outputName.toLowerCase();
    final lowerIn = inputName.toLowerCase();
    
    if (lowerOut.contains('gate') || lowerIn.contains('gate')) {
      return AlgorithmConnectionType.gateTrigger;
    }
    if (lowerOut.contains('clock') || lowerIn.contains('clock')) {
      return AlgorithmConnectionType.clockTiming;
    }
    if (lowerOut.contains('cv') || lowerIn.contains('cv')) {
      return AlgorithmConnectionType.controlVoltage;
    }
    if (lowerOut.contains('audio') || lowerIn.contains('audio')) {
      return AlgorithmConnectionType.audioSignal;
    }
    
    return AlgorithmConnectionType.mixed;
  }

  /// Build routing metadata for a poly/multi algorithm from Slot parameters
  AlgorithmRoutingMetadata _buildMetadataForSlot(Slot slot) {
    // Data-driven poly detection
    final isPoly = slot.parameters.any((p) => p.name.startsWith('Gate input 1')) ||
        slot.parameters.any((p) => p.name.contains('Gate 1 CV count'));

    // Build value lookup
    final Map<int, int> valueByParam = {
      for (final v in slot.values) v.parameterNumber: v.value,
    };
    int valueFor(String name) {
      final pi = slot.parameters.firstWhere(
        (p) => p.name == name,
        orElse: () => ParameterInfo.filler(),
      );
      if (pi.parameterNumber < 0) return 0;
      return valueByParam[pi.parameterNumber] ?? pi.defaultValue;
    }

    if (isPoly) {
      // Gate-driven CV pattern
      final List<int> gateInputs = List<int>.generate(6, (i) => valueFor('Gate input ${i + 1}'));
      while (gateInputs.isNotEmpty && gateInputs.last == 0) {
        gateInputs.removeLast();
      }
      final List<int> gateCvCounts = List<int>.generate(6, (i) => valueFor('Gate ${i + 1} CV count'))
          .take(gateInputs.length)
          .toList();

      // Extra inputs
      final paramNames = slot.parameters.map((p) => p.name).toSet();
      final List<Map<String, Object?>> extraInputs = [];
      void addExtra(String paramName, String displayName, String type) {
        extraInputs.add({
          'id': 'in_${paramName.replaceAll(' ', '_').toLowerCase()}',
          'name': displayName,
          'type': type,
          'busParam': paramName,
        });
      }
      if (paramNames.contains('Wave input')) addExtra('Wave input', 'Wave CV Input', 'cv');
      if (paramNames.contains('Pitchbend input')) addExtra('Pitchbend input', 'Pitchbend CV Input', 'cv');
      if (paramNames.contains('Root CV')) addExtra('Root CV', 'Root CV', 'cv');
      if (paramNames.contains('Arp reset')) addExtra('Arp reset', 'Arp Reset', 'gate');
      if (paramNames.contains('Audio input')) addExtra('Audio input', 'Audio Input', 'audio');

      // Outputs
      final List<Map<String, Object?>> outputs = [];
      void addOutput(String paramName, String displayName, {String type = 'audio', String? channel}) {
        outputs.add({
          'id': 'out_${displayName.replaceAll(' ', '_').toLowerCase()}',
          'name': displayName,
          'type': type,
          'busParam': paramName,
          if (channel != null) 'channel': channel,
        });
      }
      if (paramNames.contains('Left output') || paramNames.contains('Left/mono output')) {
        if (paramNames.contains('Left/mono output')) {
          addOutput('Left/mono output', 'Left/Mono Output', channel: 'left');
        } else {
          addOutput('Left output', 'Left Output', channel: 'left');
        }
      }
      if (paramNames.contains('Right output')) addOutput('Right output', 'Right Output', channel: 'right');
      if (paramNames.contains('Output bus')) addOutput('Output bus', 'Audio Output');
      if (paramNames.contains('Odd output')) addOutput('Odd output', 'Odd Output');
      if (paramNames.contains('Even output')) addOutput('Even output', 'Even Output');

      // Voice count from slot parameters if present (not required for ports)
      int voiceCount = 1;
      final maxVoicesParam = slot.parameters.firstWhere(
        (p) => p.name == 'Max voices',
        orElse: () => ParameterInfo.filler(),
      );
      final voicesParam = slot.parameters.firstWhere(
        (p) => p.name == 'Voices',
        orElse: () => ParameterInfo.filler(),
      );
      if (maxVoicesParam.parameterNumber >= 0) {
        voiceCount = valueByParam[maxVoicesParam.parameterNumber] ?? maxVoicesParam.defaultValue;
      } else if (voicesParam.parameterNumber >= 0) {
        voiceCount = valueByParam[voicesParam.parameterNumber] ?? voicesParam.defaultValue;
      }

      return AlgorithmRoutingMetadata(
        algorithmGuid: slot.algorithm.guid,
        algorithmName: slot.algorithm.name,
        routingType: RoutingType.polyphonic,
        voiceCount: voiceCount,
        requiresGateInputs: true,
        usesVirtualCvPorts: false,
        supportedPortTypes: const ['audio', 'cv', 'gate'],
        customProperties: {
          'gateInputs': gateInputs,
          'gateCvCounts': gateCvCounts,
          'extraInputs': extraInputs,
          'outputs': outputs,
        },
      );
    }

    // Non-poly: build from algorithm metadata + parameter names; honor 'Width' parameter if present
    final metaSvc = AlgorithmMetadataService();
    final AlgorithmMetadata? meta = metaSvc.getAlgorithmByGuid(slot.algorithm.guid);

    // Helper: map param names for quick lookup and value accessor
    final Map<String, ParameterInfo> paramsByName = {
      for (final p in slot.parameters) p.name: p,
    };

    int? _getIntValue(String name) {
      final pi = paramsByName[name];
      if (pi == null || pi.parameterNumber < 0) return null;
      final Map<int, int> valueByParam = {for (final v in slot.values) v.parameterNumber: v.value};
      return valueByParam[pi.parameterNumber] ?? pi.defaultValue;
    }

    // Derive declared inputs from metadata, using parameter names when available
    final List<Map<String, Object?>> declaredInputs = [];
    if (meta != null && meta.inputPorts.isNotEmpty) {
      for (final ip in meta.inputPorts) {
        final busRef = ip.busIdRef;
        final labelFromParam = busRef != null && paramsByName.containsKey(busRef) ? busRef : null;
        final label = labelFromParam ?? ip.name;
        String type = 'audio';
        final lower = label.toLowerCase();
        if (lower.contains('trigger') || lower.contains('mark') || lower.contains('stop')) type = 'gate';
        else if (lower.contains('cv')) type = 'cv';
        final inputMap = <String, Object?>{
          'id': 'in_${label.replaceAll(' ', '_').toLowerCase()}',
          'name': label,
          'type': type,
          if (busRef != null) 'busParam': busRef,
        };
        // Fallback: if metadata lacks busRef, try to match a parameter with same/similar name
        if (busRef == null) {
          final p = _findParameterByName(slot, label);
          if (p != null && p.parameterNumber >= 0) {
            inputMap['busParam'] = p.name;
          }
        }
        declaredInputs.add(inputMap);
      }
    }

    // Derive outputs from metadata similarly (fallback to parameter names)
    final List<Map<String, Object?>> declaredOutputs = [];
    if (meta != null && meta.outputPorts.isNotEmpty) {
      for (final op in meta.outputPorts) {
        final busRef = op.busIdRef;
        final labelFromParam = busRef != null && paramsByName.containsKey(busRef) ? busRef : null;
        final label = labelFromParam ?? op.name;
        final outMap = <String, Object?>{
          'id': 'out_${label.replaceAll(' ', '_').toLowerCase()}',
          'name': label,
          'type': 'audio',
          if (busRef != null) 'busParam': busRef,
        };
        // Fallback: if metadata lacks busRef, try to match by parameter name
        if (busRef == null) {
          final p = _findParameterByName(slot, label);
          if (p != null && p.parameterNumber >= 0) {
            outMap['busParam'] = p.name;
          }
        }
        declaredOutputs.add(outMap);
      }
    }

    // Fallback: if metadata lacked some ports or didn't provide busRef, synthesize from parameters
    // Inputs from parameter names (e.g., "Pitch input", "Wave input", "Gate input")
    for (final entry in paramsByName.entries) {
      final pname = entry.key;
      final lower = pname.toLowerCase();
      final hasInputWord = lower.contains('input');
      final looksLikeBus = hasInputWord && !lower.contains('mode');
      if (looksLikeBus) {
        final already = declaredInputs.any((m) => (m['name'] as String).toLowerCase() == lower);
        if (!already) {
          String type = 'audio';
          if (lower.contains('cv')) type = 'cv';
          if (lower.contains('gate') || lower.contains('trigger')) type = 'gate';
          declaredInputs.add({
            'id': 'in_${pname.replaceAll(' ', '_').toLowerCase()}',
            'name': pname,
            'type': type,
            'busParam': pname,
          });
        } else {
          // Ensure existing record has busParam
          final idx = declaredInputs.indexWhere((m) => (m['name'] as String).toLowerCase() == lower);
          if (idx >= 0 && declaredInputs[idx]['busParam'] == null) {
            declaredInputs[idx]['busParam'] = pname;
          }
        }
      }
    }

    // Outputs from parameter names (e.g., "Left output", "Right output", "Output", "Output bus")
    for (final entry in paramsByName.entries) {
      final pname = entry.key;
      final lower = pname.toLowerCase();
      final hasOutputWord = lower.contains('output');
      final looksLikeBus = hasOutputWord && !lower.contains('mode');
      if (looksLikeBus) {
        final already = declaredOutputs.any((m) => (m['name'] as String).toLowerCase() == lower);
        if (!already) {
          declaredOutputs.add({
            'id': 'out_${pname.replaceAll(' ', '_').toLowerCase()}',
            'name': pname,
            'type': 'audio',
            'busParam': pname,
          });
        } else {
          final idx = declaredOutputs.indexWhere((m) => (m['name'] as String).toLowerCase() == lower);
          if (idx >= 0 && declaredOutputs[idx]['busParam'] == null) {
            declaredOutputs[idx]['busParam'] = pname;
          }
        }
      }
    }

    // Handle width: limit audio inputs to specified count if present
    final int? width = _getIntValue('Width') ?? _getIntValue('width');
    if (width != null && width > 0) {
      // Prefer known stereo labels when width==1 or 2
      List<Map<String, Object?>> audioInputs = declaredInputs.where((m) => (m['type'] as String) == 'audio').toList();

      String baseAudioName = 'Audio';

      if (audioInputs.isEmpty) {
        // Synthesize: "Audio", "Audio 2", ...
        audioInputs = List.generate(width, (i) => {
          'id': 'in_${i + 1}',
          'name': i == 0 ? baseAudioName : '$baseAudioName ${i + 1}',
          'type': 'audio',
        });
      } else {
        if (width == 1 && audioInputs.length >= 1) {
          // Prefer Left/mono for mono
          audioInputs = [
            audioInputs.firstWhere(
              (m) => (m['name'] as String).toLowerCase().contains('left/mono'),
              orElse: () => audioInputs.first,
            )
          ];
        } else if (width == 2 && audioInputs.length >= 2) {
          // Try to pick left/mono + right if available
          final left = audioInputs.firstWhere(
            (m) => (m['name'] as String).toLowerCase().contains('left/mono') || (m['name'] as String).toLowerCase().contains('left '),
            orElse: () => audioInputs.first,
          );
          final right = audioInputs.firstWhere(
            (m) => (m['name'] as String).toLowerCase().contains('right '),
            orElse: () => audioInputs.length > 1 ? audioInputs[1] : audioInputs.first,
          );
          audioInputs = [left, right];
        }

        // If width exceeds declared inputs, pad using base name rules
        if (audioInputs.length < width) {
          final firstName = (audioInputs.first['name'] as String).trim();
          final firstIsAudio = firstName.toLowerCase() == 'audio';
          baseAudioName = firstIsAudio ? 'Audio' : 'Audio'; // default to 'Audio' for padding

          for (int i = audioInputs.length; i < width; i++) {
            final idx = i + 1;
            final name = idx == 1 && firstIsAudio ? baseAudioName : '$baseAudioName $idx';
            // Avoid duplicating the first if it's already 'Audio'
            if (idx == 1 && !firstIsAudio) {
              // keep existing firstName; continue to next index
              continue;
            }
            audioInputs.add({
              'id': 'in_$idx',
              'name': name,
              'type': 'audio',
            });
          }
        } else if (audioInputs.length > width) {
          audioInputs = audioInputs.take(width).toList();
        }
      }
      // Merge back: keep non-audio inputs, replace audio inputs with constrained list
      final nonAudio = declaredInputs.where((m) => (m['type'] as String) != 'audio');
      declaredInputs
        ..clear()
        ..addAll(audioInputs)
        ..addAll(nonAudio);
    }

    return AlgorithmRoutingMetadata(
      algorithmGuid: slot.algorithm.guid,
      algorithmName: slot.algorithm.name,
      routingType: RoutingType.multiChannel,
      channelCount: (width != null && width > 0) ? width : 1,
      supportsStereo: (width ?? 1) == 2,
      allowsIndependentChannels: true,
      createMasterMix: false,
      portNamePrefix: 'Main',
      supportedPortTypes: const ['audio', 'cv', 'gate'],
      customProperties: {
        if (declaredInputs.isNotEmpty) 'inputs': declaredInputs,
        if (declaredOutputs.isNotEmpty) 'outputs': declaredOutputs,
      },
    );
  }

  /// Convert core port type (routing) to UI port type
  PortType _toUiPortType(core_port.PortType type) {
    switch (type) {
      case core_port.PortType.audio:
        return PortType.audio;
      case core_port.PortType.cv:
        return PortType.cv;
      case core_port.PortType.gate:
        return PortType.gate;
      case core_port.PortType.clock:
        return PortType.trigger; // closest match in UI enum
    }
  }

  /// Create the 12 physical input ports of the Disting NT
  List<Port> _createPhysicalInputPorts() {
    return [
      // Audio inputs
      const Port(id: 'hw_in_1', name: 'Audio In 1', type: PortType.audio, direction: PortDirection.input),
      const Port(id: 'hw_in_2', name: 'Audio In 2', type: PortType.audio, direction: PortDirection.input),
      // CV inputs
      const Port(id: 'hw_in_3', name: 'CV 1', type: PortType.cv, direction: PortDirection.input),
      const Port(id: 'hw_in_4', name: 'CV 2', type: PortType.cv, direction: PortDirection.input),
      const Port(id: 'hw_in_5', name: 'CV 3', type: PortType.cv, direction: PortDirection.input),
      const Port(id: 'hw_in_6', name: 'CV 4', type: PortType.cv, direction: PortDirection.input),
      const Port(id: 'hw_in_7', name: 'CV 5', type: PortType.cv, direction: PortDirection.input),
      const Port(id: 'hw_in_8', name: 'CV 6', type: PortType.cv, direction: PortDirection.input),
      // Gate inputs
      const Port(id: 'hw_in_9', name: 'Gate 1', type: PortType.gate, direction: PortDirection.input),
      const Port(id: 'hw_in_10', name: 'Gate 2', type: PortType.gate, direction: PortDirection.input),
      // Trigger inputs
      const Port(id: 'hw_in_11', name: 'Trigger 1', type: PortType.trigger, direction: PortDirection.input),
      const Port(id: 'hw_in_12', name: 'Trigger 2', type: PortType.trigger, direction: PortDirection.input),
    ];
  }

  /// Create the 8 physical output ports of the Disting NT
  List<Port> _createPhysicalOutputPorts() {
    return [
      const Port(id: 'hw_out_1', name: 'Audio Out 1', type: PortType.audio, direction: PortDirection.output),
      const Port(id: 'hw_out_2', name: 'Audio Out 2', type: PortType.audio, direction: PortDirection.output),
      const Port(id: 'hw_out_3', name: 'Audio Out 3', type: PortType.audio, direction: PortDirection.output),
      const Port(id: 'hw_out_4', name: 'Audio Out 4', type: PortType.audio, direction: PortDirection.output),
      const Port(id: 'hw_out_5', name: 'Audio Out 5', type: PortType.audio, direction: PortDirection.output),
      const Port(id: 'hw_out_6', name: 'Audio Out 6', type: PortType.audio, direction: PortDirection.output),
      const Port(id: 'hw_out_7', name: 'Audio Out 7', type: PortType.audio, direction: PortDirection.output),
      const Port(id: 'hw_out_8', name: 'Audio Out 8', type: PortType.audio, direction: PortDirection.output),
    ];
  }

  /// Resolve the bus number for a given port based on its metadata and slot parameters.
  /// 
  /// Returns the bus number (1-12 for inputs, 13-20 for outputs) or null if no bus is assigned.
  /// 
  /// Resolution strategy:
  /// 1. Check port.metadata['busParam'] and lookup in slot parameters
  /// 2. Fall back to poly gate/CV logic if applicable
  /// 3. Handle edge cases: bus 0 ("None"), missing params, invalid ranges
  int? _getBusNumberForPort(core_port.Port port, Slot slot) {
    // Strategy 1: Use busParam from port metadata
    final busParam = port.metadata?['busParam'] as String?;
    if (busParam != null) {
      // Find the parameter in the slot (robust match)
      final paramInfo = _findParameterByName(slot, busParam);
      if (paramInfo != null && paramInfo.parameterNumber >= 0) {
        // Get the current value for this parameter
        final paramValue = slot.values
            .where((v) => v.parameterNumber == paramInfo.parameterNumber)
            .firstOrNull;
        
        // Only use explicitly set parameter values, not defaults
        // This prevents physical connections from being created based on parameter defaults
        final busValue = paramValue?.value ?? 0; // Default to 0 (None) if not explicitly set
        
        // Validate bus number range
        if (busValue > 0 && busValue <= 20) {
          return busValue;
        }
        // Bus 0 means "None" - no physical connection
        if (busValue == 0) {
          return null;
        }
      }
    }

    // Strategy 2: Fall back to polyphonic gate/CV logic
    if (port.metadata?['isGateInput'] == true) {
      // For gate inputs, use the gateBus from metadata
      final gateBus = port.metadata?['gateBus'] as int?;
      if (gateBus != null && gateBus > 0 && gateBus <= 12) {
        return gateBus;
      }
    }

    // CV inputs: for poly, CV ports immediately follow the gate bus.
    // PolyAlgorithmRouting sets metadata {'isGateDrivenCV': true, 'suggestedBus': gateBus + cvNumber}
    // Also honor a generic 'suggestedBus' even without the flag, to support other sources.
    final isGateDrivenCv = port.metadata?['isGateDrivenCV'] == true;
    final suggestedBus = port.metadata?['suggestedBus'] as int?;
    if (isGateDrivenCv || suggestedBus != null) {
      if (suggestedBus != null && suggestedBus > 0 && suggestedBus <= 12) {
        return suggestedBus;
      }
    }

    // Strategy 3: No bus assignment found
    return null;
  }

  /// Tries to find a parameter by name with tolerant matching.
  /// 1) Exact match
  /// 2) Case-insensitive match
  /// 3) Normalized match (strip non-alphanum, collapse spaces)
  /// 4) Contains match on normalized names
  ParameterInfo? _findParameterByName(Slot slot, String name) {
    // Exact
    final exact = slot.parameters.where((p) => p.name == name).firstOrNull;
    if (exact != null) return exact;

    final targetNorm = _normalizeName(name);

    // Case-insensitive
    final ci = slot.parameters
        .where((p) => p.name.toLowerCase() == name.toLowerCase())
        .firstOrNull;
    if (ci != null) return ci;

    // Normalized equality
    final normEq = slot.parameters
        .where((p) => _normalizeName(p.name) == targetNorm)
        .firstOrNull;
    if (normEq != null) return normEq;

    // Contains (either direction) on normalized strings
    final contains = slot.parameters
        .where((p) {
          final pn = _normalizeName(p.name);
          return pn.contains(targetNorm) || targetNorm.contains(pn);
        })
        .firstOrNull;
    return contains;
  }

  String _normalizeName(String s) {
    return s
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Discover physical input connections from hardware inputs (buses 1-12) to algorithm input ports.
  /// 
  /// Returns a list of PhysicalConnection instances representing connections from physical
  /// hardware jacks to algorithm input ports based on bus assignments.
  List<PhysicalConnection> _createPhysicalInputConnections(
    core_routing.AlgorithmRouting routing,
    Slot slot,
    int algorithmIndex,
  ) {
    final connections = <PhysicalConnection>[];
    
    // Get all input ports from the algorithm routing
    final inputPorts = routing.inputPorts;
    
    for (final port in inputPorts) {
      // Resolve the bus number for this port
      final busNumber = _getBusNumberForPort(port, slot);
      
      // Only create connections for valid input buses (1-12)
      if (busNumber != null && busNumber >= 1 && busNumber <= 12) {
        // Map bus number to hardware input port ID
        final hardwarePortId = 'hw_in_$busNumber';
        
        // Create the physical connection
        final connection = PhysicalConnection.withGeneratedId(
          sourcePortId: hardwarePortId,
          targetPortId: port.id,
          busNumber: busNumber,
          isInputConnection: true,
          algorithmIndex: algorithmIndex,
        );
        
        connections.add(connection);
      }
    }
    
    return connections;
  }

  /// Discover physical output connections from algorithm output ports to hardware outputs (buses 13-20).
  /// 
  /// Returns a list of PhysicalConnection instances representing connections from algorithm
  /// output ports to physical hardware jacks based on bus assignments.
  List<PhysicalConnection> _createPhysicalOutputConnections(
    core_routing.AlgorithmRouting routing,
    Slot slot,
    int algorithmIndex,
  ) {
    final connections = <PhysicalConnection>[];
    
    // Get all output ports from the algorithm routing
    final outputPorts = routing.outputPorts;
    
    for (final port in outputPorts) {
      // Resolve the bus number for this port
      final busNumber = _getBusNumberForPort(port, slot);
      
      // Only create connections for valid output buses (13-20)
      if (busNumber != null && busNumber >= 13 && busNumber <= 20) {
        // Map bus number to hardware output port ID (13->1, 14->2, ..., 20->8)
        final hardwarePortNumber = busNumber - 12;
        final hardwarePortId = 'hw_out_$hardwarePortNumber';
        
        // Create the physical connection
        final connection = PhysicalConnection.withGeneratedId(
          sourcePortId: port.id,
          targetPortId: hardwarePortId,
          busNumber: busNumber,
          isInputConnection: false,
          algorithmIndex: algorithmIndex,
        );
        
        connections.add(connection);
      }
    }
    
    return connections;
  }

  /// Create physical connections for a single algorithm by combining input and output discovery.
  /// 
  /// This is the integrated method that combines both input and output physical connection
  /// discovery for a given algorithm, providing a complete view of its physical routing.
  /// 
  /// Returns a list of PhysicalConnection instances sorted by connection type and port ID
  /// for stable diffing and consistent UI presentation.
  List<PhysicalConnection> _createPhysicalConnectionsForAlgorithm(
    core_routing.AlgorithmRouting routing,
    Slot slot,
    int algorithmIndex,
  ) {
    final connections = <PhysicalConnection>[];
    
    // Discover input connections (physical inputs to algorithm inputs)
    connections.addAll(_createPhysicalInputConnections(routing, slot, algorithmIndex));
    
    // Discover output connections (algorithm outputs to physical outputs)
    connections.addAll(_createPhysicalOutputConnections(routing, slot, algorithmIndex));
    
    // Sort connections for stable presentation:
    // 1. Input connections first, then output connections
    // 2. Within each type, sort by source port ID then target port ID
    connections.sort((a, b) {
      // Input connections before output connections
      if (a.isInputConnection != b.isInputConnection) {
        return a.isInputConnection ? -1 : 1;
      }
      // Within same connection type, sort by source port ID
      final sourceComparison = a.sourcePortId.compareTo(b.sourcePortId);
      if (sourceComparison != 0) {
        return sourceComparison;
      }
      // If source ports are same, sort by target port ID
      return a.targetPortId.compareTo(b.targetPortId);
    });
    
    return connections;
  }

  /// Create a new connection between source and target ports
  Future<void> createConnection({
    required String sourcePortId,
    required String targetPortId,
    String? busId,
    OutputMode outputMode = OutputMode.replace,
    double gain = 1.0,
  }) async {
    final currentState = state;
    if (currentState is! RoutingEditorStateLoaded) {
      debugPrint('Cannot create connection - routing editor not loaded');
      return;
    }

    try {
      // Validate ports exist
      final sourcePort = _findPortById(currentState, sourcePortId);
      final targetPort = _findPortById(currentState, targetPortId);
      
      if (sourcePort == null) {
        debugPrint('Source port not found: $sourcePortId');
        emit(RoutingEditorState.error('Source port not found: $sourcePortId'));
        return;
      }
      
      if (targetPort == null) {
        debugPrint('Target port not found: $targetPortId');
        emit(RoutingEditorState.error('Target port not found: $targetPortId'));
        return;
      }

      // Validate port compatibility
      if (!_canConnect(sourcePort, targetPort)) {
        debugPrint('Ports are not compatible for connection: $sourcePortId -> $targetPortId');
        emit(RoutingEditorState.error('Incompatible ports: ${sourcePort.name} -> ${targetPort.name}'));
        return;
      }

      // Check for duplicate connections
      final existingConnection = _findExistingConnection(currentState, sourcePortId, targetPortId);
      if (existingConnection != null) {
        debugPrint('Connection already exists: $sourcePortId -> $targetPortId');
        emit(RoutingEditorState.error('Connection already exists'));
        return;
      }

      // Generate unique connection ID
      final connectionId = 'conn_${sourcePortId}_${targetPortId}_${DateTime.now().millisecondsSinceEpoch}';
      
      // Determine if this is a ghost connection (algorithm output to physical input)
      final isGhostConnection = _isGhostConnection(sourcePort, targetPort);
      
      // Create new connection
      final newConnection = Connection(
        id: connectionId,
        sourcePortId: sourcePortId,
        targetPortId: targetPortId,
        busId: busId,
        outputMode: outputMode,
        gain: gain,
        isGhostConnection: isGhostConnection,
        createdAt: DateTime.now(),
      );

      // Update state with new connection
      final updatedConnections = [...currentState.connections, newConnection];
      
      emit(currentState.copyWith(
        connections: updatedConnections,
        lastError: null,
      ));

      debugPrint('Connection created: ${sourcePort.name} -> ${targetPort.name}');
      
      // Mark hardware as out of sync after local changes
      await _autoSyncToHardware();
      
    } catch (e) {
      debugPrint('Error creating connection: $e');
      emit(RoutingEditorState.error('Failed to create connection: $e'));
    }
  }

  /// Delete an existing connection by ID
  Future<void> deleteConnection(String connectionId) async {
    final currentState = state;
    if (currentState is! RoutingEditorStateLoaded) {
      debugPrint('Cannot delete connection - routing editor not loaded');
      return;
    }

    try {
      // Find the connection to delete
      final connectionToDelete = currentState.connections.firstWhere(
        (connection) => connection.id == connectionId,
        orElse: () => throw ArgumentError('Connection not found: $connectionId'),
      );

      // Remove connection from state
      final updatedConnections = currentState.connections
          .where((connection) => connection.id != connectionId)
          .toList();

      // Update bus if connection was assigned to one
      List<RoutingBus> updatedBuses = currentState.buses;
      if (connectionToDelete.busId != null) {
        updatedBuses = currentState.buses.map((bus) {
          if (bus.id == connectionToDelete.busId) {
            final updatedConnectionIds = bus.connectionIds
                .where((id) => id != connectionId)
                .toList();
            return bus.copyWith(
              connectionIds: updatedConnectionIds,
              status: updatedConnectionIds.isEmpty ? BusStatus.available : BusStatus.assigned,
              modifiedAt: DateTime.now(),
            );
          }
          return bus;
        }).toList();
      }

      emit(currentState.copyWith(
        connections: updatedConnections,
        buses: updatedBuses,
        lastError: null,
      ));

      final sourcePort = _findPortById(currentState, connectionToDelete.sourcePortId);
      final targetPort = _findPortById(currentState, connectionToDelete.targetPortId);
      debugPrint('Connection deleted: ${sourcePort?.name} -> ${targetPort?.name}');
      
      // Mark hardware as out of sync after local changes
      await _autoSyncToHardware();
      
    } catch (e) {
      debugPrint('Error deleting connection: $e');
      emit(RoutingEditorState.error('Failed to delete connection: $e'));
    }
  }

  /// Delete all connections for a specific port
  Future<void> deleteConnectionsForPort(String portId) async {
    final currentState = state;
    if (currentState is! RoutingEditorStateLoaded) {
      debugPrint('Cannot delete connections - routing editor not loaded');
      return;
    }

    try {
      final connectionsToDelete = currentState.connections
          .where((connection) => 
              connection.sourcePortId == portId || connection.targetPortId == portId)
          .toList();

      if (connectionsToDelete.isEmpty) {
        debugPrint('No connections found for port: $portId');
        return;
      }

      // Delete each connection
      for (final connection in connectionsToDelete) {
        await deleteConnection(connection.id);
      }

      debugPrint('Deleted ${connectionsToDelete.length} connections for port: $portId');
      
    } catch (e) {
      debugPrint('Error deleting connections for port: $e');
      emit(RoutingEditorState.error('Failed to delete connections for port: $e'));
    }
  }

  /// Update an existing connection's properties
  Future<void> updateConnection({
    required String connectionId,
    String? busId,
    OutputMode? outputMode,
    double? gain,
    bool? isMuted,
  }) async {
    final currentState = state;
    if (currentState is! RoutingEditorStateLoaded) {
      debugPrint('Cannot update connection - routing editor not loaded');
      return;
    }

    try {
      final connectionIndex = currentState.connections
          .indexWhere((connection) => connection.id == connectionId);
          
      if (connectionIndex == -1) {
        debugPrint('Connection not found for update: $connectionId');
        emit(RoutingEditorState.error('Connection not found: $connectionId'));
        return;
      }

      final existingConnection = currentState.connections[connectionIndex];
      final updatedConnection = existingConnection.copyWith(
        busId: busId ?? existingConnection.busId,
        outputMode: outputMode ?? existingConnection.outputMode,
        gain: gain ?? existingConnection.gain,
        isMuted: isMuted ?? existingConnection.isMuted,
        modifiedAt: DateTime.now(),
      );

      final updatedConnections = [...currentState.connections];
      updatedConnections[connectionIndex] = updatedConnection;

      emit(currentState.copyWith(
        connections: updatedConnections,
        lastError: null,
      ));

      debugPrint('Connection updated: $connectionId');
      
    } catch (e) {
      debugPrint('Error updating connection: $e');
      emit(RoutingEditorState.error('Failed to update connection: $e'));
    }
  }

  /// Helper method to find a port by ID across all port lists
  Port? _findPortById(RoutingEditorStateLoaded state, String portId) {
    // Check physical inputs
    for (final port in state.physicalInputs) {
      if (port.id == portId) return port;
    }
    
    // Check physical outputs
    for (final port in state.physicalOutputs) {
      if (port.id == portId) return port;
    }
    
    // Check algorithm ports
    for (final algorithm in state.algorithms) {
      for (final port in algorithm.inputPorts) {
        if (port.id == portId) return port;
      }
      for (final port in algorithm.outputPorts) {
        if (port.id == portId) return port;
      }
    }
    
    return null;
  }

  /// Helper method to check if two ports can be connected
  bool _canConnect(Port sourcePort, Port targetPort) {
    // Output can connect to input
    if (sourcePort.direction == PortDirection.output && 
        targetPort.direction == PortDirection.input) {
      return _arePortTypesCompatible(sourcePort.type, targetPort.type);
    }
    
    return false;
  }

  /// Helper method to check port type compatibility
  bool _arePortTypesCompatible(PortType sourceType, PortType targetType) {
    // Same types are always compatible
    if (sourceType == targetType) return true;
    
    // Audio and CV are often interchangeable
    if ((sourceType == PortType.audio && targetType == PortType.cv) ||
        (sourceType == PortType.cv && targetType == PortType.audio)) {
      return true;
    }
    
    // Gate and trigger can be compatible
    if ((sourceType == PortType.gate && targetType == PortType.trigger) ||
        (sourceType == PortType.trigger && targetType == PortType.gate)) {
      return true;
    }
    
    return false;
  }

  /// Helper method to determine if a connection is a ghost connection
  /// Ghost connections occur when an algorithm output connects to a physical input
  bool _isGhostConnection(Port sourcePort, Port targetPort) {
    // Check if source is an algorithm output port
    final isSourceAlgorithmOutput = sourcePort.id.startsWith('algo_') && 
                                   sourcePort.direction == PortDirection.output;
    
    // Check if target is a physical input port  
    final isTargetPhysicalInput = targetPort.id.startsWith('hw_in_') && 
                                 targetPort.direction == PortDirection.input;
    
    // Ghost connection: algorithm output -> physical input
    return isSourceAlgorithmOutput && isTargetPhysicalInput;
  }

  /// Helper method to find existing connection between two ports
  Connection? _findExistingConnection(RoutingEditorStateLoaded state, String sourcePortId, String targetPortId) {
    try {
      return state.connections.firstWhere(
        (connection) => connection.sourcePortId == sourcePortId && 
                       connection.targetPortId == targetPortId,
      );
    } catch (e) {
      return null;
    }
  }

  /// Create a new routing bus
  Future<void> createBus({
    required String name,
    OutputMode defaultOutputMode = OutputMode.replace,
    double masterGain = 1.0,
  }) async {
    final currentState = state;
    if (currentState is! RoutingEditorStateLoaded) {
      debugPrint('Cannot create bus - routing editor not loaded');
      return;
    }

    try {
      // Generate unique bus ID
      final busId = 'bus_${DateTime.now().millisecondsSinceEpoch}';
      
      // Create new bus
      final newBus = RoutingBus(
        id: busId,
        name: name,
        status: BusStatus.available,
        defaultOutputMode: defaultOutputMode,
        masterGain: masterGain,
        createdAt: DateTime.now(),
      );

      // Update state with new bus
      final updatedBuses = [...currentState.buses, newBus];
      
      emit(currentState.copyWith(
        buses: updatedBuses,
        lastError: null,
      ));

      debugPrint('Bus created: $name (ID: $busId)');
      
      // Mark hardware as out of sync after local changes
      await _autoSyncToHardware();
      
    } catch (e) {
      debugPrint('Error creating bus: $e');
      emit(RoutingEditorState.error('Failed to create bus: $e'));
    }
  }

  /// Delete a routing bus and reassign its connections
  Future<void> deleteBus(String busId) async {
    final currentState = state;
    if (currentState is! RoutingEditorStateLoaded) {
      debugPrint('Cannot delete bus - routing editor not loaded');
      return;
    }

    try {
      // Find the bus to delete
      final busToDelete = currentState.buses.firstWhere(
        (bus) => bus.id == busId,
        orElse: () => throw ArgumentError('Bus not found: $busId'),
      );

      // Remove bus assignment from all connections
      final updatedConnections = currentState.connections.map((connection) {
        if (connection.busId == busId) {
          return connection.copyWith(
            busId: null,
            modifiedAt: DateTime.now(),
          );
        }
        return connection;
      }).toList();

      // Remove bus from state
      final updatedBuses = currentState.buses
          .where((bus) => bus.id != busId)
          .toList();

      emit(currentState.copyWith(
        buses: updatedBuses,
        connections: updatedConnections,
        lastError: null,
      ));

      debugPrint('Bus deleted: ${busToDelete.name} (${busToDelete.connectionIds.length} connections unassigned)');
      
    } catch (e) {
      debugPrint('Error deleting bus: $e');
      emit(RoutingEditorState.error('Failed to delete bus: $e'));
    }
  }

  /// Assign a connection to a routing bus
  Future<void> assignConnectionToBus({
    required String connectionId,
    required String busId,
    OutputMode? outputMode,
  }) async {
    final currentState = state;
    if (currentState is! RoutingEditorStateLoaded) {
      debugPrint('Cannot assign connection to bus - routing editor not loaded');
      return;
    }

    try {
      // Find the connection
      final connectionIndex = currentState.connections
          .indexWhere((connection) => connection.id == connectionId);
          
      if (connectionIndex == -1) {
        debugPrint('Connection not found: $connectionId');
        emit(RoutingEditorState.error('Connection not found: $connectionId'));
        return;
      }

      // Find the bus
      final busIndex = currentState.buses
          .indexWhere((bus) => bus.id == busId);
          
      if (busIndex == -1) {
        debugPrint('Bus not found: $busId');
        emit(RoutingEditorState.error('Bus not found: $busId'));
        return;
      }

      final existingConnection = currentState.connections[connectionIndex];
      final existingBus = currentState.buses[busIndex];

      // Remove connection from old bus if it was assigned
      List<RoutingBus> updatedBuses = [...currentState.buses];
      if (existingConnection.busId != null) {
        for (int i = 0; i < updatedBuses.length; i++) {
          if (updatedBuses[i].id == existingConnection.busId) {
            final oldBusConnectionIds = updatedBuses[i].connectionIds
                .where((id) => id != connectionId)
                .toList();
            updatedBuses[i] = updatedBuses[i].copyWith(
              connectionIds: oldBusConnectionIds,
              status: oldBusConnectionIds.isEmpty ? BusStatus.available : BusStatus.assigned,
              modifiedAt: DateTime.now(),
            );
            break;
          }
        }
      }

      // Update connection with new bus assignment
      final updatedConnection = existingConnection.copyWith(
        busId: busId,
        outputMode: outputMode ?? existingBus.defaultOutputMode,
        modifiedAt: DateTime.now(),
      );

      final updatedConnections = [...currentState.connections];
      updatedConnections[connectionIndex] = updatedConnection;

      // Add connection to new bus
      final newBusConnectionIds = [...existingBus.connectionIds, connectionId];
      updatedBuses[busIndex] = existingBus.copyWith(
        connectionIds: newBusConnectionIds,
        status: BusStatus.assigned,
        modifiedAt: DateTime.now(),
      );

      emit(currentState.copyWith(
        connections: updatedConnections,
        buses: updatedBuses,
        lastError: null,
      ));

      debugPrint('Connection assigned to bus: $connectionId -> ${existingBus.name}');
      
    } catch (e) {
      debugPrint('Error assigning connection to bus: $e');
      emit(RoutingEditorState.error('Failed to assign connection to bus: $e'));
    }
  }

  /// Remove a connection from its assigned bus
  Future<void> unassignConnectionFromBus(String connectionId) async {
    final currentState = state;
    if (currentState is! RoutingEditorStateLoaded) {
      debugPrint('Cannot unassign connection from bus - routing editor not loaded');
      return;
    }

    try {
      // Find the connection
      final connectionIndex = currentState.connections
          .indexWhere((connection) => connection.id == connectionId);
          
      if (connectionIndex == -1) {
        debugPrint('Connection not found: $connectionId');
        emit(RoutingEditorState.error('Connection not found: $connectionId'));
        return;
      }

      final existingConnection = currentState.connections[connectionIndex];
      
      if (existingConnection.busId == null) {
        debugPrint('Connection is not assigned to any bus: $connectionId');
        return;
      }

      // Update connection to remove bus assignment
      final updatedConnection = existingConnection.copyWith(
        busId: null,
        modifiedAt: DateTime.now(),
      );

      final updatedConnections = [...currentState.connections];
      updatedConnections[connectionIndex] = updatedConnection;

      // Update bus to remove connection
      final updatedBuses = currentState.buses.map((bus) {
        if (bus.id == existingConnection.busId) {
          final updatedConnectionIds = bus.connectionIds
              .where((id) => id != connectionId)
              .toList();
          return bus.copyWith(
            connectionIds: updatedConnectionIds,
            status: updatedConnectionIds.isEmpty ? BusStatus.available : BusStatus.assigned,
            modifiedAt: DateTime.now(),
          );
        }
        return bus;
      }).toList();

      emit(currentState.copyWith(
        connections: updatedConnections,
        buses: updatedBuses,
        lastError: null,
      ));

      debugPrint('Connection unassigned from bus: $connectionId');
      
    } catch (e) {
      debugPrint('Error unassigning connection from bus: $e');
      emit(RoutingEditorState.error('Failed to unassign connection from bus: $e'));
    }
  }

  /// Set output mode for a specific port
  Future<void> setPortOutputMode({
    required String portId,
    required OutputMode outputMode,
  }) async {
    final currentState = state;
    if (currentState is! RoutingEditorStateLoaded) {
      debugPrint('Cannot set port output mode - routing editor not loaded');
      return;
    }

    try {
      // Verify port exists
      final port = _findPortById(currentState, portId);
      if (port == null) {
        debugPrint('Port not found: $portId');
        emit(RoutingEditorState.error('Port not found: $portId'));
        return;
      }

      // Verify it's an output port
      if (port.direction != PortDirection.output) {
        debugPrint('Cannot set output mode for input port: $portId');
        emit(RoutingEditorState.error('Output mode can only be set for output ports'));
        return;
      }

      // Update port output modes
      final updatedPortOutputModes = Map<String, OutputMode>.from(currentState.portOutputModes);
      updatedPortOutputModes[portId] = outputMode;

      emit(currentState.copyWith(
        portOutputModes: updatedPortOutputModes,
        lastError: null,
      ));

      debugPrint('Port output mode set: ${port.name} -> $outputMode');
      
    } catch (e) {
      debugPrint('Error setting port output mode: $e');
      emit(RoutingEditorState.error('Failed to set port output mode: $e'));
    }
  }

  /// Get output mode for a specific port
  OutputMode getPortOutputMode(String portId) {
    final currentState = state;
    if (currentState is RoutingEditorStateLoaded) {
      return currentState.portOutputModes[portId] ?? OutputMode.replace;
    }
    return OutputMode.replace;
  }

  /// Update bus properties
  Future<void> updateBus({
    required String busId,
    String? name,
    OutputMode? defaultOutputMode,
    double? masterGain,
  }) async {
    final currentState = state;
    if (currentState is! RoutingEditorStateLoaded) {
      debugPrint('Cannot update bus - routing editor not loaded');
      return;
    }

    try {
      final busIndex = currentState.buses
          .indexWhere((bus) => bus.id == busId);
          
      if (busIndex == -1) {
        debugPrint('Bus not found for update: $busId');
        emit(RoutingEditorState.error('Bus not found: $busId'));
        return;
      }

      final existingBus = currentState.buses[busIndex];
      final updatedBus = existingBus.copyWith(
        name: name ?? existingBus.name,
        defaultOutputMode: defaultOutputMode ?? existingBus.defaultOutputMode,
        masterGain: masterGain ?? existingBus.masterGain,
        modifiedAt: DateTime.now(),
      );

      final updatedBuses = [...currentState.buses];
      updatedBuses[busIndex] = updatedBus;

      emit(currentState.copyWith(
        buses: updatedBuses,
        lastError: null,
      ));

      debugPrint('Bus updated: ${updatedBus.name}');
      
    } catch (e) {
      debugPrint('Error updating bus: $e');
      emit(RoutingEditorState.error('Failed to update bus: $e'));
    }
  }

  /// Get all connections assigned to a specific bus
  List<Connection> getConnectionsForBus(String busId) {
    final currentState = state;
    if (currentState is RoutingEditorStateLoaded) {
      return currentState.connections
          .where((connection) => connection.busId == busId)
          .toList();
    }
    return [];
  }

  /// Get bus by ID
  RoutingBus? getBusById(String busId) {
    final currentState = state;
    if (currentState is RoutingEditorStateLoaded) {
      try {
        return currentState.buses.firstWhere((bus) => bus.id == busId);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  /// Initialize default routing buses
  Future<void> initializeDefaultBuses() async {
    final currentState = state;
    if (currentState is! RoutingEditorStateLoaded) {
      debugPrint('Cannot initialize default buses - routing editor not loaded');
      return;
    }

    try {
      final defaultBuses = [
        RoutingBus(
          id: 'bus_audio_main',
          name: 'Audio Main',
          status: BusStatus.available,
          defaultOutputMode: OutputMode.mix,
          masterGain: 1.0,
          createdAt: DateTime.now(),
        ),
        RoutingBus(
          id: 'bus_cv_main',
          name: 'CV Main',
          status: BusStatus.available,
          defaultOutputMode: OutputMode.replace,
          masterGain: 1.0,
          createdAt: DateTime.now(),
        ),
        RoutingBus(
          id: 'bus_gate_main',
          name: 'Gate/Trigger Main',
          status: BusStatus.available,
          defaultOutputMode: OutputMode.replace,
          masterGain: 1.0,
          createdAt: DateTime.now(),
        ),
      ];

      // Add default buses if they don't already exist
      final existingBusIds = currentState.buses.map((bus) => bus.id).toSet();
      final newBuses = defaultBuses
          .where((bus) => !existingBusIds.contains(bus.id))
          .toList();

      if (newBuses.isNotEmpty) {
        final updatedBuses = [...currentState.buses, ...newBuses];
        
        emit(currentState.copyWith(
          buses: updatedBuses,
          lastError: null,
        ));

        debugPrint('Initialized ${newBuses.length} default buses');
      }
      
    } catch (e) {
      debugPrint('Error initializing default buses: $e');
      emit(RoutingEditorState.error('Failed to initialize default buses: $e'));
    }
  }

  /// Sync the current routing editor state with hardware
  Future<void> syncToHardware() async {
    final currentState = state;
    if (currentState is! RoutingEditorStateLoaded) {
      debugPrint('Cannot sync to hardware - routing editor not loaded');
      return;
    }

    emit(const RoutingEditorState.syncing());

    try {
      debugPrint('Starting hardware sync with ${currentState.connections.length} connections');
      
      // Update sync status
      final syncTime = DateTime.now();
      
      emit(currentState.copyWith(
        isHardwareSynced: true,
        lastSyncTime: syncTime,
        lastError: null,
      ));

      debugPrint('Hardware sync completed at $syncTime');
      
    } catch (e) {
      debugPrint('Error syncing to hardware: $e');
      emit(RoutingEditorState.error('Failed to sync to hardware: $e'));
    }
  }

  /// Sync hardware routing data to the routing editor state
  Future<void> syncFromHardware() async {
    final currentState = state;
    if (currentState is! RoutingEditorStateLoaded) {
      debugPrint('Cannot sync from hardware - routing editor not loaded');
      return;
    }

    emit(const RoutingEditorState.syncing());

    try {
      debugPrint('Starting hardware sync from device');
      
      // Trigger hardware routing refresh through DistingCubit
      await _distingCubit.refreshRouting();
      
      // The state will be updated through the stream subscription
      // when _processSynchronizedState is called
      
      debugPrint('Hardware sync from device initiated');
      
    } catch (e) {
      debugPrint('Error syncing from hardware: $e');
      emit(RoutingEditorState.error('Failed to sync from hardware: $e'));
    }
  }

  /// Check if hardware sync is required
  bool isHardwareSyncRequired() {
    final currentState = state;
    if (currentState is! RoutingEditorStateLoaded) {
      return false;
    }
    
    return !currentState.isHardwareSynced;
  }

  /// Mark hardware as out of sync (called when local changes are made)
  void markHardwareOutOfSync() {
    final currentState = state;
    if (currentState is RoutingEditorStateLoaded && currentState.isHardwareSynced) {
      emit(currentState.copyWith(
        isHardwareSynced: false,
        lastError: null,
      ));
      debugPrint('Hardware marked as out of sync');
    }
  }

  /// Auto-sync to hardware when changes are made (if enabled)
  Future<void> _autoSyncToHardware() async {
    final currentState = state;
    if (currentState is RoutingEditorStateLoaded) {
      // Mark as out of sync first
      markHardwareOutOfSync();
      
      // Auto-save state after changes
      await _autoSaveState();
      
      // Auto-sync could be enabled/disabled via a setting
      // For now, we'll just mark as out of sync and let the user manually sync
      debugPrint('Auto-sync would trigger here (disabled for now)');
    }
  }

  /// Get hardware sync status information
  Map<String, dynamic> getHardwareSyncStatus() {
    final currentState = state;
    if (currentState is RoutingEditorStateLoaded) {
      return {
        'isHardwareSynced': currentState.isHardwareSynced,
        'lastSyncTime': currentState.lastSyncTime?.toIso8601String(),
        'connectionCount': currentState.connections.length,
        'busCount': currentState.buses.length,
      };
    }
    return {
      'isHardwareSynced': false,
      'lastSyncTime': null,
      'connectionCount': 0,
      'busCount': 0,
    };
  }

  /// Refresh routing data from hardware
  Future<void> refreshRouting() async {
    if (state is RoutingEditorStateLoaded) {
      emit(const RoutingEditorState.refreshing());
    }
    
    try {
      await _distingCubit.refreshRouting();
      // State will be updated through the stream subscription
    } catch (e) {
      debugPrint('Error refreshing routing: $e');
      emit(RoutingEditorState.error('Failed to refresh routing: $e'));
    }
  }

  /// Clear the current routing state
  void clearRouting() {
    emit(const RoutingEditorState.initial());
  }

  /// Save current routing editor state to persistent storage
  Future<void> saveState() async {
    final currentState = state;
    if (currentState is! RoutingEditorStateLoaded) {
      debugPrint('Cannot save state - routing editor not loaded');
      return;
    }

    emit(const RoutingEditorState.persisting());

    try {
      final prefs = await _prefs;
      
      // Prepare state data for serialization
      final stateData = {
        'connections': currentState.connections.map((connection) => {
          'id': connection.id,
          'sourcePortId': connection.sourcePortId,
          'targetPortId': connection.targetPortId,
          'busId': connection.busId,
          'outputMode': connection.outputMode.name,
          'gain': connection.gain,
          'isMuted': connection.isMuted,
          'createdAt': connection.createdAt?.toIso8601String(),
          'modifiedAt': connection.modifiedAt?.toIso8601String(),
        }).toList(),
        'buses': currentState.buses.map((bus) => {
          'id': bus.id,
          'name': bus.name,
          'status': bus.status.name,
          'connectionIds': bus.connectionIds,
          'defaultOutputMode': bus.defaultOutputMode.name,
          'masterGain': bus.masterGain,
          'createdAt': bus.createdAt?.toIso8601String(),
          'modifiedAt': bus.modifiedAt?.toIso8601String(),
        }).toList(),
        'portOutputModes': currentState.portOutputModes.map(
          (key, value) => MapEntry(key, value.name),
        ),
        'lastSyncTime': currentState.lastSyncTime?.toIso8601String(),
        'lastPersistTime': DateTime.now().toIso8601String(),
      };

      // Save to SharedPreferences
      final jsonString = jsonEncode(stateData);
      await prefs.setString('routing_editor_state', jsonString);

      // Update state with persistence timestamp
      final persistTime = DateTime.now();
      emit(currentState.copyWith(
        isPersistenceEnabled: true,
        lastPersistTime: persistTime,
        lastError: null,
      ));

      debugPrint('Routing editor state saved at $persistTime');
      
    } catch (e) {
      debugPrint('Error saving routing editor state: $e');
      emit(RoutingEditorState.error('Failed to save state: $e'));
    }
  }

  /// Load routing editor state from persistent storage
  Future<void> _loadPersistedState() async {
    try {
      final prefs = await _prefs;
      final jsonString = prefs.getString('routing_editor_state');
      
      if (jsonString == null) {
        debugPrint('No persisted routing editor state found');
        return;
      }

      debugPrint('Loading persisted routing editor state');
      
      final stateData = jsonDecode(jsonString) as Map<String, dynamic>;
      
      // Parse connections
      final connections = <Connection>[];
      for (final connectionData in stateData['connections'] as List) {
        final connectionMap = connectionData as Map<String, dynamic>;
        connections.add(Connection(
          id: connectionMap['id'] as String,
          sourcePortId: connectionMap['sourcePortId'] as String,
          targetPortId: connectionMap['targetPortId'] as String,
          busId: connectionMap['busId'] as String?,
          outputMode: OutputMode.values.firstWhere(
            (mode) => mode.name == connectionMap['outputMode'],
            orElse: () => OutputMode.replace,
          ),
          gain: (connectionMap['gain'] as num?)?.toDouble() ?? 1.0,
          isMuted: connectionMap['isMuted'] as bool? ?? false,
          createdAt: connectionMap['createdAt'] != null
              ? DateTime.parse(connectionMap['createdAt'] as String)
              : null,
          modifiedAt: connectionMap['modifiedAt'] != null
              ? DateTime.parse(connectionMap['modifiedAt'] as String)
              : null,
        ));
      }

      // Parse buses
      final buses = <RoutingBus>[];
      for (final busData in stateData['buses'] as List) {
        final busMap = busData as Map<String, dynamic>;
        buses.add(RoutingBus(
          id: busMap['id'] as String,
          name: busMap['name'] as String,
          status: BusStatus.values.firstWhere(
            (status) => status.name == busMap['status'],
            orElse: () => BusStatus.available,
          ),
          connectionIds: (busMap['connectionIds'] as List).cast<String>(),
          defaultOutputMode: OutputMode.values.firstWhere(
            (mode) => mode.name == busMap['defaultOutputMode'],
            orElse: () => OutputMode.replace,
          ),
          masterGain: (busMap['masterGain'] as num?)?.toDouble() ?? 1.0,
          createdAt: busMap['createdAt'] != null
              ? DateTime.parse(busMap['createdAt'] as String)
              : null,
          modifiedAt: busMap['modifiedAt'] != null
              ? DateTime.parse(busMap['modifiedAt'] as String)
              : null,
        ));
      }

      // Parse port output modes
      final portOutputModes = <String, OutputMode>{};
      final portModeData = stateData['portOutputModes'] as Map<String, dynamic>?;
      if (portModeData != null) {
        for (final entry in portModeData.entries) {
          portOutputModes[entry.key] = OutputMode.values.firstWhere(
            (mode) => mode.name == entry.value,
            orElse: () => OutputMode.replace,
          );
        }
      }

      // Parse timestamps (kept for future use, currently unused)
      // final lastSyncTime = stateData['lastSyncTime'] != null
      //     ? DateTime.parse(stateData['lastSyncTime'] as String)
      //     : null;
      // final lastPersistTime = stateData['lastPersistTime'] != null
      //     ? DateTime.parse(stateData['lastPersistTime'] as String)
      //     : null;

      debugPrint('Loaded ${connections.length} connections, ${buses.length} buses from persistent storage');
      
    } catch (e) {
      debugPrint('Error loading persisted routing editor state: $e');
      // Don't emit error state here, just log and continue with empty state
    }
  }

  /// Clear all persisted state data
  Future<void> clearPersistedState() async {
    try {
      final prefs = await _prefs;
      await prefs.remove('routing_editor_state');
      
      final currentState = state;
      if (currentState is RoutingEditorStateLoaded) {
        emit(currentState.copyWith(
          isPersistenceEnabled: false,
          lastPersistTime: null,
          lastError: null,
        ));
      }

      debugPrint('Persisted routing editor state cleared');
      
    } catch (e) {
      debugPrint('Error clearing persisted state: $e');
      emit(RoutingEditorState.error('Failed to clear persisted state: $e'));
    }
  }

  /// Get persistence status information
  Map<String, dynamic> getPersistenceStatus() {
    final currentState = state;
    if (currentState is RoutingEditorStateLoaded) {
      return {
        'isPersistenceEnabled': currentState.isPersistenceEnabled,
        'lastPersistTime': currentState.lastPersistTime?.toIso8601String(),
        'connectionCount': currentState.connections.length,
        'busCount': currentState.buses.length,
      };
    }
    return {
      'isPersistenceEnabled': false,
      'lastPersistTime': null,
      'connectionCount': 0,
      'busCount': 0,
    };
  }

  /// Auto-save state after changes (if enabled)
  Future<void> _autoSaveState() async {
    final currentState = state;
    if (currentState is RoutingEditorStateLoaded && currentState.isPersistenceEnabled) {
      debugPrint('Auto-saving routing editor state');
      await saveState();
    }
  }

  /// Enhanced error recovery method
  Future<void> recoverFromError() async {
    final currentState = state;
    if (currentState is RoutingEditorStateError) {
      debugPrint('Attempting recovery from error: ${currentState.message}');
      
      try {
        // Try to reload the last known good state
        await _loadPersistedState();
        
        // If no persisted state, return to initial state
        emit(const RoutingEditorState.initial());
        
        debugPrint('Recovery attempt completed');
        
      } catch (e) {
        debugPrint('Recovery failed: $e');
        emit(RoutingEditorState.error('Recovery failed: $e'));
      }
    }
  }

  @override
  Future<void> close() {
    _distingStateSubscription?.cancel();
    return super.close();
  }
}
