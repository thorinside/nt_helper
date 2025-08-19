name: "Physical Input/Output Nodes for Routing Canvas"
description: |
  Add physical hardware input/output nodes to the routing canvas to represent the 12 physical inputs (I1-I12) and 8 physical outputs (O1-O8) on the Disting NT hardware. These nodes allow bidirectional drag-and-drop connections between physical I/O and algorithms.

---

## Goal

**Feature Goal**: Enable visual routing between physical hardware I/O and algorithms through dedicated input/output nodes on the routing canvas

**Deliverable**: Two new node types (PhysicalInputNode and PhysicalOutputNode) that integrate seamlessly with the existing algorithm node routing system

**Success Definition**: Users can drag connections from physical input jacks to algorithm inputs, from algorithm outputs to physical output jacks, and bidirectionally route signals through the hardware's bus system

## User Persona (if applicable)

**Target User**: Eurorack modular synthesizer users working with Disting NT hardware

**Use Case**: Setting up complex signal routing between external modules and internal algorithms

**User Journey**: 
1. User opens routing canvas view
2. Sees physical input node (I1-I12) on left side, output node (O1-O8) on right side
3. Drags from physical input jack to algorithm input port
4. Drags from algorithm output port to physical output jack
5. Creates complex routing chains mixing hardware and algorithms

**Pain Points Addressed**: 
- No visual representation of hardware I/O in current canvas
- Unclear how physical inputs/outputs connect to algorithms
- Difficulty understanding signal flow from/to hardware

## Why

- Provides complete visual representation of signal routing including hardware I/O
- Enables intuitive drag-and-drop routing between hardware and algorithms
- Clarifies the bidirectional nature of bus routing (outputs can feed inputs)
- Completes the routing canvas metaphor with hardware representation

## What

Physical I/O nodes appear as vertical bars with labeled jack sockets that support bidirectional connections:
- Input node: 12 jacks (I1-I12) that can receive external signals or algorithm outputs
- Output node: 8 jacks (O1-O8) that can send signals externally or receive algorithm outputs
- Both nodes support drag operations in both directions
- Visual feedback during connection creation
- Automatic bus assignment for physical I/O connections

### Success Criteria

- [ ] Physical input node displays 12 labeled jacks (I1-I12)
- [ ] Physical output node displays 8 labeled jacks (O1-O8)
- [ ] Connections can be dragged from physical outputs (as sources) to algorithm inputs
- [ ] Algorithm outputs can be dragged to physical inputs (as destinations)
- [ ] Visual feedback shows valid/invalid connections during drag
- [ ] Connections properly map to hardware bus system
- [ ] Nodes integrate with existing layout and positioning system

## All Needed Context

### Context Completeness Check

_Before writing this PRP, validate: "If someone knew nothing about this codebase, would they have everything needed to implement this successfully?"_

### Documentation & References

