import 'package:nt_helper/models/algorithm_port.dart';
import 'package:nt_helper/models/connection.dart';
import 'package:nt_helper/util/topological_sort.dart';

class RoutingValidator {
  /// Comprehensive validation of a proposed connection
  static ValidationResult validateConnection({
    required Connection proposedConnection,
    required List<Connection> existingConnections,
    required Map<int, List<AlgorithmPort>> algorithmPorts,
  }) {
    final errors = <String>[];
    final warnings = <String>[];

    // Check 1: Port compatibility
    final sourcePort = _getPort(
      algorithmPorts[proposedConnection.sourceAlgorithmIndex] ?? [],
      proposedConnection.sourcePortId,
    );
    final targetPort = _getPort(
      algorithmPorts[proposedConnection.targetAlgorithmIndex] ?? [],
      proposedConnection.targetPortId,
    );

    if (sourcePort == null) {
      errors.add('Source port not found: ${proposedConnection.sourcePortId}');
    }
    if (targetPort == null) {
      errors.add('Target port not found: ${proposedConnection.targetPortId}');
    }

    if (sourcePort != null && targetPort != null) {
      if (!_arePortsCompatible(sourcePort, targetPort)) {
        errors.add('Incompatible port types: ${sourcePort.name} to ${targetPort.name}');
      }
    }

    // Check 2: Would create cycle?
    if (_wouldCreateCycle(proposedConnection, existingConnections)) {
      errors.add('Connection would create circular dependency');
    }

    // Check 3: Processing order constraint
    if (_isModulationConnection(targetPort)) {
      if (proposedConnection.sourceAlgorithmIndex > proposedConnection.targetAlgorithmIndex) {
        errors.add('Modulation source must be in earlier slot than target');
      }
    }

    // Check 4: Bus availability
    final busesInUse = _countBusesInUse(existingConnections);
    if (busesInUse >= 8 && !_canShareBus(proposedConnection, existingConnections)) {
      errors.add('No available auxiliary buses');
    }

    // Check 5: Duplicate connection
    if (_isDuplicateConnection(proposedConnection, existingConnections)) {
      warnings.add('Connection already exists');
    }

    // Check 6: Target already connected
    if (_isTargetAlreadyConnected(proposedConnection, existingConnections)) {
      warnings.add('Target port already has an input - will be replaced');
    }

    // Check 7: Self-connection
    if (proposedConnection.sourceAlgorithmIndex == proposedConnection.targetAlgorithmIndex) {
      errors.add('Cannot connect algorithm to itself');
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  /// Validate entire routing graph for consistency
  static GraphValidationResult validateGraph({
    required List<Connection> connections,
    required Map<int, List<AlgorithmPort>> algorithmPorts,
  }) {
    final errors = <String>[];
    final warnings = <String>[];

    // Check for cycles in the graph
    try {
      final adjacencyList = _buildAdjacencyList(connections);
      TopologicalSort.topologicalSort(adjacencyList);
    } catch (e) {
      if (e is CycleDetectedException) {
        errors.add('Circular dependency detected in routing graph');
        final cyclePath = TopologicalSort.findCyclePath(_buildAdjacencyList(connections));
        if (cyclePath != null) {
          errors.add('Cycle path: ${cyclePath.join(' -> ')}');
        }
      }
    }

    // Check bus usage
    final busUsage = <int, int>{};
    for (final connection in connections) {
      busUsage[connection.assignedBus] = (busUsage[connection.assignedBus] ?? 0) + 1;
    }

    // Warn about overused buses
    for (final entry in busUsage.entries) {
      if (entry.value > 4) { // Arbitrary threshold
        warnings.add('Bus ${entry.key} has ${entry.value} connections - may cause signal conflicts');
      }
    }

    // Check for orphaned outputs
    final outputAlgorithms = <int>{};
    final inputAlgorithms = <int>{};
    
    for (final connection in connections) {
      outputAlgorithms.add(connection.sourceAlgorithmIndex);
      inputAlgorithms.add(connection.targetAlgorithmIndex);
    }

    final orphanedOutputs = outputAlgorithms.difference(inputAlgorithms);
    if (orphanedOutputs.isNotEmpty) {
      warnings.add('Algorithms with no downstream connections: ${orphanedOutputs.join(', ')}');
    }

    return GraphValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
      suggestedOptimizations: _suggestOptimizations(connections),
    );
  }

  static AlgorithmPort? _getPort(List<AlgorithmPort> ports, String portId) {
    try {
      return ports.firstWhere((p) => p.id == portId);
    } catch (e) {
      return null;
    }
  }

  static bool _arePortsCompatible(AlgorithmPort source, AlgorithmPort target) {
    // Audio outputs can connect to audio inputs
    // CV outputs can connect to CV inputs or modulation inputs
    // Gate outputs can connect to gate/trigger inputs
    
    final sourceName = source.name.toLowerCase();
    final targetName = target.name.toLowerCase();

    if (sourceName.contains('audio') && targetName.contains('audio')) return true;
    if (sourceName.contains('cv') && (targetName.contains('cv') || targetName.contains('modulation'))) return true;
    if (sourceName.contains('gate') && (targetName.contains('gate') || targetName.contains('trigger'))) return true;
    if (sourceName.contains('signal') && targetName.contains('signal')) return true;

    return false;
  }

  static bool _wouldCreateCycle(
    Connection proposedConnection,
    List<Connection> existingConnections,
  ) {
    // Build adjacency list including proposed connection
    final adjacencyList = _buildAdjacencyList([...existingConnections, proposedConnection]);
    
    try {
      TopologicalSort.topologicalSort(adjacencyList);
      return false;
    } catch (e) {
      return e is CycleDetectedException;
    }
  }

  static Map<int, Set<int>> _buildAdjacencyList(List<Connection> connections) {
    final graph = <int, Set<int>>{};
    
    for (final conn in connections) {
      graph[conn.sourceAlgorithmIndex] ??= <int>{};
      graph[conn.targetAlgorithmIndex] ??= <int>{};
      graph[conn.sourceAlgorithmIndex]!.add(conn.targetAlgorithmIndex);
    }
    
    return graph;
  }

  static bool _isModulationConnection(AlgorithmPort? targetPort) {
    if (targetPort == null) return false;
    final portName = targetPort.name.toLowerCase();
    return portName.contains('cv') || 
           portName.contains('modulation') || 
           portName.contains('control');
  }

  static int _countBusesInUse(List<Connection> connections) {
    final busesInUse = <int>{};
    for (final connection in connections) {
      if (connection.assignedBus >= 21 && connection.assignedBus <= 28) {
        busesInUse.add(connection.assignedBus);
      }
    }
    return busesInUse.length;
  }

  static bool _canShareBus(Connection proposedConnection, List<Connection> existingConnections) {
    // Check if any existing connection has the same source - can share bus
    return existingConnections.any((conn) => 
      conn.sourceAlgorithmIndex == proposedConnection.sourceAlgorithmIndex &&
      conn.sourcePortId == proposedConnection.sourcePortId
    );
  }

  static bool _isDuplicateConnection(Connection proposedConnection, List<Connection> existingConnections) {
    return existingConnections.any((conn) =>
      conn.sourceAlgorithmIndex == proposedConnection.sourceAlgorithmIndex &&
      conn.sourcePortId == proposedConnection.sourcePortId &&
      conn.targetAlgorithmIndex == proposedConnection.targetAlgorithmIndex &&
      conn.targetPortId == proposedConnection.targetPortId
    );
  }

  static bool _isTargetAlreadyConnected(Connection proposedConnection, List<Connection> existingConnections) {
    return existingConnections.any((conn) =>
      conn.targetAlgorithmIndex == proposedConnection.targetAlgorithmIndex &&
      conn.targetPortId == proposedConnection.targetPortId
    );
  }

  static List<String> _suggestOptimizations(List<Connection> connections) {
    final suggestions = <String>[];
    
    // Find opportunities for bus sharing
    final sourceGroups = <String, List<Connection>>{};
    for (final conn in connections) {
      final key = '${conn.sourceAlgorithmIndex}_${conn.sourcePortId}';
      sourceGroups[key] ??= [];
      sourceGroups[key]!.add(conn);
    }
    
    for (final entry in sourceGroups.entries) {
      if (entry.value.length > 1) {
        final uniqueBuses = entry.value.map((c) => c.assignedBus).toSet();
        if (uniqueBuses.length > 1) {
          suggestions.add('Source ${entry.key} could share a single bus for all targets');
        }
      }
    }
    
    return suggestions;
  }
}

class ValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;

  ValidationResult({
    required this.isValid,
    required this.errors,
    required this.warnings,
  });
}

class GraphValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;
  final List<String> suggestedOptimizations;

  GraphValidationResult({
    required this.isValid,
    required this.errors,
    required this.warnings,
    required this.suggestedOptimizations,
  });
}