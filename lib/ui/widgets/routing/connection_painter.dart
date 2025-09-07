import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:nt_helper/core/routing/models/connection.dart'
    show Connection, ConnectionType;
import 'package:nt_helper/core/routing/models/port.dart';
import 'ghost_connection_tooltip.dart';
import 'connection_theme.dart';
import 'bus_label_formatter.dart';

/// Represents connection data with bus and output mode information
class ConnectionData {
  final Connection connection;
  final Offset sourcePosition;
  final Offset destinationPosition;
  final int? busNumber;
  final OutputMode? outputMode; // Output mode from source port
  final bool isSelected;
  final bool isHighlighted;
  final bool isPhysicalConnection; // True if this is a physical connection
  final bool?
  isInputConnection; // True if physical input connection, false if output, null if not physical
  final String? busLabel; // Bus label for partial connections
  final Function(bool isHovering)?
  onLabelHover; // Callback for label hover events
  final VoidCallback? onLabelTap; // Callback for label tap events

  const ConnectionData({
    required this.connection,
    required this.sourcePosition,
    required this.destinationPosition,
    this.busNumber,
    this.outputMode,
    this.isSelected = false,
    this.isHighlighted = false,
    this.isPhysicalConnection = false,
    this.isInputConnection,
    this.busLabel,
    this.onLabelHover,
    this.onLabelTap,
  });

  /// Convenience getter for ghost connection status from the connection model
  bool get isGhostConnection => connection.isGhostConnection;

  /// Convenience getter for invalid order status (backward edge)
  bool get isInvalidOrder => connection.isBackwardEdge;

  /// Convenience getter for partial connection status from the connection model
  bool get isPartial => connection.isPartial;
}

/// Custom painter for efficiently rendering multiple connection lines
///
/// This painter is optimized for rendering many connections in a single
/// paint operation, with support for overlap avoidance, connection types,
/// bus labeling, and animated flow effects for ghost connections.
class ConnectionPainter extends CustomPainter {
  final List<ConnectionData> connections;
  final ThemeData theme;
  final ConnectionStateManager? connectionStateManager;
  final bool enableAntiOverlap;
  final bool showLabels;
  final bool enableAnimations;
  final double? animationProgress;
  final String? hoveredConnectionId;

  /// Map storing label bounds for hit testing
  final Map<String, Rect> _labelBounds = {};

