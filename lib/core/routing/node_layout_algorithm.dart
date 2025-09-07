import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:nt_helper/core/routing/models/port.dart';
import 'package:nt_helper/core/routing/models/connection.dart';
import 'package:nt_helper/cubit/routing_editor_state.dart';

/// Represents a 2D position for a node in the routing canvas
class NodePosition {
  final double x;
  final double y;

  const NodePosition({required this.x, required this.y});

  @override
  bool operator ==(Object other) =>
      other is NodePosition && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);

  @override
  String toString() => 'NodePosition(x: $x, y: $y)';

  NodePosition copyWith({double? x, double? y}) {
    return NodePosition(x: x ?? this.x, y: y ?? this.y);
  }
}

/// Represents an overlap between two connections
class ConnectionOverlap {
  final String connection1Id;
  final String connection2Id;
  final NodePosition intersectionPoint;
  final double severity; // 0.0 to 1.0, where 1.0 is complete overlap

  const ConnectionOverlap({
    required this.connection1Id,
    required this.connection2Id,
    required this.intersectionPoint,
    required this.severity,
  });
}

/// Result of the layout algorithm calculation
class LayoutResult {
  final Map<String, NodePosition> physicalInputPositions;
  final Map<String, NodePosition> physicalOutputPositions;
  final Map<String, NodePosition> algorithmPositions;
  final List<ConnectionOverlap> reducedOverlaps;
  final double totalOverlapReduction;

  const LayoutResult({
    required this.physicalInputPositions,
    required this.physicalOutputPositions,
    required this.algorithmPositions,
    required this.reducedOverlaps,
    required this.totalOverlapReduction,
  });
}

/// Intelligent node layout algorithm for the routing editor
/// 
/// This algorithm optimizes node positioning to minimize connection overlap
/// while maintaining logical slot ordering and proper physical node placement.
class NodeLayoutAlgorithm {
  static const double canvasWidth = 800.0;
  static const double canvasHeight = 600.0;
  
  static const double physicalInputX = 50.0;
  static const double physicalOutputX = 750.0;
  static const double algorithmCenterX = 400.0;
  
  static const double nodeSpacingY = 80.0;
  static const double minimumNodeSpacing = 60.0;
  
  /// Calculate optimal layout for all nodes in the routing canvas
  LayoutResult calculateLayout({
    required List<Port> physicalInputs,
    required List<Port> physicalOutputs,
    required List<RoutingAlgorithm> algorithms,
    required List<Connection> connections,
  }) {
    debugPrint('[NodeLayoutAlgorithm] Starting layout calculation');
    debugPrint('  Physical inputs: ${physicalInputs.length}');
    debugPrint('  Physical outputs: ${physicalOutputs.length}');
    debugPrint('  Algorithms: ${algorithms.length}');
    debugPrint('  Connections: ${connections.length}');

    // Step 1: Position physical input ports on the left
    final physicalInputPositions = _positionPhysicalInputs(physicalInputs);

    // Step 2: Position physical output ports on the right
    final physicalOutputPositions = _positionPhysicalOutputs(physicalOutputs);

    // Step 3: Sort algorithms by slot index (lower indices appear higher)
    final sortedAlgorithms = List<RoutingAlgorithm>.from(algorithms);
    sortedAlgorithms.sort((a, b) => a.index.compareTo(b.index));

    // Step 4: Initial algorithm positioning with slot ordering
    final initialAlgorithmPositions = _positionAlgorithmsBySlotOrder(sortedAlgorithms);

    // Step 5: Optimize algorithm positions based on connections
    final optimizedAlgorithmPositions = optimizeNodePositionsForConnections(
      sortedAlgorithms,
      connections,
      {
        ...physicalInputPositions,
        ...physicalOutputPositions,
        ...initialAlgorithmPositions,
      },
    );

    // Extract only algorithm positions from optimized result
    final algorithmPositions = <String, NodePosition>{};
    for (final algorithm in sortedAlgorithms) {
      if (optimizedAlgorithmPositions.containsKey(algorithm.id)) {
        algorithmPositions[algorithm.id] = optimizedAlgorithmPositions[algorithm.id]!;
      }
    }

    // Step 6: Detect remaining overlaps after optimization
    final allPositions = {
      ...physicalInputPositions,
      ...physicalOutputPositions,
      ...algorithmPositions,
    };
    
    final overlapsAfterOptimization = detectConnectionOverlaps(connections, allPositions);

    debugPrint('[NodeLayoutAlgorithm] Layout calculation complete');
    debugPrint('  Algorithm positions: ${algorithmPositions.length}');
    debugPrint('  Remaining overlaps: ${overlapsAfterOptimization.length}');

    return LayoutResult(
      physicalInputPositions: physicalInputPositions,
      physicalOutputPositions: physicalOutputPositions,
      algorithmPositions: algorithmPositions,
      reducedOverlaps: overlapsAfterOptimization,
      totalOverlapReduction: _calculateOverlapReduction(connections, allPositions),
    );
  }

