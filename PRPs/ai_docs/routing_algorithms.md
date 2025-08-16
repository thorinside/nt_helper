# Routing Algorithms for Node-Based Visual Interface

## Core Concept: Hardware-Calculated Routing

**Critical Understanding**: The Disting NT hardware calculates and returns routing information. The app's role is to:
1. Set algorithm parameters (including bus assignments)
2. Request routing info from hardware
3. Visualize the calculated routing
4. Validate proposed connections before applying them

## Algorithm 1: Connection to Bus Assignment

When a user drags a connection from output port to input port:

```dart
class ConnectionToBusAssignment {
  /// Maps a visual connection to bus parameter updates
  static BusAssignment assignBusForConnection({
    required AlgorithmInfo sourceAlgorithm,
    required String sourcePortId,
    required AlgorithmInfo targetAlgorithm,
    required String targetPortId,
    required List<BusAssignment> existingAssignments,
  }) {
    // Step 1: Find which parameters control these ports
    final sourceParam = _findBusParameterForPort(sourceAlgorithm, sourcePortId);
    final targetParam = _findBusParameterForPort(targetAlgorithm, targetPortId);
    
    // Step 2: Check if source already has a bus assigned
    int assignedBus;
    bool replaceMode = true; // Default to replace mode
    final currentSourceBus = sourceAlgorithm.getParameterValue(sourceParam.id);
    
    if (currentSourceBus != null && currentSourceBus != 0) {
      // Source already outputting to a bus - reuse it
      assignedBus = currentSourceBus;
    } else {
      // Need to assign a new bus - prefer aux but any unused bus works
      assignedBus = _findAvailableBus(existingAssignments);
    }
    
    // Step 3: Determine replace vs add mode
    // For feedback algorithms, typically use Add mode for mixing
    if (sourceAlgorithm.type.contains('feedback') || 
        targetAlgorithm.type.contains('feedback')) {
      replaceMode = false; // Use Add mode for unity gain mixing
    }
    
    // Step 4: Create parameter updates
    return BusAssignment(
      connectionId: '${sourceAlgorithm.index}_${sourcePortId}_${targetAlgorithm.index}_${targetPortId}',
      sourceBus: assignedBus,
      replaceMode: replaceMode,
      edgeLabel: _generateEdgeLabel(assignedBus, replaceMode),
      parameterUpdates: [
        ParameterUpdate(
          algorithmIndex: sourceAlgorithm.index,
          parameterId: sourceParam.id,
          value: assignedBus,
        ),
        ParameterUpdate(
          algorithmIndex: targetAlgorithm.index,
          parameterId: targetParam.id,
          value: assignedBus,
        ),
        // If algorithm supports mode parameter, set it
        if (sourceAlgorithm.hasParameter('output_mode'))
          ParameterUpdate(
            algorithmIndex: sourceAlgorithm.index,
            parameterId: 'output_mode',
            value: replaceMode ? 'replace' : 'add',
          ),
      ],
    );
  }
  
  /// Find an available bus (prefer aux 21-28, but any unused bus works)
  static int _findAvailableBus(List<BusAssignment> existingAssignments) {
    final usedBuses = <int>{};
    
    // Collect all buses currently in use
    for (final assignment in existingAssignments) {
      usedBuses.add(assignment.sourceBus);
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
  
  /// Generate edge label like "A1 R" or "O3 A"
  static String _generateEdgeLabel(int bus, bool replaceMode) {
    String busLabel;
    if (bus <= 12) {
      busLabel = 'I${bus}'; // Input bus
    } else if (bus <= 24) {
      busLabel = 'O${bus - 12}'; // Output bus  
    } else {
      busLabel = 'A${bus - 20}'; // Aux bus
    }
    
    final mode = replaceMode ? 'R' : 'A';
    return '$busLabel $mode';
  }
  
  /// Maps port ID to the parameter that controls its bus assignment
  static AlgorithmParameter _findBusParameterForPort(
    AlgorithmInfo algorithm,
    String portId,
  ) {
    // Port definitions reference their bus parameter
    final port = algorithm.ports.firstWhere((p) => p.id == portId);
    
    if (port.busIdRef != null) {
      // Port explicitly references a bus parameter
      return algorithm.parameters.firstWhere((p) => p.id == port.busIdRef);
    }
    
    // Default bus parameter naming conventions
    if (port.isOutput) {
      return algorithm.parameters.firstWhere(
        (p) => p.id == 'output_bus' || p.id == 'out_bus' || p.id.contains('output'),
      );
    } else {
      return algorithm.parameters.firstWhere(
        (p) => p.id == 'input_bus' || p.id == 'in_bus' || p.id.contains('input'),
      );
    }
  }
}
```

