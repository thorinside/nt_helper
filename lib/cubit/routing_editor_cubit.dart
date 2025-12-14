import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'package:nt_helper/core/routing/algorithm_routing.dart' as core_routing;
import 'package:nt_helper/core/routing/models/port.dart';
import 'package:nt_helper/core/routing/models/connection.dart';
import 'package:nt_helper/core/routing/services/algorithm_connection_service.dart';
import 'package:nt_helper/core/routing/connection_discovery_service.dart';
import 'package:nt_helper/core/routing/services/connection_validator.dart';
import 'package:nt_helper/core/routing/node_layout_algorithm.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nt_helper/core/routing/models/es5_hardware_node.dart';

import 'routing_editor_state.dart';

/// Cubit that manages the state of the routing editor.
///
/// Watches the DistingCubit's synchronized state and processes routing
/// information into a visual representation for the routing canvas.
class RoutingEditorCubit extends Cubit<RoutingEditorState> {
  final DistingCubit? _distingCubit;
  Future<SharedPreferences>? _prefs;
  StreamSubscription<DistingState>? _distingStateSubscription;
  NodeLayoutAlgorithm? _layoutAlgorithm;

  RoutingEditorCubit(
    this._distingCubit, {
    AlgorithmConnectionService? algorithmConnectionService,
  }) : super(const RoutingEditorState.initial()) {
    if (_distingCubit != null) {
      _prefs = SharedPreferences.getInstance();
      _initializeStateWatcher();
      _loadPersistedState();
    }
  }

  /// Initialize watching the disting cubit state changes
  void _initializeStateWatcher() {
    if (_distingCubit == null) return;

    _distingStateSubscription = _distingCubit.stream.listen((distingState) {
      _processDistingState(distingState);
    });

    // Process current state if already synchronized
    final currentState = _distingCubit.state;
    _processDistingState(currentState);
  }

  /// Generate stable algorithm IDs based on GUID and instance counter
  ///
  /// Creates IDs in the format `algo_${guid}_${instanceCounter}` where
  /// instanceCounter increments for duplicate algorithms to ensure uniqueness.
  /// These IDs remain stable regardless of slot position changes.
  List<String> generateStableAlgorithmIds(List<Slot> slots) {
    final algorithmIds = <String>[];
    final guidCounters = <String, int>{};

    for (final slot in slots) {
      final guid = slot.algorithm.guid;
      final counter = guidCounters[guid] ?? 0;
      guidCounters[guid] = counter + 1;

      // Create stable ID without slot index
      algorithmIds.add('algo_${guid}_${counter + 1}');
    }

    return algorithmIds;
  }

  /// Generate a stable port ID using algorithm UUID and parameter number
  ///
  /// Creates simple, opaque IDs with semantic information in metadata
  String generatePortId({
    required String algorithmId,
    required int parameterNumber,
    required String portType,
  }) {
    return '${algorithmId}_port_$parameterNumber';
  }

