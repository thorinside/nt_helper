import 'package:flutter/foundation.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/models/connection.dart';

class AutoRoutingService {
  final DistingCubit _cubit;

  AutoRoutingService(this._cubit);

  /// Assign bus for a new connection
  Future<BusAssignment> assignBusForConnection({
    required int sourceAlgorithmIndex,
    required String sourcePortId,
    required int targetAlgorithmIndex,
    required String targetPortId,
    required List<Connection> existingConnections,
  }) async {
    // Check if there's already a connection from the same source output
    // If so, reuse that bus for signal splitting
    debugPrint('[AutoRoutingService] Checking for existing connections from source $sourceAlgorithmIndex:$sourcePortId');
    debugPrint('[AutoRoutingService] Existing connections: ${existingConnections.length}');
    
    for (final conn in existingConnections) {
      debugPrint('[AutoRoutingService]   - ${conn.sourceAlgorithmIndex}:${conn.sourcePortId} -> ${conn.targetAlgorithmIndex}:${conn.targetPortId} (bus ${conn.assignedBus})');
    }
    
    final existingConnectionFromSameSource = existingConnections.firstWhere(
      (conn) => 
        conn.sourceAlgorithmIndex == sourceAlgorithmIndex &&
        conn.sourcePortId == sourcePortId,
      orElse: () => const Connection(
        id: '',
        sourceAlgorithmIndex: -1,
        sourcePortId: '',
        targetAlgorithmIndex: -1,
        targetPortId: '',
        assignedBus: -1,
        replaceMode: false,
      ),
    );
    
    final assignedBus = existingConnectionFromSameSource.assignedBus != -1
        ? existingConnectionFromSameSource.assignedBus  // Reuse existing bus
        : findAvailableAuxBus(existingConnections);     // Find new bus
    
    debugPrint('[AutoRoutingService] Existing connection from same source: bus ${existingConnectionFromSameSource.assignedBus}');
    debugPrint('[AutoRoutingService] Assigned bus: $assignedBus');
    
    // Default to replace mode (can be enhanced based on algorithm types)
    final replaceMode = true;
    
    // Generate connection ID
    final connectionId = '${sourceAlgorithmIndex}_${sourcePortId}_${targetAlgorithmIndex}_$targetPortId';
    
    // Generate edge label
    final edgeLabel = _generateEdgeLabel(assignedBus, replaceMode);
    
    // Find the actual parameter numbers from the current state
    final sourceParamNumber = _findParameterNumberForPort(
      sourceAlgorithmIndex, 
      sourcePortId, 
      isOutput: true,
    );
    final targetParamNumber = _findParameterNumberForPort(
      targetAlgorithmIndex, 
      targetPortId, 
      isOutput: false,
    );
    
    debugPrint('[AutoRoutingService] Assigning bus $assignedBus: source param #$sourceParamNumber, target param #$targetParamNumber');
    
    // Create parameter updates with actual parameter numbers
    final parameterUpdates = <ParameterUpdate>[];
    
    // Only update the source output bus if this is the first connection from this source
    // (i.e., we just assigned a new bus, not reusing an existing one)
    if (existingConnectionFromSameSource.assignedBus == -1) {
      debugPrint('[AutoRoutingService] First connection from this source, setting output bus to $assignedBus');
      parameterUpdates.add(
        ParameterUpdate(
          algorithmIndex: sourceAlgorithmIndex,
          parameterId: _inferOutputBusParameterId(sourcePortId),
          parameterNumber: sourceParamNumber,
          value: assignedBus,
        ),
      );
    } else {
      debugPrint('[AutoRoutingService] Reusing existing bus $assignedBus from source, NOT updating source output');
    }
    
    // Always update the target input bus
    parameterUpdates.add(
      ParameterUpdate(
        algorithmIndex: targetAlgorithmIndex,
        parameterId: _inferInputBusParameterId(targetPortId),
        parameterNumber: targetParamNumber,
        value: assignedBus,
      ),
    );

    return BusAssignment(
      connectionId: connectionId,
      sourceBus: assignedBus,
      replaceMode: replaceMode,
      edgeLabel: edgeLabel,
      parameterUpdates: parameterUpdates,
    );
  }

