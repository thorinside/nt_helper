# Story 4.13: Resolve Specification-Based Parameter Count Mismatch

**Status:** Approved
**Updated:** 2025-11-08 - Critical finding: Parameter names are NOT unique per specification
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

### Issue 5: Parameter Names Are NOT Unique (Critical Blocker!)
**Discovered 2025-11-08:** The firmware returns duplicate parameter names:

Clock Divider Channel 1 parameters:
```json
{
  "parameter_number": 3,
  "parameter_name": "1:Divisor",
  "min": 1,
  "max": 32
},
{
  "parameter_number": 4,
  "parameter_name": "1:Divisor",  // ← DUPLICATE NAME!
  "min": 0,
  "max": 5
},
{
  "parameter_number": 5,
  "parameter_name": "1:Divisor",  // ← DUPLICATE NAME!
  "min": 0,
  "max": 9
}
```

**Impact on parameter-by-name solution:**
- `setParameterValue(parameter_name="1:Divisor", ...)` is **ambiguous**
- Current code returns error: "Parameter name is ambiguous. Please use parameter_number." (disting_tools.dart:340)
- **But parameter_number doesn't exist for this instantiation!**
- LLM is stuck: can't use names (ambiguous) and can't use numbers (don't exist)

This means the original parameter-by-name solution **will not work** for multi-channel algorithms!

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

1. **AC-1:** MCP `getCurrentPreset()` includes specification values for each slot
   - Format: `"specifications": [{"name": "Channels", "value": 2}]`
   - This is REQUIRED (not optional) for understanding available parameters
   - Specification format matches what was used to instantiate the algorithm

2. **AC-2:** MCP `getCurrentPreset()` includes total parameter count hint
   - Field: `"total_parameters": 13` (actual count returned by hardware)
   - Helps LLM understand if any parameters might be missing due to firmware limitations

3. **AC-3:** `docs/mcp-api-guide.md` documents specification-dependent parameter behavior
   - Explain that parameter_number is the only unique identifier
   - Show real example: Clock Divider with duplicate "1:Divisor" names
   - Document that parameter_name lookup fails for duplicate names
   - Recommended approach: Use parameter_number WITH specification context
   - Warning: Some specifications may cause firmware to return fewer parameters than documented

4. **AC-4:** MCP tools include specifications in responses where relevant
   - `getCurrentPreset()` includes `specifications` per slot
   - `getSlot()` includes `specifications` if added
   - Enables LLM to make spec-aware parameter decisions

5. **AC-5:** Parameter lookup logic handles ambiguous names gracefully
   - When duplicate names detected, error message includes parameter_number for each
   - Helps LLM understand it must use parameter_number to disambiguate
   - Example: "Parameter '1:Divisor' found at numbers 3, 4, 5. Use parameter_number to disambiguate."

6. **AC-6:** All tests pass, documentation complete, no regressions
   - Unit tests verify specification tracking
   - Integration tests with multi-channel algorithms
   - Documentation accurate and comprehensive

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

### Critical Realization: Previous Solution is Blocked

Earlier analysis proposed using **parameter names** for specification-agnostic operations. **This does not work** because:

1. Parameter names are NOT unique when specifications create duplicates (1:Divisor, 1:Divisor, 1:Divisor)
2. Current code rejects ambiguous names: "Please use parameter_number" (disting_tools.dart:340)
3. But parameter_number is specification-dependent and unreliable
4. **Result: LLM cannot reference parameters in multi-channel algorithms at all**

### Real Solution: Accept parameter_number + Include Specifications

Since parameter names alone cannot work, we must:
1. Accept that **parameter_number is the only unique identifier**
2. **Always provide specification values** so LLM knows which parameters exist
3. Use parameter_number WITH specification context

**New Design:**
- Include `specifications` in MCP responses (required, not optional)
- Include `total_parameters` count based on actual specs
- Validate parameter_number against expected count
- Document which spec values enable which parameter numbers

### Phase 1: Investigation & Documentation (This Task - COMPLETED)
- [x] Confirm hardware behavior with actual testing
- [x] Discover that parameter numbers are spec-dependent
- [x] **Discover critical blocker: Parameter names are NOT unique for multi-channel algorithms**
- [x] Understand current API design philosophy
- [x] Determine that parameter_number is the only reliable identifier
- [x] Document findings and revised solution approach

### Phase 2: Controller Enhancement - Store Specifications
- [ ] Modify `DistingController` to store specification values with algorithm state
  - When algorithm added with specs, store them alongside the algorithm
  - Make them queryable via controller interface
- [ ] Update Cubit to maintain specification values
- [ ] Ensure specifications survive preset save/load cycles

### Phase 3: MCP Response Enhancement - Include Specifications
- [ ] Update `getCurrentPreset()` to include `specifications` field per slot
  - Format: `"specifications": [{"name": "Channels", "value": 2}]`
- [ ] Add `total_parameters` field to indicate actual parameter count
- [ ] Update `getSlot()` to include specifications
- [ ] Test with multi-channel algorithms

### Phase 4: Improve Ambiguous Name Error Messages
- [ ] When `parameter_name` lookup finds duplicates, improve error message
  - Include which parameter_numbers correspond to the ambiguous name
  - Help LLM understand it must use parameter_number
  - Example: "Parameter '1:Divisor' found at numbers 3, 4, 5. Use parameter_number to disambiguate."
- [ ] Make the error actionable

### Phase 5: Documentation Update
- [ ] Update `docs/mcp-api-guide.md` with real examples from Clock Divider
  - Show duplicate "1:Divisor" parameter names
  - Explain why parameter_number is required
  - Show complete workflow with specifications
- [ ] Add warning about firmware limitations (missing per-channel parameters)
- [ ] Document specification value constraints (min/max for each spec)

### Phase 6: Testing & Validation
- [ ] Unit tests for specification storage and retrieval
- [ ] Test getSlot/getCurrentPreset with algorithms that have specifications
- [ ] Integration tests with multi-channel algorithms (2, 4, 8 channels)
- [ ] Verify duplicate name error messages are helpful
- [ ] Documentation accuracy review

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