  /// Process incoming DistingState and update routing editor state accordingly
  void _processDistingState(DistingState distingState) {
    distingState.when(
      initial: () => emit(const RoutingEditorState.initial()),
      selectDevice: (inputDevices, outputDevices, canWorkOffline) =>
          emit(const RoutingEditorState.disconnected()),
      connected: (disting, inputDevice, outputDevice, offline, loading) =>
          emit(const RoutingEditorState.disconnected()),
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
          ) {
            _processSynchronizedState(slots);
          },
    );
  }

  /// Check if ES-5 node should be displayed based on algorithm GUIDs
  bool shouldShowEs5Node(List<Slot> slots) {
    const es5AlgorithmGuids = {
      'usbf',
      'clck',
      'eucp',
      'es5e',
      'clkm', // Clock Multiplier
      'clkd', // Clock Divider
      'pycv', // Poly CV
    };

    for (final slot in slots) {
      if (es5AlgorithmGuids.contains(slot.algorithm.guid)) {
        return true;
      }
    }

    return false;
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

      // Conditionally create ES-5 ports based on algorithm presence
      final es5Inputs = shouldShowEs5Node(slots)
          ? ES5HardwareNode.createInputPorts()
          : <Port>[];

      // Build algorithm representations with ports determined by AlgorithmRouting
      final algorithms = <RoutingAlgorithm>[];
      final routings = <core_routing.AlgorithmRouting>[];

      // Generate stable UUIDs for each algorithm instance
      final algorithmUuids = generateStableAlgorithmIds(slots);

      for (int i = 0; i < slots.length; i++) {
        final slot = slots[i];
        final algorithmUuid = algorithmUuids[i];

        // Create routing using the AlgorithmRouting factory method
        final routing = core_routing.AlgorithmRouting.fromSlot(
          slot,
          algorithmUuid: algorithmUuid,
        );

        final inputPorts = routing.inputPorts;
        final outputPorts = routing.outputPorts;

        // Filter out algorithms with no ports (e.g., the 'note' algorithm)
        if (inputPorts.isEmpty && outputPorts.isEmpty) {
          continue;
        }

        // Add routing to list for connection discovery
        routings.add(routing);

        // Create visual representation
        final routingAlgorithm = RoutingAlgorithm(
          id: algorithmUuid,
          index: i,
          algorithm: slot.algorithm,
          // Convert core ports to UI model ports
          inputPorts: inputPorts
              .map(
                (p) => Port(
                  id: p.id,
                  name: p.name,
                  type: _toUiPortType(p.type),
                  direction: PortDirection.input,
                  busValue: p.busValue,
                  busParam: p.busParam,
                  parameterNumber: p.parameterNumber,
                  isPolyVoice: p.isPolyVoice,
                  voiceNumber: p.voiceNumber,
                  isVirtualCV: p.isVirtualCV,
                ),
              )
              .toList(),
          outputPorts: outputPorts
              .map(
                (p) => Port(
                  id: p.id,
                  name: p.name,
                  type: _toUiPortType(p.type),
                  direction: PortDirection.output,
                  busValue: p.busValue,
                  busParam: p.busParam,
                  parameterNumber: p.parameterNumber,
                  modeParameterNumber: p.modeParameterNumber,
                  outputMode: p.outputMode,
                ),
              )
              .toList(),
        );
        algorithms.add(routingAlgorithm);
      }

      // Use the ConnectionDiscoveryService to discover connections from AlgorithmRouting instances
      final discoveredConnections =
          ConnectionDiscoveryService.discoverConnections(routings);

      // Validate connections for slot ordering violations
      final connections = ConnectionValidator.validateConnections(
        discoveredConnections,
        algorithms,
      );

      // For backward compatibility, keep empty lists for now
      // These will be removed in the next refactoring step

      // Preserve zoom level and pan offset from current state if it exists
      final currentState = state;
      final zoomLevel = currentState is RoutingEditorStateLoaded
          ? currentState.zoomLevel
          : 1.0;
      final panOffset = currentState is RoutingEditorStateLoaded
          ? currentState.panOffset
          : Offset.zero;

      emit(
        RoutingEditorState.loaded(
          physicalInputs: physicalInputs,
          physicalOutputs: physicalOutputs,
          es5Inputs: es5Inputs,
          algorithms: algorithms,
          connections: connections,
          zoomLevel: zoomLevel,
          panOffset: panOffset,
          isHardwareSynced: true,
          lastSyncTime: DateTime.now(),
        ),
      );

      // Initialize default buses after loading (fire and forget)
      initializeDefaultBuses();

      // Load saved node positions for this preset
      loadNodePositions();
    } catch (e) {
      // Intentionally empty
    }
  }

  /// Convert core port type (routing) to UI port type
  PortType _toUiPortType(PortType type) {
    // After Story 7.5, only audio and CV types exist
    // Both are directly mapped
    switch (type) {
      case PortType.audio:
        return PortType.audio;
      case PortType.cv:
        return PortType.cv;
    }
  }

  /// Create the 12 physical input ports of the Disting NT
  List<Port> _createPhysicalInputPorts() {
    return [
      const Port(
        id: 'hw_in_1',
        name: 'I1',
        type: PortType.cv,
        direction: PortDirection.output,
      ),
      const Port(
        id: 'hw_in_2',
        name: 'I2',
        type: PortType.cv,
        direction: PortDirection.output,
      ),
      const Port(
        id: 'hw_in_3',
        name: 'I3',
        type: PortType.cv,
        direction: PortDirection.output,
      ),
      const Port(
        id: 'hw_in_4',
        name: 'I4',
        type: PortType.cv,
        direction: PortDirection.output,
      ),
      const Port(
        id: 'hw_in_5',
        name: 'I5',
        type: PortType.cv,
        direction: PortDirection.output,
      ),
      const Port(
        id: 'hw_in_6',
        name: 'I6',
        type: PortType.cv,
        direction: PortDirection.output,
      ),
      const Port(
        id: 'hw_in_7',
        name: 'I7',
        type: PortType.cv,
        direction: PortDirection.output,
      ),
      const Port(
        id: 'hw_in_8',
        name: 'I8',
        type: PortType.cv,
        direction: PortDirection.output,
      ),
      const Port(
        id: 'hw_in_9',
        name: 'I9',
        type: PortType.cv,
        direction: PortDirection.output,
      ),
      const Port(
        id: 'hw_in_10',
        name: 'I10',
        type: PortType.cv,
        direction: PortDirection.output,
      ),
      const Port(
        id: 'hw_in_11',
        name: 'I11',
        type: PortType.cv,
        direction: PortDirection.output,
      ),
      const Port(
        id: 'hw_in_12',
        name: 'I12',
        type: PortType.cv,
        direction: PortDirection.output,
      ),
    ];
  }

  /// Create the 8 physical output ports of the Disting NT
  List<Port> _createPhysicalOutputPorts() {
    return [
      const Port(
        id: 'hw_out_1',
        name: 'O1',
        type: PortType.audio,
        direction: PortDirection.input,
      ),
      const Port(
        id: 'hw_out_2',
        name: 'O2',
        type: PortType.audio,
        direction: PortDirection.input,
      ),
      const Port(
        id: 'hw_out_3',
        name: 'O3',
        type: PortType.audio,
        direction: PortDirection.input,
      ),
      const Port(
        id: 'hw_out_4',
        name: 'O4',
        type: PortType.audio,
        direction: PortDirection.input,
      ),
      const Port(
        id: 'hw_out_5',
        name: 'O5',
        type: PortType.audio,
        direction: PortDirection.input,
      ),
      const Port(
        id: 'hw_out_6',
        name: 'O6',
        type: PortType.audio,
        direction: PortDirection.input,
      ),
      const Port(
        id: 'hw_out_7',
        name: 'O7',
        type: PortType.audio,
        direction: PortDirection.input,
      ),
      const Port(
        id: 'hw_out_8',
        name: 'O8',
        type: PortType.audio,
        direction: PortDirection.input,
      ),
    ];
  }

  /// Create a new connection between source and target ports with automatic bus assignment
  Future<void> createConnection({
    required String sourcePortId,
    required String targetPortId,
    String? busId,
    OutputMode outputMode = OutputMode.add,
    double gain = 1.0,
  }) async {
    final currentState = state;
    if (currentState is! RoutingEditorStateLoaded) {
      return;
    }

    if (_distingCubit == null) {
      return;
    }

    try {
      // Validate ports exist

      // Debug: List all available ports
      for (final algo in currentState.algorithms) {
        for (final _ in algo.inputPorts) {}
        for (final _ in algo.outputPorts) {}
      }

      final sourcePort = _findPortById(currentState, sourcePortId);
      final targetPort = _findPortById(currentState, targetPortId);

      if (sourcePort == null) {
        throw ArgumentError('Source port not found: $sourcePortId');
      }

      if (targetPort == null) {
        throw ArgumentError('Target port not found: $targetPortId');
      }

      // Validate connection is valid (output -> input)

      if (sourcePort.direction != PortDirection.output ||
          targetPort.direction != PortDirection.input) {
        throw ArgumentError(
          'Invalid connection: source must be output, target must be input',
        );
      }

      // Check for duplicate connections
      final existingConnection = _findExistingConnection(
        currentState,
        sourcePortId,
        targetPortId,
      );
      if (existingConnection != null) {
        throw StateError('Connection already exists between these ports');
      }

      // Determine connection type and assign bus number
      final connectionType = _determineConnectionType(
        sourcePortId,
        targetPortId,
      );
      int? busNumber;

      // Assign bus numbers based on connection type
      switch (connectionType) {
        case ConnectionType.hardwareInput:
          // Hardware input to algorithm: use buses 1-12
          busNumber = await _assignBusForHardwareInput(
            sourcePortId,
            targetPort,
            currentState,
          );
          break;
        case ConnectionType.hardwareOutput:
          // Algorithm to hardware output: use buses 13-20
          busNumber = await _assignBusForHardwareOutput(
            sourcePort,
            targetPortId,
            currentState,
          );
          break;
        case ConnectionType.algorithmToAlgorithm:
          // Algorithm to algorithm: use aux buses 21-28
          busNumber = await _assignBusForAlgorithmConnection(
            sourcePort,
            targetPort,
            currentState,
          );
          break;
        default:
          return;
      }

      if (busNumber == null) {
        throw StateError('Failed to assign bus - all buses may be in use');
      }

      // The connection will appear automatically via ConnectionDiscoveryService
      // when the bus parameters are updated

      // Mark hardware as out of sync after parameter changes
      await _autoSyncToHardware();
    } catch (e) {
      // Intentionally empty
    }
  }

  /// Assign bus for hardware input connection (hardware input -> algorithm input)
  Future<int?> _assignBusForHardwareInput(
    String hardwareInputPortId,
    Port algorithmInputPort,
    RoutingEditorStateLoaded state,
  ) async {
    // Hardware inputs use buses 1-12
    final hardwareInputNumber = int.tryParse(
      hardwareInputPortId.replaceAll('hw_in_', ''),
    );
    if (hardwareInputNumber == null ||
        hardwareInputNumber < 1 ||
        hardwareInputNumber > 12) {
      return null;
    }

    final busNumber = hardwareInputNumber; // Bus 1 for hw_in_1, etc.

    // Find the algorithm that owns this input port and update its parameter
    if (algorithmInputPort.parameterNumber != null) {
      final algorithmIndex = _findAlgorithmIndexForPort(
        state,
        algorithmInputPort.id,
      );
      if (algorithmIndex != null) {
        await _distingCubit!.updateParameterValue(
          algorithmIndex: algorithmIndex,
          parameterNumber: algorithmInputPort.parameterNumber!,
          value: busNumber,
          userIsChangingTheValue: false,
        );
        return busNumber;
      }
    }

    return null;
  }

  /// Assign bus for hardware output connection (algorithm output -> hardware output)
  Future<int?> _assignBusForHardwareOutput(
    Port algorithmOutputPort,
    String hardwareOutputPortId,
    RoutingEditorStateLoaded state,
  ) async {
    int? busNumber;

    // Check for ES-5 L/R ports first
    if (hardwareOutputPortId == 'es5_L') {
      busNumber = 29; // ES-5 L
    } else if (hardwareOutputPortId == 'es5_R') {
      busNumber = 30; // ES-5 R
    } else if (hardwareOutputPortId.startsWith('es5_') &&
        hardwareOutputPortId.length == 5) {
      // ES-5 direct output ports (es5_1 through es5_8)
      final es5PortNumber = int.tryParse(hardwareOutputPortId.substring(4));
      if (es5PortNumber != null && es5PortNumber >= 1 && es5PortNumber <= 8) {
        // Check if this is ES-5 Encoder output (busParam = 'es5_encoder_mirror')
        if (algorithmOutputPort.busParam == 'es5_encoder_mirror') {
          return await _assignEs5EncoderOutput(
            algorithmOutputPort,
            es5PortNumber,
            state,
          );
        }
        // Check if this is ES-5 direct output (busParam = 'es5_direct')
        if (algorithmOutputPort.busParam == 'es5_direct') {
          return await _assignEs5DirectOutput(
            algorithmOutputPort,
            es5PortNumber,
            state,
          );
        }
        // Otherwise, this is a normal algorithm output being dragged to an ES-5 port
        // Fall through to normal bus assignment logic below
        return null;
      }
      return null;
    } else {
      // Hardware outputs use buses 13-20
      final hardwareOutputNumber = int.tryParse(
        hardwareOutputPortId.replaceAll('hw_out_', ''),
      );
      if (hardwareOutputNumber == null ||
          hardwareOutputNumber < 1 ||
          hardwareOutputNumber > 8) {
        return null;
      }

      busNumber = 12 + hardwareOutputNumber; // Bus 13 for hw_out_1, etc.
    }

    // Find the algorithm that owns this output port and update its parameter
    if (algorithmOutputPort.parameterNumber != null) {
      final algorithmIndex = _findAlgorithmIndexForPort(
        state,
        algorithmOutputPort.id,
      );
      if (algorithmIndex != null) {
        await _distingCubit!.updateParameterValue(
          algorithmIndex: algorithmIndex,
          parameterNumber: algorithmOutputPort.parameterNumber!,
          value: busNumber,
          userIsChangingTheValue: false,
        );
        return busNumber;
      }
    }

    return null;
  }

  /// Assign ES-5 direct output for Clock/Euclidean algorithms.
  ///
  /// Sets the ES-5 Output parameter for the channel to route to the specified ES-5 port (1-8).
  Future<int?> _assignEs5DirectOutput(
    Port algorithmOutputPort,
    int es5PortNumber,
    RoutingEditorStateLoaded state,
  ) async {
    final algorithmIndex = _findAlgorithmIndexForPort(
      state,
      algorithmOutputPort.id,
    );
    if (algorithmIndex == null) {
      return null;
    }

    // Get the slot from DistingCubit
    final distingState = _distingCubit?.state;
    if (distingState is! DistingStateSynchronized) {
      return null;
    }

    if (algorithmIndex < 0 || algorithmIndex >= distingState.slots.length) {
      return null;
    }

    final slot = distingState.slots[algorithmIndex];

    // Extract channel/voice number from port ID
    // Formats:
    // - Clock/Euclidean/Clock Multiplier/Clock Divider: {uuid}_channel_{N}_es5_output
    // - Poly CV: {uuid}_gate_output_{N}
    int? channel;

    // Try multi-channel format first
    var channelMatch = RegExp(
      r'_channel_(\d+)_',
    ).firstMatch(algorithmOutputPort.id);
    if (channelMatch != null) {
      channel = int.parse(channelMatch.group(1)!);
    } else {
      // Try Poly CV voice format
      channelMatch = RegExp(
        r'_gate_output_(\d+)',
      ).firstMatch(algorithmOutputPort.id);
      if (channelMatch != null) {
        channel = int.parse(channelMatch.group(1)!);
      }
    }

    if (channel == null) {
      return null;
    }

    // Find the ES-5 Output parameter
    // For multi-channel algorithms (Clock/Euclidean/etc): "$channel:ES-5 Output"
    // For Poly CV: "ES-5 Output" (no channel prefix, controls starting port for all voices)
    String es5OutputParamName = '$channel:ES-5 Output';
    var es5OutputParam = slot.parameters.firstWhere(
      (p) => p.name == es5OutputParamName,
      orElse: () => ParameterInfo.filler(),
    );

    int targetValue = es5PortNumber;
    bool isPolyCv = false;

    // If not found with channel prefix, try without (Poly CV case)
    if (es5OutputParam.parameterNumber < 0) {
      es5OutputParamName = 'ES-5 Output';
      es5OutputParam = slot.parameters.firstWhere(
        (p) => p.name == es5OutputParamName,
        orElse: () => ParameterInfo.filler(),
      );
      isPolyCv = true;
    }

    if (es5OutputParam.parameterNumber < 0) {
      return null;
    }

    // For Poly CV, calculate the starting ES-5 port based on which voice was dragged
    // Voice numbering is 1-based, ES-5 ports are 1-8
    // If Voice 3 is dragged to ES-5 5, then starting port = 5 - (3 - 1) = 3
    if (isPolyCv) {
      final voiceIndex = channel - 1; // Convert to 0-based
      targetValue = es5PortNumber - voiceIndex;

      // Clamp to valid ES-5 port range (1-8)
      if (targetValue < 1) {
        targetValue = 1;
      } else if (targetValue > 8) {
        targetValue = 8;
      }
    }

    // Set the ES-5 Output parameter
    await _distingCubit!.updateParameterValue(
      algorithmIndex: algorithmIndex,
      parameterNumber: es5OutputParam.parameterNumber,
      value: targetValue,
      userIsChangingTheValue: false,
    );

    // Return a dummy bus number to indicate success
    // The actual connection will be discovered via ConnectionDiscoveryService
    return 1; // Non-null indicates success
  }

  /// Assign ES-5 Encoder output for dragged connections.
  ///
  /// Sets the Output parameter for the channel to route to the specified ES-5 port (1-8).
  Future<int?> _assignEs5EncoderOutput(
    Port algorithmOutputPort,
    int es5PortNumber,
    RoutingEditorStateLoaded state,
  ) async {
    final algorithmIndex = _findAlgorithmIndexForPort(
      state,
      algorithmOutputPort.id,
    );
    if (algorithmIndex == null) {
      return null;
    }

    // Get the slot from DistingCubit
    final distingState = _distingCubit?.state;
    if (distingState is! DistingStateSynchronized) {
      return null;
    }

    if (algorithmIndex < 0 || algorithmIndex >= distingState.slots.length) {
      return null;
    }

    final slot = distingState.slots[algorithmIndex];

    // Extract channel number from port ID (format: {uuid}_channel_{N}_output)
    final channelMatch = RegExp(
      r'_channel_(\d+)_output',
    ).firstMatch(algorithmOutputPort.id);
    if (channelMatch == null) {
      return null;
    }

    final channel = int.parse(channelMatch.group(1)!);

    // Find the Output parameter for this channel (format: "N:Output")
    final outputParamName = '$channel:Output';
    final outputParam = slot.parameters.firstWhere(
      (p) => p.name == outputParamName,
      orElse: () => ParameterInfo.filler(),
    );

    if (outputParam.parameterNumber < 0) {
      return null;
    }

    // Set the Output parameter to the target ES-5 port number
    await _distingCubit!.updateParameterValue(
      algorithmIndex: algorithmIndex,
      parameterNumber: outputParam.parameterNumber,
      value: es5PortNumber,
      userIsChangingTheValue: false,
    );

    // Return a dummy bus number to indicate success
    // The actual connection will be discovered via ConnectionDiscoveryService
    return 1; // Non-null indicates success
  }

  /// Assign bus for algorithm-to-algorithm connection using aux buses
  Future<int?> _assignBusForAlgorithmConnection(
    Port sourceOutputPort,
    Port targetInputPort,
    RoutingEditorStateLoaded state,
  ) async {
    // Get actual parameter values from live slot data, not cached Port.busValue
    final distingState = _distingCubit?.state;
    if (distingState is! DistingStateSynchronized) {
      return null;
    }

    // Find algorithm indices for the ports
    final sourceAlgorithmIndex = _findAlgorithmIndexForPort(
      state,
      sourceOutputPort.id,
    );
    final targetAlgorithmIndex = _findAlgorithmIndexForPort(
      state,
      targetInputPort.id,
    );

    if (sourceAlgorithmIndex == null || targetAlgorithmIndex == null) {
      return null;
    }

    // Get actual parameter values from slots
    int? sourceBusValue;
    int? targetBusValue;

    if (sourceOutputPort.parameterNumber != null &&
        sourceAlgorithmIndex < distingState.slots.length) {
      final sourceSlot = distingState.slots[sourceAlgorithmIndex];
      final sourceParam = sourceSlot.values.firstWhere(
        (v) => v.parameterNumber == sourceOutputPort.parameterNumber!,
        orElse: () => throw StateError('Source parameter not found in slot'),
      );
      sourceBusValue = sourceParam.value;
    }

    if (targetInputPort.parameterNumber != null &&
        targetAlgorithmIndex < distingState.slots.length) {
      final targetSlot = distingState.slots[targetAlgorithmIndex];
      final targetParam = targetSlot.values.firstWhere(
        (v) => v.parameterNumber == targetInputPort.parameterNumber!,
        orElse: () => throw StateError('Target parameter not found in slot'),
      );
      targetBusValue = targetParam.value;
    }

    // New logic: Use source bus if it exists (non-zero), otherwise allocate new
    // Always overwrite target bus regardless of its current value
    int busToUse;
    if (sourceBusValue != null && sourceBusValue > 0) {
      // Source already has a bus - reuse it for fan-out
      busToUse = sourceBusValue;
    } else {
      // Source has no bus - allocate a new one
      // Prefer aux buses first, then fall back to any free internal bus.
      final availableBus = await _findFirstAvailableInternalBus(state);
      if (availableBus == null) {
        throw StateError(
          'No available internal buses for algorithm connections',
        );
      }
      busToUse = availableBus;
    }

    // Note: We're intentionally ignoring targetBusValue to allow easy overwriting
    if (targetBusValue != null && targetBusValue > 0) {}

    // Update both source output and target input bus parameters
    bool sourceUpdated = false;
    bool targetUpdated = false;

    // Update source output port (if it doesn't already have this bus based on actual hardware value)
    if (sourceOutputPort.parameterNumber != null &&
        sourceBusValue != busToUse) {
      await _distingCubit!.updateParameterValue(
        algorithmIndex: sourceAlgorithmIndex,
        parameterNumber: sourceOutputPort.parameterNumber!,
        value: busToUse,
        userIsChangingTheValue: false,
      );
      sourceUpdated = true;
    } else if (sourceBusValue == busToUse) {
      sourceUpdated = true; // Already has the correct bus
    }

    // Update target input port (if it doesn't already have this bus based on actual hardware value)
    if (targetInputPort.parameterNumber != null && targetBusValue != busToUse) {
      try {
        await _distingCubit!.updateParameterValue(
          algorithmIndex: targetAlgorithmIndex,
          parameterNumber: targetInputPort.parameterNumber!,
          value: busToUse,
          userIsChangingTheValue: false,
        );
        targetUpdated = true;
      } catch (e) {
        // Intentionally empty
      }
    } else if (targetBusValue == busToUse) {
      targetUpdated = true; // Already has the correct bus
    } else {}

    if (sourceUpdated && targetUpdated) {
      return busToUse;
    } else {
      throw StateError(
        'Failed to update bus parameters - algorithms may not be found',
      );
    }
  }

  /// Find the algorithm index for a given port ID
  int? _findAlgorithmIndexForPort(
    RoutingEditorStateLoaded state,
    String portId,
  ) {
    for (int i = 0; i < state.algorithms.length; i++) {
      final algorithm = state.algorithms[i];

      // Check input ports
      for (final port in algorithm.inputPorts) {
        if (port.id == portId) {
          return algorithm.index;
        }
      }

      // Check output ports
      for (final port in algorithm.outputPorts) {
        if (port.id == portId) {
          return algorithm.index;
        }
      }
    }

    return null;
  }

  /// Find the first available internal bus, preferring aux (21-28),
  /// then input (1-12), then output (13-20), excluding ES-5 by default.
  Future<int?> _findFirstAvailableInternalBus(
    RoutingEditorStateLoaded state,
  ) async {
    // Get actual parameter values from live slot data to determine bus usage
    final distingState = _distingCubit?.state;
    if (distingState is! DistingStateSynchronized) {
      return null;
    }

    // Get all currently used bus numbers from actual hardware values
    final usedBuses = <int>{};

    // Check all algorithm ports for their current bus assignments from live slot data
    for (final algorithm in state.algorithms) {
      if (algorithm.index >= distingState.slots.length) continue;

      final slot = distingState.slots[algorithm.index];

      // Check input port parameters
      for (final port in algorithm.inputPorts) {
        if (port.parameterNumber != null) {
          try {
            final paramValue = slot.values
                .firstWhere(
                  (v) => v.parameterNumber == port.parameterNumber!,
                  orElse: () => throw StateError('Parameter not found'),
                )
                .value;

            if (paramValue > 0) {
              usedBuses.add(paramValue);
            }
          } catch (e) {
            // Parameter not found, skip
          }
        }
      }

      // Check output port parameters
      for (final port in algorithm.outputPorts) {
        if (port.parameterNumber != null) {
          try {
            final paramValue = slot.values
                .firstWhere(
                  (v) => v.parameterNumber == port.parameterNumber!,
                  orElse: () => throw StateError('Parameter not found'),
                )
                .value;

            if (paramValue > 0) {
              usedBuses.add(paramValue);
            }
          } catch (e) {
            // Parameter not found, skip
          }
        }
      }
    }

    // Search order: AUX (21–28) → INPUT (1–12) → OUTPUT (13–20)
    // AUX preferred to avoid implicitly tying to physical I/O.
    int? pickFrom(int min, int max) {
      for (int b = min; b <= max; b++) {
        if (!usedBuses.contains(b)) return b;
      }
      return null;
    }

    return pickFrom(21, 28) ?? pickFrom(1, 12) ?? pickFrom(13, 20);
  }

  /// Delete an existing connection by ID
  Future<void> deleteConnection(String connectionId) async {
    final currentState = state;
    if (currentState is! RoutingEditorStateLoaded) {
      return;
    }

    try {
      // Find the connection to delete
      final connectionToDelete = currentState.connections.firstWhere(
        (connection) => connection.id == connectionId,
        orElse: () =>
            throw ArgumentError('Connection not found: $connectionId'),
      );

      // Clear the bus assignments in hardware
      await _clearBusAssignmentsForConnection(connectionToDelete, currentState);

      // Trust the DistingCubit to send us an updated state via the stream subscription
      // The _processSynchronizedState method will rebuild everything from hardware truth
      // DO NOT manually modify the local state here

      _findPortById(currentState, connectionToDelete.sourcePortId);
      _findPortById(currentState, connectionToDelete.destinationPortId);
    } catch (e) {
      // Intentionally empty
    }
  }

  /// Delete all connections for a specific port
  Future<void> deleteConnectionsForPort(String portId) async {
    final currentState = state;
    if (currentState is! RoutingEditorStateLoaded) {
      return;
    }

    try {
      final connectionsToDelete = currentState.connections
          .where(
            (connection) =>
                connection.sourcePortId == portId ||
                connection.destinationPortId == portId,
          )
          .toList();

      if (connectionsToDelete.isEmpty) {
        return;
      }

      // Delete each connection (which will also clear bus assignments)
      for (final connection in connectionsToDelete) {
        await deleteConnection(connection.id);
      }
    } catch (e) {
      // Intentionally empty
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
      return;
    }

    try {
      final connectionIndex = currentState.connections.indexWhere(
        (connection) => connection.id == connectionId,
      );

      if (connectionIndex == -1) {
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

      emit(
        currentState.copyWith(connections: updatedConnections, lastError: null),
      );
    } catch (e) {
      // Intentionally empty
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

    // Check ES-5 inputs
    for (final port in state.es5Inputs) {
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

  /// Helper method to find a port by ID and return both the port and its algorithm index
  (Port?, int?) _findPortWithAlgorithmIndex(
    RoutingEditorStateLoaded state,
    String portId,
  ) {
    // Check physical inputs (no algorithm index)
    for (final port in state.physicalInputs) {
      if (port.id == portId) return (port, null);
    }

    // Check physical outputs (no algorithm index)
    for (final port in state.physicalOutputs) {
      if (port.id == portId) return (port, null);
    }

    // Check ES-5 inputs (no algorithm index)
    for (final port in state.es5Inputs) {
      if (port.id == portId) return (port, null);
    }

    // Check algorithm ports
    for (final algorithm in state.algorithms) {
      for (final port in algorithm.inputPorts) {
        if (port.id == portId) return (port, algorithm.index);
      }
      for (final port in algorithm.outputPorts) {
        if (port.id == portId) return (port, algorithm.index);
      }
    }

    return (null, null);
  }

  /// Helper method to check if two ports can be connected

  /// Helper method to determine if a connection is a ghost connection
  /// Ghost connections occur when an algorithm output connects to a physical input

  /// Helper method to determine the type of connection based on port IDs
  ConnectionType _determineConnectionType(
    String sourcePortId,
    String targetPortId,
  ) {
    final isSourceHardware = sourcePortId.startsWith('hw_in_');
    final isTargetHardware = targetPortId.startsWith('hw_out_');
    final isTargetEs5 = targetPortId.startsWith('es5_');

    if (isSourceHardware) {
      return ConnectionType.hardwareInput;
    } else if (isTargetHardware || isTargetEs5) {
      return ConnectionType.hardwareOutput;
    } else {
      return ConnectionType.algorithmToAlgorithm;
    }
  }

  /// Test helper method to expose _determineConnectionType for testing
  @visibleForTesting
  ConnectionType testDetermineConnectionType(
    String sourcePortId,
    String targetPortId,
  ) {
    return _determineConnectionType(sourcePortId, targetPortId);
  }

  /// Helper method to find existing connection between two ports
  Connection? _findExistingConnection(
    RoutingEditorStateLoaded state,
    String sourcePortId,
    String targetPortId,
  ) {
    try {
      return state.connections.firstWhere(
        (connection) =>
            connection.sourcePortId == sourcePortId &&
            connection.destinationPortId == targetPortId,
      );
    } catch (e) {
      return null;
    }
  }

  /// Create a new routing bus
  Future<void> createBus({
    required String name,
    OutputMode defaultOutputMode = OutputMode.add,
    double masterGain = 1.0,
  }) async {
    final currentState = state;
    if (currentState is! RoutingEditorStateLoaded) {
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

      emit(currentState.copyWith(buses: updatedBuses, lastError: null));

      // Mark hardware as out of sync after local changes
      await _autoSyncToHardware();
    } catch (e) {
      // Intentionally empty
    }
  }

  /// Delete a routing bus and reassign its connections
  Future<void> deleteBus(String busId) async {
    final currentState = state;
    if (currentState is! RoutingEditorStateLoaded) {
      return;
    }

    try {
      // Find the bus to delete
      currentState.buses.firstWhere(
        (bus) => bus.id == busId,
        orElse: () => throw ArgumentError('Bus not found: $busId'),
      );

      // Remove bus assignment from all connections
      final updatedConnections = currentState.connections.map((connection) {
        if (connection.busId == busId) {
          return connection.copyWith(busId: null, modifiedAt: DateTime.now());
        }
        return connection;
      }).toList();

      // Remove bus from state
      final updatedBuses = currentState.buses
          .where((bus) => bus.id != busId)
          .toList();

      emit(
        currentState.copyWith(
          buses: updatedBuses,
          connections: updatedConnections,
          lastError: null,
        ),
      );
    } catch (e) {
      // Intentionally empty
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
      return;
    }

    try {
      // Find the connection
      final connectionIndex = currentState.connections.indexWhere(
        (connection) => connection.id == connectionId,
      );

      if (connectionIndex == -1) {
        return;
      }

      // Find the bus
      final busIndex = currentState.buses.indexWhere((bus) => bus.id == busId);

      if (busIndex == -1) {
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
              status: oldBusConnectionIds.isEmpty
                  ? BusStatus.available
                  : BusStatus.assigned,
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

      emit(
        currentState.copyWith(
          connections: updatedConnections,
          buses: updatedBuses,
          lastError: null,
        ),
      );
    } catch (e) {
      // Intentionally empty
    }
  }

  /// Remove a connection from its assigned bus
  Future<void> unassignConnectionFromBus(String connectionId) async {
    final currentState = state;
    if (currentState is! RoutingEditorStateLoaded) {
      return;
    }

    try {
      // Find the connection
      final connectionIndex = currentState.connections.indexWhere(
        (connection) => connection.id == connectionId,
      );

      if (connectionIndex == -1) {
        return;
      }

      final existingConnection = currentState.connections[connectionIndex];

      if (existingConnection.busId == null) {
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
            status: updatedConnectionIds.isEmpty
                ? BusStatus.available
                : BusStatus.assigned,
            modifiedAt: DateTime.now(),
          );
        }
        return bus;
      }).toList();

      emit(
        currentState.copyWith(
          connections: updatedConnections,
          buses: updatedBuses,
          lastError: null,
        ),
      );
    } catch (e) {
      // Intentionally empty
    }
  }

  /// Toggle output mode for a specific port
  Future<void> togglePortOutputMode({required String portId}) async {
    final currentState = state;
    if (currentState is! RoutingEditorStateLoaded) {
      return;
    }

    if (_distingCubit == null) {
      return;
    }

    try {
      // Find the port and its algorithm index
      final (port, algorithmIndex) = _findPortWithAlgorithmIndex(
        currentState,
        portId,
      );
      if (port == null) {
        return;
      }

      // Verify it's an output port
      if (port.direction != PortDirection.output) {
        return;
      }

      // Verify we have mode parameter information
      if (port.modeParameterNumber == null || algorithmIndex == null) {
        // For algorithms without mode parameters, we silently ignore the request
        // rather than showing an error to the user
        return;
      }

      // Get current parameter value from the actual slot data
      final distingState = _distingCubit.state;
      if (distingState is! DistingStateSynchronized) {
        return;
      }

      if (algorithmIndex >= distingState.slots.length) {
        return;
      }

      final currentSlot = distingState.slots[algorithmIndex];

      // Find the current value of the mode parameter
      final currentParamValue = currentSlot.values
          .firstWhere(
            (v) => v.parameterNumber == port.modeParameterNumber!,
            orElse: () => throw StateError(
              'Mode parameter ${port.modeParameterNumber} not found in slot',
            ),
          )
          .value;

      // Toggle the parameter value: 0=Add, 1=Replace
      final newParamValue = currentParamValue == 0 ? 1 : 0;
      newParamValue == 1 ? OutputMode.replace : OutputMode.add;

      // Update the hardware parameter via DistingCubit
      await _distingCubit.updateParameterValue(
        algorithmIndex: algorithmIndex,
        parameterNumber: port.modeParameterNumber!,
        value: newParamValue,
        userIsChangingTheValue: true,
      );
    } catch (e) {
      // Intentionally empty
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
      return;
    }

    try {
      final busIndex = currentState.buses.indexWhere((bus) => bus.id == busId);

      if (busIndex == -1) {
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

      emit(currentState.copyWith(buses: updatedBuses, lastError: null));
    } catch (e) {
      // Intentionally empty
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
      return;
    }

    try {
      final defaultBuses = [
        RoutingBus(
          id: 'bus_audio_main',
          name: 'Audio Main',
          status: BusStatus.available,
          defaultOutputMode: OutputMode.add,
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

        emit(currentState.copyWith(buses: updatedBuses, lastError: null));
      }
    } catch (e) {
      // Intentionally empty
    }
  }

  /// Sync the current routing editor state with hardware
  Future<void> syncToHardware() async {
    final currentState = state;
    if (currentState is! RoutingEditorStateLoaded) {
      return;
    }

    emit(currentState.copyWith(subState: SubState.syncing));

    try {
      // Update sync status
      final syncTime = DateTime.now();

      emit(
        currentState.copyWith(
          isHardwareSynced: true,
          lastSyncTime: syncTime,
          lastError: null,
        ),
      );
    } catch (e) {
      emit(
        currentState.copyWith(
          subState: SubState.error,
          lastError: e.toString(),
        ),
      );
    }
  }

  /// Sync hardware routing data to the routing editor state
  Future<void> syncFromHardware() async {
    final currentState = state;
    if (currentState is! RoutingEditorStateLoaded) {
      return;
    }

    emit(currentState.copyWith(subState: SubState.syncing));

    try {
      // Trigger hardware routing refresh through DistingCubit
      await _distingCubit?.refreshRouting();

      // The state will be updated through the stream subscription
      // when _processSynchronizedState is called
    } catch (e) {
      // Intentionally empty
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
    if (currentState is RoutingEditorStateLoaded &&
        currentState.isHardwareSynced) {
      emit(currentState.copyWith(isHardwareSynced: false, lastError: null));
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
      emit(
        (state as RoutingEditorStateLoaded).copyWith(
          subState: SubState.refreshing,
        ),
      );
    }

    try {
      await _distingCubit?.refreshRouting();
      // State will be updated through the stream subscription
    } catch (e) {
      // Intentionally empty
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
      return;
    }

    emit(currentState.copyWith(subState: SubState.persisting));

    try {
      if (_prefs == null) {
        return;
      }
      final prefs = await _prefs!;

      // Prepare state data for serialization
      final stateData = {
        'connections': currentState.connections
            .map(
              (connection) => {
                'id': connection.id,
                'sourcePortId': connection.sourcePortId,
                'targetPortId': connection.destinationPortId,
                'busId': connection.busId,
                'outputMode': connection.outputMode?.name,
                'gain': connection.gain,
                'isMuted': connection.isMuted,
                'createdAt': connection.createdAt?.toIso8601String(),
                'modifiedAt': connection.modifiedAt?.toIso8601String(),
              },
            )
            .toList(),
        'buses': currentState.buses
            .map(
              (bus) => {
                'id': bus.id,
                'name': bus.name,
                'status': bus.status.name,
                'connectionIds': bus.connectionIds,
                'defaultOutputMode': bus.defaultOutputMode.name,
                'masterGain': bus.masterGain,
                'createdAt': bus.createdAt?.toIso8601String(),
                'modifiedAt': bus.modifiedAt?.toIso8601String(),
              },
            )
            .toList(),
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
      emit(
        currentState.copyWith(
          isPersistenceEnabled: true,
          lastPersistTime: persistTime,
          lastError: null,
        ),
      );
    } catch (e) {
      // Intentionally empty
    }
  }

  /// Load routing editor state from persistent storage
  Future<void> _loadPersistedState() async {
    try {
      if (_prefs == null) {
        return;
      }
      final prefs = await _prefs!;
      final jsonString = prefs.getString('routing_editor_state');

      if (jsonString == null) {
        return;
      }

      final stateData = jsonDecode(jsonString) as Map<String, dynamic>;

      // Parse connections
      final connections = <Connection>[];
      for (final connectionData in stateData['connections'] as List) {
        final connectionMap = connectionData as Map<String, dynamic>;
        connections.add(
          Connection(
            id: connectionMap['id'] as String,
            sourcePortId: connectionMap['sourcePortId'] as String,
            destinationPortId: connectionMap['targetPortId'] as String,
            connectionType: ConnectionType.values.firstWhere(
              (type) => type.name == connectionMap['connectionType'],
              orElse: () => ConnectionType.algorithmToAlgorithm,
            ),
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
          ),
        );
      }

      // Parse buses
      final buses = <RoutingBus>[];
      for (final busData in stateData['buses'] as List) {
        final busMap = busData as Map<String, dynamic>;
        buses.add(
          RoutingBus(
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
          ),
        );
      }

      // Parse port output modes
      final portOutputModes = <String, OutputMode>{};
      final portModeData =
          stateData['portOutputModes'] as Map<String, dynamic>?;
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
    } catch (e) {
      // Don't emit error state here, just log and continue with empty state
    }
  }

  /// Clear all persisted state data
  Future<void> clearPersistedState() async {
    try {
      if (_prefs == null) {
        return;
      }
      final prefs = await _prefs!;
      await prefs.remove('routing_editor_state');

      final currentState = state;
      if (currentState is RoutingEditorStateLoaded) {
        emit(
          currentState.copyWith(
            isPersistenceEnabled: false,
            lastPersistTime: null,
            lastError: null,
          ),
        );
      }
    } catch (e) {
      // Intentionally empty
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
    if (currentState is RoutingEditorStateLoaded &&
        currentState.isPersistenceEnabled) {
      await saveState();
    }
  }

  /// Enhanced error recovery method
  Future<void> recoverFromError() async {
    final currentState = state;
    if (currentState is RoutingEditorStateLoaded &&
        currentState.lastError != null) {
      try {
        // Try to reload the last known good state
        await _loadPersistedState();

        // If no persisted state, return to initial state
        emit(const RoutingEditorState.initial());
      } catch (e) {
        // Intentionally empty
      }
    }
  }

  // Connection Deletion Business Logic (UI-agnostic)

  /// Delete a connection by ID with smart bus assignment logic
  /// This method handles the core business logic for connection deletion
  /// including bus clearing for different connection types
  Future<void> deleteConnectionWithSmartBusLogic(String connectionId) async {
    final currentState = state;
    if (currentState is! RoutingEditorStateLoaded) return;

    try {
      // Validate connection exists
      if (!currentState.connections.any((conn) => conn.id == connectionId)) {
        throw ArgumentError('Connection not found: $connectionId');
      }

      // Get connection details before deletion
      currentState.connections.firstWhere((conn) => conn.id == connectionId);

      // This just calls deleteConnection which already handles clearing bus assignments
      await deleteConnection(connectionId);
    } catch (e) {
      // Intentionally empty
    }
  }

  /// Clear bus assignments for a connection by setting parameter values to 0
  Future<void> _clearBusAssignmentsForConnection(
    Connection connection,
    RoutingEditorStateLoaded state,
  ) async {
    if (_distingCubit == null) return;

    try {
      // Find the source and destination ports
      final sourcePort = _findPortById(state, connection.sourcePortId);
      final targetPort = _findPortById(state, connection.destinationPortId);

      if (sourcePort == null || targetPort == null) {
        return;
      }

      // Use the input-only deletion pattern:
      // 1. If target is a physical output: Clear the SOURCE output bus (physical outputs don't have parameters)
      // 2. Otherwise: Clear only the TARGET input bus (preserves multi-connections from outputs)

      if (connection.destinationPortId.startsWith('hw_out_') ||
          connection.destinationPortId.startsWith('es5_')) {
        // Target is physical output (hardware or ES-5) - clear the SOURCE output bus
        if (sourcePort.parameterNumber != null &&
            !connection.sourcePortId.startsWith('hw_')) {
          // Find which algorithm this port belongs to
          for (final algorithm in state.algorithms) {
            for (final port in algorithm.outputPorts) {
              if (port.id == sourcePort.id && port.parameterNumber != null) {
                if (!_canClearBusAssignment(
                  algorithmIndex: algorithm.index,
                  parameterNumber: port.parameterNumber!,
                )) {
                  // Some outputs have no "None" (min > 0). In that case, "disconnect"
                  // from physical outputs by moving the output to an unused
                  // non-physical-output bus (aux preferred).
                  final newBus = await _findFirstAvailableNonPhysicalOutputBus(
                    state,
                    algorithmIndex: algorithm.index,
                    parameterNumber: port.parameterNumber!,
                  );
                  if (newBus == null) return;

                  await _distingCubit.updateParameterValue(
                    algorithmIndex: algorithm.index,
                    parameterNumber: port.parameterNumber!,
                    value: newBus,
                    userIsChangingTheValue: false,
                  );
                  return;
                }
                await _distingCubit.updateParameterValue(
                  algorithmIndex: algorithm.index,
                  parameterNumber: port.parameterNumber!,
                  value: 0, // 0 means "None" for bus assignments
                  userIsChangingTheValue: false,
                );
                break;
              }
            }
          }
        }
      } else {
        // Target is algorithm input - clear only the TARGET input bus
        if (targetPort.parameterNumber != null &&
            !connection.destinationPortId.startsWith('hw_')) {
          // Find which algorithm this port belongs to
          for (final algorithm in state.algorithms) {
            for (final port in algorithm.inputPorts) {
              if (port.id == targetPort.id && port.parameterNumber != null) {
                if (!_canClearBusAssignment(
                  algorithmIndex: algorithm.index,
                  parameterNumber: port.parameterNumber!,
                )) {
                  return;
                }
                await _distingCubit.updateParameterValue(
                  algorithmIndex: algorithm.index,
                  parameterNumber: port.parameterNumber!,
                  value: 0, // 0 means "None" for bus assignments
                  userIsChangingTheValue: false,
                );
                break;
              }
            }
          }
        }
      }
    } catch (e) {
      // Don't rethrow - we still want to delete the connection from UI
    }
  }

  bool _canClearBusAssignment({
    required int algorithmIndex,
    required int parameterNumber,
  }) {
    final distingState = _distingCubit?.state;
    if (distingState is! DistingStateSynchronized) {
      return true;
    }
    if (algorithmIndex < 0 || algorithmIndex >= distingState.slots.length) {
      return true;
    }
    final slot = distingState.slots[algorithmIndex];
    for (final p in slot.parameters) {
      if (p.parameterNumber == parameterNumber) {
        // If min > 0, parameter doesn't support "None" (0).
        return p.min <= 0;
      }
    }
    return true;
  }

  ({int min, int max})? _getBusParameterRange({
    required int algorithmIndex,
    required int parameterNumber,
  }) {
    final distingState = _distingCubit?.state;
    if (distingState is! DistingStateSynchronized) {
      return null;
    }
    if (algorithmIndex < 0 || algorithmIndex >= distingState.slots.length) {
      return null;
    }
    final slot = distingState.slots[algorithmIndex];
    for (final p in slot.parameters) {
      if (p.parameterNumber == parameterNumber) {
        return (min: p.min, max: p.max);
      }
    }
    return null;
  }

  Future<int?> _findFirstAvailableNonPhysicalOutputBus(
    RoutingEditorStateLoaded state, {
    required int algorithmIndex,
    required int parameterNumber,
  }) async {
    final range = _getBusParameterRange(
      algorithmIndex: algorithmIndex,
      parameterNumber: parameterNumber,
    );
    if (range == null) return null;

    // Determine currently-used bus numbers from live hardware values.
    final distingState = _distingCubit?.state;
    if (distingState is! DistingStateSynchronized) {
      return null;
    }

    final usedBuses = <int>{};
    for (final algorithm in state.algorithms) {
      if (algorithm.index >= distingState.slots.length) continue;
      final slot = distingState.slots[algorithm.index];

      for (final port in algorithm.inputPorts) {
        final paramNumber = port.parameterNumber;
        if (paramNumber == null) continue;
        final v = slot.values
            .firstWhere(
              (pv) => pv.parameterNumber == paramNumber,
              orElse: () => ParameterValue(
                algorithmIndex: algorithm.index,
                parameterNumber: paramNumber,
                value: 0,
              ),
            )
            .value;
        if (v > 0) usedBuses.add(v);
      }

      for (final port in algorithm.outputPorts) {
        final paramNumber = port.parameterNumber;
        if (paramNumber == null) continue;
        final v = slot.values
            .firstWhere(
              (pv) => pv.parameterNumber == paramNumber,
              orElse: () => ParameterValue(
                algorithmIndex: algorithm.index,
                parameterNumber: paramNumber,
                value: 0,
              ),
            )
            .value;
        if (v > 0) usedBuses.add(v);
      }
    }

    bool inRange(int b) => b >= range.min && b <= range.max;
    bool isPhysicalOutputBus(int b) => b >= 13 && b <= 20;

    // Prefer auxiliary buses (21–28), then fall back to input buses (1–12),
    // always avoiding physical output buses (13–20).
    for (int b = 21; b <= 28; b++) {
      if (inRange(b) && !usedBuses.contains(b)) return b;
    }
    for (int b = 1; b <= 12; b++) {
      if (inRange(b) && !usedBuses.contains(b)) return b;
    }

    // As a last resort, scan the parameter's allowed range for any unused bus
    // that isn't a physical output bus.
    for (int b = range.min; b <= range.max; b++) {
      if (isPhysicalOutputBus(b)) continue;
      if (!usedBuses.contains(b)) return b;
    }

    return null;
  }

  /// Inject the layout algorithm service
  void injectLayoutAlgorithm(NodeLayoutAlgorithm layoutAlgorithm) {
    if (_layoutAlgorithm != null) {
      throw StateError('Layout algorithm service already injected');
    }
    _layoutAlgorithm = layoutAlgorithm;
  }

  /// Apply the layout algorithm to optimize node positions
  Future<void> applyLayoutAlgorithm() async {
    final currentState = state;
    if (currentState is! RoutingEditorStateLoaded) {
      return;
    }

    _layoutAlgorithm ??= NodeLayoutAlgorithm();

    try {
      // Show loading state
      emit(currentState.copyWith(subState: SubState.syncing));

      // Calculate optimal layout using the algorithm
      final layoutResult = _layoutAlgorithm!.calculateLayout(
        physicalInputs: currentState.physicalInputs,
        physicalOutputs: currentState.physicalOutputs,
        es5Inputs: currentState.es5Inputs,
        algorithms: currentState.algorithms,
        connections: currentState.connections,
      );

      // Merge existing node positions with new calculated positions
      // This preserves any custom-positioned nodes not managed by the layout algorithm
      final updatedNodePositions = Map<String, NodePosition>.from(
        currentState.nodePositions,
      );

      // Update physical input positions
      updatedNodePositions.addAll(layoutResult.physicalInputPositions);

      // Update physical output positions
      updatedNodePositions.addAll(layoutResult.physicalOutputPositions);

      // Update ES-5 input positions
      updatedNodePositions.addAll(layoutResult.es5InputPositions);

      // Update algorithm positions
      updatedNodePositions.addAll(layoutResult.algorithmPositions);

      // Emit updated state with new positions
      emit(
        currentState.copyWith(
          nodePositions: updatedNodePositions,
          subState: SubState.idle,
          lastError: null,
        ),
      );

      // Save the new positions to preferences
      await saveNodePositions();
    } catch (e) {
      emit(
        currentState.copyWith(
          subState: SubState.error,
          lastError: 'Layout calculation failed: $e',
        ),
      );
    }
  }

  /// Save node positions to SharedPreferences for the current preset
  Future<void> saveNodePositions() async {
    final currentState = state;
    if (currentState is! RoutingEditorStateLoaded) return;

    final distingState = _distingCubit?.state;
    if (distingState == null) return;

    // Get preset name from synchronized state directly
    if (distingState is! DistingStateSynchronized) return;
    final presetName = distingState.presetName;
    if (presetName.isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'routing_positions_$presetName';

      // Convert NodePosition map to JSON-serializable format
      final positionsMap = <String, Map<String, double>>{};
      for (final entry in currentState.nodePositions.entries) {
        positionsMap[entry.key] = {'x': entry.value.x, 'y': entry.value.y};
      }

      final json = jsonEncode(positionsMap);
      await prefs.setString(key, json);
    } catch (e) {
      // Intentionally empty
    }
  }

  /// Load node positions from SharedPreferences for the current preset
  Future<void> loadNodePositions() async {
    final currentState = state;
    if (currentState is! RoutingEditorStateLoaded) return;

    final distingState = _distingCubit?.state;
    if (distingState == null) return;

    if (distingState is! DistingStateSynchronized) return;
    final presetName = distingState.presetName;
    if (presetName.isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'routing_positions_$presetName';
      final json = prefs.getString(key);

      if (json != null) {
        final positionsMap = jsonDecode(json) as Map<String, dynamic>;
        final nodePositions = <String, NodePosition>{};

        for (final entry in positionsMap.entries) {
          final pos = entry.value as Map<String, dynamic>;
          nodePositions[entry.key] = NodePosition(
            x: (pos['x'] as num).toDouble(),
            y: (pos['y'] as num).toDouble(),
          );
        }

        emit(currentState.copyWith(nodePositions: nodePositions));
      }
    } catch (e) {
      // Intentionally empty
    }
  }

  /// Update a single node position and save to preferences
  Future<void> updateNodePosition(String nodeId, double x, double y) async {
    final currentState = state;
    if (currentState is! RoutingEditorStateLoaded) return;

    final updatedPositions = Map<String, NodePosition>.from(
      currentState.nodePositions,
    );
    updatedPositions[nodeId] = NodePosition(x: x, y: y);

    emit(currentState.copyWith(nodePositions: updatedPositions));

    // Save positions after update
    await saveNodePositions();
  }

  /// Update zoom level with bounds checking
  void setZoomLevel(double zoomLevel) {
    final currentState = state;
    if (currentState is! RoutingEditorStateLoaded) return;

    // Clamp zoom level between 0.1x and 2.0x
    final clampedZoom = zoomLevel.clamp(0.1, 2.0);

    emit(currentState.copyWith(zoomLevel: clampedZoom));
  }

  /// Zoom in by a factor
  void zoomIn([double factor = 1.2]) {
    final currentState = state;
    if (currentState is! RoutingEditorStateLoaded) return;

    setZoomLevel(currentState.zoomLevel * factor);
  }

  /// Zoom out by a factor
  void zoomOut([double factor = 1.2]) {
    final currentState = state;
    if (currentState is! RoutingEditorStateLoaded) return;

    setZoomLevel(currentState.zoomLevel / factor);
  }

  /// Reset zoom to 100%
  void resetZoom() {
    final currentState = state;
    if (currentState is! RoutingEditorStateLoaded) return;

    emit(currentState.copyWith(zoomLevel: 1.0));
  }

  /// Update pan offset
  void updatePanOffset(Offset offset) {
    final currentState = state;
    if (currentState is! RoutingEditorStateLoaded) return;

    emit(currentState.copyWith(panOffset: offset));
  }

  /// Get available zoom levels for dropdown
  static List<double> get availableZoomLevels => [
    0.25,
    0.33,
    0.5,
    0.67,
    0.75,
    1.0,
    1.25,
    1.5,
    2.0,
  ];

  /// Get zoom percentage as integer
  int get zoomPercentage {
    final currentState = state;
    if (currentState is RoutingEditorStateLoaded) {
      return (currentState.zoomLevel * 100).round();
    }
    return 100;
  }

  @override
  Future<void> close() {
    _distingStateSubscription?.cancel();
    return super.close();
  }
}
