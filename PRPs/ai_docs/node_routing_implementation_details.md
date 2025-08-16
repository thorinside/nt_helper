# Node Routing Implementation Details

This document fills critical gaps in the node-based routing PRP with specific implementation algorithms and patterns.

## 1. Port Extraction from Algorithms

### Algorithm for Extracting Available Ports

```dart
class PortExtractor {
  /// Extract all available ports from an algorithm
  static List<PortInfo> extractPorts(AlgorithmMetadata algorithm, SlotInfo slot) {
    final ports = <PortInfo>[];
    
    // Method 1: Use explicit port definitions (newer format)
    if (algorithm.inputPorts.isNotEmpty || algorithm.outputPorts.isNotEmpty) {
      ports.addAll(_extractFromPortDefinitions(algorithm, slot));
    }
    
    // Method 2: Extract from bus parameters (legacy format)
    ports.addAll(_extractFromBusParameters(algorithm, slot));
    
    // Method 3: Handle multi-channel expansion
    if (_hasPerChannelPorts(algorithm)) {
      ports.addAll(_expandPerChannelPorts(algorithm, slot));
    }
    
    return ports;
  }
  
  static List<PortInfo> _extractFromPortDefinitions(
    AlgorithmMetadata algorithm,
    SlotInfo slot,
  ) {
    final ports = <PortInfo>[];
    
    // Process input ports
    for (final port in algorithm.inputPorts) {
      if (port.busIdRef != null) {
        // Find the parameter that controls this port's bus
        final param = algorithm.parameters.firstWhere(
          (p) => p.name == port.busIdRef,
          orElse: () => null,
        );
        
        if (param != null) {
          final currentBus = slot.getParameterValue(param.id) ?? param.defaultValue;
          ports.add(PortInfo(
            id: port.id,
            name: port.name,
            type: PortType.input,
            busParameterId: param.id,
            currentBus: currentBus,
            isPerChannel: port.isPerChannel ?? false,
          ));
        }
      }
    }
    
    // Process output ports similarly
    for (final port in algorithm.outputPorts) {
      if (port.busIdRef != null) {
        final param = algorithm.parameters.firstWhere(
          (p) => p.name == port.busIdRef,
          orElse: () => null,
        );
        
        if (param != null) {
          final currentBus = slot.getParameterValue(param.id) ?? param.defaultValue;
          ports.add(PortInfo(
            id: port.id,
            name: port.name,
            type: PortType.output,
            busParameterId: param.id,
            currentBus: currentBus,
            isPerChannel: port.isPerChannel ?? false,
          ));
        }
      }
    }
    
    return ports;
  }
  
  static List<PortInfo> _extractFromBusParameters(
    AlgorithmMetadata algorithm,
    SlotInfo slot,
  ) {
    final ports = <PortInfo>[];
    
    for (final param in algorithm.parameters) {
      if (_isBusParameter(param)) {
        // Determine port type from parameter name
        final isInput = param.name.toLowerCase().contains('input') ||
                       param.name.toLowerCase().contains('in');
        final isOutput = param.name.toLowerCase().contains('output') ||
                        param.name.toLowerCase().contains('out');
        
        if (isInput || isOutput) {
          final currentBus = slot.getParameterValue(param.id) ?? param.defaultValue;
          ports.add(PortInfo(
            id: param.id,
            name: param.name,
            type: isInput ? PortType.input : PortType.output,
            busParameterId: param.id,
            currentBus: currentBus,
            scope: param.scope,
          ));
        }
      }
    }
    
    return ports;
  }
  
  static bool _isBusParameter(AlgorithmParameter param) {
    return param.unit == 'bus' ||
           param.type == 'bus' ||
           param.isBus == true ||
           (param.minValue == 0 && param.maxValue == 28) ||
           (param.minValue == 1 && param.maxValue == 28);
  }
  
  static List<PortInfo> _expandPerChannelPorts(
    AlgorithmMetadata algorithm,
    SlotInfo slot,
  ) {
    final ports = <PortInfo>[];
    
    // Find channel count parameter
    final channelCountParam = algorithm.parameters.firstWhere(
      (p) => p.name.toLowerCase().contains('channel') && 
             p.name.toLowerCase().contains('count'),
      orElse: () => null,
    );
    
    if (channelCountParam == null) return ports;
    
    final channelCount = slot.getParameterValue(channelCountParam.id) ?? 
                        channelCountParam.defaultValue ?? 1;
    
    // Expand per-channel parameters
    for (final param in algorithm.parameters) {
      if (param.scope == 'channel' && _isBusParameter(param)) {
        for (int ch = 0; ch < channelCount; ch++) {
          final currentBus = slot.getParameterValue('${param.id}_$ch') ?? 
                            param.defaultValue;
          
          ports.add(PortInfo(
            id: '${param.id}_$ch',
            name: '${param.name} ${ch + 1}',
            type: param.name.toLowerCase().contains('input') 
                  ? PortType.input 
                  : PortType.output,
            busParameterId: '${param.id}_$ch',
            currentBus: currentBus,
            channelIndex: ch,
          ));
        }
      }
    }
    
    return ports;
  }
}
```

