import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nt_helper/cubit/routing_editor_cubit.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/core/routing/models/port.dart' as core_port;
// Haptics can be reintroduced later if needed
import 'package:nt_helper/ui/widgets/routing/connection_painter.dart';
import 'package:nt_helper/ui/widgets/routing/connection_theme.dart';
import 'package:nt_helper/ui/widgets/routing/algorithm_node_widget.dart';
import 'package:nt_helper/ui/widgets/routing/physical_input_node.dart';
import 'package:nt_helper/ui/widgets/routing/physical_output_node.dart';
// Removed unused imports from previous canvas split
import 'package:nt_helper/ui/widgets/routing/connection_validator.dart';
import 'package:nt_helper/models/physical_connection.dart';
import 'package:nt_helper/models/algorithm_connection.dart';

/// RoutingEditorWidget is the canonical widget for the routing editor UI.
/// It composes the routing canvas and exposes the same API for compatibility.
class RoutingEditorWidget extends StatefulWidget {
  final Object? routingFactory; // ignored (decisions in cubit)
  final Size canvasSize;
  final bool showPhysicalPorts;
  final bool showBusLabels;
  final Function(String nodeId)? onNodeSelected;
  final Function(String sourcePortId, String targetPortId)? onConnectionCreated;
  final Function(String connectionId)? onConnectionRemoved;

  RoutingEditorWidget({
    super.key,
    this.routingFactory,
    this.canvasSize = const Size(1200, 800),
    this.showPhysicalPorts = true,
    bool? showBusLabels,
    this.onNodeSelected,
    this.onConnectionCreated,
    this.onConnectionRemoved,
  }) : showBusLabels = showBusLabels ?? (canvasSize.width >= 800);

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
    