## Algorithm 2: Bus Sharing and Optimization

When multiple connections need the same source signal:

```dart
class BusOptimizer {
  /// Optimize bus usage when multiple targets need same source
  static List<BusAssignment> optimizeBusUsage({
    required List<Connection> connections,
    required List<AlgorithmInfo> algorithms,
  }) {
    // Group connections by source
    final connectionsBySource = <String, List<Connection>>{};
    
    for (final conn in connections) {
      final key = '${conn.sourceAlgorithmIndex}_${conn.sourcePortId}';
      connectionsBySource[key] ??= [];
      connectionsBySource[key]!.add(conn);
    }
    
    final optimizedAssignments = <BusAssignment>[];
    
    for (final group in connectionsBySource.entries) {
      final sourceConnections = group.value;
      
      if (sourceConnections.length == 1) {
        // Single connection - standard assignment
        optimizedAssignments.add(_assignSingleConnection(sourceConnections.first));
      } else {
        // Multiple targets from same source - share bus
        final sharedBus = _findAvailableAuxBus(optimizedAssignments);
        
        // Set source to write to shared bus
        final sourceAlgo = algorithms[sourceConnections.first.sourceAlgorithmIndex];
        final sourceParam = _findBusParameterForPort(
          sourceAlgo,
          sourceConnections.first.sourcePortId,
        );
        
        final updates = <ParameterUpdate>[
          ParameterUpdate(
            algorithmIndex: sourceAlgo.index,
            parameterId: sourceParam.id,
            value: sharedBus,
          ),
        ];
        
        // Set all targets to read from shared bus
        for (final conn in sourceConnections) {
          final targetAlgo = algorithms[conn.targetAlgorithmIndex];
          final targetParam = _findBusParameterForPort(
            targetAlgo,
            conn.targetPortId,
          );
          
          updates.add(ParameterUpdate(
            algorithmIndex: targetAlgo.index,
            parameterId: targetParam.id,
            value: sharedBus,
          ));
        }
        
        optimizedAssignments.add(BusAssignment(
          connectionId: group.key,
          sourceBus: sharedBus,
          parameterUpdates: updates,
        ));
      }
    }
    
    return optimizedAssignments;
  }
}
```

## Algorithm 3: Processing Order Validation and Correction

Ensure algorithms are in correct slot order for signal flow:

