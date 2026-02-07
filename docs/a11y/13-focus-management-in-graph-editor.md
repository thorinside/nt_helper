# Focus Management in Graph Editor Is Visual-Only

**Severity: High**

**Status: Addressed (2026-02-06)** — in commit 664e27b

## Files Affected

- `lib/ui/widgets/routing/routing_editor_widget.dart` (lines 109, 978-983 - FocusNode, lines 1134-1168 - keyboard handling)
- `lib/ui/widgets/routing/algorithm_node_widget.dart` (no focus management)
- `lib/ui/widgets/routing/port_widget.dart` (no focus management)

## Description

The routing editor has a single `FocusNode` (`_canvasFocusNode`) for the entire canvas. This focus node is used to capture keyboard events (Escape for cancel, Delete for connection removal, zoom shortcuts). However:

### 1. No per-node focus traversal
There is no `FocusTraversalGroup` or individual `FocusNode` per algorithm node, port, or connection. A keyboard-only user (or screen reader user using sequential navigation) cannot:
- Tab between nodes
- Navigate to individual ports
- Select connections via keyboard

### 2. No focus indicators on nodes or ports
Algorithm nodes have a visual "selected" state (thicker border via `isSelected`) but this is controlled by tap/click, not keyboard focus. There are no `:focus` visual indicators or `Focus` widgets on nodes.

### 3. Canvas-level keyboard shortcuts only work on desktop
The `Shortcuts` and `Actions` widgets (lines 967-985) are conditionally rendered only for desktop platforms. Mobile/tablet screen reader users have no keyboard/gesture shortcuts.

### 4. No focus restoration after operations
After creating a connection, deleting a connection, or performing an algorithm action (move up/down/delete), focus is not explicitly managed. The canvas focus node remains the sole focused element.

### 5. "Focus mode" in the routing editor (dimming non-focused algorithms) is visual only
The `_focusedAlgorithmIds` and `isDimmed` properties create a visual focus/dim effect for highlighting specific algorithms, but this state is not communicated to the accessibility tree.

## Impact on Blind Users

A screen reader user:
- Cannot navigate between nodes using standard navigation (swipe/Tab)
- Cannot move focus to a specific port to interact with it
- Cannot use keyboard shortcuts on mobile platforms
- Receives no feedback about which element has focus
- Cannot discover the "focus mode" feature (double-click to focus an algorithm)

## Recommended Fix

### 1. Add FocusTraversalGroup for the canvas

```dart
return FocusTraversalGroup(
  policy: OrderedTraversalPolicy(),
  child: _buildLoadedCanvas(context, ...),
);
```

### 2. Make each node focusable

```dart
// In AlgorithmNodeWidget
return Focus(
  onFocusChange: (hasFocus) {
    if (hasFocus) {
      widget.onTap?.call(); // Select on focus
    }
  },
  child: Semantics(
    focusable: true,
    focused: widget.isSelected,
    label: 'Slot ${widget.slotNumber}: ${widget.algorithmName}',
    child: // existing content
  ),
);
```

### 3. Make ports focusable within nodes

```dart
// In PortWidget
return Focus(
  child: Semantics(
    focusable: true,
    label: '${widget.label}, ${widget.isInput ? "input" : "output"}',
    child: // existing content
  ),
);
```

### 4. Implement arrow-key navigation

```dart
KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
  // ... existing escape/delete handling ...

  // Arrow key navigation between nodes
  if (event is KeyDownEvent) {
    if (event.logicalKey == LogicalKeyboardKey.tab) {
      // Move to next/previous node
      _navigateToNextNode(
        reverse: HardwareKeyboard.instance.isShiftPressed
      );
      return KeyEventResult.handled;
    }
  }
  return KeyEventResult.ignored;
}
```

### 5. Announce focus mode changes

```dart
void _handleNodeTap(String nodeId) {
  // ... existing focus logic ...
  if (_focusedAlgorithmIds.contains(nodeId)) {
    final algo = _getAlgorithmById(nodeId);
    SemanticsService.announce(
      'Focused on ${algo.name}. Other algorithms dimmed. Press Escape to clear focus.',
      TextDirection.ltr,
    );
  }
}
```
