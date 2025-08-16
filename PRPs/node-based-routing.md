name: "Node-Based Visual Routing Interface for Disting NT"
description: |
  Implementation of an interactive node-based routing visualization with drag-and-drop connections,
  automatic bus assignment, and signal flow validation for the Disting NT preset editor.

---

## Goal

**Feature Goal**: Create an alternative visual routing interface that displays algorithms as draggable nodes with connection ports, allowing users to intuitively connect algorithm outputs to inputs through direct manipulation.

**Deliverable**: A new routing view mode in the Flutter app featuring interactive node-based visualization with automatic bus assignment and signal flow validation.

**Success Definition**: Users can visually create and modify algorithm connections by dragging from output to input ports, with the system automatically handling bus assignments and ensuring valid signal processing order.

## User Persona

**Target User**: Modular synthesizer users familiar with patching cables between modules

**Use Case**: Creating complex algorithm routing without understanding the underlying bus system

**User Journey**: 
1. User switches to node view on routing page
2. Sees algorithms as visual blocks with labeled input/output ports
3. Drags connection from algorithm output to another's input
4. System automatically assigns buses and validates signal flow
5. Visual feedback shows signal paths and any routing conflicts

**Pain Points Addressed**:
- Current table view requires understanding of bus numbering system
- Difficult to visualize signal flow paths
- Manual bus assignment is error-prone
- No intuitive way to see algorithm dependencies

## Why

- Provides intuitive visual patching familiar to modular synth users
- Hides complexity of bus system while maintaining full routing power
- Enables rapid experimentation with signal routing
- Visual representation makes complex presets easier to understand
- Automatic validation prevents invalid routing configurations

## What

### Core Functionality
- Node-based visualization of algorithms with connection ports
- Drag-and-drop connection creation between nodes
- Edge labels showing bus assignment (e.g., "A1 R" for Aux 1 Replace, "O3 A" for Output 3 Add)
- Automatic bus parameter assignment (hardware calculates actual routing)
- Real-time signal flow validation
- Visual feedback for valid/invalid connections
- Automatic algorithm reordering to satisfy dependencies
- Bidirectional sync: visualize hardware routing and update parameters

### Success Criteria

- [ ] Toggle between table and node view on routing page
- [ ] Drag connections from output to input ports
- [ ] Automatic bus parameter updates sent to hardware
- [ ] Hardware routing info correctly visualized
- [ ] Visual indication of signal flow direction
- [ ] Validation prevents circular dependencies
- [ ] Persistence of routing changes to hardware via MIDI
- [ ] Performance with 32 algorithms remains smooth

## All Needed Context

### Context Completeness Check

_This PRP contains all file references, patterns, and external documentation needed for implementation without prior knowledge of the codebase._

### Documentation & References

```yaml
# MUST READ - Include these in your context window
- file: lib/ui/routing_page.dart
  why: Current routing page implementation to extend with view toggle
  pattern: StatefulWidget with real-time refresh, Cubit integration
  gotcha: 10-second refresh timer must be maintained in node view

- file: lib/ui/routing/routing_table_widget.dart
  why: Current table visualization to understand data flow
  pattern: Complex table layout with signal level visualization
  gotcha: Fixed 32x32 cell dimensions, golden/blue color coding

- file: lib/util/routing_analyzer.dart
  why: Core routing analysis logic for signal propagation
  pattern: Forward signal building, usage tracking, JSON generation
  gotcha: Complex bit masking operations, must preserve analysis logic

- file: lib/models/routing_information.dart
  why: Routing data model structure
  pattern: Simple model with algorithmIndex, routingInfo array, name
  gotcha: routingInfo is 6 packed 32-bit values with specific meanings

- file: lib/models/algorithm_port.dart
  why: Port definitions for algorithm connections
  pattern: Freezed model with bus references and channel info
  gotcha: busIdRef points to parameter that holds actual bus number

- file: lib/ui/widgets/draggable_resizable_overlay.dart
  why: Existing drag implementation patterns
  pattern: Pan gesture handling, position constraints, state persistence
  gotcha: Must constrain to screen bounds, save positions to settings

- file: lib/cubit/disting_cubit.dart
  why: State management for routing updates
  pattern: Cubit pattern with slots list, routing refresh methods
  gotcha: Optimistic updates followed by hardware verification

- file: lib/domain/sysex/requests/request_routing_information.dart
  why: MIDI communication for routing data
  pattern: SysEx message encoding with algorithm index
  gotcha: Must maintain proper SysEx formatting

- file: assets/mcp_docs/bus_mapping.md
  why: Bus numbering system documentation
  critical: Input N = Bus N, Output N = Bus N+12, Aux N = Bus N+20

- file: assets/mcp_docs/routing_concepts.md
  why: Signal flow rules and constraints
  critical: Algorithms process in slot order, modulation sources before targets

- docfile: PRPs/ai_docs/flutter_node_editor.md
  why: Flutter CustomPainter patterns for node-based editors
  section: Canvas drawing, hit testing, connection routing

- docfile: PRPs/ai_docs/graph_algorithms.md
  why: Topological sorting and auto-layout algorithms
  section: DAG validation, force-directed layout, bus assignment

- docfile: PRPs/ai_docs/routing_algorithms.md
  why: Complete routing algorithm implementations
  critical: Hardware calculates routing - app sets parameters and visualizes
  section: All algorithms for connection management and validation

- docfile: PRPs/ai_docs/node_routing_implementation_details.md
  why: Comprehensive implementation details filling all gaps
  critical: Complete algorithms for port extraction, layout, drag handling, persistence
  section: All sections - this fills every gap in the main PRP
```

