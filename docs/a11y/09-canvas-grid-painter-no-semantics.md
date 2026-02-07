# Canvas Grid Background Painter Has No Semantics

**Severity: Low**

## Files Affected

- `lib/ui/widgets/routing/routing_editor_widget.dart` (lines 1505-1517 - `_CanvasGridPainter`)

## Description

The canvas background grid is rendered via `CustomPaint` with a `_CanvasGridPainter` that draws minor and major grid lines. This grid is purely decorative -- it helps sighted users estimate distances and align nodes but carries no semantic meaning.

The grid painter is used inside a `GestureDetector` for canvas pan/tap handling, but the `CustomPaint` itself has no semantic annotations. Since the grid is purely visual decoration, this is a minor issue.

## Impact on Blind Users

Minimal direct impact. The grid background is decorative. However, the `GestureDetector` wrapping the grid handles canvas tap events (for selecting connections) and pan events (for scrolling). These gesture-based interactions are not accessible without the visual canvas approach.

## Recommended Fix

Mark the grid as decorative and exclude from semantics:

```dart
Semantics(
  excludeSemantics: true,
  child: CustomPaint(
    painter: _CanvasGridPainter(...),
    size: Size(_canvasWidth, _canvasHeight),
  ),
)
```

This ensures screen readers skip the grid entirely rather than trying to announce it.
