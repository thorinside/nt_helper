name: "Fix Physical Node Routing RangeError - Negative Index Bounds Checking"
description: |
  Fix RangeError when connecting physical inputs (I1-I12) to algorithm inputs due to negative 
  algorithm indices not being properly guarded in parameter lookup functions.

---

## Goal

**Feature Goal**: Prevent RangeError exceptions when creating or removing connections involving physical I/O nodes by adding proper bounds checking for negative algorithm indices.

**Deliverable**: Updated `AutoRoutingService._findParameterNumberForPort` method with guards against negative indices, preventing array access violations when handling physical node connections.

**Success Definition**: Users can freely connect physical inputs (I1-I12) to algorithm inputs and physical outputs (O1-O8) without triggering RangeError exceptions.

## User Persona

**Target User**: Disting NT module users managing hardware routing

**Use Case**: Connecting physical input jack I4 to a Lua Script algorithm's V/Oct input port

**User Journey**: 
1. User drags connection from physical input I4
2. User drops connection on Lua Script V/Oct input
3. Connection is created successfully without errors

**Pain Points Addressed**: 
- Repeated toast error "Failed to remove connection: RangeError (length): Invalid value: Only valid value is 0: -2"
- Inability to create physical I/O connections reliably
- Application instability when routing physical connections

## Why

- Physical I/O connections are essential for routing external signals through the Disting NT
- The bug prevents users from creating fundamental signal paths between hardware and algorithms
- The repeated error toasts degrade user experience and suggest application instability
- This is a critical data integrity issue that could corrupt routing state

## What

The routing system uses special negative algorithm indices to represent physical nodes:
- Physical Input Node: index `-2` (12 input jacks I1-I12)  
- Physical Output Node: index `-3` (8 output jacks O1-O8)

When removing connections, `AutoRoutingService._findParameterNumberForPort` attempts to access `distingState.slots[algorithmIndex]` without checking for negative indices, causing RangeError when the index is -2 or -3.

### Success Criteria

- [ ] Physical input connections (I1-I12) can be created without errors
- [ ] Physical output connections (O1-O8) can be created without errors
- [ ] Connections can be removed without RangeError exceptions
- [ ] All existing routing functionality remains intact
- [ ] Proper fallback behavior for physical nodes in parameter lookup

## All Needed Context

### Context Completeness Check

_This PRP contains all information needed to fix the RangeError without prior knowledge of the codebase._

### Documentation & References

```yaml
# MUST READ - Include these in your context window
- file: /Users/nealsanche/nosuch/nt_helper/lib/services/auto_routing_service.dart
  why: Contains the _findParameterNumberForPort method that needs fixing
  pattern: Lines 349-507 show current implementation without physical node guards
  gotcha: Method accesses slots array at line 362 without bounds checking

- file: /Users/nealsanche/nosuch/nt_helper/lib/cubit/node_routing_cubit.dart
  why: Shows correct pattern for handling physical nodes with _isPhysicalNode helper
  pattern: Lines 1191-1194 define _isPhysicalNode utility method
  gotcha: Physical nodes use indices -2 and -3, not present in slots array

- file: /Users/nealsanche/nosuch/nt_helper/lib/models/connection.dart
  why: Provides utilities for detecting physical connections
  pattern: Lines 27-32 show isPhysicalInput/isPhysicalOutput helpers
  gotcha: Physical connections are exempt from execution order constraints

- url: https://pub.dev/documentation/collection/latest/collection/IterableExtension/elementAtOrNull.html
  why: Dart best practice for safe list access with bounds checking
  critical: Use elementAtOrNull or manual guards to prevent RangeError

- docfile: PRPs/ai_docs/routing_bus_system.md
  why: Documents the bus routing system and physical I/O handling
  section: Physical I/O bus assignments and parameter exemptions
```

### Current Codebase Structure

```bash
lib/
├── services/
│   ├── auto_routing_service.dart       # Contains buggy _findParameterNumberForPort
│   └── port_extraction_service.dart    # Port ID sanitization logic
├── cubit/
│   └── node_routing_cubit.dart        # Has _isPhysicalNode helper pattern
├── models/
│   └── connection.dart                # Physical connection detection utilities
└── ui/
    └── routing/
        ├── physical_input_node_widget.dart   # Physical input UI (I1-I12)
        └── physical_output_node_widget.dart  # Physical output UI (O1-O8)
```

