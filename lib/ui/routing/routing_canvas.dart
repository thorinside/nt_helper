import 'dart:io' show Platform;
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
import 'package:nt_helper/ui/routing/physical_input_node_widget.dart';
import 'package:nt_helper/ui/routing/physical_output_node_widget.dart';
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
  final Set<String> pendingConnections;
  final Set<String> failedConnections;
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
    this.pendingConnections = const {},
    this.failedConnections = const {},
    this.onNodePositionChanged,
    this.onConnectionCreated,
    this.onConnectionRemoved,
    this.onSelectionChanged,
  });

  @override
  State<RoutingCanvas> createState() => _RoutingCanvasState();
}

class _RoutingCanvasState extends State<RoutingCanvas> {
  static const double _baseCanvasSize = 3000.0; // Base size for initial canvas
  static const double _gridSpacing = 50.0;
  static const double _canvasExpansion = 1000.0; // How much to expand when needed

  Set<int> _selectedNodes = {};
  Connection? _hoveredConnection;
  String? _hoveredLabelId;
  ConnectionPainter? _connectionPainter;
  final GlobalKey _canvasKey = GlobalKey();
  bool _finalizingConnection = false; // Prevent double create on pointer up + pan end
  double? _lastScreenWidth; // Track screen width changes
  
  // Canvas dynamic sizing state
  Size _canvasSize = const Size(_baseCanvasSize, _baseCanvasSize);
  
  // Platform detection for mobile interactions
  bool get isMobile => Platform.isAndroid || Platform.isIOS;
  
  /// Calculate required canvas bounds based on node positions
  Size _calculateRequiredCanvasBounds() {
    final cubit = context.read<NodeRoutingCubit>();
    final state = cubit.state;
    
    // Start with base canvas size
    double requiredWidth = _baseCanvasSize;
    double requiredHeight = _baseCanvasSize;
    
    // Check node positions to ensure canvas accommodates all content
    if (state is NodeRoutingStateLoaded) {
      // Check algorithm nodes
      for (final position in state.nodePositions.values) {
        final nodeRight = position.x + position.width + _canvasExpansion;
        final nodeBottom = position.y + position.height + _canvasExpansion;
        requiredWidth = math.max(requiredWidth, nodeRight);
        requiredHeight = math.max(requiredHeight, nodeBottom);
      }
      
      // Check physical output node
      final physicalOutputPosition = state.physicalOutputPosition ?? const NodePosition(
        x: 700.0, y: 100.0, width: 80.0, height: 188.0, algorithmIndex: -3,
      );
      final outputRight = physicalOutputPosition.x + physicalOutputPosition.width + _canvasExpansion;
      final outputBottom = physicalOutputPosition.y + physicalOutputPosition.height + _canvasExpansion;
      requiredWidth = math.max(requiredWidth, outputRight);
      requiredHeight = math.max(requiredHeight, outputBottom);
      
      // Check physical input node (fixed position)
      const inputNodeWidth = 80.0;
      const inputNodeHeight = 188.0;
      const inputRight = 50.0 + inputNodeWidth + _canvasExpansion;
      const inputBottom = 100.0 + inputNodeHeight + _canvasExpansion;
      requiredWidth = math.max(requiredWidth, inputRight);
      requiredHeight = math.max(requiredHeight, inputBottom);
    }
    
    return Size(requiredWidth, requiredHeight);
  }
  
  /// Update canvas size if needed
  void _updateCanvasSizeIfNeeded() {
    final requiredSize = _calculateRequiredCanvasBounds();
    
    if (requiredSize.width > _canvasSize.width || requiredSize.height > _canvasSize.height) {
      final newSize = Size(
        math.max(_canvasSize.width, requiredSize.width),
        math.max(_canvasSize.height, requiredSize.height),
      );
      
      debugPrint('[RoutingCanvas] Expanding canvas from ${_canvasSize.width.toInt()}x${_canvasSize.height.toInt()} to ${newSize.width.toInt()}x${newSize.height.toInt()}');
      
      setState(() {
        _canvasSize = newSize;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Update canvas size based on current state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateCanvasSizeIfNeeded();
    });
    
    // Check if screen width changed and update cubit
    if (_lastScreenWidth != screenWidth) {
      _lastScreenWidth = screenWidth;
      // Use post-frame callback to avoid calling setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final cubit = context.read<NodeRoutingCubit>();
        cubit.updateScreenWidth(screenWidth);
      });
    }
    
    // Update physical output node position based on screen width
    NodeRoutingCubit.updatePhysicalOutputPositionStatic(screenWidth);
    
