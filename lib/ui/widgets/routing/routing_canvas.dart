import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nt_helper/cubit/routing_editor_cubit.dart';
import 'package:nt_helper/core/routing/models/algorithm_routing_metadata.dart';
import 'package:nt_helper/core/routing/models/port.dart' as core_port;
// Routing decisions happen in the cubit; factory not needed here
// Docs/services not required here; routing is computed in the cubit
import 'package:nt_helper/services/haptic_feedback_service.dart';
import 'package:nt_helper/ui/widgets/routing/connection_line.dart' as connection_widget;
import 'package:nt_helper/ui/widgets/routing/algorithm_node.dart';
import 'package:nt_helper/ui/widgets/routing/physical_input_node.dart';
import 'package:nt_helper/ui/widgets/routing/physical_output_node.dart';
import 'package:nt_helper/ui/widgets/routing/physical_port_generator.dart';
import 'package:nt_helper/ui/widgets/routing/physical_io_node_widget.dart';
import 'package:nt_helper/ui/widgets/routing/connection_validator.dart';

/// A canvas widget that visualizes the algorithm routing system.
/// 
/// This widget orchestrates AlgorithmNode and ConnectionLine widgets,
/// listening to the RoutingEditorCubit for state changes and updating
/// the UI reactively. The layout adapts to changes in the routing state.
/// 
/// ## Architecture
/// - Uses BlocBuilder for reactive state management
/// - Implements performance optimizations with buildWhen conditions
/// - Caches algorithm metadata for efficient reuse
/// - Supports interactive connection creation via drag and drop
/// - Provides configurable canvas size and layout options
/// 
/// ## Features
/// - Real-time visualization of routing configurations
/// - Interactive node selection and highlighting
/// - Drag-and-drop connection creation
/// - Grid background for professional appearance
/// - Physical port visualization (hardware inputs/outputs)
/// - Algorithm node positioning in organized grid layout
/// - Connection line rendering with bezier curves
/// - State-aware UI updates (loading, error, disconnected states)
/// 
/// ## Performance Optimizations
/// - Efficient state change detection to minimize rebuilds
/// - Widget key usage for stable widget identity
/// - Algorithm metadata caching with automatic cleanup
/// - Optimized connection rendering
/// 
/// ## Usage
/// ```dart
/// RoutingCanvas(
///   canvasSize: Size(1200, 800),
///   showPhysicalPorts: true,
///   onNodeSelected: (nodeId) => handleSelection(nodeId),
///   onConnectionCreated: (source, target) => createConnection(source, target),
/// )
/// ```
class RoutingCanvas extends StatefulWidget {
  // Kept for API compatibility; ignored by this widget
  final Object? routingFactory;
  
  /// The size of the canvas in logical pixels.
  /// 
  /// Defines the drawable area for the routing visualization.
  /// Default size is 1200x800 pixels.
  final Size canvasSize;
  
  /// Whether to show physical input/output ports on the canvas.
  /// 
  /// When true, displays hardware input and output ports on the left
  /// and right sides of the canvas respectively.
  final bool showPhysicalPorts;
  
  /// Callback invoked when a node is selected.
  /// 
  /// Receives the ID of the selected node (e.g., 'hw_in_1', 'algorithm_0').
  final Function(String nodeId)? onNodeSelected;
  
  /// Callback invoked when a new connection is created via drag and drop.
  /// 
  /// Receives the source and target port IDs for the new connection.
  final Function(String sourcePortId, String targetPortId)? onConnectionCreated;
  
  /// Callback invoked when a connection is removed or deleted.
  /// 
  /// Receives the ID of the connection to be removed.
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
  
  // Factory no longer used; routing is resolved in the cubit
  late IHapticFeedbackService _hapticFeedback;
  
  // Haptic feedback debouncing
  String? _lastHapticTargetPortId;
  DateTime? _lastHapticTime;
  static const Duration _hapticDebounceTime = Duration(milliseconds: 100);
  
  // Memoization cache for algorithm metadata
  final Map<String, AlgorithmRoutingMetadata> _algorithmMetadataCache = {};

  @override
  void initState() {
    super.initState();
    // No-op: routing is computed by cubit and provided via state
    _hapticFeedback = HapticFeedbackService();
    _initializeNodePositions();
  }

