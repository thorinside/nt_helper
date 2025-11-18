# Story 7.6: Replace Output Mode Pattern Matching with Usage Data

Status: pending

## Story

As a developer maintaining the nt_helper routing system,
I want output mode parameters and their controlled outputs identified using hardware-provided usage data instead of parameter name pattern matching,
So that connection labels and output modes reflect actual hardware relationships as the single source of truth.

## Context

Currently, the routing framework infers output mode relationships through pattern matching:
- Mode parameter discovery: `modeParameters?.containsKey('$paramName mode')`
- Mode parameter search: Generates possible mode names and searches parameters

Story 7.3 provides the `isOutputMode` flag to identify mode control parameters. Story 7.4 provides output mode usage data via SysEx 0x55 responses that explicitly maps mode parameters to their controlled outputs.

This story removes all mode parameter pattern matching and replaces it with explicit hardware data, completing the transition to a fully data-driven routing framework.

## Acceptance Criteria

### AC-1: Remove Mode Parameter Pattern Matching

1. Locate mode parameter name matching in `lib/core/routing/multi_channel_algorithm_routing.dart:752`
2. Remove pattern matching: `modeParameters?.containsKey('$paramName mode')`
3. Replace with: Check `ParameterInfo.isOutputMode` flag (bit 3 of ioFlags)
4. When `isOutputMode == true`, parameter controls output routing for other parameters
5. Document that mode control identification comes from hardware I/O flags

### AC-2: Remove Mode Parameter Discovery Logic

6. Locate mode parameter discovery in `lib/core/routing/multi_channel_algorithm_routing.dart:817-818`
7. Remove logic that generates possible mode parameter names
8. Remove logic that searches for mode parameters by constructed names
9. Replace with: Use `OutputModeUsage` data from Story 7.4
10. Document that mode relationships come from SysEx 0x55 responses

### AC-3: Use Output Mode Usage Data

11. Access `OutputModeUsage` data from cubit/slot state
12. For each parameter with `isOutputMode == true`:
    - Look up affected parameters in `outputModeMap`
    - Retrieve list of controlled output parameter numbers
13. Map output parameters to their controlling mode parameters
14. Store mode parameter number in `Port.modeParameterNumber` field
15. Source of truth: `slot.outputModeMap` populated by Story 7.4

### AC-4: Determine Output Mode (Add vs Replace)

16. Read current value of mode parameter (0 = Add, 1 = Replace)
17. Assign `Port.outputMode` based on mode parameter value:
    - Value 0 → `OutputMode.add`
    - Value 1 → `OutputMode.replace`
18. Update output mode when mode parameter value changes
19. Store output mode in port metadata for connection visualization

### AC-5: Update Connection Visualization

20. Update connection label generation to use `Port.outputMode`
21. Connection labels distinguish Add vs Replace mode:
    - Add mode: Normal connection style/color
    - Replace mode: Different connection style/color
22. Remove any hardcoded mode parameter name assumptions
23. Document that connection styling reflects actual hardware mode configuration

### AC-6: Handle Missing Output Mode Data

24. When `isOutputMode == true` but no output mode usage data available:
    - Log warning about missing data
    - Default to `OutputMode.add` (safer fallback)
    - Document fallback behavior
25. When `ioFlags == 0` (offline/mock mode):
    - Use existing pattern matching as fallback (temporary)
    - Document that offline mode uses fallback until hardware data available
26. Online mode with hardware: Always prefer usage data over pattern matching

### AC-7: Update All Routing Classes

27. Search all files in `lib/core/routing/` for mode parameter pattern matching
28. Replace mode parameter name matching with `isOutputMode` flag checks
29. Replace mode parameter discovery with `OutputModeUsage` lookups
30. Verify `MultiChannelAlgorithmRouting` uses output mode data
31. Verify specialized routing classes use output mode data
32. Verify no mode parameter name matching remains in online mode

### AC-8: State Management Integration

33. Ensure output mode relationships accessible from routing framework
34. Access via `slot.outputModeMap` or similar state structure
35. Update output modes when mode parameter values change
36. Clear output mode data when algorithm changes or slot cleared
37. Verify state updates trigger routing recalculation

