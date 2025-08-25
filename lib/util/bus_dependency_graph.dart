import 'package:nt_helper/models/connection.dart';

/// Enhanced dependency graph that tracks precise bus lifetimes for safe optimization
class BusDependencyGraph {
  final Map<int, List<Connection>> _connections = {};
  final Map<int, PreciseBusLifetime> _busLifetimes = {};

  void clear() {
    _connections.clear();
    _busLifetimes.clear();
  }

  void addConnection(Connection connection) {
    _connections[connection.assignedBus] ??= [];
    _connections[connection.assignedBus]!.add(connection);

    _updateBusLifetime(connection);
  }

  void _updateBusLifetime(Connection connection) {
    final bus = connection.assignedBus;
    final sourceSlot = connection.sourceAlgorithmIndex;
    final targetSlot = connection.targetAlgorithmIndex;

    final existing = _busLifetimes[bus];
    if (existing == null) {
      _busLifetimes[bus] = PreciseBusLifetime(
        bus: bus,
        writerSlots: sourceSlot >= 0 ? [sourceSlot] : [],
        readerSlots: targetSlot >= 0 ? [targetSlot] : [],
        connections: [connection],
      );
    } else {
      final newWriters = Set<int>.from(existing.writerSlots);
      final newReaders = Set<int>.from(existing.readerSlots);
      final newConnections = List<Connection>.from(existing.connections);

      if (sourceSlot >= 0) newWriters.add(sourceSlot);
      if (targetSlot >= 0) newReaders.add(targetSlot);
      newConnections.add(connection);

      _busLifetimes[bus] = PreciseBusLifetime(
        bus: bus,
        writerSlots: newWriters.toList()..sort(),
        readerSlots: newReaders.toList()..sort(),
        connections: newConnections,
      );
    }
  }

  PreciseBusLifetime? getBusLifetime(int bus) {
    return _busLifetimes[bus];
  }

  /// Find the optimal connection to apply Replace mode for maximum bus reuse
  List<SafeReplaceOpportunity> findSafeReplaceOpportunities() {
    final opportunities = <SafeReplaceOpportunity>[];

    for (final lifetime in _busLifetimes.values) {
      if (lifetime.writerSlots.isEmpty || lifetime.readerSlots.isEmpty)
        continue;

      // Skip physical I/O connections (negative indices)
      if (lifetime.writerSlots.any((slot) => slot < 0)) continue;

      // Find the optimal connection to apply Replace mode
      final replaceOpportunity = _findOptimalReplaceConnection(lifetime);
      if (replaceOpportunity != null) {
        opportunities.add(replaceOpportunity);
      }
    }

    // Sort by potential bus reuse benefit (most beneficial first)
    opportunities.sort((a, b) => b.busesFreeable.compareTo(a.busesFreeable));

    return opportunities;
  }

  SafeReplaceOpportunity? _findOptimalReplaceConnection(
    PreciseBusLifetime lifetime,
  ) {
    // Strategy: Apply Replace mode to the last writer that allows bus reuse
    final bus = lifetime.bus;
    final lastReader = lifetime.lastReadSlot;

    if (lastReader == null) return null;

    // Find writers that come at or before the last reader
    final candidateWriters =
        lifetime.writerSlots
            .where((writerSlot) => writerSlot <= lastReader)
            .toList()
          ..sort(
            (a, b) => b.compareTo(a),
          ); // Sort in descending order (latest first)

    for (final writerSlot in candidateWriters) {
      // Check if this writer can safely use Replace mode
      if (_canSafelyApplyReplace(bus, writerSlot, lastReader)) {
        // Find the actual connection for this writer
        final connection = lifetime.connections.firstWhere(
          (conn) =>
              conn.sourceAlgorithmIndex == writerSlot &&
              conn.assignedBus == bus,
          orElse: () => lifetime.connections.first, // Fallback
        );

        return SafeReplaceOpportunity(
          bus: bus,
          connection: connection,
          freeAfterSlot: lastReader,
          busesFreeable: _calculatePotentialReuse(bus, lastReader),
        );
      }
    }

    return null;
  }

