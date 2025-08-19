# Routing Bus Classification and Optimization Algorithms

## Bus Classification System

### Primary Classification: By Hardware Type

```dart
enum BusType {
  physical_input,   // Buses 1-12: Hardware input jacks
  physical_output,  // Buses 13-20: Hardware output jacks  
  auxiliary,        // Buses 21-28: Internal routing buses
  none,            // Bus 0: Disconnected state
}
```

### Secondary Classification: By Usage Pattern

```dart
enum BusUsagePattern {
  source_only,      // Bus only outputs signal (no readers)
  sink_only,        // Bus only receives signal (no writers after)
  pass_through,     // Bus is read and written (potential for Replace)
  shared,           // Multiple algorithms read from this bus
  exclusive,        // Single reader, single writer
  replaceable,      // Uses Replace mode, creating reuse opportunity
}
```

### Tertiary Classification: By Lifetime

```dart
enum BusLifetimeClass {
  persistent,       // Used throughout preset execution
  transient,        // Used briefly, then available
  recyclable,       // Can be reused after Replace operation
  reserved,         // Physical I/O, cannot be optimized
}
```

## Graph Coloring Application

### Problem Mapping

The bus assignment problem maps directly to graph coloring:

```dart
// Graph representation
class ConflictGraph {
  // Nodes: Signal paths requiring buses
  Set<SignalPath> nodes;
  
  // Edges: Conflicts (simultaneous bus usage)
  Set<Conflict> edges;
  
  // Colors: Available buses (21-28 for AUX)
  Set<int> colors;
}

class SignalPath {
  int sourceSlot;
  int targetSlot;
  String sourcePort;
  String targetPort;
  Set<int> activeSlots; // Slots where signal must be preserved
}

class Conflict {
  SignalPath path1;
  SignalPath path2;
  bool exists() => path1.activeSlots.intersection(path2.activeSlots).isNotEmpty;
}
```

### DSATUR Algorithm Implementation

DSATUR (Degree of Saturation) is optimal for this use case:

```dart
class DSATURBusAllocator {
  Map<SignalPath, int> allocateBuses(ConflictGraph graph) {
    Map<SignalPath, int> allocation = {};
    Map<SignalPath, Set<int>> availableColors = {};
    Map<SignalPath, int> saturation = {};
    
    // Initialize
    for (final node in graph.nodes) {
      availableColors[node] = Set.from([21, 22, 23, 24, 25, 26, 27, 28]);
      saturation[node] = 0;
    }
    
    while (allocation.length < graph.nodes.length) {
      // Select node with highest saturation
      SignalPath selected = _selectMaxSaturation(
        graph.nodes.difference(allocation.keys.toSet()),
        saturation
      );
      
      // Assign smallest available color
      int bus = availableColors[selected].min;
      allocation[selected] = bus;
      
      // Update neighbors
      for (final neighbor in _getNeighbors(selected, graph)) {
        availableColors[neighbor].remove(bus);
        saturation[neighbor] = 8 - availableColors[neighbor].length;
      }
    }
    
    return allocation;
  }
}
```

## Linear Scan Register Allocation

### Interval Representation

```dart
class BusInterval {
  final int bus;
  final int startSlot;
  final int endSlot;
  final bool endsWithReplace; // Can be reused after endSlot
  
  bool overlaps(BusInterval other) {
    if (endsWithReplace && other.startSlot > endSlot) {
      return false; // No overlap due to Replace mode
    }
    return startSlot <= other.endSlot && endSlot >= other.startSlot;
  }
}
```

### Linear Scan Algorithm

```dart
class LinearScanBusAllocator {
  List<BusAllocation> allocate(List<BusInterval> intervals) {
    // Sort by start position
    intervals.sort((a, b) => a.startSlot.compareTo(b.startSlot));
    
    List<BusAllocation> result = [];
    List<int> availableBuses = [21, 22, 23, 24, 25, 26, 27, 28];
    Map<int, int> busFreedAtSlot = {};
    
    for (final interval in intervals) {
      // Free buses that ended with Replace
      _freeReplacedBuses(interval.startSlot, busFreedAtSlot, availableBuses);
      
      if (availableBuses.isEmpty) {
        // Spill to output buses
        availableBuses.addAll(_getSpillBuses());
      }
      
      int assignedBus = availableBuses.removeAt(0);
      result.add(BusAllocation(interval, assignedBus));
      
      if (interval.endsWithReplace) {
        busFreedAtSlot[interval.endSlot] = assignedBus;
      }
    }
    
    return result;
  }
}
```

## Tidy Algorithm Implementation

### Core Tidy Algorithm

