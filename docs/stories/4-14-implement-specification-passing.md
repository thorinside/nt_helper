# Story 4.14: Implement Specification Passing Through MCP and Controller

**Status:** In Progress
**Priority:** Critical
**Epic:** Epic 4 - MCP Integration & Improvements
**Assignee:** Amelia (Dev Agent)

---

## Summary

**Critical Bug:** Specifications are extracted from MCP requests but **never passed to the hardware**, causing all multi-channel algorithms to use default specifications.

**Impact:**
- Euclidean with Channels=4 returns same parameters as Channels=1
- Clock Divider with Channels=8 returns same parameters as Channels=2
- All specification-dependent algorithms fail to instantiate with correct specs
- Story 4.13 investigation impossible without this fix

**Root Cause:**
- `Algorithm` class lacks `specifications` field
- `DistingController.addAlgorithm()` doesn't accept specifications
- `newWithAlgorithms()` extracts specs (line 2003) but doesn't use them (line 2050)

---

## Acceptance Criteria

1. **AC-1:** `Algorithm` class includes `specifications` field
   - Type: `List<int>` (specification values)
   - Included in copyWith() method
   - Properly serialized/deserialized

2. **AC-2:** `DistingController.addAlgorithm()` accepts and passes specifications
   - Signature: `Future<void> addAlgorithm(Algorithm algorithm)` with specs in Algorithm
   - Controller extracts specs from Algorithm and passes to hardware via SysEx
   - Specifications stored with algorithm state for future queries

3. **AC-3:** MCP `newWithAlgorithms()` properly uses specifications
   - Extracts specifications from request (already done at line 2003)
   - Creates Algorithm with specifications
   - Passes to controller correctly

4. **AC-4:** MCP `addAlgorithm()` tool accepts and uses specifications
   - New parameter: `specifications` (list of integers)
   - Validates specification count matches algorithm requirements
   - Creates Algorithm with specs and passes to controller

5. **AC-5:** Bug fix in `newWithAlgorithms()` parameter handling
   - Line 2089: Fix `paramIndex` to `pInfo.parameterNumber` (from Story 4.12)
   - Ensure all parameter operations use correct parameter numbers

6. **AC-6:** All tests pass, parameter operations work with specifications
   - Unit tests for Algorithm with specs
   - Integration tests with Euclidean (Channels=1, 4, 8)
   - Verify hardware returns different parameters for different specs
   - No regressions in existing functionality

---

## Technical Details

### Current Broken Code

**disting_tools.dart - newWithAlgorithms() (lines 2003-2050):**
```dart
// Extract specifications (done correctly)
final List<dynamic>? specifications = algoSpec['specifications'] as List<dynamic>?;

// Validate them (done correctly)
if (specifications != null && specifications.isNotEmpty) {
  // Just validates, doesn't use them
}

// But then IGNORES them when creating Algorithm (BUG!)
final algorithm = Algorithm(
  algorithmIndex: -1,
  guid: resolvedGuid,
  name: algorithmMetadata.name,
  // ← No specifications field, can't pass them!
);
await _controller.addAlgorithm(algorithm);
```

**disting_tools.dart - newWithAlgorithms() (lines 2089-2092):**
```dart
// Another bug from Story 4.12 - not fixed in this method
final int? liveRawValue = await _controller.getParameterValue(
  i,
  paramIndex,  // ← WRONG! Should be pInfo.parameterNumber
);
```

### Solution

1. **Extend Algorithm class** to include specifications:
```dart
class Algorithm {
  final int algorithmIndex;
  final String guid;
  final String name;
  final List<int> specifications;  // ← NEW

  Algorithm({
    required this.algorithmIndex,
    required this.guid,
    required this.name,
    this.specifications = const [],  // ← Default empty
  });

  Algorithm copyWith({int? algorithmIndex, List<int>? specifications}) {
    return Algorithm(
      algorithmIndex: algorithmIndex ?? this.algorithmIndex,
      guid: guid,
      name: name,
      specifications: specifications ?? this.specifications,  // ← Include in copyWith
    );
  }
}
```

2. **Update Controller** to pass specifications to hardware:
```dart
// In DistingCubit or controller implementation
// When calling _distingManager.requestAddAlgorithm():
await _distingManager.requestAddAlgorithm(
  algorithmInfo,
  algorithm.specifications.isNotEmpty
    ? algorithm.specifications
    : algorithmInfo.specifications.map((s) => s.defaultValue).toList(),
);
```

3. **Fix newWithAlgorithms()** to use specifications:
```dart
// Convert dynamic list to int list
final List<int> specs = specifications != null
  ? specifications.whereType<int>().toList()
  : [];

final algorithm = Algorithm(
  algorithmIndex: -1,
  guid: resolvedGuid,
  name: algorithmMetadata.name,
  specifications: specs,  // ← Pass specifications!
);
```

4. **Fix parameter numbering bug** in newWithAlgorithms():
```dart
final int? liveRawValue = await _controller.getParameterValue(
  i,
  pInfo.parameterNumber,  // ← Use actual parameter number from hardware
);
```

---

## Files to Modify

- `lib/domain/disting_nt_sysex.dart` - Add specifications to Algorithm class
- `lib/mcp/tools/disting_tools.dart` - Fix newWithAlgorithms() and addAlgorithm() tools
- `lib/cubit/disting_cubit.dart` - Ensure specifications are passed to controller
- Any other controller implementations that need to handle specifications

---

## Testing Plan

1. **Unit Tests:**
   - Algorithm class with/without specifications
   - Controller properly extracts and passes specs

2. **Integration Tests:**
   - Create Euclidean with Channels=1, verify parameters
   - Create Euclidean with Channels=4, verify different parameters returned
   - Create Clock Divider with Channels=2 vs Channels=8
   - Verify specifications survive preset save/load

3. **Verification:**
   - Hardware returns different parameter counts for different specs
   - Parameter names include correct channel prefixes (1:, 2:, 3:, etc.)
   - All parameter operations use correct parameter numbers

---

## Story Dependencies

- Story 4.12: Fix Parameter Numbering (prerequisite - bug still exists in this code)
- Story 4.13: Specification-Parameter Mismatch (depends on this fix to investigate)

---

## Discovery Context

**Found during:** Story 4.13 investigation with hardware testing
**Evidence:**
- Euclidean Channels=1 and Channels=4 both return 15 parameters (should be different)
- Code extracts specifications but never passes them to hardware
- Algorithm class has no field to store specifications for passing