### AC-9: Unit Testing

38. Unit test verifies mode parameter identification via `isOutputMode` flag
39. Unit test verifies output mode usage data lookup
40. Unit test verifies output mode determination from parameter value
41. Unit test verifies Add mode (value 0) creates correct port metadata
42. Unit test verifies Replace mode (value 1) creates correct port metadata
43. Unit test verifies fallback when output mode data missing
44. Unit test verifies offline mode fallback behavior

### AC-10: Integration Testing

45. Integration test with real hardware verifies mode parameter detection
46. Test algorithm with output mode parameters uses usage data
47. Test changing mode parameter updates connection visualization
48. Test output mode relationships match hardware behavior
49. Manual testing across algorithms with various mode configurations

### AC-11: Documentation

50. Update routing framework documentation explaining output mode usage
51. Document that pattern matching removed for mode parameter detection
52. Document Add vs Replace mode visualization differences
53. Document fallback behavior for offline/missing data cases
54. Add inline code comments at all output mode usage sites

### AC-12: Code Quality

55. `flutter analyze` passes with zero warnings
56. All existing tests pass with no regressions
57. Routing editor correctly visualizes Add vs Replace modes
58. No mode parameter name pattern matching in online mode

## Tasks / Subtasks

- [ ] Task 1: Remove mode parameter pattern matching (AC-1)
  - [ ] Locate pattern matching in `multi_channel_algorithm_routing.dart:752`
  - [ ] Remove `modeParameters?.containsKey('$paramName mode')`
  - [ ] Replace with `ParameterInfo.isOutputMode` check
  - [ ] Add code comment explaining flag source
  - [ ] Verify no mode name matching remains

- [ ] Task 2: Remove mode parameter discovery (AC-2)
  - [ ] Locate discovery logic in `multi_channel_algorithm_routing.dart:817-818`
  - [ ] Remove mode name generation logic
  - [ ] Remove mode parameter search logic
  - [ ] Add code comment referencing Story 7.4 data source
  - [ ] Verify no mode discovery by name remains

- [ ] Task 3: Use output mode usage data (AC-3)
  - [ ] Access `OutputModeUsage` from slot state
  - [ ] Look up affected parameters for each `isOutputMode` parameter
  - [ ] Map outputs to their controlling mode parameters
  - [ ] Store `modeParameterNumber` in port metadata
  - [ ] Verify mapping is correct

- [ ] Task 4: Determine output mode value (AC-4)
  - [ ] Read current value of mode parameter
  - [ ] Map value 0 → `OutputMode.add`
  - [ ] Map value 1 → `OutputMode.replace`
  - [ ] Update mode when parameter value changes
  - [ ] Store in `Port.outputMode` field

- [ ] Task 5: Update connection visualization (AC-5)
  - [ ] Update connection label generation
  - [ ] Distinguish Add vs Replace in connection style/color
  - [ ] Remove hardcoded mode name assumptions
  - [ ] Add code comment explaining visualization
  - [ ] Test visual distinction is clear

- [ ] Task 6: Handle missing data fallbacks (AC-6)
  - [ ] Log warning when `isOutputMode` but no usage data
  - [ ] Default to `OutputMode.add` when data missing
  - [ ] Implement offline mode fallback (pattern matching)
  - [ ] Document fallback behavior
  - [ ] Prefer usage data when available

- [ ] Task 7: Update all routing classes (AC-7)
  - [ ] Search for mode parameter pattern matching
  - [ ] Replace with `isOutputMode` checks
  - [ ] Replace with `OutputModeUsage` lookups
  - [ ] Update `MultiChannelAlgorithmRouting`
  - [ ] Update specialized routing classes
  - [ ] Verify no pattern matching remains

- [ ] Task 8: Integrate with state management (AC-8)
  - [ ] Access `outputModeMap` from slot state
  - [ ] Update modes when parameter values change
  - [ ] Clear data on algorithm change
  - [ ] Trigger routing recalculation on updates
  - [ ] Verify state propagation

