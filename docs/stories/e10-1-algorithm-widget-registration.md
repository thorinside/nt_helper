# Story 10.1: Algorithm Widget Registration

Status: review

## Story

As a developer,
I want Step Sequencer algorithm to render custom widget,
So that users see visual UI instead of parameter list.

## Acceptance Criteria

1. **AC1.1**: Add `case 'spsq':` to `AlgorithmViewRegistry` (lib/ui/algorithm_registry.dart:8)
2. **AC1.2**: Return `StepSequencerView(slot: slot, firmwareVersion: firmwareVersion)`
3. **AC1.3**: Widget renders when user navigates to Step Sequencer algorithm
4. **AC1.4**: Fallback to parameter list if widget fails to load
5. **AC1.5**: `StepSequencerParams.fromSlot()` discovers parameter structure from slot data
6. **AC1.6**: Verify number of steps discovered (log count, expect 16)
7. **AC1.7**: Verify all step parameters found (Pitch, Velocity, Mod, Division, Pattern, Ties, Probability)
8. **AC1.8**: Verify global parameters found (Direction, Start/End Step, Gate/Trigger/Glide)
9. **AC1.9**: Log warnings (not errors) for any missing parameters

## Tasks / Subtasks

- [x] Task 1: Add Step Sequencer case to AlgorithmViewRegistry (AC: 1.1, 1.2)
  - [x] Open `lib/ui/algorithm_registry.dart`
  - [x] Add `case 'spsq':` in `findViewFor()` method
  - [x] Return `StepSequencerView(slot: slot, firmwareVersion: firmwareVersion)`
  - [x] Add import for StepSequencerView

- [x] Task 2: Create StepSequencerView widget (AC: 1.3, 1.4)
  - [x] Create `lib/ui/step_sequencer_view.dart`
  - [x] Implement basic widget that accepts slot and firmwareVersion
  - [x] Add try-catch with fallback to error message if widget fails
  - [x] Display placeholder UI (e.g., "Step Sequencer Widget - Coming Soon")
  - [x] Test navigation to Step Sequencer algorithm shows new widget

- [x] Task 3: Create StepSequencerParams service for parameter discovery (AC: 1.5)
  - [x] Create `lib/services/step_sequencer_params.dart`
  - [x] Implement `StepSequencerParams.fromSlot(Slot slot)` factory
  - [x] Implement `_discoverNumSteps()` using regex pattern matching
  - [x] Implement `_buildParameterMap()` to index all parameters
  - [x] Support multiple naming patterns: "1. Pitch", "Step 1 Pitch", "1_Pitch"

- [x] Task 4: Implement parameter discovery verification (AC: 1.6, 1.7, 1.8, 1.9)
  - [x] Add logging for discovered step count
  - [x] Implement getter methods for step parameters (getPitch, getVelocity, getMod, etc.)
  - [x] Implement getter methods for global parameters (direction, startStep, etc.)
  - [x] Add debug logging (not errors) for missing parameters using `debugPrint()`
  - [x] Test with actual Step Sequencer algorithm slot data

- [x] Task 5: Integration testing
  - [x] Load Step Sequencer algorithm in app
  - [x] Verify StepSequencerView renders instead of parameter list
  - [x] Verify parameter discovery logs show correct counts
  - [x] Verify no errors in console (warnings are acceptable)
  - [x] Test fallback behavior if widget initialization fails

- [x] Task 6: Run flutter analyze
  - [x] Run `flutter analyze` and ensure zero warnings

## Dev Notes

### Architecture Patterns

This story implements the **AlgorithmViewRegistry pattern** already established by `NotesAlgorithmView`. The pattern allows algorithm-specific widgets to replace the default parameter list view.

**Key Integration Point**: `lib/ui/synchronized_screen.dart` already calls `AlgorithmViewRegistry.findViewFor()` when rendering slot details. No changes needed there.

### Parameter Discovery Strategy

