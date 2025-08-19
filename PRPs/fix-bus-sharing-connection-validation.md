name: "Fix Bus Sharing Connection Validation"
description: |
  Resolve incorrect validation of connections sharing the same bus, where connections are being marked as invalid (red) even when replace mode should allow safe bus sharing.

---

## Goal

**Feature Goal**: Fix connection validation logic to correctly handle bus sharing scenarios based on replace/add modes and execution order

**Deliverable**: Updated connection validation that properly considers replace mode and execution order when connections share buses

**Success Definition**: Connections that share the same bus are displayed correctly (green when valid, red only when truly conflicting)

## User Persona

**Target User**: Engineers using the routing canvas to create algorithm connections

**Use Case**: Creating multiple connections from different algorithm outputs that need to share the same bus

**User Journey**: 
1. User creates first connection from Algorithm A output to Algorithm B input (uses bus X)
2. User creates second connection from Algorithm C output (replace mode) to Algorithm D input  
3. Because C and D are at slots 3 and 4, they use bus X.
4. Connections should display as valid (green) because replace mode allows safe sharing

**Pain Points Addressed**: 
- False positive validation errors showing connections as invalid when they can safely share a bus
- Confusion about which connections are actually problematic vs. which are safe

## Why

- Bus sharing is a normal optimization that reduces bus usage
- Replace mode specifically allows multiple sources to use the same bus safely
- Current validation incorrectly marks all bus-sharing connections as invalid
- Current drawing system shows connections that aren't actually present
- This creates visual confusion and uncertainty about routing validity

## What

The system should validate bus sharing based on:
1. Replace mode settings on output algorithms
2. Execution order of algorithms (slot order)

### Success Criteria

- [ ] Connections sharing a bus with replace mode enabled display as valid (green)
- [ ] Only connections with slot order issues (output slot is greater than input algorithm slot) display as invalid (red)
- [ ] Execution order violations are properly detected
- [ ] All existing tests (that have conditions that support these requirements) pass
- [ ] Any tests that do not test valid conditions should be removed.

## All Needed Context

### Context Completeness Check

_This PRP provides complete context for implementing correct bus sharing validation. The core issue is that connections sharing a bus are incorrectly marked invalid when replace mode should allow safe sharing._

### Documentation & References

```yaml
- file: lib/ui/routing/connection_painter.dart:119-128
  why: Connection coloring logic that shows validation state visually
  pattern: Uses violatesExecutionOrder and isValid flags to determine colors
  gotcha: Currently shows red/orange for valid bus sharing scenarios

- file: lib/models/connection.dart:40-48
  why: violatesExecutionOrder getter determines if connection breaks slot order rules
  pattern: Checks sourceAlgorithmIndex >= targetAlgorithmIndex for algorithms
  gotcha: Physical nodes (index < 0) are exempt; needs bus sharing awareness

- file: lib/util/bus_dependency_graph.dart:244-271
  why: _areBusSharingConnectionsSafe has CORRECT bus sharing validation logic
  pattern: Checks replace mode and timing to allow safe bus reuse
  gotcha: This logic exists but isn't used for UI validation

- file: lib/cubit/node_routing_cubit.dart:1580-1630
  why: loadConnectionModes reads actual replace/add mode from parameters
  pattern: Updates connection.replaceMode based on algorithm output parameters
  gotcha: Must trigger revalidation after modes are loaded

- file: lib/cubit/node_routing_cubit.dart:855-970
  why: _reconstructConnectionsFromSlots rebuilds connections from preset data
  pattern: Matches outputs to inputs by bus number, determines replace mode
  gotcha: This is where connections get initially created with modes

- file: lib/services/auto_routing_service.dart:129-136
  why: Shows how bus assignment and initial validation happens
  pattern: Assigns bus numbers when connections are created
  gotcha: Sets replaceMode=false initially, updated later by loadConnectionModes
```

### Current Implementation Issues