```dart
class ProcessingOrderManager {
  /// Validate and potentially reorder algorithms for correct signal flow
  static ProcessingOrderResult validateAndCorrectOrder({
    required List<Connection> connections,
    required List<SlotInfo> currentSlots,
  }) {
    // Build dependency graph from connections
    final dependencies = <int, Set<int>>{};
    
    for (final slot in currentSlots) {
      dependencies[slot.algorithmIndex] = {};
    }
    
    for (final conn in connections) {
      // Target depends on source
      dependencies[conn.targetAlgorithmIndex]!.add(conn.sourceAlgorithmIndex);
    }
    
    // Add modulation dependencies
    for (final slot in currentSlots) {
      for (final param in slot.algorithm.parameters) {
        if (param.type == 'cv_input' && param.sourceAlgorithmIndex != null) {
          dependencies[slot.algorithmIndex]!.add(param.sourceAlgorithmIndex);
        }
      }
    }
    
    // Perform topological sort
    try {
      final sortedOrder = _topologicalSort(dependencies);
      
      // Check if reordering needed
      final currentOrder = currentSlots.map((s) => s.algorithmIndex).toList();
      
      if (!_listEquals(sortedOrder, currentOrder)) {
        // Generate slot swaps to achieve correct order
        final swaps = _calculateSwaps(currentOrder, sortedOrder);
        
        return ProcessingOrderResult(
          isValid: false,
          requiredOrder: sortedOrder,
          swapOperations: swaps,
          message: 'Algorithms need reordering for signal flow',
        );
      }
      
      return ProcessingOrderResult(
        isValid: true,
        requiredOrder: currentOrder,
      );
      
    } catch (e) {
      if (e is CycleException) {
        return ProcessingOrderResult(
          isValid: false,
          hasCycle: true,
          cycleNodes: e.cycle,
          message: 'Circular dependency detected',
        );
      }
      rethrow;
    }
  }
  
  /// Kahn's algorithm for topological sorting
  static List<int> _topologicalSort(Map<int, Set<int>> dependencies) {
    // Calculate in-degrees
    final inDegree = <int, int>{};
    for (final node in dependencies.keys) {
      inDegree[node] = 0;
    }
    
    for (final deps in dependencies.values) {
      for (final dep in deps) {
        inDegree[dep] = (inDegree[dep] ?? 0) + 1;
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
      for (final neighbor in dependencies.keys) {
        if (dependencies[neighbor]!.contains(current)) {
          dependencies[neighbor]!.remove(current);
          inDegree[neighbor] = inDegree[neighbor]! - 1;
          
          if (inDegree[neighbor] == 0) {
            queue.add(neighbor);
          }
        }
      }
    }
    
    // Check for cycles
    if (result.length != dependencies.length) {
      throw CycleException(_findCycle(dependencies));
    }
    
    return result;
  }
  
  /// Calculate minimum swaps to reorder slots
  static List<SlotSwap> _calculateSwaps(List<int> current, List<int> target) {
    final swaps = <SlotSwap>[];
    final working = List<int>.from(current);
    
    for (int targetPos = 0; targetPos < target.length; targetPos++) {
      final targetAlgo = target[targetPos];
      final currentPos = working.indexOf(targetAlgo);
      
      if (currentPos != targetPos) {
        // Need to swap
        swaps.add(SlotSwap(
          fromSlot: currentPos,
          toSlot: targetPos,
        ));
        
        // Update working array
        final temp = working[targetPos];
        working[targetPos] = working[currentPos];
        working[currentPos] = temp;
      }
    }
    
    return swaps;
  }
}
```

## Algorithm 4: Feedback Loop Handling

Special handling for feedback send/receive pairs:

