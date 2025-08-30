# Physical I/O Nodes Specification

## Overview

Physical Input and Output nodes represent the actual hardware connections on the Disting NT Eurorack module. These nodes provide drag-and-drop sources and targets for creating routing connections within the visualization system, ensuring that the user interface accurately reflects the hardware's 12 physical inputs and 8 physical outputs.

## Hardware Reference

### Disting NT Physical I/O Configuration
- **Physical Inputs**: 12 × 1/8" (3.5mm) jacks for receiving external signals
- **Physical Outputs**: 8 × 1/8" (3.5mm) jacks for sending processed signals
- **Hardware Constraint**: Direct input-to-output routing requires an algorithm - no direct passthrough

## Visual Design

### Physical Input Node
- **Position**: Left side of canvas in vertical column
- **Layout**: Single vertical column of 12 output jacks
- **Spacing**: 35px vertical spacing (optimal for touch interaction)
- **Jack Type**: Output ports (sources for drag operations)
- **Visual Style**: Distinctive hardware styling to differentiate from algorithm nodes

### Physical Output Node  
- **Position**: Right side of canvas in vertical column
- **Layout**: Single vertical column of 8 input jacks
- **Spacing**: 35px vertical spacing (follows HID conventions)
- **Jack Type**: Input ports (targets for drop operations)
- **Visual Style**: Consistent hardware styling matching input nodes

### Design Elements

#### Container Styling
```
┌─────────────────┐
│  Physical I/O   │ ← Header with icon
├─────────────────┤
│ 🔌 Input 1      │ ← Jack + Label
│ 🔌 Input 2      │
│ 🔌 Input 3      │
│     ...         │
│ 🔌 Input 12     │
└─────────────────┘
```

#### Visual Characteristics
- **Background**: Semi-transparent Material 3 surface color with subtle border
- **Header**: Clear identification ("Physical Inputs" / "Physical Outputs")
- **Icon**: Hardware-specific icon (e.g., cable connector symbol)
- **Spacing**: 35px between jack centers for optimal touch targets
- **Width**: Fixed width to accommodate labels and maintain consistent alignment

### Material 3 Integration
- **Container Color**: `ColorScheme.surfaceContainer` with 0.8 opacity
- **Border Color**: `ColorScheme.outline` with 0.3 opacity
- **Header Text**: `ColorScheme.onSurfaceVariant` 
- **Hardware Icon**: `ColorScheme.primary` for visual emphasis

## Technical Architecture

### Component Structure
```
PhysicalIONodeWidget (StatelessWidget)
├── Container (styled background)
│   ├── Header (title + icon)
│   └── Column
│       ├── JackConnectionWidget (Port 1)
│       ├── JackConnectionWidget (Port 2)
│       └── ...
```

### Port Configuration

#### Physical Input Ports (12 total)
```dart
List<Port> generatePhysicalInputPorts() {
  return List.generate(12, (index) => Port(
    id: 'hw_in_${index + 1}',
    name: 'Input ${index + 1}',
    type: PortType.audio,  // Default to audio, may vary per port
    direction: PortDirection.output,  // Source for connections
    description: 'Hardware input jack ${index + 1}',
    metadata: {
      'isPhysical': true,
      'hardwareIndex': index + 1,
      'jackType': 'input',
    },
  ));
}
```

#### Physical Output Ports (8 total)
```dart
List<Port> generatePhysicalOutputPorts() {
  return List.generate(8, (index) => Port(
    id: 'hw_out_${index + 1}',
    name: 'Output ${index + 1}',
    type: PortType.audio,  // Default to audio, may vary per port  
    direction: PortDirection.input,   // Target for connections
    description: 'Hardware output jack ${index + 1}',
    metadata: {
      'isPhysical': true,
      'hardwareIndex': index + 1,
      'jackType': 'output',
    },
  ));
}
```

### Core Classes

