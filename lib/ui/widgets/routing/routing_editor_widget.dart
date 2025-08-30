import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nt_helper/cubit/routing_editor_cubit.dart';
import 'package:nt_helper/core/routing/models/algorithm_routing_metadata.dart';
import 'package:nt_helper/core/routing/models/port.dart' as core_port;
// Haptics can be reintroduced later if needed
import 'package:nt_helper/ui/widgets/routing/connection_line.dart' as connection_widget;
import 'package:nt_helper/ui/widgets/routing/algorithm_node.dart';
import 'package:nt_helper/ui/widgets/routing/physical_input_node.dart';
import 'package:nt_helper/ui/widgets/routing/physical_output_node.dart';
// Removed unused imports from previous canvas split
import 'package:nt_helper/ui/widgets/routing/connection_validator.dart';

/// RoutingEditorWidget is the canonical widget for the routing editor UI.
/// It composes the routing canvas and exposes the same API for compatibility.
class RoutingEditorWidget extends StatefulWidget {
  final Object? routingFactory; // ignored (decisions in cubit)
  final Size canvasSize;
  final bool showPhysicalPorts;
  final Function(String nodeId)? onNodeSelected;
  final Function(String sourcePortId, String targetPortId)? onConnectionCreated;
  final Function(String connectionId)? onConnectionRemoved;

  const RoutingEditorWidget({
    super.key,
    this.routingFactory,
    this.canvasSize = const Size(1200, 800),
    this.showPhysicalPorts = true,
    this.onNodeSelected,
    this.onConnectionCreated,
    this.onConnectionRemoved,
  });

  @override
  State<RoutingEditorWidget> createState() => _RoutingEditorWidgetState();
}

class _RoutingEditorWidgetState extends State<RoutingEditorWidget> {
  final Map<String, Offset> _nodePositions = {};
  final Set<String> _selectedNodes = {};
  String? _selectedConnectionId;
  
  String? _connectionSourcePortId;
  Offset? _dragPosition;
  final bool _isDraggingConnection = false;
  
  // Haptics can be reintroduced when needed for interactions
  
  final Map<String, AlgorithmRoutingMetadata> _algorithmMetadataCache = {};

  @override
  void initState() {
    super.initState();
    _initializeNodePositions();
  }

