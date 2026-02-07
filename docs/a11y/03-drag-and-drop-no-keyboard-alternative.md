# Drag-and-Drop Connection Creation Has No Keyboard/Accessible Alternative

**Severity: Critical**

**Status: Addressed (2026-02-06)** — in commit 664e27b

## Files Affected

- `lib/ui/widgets/routing/routing_editor_widget.dart` (connection drag handling throughout)
- `lib/ui/widgets/routing/port_widget.dart` (lines 206-238 - gesture detection)
- `lib/ui/widgets/routing/movable_physical_io_node.dart` (lines 133-136, 269-308 - node dragging)
- `lib/ui/widgets/routing/algorithm_node_widget.dart` (lines 174-179, 650-797 - node dragging)

## Description

The only way to create connections between ports is by dragging from one port to another. This is implemented via `GestureDetector` with `onPanStart`, `onPanUpdate`, and `onPanEnd` callbacks. There is no keyboard-accessible or screen reader-accessible alternative.

Similarly, moving nodes on the canvas is only possible via drag gestures (`onPanStart`/`onPanUpdate`/`onPanEnd`).

The connection creation flow:
1. User starts a drag gesture on a port (output or input)
2. A temporary connection line follows the drag position
3. When the drag ends near a compatible port, the connection is created
4. There is NO menu, dialog, or keyboard shortcut to create connections

## Impact on Blind Users

Blind users **cannot create or modify the routing graph at all**. Since the entire connection creation workflow requires:
1. Visually locating a source port
2. Performing a precise drag gesture to a target port
3. Visually confirming the connection was made

...a screen reader user is completely locked out of the core feature of this app.

## Recommended Fix

### 1. Port-tap connection creation mode

When a screen reader is active (or as a general accessibility feature), implement a "tap to connect" mode:

```dart
void _handlePortTapAccessible(Port port) {
  if (_pendingConnectionSourcePort == null) {
    // First tap: select source port
    setState(() {
      _pendingConnectionSourcePort = port;
    });
    SemanticsService.announce(
      'Selected ${port.name} as connection source. Tap a destination port to connect.',
      TextDirection.ltr,
    );
  } else {
    // Second tap: create connection
    _createConnectionWithErrorHandling(
      context.read<RoutingEditorCubit>(),
      _pendingConnectionSourcePort!.id,
      port.id,
    );
    setState(() {
      _pendingConnectionSourcePort = null;
    });
  }
}
```

### 2. "Connect to..." context menu on ports

Add a context action or long-press menu on each port that lists compatible destination ports:

```dart
Widget _buildAccessiblePortMenu(Port sourcePort, List<Port> allPorts) {
  final compatiblePorts = allPorts.where(
    (p) => _isCompatibleConnection(sourcePort, p)
  ).toList();

  return PopupMenuButton<Port>(
    child: Semantics(
      label: '${sourcePort.name}, ${sourcePort.isConnected ? "connected" : "not connected"}',
      hint: 'Double tap to open connection menu',
      child: _buildPortDot(theme),
    ),
    itemBuilder: (context) => compatiblePorts.map((target) =>
      PopupMenuItem(
        value: target,
        child: Text('Connect to ${_getPortDisplayName(target.id)}'),
      ),
    ).toList(),
    onSelected: (targetPort) {
      _createConnectionWithErrorHandling(
        context.read<RoutingEditorCubit>(),
        sourcePort.id,
        targetPort.id,
      );
    },
  );
}
```

### 3. Keyboard shortcuts for connection management

On desktop, add keyboard shortcuts:
- `Tab` to cycle through nodes
- `Enter` on a node to enter its port list
- `Space` on a port to start/complete a connection
- `Delete` to remove a selected connection
- `Arrow keys` to navigate between ports within a node
