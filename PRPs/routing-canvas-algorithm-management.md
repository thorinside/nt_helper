name: "Routing Canvas Algorithm Management Feature"
description: |
  Add algorithm management capabilities to the routing canvas, including a FAB for adding algorithms and overflow menu for deletion.

---

## Goal

**Feature Goal**: Enable users to add and remove algorithms directly from the routing canvas UI without navigating to the synchronized screen.

**Deliverable**: FloatingActionButton for adding algorithms and overflow menu on algorithm nodes for deletion, with proper non-overlapping positioning for new nodes.

**Success Definition**: Users can successfully add algorithms via FAB, new nodes appear without overlapping existing nodes, and algorithms can be deleted via overflow menu using the same cubit actions as synchronized screen.

## User Persona

**Target User**: Musicians and electronic music producers using the Disting NT module

**Use Case**: While visually editing signal routing connections, users need to add/remove algorithms without leaving the routing view

**User Journey**: 
1. User opens routing canvas to visualize preset routing
2. Decides to add a new algorithm to the signal chain
3. Taps FAB in bottom-right corner
4. Selects algorithm from dialog
5. New algorithm node appears on canvas without overlapping others
6. User can delete unwanted algorithms via overflow menu on nodes

**Pain Points Addressed**: 
- Currently must switch screens to manage algorithms
- Interrupts visual routing workflow
- Context switching reduces efficiency

## Why

- **Workflow Efficiency**: Keeps users in routing context while managing algorithms
- **Visual Consistency**: See immediate visual feedback of algorithm changes
- **Feature Parity**: Brings core algorithm management to routing interface
- **User Experience**: Reduces screen navigation and context switching

## What

Users will be able to:
- Add algorithms via a FAB positioned in bottom-right corner
- See new algorithm nodes positioned without overlapping existing nodes
- Delete algorithms via overflow menu (⋮) on each algorithm node
- All changes integrate with existing DistingCubit state management

### Success Criteria

- [ ] FAB appears in bottom-right corner of routing canvas
- [ ] FAB opens AddAlgorithmScreen when tapped
- [ ] New algorithms appear without overlapping existing nodes
- [ ] Algorithm nodes have overflow menu with delete option
- [ ] Delete action calls same cubit method as synchronized screen
- [ ] Node positions persist correctly after add/delete operations

## All Needed Context

### Context Completeness Check

_This PRP provides all file references, patterns, and implementation details needed for successful implementation without prior codebase knowledge._

### Documentation & References

```yaml
# MUST READ - Include these in your context window
- file: lib/ui/synchronized_screen.dart
  why: Reference implementation of FAB and delete action
  pattern: Lines 233-257 for FAB, lines 493-499 for delete action
  gotcha: FAB must use BlocProvider.value to pass cubit to AddAlgorithmScreen

- file: lib/ui/add_algorithm_screen.dart
  why: Algorithm selection dialog already implemented
  pattern: Returns Map with 'algorithm' and 'specValues' keys
  gotcha: Must handle null result when dialog is cancelled

- file: lib/ui/routing/routing_canvas.dart
  why: Main canvas widget that needs FAB integration
  pattern: Stack-based layout with CustomPaint and positioned nodes
  gotcha: Screen width changes trigger position recalculation

- file: lib/ui/routing/algorithm_node_widget.dart
  why: Node widget that needs overflow menu
  pattern: Lines 159-192 for header with arrow buttons
  gotcha: Header buttons area must exclude pan gestures

- file: lib/cubit/disting_cubit.dart
  why: State management for algorithm operations
  pattern: Lines 1322 onRemoveAlgorithm, lines 1247-1321 onAlgorithmSelected
  gotcha: Must handle different state types (synchronized vs other)

- file: lib/cubit/node_routing_cubit.dart
  why: Manages routing canvas state and positions
  pattern: Lines 69-150 for initialization and position management
  gotcha: Uses name-based position preservation during reordering

- file: lib/services/graph_layout_service.dart
  why: Layout algorithms for positioning new nodes
  pattern: Lines 222-265 _resolveOverlaps method
  gotcha: Current grid layout doesn't check for overlaps with existing nodes

- file: lib/services/node_positions_persistence_service.dart
  why: Persists node positions to SharedPreferences
  pattern: Debounced saves with 500ms delay
  gotcha: Positions keyed by preset name
```

### Current Codebase Structure

```bash
lib/
├── ui/
│   ├── routing/
│   │   ├── routing_canvas.dart          # Main canvas widget
│   │   ├── algorithm_node_widget.dart   # Individual node widget
│   │   ├── connection_painter.dart      # Connection rendering
│   │   └── routing_page.dart           # Parent page widget
│   ├── synchronized_screen.dart        # Reference FAB/delete implementation
│   └── add_algorithm_screen.dart       # Algorithm selection dialog
├── cubit/
│   ├── disting_cubit.dart             # Main state management
│   └── node_routing_cubit.dart        # Routing-specific state
├── services/
│   ├── graph_layout_service.dart      # Node positioning algorithms
│   └── node_positions_persistence_service.dart  # Position storage
└── models/
    └── node_position.dart             # Position data model
```