- [ ] Task 9: Write unit tests (AC-9)
  - [ ] Test mode parameter identification via flag
  - [ ] Test output mode usage lookup
  - [ ] Test Add mode (value 0)
  - [ ] Test Replace mode (value 1)
  - [ ] Test fallback when data missing
  - [ ] Test offline fallback
  - [ ] Test state updates trigger recalculation

- [ ] Task 10: Write integration tests (AC-10)
  - [ ] Test with real hardware
  - [ ] Test mode parameter detection
  - [ ] Test changing mode parameter
  - [ ] Test connection visualization
  - [ ] Manual testing across algorithms

- [ ] Task 11: Update documentation (AC-11)
  - [ ] Update routing framework docs
  - [ ] Document pattern matching removal
  - [ ] Document Add/Replace visualization
  - [ ] Document fallback behavior
  - [ ] Add inline code comments

- [ ] Task 12: Code quality validation (AC-12)
  - [ ] Run `flutter analyze`
  - [ ] Run all tests
  - [ ] Visual test routing editor
  - [ ] Verify no mode name matching

## Dev Notes

### Architecture Context

**Current Pattern Matching (to be removed):**

```dart
// Mode parameter detection (multi_channel_algorithm_routing.dart:752)
final hasMatchingModeParameter =
    modeParameters?.containsKey('$paramName mode') ?? false;

// Mode parameter discovery (multi_channel_algorithm_routing.dart:817-818)
final possibleModeNames = ['$paramName mode', '${paramName}Mode', ...];
// Search for parameters matching these names
```

**New Usage Data Approach:**

```dart
// Mode parameter identification using flag
final paramInfo = slot.parameters[parameterNumber];
final isMode = paramInfo.isOutputMode; // Bit 3 of ioFlags

// Output mode usage lookup
final outputModeData = slot.outputModeMap[modeParameterNumber];
if (outputModeData != null) {
  final affectedParams = outputModeData.affectedParameterNumbers;
  final modeValue = slot.parameters[modeParameterNumber].value;
  final outputMode = modeValue == 0 ? OutputMode.add : OutputMode.replace;

  // Apply to affected output parameters
  for (final paramNum in affectedParams) {
    // Set Port.outputMode and Port.modeParameterNumber
  }
}
```

### Output Mode Usage Data Structure (from Story 7.4)

```dart
class OutputModeUsage {
  final int sourceParameterNumber;        // The mode control parameter
  final List<int> affectedParameterNumbers; // Parameters controlled by this mode

  OutputModeUsage({
    required this.sourceParameterNumber,
    required this.affectedParameterNumbers,
  });
}

// In Slot state:
Map<int, OutputModeUsage> outputModeMap; // Key: source parameter number
```

### Output Mode Value Interpretation

**Mode Parameter Values:**
- **0 = Add mode**: Output is mixed with other outputs on the same bus
- **1 = Replace mode**: Output replaces previous outputs on the same bus

**Example:**
```dart
// Parameter 42 controls output mode for parameters [100, 101, 102]
final modeParam = slot.parameters[42];
final outputModeUsage = slot.outputModeMap[42];

if (modeParam.value == 0) {
  // Outputs 100, 101, 102 are in Add mode (mixed)
} else if (modeParam.value == 1) {
  // Outputs 100, 101, 102 are in Replace mode (exclusive)
}
```

### Connection Visualization

**Add Mode (value 0):**
- Connection style: Normal/default
- Semantic: Output is summed with other outputs on bus
- Use case: Mixing multiple sources

**Replace Mode (value 1):**
- Connection style: Distinct color/dashed line
- Semantic: Output replaces other outputs on bus
- Use case: Switching between sources

**Suggested styling:**
- Add: Solid line, standard color
- Replace: Dashed line or different color (e.g., red/orange)

### Fallback Strategy

**Priority order:**
1. **Online mode with usage data**: Use `OutputModeUsage` from SysEx 0x55 (preferred)
2. **Online mode without usage data**: Log warning, default to Add mode
3. **Offline/mock mode**: Use pattern matching fallback (temporary compatibility)

**Offline fallback rationale:**
- Offline mode has no hardware to query
- Existing pattern matching keeps offline routing functional
- Eventually could pre-populate offline data from known algorithm metadata

### State Update Flow