## 2. Routing Mask to Visual Connection Mapping

### Algorithm for Interpreting Hardware Routing Masks

```dart
class RoutingMaskInterpreter {
  /// Convert hardware routing masks to visual connections
  static List<Connection> interpretRoutingMasks(
    List<RoutingInformation> routingInfoList,
    List<SlotInfo> slots,
  ) {
    final connections = <Connection>[];
    final busWriters = <int, AlgorithmSource>{}; // bus -> who writes to it
    final busReaders = <int, List<AlgorithmTarget>>{}; // bus -> who reads from it
    
    // First pass: identify all bus writers and readers
    for (final routing in routingInfoList) {
      final slot = slots[routing.algorithmIndex];
      final ports = PortExtractor.extractPorts(slot.algorithm, slot);
      
      final inputMask = routing.routingInfo[0];   // r0
      final outputMask = routing.routingInfo[1];  // r1
      final replaceMask = routing.routingInfo[2]; // r2
      
      // Check each bus
      for (int bus = 1; bus <= 28; bus++) {
        final bitMask = 1 << bus;
        
        // Check if algorithm writes to this bus
        if ((outputMask & bitMask) != 0) {
          final replaceMode = (replaceMask & bitMask) != 0;
          
          // Find which output port uses this bus
          final outputPort = ports.firstWhere(
            (p) => p.type == PortType.output && p.currentBus == bus,
            orElse: () => null,
          );
          
          if (outputPort != null) {
            busWriters[bus] = AlgorithmSource(
              algorithmIndex: routing.algorithmIndex,
              portId: outputPort.id,
              replaceMode: replaceMode,
            );
          }
        }
        
        // Check if algorithm reads from this bus
        if ((inputMask & bitMask) != 0) {
          // Find which input port uses this bus
          final inputPort = ports.firstWhere(
            (p) => p.type == PortType.input && p.currentBus == bus,
            orElse: () => null,
          );
          
          if (inputPort != null) {
            busReaders[bus] ??= [];
            busReaders[bus]!.add(AlgorithmTarget(
              algorithmIndex: routing.algorithmIndex,
              portId: inputPort.id,
            ));
          }
        }
      }
    }
    
    // Second pass: create connections for internal routing (aux buses primarily)
    for (int bus = 1; bus <= 28; bus++) {
      // Skip physical I/O buses unless they're used for internal routing
      if (bus <= 12 || (bus >= 13 && bus <= 20)) {
        // Check if this is internal routing (both writer and reader are algorithms)
        if (!busWriters.containsKey(bus) || !busReaders.containsKey(bus)) {
          continue; // Skip physical I/O connections
        }
      }
      
      if (busWriters.containsKey(bus) && busReaders.containsKey(bus)) {
        final source = busWriters[bus]!;
        
        for (final target in busReaders[bus]!) {
          // Don't create self-connections
          if (source.algorithmIndex == target.algorithmIndex) continue;
          
          connections.add(Connection(
            id: 'bus_${bus}_${source.algorithmIndex}_${target.algorithmIndex}',
            sourceAlgorithmIndex: source.algorithmIndex,
            sourcePortId: source.portId,
            targetAlgorithmIndex: target.algorithmIndex,
            targetPortId: target.portId,
            assignedBus: bus,
            replaceMode: source.replaceMode,
            isValid: true,
            edgeLabel: _generateEdgeLabel(bus, source.replaceMode),
          ));
        }
      }
    }
    
    return connections;
  }
  
  static String _generateEdgeLabel(int bus, bool replaceMode) {
    String busLabel;
    if (bus <= 12) {
      busLabel = 'I${bus}';
    } else if (bus <= 20) {
      busLabel = 'O${bus - 12}';
    } else {
      busLabel = 'A${bus - 20}';
    }
    return '$busLabel ${replaceMode ? 'R' : 'A'}';
  }
}
```