  /// Find an available aux bus (21-28), fall back to other buses if needed
  int findAvailableAuxBus(List<Connection> existingConnections) {
    final usedBuses = <int>{};
    
    // Collect all buses currently in use
    for (final connection in existingConnections) {
      usedBuses.add(connection.assignedBus);
    }
    
    // First try aux buses (21-28) - preferred for internal routing
    for (int bus = 21; bus <= 28; bus++) {
      if (!usedBuses.contains(bus)) {
        return bus;
      }
    }
    
    // If aux buses full, try unused output buses (13-24)
    for (int bus = 13; bus <= 24; bus++) {
      if (!usedBuses.contains(bus)) {
        return bus;
      }
    }
    
    // Last resort: use input buses (1-12)
    for (int bus = 1; bus <= 12; bus++) {
      if (!usedBuses.contains(bus)) {
        return bus;
      }
    }
    
    throw InsufficientBusesException('All buses are in use');
  }

  /// Apply bus parameter updates for a connection
  Future<void> updateBusParameters(List<ParameterUpdate> updates) async {
    try {
      // Use the optimistic update pattern - update all parameters
      // The DistingCubit will handle optimistic updates and sync with hardware
      for (final update in updates) {
        debugPrint('[AutoRoutingService] Updating param #${update.parameterNumber} on slot ${update.algorithmIndex} to value ${update.value}');
        await _cubit.updateParameterValue(
          algorithmIndex: update.algorithmIndex,
          parameterNumber: update.parameterNumber,
          value: update.value,
          userIsChangingTheValue: true,
        );
      }
      
      // The parameter updates will trigger state changes that NodeRoutingCubit subscribes to
      // No need to manually refresh - the optimistic updates handle this
    } catch (e) {
      debugPrint('Failed to update bus parameters: $e');
      rethrow;
    }
  }

  /// Generate edge label like "A1 R" or "O3 A"
  String _generateEdgeLabel(int bus, bool replaceMode) {
    String busLabel;
    if (bus >= 1 && bus <= 12) {
      busLabel = 'I$bus'; // Input bus (1-12 -> I1-I12)
    } else if (bus >= 13 && bus <= 20) {
      busLabel = 'O${bus - 12}'; // Output bus (13-20 -> O1-O8)
    } else if (bus >= 21 && bus <= 28) {
      busLabel = 'A${bus - 20}'; // Aux bus (21-28 -> A1-A8)
    } else {
      busLabel = 'B$bus'; // Fallback for unknown bus
    }
    
    final mode = replaceMode ? 'R' : 'A';
    return '$busLabel $mode';
  }

  /// Infer output bus parameter ID from port ID
  String _inferOutputBusParameterId(String portId) {
    // Common patterns for output bus parameters
    if (portId.contains('output') || portId.contains('out')) {
      return 'output_bus';
    }
    return 'out_bus'; // Fallback
  }

  /// Infer input bus parameter ID from port ID
  String _inferInputBusParameterId(String portId) {
    // Common patterns for input bus parameters
    if (portId.contains('input') || portId.contains('in')) {
      return 'input_bus';
    }
    return 'in_bus'; // Fallback
  }

  /// Find the parameter number for a given port by matching port ID with parameter names
  int _findParameterNumberForPort(int algorithmIndex, String portId, {required bool isOutput}) {
    final distingState = _cubit.state;
    
    if (distingState is! DistingStateSynchronized) {
      debugPrint('[AutoRoutingService] Not synchronized, using fallback parameter number');
      return isOutput ? 0 : 1; // Fallback
    }
    
    if (algorithmIndex >= distingState.slots.length) {
      debugPrint('[AutoRoutingService] Algorithm index $algorithmIndex out of bounds');
      return isOutput ? 0 : 1; // Fallback
    }
    
    final slot = distingState.slots[algorithmIndex];
    
    // Convert portId back to a parameter name pattern
    // The portId is sanitized (e.g., "output" or "l_input")
    // We need to find parameters whose sanitized names match
    
    for (final param in slot.parameters) {
      // Sanitize the parameter name the same way PortExtractionService does
      final sanitizedParamName = param.name
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]'), '_')
          .replaceAll(RegExp(r'_+'), '_')
          .replaceAll(RegExp(r'^_|_$'), '');
      
      if (sanitizedParamName == portId) {
        debugPrint('[AutoRoutingService] Found parameter "${param.name}" (#${param.parameterNumber}) for port "$portId"');
        return param.parameterNumber;
      }
    }
    
