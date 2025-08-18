# Flutter Hover and Label Interaction Patterns

## Connection Label Hover and Click Detection in CustomPainter

### Key Concepts

1. **MouseRegion for Hover Detection**: Wraps the CustomPaint widget to detect mouse position
2. **Hit Testing in CustomPainter**: Manual calculation of whether mouse position intersects with painted elements
3. **Gesture Detection**: Layered with MouseRegion for click handling

### Implementation Pattern for Clickable Labels in CustomPainter

```dart
class InteractivePainter extends CustomPainter {
  final Offset? hoverPosition;
  final List<LabelHitBox> labelHitBoxes = [];
  
  @override
  void paint(Canvas canvas, Size size) {
    // Clear hit boxes for this paint cycle
    labelHitBoxes.clear();
    
    // Draw and record label positions
    _drawLabelWithHitBox(
      canvas: canvas,
      text: "Mode: Add",
      position: labelPosition,
      labelId: "connection_${connection.id}_mode",
    );
    
    // Check hover state
    if (hoverPosition != null) {
      final hoveredLabel = _getLabelAtPosition(hoverPosition!);
      if (hoveredLabel != null) {
        // Draw hover effect
        _drawHoverEffect(canvas, hoveredLabel);
      }
    }
  }
  
  void _drawLabelWithHitBox({
    required Canvas canvas,
    required String text,
    required Offset position,
    required String labelId,
  }) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: hoveredLabelId == labelId ? 12 : 10,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout();
    final size = textPainter.size;
    
    // Record hit box with padding
    const padding = 4.0;
    labelHitBoxes.add(LabelHitBox(
      id: labelId,
      bounds: Rect.fromCenter(
        center: position,
        width: size.width + padding * 2,
        height: size.height + padding * 2,
      ),
    ));
    
    // Draw background (different color for hover)
    final isHovered = hoveredLabelId == labelId;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: position,
          width: size.width + padding * 2,
          height: size.height + padding * 2,
        ),
        Radius.circular(3),
      ),
      Paint()..color = isHovered 
        ? Colors.blue.withOpacity(0.8)
        : Colors.black.withOpacity(0.7),
    );
    
    // Draw text
    textPainter.paint(
      canvas,
      position - Offset(size.width / 2, size.height / 2),
    );
  }
  
  String? getLabelAtPosition(Offset position) {
    for (final hitBox in labelHitBoxes) {
      if (hitBox.bounds.contains(position)) {
        return hitBox.id;
      }
    }
    return null;
  }
}

class LabelHitBox {
  final String id;
  final Rect bounds;
  
  LabelHitBox({required this.id, required this.bounds});
}
```

### Widget Integration Pattern

```dart
class InteractiveCanvasWidget extends StatefulWidget {
  // ...
}

class _InteractiveCanvasWidgetState extends State<InteractiveCanvasWidget> {
  Offset? _hoverPosition;
  String? _hoveredLabelId;
  InteractivePainter? _painter;
  
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: _hoveredLabelId != null 
        ? SystemMouseCursors.click 
        : SystemMouseCursors.basic,
      onHover: (event) {
        // Convert to local coordinates
        final RenderBox? box = context.findRenderObject() as RenderBox?;
        if (box != null) {
          final localPosition = box.globalToLocal(event.position);
          
          // Update hover position
          setState(() {
            _hoverPosition = localPosition;
            
            // Check if hovering over a label
            if (_painter != null) {
              _hoveredLabelId = _painter!.getLabelAtPosition(localPosition);
            }
          });
        }
      },
      onExit: (_) {
        setState(() {
          _hoverPosition = null;
          _hoveredLabelId = null;
        });
      },
      child: GestureDetector(
        onTapDown: (details) {
          if (_painter != null) {
            final labelId = _painter!.getLabelAtPosition(details.localPosition);
            if (labelId != null) {
              _handleLabelClick(labelId);
            }
          }
        },
        child: CustomPaint(
          painter: _painter = InteractivePainter(
            hoverPosition: _hoverPosition,
            hoveredLabelId: _hoveredLabelId,
            // ... other parameters
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
  
  void _handleLabelClick(String labelId) {
    // Parse label ID to determine which connection was clicked
    if (labelId.startsWith('connection_') && labelId.endsWith('_mode')) {
      final connectionId = labelId
        .replaceFirst('connection_', '')
        .replaceFirst('_mode', '');
      
      // Toggle the mode for this connection
      _toggleConnectionMode(connectionId);
    }
  }
}
```

## Visual Feedback Patterns

### Hover Effects
1. **Size change**: Increase font size slightly on hover (10px → 12px)
2. **Background color**: Change from black to blue background
3. **Opacity**: Increase opacity on hover (0.7 → 0.8)
4. **Cursor change**: Switch to click cursor when hovering

### Click Feedback
1. **Immediate visual update**: Change label text/color immediately
2. **Animation**: Scale or fade transition
3. **Ripple effect**: Use InkWell-style ripple if appropriate

## Optimistic Update Pattern for Mode Toggle

```dart
void _toggleConnectionMode(String connectionId) {
  // 1. Find the connection and its current mode
  final connection = connections.firstWhere((c) => c.id == connectionId);
  final currentMode = _getConnectionMode(connection); // 0 = Add, 1 = Replace
  
  // 2. Calculate new mode
  final newMode = currentMode == 0 ? 1 : 0;
  
  // 3. Optimistic UI update - update label immediately
  setState(() {
    // Update visual state to reflect new mode
    _connectionModes[connectionId] = newMode;
  });
  
  // 4. Find and update the mode parameter
  final modeParameterNumber = _findModeParameterForOutput(
    connection.sourceAlgorithmIndex,
    connection.sourcePortId,
  );
  
  if (modeParameterNumber != null) {
    // 5. Queue parameter update to hardware
    context.read<DistingCubit>().updateParameterValue(
      algorithmIndex: connection.sourceAlgorithmIndex,
      parameterNumber: modeParameterNumber,
      value: newMode.toDouble(),
      needsStringUpdate: true,
    );
  }
}
```

## Performance Considerations

1. **Minimize paint calls**: Only repaint when hover state changes
2. **Cache text painters**: Reuse TextPainter instances when possible
3. **Efficient hit testing**: Use spatial indexing for many labels
4. **Debounce hover events**: Avoid excessive repaints during mouse movement

## Mobile Compatibility

Since hover doesn't exist on mobile:
1. Use long-press as alternative to hover
2. Show mode in the label always on mobile
3. Use tap to toggle directly without hover preview