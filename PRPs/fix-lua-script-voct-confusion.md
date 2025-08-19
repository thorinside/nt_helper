name: "Fix LUA Script V/Oct Input/Output Confusion"
description: |

---

## Goal

**Feature Goal**: Fix the LUA Script algorithm's confusing V/Oct parameter display where input appears on output side and output appears on input side of the algorithm node.

**Deliverable**: Corrected port classification logic that properly disambiguates parameters with identical names based on their intended direction (input vs output).

**Success Definition**: LUA Script algorithm nodes display V/Oct inputs on the left side and V/Oct outputs on the right side, matching user expectations and system conventions.

## User Persona

**Target User**: Eurorack musicians and sound designers using Disting NT hardware

**Use Case**: Routing audio/CV signals through LUA Script algorithms for custom processing

**User Journey**: 
1. User adds LUA Script algorithm to preset
2. User sees algorithm node with clearly labeled inputs (left) and outputs (right)
3. User drags connections from/to appropriate ports without confusion
4. System correctly routes signals based on port direction

**Pain Points Addressed**: 
- V/Oct input appearing on output side causes incorrect routing attempts
- V/Oct output appearing on input side breaks signal flow expectations
- Visual confusion leads to routing errors and user frustration

## Why

- Users expect consistent UI conventions where inputs are on the left and outputs on the right
- Current bug causes routing errors that can damage audio equipment (sending outputs to inputs)
- Fixing this improves usability and prevents potential hardware issues
- Maintains consistency with all other algorithm node displays in the system

## What

The system incorrectly classifies LUA Script algorithm parameters when they have identical names (both called "V/Oct"), causing the input port to appear on the output side and vice versa. This occurs due to mismatched classification logic between PortExtractionService and AutoRoutingService.

### Success Criteria

- [ ] LUA Script V/Oct input parameters appear on left side of algorithm node
- [ ] LUA Script V/Oct output parameters appear on right side of algorithm node
- [ ] AutoRoutingService correctly identifies parameter numbers for duplicate-named ports
- [ ] All existing routing functionality continues to work for other algorithms
- [ ] No regression in parameter value assignments or routing connections

## All Needed Context

### Context Completeness Check

_This PRP contains all information needed to fix the V/Oct confusion issue including exact code locations, logic corrections, and test validation._

### Documentation & References

```yaml
# MUST READ - Include these in your context window
- file: lib/services/port_extraction_service.dart
  why: Contains port classification logic that correctly identifies input/output ports
  pattern: _isInputParameterFromSlot() and _isOutputParameterFromSlot() methods
  gotcha: Uses defaultValue ranges to classify ports (inputs: 1-12, 21-28; outputs: 13-20)

- file: lib/services/auto_routing_service.dart
  why: Contains the bug - incorrect parameter classification and type checking
  pattern: _findParameterNumberForPort() method with bus value range checks
  gotcha: Lines 455-472 have mismatched logic with PortExtractionService

- file: test/services/auto_routing_service_test.dart
  why: Contains test case demonstrating the V/Oct parameter scenario
  pattern: Test "handles Lua Script with V/Oct parameter" 
  gotcha: Shows parameter 31 "V/Oct" with defaultValue 16 (Output 4)

- file: lib/models/algorithm_metadata.dart
  why: Defines AlgorithmMetadata structure with parameters and ports
  pattern: AlgorithmParameter class with name, defaultValue, unit fields
  gotcha: Parameters can have identical names but different default values

- file: docs/algorithms/lua_.json
  why: Static definition of LUA Script algorithm
  pattern: Empty input_ports and output_ports arrays
  gotcha: Dynamic parameters come from device sync, not static definition

- url: https://github.com/flutter/flutter/issues/85684
  why: Flutter best practices for handling duplicate keys/identifiers
  critical: Use unique composite keys when disambiguating duplicate names
```

### Current Codebase tree (run `tree` in the root of the project) to get an overview of the codebase

