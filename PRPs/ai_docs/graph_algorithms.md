# Graph Algorithms for Node-Based Routing

## Topological Sorting for DAG Validation

### Kahn's Algorithm Implementation

```dart
class TopologicalSorter {
  /// Performs topological sort on algorithm dependency graph
  /// Returns ordered list of algorithm indices or throws if cycle detected
  static List<int> sort(Map<int, List<int>> adjacencyList) {
    // Build in-degree map
    final inDegree = <int, int>{};
    for (final node in adjacencyList.keys) {
      inDegree[node] ??= 0;
      for (final neighbor in adjacencyList[node] ?? []) {
        inDegree[neighbor] = (inDegree[neighbor] ?? 0) + 1;
      }
    }
    
    // Initialize queue with nodes having no dependencies
    final queue = Queue<int>();
    final result = <int>[];
    
    for (final node in inDegree.keys) {
      if (inDegree[node] == 0) {
        queue.add(node);
      }
    }
    
    // Process queue
    while (queue.isNotEmpty) {
      final current = queue.removeFirst();
      result.add(current);
      
      // Reduce in-degree for neighbors
      for (final neighbor in adjacencyList[current] ?? []) {
        inDegree[neighbor] = inDegree[neighbor]! - 1;
        if (inDegree[neighbor] == 0) {
          queue.add(neighbor);
        }
      }
    }
    
    // Check if all nodes were processed
    if (result.length != adjacencyList.length) {
      throw CycleDetectedException(_findCycle(adjacencyList));
    }
    
    return result;
  }
  
  /// DFS-based cycle detection with path reconstruction
  static List<int>? _findCycle(Map<int, List<int>> adjacencyList) {
    final visited = <int>{};
    final recursionStack = <int>{};
    final parent = <int, int>{};
    
    bool dfs(int node) {
      visited.add(node);
      recursionStack.add(node);
      
      for (final neighbor in adjacencyList[node] ?? []) {
        if (!visited.contains(neighbor)) {
          parent[neighbor] = node;
          if (dfs(neighbor)) return true;
        } else if (recursionStack.contains(neighbor)) {
          // Found cycle - reconstruct path
          final cycle = <int>[neighbor];
          int current = node;
          while (current != neighbor) {
            cycle.add(current);
            current = parent[current]!;
          }
          cycle.add(neighbor); // Close the cycle
          return true;
        }
      }
      
      recursionStack.remove(node);
      return false;
    }
    
    for (final node in adjacencyList.keys) {
      if (!visited.contains(node)) {
        if (dfs(node)) {
          // Cycle found
          return parent.entries.map((e) => e.key).toList();
        }
      }
    }
    
    return null;
  }
}
```

### Dependency Graph Builder

```dart
class DependencyGraphBuilder {
  /// Build adjacency list from connections
  /// Edge from A to B means A must process before B
  static Map<int, List<int>> buildFromConnections(
    List<Connection> connections,
    List<AlgorithmInfo> algorithms,
  ) {
    final graph = <int, List<int>>{};
    
    // Initialize all nodes
    for (final algo in algorithms) {
      graph[algo.algorithmIndex] = [];
    }
    
    // Add edges based on connections
    for (final connection in connections) {
      final source = connection.sourceAlgorithmIndex;
      final target = connection.targetAlgorithmIndex;
      
      // Source must process before target
      graph[source]!.add(target);
    }
    
    // Add modulation dependencies
    _addModulationDependencies(graph, algorithms);
    
    // Handle feedback pairs specially
    _handleFeedbackPairs(graph, algorithms);
    
    return graph;
  }
  
  static void _addModulationDependencies(
    Map<int, List<int>> graph,
    List<AlgorithmInfo> algorithms,
  ) {
    for (final algo in algorithms) {
      // Check if algorithm has CV inputs
      final cvInputs = algo.parameters
          .where((p) => p.type == ParameterType.cvInput)
          .toList();
      
      for (final cvInput in cvInputs) {
        final sourceIndex = cvInput.sourceAlgorithmIndex;
        if (sourceIndex != null && sourceIndex != algo.algorithmIndex) {
          // CV source must process before this algorithm
          graph[sourceIndex]!.add(algo.algorithmIndex);
        }
      }
    }
  }
  
  static void _handleFeedbackPairs(
    Map<int, List<int>> graph,
    List<AlgorithmInfo> algorithms,
  ) {
    // Find feedback receive/send pairs
    final feedbackPairs = <int, int>{};
    
    for (final algo in algorithms) {
      if (algo.type == 'fbrx_receive') {
        final identifier = algo.getParameter('identifier');
        // Find matching send with same identifier
        final sendAlgo = algorithms.firstWhere(
          (a) => a.type == 'fbrx_send' && 
                 a.getParameter('identifier') == identifier,
        );
        
        if (sendAlgo != null) {
          // Receive must process before send for feedback
          graph[algo.algorithmIndex]!.add(sendAlgo.algorithmIndex);
        }
      }
    }
  }
}
```

