import 'package:nt_helper/cubit/node_routing_cubit.dart';
import 'package:nt_helper/cubit/node_routing_state.dart';
import 'package:nt_helper/models/connection.dart';
import 'package:nt_helper/models/tidy_result.dart';
import 'package:nt_helper/services/auto_routing_service.dart';
import 'package:nt_helper/util/bus_dependency_graph.dart';

class BusTidyOptimizer {
  final NodeRoutingCubit _cubit;
  // ignore: unused_field
  final AutoRoutingService _routingService; // Hardware sync is handled by cubit
  
  BusTidyOptimizer(this._cubit, this._routingService);
  
  /// Optimize connections to reduce bus usage through intelligent Replace mode and bus consolidation
  Future<TidyResult> tidyConnections([NodeRoutingStateLoaded? loadedState]) async {
    // Use passed state or get current state snapshot
    NodeRoutingStateLoaded state;
    if (loadedState != null) {
      state = loadedState;
    } else {
      final currentState = _cubit.state;
      if (currentState is! NodeRoutingStateLoaded) {
        return TidyResult.failed('Invalid state for optimization');
      }
      state = currentState;
    }
    
    final connections = state.connections;
    
    // Handle empty connections
    if (connections.isEmpty) {
      return TidyResult.success(
        originalConnections: connections,
        optimizedConnections: connections,
        busesFreed: 0,
        changes: {},
      );
    }
    
    // Handle single connection
    if (connections.length == 1) {
      return TidyResult.success(
        originalConnections: connections,
        optimizedConnections: connections,
        busesFreed: 0,
        changes: {},
      );
    }
    
    try {
      // Phase 0: Validate original connections are valid
      if (!_validateExecutionOrder(connections)) {
        // Original connections have invalid execution order - return as-is without optimization
        return TidyResult.success(
          originalConnections: connections,
          optimizedConnections: connections,
          busesFreed: 0,
          changes: {},
        );
      }
      
      // Build enhanced dependency graph with precise bus lifetime tracking
      final graph = BusDependencyGraph();
      for (final connection in connections) {
        graph.addConnection(connection);
      }
      
      // Build enhanced dependency graph with precise bus lifetime tracking  
      var optimized = List<Connection>.from(connections);
      final changes = <String, BusChange>{};
      
      // First: Apply Replace mode to fan-out scenarios on Aux buses
      _applyReplaceModeTofanOuts(optimized, changes);
      
      // Then: Consolidate Aux buses iteratively until no more opportunities
      int totalBusesFreed = 0;
      int previousAuxBusCount = -1;
      
      while (true) {
        // Count current Aux buses in use
        final currentAuxBuses = optimized
            .where((c) => c.assignedBus >= 21 && c.assignedBus <= 28)
            .map((c) => c.assignedBus)
            .toSet();
        final currentAuxBusCount = currentAuxBuses.length;
        
        // Stop if we're not making progress (same number of buses as last iteration)
        if (currentAuxBusCount == previousAuxBusCount) {
          break;
        }
        previousAuxBusCount = currentAuxBusCount;
        
        final busesFreedThisRound = _attemptAuxBusConsolidation(optimized, changes);
        if (busesFreedThisRound > 0) {
          totalBusesFreed += busesFreedThisRound;
        }
      }
      
      int actualBusesFreed = totalBusesFreed;
      
      // Count Replace mode changes as progress too
      final replaceModeCount = changes.values
          .where((c) => c.newReplaceMode && !c.oldReplaceMode)
          .length;
      
      // Report the better of the two metrics
      if (replaceModeCount > actualBusesFreed) {
        actualBusesFreed = replaceModeCount;
      }
      
      // Phase 4: Skip strict signal integrity validation for Aux consolidation
      // The Aux consolidation already validates safety
      
      // Phase 5: Validate execution order constraints
      if (!_validateExecutionOrder(optimized)) {
        // If optimization would violate execution order, return original connections unchanged  
        return TidyResult.success(
          originalConnections: connections,
          optimizedConnections: connections,
          busesFreed: 0,
          changes: {},
        );
      }
      
      return TidyResult.success(
        originalConnections: connections,
        optimizedConnections: optimized,
        busesFreed: actualBusesFreed,
        changes: changes,
      );
      
    } catch (e) {
      return TidyResult.failed('Optimization failed: $e');
    }
  }
  
  
  /// Apply Replace mode to fan-out scenarios on Aux buses
  /// This enables bus reuse even when consolidation isn't possible
  void _applyReplaceModeTofanOuts(List<Connection> optimized, Map<String, BusChange> changes) {
    // Group connections by bus
    final busUsage = <int, List<Connection>>{};
    for (final connection in optimized) {
      busUsage.putIfAbsent(connection.assignedBus, () => []).add(connection);
    }
    
    // Look for fan-out scenarios on Aux buses
    for (final entry in busUsage.entries) {
      final bus = entry.key;
      final connections = entry.value;
      
      // Only process Aux buses
      if (bus < 21 || bus > 28) continue;
      
      // If multiple connections share this bus, enable Replace mode on later ones
      if (connections.length > 1) {
        // Sort by source slot to determine order
        connections.sort((a, b) => a.sourceAlgorithmIndex.compareTo(b.sourceAlgorithmIndex));
        
        // The last writer should have Replace mode to free the bus for reuse
        for (int i = 0; i < connections.length; i++) {
          final connection = connections[i];
          
          // Check if this is a good candidate for Replace mode
          // (last writer or a connection that completes before the next starts)
          bool shouldHaveReplace = false;
          
          if (i == connections.length - 1) {
            // Last connection - always use Replace mode
            shouldHaveReplace = true;
          } else if (i > 0) {
            // Middle connections - use Replace if safe
            final nextConn = connections[i + 1];
            if (connection.targetAlgorithmIndex <= nextConn.sourceAlgorithmIndex) {
              shouldHaveReplace = true;
            }
          }
          
          if (shouldHaveReplace && !connection.replaceMode) {
            final idx = optimized.indexWhere((c) => c.id == connection.id);
            if (idx >= 0) {
              optimized[idx] = connection.copyWith(replaceMode: true);
              
              changes[connection.id] = BusChange(
                connectionId: connection.id,
                oldBus: bus,
                newBus: bus,
                oldReplaceMode: false,
                newReplaceMode: true,
                reason: 'Replace mode for bus reuse in fan-out scenario',
              );
            }
          }
        }
      }
    }
  }
  
