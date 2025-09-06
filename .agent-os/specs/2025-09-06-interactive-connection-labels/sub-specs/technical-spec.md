# Technical Specification

This is the technical specification for the spec detailed in @.agent-os/specs/2025-09-06-interactive-connection-labels/spec.md

## Technical Requirements

### 1. Add Hover Support to ConnectionPainter (Minimal Changes)
- Add `onLabelHover` and `onLabelTap` optional callbacks to `ConnectionData` class (2 fields)
- Extend `_drawConnectionLabel()` to store label bounds in a `Map<String, Rect>` (5 lines)
- No custom RenderObject needed - reuse existing painting patterns

### 2. Wrap ConnectionCanvas with MouseRegion (Existing Pattern)
- Reuse the exact pattern from `GhostConnectionTooltip` (lines 151-153 in connection_painter.dart)
- Add hit testing logic to check if hover point intersects stored label bounds (10 lines)
- Call appropriate ConnectionData callback when hover detected
- Supports both mouse and stylus hover events automatically

### 3. Add Simple Hover State (Minimal State)
- Add `String? hoveredConnectionId` field to `RoutingEditorWidget` state (1 field)
- Pass hover state to ConnectionPainter via existing constructor pattern (2 lines)
- Simple visual feedback: increase border width and change color on hover (3 lines)

### 4. Reuse Existing Parameter Updates (No New Logic)
- Use existing `RoutingEditorCubit.setPortOutputMode()` method - already implemented
- Connection labels already display mode via existing `formatBusLabelWithMode()` function
- Connection already has `outputMode` field - no parameter lookup needed
- Toggle between OutputMode.add (0) and OutputMode.replace (1) using existing enum

### 5. Visual Feedback Implementation (Simple CSS-like)
```dart
// In _drawConnectionLabel(), add hover check:
final isHovered = connectionId == hoveredConnectionId;
final borderPaint = Paint()
  ..color = isHovered ? Colors.teal : Colors.black87
  ..strokeWidth = isHovered ? 3.0 : 2.0
  ..style = PaintingStyle.stroke;
```

## Implementation Pattern Reuse

- **MouseRegion**: Copy exact pattern from `ghost_connection_tooltip.dart:151-153`
- **GestureDetector**: Use same pattern as existing port tap handlers  
- **State Management**: Follow existing `_selectedNodes` pattern for `_hoveredConnection`
- **Visual Styling**: Use existing paint modification patterns from ConnectionPainter

## Total Code Changes Estimate
- ConnectionData: +2 fields
- ConnectionPainter: +15 lines (bounds storage + hover rendering)
- RoutingEditorWidget: +20 lines (MouseRegion wrapper + state)
- RoutingEditorCubit: +5 lines (connection lookup + mode toggle)
- Tests: +20 lines

**Total: ~62 lines of new code**