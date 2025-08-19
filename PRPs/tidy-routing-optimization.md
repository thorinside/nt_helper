name: "Tidy Routing Optimization - AUX Bus Reuse via Replace Mode"
description: |
  Implement a 'tidy' action that optimizes AUX bus usage by intelligently using Replace mode 
  to free up buses for reuse, reducing bus pressure in complex presets.
  
  ⚠️ MANDATORY: This feature MUST be implemented using Test-Driven Development (TDD)
  to ensure absolute correctness. No production code without failing tests first!

---

## 🔴 TDD Quick Reference (READ FIRST!)

### The Three Laws of TDD
1. **You may not write production code until you have written a failing unit test**
2. **You may not write more of a unit test than is sufficient to fail**
3. **You may not write more production code than is sufficient to pass the test**

### TDD Cycle for This Feature
```bash
# For EVERY piece of functionality:
1. Write test that fails (RED)
   flutter test path/to/test.dart --name "specific test"
   # MUST see failure

2. Write minimal code to pass (GREEN)
   # Only enough to make test pass, nothing more
   flutter test path/to/test.dart --name "specific test"
   # MUST see pass

3. Refactor if needed (REFACTOR)
   flutter test path/to/test.dart
   # ALL tests must stay green

4. Commit with message: "RED-GREEN: [test name]"
```

### Implementation Order (STRICT!)
1. Write ALL dependency graph tests → Implement graph
2. Write ALL result model tests → Implement model  
3. Write ALL optimizer tests → Implement optimizer
4. Write ALL state tests → Implement state management
5. Write ALL UI tests → Implement UI

**NEVER SKIP AHEAD! Tests drive implementation, not the other way around.**

## Goal

**Feature Goal**: Reduce AUX bus usage in Disting NT presets by 30-50% through intelligent Replace mode optimization, enabling more complex routing configurations within the 8-bus hardware limit.

**Deliverable**: A "Tidy Routing" action in the routing mode action menu that analyzes current connections and optimizes bus assignments using Replace mode where safe.

**Success Definition**: Users can click "Tidy Routing" to automatically optimize their preset's bus usage, with visual feedback showing buses freed and connections optimized.

## User Persona

**Target User**: Disting NT power users creating complex presets with multiple algorithm connections

**Use Case**: User has exhausted available AUX buses and needs to add more connections, or wants to optimize an existing preset for efficiency

**User Journey**: 
1. User enters routing mode with a complex preset
2. Sees bus usage indicator showing high utilization
3. Clicks "Tidy Routing" action from top bar menu
4. System analyzes and optimizes connections
5. UI shows animation of connections being reorganized
6. Success message displays buses freed (e.g., "Freed 3 AUX buses!")

**Pain Points Addressed**: 
- Running out of AUX buses in complex presets
- Manual optimization is tedious and error-prone
- Unclear which connections can safely use Replace mode

## Why

- **Business value**: Enables users to create more complex presets within hardware constraints
- **Integration**: Builds on existing routing system without breaking changes
- **Problems solved**: AUX bus exhaustion, inefficient bus usage, manual optimization difficulty

## What

The Tidy Routing feature will analyze the current preset's signal flow and identify opportunities to use Replace mode to free up buses. It will:

- Analyze signal dependencies across all algorithm slots
- Identify safe replacement points where buses can be reused
- Optimize bus assignments to minimize total bus usage
- Update connection modes (Add/Replace) appropriately
- Provide visual feedback during optimization
- Show results summary with buses freed

### Success Criteria

- [ ] Reduces AUX bus usage by at least 20% in typical complex presets
- [ ] Completes optimization in under 500ms for presets with 20+ connections
- [ ] Preserves all signal paths and audio integrity
- [ ] Provides clear visual feedback during optimization
- [ ] Includes undo capability for reverting optimization
- [ ] Shows meaningful error messages if optimization fails

## All Needed Context

### Context Completeness Check

_This PRP contains all necessary context for implementing the tidy routing optimization feature, including detailed algorithm descriptions, data structures, and integration points._

### Documentation & References

