name: "Move Routing Canvas to Top-Level Editor"
description: |
  Refactor the routing canvas to be a top-level editor page alongside the main synchronized screen, removing its dependency on RoutingInformation and separating it from the diagnostic Routing Analysis page

---

## Goal

**Feature Goal**: Integrate routing canvas as an alternative editing mode in the main synchronized screen, accessible via segmented button toggle

**Deliverable**: Routing canvas integrated into synchronized_screen with mode switching via bottom-left segmented button, plus simplified NodeRoutingCubit that works directly with DistingCubit state

**Success Definition**: Routing canvas is accessible via single-tap mode switch, shares FAB with parameter editor, automatically updates from DistingCubit state, and no longer depends on RoutingInformation type

## User Persona

**Target User**: Musicians using Disting NT hardware who need quick access to visual routing editor

**Use Case**: Switching between parameter editing and visual routing editing during patch creation

**User Journey**: 
1. User is in main parameter editor (synchronized screen)
2. User taps segmented button in bottom-left to switch to "Routing" mode
3. Routing canvas appears immediately showing current hardware state
4. User can drag connections and reposition nodes
5. FAB still available to add algorithms in routing view
6. User taps "Parameters" segment to switch back instantly

**Pain Points Addressed**: 
- Routing canvas currently buried in diagnostic menu
- Need multiple clicks to access visual routing editor
- Confusion between routing editor (canvas) and routing diagnostics (analysis page)

## Why

- **Accessibility**: Routing canvas is a primary editing tool, not a diagnostic view
- **Separation of Concerns**: Canvas for editing, Analysis page for SysEx diagnostics
- **User Experience**: Direct access to visual routing matches its importance
- **Architecture**: Cleaner separation between interactive editing and read-only analysis

## What

Integrate routing canvas into synchronized_screen with segmented button mode switching, refactor NodeRoutingCubit to work directly with DistingCubit state, and maintain Routing Analysis page as separate diagnostic tool

### Success Criteria

- [ ] Segmented button in bottom-left of synchronized_screen for mode switching
- [ ] Single-tap switching between Parameters and Routing modes
- [ ] FAB remains functional in both modes (Add Algorithm)
- [ ] NodeRoutingCubit no longer depends on RoutingInformation type
- [ ] Routing canvas automatically updates from DistingCubit state changes
- [ ] Routing Analysis page remains unchanged for SysEx visualization
- [ ] Visual balance: mode switcher (left) | actions (right) | FAB (docked)
- [ ] No increase in MIDI traffic

## All Needed Context

### Context Completeness Check

_This PRP contains all patterns, file references, and implementation details needed to elevate the routing canvas to a top-level editor without prior knowledge of the codebase._

### Documentation & References

```yaml
# MUST READ - Include these in your context window
- file: lib/ui/synchronized_screen.dart
  why: Primary editor screen - routing canvas will be an alternative to this
  pattern: How top-level editor screens are structured
  gotcha: Uses BlocBuilder pattern extensively

- file: lib/ui/disting_app.dart
  why: Main app structure where routing canvas needs to be integrated
  pattern: Navigation and screen selection logic
  gotcha: State-based screen selection in build method

- file: lib/cubit/node_routing_cubit.dart
  why: Core logic that needs refactoring to remove RoutingInformation
  pattern: Stream subscription to DistingCubit, connection detection
  gotcha: Currently creates empty RoutingInformation objects unnecessarily

- file: lib/ui/routing/node_routing_widget.dart
  why: Widget that needs simplification
  pattern: Currently receives routing prop that isn't needed
  gotcha: Calls initializeFromRouting which should be removed

- file: lib/ui/routing/routing_canvas.dart
  why: The actual canvas implementation - works well as-is
  pattern: Interactive drawing and node positioning
  gotcha: Already works with NodeRoutingCubit state

- file: lib/ui/routing_page.dart
  why: Current home of both canvas and table views
  pattern: Shows how canvas is currently integrated
  gotcha: Keep this for table view only, remove canvas
```