### Known Gotchas of our codebase & Library Quirks

```dart
// CRITICAL: Physical nodes use negative algorithm indices
// Physical Input Node: algorithmIndex = -2
// Physical Output Node: algorithmIndex = -3
// These indices will NEVER exist in distingState.slots array

// CRITICAL: Physical connections use hardware-fixed bus assignments
// Inputs I1-I12 → buses 1-12
// Outputs O1-O8 → buses 13-20
// Physical connections don't need parameter updates (hardware handles routing)

// PATTERN: Always check for physical nodes before accessing slots array
// Use early returns or guards when algorithmIndex < 0
```

## Implementation Blueprint

### Implementation Tasks (ordered by dependencies)

```yaml
Task 1: ADD physical node guard to _findParameterNumberForPort
  - LOCATION: lib/services/auto_routing_service.dart:349
  - IMPLEMENT: Early return check for physical nodes (indices -2 and -3)
  - FOLLOW pattern: node_routing_cubit.dart:1191 (_isPhysicalNode helper)
  - INSERT: After line 349, before any slots array access
  - RETURN: -1 for physical nodes (they don't have parameters)

Task 2: ADD physical node guard to removeConnection extension
  - LOCATION: lib/services/auto_routing_service.dart:551
  - IMPLEMENT: Check for physical nodes before calling _findParameterNumberForPort
  - PATTERN: Skip parameter updates for physical connections
  - PRESERVE: Existing connection removal logic for algorithm nodes

Task 3: VERIFY other _findParameterNumberForPort call sites
  - CHECK: Lines 49, 114, 121 for existing physical node handling
  - VERIFY: Guards are in place before these calls
  - PATTERN: Consistent with isPhysicalConnection checks at line 109

Task 4: CREATE test for physical node connections
  - CREATE: test/services/auto_routing_service_physical_test.dart
  - IMPLEMENT: Test physical input to algorithm connections
  - IMPLEMENT: Test algorithm to physical output connections
  - VERIFY: No RangeError thrown with negative indices
  - FOLLOW pattern: test/services/auto_routing_service_test.dart structure
```

### Implementation Patterns & Key Details

```dart
// Pattern 1: Add guard clause to _findParameterNumberForPort
int _findParameterNumberForPort(int algorithmIndex, String portId, {required bool isOutput}) {
  // CRITICAL: Guard against physical nodes - they don't have parameters
  if (algorithmIndex == -2 || algorithmIndex == -3) {
    debugPrint('[AutoRoutingService] Physical node $algorithmIndex detected, no parameters to lookup');
    return -1; // Physical nodes don't have parameter numbers
  }
  
  final distingState = _cubit.state;
  
  if (distingState is! DistingStateSynchronized) {
    debugPrint('[AutoRoutingService] Not synchronized, using fallback parameter number');
    return isOutput ? 0 : 1; // Fallback
  }
  
  // SAFE: algorithmIndex is now guaranteed to be >= 0
  if (algorithmIndex >= distingState.slots.length) {
    debugPrint('[AutoRoutingService] Algorithm index $algorithmIndex out of bounds');
    return isOutput ? 0 : 1; // Fallback
  }
  
  // ... rest of existing implementation
}

// Pattern 2: Update removeConnection to handle physical nodes
Future<void> removeConnection({
  required int sourceAlgorithmIndex,
  required String sourcePortId,
  required int targetAlgorithmIndex,
  required String targetPortId,
}) async {
  debugPrint('[AutoRoutingService] Removing connection from $sourceAlgorithmIndex:$sourcePortId to $targetAlgorithmIndex:$targetPortId');

  // CRITICAL: Check for physical connections that don't need parameter updates
  final isPhysicalConnection = sourceAlgorithmIndex == -2 || sourceAlgorithmIndex == -3 || 
                              targetAlgorithmIndex == -2 || targetAlgorithmIndex == -3;
  
  if (isPhysicalConnection) {
    debugPrint('[AutoRoutingService] Physical connection detected, no parameters to clear');
    // Physical connections are hardware-managed, no parameter updates needed
    return;
  }

  // Find the parameter numbers for both ports (safe for algorithm nodes only)
  final targetParamNumber = _findParameterNumberForPort(
    targetAlgorithmIndex,
    targetPortId,
    isOutput: false,
  );

  final sourceParamNumber = _findParameterNumberForPort(
    sourceAlgorithmIndex,
    sourcePortId,
    isOutput: true,
  );
  
  // ... rest of existing parameter clearing logic
}
```

