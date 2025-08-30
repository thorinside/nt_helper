import 'package:flutter/material.dart';
import 'package:nt_helper/core/routing/models/port.dart';
import 'package:nt_helper/ui/widgets/routing/connection_validator.dart';

/// Represents a connection between two ports in the routing canvas.
/// 
/// This immutable data class holds the information about which ports are connected
/// and provides all necessary data for the ConnectionLine widget to render the connection.
/// 
/// ## Features
/// - Immutable connection data structure
/// - Source and destination port information
/// - Canvas position coordinates for rendering
/// - Visual state management (selection, highlighting)
/// - Connection validity checking
/// - Color coding based on port types
/// - Optional metadata storage
/// 
/// ## Usage
/// ```dart
/// final connection = Connection(
///   sourcePort: outputPort,
///   destinationPort: inputPort,
///   sourcePosition: Offset(100, 50),
///   destinationPosition: Offset(300, 150),
///   isSelected: false,
///   isHighlighted: false,
/// );
/// ```
@immutable
class Connection {
  /// The source port (typically an output port).
  /// 
  /// This represents the starting point of the connection and determines
  /// the connection's color and validation rules.
  final Port sourcePort;
  
  /// The destination port (typically an input port).
  /// 
  /// This represents the ending point of the connection and is used
  /// for compatibility checking with the source port.
  final Port destinationPort;
  
  /// The position of the source port on the canvas.
  /// 
  /// Used as the starting point for drawing the bezier curve connection.
  final Offset sourcePosition;
  
  /// The position of the destination port on the canvas.
  /// 
  /// Used as the ending point for drawing the bezier curve connection.
  final Offset destinationPosition;
  
  /// Whether this connection is currently selected.
  /// 
  /// Selected connections are rendered with increased stroke width
  /// and full opacity for emphasis.
  final bool isSelected;
  
  /// Whether this connection should be highlighted (e.g., on hover).
  /// 
  /// Highlighted connections are rendered with slightly increased
  /// stroke width and higher opacity than normal.
  final bool isHighlighted;
  
  /// Optional metadata for this connection.
  /// 
  /// Can store additional data such as connection strength,
  /// latency, or other connection-specific properties.
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

