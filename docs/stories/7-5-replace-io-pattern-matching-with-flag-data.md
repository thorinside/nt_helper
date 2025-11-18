# Story 7.5: Replace I/O Pattern Matching with Flag Data

Status: pending

## Story

As a developer maintaining the nt_helper routing system,
I want input/output direction and audio/CV type determined from I/O flag data instead of parameter name pattern matching,
So that the routing framework uses hardware-provided metadata as the single source of truth for port configuration.

## Context

Currently, the routing framework infers parameter properties from name pattern matching:
- Input/output detection: `lowerName.contains('output')`, `lowerName.contains('out')`
- Port type inference: `lowerName.contains('cv')`, `lowerName.contains('gate')`, `lowerName.contains('clock')`

Story 7.3 provides explicit I/O flags from hardware that make this pattern matching obsolete. This story systematically replaces all pattern matching with flag-based lookups, making the routing framework data-driven.

This story does NOT touch output mode parameter logic - that remains pattern-based until Story 7.6.

## Acceptance Criteria

### AC-1: Remove Artificial Port Types

1. Remove `PortType.gate` from `lib/core/routing/models/port.dart` enum
2. Remove `PortType.clock` from `lib/core/routing/models/port.dart` enum
3. Keep only `PortType.audio` and `PortType.cv` (data-driven from `isAudio` flag)
4. Update all references to `PortType.gate` throughout codebase
5. Update all references to `PortType.clock` throughout codebase
6. Verify no hardcoded gate/clock type assignments remain

### AC-2: Replace Input/Output Pattern Matching

7. Locate input/output detection logic in `lib/core/routing/multi_channel_algorithm_routing.dart:748-756`
8. Remove pattern matching: `lowerName.contains('output')`, `lowerName.contains('out')`
9. Replace with: Check `ParameterInfo.isInput` flag (bit 0)
10. Replace with: Check `ParameterInfo.isOutput` flag (bit 1)
11. Source of truth: `slot.parameters[i].isInput` and `slot.parameters[i].isOutput`
12. Document that flags come from hardware I/O metadata

### AC-3: Replace Port Type Pattern Matching

13. Locate port type inference logic in `lib/core/routing/multi_channel_algorithm_routing.dart:758-766`
14. Remove pattern matching: `lowerName.contains('cv')`, `lowerName.contains('gate')`, `lowerName.contains('clock')`
15. Replace with: Check `ParameterInfo.isAudio` flag (bit 2)
16. Logic: `isAudio == true` → `PortType.audio`, `isAudio == false` → `PortType.cv`
17. Source of truth: `slot.parameters[i].isAudio`
18. Document that audio/CV distinction is cosmetic (affects port color only)

### AC-4: Update All Routing Classes

19. Search all files in `lib/core/routing/` for pattern matching on parameter names
20. Replace input/output detection with `isInput`/`isOutput` flag checks
21. Replace port type inference with `isAudio` flag checks
22. Verify `PolyAlgorithmRouting` uses flags instead of pattern matching
23. Verify `MultiChannelAlgorithmRouting` uses flags instead of pattern matching
24. Verify `ES5DirectOutputAlgorithmRouting` uses flags instead of pattern matching
25. Verify specialized routing classes use flags instead of pattern matching

### AC-5: Preserve Width Parameter Special Case

26. Identify Width parameter special handling in routing code
27. Document why Width requires special handling (not covered by I/O flags)
28. Preserve existing Width parameter logic unchanged
29. Add code comment explaining Width is an exception to flag-driven approach

### AC-6: Update Port Visualization

30. Update port color mapping to differentiate audio vs CV:
    - Audio ports (`isAudio == true`): Use warm color (e.g., orange)
    - CV ports (`isAudio == false`): Use cool color (e.g., blue)
31. Verify colors are visually distinct in both light and dark themes
32. Update `lib/ui/widgets/port_widget.dart` or port rendering logic
33. Document that audio/CV colors are cosmetic (no connection restrictions)

### AC-7: Verify Connection Compatibility