```yaml
# MUST READ - Include these in your context window
- file: lib/services/auto_routing_service.dart
  why: Core bus assignment logic and connection management
  pattern: findAvailableAuxBus method for bus allocation strategy
  gotcha: Bus assignment priority (AUX -> Output -> Input)

- file: lib/util/routing_analyzer.dart
  why: Signal flow analysis and bus usage tracking
  pattern: _buildForwardSignals for signal propagation logic
  gotcha: Signal level tracking (0=none, 1=present, 2=replaced)

- file: lib/models/connection.dart
  why: Connection model with bus assignment and mode handling
  pattern: replaceMode property and violatesExecutionOrder validation
  gotcha: Physical nodes (index -2, -3) exempt from execution order

- file: lib/cubit/node_routing_cubit.dart
  why: State management for routing operations
  pattern: createConnection and toggleConnectionMode methods
  gotcha: Optimistic updates with pendingConnections tracking

- file: lib/ui/synchronized_screen.dart
  why: Action menu implementation in routing mode
  pattern: _buildAppBarActions method at lines 474-931
  gotcha: Mode detection using _currentMode == EditMode.routing

- file: lib/util/routing_validator.dart
  why: Connection validation and optimization suggestions
  pattern: validateGraph method with optimization hints
  gotcha: Topological sort for cycle detection

- docfile: PRPs/ai_docs/routing_bus_system.md
  why: Comprehensive bus system architecture documentation
  section: Bus Reuse Through Replace Mode

- docfile: PRPs/ai_docs/routing_bus_classification.md
  why: Optimization algorithms and implementation strategies
  section: Tidy Algorithm Implementation

- file: test/services/auto_routing_service_test.dart
  why: Test patterns for routing services
  pattern: Mock setup and assertion patterns
  gotcha: Use @GenerateMocks for dependency injection

- file: test/util/routing_validator_test.dart
  why: Validation testing patterns
  pattern: Test data setup and result verification
  gotcha: Edge case testing for bus exhaustion
```

### Current Codebase Structure

```bash
lib/
├── cubit/
│   ├── node_routing_cubit.dart         # Routing state management
│   └── node_routing_state.dart         # State definitions
├── models/
│   ├── connection.dart                 # Connection model
│   ├── routing_graph.dart              # Graph structure with topological sort
│   └── routing_information.dart        # Hardware routing state
├── services/
│   ├── auto_routing_service.dart       # Bus assignment logic
│   └── port_extraction_service.dart    # Port discovery
├── util/
│   ├── routing_analyzer.dart           # Signal flow analysis
│   └── routing_validator.dart          # Connection validation
└── ui/
    ├── synchronized_screen.dart        # Main screen with action menu
    └── routing/
        ├── routing_canvas.dart          # Routing visualization
        └── node_routing_widget.dart    # Routing mode wrapper
```

### Desired Codebase Structure (files to be added)

```bash
lib/
├── services/
│   └── bus_tidy_optimizer.dart         # Core optimization service
├── models/
│   └── tidy_result.dart               # Result model for optimization
└── util/
    └── bus_dependency_graph.dart      # Dependency tracking for optimization

test/
├── services/
│   └── bus_tidy_optimizer_test.dart   # Unit tests for optimizer
└── util/
    └── bus_dependency_graph_test.dart # Dependency graph tests
```

### Known Gotchas & Library Quirks

```dart
// CRITICAL: Algorithm execution order is strict (slot 0 -> 1 -> 2...)
// This means readers MUST come before writers in slot order

// CRITICAL: Bus ranges are hardware-fixed:
// 1-12: Physical inputs (cannot optimize)
// 13-20: Physical outputs (fallback only)
// 21-28: AUX buses (primary optimization target)

// CRITICAL: Physical nodes (index -2, -3) are exempt from execution order
// They can create feedback loops and monitoring connections

// CRITICAL: Replace mode (value=1) completely overwrites bus signal
// This creates the optimization opportunity but requires careful validation

// CRITICAL: Connection IDs use format "sourceSlot_sourcePort_targetSlot_targetPort"
// This format is used throughout for tracking and updates
```