```yaml
# MUST READ - Include these in your context window
- file: /Users/nealsanche/nosuch/nt_helper/lib/ui/routing/algorithm_node_widget.dart
  why: Base pattern for node widget implementation including port layout and drag handling
  pattern: Widget structure with header and ports area, gesture detection, visual states
  gotcha: Ports are positioned absolutely using RenderBox calculations

- file: /Users/nealsanche/nosuch/nt_helper/lib/ui/widgets/port_widget.dart
  why: Port rendering and drag initiation patterns, visual feedback states
  pattern: Circular port with inner indicator, color coding by type, drag threshold handling
  gotcha: Only output ports can initiate connections, 10px drag threshold before starting

- file: /Users/nealsanche/nosuch/nt_helper/lib/cubit/node_routing_cubit.dart
  why: Central routing state management, connection validation, bus assignment
  pattern: Connection creation flow, port position calculation, hit testing methods
  gotcha: Uses negative algorithmIndex for special nodes (-1 for outputs already used)

- file: /Users/nealsanche/nosuch/nt_helper/lib/ui/routing/routing_canvas.dart
  why: Canvas integration point, gesture handling, node rendering orchestration
  pattern: Layered rendering (grid→nodes→connections), coordinate conversion, pan handling
  gotcha: Must convert global to canvas-local coordinates for hit testing

- file: /Users/nealsanche/nosuch/nt_helper/lib/services/auto_routing_service.dart
  why: Bus assignment logic for connections, understanding bus ranges
  pattern: Bus priority (aux→output→input), reuse existing buses, external output handling
  gotcha: Physical I/O uses fixed bus assignments (1-12 inputs, 13-20 outputs)

- file: /Users/nealsanche/nosuch/nt_helper/lib/models/connection.dart
  why: Connection data model that needs extension for physical I/O
  pattern: Source/target algorithm indices and port IDs, bus assignment
  gotcha: Currently assumes non-negative algorithm indices

- file: /Users/nealsanche/nosuch/nt_helper/lib/models/port_layout.dart
  why: Port grouping model for input/output ports
  pattern: Simple container with port lists, used for layout calculations
  gotcha: Port IDs must be unique within a node

- url: https://pub.dev/packages/fl_nodes
  why: Reference for specialized node types in Flutter node editors
  critical: Shows pattern for extending base node types with custom rendering

- docfile: PRPs/ai_docs/routing_bus_system.md
  why: Detailed bus system documentation for physical I/O mapping
  section: Bus ranges and hardware mapping
```

### Current Codebase tree (run `tree` in the root of the project) to get an overview of the codebase

```bash
lib/
├── cubit/
│   ├── node_routing_cubit.dart        # Main routing state management
│   └── node_routing_state.dart        # Freezed state classes
├── models/
│   ├── algorithm_port.dart            # Port definition model
│   ├── connection.dart                # Connection model
│   ├── node_position.dart             # Node positioning
│   └── port_layout.dart               # Port grouping
├── services/
│   ├── auto_routing_service.dart      # Bus assignment logic
│   └── graph_layout_service.dart      # Layout algorithms
├── ui/
│   ├── routing/
│   │   ├── algorithm_node_widget.dart # Algorithm node implementation
│   │   ├── connection_painter.dart    # Connection rendering
│   │   ├── node_routing_widget.dart   # BLoC wrapper
│   │   └── routing_canvas.dart        # Main canvas widget
│   └── widgets/
│       └── port_widget.dart           # Port rendering widget
```

### Desired Codebase tree with files to be added and responsibility of file

```bash
lib/
├── ui/
│   └── routing/
│       ├── physical_input_node_widget.dart  # NEW: Input node (I1-I12) visual representation
│       ├── physical_output_node_widget.dart # NEW: Output node (O1-O8) visual representation
│       └── routing_canvas.dart              # MODIFIED: Add physical nodes to canvas
├── cubit/
│   └── node_routing_cubit.dart              # MODIFIED: Handle physical node connections
├── services/
│   └── auto_routing_service.dart            # MODIFIED: Physical I/O bus assignment
```

### Known Gotchas of our codebase & Library Quirks

```dart
// CRITICAL: Algorithm indices use special negative values for non-algorithm nodes
// -1 is already used for external outputs in some contexts
// Use -2 for physical inputs, -3 for physical outputs to avoid conflicts

// CRITICAL: Bus assignment for physical I/O is fixed:
// Inputs I1-I12 → Buses 1-12 (no assignment needed, hardware-fixed)
// Outputs O1-O8 → Buses 13-20 (no assignment needed, hardware-fixed)

// CRITICAL: Port IDs must be globally unique for hit testing
// Use format: "physical_input_1" through "physical_input_12"
// Use format: "physical_output_1" through "physical_output_8"

// CRITICAL: Canvas uses absolute positioning, nodes need fixed positions
// Physical input node: x=50 (left edge with margin)
// Physical output node: x=4900 (near right edge, canvas is 5000px)

// CRITICAL: Drag threshold is 10px before connection starts (from PortWidget)
// Dead zone around ports is 30px radius (from ConnectionPainter)
```

