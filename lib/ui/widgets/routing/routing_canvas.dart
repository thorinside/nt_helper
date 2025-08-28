import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:nt_helper/cubit/routing_editor_cubit.dart';
import 'package:nt_helper/core/routing/models/algorithm_routing_metadata.dart';
import 'package:nt_helper/core/routing/models/port.dart' as core_port;
import 'package:nt_helper/core/routing/routing_factory.dart';
import 'package:nt_helper/ui/widgets/routing/connection_line.dart' as connection_widget;
import 'package:nt_helper/ui/widgets/routing/routing_algorithm_node.dart';

/// A canvas widget that visualizes the algorithm routing system.
/// 
/// This widget orchestrates AlgorithmNode and ConnectionLine widgets,
/// listening to the RoutingEditorCubit for state changes and updating
/// the UI reactively. The layout adapts to changes in the routing state.
class RoutingCanvas extends StatefulWidget {
  /// The routing factory for creating algorithm routing instances
  final RoutingFactory? routingFactory;
  
  /// The size of the canvas
  final Size canvasSize;
  
  /// Whether to show physical input/output ports
  final bool showPhysicalPorts;
  
  /// Called when a node is selected
  final Function(String nodeId)? onNodeSelected;
  
  /// Called when a connection is created
  final Function(String sourcePortId, String targetPortId)? onConnectionCreated;
  
  /// Called when a connection is removed  
  final Function(String connectionId)? onConnectionRemoved;

  const RoutingCanvas({
    super.key,
    this.routingFactory,
    this.canvasSize = const Size(1200, 800),
    this.showPhysicalPorts = true,
    this.onNodeSelected,
    this.onConnectionCreated,
    this.onConnectionRemoved,
  });

  @override
  State<RoutingCanvas> createState() => _RoutingCanvasState();
}

class _RoutingCanvasState extends State<RoutingCanvas> {
  final Map<String, Offset> _nodePositions = {};
  final Set<String> _selectedNodes = {};
  String? _selectedConnectionId;
  
  // Connection creation state
  String? _connectionSourcePortId;
  Offset? _dragPosition;
  bool _isDraggingConnection = false;
  
  late RoutingFactory _routingFactory;

  @override
  void initState() {
    super.initState();
    _routingFactory = widget.routingFactory ?? GetIt.instance<RoutingFactory>();
    _initializeNodePositions();
  }

