# Flutter Node Editor Implementation Guide

## CustomPainter for Node-Based Editors

### Basic Canvas Drawing Pattern

```dart
class NodeCanvasPainter extends CustomPainter {
  final List<NodePosition> nodes;
  final List<Connection> connections;
  final Connection? activeConnection; // Currently being dragged
  
  @override
  void paint(Canvas canvas, Size size) {
    // Draw grid background
    _drawGrid(canvas, size);
    
    // Draw connections first (behind nodes)
    for (final connection in connections) {
      _drawConnection(canvas, connection);
    }
    
    // Draw active connection if dragging
    if (activeConnection != null) {
      _drawConnection(canvas, activeConnection!, isDragging: true);
    }
    
    // Nodes drawn last (on top)
    for (final node in nodes) {
      _drawNode(canvas, node);
    }
  }
  
  void _drawConnection(Canvas canvas, Connection connection, {bool isDragging = false}) {
    final paint = Paint()
      ..color = isDragging 
        ? Colors.blue.withOpacity(0.6)
        : (connection.isValid ? Colors.green : Colors.red)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    
    final source = _getPortPosition(connection.sourceAlgorithmIndex, connection.sourcePortId);
    final target = _getPortPosition(connection.targetAlgorithmIndex, connection.targetPortId);
    
    final path = _createBezierPath(source, target);
    canvas.drawPath(path, paint);
    
    // Draw arrow head
    if (!isDragging) {
      _drawArrowHead(canvas, target, path);
    }
  }
  
  Path _createBezierPath(Offset start, Offset end) {
    final path = Path();
    path.moveTo(start.dx, start.dy);
    
    // Calculate control points for smooth curve
    final dx = end.dx - start.dx;
    final cp1 = Offset(start.dx + dx * 0.5, start.dy);
    final cp2 = Offset(end.dx - dx * 0.5, end.dy);
    
    path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, end.dx, end.dy);
    return path;
  }
  
  @override
  bool shouldRepaint(NodeCanvasPainter oldDelegate) {
    return nodes != oldDelegate.nodes || 
           connections != oldDelegate.connections ||
           activeConnection != oldDelegate.activeConnection;
  }
}
```

### Hit Testing for Interactive Elements

```dart
class NodeHitTester {
  static const double portRadius = 8.0;
  static const double hitPadding = 4.0;
  
  // Find which port is at the given position
  PortHit? hitTestPort(Offset position, List<NodePosition> nodes) {
    for (final node in nodes) {
      final ports = getPortsForNode(node);
      
      for (final port in ports) {
        final portPos = getPortPosition(node, port);
        final distance = (position - portPos).distance;
        
        if (distance <= portRadius + hitPadding) {
          return PortHit(
            nodeIndex: node.algorithmIndex,
            portId: port.id,
            position: portPos,
            isOutput: port.isOutput,
          );
        }
      }
    }
    return null;
  }
  
  // Find which node contains the position
  NodeHit? hitTestNode(Offset position, List<NodePosition> nodes) {
    // Test in reverse order (top nodes first)
    for (final node in nodes.reversed) {
      final rect = Rect.fromLTWH(node.x, node.y, node.width, node.height);
      if (rect.contains(position)) {
        return NodeHit(
          nodeIndex: node.algorithmIndex,
          localPosition: position - Offset(node.x, node.y),
        );
      }
    }
    return null;
  }
  
  // Test if position is near a connection line
  ConnectionHit? hitTestConnection(Offset position, List<Connection> connections) {
    for (final connection in connections) {
      final path = _getConnectionPath(connection);
      
      // Sample points along the path
      final metrics = path.computeMetrics();
      for (final metric in metrics) {
        final length = metric.length;
        
        // Check every 10 pixels along the path
        for (double t = 0; t <= length; t += 10) {
          final point = metric.getTangentForOffset(t)?.position;
          if (point != null) {
            final distance = (position - point).distance;
            if (distance <= 5.0) {
              return ConnectionHit(connection: connection);
            }
          }
        }
      }
    }
    return null;
  }
}
```

