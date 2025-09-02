# Technical Specification

This is the technical specification for the spec detailed in @.agent-os/specs/2025-09-02-unconnected-bus-display/spec.md

> Created: 2025-09-02
> Version: 1.0.0

## Technical Requirements

### Connection Discovery Enhancement
- Extend `ConnectionDiscoveryService` to identify ports with bus assignments that have no matching connections
- Add method to detect "orphaned" bus assignments (buses assigned but no other port shares the same bus)
- Differentiate between truly unconnected ports (bus value 0) and ports with active bus assignments lacking connections

### Visual Representation Implementation
- Create new visual components in `RoutingEditorWidget` for rendering unconnected bus indicators
- Implement short connection line rendering with appropriate directional indicators
- Add bus label rendering with proper formatting (e.g., [A1], [B3], etc.)
- Position indicators appropriately relative to port positions:
  - Output ports: line extends from port with label at end (o----[A1])
  - Input ports: label at start with line extending to port ([A3]---o)

### State Management Updates
- Extend `RoutingEditorState` to include unconnected bus information
- Add data structures to track:
  - Ports with non-zero bus assignments
  - Bus assignments without matching connections
  - Visual positioning data for unconnected indicators
- Ensure state updates trigger appropriate re-renders

### Bus Label Formatting
- Implement bus naming convention consistent with existing system
- Hardware input buses (1-12): Format as appropriate short names
- Hardware output buses (13-20): Format as appropriate short names  
- Algorithm buses: Use existing naming conventions

### Zero-Value Handling
- Implement logic to identify ports with value 0
- Exclude zero-value ports from visual representation
- Maintain internal tracking for completeness

### Visual Styling
- Use consistent color scheme with existing routing visualization
- Apply appropriate opacity/styling to indicate warning nature (not error)
- Ensure visual elements don't interfere with existing connection lines
- Maintain readability at various zoom levels

### Performance Considerations
- Optimize connection discovery for real-time updates
- Minimize computational overhead during rendering
- Cache unconnected bus calculations where appropriate
- Update only affected visual elements on state changes

## Approach

### 1. ConnectionDiscoveryService Enhancement
Extend the existing service to identify unconnected buses:
```dart
class ConnectionDiscoveryService {
  List<UnconnectedBus> discoverUnconnectedBuses(List<Port> allPorts) {
    // Implementation to find ports with bus assignments but no connections
  }
}
```

### 2. Data Model Extension
Add new models to represent unconnected bus information:
```dart
class UnconnectedBus {
  final Port port;
  final int busNumber;
  final String busLabel;
  final UnconnectedBusType type;
}
```

### 3. State Management Integration
Update `RoutingEditorCubit` to include unconnected bus discovery in the existing routing calculation flow.

### 4. Visual Component Development
Create dedicated widgets for rendering unconnected bus indicators within the existing canvas rendering system.

## External Dependencies

No new external dependencies required. Implementation will use existing Flutter rendering capabilities and the established routing framework architecture.