### Integration Points

```yaml
VALIDATION:
  - location: lib/util/routing_validator.dart
  - verify: Physical nodes handled in validateConnection method
  - pattern: Check for negative indices before validation

HIT_TESTING:
  - location: lib/cubit/node_routing_cubit.dart:994-1078
  - verify: getAlgorithmAtPosition handles physical nodes
  - pattern: Physical node bounds defined separately from slots

PORT_EXTRACTION:
  - location: lib/services/port_extraction_service.dart
  - verify: No slot access for physical nodes
  - pattern: Physical ports generated independently
```

## Validation Loop

### Level 1: Syntax & Style (Immediate Feedback)

```bash
# Run after implementing the fix
flutter analyze lib/services/auto_routing_service.dart
dart format lib/services/auto_routing_service.dart --set-exit-if-changed

# Expected: Zero errors, no formatting changes needed
```

### Level 2: Unit Tests (Component Validation)

```bash
# Run existing tests to ensure no regression
flutter test test/services/auto_routing_service_test.dart

# Run new physical node tests
flutter test test/services/auto_routing_service_physical_test.dart

# Expected: All tests pass, including new physical node tests
```

### Level 3: Integration Testing (System Validation)

```bash
# Manual test procedure:
# 1. Run the app with a connected Disting NT
flutter run

# 2. Navigate to routing canvas
# 3. Test physical input connection:
#    - Drag from I4 (physical input)
#    - Drop on any algorithm input (e.g., Lua Script V/Oct)
#    - Verify: Connection created without error toast

# 4. Test physical output connection:
#    - Drag from any algorithm output
#    - Drop on O1 (physical output)
#    - Verify: Connection created successfully

# 5. Test connection removal:
#    - Click on physical connection line
#    - Press delete/remove
#    - Verify: Connection removed without RangeError

# Expected: All operations complete without error toasts
```

### Level 4: Edge Case Validation

```bash
# Test boundary conditions
# 1. Connect all 12 physical inputs simultaneously
# 2. Connect all 8 physical outputs simultaneously
# 3. Create mixed physical/algorithm routing chains
# 4. Test undo/redo with physical connections
# 5. Save and reload preset with physical connections

# Expected: All operations stable, no RangeError exceptions
```

## Final Validation Checklist

### Technical Validation

- [ ] No `flutter analyze` errors in modified files
- [ ] All existing tests continue to pass
- [ ] New physical node tests pass
- [ ] No RangeError when accessing negative indices
- [ ] Physical connections create/remove successfully

### Feature Validation

- [ ] I1-I12 can connect to algorithm inputs without errors
- [ ] Algorithm outputs can connect to O1-O8 without errors
- [ ] Connections can be removed without error toasts
- [ ] Visual feedback remains correct for physical connections
- [ ] Routing state persists correctly across app restarts

### Code Quality Validation

- [ ] Guards added before all slots array access with negative indices
- [ ] Consistent pattern with existing physical node handling
- [ ] Clear debug messages for physical node detection
- [ ] No performance degradation from additional checks
- [ ] Comments explain why physical nodes need special handling

---

## Anti-Patterns to Avoid

- ❌ Don't use try-catch to handle expected negative indices
- ❌ Don't change the physical node index values (-2, -3)
- ❌ Don't attempt to create fake slot entries for physical nodes
- ❌ Don't skip debug logging for physical node detection
- ❌ Don't modify hardware bus assignments (1-12, 13-20)
- ❌ Don't break existing algorithm-to-algorithm routing