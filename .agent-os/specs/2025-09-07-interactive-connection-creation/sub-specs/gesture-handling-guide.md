# Gesture Handling Technical Guide

This guide documents the technical considerations for implementing drag gestures in the routing editor while preserving existing gesture functionality.

## Current Gesture Architecture

The routing editor uses a hierarchical gesture system with clear separation of concerns:

### Gesture Hierarchy
1. **Canvas Level**: Pan gestures for viewport manipulation (routing_editor_widget.dart)
2. **Node Level**: Pan gestures for dragging algorithm nodes (algorithm_node_widget.dart)
3. **Port Level**: Currently tap/hover for selection - will add pan for connection creation
4. **Connection Level**: Tap/hover for deletion (interactive_connection_widget.dart)

### Platform-Specific Handling
The codebase uses PlatformInteractionService to adapt gestures:
- **Desktop**: Mouse hover + click interactions
- **Mobile**: Tap + long press interactions
- **Tablets**: Touch with hover support detection

## Implementation Requirements

### 1. Gesture Conflict Prevention

**Critical**: Child gestures win over parent gestures by default in Flutter. The port drag gesture will automatically take precedence over canvas pan.

```dart
// Port widget implementation pattern
GestureDetector(
  behavior: HitTestBehavior.opaque, // Essential for hit detection
  onPanStart: (details) {
    // Will consume gesture before parent canvas
    _handleConnectionDragStart(details);
  },
  onPanUpdate: (details) {
    _handleConnectionDragUpdate(details);
  },
  onPanEnd: (details) {
    _handleConnectionDragEnd(details);
  },
  child: portVisual,
)
```

### 2. State Management During Drag

The RoutingEditorCubit must track:
- `isDragging`: Boolean flag for drag state
- `dragSourcePort`: The port being dragged from
- `dragCurrentPosition`: Current global position for preview line
- `highlightedTargetPort`: Port under cursor for visual feedback

### 3. Coordinate System Consistency

**Always use global coordinates** for cross-widget interactions:
```dart
onPanStart: (details) => details.globalPosition  // NOT details.localPosition
onPanUpdate: (details) => details.globalPosition // For absolute positioning
onPanEnd: (details) => details.globalPosition    // For drop detection
```

### 4. Preview Line Rendering

Reuse existing ConnectionPainter bezier calculations:
- Extract path calculation logic into static method
- Apply semi-transparent overlay for preview
- Use RepaintBoundary to isolate preview updates

### 5. Drop Target Detection (All Ports Compatible)

**No compatibility checking** - All signals in Eurorack are voltage, so any output can connect to any input.

```dart
// Find port at global position - NO TYPE CHECKING
Port? _getPortAtPosition(Offset globalPosition) {
  // Convert global to local coordinates for each port
  // Check if position is within port bounds
  // Return matching port or null (no type validation needed)
}
```

**Visual Feedback**: Port highlighting should be subtle and delightful - consider gentle scale animation or soft glow effect rather than harsh color changes.

### 6. Existing Gesture Preservation

**Must maintain**:
- Canvas pan for viewport navigation (when not dragging from port)
- Node dragging for algorithm positioning
- Connection tap/hover for deletion
- Port tap for selection (if implemented)

### 7. Performance Optimizations

- Debounce drag updates to prevent excessive rebuilds
- Cache port positions during drag operation
- Use const constructors where possible
- Batch state updates in cubit

## Testing Considerations

### Manual Testing Checklist
- [ ] Canvas pan still works when dragging empty space
- [ ] Algorithm nodes can still be dragged
- [ ] Connections can still be deleted via tap/hover
- [ ] Port drag doesn't interfere with node drag
- [ ] Preview line follows cursor smoothly
- [ ] Drop highlighting appears on valid targets
- [ ] Connection creates on valid drop
- [ ] Drag cancellation (ESC key) works properly

### Automated Testing
- Unit tests for bus assignment logic
- Widget tests for gesture detection
- Integration tests for full drag-drop flow

## Platform-Specific Considerations

### Desktop (macOS, Windows, Linux)
- Support ESC key to cancel drag
- Show cursor change during drag
- Highlight on hover during drag

### Mobile (iOS, Android)
- Larger touch targets for ports
- Visual feedback for drag start
- Haptic feedback on successful connection

### Web
- Handle both mouse and touch events
- Prevent default browser drag behavior

## Error Handling

1. **Invalid Drop Target**: No connection created (silent failure is OK)
2. **Drag Cancelled**: Clear preview + restore state
3. **Rapid Drags**: Debounce to prevent conflicts
4. **Bus Conflicts**: Display dismissable error in top-right corner
5. **General Errors**: Show dismissable notifications that allow user to continue

**Error Display Pattern**:
- Use dismissable error messages in top-right corner
- Allow user to continue working while error is displayed
- Leverage reduced intermediate states in cubit (no widget visibility changes needed)

## Code Reuse

Leverage existing implementations:
- `ConnectionPainter` for path calculations
- `PlatformInteractionService` for platform detection
- `DistingCubit.updateParameterValueOptimistically` for bus updates
- `ConnectionDiscoveryService` for connection validation