**Initial algorithm load:**
1. Parameters received via SysEx 0x43 (includes `ioFlags`)
2. Parameters with `isOutputMode == true` trigger SysEx 0x55 requests
3. Output mode usage responses populate `outputModeMap`
4. Routing framework creates ports with correct mode metadata

**Mode parameter value change:**
1. User changes mode parameter value (0 ↔ 1)
2. Cubit emits new state with updated parameter value
3. Routing framework recalculates affected port output modes
4. Connection visualization updates to reflect new mode

### Files to Modify

**Routing Framework:**
- `lib/core/routing/multi_channel_algorithm_routing.dart` - Replace mode pattern matching (lines 752, 817-818)
- `lib/core/routing/algorithm_routing.dart` - Update base class if needed
- `lib/core/routing/connection_discovery_service.dart` - Use output mode from ports

**Connection Visualization:**
- `lib/ui/widgets/routing/connection_painter.dart` - Add/Replace styling (if exists)
- `lib/ui/widgets/routing/routing_editor_widget.dart` - Connection rendering

**State Access:**
- `lib/cubit/disting_cubit.dart` - Ensure outputModeMap accessible
- `lib/models/slot.dart` - Ensure outputModeMap included in state

**Tests:**
- `test/core/routing/multi_channel_algorithm_routing_test.dart` - Add mode tests
- `test/core/routing/output_mode_test.dart` - New file for mode-specific tests
- `test/ui/widgets/routing/connection_visualization_test.dart` - Visual tests

### Pattern Matching Search Strategy

**Find all mode parameter pattern matching:**
```bash
grep -r "mode.*parameter" lib/core/routing/
grep -r "containsKey.*mode" lib/core/routing/
grep -r "Mode.*param" lib/core/routing/
grep -r "endsWith.*mode" lib/core/routing/
```

**Verify complete removal:**
- No mode parameter name construction in routing classes
- No `containsKey('$name mode')` checks
- Only flag checks: `isOutputMode`
- Only usage data lookups: `outputModeMap`

### Testing Strategy

**Unit Tests:**
- Mode parameter identification via `isOutputMode` flag
- Output mode usage data lookup works
- Add mode creates correct port metadata
- Replace mode creates correct port metadata
- Fallback when usage data missing
- Offline mode uses fallback

**Integration Tests:**
- Real hardware mode parameters detected correctly
- Changing mode parameter updates visualization
- Output mode relationships match hardware
- Connection styling reflects current mode

**Manual Testing:**
- Load algorithms with known mode parameters
- Change mode parameter and observe connection changes
- Verify Add mode allows mixing
- Verify Replace mode switches outputs
- Test offline mode still functional

### Related Stories

- **Story 7.3** - Provides `isOutputMode` flag (prerequisite)
- **Story 7.4** - Provides `OutputModeUsage` data (prerequisite)
- **Story 7.5** - Removed I/O pattern matching (related refactoring)

### Reference Documents

- `lib/core/routing/models/port.dart` - Port model with outputMode field
- Story 7.4 - Output mode usage data implementation
- Story 7.3 - I/O flags including isOutputMode
- `docs/architecture.md` - Routing system architecture

### Edge Cases

**Multiple mode parameters:**
- Some algorithms may have multiple independent mode parameters
- Each controls different sets of outputs
- `outputModeMap` stores separate entries for each mode parameter

**Parameter with multiple modes:**
- Unlikely but theoretically possible
- One output controlled by multiple mode parameters
- Last mode parameter wins (or use most restrictive mode)

**Mode parameter without outputs:**
- `isOutputMode == true` but no affected parameters in usage data
- Log warning, treat as no-op
- May indicate firmware inconsistency or algorithm design

**Disconnected outputs:**
- Output parameter not in any mode parameter's affected list
- Assume independent output (not mode-controlled)
- Default to Add mode for compatibility

## Dev Agent Record

### Context Reference

- TBD: docs/stories/7-6-replace-output-mode-pattern-matching-with-usage-data.context.xml

### Agent Model Used

TBD

### Completion Notes List

- TBD

### File List

**Modified:**
- TBD

**Added:**
- TBD

### Change Log

- **2025-11-18:** Story created by Business Analyst (Mary)