## Test-Driven Development Approach

### ⚠️ CRITICAL: Test-First Implementation Required

**This feature MUST be implemented using strict Test-Driven Development (TDD) to ensure absolute correctness.**

The routing optimization logic is complex and has zero tolerance for errors - incorrect optimization could break audio signal flow and ruin user presets. The ONLY way to guarantee correctness is to:

1. **Write tests FIRST** - Define expected behavior through tests
2. **Write minimal code** - Only enough to make tests pass
3. **Refactor with confidence** - Tests ensure no regressions

### TDD Implementation Order

```yaml
MANDATORY TDD CYCLE FOR EACH COMPONENT:
1. RED: Write failing test that defines expected behavior
2. GREEN: Write minimal code to make test pass
3. REFACTOR: Improve code while tests stay green
4. REPEAT: Next test case

NEVER SKIP AHEAD - No production code without a failing test first!
```

## Implementation Blueprint

### Data Models and Structure

```dart
// lib/models/tidy_result.dart
class TidyResult {
  final bool success;
  final List<Connection> originalConnections;
  final List<Connection> optimizedConnections;
  final int busesFreed;
  final Map<String, BusChange> changes;
  final String? errorMessage;
  final List<String> warnings;
  
  const TidyResult.success({
    required this.originalConnections,
    required this.optimizedConnections,
    required this.busesFreed,
    required this.changes,
    this.warnings = const [],
  }) : success = true, errorMessage = null;
  
  const TidyResult.failed(this.errorMessage)
    : success = false,
      originalConnections = const [],
      optimizedConnections = const [],
      busesFreed = 0,
      changes = const {},
      warnings = const [];
}

class BusChange {
  final String connectionId;
  final int oldBus;
  final int newBus;
  final bool oldReplaceMode;
  final bool newReplaceMode;
  final String reason;
}

// lib/util/bus_dependency_graph.dart
class BusDependencyGraph {
  final Map<int, BusUsage> slotUsage = {};
  final Map<int, Set<int>> slotDependencies = {};
  final Map<int, BusLifetime> busLifetimes = {};
  
  void addConnection(Connection connection);
  bool canSafelyReplace(int bus, int atSlot);
  Set<int> getAvailableBusesAfterSlot(int slot);
  List<ReplacementOpportunity> findReplacementOpportunities();
}

class BusUsage {
  final Set<int> reads = {};
  final Set<int> writes = {};
  final Map<int, bool> replaceMode = {};
}

class ReplacementOpportunity {
  final int bus;
  final int slot;
  final int freedAfterSlot;
  final List<int> potentialReusers;
}
```

### Test-Driven Implementation Tasks (STRICT TDD ORDER)

