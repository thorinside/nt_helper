import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/cubit/node_routing_state.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'package:nt_helper/models/algorithm_port.dart';
import 'package:nt_helper/models/connection.dart';
import 'package:nt_helper/models/connection_preview.dart';
import 'package:nt_helper/models/node_position.dart';
import 'package:nt_helper/models/port_layout.dart';
import 'package:nt_helper/models/routing_information.dart';
import 'package:nt_helper/services/algorithm_metadata_service.dart';
import 'package:nt_helper/services/auto_routing_service.dart';
import 'package:nt_helper/services/graph_layout_service.dart';
import 'package:nt_helper/services/port_extraction_service.dart';
import 'package:nt_helper/util/routing_validator.dart';

class NodeRoutingCubit extends Cubit<NodeRoutingState> {
  final DistingCubit _distingCubit;
  final AlgorithmMetadataService _algorithmMetadataService;
  late final AutoRoutingService _autoRoutingService;
  late final PortExtractionService _portExtractionService;
  StreamSubscription<DistingState>? _distingSubscription;

  // Physical node constants - updated to match widget changes
  static const double physicalInputNodeX = 50.0;
  static double physicalOutputNodeX = 800.0; // Will be updated dynamically
  static const double physicalNodeY = 100.0;
  static const double physicalNodeWidth = 80.0; // Narrower
  static const double physicalInputNodeHeight = 28.0 + (6.0 * 2) + (12 * 20.0) + (4.0 * 2) + 12.0; // header + header padding + jacks + padding + bottom padding
  static const double physicalOutputNodeHeight = 28.0 + (6.0 * 2) + (8 * 20.0) + (4.0 * 2) + 12.0; // header + header padding + jacks + padding + bottom padding
  static const int physicalInputAlgorithmIndex = -2;
  static const int physicalOutputAlgorithmIndex = -3;

  NodeRoutingCubit(this._distingCubit, this._algorithmMetadataService)
    : super(const NodeRoutingState.initial()) {
    _autoRoutingService = AutoRoutingService(_distingCubit);
    _portExtractionService = PortExtractionService(_algorithmMetadataService);
    _subscribeToDistingChanges();
  }

