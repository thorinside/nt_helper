# Algorithm Node Widget Missing Semantics for Node Identity and State

**Severity: Critical**

## Files Affected

- `lib/ui/widgets/routing/algorithm_node_widget.dart` (lines 170-227 - build method)
- `lib/ui/widgets/routing/routing_editor_widget.dart` (lines 1863-1992 - node instantiation)

## Description

`AlgorithmNodeWidget` renders each algorithm slot as a visual card with a title bar, input/output ports, toolbar actions, and visual state indicators (selection highlight, dimming for focus mode, collapse toggle). However, the widget has **zero `Semantics` wrapping** -- unlike `PhysicalInputNode`, `PhysicalOutputNode`, and `ES5Node` which each have a top-level `Semantics` wrapper.

The `build()` method returns a `GestureDetector` wrapping an `AnimatedContainer` with no semantic annotations:

```dart
Widget content = GestureDetector(
  onTap: () { widget.onTap?.call(); },
  onPanStart: _handleDragStart,
  onPanUpdate: _handleDragUpdate,
  onPanEnd: _handleDragEnd,
  child: AnimatedContainer(
    // ... visual styling only
  ),
);
```

While the title bar text (`#1 VCA`) is visually rendered, a screen reader will not announce the algorithm name, slot number, selection state, or available actions in a meaningful grouped way.

Additionally:
- The "Move Up"/"Move Down" `IconButton` widgets DO have tooltips, which is good
- The overflow `PopupMenuButton` has a tooltip ("More"), which is okay
- But the mapping icon has no semantic label
- The collapse toggle (`_buildCollapseToggle`) uses `GestureDetector` instead of a button, so it's not keyboard-accessible and has no semantic role

## Impact on Blind Users

When navigating the routing editor, a screen reader user will encounter algorithm nodes as an unstructured collection of buttons and text with no grouping or context. They won't know:
- Which algorithm they're interacting with
- What slot number it occupies
- Whether it's currently selected/focused
- Whether it's dimmed (not in focus mode)
- How many ports it has or which are connected

## Recommended Fix

### 1. Wrap the entire node in Semantics

```dart
@override
Widget build(BuildContext context) {
  final theme = Theme.of(context);

  Widget content = Semantics(
    label: 'Algorithm: ${widget.algorithmName}, Slot ${widget.slotNumber}',
    hint: widget.isSelected
        ? 'Selected. Double tap to deselect.'
        : 'Double tap to select and focus.',
    container: true,
    selected: widget.isSelected,
    child: GestureDetector(
      // ... existing code
    ),
  );
  // ...
}
```

### 2. Add semantic label to the mapping icon

```dart
if (_hasAnyMappings()) ...[
  Semantics(
    label: 'Has parameter mappings',
    child: Container(
      // existing mapping icon code
    ),
  ),
],
```

### 3. Make collapse toggle a proper button

```dart
Widget _buildCollapseToggle(ThemeData theme) {
  return Semantics(
    button: true,
    label: _isCollapsed
        ? 'Show ${ _unconnectedPortCount()} hidden ports'
        : 'Hide unconnected ports',
    child: InkWell(  // Use InkWell instead of GestureDetector
      onTap: () {
        setState(() { _isCollapsed = !_isCollapsed; });
        _scheduleSizeReport();
      },
      child: // ... existing visual content
    ),
  );
}
```

### 4. Announce state changes

```dart
// When focus/selection changes
if (widget.isDimmed) {
  SemanticsService.announce(
    '${widget.algorithmName} dimmed, not in focus',
    TextDirection.ltr,
  );
}
```
