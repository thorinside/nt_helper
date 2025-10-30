# Story 6.1: Mobile Performance Page Support

Status: review

## Story

As a mobile user of nt_helper,
I want to assign parameters to performance pages via the mapping editor bottom sheet,
so that I can access performance page functionality without the cramped desktop-only inline dropdown.

## Acceptance Criteria

1. Performance tab exists in PackedMappingDataEditor (fourth tab after CV/MIDI/I2C)
2. Performance tab contains dropdown selector for performance pages (0=None, 1-15=P1-P15)
3. Dropdown uses color-coded page badges matching Performance screen visual language
4. Dropdown reads current perfPageIndex from DistingCubit state via BlocBuilder
5. Selecting a page calls `DistingCubit.setPerformancePageMapping()` directly (same as inline dropdown)
6. Changes trigger optimistic state update + hardware sync + verification (zero local state)
7. Inline dropdown hidden on mobile screens (width < 600px) in section_parameter_list_view.dart
8. MappingEditorBottomSheet passes algorithmIndex and parameterNumber to editor
9. Initial tab logic selects Performance tab when perfPageIndex > 0 and no other mappings active
10. Both inline dropdown (desktop) and Performance tab (mobile) stay synchronized via cubit state
11. All existing tests pass
12. `flutter analyze` passes with zero warnings

## Tasks / Subtasks

- [x] Hide inline dropdown on mobile (AC: 7)
  - [x] Modify `lib/ui/widgets/section_parameter_list_view.dart` around lines 265-295
  - [x] Wrap performance page dropdown Row with conditional: `if (MediaQuery.of(context).size.width >= 600)`
  - [x] Verify dropdown hidden on narrow screens

- [x] Update mapping editor bottom sheet (AC: 8)
  - [x] Modify `lib/ui/widgets/mapping_editor_bottom_sheet.dart`
  - [x] Pass `algorithmIndex` and `parameterNumber` to PackedMappingDataEditor
  - [x] Keep `onSave` callback (still needed for CV/MIDI/I2C tabs)

- [x] Update PackedMappingDataEditor constructor (AC: 8)
  - [x] Add required parameters: `algorithmIndex` and `parameterNumber`
  - [x] Keep `onSave` callback parameter (still needed for CV/MIDI/I2C tabs)

- [x] Update TabController length (AC: 1)
  - [x] Change TabController length from 3 to 4 in initState()
  - [x] Add Performance tab to initial index logic (if perfPageIndex > 0)

- [x] Add Performance tab to UI (AC: 1, 9)
  - [x] Add "Performance" to TabBar tabs list
  - [x] Add `_buildPerformanceEditor()` to TabBarView children

- [x] Implement _buildPerformanceEditor() method (AC: 2-6)
  - [x] Wrap widget in `BlocBuilder<DistingCubit, DistingState>`
  - [x] Read currentPerfPageIndex from cubit state (NOT local _data)
  - [x] Create DropdownMenu<int> with "None" (0) and "P1-P15" (1-15) options
  - [x] Add color-coded page badges using _getPageColor() helper
  - [x] Set initialSelection from cubit state value
  - [x] Call `context.read<DistingCubit>().setPerformancePageMapping()` on selection
  - [x] Display help text showing current assignment from cubit state

- [x] Implement _getPageColor() helper (AC: 3)
  - [x] Create helper method returning Colors based on page index
  - [x] Use color scheme: blue, green, orange, purple, red (cycling)
  - [x] Match colors from Performance screen and inline dropdown

- [x] Add tests for Performance tab (AC: 11)
  - [x] Modify `test/ui/widgets/packed_mapping_data_editor_test.dart`
  - [x] Test: Performance tab is rendered
  - [x] Test: TabController has length 4
  - [x] Test: Performance tab auto-selected when perfPageIndex > 0

- [x] Run full validation (AC: 11-12)
  - [x] Run full test suite: `flutter test`
  - [x] Verify all existing tests pass (20/20 tests passed)
  - [x] Run `flutter analyze`
  - [x] Ensure zero warnings (confirmed: No issues found!)

## Dev Notes

### Implementation Overview

This is a Level 1 (small, atomic) feature adding mobile-friendly performance page assignment. The implementation adds a fourth "Performance" tab to the existing 3-tab mapping editor bottom sheet, providing an alternative to the desktop-only inline dropdown that doesn't fit on mobile screens.

### Key Design Decisions

