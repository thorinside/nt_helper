# Story 4.13: Resolve Specification-Based Parameter Count Mismatch

**Status:** Approved
**Priority:** Critical
**Epic:** Epic 4 - MCP Integration & Improvements
**Assignee:** TBD

---

## Summary

**Critical Discovery:** Parameter documentation (from bundled metadata) does NOT match the actual parameters returned by the hardware when algorithms are instantiated with different specifications.

When an algorithm with specifications (e.g., Clock Divider with "Channels" specification) is added to a slot, the firmware should generate a different number of parameters based on the specification values. However:

1. **Documentation claims:** Clock Divider with Channels=2 should have ~21 parameters (1 shared + 10 per-channel × 2)
2. **Hardware returns:** Only 13 parameters (regardless of Channels specification)
3. **Metadata includes:** No specification tracking, no per-channel parameter replication info

This breaks LLM usability because:
- Documentation says "parameter 50 is Channel 5 Type"
- Hardware only has parameters 0-12
- Parameter numbers in docs don't exist in the actual algorithm
- LLM gets confused, makes invalid parameter references

---

## Root Cause Analysis

### Issue 1: Documentation vs Firmware Mismatch
The bundled algorithm metadata (`docs/algorithms/*.json`) documents parameters using a **template format** with `is_per_channel: true/false`:

```json
{
  "name": "Type",
  "is_per_channel": true  // This parameter repeats for each channel
}
```

But the firmware returns **actual parameter list** for a specific instantiation:
```json
{
  "parameter_number": 2,
  "name": "1:Type"  // Only Channel 1 Type
}
```

### Issue 2: Specification Values Not Tracked
When an algorithm is added to a slot with specifications:
- Cubit knows the specifications were used
- But MCP responses don't include specification values
- Metadata service can't correlate "this algorithm has parameters 0-12 because specs were [2,...]"

### Issue 3: Per-Channel Parameter Expansion Not Documented
The metadata template format doesn't clearly indicate **how many times** a per-channel parameter appears:

```json
// Current format (ambiguous)
{
  "name": "Type",
  "is_per_channel": true
}

// Missing info:
// - Will this create parameters named "1:Type", "2:Type", ..., "N:Type"?
// - How many channels? (1-8? 1-14? 1-16?)
// - What's the actual parameter_number sequence?
```

### Issue 4: Dynamic Parameter Count Not Captured
Once an algorithm is instantiated with specs, the firmware locks the parameter count:
- Clock Divider with Channels=2: parameters 0-20 (fixed)
- Clock Divider with Channels=8: parameters 0-80 (fixed)
- But our MCP tools return the same parameter set for both!

---

## Current Behavior (Broken)

### Hardware Reality (2025-11-08 Testing)

**Clock Divider (clkd) with Channels=2:**
- Hardware returns: 13 parameters (0-12)
- Parameter names: Bypass, Reset input, 1:Type, 1:Divisor, 1:Divisor, 1:Divisor, 1:Enable, 1:Input, 1:Reset input, 1:Output, 1:Output mode, 1:ES-5 Expander, 1:ES-5 Output
- Missing: Channel 2 parameters (should have 2:Type, 2:Divisor, etc.)

**Clock Divider (clkd) with Channels=8:**
- Hardware returns: 13 parameters (0-12) **← SAME AS ABOVE!**
- Should have ~81 parameters but only 13 returned
- Channel 2-8 parameters completely missing

**Clock Multiplier (clkm) with no specifications:**
- Hardware returns: 9 parameters (0-8)
- Matches expected count (no per-channel parameters)

### MCP Response Example

```json
{
  "slots": [
    {
      "algorithm": {
        "guid": "clkd",
        "name": "Clock divider"
      },
      "parameters": [
        {
          "parameter_number": 0,
          "name": "Bypass",
          "value": 0
        },
        {
          "parameter_number": 2,
          "name": "1:Type",
          "value": 0
        }
        // Only 13 parameters returned
        // No way to know this was Channels=2 (vs Channels=8)
        // No way to know if Channel 2 parameters exist elsewhere
      ]
    }
  ]
}
```

---

## Acceptance Criteria

1. **AC-1:** MCP `getCurrentPreset()` includes specification values for each algorithm in its response
   - Format: `"specifications": [{"name": "Channels", "value": 2}]` for each slot algorithm

2. **AC-2:** Parameter documentation includes expected parameter count per specification value
   - New metadata field: `"parameter_count_by_spec": {"channels_2": 21, "channels_8": 81}`
   - Or: Per-channel parameters clearly marked with expansion multiplier