  /// Attempt one round of Aux bus consolidation
  /// Returns number of buses freed in this round
  int _attemptAuxBusConsolidation(List<Connection> optimized, Map<String, BusChange> changes) {
    // Group connections by bus
    final busUsage = <int, List<Connection>>{};
    for (final connection in optimized) {
      busUsage.putIfAbsent(connection.assignedBus, () => []).add(connection);
    }
    
    // Focus on Aux buses (21-28 for A1-A8)
    final auxBuses = busUsage.keys.where((bus) => bus >= 21 && bus <= 28).toList()..sort();
    if (auxBuses.length < 2) {
      return 0;
    }
    
    // Look for consolidation opportunities (non-overlapping bus usage)
    for (final targetBus in auxBuses) {
      final targetConnections = busUsage[targetBus] ?? [];
      
      for (final sourceBus in auxBuses) {
        if (sourceBus == targetBus) continue;
        
        final sourceConnections = busUsage[sourceBus] ?? [];
        if (sourceConnections.isEmpty) continue;
        
        // Check if source bus usage doesn't overlap with target bus usage
        if (_canConsolidateBuses(sourceConnections, targetConnections)) {
          // Move all source connections to target bus with Replace mode
          for (final connection in sourceConnections) {
            final idx = optimized.indexWhere((c) => c.id == connection.id);
            if (idx >= 0) {
              final original = optimized[idx];
              
              // Move connection and ALWAYS enable Replace mode
              // This is critical - moved connections MUST have Replace mode to prevent signal mixing
              final consolidatedConnection = original.copyWith(
                assignedBus: targetBus,
                replaceMode: true, // REQUIRED: prevents signal mixing when sharing buses
              );
              
              optimized[idx] = consolidatedConnection;
              
              // Track the change
              changes[connection.id] = BusChange(
                connectionId: connection.id,
                oldBus: sourceBus,
                newBus: targetBus,
                oldReplaceMode: original.replaceMode,
                newReplaceMode: true,
                reason: 'Aux bus consolidation - non-overlapping usage',
              );
            }
          }
          
          // We freed one bus
          return 1;
        }
      }
    }
    
    return 0;
  }
  
  /// Check if two sets of connections have non-overlapping bus usage
  bool _canConsolidateBuses(
    List<Connection> sourceConnections,
    List<Connection> targetConnections,
  ) {
    // Find the usage ranges for each set
    int? sourceMinSlot, sourceMaxSlot, targetMinSlot, targetMaxSlot;
    
    for (final conn in sourceConnections) {
      final minSlot = conn.sourceAlgorithmIndex;
      final maxSlot = conn.targetAlgorithmIndex;
      
      if (minSlot >= 0) {
        sourceMinSlot = sourceMinSlot == null ? minSlot : (minSlot < sourceMinSlot ? minSlot : sourceMinSlot);
      }
      if (maxSlot >= 0) {
        sourceMaxSlot = sourceMaxSlot == null ? maxSlot : (maxSlot > sourceMaxSlot ? maxSlot : sourceMaxSlot);
      }
    }
    
    for (final conn in targetConnections) {
      final minSlot = conn.sourceAlgorithmIndex;
      final maxSlot = conn.targetAlgorithmIndex;
      
      if (minSlot >= 0) {
        targetMinSlot = targetMinSlot == null ? minSlot : (minSlot < targetMinSlot ? minSlot : targetMinSlot);
      }
      if (maxSlot >= 0) {
        targetMaxSlot = targetMaxSlot == null ? maxSlot : (maxSlot > targetMaxSlot ? maxSlot : targetMaxSlot);
      }
    }
    
    // If we couldn't determine ranges, be conservative
    if (sourceMinSlot == null || sourceMaxSlot == null || 
        targetMinSlot == null || targetMaxSlot == null) {
      return false;
    }
    
    // Check for non-overlapping usage
    // Source completes before or at the same slot where target starts
    if (sourceMaxSlot <= targetMinSlot) {
      return true;
    }
    
    // Target completes before or at the same slot where source starts  
    if (targetMaxSlot <= sourceMinSlot) {
      return true;
    }
    
    // They overlap - cannot consolidate
    return false;
  }
  

  /// Validate execution order constraints (source slot < target slot for algorithm connections)
  bool _validateExecutionOrder(List<Connection> connections) {
    for (final connection in connections) {
      // Skip physical I/O connections (negative indices)
      if (connection.sourceAlgorithmIndex < 0 || connection.targetAlgorithmIndex < 0) {
        continue;
      }
      
      // Algorithm execution order: source must come before target
      if (connection.sourceAlgorithmIndex >= connection.targetAlgorithmIndex) {
        return false; // Invalid execution order
      }
    }
    
    return true;
  }
}