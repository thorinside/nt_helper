# Jack Connection Widget Specification

## Overview

A custom Flutter widget that visually represents a 1/8" Eurorack jack socket with interactive capabilities for the routing visualization system. The widget provides tactile feedback, drag-and-drop functionality, and clear visual distinction between different signal types.

## Visual Design

### Appearance
- **Jack Socket**: Circular element resembling a 1/8" (3.5mm) Eurorack jack
  - Outer ring: Darker shade for depth
  - Inner circle: Lighter shade with subtle gradient
  - Center hole: Small dark circle to simulate socket opening
- **Color Bar**: Horizontal bar behind the jack indicating signal type
  - **Input ports**: Extends from the jack center to the right edge
  - **Output ports**: Extends from the left edge to the jack center  
  - Height: 60% of jack diameter
  - Rounded ends for smooth appearance
- **Text Label**: Positioned based on port direction:
  - **Input ports**: Label to the right of the jack (jack on left, label on right)  
  - **Output ports**: Label to the left of the jack (label on left, jack on right)
  - Font: Material 3 typography (bodyMedium)
  - Color: OnSurface from Material 3 color scheme

### Material 3 Color Scheme
- **Audio Ports**: Primary color family (Blue tones)
- **CV Ports**: Tertiary color family (Orange/Yellow tones)  
- **Gate Ports**: Error color family (Red tones)
- **Clock Ports**: Secondary color family (Purple tones)

### Dimensions
- **Total Width**: 120dp (label + spacing + jack)
- **Total Height**: 32dp
- **Jack Diameter**: 24dp
- **Color Bar Height**: 14dp
- **Label Max Width**: 80dp
- **Spacing**: 8dp between label and jack

### Hover States
- **Jack Hover**: 
  - Subtle scale animation (1.0 → 1.1)
  - Increased elevation shadow
  - Slightly brighter color
- **Container Hover**:
  - Light background highlight
  - Smooth transition animations

## Technical Architecture

### Relationship to Existing Port Class
The `JackConnectionWidget` **augments** the existing `Port` class by providing a visual representation layer. The widget accepts a `Port` instance and renders it as an interactive jack socket:

```dart
class JackConnectionWidget extends StatefulWidget {
  final Port port;  // Uses existing Port class
  final VoidCallback? onTap;
  final VoidCallback? onDragStart;
  final ValueChanged<Offset>? onDragUpdate;  
  final ValueChanged<Offset>? onDragEnd;
  final bool isHovered;
  final bool isSelected; 
  final bool isConnected;
  final double? customWidth;
}
```

The existing `Port` class provides:
- `port.name` → Widget label
- `port.type` → Color coding and visual styling
- `port.direction` → Layout positioning (input left, output right)
- `port.isActive` → Enabled/disabled state
- `port.constraints` → Connection validation rules

### Widget Structure
```
JackConnectionWidget (StatefulWidget)
├── CustomPaint (JackPainter)
└── GestureDetector
    ├── onTap
    ├── onPanStart (drag start)
    ├── onPanUpdate (drag tracking)
    ├── onPanEnd (drag end)
    └── MouseRegion (hover detection)
```

### Core Classes

#### JackConnectionWidget
```dart
class JackConnectionWidget extends StatefulWidget {
  final Port port;                         // The port data model
  final VoidCallback? onTap;
  final VoidCallback? onDragStart;
  final ValueChanged<Offset>? onDragUpdate;  
  final ValueChanged<Offset>? onDragEnd;
  final bool isHovered;
  final bool isSelected;
  final bool isConnected;
  final double? customWidth;
}

#### JackPainter (CustomPainter)
```dart
class JackPainter extends CustomPainter {
  final Port port;                        // Uses Port.type and Port.direction
  final bool isHovered;
  final bool isSelected;
  final bool isConnected;
  final ColorScheme colorScheme;
  final Animation<double>? hoverAnimation;
}
```

### Port Type Color Mapping
```dart
Map<PortType, Color> getPortColors(ColorScheme scheme) {
  return {
    PortType.audio: scheme.primary,
    PortType.cv: scheme.tertiary, 
    PortType.gate: scheme.error,
    PortType.clock: scheme.secondary,
  };
}
```

## Interactive Behaviors

### Gesture Handling
1. **Single Tap**: Immediate callback execution
2. **Drag Start**: 
   - Detect pan start on jack area only
   - Provide haptic feedback (light impact)
   - Begin connection line rendering
3. **Drag Update**:
   - Track finger/cursor position
   - Update connection line endpoint
   - Highlight compatible target jacks
4. **Drag End**:
   - Determine drop target
   - Complete or cancel connection
   - Provide success/failure haptic feedback

### Hover Detection
- **Mouse Region**: Detect cursor entry/exit
- **Animation Controller**: Smooth hover transitions (200ms)
- **Visual Feedback**: Scale and shadow changes

### Accessibility
- **Semantic Labels**: "Audio input jack", "CV output jack", etc.
- **Semantic Hints**: "Double tap to connect", "Drag to create connection"
- **Role**: Button with specialized connection semantics
- **State Announcements**: Connected/disconnected status changes

## Animation Specifications

### Hover Animation
```dart
AnimationController(
  duration: Duration(milliseconds: 200),
  vsync: this,
);

