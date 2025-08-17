import 'package:flutter/foundation.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';
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
    // Get source parameter number and its current value
    final sourceParamNumber = _findParameterNumberForPort(
      sourceAlgorithmIndex, 
      sourcePortId, 
      isOutput: true,
    );
    final currentSourceBus = _getParameterValue(sourceAlgorithmIndex, sourceParamNumber);
    
    // Simple rules:
    // 1. If source is not connected (value 0 or null), assign first non-conflicting aux bus
    // 2. If source is connected (has a value), use that value for the target
    int assignedBus;
    if (currentSourceBus != null && currentSourceBus > 0) {
      // Source is already connected - use its bus value
      assignedBus = currentSourceBus;
      debugPrint('[AutoRoutingService] Source parameter #$sourceParamNumber has value $assignedBus, using it for connection');
    } else if (targetAlgorithmIndex == -1 && targetPortId.startsWith('output_')) {
      // Special case: External output connection - use the appropriate Output bus
      final outputNum = int.tryParse(targetPortId.replaceAll('output_', '')) ?? 1;
      assignedBus = 12 + outputNum; // Output buses are 13-20 (Output 1-8)
      debugPrint('[AutoRoutingService] External output connection, using Output bus $assignedBus');
    } else {
      // Source not connected - assign first available aux bus
      assignedBus = _findAvailableAuxBusConsideringState(existingConnections);
      debugPrint('[AutoRoutingService] Source not connected, assigning new bus $assignedBus');
    }

    debugPrint(
        '[AutoRoutingService] Final bus assignment: $assignedBus for connection $sourceAlgorithmIndex:$sourcePortId -> $targetAlgorithmIndex:$targetPortId');
    
    // Default to replace mode (can be enhanced based on algorithm types)
    final replaceMode = true;
    
    // Generate connection ID
    final connectionId = '${sourceAlgorithmIndex}_${sourcePortId}_${targetAlgorithmIndex}_$targetPortId';
    
    // Generate edge label
    final edgeLabel = _generateEdgeLabel(assignedBus, replaceMode);
    
    // Find parameter numbers - already done above for source
    // Handle external outputs (targetAlgorithmIndex = -1)
    final targetParamNumber = targetAlgorithmIndex >= 0 
        ? _findParameterNumberForPort(
            targetAlgorithmIndex, 
            targetPortId, 
            isOutput: false,
          )
        : -1; // External output doesn't have a parameter number
    
    debugPrint('[AutoRoutingService] Assigning bus $assignedBus: source param #$sourceParamNumber, target param #$targetParamNumber');
    
    // Create parameter updates with actual parameter numbers
    final parameterUpdates = <ParameterUpdate>[];

    // Always set source output to the bus
    debugPrint('[AutoRoutingService] Setting source output bus to $assignedBus');
    parameterUpdates.add(
      ParameterUpdate(
        algorithmIndex: sourceAlgorithmIndex,
        parameterId: _inferOutputBusParameterId(sourcePortId),
        parameterNumber: sourceParamNumber,
        value: assignedBus,
      ),
    );
    
    // Only set target input if it's an internal connection (not external output)
    if (targetAlgorithmIndex >= 0) {
      debugPrint('[AutoRoutingService] Setting target input bus to $assignedBus');
      parameterUpdates.add(
        ParameterUpdate(
          algorithmIndex: targetAlgorithmIndex,
          parameterId: _inferInputBusParameterId(targetPortId),
          parameterNumber: targetParamNumber,
          value: assignedBus,
        ),
      );
    }

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
    
    // If aux buses full, try unused output buses (13-20 => O1-O8)
    for (int bus = 13; bus <= 20; bus++) {
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

  // Prefer using current state to avoid races where existingConnections isn't up to date
  int _findAvailableAuxBusConsideringStateWithSet(Set<int> preferredUsed) {
    final used = _collectUsedOutputBusesFromState()..addAll(preferredUsed);

    // Aux buses first (21-28)
    for (int bus = 21; bus <= 28; bus++) {
      if (!used.contains(bus)) return bus;
    }
    // Then output buses (13-20 => O1-O8)
    for (int bus = 13; bus <= 20; bus++) {
      if (!used.contains(bus)) return bus;
    }
    // Finally input buses (1-12)
    for (int bus = 1; bus <= 12; bus++) {
      if (!used.contains(bus)) return bus;
    }
    throw InsufficientBusesException('All buses are in use');
  }

  int _findAvailableAuxBusConsideringState(List<Connection> existingConnections) {
    return _findAvailableAuxBusConsideringStateWithSet(
      existingConnections.map((c) => c.assignedBus).toSet(),
    );
  }

  /// Get the current value of a parameter from the preset state
  int? _getParameterValue(int algorithmIndex, int parameterNumber) {
    final distingState = _cubit.state;
    
    if (distingState is! DistingStateSynchronized) {
      return null;
    }
    
    if (algorithmIndex < 0 || algorithmIndex >= distingState.slots.length) {
      return null;
    }
    
    final slot = distingState.slots[algorithmIndex];
    
    // Simply find the parameter value by its number
    final val = slot.values.firstWhere(
      (v) => v.parameterNumber == parameterNumber,
      orElse: () => ParameterValue.filler(),
    );
    
    if (val.value > 0) {
      debugPrint('[AutoRoutingService] Parameter #$parameterNumber in algorithm $algorithmIndex has value ${val.value}');
      return val.value;
    }
    
    return null;
  }
  
  // Collect ALL buses currently in use (both inputs and outputs)
  Set<int> _collectUsedOutputBusesFromState() {
    final used = <int>{};
    final s = _cubit.state;
    if (s is! DistingStateSynchronized) return used;
    final units = s.unitStrings;
    
    // Check ALL slots for ANY bus parameters that are set
    for (final slot in s.slots) {
      for (final param in slot.parameters) {
        // Check if this is a bus parameter
        final unit = param.getUnitString(units) ?? '';
        final isBusParam = unit == 'bus' || (param.unit == 1 && param.max >= 28);
        
        if (!isBusParam) continue;
        
        // Get current value for this parameter
        final val = slot.values.firstWhere(
          (v) => v.parameterNumber == param.parameterNumber,
          orElse: () => ParameterValue.filler(),
        );
        
        // If it has a non-zero value, that bus is in use
        if (val.value > 0) {
          used.add(val.value);
          debugPrint('[AutoRoutingService] Bus ${val.value} is in use by parameter "${param.name}"');
        }
      }
    }
    
    debugPrint('[AutoRoutingService] Total buses in use: ${used.length} - ${used.toList()..sort()}');
    return used;
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
    final units = distingState.unitStrings;
    
    debugPrint('[AutoRoutingService] Finding parameter for port "$portId" (isOutput=$isOutput) in algorithm $algorithmIndex');
    
    // Convert portId back to a parameter name pattern
    // The portId is sanitized (e.g., "output" or "l_input")
    // We need to find parameters whose sanitized names match
    
    // First pass: exact match with sanitized name AND matching input/output type
    for (final param in slot.parameters) {
      // Sanitize the parameter name the same way PortExtractionService does
      final sanitizedParamName = param.name
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]'), '_')
          .replaceAll(RegExp(r'_+'), '_')
          .replaceAll(RegExp(r'^_|_$'), '');
      
      if (sanitizedParamName == portId) {
        // Check if this is a bus parameter
        final unit = param.getUnitString(units) ?? '';
        final isBusParam = unit == 'bus' || (param.unit == 1 && param.max >= 28);
        
        if (!isBusParam) continue;
        
        // For exact matches, also verify it matches the expected input/output type
        // Output parameters typically have default values >= 13 (Output buses start at 13)
        // Input parameters typically have default values <= 12 or 0
        final isParamOutput = param.defaultValue >= 13 && param.defaultValue <= 28;
        final isParamInput = param.defaultValue >= 0 && param.defaultValue <= 12;
        
        if (isOutput && isParamOutput) {
          debugPrint('[AutoRoutingService] Exact match OUTPUT: Found parameter "${param.name}" (#${param.parameterNumber}) for port "$portId"');
          return param.parameterNumber;
        } else if (!isOutput && isParamInput) {
          debugPrint('[AutoRoutingService] Exact match INPUT: Found parameter "${param.name}" (#${param.parameterNumber}) for port "$portId"');
          return param.parameterNumber;
        }
        // If type doesn't match, continue searching
      }
    }
    
    // Second pass: find bus parameters and match by type
    for (final param in slot.parameters) {
      // Check if this is a bus parameter
      final unit = param.getUnitString(units) ?? '';
      final isBusParam = unit == 'bus' || (param.unit == 1 && param.max >= 28);
      
      if (!isBusParam) continue;
      
      final nameLower = param.name.toLowerCase();
      final sanitizedParamName = param.name
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]'), '_')
          .replaceAll(RegExp(r'_+'), '_')
          .replaceAll(RegExp(r'^_|_$'), '');
      
      // Check if this parameter matches the type we're looking for
      if (isOutput) {
        // Looking for output parameters
        final isOutputParam = nameLower.contains('output') || 
                             nameLower.contains('send') ||
                             nameLower.contains('main out') ||
                             nameLower.contains('aux') ||
                             param.defaultValue >= 13 && param.defaultValue <= 28;
        
        if (isOutputParam) {
          // Check for partial match
          if (portId.contains('output') && sanitizedParamName.contains('output')) {
            debugPrint('[AutoRoutingService] Partial match: Found output parameter "${param.name}" (#${param.parameterNumber}) for port "$portId"');
            return param.parameterNumber;
          }
          if (portId.contains('main') && sanitizedParamName.contains('main')) {
            debugPrint('[AutoRoutingService] Partial match: Found main output parameter "${param.name}" (#${param.parameterNumber}) for port "$portId"');
            return param.parameterNumber;
          }
          // If only one output parameter exists, use it
          final outputParams = slot.parameters.where((p) {
            final pUnit = p.getUnitString(units) ?? '';
            final pNameLower = p.name.toLowerCase();
            return (pUnit == 'bus' || (p.unit == 1 && p.max >= 28)) &&
                   (pNameLower.contains('output') || pNameLower.contains('send') || 
                    pNameLower.contains('main out') || pNameLower.contains('aux'));
          }).toList();
          
          if (outputParams.length == 1) {
            debugPrint('[AutoRoutingService] Single output: Found parameter "${param.name}" (#${param.parameterNumber}) for port "$portId"');
            return param.parameterNumber;
          }
        }
      } else {
        // Looking for input parameters
        final isInputParam = nameLower.contains('input') || 
                            nameLower.contains('receive') ||
                            nameLower.contains('pitch') ||
                            nameLower.contains('wave') ||
                            nameLower.contains('clock') ||
                            nameLower.contains('gate') ||
                            nameLower.contains('v/oct') ||
                            param.defaultValue >= 1 && param.defaultValue <= 12;
        
        if (isInputParam) {
          // Check for partial match
          if (portId.contains('input') && sanitizedParamName.contains('input')) {
            // Try to match more specific inputs first
            if (portId.startsWith('l_') && sanitizedParamName.startsWith('l_')) {
              debugPrint('[AutoRoutingService] Partial match: Found L input parameter "${param.name}" (#${param.parameterNumber}) for port "$portId"');
              return param.parameterNumber;
            }
            if (portId.startsWith('r_') && sanitizedParamName.startsWith('r_')) {
              debugPrint('[AutoRoutingService] Partial match: Found R input parameter "${param.name}" (#${param.parameterNumber}) for port "$portId"');
              return param.parameterNumber;
            }
            // Generic input match
            debugPrint('[AutoRoutingService] Partial match: Found input parameter "${param.name}" (#${param.parameterNumber}) for port "$portId"');
            return param.parameterNumber;
          }
          // Check for specific parameter names
          if (portId.contains('pitch') && sanitizedParamName.contains('pitch')) {
            debugPrint('[AutoRoutingService] Partial match: Found pitch parameter "${param.name}" (#${param.parameterNumber}) for port "$portId"');
            return param.parameterNumber;
          }
          if (portId.contains('wave') && sanitizedParamName.contains('wave')) {
            debugPrint('[AutoRoutingService] Partial match: Found wave parameter "${param.name}" (#${param.parameterNumber}) for port "$portId"');
            return param.parameterNumber;
          }
          // If only one input parameter exists, use it
          final inputParams = slot.parameters.where((p) {
            final pUnit = p.getUnitString(units) ?? '';
            final pNameLower = p.name.toLowerCase();
            return (pUnit == 'bus' || (p.unit == 1 && p.max >= 28)) &&
                   (pNameLower.contains('input') || pNameLower.contains('receive') ||
                    pNameLower.contains('pitch') || pNameLower.contains('wave'));
          }).toList();
          
          if (inputParams.length == 1) {
            debugPrint('[AutoRoutingService] Single input: Found parameter "${param.name}" (#${param.parameterNumber}) for port "$portId"');
            return param.parameterNumber;
          }
        }
      }
    }
    
    debugPrint('[AutoRoutingService] WARNING: No parameter found for port "$portId" in algorithm $algorithmIndex, using fallback');
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
  /// Remove a connection by clearing both the source output and target input parameters
  Future<void> removeConnection({
    required int sourceAlgorithmIndex,
    required String sourcePortId,
    required int targetAlgorithmIndex,
    required String targetPortId,
  }) async {
    debugPrint('[AutoRoutingService] Removing connection from $sourceAlgorithmIndex:$sourcePortId to $targetAlgorithmIndex:$targetPortId');

    // Find the parameter numbers for both ports
    final targetParamNumber = _findParameterNumberForPort(
      targetAlgorithmIndex,
      targetPortId,
      isOutput: false,
    );

    final sourceParamNumber = _findParameterNumberForPort(
      sourceAlgorithmIndex,
      sourcePortId,
      isOutput: true,
    );

    // Clear BOTH the source output and target input to None (0)
    // Since each bus is exclusive to one connection, we can safely clear both
    
    // Clear target input
    await _cubit.updateParameterValue(
      algorithmIndex: targetAlgorithmIndex,
      parameterNumber: targetParamNumber,
      value: 0,
      userIsChangingTheValue: true,
    );
    debugPrint('[AutoRoutingService] Cleared input parameter #$targetParamNumber on algorithm $targetAlgorithmIndex');

    // Clear source output
    await _cubit.updateParameterValue(
      algorithmIndex: sourceAlgorithmIndex,
      parameterNumber: sourceParamNumber,
      value: 0,
      userIsChangingTheValue: true,
    );
    debugPrint('[AutoRoutingService] Cleared output parameter #$sourceParamNumber on algorithm $sourceAlgorithmIndex');
  }
}