### Desired Codebase Structure (no new files needed)

```bash
lib/
├── ui/
│   └── routing/
│       ├── routing_canvas.dart         # MODIFY: Add FAB widget
│       └── algorithm_node_widget.dart  # MODIFY: Add overflow menu
├── services/
│   └── graph_layout_service.dart      # MODIFY: Add findNonOverlappingPosition method
```

### Known Gotchas & Implementation Details

```dart
// CRITICAL: FAB must pass cubit using BlocProvider.value
FloatingActionButton(
  onPressed: () async {
    final cubit = context.read<DistingCubit>();
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider.value(
          value: cubit,  // REQUIRED: Pass existing cubit instance
          child: const AddAlgorithmScreen(),
        ),
      ),
    );
    // Handle result...
  },
)

// CRITICAL: Node overlap prevention - current grid layout doesn't check existing positions
// Must implement spiral or grid search for non-overlapping position

// CRITICAL: Delete action must use exact cubit method signature
cubit.onRemoveAlgorithm(algorithmIndex);  // Takes int index, not name

// CRITICAL: PopupMenuButton positioning in Stack requires explicit Positioned wrapper
```

## Implementation Blueprint

### Implementation Tasks (ordered by dependencies)

```yaml
Task 1: ADD method to lib/services/graph_layout_service.dart
  - IMPLEMENT: static NodePosition findNonOverlappingPosition() method
  - PATTERN: Use spiral search starting from canvas center
  - FALLBACK: Grid search if spiral fails
  - CONSTANTS: Use existing nodeWidth=200, nodeHeight=120, minSpacing=50
  - VALIDATION: Test with hasOverlap helper method

Task 2: MODIFY lib/cubit/node_routing_cubit.dart
  - ADD: Method to handle new algorithm addition
  - INTEGRATE: Call GraphLayoutService.findNonOverlappingPosition
  - UPDATE: Node positions map with new algorithm
  - PERSIST: Save positions via NodePositionsPersistenceService
  - PATTERN: Follow existing initializeFromRouting pattern

Task 3: MODIFY lib/ui/routing/routing_canvas.dart
  - ADD: FloatingActionButton in Stack children
  - POSITION: Use Positioned(right: 16, bottom: 16)
  - ICON: Icons.add_circle_rounded (match synchronized_screen)
  - TOOLTIP: "Add Algorithm to Preset"
  - NAVIGATION: Push AddAlgorithmScreen with BlocProvider.value
  - CALLBACK: Handle result and update NodeRoutingCubit

Task 4: MODIFY lib/ui/routing/algorithm_node_widget.dart
  - ADD: PopupMenuButton to header row (after arrow buttons)
  - ICON: Icons.more_vert
  - MENU ITEM: "Delete Algorithm" with Icons.delete_forever_rounded
  - CALLBACK: Add onDelete callback prop to widget
  - POSITION: Right side of header, exclude from pan gesture handling

Task 5: WIRE callbacks in lib/ui/routing/routing_canvas.dart
  - PASS: onDelete callback to AlgorithmNodeWidget instances
  - IMPLEMENT: Call distingCubit.onRemoveAlgorithm(index)
  - UPDATE: Handle state changes and re-render

Task 6: TESTING - Manual validation steps
  - TEST: FAB appears and opens algorithm dialog
  - TEST: New nodes don't overlap existing ones
  - TEST: Delete removes correct algorithm
  - TEST: Positions persist after add/delete
  - TEST: Multiple adds create non-overlapping nodes
```

### Implementation Patterns & Key Details

