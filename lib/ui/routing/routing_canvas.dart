import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nt_helper/cubit/node_routing_cubit.dart';
import 'package:nt_helper/cubit/node_routing_state.dart';
import 'package:nt_helper/models/connection.dart';
import 'package:nt_helper/models/connection_preview.dart';
import 'package:nt_helper/models/node_position.dart';
import 'package:nt_helper/models/port_layout.dart';
import 'package:nt_helper/ui/routing/algorithm_node_widget.dart';
import 'package:nt_helper/ui/routing/connection_painter.dart';
import 'package:nt_helper/ui/widgets/port_widget.dart';

typedef NodePositionCallback =
    void Function(int algorithmIndex, NodePosition position);
typedef ConnectionCallback = void Function(Connection connection);
typedef PortConnectionCallback =
    void Function(int algorithmIndex, String portId, PortType type);

class RoutingCanvas extends StatefulWidget {
  final Map<int, NodePosition> nodePositions;
  final Map<int, String> algorithmNames;
  final Map<int, PortLayout> portLayouts;
  final List<Connection> connections;
  final Set<String> connectedPorts;
  final Map<String, Offset> portPositions;
  final ConnectionPreview? connectionPreview;
  final String? hoveredConnectionId;
  final NodePositionCallback? onNodePositionChanged;
  final ConnectionCallback? onConnectionCreated;
  final ConnectionCallback? onConnectionRemoved;
  final VoidCallback? onSelectionChanged;

  const RoutingCanvas({
    super.key,
    required this.nodePositions,
    required this.algorithmNames,
    required this.portLayouts,
    required this.connections,
    required this.portPositions,
    this.connectedPorts = const {},
    this.connectionPreview,
    this.hoveredConnectionId,
    this.onNodePositionChanged,
    this.onConnectionCreated,
    this.onConnectionRemoved,
    this.onSelectionChanged,
  });

  @override
  State<RoutingCanvas> createState() => _RoutingCanvasState();
}

class _RoutingCanvasState extends State<RoutingCanvas> {
  static const double _canvasSize = 5000.0;
  static const double _gridSpacing = 50.0;

