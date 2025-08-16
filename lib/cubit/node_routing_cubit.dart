import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/cubit/node_routing_state.dart';
import 'package:nt_helper/models/algorithm_port.dart';
import 'package:nt_helper/models/connection.dart';
import 'package:nt_helper/models/node_position.dart';
import 'package:nt_helper/models/routing_information.dart';
import 'package:nt_helper/services/auto_routing_service.dart';
import 'package:nt_helper/services/graph_layout_service.dart';
import 'package:nt_helper/util/routing_validator.dart';

class NodeRoutingCubit extends Cubit<NodeRoutingState> {
  final DistingCubit _distingCubit;
  late final AutoRoutingService _autoRoutingService;
  StreamSubscription<DistingState>? _distingSubscription;

  NodeRoutingCubit(this._distingCubit) : super(const NodeRoutingState.initial()) {
    _autoRoutingService = AutoRoutingService(_distingCubit);
    _subscribeToDistingChanges();
  }

  void _subscribeToDistingChanges() {
    _distingSubscription = _distingCubit.stream.listen((distingState) {
      if (distingState is DistingStateSynchronized) {
        // Convert hardware routing data to visual representation
        _updateFromDistingState(distingState);
      }
    });
  }

  /// Initialize the node routing view with routing information
  void initializeFromRouting(List<RoutingInformation> routing) {
    emit(const NodeRoutingState.loading());
    
    try {
      // Extract algorithm information
      final algorithmNames = <int, String>{};
      for (final info in routing) {
        algorithmNames[info.algorithmIndex] = info.algorithmName;
      }

      // Extract algorithm ports (simplified for now)
      final algorithmPorts = _extractAlgorithmPorts(routing);

      // Convert routing masks to visual connections
      final connections = _interpretRoutingMasks(routing);
      final connectedPorts = _extractConnectedPorts(connections);

      // Calculate initial layout
      final algorithmIndices = routing.map((r) => r.algorithmIndex).toList();
      const canvasSize = Size(1600, 1200);
      
      final nodePositions = GraphLayoutService.calculateInitialLayout(
        algorithmIndices: algorithmIndices,
        algorithmNames: algorithmNames,
        algorithmPorts: algorithmPorts,
        connections: connections,
        canvasSize: canvasSize,
      );

      emit(NodeRoutingState.loaded(
        nodePositions: nodePositions,
        connections: connections,
        algorithmPorts: algorithmPorts,
        connectedPorts: connectedPorts,
        algorithmNames: algorithmNames,
      ));
    } catch (e) {
      emit(NodeRoutingState.error(message: 'Failed to initialize node routing: $e'));
    }
  }

  /// Update node position
  void updateNodePosition(int algorithmIndex, NodePosition newPosition) {
    final currentState = state;
    if (currentState is NodeRoutingStateLoaded) {
      final updatedPositions = Map<int, NodePosition>.from(currentState.nodePositions);
      updatedPositions[algorithmIndex] = newPosition;
      
      emit(currentState.copyWith(nodePositions: updatedPositions));
      
      // TODO: Persist to settings service
      debugPrint('Node position updated for algorithm $algorithmIndex: (${newPosition.x}, ${newPosition.y})');
    }
  }

  /// Start connection preview
  void startConnectionPreview(int sourceAlgorithmIndex, String sourcePortId) {
    final currentState = state;
    if (currentState is NodeRoutingStateLoaded) {
      final previewConnection = Connection(
        id: 'preview',
        sourceAlgorithmIndex: sourceAlgorithmIndex,
        sourcePortId: sourcePortId,
        targetAlgorithmIndex: -1,
        targetPortId: '',
        assignedBus: 21,
        replaceMode: true,
        isValid: false,
      );
      
      emit(currentState.copyWith(previewConnection: previewConnection));
    }
  }

  /// Clear connection preview
  void clearConnectionPreview() {
    final currentState = state;
    if (currentState is NodeRoutingStateLoaded) {
      emit(currentState.copyWith(previewConnection: null));
    }
  }

  /// Create a new connection
  Future<void> createConnection({
    required int sourceAlgorithmIndex,
    required String sourcePortId,
    required int targetAlgorithmIndex,
    required String targetPortId,
  }) async {
    final currentState = state;
    if (currentState is! NodeRoutingStateLoaded) return;

    try {
      // Create connection object for validation
      final connection = Connection(
        id: '${sourceAlgorithmIndex}_${sourcePortId}_${targetAlgorithmIndex}_$targetPortId',
        sourceAlgorithmIndex: sourceAlgorithmIndex,
        sourcePortId: sourcePortId,
        targetAlgorithmIndex: targetAlgorithmIndex,
        targetPortId: targetPortId,
        assignedBus: 21, // Will be assigned by auto-routing service
        replaceMode: true,
        isValid: true,
      );

      // Validate connection
      final validationResult = RoutingValidator.validateConnection(
        proposedConnection: connection,
        existingConnections: currentState.connections,
        algorithmPorts: currentState.algorithmPorts,
      );

      if (!validationResult.isValid) {
        emit(currentState.copyWith(
          errorMessage: 'Connection validation failed: ${validationResult.errors.join(', ')}'
        ));
        return;
      }

      // Assign bus and update hardware
      final busAssignment = await _autoRoutingService.assignBusForConnection(
        sourceAlgorithmIndex: sourceAlgorithmIndex,
        sourcePortId: sourcePortId,
        targetAlgorithmIndex: targetAlgorithmIndex,
        targetPortId: targetPortId,
        existingConnections: currentState.connections,
      );

      // Apply parameter updates to hardware
      await _autoRoutingService.updateBusParameters(busAssignment.parameterUpdates);

      debugPrint('Connection created: ${busAssignment.edgeLabel}');
      
      // Clear any error message on success
      emit(currentState.copyWith(errorMessage: null));
      
    } catch (e) {
      emit(currentState.copyWith(
        errorMessage: 'Failed to create connection: $e'
      ));
    }
  }