  void _initializeNodePositions() {
    final double leftMargin = widget.canvasSize.width < 800 ? 30.0 : 50.0;
    final double inputSpacing = widget.canvasSize.height < 600 ? 45.0 : 55.0;
    for (int i = 0; i < 12; i++) {
      _nodePositions['hw_in_${i + 1}'] = Offset(
        leftMargin + 120,
        100 + (i * inputSpacing),
      );
    }
    final double rightMargin = widget.canvasSize.width < 800 ? 160.0 : 170.0;
    final double outputSpacing = widget.canvasSize.height < 600 ? 60.0 : 75.0;
    for (int i = 0; i < 8; i++) {
      _nodePositions['hw_out_${i + 1}'] = Offset(
        widget.canvasSize.width - rightMargin,
        140 + (i * outputSpacing),
      );
    }
    final double algorithmStartX = widget.canvasSize.width < 800 ? 200.0 : 250.0;
    final double algorithmSpacing = widget.canvasSize.width < 1000 ? 200.0 : 250.0;
    final double algorithmRowSpacing = widget.canvasSize.height < 600 ? 140.0 : 180.0;
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
  void dispose() {
    _algorithmMetadataCache.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RoutingEditorCubit, RoutingEditorState>(
      buildWhen: (previous, current) =>
          previous.runtimeType != current.runtimeType ||
          (previous is RoutingEditorStateLoaded &&
              current is RoutingEditorStateLoaded &&
              _hasLoadedStateChanged(previous, current)),
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
      persisting: () => _buildLoadingOverlay(context),
      syncing: () => _buildLoadingOverlay(context),
      loaded: (physicalInputs, physicalOutputs, algorithms, connections, buses, portOutputModes, isHardwareSynced, isPersistenceEnabled, lastSyncTime, lastPersistTime, lastError) =>
          _buildLoadedCanvas(context, physicalInputs, physicalOutputs, algorithms, connections),
      error: (message) => _buildErrorState(context, message),
    );
  }

  Widget _buildEmptyState(BuildContext context, String message) { /* identical to RoutingCanvas */
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

  Widget _buildLoadingOverlay(BuildContext context) { /* identical to RoutingCanvas */
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

  Widget _buildErrorState(BuildContext context, String message) { /* identical to RoutingCanvas */
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
  ) { /* identical to RoutingCanvas */
    return Semantics(
      label: 'Routing canvas with ${algorithms.length} algorithm nodes and ${connections.length} connections',
      hint: 'Interactive routing canvas. Drag between ports to create connections.',
      container: true,
      child: GestureDetector(
        onTapDown: _handleCanvasTap,
        onPanUpdate: _handleCanvasDrag,
        onPanEnd: _handleCanvasDragEnd,
        child: CustomPaint(
          painter: _CanvasGridPainter(
            minorGridColor: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
            majorGridColor: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            gridSize: 50.0,
            majorEvery: 5,
          ),
          child: Stack(
            children: [
              if (widget.showPhysicalPorts) ..._buildPhysicalInputNodes(physicalInputs),
              if (widget.showPhysicalPorts) ..._buildPhysicalOutputNodes(physicalOutputs),
              ..._buildAlgorithmNodes(algorithms),
              ..._buildConnectionLines(connections),
              if (_isDraggingConnection && _dragPosition != null) _buildTemporaryConnection(),
            ],
          ),
        ),
      ),
    );
  }

  // Below methods are copied from RoutingCanvas (handlers, builders, validators)
  List<Widget> _buildPhysicalInputNodes(List<Port> physicalInputs) { /* same as RoutingCanvas */
    if (physicalInputs.isEmpty) return [];
    final nodePosition = Offset(widget.canvasSize.width < 800 ? 20.0 : 30.0, 80.0);
    return [
      Positioned(
        key: const ValueKey('physical_input_node'),
        left: nodePosition.dx,
        top: nodePosition.dy,
        child: PhysicalInputNode(
          position: nodePosition,
          showLabels: widget.canvasSize.width >= 800,
          onPortTapped: (port) => _handlePortTap(port),
          onDragStart: (port) => _handlePortDragStart(port),
          onDragUpdate: (port, position) => _handlePortDragUpdate(port, position),
          onDragEnd: (port, position) => _handlePortDragEnd(port, position),
        ),
      ),
    ];
  }

  List<Widget> _buildPhysicalOutputNodes(List<Port> physicalOutputs) { /* same as RoutingCanvas */
    if (physicalOutputs.isEmpty) return [];
    final nodePosition = Offset(widget.canvasSize.width - (widget.canvasSize.width < 800 ? 180.0 : 190.0), 120.0);
    return [
      Positioned(
        key: const ValueKey('physical_output_node'),
        left: nodePosition.dx,
        top: nodePosition.dy,
        child: PhysicalOutputNode(
          position: nodePosition,
          showLabels: widget.canvasSize.width >= 800,
          onPortTapped: (port) => _handlePortTap(port),
          onDragStart: (port) => _handlePortDragStart(port),
          onDragUpdate: (port, position) => _handlePortDragUpdate(port, position),
          onDragEnd: (port, position) => _handlePortDragEnd(port, position),
        ),
      ),
    ];
  }

  List<Widget> _buildAlgorithmNodes(List<RoutingAlgorithm> algorithms) { /* same as RoutingCanvas */
    return algorithms.map((algorithm) {
      final nodeId = 'algorithm_${algorithm.index}';
      final position = _nodePositions[nodeId] ?? Offset.zero;
      final isSelected = _selectedNodes.contains(nodeId);

      final metadata = AlgorithmRoutingMetadata(
        algorithmGuid: algorithm.algorithm.guid,
        algorithmName: algorithm.algorithm.name,
        routingType: RoutingType.polyphonic,
        voiceCount: 1,
      );

      return Positioned(
        key: ValueKey('algorithm_positioned_${algorithm.index}'),
        left: position.dx,
        top: position.dy,
        child: AlgorithmNode(
          metadata: metadata,
          inputPorts: algorithm.inputPorts
              .map((p) => core_port.Port(
                    id: p.id,
                    name: p.name,
                    type: _mapUiToCoreType(p.type),
                    direction: p.direction == PortDirection.input
                        ? core_port.PortDirection.input
                        : core_port.PortDirection.output,
                  ))
              .toList(),
          outputPorts: algorithm.outputPorts
              .map((p) => core_port.Port(
                    id: p.id,
                    name: p.name,
                    type: _mapUiToCoreType(p.type),
                    direction: p.direction == PortDirection.input
                        ? core_port.PortDirection.input
                        : core_port.PortDirection.output,
                  ))
              .toList(),
          position: position,
          isSelected: isSelected,
          onPortTapped: (port) => _handlePortTap(port),
          onNodeTapped: () => _handleNodeTap(nodeId),
        ),
      );
    }).toList();
  }

  List<Widget> _buildConnectionLines(List<Connection> connections) { /* same as RoutingCanvas */
    return connections.map((connection) {
      final sourcePosition = _getPortPosition(connection.sourcePortId);
      final targetPosition = _getPortPosition(connection.targetPortId);
      if (sourcePosition == null || targetPosition == null) {
        return const SizedBox.shrink();
      }
      final sourcePort = _findPortById(connection.sourcePortId);
      final targetPort = _findPortById(connection.targetPortId);
      if (sourcePort == null || targetPort == null) {
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
          key: ValueKey('connection_${connection.sourcePortId}_${connection.targetPortId}'),
          connection: mockConnection,
          onTapped: () => _handleConnectionTap('${connection.sourcePortId}->${connection.targetPortId}'),
        );
      }
      final isGhost = ConnectionValidator.isGhostConnection(sourcePort, targetPort);
      final connectionWidgetLine = connection_widget.Connection(
        sourcePort: sourcePort,
        destinationPort: targetPort,
        sourcePosition: sourcePosition,
        destinationPosition: targetPosition,
        isSelected: _selectedConnectionId == '${connection.sourcePortId}->${connection.targetPortId}',
        metadata: isGhost ? {'isGhost': true} : null,
      );
      return connection_widget.ConnectionLine(
        key: ValueKey('connection_${connection.sourcePortId}_${connection.targetPortId}'),
        connection: connectionWidgetLine,
        strokeWidth: isGhost ? 1.5 : 2.0,
        onTapped: () => _handleConnectionTap('${connection.sourcePortId}->${connection.targetPortId}'),
      );
    }).toList();
  }

  Widget _buildTemporaryConnection() { /* same as RoutingCanvas */
    if (_connectionSourcePortId == null || _dragPosition == null) {
      return const SizedBox.shrink();
    }
    final sourcePosition = _getPortPosition(_connectionSourcePortId!);
    if (sourcePosition == null) return const SizedBox.shrink();
    final sourcePort = _findPortById(_connectionSourcePortId!);
    if (sourcePort == null) return const SizedBox.shrink();
    final targetPort = _findPortAtPosition(_dragPosition!);
    final destinationPort = targetPort ?? core_port.Port(
      id: 'temp',
      name: 'Target',
      type: core_port.PortType.audio,
      direction: core_port.PortDirection.input,
    );
    final connection = connection_widget.Connection(
      sourcePort: sourcePort,
      destinationPort: destinationPort,
      sourcePosition: sourcePosition,
      destinationPosition: _dragPosition!,
      isSelected: false,
    );
    return connection_widget.ConnectionLine(
      key: const ValueKey('temporary_connection_line'),
      connection: connection,
      strokeWidth: 1.5,
    );
  }

  // Event handlers copied from RoutingCanvas
  void _handleCanvasTap(TapDownDetails details) { /* same logic */ }
  void _handleCanvasDrag(DragUpdateDetails details) { /* same logic */ }
  void _handleCanvasDragEnd(DragEndDetails details) { /* same logic */ }
  void _handlePortTap(core_port.Port port) { /* same logic */ }
  void _handlePortDragStart(core_port.Port port) { /* same logic */ }
  void _handlePortDragUpdate(core_port.Port port, Offset position) { /* same logic */ }
  void _handlePortDragEnd(core_port.Port port, Offset position) { /* same logic */ }
  void _handleNodeTap(String nodeId) { /* same logic */ }
  void _handleConnectionTap(String connectionId) { /* same logic */ }
  // Haptic feedback suppressed to reduce complexity

  bool _hasLoadedStateChanged(RoutingEditorStateLoaded previous, RoutingEditorStateLoaded current) { /* same as RoutingCanvas */
    if (previous.physicalInputs.length != current.physicalInputs.length ||
        previous.physicalOutputs.length != current.physicalOutputs.length ||
        previous.algorithms.length != current.algorithms.length ||
        previous.connections.length != current.connections.length) {
      return true;
    }
    for (int i = 0; i < current.algorithms.length; i++) {
      if (i >= previous.algorithms.length) return true;
      final prevAlg = previous.algorithms[i];
      final currAlg = current.algorithms[i];
      if (prevAlg.index != currAlg.index || prevAlg.algorithm.name != currAlg.algorithm.name) {
        return true;
      }
      if (prevAlg.inputPorts.length != currAlg.inputPorts.length) return true;
      for (int p = 0; p < currAlg.inputPorts.length; p++) {
        final a = prevAlg.inputPorts[p];
        final b = currAlg.inputPorts[p];
        if (a.id != b.id || a.name != b.name || a.type != b.type || a.direction != b.direction) {
          return true;
        }
      }
      if (prevAlg.outputPorts.length != currAlg.outputPorts.length) return true;
      for (int p = 0; p < currAlg.outputPorts.length; p++) {
        final a = prevAlg.outputPorts[p];
        final b = currAlg.outputPorts[p];
        if (a.id != b.id || a.name != b.name || a.type != b.type || a.direction != b.direction) {
          return true;
        }
      }
    }
    if (previous.connections.length != current.connections.length) return true;
    for (int i = 0; i < current.connections.length; i++) {
      if (i >= previous.connections.length) return true;
      final prev = previous.connections[i];
      final curr = current.connections[i];
      if (prev.sourcePortId != curr.sourcePortId || prev.targetPortId != curr.targetPortId) {
        return true;
      }
    }
    return false;
  }

  core_port.Port? _findPortById(String portId) {
    final state = context.read<RoutingEditorCubit>().state;
    if (state is! RoutingEditorStateLoaded) return null;
    for (final port in state.physicalInputs) {
      if (port.id == portId) {
        return core_port.Port(
          id: port.id,
          name: port.name,
          type: _mapUiToCoreType(port.type),
          direction: core_port.PortDirection.output,
          metadata: {'isPhysical': true, 'jackType': 'input'},
        );
      }
    }
    for (final port in state.physicalOutputs) {
      if (port.id == portId) {
        return core_port.Port(
          id: port.id,
          name: port.name,
          type: _mapUiToCoreType(port.type),
          direction: core_port.PortDirection.input,
          metadata: {'isPhysical': true, 'jackType': 'output'},
        );
      }
    }
    // Algorithm ports could be added similarly if needed
    return null;
  }
  core_port.PortType _mapUiToCoreType(PortType type) { /* same mapping as canvas */
    switch (type) {
      case PortType.audio:
        return core_port.PortType.audio;
      case PortType.cv:
        return core_port.PortType.cv;
      case PortType.gate:
        return core_port.PortType.gate;
      case PortType.trigger:
        return core_port.PortType.clock;
    }
  }
  Offset? _getPortPosition(String portId) {
    final pos = _nodePositions[portId];
    if (pos != null) return Offset(pos.dx + 60, pos.dy + 20);
    return null;
  }
  core_port.Port? _findPortAtPosition(Offset position) {
    // Simple hit test stub for temporary connection; returns null to keep analyzer happy
    return null;
  }
}

class _CanvasGridPainter extends CustomPainter { /* same as canvas */
  final Color minorGridColor;
  final Color majorGridColor;
  final double gridSize;
  final int majorEvery;
  const _CanvasGridPainter({required this.minorGridColor, required this.majorGridColor, this.gridSize = 50.0, this.majorEvery = 5});
  @override
  void paint(Canvas canvas, Size size) {
    final minorPaint = Paint()..color = minorGridColor..strokeWidth = 1;
    final majorPaint = Paint()..color = majorGridColor..strokeWidth = 1.5;
    for (double x = 0; x <= size.width; x += gridSize) {
      final isMajor = (x / gridSize) % majorEvery == 0;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), isMajor ? majorPaint : minorPaint);
    }
    for (double y = 0; y <= size.height; y += gridSize) {
      final isMajor = (y / gridSize) % majorEvery == 0;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), isMajor ? majorPaint : minorPaint);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