```yaml
## PHASE 1: TEST INFRASTRUCTURE (Tests First!)

Task 1: CREATE test/util/bus_dependency_graph_test.dart
  TDD STEP 1 - WRITE TESTS FIRST:
  - TEST: "should track bus readers correctly"
  - TEST: "should track bus writers correctly"
  - TEST: "should identify when bus can be safely replaced"
  - TEST: "should find available buses after replacement"
  - TEST: "should detect unsafe replacement scenarios"
  - TEST: "should find all replacement opportunities"
  - TEST: "should handle physical I/O nodes correctly"
  - TEST: "should track bus lifetimes accurately"
  - RUN: flutter test (MUST FAIL - no implementation yet)

Task 2: CREATE lib/util/bus_dependency_graph.dart (MINIMAL)
  TDD STEP 2 - MAKE TESTS PASS:
  - IMPLEMENT: Only enough code to make Task 1 tests pass
  - START: Empty classes with stub methods returning defaults
  - ITERATE: Add logic incrementally as each test passes
  - REFACTOR: Clean up once all tests green

Task 3: CREATE test/models/tidy_result_test.dart
  TDD STEP 1 - WRITE TESTS FIRST:
  - TEST: "should create success result with correct properties"
  - TEST: "should create failure result with error message"
  - TEST: "should track bus changes correctly"
  - TEST: "should calculate buses freed accurately"
  - TEST: "should be immutable"
  - RUN: flutter test (MUST FAIL)

Task 4: CREATE lib/models/tidy_result.dart (MINIMAL)
  TDD STEP 2 - MAKE TESTS PASS:
  - IMPLEMENT: Only factory constructors and properties
  - NO LOGIC: Just data structure to satisfy tests

## PHASE 2: CORE OPTIMIZATION LOGIC (Tests First!)

Task 5: CREATE test/services/bus_tidy_optimizer_test.dart
  TDD STEP 1 - WRITE COMPREHENSIVE TESTS FIRST:
  
  group('Simple Optimizations'):
    - TEST: "should not optimize empty connections"
    - TEST: "should not optimize single connection"
    - TEST: "should identify simple replacement opportunity"
    - TEST: "should free one bus with basic replacement"
  
  group('Complex Scenarios'):
    - TEST: "should optimize multi-path routing correctly"
    - TEST: "should handle cascade replacements"
    - TEST: "should respect execution order constraints"
    - TEST: "should not break signal dependencies"
    
  group('Edge Cases'):
    - TEST: "should handle all buses exhausted"
    - TEST: "should handle circular dependencies"
    - TEST: "should handle physical I/O correctly"
    - TEST: "should handle 32 algorithm maximum"
    
  group('Safety Validation'):
    - TEST: "should never lose signal path"
    - TEST: "should never create execution order violations"
    - TEST: "should rollback on partial failure"
    
  group('Performance'):
    - TEST: "should complete in <500ms for 20 connections"
    - TEST: "should complete in <1s for 50 connections"
    
  MOCKS: Create all required mocks first
  RUN: flutter test (MUST FAIL - 30+ failing tests expected)

Task 6: CREATE lib/services/bus_tidy_optimizer.dart (INCREMENTAL)
  TDD STEP 2 - MAKE TESTS PASS ONE BY ONE:
  - START: Empty class with constructor
  - ADD: tidyConnections() returning failed result
  - ITERATE: Make one test pass at a time
  - REFACTOR: After each green test
  - CRITICAL: Do NOT add code without failing test

## PHASE 3: STATE MANAGEMENT (Tests First!)

Task 7: CREATE test/cubit/tidy_routing_test.dart
  TDD STEP 1 - TEST STATE MANAGEMENT:
  - TEST: "should emit isOptimizing true when starting"
  - TEST: "should emit optimized connections on success"
  - TEST: "should emit error message on failure"
  - TEST: "should preserve state on invalid state"
  - TEST: "should track optimization result"
  - MOCK: BusTidyOptimizer service
  - RUN: flutter test (MUST FAIL)

Task 8: MODIFY lib/cubit/node_routing_state.dart
  TDD STEP 2A - ADD STATE PROPERTIES:
  - ADD: isOptimizing bool (default false)
  - ADD: lastOptimizationResult TidyResult?
  - RUN: Tests still fail (expected)

Task 9: MODIFY lib/cubit/node_routing_cubit.dart
  TDD STEP 2B - IMPLEMENT STATE LOGIC:
  - ADD: tidyRouting() method
  - IMPLEMENT: State transitions to pass tests
  - ITERATE: One test at a time

## PHASE 4: HARDWARE INTEGRATION (Tests First!)

Task 10: CREATE test/services/tidy_hardware_sync_test.dart
  TDD STEP 1 - TEST HARDWARE SYNC:
  - TEST: "should update bus parameters correctly"
  - TEST: "should update replace mode parameters"
  - TEST: "should batch updates in transaction"
  - TEST: "should rollback on partial failure"
  - MOCK: Hardware communication layer
  - RUN: flutter test (MUST FAIL)

Task 11: MODIFY lib/services/auto_routing_service.dart
  TDD STEP 2 - IMPLEMENT SYNC:
  - ADD: applyTidyResult() method
  - IMPLEMENT: Parameter update logic
  - ENSURE: Atomic transaction semantics

## PHASE 5: UI INTEGRATION (Visual Tests)

Task 12: CREATE test/ui/tidy_action_test.dart
  TDD STEP 1 - TEST UI BEHAVIOR:
  - TEST: "should show tidy button in routing mode only"
  - TEST: "should disable when offline"
  - TEST: "should show progress indicator"
  - TEST: "should display success message"
  - TEST: "should display error on failure"
  - USE: Widget testing with pump()
  - RUN: flutter test (MUST FAIL)

Task 13: MODIFY lib/ui/synchronized_screen.dart
  TDD STEP 2 - ADD UI ACTION:
  - ADD: Tidy button to routing mode actions
  - IMPLEMENT: Loading states and feedback
  - VERIFY: All UI tests pass
```