```dart
class FeedbackLoopHandler {
  /// Handle feedback loop connections specially
  static FeedbackConfiguration configureFeedbackLoop({
    required AlgorithmInfo feedbackSend,
    required AlgorithmInfo feedbackReceive,
    required int feedbackIdentifier,
    required List<Connection> connections,
  }) {
    // Feedback pairs use identifier parameter instead of bus routing
    // They create "teleport tunnels" through the identifier
    
    // Step 1: Ensure receive is in earlier slot than send
    if (feedbackReceive.slotIndex > feedbackSend.slotIndex) {
      return FeedbackConfiguration(
        isValid: false,
        error: 'Feedback Receive must be in earlier slot than Send',
        requiredSwap: SlotSwap(
          fromSlot: feedbackReceive.slotIndex,
          toSlot: feedbackSend.slotIndex - 1,
        ),
      );
    }
    
    // Step 2: Set matching identifiers
    final parameterUpdates = [
      ParameterUpdate(
        algorithmIndex: feedbackSend.index,
        parameterId: 'identifier',
        value: feedbackIdentifier,
      ),
      ParameterUpdate(
        algorithmIndex: feedbackReceive.index,
        parameterId: 'identifier',
        value: feedbackIdentifier,
      ),
    ];
    
    // Step 3: Configure channel count to match connections
    final channelCount = _determineChannelCount(connections);
    
    parameterUpdates.addAll([
      ParameterUpdate(
        algorithmIndex: feedbackSend.index,
        parameterId: 'channels',
        value: channelCount,
      ),
      ParameterUpdate(
        algorithmIndex: feedbackReceive.index,
        parameterId: 'channels',
        value: channelCount,
      ),
    ]);
    
    // Step 4: Set safety gain (default -40dB to prevent runaway)
    parameterUpdates.add(
      ParameterUpdate(
        algorithmIndex: feedbackReceive.index,
        parameterId: 'gain',
        value: -40, // dB
      ),
    );
    
    return FeedbackConfiguration(
      isValid: true,
      identifier: feedbackIdentifier,
      parameterUpdates: parameterUpdates,
    );
  }
  
  /// Find unused feedback identifier
  static int findAvailableFeedbackId(List<AlgorithmInfo> algorithms) {
    final usedIds = <int>{};
    
    for (final algo in algorithms) {
      if (algo.type == 'fbrx') {
        final id = algo.getParameterValue('identifier');
        if (id != null) {
          usedIds.add(id);
        }
      }
    }
    
    // Find first available ID (1-32)
    for (int id = 1; id <= 32; id++) {
      if (!usedIds.contains(id)) {
        return id;
      }
    }
    
    throw Exception('All feedback identifiers in use');
  }
}
```

## Algorithm 5: Connection Validation

Validate proposed connections before applying:

```dart
class ConnectionValidator {
  /// Comprehensive validation of a proposed connection
  static ValidationResult validateConnection({
    required Connection proposedConnection,
    required List<Connection> existingConnections,
    required List<AlgorithmInfo> algorithms,
  }) {
    final errors = <String>[];
    final warnings = <String>[];
    
    // Check 1: Port compatibility
    final sourcePort = _getPort(
      algorithms[proposedConnection.sourceAlgorithmIndex],
      proposedConnection.sourcePortId,
    );
    final targetPort = _getPort(
      algorithms[proposedConnection.targetAlgorithmIndex],
      proposedConnection.targetPortId,
    );
    
    if (!_arePortsCompatible(sourcePort, targetPort)) {
      errors.add('Incompatible port types: ${sourcePort.type} to ${targetPort.type}');
    }
    
    // Check 2: Would create cycle?
    if (_wouldCreateCycle(proposedConnection, existingConnections)) {
      errors.add('Connection would create circular dependency');
    }
    
    // Check 3: Modulation order constraint
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
    
    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }
  
  static bool _arePortsCompatible(AlgorithmPort source, AlgorithmPort target) {
    // Audio outputs can connect to audio inputs
    // CV outputs can connect to CV inputs or modulation inputs
    // Gate outputs can connect to gate/trigger inputs
    
    if (source.type == 'audio' && target.type == 'audio') return true;
    if (source.type == 'cv' && (target.type == 'cv' || target.type == 'modulation')) return true;
    if (source.type == 'gate' && (target.type == 'gate' || target.type == 'trigger')) return true;
    
    return false;
  }
  
  static bool _wouldCreateCycle(
    Connection proposedConnection,
    List<Connection> existingConnections,
  ) {
    // Build adjacency list including proposed connection
    final graph = <int, Set<int>>{};
    
    for (final conn in [...existingConnections, proposedConnection]) {
      graph[conn.sourceAlgorithmIndex] ??= {};
      graph[conn.targetAlgorithmIndex] ??= {};
      graph[conn.sourceAlgorithmIndex]!.add(conn.targetAlgorithmIndex);
    }
    
    // DFS to detect cycle
    final visited = <int>{};
    final recursionStack = <int>{};
    
    bool hasCycle(int node) {
      visited.add(node);
      recursionStack.add(node);
      
      for (final neighbor in graph[node] ?? {}) {
        if (!visited.contains(neighbor)) {
          if (hasCycle(neighbor)) return true;
        } else if (recursionStack.contains(neighbor)) {
          return true; // Found cycle
        }
      }
      
      recursionStack.remove(node);
      return false;
    }
    
    for (final node in graph.keys) {
      if (!visited.contains(node)) {
        if (hasCycle(node)) return true;
      }
    }
    
    return false;
  }
}
```