## 3. Initial Node Layout Algorithm

### Force-Directed Layout with Constraints

```dart
class NodeLayoutEngine {
  static const double NODE_WIDTH = 200.0;
  static const double NODE_HEIGHT = 120.0;
  static const double MIN_SPACING = 50.0;
  static const double CANVAS_PADDING = 100.0;
  
  /// Calculate initial positions for all nodes
  static Map<int, NodePosition> calculateInitialLayout(
    List<SlotInfo> slots,
    List<Connection> connections,
    Size canvasSize,
  ) {
    // Start with hierarchical layout based on signal flow
    final positions = _hierarchicalLayout(slots, connections, canvasSize);
    
    // Apply force-directed refinement to reduce edge crossings
    _applyForceDirectedRefinement(positions, connections);
    
    // Ensure no overlaps
    _resolveOverlaps(positions);
    
    return positions;
  }
  
  static Map<int, NodePosition> _hierarchicalLayout(
    List<SlotInfo> slots,
    List<Connection> connections,
    Size canvasSize,
  ) {
    final positions = <int, NodePosition>{};
    
    // Calculate node layers based on signal flow
    final layers = _assignLayers(slots, connections);
    final maxLayer = layers.values.fold(0, max);
    
    // Group nodes by layer
    final nodesByLayer = <int, List<int>>{};
    for (final entry in layers.entries) {
      nodesByLayer[entry.value] ??= [];
      nodesByLayer[entry.value]!.add(entry.key);
    }
    
    // Position nodes layer by layer
    final layerSpacing = (canvasSize.width - 2 * CANVAS_PADDING) / (maxLayer + 1);
    
    for (final entry in nodesByLayer.entries) {
      final layer = entry.key;
      final nodesInLayer = entry.value;
      
      final x = CANVAS_PADDING + layer * layerSpacing;
      final nodeSpacing = (canvasSize.height - 2 * CANVAS_PADDING) / 
                          (nodesInLayer.length + 1);
      
      for (int i = 0; i < nodesInLayer.length; i++) {
        final nodeIndex = nodesInLayer[i];
        final y = CANVAS_PADDING + (i + 1) * nodeSpacing;
        
        // Adjust node size based on port count
        final slot = slots[nodeIndex];
        final ports = PortExtractor.extractPorts(slot.algorithm, slot);
        final height = max(NODE_HEIGHT, 40.0 + ports.length * 20.0);
        
        positions[nodeIndex] = NodePosition(
          algorithmIndex: nodeIndex,
          x: x - NODE_WIDTH / 2,
          y: y - height / 2,
          width: NODE_WIDTH,
          height: height,
        );
      }
    }
    
    return positions;
  }
  
  static Map<int, int> _assignLayers(
    List<SlotInfo> slots,
    List<Connection> connections,
  ) {
    final layers = <int, int>{};
    final dependencies = <int, Set<int>>{};
    
    // Build dependency graph
    for (final slot in slots) {
      dependencies[slot.algorithmIndex] = {};
    }
    
    for (final conn in connections) {
      dependencies[conn.targetAlgorithmIndex]!.add(conn.sourceAlgorithmIndex);
    }
    
    // Assign layers using longest path algorithm
    int assignLayer(int node) {
      if (layers.containsKey(node)) return layers[node]!;
      
      int maxDepth = 0;
      for (final dep in dependencies[node]!) {
        maxDepth = max(maxDepth, assignLayer(dep) + 1);
      }
      
      layers[node] = maxDepth;
      return maxDepth;
    }
    
    for (final slot in slots) {
      assignLayer(slot.algorithmIndex);
    }
    
    return layers;
  }
  
  static void _applyForceDirectedRefinement(
    Map<int, NodePosition> positions,
    List<Connection> connections,
    {int iterations = 50}
  ) {
    for (int iter = 0; iter < iterations; iter++) {
      final forces = <int, Offset>{};
      
      // Initialize forces
      for (final pos in positions.values) {
        forces[pos.algorithmIndex] = Offset.zero;
      }
      
      // Apply spring forces for connected nodes
      for (final conn in connections) {
        final source = positions[conn.sourceAlgorithmIndex]!;
        final target = positions[conn.targetAlgorithmIndex]!;
        
        final sourceCenter = Offset(
          source.x + source.width / 2,
          source.y + source.height / 2,
        );
        final targetCenter = Offset(
          target.x + target.width / 2,
          target.y + target.height / 2,
        );
        
        final delta = targetCenter - sourceCenter;
        final distance = delta.distance;
        
        if (distance > 0) {
          // Ideal distance based on hierarchical layout
          final idealDistance = 250.0;
          final force = delta / distance * (distance - idealDistance) * 0.01;
          
          forces[conn.sourceAlgorithmIndex] = 
            forces[conn.sourceAlgorithmIndex]! + force;
          forces[conn.targetAlgorithmIndex] = 
            forces[conn.targetAlgorithmIndex]! - force;
        }
      }
      
      // Apply repulsion forces between all nodes
      final nodeList = positions.values.toList();
      for (int i = 0; i < nodeList.length; i++) {
        for (int j = i + 1; j < nodeList.length; j++) {
          final node1 = nodeList[i];
          final node2 = nodeList[j];
          
          final center1 = Offset(
            node1.x + node1.width / 2,
            node1.y + node1.height / 2,
          );
          final center2 = Offset(
            node2.x + node2.width / 2,
            node2.y + node2.height / 2,
          );
          
          final delta = center2 - center1;
          final distance = max(delta.distance, 10.0);
          
          final repulsion = delta / distance * (5000.0 / (distance * distance));
          
          forces[node1.algorithmIndex] = 
            forces[node1.algorithmIndex]! - repulsion;
          forces[node2.algorithmIndex] = 
            forces[node2.algorithmIndex]! + repulsion;
        }
      }
      
      // Apply forces with damping
      for (final entry in forces.entries) {
        final pos = positions[entry.key]!;
        final force = entry.value * 0.5; // Damping factor
        
        positions[entry.key] = pos.copyWith(
          x: pos.x + force.dx,
          y: pos.y + force.dy,
        );
      }
    }
  }
  
  static void _resolveOverlaps(Map<int, NodePosition> positions) {
    // Simple overlap resolution - push overlapping nodes apart
    bool hasOverlaps = true;
    int maxIterations = 10;
    
    while (hasOverlaps && maxIterations-- > 0) {
      hasOverlaps = false;
      
      final nodeList = positions.values.toList();
      for (int i = 0; i < nodeList.length; i++) {
        for (int j = i + 1; j < nodeList.length; j++) {
          final node1 = nodeList[i];
          final node2 = nodeList[j];
          
          final rect1 = Rect.fromLTWH(
            node1.x, node1.y, node1.width, node1.height);
          final rect2 = Rect.fromLTWH(
            node2.x, node2.y, node2.width, node2.height);
          
          if (rect1.overlaps(rect2)) {
            hasOverlaps = true;
            
            // Calculate push direction
            final center1 = rect1.center;
            final center2 = rect2.center;
            final delta = center2 - center1;
            
            if (delta.distance > 0) {
              final push = delta / delta.distance * MIN_SPACING;
              
              positions[node1.algorithmIndex] = node1.copyWith(
                x: node1.x - push.dx / 2,
                y: node1.y - push.dy / 2,
              );
              positions[node2.algorithmIndex] = node2.copyWith(
                x: node2.x + push.dx / 2,
                y: node2.y + push.dy / 2,
              );
            }
          }
        }
      }
    }
  }
}
```

