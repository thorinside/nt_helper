import 'package:flutter/material.dart';
import 'package:nt_helper/models/algorithm_port.dart';
import 'package:nt_helper/models/connection.dart';
import 'package:nt_helper/models/node_position.dart';
import 'package:nt_helper/ui/routing/algorithm_node_widget.dart';
import 'package:nt_helper/ui/routing/connection_painter.dart';
import 'package:nt_helper/ui/widgets/port_widget.dart';

typedef NodePositionCallback = void Function(int algorithmIndex, NodePosition position);
typedef ConnectionCallback = void Function(Connection connection);
typedef PortConnectionCallback = void Function(int algorithmIndex, String portId, PortType type);

class RoutingCanvas extends StatefulWidget {
  final Map<int, NodePosition> nodePositions;
  final Map<int, String> algorithmNames;
  final Map<int, List<AlgorithmPort>> algorithmPorts;
  final List<Connection> connections;
  final Set<String> connectedPorts;
  final NodePositionCallback? onNodePositionChanged;
  final ConnectionCallback? onConnectionCreated;
  final ConnectionCallback? onConnectionRemoved;
  final VoidCallback? onSelectionChanged;

  const RoutingCanvas({
    super.key,
    required this.nodePositions,
    required this.algorithmNames,
    required this.algorithmPorts,
    required this.connections,
    this.connectedPorts = const {},
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
  Connection? _previewConnection;
  Offset? _previewTargetPosition;
  String? _hoveredConnectionId;
  int? _connectionSourceAlgorithmIndex;
  String? _connectionSourcePortId;

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      boundaryMargin: const EdgeInsets.all(200),
      minScale: 0.1,
      maxScale: 3.0,
      child: Container(
        width: _canvasSize,
        height: _canvasSize,
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        child: Stack(
          children: [
            // Grid background
            RepaintBoundary(
              child: CustomPaint(
                painter: _GridPainter(
                  spacing: _gridSpacing,
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                ),
                size: const Size(_canvasSize, _canvasSize),
              ),
            ),

            // Connections layer
            RepaintBoundary(
              child: CustomPaint(
                painter: ConnectionPainter(
                  connections: widget.connections,
                  nodePositions: widget.nodePositions,
                  previewConnection: _previewConnection,
                  previewTargetPosition: _previewTargetPosition,
                  hoveredConnectionId: _hoveredConnectionId,
                ),
                size: const Size(_canvasSize, _canvasSize),
                child: GestureDetector(
                  onPanUpdate: _handleCanvasPanUpdate,
                  onPanEnd: _handleCanvasPanEnd,
                  onTapDown: _handleCanvasTapDown,
                  behavior: HitTestBehavior.translucent,
                ),
              ),
            ),

            // Nodes layer
            ...widget.nodePositions.entries.map((entry) {
              final algorithmIndex = entry.key;
              final position = entry.value;
              final algorithmName = widget.algorithmNames[algorithmIndex] ?? 'Unknown';
              final ports = widget.algorithmPorts[algorithmIndex] ?? [];
              
              final inputPorts = ports.where((p) => !_isOutputPort(p)).toList();
              final outputPorts = ports.where((p) => _isOutputPort(p)).toList();

              return AlgorithmNodeWidget(
                key: ValueKey(algorithmIndex),
                nodePosition: position,
                algorithmName: algorithmName,
                inputPorts: inputPorts,
                outputPorts: outputPorts,
                isSelected: _selectedNodes.contains(algorithmIndex),
                connectedPorts: widget.connectedPorts,
                onPositionChanged: (newPosition) {
                  widget.onNodePositionChanged?.call(algorithmIndex, newPosition);
                },
                onPortConnectionStart: (portId, type) => _handlePortConnectionStart(
                  algorithmIndex, portId, type),
                onPortConnectionEnd: (portId, type) => _handlePortConnectionEnd(
                  algorithmIndex, portId, type),
              );
            }),
          ],
        ),
      ),
    );
  }

  bool _isOutputPort(AlgorithmPort port) {
    // Simple heuristic - in real implementation, check port definition
    return port.name.toLowerCase().contains('out') || 
           port.name.toLowerCase().contains('send');
  }

