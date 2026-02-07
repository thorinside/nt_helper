# Ghost and Invalid Connection Tooltips Are Hover-Only

**Severity: Medium**

**Status: Addressed (2026-02-06)** — in commit 664e27b

## Files Affected

- `lib/ui/widgets/routing/ghost_connection_tooltip.dart` (lines 96-116, 140-167)
- `lib/ui/widgets/routing/invalid_connection_tooltip.dart` (lines 105-125, 155-181)

## Description

Both `GhostConnectionTooltip` and `InvalidConnectionTooltip` display detailed explanations about connection types only on mouse hover (`MouseRegion` with `onEnter`/`onExit`). The tooltip content includes:

**Ghost connections:**
- "Ghost Connection" header
- Explanation of indirect routing path (algorithm output to physical input)
- Gain values
- Mute status

**Invalid connections:**
- "Invalid Connection Order" header
- Explanation of slot ordering constraint
- Source/destination slot numbers
- Actionable fix guidance ("Use the up/down arrows to reorder algorithms")

This information is critical for understanding routing problems but is only available via mouse hover over a small (40x20px) transparent hit area positioned at the connection midpoint.

```dart
// ghost_connection_tooltip.dart line 1148-1159
return Positioned(
  left: midpoint.dx - 20,  // 40px wide hit area
  top: midpoint.dy - 10,   // 20px tall hit area
  child: GhostConnectionTooltip(
    connection: conn.connection,
    child: Container(
      width: 40,
      height: 20,
      color: Colors.transparent,  // Invisible to screen readers
    ),
  ),
);
```

The tooltip widgets use `IgnorePointer` for the content, meaning even if a screen reader could reach them, they wouldn't be interactive.

## Impact on Blind Users

Blind users cannot discover:
- That a connection is a "ghost" (indirect) connection
- That a connection has invalid slot ordering (a common user error)
- The suggested fix for invalid connections
- Gain or mute modifications on connections

This means routing problems will be invisible and unfixable without sighted assistance.

## Recommended Fix

### 1. Include connection state in semantic labels

Rather than relying on hover tooltips, encode this information directly in the connection's semantic label:

```dart
String _getConnectionSemanticLabel(Connection conn) {
  final source = _getPortDisplayName(conn.sourcePortId);
  final dest = _getPortDisplayName(conn.destinationPortId);

  final parts = <String>['$source to $dest'];

  if (conn.isGhostConnection) {
    parts.add('Ghost connection, indirect routing path');
  }
  if (conn.isBackwardEdge) {
    parts.add('Warning: Invalid slot order. Source must come before destination. Use move up/down to fix.');
  }
  if (conn.gain != 1.0) {
    parts.add('Gain: ${conn.gain.toStringAsFixed(2)}');
  }
  if (conn.isMuted) {
    parts.add('Muted');
  }

  return parts.join('. ');
}
```

### 2. Surface warnings proactively for screen readers

When an invalid connection is detected, announce it:

```dart
if (conn.isBackwardEdge) {
  SemanticsService.announce(
    'Warning: Connection from ${_getPortDisplayName(conn.sourcePortId)} '
    'to ${_getPortDisplayName(conn.destinationPortId)} has invalid slot order. '
    'Reorder algorithms to fix.',
    TextDirection.ltr,
  );
}
```

### 3. Add error summary section in accessible routing list

```dart
if (invalidConnections.isNotEmpty) {
  Semantics(
    header: true,
    liveRegion: true,
    child: Text(
      '${invalidConnections.length} routing warnings',
      style: TextStyle(color: theme.colorScheme.error),
    ),
  ),
}
```
