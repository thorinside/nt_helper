import 'package:flutter/material.dart';
import 'package:nt_helper/core/routing/models/port.dart';

/// Represents a connection between two ports in the routing canvas.
/// 
/// This class holds the information about which ports are connected
/// and provides data for the ConnectionLine widget to render.
@immutable
class Connection {
  /// The source port (typically an output port)
  final Port sourcePort;
  
  /// The destination port (typically an input port)  
  final Port destinationPort;
  
  /// The position of the source port on the canvas
  final Offset sourcePosition;
  
  /// The position of the destination port on the canvas
  final Offset destinationPosition;
  
  /// Whether this connection is currently selected
  final bool isSelected;
  
  /// Whether this connection should be highlighted (e.g., on hover)
  final bool isHighlighted;
  
  /// Optional metadata for this connection
  final Map<String, dynamic>? metadata;

  const Connection({
    required this.sourcePort,
    required this.destinationPort,
    required this.sourcePosition,
    required this.destinationPosition,
    this.isSelected = false,
    this.isHighlighted = false,
    this.metadata,
  });

  /// Creates a copy of this connection with updated properties
  Connection copyWith({
    Port? sourcePort,
    Port? destinationPort,
    Offset? sourcePosition,
    Offset? destinationPosition,
    bool? isSelected,
    bool? isHighlighted,
    Map<String, dynamic>? metadata,
  }) {
    return Connection(
      sourcePort: sourcePort ?? this.sourcePort,
      destinationPort: destinationPort ?? this.destinationPort,
      sourcePosition: sourcePosition ?? this.sourcePosition,
      destinationPosition: destinationPosition ?? this.destinationPosition,
      isSelected: isSelected ?? this.isSelected,
      isHighlighted: isHighlighted ?? this.isHighlighted,
      metadata: metadata ?? this.metadata,
    );
  }
  
  /// Gets the connection color based on the port types
  Color getConnectionColor() {
    // Use the source port type to determine color
    switch (sourcePort.type) {
      case PortType.audio:
        return Colors.blue;
      case PortType.cv:
        return Colors.orange;
      case PortType.gate:
        return Colors.red;
      case PortType.clock:
        return Colors.purple;
    }
  }
  
  /// Returns true if this connection is valid based on port compatibility
  bool get isValid {
    return sourcePort.canConnectTo(destinationPort) && 
           sourcePort.isCompatibleWith(destinationPort);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Connection &&
        other.sourcePort == sourcePort &&
        other.destinationPort == destinationPort;
  }

  @override
  int get hashCode => Object.hash(sourcePort, destinationPort);
}

/// A custom painter widget that draws bezier curve connections between ports.
/// 
/// This widget renders smooth, visually appealing connections using Flutter's
/// CustomPainter API. It supports interactive feedback such as highlighting
/// and selection states.
class ConnectionLine extends StatefulWidget {
  /// The connection to render
  final Connection connection;
  
  /// The stroke width of the connection line
  final double strokeWidth;
  
  /// Called when the connection is tapped
  final VoidCallback? onTapped;
  
  /// Called when the connection is hovered (desktop/web)
  final ValueChanged<bool>? onHover;
  
  /// Whether to animate the connection drawing
  final bool animated;
  
  /// The animation duration for drawing the connection
  final Duration animationDuration;

  const ConnectionLine({
    super.key,
    required this.connection,
    this.strokeWidth = 2.0,
    this.onTapped,
    this.onHover,
    this.animated = false,
    this.animationDuration = const Duration(milliseconds: 300),
  });

  @override
  State<ConnectionLine> createState() => _ConnectionLineState();
}

class _ConnectionLineState extends State<ConnectionLine> 
    with SingleTickerProviderStateMixin {
  
  AnimationController? _animationController;
  Animation<double>? _animation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    
    if (widget.animated) {
      _animationController = AnimationController(
        duration: widget.animationDuration,
        vsync: this,
      );
      
      _animation = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: _animationController!,
        curve: Curves.easeOutCubic,
      ));
      
      _animationController!.forward();
    }
  }

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _handleHover(true),
      onExit: (_) => _handleHover(false),
      child: GestureDetector(
        onTap: widget.onTapped,
        child: CustomPaint(
          painter: _ConnectionLinePainter(
            connection: widget.connection,
            strokeWidth: widget.strokeWidth,
            isHovered: _isHovered,
            animationValue: widget.animated ? (_animation?.value ?? 1.0) : 1.0,
          ),
          child: Container(), // Empty container to provide hit area
        ),
      ),
    );
  }
  
  void _handleHover(bool isHovered) {
    if (_isHovered != isHovered) {
      setState(() {
        _isHovered = isHovered;
      });
      widget.onHover?.call(isHovered);
    }
  }
}

/// Custom painter that renders the bezier curve connection lines.
/// 
/// This painter creates smooth curves between connection points and handles
/// visual states like selection, highlighting, and animation.
class _ConnectionLinePainter extends CustomPainter {
  /// The connection to paint
  final Connection connection;
  
  /// The stroke width for the connection line
  final double strokeWidth;
  
  /// Whether the connection is currently hovered
  final bool isHovered;
  
  /// Animation value for drawing the connection (0.0 to 1.0)
  final double animationValue;