  void _handlePortConnectionStart(int algorithmIndex, String portId, PortType type) {
    if (type == PortType.output) {
      setState(() {
        _connectionSourceAlgorithmIndex = algorithmIndex;
        _connectionSourcePortId = portId;
        _previewConnection = Connection(
          id: 'preview',
          sourceAlgorithmIndex: algorithmIndex,
          sourcePortId: portId,
          targetAlgorithmIndex: -1,
          targetPortId: '',
          assignedBus: 21, // Temporary
          replaceMode: true,
        );
      });
    }
  }

  void _handlePortConnectionEnd(int algorithmIndex, String portId, PortType type) {
    if (type == PortType.input && 
        _connectionSourceAlgorithmIndex != null && 
        _connectionSourcePortId != null) {
      
      // Create new connection
      final connection = Connection(
        id: '${_connectionSourceAlgorithmIndex}_${_connectionSourcePortId}_${algorithmIndex}_$portId',
        sourceAlgorithmIndex: _connectionSourceAlgorithmIndex!,
        sourcePortId: _connectionSourcePortId!,
        targetAlgorithmIndex: algorithmIndex,
        targetPortId: portId,
        assignedBus: 21, // Will be assigned by auto-routing service
        replaceMode: true,
        isValid: true,
      );

      widget.onConnectionCreated?.call(connection);
    }

    _clearConnectionPreview();
  }

  void _handleCanvasPanUpdate(DragUpdateDetails details) {
    if (_previewConnection != null) {
      setState(() {
        _previewTargetPosition = details.localPosition;
      });
    }
  }

  void _handleCanvasPanEnd(DragEndDetails details) {
    _clearConnectionPreview();
  }

  void _handleCanvasTapDown(TapDownDetails details) {
    // Check if tapping on a connection
    final tappedConnection = _hitTestConnection(details.localPosition);
    if (tappedConnection != null) {
      setState(() {
        _hoveredConnectionId = tappedConnection.id;
      });
      return;
    }

    // Check if tapping on a node
    final tappedNode = _hitTestNode(details.localPosition);
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
      _hoveredConnectionId = null;
    });
    widget.onSelectionChanged?.call();
  }

  void _clearConnectionPreview() {
    setState(() {
      _previewConnection = null;
      _previewTargetPosition = null;
      _connectionSourceAlgorithmIndex = null;
      _connectionSourcePortId = null;
    });
  }

  Connection? _hitTestConnection(Offset position) {
    // Simplified hit testing - in real implementation, use path hit testing
    for (final connection in widget.connections) {
      final sourcePos = widget.nodePositions[connection.sourceAlgorithmIndex];
      final targetPos = widget.nodePositions[connection.targetAlgorithmIndex];
      
      if (sourcePos != null && targetPos != null) {
        final sourcePt = Offset(sourcePos.x + sourcePos.width, sourcePos.y + sourcePos.height / 2);
        final targetPt = Offset(targetPos.x, targetPos.y + targetPos.height / 2);
        
        // Simple distance check to connection line
        final distanceToLine = _distanceToLine(position, sourcePt, targetPt);
        if (distanceToLine < 10.0) {
          return connection;
        }
      }
    }
    return null;
  }

  int? _hitTestNode(Offset position) {
    for (final entry in widget.nodePositions.entries) {
      final rect = Rect.fromLTWH(
        entry.value.x, 
        entry.value.y, 
        entry.value.width, 
        entry.value.height,
      );
      if (rect.contains(position)) {
        return entry.key;
      }
    }
    return null;
  }

  double _distanceToLine(Offset point, Offset lineStart, Offset lineEnd) {
    final line = lineEnd - lineStart;
    final lineLength = line.distance;
    if (lineLength == 0) return (point - lineStart).distance;

    final t = ((point - lineStart).dx * line.dx + (point - lineStart).dy * line.dy) / (lineLength * lineLength);
    final projection = lineStart + line * t.clamp(0.0, 1.0);
    return (point - projection).distance;
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