```bash
# Key directories for this fix
lib/
├── services/
│   ├── auto_routing_service.dart          # NEEDS FIX: Parameter classification
│   ├── port_extraction_service.dart       # Reference: Correct classification logic
│   └── algorithm_metadata_service.dart    # Algorithm data management
├── models/
│   ├── algorithm_metadata.dart            # Data structures
│   ├── algorithm_parameter.dart           # Parameter definitions
│   └── algorithm_port.dart                # Port definitions
├── ui/
│   └── routing/
│       ├── algorithm_node_widget.dart     # Visual node rendering
│       └── routing_canvas.dart            # Canvas management
└── cubit/
    └── node_routing_cubit.dart           # State management
test/
└── services/
    └── auto_routing_service_test.dart    # Test demonstrating issue
```

### Desired Codebase tree with files to be added and responsibility of file

```bash
# No new files needed - only modifications to existing files
lib/
├── services/
│   ├── auto_routing_service.dart          # MODIFIED: Fixed parameter classification
PRPs/
├── ai_docs/
│   └── routing_bus_classification.md      # NEW: Document bus value ranges for future reference
```

### Known Gotchas of our codebase & Library Quirks

```dart
// CRITICAL: Bus value ranges differ between input and output classification
// Input buses: 1-12 (physical inputs)
// Output buses: 13-20 (physical outputs) 
// Aux buses: 21-28 (can be inputs OR outputs depending on context)

// GOTCHA: Parameter sanitization must be consistent
// "V/Oct" -> "v_oct" (lowercase, special chars to underscore)

// QUIRK: Parameters with same name can have different defaultValues
// This determines their input/output classification
```

## Implementation Blueprint

### Data models and structure

No new data models needed - existing AlgorithmParameter and AlgorithmPort structures are sufficient.

### Implementation Tasks (ordered by dependencies)

```yaml
Task 1: FIX lib/services/auto_routing_service.dart parameter classification
  - LOCATE: _findParameterNumberForPort() method (lines 430-480)
  - FIX: Lines 455-458 bus value range checks to match PortExtractionService
  - CHANGE: Output check from "13-28" to "13-20"
  - CHANGE: Input check from "0-12" to "(1-12) || (21-28)"
  - TEST: Run auto_routing_service_test.dart to verify fix

Task 2: REMOVE type checking for exact name matches
  - LOCATE: Lines 460-472 in _findParameterNumberForPort()
  - REMOVE: Input/output type validation when sanitizedParamName == portId
  - KEEP: Bus parameter validation (unit check)
  - RATIONALE: Exact name matches should always be used regardless of type
  - TEST: Verify V/Oct parameters are found correctly

Task 3: CREATE PRPs/ai_docs/routing_bus_classification.md
  - DOCUMENT: Bus value ranges and their meanings
  - INCLUDE: Input (1-12), Output (13-20), Aux (21-28) classifications
  - EXPLAIN: How PortExtractionService and AutoRoutingService should align
  - PURPOSE: Prevent future classification mismatches

Task 4: UPDATE test coverage
  - VERIFY: Existing test "handles Lua Script with V/Oct parameter" passes
  - ADD: Test case for algorithms with duplicate parameter names
  - ENSURE: Both input and output V/Oct parameters are found correctly
  - CHECK: No regression in other algorithm routing tests
```

### Implementation Patterns & Key Details

