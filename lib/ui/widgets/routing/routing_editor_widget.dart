import 'dart:async';
import 'dart:math' as math;
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nt_helper/cubit/routing_editor_cubit.dart';
import 'package:nt_helper/cubit/routing_editor_state.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/core/routing/models/port.dart';
import 'package:nt_helper/core/routing/models/connection.dart';
// Haptics can be reintroduced later if needed
import 'package:nt_helper/ui/widgets/routing/connection_painter.dart'
    as painter;
import 'package:nt_helper/core/platform/platform_interaction_service.dart';
import 'package:nt_helper/ui/widgets/routing/algorithm_node_widget.dart';
import 'package:nt_helper/ui/widgets/routing/physical_input_node.dart';
import 'package:nt_helper/ui/widgets/routing/physical_output_node.dart';
import 'package:nt_helper/ui/widgets/routing/mini_map_widget.dart';
import 'package:nt_helper/core/routing/node_layout_algorithm.dart';
// Removed unused imports from previous canvas split

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
  final PlatformInteractionService? platformService;

  RoutingEditorWidget({
    super.key,
    this.routingFactory,
    this.canvasSize = const Size(1200, 800),
    this.showPhysicalPorts = true,
    bool? showBusLabels,
    this.onNodeSelected,
    this.onConnectionCreated,
    this.onConnectionRemoved,
    this.platformService,
  }) : showBusLabels = showBusLabels ?? (canvasSize.width >= 800);

  @override
  State<RoutingEditorWidget> createState() => _RoutingEditorWidgetState();
}

class _RoutingEditorWidgetState extends State<RoutingEditorWidget> {
  final Map<String, Offset> _nodePositions = {};
  final Map<String, Offset> _portPositions = {}; // Store actual port positions
  final Set<String> _selectedNodes = {};

  // Drag state management for connection creation
  bool _isDraggingConnection = false;
  Port? _dragSourcePort;
  Offset? _dragCurrentPosition;
  String? _hoveredConnectionId; // For port hover (connection deletion)
  String? _hoveredLabelConnectionId; // For label hover (mode switching)
  String? _highlightedPortId; // For port highlighting during drag operations
  Timer? _connectionHighlightTimer;
  Set<String> _selectedPortConnectionIds =
      {}; // For mobile port tap confirmation

  // Error handling state
  String? _errorMessage;
  Timer? _errorDismissTimer;
  Timer? _dragUpdateDebounceTimer;

  // Platform service for hover detection
  late final PlatformInteractionService _platformService;

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
  bool _connectionsVisible = false; // Track connection visibility separately

  // Store the current connection label bounds for hit testing
  Map<String, Rect> _connectionLabelBounds = {};