### Current Architecture Analysis

```dart
// CURRENT: Routing canvas nested inside diagnostic page
RoutingPage (StatefulWidget with Timer)
  ├── RoutingTableWidget (diagnostic view of SysEx data)
  └── NodeRoutingWidget (editor canvas)
      └── RoutingCanvas

// TARGET: Integrated editor with mode switching
SynchronizedScreen
  ├── BottomAppBar
  │   ├── SegmentedButton (left): [Parameters | Routing]
  │   └── Action buttons (right): Settings, Save, etc.
  ├── Body (conditional based on mode)
  │   ├── Parameters mode: Existing parameter editor
  │   └── Routing mode: NodeRoutingWidget with canvas
  └── FAB: Add Algorithm (works in both modes)
  
Diagnostic Menu (unchanged)
  └── RoutingAnalysisPage (table view of SysEx routing masks)

// NodeRoutingCubit currently uses RoutingInformation unnecessarily
initializeFromRouting(List<RoutingInformation> routing) // TO REMOVE
_updateFromDistingState(distingState) // Already has all needed data
```

### Known Gotchas

```dart
// CRITICAL: Navigation integration
// Need to add routing canvas option to main app navigation

// CRITICAL: NodeRoutingCubit lifecycle
// Must be created at appropriate level with proper BlocProvider

// CRITICAL: Routing Analysis page serves different purpose
// Keep it unchanged for SysEx routing mask visualization
```

## Implementation Blueprint

### Data Flow Architecture

```
Current:
DistingCubit -> buildRoutingInformation() -> NodeRoutingWidget -> NodeRoutingCubit -> Canvas

Target:
DistingCubit state -> NodeRoutingCubit (direct subscription) -> Canvas
```

### Implementation Tasks (ordered by dependencies)

```yaml
Task 1: REFACTOR lib/cubit/node_routing_cubit.dart - Remove RoutingInformation
  - REMOVE: initializeFromRouting(List<RoutingInformation> routing) method
  - ADD: initialize() method that reads directly from DistingCubit state
  - REMOVE: RoutingInformation creation in _updateFromDistingState()
  - MODIFY: _extractPortLayouts to work with slots directly
  - MODIFY: _interpretRoutingMasks to work with slots directly
  - KEEP: All connection detection logic (works via parameters)
  - BENEFIT: Cleaner data flow, no unnecessary intermediate structures

Task 2: MODIFY lib/ui/synchronized_screen.dart - Add mode switching
  - ADD: EditMode enum with parameters and routing values
  - ADD: _currentMode state variable (default EditMode.parameters)
  - MODIFY: BottomAppBar to include SegmentedButton on left side
  - IMPLEMENT: Conditional body rendering based on _currentMode
  - CREATE: _buildRoutingCanvas() method with NodeRoutingCubit BlocProvider
  - MAINTAIN: Existing FAB for both modes

Task 3: SIMPLIFY lib/ui/routing/node_routing_widget.dart
  - REMOVE: routing, showSignals, showMappings properties
  - REMOVE: initializeFromRouting call in _buildInitializing
  - MODIFY: Constructor to have no required parameters
  - ENSURE: NodeRoutingCubit initializes itself on creation
  - KEEP: All state handling and canvas rendering logic

Task 4: INTEGRATE into lib/ui/synchronized_screen.dart navigation
  - ADD: Segmented button to bottom app bar (left side)
  - IMPLEMENT: EditMode enum (parameters, routing)
  - CREATE: Mode state management in synchronized_screen
  - POSITION: Bottom-left for thumb reach, balancing FAB on right
  - UPDATE: Body content based on selected mode
  - MAINTAIN: FAB functionality for both modes (Add Algorithm)

Task 5: UPDATE lib/ui/routing_page.dart - Remove canvas, keep table
  - REMOVE: RoutingViewMode enum and toggle logic
  - REMOVE: NodeRoutingWidget integration
  - KEEP: RoutingTableWidget for SysEx visualization
  - KEEP: Real-time updates toggle (useful for diagnostics)
  - RENAME: Consider renaming to RoutingAnalysisPage for clarity
  - UPDATE: App bar title to "Routing Analysis" or "Routing Diagnostics"

Task 6: TEST integration
  - VERIFY: Canvas accessible from main navigation
  - VERIFY: Automatic updates when parameters change
  - VERIFY: Node positioning persistence works
  - VERIFY: Connection creation/deletion works
  - VERIFY: Routing Analysis page still shows SysEx data
  - VERIFY: No regression in existing functionality
```

