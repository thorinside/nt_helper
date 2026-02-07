# Routing Canvas Has No Meaningful Screen Reader Representation

**Severity: Critical**

**Status: Addressed (2026-02-06)** — AccessibleRoutingListView created with algorithm/connection sections, auto-detects accessibleNavigation, manual toggle button added

## Files Affected

- `lib/ui/widgets/routing/routing_editor_widget.dart` (lines 1409-1414, 1479-1589)
- `lib/ui/widgets/routing/connection_painter.dart` (entire file)

## Description

The routing canvas is the core interaction surface for wiring audio/CV connections between algorithm slots. For sighted users it renders as a visual node graph on a 5000x5000 canvas with draggable nodes and bezier curve connections. For screen reader users, the canvas is almost completely invisible.

The only `Semantics` widget on the entire canvas is a single top-level container label:

```dart
Semantics(
  label: 'Routing canvas with ${algorithms.length} algorithm nodes and ${connections.length} connections',
  hint: 'Interactive routing canvas. Pan and zoom to navigate. Drag between ports to create connections.',
  container: true,
  child: ...
)
```

This tells a blind user that a routing canvas exists and how many nodes/connections there are, but provides **zero information about**:

- Which algorithms are loaded in which slots
- What connections exist (source, destination, bus assignment)
- Which ports are available on each algorithm
- The current state of any connection (ghost, invalid order, partial)
- What actions are available

## Impact on Blind Users

A VoiceOver/TalkBack user entering the routing editor will hear "Routing canvas with 3 algorithm nodes and 5 connections" and then have **no way to explore, understand, or modify** the routing graph. The entire routing system -- the primary feature of this app for complex patches -- is completely inaccessible.

## Recommended Fix

The visual canvas should be supplemented with a parallel accessible representation. Two approaches (both recommended):

### 1. Add a "Routing List View" alternative mode

Create a non-visual list-based representation that screen reader users can navigate:

```dart
// Toggle between visual canvas and accessible list view
if (accessibilityMode) {
  return _buildAccessibleRoutingList(algorithms, connections);
} else {
  return _buildVisualCanvas(...);
}

Widget _buildAccessibleRoutingList(
  List<RoutingAlgorithm> algorithms,
  List<Connection> connections,
) {
  return ListView(
    children: [
      // Section: Algorithms
      Semantics(
        header: true,
        child: Text('Algorithms'),
      ),
      for (final algo in algorithms)
        Semantics(
          label: 'Slot ${algo.index + 1}: ${algo.algorithm.name}',
          hint: 'Double tap to view connections and ports',
          child: ListTile(
            title: Text('#${algo.index + 1} ${algo.algorithm.name}'),
            subtitle: Text(
              '${algo.inputPorts.length} inputs, ${algo.outputPorts.length} outputs'
            ),
            onTap: () => _showAlgorithmConnectionDetails(algo),
          ),
        ),

      // Section: Active Connections
      Semantics(
        header: true,
        child: Text('Connections'),
      ),
      for (final conn in connections)
        _buildAccessibleConnectionTile(conn),
    ],
  );
}
```

### 2. Detect screen reader and auto-switch

```dart
final isScreenReaderActive = MediaQuery.of(context).accessibleNavigation;

if (isScreenReaderActive) {
  return _buildAccessibleRoutingList(...);
}
```

### 3. Announce connection changes

Use `SemanticsService.announce()` when connections are created, deleted, or modified:

```dart
import 'package:flutter/semantics.dart';

SemanticsService.announce(
  'Connection created from Slot 1 Audio Out to Output 3',
  TextDirection.ltr,
);
```
