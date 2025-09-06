import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nt_helper/cubit/routing_editor_cubit.dart';
import 'package:nt_helper/cubit/routing_editor_state.dart';
import 'package:nt_helper/core/routing/models/connection.dart';
import 'package:nt_helper/services/interactive_connection_manager.dart';
import 'package:nt_helper/services/connection_bus_manager.dart';
import 'package:nt_helper/ui/widgets/routing/connection_drag_handler.dart';
import 'package:nt_helper/ui/widgets/routing/connection_deletion_handler.dart';
import 'package:nt_helper/ui/widgets/routing/algorithm_node_widget.dart';
import 'package:nt_helper/ui/widgets/routing/physical_input_node.dart';
import 'package:nt_helper/ui/widgets/routing/physical_output_node.dart';

/// Interactive routing canvas that integrates all connection editing features
class InteractiveRoutingCanvas extends StatefulWidget {
  final Size canvasSize;
  final bool showPhysicalPorts;
  final bool showBusLabels;
  final Function(String nodeId)? onNodeSelected;
  final Function(String sourcePortId, String targetPortId)? onConnectionCreated;
  final Function(String connectionId)? onConnectionRemoved;

  const InteractiveRoutingCanvas({
    super.key,
    this.canvasSize = const Size(1200, 800),
    this.showPhysicalPorts = true,
    this.showBusLabels = true,
    this.onNodeSelected,
    this.onConnectionCreated,
    this.onConnectionRemoved,
  });

  @override
  State<InteractiveRoutingCanvas> createState() => _InteractiveRoutingCanvasState();
}

class _InteractiveRoutingCanvasState extends State<InteractiveRoutingCanvas> {
  late InteractiveConnectionManager _connectionManager;
  final TransformationController _transformationController = TransformationController();
  final Map<String, Offset> _nodePositions = {};
  final Map<String, GlobalKey> _nodeKeys = {};