### Current Codebase tree

```bash
lib/
├── ui/
│   ├── routing_page.dart                    # Main routing page
│   ├── routing/
│   │   └── routing_table_widget.dart        # Table view widget
│   └── widgets/
│       ├── draggable_resizable_overlay.dart # Drag patterns
│       └── base_drawer.dart                 # Navigation drawer
├── models/
│   ├── routing_information.dart             # Routing data model
│   ├── algorithm_port.dart                  # Port definitions
│   └── algorithm_parameter.dart             # Parameter definitions
├── util/
│   └── routing_analyzer.dart                # Routing analysis
├── cubit/
│   └── disting_cubit.dart                   # State management
└── domain/
    └── sysex/                                # MIDI communication
```

### Desired Codebase tree with files to be added

```bash
lib/
├── ui/
│   ├── routing_page.dart                    # Modified: Add view toggle
│   ├── routing/
│   │   ├── routing_table_widget.dart        # Existing table view
│   │   ├── node_routing_widget.dart         # NEW: Node-based view
│   │   ├── algorithm_node_widget.dart       # NEW: Individual node
│   │   ├── connection_painter.dart          # NEW: Connection lines
│   │   └── routing_canvas.dart              # NEW: Main canvas
│   └── widgets/
│       └── port_widget.dart                 # NEW: Connection ports
├── models/
│   ├── node_position.dart                   # NEW: Node positions
│   ├── connection.dart                      # NEW: Connection model
│   └── routing_graph.dart                   # NEW: Graph structure
├── services/
│   ├── auto_routing_service.dart            # NEW: Bus assignment
│   └── graph_layout_service.dart            # NEW: Node layout
└── util/
    ├── routing_validator.dart               # NEW: Signal validation
    └── topological_sort.dart                # NEW: Ordering algorithm
```

### Known Gotchas of our codebase & Library Quirks

```dart
// CRITICAL: Routing info is calculated by hardware, not the app
// App sets algorithm bus parameters, hardware calculates routing masks
// Must request routing info from hardware after parameter changes

// CRITICAL: Bus usage - any bus can be used for connections
// Bus 0 = None, 1-12 = Inputs, 13-24 = Outputs, 21-28 = Aux
// Prefer Aux buses for internal connections but any bus works
// Edge labels show bus + mode: "A1 R" = Aux 1 Replace, "I2 A" = Input 2 Add

// CRITICAL: Algorithm processing order constraint
// Modulation sources MUST be in earlier slots than targets
// Feedback receive MUST be before feedback send for loops

// CRITICAL: Routing info array structure (6 x 32-bit values)
// r0 = input mask, r1 = output mask, r2 = replace mask
// These are READ from hardware, not calculated by app

// GOTCHA: Flutter analyze must have zero errors
// Use debugPrint() not print() for all debug output

// GOTCHA: Parameter updates need MIDI sync
// After updating bus parameters, must refresh routing from hardware
```

## Implementation Blueprint

### CRITICAL: Implementation Flow

**The complete implementation requires understanding this flow:**

1. **Port Extraction**: Use `PortExtractor` from implementation_details.md to get available ports from algorithms
2. **Initial Layout**: Use `NodeLayoutEngine` to position nodes without overlaps
3. **Routing Interpretation**: Use `RoutingMaskInterpreter` to convert hardware masks to visual connections
4. **Drag Handling**: Use `ConnectionDragHandler` for interactive connection creation
5. **Bus Assignment**: Hardware sets routing based on our parameter updates
6. **Validation**: Check cycles and constraints BEFORE sending to hardware
7. **Persistence**: Save node positions per preset using extended SettingsService