## Algorithm 6: Visual Connection Management

Convert between visual connections and bus parameters:

```dart
class VisualConnectionManager {
  /// Build visual connections from current routing state
  static List<Connection> buildConnectionsFromRouting({
    required List<SlotInfo> slots,
    required List<RoutingInformation> routingInfo,
  }) {
    final connections = <Connection>[];
    
    // Analyze which buses each algorithm reads/writes
    final busWriters = <int, int>{}; // bus -> algorithm index
    final busReaders = <int, List<int>>{}; // bus -> list of algorithm indices
    
    for (final routing in routingInfo) {
      final algo = slots[routing.algorithmIndex].algorithm;
      
      // Decode routing masks
      final inputMask = routing.routingInfo[0];  // r0
      final outputMask = routing.routingInfo[1]; // r1
      
      // Find which buses this algorithm writes to
      for (int bus = 1; bus <= 28; bus++) {
        if ((outputMask & (1 << bus)) != 0) {
          busWriters[bus] = routing.algorithmIndex;
        }
      }
      
      // Find which buses this algorithm reads from
      for (int bus = 1; bus <= 28; bus++) {
        if ((inputMask & (1 << bus)) != 0) {
          busReaders[bus] ??= [];
          busReaders[bus]!.add(routing.algorithmIndex);
        }
      }
    }
    
    // Create connections for aux buses only (21-28)
    // Physical I/O buses (1-24) are shown differently
    for (int bus = 21; bus <= 28; bus++) {
      if (busWriters.containsKey(bus) && busReaders.containsKey(bus)) {
        final sourceIndex = busWriters[bus]!;
        final sourceAlgo = slots[sourceIndex].algorithm;
        
        for (final targetIndex in busReaders[bus]!) {
          final targetAlgo = slots[targetIndex].algorithm;
          
          // Determine which ports are using this bus
          final sourcePort = _findPortUsingBus(sourceAlgo, bus, isOutput: true);
          final targetPort = _findPortUsingBus(targetAlgo, bus, isOutput: false);
          
          if (sourcePort != null && targetPort != null) {
            connections.add(Connection(
              id: 'bus_${bus}_${sourceIndex}_${targetIndex}',
              sourceAlgorithmIndex: sourceIndex,
              sourcePortId: sourcePort.id,
              targetAlgorithmIndex: targetIndex,
              targetPortId: targetPort.id,
              assignedBus: bus,
              isValid: true,
            ));
          }
        }
      }
    }
    
    // Handle feedback pairs separately (they don't use buses)
    _addFeedbackConnections(connections, slots);
    
    return connections;
  }
  
  static void _addFeedbackConnections(
    List<Connection> connections,
    List<SlotInfo> slots,
  ) {
    // Find feedback send/receive pairs by identifier
    final feedbackSends = <int, AlgorithmInfo>{};
    final feedbackReceives = <int, AlgorithmInfo>{};
    
    for (final slot in slots) {
      if (slot.algorithm.type == 'fbrx') {
        final id = slot.algorithm.getParameterValue('identifier');
        if (id != null) {
          if (slot.algorithm.name.contains('Send')) {
            feedbackSends[id] = slot.algorithm;
          } else {
            feedbackReceives[id] = slot.algorithm;
          }
        }
      }
    }
    
    // Create visual connections for matched pairs
    for (final entry in feedbackSends.entries) {
      final id = entry.key;
      final send = entry.value;
      
      if (feedbackReceives.containsKey(id)) {
        final receive = feedbackReceives[id]!;
        
        // Visual connection from receive output to send input
        connections.add(Connection(
          id: 'feedback_${id}',
          sourceAlgorithmIndex: receive.index,
          sourcePortId: 'feedback_out',
          targetAlgorithmIndex: send.index,
          targetPortId: 'feedback_in',
          assignedBus: 0, // Feedback doesn't use buses
          isValid: true,
          isFeedback: true,
        ));
      }
    }
  }
}
```