    // If exact match not found, try partial matching based on common patterns
    for (final param in slot.parameters) {
      final nameLower = param.name.toLowerCase();
      
      if (isOutput) {
        // Looking for output parameters
        if (portId.contains('output') && nameLower.contains('output')) {
          debugPrint('[AutoRoutingService] Found output parameter "${param.name}" (#${param.parameterNumber}) for port "$portId"');
          return param.parameterNumber;
        }
        if (portId.contains('main') && nameLower.contains('main')) {
          debugPrint('[AutoRoutingService] Found main output parameter "${param.name}" (#${param.parameterNumber}) for port "$portId"');
          return param.parameterNumber;
        }
      } else {
        // Looking for input parameters
        if (portId.contains('input') && nameLower.contains('input')) {
          // Try to match more specific inputs first (e.g., "l_input" matches "L Input")
          if (portId.startsWith('l_') && nameLower.startsWith('l ')) {
            debugPrint('[AutoRoutingService] Found L input parameter "${param.name}" (#${param.parameterNumber}) for port "$portId"');
            return param.parameterNumber;
          }
          if (portId.startsWith('r_') && nameLower.startsWith('r ')) {
            debugPrint('[AutoRoutingService] Found R input parameter "${param.name}" (#${param.parameterNumber}) for port "$portId"');
            return param.parameterNumber;
          }
          // Generic input match
          debugPrint('[AutoRoutingService] Found input parameter "${param.name}" (#${param.parameterNumber}) for port "$portId"');
          return param.parameterNumber;
        }
        // Check for specific parameter names that are inputs
        if (portId.contains('pitch') && nameLower.contains('pitch')) {
          debugPrint('[AutoRoutingService] Found pitch parameter "${param.name}" (#${param.parameterNumber}) for port "$portId"');
          return param.parameterNumber;
        }
        if (portId.contains('wave') && nameLower.contains('wave')) {
          debugPrint('[AutoRoutingService] Found wave parameter "${param.name}" (#${param.parameterNumber}) for port "$portId"');
          return param.parameterNumber;
        }
      }
    }
    
    debugPrint('[AutoRoutingService] No parameter found for port "$portId", using fallback');
    return isOutput ? 0 : 1; // Fallback
  }
}

class BusAssignment {
  final String connectionId;
  final int sourceBus;
  final bool replaceMode;
  final String edgeLabel;
  final List<ParameterUpdate> parameterUpdates;

  BusAssignment({
    required this.connectionId,
    required this.sourceBus,
    required this.replaceMode,
    required this.edgeLabel,
    required this.parameterUpdates,
  });
}

class ParameterUpdate {
  final int algorithmIndex;
  final String parameterId;
  final int parameterNumber;
  final dynamic value;

  ParameterUpdate({
    required this.algorithmIndex,
    required this.parameterId,
    required this.parameterNumber,
    required this.value,
  });
}

class InsufficientBusesException implements Exception {
  final String message;
  
  InsufficientBusesException(this.message);
  
  @override
  String toString() => 'InsufficientBusesException: $message';
}

extension AutoRoutingServiceExtensions on AutoRoutingService {
  /// Remove a connection by clearing the target input parameter
  Future<void> removeConnection({
    required int sourceAlgorithmIndex,
    required String sourcePortId,
    required int targetAlgorithmIndex,
    required String targetPortId,
  }) async {
    debugPrint('[AutoRoutingService] Removing connection from $sourceAlgorithmIndex:$sourcePortId to $targetAlgorithmIndex:$targetPortId');
    
    // Find the parameter number for the target input port
    final targetParamNumber = _findParameterNumberForPort(
      targetAlgorithmIndex,
      targetPortId,
      isOutput: false,
    );
    
    // Set the target input parameter to 0 (None) to disconnect it
    await _cubit.updateParameterValue(
      algorithmIndex: targetAlgorithmIndex,
      parameterNumber: targetParamNumber,
      value: 0, // 0 = None/disconnected
      userIsChangingTheValue: true,
    );
    
    debugPrint('[AutoRoutingService] Cleared input parameter #$targetParamNumber on algorithm $targetAlgorithmIndex');
    
    // Note: We don't clear the source output parameter because it might be
    // connected to other inputs (signal splitting). The hardware will handle
    // cleaning up unused buses automatically.
  }
}