# Technical Specification

This is the technical specification for the spec detailed in @.agent-os/specs/2025-09-07-interactive-connection-creation/spec.md

> Created: 2025-09-07
> Version: 1.0.0

## Technical Requirements

### Drag Gesture Implementation
- Implement `GestureDetector` on output port widgets to capture drag start events
- Track drag state in `RoutingEditorCubit` including source port ID and current cursor position
- Use `Listener` widget to track pointer move events during drag operation
- Calculate drag preview line endpoints using existing connection path calculation logic from `ConnectionPainter`

### Connection Preview Rendering
- Reuse existing `ConnectionPainter` path calculation for preview line
- Apply semi-transparent styling to distinguish preview from established connections
- Update preview line position in real-time as cursor moves
- Ensure preview line uses identical bezier curve math as permanent connections

### Port Highlighting (No Compatibility Checks)
- Apply visual highlight to ANY input port when cursor is within proximity threshold
- All ports are compatible - no type checking needed (all signals are voltage in Eurorack)
- Highlight any input port during drag from output port
- Visual feedback based solely on proximity, not port type

### Bus Number Assignment Logic
- Follow the same pattern as connection deletion in `RoutingEditorCubit._deleteConnection()`
- When one port has bus assignment: copy that bus value to the unassigned port
- When both ports unassigned: find next available bus number based on connection type
- Use bus ranges: 
  - 1-12 for hardware inputs
  - 13-20 for hardware outputs  
  - 21-28 (aux buses) for algorithm-to-algorithm connections
- For algorithm-to-algorithm connections: use the first available aux bus (21-28)
- Advanced aux bus mode: When source algorithm is in a higher slot than all recipients on an existing aux bus, can set output to replace mode to overwrite that bus signal (only if all existing recipients are in lower slot numbers)
- Call `_distingCubit.updateParameterValueOptimistically()` for each bus parameter update

### State Management Integration
- Leverage existing `DistingCubit.updateParameterValueOptimistically()` for bus updates
- No local connection state storage - rely on `ConnectionDiscoveryService` for connection detection
- Trigger routing refresh after bus assignment to update visualization
- Maintain single source of truth in `DistingCubit` synchronized slots

### Performance Optimization
- Debounce drag move events to prevent excessive redraws
- Cache port positions during drag operation (no compatibility to cache)
- Use `RepaintBoundary` widgets to isolate preview rendering
- Batch parameter updates when setting multiple bus values

### Error Handling
- No port compatibility validation needed (all ports are compatible)
- Check for bus number conflicts before assignment
- Display dismissable error messages in top-right corner to allow continuation
- Use existing reduced intermediate states in cubit (no widget visibility changes)
- Gracefully handle drag cancellation or escape key press

## Approach

### Implementation Strategy
1. **Phase 1**: Add drag gesture detection to existing `PortWidget` components
2. **Phase 2**: Implement connection preview rendering using existing `ConnectionPainter` logic
3. **Phase 3**: Add port compatibility checking and visual feedback
4. **Phase 4**: Implement bus assignment logic following existing deletion patterns
5. **Phase 5**: Performance optimization and error handling

### Code Reuse
- Utilize existing `ConnectionPainter` path calculation for preview lines
- Follow established patterns from `RoutingEditorCubit._deleteConnection()` for bus assignment
- Leverage existing port compatibility metadata from routing framework
- Reuse visual styling patterns from current connection visualization

## External Dependencies

### Existing Framework Components
- `AlgorithmRouting.fromSlot()` for port metadata and compatibility
- `ConnectionDiscoveryService.discoverConnections()` for connection detection
- `DistingCubit.updateParameterValueOptimistically()` for bus parameter updates
- `ConnectionPainter` for bezier curve path calculation
- `PortWidget` and `ConnectionWidget` for visual components

### Flutter Dependencies
- `GestureDetector` for drag start detection
- `Listener` for pointer move tracking
- `RepaintBoundary` for performance isolation
- Standard Flutter animation and painting APIs