  @override
  void initState() {
    super.initState();
    _connectionManager = InteractiveConnectionManager();
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RoutingEditorCubit, RoutingEditorState>(
      builder: (context, state) {
        if (state is! RoutingEditorStateLoaded) {
          return _buildLoadingState();
        }

        return Container(
          width: widget.canvasSize.width,
          height: widget.canvasSize.height,
          decoration: BoxDecoration(
            color: Colors.grey[50],
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: InteractiveViewer(
              transformationController: _transformationController,
              constrained: false,
              minScale: 0.5,
              maxScale: 2.0,
              child: ConnectionDragHandler(
                connectionManager: _connectionManager,
                child: _buildRoutingCanvas(state),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return Container(
      width: widget.canvasSize.width,
      height: widget.canvasSize.height,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading routing data...'),
          ],
        ),
      ),
    );
  }

  Widget _buildRoutingCanvas(RoutingEditorStateLoaded state) {
    _updateNodePositions(state);
    
    return SizedBox(
      width: widget.canvasSize.width,
      height: widget.canvasSize.height,
      child: Stack(
        children: [
          // Background grid
          CustomPaint(
            size: widget.canvasSize,
            painter: GridPainter(),
          ),
          
          // Connections layer
          ...state.connections.map((connection) => _buildConnection(connection, state)),
          
          // Physical input nodes
          if (widget.showPhysicalPorts)
            ...state.physicalInputs.asMap().entries.map((entry) {
              final index = entry.key;
              final port = entry.value;
              return _buildPhysicalInputNode(port, index, state);
            }),
          
          // Physical output nodes
          if (widget.showPhysicalPorts)
            ...state.physicalOutputs.asMap().entries.map((entry) {
              final index = entry.key;
              final port = entry.value;
              return _buildPhysicalOutputNode(port, index, state);
            }),
          
          // Algorithm nodes
          ...state.algorithms.asMap().entries.map((entry) {
            final index = entry.key;
            final algorithm = entry.value;
            return _buildAlgorithmNode(algorithm, index, state);
          }),
          
          // Optimistic changes indicator
          if (state.hasOptimisticChanges) _buildOptimisticIndicator(state),
          
          // Bus utilization display
          if (widget.showBusLabels) _buildBusUtilization(state),
        ],
      ),
    );
  }

  Widget _buildConnection(Connection connection, RoutingEditorStateLoaded state) {
    final sourcePosition = _getPortPosition(connection.sourcePortId, state);
    final targetPosition = _getPortPosition(connection.destinationPortId, state);

    if (sourcePosition == null || targetPosition == null) {
      return const SizedBox.shrink();
    }

    return ConnectionDeletionHandler(
      connection: connection,
      startPosition: sourcePosition,
      endPosition: targetPosition,
      child: const SizedBox.shrink(),
    );
  }

  Widget _buildPhysicalInputNode(Port port, int index, RoutingEditorStateLoaded state) {
    final position = Offset(50, 100 + (index * 60));
    _nodePositions[port.id] = position;
    
    final key = GlobalKey();
    _nodeKeys[port.id] = key;
    
    return Positioned(
      left: position.dx,
      top: position.dy,
      child: PhysicalInputNode(
        key: key,
        position: position,
        onPortTapped: (port) => widget.onNodeSelected?.call(port.id),
      ),
    );
  }

  Widget _buildPhysicalOutputNode(Port port, int index, RoutingEditorStateLoaded state) {
    final position = Offset(widget.canvasSize.width - 150, 100 + (index * 60));
    _nodePositions[port.id] = position;
    
    final key = GlobalKey();
    _nodeKeys[port.id] = key;
    
    return Positioned(
      left: position.dx,
      top: position.dy,
      child: PhysicalOutputNode(
        key: key,
        position: position,
        onPortTapped: (port) => widget.onNodeSelected?.call(port.id),
      ),
    );
  }

  Widget _buildAlgorithmNode(RoutingAlgorithm algorithm, int index, RoutingEditorStateLoaded state) {
    final position = Offset(
      200 + (index % 3) * 250,
      150 + (index ~/ 3) * 200,
    );
    _nodePositions[algorithm.id] = position;
    
    final key = GlobalKey();
    _nodeKeys[algorithm.id] = key;
    
    return Positioned(
      left: position.dx,
      top: position.dy,
      child: AlgorithmNodeWidget(
        key: key,
        algorithmName: algorithm.algorithm.name,
        position: position,
        slotNumber: algorithm.index,
        inputLabels: algorithm.inputPorts.map((p) => p.name).toList(),
        outputLabels: algorithm.outputPorts.map((p) => p.name).toList(),
        inputPortIds: algorithm.inputPorts.map((p) => p.id).toList(),
        outputPortIds: algorithm.outputPorts.map((p) => p.id).toList(),
        onTap: () => widget.onNodeSelected?.call(algorithm.id),
      ),
    );
  }

  Widget _buildOptimisticIndicator(RoutingEditorStateLoaded state) {
    return Positioned(
      top: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.orange[100],
          border: Border.all(color: Colors.orange[300]!),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.sync,
              size: 16,
              color: Colors.orange,
            ),
            const SizedBox(width: 8),
            Text(
              'Syncing ${state.pendingOperations.length} changes...',
              style: TextStyle(
                fontSize: 12,
                color: Colors.orange[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBusUtilization(RoutingEditorStateLoaded state) {
    final utilization = ConnectionBusManager.getBusUtilization(state.connections);
    
    return Positioned(
      bottom: 20,
      left: 20,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Bus Utilization',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Input: ${utilization['inputBusesUsed']}/${utilization['inputBusesTotal']}',
              style: const TextStyle(fontSize: 10),
            ),
            Text(
              'Output: ${utilization['outputBusesUsed']}/${utilization['outputBusesTotal']}',
              style: const TextStyle(fontSize: 10),
            ),
            Text(
              'Aux: ${utilization['auxBusesUsed']}/${utilization['auxBusesTotal']}',
              style: const TextStyle(fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  void _updateNodePositions(RoutingEditorStateLoaded state) {
    // Register port bounds for hit testing
    _connectionManager.clearPortBounds();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final entry in _nodeKeys.entries) {
        final portId = entry.key;
        final key = entry.value;
        final renderBox = key.currentContext?.findRenderObject() as RenderBox?;
        
        if (renderBox != null) {
          final position = renderBox.localToGlobal(Offset.zero);
          final size = renderBox.size;
          final bounds = Rect.fromLTWH(position.dx, position.dy, size.width, size.height);
          _connectionManager.registerPortBounds(portId, bounds);
        }
      }
    });
  }

  Offset? _getPortPosition(String portId, RoutingEditorStateLoaded state) {
    // This would need to be enhanced with actual port positioning logic
    return _nodePositions[portId];
  }

}

/// Custom painter for drawing the background grid
class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[200]!
      ..strokeWidth = 0.5;

    const gridSpacing = 50.0;

    // Draw vertical lines
    for (double x = 0; x < size.width; x += gridSpacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Draw horizontal lines
    for (double y = 0; y < size.height; y += gridSpacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}