## 4. State Synchronization Between Views

### Managing View Transitions and Hardware Updates

```dart
class ViewStateSynchronizer {
  /// Synchronize state when switching from table to node view
  static Future<NodeViewState> initializeNodeView(
    DistingState distingState,
    SettingsService settings,
  ) async {
    // Step 1: Get current routing from hardware
    final routingInfoList = distingState.buildRoutingInformation();
    
    // Step 2: Interpret routing masks to get connections
    final connections = RoutingMaskInterpreter.interpretRoutingMasks(
      routingInfoList,
      distingState.slots,
    );
    
    // Step 3: Load or calculate node positions
    Map<int, NodePosition> positions;
    final savedPositions = await settings.getNodePositions(
      distingState.currentPreset?.id,
    );
    
    if (savedPositions != null) {
      positions = savedPositions;
    } else {
      // Calculate initial layout
      final canvasSize = Size(1600, 1200); // Default canvas size
      positions = NodeLayoutEngine.calculateInitialLayout(
        distingState.slots,
        connections,
        canvasSize,
      );
    }
    
    return NodeViewState(
      nodePositions: positions,
      connections: connections,
      selectedNodes: {},
      hoveredConnection: null,
      draggedConnection: null,
      viewMode: NodeViewMode.normal,
      lastHardwareSync: DateTime.now(),
    );
  }
  
  /// Handle real-time hardware updates (10-second refresh)
  static Future<NodeViewState> syncWithHardware(
    NodeViewState currentState,
    DistingState distingState,
  ) async {
    // Get fresh routing info from hardware
    final routingInfoList = distingState.buildRoutingInformation();
    
    // Interpret new connections
    final newConnections = RoutingMaskInterpreter.interpretRoutingMasks(
      routingInfoList,
      distingState.slots,
    );
    
    // Identify changes
    final addedConnections = <Connection>[];
    final removedConnections = <Connection>[];
    final modifiedConnections = <Connection>[];
    
    // Find added connections
    for (final newConn in newConnections) {
      final existing = currentState.connections.firstWhere(
        (c) => c.id == newConn.id,
        orElse: () => null,
      );
      
      if (existing == null) {
        addedConnections.add(newConn);
      } else if (existing.assignedBus != newConn.assignedBus ||
                 existing.replaceMode != newConn.replaceMode) {
        modifiedConnections.add(newConn);
      }
    }
    
    // Find removed connections
    for (final oldConn in currentState.connections) {
      final stillExists = newConnections.any((c) => c.id == oldConn.id);
      if (!stillExists) {
        removedConnections.add(oldConn);
      }
    }
    
    // Apply changes with visual feedback
    return currentState.copyWith(
      connections: newConnections,
      changedConnections: [
        ...addedConnections.map((c) => ConnectionChange(c, ChangeType.added)),
        ...removedConnections.map((c) => ConnectionChange(c, ChangeType.removed)),
        ...modifiedConnections.map((c) => ConnectionChange(c, ChangeType.modified)),
      ],
      lastHardwareSync: DateTime.now(),
    );
  }
  
  /// Persist node positions when leaving node view
  static Future<void> saveNodeViewState(
    NodeViewState state,
    String? presetId,
    SettingsService settings,
  ) async {
    await settings.setNodePositions(presetId, state.nodePositions);
  }
}
```

