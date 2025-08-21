import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:nt_helper/models/connection.dart';
import 'package:nt_helper/models/connection_preview.dart';

/// Hit box for clickable labels
class LabelHitBox {
  final String id;
  final Rect bounds;
  final Offset center;
  
  LabelHitBox({
    required this.id,
    required this.bounds,
    required this.center,
  });
}

class ConnectionPainter extends CustomPainter {
  final List<Connection> connections;
  final Map<String, Offset> portPositions; // algorithmIndex_portId -> Offset
  final ConnectionPreview? connectionPreview;
  final String? hoveredConnectionId;
  final Set<String> pendingConnections;
  final Set<String> failedConnections;
  final String? hoveredLabelId;
  
  // Hit boxes for clickable labels, cleared and repopulated each paint cycle
  final List<LabelHitBox> labelHitBoxes = [];

  ConnectionPainter({
    required this.connections,
    required this.portPositions,
    this.connectionPreview,
    this.hoveredConnectionId,
    this.pendingConnections = const {},
    this.failedConnections = const {},
    this.hoveredLabelId,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Clear hit boxes for this paint cycle
    labelHitBoxes.clear();
    
    // Draw all established connections
    for (final connection in connections) {
      final isPending = pendingConnections.contains(connection.id);
      final isFailed = failedConnections.contains(connection.id);
      
      _drawConnection(
        canvas,
        connection,
        isHovered: connection.id == hoveredConnectionId,
        isPending: isPending,
        isFailed: isFailed,
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
      if (_isPointNearBezier(position, start, end, tolerance: 15.0)) { // Increased for mobile
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
    bool isPending = false,
    bool isFailed = false,
  }) {
    final sourceKey = '${connection.sourceAlgorithmIndex}_${connection.sourcePortId}';
    final targetKey = '${connection.targetAlgorithmIndex}_${connection.targetPortId}';
    
    final sourcePos = portPositions[sourceKey];
    final targetPos = portPositions[targetKey];

    if (sourcePos == null || targetPos == null) {
      debugPrint('[ConnectionPainter] Missing port positions: source=$sourceKey->$sourcePos, target=$targetKey->$targetPos');
      return;
    }
    
    debugPrint('[ConnectionPainter] Drawing connection: $sourceKey->$targetKey');

    final paint = Paint()
      ..strokeWidth = isPending ? 2.0 : (isHovered ? 5.0 : 3.0)
      ..style = PaintingStyle.stroke;

    // Set dash pattern for pending connections
    if (isPending) {
      paint.strokeWidth = 2.0;
    }

    // Color based on connection state, execution order and validity
    if (isFailed) {
      paint.color = Colors.red.withValues(alpha: 1.0);
    } else if (isPending) {
      paint.color = Colors.grey.withValues(alpha: 0.6);
    } else if (connection.violatesExecutionOrder) {
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
    
    // Draw dashed line for pending connections
    if (isPending) {
      _drawDashedPath(canvas, path, paint, dashArray: [5.0, 5.0]);
    } else {
      canvas.drawPath(path, paint);
    }

    // Draw arrow head
    _drawArrowHead(canvas, targetPos, path, paint.color);

    // Draw edge label at midpoint
    final edgeLabel = connection.edgeLabel ?? connection.getEdgeLabel();
    _drawEdgeLabel(canvas, sourcePos, targetPos, edgeLabel, connection);
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

  void _drawEdgeLabel(Canvas canvas, Offset start, Offset end, String label, Connection connection) {
    // Calculate midpoint of bezier curve
    final midPoint = _calculateBezierMidpoint(start, end);

    // Check if this connection supports mode toggle (not physical I/O)
    final hasMode = connection.sourceAlgorithmIndex >= 0;
    final displayLabel = hasMode && connection.replaceMode
        ? '$label (R)'  // Only show indicator for Replace mode
        : label;        // Show plain label for Add mode and physical I/O
    
    // Check hover state
    final labelId = 'connection_${connection.id}_mode';
    final isHovered = hoveredLabelId == labelId;

    final textPainter = TextPainter(
      text: TextSpan(
        text: displayLabel,
        style: TextStyle(
          color: Colors.white,
          fontSize: isHovered ? 12 : 10, // 10px normal, 12px hover
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    final textSize = textPainter.size;
    
    // Record hit box for click detection (only for connections with modes)
    if (hasMode) {
      const padding = 16.0; // Increased for better mobile/Apple Pencil targeting (44pt recommended minimum)
      labelHitBoxes.add(LabelHitBox(
        id: labelId,
        bounds: Rect.fromCenter(
          center: midPoint,
          width: math.max(textSize.width + padding * 2, 44.0), // Minimum 44pt tap target
          height: math.max(textSize.height + padding * 2, 44.0), // Minimum 44pt tap target
        ),
        center: midPoint,
      ));
    }

    // Draw background with mode-specific color
    final backgroundColor = hasMode
        ? (connection.replaceMode 
          ? Colors.blue.withValues(alpha: isHovered ? 0.9 : 0.7)    // Replace = blue
          : Colors.black.withValues(alpha: isHovered ? 0.9 : 0.7))  // Add = black
        : Colors.black.withValues(alpha: 0.7);  // Physical I/O = black

    final labelRect = Rect.fromCenter(
      center: midPoint,
      width: textSize.width + 8, // Slightly larger for better visual feedback
      height: textSize.height + 4,
    );

    final labelPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(labelRect, const Radius.circular(3)),
      labelPaint,
    );

    // Draw text
    textPainter.paint(
      canvas,
      Offset(
        midPoint.dx - textSize.width / 2,
        midPoint.dy - textSize.height / 2,
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


  /// Get label at position for hit testing
  String? getLabelAtPosition(Offset position) {
    for (final hitBox in labelHitBoxes) {
      if (hitBox.bounds.contains(position)) {
        return hitBox.id;
      }
    }
    return null;
  }
  
  @override
  bool shouldRepaint(ConnectionPainter oldDelegate) {
    return connections != oldDelegate.connections ||
        portPositions != oldDelegate.portPositions ||
        connectionPreview != oldDelegate.connectionPreview ||
        hoveredConnectionId != oldDelegate.hoveredConnectionId ||
        pendingConnections != oldDelegate.pendingConnections ||
        failedConnections != oldDelegate.failedConnections ||
        hoveredLabelId != oldDelegate.hoveredLabelId;
  }
}