```dart
// PROBLEM 1: violatesExecutionOrder doesn't handle Feedback algorithms
// Location: lib/models/connection.dart:40
bool get violatesExecutionOrder {
  // Missing: Check if source/target is Feedback Sender/Receiver
  // Should be: sourceSlot >= targetSlot EXCEPT for Feedback algorithms
  return sourceAlgorithmIndex >= targetAlgorithmIndex;
}

// PROBLEM 2: No bus sharing validation based on replace mode
// Location: lib/cubit/node_routing_cubit.dart after loadConnectionModes
// Missing: Check if multiple connections on same bus all have replace mode

// PROBLEM 3: isValid flag not updated after mode changes
// Location: Connection model has isValid but it's not refreshed
// When replace mode changes, connections sharing buses need revalidation
```

### Known Gotchas of our codebase

```dart
// CRITICAL: Slot execution order is 0→1→2→3→...→N
// Valid connection: source slot < target slot (signal flows forward)
// Invalid connection: source slot >= target slot (breaks causality)

// EXCEPTION: Feedback algorithms have special execution order rules
// GUIDs: "fbtx" (Feedback Send), "fbrx" (Feedback Receive)
// Feedback Send: must read from LOWER slot (source < Send's slot)
// Feedback Receive: must output to HIGHER slot (Receive's slot < target)
// The "teleport" happens internally between Send→Receive pairs

// CRITICAL: Replace mode parameter location varies by algorithm
// Must use _findModeParameterForOutput to locate the correct parameter
// Parameter value: 0 = Add mode, 1 = Replace mode

// CRITICAL: State is always up-to-date
// No timing gaps - all slot parameters are current
// loadConnectionModes should complete synchronously with state
```

## Implementation Blueprint

### Core Validation Logic Updates

Simple, consistent validation rules:

```dart
// Execution order validation (per connection):
// VALID: source slot < target slot (forward signal flow)
// INVALID: source slot >= target slot (violates causality)
// EXCEPTION: Feedback Sender/Receiver algorithms can bypass this

// Bus sharing validation (multiple connections on same bus):
// VALID: Multiple Add mode outputs → single input (signals sum)
// VALID: Single source → multiple targets (fan-out)
// REPLACE MODE: Disconnects all prior Add mode connections to that bus
// After a Replace, only subsequent connections are active on that bus
```

### Implementation Tasks (ordered by dependencies)

```yaml
Task 1: FIX lib/models/connection.dart violatesExecutionOrder
  - Base rule: sourceSlot >= targetSlot = invalid
  - NO exceptions for Feedback algorithms (they follow normal order)
  - Feedback Send reads normally, Feedback Receive outputs normally
  - The feedback loop is internal to the Send/Receive pair

Task 2: UPDATE lib/cubit/node_routing_cubit.dart loadConnectionModes
  - Ensure state is fully synchronized before validation
  - After updating replaceMode from parameters (line 1628)
  - Immediately call validateBusSharing() in same method
  - Emit single state update with all validation complete

Task 3: CREATE validateBusSharing method in node_routing_cubit.dart
  - Group connections by assignedBus
  - For each bus, sort connections by source slot order
  - Validation logic:
    - Multiple Add mode outputs to same bus: VALID (signals sum)
    - Replace mode output: invalidates prior connections on that bus
    - After Replace: only subsequent connections are valid
  - Mark connections as valid/invalid based on Replace mode boundaries

Task 4: REMOVE - Feedback algorithms follow normal execution order
  - No special handling needed for Feedback Send/Receive
  - They must follow slot order for their connections
  - The feedback happens internally between paired Send/Receive

Task 5: UPDATE tests for consistency
  - Review test/util/routing_validator_test.dart
  - Tests expecting bus sharing failure without replace mode: KEEP
  - Tests expecting failure with replace mode enabled: REMOVE/FIX
  - Add test cases for Feedback algorithm exceptions
  - Use best judgment, ask user if unclear
```

## Validation Gates

### Pre-Implementation Checks
- [ ] Run `flutter analyze` - zero issues required
- [ ] Document current failing case with screenshot
- [ ] Create branch: `fix-bus-sharing-validation`