### Gesture Handling for Node Editor

```dart
class NodeEditorGestureHandler extends StatefulWidget {
  @override
  State<NodeEditorGestureHandler> createState() => _NodeEditorGestureHandlerState();
}

class _NodeEditorGestureHandlerState extends State<NodeEditorGestureHandler> {
  // Gesture state
  Offset? _dragStart;
  PortHit? _connectionStart;
  NodeHit? _draggedNode;
  Set<int> _selectedNodes = {};
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      
      onTapDown: (details) {
        final localPos = details.localPosition;
        
        // Check what was tapped
        final portHit = _hitTester.hitTestPort(localPos, _nodes);
        if (portHit != null && portHit.isOutput) {
          // Start connection dragging from output port
          setState(() {
            _connectionStart = portHit;
            _dragStart = localPos;
          });
          return;
        }
        
        final nodeHit = _hitTester.hitTestNode(localPos, _nodes);
        if (nodeHit != null) {
          // Select/deselect node
          setState(() {
            if (details.kind == PointerDeviceKind.mouse && 
                RawKeyboard.instance.keysPressed.contains(LogicalKeyboardKey.controlLeft)) {
              // Multi-select with Ctrl
              if (_selectedNodes.contains(nodeHit.nodeIndex)) {
                _selectedNodes.remove(nodeHit.nodeIndex);
              } else {
                _selectedNodes.add(nodeHit.nodeIndex);
              }
            } else {
              // Single select
              _selectedNodes = {nodeHit.nodeIndex};
              _draggedNode = nodeHit;
              _dragStart = localPos;
            }
          });
        } else {
          // Clicked empty space - deselect all
          setState(() {
            _selectedNodes.clear();
          });
        }
      },
      
      onPanUpdate: (details) {
        if (_connectionStart != null) {
          // Update connection preview
          setState(() {
            _activeConnection = Connection(
              sourceAlgorithmIndex: _connectionStart!.nodeIndex,
              sourcePortId: _connectionStart!.portId,
              targetPosition: details.localPosition, // Temporary position
            );
          });
        } else if (_draggedNode != null) {
          // Move selected nodes
          final delta = details.localPosition - _dragStart!;
          setState(() {
            for (final nodeIndex in _selectedNodes) {
              final node = _nodes.firstWhere((n) => n.algorithmIndex == nodeIndex);
              node.x += delta.dx;
              node.y += delta.dy;
            }
            _dragStart = details.localPosition;
          });
        }
      },
      
      onPanEnd: (details) {
        if (_connectionStart != null) {
          // Try to complete connection
          final endPos = details.localPosition;
          final targetPort = _hitTester.hitTestPort(endPos, _nodes);
          
          if (targetPort != null && !targetPort.isOutput) {
            // Valid connection - create it
            _createConnection(_connectionStart!, targetPort);
          }
          
          setState(() {
            _connectionStart = null;
            _activeConnection = null;
          });
        }
        
        setState(() {
          _draggedNode = null;
          _dragStart = null;
        });
      },
      
      child: CustomPaint(
        painter: NodeCanvasPainter(
          nodes: _nodes,
          connections: _connections,
          activeConnection: _activeConnection,
          selectedNodes: _selectedNodes,
        ),
        size: Size.infinite,
      ),
    );
  }
}
```

### Connection Routing Algorithms