**Key Understanding**: We don't calculate routing masks - we set bus parameters and the hardware calculates the masks. We then read these masks to visualize the routing.

### Data models and structure

```dart
// lib/models/node_position.dart
@freezed
class NodePosition with _$NodePosition {
  const factory NodePosition({
    required int algorithmIndex,
    required double x,
    required double y,
    @Default(200.0) double width,
    @Default(100.0) double height,
  }) = _NodePosition;
}

// lib/models/connection.dart
@freezed
class Connection with _$Connection {
  const factory Connection({
    required String id,
    required int sourceAlgorithmIndex,
    required String sourcePortId,
    required int targetAlgorithmIndex,
    required String targetPortId,
    required int assignedBus,  // Bus number (1-28)
    required bool replaceMode,  // true = Replace, false = Add
    @Default(false) bool isValid,
    String? edgeLabel,  // e.g., "A1 R", "O3 A", "I2 R"
  }) = _Connection;
  
  // Helper to generate edge label
  String getEdgeLabel() {
    final busType = assignedBus <= 12 ? 'I' : 
                   assignedBus <= 24 ? 'O' : 'A';
    final busNum = assignedBus <= 12 ? assignedBus :
                   assignedBus <= 24 ? assignedBus - 12 :
                   assignedBus - 20;
    final mode = replaceMode ? 'R' : 'A';
    return '$busType$busNum $mode';
  }
}

// lib/models/routing_graph.dart
class RoutingGraph {
  final List<NodePosition> nodePositions;
  final List<Connection> connections;
  final Map<int, List<AlgorithmPort>> algorithmPorts;
  
  bool validateTopology();  // Check for cycles
  List<int> getProcessingOrder();  // Topological sort
  int assignBus(Connection connection);  // Auto bus assignment
}
```

### Implementation Tasks (ordered by dependencies)

```yaml
Task 1: CREATE lib/models/node_position.dart, connection.dart, routing_graph.dart
  - IMPLEMENT: Freezed models for node positions and connections
  - FOLLOW pattern: lib/models/algorithm_port.dart (freezed structure)
  - NAMING: Use freezed naming conventions with factory constructors
  - PLACEMENT: Models directory with other data structures

Task 2: CREATE lib/util/topological_sort.dart
  - IMPLEMENT: Kahn's algorithm for DAG topological sorting
  - FOLLOW pattern: lib/util/routing_analyzer.dart (utility structure)
  - NAMING: topologicalSort() returns ordered algorithm indices
  - VALIDATION: detectCycles() returns bool and cycle path if found
  - PLACEMENT: Util directory with other analysis tools

Task 3: CREATE lib/services/auto_routing_service.dart
  - IMPLEMENT: AutoRoutingService class with bus parameter assignment
  - FOLLOW pattern: lib/services/disting_controller_impl.dart (service pattern)
  - NAMING: assignBusForConnection(), updateBusParameters(), findAvailableAuxBus()
  - ALGORITHM: See PRPs/ai_docs/routing_algorithms.md Algorithm 1 & 2
  - CRITICAL: Sets parameters only, hardware calculates actual routing
  - PLACEMENT: Services directory with other business logic

Task 4: CREATE lib/ui/routing/algorithm_node_widget.dart
  - IMPLEMENT: StatefulWidget for draggable algorithm node
  - FOLLOW pattern: lib/ui/widgets/draggable_resizable_overlay.dart (drag handling)
  - NAMING: AlgorithmNodeWidget with ports list display
  - FEATURES: Pan gestures, visual ports, selection state
  - PLACEMENT: In routing subdirectory with other routing widgets

Task 5: CREATE lib/ui/routing/connection_painter.dart
  - IMPLEMENT: CustomPainter for drawing bezier connections
  - FOLLOW pattern: Research Flutter CustomPainter tutorials
  - NAMING: ConnectionPainter extends CustomPainter
  - FEATURES: Bezier curves, arrow heads, highlight on hover
  - PLACEMENT: Routing subdirectory for painting logic

Task 6: CREATE lib/ui/routing/routing_canvas.dart
  - IMPLEMENT: InteractiveViewer with CustomPaint for main canvas
  - FOLLOW pattern: Flutter InteractiveViewer for pan/zoom
  - NAMING: RoutingCanvas widget containing nodes and connections
  - FEATURES: Pan/zoom, grid background, connection dragging
  - PLACEMENT: Main canvas in routing subdirectory

Task 7: CREATE lib/ui/routing/node_routing_widget.dart
  - IMPLEMENT: Main widget coordinating node view
  - FOLLOW pattern: lib/ui/routing/routing_table_widget.dart (structure)
  - NAMING: NodeRoutingWidget as StatefulWidget
  - INTEGRATION: Use DistingCubit for state, RoutingAnalyzer for validation
  - PLACEMENT: Parallel to routing_table_widget.dart

Task 8: MODIFY lib/ui/routing_page.dart
  - INTEGRATE: Add toggle button for table/node view
  - FIND pattern: Current RoutingTableWidget usage
  - ADD: ViewMode enum, conditional rendering based on mode
  - PRESERVE: Real-time refresh timer, cubit integration

Task 9: CREATE lib/services/graph_layout_service.dart
  - IMPLEMENT: Force-directed layout algorithm for initial positions
  - ALGORITHM: Spring forces between connected nodes
  - NAMING: layoutGraph(), applyForces(), calculateRepulsion()
  - OUTPUT: Optimized NodePosition list
  - PLACEMENT: Services for layout calculations

Task 10: CREATE lib/util/routing_validator.dart
  - IMPLEMENT: Connection validation before applying to hardware
  - ALGORITHM: See PRPs/ai_docs/routing_algorithms.md Algorithm 5
  - NAMING: validateConnection(), checkProcessingOrder(), detectCycles()
  - INTEGRATION: Validate BEFORE sending parameter updates to hardware
  - PLACEMENT: Util directory with validation logic

Task 11: MODIFY lib/cubit/disting_cubit.dart
  - ADD: Node view state management methods
  - IMPLEMENT: updateNodePosition(), addConnection(), removeConnection()
  - INTEGRATE: Call auto-routing service for parameter updates
  - CRITICAL: After parameter updates, call refreshRouting() to get hardware state
  - PRESERVE: Existing routing refresh and update logic

Task 12: CREATE tests for all new components
  - IMPLEMENT: Unit tests for topological sort, auto-routing, validation
  - FOLLOW pattern: test/ directory structure
  - COVERAGE: Edge cases - cycles, max connections, invalid buses
  - PLACEMENT: Matching test/ structure for each new file
```