## 5. Visual Feedback During Connection Dragging

### Interactive Connection Creation

```dart
class ConnectionDragHandler {
  ConnectionPreview? _preview;
  PortHit? _sourcePort;
  
  /// Handle drag start from a port
  void onDragStart(PortHit port, Offset position) {
    if (port.type == PortType.output) {
      _sourcePort = port;
      _preview = ConnectionPreview(
        sourceAlgorithmIndex: port.algorithmIndex,
        sourcePortId: port.portId,
        sourcePosition: port.position,
        targetPosition: position,
        isValid: true,
      );
    }
  }
  
  /// Update drag preview and validate
  void onDragUpdate(
    Offset position,
    List<NodePosition> nodes,
    List<Connection> existingConnections,
  ) {
    if (_preview == null || _sourcePort == null) return;
    
    // Find target port under cursor
    final targetPort = _findPortAtPosition(position, nodes);
    
    // Update preview
    _preview = _preview!.copyWith(
      targetPosition: position,
      targetAlgorithmIndex: targetPort?.algorithmIndex,
      targetPortId: targetPort?.portId,
    );
    
    // Validate connection if hovering over a port
    if (targetPort != null && targetPort.type == PortType.input) {
      final validationResult = _validateConnection(
        _sourcePort!,
        targetPort,
        existingConnections,
      );
      
      _preview = _preview!.copyWith(
        isValid: validationResult.isValid,
        validationMessage: validationResult.message,
        suggestedBus: validationResult.suggestedBus,
      );
    }
  }
  
  /// Complete connection creation
  Future<Connection?> onDragEnd(
    Offset position,
    List<NodePosition> nodes,
    DistingCubit cubit,
  ) async {
    if (_preview == null || _sourcePort == null) return null;
    
    final targetPort = _findPortAtPosition(position, nodes);
    
    if (targetPort != null && 
        targetPort.type == PortType.input &&
        _preview!.isValid) {
      
      // Create connection with bus assignment
      final busAssignment = await AutoRoutingService.assignBusForConnection(
        sourceAlgorithm: _sourcePort!.algorithm,
        sourcePortId: _sourcePort!.portId,
        targetAlgorithm: targetPort.algorithm,
        targetPortId: targetPort.portId,
        existingAssignments: cubit.state.busAssignments,
      );
      
      // Apply parameter updates
      for (final update in busAssignment.parameterUpdates) {
        await cubit.updateAlgorithmParameter(
          update.algorithmIndex,
          update.parameterId,
          update.value,
        );
      }
      
      // Refresh routing from hardware
      await cubit.refreshRouting();
      
      return Connection(
        id: busAssignment.connectionId,
        sourceAlgorithmIndex: _sourcePort!.algorithmIndex,
        sourcePortId: _sourcePort!.portId,
        targetAlgorithmIndex: targetPort.algorithmIndex,
        targetPortId: targetPort.portId,
        assignedBus: busAssignment.sourceBus,
        replaceMode: busAssignment.replaceMode,
        edgeLabel: busAssignment.edgeLabel,
        isValid: true,
      );
    }
    
    return null;
  }
  
  ValidationResult _validateConnection(
    PortHit source,
    PortHit target,
    List<Connection> existing,
  ) {
    // Check port compatibility
    if (!_arePortsCompatible(source, target)) {
      return ValidationResult(
        isValid: false,
        message: 'Incompatible port types',
      );
    }
    
    // Check for cycles
    if (_wouldCreateCycle(source.algorithmIndex, target.algorithmIndex, existing)) {
      return ValidationResult(
        isValid: false,
        message: 'Would create circular dependency',
      );
    }
    
    // Check processing order
    if (source.algorithmIndex > target.algorithmIndex && 
        !_isFeedbackConnection(source, target)) {
      return ValidationResult(
        isValid: false,
        message: 'Source must be in earlier slot',
      );
    }
    
    // Find available bus
    final suggestedBus = _findAvailableBus(existing);
    if (suggestedBus == null) {
      return ValidationResult(
        isValid: false,
        message: 'No available buses',
      );
    }
    
    return ValidationResult(
      isValid: true,
      suggestedBus: suggestedBus,
    );
  }
}

/// Visual feedback painter for connection preview
class ConnectionPreviewPainter extends CustomPainter {
  final ConnectionPreview preview;
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    
    // Color based on validity
    if (!preview.isValid) {
      paint.color = Colors.red.withOpacity(0.8);
      paint.strokeWidth = 3.0;
    } else if (preview.targetPortId != null) {
      paint.color = Colors.green.withOpacity(0.8);
      paint.strokeWidth = 3.0;
    } else {
      paint.color = Colors.blue.withOpacity(0.6);
      paint.pathEffect = ui.PathEffect.compose(
        ui.PathEffect.dashPath([10, 5], 0),
        null,
      );
    }
    
    // Draw bezier curve
    final path = Path();
    path.moveTo(preview.sourcePosition.dx, preview.sourcePosition.dy);
    
    final cp1 = Offset(
      preview.sourcePosition.dx + 100,
      preview.sourcePosition.dy,
    );
    final cp2 = Offset(
      preview.targetPosition.dx - 100,
      preview.targetPosition.dy,
    );
    
    path.cubicTo(
      cp1.dx, cp1.dy,
      cp2.dx, cp2.dy,
      preview.targetPosition.dx, preview.targetPosition.dy,
    );
    
    canvas.drawPath(path, paint);
    
    // Draw validation message if present
    if (preview.validationMessage != null) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: preview.validationMessage,
          style: TextStyle(
            color: preview.isValid ? Colors.green : Colors.red,
            fontSize: 12,
            backgroundColor: Colors.black87,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        preview.targetPosition + Offset(10, -20),
      );
    }
    
    // Draw suggested bus label
    if (preview.suggestedBus != null) {
      final busLabel = _getBusLabel(preview.suggestedBus!);
      final labelPainter = TextPainter(
        text: TextSpan(
          text: busLabel,
          style: TextStyle(
            color: Colors.white,
            fontSize: 10,
            backgroundColor: Colors.black54,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      labelPainter.layout();
      
      // Position at midpoint
      final midPoint = Offset(
        (preview.sourcePosition.dx + preview.targetPosition.dx) / 2,
        (preview.sourcePosition.dy + preview.targetPosition.dy) / 2,
      );
      labelPainter.paint(canvas, midPoint);
    }
  }
  
  @override
  bool shouldRepaint(ConnectionPreviewPainter oldDelegate) {
    return preview != oldDelegate.preview;
  }
}
```