  Set<int> _selectedNodes = {};
  Connection? _hoveredConnection;
  final GlobalKey _canvasKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Container(
        key: _canvasKey,
        width: _canvasSize,
        height: _canvasSize,
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        child: Stack(
          children: [
            // Grid background with gesture detector for empty space (bottom layer)
            GestureDetector(
              onPanUpdate: _handleCanvasPanUpdate,
              onPanEnd: _handleCanvasPanEnd,
              onTapDown: _handleCanvasTapDown,
              behavior: HitTestBehavior.opaque,  // This will catch events in empty space
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: _GridPainter(
                    spacing: _gridSpacing,
                    color: Theme.of(
                      context,
                    ).colorScheme.outline.withValues(alpha: 0.2),
                  ),
                  size: const Size(_canvasSize, _canvasSize),
                ),
              ),
            ),

            // Nodes layer (middle layer) - gestures handled by nodes themselves
            ...widget.nodePositions.entries.map((entry) {
              final algorithmIndex = entry.key;
              final position = entry.value;
              final algorithmName =
                  widget.algorithmNames[algorithmIndex] ?? 'Unknown';
              final portLayout = widget.portLayouts[algorithmIndex];

              if (portLayout == null) return const SizedBox.shrink();
              
              // Determine which algorithms have this index in the sorted positions
              final sortedIndices = widget.nodePositions.keys.toList()..sort();
              final canMoveUp = algorithmIndex > 0;
              final canMoveDown = algorithmIndex < sortedIndices.length - 1;

              return AlgorithmNodeWidget(
                key: ValueKey(algorithmIndex),
                nodePosition: position,
                algorithmName: algorithmName,
                inputPorts: portLayout.inputPorts,
                outputPorts: portLayout.outputPorts,
                isSelected: _selectedNodes.contains(algorithmIndex),
                connectedPorts: widget.connectedPorts,
                canMoveUp: canMoveUp,
                canMoveDown: canMoveDown,
                onMoveUp: canMoveUp ? () => _handleMoveAlgorithmUp(algorithmIndex) : null,
                onMoveDown: canMoveDown ? () => _handleMoveAlgorithmDown(algorithmIndex) : null,
                onPositionChanged: (newPosition) {
                  widget.onNodePositionChanged?.call(
                    algorithmIndex,
                    newPosition,
                  );
                },
                onPortConnectionStart: (portId, type) =>
                    _handlePortConnectionStart(algorithmIndex, portId, type),
                onPortConnectionEnd: (portId, type) =>
                    _handlePortConnectionEnd(algorithmIndex, portId, type),
                onPortPanStart: (portId, type, details) =>
                    _handlePortPanStart(algorithmIndex, portId, type, details),
                onPortPanUpdate: (portId, type, details) =>
                    _handlePortPanUpdate(algorithmIndex, portId, type, details),
                onPortPanEnd: (portId, type, details) =>
                    _handlePortPanEnd(algorithmIndex, portId, type, details),
              );
            }),

            // Connections layer (top layer - drawn last, appears on top)
            RepaintBoundary(
              child: MouseRegion(
                cursor: _hoveredConnection != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
                onHover: _handleConnectionHover,
                onExit: (_) => _handleConnectionExit(),
                child: GestureDetector(
                  onTapDown: _handleConnectionTapDown,
                  behavior: HitTestBehavior.translucent,
                  child: CustomPaint(
                    painter: ConnectionPainter(
                      connections: widget.connections,
                      portPositions: widget.portPositions,
                      connectionPreview: widget.connectionPreview,
                      hoveredConnectionId: _hoveredConnection?.id,
                    ),
                    size: const Size(_canvasSize, _canvasSize),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handlePortConnectionStart(
    int algorithmIndex,
    String portId,
    PortType type,
  ) {
    if (type == PortType.output) {
      final cubit = context.read<NodeRoutingCubit>();
      
      // Start connection preview - the ConnectionPainter will get the actual port position
      cubit.startConnectionPreview(
        algorithmIndex,
        portId,
        Offset.zero, // Initial cursor position, will be updated on first pan update
      );
    }
  }

  void _handlePortConnectionEnd(
    int algorithmIndex,
    String portId,
    PortType type,
  ) {
    final cubit = context.read<NodeRoutingCubit>();
    final currentState = cubit.state;
    
    if (type == PortType.input && 
        currentState is NodeRoutingStateLoaded && 
        currentState.connectionPreview != null) {
      // Create new connection through cubit
      final connection = Connection(
        id: '${currentState.connectionPreview!.sourceAlgorithmIndex}_${currentState.connectionPreview!.sourcePortId}_${algorithmIndex}_$portId',
        sourceAlgorithmIndex: currentState.connectionPreview!.sourceAlgorithmIndex,
        sourcePortId: currentState.connectionPreview!.sourcePortId,
        targetAlgorithmIndex: algorithmIndex,
        targetPortId: portId,
        assignedBus: 21, // Will be assigned by auto-routing service
        replaceMode: true,
        isValid: true,
      );

      widget.onConnectionCreated?.call(connection);
    }

    // Clear connection preview
    cubit.clearConnectionPreview();
  }

  void _handlePortPanStart(
    int algorithmIndex,
    String portId,
    PortType type,
    DragStartDetails details,
  ) {
    if (type == PortType.output) {
      final cubit = context.read<NodeRoutingCubit>();
      
      // Get the actual port position to start from
      final portKey = '${algorithmIndex}_$portId';
      final portPosition = widget.portPositions[portKey] ?? Offset.zero;
      
      debugPrint('[RoutingCanvas] Starting connection from port $portKey at $portPosition');
      
      // Start connection preview at the port position
      // The line will appear as soon as the mouse moves away from the port
      cubit.startConnectionPreview(
        algorithmIndex,
        portId,
        portPosition,  // Start at port center
      );
    }
  }

  void _handlePortPanUpdate(
    int algorithmIndex,
    String portId,
    PortType type,
    DragUpdateDetails details,
  ) {
    if (type == PortType.output) {
      final cubit = context.read<NodeRoutingCubit>();
      final currentState = cubit.state;
      
      if (currentState is NodeRoutingStateLoaded && currentState.connectionPreview != null) {
        // Convert global coordinates to canvas-local coordinates
        final RenderBox? canvasBox = _canvasKey.currentContext?.findRenderObject() as RenderBox?;
        if (canvasBox == null) {
          debugPrint('[RoutingCanvas] Could not find canvas render box');
          return;
        }
        
        final canvasPosition = canvasBox.globalToLocal(details.globalPosition);
        debugPrint('[RoutingCanvas] Pan update: global=${details.globalPosition}, canvas=$canvasPosition');
        
        // Use cubit for hit testing with canvas coordinates
        final hoveredAlgorithm = cubit.getAlgorithmAtPosition(canvasPosition);
        final hoveredPort = hoveredAlgorithm != null 
            ? cubit.getPortAtPosition(canvasPosition, hoveredAlgorithm)
            : null;

        // Update connection preview through cubit
        cubit.updateConnectionPreview(
          canvasPosition,
          hoveredAlgorithmIndex: hoveredAlgorithm,
          hoveredPortId: hoveredPort,
        );
      }
    }
  }

  void _handlePortPanEnd(
    int algorithmIndex,
    String portId,
    PortType type,
    DragEndDetails details,
  ) async {
    if (type == PortType.output) {
      final cubit = context.read<NodeRoutingCubit>();
      final currentState = cubit.state;
      
      // Check if we have a valid connection preview that can be completed
      if (currentState is NodeRoutingStateLoaded && 
          currentState.connectionPreview != null &&
          currentState.connectionPreview!.isValid &&
          currentState.connectionPreview!.hoveredTargetAlgorithmIndex != null &&
          currentState.connectionPreview!.hoveredTargetPortId != null) {
        
        // Create the connection (async)
        await cubit.createConnection(
          sourceAlgorithmIndex: currentState.connectionPreview!.sourceAlgorithmIndex,
          sourcePortId: currentState.connectionPreview!.sourcePortId,
          targetAlgorithmIndex: currentState.connectionPreview!.hoveredTargetAlgorithmIndex!,
          targetPortId: currentState.connectionPreview!.hoveredTargetPortId!,
        );
      }
      
      // Always clear connection preview at the end
      cubit.clearConnectionPreview();
    }
  }


  void _handleCanvasPanUpdate(DragUpdateDetails details) {
    final cubit = context.read<NodeRoutingCubit>();
    final currentState = cubit.state;
    
    if (currentState is NodeRoutingStateLoaded && currentState.connectionPreview != null) {
      // Use cubit for hit testing
      final hoveredAlgorithm = cubit.getAlgorithmAtPosition(details.localPosition);
      final hoveredPort = hoveredAlgorithm != null 
          ? cubit.getPortAtPosition(details.localPosition, hoveredAlgorithm)
          : null;

      // Update connection preview through cubit
      cubit.updateConnectionPreview(
        details.localPosition,
        hoveredAlgorithmIndex: hoveredAlgorithm,
        hoveredPortId: hoveredPort,
      );
    }
  }

  void _handleCanvasPanEnd(DragEndDetails details) {
    final cubit = context.read<NodeRoutingCubit>();
    final currentState = cubit.state;
    
    // Check if we have a valid connection preview that can be completed
    if (currentState is NodeRoutingStateLoaded && 
        currentState.connectionPreview != null &&
        currentState.connectionPreview!.isValid &&
        currentState.connectionPreview!.hoveredTargetAlgorithmIndex != null &&
        currentState.connectionPreview!.hoveredTargetPortId != null) {
      
      // Create the connection
      cubit.createConnection(
        sourceAlgorithmIndex: currentState.connectionPreview!.sourceAlgorithmIndex,
        sourcePortId: currentState.connectionPreview!.sourcePortId,
        targetAlgorithmIndex: currentState.connectionPreview!.hoveredTargetAlgorithmIndex!,
        targetPortId: currentState.connectionPreview!.hoveredTargetPortId!,
      );
    }
    
    // Clear connection preview through cubit
    cubit.clearConnectionPreview();
  }

  void _handleCanvasTapDown(TapDownDetails details) {
    final cubit = context.read<NodeRoutingCubit>();
    
    // Check if tapping on a node using cubit hit testing
    final tappedNode = cubit.getAlgorithmAtPosition(details.localPosition);
    if (tappedNode != null) {
      setState(() {
        _selectedNodes = {tappedNode};
      });
      widget.onSelectionChanged?.call();
      return;
    }

    // Clicked on empty space - clear selection
    setState(() {
      _selectedNodes.clear();
    });
    widget.onSelectionChanged?.call();
  }
  
  void _handleMoveAlgorithmUp(int algorithmIndex) {
    final cubit = context.read<NodeRoutingCubit>();
    cubit.moveAlgorithmUp(algorithmIndex);
  }
  
  void _handleMoveAlgorithmDown(int algorithmIndex) {
    final cubit = context.read<NodeRoutingCubit>();
    cubit.moveAlgorithmDown(algorithmIndex);
  }
  
  void _handleConnectionHover(PointerEvent event) {
    final hoveredConnection = _getConnectionAtPosition(event.localPosition);
    if (hoveredConnection != _hoveredConnection) {
      setState(() {
        _hoveredConnection = hoveredConnection;
      });
    }
  }
  
  void _handleConnectionExit() {
    if (_hoveredConnection != null) {
      setState(() {
        _hoveredConnection = null;
      });
    }
  }
  
  void _handleConnectionTapDown(TapDownDetails details) {
    // Find which connection was clicked
    final clickedConnection = _getConnectionAtPosition(details.localPosition);
    if (clickedConnection != null) {
      // Show confirmation dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Remove Connection'),
          content: Text(
            'Remove connection ${clickedConnection.getEdgeLabel()}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                widget.onConnectionRemoved?.call(clickedConnection);
              },
              child: const Text('Remove', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
    }
  }
  
  Connection? _getConnectionAtPosition(Offset position) {
    // Check each connection to see if the click is near the line
    for (final connection in widget.connections) {
      final sourceKey = '${connection.sourceAlgorithmIndex}_${connection.sourcePortId}';
      final targetKey = '${connection.targetAlgorithmIndex}_${connection.targetPortId}';
      
      final sourcePos = widget.portPositions[sourceKey];
      final targetPos = widget.portPositions[targetKey];
      
      if (sourcePos == null || targetPos == null) continue;
      
      // Check if click is near the bezier curve
      if (_isPointNearBezier(position, sourcePos, targetPos, tolerance: 10.0)) {
        return connection;
      }
    }
    return null;
  }
  
  bool _isPointNearBezier(Offset point, Offset start, Offset end, {double tolerance = 10.0}) {
    // Sample points along the bezier curve and check distance
    const samples = 20;
    for (int i = 0; i <= samples; i++) {
      final t = i / samples;
      final curvePoint = _getBezierPoint(t, start, end);
      final distance = (point - curvePoint).distance;
      if (distance <= tolerance) {
        return true;
      }
    }
    return false;
  }
  
  Offset _getBezierPoint(double t, Offset start, Offset end) {
    // Calculate bezier point at parameter t
    // Using same control point logic as ConnectionPainter
    final distance = (end - start).distance;
    final controlStrength = math.min(distance * 0.4, 100.0);
    
    Offset cp1, cp2;
    if ((end.dx - start.dx).abs() > (end.dy - start.dy).abs()) {
      // Horizontal-dominant
      cp1 = Offset(start.dx + controlStrength, start.dy);
      cp2 = Offset(end.dx - controlStrength, end.dy);
    } else {
      // Vertical
      final midY = (start.dy + end.dy) / 2;
      cp1 = Offset(start.dx + controlStrength * 0.3, midY);
      cp2 = Offset(end.dx - controlStrength * 0.3, midY);
    }
    
    // Cubic bezier formula
    final u = 1 - t;
    return start * (u * u * u) +
           cp1 * (3 * u * u * t) +
           cp2 * (3 * u * t * t) +
           end * (t * t * t);
  }

}

class _GridPainter extends CustomPainter {
  final double spacing;
  final Color color;

  _GridPainter({required this.spacing, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0;

    // Draw vertical lines
    for (double x = 0; x <= size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Draw horizontal lines
    for (double y = 0; y <= size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter oldDelegate) {
    return spacing != oldDelegate.spacing || color != oldDelegate.color;
  }
}