34. Confirm `Port.isCompatibleWith()` still returns `true` for all types
35. Confirm audio ports can connect to CV ports (no type restrictions)
36. Confirm `Port.canConnectTo()` only checks direction, not type
37. Add test verifying audio→CV and CV→audio connections allowed

### AC-8: Offline/Mock Mode Behavior

38. Offline mode: All parameters have `ioFlags = 0` (no I/O metadata)
39. Mock mode: All parameters have `ioFlags = 0` (no I/O metadata)
40. When `isInput == false` and `isOutput == false`, use fallback logic:
    - Default to treating as output if bus parameter exists
    - Document fallback behavior in code comments
41. Offline mode remains functional with fallback logic

### AC-9: Unit Testing

42. Unit test verifies input detection using `isInput` flag
43. Unit test verifies output detection using `isOutput` flag
44. Unit test verifies audio port type from `isAudio == true`
45. Unit test verifies CV port type from `isAudio == false`
46. Unit test verifies fallback when `ioFlags == 0`
47. Unit test verifies no gate/clock port types created
48. Unit test verifies audio→CV connection allowed

### AC-10: Integration Testing

49. Integration test with real hardware verifies correct port types
50. Test Clock algorithm input uses `isInput` flag (not name matching)
51. Test Poly CV outputs use `isOutput` and `isAudio` flags
52. Test routing visualization shows correct port colors
53. Manual testing across multiple algorithm types

### AC-11: Documentation

54. Update routing framework documentation explaining I/O flag usage
55. Document that pattern matching has been removed for I/O detection
56. Document audio/CV distinction is cosmetic (VU meter vs voltage on hardware)
57. Document Width parameter exception and why it exists
58. Add inline code comments at all flag check sites

### AC-12: Code Quality

59. `flutter analyze` passes with zero warnings
60. All existing tests pass with no regressions
61. Routing editor visual tests confirm correct port colors
62. No pattern matching on parameter names for I/O type detection

## Tasks / Subtasks

- [ ] Task 1: Remove artificial port types (AC-1)
  - [ ] Remove `PortType.gate` from enum
  - [ ] Remove `PortType.clock` from enum
  - [ ] Find all references to `PortType.gate` in codebase
  - [ ] Find all references to `PortType.clock` in codebase
  - [ ] Update or remove all gate/clock references
  - [ ] Verify port type is only audio or CV

- [ ] Task 2: Replace input/output pattern matching (AC-2)
  - [ ] Locate pattern matching in `multi_channel_algorithm_routing.dart:748-756`
  - [ ] Replace with `ParameterInfo.isInput` check
  - [ ] Replace with `ParameterInfo.isOutput` check
  - [ ] Access flags via `slot.parameters[i].isInput/isOutput`
  - [ ] Add code comment explaining flag source
  - [ ] Remove all name-based input/output detection

- [ ] Task 3: Replace port type pattern matching (AC-3)
  - [ ] Locate pattern matching in `multi_channel_algorithm_routing.dart:758-766`
  - [ ] Replace with `ParameterInfo.isAudio` check
  - [ ] Implement logic: `isAudio ? PortType.audio : PortType.cv`
  - [ ] Access flag via `slot.parameters[i].isAudio`
  - [ ] Add code comment explaining cosmetic nature
  - [ ] Remove all name-based port type detection

- [ ] Task 4: Update all routing classes (AC-4)
  - [ ] Search `lib/core/routing/` for parameter name pattern matching
  - [ ] Update `PolyAlgorithmRouting` to use flags
  - [ ] Update `MultiChannelAlgorithmRouting` to use flags
  - [ ] Update `ES5DirectOutputAlgorithmRouting` to use flags
  - [ ] Update all specialized routing classes
  - [ ] Verify no pattern matching remains

- [ ] Task 5: Preserve Width parameter special case (AC-5)
  - [ ] Identify Width parameter special handling
  - [ ] Document why Width needs special handling
  - [ ] Add code comment explaining exception
  - [ ] Preserve existing Width logic unchanged