  /// Returns true if this connection represents a ghost connection
  bool get isGhostConnection {
    return ConnectionValidator.isGhostConnection(sourcePort, destinationPort);
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
/// 
/// ## Features
/// - Smooth bezier curve rendering with horizontal control points
/// - Interactive hover and tap detection
/// - Animation support for connection drawing
/// - Color-coded connections based on port types
/// - Visual feedback for selection and highlighting states
/// - Invalid connection styling (red with reduced opacity)
/// - Optimized hit testing for easier interaction
/// - Accessibility support with semantic labels
/// 
/// ## Usage
/// ```dart
/// ConnectionLine(
///   connection: connectionData,
///   strokeWidth: 2.0,
///   animated: true,
///   onTapped: () => handleConnectionTap(),
///   onHover: (isHovered) => handleHover(isHovered),
/// )
/// ```
class ConnectionLine extends StatefulWidget {
  /// The connection data containing ports, positions, and visual state.
  /// 
  /// This provides all necessary information for rendering the connection line.
  final Connection connection;
  
  /// The base stroke width of the connection line.
  /// 
  /// The actual rendered width may be modified based on connection state
  /// (selection increases width by 1.5x, highlighting by 1.2x).
  final double strokeWidth;
  
  /// Callback invoked when the connection line is tapped.
  /// 
  /// Typically used for connection selection or context menu display.
  final VoidCallback? onTapped;
  
  /// Callback invoked when the connection is hovered (desktop/web platforms).
  /// 
  /// Receives a boolean indicating whether the mouse entered (true) or exited (false) the connection area.
  final ValueChanged<bool>? onHover;
  
  /// Whether to animate the connection drawing from start to finish.
  /// 
  /// When enabled, the connection will animate from source to destination
  /// using the specified animation duration and easing curve.
  final bool animated;
  
  /// The duration for the connection drawing animation.
  /// 
  /// Only used when [animated] is true. Uses ease-out cubic curve for natural motion.
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
    final semanticLabel = widget.connection.isGhostConnection
        ? 'Ghost connection from ${widget.connection.sourcePort.name} to ${widget.connection.destinationPort.name} - signal available to other algorithms'
        : 'Connection from ${widget.connection.sourcePort.name} to ${widget.connection.destinationPort.name}';
        
    final semanticHint = widget.connection.isGhostConnection
        ? 'Ghost connection line - algorithm output to physical I/O. Tap to select or modify.'
        : 'Port connection line. Tap to select or modify connection.';

    Widget connectionWidget = MouseRegion(
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

    // Wrap ghost connections in tooltip
    if (widget.connection.isGhostConnection) {
      final tooltipMessage = ConnectionValidator.getConnectionDescription(
        widget.connection.sourcePort, 
        widget.connection.destinationPort,
      );
      
      connectionWidget = Tooltip(
        message: tooltipMessage,
        waitDuration: const Duration(milliseconds: 500),
        child: connectionWidget,
      );
    }

    return Semantics(
      label: semanticLabel,
      hint: semanticHint,
      button: true,
      enabled: true,
      selected: widget.connection.isSelected,
      child: connectionWidget,
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
    
    // For ghost connections, create and draw dashed path
    Path pathToDraw = path;
    if (connection.isGhostConnection) {
      pathToDraw = _createDashedPath(path);
      paint.color = lineColor.withValues(alpha: lineColor.a * 0.7);
    }
    
    // Apply animation by trimming the path
    if (animationValue < 1.0 && animationValue > 0.0) {
      final pathMetrics = pathToDraw.computeMetrics();
      if (pathMetrics.isNotEmpty) {
        try {
          final pathMetric = pathMetrics.first;
          final pathLength = pathMetric.length;
          if (pathLength > 0) {
            final animatedLength = pathLength * animationValue;
            if (animatedLength > 0) {
              final animatedPath = pathMetric.extractPath(0.0, animatedLength);
              canvas.drawPath(animatedPath, paint);
            }
          }
        } catch (e) {
          // Fallback to drawing the full path if animation fails
          canvas.drawPath(pathToDraw, paint);
        }
      }
    } else {
      canvas.drawPath(pathToDraw, paint);
    }
    
    // Draw ghost connection indicator
    if (connection.isGhostConnection) {
      _drawGhostIndicator(canvas, path);
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
    
    // Validate input coordinates
    if (!start.isFinite || !end.isFinite) {
      // Return a simple line path as fallback
      path.moveTo(0, 0);
      path.lineTo(100, 100);
      return path;
    }
    
    path.moveTo(start.dx, start.dy);
    
    // Calculate control points for smooth curves
    final dx = end.dx - start.dx;
    
    // Use horizontal offset for control points to create natural curves
    final controlOffset = (dx.abs() * 0.5).clamp(10.0, 200.0);
    
    final controlPoint1 = Offset(
      start.dx + (dx > 0 ? controlOffset : -controlOffset),
      start.dy,
    );
    
    final controlPoint2 = Offset(
      end.dx - (dx > 0 ? controlOffset : -controlOffset),
      end.dy,
    );
    
    // Validate control points
    if (controlPoint1.isFinite && controlPoint2.isFinite) {
      path.cubicTo(
        controlPoint1.dx, controlPoint1.dy,
        controlPoint2.dx, controlPoint2.dy,
        end.dx, end.dy,
      );
    } else {
      // Fallback to simple line if control points are invalid
      path.lineTo(end.dx, end.dy);
    }
    
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
  
  /// Creates a dashed path for ghost connections
  Path _createDashedPath(Path originalPath) {
    final dashedPath = Path();
    final pathMetrics = originalPath.computeMetrics();
    
    for (final pathMetric in pathMetrics) {
      double distance = 0.0;
      bool draw = true;
      const double dashLength = 8.0;
      const double gapLength = 4.0;
      
      while (distance < pathMetric.length) {
        final segmentLength = draw ? dashLength : gapLength;
        final endDistance = (distance + segmentLength).clamp(0.0, pathMetric.length);
        
        if (draw) {
          final extractedPath = pathMetric.extractPath(distance, endDistance);
          dashedPath.addPath(extractedPath, Offset.zero);
        }
        
        distance = endDistance;
        draw = !draw;
      }
    }
    
    return dashedPath;
  }
  
  /// Draws ghost connection indicator (small ghost icon)
  void _drawGhostIndicator(Canvas canvas, Path connectionPath) {
    final pathMetrics = connectionPath.computeMetrics();
    if (pathMetrics.isEmpty) return;
    
    // Find the midpoint of the connection
    final pathMetric = pathMetrics.first;
    final midDistance = pathMetric.length * 0.5;
    final tangent = pathMetric.getTangentForOffset(midDistance);
    
    if (tangent == null) return;
    
    final midPoint = tangent.position;
    
    // Draw a small ghost icon (translucent circle with "G")
    final ghostPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.white.withValues(alpha: 0.9);
    
    const ghostRadius = 10.0;
    canvas.drawCircle(midPoint, ghostRadius, ghostPaint);
    
    // Draw border
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = connection.getConnectionColor().withValues(alpha: 0.8);
    
    canvas.drawCircle(midPoint, ghostRadius, borderPaint);
    
    // Draw "G" text
    final textSpan = TextSpan(
      text: 'G',
      style: TextStyle(
        color: connection.getConnectionColor().withValues(alpha: 0.9),
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
    );
    
    final textPainter = TextPainter(
      text: textSpan,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout();
    final textOffset = Offset(
      midPoint.dx - textPainter.width / 2,
      midPoint.dy - textPainter.height / 2,
    );
    
    textPainter.paint(canvas, textOffset);
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
/// and provides batch operations for connection management. It uses a Stack
/// layout to overlay all connections and supports individual interaction callbacks.
/// 
/// ## Performance Features
/// - Efficient Stack-based rendering for multiple connections
/// - Individual connection interaction handling
/// - Batch animation support
/// - Optimized for large numbers of connections
/// 
/// ## Usage
/// ```dart
/// ConnectionLineManager(
///   connections: connectionsList,
///   strokeWidth: 2.0,
///   animated: true,
///   onConnectionTapped: (connection) => handleTap(connection),
///   onConnectionHover: (connection, hovered) => handleHover(connection, hovered),
/// )
/// ```
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