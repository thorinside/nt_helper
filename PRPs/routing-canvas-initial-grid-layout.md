# PRP: Routing Canvas Initial Grid Layout

## Goal

**Feature Goal**: Ensure all nodes are visible when the routing canvas is first shown by arranging them in a grid pattern, then persist user manual positioning in memory.

**Deliverable**: Automatic grid layout system that arranges nodes numerically (left-to-right, top-to-bottom) on initial display, with state tracking for user repositioning.

**Success Definition**: 
- All nodes visible within canvas viewport on first display
- Nodes arranged in predictable grid pattern by algorithm index
- User manual repositioning tracked in state (memory only, no persistence)
- Business logic contained in cubit, not view classes

## Context

```yaml
existing_implementation:
  routing_canvas: lib/ui/routing/routing_canvas.dart
  node_cubit: lib/cubit/node_routing_cubit.dart
  node_state: lib/cubit/node_routing_state.dart
  graph_layout: lib/services/graph_layout_service.dart
  node_position_model: lib/models/node_position.dart
  node_widget: lib/ui/routing/algorithm_node_widget.dart
  routing_page: lib/ui/routing_page.dart
  routing_widget: lib/ui/routing/node_routing_widget.dart

current_layout_approach:
  - GraphLayoutService.calculateInitialLayout uses hierarchical + force-directed
  - Fallback grid layout exists but not used: GraphLayoutService.fallbackGridLayout
  - Canvas size constants: _canvasSize = 5000.0, nodeWidth = 200.0, nodeHeight = 120.0
  - Node positions stored in Map<int, NodePosition> in NodeRoutingStateLoaded
  - updateNodePosition method exists in NodeRoutingCubit for tracking changes

state_management_pattern:
  - NodeRoutingCubit manages all routing logic (IMPORTANT: business logic stays here)
  - RoutingCanvas is pure UI widget, delegates all logic to cubit
  - State updates via cubit.updateNodePosition(algorithmIndex, newPosition)
  - Node positions tracked in NodeRoutingStateLoaded.nodePositions map

canvas_dimensions:
  - Fixed canvas: 5000x5000 pixels
  - Grid spacing: 50 pixels  
  - Canvas padding: 100 pixels
  - Node dimensions: 200x120 base (adjusts for port count)

antipatterns_to_avoid:
  - DO NOT put business logic in view classes (RoutingCanvas, NodeRoutingWidget)
  - All layout calculations belong in cubit or services
  - Views should only handle presentation and gesture forwarding

note: "Existing node editor is working well enough - focus on initial layout only"
```

## Implementation Tasks

1. **Add user interaction tracking to NodeRoutingState**
   - Add `bool hasUserRepositioned` field to NodeRoutingStateLoaded
   - Initialize as false in cubit's initializeFromRouting method
   - Set to true when updateNodePosition called

2. **Modify GraphLayoutService for grid-first approach**
   - Create new method `calculateGridLayout` that:
     - Sorts algorithm indices numerically
     - Calculates optimal grid dimensions based on node count
     - Positions nodes left-to-right, top-to-bottom
     - Centers grid within viewport bounds
   - Keep existing methods as alternative layouts

3. **Update NodeRoutingCubit initialization logic**
   - In initializeFromRouting, check if hasUserRepositioned is false
   - If false: use GraphLayoutService.calculateGridLayout
   - If true: preserve existing nodePositions from state
   - Ensure _calculatePortPositions called after layout

4. **Add viewport calculation for visible area**
   - Calculate visible viewport from canvas widget context
   - Ensure grid fits within typical screen dimensions (1600x1200)
   - Add padding to prevent edge clipping

5. **Implement extensible grid parameters**
   - Make grid columns/rows calculation dynamic
   - Support variable node counts without hardcoding
   - Account for node width/height in spacing calculations

## Validation Gates

### Functional Validation
- [ ] `flutter analyze` - Zero warnings/errors
- [ ] All nodes visible on initial canvas display
- [ ] Nodes arranged in numerical order (0,1,2,3... left-to-right, top-to-bottom)
- [ ] Manual repositioning persists during session
- [ ] Grid recalculates only on first display, not after user interaction

### Code Quality Gates  
- [ ] Business logic remains in NodeRoutingCubit only
- [ ] No layout calculations in RoutingCanvas widget
- [ ] State properly managed through cubit pattern
- [ ] Uses existing updateNodePosition for tracking changes

### Performance Validation
- [ ] Canvas renders smoothly with 20+ nodes
- [ ] Node dragging remains responsive
- [ ] No unnecessary re-layouts after user interaction

## Test Commands

```bash
# Run static analysis
flutter analyze

# Test the routing page with node view
# Navigate to Routing page and switch to node view
# Verify grid layout appears on first display
# Drag nodes and verify positions persist
# Switch views and return - positions should remain
```

## Final Validation Checklist

- [ ] Grid layout calculation uses sorted algorithm indices
- [ ] hasUserRepositioned flag properly tracks interaction state  
- [ ] Viewport bounds calculation ensures all nodes visible
- [ ] Grid dimensions scale with node count
- [ ] Manual positions persist in memory during session
- [ ] No business logic leaked into view classes
- [ ] Existing hierarchical layout preserved as option
- [ ] Port positions recalculated after any layout change

## References

- Grid layout algorithms: Use simple row/column calculation with ceiling division
- Flutter canvas coordinates: Origin at top-left, x increases right, y increases down
- State management: Follow existing Cubit pattern in node_routing_cubit.dart
- Node positioning: NodePosition model with x,y,width,height fields

## Success Metrics

**Confidence Score**: 9/10 - All required components exist, only need grid calculation and state flag

**Risk Areas**: 
- Viewport size detection may vary across platforms
- Large node counts (>50) may need pagination or zoom