## Automatic Bus Assignment

### Bus Assignment Strategy

```dart
class BusAssignmentStrategy {
  static const int FIRST_AUX_BUS = 21;
  static const int LAST_AUX_BUS = 28;
  static const int MAX_AUX_BUSES = 8;
  
  /// Assigns buses to connections minimizing bus usage
  static Map<Connection, int> assignBuses(
    List<Connection> connections,
    Map<int, List<int>> dependencyGraph,
  ) {
    final assignments = <Connection, int>{};
    final busUsage = BusUsageTracker();
    
    // Sort connections by dependency order
    final sortedConnections = _sortConnectionsByDependency(
      connections,
      dependencyGraph,
    );
    
    for (final connection in sortedConnections) {
      // Try to reuse a bus if possible
      final reusableBus = busUsage.findReusableBus(
        connection,
        assignments,
        dependencyGraph,
      );
      
      if (reusableBus != null) {
        assignments[connection] = reusableBus;
        busUsage.markBusUsed(reusableBus, connection);
      } else {
        // Allocate new bus
        final newBus = busUsage.allocateNewBus();
        if (newBus == null) {
          throw InsufficientBusesException(
            'No available buses for connection ${connection.id}',
          );
        }
        assignments[connection] = newBus;
        busUsage.markBusUsed(newBus, connection);
      }
    }
    
    return assignments;
  }
  
  /// Sort connections to process in dependency order
  static List<Connection> _sortConnectionsByDependency(
    List<Connection> connections,
    Map<int, List<int>> dependencyGraph,
  ) {
    // Topological sort of algorithms
    final algorithmOrder = TopologicalSorter.sort(dependencyGraph);
    final orderMap = <int, int>{};
    for (int i = 0; i < algorithmOrder.length; i++) {
      orderMap[algorithmOrder[i]] = i;
    }
    
    // Sort connections by source algorithm order
    return connections.toList()
      ..sort((a, b) {
        final orderA = orderMap[a.sourceAlgorithmIndex] ?? 999;
        final orderB = orderMap[b.sourceAlgorithmIndex] ?? 999;
        return orderA.compareTo(orderB);
      });
  }
}

class BusUsageTracker {
  final Map<int, BusUsageInfo> _busUsage = {};
  final Set<int> _allocatedBuses = {};
  
  /// Find a bus that can be reused for this connection
  int? findReusableBus(
    Connection connection,
    Map<Connection, int> existingAssignments,
    Map<int, List<int>> dependencyGraph,
  ) {
    for (final entry in _busUsage.entries) {
      final bus = entry.key;
      final usage = entry.value;
      
      // Check if bus is free at the point where target needs it
      if (_isBusFreeForConnection(bus, connection, usage, dependencyGraph)) {
        return bus;
      }
    }
    return null;
  }
  
  bool _isBusFreeForConnection(
    int bus,
    Connection connection,
    BusUsageInfo currentUsage,
    Map<int, List<int>> dependencyGraph,
  ) {
    // Bus is free if:
    // 1. Last writer processes before target
    // 2. No readers between last writer and target
    
    final lastWriter = currentUsage.lastWriter;
    final target = connection.targetAlgorithmIndex;
    
    // Check dependency order
    if (!_processesBefor(lastWriter, target, dependencyGraph)) {
      return false;
    }
    
    // Check for intermediate readers
    for (final reader in currentUsage.readers) {
      if (_processesBetween(reader, lastWriter, target, dependencyGraph)) {
        return false;
      }
    }
    
    return true;
  }
  
  /// Allocate a new aux bus
  int? allocateNewBus() {
    for (int bus = FIRST_AUX_BUS; bus <= LAST_AUX_BUS; bus++) {
      if (!_allocatedBuses.contains(bus)) {
        _allocatedBuses.add(bus);
        return bus;
      }
    }
    return null; // No buses available
  }
  
  void markBusUsed(int bus, Connection connection) {
    _busUsage[bus] ??= BusUsageInfo();
    _busUsage[bus]!.lastWriter = connection.sourceAlgorithmIndex;
    _busUsage[bus]!.readers.add(connection.targetAlgorithmIndex);
  }
}
```

