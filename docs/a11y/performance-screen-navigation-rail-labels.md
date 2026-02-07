# Performance Screen: Navigation Rail Page Labels Not Accessible

**Severity:** High

**Status: Addressed (2026-02-06)** — in commit 664e27b

**Files affected:**
- `lib/ui/performance_screen.dart` (lines 117-140, `_buildPageBadge`)
- `lib/ui/performance_screen.dart` (lines 300-314, NavigationRail setup)

## Description

The performance screen uses a `NavigationRail` with custom badge widgets for page selection. Each `NavigationRailDestination` has:
- `icon`: A custom colored badge showing "P1", "P2", etc.
- `label`: `const Text('')` (empty string!)

The `NavigationRailLabelType` is set to `none`, and the label is an empty `Text('')`. This means screen readers have almost no useful information about what each navigation destination represents.

The custom `_buildPageBadge` widget is a `Container` with a `Text` child showing "P1", "P2", etc. - this text may or may not be read by the screen reader depending on the semantic tree, but the colors (which visually distinguish pages) are completely lost.

## Impact on blind users

Blind users navigating the performance page selector will hear either nothing meaningful or just "P1", "P2" with no context about what these pages contain or how many parameters are on each page. The color coding that sighted users rely on is completely invisible.

## Recommended fix

1. Provide meaningful labels to each `NavigationRailDestination`:

```dart
NavigationRailDestination(
  icon: _buildPageBadge(pageIndex, isSelected: isSelected),
  label: Text('Performance Page $pageIndex'),
  // Could also include parameter count:
  // label: Text('Page $pageIndex (${pageParams.length} parameters)'),
)
```

2. Change `labelType` to `NavigationRailLabelType.all` or at minimum `selected`:

```dart
labelType: NavigationRailLabelType.all,
```

3. Add `Semantics` to the badge widget:

```dart
Semantics(
  label: 'Performance page $pageIndex${isSelected ? ", selected" : ""}',
  child: Transform.scale(...),
)
```