### Test Specifications and Expected Behaviors

```dart
// COMPREHENSIVE TEST CASES FOR BUS DEPENDENCY GRAPH

group('BusDependencyGraph', () {
  test('should track bus readers correctly', () {
    final graph = BusDependencyGraph();
    final connection = Connection(
      sourceAlgorithmIndex: 0,
      targetAlgorithmIndex: 1,
      assignedBus: 21,
    );
    
    graph.addConnection(connection);
    
    expect(graph.getBusReaders(21), contains(1));
    expect(graph.getBusWriters(21), contains(0));
  });
  
  test('should identify safe replacement scenario', () {
    final graph = BusDependencyGraph();
    // Slot 0 writes to bus 21
    // Slot 1 reads bus 21 and writes to bus 21 with Replace
    // Slot 2 should be able to reuse bus 21
    
    graph.addConnection(Connection(
      sourceAlgorithmIndex: 0,
      targetAlgorithmIndex: 1,
      assignedBus: 21,
      replaceMode: false,
    ));
    
    graph.addConnection(Connection(
      sourceAlgorithmIndex: 1,
      targetAlgorithmIndex: 2,
      assignedBus: 21,
      replaceMode: true, // Replace mode frees the bus
    ));
    
    expect(graph.canSafelyReplace(21, atSlot: 1), isTrue);
    expect(graph.getAvailableBusesAfterSlot(1), contains(21));
  });
  
  test('should detect unsafe replacement - reader after writer', () {
    final graph = BusDependencyGraph();
    // Slot 0 writes to bus 21
    // Slot 1 wants to replace bus 21
    // Slot 2 still needs to read original signal - UNSAFE!
    
    graph.addConnection(Connection(
      sourceAlgorithmIndex: 0,
      targetAlgorithmIndex: 2, // Target in slot 2
      assignedBus: 21,
    ));
    
    expect(graph.canSafelyReplace(21, atSlot: 1), isFalse);
  });
});

// COMPREHENSIVE TEST CASES FOR TIDY OPTIMIZER

group('BusTidyOptimizer - Simple Cases', () {
  test('should identify basic replacement opportunity', () {
    // Setup: VCO -> Filter -> Output
    // VCO uses bus 21, Filter can replace it
    final connections = [
      Connection(
        id: '0_out_1_in',
        sourceAlgorithmIndex: 0,
        targetAlgorithmIndex: 1,
        assignedBus: 21,
        replaceMode: false, // Currently Add mode
      ),
      Connection(
        id: '1_out_2_in',
        sourceAlgorithmIndex: 1,
        targetAlgorithmIndex: 2,
        assignedBus: 22,
        replaceMode: false,
      ),
    ];
    
    final result = optimizer.tidyConnections(connections);
    
    expect(result.success, isTrue);
    expect(result.changes, hasLength(1));
    expect(result.changes['0_out_1_in']?.newReplaceMode, isTrue);
    // After optimization, connection should use Replace mode
  });
});

group('BusTidyOptimizer - Complex Signal Paths', () {
  test('should handle branching signal paths correctly', () {
    // Setup: VCO -> Filter and Envelope
    //        Filter -> Output1
    //        Envelope -> Output2
    // VCO signal must reach both branches
    
    final connections = [
      Connection(
        id: 'vco_to_filter',
        sourceAlgorithmIndex: 0, // VCO
        targetAlgorithmIndex: 1, // Filter
        assignedBus: 21,
        replaceMode: false,
      ),
      Connection(
        id: 'vco_to_envelope',
        sourceAlgorithmIndex: 0, // VCO
        targetAlgorithmIndex: 2, // Envelope
        assignedBus: 21, // Same bus - signal sharing
        replaceMode: false,
      ),
      Connection(
        id: 'filter_to_out1',
        sourceAlgorithmIndex: 1,
        targetAlgorithmIndex: 3,
        assignedBus: 22,
        replaceMode: false,
      ),
      Connection(
        id: 'envelope_to_out2',
        sourceAlgorithmIndex: 2,
        targetAlgorithmIndex: 4,
        assignedBus: 23,
        replaceMode: false,
      ),
    ];
    
    final result = optimizer.tidyConnections(connections);
    
    // Neither branch can use Replace on bus 21
    // because both need the original VCO signal
    expect(result.success, isTrue);
    final bus21Changes = result.changes.values
        .where((c) => c.oldBus == 21 && c.newReplaceMode == true);
    expect(bus21Changes, isEmpty, 
        reason: 'Cannot replace bus 21 - both branches need it');
  });
});

group('BusTidyOptimizer - Performance', () {
  test('should optimize 20 connections in under 500ms', () {
    final connections = _generateComplexPreset(connectionCount: 20);
    
    final stopwatch = Stopwatch()..start();
    final result = optimizer.tidyConnections(connections);
    stopwatch.stop();
    
    expect(result.success, isTrue);
    expect(stopwatch.elapsedMilliseconds, lessThan(500));
  });
});
```