    // Center the view on the canvas after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _centerCanvas();
      // Give ports time to register their positions
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          setState(() {
            _portsReady = true;
          });
        }
      });
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
    // Physical port anchors are resolved dynamically by measuring widgets
    // Algorithm nodes in the center area
    const double algorithmStartX = centerX - 250;
    const double algorithmSpacing = 300.0;
    const double algorithmRowSpacing = 200.0;
    for (int i = 0; i < 8; i++) {
      final column = i % 2;
      final row = i ~/ 2;
      _nodePositions['algorithm_$i'] = Offset(
        algorithmStartX + (column * algorithmSpacing),
        centerY - 300 + (row * algorithmRowSpacing),
      );
    }
  }

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    _verticalScrollController.dispose();
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
      loaded: (physicalInputs, physicalOutputs, algorithms, connections, physicalConnections, algorithmConnections, buses, portOutputModes, isHardwareSynced, isPersistenceEnabled, lastSyncTime, lastPersistTime, lastError) =>
          _buildLoadedCanvas(context, physicalInputs, physicalOutputs, algorithms, connections, physicalConnections, algorithmConnections),
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
    List<PhysicalConnection> physicalConnections,
    List<AlgorithmConnection> algorithmConnections,
  ) {
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
                // Draw connections above nodes so they appear to emanate from ports
                if (physicalConnections.isNotEmpty)
                  IgnorePointer(
                    ignoring: true,
                    child: _buildPhysicalConnectionCanvas(physicalConnections),
                  ),
                if (algorithmConnections.isNotEmpty && _portsReady)
                  IgnorePointer(
                    ignoring: true,
                    child: _buildAlgorithmConnectionCanvas(algorithmConnections),
                  ),
                if (connections.isNotEmpty)
                  IgnorePointer(
                    ignoring: true,
                    child: _buildConnectionCanvas(connections),
                  ),
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
    final nodePosition = Offset(centerX - 800, centerY - 300);
    
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
          onPortPositionResolved: (port, globalCenter) {
            _updatePortAnchor(port.id, globalCenter);
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
    final nodePosition = Offset(centerX + 600, centerY - 300);
    
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
          onPortPositionResolved: (port, globalCenter) {
            _updatePortAnchor(port.id, globalCenter);
          },
        ),
      ),
    ];
  }

  List<Widget> _buildAlgorithmNodes(List<RoutingAlgorithm> algorithms) {
    return algorithms.map((algorithm) {
      final nodeId = 'algorithm_${algorithm.index}';
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
          key: ValueKey('algorithm_widget_${algorithm.index}'),
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

  Widget _buildConnectionCanvas(List<Connection> connections) {
    // Get the current state to access bus numbers and output modes
    final state = context.read<RoutingEditorCubit>().state;
    Map<String, int> busNumbers = {};
    Map<String, String> outputModes = {};
    
    if (state is RoutingEditorStateLoaded) {
      // Convert buses list to a map of port ID to bus number
      for (int i = 0; i < state.buses.length; i++) {
        final bus = state.buses[i];
        for (final connectionId in bus.connectionIds) {
          // Extract port ID from connection ID if needed
          busNumbers[connectionId] = i + 1; // Bus numbers are 1-indexed
        }
      }
      
      // Convert OutputMode enum to string
      outputModes = state.portOutputModes.map((key, value) => 
        MapEntry(key, value == OutputMode.mix ? 'mix' : 'replace'));
    }
    
    // Create ConnectionData objects for each connection
    final connectionDataList = <ConnectionData>[];
    for (final connection in connections) {
      final sourcePosition = _getPortPosition(connection.sourcePortId);
      final targetPosition = _getPortPosition(connection.targetPortId);
      if (sourcePosition == null || targetPosition == null) continue;
      
      final sourcePort = _findPortById(connection.sourcePortId);
      final targetPort = _findPortById(connection.targetPortId);
      
      // Convert to routing.Connection for ConnectionData
      final routingConnection = Connection(
        id: '${connection.sourcePortId}->${connection.targetPortId}',
        sourcePortId: connection.sourcePortId,
        targetPortId: connection.targetPortId,
        isGhostConnection: sourcePort != null && targetPort != null 
            ? ConnectionValidator.isGhostConnection(sourcePort, targetPort)
            : false,
      );
      
      connectionDataList.add(ConnectionData(
        connection: routingConnection,
        sourcePosition: sourcePosition,
        destinationPosition: targetPosition,
        busNumber: busNumbers[connection.sourcePortId],
        outputMode: outputModes[connection.sourcePortId],
        isSelected: _selectedConnectionId == routingConnection.id,
        isHighlighted: false,
      ));
    }
    
    // Create theme and state manager
    final theme = Theme.of(context);
    final connectionTheme = ConnectionVisualTheme.fromColorScheme(theme.colorScheme);
    final stateManager = ConnectionStateManager(
      theme: connectionTheme,
      selectedConnectionIds: _selectedConnectionId != null ? {_selectedConnectionId!} : {},
    );
    
    // Return ConnectionCanvas widget
    return ConnectionCanvas(
      connections: connectionDataList,
      connectionStateManager: stateManager,
      enableAntiOverlap: true,
      showLabels: true,
      enableAnimations: true,
      onConnectionTapped: (connectionData) {
        _handleConnectionTap(connectionData.connection.id);
      },
    );
  }

  Widget _buildPhysicalConnectionCanvas(List<PhysicalConnection> physicalConnections) {
    // Convert PhysicalConnection objects to ConnectionData for rendering
    final connectionDataList = <ConnectionData>[];
    
    for (final physicalConnection in physicalConnections) {
      final sourcePosition = _getPortPosition(physicalConnection.sourcePortId);
      final targetPosition = _getPortPosition(physicalConnection.targetPortId);
      if (sourcePosition == null || targetPosition == null) continue;
      
      // Convert PhysicalConnection to routing.Connection for ConnectionData
      final routingConnection = Connection(
        id: physicalConnection.id,
        sourcePortId: physicalConnection.sourcePortId,
        targetPortId: physicalConnection.targetPortId,
        isGhostConnection: false, // Physical connections are solid, not ghost
      );
      
      connectionDataList.add(ConnectionData(
        connection: routingConnection,
        sourcePosition: sourcePosition,
        destinationPosition: targetPosition,
        busNumber: physicalConnection.busNumber,
        outputMode: null, // Physical connections ignore output mode styling
        isSelected: false, // Physical connections are never selected
        isHighlighted: false,
        isPhysicalConnection: true, // Mark as physical connection
        isInputConnection: physicalConnection.isInputConnection, // Pass input/output info
      ));
    }
    
    if (connectionDataList.isEmpty) return const SizedBox.shrink();
    
    // Create a custom theme for physical connections with distinct colors
    final theme = Theme.of(context);
    final physicalConnectionTheme = ConnectionVisualTheme.fromColorScheme(
      theme.colorScheme.copyWith(
        primary: Colors.blue,      // Use blue for input connections
        secondary: Colors.green,   // Use green for output connections  
        tertiary: Colors.blueGrey, // Use blue-grey for mixed connections
      ),
    );
    
    final stateManager = ConnectionStateManager(
      theme: physicalConnectionTheme,
      selectedConnectionIds: {}, // Physical connections are never selected
    );
    
    // Return ConnectionCanvas widget with physical connection styling
    return ConnectionCanvas(
      connections: connectionDataList,
      connectionStateManager: stateManager,
      enableAntiOverlap: true,
      showLabels: widget.showBusLabels, // Show I#/O# labels based on widget parameter
      enableAnimations: false, // Physical connections don't need animations
      onConnectionTapped: null, // Physical connections are not interactive
    );
  }
  
  Widget _buildAlgorithmConnectionCanvas(List<AlgorithmConnection> algorithmConnections) {
    if (algorithmConnections.isEmpty) return const SizedBox.shrink();
    
    // Group connections by execution order direction for different styling
    final forwardConnections = <AlgorithmConnection>[];
    final backwardConnections = <AlgorithmConnection>[];
    
    for (final connection in algorithmConnections) {
      if (connection.isBackwardEdge) {
        backwardConnections.add(connection);
      } else {
        forwardConnections.add(connection);
      }
    }
    
    // Create a stack of connection canvases: backward edges (red) on top of forward edges
    final canvasLayers = <Widget>[];
    
    // Add forward connections first (normal colors, bottom layer)
    if (forwardConnections.isNotEmpty) {
      canvasLayers.add(_buildConnectionLayer(forwardConnections, isBackwardEdge: false));
    }
    
    // Add backward connections on top (red highlighting, top layer)
    if (backwardConnections.isNotEmpty) {
      canvasLayers.add(_buildConnectionLayer(backwardConnections, isBackwardEdge: true));
    }
    
    return Stack(children: canvasLayers);
  }
  
  /// Build a connection layer for a group of connections with consistent styling
  Widget _buildConnectionLayer(List<AlgorithmConnection> connections, {required bool isBackwardEdge}) {
    // Group by connection type within this execution order group
    final connectionsByType = <AlgorithmConnectionType, List<AlgorithmConnection>>{};
    for (final connection in connections) {
      connectionsByType.putIfAbsent(connection.connectionType, () => []).add(connection);
    }
    
    final typeCanvasLayers = <Widget>[];
    
    for (final entry in connectionsByType.entries) {
      final connectionType = entry.key;
      final connectionsOfType = entry.value;
      
      final connectionDataList = <ConnectionData>[];
      
      debugPrint('_buildConnectionLayer: Processing ${connectionsOfType.length} connections of type ${connectionsOfType.first.connectionType}');
      
      for (final algorithmConnection in connectionsOfType) {
        // Handle physical output connections differently
        if (algorithmConnection.isPhysicalOutput) {
          // Algorithm to physical output connection
          // Use the port ID directly from the connection
          final sourcePortId = algorithmConnection.sourcePortId;
          
          final sourcePosition = _getPortPosition(sourcePortId);
          final targetPosition = _getPhysicalOutputPosition(algorithmConnection.busNumber);
          
          if (sourcePosition == null || targetPosition == null) {
            debugPrint('AlgorithmConnection: Could not resolve positions for physical output ${algorithmConnection.id}');
            debugPrint('  Source port $sourcePortId position: $sourcePosition');
            debugPrint('  Target bus ${algorithmConnection.busNumber} position: $targetPosition');
            continue;
          }
          
          // Convert to routing.Connection for rendering
          final routingConnection = Connection(
            id: algorithmConnection.id,
            sourcePortId: sourcePortId,
            targetPortId: 'physical_output_${algorithmConnection.busNumber}',
            isGhostConnection: !algorithmConnection.isValid,
          );
          
          connectionDataList.add(ConnectionData(
            connection: routingConnection,
            sourcePosition: sourcePosition,
            destinationPosition: targetPosition,
            busNumber: algorithmConnection.busNumber,
            outputMode: null,
            isSelected: false,
            isHighlighted: false,
            isPhysicalConnection: false, // This is an algorithm connection to physical output
            isInputConnection: null,
          ));
        } else {
          // Algorithm to algorithm connection
          // The port IDs in AlgorithmConnection are the actual port IDs from the BusRegistry
          debugPrint('AlgorithmConnection: Processing ${algorithmConnection.id} - source: algo${algorithmConnection.sourceAlgorithmIndex}:${algorithmConnection.sourcePortId} -> target: algo${algorithmConnection.targetAlgorithmIndex}:${algorithmConnection.targetPortId}');
          
          // Use the port IDs directly - they're already the correct ones from BusRegistry
          final sourcePortId = algorithmConnection.sourcePortId;
          final targetPortId = algorithmConnection.targetPortId;
          
          debugPrint('Looking for positions: source=$sourcePortId, target=$targetPortId');
          debugPrint('  Source algo ${algorithmConnection.sourceAlgorithmIndex}, Target algo ${algorithmConnection.targetAlgorithmIndex}');
          
          final sourcePosition = _getPortPosition(sourcePortId);
          final targetPosition = _getPortPosition(targetPortId);
          if (sourcePosition == null || targetPosition == null) {
            debugPrint('AlgorithmConnection: Could not resolve positions for ${algorithmConnection.id}');
            debugPrint('  Source port $sourcePortId position: $sourcePosition');
            debugPrint('  Target port $targetPortId position: $targetPosition');
            
            // Debug: print what ports are available for these algorithms
            final routingState = context.read<RoutingEditorCubit>().state;
            if (routingState is RoutingEditorStateLoaded) {
              final sourceAlgo = routingState.algorithms.firstWhere(
                (a) => a.index == algorithmConnection.sourceAlgorithmIndex,
                orElse: () => throw Exception('Source algo not found'),
              );
              final targetAlgo = routingState.algorithms.firstWhere(
                (a) => a.index == algorithmConnection.targetAlgorithmIndex, 
                orElse: () => throw Exception('Target algo not found'),
              );
              debugPrint('  Available output ports on source algo: ${sourceAlgo.outputPorts.map((p) => p.id).join(", ")}');
              debugPrint('  Available input ports on target algo: ${targetAlgo.inputPorts.map((p) => p.id).join(", ")}');
            }
            continue;
          }
          
          // Convert AlgorithmConnection to routing.Connection for ConnectionData
          final routingConnection = Connection(
            id: algorithmConnection.id,
            sourcePortId: sourcePortId,
            targetPortId: targetPortId,
            isGhostConnection: !algorithmConnection.isValid, // Invalid connections are ghost/dashed
          );
          
          connectionDataList.add(ConnectionData(
            connection: routingConnection,
            sourcePosition: sourcePosition,
            destinationPosition: targetPosition,
            busNumber: algorithmConnection.busNumber,
            outputMode: null, // Algorithm connections use standard styling
            isSelected: false, // Algorithm connections are not selectable for now
            isHighlighted: false,
            isPhysicalConnection: false, // This is an algorithm connection
            isInputConnection: null, // Not applicable for algorithm connections
          ));
        }
      }
      
      if (connectionDataList.isNotEmpty) {
        // Create execution order and type-specific connection theme
        final connectionTheme = isBackwardEdge 
            ? _createBackwardEdgeTheme(connectionsOfType)
            : _createConnectionThemeForType(connectionType);
        
        // Create state manager for this connection type
        final stateManager = ConnectionStateManager(
          theme: connectionTheme,
          selectedConnectionIds: {}, // Algorithm connections are not selectable for now
        );
        
        // Add canvas layer for this connection type
        typeCanvasLayers.add(
          ConnectionCanvas(
            connections: connectionDataList,
            connectionStateManager: stateManager,
            enableAntiOverlap: true,
            showLabels: widget.showBusLabels, // Show bus labels based on widget parameter
            enableAnimations: true, // Algorithm connections support animations
            onConnectionTapped: null, // Algorithm connections are not interactive for now
          ),
        );
      }
    }
    
    // Return a stack of connection canvases for different types within this execution order group
    return Stack(children: typeCanvasLayers);
  }

  Widget _buildTemporaryConnection() {
    if (_connectionSourcePortId == null || _dragPosition == null) {
      return const SizedBox.shrink();
    }
    final sourcePosition = _getPortPosition(_connectionSourcePortId!);
    if (sourcePosition == null) return const SizedBox.shrink();
    
    // Create a temporary connection for preview
    final tempConnection = Connection(
      id: 'temp_connection',
      sourcePortId: _connectionSourcePortId!,
      targetPortId: 'temp_target',
      isGhostConnection: true, // Show as dashed line during drag
    );
    
    final connectionData = ConnectionData(
      connection: tempConnection,
      sourcePosition: sourcePosition,
      destinationPosition: _dragPosition!,
      isHighlighted: true,
    );
    
    // Use ConnectionPainter directly for the temporary connection
    return CustomPaint(
      painter: ConnectionPainter(
        connections: [connectionData],
        theme: Theme.of(context),
        enableAntiOverlap: false,
        showLabels: false,
        enableAnimations: true,
        animationProgress: 1.0,
      ),
      child: const SizedBox.expand(),
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

  
  // Original event handlers (removed unused canvas tap/drag stubs)
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
        previous.connections.length != current.connections.length ||
        previous.physicalConnections.length != current.physicalConnections.length) {
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
    
    // Check physical connections for changes
    if (previous.physicalConnections.length != current.physicalConnections.length) return true;
    for (int i = 0; i < current.physicalConnections.length; i++) {
      if (i >= previous.physicalConnections.length) return true;
      final prev = previous.physicalConnections[i];
      final curr = current.physicalConnections[i];
      if (prev.id != curr.id || 
          prev.sourcePortId != curr.sourcePortId || 
          prev.targetPortId != curr.targetPortId ||
          prev.busNumber != curr.busNumber ||
          prev.algorithmIndex != curr.algorithmIndex) {
        return true;
      }
    }
    
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
    // Algorithm ports
    for (final algo in state.algorithms) {
      for (final p in algo.inputPorts) {
        if (p.id == portId) {
          return core_port.Port(
            id: p.id,
            name: p.name,
            type: _mapUiToCoreType(p.type),
            direction: core_port.PortDirection.input,
          );
        }
      }
      for (final p in algo.outputPorts) {
        if (p.id == portId) {
          return core_port.Port(
            id: p.id,
            name: p.name,
            type: _mapUiToCoreType(p.type),
            direction: core_port.PortDirection.output,
          );
        }
      }
    }
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
    // Always calculate port positions based on algorithm positions and port indices
    // This is synchronous and doesn't depend on widget measurement
    
    final routingState = context.read<RoutingEditorCubit>().state;
    if (routingState is! RoutingEditorStateLoaded) return null;
    
    for (final algo in routingState.algorithms) {
      // Check inputs
      final inputIndex = algo.inputPorts.indexWhere((p) => p.id == portId);
      if (inputIndex != -1) {
        final nodeId = 'algorithm_${algo.index}';
        final nodePos = _nodePositions[nodeId];
        if (nodePos != null) {
          // Calculate position based on index
          // Header is ~40px, each port is ~28px with 4px padding
          final portOffset = Offset(12, 50 + inputIndex * 32);
          return Offset(nodePos.dx + portOffset.dx, nodePos.dy + portOffset.dy);
        }
      }
      
      // Check outputs  
      final outputIndex = algo.outputPorts.indexWhere((p) => p.id == portId);
      if (outputIndex != -1) {
        final nodeId = 'algorithm_${algo.index}';
        final nodePos = _nodePositions[nodeId];
        if (nodePos != null) {
          // Outputs are on the right edge (assuming 300px width)
          final portOffset = Offset(288, 50 + outputIndex * 32);
          return Offset(nodePos.dx + portOffset.dx, nodePos.dy + portOffset.dy);
        }
      }
    }
    
    return null;
  }


  /// Get the position for a physical output based on bus number
  Offset? _getPhysicalOutputPosition(int busNumber) {
    // Physical outputs use bus numbers to determine which output port
    // For buses 13-20: map to physical outputs O1-O8
    if (busNumber >= 13 && busNumber <= 20) {
      final outputIndex = busNumber - 13; // Convert to 0-7 index
      final outputPortId = 'output_${outputIndex + 1}'; // O1, O2, ... O8
      return _getPortPosition(outputPortId);
    }
    
    // For other bus numbers, try direct mapping to physical outputs
    // This handles cases where algorithms output directly to numbered buses
    final physicalOutputId = 'physical_output_$busNumber';
    final position = _getPortPosition(physicalOutputId);
    if (position != null) {
      return position;
    }
    
    // Fallback: try to find any physical output port
    final outputPortId = 'output_$busNumber';
    return _getPortPosition(outputPortId);
  }

  /// Create a theme for a specific algorithm connection type
  ConnectionVisualTheme _createConnectionThemeForType(AlgorithmConnectionType connectionType) {
    final theme = Theme.of(context);
    final connectionColor = _getConnectionTypeColor(connectionType);
    
    // Create base theme with type-specific styling
    return ConnectionVisualTheme(
      // Valid connections: styled with type-specific color
      directConnection: ConnectionStyle(
        strokeWidth: 2.5, // Slightly thicker than regular connections for prominence
        color: connectionColor,
        dashPattern: null, // Solid lines for valid connections
        animationEnabled: false,
        endpointRadius: 3.0,
        glowEffect: false,
      ),
      // Invalid connections: red, dashed (overrides type color)
      ghostConnection: ConnectionStyle(
        strokeWidth: 2.0,
        color: theme.colorScheme.error, // Red for invalid connections
        dashPattern: [8.0, 4.0], // Dashed pattern for invalid connections
        animationEnabled: true, // Subtle animation to draw attention
        endpointRadius: 2.5,
        glowEffect: true, // Glow effect for better visibility
      ),
      // Error connections (same as invalid for algorithm connections)
      errorConnection: ConnectionStyle(
        strokeWidth: 2.5,
        color: theme.colorScheme.error,
        dashPattern: [6.0, 3.0],
        animationEnabled: false,
        endpointRadius: 3.0,
        glowEffect: false,
      ),
      // Selected connections: highlighted with thicker stroke using type color
      selectedConnection: ConnectionStyle(
        strokeWidth: 3.5,
        color: connectionColor,
        dashPattern: null,
        animationEnabled: false,
        endpointRadius: 4.0,
        glowEffect: true,
      ),
      // Hover state: slightly thicker and brighter using type color
      highlightedConnection: ConnectionStyle(
        strokeWidth: 3.0,
        color: connectionColor.withValues(alpha: 0.8), // Slightly transparent for hover
        dashPattern: null,
        animationEnabled: false,
        endpointRadius: 3.5,
        glowEffect: false,
      ),
    );
  }

  /// Get color based on algorithm connection type
  Color _getConnectionTypeColor(AlgorithmConnectionType connectionType) {
    switch (connectionType) {
      case AlgorithmConnectionType.audioSignal:
        return Colors.orange; // Orange for audio signals
      case AlgorithmConnectionType.controlVoltage:
        return Colors.blue; // Blue for CV signals
      case AlgorithmConnectionType.gateTrigger:
        return Colors.green; // Green for gate/trigger signals
      case AlgorithmConnectionType.clockTiming:
        return Colors.purple; // Purple for clock signals
      case AlgorithmConnectionType.mixed:
        return Colors.grey; // Grey for mixed/unknown signals
    }
  }

  /// Create a theme for backward edges (execution order violations) with red highlighting
  /// and optional dashed pattern for invalid connections (self-connections)
  ConnectionVisualTheme _createBackwardEdgeTheme(List<AlgorithmConnection> connections) {
    final theme = Theme.of(context);
    final redColor = theme.colorScheme.error; // Red for backward edges
    
    // Check if any connections in this group are invalid (self-connections)
    final hasInvalidConnections = connections.any((conn) => !conn.isValid);
    final dashPattern = hasInvalidConnections ? [8.0, 4.0] : null; // Dashed for invalid connections
    
    return ConnectionVisualTheme(
      // Valid backward connections: solid red (execution order violation warning)
      directConnection: ConnectionStyle(
        strokeWidth: 2.5,
        color: redColor,
        dashPattern: dashPattern, // Solid for valid backward edges, dashed for invalid
        animationEnabled: hasInvalidConnections, // Animation for invalid connections
        endpointRadius: 3.0,
        glowEffect: hasInvalidConnections, // Glow effect for invalid connections
      ),
      // Invalid backward connections: dashed red (double violation: invalid + backward)
      ghostConnection: ConnectionStyle(
        strokeWidth: 2.0,
        color: redColor,
        dashPattern: [6.0, 3.0], // More pronounced dashing for invalid connections
        animationEnabled: true, // Animation to draw attention to problems
        endpointRadius: 2.5,
        glowEffect: true, // Glow effect for visibility
      ),
      // Error connections: same as ghost for algorithm connections
      errorConnection: ConnectionStyle(
        strokeWidth: 2.5,
        color: redColor,
        dashPattern: [6.0, 3.0],
        animationEnabled: false,
        endpointRadius: 3.0,
        glowEffect: false,
      ),
      // Selected backward connections: thicker red
      selectedConnection: ConnectionStyle(
        strokeWidth: 3.5,
        color: redColor,
        dashPattern: dashPattern,
        animationEnabled: false,
        endpointRadius: 4.0,
        glowEffect: true,
      ),
      // Hover state: slightly transparent red
      highlightedConnection: ConnectionStyle(
        strokeWidth: 3.0,
        color: redColor.withValues(alpha: 0.8),
        dashPattern: dashPattern,
        animationEnabled: false,
        endpointRadius: 3.5,
        glowEffect: false,
      ),
    );
  }

  void _updatePortAnchor(String portId, Offset globalCenter) {
    final ctx = _canvasKey.currentContext;
    if (ctx == null) return;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null || !box.attached) return;
    final local = box.globalToLocal(globalCenter);
    // Don't trigger unnecessary rebuilds if position hasn't changed significantly
    final existingPosition = _nodePositions[portId];
    if (existingPosition != null && (existingPosition - local).distance < 1.0) {
      return;
    }
    setState(() {
      _nodePositions[portId] = local;
    });
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
