# Physical I/O and ES-5 Nodes Have Semantics But Are Incomplete

**Severity: Medium**

**Status: Addressed (2026-02-06)** — in commit 664e27b

## Files Affected

- `lib/ui/widgets/routing/physical_input_node.dart` (lines 92-119)
- `lib/ui/widgets/routing/physical_output_node.dart` (lines 92-120)
- `lib/ui/widgets/routing/es5_node.dart` (lines 94-123)
- `lib/ui/widgets/routing/movable_physical_io_node.dart` (lines 129-173, 204-267)

## Description

Unlike `AlgorithmNodeWidget`, the physical I/O nodes DO have top-level `Semantics` wrappers. This is commendable:

```dart
// PhysicalInputNode
Semantics(
  label: 'Inputs',
  hint: 'Hardware input jacks. These act as outputs to algorithms.',
  child: MovablePhysicalIONode(...)
)

// PhysicalOutputNode
Semantics(
  label: 'Outputs',
  hint: 'Hardware output jacks. These act as inputs from algorithms.',
  child: MovablePhysicalIONode(...)
)

// ES5Node
Semantics(
  label: 'ES-5 Expander',
  hint: 'ES-5 Eurorack expander jacks. Receives signals from algorithms and outputs to hardware.',
  child: MovablePhysicalIONode(...)
)
```

However, the semantics are incomplete:

### 1. No port count in labels
The labels say "Inputs" and "Outputs" but don't say how many (12 inputs, 8 outputs). This would help a blind user understand the scope.

### 2. No connection state summary
The semantics don't indicate how many ports are currently connected, which would be valuable overview information.

### 3. Individual port rows lack Semantics
Inside `MovablePhysicalIONode._buildPortRow()` (line 217-267), each port is rendered via `PortWidget` which has no Semantics (see finding #05). The port labels are plain `Text` but the jack dots and their connection/highlight states are not semantically annotated.

### 4. Node dragging has no keyboard alternative
The `MovablePhysicalIONode` only supports drag-based repositioning via `GestureDetector.onPanStart/Update/End`. No keyboard alternative exists for moving these nodes.

### 5. Header row is not marked as a heading
The `_buildHeader` method (line 176-201) renders the title text but doesn't mark it as a semantic heading, which would help screen readers understand the node structure.

## Impact on Blind Users

Blind users will find the physical I/O nodes with VoiceOver/TalkBack and hear "Inputs - Hardware input jacks. These act as outputs to algorithms." This is better than nothing but still insufficient for actual use. They won't be able to:
- Enumerate which specific jacks are available
- Know which jacks are connected
- Interact with individual jacks to create/remove connections
- Reposition nodes (minor concern for accessibility)

## Recommended Fix

### 1. Enhance node labels with counts and state

```dart
Semantics(
  label: 'Inputs: ${ports.length} hardware input jacks, '
         '${ports.where((p) => p.isConnected).length} connected',
  hint: 'Hardware input jacks. These act as outputs to algorithms. '
        'Navigate inside to explore individual ports.',
  container: true,
  child: MovablePhysicalIONode(...)
)
```

### 2. Mark header as semantic heading

```dart
Widget _buildHeader(ColorScheme colorScheme, ThemeData theme) {
  return Semantics(
    header: true,
    child: Container(
      // existing header content
    ),
  );
}
```

### 3. Add connection count per port

```dart
Widget _buildPortRow(Port port) {
  final connectionCount = widget.connectedPorts?.contains(port.id) == true ? 1 : 0;

  return Semantics(
    label: '${port.name}, ${port.type == PortType.audio ? "audio" : "CV"}, '
           '${connectionCount > 0 ? "connected" : "not connected"}',
    child: // existing port widget
  );
}
```
