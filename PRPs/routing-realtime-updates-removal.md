name: "Remove Real-Time Updates Toggle and Enable Automatic Routing Canvas Updates"
description: |
  Investigate and refactor the routing canvas and routing analysis screens to automatically update from DistingCubit state changes, removing the need for manual real-time update toggle

---

## Goal

**Feature Goal**: Remove the manual "real time updates" toggle from routing screens and enable automatic updates through proper BlocBuilder pattern implementation, while also removing unnecessary RoutingInformation dependency

**Deliverable**: Refactored RoutingPage with automatic state updates and simplified NodeRoutingCubit that works directly with DistingCubit state

**Success Definition**: Routing canvas and routing table views automatically reflect hardware state changes without manual intervention, periodic timers, or unnecessary data structures

## User Persona

**Target User**: Musicians using Disting NT hardware who need real-time visual feedback of signal routing

**Use Case**: Viewing and modifying audio signal routing while performing or configuring patches

**User Journey**: 
1. User opens routing screen (canvas or table view)
2. Routing visualization immediately shows current hardware state
3. When user or hardware makes routing changes, display updates automatically
4. No manual sync button or toggle needed

**Pain Points Addressed**: 
- Routing canvas doesn't update without enabling real-time toggle
- Users forget to enable updates and see stale routing information
- Unnecessary cognitive overhead of managing update state

## Why

- **Consistency**: Other screens in the app (synchronized_screen, performance_screen) automatically update from cubit state
- **Performance**: Eliminates unnecessary Timer.periodic polling and redundant refreshRouting() calls
- **UX**: Removes confusion about when routing display is current vs stale
- **Architecture**: Aligns with established BlocBuilder pattern used throughout codebase

## What

Refactor RoutingPage to use BlocBuilder pattern for automatic state synchronization, and refactor NodeRoutingCubit to remove unnecessary RoutingInformation dependency, matching patterns established in synchronized_screen.dart and other screens

### Success Criteria

- [ ] NodeRoutingCubit no longer depends on RoutingInformation type
- [ ] NodeRoutingCubit initializes directly from DistingCubit state
- [ ] Routing canvas updates automatically when hardware state changes
- [ ] Routing table view updates automatically when hardware state changes  
- [ ] No manual refresh toggle in app bar
- [ ] No Timer.periodic polling mechanism
- [ ] Zero increase in network/MIDI traffic (uses existing cubit state updates)

## All Needed Context

### Context Completeness Check

_This PRP contains all patterns, file references, and implementation details needed to refactor the routing update mechanism without prior knowledge of the codebase._

### Documentation & References

```yaml
# MUST READ - Include these in your context window
- file: lib/ui/synchronized_screen.dart
  why: Primary example of BlocBuilder pattern for DistingCubit
  pattern: Multiple BlocBuilder widgets updating from cubit state
  gotcha: Uses switch expression for state handling (lines 936-941)

- file: lib/ui/routing_page.dart
  why: Current implementation to refactor
  pattern: Timer-based polling pattern to remove
  gotcha: Creates NodeRoutingCubit in build method, needs lifecycle management

- file: lib/cubit/node_routing_cubit.dart
  why: Understand how NodeRoutingCubit subscribes to DistingCubit
  pattern: Stream subscription in _subscribeToDistingChanges() method
  gotcha: Already receives all data from DistingCubit, doesn't need refreshRouting()

- file: lib/ui/performance_screen.dart
  why: Example of BlocBuilder with DistingCubit for parameter updates
  pattern: BlocBuilder at line 60, automatic state-driven UI
  gotcha: Shows both polling and BlocBuilder patterns (prefer BlocBuilder)

- file: lib/cubit/disting_cubit.dart
  why: Understand refreshRouting() method that we're removing dependency on
  pattern: refreshRouting() fetches hardware routing masks (lines with requestRoutingInformation)
  gotcha: NodeRoutingCubit doesn't use these masks, gets data from parameters instead
```

### Current Implementation Analysis

```dart
// CURRENT PROBLEM: RoutingPage doesn't listen to DistingCubit state changes
// Uses Timer.periodic for updates instead of reactive pattern

// lib/ui/routing_page.dart - Current antipattern
Timer.periodic(const Duration(seconds: 10), (timer) {
  _requestRoutingRefresh(); // Fetches routing masks not needed by NodeRoutingCubit
});

// lib/cubit/node_routing_cubit.dart - Already subscribes to state
_distingSubscription = _distingCubit.stream.listen((distingState) {
  if (distingState is DistingStateSynchronized) {
    _updateFromDistingState(distingState); // Gets all data from parameters
  }
});

// Key finding: NodeRoutingCubit sets routingInfo to empty array (line 560)
// Proves it doesn't use hardware routing masks from refreshRouting()
routingInfo: const [], // Empty routing info, not used for connection detection

// UNNECESSARY DEPENDENCY: NodeRoutingCubit uses RoutingInformation type
// but only needs algorithmIndex and algorithmName fields
// The routingInfo array (6 packed 32-bit values) is always empty/ignored
```

