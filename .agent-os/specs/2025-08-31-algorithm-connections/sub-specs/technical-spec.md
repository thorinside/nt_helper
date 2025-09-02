# Technical Implementation Specification

## Architecture Overview

### Design Principles

1. **Separation of Concerns**: Connection discovery logic separate from UI rendering
2. **Immutability**: All connection data structures are immutable (using freezed)
3. **Reactive Updates**: Connections automatically update via stream subscriptions
4. **Performance First**: Caching and optimization built-in from the start
5. **Testability**: All components designed for easy unit testing

### Data Flow

```
Slot Parameters Change
        ↓
DistingCubit (synchronized state)
        ↓
RoutingEditorCubit (listens to stream)
        ↓
AlgorithmConnectionService (discovery)
        ↓
AlgorithmConnection models (immutable)
        ↓
RoutingEditorState (updated with `algorithmConnections`)
        ↓
RoutingEditorWidget + ConnectionCanvas (renders connections)
```

### Data Model Extensions

#### AlgorithmConnection Model

**File**: @lib/models/algorithm_connection.dart

```dart
@freezed
sealed class AlgorithmConnection with _$AlgorithmConnection {
  const factory AlgorithmConnection({
    required String id,
    required int sourceAlgorithmIndex,
    required String sourcePortId,
    required int targetAlgorithmIndex, 
    required String targetPortId,
    required int busNumber,
    required bool isValid,
    required DateTime createdAt,
  }) = _AlgorithmConnection;
  
  factory AlgorithmConnection.fromJson(Map<String, dynamic> json) =>
      _$AlgorithmConnectionFromJson(json);
}

extension AlgorithmConnectionHelpers on AlgorithmConnection {
  bool get violatesExecutionOrder => sourceAlgorithmIndex >= targetAlgorithmIndex;
  
  String get busTypeLabel {
    if (busNumber >= 1 && busNumber <= 12) return 'Input';
    if (busNumber >= 13 && busNumber <= 20) return 'Output';
    if (busNumber >= 21 && busNumber <= 28) return 'Aux';
    return 'Unknown';
  }
  
  static String generateId(int sourceAlgIndex, String sourcePortId, 
                          int targetAlgIndex, String targetPortId, int busNumber) {
    return 'algo_conn_${sourceAlgIndex}_${sourcePortId}_${targetAlgIndex}_${targetPortId}_bus_$busNumber';
  }
}
```

#### Enhanced RoutingEditorState

**File**: @lib/cubit/routing_editor_state.dart

```dart
@freezed 
sealed class RoutingEditorState with _$RoutingEditorState {
  const factory RoutingEditorState.loaded({
    required List<Port> physicalInputs,
    required List<Port> physicalOutputs,
    required List<RoutingAlgorithm> algorithms,
    required List<Connection> connections,
    required List<PhysicalConnection> physicalConnections,
    required List<AlgorithmConnection> algorithmConnections, // NEW
    required List<RoutingBus> buses,
    required Map<String, OutputMode> portOutputModes,
    required bool isHardwareSynced,
    required bool isPersistenceEnabled,
    required DateTime? lastSyncTime,
    required DateTime? lastPersistTime,
    String? lastError,
  }) = RoutingEditorStateLoaded;
}
```

### Service Layer

#### AlgorithmConnectionService

**File**: @lib/core/routing/services/algorithm_connection_service.dart

