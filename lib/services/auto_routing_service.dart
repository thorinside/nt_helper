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
    // Find available aux bus (prefer 21-28)
    final assignedBus = findAvailableAuxBus(existingConnections);
    
    // Default to replace mode (can be enhanced based on algorithm types)
    final replaceMode = true;
    
    // Generate connection ID
    final connectionId = '${sourceAlgorithmIndex}_${sourcePortId}_${targetAlgorithmIndex}_$targetPortId';
    
    // Generate edge label
    final edgeLabel = _generateEdgeLabel(assignedBus, replaceMode);
    
    // Create parameter updates (will be applied by caller)
    // Note: In real implementation, would look up algorithm metadata to find 
    // the actual parameter numbers for bus parameters
    final parameterUpdates = <ParameterUpdate>[
      ParameterUpdate(
        algorithmIndex: sourceAlgorithmIndex,
        parameterId: _inferOutputBusParameterId(sourcePortId),
        parameterNumber: 0, // TODO: Look up actual parameter number from algorithm metadata
        value: assignedBus,
      ),
      ParameterUpdate(
        algorithmIndex: targetAlgorithmIndex,
        parameterId: _inferInputBusParameterId(targetPortId),
        parameterNumber: 1, // TODO: Look up actual parameter number from algorithm metadata  
        value: assignedBus,
      ),
    ];

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
      for (final update in updates) {
        await _cubit.updateParameterValue(
          algorithmIndex: update.algorithmIndex,
          parameterNumber: update.parameterNumber,
          value: update.value,
          userIsChangingTheValue: true,
        );
      }
      
      // Request routing info from hardware to get calculated masks
      await _cubit.refreshRouting();
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