#### PhysicalIONodeWidget
```dart
class PhysicalIONodeWidget extends StatelessWidget {
  final List<Port> ports;
  final String title;
  final IconData icon;
  final Function(Port)? onPortTapped;
  final VoidCallback? onDragStart;
  final ValueChanged<Offset>? onDragUpdate;
  final ValueChanged<Offset>? onDragEnd;
  final Offset position;
  final bool isVerticalLayout;
}
```

#### PhysicalInputNode
```dart
class PhysicalInputNode extends StatelessWidget {
  final Function(Port)? onPortTapped;
  final VoidCallback? onDragStart;
  final ValueChanged<Offset>? onDragUpdate; 
  final ValueChanged<Offset>? onDragEnd;
  final Offset position;
}
```

#### PhysicalOutputNode  
```dart
class PhysicalOutputNode extends StatelessWidget {
  final Function(Port)? onPortTapped;
  final VoidCallback? onDragStart;
  final ValueChanged<Offset>? onDragUpdate;
  final ValueChanged<Offset>? onDragEnd; 
  final Offset position;
}
```

## Connection Validation Rules

### Valid Connections
1. **Physical Input → Algorithm Input**: ✅ Allowed
   ```
   [Physical Input] ──→ [Algorithm Node Input]
   ```

2. **Algorithm Output → Physical Output**: ✅ Allowed
   ```
   [Algorithm Node Output] ──→ [Physical Output]
   ```

3. **Algorithm Output → Algorithm Input**: ✅ Allowed
   ```
   [Algorithm Node Output] ──→ [Algorithm Node Input]
   ```

4. **Algorithm Output → Physical Input (Ghost Connection)**: ✅ Allowed
   ```
   [Algorithm Node Output] ──→ [Physical Input] (creates ghost signal)
   ```
   - **Purpose**: Creates a "ghost connection" that other algorithms can access
   - **Behavior**: Signal appears on physical input for use by other algorithms
   - **Visual Indicator**: Special styling to indicate ghost connection vs hardware input

5. **Algorithm Output → Physical Output (Ghost Connection)**: ✅ Allowed
   ```
   [Algorithm Node Output] ──→ [Physical Output] (creates ghost signal)
   ```
   - **Purpose**: Creates a "ghost connection" that other algorithms can access
   - **Behavior**: Signal appears on physical output for use by other algorithms
   - **Visual Indicator**: Special styling to indicate ghost connection vs direct output

### Invalid Connections
1. **Physical Input → Physical Output**: ❌ Forbidden
   ```
   [Physical Input] ──X──→ [Physical Output]
   ```
   - **Reason**: Disting NT hardware does not support direct input-to-output routing without algorithms
   - **User Feedback**: Clear error message explaining hardware limitation

2. **Physical Output → Physical Input**: ❌ Forbidden
   ```
   [Physical Output] ──X──→ [Physical Input]
   ```
   - **Reason**: Logical impossibility (outputs cannot feed inputs directly)

3. **Physical Output → Physical Output**: ❌ Forbidden
   ```
   [Physical Output] ──X──→ [Physical Output]
   ```
   - **Reason**: Output-to-output connections are not meaningful

4. **Physical Input → Physical Input**: ❌ Forbidden
   ```
   [Physical Input] ──X──→ [Physical Input]
   ```
   - **Reason**: Input-to-input connections are not meaningful

5. **Same Node Internal Connections**: ❌ Forbidden
   ```
   [Node Output] ──X──→ [Same Node Input]
   ```
   - **Reason**: Would create feedback loops

