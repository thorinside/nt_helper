# Story 4.12: Fix Parameter Numbering Mismatch in MCP Tools

**Status:** Approved
**Priority:** High
**Epic:** Epic 4 - MCP Integration & Improvements
**Assignee:** Amelia (Dev Agent)

---

## Summary

MCP tools and internal parameter handling confuse parameter **array indices** with **actual parameter numbers**. When an algorithm is loaded into a slot, the hardware returns `ParameterInfo` objects with correct `parameterNumber` fields, but the MCP tools use array indices instead. This causes parameter data returned by MCP tools to not match the bundled documentation.

**Root Cause:** In `lib/mcp/tools/disting_tools.dart:108`, the code uses `paramIndex` (array position) instead of `pInfo.parameterNumber` when building parameter metadata for MCP responses.

---

## Acceptance Criteria

1. **AC-1:** MCP tool `getCurrentPreset()` returns `parameter_number` matching the actual `pInfo.parameterNumber` from hardware, not array position
2. **AC-2:** MCP tool `getSlot()` returns correct parameter numbers for all parameters in the slot
3. **AC-3:** MCP tool `getParameter()` returns correct parameter number in response
4. **AC-4:** Mapping operations (CV, MIDI, i2c) use correct parameter numbers when stored/retrieved
5. **AC-5:** Parameter value lookups in controller work correctly with actual parameter numbers
6. **AC-6:** All tests pass, including new tests validating parameter number correctness

---

## Tasks

### Task 1: Fix MCP Tools Parameter Numbering
- Update `disting_tools.dart` to use `pInfo.parameterNumber` instead of `paramIndex`
- Update all parameter response builders (getCurrentPreset, getSlot, getParameter)
- Ensure parameter_number in all JSON responses matches hardware values

### Task 2: Update Controller Method Signatures (if needed)
- Review `disting_controller.dart` to ensure it doesn't assume array-based indexing
- Validate that `getParameterValue()` and `updateParameterValue()` work with actual parameter numbers

### Task 3: Write Tests
- Test that parameter numbers in responses match actual hardware values
- Test parameter lookup by actual parameter number vs array index
- Test parameter updates use correct parameter numbers

### Task 4: Validate with Real Hardware
- Run on connected device and verify parameter data matches documentation
- Test parameter mappings with actual parameter numbers
- Verify preset save/load cycle preserves correct parameter numbers

---

## Technical Context

### Current Implementation (Broken)
```dart
// disting_tools.dart:95-108
for (int paramIndex = 0; paramIndex < parameterInfos.length; paramIndex++) {
  final pInfo = parameterInfos[paramIndex];
  // ...
  final paramData = {
    'parameter_number': paramIndex,  // ❌ WRONG: Uses array index
    // ...
  };
}
```

### Correct Implementation
```dart
// Should be:
'parameter_number': pInfo.parameterNumber,  // ✅ Use actual parameter number
```

### Related Code Locations
- `lib/mcp/tools/disting_tools.dart:74-180` - getCurrentPreset() and other preset operations
- `lib/mcp/tools/algorithm_tools.dart` - Algorithm detail responses
- `lib/services/disting_controller.dart` - Controller interface and parameter operations
- `lib/cubit/disting_cubit.dart` - State management for slots and parameters

---

## Dev Agent Record

### Context Reference
None yet (will update after investigation)

### Notes
- Parameter numbers are 0-based, matching array indices only by coincidence
- Hardware uses true parameter numbers; array order can vary
- This fix affects all parameter-related MCP operations
