import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nt_helper/cubit/routing_editor_cubit.dart';
import 'package:nt_helper/cubit/routing_editor_state.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/core/routing/models/port.dart' as core_port;
import 'package:nt_helper/core/routing/models/connection.dart';
import 'package:nt_helper/ui/widgets/routing/interactive_routing_canvas.dart';
// Haptics can be reintroduced later if needed
import 'package:nt_helper/ui/widgets/routing/connection_painter.dart' as painter;
import 'package:nt_helper/ui/widgets/routing/algorithm_node_widget.dart';
import 'package:nt_helper/ui/widgets/routing/physical_input_node.dart';
import 'package:nt_helper/ui/widgets/routing/physical_output_node.dart';
import 'package:nt_helper/core/routing/services/connection_drag_handler.dart';
import 'package:nt_helper/core/routing/services/connection_deletion_handler.dart';
import 'package:nt_helper/core/routing/services/connection_bus_manager.dart';
import 'package:nt_helper/core/routing/services/interactive_connection_validator.dart';
import 'package:nt_helper/ui/routing/widgets/drag_preview_painter.dart';
import 'package:nt_helper/ui/routing/widgets/connection_delete_dialog.dart';
import 'package:nt_helper/ui/routing/widgets/port_mode_indicator.dart';
// Removed unused imports from previous canvas split

/// RoutingEditorWidget is the canonical widget for the routing editor UI.
/// It composes the routing canvas and exposes the same API for compatibility.
class RoutingEditorWidget extends StatefulWidget {
  final Object? routingFactory; // ignored (decisions in cubit)
  final Size canvasSize;
  final bool showPhysicalPorts;
  final bool showBusLabels;
  final bool enableInteractiveEditing; // New: Enable interactive connection editing
  final Function(String nodeId)? onNodeSelected;
  final Function(String sourcePortId, String targetPortId)? onConnectionCreated;
  final Function(String connectionId)? onConnectionRemoved;

  RoutingEditorWidget({
    super.key,
    this.routingFactory,
    this.canvasSize = const Size(1200, 800),
    this.showPhysicalPorts = true,
    bool? showBusLabels,
    this.enableInteractiveEditing = false,
    this.onNodeSelected,
    this.onConnectionCreated,
    this.onConnectionRemoved,
  }) : showBusLabels = showBusLabels ?? (canvasSize.width >= 800);

  @override
  State<RoutingEditorWidget> createState() => _RoutingEditorWidgetState();
}

class _RoutingEditorWidgetState extends State<RoutingEditorWidget> {
  final Map<String, Offset> _nodePositions = {};
  final Map<String, Offset> _portPositions = {};  // Store actual port positions
  final Set<String> _selectedNodes = {};
  
  Offset? _dragPosition;
  bool _isDraggingConnection = false;
  
  // Drag-and-drop connection handler
  late ConnectionDragHandler _dragHandler;
  
  // Connection deletion handler
  late ConnectionDeletionHandler _deletionHandler;
  
  // Bus management and validation
  final ConnectionBusManager _busManager = ConnectionBusManager();
  
  // ScrollControllers for manual pan control
  late ScrollController _horizontalScrollController;
  late ScrollController _verticalScrollController;
  // Canvas container key for coordinate transforms
  final GlobalKey _canvasKey = GlobalKey();
  
  // Canvas dimensions
  static const double _canvasWidth = 5000.0;
  static const double _canvasHeight = 5000.0;
  
  // Dragging state for canvas pan
  bool _isPanning = false;
  Offset _lastPanPosition = Offset.zero;
  bool _isDraggingNode = false;
  

  bool _portsReady = false;

