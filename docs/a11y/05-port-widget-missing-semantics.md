# Port Widgets Missing Semantic Labels and Roles

**Severity: High**

## Files Affected

- `lib/ui/widgets/routing/port_widget.dart` (lines 185-243, 246-256, 407-498)
- `lib/ui/widgets/port_widget.dart` (lines 48-163)

## Description

### Routing Port Widget (`lib/ui/widgets/routing/port_widget.dart`)

The `PortWidget` in the routing system renders each audio/CV port as a colored dot with a text label. It supports tap, long press, drag, and hover interactions. However, it has **no `Semantics` wrapper** communicating:

- The port's role (input vs output)
- Its connection state (connected/disconnected)
- Its port type (audio vs CV)
- Whether it's highlighted or shadowed
- Available interactions (tap to connect, long-press to delete)

The text label is rendered as a plain `Text` widget, so screen readers may read the label text, but with no context about what it represents or what actions are available.

The `GestureDetector` wrapping the port (line 206) captures tap, long press, and drag gestures but provides no semantic actions:

```dart
portWidget = GestureDetector(
  onTap: widget.onTap,
  onLongPress: ...,
  onPanStart: ...,
  child: portWidget,
);
```

### Top-Level Port Widget (`lib/ui/widgets/port_widget.dart`)

This older PortWidget similarly has no semantic annotations. It renders a 24x24 circle with color-coded signal types and inner dots, but a screen reader just sees a `Container` inside a `GestureDetector`.

## Impact on Blind Users

Screen reader users navigating within a node will encounter port dots and labels without understanding:
- Whether a port is an input or output
- Whether it's connected to something
- What signal type it carries (audio, CV, gate, clock)
- What happens when they interact with it
- That long-pressing will delete connections on that port

The "long-press to delete connection" tooltip hint (shown after hovering for 2 seconds) is visual-only and would not be discovered by a screen reader user.

## Recommended Fix

### 1. Wrap each port in Semantics

```dart
@override
Widget build(BuildContext context) {
  final effectiveTheme = widget.theme ?? Theme.of(context);
  final portTypeLabel = widget.port?.type == PortType.audio ? 'Audio' : 'CV';
  final directionLabel = widget.isInput ? 'Input' : 'Output';
  final connectionLabel = widget.isConnected ? 'Connected' : 'Not connected';
  final shadowLabel = widget.showShadowDot ? ', shadowed by later slot' : '';

  return Semantics(
    label: '${widget.label}, $portTypeLabel $directionLabel, $connectionLabel$shadowLabel',
    hint: widget.isConnected
        ? 'Long press to delete connections. Drag to create new connection.'
        : 'Drag to create a connection.',
    button: true,
    child: // existing port widget build
  );
}
```

### 2. Add semantic custom actions for port operations

```dart
Semantics(
  customSemanticsActions: {
    if (widget.isConnected && widget.onLongPress != null)
      CustomSemanticsAction(label: 'Delete connections'):
          () => widget.onLongPress!(),
    if (widget.onDragStart != null)
      CustomSemanticsAction(label: 'Create connection'):
          () => _startAccessibleConnection(),
  },
  child: // ...
)
```

### 3. Announce connection state changes

When a port's connection state changes (connection created or deleted), announce it:

```dart
if (oldWidget.isConnected != widget.isConnected) {
  SemanticsService.announce(
    '${widget.label} ${widget.isConnected ? "connected" : "disconnected"}',
    TextDirection.ltr,
  );
}
```