  /// Initialize default positions for nodes in a grid layout
  void _initializeNodePositions() {
    // Position physical inputs on the left
    const double leftMargin = 50.0;
    const double inputSpacing = 60.0;
    for (int i = 0; i < 12; i++) {
      _nodePositions['hw_in_${i + 1}'] = Offset(
        leftMargin,
        100 + (i * inputSpacing),
      );
    }
    
    // Position physical outputs on the right
    const double rightMargin = 50.0;
    const double outputSpacing = 80.0;
    for (int i = 0; i < 8; i++) {
      _nodePositions['hw_out_${i + 1}'] = Offset(
        widget.canvasSize.width - rightMargin - 120,
        150 + (i * outputSpacing),
      );
    }
    
    // Position algorithm slots in the middle (4 rows of 2 columns)
    const double algorithmStartX = 300.0;
    const double algorithmSpacing = 250.0;
    const double algorithmRowSpacing = 180.0;
    for (int i = 0; i < 8; i++) {
      final column = i % 2;
      final row = i ~/ 2;
      _nodePositions['algorithm_$i'] = Offset(
        algorithmStartX + (column * algorithmSpacing),
        150 + (row * algorithmRowSpacing),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RoutingEditorCubit, RoutingEditorState>(
      builder: (context, state) {
        return Container(
          width: widget.canvasSize.width,
          height: widget.canvasSize.height,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border.all(
              color: Theme.of(context).dividerColor,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: _buildCanvasContent(context, state),
          ),
        );
      },
    );
  }

  Widget _buildCanvasContent(BuildContext context, RoutingEditorState state) {
    return state.when(
      initial: () => _buildEmptyState(context, 'Initializing routing editor...'),
      disconnected: () => _buildEmptyState(context, 'Hardware disconnected'),
      connecting: () => _buildEmptyState(context, 'Connecting to hardware...'),
      refreshing: () => _buildLoadingOverlay(context),
      loaded: (physicalInputs, physicalOutputs, algorithms, connections) =>
          _buildLoadedCanvas(context, physicalInputs, physicalOutputs, algorithms, connections),
      error: (message) => _buildErrorState(context, message),
    );
  }

  Widget _buildEmptyState(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.device_hub,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingOverlay(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Refreshing routing data...'),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Error',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadedCanvas(
    BuildContext context,
    List<Port> physicalInputs,
    List<Port> physicalOutputs,
    List<RoutingAlgorithm> algorithms,
    List<Connection> connections,
  ) {
    return GestureDetector(
      onTapDown: _handleCanvasTap,
      onPanUpdate: _handleCanvasDrag,
      onPanEnd: _handleCanvasDragEnd,
      child: CustomPaint(
        painter: _CanvasGridPainter(
          gridColor: Theme.of(context).dividerColor.withValues(alpha: 0.3),
          gridSize: 25.0,
        ),
        child: Stack(
          children: [
            // Physical input ports
            if (widget.showPhysicalPorts)
              ..._buildPhysicalInputNodes(physicalInputs),
            
            // Physical output ports
            if (widget.showPhysicalPorts)
              ..._buildPhysicalOutputNodes(physicalOutputs),
            
            // Algorithm nodes
            ..._buildAlgorithmNodes(algorithms),
            
            // Connection lines
            ..._buildConnectionLines(connections),
            
            // Temporary connection line while dragging
            if (_isDraggingConnection && _dragPosition != null)
              _buildTemporaryConnection(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildPhysicalInputNodes(List<Port> physicalInputs) {
    return physicalInputs.map((port) {
      final position = _nodePositions[port.id] ?? Offset.zero;
      return Positioned(
        left: position.dx,
        top: position.dy,
        child: _buildPhysicalPortNode(port, isInput: true),
      );
    }).toList();
  }

  List<Widget> _buildPhysicalOutputNodes(List<Port> physicalOutputs) {
    return physicalOutputs.map((port) {
      final position = _nodePositions[port.id] ?? Offset.zero;
      return Positioned(
        left: position.dx,
        top: position.dy,
        child: _buildPhysicalPortNode(port, isInput: false),
      );
    }).toList();
  }

  Widget _buildPhysicalPortNode(Port port, {required bool isInput}) {
    final isSelected = _selectedNodes.contains(port.id);
    
    return GestureDetector(
      onTap: () => _handleNodeTap(port.id),
      child: Container(
        width: 120,
        height: 40,
        decoration: BoxDecoration(
          color: _getPortTypeColor(port.type).withValues(alpha: 0.2),
          border: Border.all(
            color: isSelected 
                ? Theme.of(context).primaryColor 
                : _getPortTypeColor(port.type),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            port.name,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  List<Widget> _buildAlgorithmNodes(List<RoutingAlgorithm> algorithms) {
    return algorithms.map((algorithm) {
      final nodeId = 'algorithm_${algorithm.index}';
      final position = _nodePositions[nodeId] ?? Offset.zero;
      final isSelected = _selectedNodes.contains(nodeId);
      
      // Convert to AlgorithmRoutingMetadata for the RoutingAlgorithmNode
      final metadata = AlgorithmRoutingMetadata(
        algorithmGuid: algorithm.algorithm.name, // Using name as GUID for now
        algorithmName: algorithm.algorithm.name,
        routingType: RoutingType.polyphonic, // Default - this would need to be determined properly
        voiceCount: 4, // Default
        channelCount: 1,
      );
      
      return Positioned(
        left: position.dx,
        top: position.dy,
        child: RoutingAlgorithmNode(
          metadata: metadata,
          routingFactory: _routingFactory,
          position: position,
          isSelected: isSelected,
          onNodeTapped: () => _handleNodeTap(nodeId),
          onPortTapped: (port) => _handlePortTap(port),
        ),
      );
    }).toList();
  }

  List<Widget> _buildConnectionLines(List<Connection> connections) {
    return connections.map((connection) {
      final sourcePosition = _getPortPosition(connection.sourcePortId);
      final targetPosition = _getPortPosition(connection.targetPortId);
      
      if (sourcePosition == null || targetPosition == null) {
        return const SizedBox.shrink();
      }
      
      // Create a mock connection for the ConnectionLine widget
      // This is a simplified version - in a real implementation, we'd need
      // to properly resolve the port information
      final mockConnection = connection_widget.Connection(
        sourcePort: core_port.Port(
          id: connection.sourcePortId,
          name: 'Source',
          type: core_port.PortType.audio,
          direction: core_port.PortDirection.output,
        ),
        destinationPort: core_port.Port(
          id: connection.targetPortId,
          name: 'Target',
          type: core_port.PortType.audio,
          direction: core_port.PortDirection.input,
        ),
        sourcePosition: sourcePosition,
        destinationPosition: targetPosition,
        isSelected: _selectedConnectionId == '${connection.sourcePortId}->${connection.targetPortId}',
      );
      
      return connection_widget.ConnectionLine(
        connection: mockConnection,
        onTapped: () => _handleConnectionTap('${connection.sourcePortId}->${connection.targetPortId}'),
      );
    }).toList();
  }

  Widget _buildTemporaryConnection() {
    if (_connectionSourcePortId == null || _dragPosition == null) {
      return const SizedBox.shrink();
    }
    
    final sourcePosition = _getPortPosition(_connectionSourcePortId!);
    if (sourcePosition == null) return const SizedBox.shrink();
    
    final mockConnection = connection_widget.Connection(
      sourcePort: core_port.Port(
        id: _connectionSourcePortId!,
        name: 'Source',
        type: core_port.PortType.audio,
        direction: core_port.PortDirection.output,
      ),
      destinationPort: core_port.Port(
        id: 'temp',
        name: 'Target',
        type: core_port.PortType.audio,
        direction: core_port.PortDirection.input,
      ),
      sourcePosition: sourcePosition,
      destinationPosition: _dragPosition!,
      isHighlighted: true,
    );
    
    return connection_widget.ConnectionLine(
      connection: mockConnection,
      strokeWidth: 1.5,
    );
  }

  void _handleCanvasTap(TapDownDetails details) {
    // Clear selections when tapping on empty canvas
    setState(() {
      _selectedNodes.clear();
      _selectedConnectionId = null;
    });
  }

  void _handleCanvasDrag(DragUpdateDetails details) {
    if (_isDraggingConnection) {
      setState(() {
        _dragPosition = details.localPosition;
      });
    }
  }

  void _handleCanvasDragEnd(DragEndDetails details) {
    if (_isDraggingConnection) {
      setState(() {
        _isDraggingConnection = false;
        _connectionSourcePortId = null;
        _dragPosition = null;
      });
    }
  }

  void _handleNodeTap(String nodeId) {
    setState(() {
      if (_selectedNodes.contains(nodeId)) {
        _selectedNodes.remove(nodeId);
      } else {
        _selectedNodes.clear();
        _selectedNodes.add(nodeId);
      }
      _selectedConnectionId = null;
    });
    
    widget.onNodeSelected?.call(nodeId);
  }

  void _handlePortTap(core_port.Port port) {
    if (_isDraggingConnection) {
      // Complete connection
      if (_connectionSourcePortId != null && _connectionSourcePortId != port.id) {
        widget.onConnectionCreated?.call(_connectionSourcePortId!, port.id);
      }
      setState(() {
        _isDraggingConnection = false;
        _connectionSourcePortId = null;
        _dragPosition = null;
      });
    } else {
      // Start connection
      setState(() {
        _isDraggingConnection = true;
        _connectionSourcePortId = port.id;
        _dragPosition = _getPortPosition(port.id);
      });
    }
  }

  void _handleConnectionTap(String connectionId) {
    setState(() {
      _selectedNodes.clear();
      _selectedConnectionId = _selectedConnectionId == connectionId ? null : connectionId;
    });
  }

  /// Get the visual position of a port on the canvas
  Offset? _getPortPosition(String portId) {
    // This is a simplified implementation
    // In a real implementation, we'd need to calculate exact port positions
    // based on the node position and port layout
    final nodePosition = _nodePositions[portId];
    if (nodePosition != null) {
      return Offset(nodePosition.dx + 60, nodePosition.dy + 20); // Center of node
    }
    
    // Try to find it as an algorithm port
    for (int i = 0; i < 8; i++) {
      final algorithmNodeId = 'algorithm_$i';
      final algorithmPosition = _nodePositions[algorithmNodeId];
      if (algorithmPosition != null && portId.startsWith('alg_${i}_')) {
        // Estimate port position within the algorithm node
        return Offset(algorithmPosition.dx + 80, algorithmPosition.dy + 50);
      }
    }
    
    return null;
  }

  Color _getPortTypeColor(PortType portType) {
    switch (portType) {
      case PortType.audio:
        return Colors.blue;
      case PortType.cv:
        return Colors.orange;
      case PortType.gate:
        return Colors.red;
      case PortType.trigger:
        return Colors.purple;
    }
  }
}

/// Custom painter for drawing the canvas grid background
class _CanvasGridPainter extends CustomPainter {
  final Color gridColor;
  final double gridSize;

  const _CanvasGridPainter({
    required this.gridColor,
    this.gridSize = 20.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    // Draw vertical lines
    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    // Draw horizontal lines
    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CanvasGridPainter oldDelegate) {
    return oldDelegate.gridColor != gridColor || 
           oldDelegate.gridSize != gridSize;
  }
}

