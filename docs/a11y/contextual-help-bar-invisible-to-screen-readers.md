# Contextual Help Bar and HelpHoverRegion Invisible to Screen Readers

**Severity: Medium**

**Status: Addressed (2026-02-06)** — in commit 664e27b

## Files Affected
- `lib/ui/widgets/contextual_help_bar.dart` (lines 1-88)

## Description

The `ContextualHelpBar` shows hint text when users hover over interactive elements (e.g., "Double-click: Focus algorithm UI  |  Long-press: Rename algorithm"). It is triggered by `MouseRegion.onEnter`/`onExit` events via the `HelpHoverRegion` wrapper.

This entire system is mouse-hover-only:
- `MouseRegion` does not fire on touch or screen reader focus
- The bar animates to height 0 when no help is shown (line 21), effectively hiding it
- The help text contains critical discoverability information about gesture shortcuts

## Impact on Blind Users

- All contextual help text is inaccessible - screen reader users never see "Double-click to..." hints
- The help system is designed around mouse hover, a modality that doesn't exist for screen reader users
- This means the gesture-based shortcuts described in the help text are doubly inaccessible: both the hints and the gestures themselves

## Recommended Fix

Rather than trying to make hover-based help work for screen readers, the solution is to:
1. Add the help information directly to the `Semantics` hints of the widgets themselves
2. Use `Semantics(hint: ...)` on interactive elements to provide the same information

```dart
// Instead of relying on ContextualHelpBar, put hints on the widget:
Semantics(
  hint: 'Double-tap to focus hardware display. Long-press to rename.',
  child: ListTile(...),
)
```

The `ContextualHelpBar` itself could also be made accessible as a live region for when it does have content:

```dart
Semantics(
  liveRegion: true,
  child: AnimatedContainer(...),
)
```