  ConnectionPainter({
    required this.connections,
    required this.theme,
    this.connectionStateManager,
    this.enableAntiOverlap = true,
    this.showLabels = true,
    this.enableAnimations = true,
    this.animationProgress,
    this.hoveredConnectionId,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (connections.isEmpty) return;

    // Clear previous label bounds
    _labelBounds.clear();

    // Group connections by type for batch rendering
    final regularConnections = <ConnectionData>[];
    final ghostConnections = <ConnectionData>[];
    final invalidConnections = <ConnectionData>[];
    final selectedConnections = <ConnectionData>[];
    final partialConnections = <ConnectionData>[];

    for (final conn in connections) {
      if (conn.isSelected) {
        selectedConnections.add(conn);
      } else if (conn.isPartial) {
        partialConnections.add(conn);
      } else if (conn.isInvalidOrder) {
        invalidConnections.add(conn);
      } else if (conn.isGhostConnection) {
        ghostConnections.add(conn);
      } else {
        regularConnections.add(conn);
      }
    }

    // Draw in order: regular -> ghost -> invalid -> partial -> selected (for proper layering)
    _drawConnectionBatch(
      canvas,
      regularConnections,
      ConnectionVisualType.regular,
    );
    _drawConnectionBatch(canvas, ghostConnections, ConnectionVisualType.ghost);
    _drawConnectionBatch(
      canvas,
      invalidConnections,
      ConnectionVisualType.invalid,
    );
    _drawConnectionBatch(
      canvas,
      partialConnections,
      ConnectionVisualType.partial,
    );
    _drawConnectionBatch(
      canvas,
      selectedConnections,
      ConnectionVisualType.selected,
    );

    // Draw labels last so they appear on top (skip partial connections as they have their own labels)
    if (showLabels) {
      for (final conn in connections) {
        // Skip partial connections - they have their own label handling
        if (!conn.isPartial) {
          _drawConnectionLabel(canvas, conn);
        }
      }
    }
  }

  /// Draw a batch of connections of the same type
  void _drawConnectionBatch(
    Canvas canvas,
    List<ConnectionData> batch,
    ConnectionVisualType type,
  ) {
    if (batch.isEmpty) return;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (final conn in batch) {
      // Calculate path - special handling for partial connections
      Path path;
      if (type == ConnectionVisualType.partial) {
        // For partial connections, create a short straight line to the label
        path = _createPartialConnectionPath(conn);
      } else {
        // Regular path calculation for other connection types
        path = enableAntiOverlap
            ? _createRoutedPath(conn, batch)
            : _createDirectPath(conn.sourcePosition, conn.destinationPosition);
      }

      // Apply visual style based on connection type
      _applyConnectionStyle(paint, conn, type);

      // Draw the connection
      if (type == ConnectionVisualType.ghost) {
        _drawDashedPath(canvas, path, paint);

        // Draw animated flow effects if enabled
        if (enableAnimations && animationProgress != null) {
          _drawAnimatedFlow(canvas, path, conn);
        }
      } else if (type == ConnectionVisualType.invalid) {
        _drawDashedPath(canvas, path, paint);
      } else if (type == ConnectionVisualType.partial) {
        _drawDashedPath(canvas, path, paint);

        // Draw bus label at the endpoint for partial connections
        _drawPartialConnectionBusLabel(canvas, conn);
      } else {
        canvas.drawPath(path, paint);
      }

      // Draw endpoints (skip for partial connections)
      if (type != ConnectionVisualType.partial) {
        _drawEndpoints(canvas, conn);
      }
    }
  }

  /// Create a bezier path with routing to avoid overlaps
  Path _createRoutedPath(
    ConnectionData connection,
    List<ConnectionData> allConnections,
  ) {
    final start = connection.sourcePosition;
    final end = connection.destinationPosition;

    // Find overlapping connections
    final overlaps = _findOverlappingConnections(connection, allConnections);

    if (overlaps.isEmpty) {
      return _createDirectPath(start, end);
    }

    // Calculate offset to avoid overlaps
    final offsetIndex = overlaps.indexOf(connection);
    final offsetAmount = (offsetIndex + 1) * 10.0;

    return _createOffsetPath(start, end, offsetAmount);
  }

  /// Find connections that overlap with the given connection
  List<ConnectionData> _findOverlappingConnections(
    ConnectionData target,
    List<ConnectionData> connections,
  ) {
    final overlapping = <ConnectionData>[];

    for (final conn in connections) {
      if (conn == target) continue;

      // Check if connections share similar paths
      if (_pathsOverlap(target, conn)) {
        overlapping.add(conn);
      }
    }

    return overlapping;
  }

  /// Check if two connection paths overlap
  bool _pathsOverlap(ConnectionData a, ConnectionData b) {
    // Simple overlap detection based on endpoint proximity
    const threshold = 50.0;

    final startDistance = (a.sourcePosition - b.sourcePosition).distance;
    final endDistance =
        (a.destinationPosition - b.destinationPosition).distance;

    return startDistance < threshold && endDistance < threshold;
  }

  /// Create a direct bezier path between two points
  Path _createDirectPath(Offset start, Offset end) {
    return createBezierPath(start, end);
  }

  /// Create an offset bezier path to avoid overlaps
  Path _createOffsetPath(Offset start, Offset end, double offset) {
    final path = Path();
    path.moveTo(start.dx, start.dy);

    final dx = end.dx - start.dx;
    final controlOffset = (dx.abs() * 0.5).clamp(30.0, 150.0);

    // Add vertical offset to control points
    final cp1 = Offset(
      start.dx + (dx > 0 ? controlOffset : -controlOffset),
      start.dy + offset,
    );
    final cp2 = Offset(
      end.dx - (dx > 0 ? controlOffset : -controlOffset),
      end.dy + offset,
    );

    path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, end.dx, end.dy);
    return path;
  }