### Known Gotchas

```dart
// CRITICAL: NodeRoutingCubit lifecycle management
// Currently created in build method - needs proper lifecycle with BlocProvider

// CRITICAL: buildRoutingInformation() may still be needed for table view
// Investigate if RoutingTableWidget can work directly with cubit state

// CRITICAL: DistingCubit must emit state changes when routing changes
// Verify this happens on parameter updates that affect routing
```

## Implementation Blueprint

### Data Flow Architecture

```
Before (Current):
RoutingPage -> Timer -> refreshRouting() -> Hardware -> buildRoutingInformation() -> UI

After (Target):
DistingCubit state changes -> BlocBuilder rebuilds -> NodeRoutingCubit updates -> UI updates
```

### Implementation Tasks (ordered by dependencies)

```yaml
Task 1: REFACTOR lib/cubit/node_routing_cubit.dart - Remove RoutingInformation dependency
  - REMOVE: RoutingInformation parameter from initializeFromRouting()
  - REPLACE: With direct initialization from DistingCubit state
  - MODIFY: _updateFromDistingState() to not create RoutingInformation objects
  - UPDATE: All methods to work with algorithm data directly from slots
  - BENEFIT: Eliminates unnecessary data structure and clarifies data flow

Task 2: REFACTOR lib/ui/routing/node_routing_widget.dart
  - REMOVE: routing, showSignals, showMappings properties
  - REMOVE: Call to initializeFromRouting in _buildInitializing
  - INITIALIZE: NodeRoutingCubit directly from DistingCubit state on creation
  - SIMPLIFY: Widget to only handle state display, not initialization

Task 3: ANALYZE lib/ui/routing/routing_table_widget.dart
  - UNDERSTAND: Data requirements for table view
  - DETERMINE: If buildRoutingInformation() still needed for table view only
  - DOCUMENT: Alternative data source from cubit state if possible
  - VALIDATE: Table can work with NodeRoutingCubit data or needs separate handling

Task 4: MODIFY lib/ui/routing_page.dart - Convert to StatelessWidget
  - REMOVE: StatefulWidget and all state management
  - REMOVE: Timer, _isRealtimeActive, _loading, _routingInformation state
  - REMOVE: initState, dispose, _toggleRealtime methods
  - CONVERT: To StatelessWidget with BlocBuilder pattern
  - FOLLOW pattern: lib/ui/synchronized_screen.dart BlocBuilder usage

Task 5: MODIFY lib/ui/routing_page.dart - Implement BlocBuilder
  - WRAP: Entire widget tree in BlocBuilder<DistingCubit, DistingState>
  - HANDLE: Different states (Initial, SelectDevice, Synchronized)
  - CREATE: NodeRoutingCubit at appropriate level with BlocProvider
  - PATTERN: Match synchronized_screen.dart state handling (switch expression)

Task 6: MODIFY lib/ui/routing_page.dart - Update app bar
  - REMOVE: Real-time updates toggle IconButton
  - KEEP: View mode toggle (table/node view)
  - SIMPLIFY: App bar to only show essential actions

Task 7: VERIFY lib/cubit/node_routing_cubit.dart subscription
  - CONFIRM: _subscribeToDistingChanges properly updates on all state changes
  - TEST: Connection detection works without RoutingInformation
  - VALIDATE: All routing data available from parameter analysis

Task 8: MODIFY lib/ui/routing/routing_table_widget.dart (if needed)
  - ADAPT: To work with NodeRoutingCubit state if possible
  - ALTERNATIVE: Keep buildRoutingInformation() for table view only if required
  - ENSURE: Reactive updates from cubit state changes

Task 9: TEST automatic updates
  - VERIFY: Canvas updates when parameters change
  - VERIFY: Table view updates when parameters change
  - VERIFY: No manual refresh needed
  - VERIFY: No increase in MIDI traffic
```

### Implementation Pattern