  void _subscribeToDistingChanges() {
    _distingSubscription = _distingCubit.stream.listen((distingState) {
      if (distingState is DistingStateSynchronized) {
        // Convert hardware routing data to visual representation
        _updateFromDistingState(distingState);
      }
    });
    
    // Also sync with current state if already synchronized
    final currentDistingState = _distingCubit.state;
    if (currentDistingState is DistingStateSynchronized) {
      // Use a post-frame callback to avoid updating during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _updateFromDistingState(currentDistingState);
      });
    }
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

      // Extract algorithm port layouts
      final portLayouts = _extractPortLayouts(routing);

      // Convert routing masks to visual connections
      final connections = _interpretRoutingMasks(routing);
      final connectedPorts = _extractConnectedPorts(connections);

      // Calculate layout based on user interaction history
      final algorithmIndices = routing.map((r) => r.algorithmIndex).toList();
      const canvasSize = Size(1600, 1200);

      // Convert portLayouts to algorithmPorts format for GraphLayoutService
      final algorithmPorts = portLayouts.map(
        (index, layout) => MapEntry(
          index, 
          [...layout.inputPorts, ...layout.outputPorts],
        ),
      );

      // Check if user has manually repositioned nodes and preserve state
      final currentState = state;
      final Map<int, NodePosition> nodePositions;
      final bool hasUserRepositioned;
      
      if (currentState is NodeRoutingStateLoaded && currentState.hasUserRepositioned) {
        // Preserve existing positions but update for any new algorithms
        hasUserRepositioned = true;
        final existingPositions = currentState.nodePositions;
        nodePositions = Map<int, NodePosition>.from(existingPositions);
        
        // Add positions for any new algorithms using grid layout
        final newAlgorithms = algorithmIndices.where(
          (index) => !nodePositions.containsKey(index),
        ).toList();
        
        if (newAlgorithms.isNotEmpty) {
          final newPositions = GraphLayoutService.calculateGridLayout(
            algorithmIndices: newAlgorithms,
            algorithmNames: algorithmNames,
            algorithmPorts: algorithmPorts,
            canvasSize: canvasSize,
          );
          nodePositions.addAll(newPositions);
        }
      } else {
        // Use grid layout for initial display
        hasUserRepositioned = false;
        nodePositions = GraphLayoutService.calculateGridLayout(
          algorithmIndices: algorithmIndices,
          algorithmNames: algorithmNames,
          algorithmPorts: algorithmPorts,
          canvasSize: canvasSize,
        );
      }

      // Calculate port positions
      final portPositions = _calculatePortPositions(nodePositions, portLayouts);

      emit(
        NodeRoutingState.loaded(
          nodePositions: nodePositions,
          connections: connections,
          portLayouts: portLayouts,
          connectedPorts: connectedPorts,
          algorithmNames: algorithmNames,
          portPositions: portPositions,
          hasUserRepositioned: hasUserRepositioned,
        ),
      );
    } catch (e) {
      emit(
        NodeRoutingState.error(
          message: 'Failed to initialize node routing: $e',
        ),
      );
    }
  }

  /// Update node position and recalculate port positions
  void updateNodePosition(int algorithmIndex, NodePosition newPosition) {
    final currentState = state;
    if (currentState is NodeRoutingStateLoaded) {
      final updatedPositions = Map<int, NodePosition>.from(
        currentState.nodePositions,
      );
      updatedPositions[algorithmIndex] = newPosition;

      // Recalculate port positions with updated node positions
      final updatedPortPositions = _calculatePortPositions(
        updatedPositions, 
        currentState.portLayouts,
      );

      emit(currentState.copyWith(
        nodePositions: updatedPositions,
        portPositions: updatedPortPositions,
        hasUserRepositioned: true,
      ));

      // TODO: Persist to settings service
      debugPrint(
        'Node position updated for algorithm $algorithmIndex: (${newPosition.x}, ${newPosition.y})',
      );
    }
  }

  /// Start connection preview
  void startConnectionPreview(int sourceAlgorithmIndex, String sourcePortId, Offset cursorPosition) {
    final currentState = state;
    if (currentState is NodeRoutingStateLoaded) {
      final connectionPreview = ConnectionPreview(
        sourceAlgorithmIndex: sourceAlgorithmIndex,
        sourcePortId: sourcePortId,
        cursorPosition: cursorPosition,
        isValid: false,
      );

      emit(currentState.copyWith(connectionPreview: connectionPreview));
    }
  }

  /// Update connection preview cursor position and validate target
  void updateConnectionPreview(Offset cursorPosition, {int? hoveredAlgorithmIndex, String? hoveredPortId}) {
    final currentState = state;
    if (currentState is NodeRoutingStateLoaded && currentState.connectionPreview != null) {
      // Check basic validity
      final isValid = hoveredAlgorithmIndex != null && hoveredPortId != null
          ? _isValidConnectionTarget(
              currentState.connectionPreview!.sourceAlgorithmIndex,
              currentState.connectionPreview!.sourcePortId,
              hoveredAlgorithmIndex,
              hoveredPortId,
              currentState.connections,
              currentState.portLayouts,
            )
          : false;
      
      // Check execution order violation (skip for physical nodes)
      final violatesOrder = hoveredAlgorithmIndex != null && 
                            !_isPhysicalNode(currentState.connectionPreview!.sourceAlgorithmIndex) &&
                            !_isPhysicalNode(hoveredAlgorithmIndex)
          ? currentState.connectionPreview!.sourceAlgorithmIndex >= hoveredAlgorithmIndex
          : false;

      final updatedPreview = currentState.connectionPreview!.copyWith(
        cursorPosition: cursorPosition,
        isValid: isValid && !violatesOrder,  // Not valid if violates order
        hoveredTargetAlgorithmIndex: hoveredAlgorithmIndex,
        hoveredTargetPortId: hoveredPortId,
        violatesExecutionOrder: violatesOrder,
      );

      emit(currentState.copyWith(connectionPreview: updatedPreview));
    }
  }

  /// Clear connection preview
  void clearConnectionPreview() {
    final currentState = state;
    if (currentState is NodeRoutingStateLoaded) {
      emit(currentState.copyWith(connectionPreview: null));
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

    debugPrint('[NodeRoutingCubit] Creating connection: $sourceAlgorithmIndex/$sourcePortId -> $targetAlgorithmIndex/$targetPortId');

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
      // Convert portLayouts to algorithmPorts format for validator
      final algorithmPorts = <int, List<AlgorithmPort>>{};
      for (final entry in currentState.portLayouts.entries) {
        algorithmPorts[entry.key] = [
          ...entry.value.inputPorts,
          ...entry.value.outputPorts,
        ];
      }
      
      // Add physical node ports for validation
      _addPhysicalNodePortsForValidation(algorithmPorts);
      
      final validationResult = RoutingValidator.validateConnection(
        proposedConnection: connection,
        existingConnections: currentState.connections,
        algorithmPorts: algorithmPorts,
      );

      if (!validationResult.isValid) {
        emit(
          currentState.copyWith(
            errorMessage:
                'Connection validation failed: ${validationResult.errors.join(', ')}',
          ),
        );
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

      debugPrint('[NodeRoutingCubit] Bus assignment: ${busAssignment.edgeLabel}, parameters: ${busAssignment.parameterUpdates.length}');

      // Apply parameter updates to hardware using optimistic update pattern
      await _autoRoutingService.updateBusParameters(
        busAssignment.parameterUpdates,
      );

      debugPrint('Connection created: ${busAssignment.edgeLabel}');
      
      // The optimistic parameter updates will trigger state changes in DistingCubit
      // Our subscription to DistingCubit will automatically call _updateFromDistingState
      // which will re-interpret the connections and update the visual state
      
      // Force a refresh to ensure we have the latest state
      final latestState = _distingCubit.state;
      if (latestState is DistingStateSynchronized) {
        _updateFromDistingState(latestState);
      }

      // Clear any error message on success
      emit(currentState.copyWith(errorMessage: null));
    } catch (e) {
      emit(
        currentState.copyWith(errorMessage: 'Failed to create connection: $e'),
      );
    }
  }

  /// Remove a connection
  Future<void> removeConnection(Connection connection) async {
    final currentState = state;
    if (currentState is! NodeRoutingStateLoaded) return;

    try {
      debugPrint('Removing connection: ${connection.sourceAlgorithmIndex}:${connection.sourcePortId} -> ${connection.targetAlgorithmIndex}:${connection.targetPortId}');
      
      // Optimistic update - immediately remove the connection from the visual state
      final updatedConnections = currentState.connections
          .where((c) => c.id != connection.id)
          .toList();
      final updatedConnectedPorts = _extractConnectedPorts(updatedConnections);
      
      emit(currentState.copyWith(
        connections: updatedConnections,
        connectedPorts: updatedConnectedPorts,
        errorMessage: null,
      ));
      
      // Now update the hardware in the background
      _autoRoutingService.removeConnection(
        sourceAlgorithmIndex: connection.sourceAlgorithmIndex,
        sourcePortId: connection.sourcePortId,
        targetAlgorithmIndex: connection.targetAlgorithmIndex,
        targetPortId: connection.targetPortId,
      ).then((_) {
        debugPrint('Connection removed from hardware: ${connection.id}');
        // The hardware update will trigger a state refresh via our DistingCubit subscription
        // which will ensure consistency between visual and hardware state
      }).catchError((e) {
        // On error, the next hardware state update will restore the correct state
        debugPrint('Error removing connection: $e');
        final errorState = state;
        if (errorState is NodeRoutingStateLoaded) {
          emit(errorState.copyWith(
            errorMessage: 'Failed to remove connection: $e',
          ));
        }
      });
    } catch (e) {
      emit(
        currentState.copyWith(errorMessage: 'Failed to remove connection: $e'),
      );
    }
  }

  /// Update the visual state when DistingCubit routing changes
  void _updateFromDistingState(DistingStateSynchronized distingState) {
    final currentState = state;
    if (currentState is! NodeRoutingStateLoaded) return;
    
    debugPrint('[NodeRoutingCubit] ========================================');
    debugPrint('[NodeRoutingCubit] Updating from hardware routing change');
    debugPrint('[NodeRoutingCubit] Number of slots: ${distingState.slots.length}');
    
    // Build routing information from the current hardware state
    final routingInfoList = <RoutingInformation>[];
    final algorithmNames = <int, String>{};
    
    for (int i = 0; i < distingState.slots.length; i++) {
      final slot = distingState.slots[i];
      algorithmNames[i] = slot.algorithm.name;
      routingInfoList.add(RoutingInformation(
        algorithmIndex: i,
        algorithmName: slot.algorithm.name,
        routingInfo: const [], // Empty routing info, not used for connection detection
      ));
      debugPrint('[NodeRoutingCubit] Slot $i: ${slot.algorithm.name} (${slot.algorithm.guid})');
    }
    
    // Re-extract port layouts for the new algorithm positions
    final newPortLayouts = _extractPortLayouts(routingInfoList);
    
    // Log port layout details
    for (final entry in newPortLayouts.entries) {
      final layout = entry.value;
      debugPrint('[NodeRoutingCubit] Algorithm ${entry.key} ports: ${layout.inputPorts.length} inputs, ${layout.outputPorts.length} outputs');
    }
    
    // Re-extract connections from the updated hardware state
    final newConnections = _interpretRoutingMasks(routingInfoList);
    final newConnectedPorts = _extractConnectedPorts(newConnections);
    
    debugPrint('[NodeRoutingCubit] *** CONNECTIONS FOUND: ${newConnections.length} ***');
    
    // Debug: log each connection found with more detail
    for (final conn in newConnections) {
      debugPrint('[NodeRoutingCubit] Connection: Alg${conn.sourceAlgorithmIndex}:"${conn.sourcePortId}" -> Alg${conn.targetAlgorithmIndex}:"${conn.targetPortId}" (bus ${conn.assignedBus})');
    }
    
    if (newConnections.isEmpty) {
      debugPrint('[NodeRoutingCubit] WARNING: No connections found! Check bus parameter detection.');
    }
    
    debugPrint('[NodeRoutingCubit] ========================================');
    
    // Update node positions to match new algorithm indices
    // Try to preserve relative positions when algorithms are reordered
    final oldPositions = currentState.nodePositions;
    final newNodePositions = <int, NodePosition>{};
    
    // Map old algorithm names to their positions
    final nameToPosition = <String, NodePosition>{};
    for (final entry in currentState.algorithmNames.entries) {
      final oldIndex = entry.key;
      final name = entry.value;
      if (oldPositions.containsKey(oldIndex)) {
        nameToPosition[name] = oldPositions[oldIndex]!;
      }
    }
    
    // Assign positions based on algorithm names
    for (final entry in algorithmNames.entries) {
      final newIndex = entry.key;
      final name = entry.value;
      
      if (nameToPosition.containsKey(name)) {
        // Found the same algorithm, update its index in the position
        final oldPos = nameToPosition[name]!;
        newNodePositions[newIndex] = oldPos.copyWith(
          algorithmIndex: newIndex,
        );
      } else {
        // New algorithm or couldn't match, use default position
        newNodePositions[newIndex] = NodePosition(
          x: 100.0 + (newIndex % 3) * 300,
          y: 100.0 + (newIndex ~/ 3) * 200,
          width: 250,
          height: 150,
          algorithmIndex: newIndex,
        );
      }
    }
    
    // Recalculate port positions with updated node positions
    final newPortPositions = _calculatePortPositions(newNodePositions, newPortLayouts);
    
    // Update the visual state with all the new data
    emit(currentState.copyWith(
      nodePositions: newNodePositions,
      algorithmNames: algorithmNames,
      portLayouts: newPortLayouts,
      connections: newConnections,
      connectedPorts: newConnectedPorts,
      portPositions: newPortPositions,
    ));
  }

  /// Extract port layouts from routing information using actual algorithm metadata
  Map<int, PortLayout> _extractPortLayouts(
    List<RoutingInformation> routing,
  ) {
    final portLayouts = <int, PortLayout>{};
    final distingState = _distingCubit.state;

    if (distingState is DistingStateSynchronized) {
      for (final info in routing) {
        final algorithmIndex = info.algorithmIndex;

        // Get algorithm data from the slot
        if (algorithmIndex < distingState.slots.length) {
          final slot = distingState.slots[algorithmIndex];
          final algorithmGuid = slot.algorithm.guid;

          debugPrint('[NodeRoutingCubit] Extracting ports for algorithm $algorithmIndex: "$algorithmGuid"');

          // Extract ports using PortExtractionService with live parameter data
          final portInfo = _portExtractionService.extractPortsFromSlot(slot);

          portLayouts[algorithmIndex] = PortLayout(
            inputPorts: portInfo.inputPorts,
            outputPorts: portInfo.outputPorts,
          );
        } else {
          // Fallback for invalid algorithm index
          portLayouts[algorithmIndex] = _getDefaultPortLayout();
        }
      }
    } else {
      // Fallback when not synchronized
      for (final info in routing) {
        portLayouts[info.algorithmIndex] = _getDefaultPortLayout();
      }
    }

    return portLayouts;
  }

  /// Get default port layout for fallback scenarios
  PortLayout _getDefaultPortLayout() {
    return const PortLayout(
      inputPorts: [
        AlgorithmPort(id: 'input_1', name: 'Input 1', busIdRef: 'input_bus'),
        AlgorithmPort(id: 'input_2', name: 'Input 2', busIdRef: 'input_bus_2'),
      ],
      outputPorts: [
        AlgorithmPort(id: 'output_1', name: 'Output 1', busIdRef: 'output_bus'),
        AlgorithmPort(id: 'output_2', name: 'Output 2', busIdRef: 'output_bus_2'),
      ],
    );
  }

  /// Find connections by matching parameter values across algorithms
  List<Connection> _interpretRoutingMasks(
    List<RoutingInformation> routingInfoList,
  ) {
    final connections = <Connection>[];
    final distingState = _distingCubit.state;

    if (distingState is! DistingStateSynchronized) {
      debugPrint('[NodeRoutingCubit] Not synchronized, no connections');
      return connections;
    }

    debugPrint('[NodeRoutingCubit] Finding connections by matching parameter values');

    // Find all output parameters and their values
    final outputParams = <({int algorithmIndex, String paramName, int paramNumber, int busValue})>[];
    final inputParams = <({int algorithmIndex, String paramName, int paramNumber, int busValue})>[];

    for (final routing in routingInfoList) {
      final algorithmIndex = routing.algorithmIndex;
      if (algorithmIndex >= distingState.slots.length) continue;

      final slot = distingState.slots[algorithmIndex];
      debugPrint('[NodeRoutingCubit] Analyzing algorithm $algorithmIndex parameters');

      // Check each parameter to see if it's an output or input bus assignment
      for (int i = 0; i < slot.parameters.length; i++) {
        final param = slot.parameters[i];
        final paramValue = slot.values.firstWhere(
          (v) => v.parameterNumber == param.parameterNumber,
          orElse: () => ParameterValue(
            algorithmIndex: algorithmIndex,
            parameterNumber: param.parameterNumber,
            value: param.defaultValue,
          ),
        );

        // Check if this is a bus parameter (enum type with bus range)
        final isBusParameter = param.unit == 1 && param.max >= 28;
        
        debugPrint('[NodeRoutingCubit] Algorithm $algorithmIndex parameter "${param.name}" unit=${param.unit} max=${param.max} defaultValue=${param.defaultValue} currentValue=${paramValue.value} isBusParameter=$isBusParameter');

        // Skip if not a bus parameter
        if (!isBusParameter) {
          continue;
        }

        // Skip if current value is 0 (None/not connected)
        if (paramValue.value == 0) {
          debugPrint('[NodeRoutingCubit] Skipping bus parameter "${param.name}" (value=0, not connected)');
          continue;
        }

        // Determine if this parameter is an input or output based on defaultValue and name
        bool isOutputParam = false;
        bool isInputParam = false;
        
        // Check defaultValue first (preferred method)
        if (param.defaultValue >= 13 && param.defaultValue <= 28) {
          isOutputParam = true;
        } else if (param.defaultValue >= 1 && param.defaultValue <= 12) {
          isInputParam = true;
        } else {
          // Parameter defaults to "None" or other - determine type from name
          final nameLower = param.name.toLowerCase();
          if (nameLower.contains('output') || nameLower.contains('send') || 
              nameLower.contains('main out') || nameLower.contains('aux')) {
            isOutputParam = true;
          } else if (nameLower.contains('input') || nameLower.contains('receive') || 
                     nameLower.contains('pitch') || nameLower.contains('wave') ||
                     nameLower.contains('formant') || nameLower.contains('clock') ||
                     nameLower.contains('reset') || nameLower.contains('step') ||
                     nameLower.contains('gate') || nameLower.contains('v/oct') ||
                     nameLower.contains('sync') || nameLower.contains('trigger')) {
            isInputParam = true;
          } else {
            // If we can't determine from name, check the current value range
            // Outputs typically use 13-28, inputs use 1-12 or 21-28
            if (paramValue.value >= 13 && paramValue.value <= 20) {
              isOutputParam = true;
            } else if (paramValue.value >= 1 && paramValue.value <= 12) {
              isInputParam = true;
            } else if (paramValue.value >= 21 && paramValue.value <= 28) {
              // Aux buses can be either, check name more carefully
              if (nameLower.endsWith(' out') || nameLower.startsWith('out')) {
                isOutputParam = true;
              } else {
                isInputParam = true;
              }
            }
          }
        }
        
        if (isOutputParam) {
          // Output or Aux parameter (can send signals)
          outputParams.add((
            algorithmIndex: algorithmIndex,
            paramName: param.name,
            paramNumber: param.parameterNumber,
            busValue: paramValue.value,
          ));
          debugPrint('[NodeRoutingCubit] Found OUTPUT parameter: Algorithm $algorithmIndex "${param.name}" paramNumber=${param.parameterNumber} defaultValue=${param.defaultValue} currentValue=${paramValue.value}');
        } else if (isInputParam) {
          // Input parameter (can receive signals)
          inputParams.add((
            algorithmIndex: algorithmIndex,
            paramName: param.name,
            paramNumber: param.parameterNumber,
            busValue: paramValue.value,
          ));
          debugPrint('[NodeRoutingCubit] Found INPUT parameter: Algorithm $algorithmIndex "${param.name}" paramNumber=${param.parameterNumber} defaultValue=${param.defaultValue} currentValue=${paramValue.value}');
        }
      }
    }

    debugPrint('[NodeRoutingCubit] Starting connection matching: ${outputParams.length} outputs, ${inputParams.length} inputs');
    
    // Debug: Print all found parameters
    debugPrint('[NodeRoutingCubit] OUTPUT parameters found:');
    for (final output in outputParams) {
      debugPrint('  - Algorithm ${output.algorithmIndex}: "${output.paramName}" -> Bus ${output.busValue}');
    }
    debugPrint('[NodeRoutingCubit] INPUT parameters found:');
    for (final input in inputParams) {
      debugPrint('  - Algorithm ${input.algorithmIndex}: "${input.paramName}" -> Bus ${input.busValue}');
    }
    
    // Detect physical I/O connections
    debugPrint('[NodeRoutingCubit] Detecting physical I/O connections...');
    
    // Physical input connections (buses 1-12)
    for (final input in inputParams) {
      if (input.busValue >= 1 && input.busValue <= 12) {
        final physicalInputNumber = input.busValue;
        final sourcePortId = 'physical_input_$physicalInputNumber';
        final targetPortId = _findPortIdForParameter(
          input.algorithmIndex, 
          input.paramNumber, 
          routingInfoList, 
          isInput: true,
        );
        
        debugPrint('[NodeRoutingCubit] *** FOUND PHYSICAL INPUT CONNECTION: I$physicalInputNumber -> Algorithm ${input.algorithmIndex} "${input.paramName}" (bus ${input.busValue}) ***');
        
        connections.add(
          Connection(
            id: '${physicalInputAlgorithmIndex}_${sourcePortId}_${input.algorithmIndex}_$targetPortId',
            sourceAlgorithmIndex: physicalInputAlgorithmIndex,
            sourcePortId: sourcePortId,
            targetAlgorithmIndex: input.algorithmIndex,
            targetPortId: targetPortId,
            assignedBus: input.busValue,
            replaceMode: true,
            isValid: true,
          ),
        );
      }
    }
    
    // Physical output connections (buses 13-20)
    for (final output in outputParams) {
      if (output.busValue >= 13 && output.busValue <= 20) {
        final physicalOutputNumber = output.busValue - 12; // Bus 13 = O1, Bus 14 = O2, etc.
        final sourcePortId = _findPortIdForParameter(
          output.algorithmIndex, 
          output.paramNumber, 
          routingInfoList, 
          isInput: false,
        );
        final targetPortId = 'physical_output_$physicalOutputNumber';
        
        debugPrint('[NodeRoutingCubit] *** FOUND PHYSICAL OUTPUT CONNECTION: Algorithm ${output.algorithmIndex} "${output.paramName}" -> O$physicalOutputNumber (bus ${output.busValue}) ***');
        
        connections.add(
          Connection(
            id: '${output.algorithmIndex}_${sourcePortId}_${physicalOutputAlgorithmIndex}_$targetPortId',
            sourceAlgorithmIndex: output.algorithmIndex,
            sourcePortId: sourcePortId,
            targetAlgorithmIndex: physicalOutputAlgorithmIndex,
            targetPortId: targetPortId,
            assignedBus: output.busValue,
            replaceMode: true,
            isValid: true,
          ),
        );
      }
    }
    
    // Match output parameters with input parameters that have the same bus value
    for (final output in outputParams) {
      for (final input in inputParams) {
        if (output.algorithmIndex == input.algorithmIndex) continue; // Skip self-connections
        if (output.busValue != input.busValue) continue; // Must use same bus

        debugPrint('[NodeRoutingCubit] *** FOUND CONNECTION: Algorithm ${output.algorithmIndex} "${output.paramName}" -> Algorithm ${input.algorithmIndex} "${input.paramName}" (bus ${output.busValue}) ***');

        // Extract clean port names from parameter names
        final sourcePortId = _extractPortNameFromParameter(output.paramName);
        final targetPortId = _extractPortNameFromParameter(input.paramName);

        connections.add(
          Connection(
            id: 'param_${output.algorithmIndex}_${input.algorithmIndex}_${output.busValue}',
            sourceAlgorithmIndex: output.algorithmIndex,
            sourcePortId: sourcePortId,
            targetAlgorithmIndex: input.algorithmIndex,
            targetPortId: targetPortId,
            assignedBus: output.busValue,
            replaceMode: true,
            isValid: true,
          ),
        );
      }
    }

    debugPrint('[NodeRoutingCubit] Created ${connections.length} connections total');
    return connections;
  }

  /// Find the correct port ID for a given parameter number
  String _findPortIdForParameter(
    int algorithmIndex,
    int parameterNumber,
    List<RoutingInformation> routingInfoList,
    {required bool isInput}
  ) {
    final distingState = _distingCubit.state;
    if (distingState is! DistingStateSynchronized) {
      // Fallback to parameter name sanitization
      return _extractPortNameFromParameter('param_$parameterNumber');
    }

    if (algorithmIndex >= distingState.slots.length) {
      return _extractPortNameFromParameter('param_$parameterNumber');
    }

    final slot = distingState.slots[algorithmIndex];
    
    // Find the parameter with the matching parameter number
    final param = slot.parameters.firstWhere(
      (p) => p.parameterNumber == parameterNumber,
      orElse: () => ParameterInfo.filler(),
    );

    if (param.parameterNumber == -1) {
      // Parameter not found, use fallback
      return _extractPortNameFromParameter('param_$parameterNumber');
    }

    // Get the port ID from PortExtractionService logic
    final portId = _sanitizePortId(param.name);
    
    debugPrint('[NodeRoutingCubit] Found port ID "$portId" for parameter ${param.parameterNumber}: "${param.name}"');
    
    return portId;
  }

  /// Sanitize port ID using same logic as PortExtractionService
  String _sanitizePortId(String name) {
    return name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }

  /// Extract clean port name from parameter name - using same logic as PortExtractionService
  String _extractPortNameFromParameter(String paramName) {
    // Use same sanitization logic as PortExtractionService._sanitizePortId
    return paramName
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }


  /// Extract connected ports from connections
  Set<String> _extractConnectedPorts(List<Connection> connections) {
    final connectedPorts = <String>{};

    for (final connection in connections) {
      connectedPorts.add(
        '${connection.sourceAlgorithmIndex}_${connection.sourcePortId}',
      );
      connectedPorts.add(
        '${connection.targetAlgorithmIndex}_${connection.targetPortId}',
      );
    }

    return connectedPorts;
  }

  /// Calculate port positions for all algorithms based on their node positions
  Map<String, Offset> _calculatePortPositions(
    Map<int, NodePosition> nodePositions,
    Map<int, PortLayout> portLayouts,
  ) {
    final portPositions = <String, Offset>{};

    // Layout constants - these should match the view but are defined here
    // to avoid coupling the cubit to the view implementation
    const headerHeight = 36.0; // Header with buttons
    const horizontalPadding = 8.0;
    const verticalPadding = 4.0;
    const portWidgetSize = 16.0;
    const portVerticalMargin = 2.0;
    const portRowPadding = 1.0;
    const rowHeight = portWidgetSize + (portVerticalMargin * 2) + (portRowPadding * 2);

    for (final entry in nodePositions.entries) {
      final algorithmIndex = entry.key;
      final nodePos = entry.value;
      final portLayout = portLayouts[algorithmIndex];

      if (portLayout == null) continue;

      // Calculate input port positions (left side)
      for (int i = 0; i < portLayout.inputPorts.length; i++) {
        final port = portLayout.inputPorts[i];
        final portId = port.id ?? port.name;
        final portKey = '${algorithmIndex}_$portId';

        final portY = nodePos.y + 
                      headerHeight + 
                      verticalPadding + 
                      (i * rowHeight) + 
                      portRowPadding + 
                      portVerticalMargin + 
                      (portWidgetSize / 2);

        final portX = nodePos.x + horizontalPadding + (portWidgetSize / 2);
        
        portPositions[portKey] = Offset(portX, portY);
      }

      // Calculate output port positions (right side)
      for (int i = 0; i < portLayout.outputPorts.length; i++) {
        final port = portLayout.outputPorts[i];
        final portId = port.id ?? port.name;
        final portKey = '${algorithmIndex}_$portId';

        final portY = nodePos.y + 
                      headerHeight + 
                      verticalPadding + 
                      (i * rowHeight) + 
                      portRowPadding + 
                      portVerticalMargin + 
                      (portWidgetSize / 2);

        final portX = nodePos.x + nodePos.width - horizontalPadding - (portWidgetSize / 2);
        
        portPositions[portKey] = Offset(portX, portY);
      }
    }

    // Add physical node port positions
    _addPhysicalNodePortPositions(portPositions);

    return portPositions;
  }

  /// Validate if a connection target is valid
  bool _isValidConnectionTarget(
    int sourceAlgorithmIndex,
    String sourcePortId,
    int targetAlgorithmIndex,
    String targetPortId,
    List<Connection> existingConnections,
    Map<int, PortLayout> portLayouts,
  ) {
    // Prevent self-connections
    if (sourceAlgorithmIndex == targetAlgorithmIndex) {
      return false;
    }

    // Handle physical nodes - they don't appear in portLayouts
    bool sourcePortExists = false;
    bool targetPortExists = false;
    
    // Validate source port
    if (sourceAlgorithmIndex == physicalInputAlgorithmIndex) {
      // Physical input ports (I1-I12)
      sourcePortExists = sourcePortId.startsWith('physical_input_') &&
          _isValidPhysicalInputPortId(sourcePortId);
    } else if (sourceAlgorithmIndex == physicalOutputAlgorithmIndex) {
      // Physical output ports (O1-O8) - these act as bidirectional
      sourcePortExists = sourcePortId.startsWith('physical_output_') &&
          _isValidPhysicalOutputPortId(sourcePortId);
    } else {
      // Algorithm node source port
      final sourceLayout = portLayouts[sourceAlgorithmIndex];
      if (sourceLayout == null) return false;
      sourcePortExists = sourceLayout.outputPorts.any(
        (port) => (port.id ?? port.name) == sourcePortId,
      );
    }
    
    if (!sourcePortExists) return false;

    // Validate target port
    if (targetAlgorithmIndex == physicalInputAlgorithmIndex) {
      // Physical input ports (I1-I12) - these act as bidirectional
      targetPortExists = targetPortId.startsWith('physical_input_') &&
          _isValidPhysicalInputPortId(targetPortId);
    } else if (targetAlgorithmIndex == physicalOutputAlgorithmIndex) {
      // Physical output ports (O1-O8)
      targetPortExists = targetPortId.startsWith('physical_output_') &&
          _isValidPhysicalOutputPortId(targetPortId);
    } else {
      // Algorithm node target port
      final targetLayout = portLayouts[targetAlgorithmIndex];
      if (targetLayout == null) return false;
      targetPortExists = targetLayout.inputPorts.any(
        (port) => (port.id ?? port.name) == targetPortId,
      );
    }
    
    if (!targetPortExists) return false;

    // Check if connection already exists
    final existingConnection = existingConnections.any(
      (conn) =>
          conn.sourceAlgorithmIndex == sourceAlgorithmIndex &&
          conn.sourcePortId == sourcePortId &&
          conn.targetAlgorithmIndex == targetAlgorithmIndex &&
          conn.targetPortId == targetPortId,
    );

    return !existingConnection;
  }

  /// Get port at position (used for hit testing from UI)
  String? getPortAtPosition(Offset position, int algorithmIndex) {
    final currentState = state;
    if (currentState is! NodeRoutingStateLoaded) return null;

    // Handle physical nodes
    if (algorithmIndex == physicalInputAlgorithmIndex) {
      return _getPhysicalInputPortAtPosition(position);
    } else if (algorithmIndex == physicalOutputAlgorithmIndex) {
      return _getPhysicalOutputPortAtPosition(position);
    }

    // Handle algorithm nodes
    final portLayout = currentState.portLayouts[algorithmIndex];
    if (portLayout == null) return null;

    // Check all ports for this algorithm
    for (final port in [...portLayout.inputPorts, ...portLayout.outputPorts]) {
      final portId = port.id ?? port.name;
      final portKey = '${algorithmIndex}_$portId';
      final portPosition = currentState.portPositions[portKey];
      
      if (portPosition != null) {
        // Check if position is within port bounds (16x16 centered on position)
        const portSize = 16.0;
        final portRect = Rect.fromCenter(
          center: portPosition,
          width: portSize,
          height: portSize,
        );
        
        if (portRect.contains(position)) {
          return portId;
        }
      }
    }

    return null;
  }

  /// Get algorithm at position (used for hit testing from UI)
  int? getAlgorithmAtPosition(Offset position) {
    final currentState = state;
    if (currentState is! NodeRoutingStateLoaded) return null;

    // Check physical input node first
    final physicalInputRect = Rect.fromLTWH(
      physicalInputNodeX,
      physicalNodeY,
      physicalNodeWidth,
      physicalInputNodeHeight,
    );
    if (physicalInputRect.contains(position)) {
      return physicalInputAlgorithmIndex;
    }

    // Check physical output node
    final physicalOutputRect = Rect.fromLTWH(
      physicalOutputNodeX,
      physicalNodeY,
      physicalNodeWidth,
      physicalOutputNodeHeight,
    );
    if (physicalOutputRect.contains(position)) {
      return physicalOutputAlgorithmIndex;
    }

    // Check algorithm nodes
    for (final entry in currentState.nodePositions.entries) {
      final algorithmIndex = entry.key;
      final nodePos = entry.value;
      
      final nodeRect = Rect.fromLTWH(
        nodePos.x,
        nodePos.y,
        nodePos.width,
        nodePos.height,
      );
      
      if (nodeRect.contains(position)) {
        return algorithmIndex;
      }
    }

    return null;
  }
  
  /// Move algorithm up one slot (delegate to DistingCubit)
  Future<void> moveAlgorithmUp(int algorithmIndex) async {
    await _distingCubit.moveAlgorithmUp(algorithmIndex);
  }
  
  /// Move algorithm down one slot (delegate to DistingCubit)
  Future<void> moveAlgorithmDown(int algorithmIndex) async {
    await _distingCubit.moveAlgorithmDown(algorithmIndex);
  }

  /// Get physical input port at position
  String? _getPhysicalInputPortAtPosition(Offset position) {
    const headerHeight = 28.0;
    const portRowHeight = 20.0;
    const verticalPadding = 4.0;
    const portSize = 16.0;
    
    // Check if position is within physical input node bounds
    final nodeRect = Rect.fromLTWH(
      physicalInputNodeX,
      physicalNodeY,
      physicalNodeWidth,
      physicalInputNodeHeight,
    );
    
    if (!nodeRect.contains(position)) return null;
    
    // Calculate which jack was hit
    final relativeY = position.dy - physicalNodeY - headerHeight - verticalPadding;
    if (relativeY < 0) return null;
    
    final jackIndex = (relativeY / portRowHeight).floor();
    if (jackIndex < 0 || jackIndex >= 12) return null;
    
    // Check if position is within the centered port widget area
    final jackY = physicalNodeY + headerHeight + verticalPadding + (jackIndex * portRowHeight) + (portRowHeight / 2);
    final portX = physicalInputNodeX + (physicalNodeWidth / 2); // Centered horizontally
    
    final portRect = Rect.fromCenter(
      center: Offset(portX, jackY),
      width: portSize,
      height: portSize,
    );
    
    if (portRect.contains(position)) {
      return 'physical_input_${jackIndex + 1}';
    }
    
    return null;
  }

  /// Get physical output port at position
  String? _getPhysicalOutputPortAtPosition(Offset position) {
    const headerHeight = 28.0;
    const portRowHeight = 20.0;
    const verticalPadding = 4.0;
    const portSize = 16.0;
    
    // Check if position is within physical output node bounds
    final nodeRect = Rect.fromLTWH(
      physicalOutputNodeX,
      physicalNodeY,
      physicalNodeWidth,
      physicalOutputNodeHeight,
    );
    
    if (!nodeRect.contains(position)) return null;
    
    // Calculate which jack was hit
    final relativeY = position.dy - physicalNodeY - headerHeight - verticalPadding;
    if (relativeY < 0) return null;
    
    final jackIndex = (relativeY / portRowHeight).floor();
    if (jackIndex < 0 || jackIndex >= 8) return null;
    
    // Check if position is within the centered port widget area
    final jackY = physicalNodeY + headerHeight + verticalPadding + (jackIndex * portRowHeight) + (portRowHeight / 2);
    final portX = physicalOutputNodeX + (physicalNodeWidth / 2); // Centered horizontally
    
    final portRect = Rect.fromCenter(
      center: Offset(portX, jackY),
      width: portSize,
      height: portSize,
    );
    
    if (portRect.contains(position)) {
      return 'physical_output_${jackIndex + 1}';
    }
    
    return null;
  }

  /// Validate physical input port ID (I1-I12)
  bool _isValidPhysicalInputPortId(String portId) {
    final match = RegExp(r'^physical_input_(\d+)$').firstMatch(portId);
    if (match == null) return false;
    
    final jackNumber = int.tryParse(match.group(1) ?? '');
    return jackNumber != null && jackNumber >= 1 && jackNumber <= 12;
  }

  /// Validate physical output port ID (O1-O8)
  bool _isValidPhysicalOutputPortId(String portId) {
    final match = RegExp(r'^physical_output_(\d+)$').firstMatch(portId);
    if (match == null) return false;
    
    final jackNumber = int.tryParse(match.group(1) ?? '');
    return jackNumber != null && jackNumber >= 1 && jackNumber <= 8;
  }

  /// Check if algorithm index is a physical node
  bool _isPhysicalNode(int algorithmIndex) {
    return algorithmIndex == physicalInputAlgorithmIndex || 
           algorithmIndex == physicalOutputAlgorithmIndex;
  }

  /// Add physical node ports for validation
  void _addPhysicalNodePortsForValidation(Map<int, List<AlgorithmPort>> algorithmPorts) {
    // Physical input node ports (I1-I12) - treat as output ports for dragging
    final physicalInputPorts = <AlgorithmPort>[];
    for (int i = 1; i <= 12; i++) {
      physicalInputPorts.add(AlgorithmPort(
        id: 'physical_input_$i',
        name: 'I$i',
        description: 'Physical input jack $i',
      ));
    }
    algorithmPorts[physicalInputAlgorithmIndex] = physicalInputPorts;
    
    // Physical output node ports (O1-O8) - treat as input ports for dropping
    final physicalOutputPorts = <AlgorithmPort>[];
    for (int i = 1; i <= 8; i++) {
      physicalOutputPorts.add(AlgorithmPort(
        id: 'physical_output_$i',
        name: 'O$i',
        description: 'Physical output jack $i',
      ));
    }
    algorithmPorts[physicalOutputAlgorithmIndex] = physicalOutputPorts;
  }

  /// Update physical output node position based on screen width
  static void updatePhysicalOutputPosition(double screenWidth) {
    physicalOutputNodeX = screenWidth - physicalNodeWidth - 50.0;
  }

  /// Add port positions for physical nodes (not in nodePositions map)
  void _addPhysicalNodePortPositions(Map<String, Offset> portPositions) {
    // Physical node constants (must match widget definitions)
    const headerHeight = 28.0;
    const portRowHeight = 20.0;
    const verticalPadding = 4.0;
    
    // Physical input node (I1-I12)
    for (int i = 1; i <= 12; i++) {
      final portId = 'physical_input_$i';
      final portKey = '${physicalInputAlgorithmIndex}_$portId';
      
      final jackY = physicalNodeY + headerHeight + verticalPadding + 
                   ((i - 1) * portRowHeight) + (portRowHeight / 2);
      final portX = physicalInputNodeX + (physicalNodeWidth / 2); // Centered
      
      portPositions[portKey] = Offset(portX, jackY);
    }
    
    // Physical output node (O1-O8)  
    for (int i = 1; i <= 8; i++) {
      final portId = 'physical_output_$i';
      final portKey = '${physicalOutputAlgorithmIndex}_$portId';
      
      final jackY = physicalNodeY + headerHeight + verticalPadding + 
                   ((i - 1) * portRowHeight) + (portRowHeight / 2);
      
      final portX = physicalOutputNodeX + (physicalNodeWidth / 2); // Centered
      
      portPositions[portKey] = Offset(portX, jackY);
    }
  }

  @override
  Future<void> close() {
    _distingSubscription?.cancel();
    return super.close();
  }
}