  /// Create a short straight path for partial connections
  Path _createPartialConnectionPath(ConnectionData conn) {
    final path = Path();

    // For partial connections, we already have the correct positions:
    // - sourcePosition is the port (or label for inputs)
    // - destinationPosition is the label (or port for inputs)
    // Just draw a straight line between them
    path.moveTo(conn.sourcePosition.dx, conn.sourcePosition.dy);
    path.lineTo(conn.destinationPosition.dx, conn.destinationPosition.dy);

    return path;
  }

  /// Apply visual style to paint based on connection properties
  void _applyConnectionStyle(
    Paint paint,
    ConnectionData conn,
    ConnectionVisualType type,
  ) {
    // Handle invalid connections with error color
    if (type == ConnectionVisualType.invalid) {
      paint
        ..strokeWidth = 2.0
        ..color = theme.colorScheme.error;
      return;
    }

    // Handle partial connections with distinctive styling
    if (type == ConnectionVisualType.partial) {
      paint
        ..strokeWidth = 2.0
        ..color = theme.colorScheme.onSurface.withValues(alpha: 0.6);
      return;
    }

    // Get style from theme manager if available, otherwise fall back to defaults
    ConnectionStyle style;

    if (connectionStateManager != null) {
      style = connectionStateManager!.getConnectionStyle(conn.connection);
    } else {
      // Fallback to default theme
      final fallbackTheme = ConnectionVisualTheme.fromColorScheme(
        theme.colorScheme,
      );
      style = fallbackTheme.getStyleForConnection(
        connection: conn.connection,
        isSelected: conn.isSelected,
        isHighlighted: conn.isHighlighted,
        hasError: conn.isInvalidOrder,
      );
    }

    // Use port type color as base, modified by connection style
    Color baseColor = PortTypeColors.getColorForPortId(
      conn.connection.sourcePortId,
    );
    Color finalColor;

    // For highlighted connections, use pure red for maximum visibility
    if (conn.isHighlighted) {
      finalColor = Colors.red;
    } else {
      finalColor = Color.lerp(baseColor, style.color, 0.7) ?? style.color;
    }

    // Apply replace mode styling
    if (conn.outputMode == OutputMode.replace) {
      finalColor = Colors.blue.withValues(alpha: finalColor.a);
    }

    paint
      ..strokeWidth = style.strokeWidth
      ..color = finalColor;
  }

  /// Draw a dashed path for ghost connections
  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    final pathMetrics = path.computeMetrics();