### Implementation Patterns & Key Details

```dart
// TDD-DRIVEN BusTidyOptimizer implementation
// IMPORTANT: This code should ONLY be written AFTER tests are failing!

class BusTidyOptimizer {
  final NodeRoutingCubit _cubit;
  final AutoRoutingService _routingService;
  
  // Start with minimal implementation that returns failure
  // Add logic ONLY to make specific tests pass
  Future<TidyResult> tidyConnections(List<Connection> connections) async {
    // TDD Step 1: Return failure to make first test fail correctly
    // return TidyResult.failed('Not implemented');
    
    // TDD Step 2: Add empty check ONLY after test for it exists
    // if (connections.isEmpty) {
    //   return TidyResult.success(
    //     originalConnections: connections,
    //     optimizedConnections: connections,
    //     busesFreed: 0,
    //     changes: {},
    //   );
    // }
    
    // TDD Step 3: Add single connection check after its test
    // TDD Step 4: Add dependency graph after graph tests pass
    // TDD Step 5: Add optimization logic incrementally
    // NEVER ADD CODE WITHOUT A FAILING TEST!
    // PATTERN: Get current state snapshot (follow auto_routing_service.dart)
    final state = _cubit.state;
    if (state is! NodeRoutingStateLoaded) {
      return TidyResult.failed('Invalid state for optimization');
    }
    
    // Build dependency graph from current connections
    final graph = BusDependencyGraph();
    for (final connection in state.connections) {
      graph.addConnection(connection);
    }
    
    // CRITICAL: Find replacement opportunities in O(n²) time
    final opportunities = graph.findReplacementOpportunities();
    
    // GOTCHA: Sort opportunities by potential gain
    opportunities.sort((a, b) => 
      b.potentialReusers.length.compareTo(a.potentialReusers.length));
    
    // Apply optimizations greedily
    final optimized = List<Connection>.from(state.connections);
    final changes = <String, BusChange>{};
    
    for (final opp in opportunities) {
      // Validate safety before applying
      if (graph.canSafelyReplace(opp.bus, opp.slot)) {
        // Update connection to use Replace mode
        final connIndex = optimized.indexWhere((c) => 
          c.targetAlgorithmIndex == opp.slot &&
          c.assignedBus == opp.bus);
          
        if (connIndex != -1) {
          final oldConn = optimized[connIndex];
          optimized[connIndex] = oldConn.copyWith(replaceMode: true);
          changes[oldConn.id] = BusChange(
            connectionId: oldConn.id,
            oldBus: oldConn.assignedBus,
            newBus: oldConn.assignedBus,
            oldReplaceMode: false,
            newReplaceMode: true,
            reason: 'Enables bus reuse after slot ${opp.slot}',
          );
        }
      }
    }
    
    // Count freed buses
    final oldBusUsage = _countUniqueBuses(state.connections);
    final newBusUsage = _countUniqueBuses(optimized);
    final busesFreed = oldBusUsage - newBusUsage;
    
    return TidyResult.success(
      originalConnections: state.connections,
      optimizedConnections: optimized,
      busesFreed: busesFreed,
      changes: changes,
    );
  }
}

// NodeRoutingCubit integration pattern
Future<void> tidyRouting() async {
  if (state is! NodeRoutingStateLoaded) return;
  
  final loadedState = state as NodeRoutingStateLoaded;
  
  // PATTERN: Emit loading state (follow createConnection pattern)
  emit(loadedState.copyWith(isOptimizing: true));
  
  try {
    // Run optimization
    final optimizer = BusTidyOptimizer(_cubit, _routingService);
    final result = await optimizer.tidyConnections();
    
    if (result.success) {
      // Apply optimized connections
      await _routingService.applyTidyResult(result);
      
      // Update state with optimized connections
      emit(loadedState.copyWith(
        connections: result.optimizedConnections,
        isOptimizing: false,
        lastOptimizationResult: result,
        successMessage: 'Freed ${result.busesFreed} buses!',
      ));
    } else {
      emit(loadedState.copyWith(
        isOptimizing: false,
        errorMessage: result.errorMessage,
      ));
    }
  } catch (e) {
    emit(loadedState.copyWith(
      isOptimizing: false,
      errorMessage: 'Optimization failed: $e',
    ));
  }
}

// UI Integration pattern
if (_currentMode == EditMode.routing) ...[
  IconButton(
    icon: const Icon(Icons.cleaning_services),
    tooltip: 'Tidy Routing - Optimize bus usage',
    onPressed: widget.loading || isOffline
      ? null
      : () async {
          // PATTERN: Show feedback (follow existing patterns)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Optimizing routing...')),
          );
          
          await context.read<NodeRoutingCubit>().tidyRouting();
          
          // Result feedback handled by BlocListener
        },
  ),
],
```