## Implementation Blueprint

### Data models and structure

Create the core data models for physical nodes, extending existing patterns.

```dart
// Extension to node_position.dart concept
class PhysicalNodePosition {
  final double x;
  final double y; 
  final double height; // Dynamic based on jack count
  final bool isInput; // true for input node, false for output
}

// Port layout for physical nodes
class PhysicalPortLayout {
  final List<AlgorithmPort> jacks; // I1-I12 or O1-O8
  
  // Constructor creates appropriate jacks
  PhysicalPortLayout.inputs() : jacks = List.generate(
    12, (i) => AlgorithmPort(
      id: 'physical_input_${i+1}',
      name: 'I${i+1}',
    )
  );
  
  PhysicalPortLayout.outputs() : jacks = List.generate(
    8, (i) => AlgorithmPort(
      id: 'physical_output_${i+1}', 
      name: 'O${i+1}',
    )
  );
}
```

### Implementation Tasks (ordered by dependencies)

```yaml
Task 1: CREATE lib/ui/routing/physical_input_node_widget.dart
  - IMPLEMENT: StatelessWidget for physical input node with 12 jacks
  - FOLLOW pattern: lib/ui/routing/algorithm_node_widget.dart (structure, layout constants)
  - NAMING: PhysicalInputNodeWidget class, jacks labeled I1-I12
  - VISUAL: Vertical bar design, 20px width, height = 36px header + (12 * 22px) ports
  - PLACEMENT: Fixed at x=50 on canvas
  - PORT IDs: "physical_input_1" through "physical_input_12"

Task 2: CREATE lib/ui/routing/physical_output_node_widget.dart
  - IMPLEMENT: StatelessWidget for physical output node with 8 jacks
  - FOLLOW pattern: lib/ui/routing/algorithm_node_widget.dart (structure, layout constants)
  - NAMING: PhysicalOutputNodeWidget class, jacks labeled O1-O8
  - VISUAL: Vertical bar design, 20px width, height = 36px header + (8 * 22px) ports
  - PLACEMENT: Fixed at x=4900 on canvas
  - PORT IDs: "physical_output_1" through "physical_output_8"

Task 3: MODIFY lib/cubit/node_routing_cubit.dart
  - ADD: Physical node position tracking (algorithmIndex -2 for inputs, -3 for outputs)
  - EXTEND: getAlgorithmAtPosition() to check physical node bounds
  - EXTEND: getPortAtPosition() to handle physical node port lookup
  - MODIFY: _isValidConnectionTarget() to allow physical I/O connections
  - ADD: _calculatePhysicalPortPositions() method for jack positions
  - DEPENDENCIES: Import new physical node widgets from Tasks 1-2

Task 4: MODIFY lib/ui/routing/routing_canvas.dart
  - ADD: PhysicalInputNodeWidget to canvas at fixed position
  - ADD: PhysicalOutputNodeWidget to canvas at fixed position
  - INTEGRATE: Include physical nodes in Stack widget layering
  - HANDLE: Gesture detection for physical node ports
  - DEPENDENCIES: Import physical node widgets from Tasks 1-2

Task 5: MODIFY lib/services/auto_routing_service.dart
  - ADD: Special case for physical input connections (use buses 1-12)
  - ADD: Special case for physical output connections (use buses 13-20)
  - MODIFY: assignBusForConnection() to detect physical I/O by negative indices
  - SKIP: Parameter updates for physical I/O (hardware-fixed buses)
  - PRESERVE: Existing algorithm-to-algorithm routing logic

Task 6: MODIFY lib/models/connection.dart
  - EXTEND: Support negative algorithmIndex values for physical nodes
  - ADD: Helper methods isPhysicalInput() and isPhysicalOutput()
  - MAINTAIN: Backward compatibility with existing connections
  - DOCUMENT: Special index values (-2 inputs, -3 outputs)

Task 7: ADD Visual Polish and Feedback
  - IMPLEMENT: Hover states for physical jacks matching PortWidget patterns
  - ADD: Connection preview colors (green valid, red invalid)
  - STYLE: Match existing port colors (blue/orange/green by signal type)
  - ANIMATE: Port size changes on hover/connection (6px to 8px inner circle)
```

