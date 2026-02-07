# Performance Page Badges Rely on Color and Short Labels

**Severity: Medium**

**Status: Addressed (2026-02-06)** — in commit 664e27b

## Files Affected
- `lib/ui/widgets/section_parameter_list_view.dart` (lines 109-130, 160-187)

## Description

Performance parameter rows include a colored `Chip` badge showing "P1", "P2", etc. (line 121) with color-coded backgrounds (blue, green, orange, purple, red). The remove button (line 181) is an `IconButton` with `Icons.close` and a tooltip.

Issues:
- The "P1", "P2" labels are cryptic - a screen reader will read "P1" with no context
- Colors differentiate pages but are meaningless to screen reader users
- The `Chip` widget has no semantic label explaining what "P1" means
- The remove button tooltip "Remove from performance page" is good
- The performance page `DropdownButton` (line 291) has a hint "Page" but no label explaining what it does

## Impact on Blind Users

- "P1" is read but not understood - should be "Performance page 1"
- The entire performance page concept (assigning parameters to hardware knob pages) is not explained
- The inline dropdown for page assignment (desktop only) says "Page" but a screen reader user doesn't know this assigns the parameter to a hardware performance page

## Recommended Fix

```dart
Widget _buildPageBadge(int pageIndex) {
  return Semantics(
    label: 'Performance page $pageIndex',
    child: Chip(
      label: Text('P$pageIndex'),
      ...
    ),
  );
}

// For the page selector dropdown
Semantics(
  label: 'Assign to performance page',
  child: DropdownButton<int>(
    ...
  ),
)
```