  @override
  void initState() {
    super.initState();
    _platformService = widget.platformService ?? PlatformInteractionService();
    _horizontalScrollController = ScrollController();
    _verticalScrollController = ScrollController();

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
      _horizontalScrollController.jumpTo(
        (_canvasWidth - widget.canvasSize.width) / 2,
      );
    }
    if (_verticalScrollController.hasClients) {
      _verticalScrollController.jumpTo(
        (_canvasHeight - widget.canvasSize.height) / 2,
      );
    }
  }

  void _initializeNodePositions() {
    // Position nodes in the center area of the 5000x5000 canvas
    const double centerX = _canvasWidth / 2;
    const double centerY = _canvasHeight / 2;

    // Physical inputs on the left side (matching _buildPhysicalInputNodes)
    _nodePositions['physical_inputs'] = const Offset(
      centerX - 800,
      centerY - 300,
    );

    // Physical outputs on the right side (matching _buildPhysicalOutputNodes)
    _nodePositions['physical_outputs'] = const Offset(
      centerX + 600,
      centerY - 300,
    );

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
    _connectionHighlightTimer?.cancel();
    _errorDismissTimer?.cancel();
    _dragUpdateDebounceTimer?.cancel();
    _horizontalScrollController.dispose();
    _verticalScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RoutingEditorCubit, RoutingEditorState>(
      buildWhen: (previous, current) {
        final shouldRebuild =
            previous.runtimeType != current.runtimeType ||
            (previous is RoutingEditorStateLoaded &&
                current is RoutingEditorStateLoaded &&
                _hasLoadedStateChanged(previous, current));

        // Only clear port positions when the routing structure actually changes
        // This prevents flicker when state updates don't affect the visual layout
        if (shouldRebuild && current is RoutingEditorStateLoaded) {
          if (previous is! RoutingEditorStateLoaded ||
              _hasRoutingStructureChanged(previous, current)) {
            _portPositions.clear();
            _portsReady = false;
            _connectionsVisible = false;
          }
        }

        return shouldRebuild;
      },
      builder: (context, state) {
        return Stack(
          children: [
            Container(
              width: widget.canvasSize.width,
              height: widget.canvasSize.height,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border.all(color: Theme.of(context).dividerColor, width: 1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _platformService.isDesktopPlatform()
                    ? Focus(
                        onKeyEvent: (node, event) => _handleKeyEvent(event),
                        child: _buildCanvasContent(context, state),
                      )
                    : _buildCanvasContent(context, state),
              ),
            ),
            // MiniMapWidget positioned in bottom-right corner with 16px margin
            if (state is RoutingEditorStateLoaded)
              Positioned(
                bottom: 16.0,
                right: 16.0,
                child: MiniMapWidget(
                  horizontalScrollController: _horizontalScrollController,
                  verticalScrollController: _verticalScrollController,
                  canvasWidth: _canvasWidth,
                  canvasHeight: _canvasHeight,
                  nodePositions: _nodePositions,
                  connections: state.connections,
                  portPositions: _portPositions,
                ),
              ),
            // Error display widget in top-right corner (above mini-map in z-order)
            if (_errorMessage != null) _buildErrorDisplay(),
          ],
        );
      },
    );
  }

  /// Build dismissable error display widget
  Widget _buildErrorDisplay() {
    return Positioned(
      top: 8,
      right: 8,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 300),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).shadowColor.withValues(alpha: 0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 16,
              color: Theme.of(context).colorScheme.onErrorContainer,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                _errorMessage!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _dismissError,
              child: Icon(
                Icons.close,
                size: 16,
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Handle keyboard events for desktop platforms
  KeyEventResult _handleKeyEvent(KeyEvent event) {
    if (_platformService.isDesktopPlatform() && 
        event is KeyDownEvent && 
        event.logicalKey == LogicalKeyboardKey.escape) {
      
      // Cancel drag operation if in progress
      if (_isDraggingConnection) {
        _cancelDragOperation();
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  /// Cancel current drag operation
  void _cancelDragOperation() {
    debugPrint('=== DRAG CANCELLED: ESC key pressed');
    setState(() {
      _isDraggingConnection = false;
      _dragSourcePort = null;
      _dragCurrentPosition = null;
      _highlightedPortId = null;
    });
  }

  /// Display an error message with auto-dismiss after 5 seconds
  void _showError(String message) {
    debugPrint('=== ROUTING ERROR: $message');
    setState(() {
      _errorMessage = message;
    });

    // Cancel previous timer if exists
    _errorDismissTimer?.cancel();
    
    // Auto-dismiss after 5 seconds
    _errorDismissTimer = Timer(const Duration(seconds: 5), () {
      if (mounted && _errorMessage == message) {
        _dismissError();
      }
    });
  }

  /// Dismiss current error message
  void _dismissError() {
    _errorDismissTimer?.cancel();
    setState(() {
      _errorMessage = null;
    });
  }

  /// Create connection with comprehensive error handling
  Future<void> _createConnectionWithErrorHandling(
    RoutingEditorCubit cubit,
    String sourcePortId,
    String targetPortId,
  ) async {
    try {
      // Check current state
      final currentState = cubit.state;
      if (currentState is! RoutingEditorStateLoaded) {
        _showError('Routing editor not ready');
        return;
      }

      // Only check aux buses for algorithm-to-algorithm connections
      // Hardware input/output connections (buses 1-20) are always available
      final isHardwareConnection = sourcePortId.startsWith('hw_') || targetPortId.startsWith('hw_');
      if (!isHardwareConnection) {
        final availableAuxBuses = await _checkAvailableAuxBuses(currentState);
        if (!availableAuxBuses) {
          _showError('No available buses for algorithm connection');
          return;
        }
      }

      // Attempt to create the connection
      await cubit.createConnection(
        sourcePortId: sourcePortId,
        targetPortId: targetPortId,
      );
      
      debugPrint('Connection created successfully');
    } on ArgumentError catch (e) {
      _showError('Invalid connection: ${e.message}');
    } on StateError catch (e) {
      _showError('State error: ${e.message}');
    } catch (e) {
      _showError('Connection failed: ${e.toString()}');
      debugPrint('Connection creation error: $e');
    }
  }

  /// Check if there are available aux buses for algorithm-to-algorithm connections
  Future<bool> _checkAvailableAuxBuses(RoutingEditorStateLoaded state) async {
    // Get all currently used bus numbers from existing connections
    final usedBuses = <int>{};
    
    // Check all algorithm ports for their current bus assignments
    for (final algorithm in state.algorithms) {
      for (final port in [...algorithm.inputPorts, ...algorithm.outputPorts]) {
        if (port.busValue != null && port.busValue! > 0) {
          usedBuses.add(port.busValue!);
        }
      }
    }
    
    // Check if aux buses (21-28) are available
    for (int busNumber = 21; busNumber <= 28; busNumber++) {
      if (!usedBuses.contains(busNumber)) {
        return true; // Found at least one available bus
      }
    }
    
    return false; // All aux buses are in use
  }

  Widget _buildCanvasContent(BuildContext context, RoutingEditorState state) {
    return state.when(
      initial: () =>
          _buildEmptyState(context, 'Initializing routing editor...'),
      disconnected: () => _buildEmptyState(context, 'Hardware disconnected'),
      loaded:
          (
            physicalInputs,
            physicalOutputs,
            algorithms,
            connections,
            buses,
            portOutputModes,
            nodePositions,
            isHardwareSynced,
            isPersistenceEnabled,
            lastSyncTime,
            lastPersistTime,
            lastError,
            subState,
          ) => _buildLoadedCanvas(
            context,
            physicalInputs,
            physicalOutputs,
            algorithms,
            connections,
            nodePositions,
          ),
    );
  }

  Widget _buildEmptyState(BuildContext context, String message) {
    /* identical to RoutingCanvas */
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.device_hub,
            size: 64,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.7),
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
    Map<String, NodePosition> stateNodePositions,
  ) {
    return Semantics(
      label:
          'Routing canvas with ${algorithms.length} algorithm nodes and ${connections.length} connections',
      hint:
          'Interactive routing canvas. Pan and zoom to navigate. Drag between ports to create connections.',
      container: true,
      child: SingleChildScrollView(
        controller: _horizontalScrollController,
        scrollDirection: Axis.horizontal,
        physics:
            const NeverScrollableScrollPhysics(), // Disable scroll gestures
        child: SingleChildScrollView(
          controller: _verticalScrollController,
          scrollDirection: Axis.vertical,
          physics:
              const NeverScrollableScrollPhysics(), // Disable scroll gestures
          child: Listener(
            // Handle mouse wheel and trackpad scrolling
            onPointerSignal: (pointerSignal) {
              if (pointerSignal is PointerScrollEvent) {
                // Handle horizontal scrolling (trackpad side-scroll or shift+wheel)
                if (_horizontalScrollController.hasClients) {
                  final newHorizontal =
                      _horizontalScrollController.offset +
                      pointerSignal.scrollDelta.dx;
                  _horizontalScrollController.jumpTo(
                    newHorizontal.clamp(
                      _horizontalScrollController.position.minScrollExtent,
                      _horizontalScrollController.position.maxScrollExtent,
                    ),
                  );
                }

                // Handle vertical scrolling (mouse wheel or trackpad)
                if (_verticalScrollController.hasClients) {
                  final newVertical =
                      _verticalScrollController.offset +
                      pointerSignal.scrollDelta.dy;
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
                        debugPrint(
                          '=== GRID TAP DOWN: ${details.localPosition}',
                        );
                        _handleCanvasTap(details.localPosition, connections);
                      },
                      onPanStart: _handleCanvasPanStart,
                      onPanUpdate: _handleCanvasPanUpdate,
                      onPanEnd: _handleCanvasPanEnd,
                      behavior: HitTestBehavior
                          .translucent, // Allow events to pass through to child widgets
                      child: CustomPaint(
                        painter: _CanvasGridPainter(
                          minorGridColor: Theme.of(
                            context,
                          ).colorScheme.outline.withValues(alpha: 0.1),
                          majorGridColor: Theme.of(
                            context,
                          ).colorScheme.outline.withValues(alpha: 0.2),
                          gridSize: 50.0,
                          majorEvery: 5,
                        ),
                        size: Size(_canvasWidth, _canvasHeight),
                      ),
                    ),
                  ),
                  // Nodes on middle layer (connections will draw above to overlay ports)
                  if (widget.showPhysicalPorts)
                    ..._buildPhysicalInputNodes(physicalInputs, connections, stateNodePositions),
                  if (widget.showPhysicalPorts)
                    ..._buildPhysicalOutputNodes(physicalOutputs, connections, stateNodePositions),
                  ..._buildAlgorithmNodes(algorithms, connections, stateNodePositions),
                  // Draw all connections with unified canvas
                  // Use RepaintBoundary to isolate canvas repaints
                  // Keep connections visible if they were already visible and ports haven't been cleared
                  if (_connectionsVisible || _portsReady)
                    RepaintBoundary(
                      child: _buildUnifiedConnectionCanvas(connections),
                    )
                  else
                    const SizedBox.shrink(),
                  if (_isDraggingConnection && _dragCurrentPosition != null)
                    _buildTemporaryConnection(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Below methods are copied from RoutingCanvas (handlers, builders, validators)
  List<Widget> _buildPhysicalInputNodes(
    List<Port> physicalInputs,
    List<Connection> connections,
    Map<String, NodePosition> stateNodePositions,
  ) {
    if (physicalInputs.isEmpty) return [];
    // Position in the center area of the canvas, to the left of algorithms
    const double centerX = _canvasWidth / 2;
    const double centerY = _canvasHeight / 2;
    
    // Check for position from state first
    final statePosition = stateNodePositions['physical_inputs'];
    final Offset nodePosition;
    
    if (statePosition != null) {
      nodePosition = Offset(statePosition.x, statePosition.y);
      _nodePositions['physical_inputs'] = nodePosition;
    } else {
      nodePosition = _nodePositions['physical_inputs'] ??
          const Offset(centerX - 800, centerY - 300);
    }

    return [
      Positioned(
        key: const ValueKey('physical_input_node'),
        left: nodePosition.dx,
        top: nodePosition.dy,
        child: PhysicalInputNode(
          ports: physicalInputs,
          connectedPorts: _getConnectedPortIds(connections).toSet(),
          position: nodePosition,
          onPositionChanged: (newPosition) {
            setState(() {
              _nodePositions['physical_inputs'] = newPosition;
            });
            // Save position to preferences
            context.read<RoutingEditorCubit>().updateNodePosition(
              'physical_inputs',
              newPosition.dx,
              newPosition.dy,
            );
          },
          showLabels: widget.canvasSize.width >= 800,
          onPortTapped: (port) => _handlePortTap(port),
          onDragStart: (port) => _handlePortDragStart(port),
          onDragUpdate: (port, position) =>
              _handlePortDragUpdate(port, position),
          onDragEnd: (port, position) => _handlePortDragEnd(port, position),
          onPortPositionResolved: (port, globalCenter) {
            _updatePortAnchor(port.id, globalCenter);
          },
          onRoutingAction: (portId, action) =>
              _handlePortRoutingAction(portId, action, connections),
          highlightedPortId: _isDraggingConnection ? _highlightedPortId : null,
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

  List<Widget> _buildPhysicalOutputNodes(
    List<Port> physicalOutputs,
    List<Connection> connections,
    Map<String, NodePosition> stateNodePositions,
  ) {
    if (physicalOutputs.isEmpty) return [];
    // Position in the center area of the canvas, to the right of algorithms
    const double centerX = _canvasWidth / 2;
    const double centerY = _canvasHeight / 2;
    
    // Check for position from state first
    final statePosition = stateNodePositions['physical_outputs'];
    final Offset nodePosition;
    
    if (statePosition != null) {
      nodePosition = Offset(statePosition.x, statePosition.y);
      _nodePositions['physical_outputs'] = nodePosition;
    } else {
      nodePosition = _nodePositions['physical_outputs'] ??
          const Offset(centerX + 600, centerY - 300);
    }

    return [
      Positioned(
        key: const ValueKey('physical_output_node'),
        left: nodePosition.dx,
        top: nodePosition.dy,
        child: PhysicalOutputNode(
          ports: physicalOutputs,
          connectedPorts: _getConnectedPortIds(connections).toSet(),
          position: nodePosition,
          onPositionChanged: (newPosition) {
            setState(() {
              _nodePositions['physical_outputs'] = newPosition;
            });
            // Save position to preferences
            context.read<RoutingEditorCubit>().updateNodePosition(
              'physical_outputs',
              newPosition.dx,
              newPosition.dy,
            );
          },
          showLabels: widget.canvasSize.width >= 800,
          onPortTapped: (port) => _handlePortTap(port),
          onDragStart: (port) => _handlePortDragStart(port),
          onDragUpdate: (port, position) =>
              _handlePortDragUpdate(port, position),
          onDragEnd: (port, position) => _handlePortDragEnd(port, position),
          onPortPositionResolved: (port, globalCenter) {
            _updatePortAnchor(port.id, globalCenter);
          },
          onRoutingAction: (portId, action) =>
              _handlePortRoutingAction(portId, action, connections),
          highlightedPortId: _isDraggingConnection ? _highlightedPortId : null,
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

  List<Widget> _buildAlgorithmNodes(
    List<RoutingAlgorithm> algorithms,
    List<Connection> connections,
    Map<String, NodePosition> stateNodePositions,
  ) {
    return algorithms.map((algorithm) {
      // Use stable algorithm ID instead of index for consistent positioning
      final nodeId = algorithm.id;
      
      // First check if there's a position from the layout algorithm in state
      final statePosition = stateNodePositions[nodeId];
      final Offset position;
      
      if (statePosition != null) {
        // Use position from state (layout algorithm result)
        position = Offset(statePosition.x, statePosition.y);
        // Update local cache with state position
        _nodePositions[nodeId] = position;
      } else {
        // Fall back to local position or default
        final defaultPosition = Offset(
          _canvasWidth / 2 - 250 + ((algorithm.index % 2) * 300),
          _canvasHeight / 2 - 300 + ((algorithm.index ~/ 2) * 200),
        );
        position = _nodePositions[nodeId] ?? defaultPosition;
        // Store the default position if not already in the map
        if (!_nodePositions.containsKey(nodeId)) {
          _nodePositions[nodeId] = defaultPosition;
        }
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
          connectedPorts: _getConnectedPortIds(connections),
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
            debugPrint(
              '=== ROUTING EDITOR: Node $nodeId position changed to $newPosition',
            );
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
            // Save position to preferences
            context.read<RoutingEditorCubit>().updateNodePosition(
              nodeId,
              newPosition.dx,
              newPosition.dy,
            );
          },
          onDragEnd: () {
            if (_isDraggingNode) {
              setState(() {
                _isDraggingNode = false;
              });
            }
          },
          onMoveUp: algorithm.index > 0
              ? () => _handleAlgorithmMoveUp(algorithm.index)
              : null,
          onMoveDown: algorithm.index < algorithms.length - 1
              ? () => _handleAlgorithmMoveDown(algorithm.index)
              : null,
          onDelete: () => _handleAlgorithmDelete(algorithm.index),
          onRoutingAction: (portId, action) =>
              _handlePortRoutingAction(portId, action, connections),
          onPortTapped: (portId) => _handlePortTapById(portId),
          onPortDragStart: _handleAlgorithmPortDragStart,
          onPortDragUpdate: _handleAlgorithmPortDragUpdate,
          onPortDragEnd: _handleAlgorithmPortDragEnd,
          highlightedPortId: _isDraggingConnection ? _highlightedPortId : null,
          // onTap: () => _handleNodeTap(nodeId), // Disable selection for now
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

      final isPhysicalConnection =
          connectionType == ConnectionType.hardwareInput ||
          connectionType == ConnectionType.hardwareOutput;
      final isInputConnection =
          connectionType == ConnectionType.hardwareInput ||
          connectionType == ConnectionType.partialBusToInput;

      // Get bus number directly from the connection
      int? busNumber = connection.busNumber;

      // Fallback to extracting from busId if needed (e.g., "bus_5" -> 5)
      if (busNumber == null && connection.busId != null) {
        final busIdMatch = RegExp(r'bus_(\d+)').firstMatch(connection.busId!);
        if (busIdMatch != null) {
          busNumber = int.tryParse(busIdMatch.group(1)!);
          debugPrint(
            'RoutingEditorWidget: Got bus number from busId: $busNumber',
          );
        }
      }

      if (busNumber == null) {
        debugPrint(
          'RoutingEditorWidget: No bus number found for connection ${connection.id}',
        );
        debugPrint('  - busNumber: ${connection.busNumber}');
        debugPrint('  - busId: ${connection.busId}');
      }

      connectionDataList.add(
        painter.ConnectionData(
          connection: connection,
          sourcePosition: sourcePosition,
          destinationPosition: targetPosition,
          busNumber: busNumber,
          outputMode: connection.outputMode,
          isSelected: false,
          isHighlighted:
              _hoveredConnectionId == connection.id ||
              _selectedPortConnectionIds.contains(
                connection.id,
              ), // Highlight if hovered or selected for deletion
          isPhysicalConnection: isPhysicalConnection,
          isInputConnection: isInputConnection,
          busLabel: connection
              .busLabel, // Pass through bus label for partial connections
          onLabelHover:
              null, // Label hover is handled by the overlay widgets, not here
          onLabelTap: () => _toggleConnectionOutputMode(connection.id),
        ),
      );
    }

    if (connectionDataList.isEmpty) {
      return const SizedBox.shrink();
    }

    // Choose rendering approach based on platform capabilities
    if (_platformService.supportsHoverInteractions()) {
      // Desktop: Use individual hoverable connections for delete functionality
      return _buildHoverableConnections(connectionDataList);
    } else {
      // Mobile/other: Use unified painter with label overlays
      return Stack(
        children: [
          // The connection painter itself (no pointer events)
          IgnorePointer(
            child: CustomPaint(
              painter: _ConnectionPainterWithBounds(
                connections: connectionDataList,
                theme: Theme.of(context),
                showLabels: true,
                enableAnimations: true,
                hoveredConnectionId:
                    _hoveredLabelConnectionId, // Use label hover state for label highlighting
                onBoundsUpdated: (bounds) {
                  _connectionLabelBounds = bounds;
                },
              ),
              child: const SizedBox.expand(),
            ),
          ),
          // Invisible overlay for gesture detection only over connection labels
          ..._buildConnectionLabelOverlays(),
        ],
      );
    }
  }

  /// Build individual hoverable connections for desktop platforms
  Widget _buildHoverableConnections(
    List<painter.ConnectionData> connectionDataList,
  ) {
    // For desktop, we use a hybrid approach:
    // 1. Render all connections with unified painter (efficient)
    // 2. Overlay individual hover detection areas for delete functionality

    return Stack(
      children: [
        // Base connection rendering (efficient batch painting) - ignore pointer events
        IgnorePointer(
          child: CustomPaint(
            painter: _ConnectionPainterWithBounds(
              connections: connectionDataList,
              theme: Theme.of(context),
              showLabels: true,
              enableAnimations: true,
              hoveredConnectionId:
                  _hoveredLabelConnectionId, // Use label hover state for label highlighting
              onBoundsUpdated: (bounds) {
                _connectionLabelBounds = bounds;
              },
            ),
            child: const SizedBox.expand(),
          ),
        ),

        // Keep existing label overlays for output mode toggling
        ..._buildConnectionLabelOverlays(),
      ],
    );
  }

  Widget _buildTemporaryConnection() {
    if (!_isDraggingConnection ||
        _dragSourcePort == null ||
        _dragCurrentPosition == null) {
      return const SizedBox.shrink();
    }

    final sourcePosition = _getPortPosition(_dragSourcePort!.id);
    if (sourcePosition == null) return const SizedBox.shrink();

    // Use RepaintBoundary for performance during drag operations
    return RepaintBoundary(
      child: CustomPaint(
        painter: _TemporaryConnectionPainter(
          sourcePosition: sourcePosition,
          targetPosition: _dragCurrentPosition!,
          sourcePortId: _dragSourcePort!.id,
          theme: Theme.of(context),
        ),
        child: const SizedBox.expand(),
      ),
    );
  }

  void _handleCanvasTap(Offset tapPosition, List<Connection> connections) {
    debugPrint('=== CANVAS TAP: $tapPosition');

    // If there's a highlighted connection, check if the tap hits it
    if (_hoveredConnectionId != null) {
      final highlightedConnection = connections.firstWhere(
        (conn) => conn.id == _hoveredConnectionId,
        orElse: () => Connection(
          id: '',
          sourcePortId: '',
          destinationPortId: '',
          connectionType: ConnectionType.algorithmToAlgorithm,
        ),
      );

      if (highlightedConnection.id.isNotEmpty &&
          _isPointNearConnection(tapPosition, highlightedConnection)) {
        // Tap hit the highlighted connection - delete it
        debugPrint('Deleting connection: $_hoveredConnectionId');
        _deleteConnection(_hoveredConnectionId!, connections);
        return;
      }
    }

    // Tap didn't hit highlighted connection - deselect it
    _clearConnectionHighlight();
  }

  bool _isPointNearConnection(Offset tapPoint, Connection connection) {
    // Get connection line positions
    final sourcePos = _getPortPosition(connection.sourcePortId);
    final destPos = _getPortPosition(connection.destinationPortId);

    if (sourcePos == null || destPos == null) return false;

    // Check if tap is within ~15px of the connection line
    const double hitRadius = 15.0;
    final distance = _distanceFromPointToLine(tapPoint, sourcePos, destPos);
    return distance <= hitRadius;
  }

  double _distanceFromPointToLine(
    Offset point,
    Offset lineStart,
    Offset lineEnd,
  ) {
    // Calculate distance from point to line segment
    final A = point.dx - lineStart.dx;
    final B = point.dy - lineStart.dy;
    final C = lineEnd.dx - lineStart.dx;
    final D = lineEnd.dy - lineStart.dy;

    final dot = A * C + B * D;
    final lenSq = C * C + D * D;

    if (lenSq == 0) {
      // Line is a point
      return math.sqrt(A * A + B * B);
    }

    final param = dot / lenSq;

    double xx, yy;
    if (param < 0) {
      xx = lineStart.dx;
      yy = lineStart.dy;
    } else if (param > 1) {
      xx = lineEnd.dx;
      yy = lineEnd.dy;
    } else {
      xx = lineStart.dx + param * C;
      yy = lineStart.dy + param * D;
    }

    final dx = point.dx - xx;
    final dy = point.dy - yy;
    return math.sqrt(dx * dx + dy * dy);
  }

  void _deleteConnection(String connectionId, List<Connection> connections) {
    // Call the cubit to delete the connection
    context.read<RoutingEditorCubit>().deleteConnection(connectionId);

    // Clear highlighting
    _clearConnectionHighlight();
  }

  void _clearConnectionHighlight() {
    _connectionHighlightTimer?.cancel();
    setState(() {
      _hoveredConnectionId = null;
    });
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
          newHorizontal.clamp(
            0.0,
            _horizontalScrollController.position.maxScrollExtent,
          ),
        );
      }

      if (_verticalScrollController.hasClients) {
        final newVertical = _verticalScrollController.offset - delta.dy;
        _verticalScrollController.jumpTo(
          newVertical.clamp(
            0.0,
            _verticalScrollController.position.maxScrollExtent,
          ),
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

  // Port and node interaction handlers
  void _handlePortTap(Port port) {
    debugPrint('=== PORT TAP: ${port.id} (${port.name})');

    // Only allow deletion from input ports
    if (!port.isInput) {
      debugPrint('Deletion only allowed from input ports. Ignoring tap on output port: ${port.id}');
      return;
    }

    if (_platformService.isMobilePlatform()) {
      // Mobile: Show confirmation dialog
      _showPortConnectionsDeleteConfirmation(port.id, port.name);
    } else {
      // Desktop: Keep immediate deletion
      final cubit = context.read<RoutingEditorCubit>();
      cubit.deleteConnectionsForPort(port.id);
    }
  }

  void _handlePortTapById(String portId) {
    debugPrint('=== PORT TAP: $portId');

    // Find the actual port to check if it's an input
    final state = context.read<RoutingEditorCubit>().state;
    if (state is! RoutingEditorStateLoaded) {
      debugPrint('Cannot process port tap - routing editor not loaded');
      return;
    }

    // Search through all ports to find the tapped port
    Port? tappedPort;
    
    // Check physical inputs
    for (final port in state.physicalInputs) {
      if (port.id == portId) {
        tappedPort = port;
        break;
      }
    }
    
    // Check physical outputs if not found
    if (tappedPort == null) {
      for (final port in state.physicalOutputs) {
        if (port.id == portId) {
          tappedPort = port;
          break;
        }
      }
    }
    
    // Check algorithm ports if not found
    if (tappedPort == null) {
      for (final algorithm in state.algorithms) {
        for (final port in [...algorithm.inputPorts, ...algorithm.outputPorts]) {
          if (port.id == portId) {
            tappedPort = port;
            break;
          }
        }
        if (tappedPort != null) break;
      }
    }

    if (tappedPort == null) {
      debugPrint('Could not find port with ID: $portId');
      return;
    }

    // Only allow deletion from input ports
    if (!tappedPort.isInput) {
      debugPrint('Deletion only allowed from input ports. Ignoring tap on output port: $portId');
      return;
    }

    if (_platformService.isMobilePlatform()) {
      // Mobile: Show confirmation dialog
      _showPortConnectionsDeleteConfirmation(portId, null);
    } else {
      // Desktop: Keep immediate deletion
      final cubit = context.read<RoutingEditorCubit>();
      cubit.deleteConnectionsForPort(portId);
    }
  }

  void _handlePortDragStart(Port port) {
    // Only start drag from output ports
    if (!port.isOutput) {
      return;
    }

    // Allow dragging from output ports even when connected to enable fan-out patterns
    // (Input port check above already prevents dragging from inputs)

    // Get the current port position
    final portPosition = _getPortPosition(port.id);
    if (portPosition == null) {
      debugPrint('Cannot find position for port: ${port.id}');
      return;
    }

    setState(() {
      _isDraggingConnection = true;
      _dragSourcePort = port;
      _dragCurrentPosition = portPosition;
    });
  }

  void _handlePortDragUpdate(Port port, Offset position) {
    // Only update if we're dragging a connection and this is the source port
    if (!_isDraggingConnection || _dragSourcePort?.id != port.id) {
      return;
    }

    // Convert global position to local canvas coordinates
    final ctx = _canvasKey.currentContext;
    if (ctx == null) return;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null || !box.attached) return;
    final localPosition = box.globalToLocal(position);

    // Immediate position update for fluid preview
    setState(() {
      _dragCurrentPosition = localPosition;
    });

    // Cancel previous debounce timer
    _dragUpdateDebounceTimer?.cancel();

    // Debounced port detection (16ms for 60fps)
    _dragUpdateDebounceTimer = Timer(const Duration(milliseconds: 16), () {
      if (!mounted || !_isDraggingConnection || _dragSourcePort?.id != port.id) {
        return;
      }

      final targetPort = _findPortAtPosition(localPosition);
      final newHighlight = targetPort?.isInput == true ? targetPort?.id : null;
      
      // Only setState if highlight actually changed
      if (newHighlight != _highlightedPortId) {
        setState(() {
          _highlightedPortId = newHighlight;
        });
      }
    });
  }

  // Handler methods for algorithm port drags (using port ID instead of Port object)
  void _handleAlgorithmPortDragStart(String portId) {
    // Find the port in the current state
    final state = context.read<RoutingEditorCubit>().state;
    if (state is! RoutingEditorStateLoaded) return;
    
    // Find port in algorithms
    Port? port;
    for (final algorithm in state.algorithms) {
      port = algorithm.outputPorts.firstWhereOrNull((p) => p.id == portId);
      if (port != null) break;
    }
    
    if (port == null) {
      debugPrint('Port not found: $portId');
      return;
    }
    
    // Allow dragging from output ports even when connected to enable fan-out patterns
    // (Only output ports can be dragged from, checked above)
    
    // Get the current port position
    final portPosition = _getPortPosition(portId);
    if (portPosition == null) {
      debugPrint('Cannot find position for port: $portId');
      return;
    }
    
    setState(() {
      _isDraggingConnection = true;
      _dragSourcePort = port;
      _dragCurrentPosition = portPosition;
    });
    
    debugPrint('Started connection drag from algorithm output port: ${port.name}');
  }
  
  void _handleAlgorithmPortDragUpdate(String portId, Offset position) {
    // Only update if we're dragging a connection and this is the source port
    if (!_isDraggingConnection || _dragSourcePort?.id != portId) {
      return;
    }
    
    // Convert global position to local canvas coordinates
    final ctx = _canvasKey.currentContext;
    if (ctx == null) return;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null || !box.attached) return;
    final localPosition = box.globalToLocal(position);
    
    // Immediate position update for fluid preview
    setState(() {
      _dragCurrentPosition = localPosition;
    });
    
    // Cancel previous debounce timer
    _dragUpdateDebounceTimer?.cancel();
    
    // Debounced port detection (16ms for 60fps)
    _dragUpdateDebounceTimer = Timer(const Duration(milliseconds: 16), () {
      if (!mounted || !_isDraggingConnection || _dragSourcePort?.id != portId) {
        return;
      }
      
      final targetPort = _findPortAtPosition(localPosition);
      final newHighlight = targetPort?.isInput == true ? targetPort?.id : null;
      
      // Only setState if highlight actually changed
      if (newHighlight != _highlightedPortId) {
        setState(() {
          _highlightedPortId = newHighlight;
        });
      }
    });
  }
  
  Future<void> _handleAlgorithmPortDragEnd(String portId, Offset position) async {
    // Convert global position to local canvas coordinates
    final ctx = _canvasKey.currentContext;
    if (ctx == null) return;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null || !box.attached) return;
    final localPosition = box.globalToLocal(position);
    
    // Only handle if we're dragging a connection and this is the source port
    if (!_isDraggingConnection || _dragSourcePort?.id != portId) {
      return;
    }
    
    // Cancel any pending drag update
    _dragUpdateDebounceTimer?.cancel();
    
    try {
      // Find port at drop position
      final targetPort = _findPortAtPosition(localPosition);
      
      if (targetPort != null) {
        debugPrint('Port found at drop position: ${targetPort.name}, isInput: ${targetPort.isInput}, direction: ${targetPort.direction}, id: ${targetPort.id}');
      }
      
      if (targetPort != null && targetPort.isInput) {
        debugPrint('Valid drop target found: ${targetPort.name}');
        
        // Check for duplicate connection before attempting to create
        final cubit = context.read<RoutingEditorCubit>();
        final currentState = cubit.state;
        if (currentState is RoutingEditorStateLoaded) {
          final exists = currentState.connections.any((conn) =>
            conn.sourcePortId == _dragSourcePort!.id &&
            conn.destinationPortId == targetPort.id
          );
          
          if (exists) {
            _showError('Connection already exists between these ports');
            return;
          }
          
          // Only check aux buses for algorithm-to-algorithm connections
          // Hardware connections (buses 1-20) are always available
          final isHardwareConnection = _dragSourcePort!.id.startsWith('hw_') || targetPort.id.startsWith('hw_');
          if (!isHardwareConnection) {
            if (!(await _checkAvailableAuxBuses(currentState))) {
              return;
            }
          }
        }
        
        // Create the connection
        try {
          await cubit.createConnection(
            sourcePortId: _dragSourcePort!.id,
            targetPortId: targetPort.id,
          );
          debugPrint('Connection created successfully');
        } catch (e) {
          _showError('Failed to create connection: ${e.toString()}');
        }
      } else {
        debugPrint('Invalid drop target or dropped on non-port area');
      }
    } finally {
      // Always clear drag state
      setState(() {
        _isDraggingConnection = false;
        _dragSourcePort = null;
        _dragCurrentPosition = null;
        _highlightedPortId = null;
      });
    }
  }

  Future<void> _handlePortDragEnd(Port port, Offset position) async {
    // Convert global position to local canvas coordinates
    final ctx = _canvasKey.currentContext;
    if (ctx == null) return;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null || !box.attached) return;
    final localPosition = box.globalToLocal(position);
    
    // Only handle if we're dragging a connection and this is the source port
    if (!_isDraggingConnection || _dragSourcePort?.id != port.id) {
      return;
    }

    // Cancel any pending drag update
    _dragUpdateDebounceTimer?.cancel();

    try {
      // Find port at drop position
      final targetPort = _findPortAtPosition(localPosition);

      if (targetPort != null) {
        debugPrint('Port found at drop position: ${targetPort.name}, isInput: ${targetPort.isInput}, direction: ${targetPort.direction}, id: ${targetPort.id}');
      }
      
      if (targetPort != null && targetPort.isInput) {
        debugPrint('Valid drop target found: ${targetPort.name}');
        
        // Check for duplicate connection before attempting to create
        final currentState = context.read<RoutingEditorCubit>().state;
        if (currentState is RoutingEditorStateLoaded) {
          final existingConnection = currentState.connections.any(
            (conn) => conn.sourcePortId == _dragSourcePort!.id && 
                     conn.destinationPortId == targetPort.id,
          );
          
          if (existingConnection) {
            _showError('Connection already exists between these ports');
            return;
          }
        }
        
        // Create the connection using the cubit
        final cubit = context.read<RoutingEditorCubit>();
        await _createConnectionWithErrorHandling(cubit, _dragSourcePort!.id, targetPort.id);
        
        debugPrint(
          'Connection creation requested: ${_dragSourcePort!.name} -> ${targetPort.name}',
        );
      } else {
        // Invalid drop - silently clear drag state (no error message)
        debugPrint('No valid input port found at drop position - silent failure');
      }
    } catch (e) {
      _showError('Failed to create connection: ${e.toString()}');
      debugPrint('Error in drag end: $e');
    } finally {
      // Always clear drag state
      setState(() {
        _isDraggingConnection = false;
        _dragSourcePort = null;
        _dragCurrentPosition = null;
        _highlightedPortId = null; // Clear highlighting when drag ends
      });
    }
  }

  Future<void> _showPortConnectionsDeleteConfirmation(
    String portId,
    String? portName,
  ) async {
    // Get the current state to find connections
    final routingState = context.read<RoutingEditorCubit>().state;
    if (routingState is! RoutingEditorStateLoaded) return;

    // Find all connections for this port
    final portConnections = routingState.connections
        .where(
          (conn) =>
              conn.sourcePortId == portId || conn.destinationPortId == portId,
        )
        .toList();

    if (portConnections.isEmpty) {
      debugPrint('No connections found for port: $portId');
      return;
    }

    // Highlight the connections that will be deleted
    setState(() {
      _selectedPortConnectionIds = portConnections.map((c) => c.id).toSet();
    });

    // Build connection descriptions for the dialog
    final connectionDescriptions = <String>[];
    for (final connection in portConnections) {
      // Try to find actual port names
      final allPorts = [
        ...routingState.physicalInputs,
        ...routingState.physicalOutputs,
        for (final algo in routingState.algorithms) ...[
          ...algo.inputPorts,
          ...algo.outputPorts,
        ],
      ];

      final sourcePort = allPorts.firstWhere(
        (p) => p.id == connection.sourcePortId,
        orElse: () => Port(
          id: '',
          name: connection.sourcePortId,
          type: PortType.cv,
          direction: PortDirection.input,
        ),
      );
      final destPort = allPorts.firstWhere(
        (p) => p.id == connection.destinationPortId,
        orElse: () => Port(
          id: '',
          name: connection.destinationPortId,
          type: PortType.cv,
          direction: PortDirection.input,
        ),
      );

      connectionDescriptions.add('${sourcePort.name} → ${destPort.name}');
    }

    // Show confirmation dialog
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          portConnections.length == 1
              ? 'Delete Connection?'
              : 'Delete ${portConnections.length} Connections?',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (portName != null) Text('From port: $portName\n'),
            Text(
              portConnections.length == 1
                  ? 'This will delete the connection:'
                  : 'This will delete the following connections:',
            ),
            const SizedBox(height: 8),
            ...connectionDescriptions.map(
              (desc) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text('• $desc', style: const TextStyle(fontSize: 14)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    // Clear highlighting
    setState(() {
      _selectedPortConnectionIds.clear();
    });

    // Delete connections if confirmed
    if (shouldDelete == true && mounted) {
      final cubit = context.read<RoutingEditorCubit>();
      for (final connection in portConnections) {
        await cubit.deleteConnectionWithSmartBusLogic(connection.id);
      }
      debugPrint(
        'Deleted ${portConnections.length} connections for port $portId',
      );
    }
  }

  bool _hasLoadedStateChanged(
    RoutingEditorStateLoaded previous,
    RoutingEditorStateLoaded current,
  ) {
    /* same as RoutingCanvas */
    if (previous.physicalInputs.length != current.physicalInputs.length ||
        previous.physicalOutputs.length != current.physicalOutputs.length ||
        previous.algorithms.length != current.algorithms.length ||
        previous.connections.length != current.connections.length ||
        previous.nodePositions.length != current.nodePositions.length) {
      return true;
    }
    
    // Check if node positions have changed
    for (final entry in current.nodePositions.entries) {
      final prevPosition = previous.nodePositions[entry.key];
      if (prevPosition == null || 
          prevPosition.x != entry.value.x || 
          prevPosition.y != entry.value.y) {
        return true;
      }
    }
    for (int i = 0; i < current.algorithms.length; i++) {
      if (i >= previous.algorithms.length) return true;
      final prevAlg = previous.algorithms[i];
      final currAlg = current.algorithms[i];
      if (prevAlg.index != currAlg.index ||
          prevAlg.algorithm.name != currAlg.algorithm.name) {
        return true;
      }
      if (prevAlg.inputPorts.length != currAlg.inputPorts.length) return true;
      for (int p = 0; p < currAlg.inputPorts.length; p++) {
        final a = prevAlg.inputPorts[p];
        final b = currAlg.inputPorts[p];
        if (a.id != b.id ||
            a.name != b.name ||
            a.type != b.type ||
            a.direction != b.direction) {
          return true;
        }
      }
      if (prevAlg.outputPorts.length != currAlg.outputPorts.length) return true;
      for (int p = 0; p < currAlg.outputPorts.length; p++) {
        final a = prevAlg.outputPorts[p];
        final b = currAlg.outputPorts[p];
        if (a.id != b.id ||
            a.name != b.name ||
            a.type != b.type ||
            a.direction != b.direction) {
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

  /// Check if the routing structure (ports and algorithms) has actually changed
  /// This is more restrictive than _hasLoadedStateChanged and only returns true
  /// when the visual layout needs to be recreated
  bool _hasRoutingStructureChanged(
    RoutingEditorStateLoaded previous,
    RoutingEditorStateLoaded current,
  ) {
    // Check if algorithms changed structurally
    if (previous.algorithms.length != current.algorithms.length) {
      return true;
    }
    
    for (int i = 0; i < current.algorithms.length; i++) {
      final prevAlg = previous.algorithms[i];
      final currAlg = current.algorithms[i];
      
      // Algorithm changed (different type or position)
      if (prevAlg.algorithm.guid != currAlg.algorithm.guid ||
          prevAlg.index != currAlg.index) {
        return true;
      }
      
      // Port structure changed
      if (prevAlg.inputPorts.length != currAlg.inputPorts.length ||
          prevAlg.outputPorts.length != currAlg.outputPorts.length) {
        return true;
      }
      
      // Port IDs changed (indicates different routing)
      for (int p = 0; p < currAlg.inputPorts.length; p++) {
        if (prevAlg.inputPorts[p].id != currAlg.inputPorts[p].id) {
          return true;
        }
      }
      for (int p = 0; p < currAlg.outputPorts.length; p++) {
        if (prevAlg.outputPorts[p].id != currAlg.outputPorts[p].id) {
          return true;
        }
      }
    }
    
    // Physical ports structure changed
    if (previous.physicalInputs.length != current.physicalInputs.length ||
        previous.physicalOutputs.length != current.physicalOutputs.length) {
      return true;
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
        final nodePos =
            _nodePositions['physical_inputs'] ??
            const Offset(centerX - 800, centerY - 300);
        // Physical input node width is ~150px, ports are on the right edge
        final portOffset = Offset(
          150,
          50 + (inputNum - 1) * 30,
        ); // Stack vertically
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
        final nodePos =
            _nodePositions['physical_outputs'] ??
            const Offset(centerX + 600, centerY - 300);
        // Physical output node ports are on the left edge
        final portOffset = Offset(
          0,
          50 + (outputNum - 1) * 30,
        ); // Stack vertically
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

  /// Find a port at the given position within a reasonable hit radius
  Port? _findPortAtPosition(Offset position) {
    const double hitRadius = 20.0; // Pixels

    final routingState = context.read<RoutingEditorCubit>().state;
    if (routingState is! RoutingEditorStateLoaded) return null;

    // Check all ports and find the closest one within hit radius
    Port? closestPort;
    double closestDistance = double.infinity;

    // Helper function to check a port's position
    void checkPort(Port port) {
      final portPosition = _getPortPosition(port.id);
      if (portPosition != null) {
        final distance = (position - portPosition).distance;
        if (distance <= hitRadius && distance < closestDistance) {
          closestDistance = distance;
          closestPort = port;
        }
      }
    }

    // Check physical inputs
    for (final port in routingState.physicalInputs) {
      checkPort(port);
    }

    // Check physical outputs
    for (final port in routingState.physicalOutputs) {
      checkPort(port);
    }

    // Check algorithm ports
    for (final algorithm in routingState.algorithms) {
      for (final port in algorithm.inputPorts) {
        checkPort(port);
      }
      for (final port in algorithm.outputPorts) {
        checkPort(port);
      }
    }

    return closestPort;
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
    final needsUpdate =
        existingPosition == null || (existingPosition - local).distance > 1.0;

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
              _connectionsVisible = true;
            });
          }
        });
      } else if (_portsReady) {
        // After initial setup, update immediately but don't change connection visibility
        // if it's already true (prevents flicker)
        setState(() {
          if (!_connectionsVisible) {
            _connectionsVisible = true;
          }
        });
      }
    }
  }

  /// Get a set of all connected port IDs
  Set<String> _getConnectedPortIds(List<Connection> connections) {
    final connectedPorts = <String>{};
    for (final connection in connections) {
      connectedPorts.add(connection.sourcePortId);
      connectedPorts.add(connection.destinationPortId);
    }
    return connectedPorts;
  }

  /// Handle routing actions from PortWidget
  void _handlePortRoutingAction(
    String portId,
    String action,
    List<Connection> connections,
  ) {
    debugPrint('=== PORT ROUTING ACTION: $portId -> $action');

    switch (action) {
      case 'hover_start':
        // Find connections involving this port and highlight the first one
        final portConnections = connections
            .where(
              (conn) =>
                  conn.sourcePortId == portId ||
                  conn.destinationPortId == portId,
            )
            .toList();

        if (portConnections.isNotEmpty) {
          _connectionHighlightTimer?.cancel();
          setState(() {
            _hoveredConnectionId = portConnections.first.id;
          });
          debugPrint('Highlighting connection: ${portConnections.first.id}');

          // Auto-deselect after 5 seconds
          _connectionHighlightTimer = Timer(const Duration(seconds: 5), () {
            _clearConnectionHighlight();
            debugPrint('Auto-cleared connection highlighting after 5 seconds');
          });
        }
        break;

      case 'hover_end':
        setState(() {
          _hoveredConnectionId = null;
        });
        debugPrint('Cleared connection highlighting');
        break;

      case 'delete_connections':
        // Find and delete all connections for this port
        final portConnections = connections
            .where(
              (conn) =>
                  conn.sourcePortId == portId ||
                  conn.destinationPortId == portId,
            )
            .toList();

        debugPrint(
          'Deleting ${portConnections.length} connections for port $portId',
        );
        final cubit = context.read<RoutingEditorCubit>();
        for (final connection in portConnections) {
          cubit.deleteConnectionWithSmartBusLogic(connection.id);
        }
        break;
    }
  }

  /// Build invisible overlays positioned over connection labels for gesture detection
  List<Widget> _buildConnectionLabelOverlays() {
    final overlays = <Widget>[];
    final routingState = context.read<RoutingEditorCubit>().state;
    if (routingState is! RoutingEditorStateLoaded) return overlays;

    for (final entry in _connectionLabelBounds.entries) {
      final connectionId = entry.key;
      final bounds = entry.value;

      // Check if this is a partial connection bus label
      if (connectionId.startsWith('partial_')) {
        // This is an unconnected bus label - add tap handler to clear the output
        final actualConnectionId = connectionId.substring(8); // Remove 'partial_' prefix
        
        overlays.add(
          Positioned(
            left: bounds.left,
            top: bounds.top,
            width: bounds.width,
            height: bounds.height,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _clearOutputBusForPartialConnection(actualConnectionId),
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Container(
                  color: Colors.transparent, // Invisible but tappable
                ),
              ),
            ),
          ),
        );
        continue;
      }

      // Find the connection to check if it has a mode parameter
      final connection = routingState.connections.firstWhere(
        (conn) => conn.id == connectionId,
        orElse: () => Connection(
          id: connectionId,
          sourcePortId: '',
          destinationPortId: '',
          connectionType: ConnectionType.algorithmToAlgorithm,
        ),
      );

      // Find the source port to check for mode parameter
      // Collect all ports from algorithms
      final allPorts = [
        ...routingState.physicalInputs,
        ...routingState.physicalOutputs,
        for (final algo in routingState.algorithms) ...[
          ...algo.inputPorts,
          ...algo.outputPorts,
        ],
      ];

      final sourcePort = allPorts.firstWhere(
        (port) => port.id == connection.sourcePortId,
        orElse: () => Port(
          id: '',
          name: '',
          type: PortType.cv,
          direction: PortDirection.input,
        ),
      );

      // Only add hover effect if the port has a mode parameter
      final hasModeParameter = sourcePort.modeParameterNumber != null;

      Widget overlay = GestureDetector(
        behavior: HitTestBehavior.opaque, // Capture all taps in this area
        onTap: () {
          debugPrint('Connection label tapped: $connectionId');
          _toggleConnectionOutputMode(connectionId);
        },
        child: const SizedBox.expand(), // Fill the entire positioned area
      );

      // Wrap in MouseRegion only if it has a mode parameter
      if (hasModeParameter) {
        overlay = MouseRegion(
          onEnter: (_) {
            setState(() {
              _hoveredLabelConnectionId = connectionId;
            });
          },
          onExit: (_) {
            setState(() {
              _hoveredLabelConnectionId = null;
            });
          },
          child: overlay,
        );
      }

      overlays.add(
        Positioned(
          left: bounds.left,
          top: bounds.top,
          width: bounds.width,
          height: bounds.height,
          child: overlay,
        ),
      );
    }

    return overlays;
  }

  /// Toggle output mode for a connection between add (0) and replace (1)
  /// Clear the output bus assignment for a partial connection
  void _clearOutputBusForPartialConnection(String connectionId) {
    final routingCubit = context.read<RoutingEditorCubit>();
    final routingState = routingCubit.state;
    
    if (routingState is! RoutingEditorStateLoaded) return;
    
    // Find the partial connection
    final connection = routingState.connections.firstWhere(
      (conn) => conn.id == connectionId && conn.isPartial,
      orElse: () => Connection(
        id: '',
        sourcePortId: '',
        destinationPortId: '',
        connectionType: ConnectionType.algorithmToAlgorithm,
      ),
    );
    
    if (connection.id.isEmpty) {
      debugPrint('Partial connection not found: $connectionId');
      return;
    }
    
    // For partial output-to-bus connections, the source is the output port
    if (connection.connectionType == ConnectionType.partialOutputToBus) {
      final sourcePortId = connection.sourcePortId;
      
      // Find the port and its algorithm
      for (final algorithm in routingState.algorithms) {
        for (final port in algorithm.outputPorts) {
          if (port.id == sourcePortId && port.parameterNumber != null) {
            debugPrint('Clearing output bus for port ${port.name} (algorithm ${algorithm.index})');
            
            // Clear the bus assignment by setting parameter to 0
            context.read<DistingCubit>().updateParameterValue(
              algorithmIndex: algorithm.index,
              parameterNumber: port.parameterNumber!,
              value: 0, // 0 means "None" for bus assignments
              userIsChangingTheValue: true,
            );
            return;
          }
        }
      }
    }
  }

  void _toggleConnectionOutputMode(String connectionId) {
    final routingState = context.read<RoutingEditorCubit>().state;
    if (routingState is! RoutingEditorStateLoaded) return;

    // Find the connection to get its source port
    final connection = routingState.connections.firstWhere(
      (conn) => conn.id == connectionId,
      orElse: () => throw ArgumentError('Connection not found: $connectionId'),
    );

    // Toggle the output mode for the source port
    context.read<RoutingEditorCubit>().togglePortOutputMode(
      portId: connection.sourcePortId,
    );

    debugPrint('Toggling output mode for ${connection.sourcePortId}');
  }
}

class _CanvasGridPainter extends CustomPainter {
  /* same as canvas */
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
    final minorPaint = Paint()
      ..color = minorGridColor
      ..strokeWidth = 1;
    final majorPaint = Paint()
      ..color = majorGridColor
      ..strokeWidth = 1.5;
    for (double x = 0; x <= size.width; x += gridSize) {
      final isMajor = (x / gridSize) % majorEvery == 0;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        isMajor ? majorPaint : minorPaint,
      );
    }
    for (double y = 0; y <= size.height; y += gridSize) {
      final isMajor = (y / gridSize) % majorEvery == 0;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        isMajor ? majorPaint : minorPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// ConnectionPainter wrapper that stores bounds in the widget state
class _ConnectionPainterWithBounds extends CustomPainter {
  final List<painter.ConnectionData> connections;
  final ThemeData theme;
  final bool showLabels;
  final bool enableAnimations;
  final String? hoveredConnectionId;
  final Function(Map<String, Rect>) onBoundsUpdated;

  late final painter.ConnectionPainter _delegate;

  _ConnectionPainterWithBounds({
    required this.connections,
    required this.theme,
    required this.showLabels,
    required this.enableAnimations,
    required this.hoveredConnectionId,
    required this.onBoundsUpdated,
  }) {
    _delegate = painter.ConnectionPainter(
      connections: connections,
      theme: theme,
      showLabels: showLabels,
      enableAnimations: enableAnimations,
      hoveredConnectionId: hoveredConnectionId,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Delegate to the original painter
    _delegate.paint(canvas, size);

    // Extract and store the bounds in the widget
    onBoundsUpdated(_delegate.getLabelBounds());
  }

  @override
  bool shouldRepaint(covariant _ConnectionPainterWithBounds oldDelegate) {
    return _delegate.shouldRepaint(oldDelegate._delegate);
  }
}

/// Custom painter for temporary connection preview during drag operations
class _TemporaryConnectionPainter extends CustomPainter {
  final Offset sourcePosition;
  final Offset targetPosition;
  final String sourcePortId;
  final ThemeData theme;

  const _TemporaryConnectionPainter({
    required this.sourcePosition,
    required this.targetPosition,
    required this.sourcePortId,
    required this.theme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Create the bezier path using the same calculation as ConnectionPainter
    final path = painter.ConnectionPainter.createBezierPath(
      sourcePosition,
      targetPosition,
    );

    // Get color for the source port type (similar to ConnectionPainter._getPortColor)
    Color connectionColor = _getPortColor(sourcePortId);

    // Apply semi-transparent styling for preview
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = connectionColor.withValues(alpha: 0.5); // Semi-transparent

    // Draw the connection path
    canvas.drawPath(path, paint);

    // Draw endpoints with semi-transparent styling
    final endpointPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = connectionColor.withValues(alpha: 0.7);

    const radius = 4.0;
    canvas.drawCircle(sourcePosition, radius, endpointPaint);
    canvas.drawCircle(targetPosition, radius, endpointPaint);
  }

  /// Get color for a port based on its type (simplified version from ConnectionPainter)
  Color _getPortColor(String portId) {
    // Parse port type from ID (simplified - should use actual port data)
    if (portId.contains('audio')) return theme.colorScheme.primary;
    if (portId.contains('cv')) return Colors.orange;
    if (portId.contains('gate')) return Colors.red;
    if (portId.contains('clock') || portId.contains('trigger')) {
      return Colors.purple;
    }
    return theme.colorScheme.onSurface;
  }

  @override
  bool shouldRepaint(covariant _TemporaryConnectionPainter oldDelegate) {
    return oldDelegate.sourcePosition != sourcePosition ||
        oldDelegate.targetPosition != targetPosition ||
        oldDelegate.sourcePortId != sourcePortId ||
        oldDelegate.theme != theme;
  }
}