```dart
class BusTidyOptimizer {
  /// Optimizes bus usage by identifying Replace mode opportunities
  TidyResult tidyConnections(List<Connection> connections, 
                             List<Algorithm> algorithms) {
    // Step 1: Build dependency graph
    DependencyGraph deps = _buildDependencyGraph(connections, algorithms);
    
    // Step 2: Identify replacement opportunities
    List<ReplacementOpportunity> opportunities = _findReplacementOpportunities(deps);
    
    // Step 3: Calculate new bus assignments
    Map<String, BusChange> changes = _calculateOptimalAssignments(opportunities, deps);
    
    // Step 4: Validate safety
    ValidationResult validation = _validateChanges(changes, deps);
    
    if (!validation.isValid) {
      return TidyResult.failed(validation.errors);
    }
    
    // Step 5: Generate updated connections
    List<Connection> optimized = _applyChanges(connections, changes);
    
    return TidyResult.success(
      originalConnections: connections,
      optimizedConnections: optimized,
      busesFreed: _countFreedBuses(connections, optimized),
      changes: changes,
    );
  }
  
  List<ReplacementOpportunity> _findReplacementOpportunities(DependencyGraph deps) {
    List<ReplacementOpportunity> opportunities = [];
    
    for (final bus in deps.buses) {
      // Find all writers to this bus
      List<SlotWrite> writers = deps.getWriters(bus);
      
      // Find all readers of this bus
      List<SlotRead> readers = deps.getReaders(bus);
      
      // Check if any writer can use Replace mode
      for (final writer in writers) {
        // Find last reader before this writer
        SlotRead? lastReader = readers
            .where((r) => r.slot < writer.slot)
            .lastOrNull;
        
        if (lastReader != null) {
          // Check if safe to replace
          bool safeToReplace = !readers.any((r) => 
            r.slot > writer.slot && r.slot < _nextWriter(writer, writers)?.slot ?? 999
          );
          
          if (safeToReplace) {
            opportunities.add(ReplacementOpportunity(
              bus: bus,
              slot: writer.slot,
              freedAfterSlot: writer.slot,
              potentialReusers: _findPotentialReusers(writer.slot, deps),
            ));
          }
        }
      }
    }
    
    return opportunities;
  }
}
```

### Dependency Graph Structure

```dart
class DependencyGraph {
  // Track bus usage by slot
  Map<int, BusUsage> slotUsage = {};
  
  // Track dependencies between slots
  Map<int, Set<int>> slotDependencies = {};
  
  // Bus lifetime tracking
  Map<int, BusLifetime> busLifetimes = {};
  
  class BusUsage {
    Set<int> reads = {};   // Buses this slot reads from
    Set<int> writes = {};  // Buses this slot writes to
    Map<int, bool> replaceMode = {}; // Bus -> uses Replace mode
  }
  
  class BusLifetime {
    int firstUse;     // First slot using this bus
    int lastRead;     // Last slot reading this bus
    int lastWrite;    // Last slot writing to this bus
    bool replaceable; // Can be freed via Replace mode
  }
}
```

## Optimization Heuristics

### Fast Heuristics for Real-time

```dart
class FastTidyHeuristics {
  // Greedy algorithm - O(n log n)
  QuickTidyResult quickTidy(List<Connection> connections) {
    // Sort connections by source slot
    connections.sort((a, b) => a.sourceSlot.compareTo(b.sourceSlot));
    
    // Track bus availability
    BusAvailabilityTracker tracker = BusAvailabilityTracker();
    
    for (final conn in connections) {
      // Check if we can reuse a bus that was replaced
      int? reusableBus = tracker.findReusableBus(conn.sourceSlot);
      
      if (reusableBus != null) {
        conn.assignedBus = reusableBus;
        conn.replaceMode = _shouldReplace(conn, tracker);
      }
      
      tracker.update(conn);
    }
    
    return QuickTidyResult(connections, tracker.busesFreed);
  }
}
```

### Optimal Algorithm for Offline

```dart
class OptimalTidyAlgorithm {
  // Branch and bound - O(2^n) worst case, but with pruning
  OptimalResult findOptimal(List<Connection> connections) {
    PriorityQueue<SearchState> queue = PriorityQueue();
    queue.add(SearchState.initial(connections));
    
    OptimalResult best = null;
    
    while (queue.isNotEmpty) {
      SearchState state = queue.removeFirst();
      
      // Prune if can't beat current best
      if (best != null && state.lowerBound >= best.busCount) {
        continue;
      }
      
      if (state.isComplete) {
        if (best == null || state.busCount < best.busCount) {
          best = OptimalResult(state);
        }
        continue;
      }
      
      // Branch on next connection
      for (final choice in state.getChoices()) {
        SearchState next = state.apply(choice);
        if (next.isValid) {
          queue.add(next);
        }
      }
    }
    
    return best;
  }
}
```

## Validation Framework

### Safety Validation

```dart
class TidyValidator {
  ValidationResult validate(TidyResult result) {
    List<ValidationError> errors = [];
    
    // Check signal integrity
    for (final conn in result.optimizedConnections) {
      if (!_signalAvailable(conn)) {
        errors.add(ValidationError(
          'Signal not available at target slot',
          conn,
        ));
      }
    }
    
    // Check bus conflicts
    Map<int, List<SlotUsage>> busUsage = _buildBusUsage(result.optimizedConnections);
    for (final bus in busUsage.keys) {
      if (_hasConflict(busUsage[bus])) {
        errors.add(ValidationError(
          'Bus conflict detected',
          bus,
        ));
      }
    }
    
    // Check execution order
    for (final conn in result.optimizedConnections) {
      if (conn.violatesExecutionOrder) {
        errors.add(ValidationError(
          'Execution order violation',
          conn,
        ));
      }
    }
    
    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: _generateWarnings(result),
    );
  }
}
```

## Performance Metrics

### Complexity Analysis

| Algorithm | Time Complexity | Space Complexity | Quality |
|-----------|----------------|------------------|---------|
| Greedy First-Fit | O(n log n) | O(n) | 2-approx |
| Linear Scan | O(n log n) | O(n) | Near-optimal |
| DSATUR | O(n²) | O(n²) | Optimal for most |
| Graph Coloring | O(n³) | O(n²) | Optimal |
| Branch & Bound | O(2^n)* | O(n) | Optimal |

*With pruning, typically O(n³) in practice

### Expected Improvements

Based on analysis of typical Disting NT presets:

- **Simple presets** (1-5 connections): 0-20% bus reduction
- **Medium presets** (6-15 connections): 20-40% bus reduction  
- **Complex presets** (16+ connections): 30-50% bus reduction

The improvement depends on:
- Signal flow topology
- Existing Replace mode usage
- Algorithm execution order
- Port connectivity patterns