### Validation Implementation
```dart
class ConnectionValidator {
  static bool isValidConnection(Port source, Port target) {
    final sourceIsPhysical = source.metadata?['isPhysical'] == true;
    final targetIsPhysical = target.metadata?['isPhysical'] == true;
    final sourceIsAlgorithm = !sourceIsPhysical;
    final targetIsAlgorithm = !targetIsPhysical;
    
    // Valid: Physical Input → Algorithm Input
    if (sourceIsPhysical && targetIsAlgorithm && 
        source.direction == PortDirection.output && target.direction == PortDirection.input) {
      return true;
    }
    
    // Valid: Algorithm Output → Physical Output (direct connection)
    if (sourceIsAlgorithm && targetIsPhysical &&
        source.direction == PortDirection.output && target.direction == PortDirection.input) {
      return true;
    }
    
    // Valid: Algorithm Output → Algorithm Input
    if (sourceIsAlgorithm && targetIsAlgorithm &&
        source.direction == PortDirection.output && target.direction == PortDirection.input) {
      return true;
    }
    
    // Valid: Algorithm Output → Physical Input (Ghost Connection)
    if (sourceIsAlgorithm && targetIsPhysical &&
        source.direction == PortDirection.output && target.direction == PortDirection.output) {
      return true;
    }
    
    // Valid: Algorithm Output → Physical Output (Ghost Connection) - duplicate case, but explicit
    if (sourceIsAlgorithm && targetIsPhysical &&
        source.direction == PortDirection.output && target.direction == PortDirection.input) {
      return true; // Already covered above, but keeping for clarity
    }
    
    // Prevent same-node connections
    if (source.id.startsWith(target.id.split('_').first)) {
      return false;
    }
    
    // All other combinations are invalid
    return false;
  }
  
  static String getValidationError(Port source, Port target) {
    final sourceIsPhysical = source.metadata?['isPhysical'] == true;
    final targetIsPhysical = target.metadata?['isPhysical'] == true;
    
    // Physical to physical connections (except algorithm ghost connections)
    if (sourceIsPhysical && targetIsPhysical) {
      return 'Direct physical-to-physical connections are not supported. Signals must be routed through algorithms.';
    }
    
    // Same node connections
    if (source.id.startsWith(target.id.split('_').first)) {
      return 'Cannot connect a node to itself - this would create a feedback loop.';
    }
    
    return 'These ports cannot be connected. Check port directions and types.';
  }
  
  static bool isGhostConnection(Port source, Port target) {
    final sourceIsAlgorithm = source.metadata?['isPhysical'] != true;
    final targetIsPhysical = target.metadata?['isPhysical'] == true;
    
    return sourceIsAlgorithm && targetIsPhysical && 
           source.direction == PortDirection.output;
  }
  
  static String getConnectionDescription(Port source, Port target) {
    if (isGhostConnection(source, target)) {
      final targetType = target.metadata?['jackType'] as String? ?? 'unknown';
      return 'Creates ghost signal on physical $targetType - available to other algorithms';
    }
    
    return 'Direct signal routing';
  }
}
```

## Layout and Positioning

### Canvas Integration
```dart
// Physical Input positioning (left side)
final physicalInputPosition = Offset(
  50.0,  // Left margin
  100.0, // Top offset
);

// Physical Output positioning (right side) 
final physicalOutputPosition = Offset(
  canvasWidth - nodeWidth - 50.0,  // Right margin
  100.0, // Top offset
);
```

### Responsive Spacing
```dart
double getOptimalSpacing(Size screenSize) {
  // Base spacing: 35px (optimal for touch)
  double baseSpacing = 35.0;
  
  // Adjust for screen height
  if (screenSize.height < 600) {
    return baseSpacing * 0.8;  // 28px for smaller screens
  } else if (screenSize.height > 1000) {
    return baseSpacing * 1.2;  // 42px for larger screens  
  }
  
  return baseSpacing;
}
```

### Touch Target Optimization
- **Minimum Touch Target**: 44px × 44px (iOS HIG guidelines)
- **Recommended Touch Target**: 48dp × 48dp (Material Design)
- **Implementation**: 35px spacing with 24px jack diameter provides 40px+ effective target

## Interactive Behaviors

### Drag and Drop Workflow