    for (final metric in pathMetrics) {
      double distance = 0.0;
      bool draw = true;
      const dashLength = 8.0;
      const gapLength = 4.0;

      while (distance < metric.length) {
        final segmentLength = draw ? dashLength : gapLength;
        final endDistance = (distance + segmentLength).clamp(
          0.0,
          metric.length,
        );

        if (draw) {
          final segment = metric.extractPath(distance, endDistance);
          canvas.drawPath(segment, paint);
        }

        distance = endDistance;
        draw = !draw;
      }
    }
  }

  /// Draw animated flow effects for ghost connections
  void _drawAnimatedFlow(Canvas canvas, Path path, ConnectionData conn) {
    if (animationProgress == null) return;

    final pathMetrics = path.computeMetrics();
    if (pathMetrics.isEmpty) return;

    final metric = pathMetrics.first;
    const dotCount = 3;
    const dotRadius = 3.0;
    const flowSpeed = 2.0; // Speed multiplier for animation

    // Create paint for animated dots
    final dotPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = _getPortColor(
        conn.connection.sourcePortId,
      ).withValues(alpha: 0.8);

    // Draw multiple animated dots along the path
    for (int i = 0; i < dotCount; i++) {
      // Calculate position for this dot with offset based on animation progress
      final offset = (i / dotCount) + (animationProgress! * flowSpeed);
      final normalizedOffset = offset % 1.0;
      final distance = normalizedOffset * metric.length;

      // Get position along path
      final tangent = metric.getTangentForOffset(distance);
      if (tangent != null) {
        // Draw dot with fade effect based on position
        final fadeAlpha = (1.0 - (distance / metric.length) * 0.3).clamp(
          0.0,
          1.0,
        );
        dotPaint.color = dotPaint.color.withValues(alpha: fadeAlpha * 0.8);

        canvas.drawCircle(tangent.position, dotRadius, dotPaint);
      }
    }
  }

  /// Draw connection endpoints
  void _drawEndpoints(Canvas canvas, ConnectionData conn) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = _getPortColor(conn.connection.sourcePortId);

    const radius = 3.0;
    canvas.drawCircle(conn.sourcePosition, radius, paint);
    canvas.drawCircle(conn.destinationPosition, radius, paint);
  }

  /// Draw connection label with bus number and output mode
  void _drawConnectionLabel(Canvas canvas, ConnectionData conn) {
    if (conn.busNumber == null) {
      return;
    }

    // Calculate midpoint - try path metrics first, fallback to simple calculation
    Offset midPoint;

    final path = _createDirectPath(
      conn.sourcePosition,
      conn.destinationPosition,
    );
    final metrics = path.computeMetrics();

    if (metrics.isNotEmpty) {
      final metricsIterator = metrics.iterator;
      if (metricsIterator.moveNext()) {
        final metric = metricsIterator.current;
        if (metric.length > 0) {
          final midDistance = metric.length * 0.5;
          final tangent = metric.getTangentForOffset(midDistance);
          if (tangent != null) {
            midPoint = tangent.position;
          } else {
            midPoint = Offset(
              (conn.sourcePosition.dx + conn.destinationPosition.dx) / 2,
              (conn.sourcePosition.dy + conn.destinationPosition.dy) / 2,
            );
          }
        } else {
          midPoint = Offset(
            (conn.sourcePosition.dx + conn.destinationPosition.dx) / 2,
            (conn.sourcePosition.dy + conn.destinationPosition.dy) / 2,
          );
        }
      } else {
        midPoint = Offset(
          (conn.sourcePosition.dx + conn.destinationPosition.dx) / 2,
          (conn.sourcePosition.dy + conn.destinationPosition.dy) / 2,
        );
      }
    } else {
      // Fallback to simple midpoint calculation
      midPoint = Offset(
        (conn.sourcePosition.dx + conn.destinationPosition.dx) / 2,
        (conn.sourcePosition.dy + conn.destinationPosition.dy) / 2,
      );
    }

    // Use BusLabelFormatter to get the label with mode-aware formatting
    final label = formatBusLabelWithMode(conn.busNumber, conn.outputMode);
    if (label.isEmpty) {
      return;
    }

    // Create text painter with enhanced text style
    final textStyle = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.bold,
      color: Colors.black, // Explicit black color for visibility
    );

    final textPainter = createLabelTextPainter(label, textStyle);
    textPainter.layout();

    // Calculate label position
    final labelRect = Rect.fromCenter(
      center: midPoint,
      width: textPainter.width + 12,
      height: textPainter.height + 8,
    );

    // Store label bounds for hit testing
    _labelBounds[conn.connection.id] = labelRect;

    // Draw label background with high contrast
    final backgroundPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.white.withValues(
        alpha: 0.95,
      ); // High contrast white background

    // Check hover state and apply styling
    final isHovered = hoveredConnectionId == conn.connection.id;
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = isHovered ? 3.0 : 2.0
      ..color = isHovered ? Colors.teal : Colors.black;

    // Save canvas state
    canvas.save();

    // Draw label background
    canvas.drawRRect(
      RRect.fromRectAndRadius(labelRect, const Radius.circular(6)),
      backgroundPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(labelRect, const Radius.circular(6)),
      borderPaint,
    );

    // Draw text
    final textOffset = Offset(
      midPoint.dx - textPainter.width / 2,
      midPoint.dy - textPainter.height / 2,
    );

    textPainter.paint(canvas, textOffset);

    // Restore canvas state
    canvas.restore();
  }

  /// Draw bus label at the endpoint of a partial connection
  void _drawPartialConnectionBusLabel(Canvas canvas, ConnectionData conn) {
    if (conn.busLabel == null || conn.busLabel!.isEmpty) {
      return;
    }

    // Determine which end has the label
    final connectionType = conn.connection.connectionType;
    final isOutputTobus = connectionType == ConnectionType.partialOutputToBus;

    // The label position is at the destination for outputs, source for inputs
    final labelCenter = isOutputTobus
        ? conn.destinationPosition
        : conn.sourcePosition;

    // Create text painter for bus label
    final textStyle = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.bold,
      color: theme.colorScheme.onSurface,
    );

    final textPainter = createLabelTextPainter(conn.busLabel!, textStyle);
    textPainter.layout();

    // Calculate label position centered at the endpoint
    final labelOffset = Offset(
      labelCenter.dx - textPainter.width / 2,
      labelCenter.dy - textPainter.height / 2,
    );

    // Create label background with padding
    final labelRect = Rect.fromLTWH(
      labelOffset.dx - 4,
      labelOffset.dy - 2,
      textPainter.width + 8,
      textPainter.height + 4,
    );

    // Store bounds for partial connection bus labels to enable tap handling
    // Use a special prefix to distinguish from regular connection labels
    _labelBounds['partial_${conn.connection.id}'] = labelRect;

    // Draw label background with subtle styling
    final backgroundPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = theme.colorScheme.surface.withValues(alpha: 0.9);

    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = theme.colorScheme.outline.withValues(alpha: 0.5);

    canvas.drawRRect(
      RRect.fromRectAndRadius(labelRect, const Radius.circular(4)),
      backgroundPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(labelRect, const Radius.circular(4)),
      borderPaint,
    );

    // Draw the text
    textPainter.paint(canvas, labelOffset);
  }

  /// Calculate the midpoint of a Bezier curve path
  static Offset calculateBezierMidpoint(Offset start, Offset end) {
    // For simple implementation, use path metrics to find the actual midpoint
    final path = Path();
    path.moveTo(start.dx, start.dy);

    final dx = end.dx - start.dx;
    final controlOffset = (dx.abs() * 0.5).clamp(30.0, 150.0);

    final cp1 = Offset(
      start.dx + (dx > 0 ? controlOffset : -controlOffset),
      start.dy,
    );
    final cp2 = Offset(
      end.dx - (dx > 0 ? controlOffset : -controlOffset),
      end.dy,
    );

    path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, end.dx, end.dy);

    final metrics = path.computeMetrics();

    // Safely iterate through metrics
    for (final metric in metrics) {
      final tangent = metric.getTangentForOffset(metric.length * 0.5);
      if (tangent != null) {
        return tangent.position;
      }
    }

    // Fallback to simple linear interpolation
    return Offset.lerp(start, end, 0.5)!;
  }

  /// Calculate the angle for label rotation based on connection direction
  static double calculateLabelAngle(Offset start, Offset end) {
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    return math.atan2(dy, dx);
  }

  /// Format bus number into label string using BusLabelFormatter
  static String formatBusLabel(int? busNumber) {
    return BusLabelFormatter.formatBusNumber(busNumber) ?? '';
  }

  /// Format bus number into label string with mode-aware formatting using BusLabelFormatter
  static String formatBusLabelWithMode(int? busNumber, OutputMode? outputMode) {
    return BusLabelFormatter.formatBusLabelWithMode(busNumber, outputMode) ??
        '';
  }

  /// Create a TextPainter for label rendering
  static TextPainter createLabelTextPainter(String text, TextStyle style) {
    final textSpan = TextSpan(text: text, style: style);
    return TextPainter(
      text: textSpan,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
  }

  /// Create a bezier path between two points (static utility method)
  /// This uses the same bezier curve calculation as the ConnectionPainter
  static Path createBezierPath(Offset start, Offset end) {
    final path = Path();
    path.moveTo(start.dx, start.dy);

    final dx = end.dx - start.dx;
    final controlOffset = (dx.abs() * 0.5).clamp(30.0, 150.0);

    final cp1 = Offset(
      start.dx + (dx > 0 ? controlOffset : -controlOffset),
      start.dy,
    );
    final cp2 = Offset(
      end.dx - (dx > 0 ? controlOffset : -controlOffset),
      end.dy,
    );

    path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, end.dx, end.dy);
    return path;
  }

  /// Get color for a port based on its type
  Color _getPortColor(String portId) {
    // Parse port type from ID (simplified - should use actual port data)
    if (portId.contains('audio')) return Colors.blue;
    if (portId.contains('cv')) return Colors.orange;
    if (portId.contains('gate')) return Colors.red;
    if (portId.contains('clock') || portId.contains('trigger')) {
      return Colors.purple;
    }
    return Colors.grey;
  }

  /// Get current label bounds for testing purposes
  Map<String, Rect> getLabelBounds() => Map.from(_labelBounds);

  /// Hit test for connection labels
  String? hitTestLabel(Offset point) {
    for (final entry in _labelBounds.entries) {
      if (entry.value.contains(point)) {
        return entry.key;
      }
    }
    return null;
  }

  @override
  bool shouldRepaint(covariant ConnectionPainter oldDelegate) {
    return oldDelegate.connections != connections ||
        oldDelegate.connectionStateManager != connectionStateManager ||
        oldDelegate.enableAntiOverlap != enableAntiOverlap ||
        oldDelegate.showLabels != showLabels ||
        oldDelegate.enableAnimations != enableAnimations ||
        oldDelegate.animationProgress != animationProgress ||
        oldDelegate.hoveredConnectionId != hoveredConnectionId ||
        oldDelegate.theme != theme;
  }
}

