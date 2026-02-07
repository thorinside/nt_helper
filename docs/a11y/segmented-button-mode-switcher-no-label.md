# Parameters/Routing Mode Switcher Missing Semantic Context

**Severity:** High

**Status: Addressed (2026-02-06)** — in commit 664e27b

**Files affected:**
- `lib/ui/synchronized_screen.dart` (lines 552-587, `_buildBottomAppBar` segmented button)

## Description

The `SegmentedButton<EditMode>` in the bottom app bar switches between "Parameters" and "Routing" modes. On narrow screens, the text labels are hidden (`label: null` for non-wide screens) and only icons are shown:
- `Icons.tune` for Parameters
- `Icons.account_tree` for Routing

The `ButtonSegment` widgets do not have `tooltip` properties set, so when labels are hidden on mobile, screen readers will only announce the icon's implicit semantic label (which may be generic like "tune" or "account tree").

## Impact on blind users

On mobile/narrow screens, blind users will hear unhelpful icon descriptions like "tune" and "account tree" instead of "Parameters" and "Routing". They won't understand what these mode switches do or which is currently selected.

## Recommended fix

Add `tooltip` to each `ButtonSegment` so the semantic meaning is always available:

```dart
ButtonSegment(
  value: EditMode.parameters,
  label: isWideScreen ? const Text('Parameters') : null,
  icon: const Icon(Icons.tune),
  tooltip: 'Parameters mode',
),
ButtonSegment(
  value: EditMode.routing,
  label: isWideScreen ? const Text('Routing') : null,
  icon: const Icon(Icons.account_tree),
  tooltip: 'Routing mode',
),
```