## Force-Directed Layout

### Graph Layout Algorithm

```dart
class ForceDirectedLayout {
  static const double SPRING_LENGTH = 150.0;
  static const double SPRING_STRENGTH = 0.1;
  static const double REPULSION_STRENGTH = 5000.0;
  static const double DAMPING = 0.9;
  static const int MAX_ITERATIONS = 500;
  static const double CONVERGENCE_THRESHOLD = 0.1;
  
  /// Calculate optimal positions for nodes
  static Map<int, Offset> calculateLayout(
    List<int> nodeIds,
    List<Connection> connections,
    {Size? canvasSize}
  ) {
    // Initialize random positions
    final positions = <int, Offset>{};
    final velocities = <int, Offset>{};
    final random = Random();
    
    final size = canvasSize ?? Size(1000, 800);
    
    for (final nodeId in nodeIds) {
      positions[nodeId] = Offset(
        random.nextDouble() * size.width,
        random.nextDouble() * size.height,
      );
      velocities[nodeId] = Offset.zero;
    }
    
    // Build adjacency for connected nodes
    final adjacency = <int, Set<int>>{};
    for (final connection in connections) {
      adjacency[connection.sourceAlgorithmIndex] ??= {};
      adjacency[connection.targetAlgorithmIndex] ??= {};
      adjacency[connection.sourceAlgorithmIndex]!.add(connection.targetAlgorithmIndex);
    }
    
    // Iterate until convergence
    for (int iteration = 0; iteration < MAX_ITERATIONS; iteration++) {
      final forces = <int, Offset>{};
      
      // Initialize forces
      for (final nodeId in nodeIds) {
        forces[nodeId] = Offset.zero;
      }
      
      // Calculate repulsion forces (all pairs)
      for (int i = 0; i < nodeIds.length; i++) {
        for (int j = i + 1; j < nodeIds.length; j++) {
          final node1 = nodeIds[i];
          final node2 = nodeIds[j];
          
          final delta = positions[node2]! - positions[node1]!;
          final distance = delta.distance.clamp(10.0, double.infinity);
          
          final repulsion = delta / distance * (REPULSION_STRENGTH / (distance * distance));
          
          forces[node1] = forces[node1]! - repulsion;
          forces[node2] = forces[node2]! + repulsion;
        }
      }
      
      // Calculate spring forces (connected nodes)
      for (final connection in connections) {
        final source = connection.sourceAlgorithmIndex;
        final target = connection.targetAlgorithmIndex;
        
        final delta = positions[target]! - positions[source]!;
        final distance = delta.distance;
        
        if (distance > 0) {
          final springForce = delta / distance * (distance - SPRING_LENGTH) * SPRING_STRENGTH;
          
          forces[source] = forces[source]! + springForce;
          forces[target] = forces[target]! - springForce;
        }
      }
      
      // Apply directional bias for signal flow (left to right)
      for (final connection in connections) {
        final source = connection.sourceAlgorithmIndex;
        final target = connection.targetAlgorithmIndex;
        
        // Add slight rightward force to targets
        forces[target] = forces[target]! + Offset(10.0, 0);
      }
      
      // Update positions
      double maxDisplacement = 0.0;
      
      for (final nodeId in nodeIds) {
        // Update velocity with damping
        velocities[nodeId] = (velocities[nodeId]! + forces[nodeId]!) * DAMPING;
        
        // Update position
        final newPosition = positions[nodeId]! + velocities[nodeId]!;
        
        // Constrain to canvas
        positions[nodeId] = Offset(
          newPosition.dx.clamp(50, size.width - 50),
          newPosition.dy.clamp(50, size.height - 50),
        );
        
        maxDisplacement = max(maxDisplacement, velocities[nodeId]!.distance);
      }
      
      // Check convergence
      if (maxDisplacement < CONVERGENCE_THRESHOLD) {
        break;
      }
    }
    
    return positions;
  }
  
  /// Hierarchical layout for DAG structures
  static Map<int, Offset> calculateHierarchicalLayout(
    Map<int, List<int>> dependencyGraph,
    {Size? canvasSize}
  ) {
    final positions = <int, Offset>{};
    final size = canvasSize ?? Size(1000, 800);
    
    // Calculate levels using topological sort
    final levels = _assignLevels(dependencyGraph);
    final nodesPerLevel = <int, List<int>>{};
    
    for (final entry in levels.entries) {
      final level = entry.value;
      nodesPerLevel[level] ??= [];
      nodesPerLevel[level]!.add(entry.key);
    }
    
    // Position nodes level by level
    final levelHeight = size.height / (nodesPerLevel.length + 1);
    
    for (final entry in nodesPerLevel.entries) {
      final level = entry.key;
      final nodes = entry.value;
      
      final y = levelHeight * (level + 1);
      final nodeWidth = size.width / (nodes.length + 1);
      
      for (int i = 0; i < nodes.length; i++) {
        final x = nodeWidth * (i + 1);
        positions[nodes[i]] = Offset(x, y);
      }
    }
    
    // Minimize crossings using barycentric method
    _minimizeCrossings(positions, dependencyGraph, nodesPerLevel);
    
    return positions;
  }
  
  static Map<int, int> _assignLevels(Map<int, List<int>> graph) {
    final levels = <int, int>{};
    final visited = <int>{};
    
    void assignLevel(int node, int level) {
      if (visited.contains(node)) return;
      visited.add(node);
      
      levels[node] = max(levels[node] ?? 0, level);
      
      for (final neighbor in graph[node] ?? []) {
        assignLevel(neighbor, level + 1);
      }
    }
    
    // Start from nodes with no incoming edges
    final inDegree = <int, int>{};
    for (final node in graph.keys) {
      inDegree[node] ??= 0;
      for (final neighbors in graph.values) {
        if (neighbors.contains(node)) {
          inDegree[node] = inDegree[node]! + 1;
        }
      }
    }
    
    for (final node in graph.keys) {
      if (inDegree[node] == 0) {
        assignLevel(node, 0);
      }
    }
    
    return levels;
  }
  
  static void _minimizeCrossings(
    Map<int, Offset> positions,
    Map<int, List<int>> graph,
    Map<int, List<int>> nodesPerLevel,
  ) {
    // Barycentric method: position nodes at average x of connected nodes
    for (int iteration = 0; iteration < 10; iteration++) {
      for (final levelNodes in nodesPerLevel.values) {
        final newX = <int, double>{};
        
        for (final node in levelNodes) {
          final connected = [
            ...graph[node] ?? [],
            ...graph.entries
                .where((e) => e.value.contains(node))
                .map((e) => e.key),
          ];
          
          if (connected.isNotEmpty) {
            double sumX = 0;
            int count = 0;
            
            for (final other in connected) {
              if (positions.containsKey(other)) {
                sumX += positions[other]!.dx;
                count++;
              }
            }
            
            if (count > 0) {
              newX[node] = sumX / count;
            }
          }
        }
        
        // Apply new positions
        for (final entry in newX.entries) {
          final current = positions[entry.key]!;
          positions[entry.key] = Offset(entry.value, current.dy);
        }
      }
    }
  }
}
```

