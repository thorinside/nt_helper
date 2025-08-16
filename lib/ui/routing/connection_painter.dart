import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:nt_helper/models/connection.dart';
import 'package:nt_helper/models/node_position.dart';

class ConnectionPainter extends CustomPainter {
  final List<Connection> connections;
  final Map<int, NodePosition> nodePositions;
  final Connection? previewConnection;
  final Offset? previewTargetPosition;
  final String? hoveredConnectionId;

  ConnectionPainter({
    required this.connections,
    required this.nodePositions,
    this.previewConnection,
    this.previewTargetPosition,
    this.hoveredConnectionId,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw all established connections
    for (final connection in connections) {
      _drawConnection(canvas, connection, isHovered: connection.id == hoveredConnectionId);
    }

    // Draw preview connection if dragging
    if (previewConnection != null && previewTargetPosition != null) {
      _drawPreviewConnection(canvas, previewConnection!, previewTargetPosition!);
    }
  }

  void _drawConnection(Canvas canvas, Connection connection, {bool isHovered = false}) {
    final sourcePos = _getPortPosition(connection.sourceAlgorithmIndex, connection.sourcePortId, isOutput: true);
    final targetPos = _getPortPosition(connection.targetAlgorithmIndex, connection.targetPortId, isOutput: false);

    if (sourcePos == null || targetPos == null) return;

    final paint = Paint()
      ..strokeWidth = isHovered ? 3.0 : 2.0
      ..style = PaintingStyle.stroke;

    // Color based on validity and hover state
    if (!connection.isValid) {
      paint.color = Colors.red.withValues(alpha: 0.8);
    } else if (isHovered) {
      paint.color = Colors.white.withValues(alpha: 0.9);
    } else {
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

  void _drawPreviewConnection(Canvas canvas, Connection connection, Offset targetPosition) {
    final sourcePos = _getPortPosition(connection.sourceAlgorithmIndex, connection.sourcePortId, isOutput: true);
    
    if (sourcePos == null) return;

    final paint = Paint()
      ..color = Colors.blue.withValues(alpha: 0.6)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // Dashed line for preview
    // Note: PathEffect may not be available in all Flutter versions
    // Alternative approach: draw dashed line manually or use different visual indicator

    final path = _createBezierPath(sourcePos, targetPosition);
    canvas.drawPath(path, paint);
  }

  Path _createBezierPath(Offset start, Offset end) {
    final path = Path();
    path.moveTo(start.dx, start.dy);

    // Calculate control points for smooth horizontal emphasis
    final dx = (end.dx - start.dx).abs();
    final controlPointOffset = math.max(50.0, dx * 0.5);
    
    final cp1 = Offset(start.dx + controlPointOffset, start.dy);
    final cp2 = Offset(end.dx - controlPointOffset, end.dy);

    path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, end.dx, end.dy);
    return path;
  }

  void _drawArrowHead(Canvas canvas, Offset target, Path connectionPath, Color color) {
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

  Offset? _getPortPosition(int algorithmIndex, String portId, {required bool isOutput}) {
    final nodePos = nodePositions[algorithmIndex];
    if (nodePos == null) return null;

    // Simplified port position calculation
    // In a real implementation, this would query the actual port layout
    const portOffset = 8.0; // Half of port widget width
    const headerHeight = 30.0;
    const portSpacing = 18.0;
    
    // Mock port index (in real implementation, find actual port index)
    final portIndex = portId.hashCode % 4; // Simplified for demo
    
    final portY = nodePos.y + headerHeight + (portIndex * portSpacing) + portOffset;
    
    if (isOutput) {
      return Offset(nodePos.x + nodePos.width, portY);
    } else {
      return Offset(nodePos.x, portY);
    }
  }

  @override
  bool shouldRepaint(ConnectionPainter oldDelegate) {
    return connections != oldDelegate.connections ||
           nodePositions != oldDelegate.nodePositions ||
           previewConnection != oldDelegate.previewConnection ||
           previewTargetPosition != oldDelegate.previewTargetPosition ||
           hoveredConnectionId != oldDelegate.hoveredConnectionId;
  }
}