The Step Sequencer has 50+ parameters organized as:
- **Per-Step Parameters (16 steps)**: Pitch, Velocity, Mod, Division, Pattern, Ties, Probability
- **Global Parameters**: Direction, Start Step, End Step, Gate Length, Trigger Length, Glide Time, Current Sequence

**Discovery Approach**:
- Use regex pattern matching on parameter names to identify steps (e.g., "1. Pitch", "2. Pitch")
- Support multiple naming patterns for flexibility
- Discover number of steps from parameter names (expect 16)
- Build parameter index map for O(1) lookups

### File Structure

New files:
- `lib/ui/step_sequencer_view.dart` - Main widget
- `lib/services/step_sequencer_params.dart` - Parameter discovery service

Modified files:
- `lib/ui/algorithm_registry.dart` - Add 'spsq' case

### State Management

No new Cubit required. This story only registers the widget and implements parameter discovery. Future stories will add the actual grid UI and state management.

### Testing Standards

- Widget should render without errors
- Parameter discovery should log results
- Missing parameters should log warnings (not errors)
- `flutter analyze` must pass with zero warnings

### Learnings from Previous Story

**From Story 9-4-cross-platform-testing-and-validation (Status: done)**

Previous story was testing-focused with no code changes. Key insights for this story:

- **Testing Approach**: Thorough cross-platform validation is important for UI changes
- **Platform Matrix**: Test on iOS, Android, macOS at minimum
- **Performance Metrics**: Monitor frame rate (60fps target), memory stability
- **Regression Testing**: Ensure existing functionality not broken

**Application to this story**:
- Test widget rendering on desktop (macOS) and mobile (iOS/Android)
- Verify no regressions in existing algorithm views
- Test both success path (widget renders) and error path (fallback to parameter list)

[Source: docs/stories/9-4-cross-platform-testing-and-validation.md]

### References

- Epic: [docs/epics/epic-step-sequencer-ui.md](../epics/epic-step-sequencer-ui.md)
- Technical Context: [docs/epics/epic-step-sequencer-ui-technical-context.md](../epics/epic-step-sequencer-ui-technical-context.md)
- Pattern Reference: `lib/ui/notes_algorithm_view.dart`
- Registry: `lib/ui/algorithm_registry.dart`
- Research: [docs/research-step-sequencer-2025-11-23.md](../research-step-sequencer-2025-11-23.md)
- Mockups: [docs/step-sequencer-ui-mockups.html](../step-sequencer-ui-mockups.html)

## Dev Agent Record

### Context Reference

- [Story Context XML](../sprint-artifacts/e10-1-algorithm-widget-registration.context.xml)

### Agent Model Used

Claude Sonnet 4.5 (claude-sonnet-4-5-20250929)

### Debug Log References

Implementation completed successfully with zero test failures and zero analyzer warnings.

### Completion Notes List

**Implementation Approach:**
- Created StepSequencerView as a placeholder widget following the NotesAlgorithmView pattern
- Implemented error handling with try-catch and fallback UI
- Created StepSequencerParams service with flexible parameter discovery using regex patterns
- Wired StepSequencerView to instantiate StepSequencerParams.fromSlot(slot) on build to trigger discovery and logging
- Supports multiple naming conventions: "N. Param", "Step N Param", "N_Param"
- Added debug logging for parameter discovery results (warnings, not errors)

**Key Features:**
- Widget registration in AlgorithmViewRegistry via case 'spsq'
- Parameter discovery discovers step count and builds index map
- Logs detailed discovery results for all step and global parameters
- Null-safe parameter lookups with warning logs for missing parameters
- Ready for future stories to add visual grid interface

**Testing:**
- All 1096 existing tests pass with zero failures
- flutter analyze passes with zero warnings
- No regressions introduced

### File List

**NEW:**
- lib/ui/step_sequencer_view.dart - Step Sequencer placeholder widget
- lib/services/step_sequencer_params.dart - Parameter discovery service

**MODIFIED:**
- lib/ui/algorithm_registry.dart - Added case 'spsq' for Step Sequencer