### Implementation Patterns & Key Details

```dart
// Node dragging pattern (from draggable_resizable_overlay.dart)
class AlgorithmNodeWidget extends StatefulWidget {
  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      position = position.copyWith(
        x: position.x + details.delta.dx,
        y: position.y + details.delta.dy,
      );
      widget.onPositionChanged?.call(position);
    });
  }
}

// Connection drawing pattern with edge labels
class ConnectionPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = connection.isValid ? Colors.green : Colors.red
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    
    final path = Path();
    // Bezier curve from source to target
    path.moveTo(sourcePoint.dx, sourcePoint.dy);
    final cp1 = Offset(sourcePoint.dx + 50, sourcePoint.dy);
    final cp2 = Offset(targetPoint.dx - 50, targetPoint.dy);
    path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, targetPoint.dx, targetPoint.dy);
    canvas.drawPath(path, paint);
    
    // Draw edge label at midpoint
    final midPoint = _calculateBezierPoint(sourcePoint, cp1, cp2, targetPoint, 0.5);
    final textPainter = TextPainter(
      text: TextSpan(
        text: connection.getEdgeLabel(), // e.g., "A1 R"
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
          backgroundColor: Colors.black54,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, midPoint - Offset(textPainter.width / 2, textPainter.height / 2));
  }
  
  Offset _calculateBezierPoint(Offset p0, Offset p1, Offset p2, Offset p3, double t) {
    final u = 1 - t;
    return p0 * (u * u * u) + p1 * (3 * u * u * t) + p2 * (3 * u * t * t) + p3 * (t * t * t);
  }
}

// Bus parameter assignment pattern (from routing_algorithms.md)
class AutoRoutingService {
  Future<void> assignBusForConnection(Connection connection) async {
    // Find available aux bus (21-28)
    final bus = findAvailableAuxBus();
    
    // Update source algorithm's output bus parameter
    await cubit.updateAlgorithmParameter(
      connection.sourceAlgorithmIndex,
      'output_bus', // or specific port's bus parameter
      bus,
    );
    
    // Update target algorithm's input bus parameter  
    await cubit.updateAlgorithmParameter(
      connection.targetAlgorithmIndex,
      'input_bus', // or specific port's bus parameter
      bus,
    );
    
    // Request routing info from hardware to get calculated masks
    await cubit.refreshRouting();
  }
}

// Topological sort for processing order
List<int> topologicalSort(Map<int, List<int>> adjacencyList) {
  final inDegree = <int, int>{};
  final queue = Queue<int>();
  final result = <int>[];
  
  // Calculate in-degrees
  for (final node in adjacencyList.keys) {
    inDegree[node] ??= 0;
    for (final neighbor in adjacencyList[node]!) {
      inDegree[neighbor] = (inDegree[neighbor] ?? 0) + 1;
    }
  }
  
  // Add nodes with no dependencies
  inDegree.forEach((node, degree) {
    if (degree == 0) queue.add(node);
  });
  
  // Process queue
  while (queue.isNotEmpty) {
    final node = queue.removeFirst();
    result.add(node);
    
    for (final neighbor in adjacencyList[node] ?? []) {
      inDegree[neighbor] = inDegree[neighbor]! - 1;
      if (inDegree[neighbor] == 0) {
        queue.add(neighbor);
      }
    }
  }
  
  if (result.length != adjacencyList.length) {
    throw Exception('Cycle detected in routing graph');
  }
  
  return result;
}
```

