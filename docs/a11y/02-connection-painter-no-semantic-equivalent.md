# ConnectionPainter (CustomPainter) Has No Semantic Equivalent

**Severity: Critical**

**Status: Partially addressed (2026-02-06)** — in commit 664e27b. Remaining: connection_painter.dart not modified

## Files Affected

- `lib/ui/widgets/routing/connection_painter.dart` (entire file, especially lines 70-1027)
- `lib/ui/widgets/routing/routing_editor_widget.dart` (lines 1521-1527, 1562-1569)

## Description

All connections between nodes are rendered entirely via `CustomPainter` (`ConnectionPainter`). This class draws bezier curves, bus labels, endpoint dots, animated ghost connections, and delete animations directly onto a `Canvas`. CustomPainter output is completely invisible to the accessibility tree.

The `ConnectionPainter` renders:
- Regular connections (solid bezier curves)
- Ghost connections (dashed lines with animated flow dots)
- Invalid connections (dashed error-colored lines)
- Partial connections (short dashed lines with bus labels)
- Connection labels (bus numbers like "I1", "O3", "A2")
- Delete animation states (color transitions)

**None of this information** is available to screen readers. The connection labels painted on the canvas (e.g., "O3 R" for Output 3 in Replace mode) contain critical routing information that blind users cannot access.

## Impact on Blind Users

A blind user cannot:
- Know which ports are connected to which
- Understand bus assignments (I1-I12, O1-O8, A1-A8)
- Detect invalid/backward connections that will cause audio problems
- Identify ghost connections vs direct connections
- See output mode indicators (Replace vs Add)

## Recommended Fix

### 1. Add Semantics overlay for each connection

For every rendered connection, create a corresponding Semantics node in the widget tree:

```dart
// In routing_editor_widget.dart, alongside _buildConnections()
Widget _buildConnectionSemantics(List<Connection> connections) {
  return Semantics(
    container: true,
    label: 'Connections',
    child: Column(
      children: connections.map((conn) {
        final sourceName = _getPortDisplayName(conn.sourcePortId);
        final destName = _getPortDisplayName(conn.destinationPortId);
        final busLabel = BusLabelFormatter.formatBusNumber(conn.busNumber);
        final statusPrefix = conn.isGhostConnection
            ? 'Ghost connection: '
            : conn.isBackwardEdge
                ? 'Invalid connection: '
                : 'Connection: ';

        return Semantics(
          label: '$statusPrefix$sourceName to $destName via bus $busLabel',
          hint: 'Double tap to select, then delete to remove',
          button: true,
          child: const SizedBox.shrink(), // Invisible but in semantic tree
        );
      }).toList(),
    ),
  );
}
```

### 2. Provide semantic annotations for the SemanticsBuilder

Override `SemanticsBuilder` in `ConnectionPainter` to declare semantic regions:

```dart
@override
SemanticsBuilderCallback get semanticsBuilder {
  return (Size size) {
    return connections.map((conn) {
      final midpoint = Offset(
        (conn.sourcePosition.dx + conn.destinationPosition.dx) / 2,
        (conn.sourcePosition.dy + conn.destinationPosition.dy) / 2,
      );
      return CustomPainterSemantics(
        rect: Rect.fromCenter(center: midpoint, width: 60, height: 30),
        properties: SemanticsProperties(
          label: 'Connection: ${conn.connection.sourcePortId} to ${conn.connection.destinationPortId}',
          value: 'Bus ${conn.busNumber ?? "unassigned"}',
        ),
      );
    }).toList();
  };
}
```