    return Listener(
      // Fallback: create connection on any pointer up if preview is valid
      onPointerUp: _handleGlobalPointerUp,
      child: Container(
        key: _canvasKey,
        width: _canvasSize.width,
        height: _canvasSize.height,
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        child: Stack(
            children: [
              // Grid background with gesture detector for empty space (bottom layer)
              GestureDetector(
                // Handle taps on empty space (panning now handled by ScrollView)
                onTapDown: _handleCanvasTapDown,
                behavior: HitTestBehavior.opaque,  // Catch events in empty space only
                child: RepaintBoundary(
                child: CustomPaint(
                  painter: _GridPainter(
                    spacing: _gridSpacing,
                    color: Theme.of(
                      context,
                    ).colorScheme.outline.withValues(alpha: 0.2),
                  ),
                  size: _canvasSize,
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
                onDelete: () => _handleDeleteAlgorithm(algorithmIndex),
                onPositionChanged: (newPosition) {
                  widget.onNodePositionChanged?.call(
                    algorithmIndex,
                    newPosition,
                  );
                  // Update canvas size to accommodate new node position
                  _updateCanvasSizeIfNeeded();
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

            // Physical input node (fixed position on left)
            Positioned(
              left: 50.0,
              top: 100.0,
              child: PhysicalInputNodeWidget(
                connectedPorts: widget.connectedPorts,
                onPortConnectionStart: (portId, type) =>
                    _handlePortConnectionStart(-2, portId, type),
                onPortConnectionEnd: (portId, type) =>
                    _handlePortConnectionEnd(-2, portId, type),
                onPortPanStart: (portId, type, details) =>
                    _handlePortPanStart(-2, portId, type, details),
                onPortPanUpdate: (portId, type, details) =>
                    _handlePortPanUpdate(-2, portId, type, details),
                onPortPanEnd: (portId, type, details) =>
                    _handlePortPanEnd(-2, portId, type, details),
              ),
            ),

            // Physical output node (dynamic position)
            BlocBuilder<NodeRoutingCubit, NodeRoutingState>(
              builder: (context, state) {
                if (state is! NodeRoutingStateLoaded) {
                  return const SizedBox.shrink();
                }
                
                // Use helper to get position with fallback
                final physicalOutputPosition = state.physicalOutputPosition ?? const NodePosition(
                  x: 700.0, // Default fallback
                  y: 100.0,
                  width: 80.0,
                  height: 188.0,
                  algorithmIndex: -3,
                );
                
                return Positioned(
                  left: physicalOutputPosition.x,
                  top: physicalOutputPosition.y,
                  child: PhysicalOutputNodeWidget(
                    nodePosition: physicalOutputPosition,
                    connectedPorts: widget.connectedPorts,
                    onPositionChanged: (newPosition) {
                      context.read<NodeRoutingCubit>().updatePhysicalOutputPosition(newPosition);
                      // Update canvas size to accommodate new physical output position
                      _updateCanvasSizeIfNeeded();
                    },
                    onPortConnectionStart: (portId, type) =>
                        _handlePortConnectionStart(-3, portId, type),
                    onPortConnectionEnd: (portId, type) =>
                        _handlePortConnectionEnd(-3, portId, type),
                    onPortPanStart: (portId, type, details) =>
                        _handlePortPanStart(-3, portId, type, details),
                    onPortPanUpdate: (portId, type, details) =>
                        _handlePortPanUpdate(-3, portId, type, details),
                    onPortPanEnd: (portId, type, details) =>
                        _handlePortPanEnd(-3, portId, type, details),
                  ),
                );
              },
            ),

            // Connections layer (top layer - drawn last, appears on top)
            RepaintBoundary(
              child: MouseRegion(
                opaque: false, // Don't block hits to nodes/ports underneath
                cursor: isMobile ? SystemMouseCursors.basic
                  : (_hoveredLabelId != null ? SystemMouseCursors.click 
                    : (_hoveredConnection != null ? SystemMouseCursors.click : SystemMouseCursors.basic)),
                onHover: isMobile ? null : _handleConnectionHover,
                onExit: isMobile ? null : (_) => _handleConnectionExit(),
                child: GestureDetector(
                  onTapDown: _handleConnectionTapDown,
                  behavior: HitTestBehavior.deferToChild,
                  child: CustomPaint(
                    painter: _connectionPainter = ConnectionPainter(
                      connections: widget.connections,
                      portPositions: widget.portPositions,
                      connectionPreview: widget.connectionPreview,
                      hoveredConnectionId: _hoveredConnection?.id,
                      hoveredLabelId: _hoveredLabelId,
                      pendingConnections: widget.pendingConnections,
                      failedConnections: widget.failedConnections,
                    ),
                    size: _canvasSize,
                  ),
                ),
              ),
            ),

            // Spacer to prevent content from being hidden by FAB
            Positioned(
              right: 0,
              bottom: 0,
              width: 80,
              height: 80,
              child: Container(), // Invisible spacer
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
        replaceMode: false, // Default to Add mode, will be updated by loadConnectionModes
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
      _finalizingConnection = false; // reset for new gesture
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
      if (_finalizingConnection) return; // already handled elsewhere
      final cubit = context.read<NodeRoutingCubit>();
      final currentState = cubit.state;

      if (currentState is NodeRoutingStateLoaded &&
          currentState.connectionPreview != null) {
        // Snapshot needed data, then clear preview immediately to avoid double-fire
        final preview = currentState.connectionPreview!;
        cubit.clearConnectionPreview();

        if (preview.isValid &&
            preview.hoveredTargetAlgorithmIndex != null &&
            preview.hoveredTargetPortId != null) {
          _finalizingConnection = true;
          await cubit.createConnection(
            sourceAlgorithmIndex: preview.sourceAlgorithmIndex,
            sourcePortId: preview.sourcePortId,
            targetAlgorithmIndex: preview.hoveredTargetAlgorithmIndex!,
            targetPortId: preview.hoveredTargetPortId!,
          );
        }
      }
    }
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


  void _handleGlobalPointerUp(PointerUpEvent event) async {
    final cubit = context.read<NodeRoutingCubit>();
    final currentState = cubit.state;

    if (currentState is NodeRoutingStateLoaded &&
        currentState.connectionPreview != null) {
      if (_finalizingConnection) {
        // Another handler already finalized this gesture
        cubit.clearConnectionPreview();
        return;
      }
      // Convert to canvas coordinates and re-hit-test the final target
      final RenderBox? canvasBox = _canvasKey.currentContext?.findRenderObject() as RenderBox?;
      if (canvasBox != null) {
        final canvasPos = canvasBox.globalToLocal(event.position);
        
        final hoveredAlg = cubit.getAlgorithmAtPosition(canvasPos);
        String? hoveredPort = hoveredAlg != null ? cubit.getPortAtPosition(canvasPos, hoveredAlg) : null;
        
        // Ensure inferred target is an input port; otherwise ignore
        if (hoveredAlg != null && hoveredPort != null) {
          final stateForCheck = cubit.state;
          if (stateForCheck is NodeRoutingStateLoaded) {
            final layout = stateForCheck.portLayouts[hoveredAlg];
            final isInput = layout?.inputPorts.any((p) => (p.id ?? p.name) == hoveredPort) ?? false;
            if (!isInput) {
              hoveredPort = null;
            }
          }
        }

        final hasExplicitTarget =
            currentState.connectionPreview!.hoveredTargetAlgorithmIndex != null &&
            currentState.connectionPreview!.hoveredTargetPortId != null &&
            currentState.connectionPreview!.isValid;

        final canInferTarget = hoveredAlg != null && hoveredPort != null;

        if (hasExplicitTarget || canInferTarget) {
          final targetAlg = hasExplicitTarget
              ? currentState.connectionPreview!.hoveredTargetAlgorithmIndex!
              : hoveredAlg!;
          final targetPort = hasExplicitTarget
              ? currentState.connectionPreview!.hoveredTargetPortId!
              : hoveredPort!;

          _finalizingConnection = true;
          await cubit.createConnection(
            sourceAlgorithmIndex: currentState.connectionPreview!.sourceAlgorithmIndex,
            sourcePortId: currentState.connectionPreview!.sourcePortId,
            targetAlgorithmIndex: targetAlg,
            targetPortId: targetPort,
          );
        }
      }

      // Always clear preview after pointer up
      cubit.clearConnectionPreview();
    }
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
    
    // Check for label hover using painter hit boxes
    String? hoveredLabelId;
    if (_connectionPainter != null) {
      hoveredLabelId = _connectionPainter!.getLabelAtPosition(event.localPosition);
    }
    
    if (hoveredConnection != _hoveredConnection || hoveredLabelId != _hoveredLabelId) {
      setState(() {
        _hoveredConnection = hoveredConnection;
        _hoveredLabelId = hoveredLabelId;
      });
      
      // Update cubit state for label hover
      final cubit = context.read<NodeRoutingCubit>();
      cubit.updateLabelHover(hoveredLabelId);
    }
  }
  
  void _handleConnectionExit() {
    if (_hoveredConnection != null || _hoveredLabelId != null) {
      setState(() {
        _hoveredConnection = null;
        _hoveredLabelId = null;
      });
      
      // Clear label hover state in cubit
      final cubit = context.read<NodeRoutingCubit>();
      cubit.updateLabelHover(null);
    }
  }
  
  void _handleConnectionTapDown(TapDownDetails details) {
    // First check for label click (higher priority)
    String? clickedLabelId;
    if (_connectionPainter != null) {
      clickedLabelId = _connectionPainter!.getLabelAtPosition(details.localPosition);
    }
    
    if (clickedLabelId != null) {
      // Handle label click for mode toggle
      _handleLabelClick(clickedLabelId);
      return;
    }
    
    // Find which connection was clicked (fallback to connection removal)
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
  
  /// Handle label click for mode toggle
  void _handleLabelClick(String labelId) {
    // Parse label ID to determine which connection was clicked
    if (labelId.startsWith('connection_') && labelId.endsWith('_mode')) {
      final connectionId = labelId
        .replaceFirst('connection_', '')
        .replaceFirst('_mode', '');
      
      debugPrint('[RoutingCanvas] Label clicked: $labelId -> connectionId: $connectionId');
      
      // Toggle the mode for this connection
      final cubit = context.read<NodeRoutingCubit>();
      cubit.toggleConnectionMode(connectionId);
    }
  }


  /// Handle delete algorithm action
  void _handleDeleteAlgorithm(int algorithmIndex) {
    final nodeRoutingCubit = context.read<NodeRoutingCubit>();
    nodeRoutingCubit.removeAlgorithm(algorithmIndex);
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
