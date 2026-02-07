# Mini Map Widget Completely Inaccessible

**Severity: Medium**

**Status: Addressed (2026-02-06)** — in commit 664e27b

## Files Affected

- `lib/ui/widgets/routing/mini_map_widget.dart` (entire file, especially lines 378-427 build method, 431-727 painter)

## Description

The `MiniMapWidget` provides a scaled-down overview of the entire routing canvas for quick navigation. It is rendered entirely via `CustomPainter` (`_MiniMapPainter`) with `GestureDetector` and `MouseRegion` for interaction. There are no `Semantics` annotations anywhere in the widget.

The mini map:
- Shows all node positions as colored rectangles
- Shows all connections as thin lines
- Shows the current viewport rectangle
- Supports tap-to-navigate (tap a location to scroll there)
- Supports drag-to-pan (drag the viewport rectangle)
- Provides hover cursor feedback

All of this visual overview functionality is invisible to screen readers.

## Impact on Blind Users

The mini map is a navigation aid that is inherently visual. A blind user will encounter an unlabeled container when tabbing through the interface. Since the mini map's purpose is visual overview navigation, its absence won't block any core functionality **if** alternative navigation is available.

However, without any semantic label, a screen reader user may be confused by the presence of an interactive but unlabeled widget.

## Recommended Fix

### 1. Hide from accessibility tree with explanation

Since the mini map is purely a visual aid, the simplest fix is to exclude it from the accessibility tree and provide alternative navigation:

```dart
return Semantics(
  excludeSemantics: true,
  label: 'Mini map for visual navigation, not needed with screen reader',
  child: Container(
    // existing mini map content
  ),
);
```

### 2. Alternatively, provide a text-based navigation summary

```dart
if (MediaQuery.of(context).accessibleNavigation) {
  return Semantics(
    label: 'Canvas navigation: ${nodePositions.length} nodes visible. '
           'Use the node list to navigate directly to algorithms.',
    child: const SizedBox.shrink(),
  );
}
```

### 3. Add "Navigate to node" action as alternative

Instead of a visual mini map, provide a dropdown or action that lets screen reader users jump to specific nodes:

```dart
DropdownButton<String>(
  hint: const Text('Jump to node'),
  items: _nodePositions.keys.map((id) =>
    DropdownMenuItem(value: id, child: Text(_getNodeDisplayName(id)))
  ).toList(),
  onChanged: (nodeId) {
    if (nodeId != null) {
      _scrollToPosition(_nodePositions[nodeId]!);
    }
  },
)
```