### Integration Points

```yaml
STATE_MANAGEMENT:
  - add to: lib/cubit/node_routing_state.dart
  - properties: "bool isOptimizing, TidyResult? lastOptimizationResult"

CUBIT_METHODS:
  - add to: lib/cubit/node_routing_cubit.dart
  - method: "Future<void> tidyRouting()"

UI_ACTIONS:
  - add to: lib/ui/synchronized_screen.dart
  - location: "_buildAppBarActions() line ~490 in routing mode section"
  - widget: "IconButton with Icons.cleaning_services"

SERVICE_LAYER:
  - add to: lib/services/auto_routing_service.dart
  - method: "Future<void> applyTidyResult(TidyResult result)"

HARDWARE_SYNC:
  - update: Parameter indices 0 (output), 1 (input), 2 (replace mode)
  - batch: Use transaction pattern for atomic updates
```

## Validation Loop - TDD Enforcement

### ⚠️ CRITICAL: Test-First Validation Gates

**NO CODE WITHOUT TESTS! Each validation level enforces TDD discipline.**

### Level 0: TDD Compliance Check (MANDATORY FIRST STEP)

```bash
# BEFORE writing ANY production code, verify tests exist and fail
flutter test test/util/bus_dependency_graph_test.dart
# Expected: FAILURE - "type 'BusDependencyGraph' not found"

flutter test test/models/tidy_result_test.dart  
# Expected: FAILURE - "type 'TidyResult' not found"

flutter test test/services/bus_tidy_optimizer_test.dart
# Expected: FAILURE - "type 'BusTidyOptimizer' not found"

# If ANY test passes before implementation, STOP!
# This means TDD process was violated
```

### Level 1: Red-Green-Refactor Cycle Validation