  /// Position physical input ports vertically on the left side
  Map<String, NodePosition> _positionPhysicalInputs(List<Port> physicalInputs) {
    final positions = <String, NodePosition>{};
    
    if (physicalInputs.isEmpty) return positions;
    
    final totalHeight = (physicalInputs.length - 1) * nodeSpacingY;
    final startY = (canvasHeight - totalHeight) / 2;
    
    for (int i = 0; i < physicalInputs.length; i++) {
      positions[physicalInputs[i].id] = NodePosition(
        x: physicalInputX,
        y: startY + (i * nodeSpacingY),
      );
    }
    
    return positions;
  }

  /// Position physical output ports vertically on the right side
  Map<String, NodePosition> _positionPhysicalOutputs(List<Port> physicalOutputs) {
    final positions = <String, NodePosition>{};
    
    if (physicalOutputs.isEmpty) return positions;
    
    final totalHeight = (physicalOutputs.length - 1) * nodeSpacingY;
    final startY = (canvasHeight - totalHeight) / 2;
    
    for (int i = 0; i < physicalOutputs.length; i++) {
      positions[physicalOutputs[i].id] = NodePosition(
        x: physicalOutputX,
        y: startY + (i * nodeSpacingY),
      );
    }
    
    return positions;
  }

  /// Position algorithms in the center based on slot ordering
  /// Lower slot indices (index 0, 1, 2...) appear higher (smaller Y values)
  Map<String, NodePosition> _positionAlgorithmsBySlotOrder(List<RoutingAlgorithm> sortedAlgorithms) {
    final positions = <String, NodePosition>{};
    
    if (sortedAlgorithms.isEmpty) return positions;
    
    final totalHeight = (sortedAlgorithms.length - 1) * nodeSpacingY;
    final startY = (canvasHeight - totalHeight) / 2;
    
    for (int i = 0; i < sortedAlgorithms.length; i++) {
      positions[sortedAlgorithms[i].id] = NodePosition(
        x: algorithmCenterX,
        y: startY + (i * nodeSpacingY),
      );
    }
    
    return positions;
  }

  /// Detect connection overlaps between line segments
  List<ConnectionOverlap> detectConnectionOverlaps(
    List<Connection> connections,
    Map<String, NodePosition> nodePositions,
  ) {
    final overlaps = <ConnectionOverlap>[];
    
    // Get connections that have both endpoints positioned
    final validConnections = connections.where((connection) {
      return nodePositions.containsKey(connection.sourcePortId) &&
          nodePositions.containsKey(connection.destinationPortId);
    }).toList();
    
    // Check each pair of connections for intersection
    for (int i = 0; i < validConnections.length; i++) {
      for (int j = i + 1; j < validConnections.length; j++) {
        final conn1 = validConnections[i];
        final conn2 = validConnections[j];
        
        final pos1Start = nodePositions[conn1.sourcePortId]!;
        final pos1End = nodePositions[conn1.destinationPortId]!;
        final pos2Start = nodePositions[conn2.sourcePortId]!;
        final pos2End = nodePositions[conn2.destinationPortId]!;
        
        final intersection = _findLineIntersection(
          pos1Start, pos1End,
          pos2Start, pos2End,
        );
        
        if (intersection != null) {
          final severity = _calculateOverlapSeverity(
            pos1Start, pos1End,
            pos2Start, pos2End,
            intersection,
          );
          
          overlaps.add(ConnectionOverlap(
            connection1Id: conn1.id,
            connection2Id: conn2.id,
            intersectionPoint: intersection,
            severity: severity,
          ));
        }
      }
    }
    
    return overlaps;
  }