Tween<double>(begin: 1.0, end: 1.1).animate(
  CurvedAnimation(parent: controller, curve: Curves.easeInOut)
);
```

### Connection Pulse
- **Duration**: 1000ms continuous
- **Effect**: Subtle color intensity oscillation when connected
- **Curve**: Sine wave pattern

### Drag Feedback
- **Connection Line**: Bezier curve from jack center to cursor
- **Color**: Semi-transparent port type color
- **Stroke Width**: 3dp
- **Animation**: Subtle flow animation along the curve

## Integration Points

### With AlgorithmNode
```dart
// Replace existing _buildPortWidget method
Widget _buildPortWidget(BuildContext context, Port port) {
  return JackConnectionWidget(
    port: port,                           // Pass entire Port instance
    onTap: () => onPortTapped?.call(port),
    onDragStart: () => beginConnection(port),
    onDragEnd: (offset) => completeConnection(port, offset),
  );
}

// Input ports (left side)
Column(
  children: inputPorts.map((port) => _buildPortWidget(context, port)).toList(),
)

// Output ports (right side) 
Column(
  children: outputPorts.map((port) => _buildPortWidget(context, port)).toList(),
)
```

### With Physical I/O Nodes
- **Input Nodes**: Display physical input jacks (line in, mic, etc.)
- **Output Nodes**: Display physical output jacks (line out, headphones)
- **Special Styling**: Distinct visual treatment for hardware vs software ports

## Testing Strategy

### Unit Tests
1. **Widget Rendering**: Verify correct visual elements are painted
2. **Color Mapping**: Test port type → color associations
3. **Gesture Recognition**: Mock gesture events and verify callbacks
4. **Animation States**: Test hover/selection state transitions
5. **Accessibility**: Verify semantic properties are set correctly

### Integration Tests
1. **Node Integration**: Test within AlgorithmNode and physical nodes
2. **Connection Workflow**: End-to-end drag-and-drop connection creation
3. **Theme Adaptation**: Test with different Material 3 themes
4. **Responsive Behavior**: Test at different screen sizes

### Visual Tests
1. **Golden Tests**: Capture reference images for each port type
2. **Animation Tests**: Verify smooth transitions and hover effects
3. **Theme Tests**: Test appearance across light/dark themes

## Performance Considerations

### Optimization Strategies
1. **CustomPainter Caching**: Cache paint objects for reuse
2. **Animation Throttling**: Limit update frequency during drag operations
3. **Conditional Rebuilds**: Use RepaintBoundary for isolated repaints
4. **Memory Management**: Proper disposal of animation controllers

### Rendering Efficiency
```dart
@override
bool shouldRepaint(JackPainter oldDelegate) {
  return oldDelegate.portType != portType ||
         oldDelegate.isHovered != isHovered ||
         oldDelegate.isSelected != isSelected ||
         oldDelegate.isConnected != isConnected;
}
```

## Implementation Phases

### Phase 1: Core Widget Structure
- Basic CustomPainter implementation
- Static jack rendering with color coding
- Simple gesture detection (tap only)

### Phase 2: Interactive Features  
- Hover detection and animation
- Drag gesture handling
- Connection line rendering during drag

### Phase 3: Integration & Polish
- Integration with existing AlgorithmNode
- Physical I/O node integration  
- Accessibility enhancements
- Performance optimizations

### Phase 4: Testing & Validation
- Comprehensive unit test suite
- Integration testing with routing canvas
- User experience validation
- Performance profiling

## File Structure
```
lib/ui/widgets/routing/
├── jack_connection_widget.dart        # Main widget implementation
├── jack_painter.dart                  # CustomPainter for jack rendering
├── jack_animation_controller.dart     # Animation management
└── jack_theme_extension.dart          # Theme-aware color mapping

test/ui/widgets/routing/
├── jack_connection_widget_test.dart   # Unit tests
├── jack_painter_test.dart             # Painter tests
├── jack_integration_test.dart         # Integration tests
└── goldens/                           # Golden test reference images
    ├── jack_audio_input.png
    ├── jack_cv_output.png
    └── ...
```

## Dependencies
- `flutter/material.dart`: Material 3 theming and basic widgets
- `flutter/services.dart`: Haptic feedback
- `flutter/rendering.dart`: CustomPainter capabilities
- Existing: `core/routing/models/port.dart`: Port type definitions

## Success Criteria
1. ✅ Visually resembles 1/8" Eurorack jack socket
2. ✅ Clear color coding for different port types  
3. ✅ Smooth hover and selection animations
4. ✅ Robust drag-and-drop connection workflow
5. ✅ Full accessibility support
6. ✅ Seamless integration with existing routing components
7. ✅ 60fps performance during animations and interactions
8. ✅ Comprehensive test coverage (>90%)

---

*This specification provides the foundation for implementing a professional-grade jack connection widget that enhances the user experience of the Disting NT routing visualization system.*