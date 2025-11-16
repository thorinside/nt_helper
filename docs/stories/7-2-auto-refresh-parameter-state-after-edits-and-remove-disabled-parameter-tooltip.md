# Story 7.2: Auto-Refresh Parameter State After Edits and Remove Disabled Parameter Tooltip

Status: drafted

## Story

As a user editing algorithm parameters,
I want the parameter disabled states to automatically update when I change a parameter that affects other parameters,
So that I can immediately see which parameters become available or unavailable without manually refreshing.

## Acceptance Criteria

1. **Auto-refresh Logic**
   - When user finishes editing a parameter value (on value commit, not during drag), schedule a single `requestAllParameterValues` message
   - Refresh occurs after user completes parameter edit action (slider release, text input commit, etc.)

2. **Debouncing Mechanism**
   - Implement debounce/throttle to ensure only one refresh request is queued at a time
   - Debounce timing: Wait 300ms after last parameter edit before sending refresh request
   - Allows batch edits without flooding system with multiple refresh requests

3. **Debounce State Management**
   - DistingCubit or parameter editor widget manages debounced refresh timer
   - If new parameter edit occurs before timer expires, cancel pending refresh and restart timer
   - No partial or duplicate requests sent to hardware

4. **UI Behavior**
   - No loading spinner needed (refresh is fast and non-blocking)
   - Parameter disabled states update automatically after refresh completes
   - UI remains responsive during refresh operation

5. **Remove Tooltip**
   - Remove tooltip/help text that previously explained why parameter is disabled
   - Grayed-out appearance (0.5 opacity from Story 7.1) and read-only state provide sufficient visual feedback
   - Disabled parameters remain clearly distinguishable without tooltip clutter

6. **Code Quality**
   - `flutter analyze` passes with zero warnings
   - All existing tests pass with no regressions

## Tasks / Subtasks

- [ ] Task 1: Implement debounced refresh mechanism (AC: 1, 2, 3)
  - [ ] Add `Timer` field to DistingCubit or parameter editor for debounce management
  - [ ] Create method to schedule debounced `requestAllParameterValues` call
  - [ ] Implement cancel logic for pending timer when new edit occurs
  - [ ] Set debounce delay to 300ms
  - [ ] Add unit test verifying debounce prevents request flooding

- [ ] Task 2: Integrate refresh trigger into parameter edit flow (AC: 1, 4)
  - [ ] Identify parameter value commit points in UI widgets (slider onChangeEnd, text field onSubmitted, etc.)
  - [ ] Call debounced refresh method after each parameter commit
  - [ ] Verify refresh does not trigger during drag operations (only on commit)
  - [ ] Test with various parameter editor widgets (sliders, text fields, dropdowns)

- [ ] Task 3: Remove disabled parameter tooltips (AC: 5)
  - [ ] Locate tooltip implementation in parameter editor widgets
  - [ ] Remove tooltip code for disabled parameters
  - [ ] Verify grayed-out appearance (0.5 opacity) remains intact
  - [ ] Add widget test verifying tooltip is removed

- [ ] Task 4: Integration testing (AC: 1, 2, 3, 4)
  - [ ] Create integration test changing Clock algorithm Source parameter
  - [ ] Verify auto-refresh triggers after Source parameter change
  - [ ] Verify Clock Input parameter disabled state updates automatically
  - [ ] Test rapid parameter edits verify debounce prevents flooding
  - [ ] Test parameter state updates reflect in UI without manual refresh

- [ ] Task 5: Code quality validation (AC: 6)
  - [ ] Run `flutter analyze` and fix any warnings
  - [ ] Run all existing tests
  - [ ] Verify no regressions in parameter editing behavior
  - [ ] Verify no regressions in disabled state display

## Dev Notes

### Architecture Context

**Related Story:** Story E7.1 implemented the parameter disabled/grayed-out state based on SysEx flag extraction. This story builds on that foundation by adding automatic state refresh.

**Auto-Refresh Strategy:**
- Trigger: Parameter value commit (slider release, text input submit, dropdown change)
- Mechanism: Debounced `requestAllParameterValues` call (300ms delay)
- Goal: Keep disabled state synchronized when parameter changes affect other parameters

**Debounce Pattern:**
```dart
Timer? _parameterRefreshTimer;

void scheduleParameterRefresh() {
  _parameterRefreshTimer?.cancel();
  _parameterRefreshTimer = Timer(Duration(milliseconds: 300), () {
    _midiManager.requestAllParameterValues();
  });
}
```

### Project Structure Notes

**Files to Modify:**
- `lib/cubit/disting_cubit.dart` - Add debounced refresh logic, manage timer lifecycle
- `lib/ui/widgets/parameter_editor_widget.dart` or equivalent - Trigger refresh on parameter commit, remove tooltip
- Parameter editor widgets (sliders, text fields) - Hook into commit events

**Test Files:**
- `test/cubit/disting_cubit_test.dart` - Unit test debounce logic
- `test/integration/parameter_disabled_state_test.dart` - Integration test auto-refresh behavior
- `test/ui/widgets/parameter_editor_widget_test.dart` - Widget test tooltip removal

### References

- [Source: docs/epics.md#Epic-7] - Story E7.2 acceptance criteria and technical notes
- [Source: docs/stories/7-1-implement-parameter-disabled-grayed-out-state-in-ui.md] - Foundation story for disabled state implementation
- [Source: lib/cubit/disting_cubit.dart] - State management for parameter refresh
- [Source: lib/domain/i_disting_midi_manager.dart] - `requestAllParameterValues()` method signature

## Dev Agent Record

### Context Reference

<!-- Path(s) to story context XML will be added here by context workflow -->

### Agent Model Used

claude-sonnet-4-5-20250929

### Debug Log References

### Completion Notes List

### File List