- [ ] Task 6: Update port visualization (AC-6)
  - [ ] Define audio port color (warm, e.g., orange)
  - [ ] Define CV port color (cool, e.g., blue)
  - [ ] Update port rendering to use `isAudio` flag for color
  - [ ] Test colors in light theme
  - [ ] Test colors in dark theme
  - [ ] Add code comment explaining cosmetic purpose

- [ ] Task 7: Verify connection compatibility (AC-7)
  - [ ] Check `Port.isCompatibleWith()` returns true for all types
  - [ ] Check `Port.canConnectTo()` only checks direction
  - [ ] Write test for audio→CV connection
  - [ ] Write test for CV→audio connection
  - [ ] Verify no type-based restrictions exist

- [ ] Task 8: Handle offline/mock mode (AC-8)
  - [ ] Verify offline mode has `ioFlags = 0`
  - [ ] Verify mock mode has `ioFlags = 0`
  - [ ] Implement fallback: default to output if bus param exists
  - [ ] Document fallback behavior
  - [ ] Test offline mode routing still works

- [ ] Task 9: Write unit tests (AC-9)
  - [ ] Test input detection via `isInput` flag
  - [ ] Test output detection via `isOutput` flag
  - [ ] Test audio port type via `isAudio == true`
  - [ ] Test CV port type via `isAudio == false`
  - [ ] Test fallback when `ioFlags == 0`
  - [ ] Test no gate/clock types created
  - [ ] Test audio↔CV connections allowed

- [ ] Task 10: Write integration tests (AC-10)
  - [ ] Test with real hardware for correct port types
  - [ ] Test Clock algorithm uses flags
  - [ ] Test Poly CV outputs use flags
  - [ ] Test routing visualization colors
  - [ ] Manual testing across algorithms

- [ ] Task 11: Update documentation (AC-11)
  - [ ] Update routing framework docs
  - [ ] Document pattern matching removal
  - [ ] Document audio/CV cosmetic distinction
  - [ ] Document Width parameter exception
  - [ ] Add inline code comments

- [ ] Task 12: Code quality validation (AC-12)
  - [ ] Run `flutter analyze`
  - [ ] Run all tests
  - [ ] Visual test routing editor
  - [ ] Verify no name-based pattern matching

## Dev Notes

### Architecture Context

**Current Pattern Matching (to be removed):**

```dart
// Input/output detection (multi_channel_algorithm_routing.dart:748-756)
final lowerName = paramName.toLowerCase();
final isOutput = lowerName.contains('output') ||
                 (lowerName.contains('out') && !lowerName.contains('input'));

// Port type inference (multi_channel_algorithm_routing.dart:758-766)
String portType = 'audio';
if (lowerName.contains('cv') ||
    lowerName.contains('gate') ||
    lowerName.contains('clock')) {
  portType = 'cv'; // or 'gate' or 'clock'
}
```

**New Flag-Based Approach:**

```dart
// Input/output detection using I/O flags
final paramInfo = slot.parameters[parameterNumber];
final isInput = paramInfo.isInput;   // Bit 0 of ioFlags
final isOutput = paramInfo.isOutput; // Bit 1 of ioFlags

// Port type inference using audio flag
final portType = paramInfo.isAudio ? PortType.audio : PortType.cv; // Bit 2
```

### I/O Flag Bit Layout (from Story 7.3)

```
Bit 0 (value 1): isInput - Parameter is an input
Bit 1 (value 2): isOutput - Parameter is an output
Bit 2 (value 4): isAudio - Audio signal (true) vs CV signal (false)
Bit 3 (value 8): isOutputMode - Controls output mode (handled in Story 7.6)
```

### Audio vs CV Distinction

**Purpose:**
- Hardware display: VU meters (audio) vs voltage values (CV)
- UI visualization: Port circle colors (warm vs cool)

**NOT used for:**
- Connection restrictions (all types compatible)
- Signal processing (everything is voltage in Eurorack)
- Routing logic (connections based on direction only)