### Post-Implementation Validation
- [ ] `flutter analyze` passes clean
- [ ] Updated tests pass (invalid tests removed/fixed)
- [ ] Manual test scenarios:
  
  **Scenario 1: Bus Sharing Between Algorithms**
  ```
  1. Create Algorithm A (slot 0) → Algorithm B (slot 1) on bus 21
  2. Create Algorithm C (slot 2, replace mode) → Algorithm D (slot 3) 
  3. System assigns bus 21 to second connection
  4. EXPECTED: Both connections show GREEN (valid)
  5. Toggle C to Add mode
  6. EXPECTED: Connection shows RED (conflict)
  7. Toggle back to Replace mode  
  8. EXPECTED: Connection returns to GREEN
  ```
  
  **Scenario 2: Feedback Loop Example**
  ```
  Signal flow with Feedback algorithms (Identifier = 1):
  - VCO (slot 0) → Aux 1
  - Feedback Receive (slot 1, ID=1) → Aux 1 (adds to VCO signal)
  - Delay (slot 2) reads Aux 1 → outputs Aux 2
  - Feedback Send (slot 3, ID=1) reads Aux 2 → internally sends to Receive ID=1
  - Reverb (slot 4) reads Aux 2 → outputs O1 & O2
  
  All connections follow normal slot order:
  - VCO (0) → Delay (2) via Aux 1: Valid (0 < 2)
  - Feedback Receive (1) → Delay (2) via Aux 1: Valid (1 < 2)
  - Delay (2) → Feedback Send (3) via Aux 2: Valid (2 < 3)
  - Delay (2) → Reverb (4) via Aux 2: Valid (2 < 4)
  
  The feedback loop is internal between Send/Receive, not visible as a connection
  ```
  
  **Scenario 3: Replace Chain to Physical Output**
  ```
  Preset: "Thorp Test" 
  Routing (all using bus 13 / Output 1):
  - Slot 0 (VCO): Input[1] → Output[13] (Add mode)
  - Slot 1 (Attenuverter): Input[13] → Output[13] (Replace mode)
  - Slot 2 (Delay): Input[13] → Output[13] (Replace mode)
  - Slot 3 (Reverb): Input[13] → Output[13,14] (Replace mode)
  
  EXPECTED: ALL connections show GREEN (valid replace chain)
  ACTUAL BUG: Attenuverter→O1, Delay→O1, Reverb→O1 show RED
  
  Why this is valid:
  - Sequential processing: slot 0 → 1 → 2 → 3
  - Each slot with Replace mode overwrites bus 13
  - No bus conflicts: each processes before the next
  ```

## Final Validation Checklist

- [ ] Source slot < target slot = GREEN (forward flow)
- [ ] Source slot >= target slot = RED (violates order)
- [ ] Feedback algorithms follow normal slot order rules
- [ ] Multiple Add mode connections to same bus = GREEN (signals sum)
- [ ] Replace mode disconnects prior connections on that bus
- [ ] Connections before a Replace mode = RED (disconnected)
- [ ] Connections after a Replace mode = GREEN (active)
- [ ] Fan-out (one source → many targets) = always GREEN
- [ ] Mode toggle triggers immediate revalidation
- [ ] State updates are atomic (no intermediate invalid states)

## Implementation Notes

**Root Cause**: Two separate issues:
1. Execution order only checks slot indices, not considering Feedback algorithms
2. Bus sharing validation doesn't check if all connections have replace mode enabled

**Solution - Simple and Consistent**:
1. Execution order: sourceSlot < targetSlot is valid (no exceptions)
2. Bus sharing: Add mode signals sum, Replace mode disconnects prior connections
3. Replace mode creates a boundary - only connections after it are active
4. State is always current - no async timing issues to handle

**Key Principles**:
- Correctness over performance (don't optimize prematurely)
- Simple, consistent rules matching hardware behavior
- State updates are atomic - no intermediate invalid states
- Trust the hardware developer's consistency