  bool _canSafelyApplyReplace(int bus, int writerSlot, int lastReaderSlot) {
    // Replace mode is safe if:
    // 1. The writer slot is at or before the last reader slot
    // 2. There are no readers after this writer that need the original signal

    if (writerSlot > lastReaderSlot) return false;

    final lifetime = _busLifetimes[bus]!;

    // For simple cases (single writer), Replace mode is generally safe
    if (lifetime.writerSlots.length == 1) {
      return true;
    }

    // For multiple writers, only the final writer should use Replace mode
    // to avoid breaking signal paths for later readers
    final finalWriter = lifetime.writerSlots.reduce((a, b) => a > b ? a : b);
    return writerSlot == finalWriter;
  }

  int _calculatePotentialReuse(int bus, int freeAfterSlot) {
    // Count how many other buses could potentially be consolidated
    // This is a heuristic - could be improved with more sophisticated analysis
    int potentialReuse = 0;

    for (final otherLifetime in _busLifetimes.values) {
      if (otherLifetime.bus == bus) continue;

      // If this other bus starts after our bus is freed, it could reuse it
      if (otherLifetime.firstWriteSlot != null &&
          otherLifetime.firstWriteSlot! > freeAfterSlot) {
        potentialReuse++;
      }
    }

    return potentialReuse;
  }

  /// Get information about buses that become available for reuse after Replace mode
  List<int> getBusesAvailableForReuse(
    List<SafeReplaceOpportunity> replaceOpportunities,
  ) {
    final availableBuses = <int>[];

    for (final replaceOpp in replaceOpportunities) {
      // After Replace mode is applied, this bus becomes available for new connections
      availableBuses.add(replaceOpp.bus);
    }

    return availableBuses;
  }

  /// Validate that an optimization preserves signal integrity
  bool validateSignalIntegrity(
    List<Connection> originalConnections,
    List<Connection> optimizedConnections,
  ) {
    // 1. Check that all signal paths are preserved (same source → target mappings)
    final originalPaths = _extractSignalPaths(originalConnections);
    final optimizedPaths = _extractSignalPaths(optimizedConnections);

    if (originalPaths.length != optimizedPaths.length) {
      return false; // Number of connections changed
    }

    // Every original path should have exactly one corresponding optimized path
    for (final originalPath in originalPaths) {
      final matchingPaths = optimizedPaths
          .where(
            (optimizedPath) => _pathsEquivalent(originalPath, optimizedPath),
          )
          .toList();
      if (matchingPaths.length != 1) {
        return false; // Signal path lost or duplicated
      }
    }

    // 2. Check that no connections were accidentally merged on the same bus that shouldn't be
    final busUsage = <int, List<Connection>>{};
    for (final connection in optimizedConnections) {
      busUsage.putIfAbsent(connection.assignedBus, () => []).add(connection);
    }

    // Validate that connections sharing a bus don't create conflicts
    for (final entry in busUsage.entries) {
      if (entry.value.length > 1 &&
          !_areBusSharingConnectionsSafe(entry.value)) {
        return false; // Unsafe bus sharing detected
      }
    }

    // 3. Check execution order is maintained
    for (final connection in optimizedConnections) {
      if (connection.sourceAlgorithmIndex >= 0 &&
          connection.targetAlgorithmIndex >= 0) {
        if (connection.sourceAlgorithmIndex >=
            connection.targetAlgorithmIndex) {
          return false; // Invalid execution order
        }
      }
    }

    return true;
  }

  List<SignalPath> _extractSignalPaths(List<Connection> connections) {
    final paths = <SignalPath>[];

    for (final connection in connections) {
      paths.add(
        SignalPath(
          source: connection.sourceAlgorithmIndex,
          target: connection.targetAlgorithmIndex,
          bus: connection.assignedBus,
        ),
      );
    }

    return paths;
  }