  /// Find intersection point between two line segments
  NodePosition? _findLineIntersection(
    NodePosition line1Start,
    NodePosition line1End,
    NodePosition line2Start,
    NodePosition line2End,
  ) {
    final x1 = line1Start.x;
    final y1 = line1Start.y;
    final x2 = line1End.x;
    final y2 = line1End.y;
    final x3 = line2Start.x;
    final y3 = line2Start.y;
    final x4 = line2End.x;
    final y4 = line2End.y;

    final denominator = (x1 - x2) * (y3 - y4) - (y1 - y2) * (x3 - x4);
    if (denominator.abs() < 1e-10) return null; // Lines are parallel
    
    final t = ((x1 - x3) * (y3 - y4) - (y1 - y3) * (x3 - x4)) / denominator;
    final u = -((x1 - x2) * (y1 - y3) - (y1 - y2) * (x1 - x3)) / denominator;
    
    // Check if intersection is within both line segments
    if (t >= 0 && t <= 1 && u >= 0 && u <= 1) {
      return NodePosition(
        x: x1 + t * (x2 - x1),
        y: y1 + t * (y2 - y1),
      );
    }
    
    return null;
  }

  /// Calculate overlap severity based on intersection characteristics
  double _calculateOverlapSeverity(
    NodePosition line1Start,
    NodePosition line1End,
    NodePosition line2Start,
    NodePosition line2End,
    NodePosition intersection,
  ) {
    // Calculate how close the intersection is to the midpoint of each line
    final line1MidX = (line1Start.x + line1End.x) / 2;
    final line1MidY = (line1Start.y + line1End.y) / 2;
    final line2MidX = (line2Start.x + line2End.x) / 2;
    final line2MidY = (line2Start.y + line2End.y) / 2;
    
    final line1Length = math.sqrt(
      math.pow(line1End.x - line1Start.x, 2) + math.pow(line1End.y - line1Start.y, 2),
    );
    final line2Length = math.sqrt(
      math.pow(line2End.x - line2Start.x, 2) + math.pow(line2End.y - line2Start.y, 2),
    );
    
    final distToLine1Mid = math.sqrt(
      math.pow(intersection.x - line1MidX, 2) + math.pow(intersection.y - line1MidY, 2),
    );
    final distToLine2Mid = math.sqrt(
      math.pow(intersection.x - line2MidX, 2) + math.pow(intersection.y - line2MidY, 2),
    );
    
    // Higher severity when intersection is near the middle of both lines
    final line1Severity = 1.0 - (distToLine1Mid / (line1Length / 2)).clamp(0.0, 1.0);
    final line2Severity = 1.0 - (distToLine2Mid / (line2Length / 2)).clamp(0.0, 1.0);
    
    return (line1Severity + line2Severity) / 2;
  }