#### Physical Input (Drag Source)
1. **Drag Start**: User begins drag from physical input jack
2. **Visual Feedback**: Connection line appears from jack to cursor
3. **Drag Update**: Line follows cursor, compatible targets highlight  
4. **Drag End**: 
   - **Valid Target**: Create connection, show success feedback
   - **Invalid Target**: Show error message, cancel connection
   - **No Target**: Cancel connection silently

#### Physical Output (Drop Target)
1. **Drag Enter**: Highlight when compatible connection approaches
2. **Drag Over**: Maintain highlight while connection hovers
3. **Drag Leave**: Remove highlight when connection moves away
4. **Drop**: Accept connection if validation passes

### Visual Feedback States

#### Connection Creation States
```dart
enum ConnectionState {
  idle,           // No active connection
  dragging,       // Currently dragging from source
  validTarget,    // Hovering over valid target
  invalidTarget,  // Hovering over invalid target
  connecting,     // Processing connection creation
  connected,      // Connection successfully created
  ghostConnected, // Ghost connection created
  error,          // Connection failed
}
```

#### Visual Indicators
- **Idle**: Default appearance
- **Dragging**: Source jack pulses, connection line visible
- **Valid Target**: Target jack glows green, scale animation
- **Invalid Target**: Target jack shows red indicator, shake animation
- **Connected**: Both jacks show connection indicator
- **Ghost Connected**: Special visual treatment for ghost connections

#### Ghost Connection Visual Design
Ghost connections require distinctive visual treatment to indicate their special nature:

**Connection Lines:**
- **Style**: Dashed or dotted line pattern instead of solid
- **Color**: Semi-transparent version of normal connection color
- **Animation**: Subtle "flow" animation to indicate signal presence
- **Thickness**: Slightly thinner than direct connections

**Jack Indicators:**
- **Ghost Source**: Small "ghost" icon overlay on algorithm output jack
- **Ghost Target**: Distinctive border/glow on physical input/output jack
- **Tooltip**: Hover tooltip explaining "Ghost signal - available to other algorithms"

**Visual Examples:**
```
Normal Connection:  [Algo Out] ═══════► [Physical Out]
Ghost Connection:   [Algo Out] ┈┈┈┈┈┈► [Physical In] 👻
                                       ↑ Ghost indicator
```

### Haptic Feedback
- **Drag Start**: Light impact feedback
- **Valid Target**: Light impact when entering valid drop zone
- **Invalid Target**: Error pattern haptic (iOS only)
- **Connection Success**: Success pattern haptic
- **Connection Failure**: Error pattern haptic

## Accessibility

### Screen Reader Support
```dart
Semantics(
  label: 'Physical input ${index + 1}',
  hint: 'Hardware audio input jack. Drag to connect to algorithm inputs.',
  value: isConnected ? 'Connected' : 'Available',
  button: true,
  enabled: true,
  child: JackConnectionWidget(...),
)
```

### Keyboard Navigation
- **Tab Navigation**: Sequential navigation through all jacks
- **Space/Enter**: Initiate connection from focused jack
- **Arrow Keys**: Navigate between nearby jacks
- **Escape**: Cancel active connection

### High Contrast Support
- **Increased Border Width**: 2px borders in high contrast mode
- **Enhanced Color Differentiation**: Higher contrast color pairs
- **Alternative Visual Indicators**: Patterns in addition to colors

## Performance Considerations

### Rendering Optimization
```dart
class PhysicalIONodeWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        child: Column(
          children: ports.map((port) => 
            RepaintBoundary(
              key: ValueKey(port.id),
              child: JackConnectionWidget(port: port),
            )
          ).toList(),
        ),
      ),
    );
  }
}
```

### Memory Management
- **Port List Caching**: Reuse port instances across rebuilds
- **Widget Key Usage**: Stable keys for optimal widget recycling
- **Lazy Loading**: Generate port widgets only when visible

