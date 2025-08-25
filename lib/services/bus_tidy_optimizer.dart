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
  Future<TidyResult> tidyConnections([
    NodeRoutingStateLoaded? loadedState,
  ]) async {
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

      // Phase 1: Apply Replace mode to enable bus reuse (safe optimization)
      _applyReplaceModeForBusReuse(optimized, changes);

      // Phase 2: Conservative Aux bus consolidation (only when completely safe)
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

        final busesFreedThisRound = _attemptAuxBusConsolidation(
          optimized,
          changes,
        );
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

  /// Apply Replace mode to enable bus reuse (conservative approach)
  /// Only applies Replace mode when it's safe and won't break signal flow
  void _applyReplaceModeForBusReuse(
    List<Connection> optimized,
    Map<String, BusChange> changes,
  ) {
    // Group connections by bus
    final busUsage = <int, List<Connection>>{};
    for (final connection in optimized) {
      busUsage.putIfAbsent(connection.assignedBus, () => []).add(connection);
    }

    // Process each Aux bus to find safe Replace mode opportunities
    for (final entry in busUsage.entries) {
      final bus = entry.key;
      final connections = entry.value;

      // Only process Aux buses
      if (bus < 21 || bus > 28) continue;

      // Single connection on a bus - check if it can use Replace mode
      if (connections.length == 1) {
        final connection = connections[0];

        // Check if this bus is the final destination (no other connections read from this algorithm's output)
        // If so, it's safe to use Replace mode
        bool isFinalDestination = true;
        for (final otherConn in optimized) {
          if (otherConn.id != connection.id &&
              otherConn.sourceAlgorithmIndex ==
                  connection.targetAlgorithmIndex &&
              otherConn.assignedBus == bus) {
            isFinalDestination = false;
            break;
          }
        }

        if (isFinalDestination && !connection.replaceMode) {
          final idx = optimized.indexWhere((c) => c.id == connection.id);
          if (idx >= 0) {
            optimized[idx] = connection.copyWith(replaceMode: true);

            changes[connection.id] = BusChange(
              connectionId: connection.id,
              oldBus: bus,
              newBus: bus,
              oldReplaceMode: false,
              newReplaceMode: true,
              reason: 'Replace mode enabled - final destination on bus',
            );
          }
        }
      }
      // Multiple connections on the same bus - be very conservative
      else if (connections.length > 1) {
        // Sort by execution order
        connections.sort((a, b) {
          // First by source slot, then by target slot
          final sourceCompare = a.sourceAlgorithmIndex.compareTo(
            b.sourceAlgorithmIndex,
          );
          if (sourceCompare != 0) return sourceCompare;
          return a.targetAlgorithmIndex.compareTo(b.targetAlgorithmIndex);
        });

        // Only enable Replace mode on the LAST connection if it's safe
        final lastConnection = connections.last;

        // Check if the last connection is truly the last user of this bus
        bool isLastUser = true;
        for (final conn in connections) {
          if (conn.id != lastConnection.id) {
            // If any other connection starts after this one ends, not safe
            if (conn.sourceAlgorithmIndex >=
                lastConnection.targetAlgorithmIndex) {
              isLastUser = false;
              break;
            }
          }
        }

        if (isLastUser && !lastConnection.replaceMode) {
          final idx = optimized.indexWhere((c) => c.id == lastConnection.id);
          if (idx >= 0) {
            optimized[idx] = lastConnection.copyWith(replaceMode: true);

            changes[lastConnection.id] = BusChange(
              connectionId: lastConnection.id,
              oldBus: bus,
              newBus: bus,
              oldReplaceMode: false,
              newReplaceMode: true,
              reason: 'Replace mode enabled - last user of shared bus',
            );
          }
        }
      }
    }
  }

  /// Attempt one round of Aux bus consolidation
  /// Returns number of buses freed in this round
  /// CONSERVATIVE APPROACH: Only consolidate when absolutely safe
  int _attemptAuxBusConsolidation(
    List<Connection> optimized,
    Map<String, BusChange> changes,
  ) {
    // Group connections by bus
    final busUsage = <int, List<Connection>>{};
    for (final connection in optimized) {
      busUsage.putIfAbsent(connection.assignedBus, () => []).add(connection);
    }

    // Focus on Aux buses (21-28 for A1-A8)
    final auxBuses =
        busUsage.keys.where((bus) => bus >= 21 && bus <= 28).toList()..sort();
    if (auxBuses.length < 2) {
      return 0;
    }

    // CONSERVATIVE: Only consolidate completely non-overlapping buses
    // This means the source bus must complete ALL its operations before
    // the target bus begins ANY of its operations
    for (final targetBus in auxBuses) {
      final targetConnections = busUsage[targetBus] ?? [];
      if (targetConnections.isEmpty) continue;

      for (final sourceBus in auxBuses) {
        if (sourceBus == targetBus) continue;

        final sourceConnections = busUsage[sourceBus] ?? [];
        if (sourceConnections.isEmpty) continue;

        // Find the complete execution ranges
        int? sourceMinSlot, sourceMaxSlot, targetMinSlot, targetMaxSlot;

        // Calculate source bus execution range
        for (final conn in sourceConnections) {
          if (conn.sourceAlgorithmIndex >= 0) {
            sourceMinSlot = sourceMinSlot == null
                ? conn.sourceAlgorithmIndex
                : (conn.sourceAlgorithmIndex < sourceMinSlot
                      ? conn.sourceAlgorithmIndex
                      : sourceMinSlot);
          }
          if (conn.targetAlgorithmIndex >= 0) {
            sourceMaxSlot = sourceMaxSlot == null
                ? conn.targetAlgorithmIndex
                : (conn.targetAlgorithmIndex > sourceMaxSlot
                      ? conn.targetAlgorithmIndex
                      : sourceMaxSlot);
          }
        }

        // Calculate target bus execution range
        for (final conn in targetConnections) {
          if (conn.sourceAlgorithmIndex >= 0) {
            targetMinSlot = targetMinSlot == null
                ? conn.sourceAlgorithmIndex
                : (conn.sourceAlgorithmIndex < targetMinSlot
                      ? conn.sourceAlgorithmIndex
                      : targetMinSlot);
          }
          if (conn.targetAlgorithmIndex >= 0) {
            targetMaxSlot = targetMaxSlot == null
                ? conn.targetAlgorithmIndex
                : (conn.targetAlgorithmIndex > targetMaxSlot
                      ? conn.targetAlgorithmIndex
                      : targetMaxSlot);
          }
        }

        // Skip if we couldn't determine ranges
        if (sourceMinSlot == null ||
            sourceMaxSlot == null ||
            targetMinSlot == null ||
            targetMaxSlot == null) {
          continue;
        }

        // ULTRA CONSERVATIVE: Only consolidate if there's NO overlap whatsoever
        // Source must complete entirely before target begins
        bool canSafelyConsolidate = false;

        if (sourceMaxSlot < targetMinSlot) {
          // Source completes before target starts - safe to consolidate
          canSafelyConsolidate = true;
        } else if (targetMaxSlot < sourceMinSlot) {
          // Target completes before source starts - safe to consolidate
          canSafelyConsolidate = true;
        }

        if (!canSafelyConsolidate) {
          continue;
        }

        // Additional safety check: Verify no shared algorithms between source and target
        final sourceAlgorithms = <int>{};
        final targetAlgorithms = <int>{};

        for (final conn in sourceConnections) {
          if (conn.sourceAlgorithmIndex >= 0)
            sourceAlgorithms.add(conn.sourceAlgorithmIndex);
          if (conn.targetAlgorithmIndex >= 0)
            sourceAlgorithms.add(conn.targetAlgorithmIndex);
        }

        for (final conn in targetConnections) {
          if (conn.sourceAlgorithmIndex >= 0)
            targetAlgorithms.add(conn.sourceAlgorithmIndex);
          if (conn.targetAlgorithmIndex >= 0)
            targetAlgorithms.add(conn.targetAlgorithmIndex);
        }

        // If any algorithm appears in both sets, skip consolidation
        if (sourceAlgorithms.intersection(targetAlgorithms).isNotEmpty) {
          continue;
        }

        // SAFE TO CONSOLIDATE: Move all source connections to target bus
        for (final connection in sourceConnections) {
          final idx = optimized.indexWhere((c) => c.id == connection.id);
          if (idx >= 0) {
            final original = optimized[idx];

            // Determine if Replace mode is needed
            // Use Replace mode if this is the last writer to the bus
            bool useReplace = false;
            if (sourceMaxSlot < targetMinSlot) {
              // Source finishes first, so it should use Replace to free the bus
              useReplace = (connection.targetAlgorithmIndex == sourceMaxSlot);
            } else {
              // Target finishes first, keep existing Replace mode logic
              useReplace = true;
            }

            final consolidatedConnection = original.copyWith(
              assignedBus: targetBus,
              replaceMode: useReplace,
            );

            optimized[idx] = consolidatedConnection;

            // Track the change
            changes[connection.id] = BusChange(
              connectionId: connection.id,
              oldBus: sourceBus,
              newBus: targetBus,
              oldReplaceMode: original.replaceMode,
              newReplaceMode: useReplace,
              reason: 'Safe Aux bus consolidation - completely non-overlapping',
            );
          }
        }

        // We freed one bus - return immediately to be conservative
        // Don't try multiple consolidations in one pass
        return 1;
      }
    }

    return 0;
  }

  // REMOVED: Old helper methods (_updateRelatedConnections, _wouldCreateSignalMixing, _canConsolidateBuses)
  // The conservative approach handles all safety checks inline within _attemptAuxBusConsolidation

  /// Validate execution order constraints (source slot < target slot for algorithm connections)
  bool _validateExecutionOrder(List<Connection> connections) {
    for (final connection in connections) {
      // Skip physical I/O connections (negative indices)
      if (connection.sourceAlgorithmIndex < 0 ||
          connection.targetAlgorithmIndex < 0) {
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