  /// Optimize node positions to minimize connection overlaps
  Map<String, NodePosition> optimizeNodePositionsForConnections(
    List<RoutingAlgorithm> algorithms,
    List<Connection> connections,
    Map<String, NodePosition> initialPositions,
  ) {
    final optimizedPositions = Map<String, NodePosition>.from(initialPositions);
    
    if (algorithms.isEmpty || connections.isEmpty) {
      return optimizedPositions;
    }
    
    // Multiple optimization passes to reduce overlaps
    const maxIterations = 5;
    double previousOverlapCount = double.infinity;
    
    for (int iteration = 0; iteration < maxIterations; iteration++) {
      bool positionsChanged = false;
      
      // Try to optimize each algorithm's position
      for (final algorithm in algorithms) {
        final currentPos = optimizedPositions[algorithm.id];
        if (currentPos == null) continue;
        
        final bestPosition = _findOptimalPositionForAlgorithm(
          algorithm,
          connections,
          optimizedPositions,
        );
        
        // Only update if position significantly changes
        final distance = math.sqrt(
          math.pow(bestPosition.x - currentPos.x, 2) + 
          math.pow(bestPosition.y - currentPos.y, 2),
        );
        
        if (distance > 10.0) { // Minimum distance threshold for changes
          optimizedPositions[algorithm.id] = bestPosition;
          positionsChanged = true;
        }
      }
      
      // Check for convergence
      final currentOverlaps = detectConnectionOverlaps(connections, optimizedPositions);
      final currentOverlapCount = currentOverlaps.length.toDouble();
      
      if (!positionsChanged || currentOverlapCount >= previousOverlapCount) {
        debugPrint('[NodeLayoutAlgorithm] Optimization converged at iteration $iteration');
        break;
      }
      
      previousOverlapCount = currentOverlapCount;
    }
    
    return optimizedPositions;
  }

  /// Find optimal position for a specific algorithm based on its connections
  NodePosition _findOptimalPositionForAlgorithm(
    RoutingAlgorithm algorithm,
    List<Connection> connections,
    Map<String, NodePosition> allPositions,
  ) {
    // Find all connections involving this algorithm
    final algorithmConnections = connections.where((connection) {
      final sourceIsAlgoPort = algorithm.inputPorts.any((port) => port.id == connection.sourcePortId) ||
          algorithm.outputPorts.any((port) => port.id == connection.sourcePortId);
      final destIsAlgoPort = algorithm.inputPorts.any((port) => port.id == connection.destinationPortId) ||
          algorithm.outputPorts.any((port) => port.id == connection.destinationPortId);
      
      return sourceIsAlgoPort || destIsAlgoPort;
    }).toList();
    
    if (algorithmConnections.isEmpty) {
      // No connections, keep original position based on slot order
      return allPositions[algorithm.id] ?? NodePosition(x: algorithmCenterX, y: 100.0 + algorithm.index * nodeSpacingY);
    }
    
    // Calculate center of mass for connected nodes
    var totalX = 0.0;
    var totalY = 0.0;
    var connectedNodeCount = 0;
    
    for (final connection in algorithmConnections) {
      // Check source port
      final sourcePos = allPositions[connection.sourcePortId];
      if (sourcePos != null) {
        totalX += sourcePos.x;
        totalY += sourcePos.y;
        connectedNodeCount++;
      }
      
      // Check destination port
      final destPos = allPositions[connection.destinationPortId];
      if (destPos != null) {
        totalX += destPos.x;
        totalY += destPos.y;
        connectedNodeCount++;
      }
    }
    
    if (connectedNodeCount == 0) {
      return allPositions[algorithm.id] ?? NodePosition(x: algorithmCenterX, y: 100.0 + algorithm.index * nodeSpacingY);
    }
    
    // Calculate ideal position as center of mass
    final idealX = totalX / connectedNodeCount;
    final idealY = totalY / connectedNodeCount;
    
    // Constrain position to reasonable bounds and maintain some slot ordering influence
    final slotOrderY = 100.0 + algorithm.index * nodeSpacingY;
    final constrainedX = idealX.clamp(150.0, canvasWidth - 150.0);
    final constrainedY = (idealY * 0.7 + slotOrderY * 0.3).clamp(50.0, canvasHeight - 50.0);
    
    return NodePosition(x: constrainedX, y: constrainedY);
  }

  /// Calculate total overlap reduction achieved by the layout
  double _calculateOverlapReduction(
    List<Connection> connections,
    Map<String, NodePosition> finalPositions,
  ) {
    if (connections.isEmpty) return 0.0;
    
    // For now, return a simple metric based on connection spread
    // In a more sophisticated implementation, this could compare against
    // an initial layout and measure actual overlap reduction
    
    final overlaps = detectConnectionOverlaps(connections, finalPositions);
    final overlapRatio = overlaps.length / connections.length.clamp(1, double.infinity);
    
    return (1.0 - overlapRatio).clamp(0.0, 1.0);
  }
}