## 6. Settings Persistence for Node Positions

### Extended Settings Service

```dart
extension NodeViewSettings on SettingsService {
  static const String _nodePositionsPrefix = 'node_positions_';
  static const String _nodeViewModeKey = 'node_view_mode';
  static const String _nodeViewZoomKey = 'node_view_zoom';
  static const String _nodeViewPanKey = 'node_view_pan';
  
  /// Save node positions for a specific preset
  Future<bool> setNodePositions(
    String? presetId,
    Map<int, NodePosition> positions,
  ) async {
    final key = '$_nodePositionsPrefix${presetId ?? 'default'}';
    final jsonList = positions.values.map((p) => {
      'index': p.algorithmIndex,
      'x': p.x,
      'y': p.y,
      'width': p.width,
      'height': p.height,
    }).toList();
    
    final jsonString = jsonEncode(jsonList);
    return await _prefs?.setString(key, jsonString) ?? false;
  }
  
  /// Load node positions for a specific preset
  Map<int, NodePosition>? getNodePositions(String? presetId) {
    final key = '$_nodePositionsPrefix${presetId ?? 'default'}';
    final jsonString = _prefs?.getString(key);
    
    if (jsonString == null) return null;
    
    try {
      final jsonList = jsonDecode(jsonString) as List;
      final positions = <int, NodePosition>{};
      
      for (final json in jsonList) {
        final index = json['index'] as int;
        positions[index] = NodePosition(
          algorithmIndex: index,
          x: json['x'] as double,
          y: json['y'] as double,
          width: json['width'] as double,
          height: json['height'] as double,
        );
      }
      
      return positions;
    } catch (e) {
      debugPrint('Failed to load node positions: $e');
      return null;
    }
  }
  
  /// Clear saved positions for a preset
  Future<bool> clearNodePositions(String? presetId) async {
    final key = '$_nodePositionsPrefix${presetId ?? 'default'}';
    return await _prefs?.remove(key) ?? false;
  }
  
  /// Save view state (zoom, pan)
  Future<void> saveNodeViewState({
    required double zoom,
    required Offset pan,
    required bool isNodeView,
  }) async {
    await _prefs?.setDouble(_nodeViewZoomKey, zoom);
    await _prefs?.setDouble('${_nodeViewPanKey}_x', pan.dx);
    await _prefs?.setDouble('${_nodeViewPanKey}_y', pan.dy);
    await _prefs?.setBool(_nodeViewModeKey, isNodeView);
  }
  
  /// Load view state
  NodeViewSettings loadNodeViewState() {
    return NodeViewSettings(
      zoom: _prefs?.getDouble(_nodeViewZoomKey) ?? 1.0,
      pan: Offset(
        _prefs?.getDouble('${_nodeViewPanKey}_x') ?? 0.0,
        _prefs?.getDouble('${_nodeViewPanKey}_y') ?? 0.0,
      ),
      isNodeView: _prefs?.getBool(_nodeViewModeKey) ?? false,
    );
  }
}
```

## Key Implementation Patterns

### 1. Port Identification
- Check for `busIdRef` in port definitions
- Look for parameters with `unit: "bus"` or `type: "bus"`
- Handle per-channel expansion for multi-channel algorithms

### 2. Connection Validation
- Always check processing order constraints
- Detect cycles using DFS
- Validate port type compatibility
- Ensure bus availability

### 3. Visual Feedback
- Use opacity changes during drag operations
- Color code connections by validity (green=valid, red=invalid)
- Show edge labels with bus and mode
- Provide hover tooltips for validation messages

### 4. Performance Optimization
- Use RepaintBoundary to isolate redraw regions
- Cache layout calculations
- Debounce position updates during dragging
- Implement viewport culling for large graphs

### 5. State Management
- Maintain separation between visual state and hardware state
- Use optimistic updates with eventual consistency
- Persist positions per preset
- Handle real-time hardware updates gracefully