## Signal Flow Validation

### Routing Validator

```dart
class RoutingValidator {
  /// Validate complete routing configuration
  static ValidationResult validateRouting(
    List<Connection> connections,
    List<AlgorithmInfo> algorithms,
  ) {
    final errors = <ValidationError>[];
    final warnings = <ValidationWarning>[];
    
    // Check for cycles
    try {
      final graph = DependencyGraphBuilder.buildFromConnections(
        connections,
        algorithms,
      );
      TopologicalSorter.sort(graph);
    } catch (e) {
      if (e is CycleDetectedException) {
        errors.add(ValidationError(
          type: ErrorType.cycle,
          message: 'Circular dependency detected',
          affectedNodes: e.cyclePath,
        ));
      }
    }
    
    // Check bus conflicts
    final busConflicts = _checkBusConflicts(connections);
    errors.addAll(busConflicts);
    
    // Check modulation order
    final modulationErrors = _checkModulationOrder(connections, algorithms);
    errors.addAll(modulationErrors);
    
    // Check feedback configuration
    final feedbackErrors = _checkFeedbackConfiguration(algorithms);
    errors.addAll(feedbackErrors);
    
    // Check for orphaned algorithms
    final orphaned = _findOrphanedAlgorithms(connections, algorithms);
    for (final orphan in orphaned) {
      warnings.add(ValidationWarning(
        type: WarningType.orphaned,
        message: 'Algorithm has no connections',
        nodeIndex: orphan,
      ));
    }
    
    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }
  
  static List<ValidationError> _checkBusConflicts(
    List<Connection> connections,
  ) {
    final errors = <ValidationError>[];
    final busWriters = <int, List<int>>{};
    
    for (final connection in connections) {
      final bus = connection.assignedBus;
      busWriters[bus] ??= [];
      busWriters[bus]!.add(connection.sourceAlgorithmIndex);
    }
    
    // Check for multiple writers to same bus
    for (final entry in busWriters.entries) {
      if (entry.value.length > 1) {
        errors.add(ValidationError(
          type: ErrorType.busConflict,
          message: 'Multiple algorithms writing to bus ${entry.key}',
          affectedNodes: entry.value,
        ));
      }
    }
    
    return errors;
  }
  
  static List<ValidationError> _checkModulationOrder(
    List<Connection> connections,
    List<AlgorithmInfo> algorithms,
  ) {
    final errors = <ValidationError>[];
    
    for (final algo in algorithms) {
      final cvInputs = algo.parameters
          .where((p) => p.type == ParameterType.cvInput);
      
      for (final cvInput in cvInputs) {
        final sourceIndex = cvInput.sourceAlgorithmIndex;
        if (sourceIndex != null && sourceIndex > algo.algorithmIndex) {
          errors.add(ValidationError(
            type: ErrorType.modulationOrder,
            message: 'CV source must be in earlier slot than target',
            affectedNodes: [sourceIndex, algo.algorithmIndex],
          ));
        }
      }
    }
    
    return errors;
  }
  
  static List<int> _findOrphanedAlgorithms(
    List<Connection> connections,
    List<AlgorithmInfo> algorithms,
  ) {
    final connected = <int>{};
    
    for (final connection in connections) {
      connected.add(connection.sourceAlgorithmIndex);
      connected.add(connection.targetAlgorithmIndex);
    }
    
    return algorithms
        .map((a) => a.algorithmIndex)
        .where((index) => !connected.contains(index))
        .toList();
  }
}
```

## Best Practices

1. **Always validate topology** before applying routing changes
2. **Use topological sort** to determine processing order
3. **Minimize bus usage** through intelligent reuse
4. **Provide clear error messages** for validation failures
5. **Cache layout calculations** when possible
6. **Use hierarchical layout** for feed-forward networks
7. **Apply force-directed** for more organic layouts
8. **Implement undo/redo** for routing operations