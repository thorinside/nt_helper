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
import 'package:nt_helper/ui/widgets/routing/connection_validator.dart'
    as ui_validator;
import 'package:nt_helper/core/routing/node_layout_algorithm.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nt_helper/core/routing/models/es5_hardware_node.dart';
import 'package:nt_helper/core/routing/bus_spec.dart';

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
  List<Slot>? _lastProcessedSlots;

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
            availableFirmwareUpdate,
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
  /// Only skips processing when the slots list is the exact same reference
  /// (meaning a non-slot field changed, like loading or screenshot). Otherwise,
  /// always recalculates — Bloc's emit() deduplicates via Freezed equality,
  /// so unchanged routing results won't trigger UI rebuilds.
  void _processSynchronizedState(List<Slot> slots) {
    // Identical reference means non-slot fields changed (loading, screenshot, etc.)
    if (identical(slots, _lastProcessedSlots)) return;

    _lastProcessedSlots = slots;

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

      // Compute AUX bus usage info
      final distingState = _distingCubit?.state;
      final hasExtended =
          distingState is DistingStateSynchronized &&
          distingState.firmwareVersion.hasExtendedAuxBuses;
      final auxBusUsage = _computeAuxBusUsage(algorithms, slots, hasExtended);

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
          auxBusUsage: auxBusUsage,
          hasExtendedAuxBuses: hasExtended,
        ),
      );

      // Initialize default buses after loading (fire and forget)
      initializeDefaultBuses();

      // Load saved node positions for this preset
      loadNodePositions();
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('Routing processing error: $e\n$stackTrace');
      }
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
    return List.generate(12, (i) {
      final n = i + 1;
      return Port(
        id: 'hw_in_$n',
        name: 'I$n',
        type: PortType.cv,
        direction: PortDirection.output,
        hardwareIndex: n,
        role: PortRole.physicalInputBus,
      );
    });
  }

  /// Create the 8 physical output ports of the Disting NT
  List<Port> _createPhysicalOutputPorts() {
    return List.generate(8, (i) {
      final n = i + 1;
      return Port(
        id: 'hw_out_$n',
        name: 'O$n',
        type: PortType.audio,
        direction: PortDirection.input,
        hardwareIndex: n,
        role: PortRole.physicalOutputBus,
      );
    });
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
      final sourcePort = _findPortById(currentState, sourcePortId);
      final targetPort = _findPortById(currentState, targetPortId);

      if (sourcePort == null) {
        throw ArgumentError('Source port not found: $sourcePortId');
      }

      if (targetPort == null) {
        throw ArgumentError('Target port not found: $targetPortId');
      }

      // Validate connection using symmetric ConnectionValidator
      if (!ui_validator.ConnectionValidator.isValidConnection(
        sourcePort,
        targetPort,
      )) {
        throw ArgumentError(
          'Invalid connection: ${ui_validator.ConnectionValidator.getValidationError(sourcePort, targetPort)}',
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

      // Dispatch bus assignment based on port roles.
      // The ConnectionValidator has already ensured one port is an algorithm
      // port and the other is either a bus or a complementary algorithm port.
      int? busNumber;

      final sourceRole = sourcePort.effectiveRole;
      final targetRole = targetPort.effectiveRole;

      if (sourcePort.isBus && targetPort.isBusReader) {
        // Bus -> algorithm input: assign bus number to the reader
        if (sourceRole == PortRole.physicalInputBus) {
          busNumber = await _assignBusForHardwareInput(
            sourcePortId,
            targetPort,
            currentState,
          );
        } else if (sourceRole == PortRole.physicalOutputBus) {
          busNumber = await _assignBusForPhysicalOutputToAlgorithmInput(
            sourcePortId,
            targetPort,
            currentState,
          );
        } else {
          // ES-5 bus -> algorithm input
          busNumber = await _assignBusForHardwareOutput(
            targetPort,
            sourcePortId,
            currentState,
          );
        }
      } else if (targetPort.isBus && sourcePort.isBusWriter) {
        // Algorithm output -> bus: assign bus number to the writer
        if (ui_validator.ConnectionValidator.isGhostConnection(
          sourcePort,
          targetPort,
        )) {
          busNumber = await _assignBusForGhostConnection(
            sourcePort,
            targetPortId,
            currentState,
          );
        } else {
          busNumber = await _assignBusForHardwareOutput(
            sourcePort,
            targetPortId,
            currentState,
          );
        }
      } else if (sourcePort.isBus && targetPort.isBusWriter) {
        // Physical bus -> algorithm output (ghost in reverse drag direction)
        if (ui_validator.ConnectionValidator.isGhostConnection(
          sourcePort,
          targetPort,
        )) {
          busNumber = await _assignBusForGhostConnection(
            targetPort,
            sourcePortId,
            currentState,
          );
        } else {
          busNumber = await _assignBusForHardwareOutput(
            targetPort,
            sourcePortId,
            currentState,
          );
        }
      } else if (targetPort.isBus && sourcePort.isBusReader) {
        // Algorithm input -> bus: assign bus number to the reader
        if (targetRole == PortRole.physicalInputBus) {
          busNumber = await _assignBusForHardwareInput(
            targetPortId,
            sourcePort,
            currentState,
          );
        } else if (targetRole == PortRole.physicalOutputBus) {
          busNumber = await _assignBusForPhysicalOutputToAlgorithmInput(
            targetPortId,
            sourcePort,
            currentState,
          );
        } else {
          // Algorithm input -> ES-5 bus
          busNumber = await _assignBusForHardwareOutput(
            sourcePort,
            targetPortId,
            currentState,
          );
        }
      } else if (sourceRole == PortRole.busWriter &&
          targetRole == PortRole.busReader) {
        // Algorithm output -> algorithm input: aux buses
        busNumber = await _assignBusForAlgorithmConnection(
          sourcePort,
          targetPort,
          currentState,
        );
      } else if (sourceRole == PortRole.busReader &&
          targetRole == PortRole.busWriter) {
        // Algorithm input -> algorithm output (reverse drag): aux buses
        busNumber = await _assignBusForAlgorithmConnection(
          targetPort,
          sourcePort,
          currentState,
        );
      } else {
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
      rethrow;
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

  /// Assign bus for ghost connection (algorithm output -> physical input)
  ///
  /// Ghost connections route an algorithm's output to a physical input bus (1-12),
  /// making the signal available to other algorithms reading from that input.
  Future<int?> _assignBusForGhostConnection(
    Port algorithmOutputPort,
    String hardwareInputPortId,
    RoutingEditorStateLoaded state,
  ) async {
    final hardwareInputNumber = int.tryParse(
      hardwareInputPortId.replaceAll('hw_in_', ''),
    );
    if (hardwareInputNumber == null ||
        hardwareInputNumber < 1 ||
        hardwareInputNumber > 12) {
      return null;
    }

    final busNumber = hardwareInputNumber;

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

  /// Assign bus for physical output -> algorithm input connection
  ///
  /// The algorithm input reads from the output bus (13-20).
  Future<int?> _assignBusForPhysicalOutputToAlgorithmInput(
    String hardwareOutputPortId,
    Port algorithmInputPort,
    RoutingEditorStateLoaded state,
  ) async {
    final hardwareOutputNumber = int.tryParse(
      hardwareOutputPortId.replaceAll('hw_out_', ''),
    );
    if (hardwareOutputNumber == null ||
        hardwareOutputNumber < 1 ||
        hardwareOutputNumber > 8) {
      return null;
    }

    final busNumber = 12 + hardwareOutputNumber; // Bus 13 for hw_out_1, etc.

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

    int busToUse;
    if (sourceBusValue != null && BusSpec.isAux(sourceBusValue)) {
      // Source already on an AUX bus — reuse for fan-out
      busToUse = sourceBusValue;
    } else {
      // Source unassigned or on a physical bus — allocate an AUX bus
      // Add-only sources (no mode parameter) must use an empty bus;
      // sources that support Replace can reuse a bus from lower slots.
      final canReplace = sourceOutputPort.modeParameterNumber != null;
      final availableBus = await _findAvailableAuxBus(
        state,
        sourceAlgorithmIndex,
        allowReuse: canReplace,
      );
      if (availableBus == null) {
        throw StateError('No free AUX busses');
      }
      busToUse = availableBus.bus;
    }

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

    // Set output mode to Replace for algorithm-to-algorithm connections
    if (sourceOutputPort.modeParameterNumber != null) {
      await _distingCubit!.updateParameterValue(
        algorithmIndex: sourceAlgorithmIndex,
        parameterNumber: sourceOutputPort.modeParameterNumber!,
        value: 1, // 1 = Replace
        userIsChangingTheValue: false,
      );
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

  /// Compute per-AUX-bus usage info from the current algorithms and slots.
  Map<int, AuxBusUsageInfo> _computeAuxBusUsage(
    List<RoutingAlgorithm> algorithms,
    List<Slot> slots,
    bool hasExtended,
  ) {
    final auxCeiling = BusSpec.auxMaxForFirmware(
      hasExtendedAuxBuses: hasExtended,
    );
    final result = <int, AuxBusUsageInfo>{};

    for (final algorithm in algorithms) {
      if (algorithm.index >= slots.length) continue;
      final slot = slots[algorithm.index];
      final algoName = slot.algorithm.name;

      for (final port in algorithm.outputPorts) {
        if (port.parameterNumber == null) continue;
        try {
          final paramValue = slot.values
              .firstWhere((v) => v.parameterNumber == port.parameterNumber!)
              .value;
          if (paramValue < BusSpec.auxMin || paramValue > auxCeiling) continue;
          if (!BusSpec.isAux(paramValue)) continue;
          final info = result.putIfAbsent(
            paramValue,
            () => AuxBusUsageInfo(busNumber: paramValue),
          );
          info.algorithmIds.add(algorithm.id);
          info.sourceNames.add(algoName);
        } catch (_) {}
      }

      for (final port in algorithm.inputPorts) {
        if (port.parameterNumber == null) continue;
        try {
          final paramValue = slot.values
              .firstWhere((v) => v.parameterNumber == port.parameterNumber!)
              .value;
          if (paramValue < BusSpec.auxMin || paramValue > auxCeiling) continue;
          if (!BusSpec.isAux(paramValue)) continue;
          final info = result.putIfAbsent(
            paramValue,
            () => AuxBusUsageInfo(busNumber: paramValue),
          );
          info.algorithmIds.add(algorithm.id);
          info.destNames.add(algoName);
        } catch (_) {}
      }
    }

    return result;
  }

  /// Focus algorithms using a specific AUX bus (toggle behavior).
  void focusAuxBus(int busNumber) {
    final currentState = state;
    if (currentState is! RoutingEditorStateLoaded) return;

    final info = currentState.auxBusUsage[busNumber];
    if (info == null || info.algorithmIds.isEmpty) return;

    // Toggle: if already focused on exactly this bus's algorithms, clear focus
    if (currentState.focusedAlgorithmIds.isNotEmpty &&
        currentState.focusedAlgorithmIds.length == info.algorithmIds.length &&
        currentState.focusedAlgorithmIds.containsAll(info.algorithmIds)) {
      clearFocus();
    } else {
      emit(currentState.copyWith(focusedAlgorithmIds: info.algorithmIds));
    }
  }

  /// Find an available AUX bus (21-28) for an algorithm connection.
  ///
  /// A bus is available if it's completely unused, or if all algorithms
  /// currently using it are at slot numbers lower than [sourceSlot]
  /// (i.e., they execute before the source, so a Replace write starts
  /// a clean session).
  Future<_AvailableAuxBus?> _findAvailableAuxBus(
    RoutingEditorStateLoaded state,
    int sourceSlot, {
    bool allowReuse = true,
  }) async {
    final distingState = _distingCubit?.state;
    if (distingState is! DistingStateSynchronized) return null;

    final auxCeiling = BusSpec.auxMaxForFirmware(
      hasExtendedAuxBuses: distingState.firmwareVersion.hasExtendedAuxBuses,
    );

    // Map each AUX bus to the highest slot number that uses it
    final maxSlotPerBus = <int, int>{};
    for (final algorithm in state.algorithms) {
      if (algorithm.index >= distingState.slots.length) continue;
      final slot = distingState.slots[algorithm.index];
      for (final port in [...algorithm.inputPorts, ...algorithm.outputPorts]) {
        if (port.parameterNumber != null) {
          try {
            final paramValue = slot.values
                .firstWhere((v) => v.parameterNumber == port.parameterNumber!)
                .value;
            if (BusSpec.isAux(paramValue)) {
              final current = maxSlotPerBus[paramValue];
              if (current == null || algorithm.index > current) {
                maxSlotPerBus[paramValue] = algorithm.index;
              }
            }
          } catch (_) {}
        }
      }
    }

    // Prefer a completely unused AUX bus first
    for (int b = BusSpec.auxMin; b <= auxCeiling; b++) {
      if (!BusSpec.isAux(b)) continue;
      if (!maxSlotPerBus.containsKey(b)) {
        return _AvailableAuxBus(bus: b, isReused: false);
      }
    }

    // Fall back to a reusable AUX bus whose users are all at lower slots
    if (allowReuse) {
      for (int b = BusSpec.auxMin; b <= auxCeiling; b++) {
        if (!BusSpec.isAux(b)) continue;
        if (maxSlotPerBus[b]! < sourceSlot) {
          return _AvailableAuxBus(bus: b, isReused: true);
        }
      }
    }

    return null;
  }

  /// Build a greedy plan that consolidates as many AUX buses as possible.
  /// Returns `null` if no consolidation is possible.
  AuxBusConsolidationPlan? buildConsolidationPlan() {
    final currentState = state;
    if (currentState is! RoutingEditorStateLoaded) return null;

    final distingState = _distingCubit?.state;
    if (distingState is! DistingStateSynchronized) return null;

    final auxCeiling = BusSpec.auxMaxForFirmware(
      hasExtendedAuxBuses: distingState.firmwareVersion.hasExtendedAuxBuses,
    );

    final busInfo = <int, _AuxBusInfo>{};

    for (final algorithm in currentState.algorithms) {
      if (algorithm.index >= distingState.slots.length) continue;
      final slot = distingState.slots[algorithm.index];

      for (final port in algorithm.outputPorts) {
        if (port.parameterNumber == null) continue;
        try {
          final paramValue = slot.values
              .firstWhere((v) => v.parameterNumber == port.parameterNumber!)
              .value;
          if (paramValue < BusSpec.auxMin || paramValue > auxCeiling) continue;

          final info = busInfo.putIfAbsent(paramValue, () => _AuxBusInfo());
          info.addPort(algorithm.index, isSource: true);
          info.sources.add(
            _SourceRecord(
              algorithm.index,
              port.modeParameterNumber != null,
              port.modeParameterNumber,
            ),
          );
          info.ports.add(_BusPort(algorithm.index, port.parameterNumber!));
        } catch (_) {}
      }

      for (final port in algorithm.inputPorts) {
        if (port.parameterNumber == null) continue;
        try {
          final paramValue = slot.values
              .firstWhere((v) => v.parameterNumber == port.parameterNumber!)
              .value;
          if (paramValue < BusSpec.auxMin || paramValue > auxCeiling) continue;

          final info = busInfo.putIfAbsent(paramValue, () => _AuxBusInfo());
          info.addPort(algorithm.index, isSource: false);
          info.ports.add(_BusPort(algorithm.index, port.parameterNumber!));
        } catch (_) {}
      }
    }

    // Greedily find all possible merges, simulating each one before searching
    // for the next so that updated bus membership is taken into account.
    final merges = <ConsolidationMerge>[];

    bool foundMerge = true;
    while (foundMerge) {
      foundMerge = false;
      final busNumbers = busInfo.keys.toList();

      for (int i = 0; i < busNumbers.length && !foundMerge; i++) {
        for (int j = i + 1; j < busNumbers.length && !foundMerge; j++) {
          final busA = busNumbers[i];
          final busB = busNumbers[j];
          final infoA = busInfo[busA]!;
          final infoB = busInfo[busB]!;

          if (_canMerge(keepInfo: infoA, freeInfo: infoB)) {
            merges.add(
              _buildMerge(
                keepBus: busA,
                freeBus: busB,
                keepBusInfo: infoA,
                freeBusInfo: infoB,
                portsToMove: infoB.ports,
                distingState: distingState,
              ),
            );
            _simulateMerge(busInfo, keepBus: busA, freeBus: busB);
            foundMerge = true;
            break;
          }

          if (_canMerge(keepInfo: infoB, freeInfo: infoA)) {
            merges.add(
              _buildMerge(
                keepBus: busB,
                freeBus: busA,
                keepBusInfo: infoB,
                freeBusInfo: infoA,
                portsToMove: infoA.ports,
                distingState: distingState,
              ),
            );
            _simulateMerge(busInfo, keepBus: busB, freeBus: busA);
            foundMerge = true;
            break;
          }
        }
      }
    }

    if (merges.isEmpty) return null;

    final description = merges.length == 1
        ? merges.first.description
        : 'Free ${merges.length} AUX buses';

    return AuxBusConsolidationPlan(description: description, merges: merges);
  }

  /// Check whether the free bus can be safely merged into the keep bus.
  ///
  /// Requirements:
  /// 1. Keep bus has a Replace-capable source at slot R
  /// 2. Free bus's entire activity (maxSlot) < R
  /// 3. No keep bus ports in the danger zone that aren't also free bus ports
  /// 4. Every source on the merged bus except the lowest-slot one must have
  ///    Replace capability — otherwise earlier data stays on the bus and mixes
  bool _canMerge({
    required _AuxBusInfo keepInfo,
    required _AuxBusInfo freeInfo,
  }) {
    if (keepInfo.replaceSourceSlot == null || freeInfo.maxSlot == null) {
      return false;
    }
    if (keepInfo.replaceSourceSlot! <= freeInfo.maxSlot!) return false;

    // If the free bus has no sources, it's read-only — safe to merge.
    if (freeInfo.minSourceSlot == null) return true;

    // Check for keep bus ports in the danger zone that would be affected
    // by the free bus's source writes.
    final dangerStart = freeInfo.minSourceSlot!;
    final dangerEnd = keepInfo.replaceSourceSlot!;
    for (final slot in keepInfo.portSlots) {
      if (slot >= dangerStart &&
          slot < dangerEnd &&
          !freeInfo.portSlots.contains(slot)) {
        return false;
      }
    }

    // Every source except the lowest-slot one on the merged bus must have
    // Replace capability so each creates a clean session boundary.
    final allSources = [...keepInfo.sources, ...freeInfo.sources];
    allSources.sort((a, b) => a.slot.compareTo(b.slot));
    for (int i = 1; i < allSources.length; i++) {
      if (!allSources[i].canReplace) return false;
    }

    return true;
  }

  /// Simulate a merge in the busInfo map so the next search iteration
  /// sees updated bus membership.
  void _simulateMerge(
    Map<int, _AuxBusInfo> busInfo, {
    required int keepBus,
    required int freeBus,
  }) {
    final keepInfo = busInfo[keepBus]!;
    final freeInfo = busInfo[freeBus]!;

    keepInfo.ports.addAll(freeInfo.ports);
    keepInfo.portSlots.addAll(freeInfo.portSlots);
    keepInfo.sources.addAll(freeInfo.sources);
    if (freeInfo.maxSlot != null) {
      if (keepInfo.maxSlot == null || freeInfo.maxSlot! > keepInfo.maxSlot!) {
        keepInfo.maxSlot = freeInfo.maxSlot;
      }
    }
    busInfo.remove(freeBus);
  }

  ConsolidationMerge _buildMerge({
    required int keepBus,
    required int freeBus,
    required _AuxBusInfo keepBusInfo,
    required _AuxBusInfo freeBusInfo,
    required List<_BusPort> portsToMove,
    required DistingStateSynchronized distingState,
  }) {
    final keepLocal = BusSpec.toLocalNumber(keepBus) ?? keepBus;
    final freeLocal = BusSpec.toLocalNumber(freeBus) ?? freeBus;

    final steps = portsToMove.map((port) {
      String algoName = 'Slot ${port.algorithmIndex}';
      if (port.algorithmIndex < distingState.slots.length) {
        algoName = distingState.slots[port.algorithmIndex].algorithm.name;
      }
      return ConsolidationStep(
        algorithmIndex: port.algorithmIndex,
        algorithmName: algoName,
        parameterNumber: port.parameterNumber,
        fromBus: freeBus,
        toBus: keepBus,
      );
    }).toList();

    // Collect all sources from both buses, sort by slot. Every source except
    // the lowest-slot one needs Replace mode set to create session boundaries.
    final allSources = [...keepBusInfo.sources, ...freeBusInfo.sources];
    allSources.sort((a, b) => a.slot.compareTo(b.slot));

    final replaceModeSteps = <ReplaceModeStep>[];
    for (int i = 1; i < allSources.length; i++) {
      final src = allSources[i];
      if (src.canReplace && src.modeParameterNumber != null) {
        String algoName = 'Slot ${src.slot}';
        if (src.slot < distingState.slots.length) {
          algoName = distingState.slots[src.slot].algorithm.name;
        }
        replaceModeSteps.add(
          ReplaceModeStep(
            algorithmIndex: src.slot,
            algorithmName: algoName,
            parameterNumber: src.modeParameterNumber!,
          ),
        );
      }
    }

    return ConsolidationMerge(
      keepBus: keepBus,
      freeBus: freeBus,
      description: 'Merge AUX $freeLocal into AUX $keepLocal',
      steps: steps,
      replaceModeSteps: replaceModeSteps,
    );
  }

  /// Execute a previously-built consolidation plan, iterating through each
  /// merge and calling progress callbacks as steps complete.
  ///
  /// Paces parameter updates with short delays to let the parameter queue
  /// drain and the model stay in sync with hardware.
  Future<void> executeConsolidationPlan(
    AuxBusConsolidationPlan plan, {
    void Function(int mergeIndex, int stepIndex)? onStepComplete,
    void Function(int mergeIndex, int replaceModeIndex)? onReplaceModeSet,
  }) async {
    const paceDelay = Duration(milliseconds: 150);

    for (int m = 0; m < plan.merges.length; m++) {
      final merge = plan.merges[m];

      for (int r = 0; r < merge.replaceModeSteps.length; r++) {
        final rStep = merge.replaceModeSteps[r];
        await _distingCubit!.updateParameterValue(
          algorithmIndex: rStep.algorithmIndex,
          parameterNumber: rStep.parameterNumber,
          value: 1, // 1 = Replace
          userIsChangingTheValue: false,
        );
        onReplaceModeSet?.call(m, r);
        await Future.delayed(paceDelay);
      }

      for (int i = 0; i < merge.steps.length; i++) {
        final step = merge.steps[i];
        await _distingCubit!.updateParameterValue(
          algorithmIndex: step.algorithmIndex,
          parameterNumber: step.parameterNumber,
          value: merge.keepBus,
          userIsChangingTheValue: false,
        );
        onStepComplete?.call(m, i);
        await Future.delayed(paceDelay);
      }
    }
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

  /// Reset all bus connections for a specific algorithm slot.
  ///
  /// Sets all bus parameters with `min == 0` to 0 (disconnected).
  /// Parameters with `min > 0` are left unchanged.
  /// Returns the number of parameters reset, or -1 if state is not ready.
  Future<int> resetAllConnections(int algorithmIndex) async {
    final distingState = _distingCubit?.state;
    if (distingState is! DistingStateSynchronized) {
      return -1;
    }
    if (algorithmIndex < 0 || algorithmIndex >= distingState.slots.length) {
      return -1;
    }

    final slot = distingState.slots[algorithmIndex];
    var resetCount = 0;

    for (final param in slot.parameters) {
      final isBusParameter =
          param.unit == 1 &&
          (param.min == 0 || param.min == 1) &&
          BusSpec.isBusParameterMaxValue(param.max);

      if (!isBusParameter) continue;
      if (param.min > 0) continue;

      // Look up current value from slot.values
      final currentValue = slot.values
          .where((v) => v.parameterNumber == param.parameterNumber)
          .firstOrNull
          ?.value;
      if (currentValue == null || currentValue == 0) continue;

      await _distingCubit!.updateParameterValue(
        algorithmIndex: algorithmIndex,
        parameterNumber: param.parameterNumber,
        value: 0,
        userIsChangingTheValue: false,
      );
      resetCount++;
    }

    return resetCount;
  }

  /// Move all bus parameter references from [sourceBus] to [destinationBus].
  ///
  /// Iterates every slot's parameters, finds bus parameters currently set to
  /// [sourceBus], and rewrites them to [destinationBus]. The destination must
  /// be an empty (unused) AUX bus. Returns the number of parameters rewritten.
  Future<int> moveAuxBus(int sourceBus, int destinationBus) async {
    final distingState = _distingCubit?.state;
    if (distingState is! DistingStateSynchronized) return -1;

    // Guard: destination must be empty
    final currentState = state;
    if (currentState is RoutingEditorStateLoaded) {
      final destInfo = currentState.auxBusUsage[destinationBus];
      if (destInfo != null && destInfo.sessionCount > 0) return -1;
    }

    const paceDelay = Duration(milliseconds: 150);
    var writeCount = 0;

    for (int slotIdx = 0; slotIdx < distingState.slots.length; slotIdx++) {
      final slot = distingState.slots[slotIdx];

      for (final param in slot.parameters) {
        final isBusParameter =
            param.unit == 1 &&
            (param.min == 0 || param.min == 1) &&
            BusSpec.isBusParameterMaxValue(param.max);
        if (!isBusParameter) continue;

        final currentValue = slot.values
            .where((v) => v.parameterNumber == param.parameterNumber)
            .firstOrNull
            ?.value;
        if (currentValue != sourceBus) continue;

        await _distingCubit!.updateParameterValue(
          algorithmIndex: slotIdx,
          parameterNumber: param.parameterNumber,
          value: destinationBus,
          userIsChangingTheValue: false,
        );
        writeCount++;
        await Future.delayed(paceDelay);
      }
    }

    if (writeCount > 0) {
      await _autoSyncToHardware();
    }

    return writeCount;
  }

  /// Returns a user-facing reason if the connection cannot be deleted, otherwise null.
  ///
  /// Some parameters (notably certain bus inputs/outputs) have `min > 0` and do not
  /// support a "None" (0) value. Attempting to clear those would immediately be
  /// reverted by hardware truth on the next sync.
  String? deletionBlockReasonForConnection(Connection connection) {
    final currentState = state;
    if (currentState is! RoutingEditorStateLoaded) {
      return null;
    }

    // Output→physical-output connections are always "deletable" from the editor
    // perspective: if the output doesn't support "None", we can reassign it to a
    // non-physical-output bus instead of clearing it.
    if (connection.destinationPortId.startsWith('hw_out_') ||
        connection.destinationPortId.startsWith('es5_')) {
      return null;
    }

    // For algorithm-input connections, we clear the destination input bus.
    final targetPort = _findPortById(
      currentState,
      connection.destinationPortId,
    );
    final targetParamNumber = targetPort?.parameterNumber;
    if (targetParamNumber == null) {
      return null;
    }

    final algorithmIndex = _findAlgorithmIndexForPort(
      currentState,
      connection.destinationPortId,
    );
    if (algorithmIndex == null) {
      return null;
    }

    final canClear = _canClearBusAssignment(
      algorithmIndex: algorithmIndex,
      parameterNumber: targetParamNumber,
    );
    return canClear ? null : 'required bus assignment';
  }

  /// Returns a user-facing reason if any connection for this port cannot be deleted.
  String? deletionBlockReasonForPortConnections(String portId) {
    final currentState = state;
    if (currentState is! RoutingEditorStateLoaded) {
      return null;
    }

    final portConnections = currentState.connections
        .where(
          (conn) =>
              conn.sourcePortId == portId || conn.destinationPortId == portId,
        )
        .toList();
    for (final conn in portConnections) {
      final reason = deletionBlockReasonForConnection(conn);
      if (reason != null) return reason;
    }
    return null;
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
    final isSourceHardwareInput = sourcePortId.startsWith('hw_in_');
    final isSourceHardwareOutput = sourcePortId.startsWith('hw_out_');
    final isTargetHardwareOutput = targetPortId.startsWith('hw_out_');
    final isTargetHardwareInput = targetPortId.startsWith('hw_in_');
    final isTargetEs5 = targetPortId.startsWith('es5_');

    if (isSourceHardwareInput) {
      return ConnectionType.hardwareInput;
    } else if (isSourceHardwareOutput) {
      // Physical output -> algorithm input: algorithm reads from output bus
      return ConnectionType.hardwareOutput;
    } else if (isTargetHardwareOutput || isTargetEs5) {
      return ConnectionType.hardwareOutput;
    } else if (isTargetHardwareInput) {
      // Ghost connection: algorithm output -> physical input
      return ConnectionType.hardwareInput;
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

      // Clear both sides of the connection if possible.
      // Physical ports (hw_in/hw_out/es5) don't have parameters to clear.
      await _clearAlgorithmPortBus(sourcePort, state);
      await _clearAlgorithmPortBus(targetPort, state);
    } catch (e) {
      // Don't rethrow - we still want to delete the connection from UI
    }
  }

  /// Clear the bus assignment for an algorithm port, setting it to 0 (None)
  /// if the parameter supports it. Skips physical/ES-5 ports.
  Future<void> _clearAlgorithmPortBus(
    Port port,
    RoutingEditorStateLoaded state,
  ) async {
    if (_distingCubit == null) return;
    if (port.parameterNumber == null) return;
    if (port.isBus) return; // Physical/ES-5 ports don't have parameters

    for (final algorithm in state.algorithms) {
      final match = [...algorithm.inputPorts, ...algorithm.outputPorts]
          .where((p) => p.id == port.id && p.parameterNumber != null)
          .firstOrNull;
      if (match == null) continue;

      if (!_canClearBusAssignment(
        algorithmIndex: algorithm.index,
        parameterNumber: match.parameterNumber!,
      )) {
        // Output can't be set to None — move to an unused non-physical bus
        if (port.isBusWriter) {
          final newBus = await _findFirstAvailableNonPhysicalOutputBus(
            state,
            algorithmIndex: algorithm.index,
            parameterNumber: match.parameterNumber!,
          );
          if (newBus != null) {
            await _distingCubit.updateParameterValue(
              algorithmIndex: algorithm.index,
              parameterNumber: match.parameterNumber!,
              value: newBus,
              userIsChangingTheValue: false,
            );
          }
        }
        return;
      }

      await _distingCubit.updateParameterValue(
        algorithmIndex: algorithm.index,
        parameterNumber: match.parameterNumber!,
        value: 0,
        userIsChangingTheValue: false,
      );
      return;
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
  /// If nodes are focused, applies cascade layout to just those nodes
  Future<void> applyLayoutAlgorithm() async {
    final currentState = state;
    if (currentState is! RoutingEditorStateLoaded) {
      return;
    }

    // If nodes are focused, apply cascade layout to just those nodes
    if (currentState.focusedAlgorithmIds.isNotEmpty) {
      await _applyCascadeLayout(currentState);
      return;
    }

    // Full layout algorithm for all nodes
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

  /// Apply cascade layout to focused nodes only
  /// Arranges nodes in a diagonal stair-step pattern (down-right), sorted by slot
  Future<void> _applyCascadeLayout(
    RoutingEditorStateLoaded currentState,
  ) async {
    final focusedIds = currentState.focusedAlgorithmIds;

    // Find centroid of focused nodes using node centers (not left edges)
    // This ensures applying cascade multiple times doesn't drift
    final focusedPositions = currentState.nodePositions.entries
        .where((e) => focusedIds.contains(e.key))
        .toList();

    if (focusedPositions.isEmpty) return;

    double sumX = 0, sumY = 0;
    for (final pos in focusedPositions) {
      // Use center of node for centroid calculation
      sumX += pos.value.x + pos.value.width / 2;
      sumY += pos.value.y + pos.value.height / 2;
    }
    final centroidX = sumX / focusedPositions.length;
    final centroidY = sumY / focusedPositions.length;

    // Sort focused algorithms by slot number (lower slots first)
    final sortedFocused =
        currentState.algorithms.where((a) => focusedIds.contains(a.id)).toList()
          ..sort((a, b) => a.index.compareTo(b.index));

    // Gap between right edge of one node and left edge of next (2 grid squares)
    const horizontalGap = 100.0;
    const verticalOffset = 100.0;

    final updatedPositions = Map<String, NodePosition>.from(
      currentState.nodePositions,
    );

    // First pass: position nodes starting at x=0, y=0 to build cascade shape
    final tempPositions = <String, (double x, double y, double w, double h)>{};
    double currentX = 0;
    for (int i = 0; i < sortedFocused.length; i++) {
      final algoId = sortedFocused[i].id;
      final existingPos = currentState.nodePositions[algoId];
      final nodeWidth = existingPos?.width ?? 200.0;
      final nodeHeight = existingPos?.height ?? 100.0;

      tempPositions[algoId] = (
        currentX,
        i * verticalOffset,
        nodeWidth,
        nodeHeight,
      );
      currentX += nodeWidth + horizontalGap;
    }

    // Calculate the average center of the cascade at origin
    double sumCascadeCenterX = 0, sumCascadeCenterY = 0;
    for (final entry in tempPositions.entries) {
      final (x, y, w, h) = entry.value;
      sumCascadeCenterX += x + w / 2;
      sumCascadeCenterY += y + h / 2;
    }
    final cascadeCenterX = sumCascadeCenterX / tempPositions.length;
    final cascadeCenterY = sumCascadeCenterY / tempPositions.length;

    // Calculate offset to move cascade center to original centroid
    final offsetX = centroidX - cascadeCenterX;
    final offsetY = centroidY - cascadeCenterY;

    // Apply offset to all node positions
    for (final entry in tempPositions.entries) {
      final (x, y, w, h) = entry.value;
      updatedPositions[entry.key] = NodePosition(
        x: x + offsetX,
        y: y + offsetY,
        width: w,
        height: h,
      );
    }

    emit(
      currentState.copyWith(
        nodePositions: updatedPositions,
        cascadeScrollTarget: Offset(centroidX, centroidY),
      ),
    );
    await saveNodePositions();
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

  /// Update multiple node positions at once (for multi-drag)
  Future<void> updateMultipleNodePositions(Map<String, Offset> updates) async {
    final currentState = state;
    if (currentState is! RoutingEditorStateLoaded) return;

    final updatedPositions = Map<String, NodePosition>.from(
      currentState.nodePositions,
    );
    for (final entry in updates.entries) {
      updatedPositions[entry.key] = NodePosition(
        x: entry.value.dx,
        y: entry.value.dy,
      );
    }

    emit(currentState.copyWith(nodePositions: updatedPositions));

    // Save positions after update
    await saveNodePositions();
  }

  /// Update a node's size (called when widget reports its actual rendered size)
  void updateNodeSize(String nodeId, double width, double height) {
    final currentState = state;
    if (currentState is! RoutingEditorStateLoaded) return;

    final existingPos = currentState.nodePositions[nodeId];
    if (existingPos == null) return;

    // Only update if size actually changed
    if (existingPos.width == width && existingPos.height == height) return;

    final updatedPositions = Map<String, NodePosition>.from(
      currentState.nodePositions,
    );
    updatedPositions[nodeId] = existingPos.copyWith(
      width: width,
      height: height,
    );

    emit(currentState.copyWith(nodePositions: updatedPositions));
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

  // Focus Mode Methods

  /// Toggle focus on an algorithm (add/remove from focused set)
  void toggleAlgorithmFocus(String algorithmId) {
    final currentState = state;
    if (currentState is! RoutingEditorStateLoaded) return;

    final updatedFocused = Set<String>.from(currentState.focusedAlgorithmIds);
    if (updatedFocused.contains(algorithmId)) {
      updatedFocused.remove(algorithmId);
    } else {
      updatedFocused.add(algorithmId);
    }

    emit(currentState.copyWith(focusedAlgorithmIds: updatedFocused));
  }

  /// Set focus to exactly one algorithm (replaces current focus set)
  void setFocusedAlgorithm(String algorithmId) {
    final currentState = state;
    if (currentState is! RoutingEditorStateLoaded) return;

    final nodePos = currentState.nodePositions[algorithmId];
    final scrollTarget = nodePos != null
        ? Offset(nodePos.x + nodePos.width / 2, nodePos.y + nodePos.height / 2)
        : null;

    emit(currentState.copyWith(
      focusedAlgorithmIds: {algorithmId},
      cascadeScrollTarget: scrollTarget,
    ));
  }

  /// Set focus by slot index - finds the algorithm at that slot and focuses it
  void setFocusedAlgorithmBySlotIndex(int slotIndex) {
    final currentState = state;
    if (currentState is! RoutingEditorStateLoaded) return;

    final algorithm = currentState.algorithms
        .where((a) => a.index == slotIndex)
        .firstOrNull;
    if (algorithm != null) {
      setFocusedAlgorithm(algorithm.id);
    }
  }

  /// Clear all focused algorithms (exit focus mode)
  void clearFocus() {
    final currentState = state;
    if (currentState is! RoutingEditorStateLoaded) return;

    if (currentState.focusedAlgorithmIds.isNotEmpty) {
      emit(currentState.copyWith(focusedAlgorithmIds: const {}));
    }
  }

  /// Check if focus mode is active (any algorithms focused)
  bool get isFocusModeActive {
    final currentState = state;
    if (currentState is! RoutingEditorStateLoaded) return false;
    return currentState.focusedAlgorithmIds.isNotEmpty;
  }

  /// Clear the cascade scroll target (called after scrolling is complete)
  void clearCascadeScrollTarget() {
    final currentState = state;
    if (currentState is! RoutingEditorStateLoaded) return;

    if (currentState.cascadeScrollTarget != null) {
      emit(currentState.copyWith(cascadeScrollTarget: null));
    }
  }

  @override
  Future<void> close() {
    _distingStateSubscription?.cancel();
    _lastProcessedSlots = null;
    return super.close();
  }
}

class ConsolidationStep {
  final int algorithmIndex;
  final String algorithmName;
  final int parameterNumber;
  final int fromBus;
  final int toBus;

  const ConsolidationStep({
    required this.algorithmIndex,
    required this.algorithmName,
    required this.parameterNumber,
    required this.fromBus,
    required this.toBus,
  });
}

class ReplaceModeStep {
  final int algorithmIndex;
  final String algorithmName;
  final int parameterNumber;

  const ReplaceModeStep({
    required this.algorithmIndex,
    required this.algorithmName,
    required this.parameterNumber,
  });
}

class ConsolidationMerge {
  final int keepBus;
  final int freeBus;
  final String description;
  final List<ConsolidationStep> steps;
  final List<ReplaceModeStep> replaceModeSteps;

  const ConsolidationMerge({
    required this.keepBus,
    required this.freeBus,
    required this.description,
    required this.steps,
    this.replaceModeSteps = const [],
  });

  bool get hasReplaceModeStep => replaceModeSteps.isNotEmpty;
}

class AuxBusConsolidationPlan {
  final String description;
  final List<ConsolidationMerge> merges;

  const AuxBusConsolidationPlan({
    required this.description,
    required this.merges,
  });
}

/// Result from [_findAvailableAuxBus].
class _AvailableAuxBus {
  final int bus;
  final bool isReused;
  const _AvailableAuxBus({required this.bus, required this.isReused});
}

class _SourceRecord {
  final int slot;
  final bool canReplace;
  final int? modeParameterNumber;
  const _SourceRecord(this.slot, this.canReplace, this.modeParameterNumber);
}

class _AuxBusInfo {
  /// Highest slot index across ALL ports (input and output) on this bus.
  int? maxSlot;

  /// All slot indices that have ports on this bus.
  final Set<int> portSlots = {};

  /// All output sources on this bus, in scan order.
  final List<_SourceRecord> sources = [];

  final List<_BusPort> ports = [];

  void addPort(int slot, {required bool isSource}) {
    portSlots.add(slot);
    if (maxSlot == null || slot > maxSlot!) maxSlot = slot;
  }

  /// Highest-slot Replace-capable source, or null.
  int? get replaceSourceSlot {
    int? best;
    for (final s in sources) {
      if (s.canReplace && (best == null || s.slot > best)) best = s.slot;
    }
    return best;
  }

  /// Mode parameter number for the highest-slot Replace-capable source.
  int? get replaceSourceModeParameter {
    _SourceRecord? best;
    for (final s in sources) {
      if (s.canReplace && (best == null || s.slot > best.slot)) best = s;
    }
    return best?.modeParameterNumber;
  }

  int? get minSourceSlot {
    if (sources.isEmpty) return null;
    int m = sources.first.slot;
    for (final s in sources) {
      if (s.slot < m) m = s.slot;
    }
    return m;
  }
}

class _BusPort {
  final int algorithmIndex;
  final int parameterNumber;
  const _BusPort(this.algorithmIndex, this.parameterNumber);
}