  /// Remove a connection
  Future<void> removeConnection(Connection connection) async {
    final currentState = state;
    if (currentState is! NodeRoutingStateLoaded) return;

    try {
      // Set source output bus to 0 (none) - this removes the connection
      await _distingCubit.updateParameterValue(
        algorithmIndex: connection.sourceAlgorithmIndex,
        parameterNumber: 0, // TODO: Look up actual parameter number from algorithm metadata
        value: 0,
        userIsChangingTheValue: true,
      );
      
      // Refresh routing to get updated state from hardware
      await _distingCubit.refreshRouting();
      
      debugPrint('Connection removed: ${connection.id}');
      
      // Clear any error message on success
      emit(currentState.copyWith(errorMessage: null));
      
    } catch (e) {
      emit(currentState.copyWith(
        errorMessage: 'Failed to remove connection: $e'
      ));
    }
  }

  /// Update the visual state when DistingCubit routing changes
  void _updateFromDistingState(DistingStateSynchronized distingState) {
    // TODO: Extract routing information from distingState and update visual representation
    // This would be called when hardware routing changes to keep visuals in sync
  }

  /// Extract algorithm ports from routing information
  Map<int, List<AlgorithmPort>> _extractAlgorithmPorts(List<RoutingInformation> routing) {
    final ports = <int, List<AlgorithmPort>>{};
    
    // TODO: Extract actual ports from algorithm metadata in distingState.algorithms
    // For now, using basic ports to get the structure working
    for (final info in routing) {
      ports[info.algorithmIndex] = [
        const AlgorithmPort(
          id: 'input_1',
          name: 'Input 1',
          busIdRef: 'input_bus',
        ),
        const AlgorithmPort(
          id: 'input_2', 
          name: 'Input 2',
          busIdRef: 'input_bus_2',
        ),
        const AlgorithmPort(
          id: 'output_1',
          name: 'Output 1',
          busIdRef: 'output_bus',
        ),
        const AlgorithmPort(
          id: 'output_2',
          name: 'Output 2', 
          busIdRef: 'output_bus_2',
        ),
      ];
    }
    
    return ports;
  }

  /// Convert routing masks to visual connections
  List<Connection> _interpretRoutingMasks(List<RoutingInformation> routingInfoList) {
    final connections = <Connection>[];
    final busWriters = <int, int>{}; // bus -> algorithm index
    final busReaders = <int, List<int>>{}; // bus -> list of algorithm indices

    // Analyze which buses each algorithm reads/writes
    for (final routing in routingInfoList) {
      final inputMask = routing.routingInfo[0];  // r0
      final outputMask = routing.routingInfo[1]; // r1

      // Find which buses this algorithm writes to
      for (int bus = 1; bus <= 28; bus++) {
        if ((outputMask & (1 << bus)) != 0) {
          busWriters[bus] = routing.algorithmIndex;
        }
      }

      // Find which buses this algorithm reads from
      for (int bus = 1; bus <= 28; bus++) {
        if ((inputMask & (1 << bus)) != 0) {
          busReaders[bus] ??= [];
          busReaders[bus]!.add(routing.algorithmIndex);
        }
      }
    }

    // Create connections for aux buses only (21-28)
    for (int bus = 21; bus <= 28; bus++) {
      if (busWriters.containsKey(bus) && busReaders.containsKey(bus)) {
        final sourceIndex = busWriters[bus]!;

        for (final targetIndex in busReaders[bus]!) {
          if (sourceIndex == targetIndex) continue; // Skip self-connections

          connections.add(Connection(
            id: 'bus_${bus}_${sourceIndex}_$targetIndex',
            sourceAlgorithmIndex: sourceIndex,
            sourcePortId: 'output_1', // Simplified
            targetAlgorithmIndex: targetIndex,
            targetPortId: 'input_1', // Simplified
            assignedBus: bus,
            replaceMode: true,
            isValid: true,
          ));
        }
      }
    }

    return connections;
  }

  /// Extract connected ports from connections
  Set<String> _extractConnectedPorts(List<Connection> connections) {
    final connectedPorts = <String>{};
    
    for (final connection in connections) {
      connectedPorts.add('${connection.sourceAlgorithmIndex}_${connection.sourcePortId}');
      connectedPorts.add('${connection.targetAlgorithmIndex}_${connection.targetPortId}');
    }
    
    return connectedPorts;
  }

  @override
  Future<void> close() {
    _distingSubscription?.cancel();
    return super.close();
  }
}