```dart
class ConnectionRouter {
  // Manhattan routing (right angles only)
  static Path createManhattanPath(Offset start, Offset end) {
    final path = Path();
    path.moveTo(start.dx, start.dy);
    
    final midX = start.dx + (end.dx - start.dx) / 2;
    
    path.lineTo(midX, start.dy);
    path.lineTo(midX, end.dy);
    path.lineTo(end.dx, end.dy);
    
    return path;
  }
  
  // Smart bezier with obstacle avoidance
  static Path createSmartBezierPath(Offset start, Offset end, List<Rect> obstacles) {
    final directPath = _createDirectBezier(start, end);
    
    // Check if direct path intersects any obstacles
    if (!_pathIntersectsObstacles(directPath, obstacles)) {
      return directPath;
    }
    
    // Find waypoints around obstacles
    final waypoints = _findWaypoints(start, end, obstacles);
    return _createPathThroughWaypoints(start, end, waypoints);
  }
  
  static Path _createDirectBezier(Offset start, Offset end) {
    final path = Path();
    path.moveTo(start.dx, start.dy);
    
    // Horizontal emphasis for signal flow
    final dx = (end.dx - start.dx).abs();
    final cp1 = Offset(start.dx + dx * 0.6, start.dy);
    final cp2 = Offset(end.dx - dx * 0.6, end.dy);
    
    path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, end.dx, end.dy);
    return path;
  }
}
```

### Performance Optimization

```dart
class OptimizedNodeCanvas extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      boundaryMargin: EdgeInsets.all(double.infinity),
      minScale: 0.1,
      maxScale: 3.0,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              // Background grid - only repaints when viewport changes
              RepaintBoundary(
                child: CustomPaint(
                  painter: GridPainter(),
                  size: Size(5000, 5000), // Large canvas
                ),
              ),
              
              // Connections layer - repaints when connections change
              RepaintBoundary(
                child: CustomPaint(
                  painter: ConnectionsPainter(connections: connections),
                  size: Size(5000, 5000),
                ),
              ),
              
              // Nodes as widgets - better performance for complex nodes
              ...nodes.map((node) => Positioned(
                left: node.x,
                top: node.y,
                child: RepaintBoundary(
                  child: AlgorithmNodeWidget(
                    node: node,
                    isSelected: selectedNodes.contains(node.algorithmIndex),
                    onDragUpdate: (delta) => _handleNodeDrag(node, delta),
                  ),
                ),
              )),
            ],
          );
        },
      ),
    );
  }
}
```

### Node Widget Implementation

```dart
class AlgorithmNodeWidget extends StatelessWidget {
  final NodePosition node;
  final bool isSelected;
  
  @override
  Widget build(BuildContext context) {
    return Container(
      width: node.width,
      height: node.height,
      decoration: BoxDecoration(
        color: Colors.grey[800],
        border: Border.all(
          color: isSelected ? Colors.blue : Colors.grey,
          width: isSelected ? 2.0 : 1.0,
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: Offset(2, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Text(
              node.algorithmName,
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          
          // Ports
          Expanded(
            child: Row(
              children: [
                // Input ports
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: inputPorts.map((port) => PortWidget(
                    port: port,
                    isInput: true,
                    onConnectionStart: () => _startConnection(port),
                  )).toList(),
                ),
                
                Spacer(),
                
                // Output ports  
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: outputPorts.map((port) => PortWidget(
                    port: port,
                    isInput: false,
                    onConnectionStart: () => _startConnection(port),
                  )).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PortWidget extends StatelessWidget {
  final AlgorithmPort port;
  final bool isInput;
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (_) => onConnectionStart?.call(),
      child: Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _getPortColor(port),
          border: Border.all(color: Colors.white, width: 1),
        ),
        child: Center(
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.5),
            ),
          ),
        ),
      ),
    );
  }
  
  Color _getPortColor(AlgorithmPort port) {
    // Color code by signal type
    if (port.name.contains('Audio')) return Colors.blue;
    if (port.name.contains('CV')) return Colors.orange;
    if (port.name.contains('Gate')) return Colors.green;
    return Colors.grey;
  }
}
```

## Best Practices

1. **Use RepaintBoundary** to isolate redraw regions
2. **Implement shouldRepaint** correctly in CustomPainter
3. **Use InteractiveViewer** for pan/zoom instead of custom implementation
4. **Cache complex paths** if they don't change frequently
5. **Use widgets for nodes** instead of painting them for better interaction
6. **Implement viewport culling** - only draw visible elements
7. **Debounce position updates** during dragging to reduce rebuilds
8. **Use CustomClipper** for complex node shapes