### Implementation Pattern

```dart
// lib/ui/synchronized_screen.dart - Add mode switching
enum EditMode { parameters, routing }

class _SynchronizedScreenState extends State<SynchronizedScreen> {
  EditMode _currentMode = EditMode.parameters;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.preset?.name ?? 'Preset'),
        // Existing tab bar for algorithm slots
        bottom: TabBar(...),
      ),
      body: _currentMode == EditMode.parameters
        ? _buildParameterEditor()  // Existing parameter UI
        : _buildRoutingCanvas(),    // New routing canvas
      bottomNavigationBar: BottomAppBar(
        child: Row(
          children: [
            // Left side - Mode switcher
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: SegmentedButton<EditMode>(
                segments: const [
                  ButtonSegment(
                    value: EditMode.parameters,
                    label: Text('Parameters'),
                    icon: Icon(Icons.tune),
                  ),
                  ButtonSegment(
                    value: EditMode.routing,
                    label: Text('Routing'),
                    icon: Icon(Icons.account_tree),
                  ),
                ],
                selected: {_currentMode},
                onSelectionChanged: (Set<EditMode> modes) {
                  setState(() {
                    _currentMode = modes.first;
                  });
                },
                style: ButtonStyle(
                  // Material 3 styling for prominence
                  visualDensity: VisualDensity.comfortable,
                ),
              ),
            ),
            
            const Spacer(),
            
            // Right side - Existing action buttons
            IconButton(icon: Icon(Icons.settings), ...),
            IconButton(icon: Icon(Icons.save), ...),
            // etc.
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _handleAddAlgorithm(),
        child: const Icon(Icons.add),
        tooltip: 'Add Algorithm',
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
    );
  }
  
  Widget _buildRoutingCanvas() {
    return BlocProvider(
      create: (_) => NodeRoutingCubit(
        widget.cubit,
        AlgorithmMetadataService(),
        NodePositionsPersistenceService(),
      )..initialize(),
      child: const NodeRoutingWidget(),
    );
  }

// Simplified NodeRoutingCubit initialization
class NodeRoutingCubit extends Cubit<NodeRoutingState> {
  void initialize() {
    final state = _distingCubit.state;
    if (state is DistingStateSynchronized) {
      _updateFromDistingState(state);
    }
  }
  
  // Remove initializeFromRouting entirely
  // Work directly with slots from DistingCubit state
}
```

### Integration Points

```yaml
NAVIGATION:
  - location: lib/ui/synchronized_screen.dart bottom app bar
  - widget: SegmentedButton with EditMode enum
  - position: Bottom-left for optimal thumb reach
  - balance: FAB on right, mode switcher on left

STATE MANAGEMENT:
  - Local: EditMode state in synchronized_screen
  - Cubit: NodeRoutingCubit lifecycle managed by BlocProvider
  - Updates: Automatic via DistingCubit subscription
  - Persistence: Node positions per preset maintained

UI LAYOUT:
  - BottomAppBar: Mode switcher (left) | Actions (right)
  - FAB: Shared between both modes (Add Algorithm)
  - Body: Conditional rendering based on EditMode
  - AppBar: Unchanged, keeps existing tab bar for slots

SEPARATION:
  - Clear: Routing canvas (editor) vs Routing analysis (diagnostics)
  - Access: Canvas via segmented button, Analysis via menu
  - Purpose: Editor for creation, Analysis for debugging
```