3. **AC-3:** Metadata service tracks which specifications were used to instantiate each algorithm
   - Cubit/Controller stores specification values with algorithm state
   - MCP tools can query this information

4. **AC-4:** MCP tools validate parameter_number against known count for actual specs
   - If LLM requests parameter 50 but spec only generates 21 parameters → clear error
   - Error message: "Parameter 50 invalid for Clock Divider with Channels=2 (max: 21)"

5. **AC-5:** Document updated algorithm metadata schema to support specification-dependent parameter lists
   - Either template-based expansion rules
   - Or pre-generated parameter lists for each spec combination

6. **AC-6:** All tests pass, no regression in parameter operations

---

## Technical Details

### Hardware Behavior Questions (Investigation Needed)

1. **Why does hardware return only 13 parameters for both Channels=2 and Channels=8?**
   - Is the firmware only returning Channel 1 parameters?
   - Are channels 2-8 parameters accessed differently?
   - Is there a separate query to get per-channel parameter info?

2. **How does the firmware track parameter numbers across channels?**
   - Are they: `0=shared, 1-10=ch1, 11-20=ch2, 21-30=ch3...`?
   - Or are they: `0=shared, 1-10=ch1, 1-10=ch2, 1-10=ch3...` (parameter numbers repeat)?
   - Or something else?

3. **What's the relationship between parameter_number in responses and actual firmware indexing?**
   - The "1:Type" naming suggests per-channel, but parameter_number=2 for all of them?

### Data Flow That Needs Fixing

```
User creates preset with "Clock Divider, Channels=2"
  ↓
Cubit calls controller.addAlgorithm(guid="clkd", specs=[2])
  ↓
Firmware instantiates algorithm with 21 parameters (1 + 10×2)
  ↓
Cubit queries getParametersForSlot() → ✓ Gets 13 params (partial!)
  ↓
MCP tool getCurrentPreset()
  - Returns 13 parameters
  - No way to know specs were [2]
  - LLM can't correlate to documentation
  - If LLM queries parameter 15, fails with "out of bounds"
```

---

## Proposed Solution Outline

### Phase 1: Investigation (This Task)
- [ ] Confirm hardware behavior with actual testing
- [ ] Determine if firmware has API to query all channel parameters
- [ ] Map parameter_number scheme for multi-channel algorithms
- [ ] Document findings in detailed technical report

### Phase 2: Metadata Enhancement
- [ ] Update algorithm JSON schema to include parameter count per spec
- [ ] Generate parameter count matrix for all spec combinations
- [ ] Document which parameter numbers correspond to which channels

### Phase 3: MCP Response Enhancement
- [ ] Include specifications in slot data: `"specifications": [{"name": "Channels", "value": 2}]`
- [ ] Add parameter count validation: `"total_parameters": 21`
- [ ] Add metadata linking: `"parameter_count_specification": "Channels=2"`

### Phase 4: Controller Enhancement
- [ ] Store specification values with algorithm state
- [ ] Support parameter queries with spec awareness
- [ ] Add validation: reject parameter_number > known_count

### Phase 5: Testing & Documentation
- [ ] Unit tests for spec-aware parameter validation
- [ ] Integration tests with multi-channel algorithms
- [ ] Update MCP documentation with spec examples
- [ ] Add warnings about parameter availability based on specs

---

## Testing Notes

**Tested Algorithms (2025-11-08):**

| Algorithm | GUID | Specs | Returned Params | Expected | Status |
|-----------|------|-------|-----------------|----------|--------|
| Clock Divider | clkd | Channels=2 | 13 | ~21 | ❌ MISMATCH |
| Clock Divider | clkd | Channels=8 | 13 | ~81 | ❌ MISMATCH |
| Clock Multiplier | clkm | (none) | 9 | 9 | ✅ OK |
| Elements | nt_elements | (none) | 30 | 30 | ✅ OK |

---

## Story Dependencies

- Story 4.12 (Fix Parameter Numbering) - Prerequisite completed
- Requires hardware investigation and firmware API research

---

## Questions for Hardware Team

1. Does the firmware support querying all per-channel parameters for multi-channel algorithms?
2. Are per-channel parameters only accessible via separate query mechanism?
3. What is the parameter_number scheme for channels (sequential, repeated, sparse)?
4. Are specifications "read-back" available after algorithm is instantiated?
