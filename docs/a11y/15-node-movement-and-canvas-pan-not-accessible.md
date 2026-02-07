# Canvas Pan and Node Movement Are Gesture-Only

**Severity: Medium**

**Status: Addressed (2026-02-06)** — in commit 664e27b

## Files Affected

- `lib/ui/widgets/routing/routing_editor_widget.dart` (lines 1427-1466 pointer signal handler, 1486-1503 canvas gesture detector)
- `lib/ui/widgets/routing/algorithm_node_widget.dart` (lines 650-797 drag handling)
- `lib/ui/widgets/routing/movable_physical_io_node.dart` (lines 269-308 drag handling)

## Description

### Canvas Navigation

The routing canvas is a 5000x5000 pixel area viewed through a viewport. Navigation is only possible via:
- **Mouse wheel/trackpad scroll** (handled by `Listener.onPointerSignal`)
- **Drag to pan** on empty canvas space (`GestureDetector.onPanStart/Update/End`)
- **Pinch to zoom** (zoom modifier + scroll)
- **Mini map click/drag** (visual-only, see finding #06)

There is no keyboard navigation to scroll the canvas viewport. The `Shortcuts` widget handles zoom (Cmd+/Cmd-) but not pan.

### Node Positioning

All nodes (algorithms, physical I/O, ES-5) can only be repositioned via drag gestures. The grid snapping (50px for algorithms, 25px for physical nodes) is automatic but has no keyboard equivalent.

### Double-tap to reset zoom
The canvas supports double-tap to reset zoom (line 1494-1498), but this is gesture-only with no keyboard alternative beyond the Cmd+0 shortcut (desktop only).

## Impact on Blind Users

For fully blind users, canvas pan and node positioning are less important since they would use the accessible list view (once implemented). However, for **keyboard-only** users or **low-vision** users who combine screen magnification with screen reading:

- Cannot scroll the canvas to see different areas
- Cannot reposition nodes for better visual layout
- Cannot zoom without mouse modifier keys on mobile

## Recommended Fix

### 1. Add keyboard pan shortcuts

```dart
shortcuts: {
  // Existing zoom shortcuts...
  // Pan shortcuts
  LogicalKeySet(LogicalKeyboardKey.arrowUp):
      const ScrollIntent(direction: AxisDirection.up, type: ScrollIncrementType.line),
  LogicalKeySet(LogicalKeyboardKey.arrowDown):
      const ScrollIntent(direction: AxisDirection.down, type: ScrollIncrementType.line),
  LogicalKeySet(LogicalKeyboardKey.arrowLeft):
      const ScrollIntent(direction: AxisDirection.left, type: ScrollIncrementType.line),
  LogicalKeySet(LogicalKeyboardKey.arrowRight):
      const ScrollIntent(direction: AxisDirection.right, type: ScrollIncrementType.line),
}
```

### 2. Add "Fit to View" button with semantic label

The `_fitToView()` method exists but is only accessible via the controller. Expose it as a button:

```dart
Semantics(
  label: 'Fit canvas to view all nodes',
  button: true,
  child: IconButton(
    icon: const Icon(Icons.fit_screen),
    tooltip: 'Fit to view',
    onPressed: _fitToView,
  ),
)
```

### 3. For screen reader users, skip canvas navigation entirely

When a screen reader is active, present the accessible list view (finding #01) which doesn't require canvas navigation at all.