```dart
// Pattern: FAB in Stack-based canvas
Stack(
  children: [
    // Existing canvas content...
    CustomPaint(/*...*/),
    
    // Algorithm nodes
    ...nodeWidgets,
    
    // FAB positioned in bottom-right
    Positioned(
      right: 16.0,
      bottom: 16.0,
      child: FloatingActionButton.small(
        tooltip: "Add Algorithm to Preset",
        onPressed: _handleAddAlgorithm,
        child: Icon(Icons.add_circle_rounded),
      ),
    ),
  ],
)

// Pattern: Non-overlapping position calculation
static NodePosition findNonOverlappingPosition({
  required Map<int, NodePosition> existingPositions,
  required int algorithmIndex,
  Offset? preferredCenter,
}) {
  final center = preferredCenter ?? Offset(800, 400);  // Canvas center
  double radius = 0;
  double angle = 0;
  
  while (radius < 1000) {
    final x = center.dx + radius * cos(angle);
    final y = center.dy + radius * sin(angle);
    
    final testPos = NodePosition(
      algorithmIndex: algorithmIndex,
      x: x - nodeWidth/2,
      y: y - nodeHeight/2,
      width: nodeWidth,
      height: math.max(nodeHeight, 60.0 + portCount * 20.0),
    );
    
    if (!hasOverlap(testPos, existingPositions, minSpacing)) {
      return testPos;
    }
    
    angle += 0.5;  // Radians
    radius += 20 * angle / (2 * pi);  // Spiral
  }
  
  // Fallback to grid position
  return _findGridPosition(existingPositions, algorithmIndex);
}

// Pattern: Overflow menu in algorithm node
Row(
  children: [
    // Algorithm name
    Expanded(
      child: Text(algorithmName, /*...*/),
    ),
    // Move up/down buttons
    if (widget.canMoveUp) IconButton(/*...*/),
    if (widget.canMoveDown) IconButton(/*...*/),
    // Overflow menu
    PopupMenuButton<String>(
      icon: Icon(Icons.more_vert, size: 20),
      onSelected: (value) {
        if (value == 'delete') {
          widget.onDelete?.call();
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_forever_rounded, size: 18),
              SizedBox(width: 8),
              Text('Delete Algorithm'),
            ],
          ),
        ),
      ],
    ),
  ],
)
```

### Integration Points

```yaml
STATE_MANAGEMENT:
  - DistingCubit: onAlgorithmSelected, onRemoveAlgorithm methods
  - NodeRoutingCubit: Update nodePositions, algorithmNames maps
  
NAVIGATION:
  - AddAlgorithmScreen: Returns Map with algorithm and specValues
  - BlocProvider.value: Pass existing cubit to dialog
  
PERSISTENCE:
  - NodePositionsPersistenceService: Auto-saves positions
  - SharedPreferences: Keyed by preset name
  
LAYOUT:
  - GraphLayoutService: New findNonOverlappingPosition method
  - Spiral search: Start from canvas center
  - Grid fallback: If spiral fails to find space
```

## Validation Loop

### Level 1: Syntax & Style

```bash
# After modifications
flutter analyze
# Expected: Zero errors/warnings

# Check formatting
dart format lib/ui/routing/ --set-exit-if-changed
# Expected: No formatting changes needed
```

### Level 2: Widget Testing

```bash
# Test routing canvas renders with FAB
flutter test test/ui/routing/routing_canvas_test.dart

# Test algorithm node renders with overflow menu  
flutter test test/ui/routing/algorithm_node_widget_test.dart

# Expected: All widget tests pass
```

### Level 3: Integration Testing

```bash
# Run app and test manually
flutter run

# Manual test steps:
# 1. Navigate to routing canvas
# 2. Verify FAB appears in bottom-right
# 3. Tap FAB and add algorithm
# 4. Verify new node doesn't overlap
# 5. Tap overflow menu on node
# 6. Select delete and verify removal
# 7. Add multiple algorithms rapidly
# 8. Verify all positioned without overlap
```

### Level 4: State Persistence Testing

```bash
# Test position persistence
# 1. Add algorithms and position manually
# 2. Restart app
# 3. Verify positions restored correctly

# Test with different presets
# 1. Add algorithms to preset A
# 2. Switch to preset B
# 3. Add different algorithms
# 4. Switch back to A
# 5. Verify correct positions for each
```

## Final Validation Checklist

### Technical Validation

- [ ] Flutter analyze shows zero issues
- [ ] Code follows existing patterns from synchronized_screen
- [ ] FAB properly positioned in Stack layout
- [ ] Overflow menu excludes from pan gestures
- [ ] Non-overlapping position algorithm works

### Feature Validation

- [ ] FAB opens AddAlgorithmScreen successfully
- [ ] New algorithms appear without overlaps
- [ ] Delete removes correct algorithm
- [ ] State updates propagate correctly
- [ ] Positions persist across app restarts

### Code Quality

- [ ] Uses existing DistingCubit methods
- [ ] Follows existing Widget patterns
- [ ] No duplicate code from synchronized_screen
- [ ] Proper error handling for dialog cancellation
- [ ] Accessibility tooltips included

### User Experience

- [ ] FAB easily accessible but not intrusive
- [ ] Delete confirmation if needed
- [ ] Visual feedback during operations
- [ ] Smooth node positioning animations
- [ ] Consistent with app's design language

---

## Anti-Patterns to Avoid

- ❌ Don't create new state management - use existing DistingCubit
- ❌ Don't duplicate AddAlgorithmScreen - reuse existing
- ❌ Don't hardcode positions - use dynamic calculation
- ❌ Don't skip overlap checking - ensure clean layout
- ❌ Don't forget BlocProvider.value when navigating
- ❌ Don't ignore preset-based position persistence