```bash
# TDD CYCLE for each component:

# 1. RED: Verify test fails
flutter test test/util/bus_dependency_graph_test.dart --name "should track bus readers"
# Expected: FAIL

# 2. GREEN: Write minimal code, verify test passes
flutter test test/util/bus_dependency_graph_test.dart --name "should track bus readers"  
# Expected: PASS

# 3. REFACTOR: Verify all tests still pass after cleanup
flutter test test/util/bus_dependency_graph_test.dart
# Expected: ALL PASS

# 4. COVERAGE: Verify no untested code
flutter test --coverage test/util/bus_dependency_graph_test.dart
lcov --list coverage/lcov.info | grep bus_dependency_graph
# Expected: 100% coverage for new code
```

### Level 2: Unit Test Coverage Enforcement

```bash
# Strict coverage requirements for TDD
flutter test --coverage

# Generate coverage report
genhtml coverage/lcov.info -o coverage/html

# Check coverage for each new file
lcov --list coverage/lcov.info | grep -E "(bus_tidy|bus_dependency|tidy_result)"
# Expected: MINIMUM 95% line coverage
# Expected: MINIMUM 90% branch coverage

# Any uncovered code = TDD violation
# Review and add tests for uncovered branches
```

### Level 3: Integration Testing (System Validation)

```bash
# Run the application
flutter run -d macos

# Manual testing checklist:
# 1. Create preset with 10+ connections
# 2. Enter routing mode
# 3. Click Tidy Routing action
# 4. Verify optimization completes < 500ms
# 5. Check buses freed in success message
# 6. Verify audio signal integrity preserved
# 7. Test undo functionality
# 8. Save and reload preset

# Performance validation
flutter run --profile -d macos
# Monitor optimization time in DevTools

# Expected: Smooth UI, fast optimization, correct results
```

### Level 4: Hardware Validation

```bash
# Connect to actual Disting NT hardware

# Test with real device:
# 1. Load complex preset on hardware
# 2. Run tidy optimization
# 3. Verify parameters updated correctly
# 4. Check audio output unchanged
# 5. Test with edge cases (all buses used)

# Verify MIDI SysEx communication
# Monitor with MIDI tool to verify parameter updates

# Expected: Hardware state matches optimized routing
```

## Final Validation Checklist

### TDD Compliance Validation (MUST COMPLETE FIRST)

- [ ] ALL tests written BEFORE implementation code
- [ ] Every production method has corresponding test
- [ ] Test coverage >95% for all new code
- [ ] No untested branches or edge cases
- [ ] Tests define complete specification
- [ ] Tests are the source of truth for behavior

### Technical Validation

- [ ] All validation levels completed successfully
- [ ] flutter analyze shows zero issues
- [ ] All tests pass: `flutter test`
- [ ] Performance target met (<500ms for 20+ connections)
- [ ] Hardware sync verified with actual device
- [ ] Zero regression in existing tests

### Feature Validation

- [ ] Tidy action appears in routing mode menu
- [ ] Optimization reduces bus usage by 20%+ in complex presets
- [ ] Signal integrity preserved (verified by tests)
- [ ] Visual feedback during optimization
- [ ] Success/error messages display correctly
- [ ] Undo functionality works
- [ ] All edge cases handled (verified by tests)

### Code Quality Validation

- [ ] Follows existing codebase patterns
- [ ] Uses established service/cubit architecture
- [ ] Proper error handling and validation
- [ ] Test coverage >95% for new code (TDD requirement)
- [ ] No hardcoded values or magic numbers
- [ ] Code is minimal - only what tests require

### Documentation & Deployment

- [ ] Code is self-documenting with clear names
- [ ] Complex algorithms have explanatory comments
- [ ] Test cases document expected behavior
- [ ] UI strings are user-friendly

---

## Anti-Patterns to Avoid

- ❌ Don't modify connections without validation
- ❌ Don't optimize if it breaks signal flow
- ❌ Don't block UI during optimization
- ❌ Don't apply partial optimizations on failure
- ❌ Don't ignore physical I/O constraints
- ❌ Don't assume bus availability without checking