### Touch Response Optimization
- **Hit Testing**: Efficient hit testing with proper bounds
- **Gesture Recognition**: Optimized gesture detection with appropriate delays
- **Animation Performance**: 60fps animations using optimized controllers

## Integration Points

### With RoutingCanvas
```dart
Widget _buildPhysicalNodes(BuildContext context) {
  return Stack(
    children: [
      // Physical Inputs (left side)
      Positioned(
        left: 50,
        top: 100,
        child: PhysicalInputNode(
          onPortTapped: _handlePhysicalInputTapped,
          onDragStart: _handleDragStart,
          onDragEnd: _handleDragEnd,
        ),
      ),
      
      // Physical Outputs (right side)
      Positioned(
        right: 50,
        top: 100,
        child: PhysicalOutputNode(
          onPortTapped: _handlePhysicalOutputTapped,
          onDragStart: _handleDragStart,
          onDragEnd: _handleDragEnd,
        ),
      ),
    ],
  );
}
```

### With Connection System
```dart
void _handleConnectionAttempt(Port source, Port target) {
  if (!ConnectionValidator.isValidConnection(source, target)) {
    _showConnectionError(
      ConnectionValidator.getValidationError(source, target)
    );
    return;
  }
  
  _createConnection(source, target);
}
```

## Testing Strategy

### Unit Tests
1. **Port Generation**: Verify correct port count and configuration
2. **Connection Validation**: Test all connection rules and edge cases
3. **Layout Calculation**: Test responsive spacing and positioning
4. **Widget Rendering**: Verify correct visual appearance

### Integration Tests  
1. **Drag and Drop**: Full drag-and-drop workflow testing
2. **Canvas Integration**: Test within complete routing canvas
3. **Connection Creation**: End-to-end connection workflows
4. **Error Handling**: Invalid connection attempt handling

### Accessibility Tests
1. **Screen Reader**: Verify all semantic labels and hints
2. **Keyboard Navigation**: Test complete keyboard workflow
3. **High Contrast**: Visual appearance in accessibility modes
4. **Touch Targets**: Verify minimum touch target sizes

### Performance Tests
1. **Rendering Performance**: Frame rate during animations
2. **Memory Usage**: Check for memory leaks during long sessions
3. **Touch Response**: Measure touch-to-response latency
4. **Scalability**: Performance with multiple active connections

## File Structure
```
lib/ui/widgets/routing/
├── physical_io_node_widget.dart       # Base physical I/O widget
├── physical_input_node.dart           # Physical input node implementation
├── physical_output_node.dart          # Physical output node implementation
├── connection_validator.dart          # Connection validation logic
└── io_node_theme_extension.dart       # Theme extensions for I/O nodes

test/ui/widgets/routing/
├── physical_io_node_widget_test.dart  # Unit tests
├── physical_input_node_test.dart      # Input node tests
├── physical_output_node_test.dart     # Output node tests
├── connection_validator_test.dart     # Validation logic tests
└── physical_io_integration_test.dart  # Integration tests
```

## Success Criteria
1. ✅ 12 physical input jacks positioned on left side with 35px spacing
2. ✅ 8 physical output jacks positioned on right side with 35px spacing
3. ✅ Clear visual distinction from algorithm nodes (hardware styling)
4. ✅ Smooth drag-and-drop connection creation workflow
5. ✅ Proper connection validation preventing invalid connections
6. ✅ Support for ghost connections (algorithm output → physical I/O)
7. ✅ Distinctive visual treatment for ghost vs direct connections
8. ✅ Clear error messaging for invalid connection attempts
9. ✅ Ghost connection tooltips explaining functionality
10. ✅ Full accessibility support including screen reader compatibility
11. ✅ 60fps performance during all interactions and animations
12. ✅ Responsive layout adapting to different screen sizes
13. ✅ Integration with existing routing visualization system

---

*This specification ensures the physical I/O interface accurately represents the Disting NT hardware while providing an intuitive and accessible user experience for creating routing connections.*