  const _ConnectionLinePainter({
    required this.connection,
    required this.strokeWidth,
    required this.isHovered,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Determine line properties based on connection state
    double effectiveStrokeWidth = strokeWidth;
    Color lineColor = connection.getConnectionColor();
    
    if (connection.isSelected) {
      effectiveStrokeWidth *= 1.5;
      lineColor = lineColor.withValues(alpha: 1.0);
    } else if (connection.isHighlighted || isHovered) {
      effectiveStrokeWidth *= 1.2;
      lineColor = lineColor.withValues(alpha: 0.8);
    } else {
      lineColor = lineColor.withValues(alpha: 0.6);
    }
    
    // Adjust for invalid connections
    if (!connection.isValid) {
      lineColor = Colors.red.withValues(alpha: 0.5);
    }
    
    paint
      ..strokeWidth = effectiveStrokeWidth
      ..color = lineColor;

    // Create the bezier curve path
    final path = _createBezierPath(
      connection.sourcePosition,
      connection.destinationPosition,
    );
    
    // Apply animation by trimming the path
    if (animationValue < 1.0) {
      final pathMetrics = path.computeMetrics();
      if (pathMetrics.isNotEmpty) {
        final pathMetric = pathMetrics.first;
        final animatedPath = pathMetric.extractPath(
          0.0,
          pathMetric.length * animationValue,
        );
        canvas.drawPath(animatedPath, paint);
      }
    } else {
      canvas.drawPath(path, paint);
    }
    
    // Draw connection endpoints
    _drawEndpoints(canvas, paint);
    
    // Draw selection indicator if selected
    if (connection.isSelected) {
      _drawSelectionIndicator(canvas, paint);
    }
  }

  /// Creates a smooth bezier curve path between two points
  Path _createBezierPath(Offset start, Offset end) {
    final path = Path();
    path.moveTo(start.dx, start.dy);
    
    // Calculate control points for smooth curves
    final dx = end.dx - start.dx;
    
    // Use horizontal offset for control points to create natural curves
    final controlOffset = dx.abs() * 0.5;
    
    final controlPoint1 = Offset(
      start.dx + controlOffset,
      start.dy,
    );
    
    final controlPoint2 = Offset(
      end.dx - controlOffset,
      end.dy,
    );
    
    path.cubicTo(
      controlPoint1.dx, controlPoint1.dy,
      controlPoint2.dx, controlPoint2.dy,
      end.dx, end.dy,
    );
    
    return path;
  }
  
  /// Draws small circles at the connection endpoints
  void _drawEndpoints(Canvas canvas, Paint paint) {
    final endpointPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = connection.getConnectionColor();
      
    const endpointRadius = 3.0;
    
    canvas.drawCircle(connection.sourcePosition, endpointRadius, endpointPaint);
    canvas.drawCircle(connection.destinationPosition, endpointRadius, endpointPaint);
  }
  
  /// Draws a selection indicator around the connection
  void _drawSelectionIndicator(Canvas canvas, Paint paint) {
    final selectionPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth + 4
      ..color = Colors.blue.withValues(alpha: 0.3)
      ..strokeCap = StrokeCap.round;
      
    final path = _createBezierPath(
      connection.sourcePosition,
      connection.destinationPosition,
    );
    
    canvas.drawPath(path, selectionPaint);
  }

  @override
  bool shouldRepaint(covariant _ConnectionLinePainter oldDelegate) {
    return oldDelegate.connection != connection ||
           oldDelegate.strokeWidth != strokeWidth ||
           oldDelegate.isHovered != isHovered ||
           oldDelegate.animationValue != animationValue;
  }

  @override
  bool hitTest(Offset position) {
    // Create a path for hit testing with wider stroke
    final path = _createBezierPath(
      connection.sourcePosition,
      connection.destinationPosition,
    );
    
    // Increase hit area for easier interaction
    const hitTestStrokeWidth = 8.0;
    
    return path.contains(position) || _isNearPath(path, position, hitTestStrokeWidth);
  }
  
  /// Checks if a position is near the path within a given distance
  bool _isNearPath(Path path, Offset position, double distance) {
    final pathMetrics = path.computeMetrics();
    
    for (final pathMetric in pathMetrics) {
      const step = 2.0; // Step size for sampling the path
      for (double i = 0; i < pathMetric.length; i += step) {
        final tangent = pathMetric.getTangentForOffset(i);
        if (tangent != null) {
          final pathPoint = tangent.position;
          final distanceToPoint = (pathPoint - position).distance;
          if (distanceToPoint <= distance) {
            return true;
          }
        }
      }
    }
    
    return false;
  }
}

/// A widget that manages multiple ConnectionLine widgets efficiently.
/// 
/// This widget is optimized for rendering many connections simultaneously
/// and provides batch operations for connection management.
class ConnectionLineManager extends StatelessWidget {
  /// The list of connections to render
  final List<Connection> connections;
  
  /// The stroke width for all connection lines
  final double strokeWidth;
  
  /// Called when a connection is tapped
  final Function(Connection connection)? onConnectionTapped;
  
  /// Called when a connection is hovered
  final Function(Connection connection, bool isHovered)? onConnectionHover;
  
  /// Whether to animate connection drawing
  final bool animated;

  const ConnectionLineManager({
    super.key,
    required this.connections,
    this.strokeWidth = 2.0,
    this.onConnectionTapped,
    this.onConnectionHover,
    this.animated = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: connections.map((connection) {
        return ConnectionLine(
          connection: connection,
          strokeWidth: strokeWidth,
          animated: animated,
          onTapped: () => onConnectionTapped?.call(connection),
          onHover: (isHovered) => onConnectionHover?.call(connection, isHovered),
        );
      }).toList(),
    );
  }
}