## Algorithm 7: Automatic Algorithm Reordering

When connections require reordering:

```dart
class AutomaticReorderer {
  /// Automatically reorder algorithms to satisfy all connections
  static ReorderingPlan planReordering({
    required List<Connection> connections,
    required List<SlotInfo> currentSlots,
  }) {
    // Build optimal order using topological sort
    final dependencies = _buildDependencies(connections, currentSlots);
    final optimalOrder = _topologicalSort(dependencies);
    
    // Generate minimal swap sequence
    final swaps = <SlotSwap>[];
    final workingOrder = currentSlots.map((s) => s.algorithmIndex).toList();
    
    // Use selection sort approach for minimal swaps
    for (int targetPos = 0; targetPos < optimalOrder.length; targetPos++) {
      final targetAlgo = optimalOrder[targetPos];
      final currentPos = workingOrder.indexOf(targetAlgo);
      
      if (currentPos != targetPos && currentPos != -1) {
        // Swap needed
        swaps.add(SlotSwap(
          fromSlot: currentPos,
          toSlot: targetPos,
          algorithmIndex: targetAlgo,
        ));
        
        // Update working order
        workingOrder.removeAt(currentPos);
        workingOrder.insert(targetPos, targetAlgo);
      }
    }
    
    return ReorderingPlan(
      originalOrder: currentSlots.map((s) => s.algorithmIndex).toList(),
      targetOrder: optimalOrder,
      swapSequence: swaps,
      affectedConnections: _identifyAffectedConnections(swaps, connections),
    );
  }
  
  /// Apply reordering plan to hardware
  static Future<void> applyReordering({
    required ReorderingPlan plan,
    required DistingCubit cubit,
  }) async {
    // Apply swaps one by one
    for (final swap in plan.swapSequence) {
      await cubit.swapSlots(swap.fromSlot, swap.toSlot);
      
      // Small delay to let hardware process
      await Future.delayed(Duration(milliseconds: 50));
    }
    
    // Refresh routing after reordering
    await cubit.refreshRouting();
  }
}
```

## Key Implementation Notes

1. **Hardware is Source of Truth**: Always request routing info from hardware after parameter changes
2. **Bus Priority**: Prefer Aux (21-28), then Output (13-24), then Input (1-12) buses
3. **Any Bus Works**: Any bus can be used as long as processing order is correct
4. **Edge Labels**: Show bus and mode - "A1 R" (Aux 1 Replace), "O3 A" (Output 3 Add)
5. **Feedback Uses Add Mode**: Feedback algorithms typically use Add mode for unity gain mixing
6. **Validation Before Application**: Always validate connections before sending to hardware
7. **Atomic Operations**: Group related parameter updates and send together
8. **Processing Order Matters**: Source must process before target (except feedback pairs)

## Data Structures

```dart
class BusAssignment {
  final String connectionId;
  final int sourceBus;
  final bool replaceMode;
  final String edgeLabel;  // e.g., "A1 R", "O3 A", "I2 R"
  final List<ParameterUpdate> parameterUpdates;
}

class ParameterUpdate {
  final int algorithmIndex;
  final String parameterId;
  final dynamic value;
}

class ProcessingOrderResult {
  final bool isValid;
  final List<int> requiredOrder;
  final List<SlotSwap> swapOperations;
  final bool hasCycle;
  final List<int>? cycleNodes;
  final String? message;
}

class Connection {
  final String id;
  final int sourceAlgorithmIndex;
  final String sourcePortId;
  final int targetAlgorithmIndex;
  final String targetPortId;
  final int assignedBus;
  final bool isValid;
  final bool isFeedback;
}
```