```dart
// Target pattern for lib/ui/routing_page.dart
class RoutingPage extends StatelessWidget {
  final DistingCubit cubit;
  
  const RoutingPage({super.key, required this.cubit});
  
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DistingCubit, DistingState>(
      bloc: cubit,
      builder: (context, state) {
        return switch (state) {
          DistingStateSynchronized() => Scaffold(
            appBar: AppBar(
              title: const Text('Routing Analysis'),
              actions: [
                // Only view mode toggle, no refresh toggle
                IconButton(
                  icon: Icon(_viewMode == RoutingViewMode.table 
                    ? Icons.account_tree 
                    : Icons.table_chart),
                  onPressed: _toggleViewMode,
                ),
              ],
            ),
            body: _viewMode == RoutingViewMode.table
              ? RoutingTableWidget(
                  // May still need buildRoutingInformation() for table view
                  routing: cubit.buildRoutingInformation(),
                  showSignals: true,
                  showMappings: false,
                )
              : BlocProvider(
                  create: (_) => NodeRoutingCubit(
                    cubit,
                    AlgorithmMetadataService(),
                    NodePositionsPersistenceService(),
                  )..initialize(), // Direct initialization, no RoutingInformation
                  child: const NodeRoutingWidget(), // No props needed
                ),
          ),
          _ => const Center(child: CircularProgressIndicator()),
        };
      },
    );
  }
}
```

### Integration Points

```yaml
STATE MANAGEMENT:
  - Ensure: DistingCubit emits state on routing-relevant parameter changes
  - Verify: NodeRoutingCubit subscription handles all update scenarios

UI COMPONENTS:
  - Update: RoutingTableWidget to be reactive if using static data
  - Maintain: NodeRoutingWidget already reactive through NodeRoutingCubit

LIFECYCLE:
  - Manage: NodeRoutingCubit creation/disposal with BlocProvider
  - Ensure: Proper cleanup of stream subscriptions
```

## Validation Loop

### Level 1: Syntax & Style

```bash
# After modifications
flutter analyze lib/ui/routing_page.dart
flutter analyze lib/ui/routing/

# Expected: Zero warnings or errors
```

### Level 2: State Management Tests

```bash
# Test cubit updates propagate
flutter test test/cubit/node_routing_cubit_test.dart
flutter test test/ui/routing_page_test.dart

# Verify BlocBuilder rebuilds on state changes
```

### Level 3: Integration Testing

```bash
# Manual testing procedure:
1. Open routing page (canvas view)
2. Change a parameter that affects routing in another screen
3. Verify canvas updates without manual intervention
4. Switch to table view
5. Verify table shows current state
6. Create/remove connections in hardware
7. Verify automatic UI updates

# No timer logs should appear in debug console
# No periodic refreshRouting() calls in debug output
```

### Level 4: Performance Validation

```bash
# Monitor MIDI traffic
# Before: Periodic spikes every 10 seconds when real-time enabled
# After: Only updates when actual state changes occur

# Memory profiling
# Ensure no memory leaks from removed Timer
# Verify proper subscription cleanup

# UI responsiveness
# Canvas should update within 100ms of state change
# No UI freezes or jank
```

## Final Validation Checklist

### Technical Validation

- [ ] flutter analyze shows zero warnings/errors
- [ ] All existing tests pass
- [ ] No Timer.periodic in routing_page.dart
- [ ] No refreshRouting() calls for routing canvas updates
- [ ] BlocBuilder pattern properly implemented

### Feature Validation

- [ ] NodeRoutingCubit no longer uses RoutingInformation type
- [ ] NodeRoutingWidget no longer requires routing prop
- [ ] Routing canvas updates automatically on parameter changes
- [ ] Routing table updates automatically on parameter changes
- [ ] View mode toggle still works
- [ ] No manual refresh toggle in UI
- [ ] Updates happen within 100ms of hardware state change

### Code Quality

- [ ] Follows synchronized_screen.dart BlocBuilder pattern
- [ ] Proper state handling for all DistingState variants
- [ ] NodeRoutingCubit lifecycle properly managed
- [ ] No unnecessary state variables
- [ ] Clean removal of all timer-related code

## Anti-Patterns to Avoid

- ❌ Don't use Timer.periodic for state synchronization
- ❌ Don't manually fetch data that's available in cubit state
- ❌ Don't create multiple NodeRoutingCubit instances
- ❌ Don't ignore cubit state changes in favor of manual refresh
- ❌ Don't mix StatefulWidget state with BlocBuilder pattern unnecessarily
- ❌ Don't call refreshRouting() unless specifically needed for hardware sync
- ❌ Don't create unnecessary intermediate data structures (like RoutingInformation) when simpler solutions exist