  /// Initialize default positions for nodes in a grid layout
  void _initializeNodePositions() {
    // Physical I/O nodes are positioned directly in the build methods
    // We only need individual port positions for connection line endpoints
    
    // Store individual physical input port positions for connection endpoints
    final double leftMargin = widget.canvasSize.width < 800 ? 30.0 : 50.0;
    final double inputSpacing = widget.canvasSize.height < 600 ? 45.0 : 55.0;
    for (int i = 0; i < 12; i++) {
      _nodePositions['hw_in_${i + 1}'] = Offset(
        leftMargin + 120, // Right edge of physical input node
        100 + (i * inputSpacing),
      );
    }
    
    // Store individual physical output port positions for connection endpoints
    final double rightMargin = widget.canvasSize.width < 800 ? 160.0 : 170.0;
    final double outputSpacing = widget.canvasSize.height < 600 ? 60.0 : 75.0;
    for (int i = 0; i < 8; i++) {
      _nodePositions['hw_out_${i + 1}'] = Offset(
        widget.canvasSize.width - rightMargin, // Left edge of physical output node
        140 + (i * outputSpacing),
      );
    }
    
    // Position algorithm slots in the middle (responsive grid)
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
    // Clear caches to prevent memory leaks
    _algorithmMetadataCache.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RoutingEditorCubit, RoutingEditorState>(
      buildWhen: (previous, current) {
        // Only rebuild if the state type changes or the loaded state data changes
        return previous.runtimeType != current.runtimeType ||
               (previous is RoutingEditorStateLoaded && current is RoutingEditorStateLoaded && 
                _hasLoadedStateChanged(previous, current));
      },
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
      ),
    );
  }

  List<Widget> _buildPhysicalInputNodes(List<Port> physicalInputs) {
    // Group all physical inputs into a single PhysicalInputNode
    if (physicalInputs.isEmpty) return [];
    
    // Position for the physical input node (left side of canvas)
    final nodePosition = Offset(
      widget.canvasSize.width < 800 ? 20.0 : 30.0,
      80.0, // Start from top with some margin
    );
    
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

  List<Widget> _buildPhysicalOutputNodes(List<Port> physicalOutputs) {
    // Group all physical outputs into a single PhysicalOutputNode
    if (physicalOutputs.isEmpty) return [];
    
    // Position for the physical output node (right side of canvas)
    final nodePosition = Offset(
      widget.canvasSize.width - (widget.canvasSize.width < 800 ? 180.0 : 190.0), // Adjusted for larger nodes
      120.0, // Start slightly lower than inputs for visual balance
    );
    
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

  // Port drag handling methods
  void _handlePortDragStart(core_port.Port port) {
    // Provide heavy impact feedback when starting a drag operation
    _hapticFeedback.heavyImpact(context);
    
    setState(() {
      _isDraggingConnection = true;
      _connectionSourcePortId = port.id;
      _dragPosition = _getPortPosition(port.id);
    });
  }
  
  void _handlePortDragUpdate(core_port.Port port, Offset globalPosition) {
    // Convert global position to local canvas position
    final RenderBox? box = context.findRenderObject() as RenderBox?;
    if (box != null) {
      final localPosition = box.globalToLocal(globalPosition);
      
      // Check if hovering over a valid connection target and provide light feedback
      final hoveredPort = _findPortAtPosition(localPosition);
      if (hoveredPort != null && 
          hoveredPort.id != port.id && 
          ConnectionValidator.isValidConnection(port, hoveredPort)) {
        // Provide debounced light haptic feedback for valid hover target
        _provideDebouncedHapticFeedback(hoveredPort.id);
      }
      
      setState(() {
        _dragPosition = localPosition;
      });
    }
  }
  
  void _handlePortDragEnd(core_port.Port sourcePort, Offset globalPosition) {
    // Convert global position to local canvas position
    final RenderBox? box = context.findRenderObject() as RenderBox?;
    if (box != null) {
      final localPosition = box.globalToLocal(globalPosition);
      
      // Find target port at position
      final targetPort = _findPortAtPosition(localPosition);
      
      if (targetPort != null && targetPort.id != sourcePort.id) {
        // Validate and create connection
        if (ConnectionValidator.isValidConnection(sourcePort, targetPort)) {
          widget.onConnectionCreated?.call(sourcePort.id, targetPort.id);
          
          // Provide successful connection haptic feedback
          _hapticFeedback.mediumImpact(context);
          
          // Check if it's a ghost connection
          if (ConnectionValidator.isGhostConnection(sourcePort, targetPort)) {
            debugPrint('Ghost connection created: ${ConnectionValidator.getConnectionDescription(sourcePort, targetPort)}');
          }
        } else {
          // Show error for invalid connection
          final error = ConnectionValidator.getValidationError(sourcePort, targetPort);
          debugPrint('Invalid connection: $error');
          
          // Provide error haptic feedback
          _hapticFeedback.errorFeedback(context);
        }
      }
    }
    
    setState(() {
      _isDraggingConnection = false;
      _connectionSourcePortId = null;
      _dragPosition = null;
    });
  }
  
  /// Find a port at the given canvas position
  core_port.Port? _findPortAtPosition(Offset position) {
    // Check physical input ports using actual node positioning
    final inputNodeX = widget.canvasSize.width < 800 ? 20.0 : 30.0;
    const inputNodeWidth = 160.0; // Updated to match new node width
    const inputStartY = 80.0;
    final jackSpacing = PhysicalIONodeWidget.getOptimalSpacing(widget.canvasSize);
    const headerHeight = 40.0; // Height of header section
    
    if (position.dx >= inputNodeX && position.dx <= inputNodeX + inputNodeWidth) {
      for (int i = 0; i < 12; i++) {
        final portY = inputStartY + headerHeight + (i * jackSpacing) + (jackSpacing / 2);
        if ((position.dy - portY).abs() < (jackSpacing / 2)) {
          return PhysicalPortGenerator.generatePhysicalInputPort(i + 1);
        }
      }
    }
    
    // Check physical output ports using actual node positioning  
    final outputNodeX = widget.canvasSize.width - (widget.canvasSize.width < 800 ? 180.0 : 190.0); // Adjusted for larger nodes
    const outputNodeWidth = 160.0; // Updated to match new node width
    const outputStartY = 120.0;
    
    if (position.dx >= outputNodeX && position.dx <= outputNodeX + outputNodeWidth) {
      for (int i = 0; i < 8; i++) {
        final portY = outputStartY + headerHeight + (i * jackSpacing) + (jackSpacing / 2);
        if ((position.dy - portY).abs() < (jackSpacing / 2)) {
          return PhysicalPortGenerator.generatePhysicalOutputPort(i + 1);
        }
      }
    }
    
    // TODO: Check algorithm node ports
    
    return null;
  }

  List<Widget> _buildAlgorithmNodes(List<RoutingAlgorithm> algorithms) {
    return algorithms.map((algorithm) {
      final nodeId = 'algorithm_${algorithm.index}';
      final position = _nodePositions[nodeId] ?? Offset.zero;
      final isSelected = _selectedNodes.contains(nodeId);

      // Build minimal metadata for display; ports already computed by cubit
      final metadata = AlgorithmRoutingMetadata(
        algorithmGuid: algorithm.algorithm.guid,
        algorithmName: algorithm.algorithm.name,
        routingType: RoutingType.polyphonic, // display only
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

  core_port.PortType _mapUiToCoreType(PortType type) {
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

  List<Widget> _buildConnectionLines(List<Connection> connections) {
    return connections.map((connection) {
      final sourcePosition = _getPortPosition(connection.sourcePortId);
      final targetPosition = _getPortPosition(connection.targetPortId);
      
      if (sourcePosition == null || targetPosition == null) {
        return const SizedBox.shrink();
      }
      
      // Get actual port objects for proper connection rendering
      final sourcePort = _findPortById(connection.sourcePortId);
      final targetPort = _findPortById(connection.targetPortId);
      
      if (sourcePort == null || targetPort == null) {
        // Fallback to basic connection if ports not found
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
      
      // Check if this is a ghost connection
      final isGhost = ConnectionValidator.isGhostConnection(sourcePort, targetPort);
      
      final connectionWidget = connection_widget.Connection(
        sourcePort: sourcePort,
        destinationPort: targetPort,
        sourcePosition: sourcePosition,
        destinationPosition: targetPosition,
        isSelected: _selectedConnectionId == '${connection.sourcePortId}->${connection.targetPortId}',
        metadata: isGhost ? {'isGhost': true} : null,
      );
      
      return connection_widget.ConnectionLine(
        key: ValueKey('connection_${connection.sourcePortId}_${connection.targetPortId}'),
        connection: connectionWidget,
        strokeWidth: isGhost ? 1.5 : 2.0, // Ghost connections are slightly thinner
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
    
    // Get the actual source port for validation
    final sourcePort = _findPortById(_connectionSourcePortId!);
    if (sourcePort == null) return const SizedBox.shrink();
    
    // Try to find target port at current drag position
    final targetPort = _findPortAtPosition(_dragPosition!);
    
    // Create appropriate target for validation
    final destinationPort = targetPort ?? core_port.Port(
      id: 'temp',
      name: 'Target',
      type: core_port.PortType.audio,
      direction: core_port.PortDirection.input,
    );
    
    // Check if this would be a valid connection
    final isValidConnection = targetPort != null && 
                             targetPort.id != sourcePort.id &&
                             ConnectionValidator.isValidConnection(sourcePort, targetPort);
    
    final isGhostConnection = isValidConnection && 
                             ConnectionValidator.isGhostConnection(sourcePort, targetPort);
    
    final mockConnection = connection_widget.Connection(
      sourcePort: sourcePort,
      destinationPort: destinationPort,
      sourcePosition: sourcePosition,
      destinationPosition: _dragPosition!,
      isHighlighted: true,
      metadata: {
        if (!isValidConnection && targetPort != null) 'invalid': true,
        if (isGhostConnection) 'isGhost': true,
      },
    );
    
    // Visual feedback based on validity
    return connection_widget.ConnectionLine(
      key: const ValueKey('temp_connection'),
      connection: mockConnection,
      strokeWidth: isValidConnection ? 2.5 : 1.5,
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
        // Validate the connection before creating it
        final sourcePort = _findPortById(_connectionSourcePortId!);
        if (sourcePort != null && ConnectionValidator.isValidConnection(sourcePort, port)) {
          widget.onConnectionCreated?.call(_connectionSourcePortId!, port.id);
          
          // Provide successful connection haptic feedback
          _hapticFeedback.mediumImpact(context);
          
          // Check if it's a ghost connection and show visual indicator
          if (ConnectionValidator.isGhostConnection(sourcePort, port)) {
            // TODO: Add visual indicator for ghost connection
            debugPrint('Ghost connection created: ${ConnectionValidator.getConnectionDescription(sourcePort, port)}');
          }
        } else if (sourcePort != null) {
          // Show error message for invalid connection
          final error = ConnectionValidator.getValidationError(sourcePort, port);
          debugPrint('Invalid connection: $error');
          
          // Provide error haptic feedback
          _hapticFeedback.errorFeedback(context);
          
          // TODO: Show user-friendly error message
        }
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

  /// Provides debounced haptic feedback to prevent rapid successive triggers
  void _provideDebouncedHapticFeedback(String targetPortId) {
    final now = DateTime.now();
    
    // Check if this is a new target or enough time has passed
    if (_lastHapticTargetPortId != targetPortId || 
        _lastHapticTime == null || 
        now.difference(_lastHapticTime!) > _hapticDebounceTime) {
      
      _hapticFeedback.lightImpact(context);
      _lastHapticTargetPortId = targetPortId;
      _lastHapticTime = now;
    }
  }

  // Metadata per node is minimal for display since ports are precomputed

  // Deprecated: routing metadata decisions are now made in the cubit
  
  // No routing decisions here — cubit supplies ports and we just render them

  /// Efficiently checks if the loaded state data has meaningfully changed
  bool _hasLoadedStateChanged(RoutingEditorStateLoaded previous, RoutingEditorStateLoaded current) {
    // Check if lists have different lengths (most common case)
    if (previous.physicalInputs.length != current.physicalInputs.length ||
        previous.physicalOutputs.length != current.physicalOutputs.length ||
        previous.algorithms.length != current.algorithms.length ||
        previous.connections.length != current.connections.length) {
      return true;
    }
    
    // For small lists, we can do more detailed comparison
    // In a production app, you might want to implement more sophisticated
    // change detection or use immutable data structures
    
    // Check algorithms for changes (indices, names, and port sets)
    for (int i = 0; i < current.algorithms.length; i++) {
      if (i >= previous.algorithms.length) return true;
      final prevAlg = previous.algorithms[i];
      final currAlg = current.algorithms[i];
      if (prevAlg.index != currAlg.index || prevAlg.algorithm.name != currAlg.algorithm.name) {
        return true;
      }
      // Compare input ports
      if (prevAlg.inputPorts.length != currAlg.inputPorts.length) return true;
      for (int p = 0; p < currAlg.inputPorts.length; p++) {
        final a = prevAlg.inputPorts[p];
        final b = currAlg.inputPorts[p];
        if (a.id != b.id || a.name != b.name || a.type != b.type || a.direction != b.direction) {
          return true;
        }
      }
      // Compare output ports
      if (prevAlg.outputPorts.length != currAlg.outputPorts.length) return true;
      for (int p = 0; p < currAlg.outputPorts.length; p++) {
        final a = prevAlg.outputPorts[p];
        final b = currAlg.outputPorts[p];
        if (a.id != b.id || a.name != b.name || a.type != b.type || a.direction != b.direction) {
          return true;
        }
      }
    }
    
    // Check connections for changes
    if (previous.connections.length != current.connections.length) return true;
    for (int i = 0; i < current.connections.length; i++) {
      if (i >= previous.connections.length) return true;
      final prev = previous.connections[i];
      final curr = current.connections[i];
      if (prev.sourcePortId != curr.sourcePortId ||
          prev.targetPortId != curr.targetPortId) {
        return true;
      }
    }
    
    return false; // No meaningful changes detected
  }

  /// Find a port by its ID from the current state
  core_port.Port? _findPortById(String portId) {
    final state = context.read<RoutingEditorCubit>().state;
    if (state is! RoutingEditorStateLoaded) return null;
    
    // Check physical inputs
    for (final port in state.physicalInputs) {
      if (port.id == portId) {
        // Convert from state Port to core_port.Port
        return core_port.Port(
          id: port.id,
          name: port.name,
          type: _convertPortType(port.type),
          direction: core_port.PortDirection.output, // Physical inputs are sources
          metadata: {
            'isPhysical': true,
            'jackType': 'input',
            'hardwareIndex': port.id.replaceAll('hw_in_', ''),
          },
        );
      }
    }
    
    // Check physical outputs
    for (final port in state.physicalOutputs) {
      if (port.id == portId) {
        // Convert from state Port to core_port.Port
        return core_port.Port(
          id: port.id,
          name: port.name,
          type: _convertPortType(port.type),
          direction: core_port.PortDirection.input, // Physical outputs are destinations
          metadata: {
            'isPhysical': true,
            'jackType': 'output',
            'hardwareIndex': port.id.replaceAll('hw_out_', ''),
          },
        );
      }
    }
    
    // TODO: Check algorithm ports when we have proper port generation
    
    return null;
  }
  
  /// Convert from state PortType to core_port.PortType
  core_port.PortType _convertPortType(PortType statePortType) {
    switch (statePortType) {
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
}

/// Custom painter for drawing the canvas grid background
class _CanvasGridPainter extends CustomPainter {
  final Color minorGridColor;
  final Color majorGridColor;
  final double gridSize;
  final int majorEvery;

  const _CanvasGridPainter({
    required this.minorGridColor,
    required this.majorGridColor,
    this.gridSize = 50.0,
    this.majorEvery = 5,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.stroke;

    // Vertical lines
    for (double x = 0; x <= size.width; x += gridSize) {
      final isMajor = (x / gridSize) % majorEvery == 0;
      paint
        ..color = isMajor ? majorGridColor : minorGridColor
        ..strokeWidth = isMajor ? 1.0 : 0.5;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Horizontal lines
    for (double y = 0; y <= size.height; y += gridSize) {
      final isMajor = (y / gridSize) % majorEvery == 0;
      paint
        ..color = isMajor ? majorGridColor : minorGridColor
        ..strokeWidth = isMajor ? 1.0 : 0.5;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _CanvasGridPainter oldDelegate) {
    return oldDelegate.minorGridColor != minorGridColor ||
           oldDelegate.majorGridColor != majorGridColor ||
           oldDelegate.gridSize != gridSize ||
           oldDelegate.majorEvery != majorEvery;
  }
}