**Why add to mapping editor instead of new mobile UI?**
- Mapping editor is already the central location for all parameter configuration (CV/MIDI/I2C)
- Creates unified, consistent editing experience
- Users already know how to access it (mapping button on each parameter row)

**Why keep desktop inline dropdown?**
- Desktop users benefit from quick, in-place editing without modal
- No need to change working desktop UX to fix mobile issue
- Both methods serve different use cases: desktop = quick inline, mobile = detailed modal

**Why use BlocBuilder instead of local state?**
- Cubit is source of truth for all mapping data
- Eliminates synchronization issues between inline dropdown and Performance tab
- Matches pattern from inline dropdown (calls `setPerformancePageMapping()` directly)
- Widget auto-rebuilds when cubit emits new state (optimistic update + hardware sync)

### State Management Flow

1. **User Opens Editor**: Reads current perfPageIndex from DistingCubit state
2. **User Selects Page**: Calls `DistingCubit.setPerformancePageMapping()` (same as inline dropdown)
3. **Cubit Optimistic Update**: Emits new state immediately with updated mapping
4. **All Widgets Rebuild**: Performance tab, inline dropdown, Performance screen all update
5. **Hardware Sync**: Sends SysEx, verifies with exponential backoff retries
6. **Hardware Wins**: If hardware differs, cubit emits corrected state, all widgets update again

### Files Modified

**Primary Changes:**
- `lib/ui/widgets/packed_mapping_data_editor.dart` - Add fourth tab, BlocBuilder, dropdown
- `lib/ui/widgets/section_parameter_list_view.dart` - Hide inline dropdown on mobile
- `lib/ui/widgets/mapping_editor_bottom_sheet.dart` - Pass algorithmIndex/parameterNumber

**Test Changes:**
- `test/ui/widgets/packed_mapping_data_editor_test.dart` - Add Performance tab tests

### No Changes Required

- `lib/models/packed_mapping_data.dart` - Already has perfPageIndex field
- `lib/cubit/disting_cubit.dart` - Already has setPerformancePageMapping method
- `lib/domain/sysex/requests/set_performance_page_message.dart` - Already handles SysEx
- `lib/ui/performance_screen.dart` - Already reads from perfPageIndex

### References

- [Tech Spec: docs/tech-spec-epic-6.md] - Complete specification
- [Source: lib/ui/widgets/packed_mapping_data_editor.dart] - 3-tab editor to extend
- [Source: lib/ui/widgets/section_parameter_list_view.dart:272-295] - Inline dropdown to hide on mobile
- [Source: lib/cubit/disting_cubit.dart:1689-1779] - setPerformancePageMapping implementation
- [Source: lib/ui/performance_screen.dart] - Color scheme reference for page badges

## Dev Agent Record

### Context Reference

No context file needed - Level 1 implementation with existing patterns and zero new dependencies.

### Agent Model Used

claude-sonnet-4-5-20250929

### Debug Log References

Implementation followed the exact pattern from tech spec. Added fourth "Performance" tab to PackedMappingDataEditor with BlocBuilder pattern to read cubit state directly. Performance tab calls `setPerformancePageMapping()` directly (same as inline dropdown) for optimistic updates and hardware sync. All tests pass (20/20), flutter analyze passes with zero warnings, build succeeds.

### Completion Notes List

- Successfully added fourth Performance tab to PackedMappingDataEditor following existing tab patterns
- Implemented BlocBuilder to read perfPageIndex from DistingCubit state (zero local state in Performance tab)
- Performance tab calls `setPerformancePageMapping()` directly matching inline dropdown behavior
- Added color-coded page badges (P1-P15) using same color scheme as Performance screen
- Hid inline performance dropdown on mobile screens (width < 600px) using MediaQuery conditional
- Passed algorithmIndex and parameterNumber through mapping editor bottom sheet to enable cubit calls
- All acceptance criteria met including zero flutter analyze warnings
- All 20 tests pass including 3 new Performance tab tests
- Build succeeds on macOS (debug mode verified)

### File List

**Modified:**
- lib/ui/widgets/packed_mapping_data_editor.dart
- lib/ui/widgets/section_parameter_list_view.dart
- lib/ui/widgets/mapping_editor_bottom_sheet.dart
- test/ui/widgets/packed_mapping_data_editor_test.dart

**Created:**
(None - all changes are contained within existing files)

### Change Log

(To be filled during implementation with specific line numbers and changes)