### Width Parameter Special Case

Some algorithms have "Width" parameters that affect routing but don't fit the standard I/O flag model. These require special handling and should be preserved as exceptions to the flag-driven approach.

**Example:** Stereo width parameters that control channel pairing or mixing behavior.

### Offline/Mock Mode Fallback

When `ioFlags == 0` (offline/mock mode), use heuristic fallback:
1. If parameter has bus assignment → assume output
2. If parameter name suggests input → assume input
3. Default to CV type (safer than assuming audio)

This ensures offline mode remains functional while still preferring flag data when available.

### Port Color Mapping

**Suggested color scheme:**
- Audio: `HSL(30, 70%, 60%)` - Orange/warm
- CV: `HSL(210, 70%, 60%)` - Blue/cool

**Accessibility:**
- Ensure sufficient contrast in both themes
- Consider colorblind-friendly palette
- Maintain existing port size/shape conventions

### Files to Modify

**Port Type Enum:**
- `lib/core/routing/models/port.dart` - Remove gate/clock, update comments

**Routing Framework:**
- `lib/core/routing/multi_channel_algorithm_routing.dart` - Replace pattern matching (lines 748-766)
- `lib/core/routing/poly_algorithm_routing.dart` - Update if uses pattern matching
- `lib/core/routing/es5_direct_output_algorithm_routing.dart` - Update if uses pattern matching
- `lib/core/routing/clock_algorithm_routing.dart` - Update if uses pattern matching
- `lib/core/routing/euclidean_algorithm_routing.dart` - Update if uses pattern matching
- `lib/core/routing/routing_factory.dart` - Update if uses pattern matching

**Port Visualization:**
- `lib/ui/widgets/port_widget.dart` - Update color based on `isAudio` flag
- `lib/ui/widgets/routing/routing_editor_widget.dart` - Verify color usage

**Tests:**
- `test/core/routing/multi_channel_algorithm_routing_test.dart` - Add flag-based tests
- `test/core/routing/port_test.dart` - Add compatibility tests
- `test/ui/widgets/port_widget_test.dart` - Add color tests

### Pattern Matching Search Strategy

**Find all pattern matching sites:**
```bash
grep -r "contains('output')" lib/core/routing/
grep -r "contains('out')" lib/core/routing/
grep -r "contains('input')" lib/core/routing/
grep -r "contains('cv')" lib/core/routing/
grep -r "contains('gate')" lib/core/routing/
grep -r "contains('clock')" lib/core/routing/
grep -r "toLowerCase()" lib/core/routing/
```

**Verify complete removal:**
- No `lowerName.contains()` calls in routing classes
- No `paramName.toLowerCase()` for type inference
- Only flag checks: `isInput`, `isOutput`, `isAudio`

### Testing Strategy

**Unit Tests:**
- Flag-based input detection works correctly
- Flag-based output detection works correctly
- Flag-based audio/CV type inference works correctly
- Fallback logic when `ioFlags == 0`
- No gate/clock port types created
- Audio/CV ports can connect

**Integration Tests:**
- Real hardware provides correct flags
- Routing framework creates correct ports
- Port colors match audio/CV types
- Connections work across audio/CV boundaries

**Manual Testing:**
- Load various algorithms and inspect routing editor
- Verify port colors distinguish audio vs CV
- Verify connections allowed between all port types
- Test offline mode still creates usable routing

### Related Stories

- **Story 7.3** - Provides I/O flags (prerequisite)
- **Story 7.6** - Will handle output mode parameter matching (separate concern)
- **Story 7.4** - Provides output mode data (not used in this story)

### Reference Documents

- `lib/core/routing/algorithm_routing.dart` - Routing framework base class
- `lib/core/routing/models/port.dart` - Port model and compatibility
- `docs/architecture.md` - Routing system architecture
- Story 7.3 - I/O flag implementation details

## Dev Agent Record

### Context Reference

- TBD: docs/stories/7-5-replace-io-pattern-matching-with-flag-data.context.xml

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