  @override
  void initState() {
    super.initState();
    _horizontalScrollController = ScrollController();
    _verticalScrollController = ScrollController();
    
    // Initialize drag handler with callbacks
    _dragHandler = ConnectionDragHandler(
      onDragStart: _onDragStart,
      onDragUpdate: _onDragUpdate,
      onDragEnd: _onDragEnd,
      onDragCancel: _onDragCancel,
    );
    
    // Initialize deletion handler with callbacks
    _deletionHandler = ConnectionDeletionHandler(
      onDeleteConnection: _onDeleteConnection,
      onHoverChanged: _onConnectionHoverChanged,
      onShowDeleteConfirmation: _onShowDeleteConfirmation,
      onHideDeleteConfirmation: _onHideDeleteConfirmation,
    );
    
    // Center the view on the canvas after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _centerCanvas();
      // Ports will set _portsReady when they register their positions
    });
    
    _initializeNodePositions();
  }
  
  void _centerCanvas() {
    // Center the scroll view on the canvas
    if (_horizontalScrollController.hasClients) {
      _horizontalScrollController.jumpTo((_canvasWidth - widget.canvasSize.width) / 2);
    }
    if (_verticalScrollController.hasClients) {
      _verticalScrollController.jumpTo((_canvasHeight - widget.canvasSize.height) / 2);
    }
  }

  void _initializeNodePositions() {
    // Position nodes in the center area of the 5000x5000 canvas
    const double centerX = _canvasWidth / 2;
    const double centerY = _canvasHeight / 2;
    
    // Physical inputs on the left side (matching _buildPhysicalInputNodes)
    _nodePositions['physical_inputs'] = const Offset(centerX - 800, centerY - 300);
    
    // Physical outputs on the right side (matching _buildPhysicalOutputNodes)
    _nodePositions['physical_outputs'] = const Offset(centerX + 600, centerY - 300);
    
    // Algorithm nodes in the center area
    // We'll initialize them when we have the actual algorithm IDs
    final routingState = context.read<RoutingEditorCubit>().state;
    if (routingState is RoutingEditorStateLoaded) {
      const double algorithmStartX = centerX - 250;
      const double algorithmSpacing = 300.0;
      const double algorithmRowSpacing = 200.0;
      for (int i = 0; i < routingState.algorithms.length && i < 8; i++) {
        final algo = routingState.algorithms[i];
        final column = i % 2;
        final row = i ~/ 2;
        _nodePositions[algo.id] = Offset(
          algorithmStartX + (column * algorithmSpacing),
          centerY - 300 + (row * algorithmRowSpacing),
        );
      }
    }
  }

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    _verticalScrollController.dispose();
    _deletionHandler.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RoutingEditorCubit, RoutingEditorState>(
      buildWhen: (previous, current) {
        final shouldRebuild = previous.runtimeType != current.runtimeType ||
            (previous is RoutingEditorStateLoaded &&
                current is RoutingEditorStateLoaded &&
                _hasLoadedStateChanged(previous, current));
        
        // Clear port positions when state changes significantly
        if (shouldRebuild && current is RoutingEditorStateLoaded) {
          _portPositions.clear();
          _portsReady = false;
        }
        
        return shouldRebuild;
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
      loaded: (physicalInputs, physicalOutputs, algorithms, connections, buses, portOutputModes, isHardwareSynced, isPersistenceEnabled, lastSyncTime, lastPersistTime, lastError, pendingOperations, baseConnections, hasOptimisticChanges, lastOptimisticChangeTime) =>
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
  ) {
    // Use interactive canvas if enabled
    if (widget.enableInteractiveEditing) {
      return InteractiveRoutingCanvas(
        canvasSize: widget.canvasSize,
        showPhysicalPorts: widget.showPhysicalPorts,
        showBusLabels: widget.showBusLabels,
        onNodeSelected: widget.onNodeSelected,
        onConnectionCreated: widget.onConnectionCreated,
        onConnectionRemoved: widget.onConnectionRemoved,
      );
    }

    // Use original canvas implementation
    return Semantics(
      label: 'Routing canvas with ${algorithms.length} algorithm nodes and ${connections.length} connections',
      hint: 'Interactive routing canvas. Pan and zoom to navigate. Drag between ports to create connections.',
      container: true,
      child: SingleChildScrollView(
        controller: _horizontalScrollController,
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(), // Disable scroll gestures
        child: SingleChildScrollView(
          controller: _verticalScrollController,
          scrollDirection: Axis.vertical,
          physics: const NeverScrollableScrollPhysics(), // Disable scroll gestures
          child: Listener(
            // Handle mouse wheel and trackpad scrolling
            onPointerSignal: (pointerSignal) {
              if (pointerSignal is PointerScrollEvent) {
                // Handle horizontal scrolling (trackpad side-scroll or shift+wheel)
                if (_horizontalScrollController.hasClients) {
                  final newHorizontal = _horizontalScrollController.offset + pointerSignal.scrollDelta.dx;
                  _horizontalScrollController.jumpTo(
                    newHorizontal.clamp(
                      _horizontalScrollController.position.minScrollExtent,
                      _horizontalScrollController.position.maxScrollExtent,
                    ),
                  );
                }
                
                // Handle vertical scrolling (mouse wheel or trackpad)
                if (_verticalScrollController.hasClients) {
                  final newVertical = _verticalScrollController.offset + pointerSignal.scrollDelta.dy;
                  _verticalScrollController.jumpTo(
                    newVertical.clamp(
                      _verticalScrollController.position.minScrollExtent,
                      _verticalScrollController.position.maxScrollExtent,
                    ),
                  );
                }
              }
            },
            child: Container(
              key: _canvasKey,
              width: _canvasWidth,
              height: _canvasHeight,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
              ),
            child: Stack(
                clipBehavior: Clip.none,
                children: [
                // Grid background with gesture detector for empty space (bottom layer)
                SizedBox(
                  width: _canvasWidth,
                  height: _canvasHeight,
                  child: GestureDetector(
                    // Handle taps and panning on empty space
                    onTapDown: (details) {
                      debugPrint('=== GRID TAP DOWN: ${details.localPosition}');
                    },
                    onPanStart: _handleCanvasPanStart,
                    onPanUpdate: _handleCanvasPanUpdate,
                    onPanEnd: _handleCanvasPanEnd,
                    behavior: HitTestBehavior.opaque, // Catch events in empty space only
                    child: CustomPaint(
                      painter: _CanvasGridPainter(
                        minorGridColor: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
                        majorGridColor: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                        gridSize: 50.0,
                        majorEvery: 5,
                      ),
                      size: Size(_canvasWidth, _canvasHeight),
                    ),
                  ),
                ),
                // Nodes on middle layer (connections will draw above to overlay ports)
                if (widget.showPhysicalPorts) ..._buildPhysicalInputNodes(physicalInputs),
                if (widget.showPhysicalPorts) ..._buildPhysicalOutputNodes(physicalOutputs),
                ..._buildAlgorithmNodes(algorithms),
                // Draw all connections with unified canvas
                if (connections.isNotEmpty) ...[
                  if (_portsReady)
                    IgnorePointer(
                      ignoring: true,
                      child: _buildUnifiedConnectionCanvas(connections),
                    )
                  else
                    IgnorePointer(
                      ignoring: true,
                      child: Center(
                        child: Text('Waiting for ports... (${connections.length} connections ready)'),
                      ),
                    ),
                ],
                if (_isDraggingConnection && _dragPosition != null) _buildTemporaryConnection(),
              ],
            ),
          ),
          ),
        ),
      ),
    );
  }

  // Below methods are copied from RoutingCanvas (handlers, builders, validators)
  List<Widget> _buildPhysicalInputNodes(List<Port> physicalInputs) {
    if (physicalInputs.isEmpty) return [];
    // Position in the center area of the canvas, to the left of algorithms
    const double centerX = _canvasWidth / 2;
    const double centerY = _canvasHeight / 2;
    final nodePosition = _nodePositions['physical_inputs'] ?? const Offset(centerX - 800, centerY - 300);
    
    return [
      Positioned(
        key: const ValueKey('physical_input_node'),
        left: nodePosition.dx,
        top: nodePosition.dy,
        child: PhysicalInputNode(
          position: nodePosition,
          onPositionChanged: (newPosition) {
            setState(() {
              _nodePositions['physical_inputs'] = newPosition;
            });
          },
          showLabels: widget.canvasSize.width >= 800,
          onPortTapped: (port) => _handlePortTap(port),
          onDragStart: (port) => _handlePortDragStart(port),
          onDragUpdate: (port, position) => _handlePortDragUpdate(port, position),
          onDragEnd: (port, position) => _handlePortDragEnd(port, position),
          onPortPositionResolved: (port, globalCenter) {
            _updatePortAnchor(port.id, globalCenter);
          },
          onNodeDragStart: () {
            // Node drag start handler (could be used for visual feedback)
          },
          onNodeDragEnd: () {
            // Node drag end handler (could be used for cleanup)
          },
        ),
      ),
    ];
  }

  List<Widget> _buildPhysicalOutputNodes(List<Port> physicalOutputs) {
    if (physicalOutputs.isEmpty) return [];
    // Position in the center area of the canvas, to the right of algorithms
    const double centerX = _canvasWidth / 2;
    const double centerY = _canvasHeight / 2;
    final nodePosition = _nodePositions['physical_outputs'] ?? const Offset(centerX + 600, centerY - 300);
    
    return [
      Positioned(
        key: const ValueKey('physical_output_node'),
        left: nodePosition.dx,
        top: nodePosition.dy,
        child: PhysicalOutputNode(
          position: nodePosition,
          onPositionChanged: (newPosition) {
            setState(() {
              _nodePositions['physical_outputs'] = newPosition;
            });
          },
          showLabels: widget.canvasSize.width >= 800,
          onPortTapped: (port) => _handlePortTap(port),
          onDragStart: (port) => _handlePortDragStart(port),
          onDragUpdate: (port, position) => _handlePortDragUpdate(port, position),
          onDragEnd: (port, position) => _handlePortDragEnd(port, position),
          onPortPositionResolved: (port, globalCenter) {
            _updatePortAnchor(port.id, globalCenter);
          },
          onNodeDragStart: () {
            // Node drag start handler (could be used for visual feedback)
          },
          onNodeDragEnd: () {
            // Node drag end handler (could be used for cleanup)
          },
        ),
      ),
    ];
  }

  List<Widget> _buildAlgorithmNodes(List<RoutingAlgorithm> algorithms) {
    return algorithms.map((algorithm) {
      // Use stable algorithm ID instead of index for consistent positioning
      final nodeId = algorithm.id;
      // Use a default position in the center area if not yet positioned
      final defaultPosition = Offset(
        _canvasWidth / 2 - 250 + ((algorithm.index % 2) * 300),
        _canvasHeight / 2 - 300 + ((algorithm.index ~/ 2) * 200),
      );
      final position = _nodePositions[nodeId] ?? defaultPosition;
      // Store the default position if not already in the map
      if (!_nodePositions.containsKey(nodeId)) {
        _nodePositions[nodeId] = defaultPosition;
      }
      final isSelected = _selectedNodes.contains(nodeId);

      return Positioned(
        left: position.dx,
        top: position.dy,
        child: AlgorithmNodeWidget(
          key: ValueKey(algorithm.id), // Use stable ID for widget key
          algorithmName: algorithm.algorithm.name,
          slotNumber: algorithm.index + 1, // 1-indexed for display
          position: position,
          isSelected: isSelected,
          inputLabels: algorithm.inputPorts.map((p) => p.name).toList(),
          outputLabels: algorithm.outputPorts.map((p) => p.name).toList(),
          inputPortIds: algorithm.inputPorts.map((p) => p.id).toList(),
          outputPortIds: algorithm.outputPorts.map((p) => p.id).toList(),
          onPortPositionResolved: (portId, globalCenter, isInput) {
            _updatePortAnchor(portId, globalCenter);
          },
          onDragStart: () {
            if (!_isDraggingNode) {
              setState(() {
                _isDraggingNode = true;
                _isPanning = false;
              });
            }
          },
          onPositionChanged: (newPosition) {
            // When a node is being dragged, flag it so canvas doesn't pan
            if (!_isDraggingNode) {
              setState(() {
                _isDraggingNode = true;
                _isPanning = false;
              });
            }
            setState(() {
              _nodePositions[nodeId] = newPosition;
            });
          },
          onDragEnd: () {
            if (_isDraggingNode) {
              setState(() {
                _isDraggingNode = false;
              });
            }
          },
          onMoveUp: algorithm.index > 0 ? () => _handleAlgorithmMoveUp(algorithm.index) : null,
          onMoveDown: algorithm.index < algorithms.length - 1 ? () => _handleAlgorithmMoveDown(algorithm.index) : null,
          onDelete: () => _handleAlgorithmDelete(algorithm.index),
          onTap: () => _handleNodeTap(nodeId),
        ),
      );
    }).toList();
  }

  Widget _buildUnifiedConnectionCanvas(List<Connection> connections) {
    // Build ConnectionData list for all connections
    final connectionDataList = <painter.ConnectionData>[];
    
    for (final connection in connections) {
      // For partial connections, we need special handling
      Offset? sourcePosition;
      Offset? targetPosition;
      
      if (connection.isPartial) {
        // For partial connections, one endpoint is a virtual bus endpoint
        // We only need the actual port position
        final connectionType = connection.connectionType;
        if (connectionType == ConnectionType.partialOutputToBus) {
          // Source is the actual output port
          sourcePosition = _getPortPosition(connection.sourcePortId);
          // For destination, create a position 75px to the right for the label
          if (sourcePosition != null) {
            targetPosition = Offset(sourcePosition.dx + 75, sourcePosition.dy);
          }
        } else if (connectionType == ConnectionType.partialBusToInput) {
          // Destination is the actual input port
          targetPosition = _getPortPosition(connection.destinationPortId);
          // For source, create a position 75px to the left for the label
          if (targetPosition != null) {
            sourcePosition = Offset(targetPosition.dx - 75, targetPosition.dy);
          }
        }
      } else {
        // Regular connection handling
        sourcePosition = _getPortPosition(connection.sourcePortId);
        targetPosition = _getPortPosition(connection.destinationPortId);
      }
      
      if (sourcePosition == null || targetPosition == null) {
        continue;
      }
      
      // Extract connection metadata to determine connection type
      final connectionType = connection.connectionType;
      
      final isPhysicalConnection = connectionType == ConnectionType.hardwareInput || 
          connectionType == ConnectionType.hardwareOutput;
      final isInputConnection = connectionType == ConnectionType.hardwareInput || 
          connectionType == ConnectionType.partialBusToInput;
      
      // Get bus number directly from the connection
      int? busNumber = connection.busNumber;
      
      // Fallback to extracting from busId if needed (e.g., "bus_5" -> 5)
      if (busNumber == null && connection.busId != null) {
        final busIdMatch = RegExp(r'bus_(\d+)').firstMatch(connection.busId!);
        if (busIdMatch != null) {
          busNumber = int.tryParse(busIdMatch.group(1)!);
          debugPrint('RoutingEditorWidget: Got bus number from busId: $busNumber');
        }
      }
      
      if (busNumber == null) {
        debugPrint('RoutingEditorWidget: No bus number found for connection ${connection.id}');
        debugPrint('  - busNumber: ${connection.busNumber}');
        debugPrint('  - busId: ${connection.busId}');
      }
      
      connectionDataList.add(painter.ConnectionData(
        connection: connection,
        sourcePosition: sourcePosition,
        destinationPosition: targetPosition,
        busNumber: busNumber,
        outputMode: connection.outputMode,
        isSelected: false,
        isHighlighted: false,
        isPhysicalConnection: isPhysicalConnection,
        isInputConnection: isInputConnection,
        busLabel: connection.busLabel, // Pass through bus label for partial connections
      ));
    }
    
    if (connectionDataList.isEmpty) {
      return const SizedBox.shrink();
    }
    
    // Use the unified ConnectionPainter
    return CustomPaint(
      painter: painter.ConnectionPainter(
        connections: connectionDataList,
        theme: Theme.of(context),
        showLabels: true,
        enableAnimations: true,
      ),
      child: const SizedBox.expand(),
    );
  }
  
  Widget _buildTemporaryConnection() {
    // Use the drag handler's preview data for enhanced visual feedback
    final previewData = _dragHandler.previewData;
    if (previewData == null) {
      return const SizedBox.shrink();
    }

    return IgnorePointer(
      child: DragPreviewWidget(
        previewData: previewData,
        validColor: Colors.green.withValues(alpha: 0.8),
        invalidColor: Colors.red.withValues(alpha: 0.8),
        strokeWidth: 3.0,
      ),
    );
  }

  // Transform-aware event handlers for InteractiveViewer
  void _handleCanvasPanStart(DragStartDetails details) {
    // Only start panning if we're not dragging a node
    if (!_isDraggingNode) {
      _isPanning = true;
      _lastPanPosition = details.globalPosition;
    }
  }
  
  void _handleCanvasPanUpdate(DragUpdateDetails details) {
    if (_isPanning && !_isDraggingNode) {
      // Pan the canvas by adjusting scroll controllers
      final delta = details.globalPosition - _lastPanPosition;
      _lastPanPosition = details.globalPosition;
      
      if (_horizontalScrollController.hasClients) {
        final newHorizontal = _horizontalScrollController.offset - delta.dx;
        _horizontalScrollController.jumpTo(
          newHorizontal.clamp(0.0, _horizontalScrollController.position.maxScrollExtent),
        );
      }
      
      if (_verticalScrollController.hasClients) {
        final newVertical = _verticalScrollController.offset - delta.dy;
        _verticalScrollController.jumpTo(
          newVertical.clamp(0.0, _verticalScrollController.position.maxScrollExtent),
        );
      }
    }
  }
  
  void _handleCanvasPanEnd(DragEndDetails details) {
    setState(() {
      _isPanning = false;
      _isDraggingNode = false;
    });
  }

  
  // Original event handlers
  void _handlePortTap(core_port.Port port) {
    debugPrint('Port tapped: ${port.id} (${port.name})');
    // Handle port mode toggle for Add/Replace mode
    if (port.direction == core_port.PortDirection.output) {
      _handlePortModeToggle(port);
    }
  }

  void _handlePortDragStart(core_port.Port port) {
    debugPrint('Port drag start: ${port.id} (${port.name})');
    final portPosition = _getPortPosition(port.id);
    if (portPosition != null) {
      _dragHandler.startDrag(port, portPosition);
    }
  }

  void _handlePortDragUpdate(core_port.Port port, Offset position) {
    _dragHandler.updateDrag(position);
  }

  void _handlePortDragEnd(core_port.Port port, Offset position) {
    // Find target port at drop position
    final targetPort = _findPortAtPosition(position);
    _dragHandler.endDrag(targetPort);
  }

  void _handleNodeTap(String nodeId) {
    debugPrint('Node tapped: $nodeId');
    // Handle node selection
    setState(() {
      if (_selectedNodes.contains(nodeId)) {
        _selectedNodes.remove(nodeId);
      } else {
        _selectedNodes.add(nodeId);
      }
    });
    widget.onNodeSelected?.call(nodeId);
  }

  // Drag handler callbacks
  void _onDragStart(core_port.Port sourcePort, Offset startPosition) {
    setState(() {
      _isDraggingConnection = true;
      _dragPosition = startPosition;
    });
    debugPrint('Drag started from port: ${sourcePort.name}');
  }

  void _onDragUpdate(Offset currentPosition, bool isValidDrop) {
    setState(() {
      _dragPosition = currentPosition;
    });
  }

  void _onDragEnd(core_port.Port sourcePort, core_port.Port? targetPort) {
    setState(() {
      _isDraggingConnection = false;
      _dragPosition = null;
    });

    if (targetPort != null) {
      // Validate the connection using the validator
      final routingState = context.read<RoutingEditorCubit>().state;
      if (routingState is RoutingEditorStateLoaded) {
        final validation = InteractiveConnectionValidator.validateConnectionCreation(
          sourcePort: sourcePort,
          targetPort: targetPort,
          currentState: routingState,
          isDragOperation: true,
        );

        if (validation.isValid) {
          // Normalize connection (ensure output -> input direction)
          final (source, target) = _dragHandler.normalizeConnection(sourcePort, targetPort);
          _createOptimisticConnectionWithValidation(source, target);
          debugPrint('Connection created: ${source.name} -> ${target.name}');
          
          // Show warning if present
          if (validation.warningMessage != null) {
            _showConnectionWarning(validation.warningMessage!);
          }
        } else {
          // Show validation error
          _showConnectionError(validation.errorMessage!, validation.suggestions);
          debugPrint('Connection validation failed: ${validation.errorMessage}');
        }
      }
    } else {
      debugPrint('Invalid connection or no target port');
    }
  }

  void _onDragCancel() {
    setState(() {
      _isDraggingConnection = false;
      _dragPosition = null;
    });
    debugPrint('Drag cancelled');
  }

  // Port mode toggle for Add/Replace functionality
  void _handlePortModeToggle(core_port.Port port) {
    final cubit = context.read<RoutingEditorCubit>();
    final currentMode = cubit.getPortOutputMode(port.id);
    final newMode = currentMode == core_port.OutputMode.add 
        ? core_port.OutputMode.replace 
        : core_port.OutputMode.add;
    
    cubit.setPortOutputMode(portId: port.id, outputMode: newMode);
    debugPrint('Port ${port.name} mode toggled to: $newMode');
    
    // Show visual feedback
    PortModeSnackbar.show(
      context,
      portName: port.name,
      newMode: newMode,
    );
  }

  // Create optimistic connection through cubit (legacy method for backward compatibility)

  // Create optimistic connection with validation and bus assignment
  void _createOptimisticConnectionWithValidation(core_port.Port sourcePort, core_port.Port targetPort) {
    // Create temporary connection for bus assignment
    final tempConnection = Connection(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      sourcePortId: sourcePort.id,
      destinationPortId: targetPort.id,
      connectionType: _determineConnectionTypeFromPorts(sourcePort, targetPort),
    );

    // Assign bus automatically
    final assignedBus = _busManager.assignBus(tempConnection, sourcePort, targetPort);
    
    final cubit = context.read<RoutingEditorCubit>();
    cubit.createConnectionOptimistic(
      sourcePortId: sourcePort.id,
      targetPortId: targetPort.id,
      busId: assignedBus?.toString(),
    );
    
    widget.onConnectionCreated?.call(sourcePort.id, targetPort.id);

    // Show bus assignment feedback
    if (assignedBus != null) {
      _showBusAssignmentFeedback(sourcePort.name, targetPort.name, assignedBus);
    }
  }

  // Determine connection type from ports
  ConnectionType _determineConnectionTypeFromPorts(core_port.Port sourcePort, core_port.Port targetPort) {
    final isSourceHardware = sourcePort.id.startsWith('hw_');
    final isTargetHardware = targetPort.id.startsWith('hw_');
    
    if (isSourceHardware && !isTargetHardware) {
      return ConnectionType.hardwareInput;
    } else if (!isSourceHardware && isTargetHardware) {
      return ConnectionType.hardwareOutput;
    } else {
      return ConnectionType.algorithmToAlgorithm;
    }
  }

  // Show connection validation error
  void _showConnectionError(String error, List<String> suggestions) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(error, style: const TextStyle(fontWeight: FontWeight.w500))),
              ],
            ),
            if (suggestions.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...suggestions.map((suggestion) => Padding(
                padding: const EdgeInsets.only(left: 28),
                child: Text('• $suggestion', style: const TextStyle(fontSize: 12)),
              )),
            ],
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        ),
      ),
    );
  }

  // Show connection validation warning
  void _showConnectionWarning(String warning) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.black87, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(warning, style: const TextStyle(color: Colors.black87))),
          ],
        ),
        backgroundColor: Colors.orange.shade300,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Show bus assignment feedback
  void _showBusAssignmentFeedback(String sourceName, String targetName, int busNumber) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.cable, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Connection created: $sourceName → $targetName (Bus $busNumber)',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Find port at given position for drop detection
  core_port.Port? _findPortAtPosition(Offset position) {
    const double portRadius = 15.0; // Port hit detection radius
    
    final routingState = context.read<RoutingEditorCubit>().state;
    if (routingState is! RoutingEditorStateLoaded) return null;

    // Check all ports for proximity to the drop position
    for (final algorithm in routingState.algorithms) {
      for (final port in [...algorithm.inputPorts, ...algorithm.outputPorts]) {
        final portPosition = _getPortPosition(port.id);
        if (portPosition != null && (portPosition - position).distance <= portRadius) {
          // Convert UI Port to core_port.Port
          return core_port.Port(
            id: port.id,
            name: port.name,
            type: _toCorePortType(port.type),
            direction: port.direction == PortDirection.input 
                ? core_port.PortDirection.input 
                : core_port.PortDirection.output,
            busValue: port.busNumber,
            busParam: port.parameterName,
          );
        }
      }
    }

    // Check physical ports
    for (final port in [...routingState.physicalInputs, ...routingState.physicalOutputs]) {
      final portPosition = _getPortPosition(port.id);
      if (portPosition != null && (portPosition - position).distance <= portRadius) {
        // Convert UI Port to core_port.Port
        return core_port.Port(
          id: port.id,
          name: port.name,
          type: _toCorePortType(port.type),
          direction: port.direction == PortDirection.input 
              ? core_port.PortDirection.input 
              : core_port.PortDirection.output,
          busValue: port.busNumber,
          busParam: port.parameterName,
        );
      }
    }

    return null;
  }

  /// Convert UI PortType to core PortType
  core_port.PortType _toCorePortType(PortType type) {
    switch (type) {
      case PortType.audio:
        return core_port.PortType.audio;
      case PortType.cv:
        return core_port.PortType.cv;
      case PortType.gate:
        return core_port.PortType.gate;
      case PortType.trigger:
        return core_port.PortType.gate; // Map trigger to gate for compatibility
    }
  }

  // Connection deletion callbacks
  void _onDeleteConnection(String connectionId) {
    final cubit = context.read<RoutingEditorCubit>();
    cubit.deleteConnectionOptimistic(connectionId);
    widget.onConnectionRemoved?.call(connectionId);
    
    // Show feedback
    ConnectionDeleteSnackbar.show(
      context,
      message: 'Connection deleted',
      // TODO: Implement undo functionality
    );
  }

  void _onConnectionHoverChanged(String connectionId, bool isHovered, Offset position) {
    // Trigger rebuild to show/hide delete icon
    setState(() {
      // State will be reflected in the deletion handler
    });
  }

  void _onShowDeleteConfirmation(String connectionId) async {
    final routingState = context.read<RoutingEditorCubit>().state;
    if (routingState is! RoutingEditorStateLoaded) return;

    // Find the connection
    final connection = routingState.connections.firstWhere(
      (conn) => conn.id == connectionId,
      orElse: () => throw ArgumentError('Connection not found: $connectionId'),
    );

    // Get port names for better UX
    final sourcePort = _findPortByIdInState(routingState, connection.sourcePortId);
    final targetPort = _findPortByIdInState(routingState, connection.destinationPortId);

    // Show confirmation dialog
    final confirmed = await ConnectionDeleteDialog.show(
      context,
      connection: connection,
      sourcePortName: sourcePort?.name,
      targetPortName: targetPort?.name,
    );

    if (confirmed == true) {
      _deletionHandler.confirmDeletion();
    } else {
      _deletionHandler.cancelDeletion();
    }
  }

  void _onHideDeleteConfirmation() {
    // Hide any active confirmation UI if needed
    setState(() {
      // Confirmation dialog is already dismissed
    });
  }

  // Helper to find port by ID in current state
  Port? _findPortByIdInState(RoutingEditorStateLoaded state, String portId) {
    // Check physical inputs
    for (final port in state.physicalInputs) {
      if (port.id == portId) return port;
    }

    // Check physical outputs
    for (final port in state.physicalOutputs) {
      if (port.id == portId) return port;
    }

    // Check algorithm ports
    for (final algorithm in state.algorithms) {
      for (final port in algorithm.inputPorts) {
        if (port.id == portId) return port;
      }
      for (final port in algorithm.outputPorts) {
        if (port.id == portId) return port;
      }
    }

    return null;
  }

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
      if (prev.sourcePortId != curr.sourcePortId || 
          prev.destinationPortId != curr.destinationPortId ||
          prev.outputMode != curr.outputMode ||
          prev.gain != curr.gain ||
          prev.isMuted != curr.isMuted ||
          prev.busNumber != curr.busNumber ||
          prev.busLabel != curr.busLabel) {
        return true;
      }
    }
    
    // Check physical connections for changes
    
    return false;
  }

  // Algorithm operation handlers
  void _handleAlgorithmMoveUp(int algorithmIndex) {
    final cubit = context.read<DistingCubit>();
    cubit.moveAlgorithmUp(algorithmIndex);
  }

  void _handleAlgorithmMoveDown(int algorithmIndex) {
    final cubit = context.read<DistingCubit>();
    cubit.moveAlgorithmDown(algorithmIndex);
  }

  void _handleAlgorithmDelete(int algorithmIndex) {
    final cubit = context.read<DistingCubit>();
    cubit.onRemoveAlgorithm(algorithmIndex);
  }

  Offset? _getPortPosition(String portId) {
    // First check if we have a stored position from the actual widget
    if (_portPositions.containsKey(portId)) {
      return _portPositions[portId];
    }
    
    // Fallback to calculating port positions based on algorithm positions and port indices
    // This is synchronous and doesn't depend on widget measurement
    
    final routingState = context.read<RoutingEditorCubit>().state;
    if (routingState is! RoutingEditorStateLoaded) return null;
    
    // Check physical inputs (hw_in_1 through hw_in_12)
    if (portId.startsWith('hw_in_')) {
      final inputNum = int.tryParse(portId.substring(6));
      if (inputNum != null && inputNum >= 1 && inputNum <= 12) {
        // Physical inputs are on the left side
        const double centerX = _canvasWidth / 2;
        const double centerY = _canvasHeight / 2;
        final nodePos = _nodePositions['physical_inputs'] ?? const Offset(centerX - 800, centerY - 300);
        // Physical input node width is ~150px, ports are on the right edge
        final portOffset = Offset(150, 50 + (inputNum - 1) * 30); // Stack vertically
        return Offset(nodePos.dx + portOffset.dx, nodePos.dy + portOffset.dy);
      }
    }
    
    // Check physical outputs (hw_out_1 through hw_out_8)
    if (portId.startsWith('hw_out_')) {
      final outputNum = int.tryParse(portId.substring(7));
      if (outputNum != null && outputNum >= 1 && outputNum <= 8) {
        // Physical outputs are on the right side
        const double centerX = _canvasWidth / 2;
        const double centerY = _canvasHeight / 2;
        final nodePos = _nodePositions['physical_outputs'] ?? const Offset(centerX + 600, centerY - 300);
        // Physical output node ports are on the left edge
        final portOffset = Offset(0, 50 + (outputNum - 1) * 30); // Stack vertically
        return Offset(nodePos.dx + portOffset.dx, nodePos.dy + portOffset.dy);
      }
    }
    
    // Skip virtual bus endpoint positions - we handle these differently for partial connections
    if (portId.startsWith('bus_') && portId.endsWith('_endpoint')) {
      // Return null for virtual bus endpoints - they shouldn't be used directly
      return null;
    }
    
    for (final algo in routingState.algorithms) {
      // Check inputs
      final inputIndex = algo.inputPorts.indexWhere((p) => p.id == portId);
      if (inputIndex != -1) {
        final nodeId = algo.id;
        final nodePos = _nodePositions[nodeId];
        if (nodePos != null) {
          // Calculate position based on index
          // Header is ~40px, each port is ~35px height
          // Adjust for the actual port center position
          final portOffset = Offset(0, 50 + inputIndex * 35);
          return Offset(nodePos.dx + portOffset.dx, nodePos.dy + portOffset.dy);
        }
      }
      
      // Check outputs  
      final outputIndex = algo.outputPorts.indexWhere((p) => p.id == portId);
      if (outputIndex != -1) {
        final nodeId = algo.id;
        final nodePos = _nodePositions[nodeId];
        if (nodePos != null) {
          // Outputs are on the right edge (assuming 300px width)
          // Adjust for the actual port center position
          final portOffset = Offset(300, 50 + outputIndex * 35);
          return Offset(nodePos.dx + portOffset.dx, nodePos.dy + portOffset.dy);
        }
      }
    }
    
    return null;
  }



  /// Create a theme for a specific algorithm connection type

  void _updatePortAnchor(String portId, Offset globalCenter) {
    final ctx = _canvasKey.currentContext;
    if (ctx == null) return;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null || !box.attached) return;
    final local = box.globalToLocal(globalCenter);
    // Check if position has changed significantly
    final existingPosition = _portPositions[portId];
    final needsUpdate = existingPosition == null || (existingPosition - local).distance > 1.0;
    
    if (needsUpdate) {
      // Store port position
      _portPositions[portId] = local;
      
      // If ports aren't ready yet, check if we have enough positions to start rendering
      if (!_portsReady && _portPositions.isNotEmpty) {
        // Delay slightly to collect all port positions in the same frame
        Future.microtask(() {
          if (mounted && !_portsReady) {
            setState(() {
              _portsReady = true;
            });
          }
        });
      } else if (_portsReady) {
        // After initial setup, update immediately
        setState(() {});
      }
    }
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