```dart
// Task 1: Fix parameter classification in auto_routing_service.dart
// BEFORE (incorrect):
final isParamOutput = param.defaultValue >= 13 && param.defaultValue <= 28;
final isParamInput = param.defaultValue >= 0 && param.defaultValue <= 12;

// AFTER (correct - matching PortExtractionService):
final isParamOutput = param.defaultValue >= 13 && param.defaultValue <= 20;
final isParamInput = (param.defaultValue >= 1 && param.defaultValue <= 12) || 
                     (param.defaultValue >= 21 && param.defaultValue <= 28);

// Task 2: Remove type checking for exact matches
// BEFORE (with type checking):
if (sanitizedParamName == portId) {
  final unit = param.getUnitString(units) ?? '';
  final isBusParam = unit == 'bus' || (param.unit == 1 && param.max >= 28);
  if (!isBusParam) continue;
  
  // Type checking that causes V/Oct confusion
  if (isOutput && isParamOutput) {
    debugPrint('[AutoRoutingService] Exact match...');
    return param.parameterNumber;
  } else if (!isOutput && isParamInput) {
    debugPrint('[AutoRoutingService] Exact match...');
    return param.parameterNumber;
  }
  // Falls through if types don't match - THIS IS THE BUG
}

// AFTER (without type checking for exact matches):
if (sanitizedParamName == portId) {
  final unit = param.getUnitString(units) ?? '';
  final isBusParam = unit == 'bus' || (param.unit == 1 && param.max >= 28);
  
  if (!isBusParam) continue;
  
  // If names match exactly, use this parameter regardless of type
  debugPrint('[AutoRoutingService] Exact match: Found parameter "${param.name}" (#${param.parameterNumber}) for port "$portId"');
  return param.parameterNumber;
}
```

### Integration Points

```yaml
DATABASE:
  - No database changes needed

CONFIG:
  - No configuration changes needed

ROUTES:
  - No API route changes needed

STATE_MANAGEMENT:
  - NodeRoutingCubit will automatically use corrected parameter lookup
  - No changes needed to cubit logic
```

## Validation Loop

### Level 1: Syntax & Style (Immediate Feedback)

```bash
# Run after modifications
flutter analyze

# Expected: Zero errors. If errors exist, fix before proceeding.
```

### Level 2: Unit Tests (Component Validation)

```bash
# Test the specific fix
flutter test test/services/auto_routing_service_test.dart

# Test related services
flutter test test/services/port_extraction_service_test.dart

# Full service test suite
flutter test test/services/

# Expected: All tests pass, especially "handles Lua Script with V/Oct parameter"
```

### Level 3: Integration Testing (System Validation)

```bash
# Run the app and test routing canvas
flutter run

# Manual testing steps:
# 1. Add LUA Script algorithm to preset
# 2. Verify V/Oct input appears on LEFT side
# 3. Verify V/Oct output appears on RIGHT side
# 4. Create routing connections to/from V/Oct ports
# 5. Save preset and reload to verify persistence

# Test with hardware if available:
# 1. Connect to Disting NT via MIDI
# 2. Load preset with LUA Script algorithm
# 3. Verify routing matches visual display
```

### Level 4: Creative & Domain-Specific Validation

```bash
# Visual regression testing
# Take screenshots before and after fix
# Compare algorithm node layouts

# Test with various LUA scripts that expose different parameters
# Verify all parameter types are correctly positioned

# Test edge cases:
# - Algorithms with 3+ parameters with same name
# - Parameters with special characters in names
# - Dynamic parameter updates from device
```

## Final Validation Checklist

### Technical Validation

- [ ] All 4 validation levels completed successfully
- [ ] flutter analyze shows zero warnings/errors
- [ ] All tests pass: `flutter test`
- [ ] Manual testing confirms V/Oct ports appear on correct sides

### Feature Validation

- [ ] LUA Script V/Oct inputs appear on left side of node
- [ ] LUA Script V/Oct outputs appear on right side of node
- [ ] Routing connections work correctly with fixed ports
- [ ] No regression in other algorithm displays
- [ ] Parameter values are correctly assigned

### Code Quality Validation

- [ ] Changes minimal and focused on the specific issue
- [ ] Debug print statements provide clear diagnostics
- [ ] Code follows existing patterns in codebase
- [ ] Documentation added for bus value ranges

### Documentation & Deployment

- [ ] Bus classification documentation created
- [ ] Test coverage includes duplicate name scenarios
- [ ] No breaking changes to existing functionality

---

## Anti-Patterns to Avoid

- ❌ Don't change the PortExtractionService logic (it's correct)
- ❌ Don't modify algorithm metadata files directly
- ❌ Don't add complex disambiguation logic when simple fix works
- ❌ Don't change UI rendering logic (issue is in parameter lookup)
- ❌ Don't break existing routing for other algorithms
- ❌ Don't ignore the Aux bus range (21-28) in input classification