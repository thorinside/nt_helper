# Connection Deletion Requires Visual-Only Interactions

**Severity: High**

**Status: Addressed (2026-02-06)** — Semantics with customSemanticsActions for delete on interactive_connection_widget.dart, connection delete announcements via SemanticsService

## Files Affected

- `lib/ui/widgets/routing/interactive_connection_widget.dart` (lines 73-121 - hover/tap/long-press handlers)
- `lib/ui/widgets/routing/routing_editor_widget.dart` (connection highlight/delete via canvas tap, lines 1488-1493)
- `lib/ui/widgets/routing/port_widget.dart` (lines 148-178 - hover hint for delete)

## Description

Connection deletion is implemented through three interaction patterns, none of which are accessible:

### 1. Desktop: Hover + Click on Connection Line
On desktop, hovering over a connection bezier curve highlights it, then clicking deletes it. This is implemented via `InteractiveConnectionWidget` using `MouseRegion` + `GestureDetector`. The hover detection uses `_ConnectionHoverPainter.hitTest()` which performs path proximity testing. Screen readers don't generate hover events.

### 2. Mobile: Tap Connection Label on Canvas
Tapping near a connection's bus label on the canvas selects/highlights the connection. This depends on visual hit-testing of painted labels via `ConnectionPainter._labelBounds`. The label overlay tap targets (`_buildConnectionLabelOverlays()`) are invisible semantic elements.

### 3. Port Long-Press Delete Animation
Long-pressing a connected port initiates a color animation (red -> orange -> white -> fade out) that deletes all connections on that port. This is discoverable only via:
- A tooltip that appears after hovering for 2 seconds (visual only)
- No semantic announcement of the action or its progress

The animated deletion (`_handlePortLongPressStart`, `_deleteAnimationController`) provides visual feedback during the long press but no audio/haptic/semantic feedback.

### 4. Delete Key on Selected Connection (Desktop Only)
After clicking a connection label to select it, pressing Delete/Backspace removes it. This is keyboard-accessible but requires the visual selection step first.

## Impact on Blind Users

A blind user cannot:
- Select a connection for deletion (requires visual identification and click/tap)
- Discover the long-press-to-delete-port-connections gesture
- Receive feedback during the deletion animation
- Know which connections would be deleted by a port long-press

## Recommended Fix

### 1. Add connection deletion to accessible routing list

In the accessible list view (see finding #01), each connection should have a delete action:

```dart
ListTile(
  title: Text('Slot 1 Audio Out -> Output 3 (Bus O3)'),
  trailing: Semantics(
    label: 'Delete this connection',
    child: IconButton(
      icon: const Icon(Icons.delete),
      onPressed: () => _deleteConnection(conn.id),
    ),
  ),
)
```

### 2. Add custom semantic action for port connection deletion

```dart
Semantics(
  customSemanticsActions: {
    CustomSemanticsAction(label: 'Delete all connections on this port'):
        () => _handlePortLongPress(port),
  },
  child: portWidget,
)
```

### 3. Announce deletion progress and completion

```dart
void _handlePortLongPressStart(Port port) {
  // ... existing code ...
  SemanticsService.announce(
    'Hold to delete ${connectionsToDelete.length} connections on ${port.name}',
    TextDirection.ltr,
  );
}

void _onFadeOutAnimationStatus(AnimationStatus status) {
  if (status == AnimationStatus.completed) {
    // ... existing deletion code ...
    SemanticsService.announce(
      'Connections deleted from ${_deletingPort!.name}',
      TextDirection.ltr,
    );
  }
}
```
