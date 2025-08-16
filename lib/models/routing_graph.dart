import 'dart:collection';
import 'package:nt_helper/models/algorithm_port.dart';
import 'package:nt_helper/models/connection.dart';
import 'package:nt_helper/models/node_position.dart';

class RoutingGraph {
  final List<NodePosition> nodePositions;
  final List<Connection> connections;
  final Map<int, List<AlgorithmPort>> algorithmPorts;

  RoutingGraph({
    required this.nodePositions,
    required this.connections,
    required this.algorithmPorts,
  });

  /// Validate graph topology for cycles
  bool validateTopology() {
    try {
      getProcessingOrder();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get topological sort order of algorithms
  List<int> getProcessingOrder() {
    // Build adjacency list from connections
    final graph = <int, Set<int>>{};
    
    // Initialize all nodes
    for (final position in nodePositions) {
      graph[position.algorithmIndex] = <int>{};
    }
    
    // Add edges from connections
    for (final connection in connections) {
      graph[connection.sourceAlgorithmIndex] ??= <int>{};
      graph[connection.targetAlgorithmIndex] ??= <int>{};
      graph[connection.sourceAlgorithmIndex]!.add(connection.targetAlgorithmIndex);
    }

    return _topologicalSort(graph);
  }

  /// Kahn's algorithm for topological sorting
  List<int> _topologicalSort(Map<int, Set<int>> graph) {
    // Calculate in-degrees
    final inDegree = <int, int>{};
    for (final node in graph.keys) {
      inDegree[node] = 0;
    }
    
    for (final neighbors in graph.values) {
      for (final neighbor in neighbors) {
        inDegree[neighbor] = (inDegree[neighbor] ?? 0) + 1;
      }
    }
    
    // Start with nodes that have no dependencies
    final queue = Queue<int>();
    final result = <int>[];
    
    for (final entry in inDegree.entries) {
      if (entry.value == 0) {
        queue.add(entry.key);
      }
    }
    
    // Process queue
    while (queue.isNotEmpty) {
      final current = queue.removeFirst();
      result.add(current);
      
      // Remove edges from current node
      for (final neighbor in graph[current] ?? <int>{}) {
        inDegree[neighbor] = inDegree[neighbor]! - 1;
        if (inDegree[neighbor] == 0) {
          queue.add(neighbor);
        }
      }
    }
    
    // Check for cycles
    if (result.length != graph.length) {
      throw Exception('Cycle detected in routing graph');
    }
    
    return result;
  }

  /// Find an available aux bus for new connections
  int assignBus(Connection connection) {
    final usedBuses = <int>{};
    
    // Collect all buses currently in use
    for (final conn in connections) {
      usedBuses.add(conn.assignedBus);
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
    
    throw Exception('No available buses for connection');
  }

  /// Create a copy with updated connections
  RoutingGraph copyWith({
    List<NodePosition>? nodePositions,
    List<Connection>? connections,
    Map<int, List<AlgorithmPort>>? algorithmPorts,
  }) {
    return RoutingGraph(
      nodePositions: nodePositions ?? this.nodePositions,
      connections: connections ?? this.connections,
      algorithmPorts: algorithmPorts ?? this.algorithmPorts,
    );
  }
}