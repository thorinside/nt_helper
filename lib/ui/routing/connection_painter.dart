import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:nt_helper/models/connection.dart';
import 'package:nt_helper/models/connection_preview.dart';

class ConnectionPainter extends CustomPainter {
  final List<Connection> connections;
  final Map<String, Offset> portPositions; // algorithmIndex_portId -> Offset
  final ConnectionPreview? connectionPreview;
  final String? hoveredConnectionId;

  ConnectionPainter({
    required this.connections,
    required this.portPositions,
    this.connectionPreview,
    this.hoveredConnectionId,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw all established connections
    for (final connection in connections) {
      _drawConnection(
        canvas,
        connection,
        isHovered: connection.id == hoveredConnectionId,
      );
    }

    // Draw preview connection if dragging
    if (connectionPreview != null) {
      _drawPreviewConnection(canvas, connectionPreview!);
    }
  }

  // Make the painter hit-testable only near actual connection lines
  @override
  bool? hitTest(Offset position) {
    // Check established connections first
    for (final connection in connections) {
      final sourceKey = '${connection.sourceAlgorithmIndex}_${connection.sourcePortId}';
      final targetKey = '${connection.targetAlgorithmIndex}_${connection.targetPortId}';
      final start = portPositions[sourceKey];
      final end = portPositions[targetKey];
      if (start == null || end == null) continue;
      if (_isPointNearBezier(position, start, end, tolerance: 10.0)) {
        return true;
      }
    }

    // Optionally, consider preview path as hit-testable (not necessary for taps)
    return false;
  }

  void _drawConnection(
    Canvas canvas,
    Connection connection, {
    bool isHovered = false,
  }) {
    final sourceKey = '${connection.sourceAlgorithmIndex}_${connection.sourcePortId}';
    final targetKey = '${connection.targetAlgorithmIndex}_${connection.targetPortId}';
    
    final sourcePos = portPositions[sourceKey];
    final targetPos = portPositions[targetKey];

    if (sourcePos == null || targetPos == null) return;

    final paint = Paint()
      ..strokeWidth = isHovered ? 4.0 : 2.0  // Thicker when hovered
      ..style = PaintingStyle.stroke;

    // Color based on execution order and validity (not hover state)
    if (connection.violatesExecutionOrder) {
      // Invalid execution order - signal won't reach target
      paint.color = Colors.red.withValues(alpha: 0.8);
    } else if (!connection.isValid) {
      // Other validation issues
      paint.color = Colors.orange.withValues(alpha: 0.8);
    } else {
      // Valid connection - same color whether hovered or not
      paint.color = Colors.green.withValues(alpha: 0.7);
    }

    // Create bezier path
    final path = _createBezierPath(sourcePos, targetPos);
    canvas.drawPath(path, paint);

    // Draw arrow head
    _drawArrowHead(canvas, targetPos, path, paint.color);

    // Draw edge label at midpoint
    final edgeLabel = connection.edgeLabel ?? connection.getEdgeLabel();
    _drawEdgeLabel(canvas, sourcePos, targetPos, edgeLabel);
  }

  void _drawPreviewConnection(
    Canvas canvas,
    ConnectionPreview connectionPreview,
  ) {
    final sourceKey = '${connectionPreview.sourceAlgorithmIndex}_${connectionPreview.sourcePortId}';
    final sourcePos = portPositions[sourceKey];

    if (sourcePos == null) {
      debugPrint('[ConnectionPainter] No source position for $sourceKey');
      return;
    }

    debugPrint('[ConnectionPainter] Drawing preview from $sourcePos to ${connectionPreview.cursorPosition}');

    // Color based on validity and execution order
    Color previewColor;
    if (connectionPreview.violatesExecutionOrder) {
      // Invalid due to execution order
      previewColor = Colors.red.withValues(alpha: 0.7);
    } else if (connectionPreview.isValid) {
      // Valid connection
      previewColor = Colors.green.withValues(alpha: 0.7);
    } else {
      // Invalid for other reasons (or no target)
      previewColor = Colors.orange.withValues(alpha: 0.7);
    }

    final paint = Paint()
      ..color = previewColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final path = _createBezierPath(sourcePos, connectionPreview.cursorPosition);

    // Draw dashed line for preview
    _drawDashedPath(canvas, path, paint, dashArray: [8, 4]);
  }

  /// Draw a dashed path by sampling points along the path
  void _drawDashedPath(
    Canvas canvas,
    Path path,
    Paint paint, {
    required List<double> dashArray,
  }) {
    final metrics = path.computeMetrics().first;
    double distance = 0.0;
    bool draw = true;
    int dashIndex = 0;

    while (distance < metrics.length) {
      final currentDashLength = dashArray[dashIndex % dashArray.length];
      final nextDistance = math.min(
        distance + currentDashLength,
        metrics.length,
      );

      if (draw) {
        final startTangent = metrics.getTangentForOffset(distance);
        final endTangent = metrics.getTangentForOffset(nextDistance);

        if (startTangent != null && endTangent != null) {
          final dashPath = Path();
          dashPath.moveTo(startTangent.position.dx, startTangent.position.dy);

          // Sample points along the curve for smooth dashed lines
          const sampleCount = 8;
          for (int i = 1; i <= sampleCount; i++) {
            final t = distance + (nextDistance - distance) * (i / sampleCount);
            final tangent = metrics.getTangentForOffset(t);
            if (tangent != null) {
              dashPath.lineTo(tangent.position.dx, tangent.position.dy);
            }
          }

          canvas.drawPath(dashPath, paint);
        }
      }

      distance = nextDistance;
      draw = !draw;
      dashIndex++;
    }
  }

  Path _createBezierPath(Offset start, Offset end) {
    final path = Path();
    path.moveTo(start.dx, start.dy);

    // Calculate adaptive control points based on distance and direction
    final distance = (end - start).distance;
    final controlStrength = math.min(distance * 0.4, 100.0);

    // Different curves for horizontal vs vertical routing
    if ((end.dx - start.dx).abs() > (end.dy - start.dy).abs()) {
      // Horizontal-dominant: smooth S-curve
      final cp1 = Offset(start.dx + controlStrength, start.dy);
      final cp2 = Offset(end.dx - controlStrength, end.dy);
      path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, end.dx, end.dy);
    } else {
      // Vertical: use midpoint control for better aesthetics
      final midY = (start.dy + end.dy) / 2;
      final cp1 = Offset(start.dx + controlStrength * 0.3, midY);
      final cp2 = Offset(end.dx - controlStrength * 0.3, midY);
      path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, end.dx, end.dy);
    }

