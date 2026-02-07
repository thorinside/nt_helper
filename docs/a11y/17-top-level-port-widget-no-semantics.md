# Top-Level Port Widget Has No Semantic Information

**Severity: Medium**

## Files Affected

- `lib/ui/widgets/port_widget.dart` (entire file, lines 1-216)

## Description

The top-level `PortWidget` (in `lib/ui/widgets/port_widget.dart`, distinct from `lib/ui/widgets/routing/port_widget.dart`) is used elsewhere in the app for rendering connection ports outside the routing editor context. It has:

- **No `Semantics` wrapper** on the entire widget
- Port identity determined only by color (signal type color-coding via `_getPortTypeColor()`)
- Connection state shown only visually (dot size changes from 6 to 8 when connected)
- Hover/press states shown only via box shadow and opacity changes
- The `GestureDetector` wrapping it captures pan/tap events with no semantic actions

The widget is a 24x24 circle rendered as a `Container` with `BoxDecoration`:

```dart
child: Container(
  width: 24,
  height: 24,
  margin: const EdgeInsets.symmetric(vertical: 4),
  decoration: BoxDecoration(
    shape: BoxShape.circle,
    color: _getPortColor(),
    border: Border.all(...)
  ),
  child: Center(
    child: AnimatedContainer(
      // Inner dot showing connection state
    ),
  ),
)
```

A screen reader will encounter this as an unlabeled container with no description of what the port represents, its signal type, or its connection state.

## Impact on Blind Users

This widget is used in non-routing contexts. Blind users encountering it will hear nothing meaningful -- just an interactive area with no description. They cannot determine:
- What the port represents
- Whether it's connected
- What type of signal it carries
- What interactions are available

## Recommended Fix

### 1. Add Semantics wrapper

```dart
@override
Widget build(BuildContext context) {
  final portTypeLabel = _getPortTypeLabel();
  final typeLabel = widget.type == PortType.input ? 'Input' : 'Output';
  final connectionLabel = widget.isConnected ? 'Connected' : 'Not connected';

  return Semantics(
    label: '${widget.port.name}, $portTypeLabel $typeLabel, $connectionLabel',
    hint: widget.type == PortType.output
        ? 'Drag to create connection'
        : 'Drop connection target',
    button: true,
    child: GestureDetector(
      // ... existing gesture handling
    ),
  );
}

String _getPortTypeLabel() {
  final portName = widget.port.name.toLowerCase();
  if (portName.contains('audio') || portName.contains('signal')) return 'Audio';
  if (portName.contains('cv') || portName.contains('control')) return 'CV';
  if (portName.contains('gate') || portName.contains('trigger')) return 'Gate';
  if (portName.contains('clock') || portName.contains('sync')) return 'Clock';
  return 'Signal';
}
```
