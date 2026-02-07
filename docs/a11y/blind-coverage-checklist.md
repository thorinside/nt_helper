# Blind Coverage Checklist

This checklist focuses specifically on accessibility coverage for blind and screen-reader users.

## Automated coverage now in place

1. Routing port semantics:
   - Verifies role, label, state, and action hint for connected/disconnected ports.
   - Test file: `test/ui/accessibility/widget_semantics_test.dart`

2. Parameter value announcements:
   - Verifies semantic output for boolean, enumerated, and MIDI note values.
   - Confirms note values are exposed as live regions for screen-reader updates.
   - Test file: `test/ui/accessibility/widget_semantics_test.dart`

3. Accessible routing list workflow:
   - Verifies algorithm and connection summaries are exposed in semantics.
   - Verifies explicit empty-state messaging when no connections exist.
   - Test file: `test/ui/accessibility/routing_accessibility_test.dart`

4. Live announcement flows:
   - Verifies `SemanticsService.sendAnnouncement` for sync/firmware progress, success, and failure transitions.
   - Test file: `test/ui/accessibility/semantics_announcements_test.dart`

## Remaining blind-coverage gaps

1. Keyboard-only routing:
   - Add tests for fully non-pointer connection creation/deletion using keyboard actions only.

2. Focus lifecycle:
   - Add tests for dialog open/close focus placement and focus restoration.

3. Step sequencer non-visual editing:
   - Add tests that validate semantic grouping and value announcements for step editing controls.

## Definition of done for blind coverage

1. Core workflows (connect, edit, save, delete) have semantic labels and role assertions.
2. Dynamic state changes produce verifiable announcements or live-region updates.
3. Keyboard-only alternatives are tested for all pointer-first interactions.
4. Empty states and errors are explicitly announced in text and semantics.