    return path;
  }

  // Simple proximity test against our bezier path by sampling points
  bool _isPointNearBezier(Offset point, Offset start, Offset end, {double tolerance = 10.0}) {
    // Dead zone radius around ports - don't detect connection clicks near ports
    // This allows dragging new connections from already-connected ports
    const double portDeadZoneRadius = 30.0;
    
    // Check if click is within dead zone of source or target port
    final distanceToStart = (point - start).distance;
    final distanceToEnd = (point - end).distance;
    
    if (distanceToStart <= portDeadZoneRadius || distanceToEnd <= portDeadZoneRadius) {
      // Within dead zone - don't consider this a click on the connection
      return false;
    }
    
    const samples = 20;
    for (int i = 0; i <= samples; i++) {
      final t = i / samples;
      final p = _bezierPointAt(t, start, end);
      if ((point - p).distance <= tolerance) return true;
    }
    return false;
  }

  Offset _bezierPointAt(double t, Offset start, Offset end) {
    final distance = (end - start).distance;
    final controlStrength = math.min(distance * 0.4, 100.0);

    late Offset cp1; 
    late Offset cp2;
    if ((end.dx - start.dx).abs() > (end.dy - start.dy).abs()) {
      cp1 = Offset(start.dx + controlStrength, start.dy);
      cp2 = Offset(end.dx - controlStrength, end.dy);
    } else {
      final midY = (start.dy + end.dy) / 2;
      cp1 = Offset(start.dx + controlStrength * 0.3, midY);
      cp2 = Offset(end.dx - controlStrength * 0.3, midY);
    }

    final u = 1 - t;
    return start * (u * u * u) +
        cp1 * (3 * u * u * t) +
        cp2 * (3 * u * t * t) +
        end * (t * t * t);
  }

  void _drawArrowHead(
    Canvas canvas,
    Offset target,
    Path connectionPath,
    Color color,
  ) {
    // Calculate arrow direction from path tangent
    final metrics = connectionPath.computeMetrics().first;
    final tangent = metrics.getTangentForOffset(metrics.length - 5);

    if (tangent == null) return;

    final angle = math.atan2(tangent.vector.dy, tangent.vector.dx);
    const arrowLength = 8.0;
    const arrowAngle = math.pi / 6; // 30 degrees

    final arrowPaint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // Arrow head points
    final arrowPoint1 = Offset(
      target.dx - arrowLength * math.cos(angle - arrowAngle),
      target.dy - arrowLength * math.sin(angle - arrowAngle),
    );

    final arrowPoint2 = Offset(
      target.dx - arrowLength * math.cos(angle + arrowAngle),
      target.dy - arrowLength * math.sin(angle + arrowAngle),
    );

    // Draw arrow head
    final arrowPath = Path()
      ..moveTo(arrowPoint1.dx, arrowPoint1.dy)
      ..lineTo(target.dx, target.dy)
      ..lineTo(arrowPoint2.dx, arrowPoint2.dy);

    canvas.drawPath(arrowPath, arrowPaint);
  }

  void _drawEdgeLabel(Canvas canvas, Offset start, Offset end, String label) {
    // Calculate midpoint of bezier curve
    final midPoint = _calculateBezierMidpoint(start, end);

    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    // Draw background for label
    final labelRect = Rect.fromCenter(
      center: midPoint,
      width: textPainter.width + 6,
      height: textPainter.height + 2,
    );

    final labelPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(labelRect, const Radius.circular(3)),
      labelPaint,
    );

    // Draw text
    textPainter.paint(
      canvas,
      Offset(
        midPoint.dx - textPainter.width / 2,
        midPoint.dy - textPainter.height / 2,
      ),
    );
  }

  Offset _calculateBezierMidpoint(Offset start, Offset end) {
    // Calculate midpoint of bezier curve (t = 0.5)
    final dx = (end.dx - start.dx).abs();
    final controlPointOffset = math.max(50.0, dx * 0.5);

    final cp1 = Offset(start.dx + controlPointOffset, start.dy);
    final cp2 = Offset(end.dx - controlPointOffset, end.dy);

    // Bezier curve at t = 0.5
    const t = 0.5;
    const u = 1 - t;

    return start * (u * u * u) +
        cp1 * (3 * u * u * t) +
        cp2 * (3 * u * t * t) +
        end * (t * t * t);
  }

  @override
  bool shouldRepaint(ConnectionPainter oldDelegate) {
    return connections != oldDelegate.connections ||
        portPositions != oldDelegate.portPositions ||
        connectionPreview != oldDelegate.connectionPreview ||
        hoveredConnectionId != oldDelegate.hoveredConnectionId;
  }
}