  bool _pathsEquivalent(SignalPath path1, SignalPath path2) {
    // Paths are equivalent if they connect the same source to the same target
    // (the bus used doesn't matter for signal integrity)
    return path1.source == path2.source && path1.target == path2.target;
  }

  bool _areBusSharingConnectionsSafe(List<Connection> connectionsOnSameBus) {
    // Connections can safely share a bus only in specific cases:
    // 1. Fan-out scenario: one source feeding multiple targets (same source, different targets)
    // 2. Replace mode scenario: connections that don't interfere with each other

    if (connectionsOnSameBus.length < 2) return true;

    // Group by source algorithm
    final bySource = <int, List<Connection>>{};
    for (final conn in connectionsOnSameBus) {
      bySource.putIfAbsent(conn.sourceAlgorithmIndex, () => []).add(conn);
    }

    // If all connections have the same source, it's a fan-out (generally safe)
    if (bySource.length == 1) {
      return true;
    }

    // Multiple sources on same bus - check if Replace mode makes it safe
    final sortedConnections = List<Connection>.from(connectionsOnSameBus);
    sortedConnections.sort(
      (a, b) => a.sourceAlgorithmIndex.compareTo(b.sourceAlgorithmIndex),
    );

    // For Replace mode safety, check that each connection either:
    // 1. Has Replace mode and finishes before the next connection starts, OR
    // 2. Is the last connection and can safely coexist
    for (int i = 0; i < sortedConnections.length; i++) {
      final current = sortedConnections[i];

      // If this is not the last connection
      if (i < sortedConnections.length - 1) {
        final next = sortedConnections[i + 1];

        // Current connection must have Replace mode and complete before next starts
        if (!current.replaceMode) {
          return false; // Would create bus conflict without Replace mode
        }

        // Verify execution order: current target must complete before next source
        if (current.targetAlgorithmIndex >= next.sourceAlgorithmIndex) {
          return false; // Timing conflict
        }
      }
    }

    return true; // All checks passed - bus sharing is safe
  }
}

/// Precise bus lifetime tracking with write/read timeline
class PreciseBusLifetime {
  final int bus;
  final List<int> writerSlots;
  final List<int> readerSlots;
  final List<Connection> connections;

  PreciseBusLifetime({
    required this.bus,
    required this.writerSlots,
    required this.readerSlots,
    required this.connections,
  });

  int? get firstWriteSlot => writerSlots.isEmpty ? null : writerSlots.first;
  int? get lastReadSlot => readerSlots.isEmpty ? null : readerSlots.last;
  int? get lastWriteSlot => writerSlots.isEmpty ? null : writerSlots.last;

  bool get hasReplaceMode => connections.any((conn) => conn.replaceMode);

  /// Bus becomes available for reuse after the last reader if Replace mode is used
  int? get freeAfterSlot {
    if (!hasReplaceMode || lastReadSlot == null) return null;
    return lastReadSlot;
  }

  bool get canBeReused => hasReplaceMode && freeAfterSlot != null;

  @override
  String toString() =>
      'BusLifetime(bus: $bus, writers: $writerSlots, readers: $readerSlots)';
}

/// Opportunity to safely apply Replace mode to a connection
class SafeReplaceOpportunity {
  final int bus;
  final Connection connection;
  final int freeAfterSlot;
  final int busesFreeable;

  SafeReplaceOpportunity({
    required this.bus,
    required this.connection,
    required this.freeAfterSlot,
    required this.busesFreeable,
  });

  @override
  String toString() =>
      'SafeReplaceOpportunity(bus: $bus, freeAfter: $freeAfterSlot, freeable: $busesFreeable)';
}

/// Represents a signal path from source to target
class SignalPath {
  final int source;
  final int target;
  final int bus;

  SignalPath({required this.source, required this.target, required this.bus});

  @override
  String toString() => 'SignalPath($source → $target via bus $bus)';
}
