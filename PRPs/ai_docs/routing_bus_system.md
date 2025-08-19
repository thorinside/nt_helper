# Disting NT Routing Bus System Documentation

## Overview

The Disting NT hardware provides 28 buses for signal routing between algorithms and physical I/O. This document provides comprehensive information about the bus system architecture, signal flow mechanics, and optimization strategies.

## Bus Architecture

### Bus Ranges and Types

```
Buses 1-12:  Physical Input jacks (I1-I12)
             - Hardware-mapped to physical input jacks
             - Bidirectional (can be sources or targets)
             - Cannot be dynamically assigned
             
Buses 13-20: Physical Output jacks (O1-O8)
             - Hardware-mapped to physical output jacks (Note: 8 outputs, not 12)
             - Bidirectional (can be sources or targets)
             - Cannot be dynamically assigned
             
Buses 21-28: Auxiliary buses (A1-A8) 
             - Internal routing only
             - Dynamically assignable
             - Preferred for algorithm-to-algorithm connections
             
Bus 0:       None/disconnected state
             - Special value indicating no connection
```

### Bus Assignment Priority

```dart
// From auto_routing_service.dart
Priority Order:
1. AUX buses (21-28) - Preferred for internal routing
2. Output buses (13-20) - Fallback when AUX exhausted
3. Input buses (1-12) - Last resort
```

## Signal Flow Mechanics

### Algorithm Execution Order

Algorithms process in strict slot order:
- Slot 0 executes first
- Slot 1 executes second
- ... and so on

This creates critical timing constraints for bus sharing.

### Connection Modes

Each bus connection can operate in one of two modes:

#### Add Mode (value = 0)
- Signals are mixed/summed on the bus
- Multiple sources can contribute without interference
- Default mode for most connections

#### Replace Mode (value = 1)
- Completely overwrites any existing signal on the bus
- Effectively "takes over" the bus
- Creates opportunity for bus reuse

### Signal Level Tracking

The routing analyzer tracks signal levels to understand bus usage:

```dart
// Signal levels from routing_analyzer.dart:
// 0 = No signal
// 1 = Signal present
// 2 = Signal replaced once
// Cycles back to 1 if replaced again
```

## Bus Reuse Through Replace Mode

### The Optimization Opportunity

When an algorithm uses Replace mode, it creates a "bus reset point" where that bus becomes available for reuse by algorithms in later slots.

### Example Scenario

```
Slot 0: VCO outputs to Bus 21 (Add mode)
        Bus 21 now contains: VCO signal

Slot 1: Filter reads Bus 21, outputs to Bus 21 (Replace mode)  
        Bus 21 now contains: Filter signal (VCO signal replaced)

Slot 2: Envelope can now safely use Bus 21 for new signal
        Bus 21 is effectively "free" after Slot 1's Replace
```

### Safety Constraints

For safe bus reuse with Replace mode:

1. **Readers Before Writers Rule**: Any algorithm that needs to read the original signal must come BEFORE the algorithm that replaces it

2. **Dependency Analysis**: Must track which slots read from each bus to determine safe replacement points

3. **Execution Order Validation**: Source slot must be less than target slot for valid connections

## Routing State Representation

### Hardware Parameters

Each algorithm slot has routing parameters:

```dart
// Parameter indices for routing (from routing constants)
const int outputParameterIndex = 0;
const int inputParameterIndex = 1;
const int replaceModeParameterIndex = 2;
```

### Routing Information Structure

```dart
class RoutingInformation {
  final List<int> routingInfo; // 6-element array
  // [0] = inputMask - which buses this algorithm reads from
  // [1] = outputMask - which buses this algorithm outputs to  
  // [2] = replaceMask - which output buses use Replace mode
  // [3] = unused
  // [4] = unused
  // [5] = mappingMask - CV mapping buses
}
```

### Bitmask Encoding

Bus assignments are encoded as bitmasks:
- Bit position corresponds to bus number
- Bit set = bus is used
- Example: `0x00200000` = Bus 21 is used (bit 21 is set)

## Physical I/O Node Handling

### Special Node Types

```dart
// From node routing constants
const int physicalInputNodeIndex = -2;   // Maps to buses 1-12
const int physicalOutputNodeIndex = -3;  // Maps to buses 13-20
```

### Physical Connection Rules

1. Physical nodes use fixed bus assignments (no parameters)
2. Exempt from execution order constraints
3. Support bidirectional connections (monitoring, feedback)
4. Cannot use AUX buses

## Bus Assignment Algorithm

### Current Implementation

```dart
// Simplified from auto_routing_service.dart
int findAvailableAuxBus(List<Connection> existingConnections) {
  Set<int> usedBuses = _collectUsedBuses(existingConnections);
  
  // Try AUX buses first (21-28)
  for (int bus = 21; bus <= 28; bus++) {
    if (!usedBuses.contains(bus)) return bus;
  }
  
  // Try output buses (13-20)
  for (int bus = 13; bus <= 20; bus++) {
    if (!usedBuses.contains(bus)) return bus;
  }
  
  // Try input buses (1-12) as last resort
  for (int bus = 1; bus <= 12; bus++) {
    if (!usedBuses.contains(bus)) return bus;
  }
  
  throw InsufficientBusesException();
}
```

## Optimization Strategies

### Bus Reuse Algorithm

Key steps for optimizing bus usage:

1. **Build Dependency Graph**: Track which slots read/write each bus
2. **Identify Replace Points**: Find where buses become available
3. **Validate Safety**: Ensure no dependencies are broken
4. **Assign Optimally**: Prefer reused buses over new allocations

### Data Structures for Optimization

```dart
class BusLifetime {
  final int bus;
  final int startSlot;  // When bus first used
  final int endSlot;    // When bus last read (before replacement)
  final bool canReuse;  // True if replaced and safe to reuse
}

class BusOptimizer {
  Map<int, Set<int>> busReaders;   // bus -> slots that read
  Map<int, Set<int>> busWriters;   // bus -> slots that write
  Map<int, bool> busReplaceMode;   // bus -> uses replace mode
}
```

## Validation and Constraints

### Connection Validation

Before creating a connection, validate:
1. Source and target exist
2. Ports are compatible
3. No cycles created
4. Execution order respected
5. Buses available

### Bus Limit Constraints

- Maximum 8 AUX buses available
- Physical I/O buses cannot be reallocated
- Each connection needs exactly one bus

## Implementation Considerations

### Performance

- Bus assignment: O(n) where n = number of buses
- Optimization with graph coloring: O(n²) to O(n³)
- Linear scan optimization: O(n log n)

### Memory

- Routing state: ~200 bytes per algorithm slot
- Connection tracking: ~50 bytes per connection
- Dependency graph: O(slots × buses) space

### Real-time Constraints

- Bus assignment must complete in <100ms for UI responsiveness
- Hardware sync may take additional time
- Optimization should be asynchronous/cancellable

## Testing Considerations

### Unit Tests

- Test each bus type assignment
- Validate Replace mode behavior
- Verify execution order constraints
- Test bus exhaustion scenarios

### Integration Tests

- Test hardware parameter sync
- Validate visual representation matches hardware
- Test undo/redo with optimization
- Verify persistence/loading

### Edge Cases

- All buses exhausted
- Circular dependencies
- Physical I/O edge cases
- Empty presets
- Maximum slot count (32 algorithms)