/// Connection type for visual styling
enum ConnectionVisualType { regular, ghost, invalid, partial, selected }

/// Widget that uses ConnectionPainter for efficient batch rendering with animation support
class ConnectionCanvas extends StatefulWidget {
  final List<ConnectionData> connections;
  final ConnectionStateManager? connectionStateManager;
  final bool enableAntiOverlap;
  final bool showLabels;
  final bool enableAnimations;
  final Function(ConnectionData)? onConnectionTapped;

  const ConnectionCanvas({
    super.key,
    required this.connections,
    this.connectionStateManager,
    this.enableAntiOverlap = true,
    this.showLabels = true,
    this.enableAnimations = true,
    this.onConnectionTapped,
  });

  @override
  State<ConnectionCanvas> createState() => _ConnectionCanvasState();
}

class _ConnectionCanvasState extends State<ConnectionCanvas>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    // Initialize animation controller for ghost connection flow effects
    _animationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_animationController);

    // Start animation if there are ghost connections and animations are enabled
    if (widget.enableAnimations && _hasGhostConnections()) {
      _animationController.repeat();
    }
  }

  @override
  void didUpdateWidget(ConnectionCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update animation state based on ghost connections and animation settings
    if (widget.enableAnimations && _hasGhostConnections()) {
      if (!_animationController.isAnimating) {
        _animationController.repeat();
      }
    } else {
      _animationController.stop();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Check if any connections are ghost connections
  bool _hasGhostConnections() {
    return widget.connections.any((conn) => conn.isGhostConnection);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Stack(
          children: [
            // Main connection rendering
            CustomPaint(
              painter: ConnectionPainter(
                connections: widget.connections,
                theme: theme,
                connectionStateManager: widget.connectionStateManager,
                enableAntiOverlap: widget.enableAntiOverlap,
                showLabels: widget.showLabels,
                enableAnimations: widget.enableAnimations,
                animationProgress: widget.enableAnimations
                    ? _animation.value
                    : null,
              ),
              child: Container(), // Provides hit test area
            ),
            // Invisible tooltip trigger areas for ghost connections
            ...widget.connections
                .where((conn) => conn.isGhostConnection)
                .map((conn) => _buildTooltipTrigger(conn)),
          ],
        );
      },
    );
  }

  /// Build an invisible hover area for tooltip triggering
  Widget _buildTooltipTrigger(ConnectionData conn) {
    // Calculate the midpoint of the connection for tooltip placement
    final midpoint = Offset(
      (conn.sourcePosition.dx + conn.destinationPosition.dx) / 2,
      (conn.sourcePosition.dy + conn.destinationPosition.dy) / 2,
    );

    return Positioned(
      left: midpoint.dx - 20, // 40px wide hit area
      top: midpoint.dy - 10, // 20px tall hit area
      child: GhostConnectionTooltip(
        connection: conn.connection,
        child: Container(
          width: 40,
          height: 20,
          color: Colors.transparent, // Invisible but accepts hover events
        ),
      ),
    );
  }
}