## Validation Loop

### Level 1: Syntax & Style

```bash
# After modifications
flutter analyze lib/ui/routing_canvas_screen.dart
flutter analyze lib/cubit/node_routing_cubit.dart
flutter analyze lib/ui/routing/

# Expected: Zero warnings or errors
```

### Level 2: Unit Tests

```bash
# Test NodeRoutingCubit without RoutingInformation
flutter test test/cubit/node_routing_cubit_test.dart

# Test new screen integration
flutter test test/ui/routing_canvas_screen_test.dart

# Verify no regression
flutter test
```

### Level 3: Integration Testing

```bash
# Manual testing procedure:
1. Launch app and connect to hardware
2. Open synchronized screen (main editor)
3. Locate segmented button in bottom-left
4. Tap "Routing" segment to switch modes
5. Verify canvas appears immediately with current routing
6. Create a connection by dragging between nodes
7. Verify connection appears in hardware
8. Tap FAB to add algorithm (should work in routing mode)
9. Tap "Parameters" segment to switch back
10. Change a bus parameter value
11. Tap "Routing" to return to canvas
12. Verify canvas reflects the parameter change
13. Navigate to Routing Analysis via menu (diagnostics)
14. Verify SysEx routing masks still display correctly

# Interaction testing:
- Segmented button responds to taps immediately
- Mode transitions are smooth (no loading delay)
- FAB remains in same position for both modes
- Bottom bar layout stays balanced
```

### Level 4: User Experience Validation

```bash
# Navigation flow testing:
- Time to access routing canvas: 1 tap (segmented button)
- Mode switching latency: < 50ms
- Visual feedback: Immediate segment highlight
- No confusion: Clear mode indicator in segmented button

# Layout validation:
- Bottom bar balance: Mode (left) | Actions (right) | FAB
- Thumb reach test: Segmented button easily accessible
- No UI overlap or crowding
- Icons clearly distinguish modes

# Performance testing:
- Canvas responsiveness during interaction
- Update latency < 100ms for parameter changes
- Memory usage stable during mode switches
- No flicker or jank during transitions
```

## Final Validation Checklist

### Technical Validation

- [ ] flutter analyze shows zero warnings/errors
- [ ] All existing tests pass
- [ ] NodeRoutingCubit no longer uses RoutingInformation
- [ ] Routing canvas accessible from main navigation
- [ ] BlocBuilder pattern properly implemented

### Feature Validation

- [ ] Segmented button switches between Parameters and Routing modes
- [ ] Single tap to access routing canvas
- [ ] FAB works in both modes for adding algorithms
- [ ] Automatic updates from DistingCubit state
- [ ] Node positioning and connections work
- [ ] Routing Analysis page unchanged and functional
- [ ] Clear visual separation: mode switcher left, actions right

### Code Quality

- [ ] Follows existing navigation patterns
- [ ] Proper state management with BlocBuilder
- [ ] NodeRoutingCubit lifecycle properly managed
- [ ] Clean separation of concerns
- [ ] No unnecessary data structures

### User Experience

- [ ] Routing canvas accessible with single tap
- [ ] Segmented button position optimal for thumb reach
- [ ] Visual balance maintained in bottom app bar
- [ ] Clear mode indication in segmented button
- [ ] Smooth transitions between modes (< 50ms)
- [ ] FAB position consistent across modes
- [ ] No performance degradation

## Anti-Patterns to Avoid

- ❌ Don't mix editor and diagnostic functionality
- ❌ Don't create RoutingInformation when not needed
- ❌ Don't bury primary editing tools in diagnostic menus
- ❌ Don't duplicate state management logic
- ❌ Don't break existing Routing Analysis functionality
- ❌ Don't add complex navigation when simple patterns exist