```dart
class AlgorithmConnectionService {
  final RoutingFactory _routingFactory;
  int? _lastHash;
  List<AlgorithmConnection>? _lastConnections;

  AlgorithmConnectionService(this._routingFactory);

  /// Discover all algorithm-to-algorithm connections from current slot configuration
  List<AlgorithmConnection> discoverAlgorithmConnections(List<Slot> slots) {
    final currentHash = _generateSlotHash(slots);
    if (_lastHash == currentHash && _lastConnections != null) {
      return _lastConnections!;
    }

    final connections = <AlgorithmConnection>[];
    final outputPorts = <_PortWithBus>[];
    final inputPorts = <_PortWithBus>[];

    // Phase 1: Collect all algorithm ports with bus assignments
    _collectAlgorithmPorts(slots, outputPorts, inputPorts);

    // Phase 2: Create connections for matching bus numbers (1–28)
    connections.addAll(_createBusConnections(outputPorts, inputPorts));

    // Phase 3: Sort for deterministic presentation
    connections.sort(_compareConnections);

    _lastHash = currentHash;
    _lastConnections = connections;
    return connections;
  }
  
  void _collectAlgorithmPorts(List<Slot> slots, 
                               List<_PortWithBus> outputPorts,
                               List<_PortWithBus> inputPorts) {
    for (int i = 0; i < slots.length; i++) {
      final slot = slots[i];
      // Use the routing factory directly from metadata inferred per-slot
      final metadata = AlgorithmRoutingMetadataFactory.fromSlot(slot);
      final routing = _routingFactory.createRouting(metadata);
      
      // Collect outputs with bus assignments
      for (final port in routing.outputPorts) {
        final busNumber = _getBusNumberForPort(port, slot);
        if (busNumber != null && busNumber > 0 && busNumber <= 28) {
          outputPorts.add(_PortWithBus(i, port, busNumber));
        }
      }
      
      // Collect inputs with bus assignments
      for (final port in routing.inputPorts) {
        final busNumber = _getBusNumberForPort(port, slot);
        if (busNumber != null && busNumber > 0 && busNumber <= 28) {
          inputPorts.add(_PortWithBus(i, port, busNumber));
        }
      }
    }
  }
  
  List<AlgorithmConnection> _createBusConnections(
      List<_PortWithBus> outputs, List<_PortWithBus> inputs) {
    final connections = <AlgorithmConnection>[];
    
    // Use a map for efficient lookups
    final inputsByBus = <int, List<_PortWithBus>>{};
    for (final input in inputs) {
      inputsByBus.putIfAbsent(input.busNumber, () => []).add(input);
    }
    
    for (final output in outputs) {
      final matchingInputs = inputsByBus[output.busNumber] ?? [];
      for (final input in matchingInputs) {
        // Skip self-connections
        if (output.algorithmIndex == input.algorithmIndex) continue;
        
        connections.add(AlgorithmConnection(
          id: AlgorithmConnectionHelpers.generateId(
            output.algorithmIndex, output.port.id,
            input.algorithmIndex, input.port.id,
            output.busNumber,
          ),
          sourceAlgorithmIndex: output.algorithmIndex,
          sourcePortId: output.port.id,
          targetAlgorithmIndex: input.algorithmIndex,
          targetPortId: input.port.id,
          busNumber: output.busNumber,
          isValid: output.algorithmIndex < input.algorithmIndex,
          createdAt: DateTime.now(),
        ));
      }
    }
    
    return connections;
  }
}
```

### Integration Points

#### RoutingEditorCubit Enhancement

**File**: @lib/cubit/routing_editor_cubit.dart

Update `_processSynchronizedState` to compute `algorithmConnections` via the new service and include it in `RoutingEditorState.loaded`. Ensure `_hasLoadedStateChanged` compares `algorithmConnections` so the UI refreshes appropriately.

## Bus Resolution Strategy

### Port Bus Assignment Resolution

Introduce a shared utility to prevent coupling to private cubit methods.

**File**: @lib/core/routing/utils/bus_resolution.dart

- Resolve bus from `port.metadata['busParam']` against slot parameters
- Fallbacks for poly gate/CV metadata (e.g., `isGateInput`, `gateBus`, `suggestedBus`)
- Return 1–28 for internal connections; return null for 0 (None) or out of range

## UI Rendering

### Connection Visualization

Use the existing `RoutingEditorWidget` and `ConnectionCanvas` to render algorithm connections as an additional layer:

- Add a non-interactive `ConnectionCanvas` for `algorithmConnections` above physical connections and below user-created connections
- Invalid connections use the theme’s error style (red, dashed)
- Valid connections inherit color from the source output port type color (no per-port hue changes)
- Labels show at midpoints as "Bus #"

## Performance Considerations

### Connection Caching

Service maintains a simple last-hash + last-result cache (no recursion into itself). Compute a stable hash from slot algorithms and their bus-related parameter values.

### Rendering Optimizations

Rendering is already efficient for the 32-algorithm limit; advanced optimizations are optional.

## Error Handling

### Connection Discovery Errors

```dart
List<AlgorithmConnection> discoverAlgorithmConnections(List<Slot> slots) {
  try {
    // Discovery logic...
    return connections;
  } catch (e) {
    debugPrint('Error discovering algorithm connections: $e');
    // Return empty list rather than crashing
    return <AlgorithmConnection>[];
  }
}
```

### UI Rendering Fallbacks

```dart
void _paintAlgorithmConnection(Canvas canvas, AlgorithmConnection connection) {
  try {
    // Rendering logic...
  } catch (e) {
    debugPrint('Error rendering connection ${connection.id}: $e');
    // Skip this connection and continue with others
  }
}
```

## Testing Strategy

### Unit Tests

1. **AlgorithmConnection model**: Validation logic, ID generation
2. **AlgorithmConnectionService**: Connection discovery with various slot configurations
3. **Bus resolution**: Parameter lookup and fallback behaviors
4. **Sorting**: Deterministic connection ordering

### Integration Tests

1. **End-to-End**: Full workflow from slot change to UI update
2. **State Management**: Cubit state transitions with algorithm connections
3. **Performance**: Typical routing configuration handling (optional)

### Visual Tests

1. **Screenshot Comparisons**: Various connection scenarios
2. **Animation Testing**: Connection updates during parameter changes
3. **Accessibility**: Color contrast and visual hierarchy
