# No Focus Traversal Groups or Policies in App

**Severity: Critical**

**Status: Addressed (2026-02-06)** — in commit 664e27b

## Files Affected
- `lib/ui/synchronized_screen.dart`
- `lib/ui/widgets/routing/routing_editor_widget.dart`
- `lib/ui/performance_screen.dart`
- All screens

## Description

The app contains **zero** instances of `FocusTraversalGroup`, `FocusTraversalPolicy`, or `OrderedTraversalPolicy`. Without these, keyboard Tab navigation follows the default widget tree order, which may not match the logical reading order for the app's complex layouts.

Currently only 3 files use `FocusNode`:
- `routing_editor_widget.dart` - single canvas focus node
- `add_algorithm_screen.dart` - view focus node for keyboard handling
- `bpm_editor_widget.dart` - single focus node

Individual interactive elements (parameter rows, ports, nodes, buttons) do not have their own focus nodes, making it impossible to Tab to them.

## Impact on Blind Users

- Tab key navigation is essentially broken for the main workflow
- Users cannot Tab through parameter rows, algorithm tabs, or routing nodes
- Focus order is unpredictable in complex layouts (sidebar + main content + bottom bar)
- After closing dialogs, focus is not restored to the trigger element
- There is no way to navigate the routing canvas by keyboard at all

## Recommended Fix

1. Add `FocusTraversalGroup` with `OrderedTraversalPolicy` to each major screen section
2. Make every interactive element focusable with its own `FocusNode`
3. Implement focus restoration after dialog/sheet dismissal
4. See [keyboard-navigation-scheme.md](keyboard-navigation-scheme.md) section 2 for the complete focus management strategy
