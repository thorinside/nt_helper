# Technical Specification

This is the technical specification for the spec detailed in @.agent-os/specs/2025-09-08-canvas-minimap-navigation/spec.md

## Technical Requirements

### Widget Architecture

- **MiniMapWidget**: Stateful widget that maintains viewport synchronization with the main canvas
  - Accepts ScrollController references from parent RoutingEditorWidget
  - Manages mini-map-specific gesture detection and coordinate transformation
  - Calculates scale factor based on canvas-to-minimap size ratio
  - Updates viewport rectangle position based on scroll controller offsets

- **MiniMapPainter**: CustomPainter implementation for efficient rendering
  - Renders simplified node representations as colored rectangles
  - Draws connections as thin lines without labels or decorations  
  - Paints viewport rectangle with semi-transparent fill and solid border
  - Uses canvas clipping to prevent overflow outside mini-map bounds

### UI/UX Specifications

- **Dimensions and Positioning**:
  - Mini-map size: 200px width × 150px height (maintains 4:3 aspect ratio)
  - Position: Bottom-right corner with 16px margin from canvas edges
  - Background: Semi-transparent (opacity 0.9) with theme surface color
  - Border: 1px solid divider color with 4px border radius
  - Z-index: Above canvas content but below error messages

- **Visual Representation**:
  - Nodes: Simplified 8×6px rectangles with algorithm-specific colors
  - Physical I/O: Distinctive shapes (inputs left-aligned, outputs right-aligned)
  - Connections: 0.5px width lines using connection type colors
  - Viewport rectangle: 2px border with primary color, 10% opacity fill
  - Grid: Optional subtle grid lines at 500px intervals

- **Interaction Behavior**:
  - Tap response: < 50ms viewport center animation
  - Drag feedback: Real-time viewport rectangle movement
  - Cursor changes: Pointer on hover, grab while dragging
  - Touch targets: Minimum 44px for mobile compatibility

### Integration Requirements

- **State Synchronization**:
  - Listen to ScrollController position changes for viewport updates
  - Access _nodePositions Map from RoutingEditorWidget for node locations
  - Subscribe to RoutingEditorCubit state for connection data
  - Coordinate transformation between canvas space and mini-map space

- **Parent Widget Modifications**:
  - Add MiniMapWidget to the Stack in RoutingEditorWidget's build method
  - Pass horizontal and vertical ScrollControllers to MiniMapWidget
  - Expose node positions through a callback or inherited widget
  - Ensure mini-map updates when nodes are moved or connections change

- **Event Handling**:
  - Intercept tap events on mini-map before canvas gesture detection
  - Calculate canvas coordinates from mini-map tap position
  - Use ScrollController.animateTo() for smooth navigation
  - Prevent event bubbling to underlying canvas during mini-map interaction

### Performance Criteria

- **Rendering Performance**:
  - Repaint only when node positions or viewport changes (use RepaintBoundary)
  - Simplified rendering: Skip text, icons, and complex shapes
  - Maximum 16ms frame time for 60 FPS during viewport dragging
  - Debounce rapid scroll events to limit repaints (10ms threshold)

- **Memory Efficiency**:
  - Cache scaled node positions to avoid recalculation
  - Reuse Paint objects across frame renders
  - Limit connection path complexity (straight lines only)
  - Total memory overhead < 2MB for typical 50-node canvas

- **Responsiveness Targets**:
  - Tap-to-navigate latency: < 50ms
  - Viewport rectangle update: < 16ms from scroll event  
  - Initial render: < 100ms
  - Support up to 200 nodes without performance degradation