### Implementation Patterns & Key Details

```dart
// Physical node widget pattern (physical_input_node_widget.dart)
class PhysicalInputNodeWidget extends StatelessWidget {
  static const double nodeWidth = 120.0;
  static const double headerHeight = 36.0;
  static const double portRowHeight = 22.0;
  static const int jackCount = 12;
  
  @override
  Widget build(BuildContext context) {
    return Container(
      width: nodeWidth,
      height: headerHeight + (jackCount * portRowHeight),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: Theme.of(context).colorScheme.outline),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Header
          Container(
            height: headerHeight,
            child: Center(child: Text('INPUTS', style: TextStyle(fontWeight: FontWeight.bold))),
          ),
          // Jacks
          ...List.generate(jackCount, (index) => _buildJack(context, index + 1)),
        ],
      ),
    );
  }
  
  Widget _buildJack(BuildContext context, int jackNumber) {
    return Container(
      height: portRowHeight,
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Row(
        children: [
          // Port widget on left (acts as output for dragging)
          PortWidget(
            algorithmIndex: -2, // Special index for physical inputs
            portId: 'physical_input_$jackNumber',
            portName: 'I$jackNumber',
            type: PortType.output, // Can be dragged FROM
            onConnectionStart: () => /* trigger connection mode */,
          ),
          SizedBox(width: 4),
          Text('I$jackNumber', style: TextStyle(fontSize: 10)),
        ],
      ),
    );
  }
}

// Cubit extension for physical nodes
extension PhysicalNodeRouting on NodeRoutingCubit {
  bool isPhysicalNode(int algorithmIndex) {
    return algorithmIndex == -2 || algorithmIndex == -3;
  }
  
  Offset? getPhysicalPortPosition(int nodeIndex, String portId) {
    if (nodeIndex == -2) {
      // Physical input node at x=50
      final portNumber = int.parse(portId.split('_').last);
      return Offset(50 + 16, // x: node position + port offset
                   36 + (portNumber - 1) * 22 + 11); // y: header + port rows
    } else if (nodeIndex == -3) {
      // Physical output node at x=4900
      final portNumber = int.parse(portId.split('_').last);
      return Offset(4900 + 104, // x: node position + width - port offset
                   36 + (portNumber - 1) * 22 + 11); // y: header + port rows
    }
    return null;
  }
}

// Auto-routing service physical I/O handling
int assignBusForPhysicalConnection(Connection connection) {
  // Physical input as source: use input bus directly
  if (connection.sourceAlgorithmIndex == -2) {
    final inputNumber = int.parse(connection.sourcePortId.split('_').last);
    return inputNumber; // Buses 1-12
  }
  
  // Physical output as target: use output bus directly  
  if (connection.targetAlgorithmIndex == -3) {
    final outputNumber = int.parse(connection.targetPortId.split('_').last);
    return 12 + outputNumber; // Buses 13-20
  }
  
  // Fall back to standard routing
  return assignBusForConnection(connection);
}
```

### Integration Points

```yaml
CANVAS:
  - add to: lib/ui/routing/routing_canvas.dart Stack children
  - pattern: "Positioned(left: 50, top: 100, child: PhysicalInputNodeWidget())"
  - pattern: "Positioned(left: 4900, top: 100, child: PhysicalOutputNodeWidget())"

STATE:
  - modify: lib/cubit/node_routing_cubit.dart
  - add: Physical node position constants
  - extend: Hit testing to include physical node bounds

ROUTING:
  - modify: lib/services/auto_routing_service.dart
  - add: Physical I/O detection by negative indices
  - map: Direct bus assignment (inputs 1-12, outputs 13-20)

VALIDATION:
  - modify: Connection validation to skip execution order for physical nodes
  - allow: Bidirectional connections (both as source and target)
```

