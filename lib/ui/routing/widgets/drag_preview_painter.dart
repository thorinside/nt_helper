import 'package:flutter/material.dart';
import 'package:nt_helper/core/routing/services/connection_drag_handler.dart';
import 'package:nt_helper/core/routing/models/port.dart';

/// Custom painter for rendering connection drag previews
class DragPreviewPainter extends CustomPainter {
  final DragPreviewData? previewData;
  final Color validColor;
  final Color invalidColor;
  final double strokeWidth;

  DragPreviewPainter({
    this.previewData,
    this.validColor = Colors.green,
    this.invalidColor = Colors.red,
    this.strokeWidth = 2.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (previewData == null) return;

    final paint = Paint()
      ..color = previewData!.isValidDrop ? validColor : invalidColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Draw drag line with bezier curve for better visual appearance
    final path = _createBezierPath(
      previewData!.startPosition,
      previewData!.currentPosition,
    );

    canvas.drawPath(path, paint);

    // Draw arrowhead at the end
    _drawArrowHead(
      canvas,
      paint,
      previewData!.currentPosition,
      previewData!.startPosition,
    );

    // Draw connection indicator at start point
    _drawConnectionPoint(
      canvas,
      paint,
      previewData!.startPosition,
      previewData!.sourcePort,
    );
  }

  /// Create a bezier curve path for the connection line
  Path _createBezierPath(Offset start, Offset end) {
    final path = Path();
    path.moveTo(start.dx, start.dy);

    // Calculate control points for a smooth curve
    final controlPointOffset = (end.dx - start.dx).abs() * 0.5;
    final controlPoint1 = Offset(start.dx + controlPointOffset, start.dy);
    final controlPoint2 = Offset(end.dx - controlPointOffset, end.dy);

    path.cubicTo(
      controlPoint1.dx,
      controlPoint1.dy,
      controlPoint2.dx,
      controlPoint2.dy,
      end.dx,
      end.dy,
    );

    return path;
  }

  /// Draw arrowhead at the end of the connection line
  void _drawArrowHead(Canvas canvas, Paint paint, Offset end, Offset start) {
    const double arrowSize = 8.0;
    
    // Calculate arrow direction
    final direction = (end - start).normalized;
    final perpendicular = Offset(-direction.dy, direction.dx);

    // Arrow points
    final arrowPoint1 = end - direction * arrowSize + perpendicular * (arrowSize * 0.5);
    final arrowPoint2 = end - direction * arrowSize - perpendicular * (arrowSize * 0.5);

    final arrowPath = Path()
      ..moveTo(end.dx, end.dy)
      ..lineTo(arrowPoint1.dx, arrowPoint1.dy)
      ..moveTo(end.dx, end.dy)
      ..lineTo(arrowPoint2.dx, arrowPoint2.dy);

    canvas.drawPath(arrowPath, paint);
  }

  /// Draw connection indicator at the start point
  void _drawConnectionPoint(Canvas canvas, Paint paint, Offset position, Port port) {
    final fillPaint = Paint()
      ..color = _getPortColor(port.type)
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = paint.color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    const double radius = 6.0;

    // Draw filled circle
    canvas.drawCircle(position, radius, fillPaint);
    
    // Draw stroke
    canvas.drawCircle(position, radius, strokePaint);
  }

  /// Get color based on port type
  Color _getPortColor(PortType type) {
    switch (type) {
      case PortType.audio:
        return Colors.blue;
      case PortType.cv:
        return Colors.orange;
      case PortType.gate:
        return Colors.purple;
      case PortType.clock:
        return Colors.red;
    }
  }

  @override
  bool shouldRepaint(DragPreviewPainter oldDelegate) {
    return oldDelegate.previewData != previewData ||
           oldDelegate.validColor != validColor ||
           oldDelegate.invalidColor != invalidColor ||
           oldDelegate.strokeWidth != strokeWidth;
  }
}

/// Widget that renders drag preview overlay
class DragPreviewWidget extends StatelessWidget {
  final DragPreviewData? previewData;
  final Color validColor;
  final Color invalidColor;
  final double strokeWidth;

  const DragPreviewWidget({
    super.key,
    this.previewData,
    this.validColor = Colors.green,
    this.invalidColor = Colors.red,
    this.strokeWidth = 2.0,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: DragPreviewPainter(
        previewData: previewData,
        validColor: validColor,
        invalidColor: invalidColor,
        strokeWidth: strokeWidth,
      ),
      size: Size.infinite,
    );
  }
}

/// Extension for Offset normalization
extension OffsetExtensions on Offset {
  Offset get normalized {
    final magnitude = distance;
    if (magnitude == 0) return Offset.zero;
    return this / magnitude;
  }
}