### Integration Points

```yaml
STATE_MANAGEMENT:
  - modify: lib/cubit/disting_cubit.dart
  - add: NodeViewState with positions and connections
  - pattern: "copyWith pattern for state updates"

SETTINGS:
  - add to: lib/services/settings_service.dart
  - store: "node positions, view mode preference"
  - pattern: "existing overlay position storage"

MIDI_SYNC:
  - integrate: lib/domain/sysex/requests/set_algorithm_parameter.dart
  - update: "bus parameters when connections change"
  - pattern: "existing parameter update flow"
```

## Validation Loop

### Level 1: Syntax & Style (Immediate Feedback)

```bash
# After each file creation
flutter analyze lib/ui/routing/
flutter analyze lib/models/
flutter analyze lib/services/
flutter analyze lib/util/

# Expected: Zero errors and warnings
```

### Level 2: Unit Tests (Component Validation)

```bash
# Test topological sort
flutter test test/util/topological_sort_test.dart

# Test auto-routing service
flutter test test/services/auto_routing_service_test.dart

# Test routing validation
flutter test test/util/routing_validator_test.dart

# Run all tests
flutter test
```

### Level 3: Integration Testing (System Validation)

```bash
# Build and run the app
flutter run

# Manual testing checklist:
# 1. Switch to node view on routing page
# 2. Drag algorithm nodes to new positions
# 3. Create connection by dragging from output to input
# 4. Verify bus assignment in debug output
# 5. Switch to table view - verify routing persisted
# 6. Test with complex preset (20+ algorithms)
# 7. Test cycle detection (create circular connection)
# 8. Test feedback loop creation
```

### Level 4: Performance & Edge Cases

```bash
# Performance profiling
flutter run --profile

# Test with maximum complexity:
# - 32 algorithms fully connected
# - Rapid node dragging
# - Multiple simultaneous connections

# Edge cases to verify:
# - All aux buses exhausted
# - Circular dependency rejection
# - Feedback loop validation
# - Algorithm reordering after connection
```

## Final Validation Checklist

### Technical Validation

- [ ] All validation levels completed successfully
- [ ] flutter analyze shows zero issues
- [ ] All unit tests pass
- [ ] Integration with existing routing system verified
- [ ] Performance acceptable with 32 algorithms

### Feature Validation

- [ ] Toggle between table and node view works
- [ ] Nodes are draggable with position persistence
- [ ] Connections can be created via drag-and-drop
- [ ] Auto bus assignment works correctly
- [ ] Invalid connections are prevented
- [ ] Changes persist to hardware via MIDI
- [ ] Visual feedback clear and intuitive

### Code Quality Validation

- [ ] Follows existing Cubit state management pattern
- [ ] Uses debugPrint() not print()
- [ ] Freezed models properly implemented
- [ ] File placement matches codebase structure
- [ ] No hardcoded values - uses settings/config

### Documentation & Deployment

- [ ] Code is self-documenting with clear naming
- [ ] Complex algorithms have explanatory comments
- [ ] Settings properly integrated for persistence

---

## Anti-Patterns to Avoid

- ❌ Don't expose raw bus numbers to users - use abstraction
- ❌ Don't allow circular dependencies - validate graph
- ❌ Don't skip flutter analyze - must be zero warnings
- ❌ Don't use print() - always use debugPrint()
- ❌ Don't hardcode dimensions - make responsive
- ❌ Don't ignore existing patterns - follow codebase conventions
- ❌ Don't create redundant state - integrate with DistingCubit