## Validation Loop

### Level 1: Syntax & Style (Immediate Feedback)

```bash
# Run after each file creation
flutter analyze lib/ui/routing/physical_input_node_widget.dart
flutter analyze lib/ui/routing/physical_output_node_widget.dart

# Project-wide validation
flutter analyze

# Expected: Zero errors and warnings
```

### Level 2: Unit Tests (Component Validation)

```bash
# Test physical node widgets
flutter test test/ui/routing/physical_input_node_widget_test.dart
flutter test test/ui/routing/physical_output_node_widget_test.dart

# Test routing cubit modifications
flutter test test/cubit/node_routing_cubit_test.dart

# Test auto-routing service
flutter test test/services/auto_routing_service_test.dart

# Full test suite
flutter test

# Expected: All tests pass
```

### Level 3: Integration Testing (System Validation)

```bash
# Run the application
flutter run

# Manual testing checklist:
# 1. Open routing canvas view
# 2. Verify physical input node appears on left (12 jacks)
# 3. Verify physical output node appears on right (8 jacks)
# 4. Test dragging from physical input jack to algorithm input
# 5. Test dragging from algorithm output to physical output jack
# 6. Test dragging from algorithm output to physical input (bus mixing)
# 7. Verify connection colors (green valid, red invalid)
# 8. Check bus assignments in connection labels

# Hot reload testing
# Make visual changes and press 'r' to verify hot reload works
```

### Level 4: Creative & Domain-Specific Validation

```bash
# MCP Server validation (if integrated)
mcp__dart__hot_reload

# Routing validation
# Create complex routing: Physical Input → Algorithm 1 → Algorithm 2 → Physical Output
# Verify bus assignments: I1-I12 for inputs, O1-O8 for outputs, A1-A8 for internal

# Hardware simulation testing
# Test with mock MIDI manager to verify bus parameter updates
# Verify physical I/O connections don't update algorithm parameters

# Performance testing
# Create maximum connections (all 12 inputs + 8 outputs connected)
# Verify canvas remains responsive during panning and zooming

# Visual consistency
# Screenshot and compare with existing algorithm nodes
# Verify consistent spacing, colors, and interaction patterns
```

## Final Validation Checklist

### Technical Validation

- [ ] All 4 validation levels completed successfully
- [ ] flutter analyze shows zero issues
- [ ] All existing tests still pass
- [ ] New physical node widgets render correctly
- [ ] Connections can be created bidirectionally

### Feature Validation

- [ ] Physical input node shows 12 jacks (I1-I12)
- [ ] Physical output node shows 8 jacks (O1-O8)
- [ ] Can drag from physical inputs to algorithm inputs
- [ ] Can drag from algorithm outputs to physical outputs
- [ ] Can drag from algorithm outputs to physical inputs (bus mixing)
- [ ] Visual feedback during drag (green/red preview lines)
- [ ] Bus assignments correct (1-12 inputs, 13-20 outputs)
- [ ] Existing algorithm routing still works

### Code Quality Validation

- [ ] Follows existing widget patterns from algorithm_node_widget.dart
- [ ] Uses consistent port rendering from port_widget.dart
- [ ] Integrates cleanly with node_routing_cubit.dart
- [ ] Maintains backward compatibility
- [ ] No hardcoded values that should be constants

### Documentation & Deployment

- [ ] Code uses clear variable and method names
- [ ] Physical node indices documented (-2 inputs, -3 outputs)
- [ ] Bus mapping documented in comments
- [ ] Integration points clearly marked

---

## Anti-Patterns to Avoid

- ❌ Don't create new routing patterns - extend existing ones
- ❌ Don't hardcode positions - use constants
- ❌ Don't skip validation for physical I/O connections
- ❌ Don't update algorithm parameters for physical I/O
- ❌ Don't allow connections that violate bus limits
- ❌ Don't create separate gesture handlers - reuse existing
- ❌ Don't break existing algorithm node functionality