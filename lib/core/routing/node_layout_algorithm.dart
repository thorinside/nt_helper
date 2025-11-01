import 'dart:math' as math;
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
  final Map<String, NodePosition> es5InputPositions;
  final Map<String, NodePosition> algorithmPositions;
  final List<ConnectionOverlap> reducedOverlaps;
  final double totalOverlapReduction;

  const LayoutResult({
    required this.physicalInputPositions,
    required this.physicalOutputPositions,
    required this.es5InputPositions,
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
  static const double canvasWidth = 5000.0;
  static const double canvasHeight = 5000.0;

  static const double physicalInputX = 1700.0; // Left side, centered
  static const double physicalOutputX = 3300.0; // Right side, centered
  static const double algorithmCenterX = 2500.0; // Center of canvas

  static const double nodeSpacingY = 80.0;
  static const double minimumNodeSpacing = 60.0;

  /// Calculate optimal layout for all nodes in the routing canvas
  LayoutResult calculateLayout({
    required List<Port> physicalInputs,
    required List<Port> physicalOutputs,
    List<Port> es5Inputs = const [],
    required List<RoutingAlgorithm> algorithms,
    required List<Connection> connections,
  }) {
    // Step 1: Sort algorithms by slot index (lower indices appear higher)
    final sortedAlgorithms = List<RoutingAlgorithm>.from(algorithms);
    sortedAlgorithms.sort((a, b) => a.index.compareTo(b.index));

    // Step 2: Analyze connections to determine optimal column placement
    final columnAssignments = _assignAlgorithmsToColumns(
      sortedAlgorithms,
      connections,
    );

    // Step 3: Position algorithms based on column assignments and slot ordering
    final initialAlgorithmPositions = _positionAlgorithmsByColumn(
      sortedAlgorithms,
      columnAssignments,
    );

    // Step 4: Optimize algorithm positions based on connections
    final optimizedAlgorithmPositions = optimizeNodePositionsForConnections(
      sortedAlgorithms,
      connections,
      initialAlgorithmPositions,
    );

    // Extract only algorithm positions from optimized result
    final algorithmPositions = <String, NodePosition>{};
    for (final algorithm in sortedAlgorithms) {
      if (optimizedAlgorithmPositions.containsKey(algorithm.id)) {
        algorithmPositions[algorithm.id] =
            optimizedAlgorithmPositions[algorithm.id]!;
      }
    }

    // Step 5: Position physical I/O nodes based on algorithm bounding box
    final physicalInputPositions = _positionPhysicalInputsRelativeToAlgorithms(
      physicalInputs,
      algorithmPositions,
    );

    final physicalOutputPositions =
        _positionPhysicalOutputsRelativeToAlgorithms(
          physicalOutputs,
          algorithmPositions,
          sortedAlgorithms,
        );

    final es5InputPositions = _positionEs5InputsRelativeToAlgorithms(
      es5Inputs,
      algorithmPositions,
    );

    // Step 6: Detect remaining overlaps after optimization
    final allPositions = {
      ...physicalInputPositions,
      ...physicalOutputPositions,
      ...es5InputPositions,
      ...algorithmPositions,
    };

    final overlapsAfterOptimization = detectConnectionOverlaps(
      connections,
      allPositions,
    );

    return LayoutResult(
      physicalInputPositions: physicalInputPositions,
      physicalOutputPositions: physicalOutputPositions,
      es5InputPositions: es5InputPositions,
      algorithmPositions: algorithmPositions,
      reducedOverlaps: overlapsAfterOptimization,
      totalOverlapReduction: _calculateOverlapReduction(
        connections,
        allPositions,
      ),
    );
  }

  /// Position physical input node relative to algorithm bounding box
  Map<String, NodePosition> _positionPhysicalInputsRelativeToAlgorithms(
    List<Port> physicalInputs,
    Map<String, NodePosition> algorithmPositions,
  ) {
    final positions = <String, NodePosition>{};

    if (physicalInputs.isEmpty || algorithmPositions.isEmpty) return positions;

    const double gridSize = 50.0;
    const double physicalNodeWidthInGrids =
        3.0; // Physical I/O nodes are narrower ~150px
    const double gapInGrids =
        1.0; // 1.0 * 50 = 50px gap to algorithms (1 grid square)

    // Calculate algorithm bounding box
    double minX = double.infinity;
    double maxX = double.negativeInfinity;
    double minY = double.infinity;
    double maxY = double.negativeInfinity;

    for (final pos in algorithmPositions.values) {
      if (pos.x < minX) minX = pos.x;
      if (pos.x > maxX) maxX = pos.x;
      if (pos.y < minY) minY = pos.y;
      if (pos.y > maxY) maxY = pos.y;
    }

    // No need to add width here as minX already represents the left edge of algorithms
    // Add approximate node height for bottom edge
    maxY += 3.0 * gridSize; // Approximate node height

    // Calculate height of physical inputs node based on number of ports
    // Each port takes about 30px, plus header and padding
    final physicalNodeHeight =
        (physicalInputs.length * 30.0 + 60.0); // Header + padding

    // Position physical inputs to the left with 1 grid square gap
    final x =
        ((minX - (physicalNodeWidthInGrids + gapInGrids) * gridSize) / gridSize)
            .round() *
        gridSize;

    // Center vertically relative to algorithm bounding box
    // Account for the physical node's own height
    final algorithmCenterY = (minY + maxY) / 2;
    final y =
        ((algorithmCenterY - physicalNodeHeight / 2) / gridSize).round() *
        gridSize;

    positions['physical_inputs'] = NodePosition(x: x, y: y);

    return positions;
  }

  /// Position ES-5 input node below physical outputs (right side)
  Map<String, NodePosition> _positionEs5InputsRelativeToAlgorithms(
    List<Port> es5Inputs,
    Map<String, NodePosition> algorithmPositions,
  ) {
    final positions = <String, NodePosition>{};

    if (es5Inputs.isEmpty || algorithmPositions.isEmpty) return positions;

    const double gridSize = 50.0;
    const double gapInGrids = 1.0;
    const double verticalGapBetweenNodes =
        100.0; // Gap between physical outputs and ES-5

    // Calculate algorithm bounding box
    double minX = double.infinity;
    double maxX = double.negativeInfinity;
    double minY = double.infinity;
    double maxY = double.negativeInfinity;

    for (final pos in algorithmPositions.values) {
      if (pos.x < minX) minX = pos.x;
      if (pos.x > maxX) maxX = pos.x;
      if (pos.y < minY) minY = pos.y;
      if (pos.y > maxY) maxY = pos.y;
    }

    maxY += 3.0 * gridSize;

    // Position ES-5 at same X as physical outputs (right side)
    // Use similar logic as physical outputs positioning
    final algorithmWidth = 250.0; // Default estimate
    final physicalOutputsX =
        ((maxX + algorithmWidth + gapInGrids * gridSize) / gridSize).round() *
        gridSize;

    final x = physicalOutputsX;

    // Position below physical outputs
    // Estimate physical outputs height and add gap
    final physicalOutputsEstimatedHeight = 8 * 30.0 + 60.0; // 8 outputs typical
    final algorithmCenterY = (minY + maxY) / 2;
    final physicalOutputsY =
        algorithmCenterY - physicalOutputsEstimatedHeight / 2;

    final y =
        ((physicalOutputsY +
                    physicalOutputsEstimatedHeight +
                    verticalGapBetweenNodes) /
                gridSize)
            .round() *
        gridSize;

    positions['es5_node'] = NodePosition(x: x, y: y);

    return positions;
  }

  /// Position physical output node relative to algorithm bounding box
  Map<String, NodePosition> _positionPhysicalOutputsRelativeToAlgorithms(
    List<Port> physicalOutputs,
    Map<String, NodePosition> algorithmPositions,
    List<RoutingAlgorithm> algorithms,
  ) {
    final positions = <String, NodePosition>{};

    if (physicalOutputs.isEmpty || algorithmPositions.isEmpty) return positions;

    const double gridSize = 50.0;
    const double gapInGrids = 1.0; // 50px gap to algorithms (1 grid square)

    // Calculate algorithm bounding box and find rightmost algorithm
    double minX = double.infinity;
    double maxX = double.negativeInfinity;
    double minY = double.infinity;
    double maxY = double.negativeInfinity;
    String? rightmostAlgorithmId;

    for (final entry in algorithmPositions.entries) {
      final pos = entry.value;
      if (pos.x < minX) minX = pos.x;
      if (pos.x >= maxX) {
        maxX = pos.x;
        rightmostAlgorithmId = entry.key;
      }
      if (pos.y < minY) minY = pos.y;
      if (pos.y > maxY) maxY = pos.y;
    }

    // Find the rightmost algorithm and estimate its width
    double algorithmWidth = 250.0; // Default estimate
    if (rightmostAlgorithmId != null) {
      final rightmostAlgorithm = algorithms.firstWhere(
        (a) => a.id == rightmostAlgorithmId,
        orElse: () => algorithms.first,
      );
      // Use the same estimation logic as in _positionAlgorithmsByColumn
      final titleWidth = rightmostAlgorithm.algorithm.name.length * 8.0 + 150.0;

      double maxLabelWidth = 100.0;
      for (final port in rightmostAlgorithm.inputPorts) {
        maxLabelWidth = math.max(maxLabelWidth, port.name.length * 7.0);
      }
      for (final port in rightmostAlgorithm.outputPorts) {
        maxLabelWidth = math.max(maxLabelWidth, port.name.length * 7.0);
      }

      final portAreaWidth = maxLabelWidth * 2 + 100.0;
      algorithmWidth = math.max(math.max(titleWidth, portAreaWidth), 200.0);
    }

    maxX += algorithmWidth;
    // Add approximate node height for bottom edge
    maxY += 3.0 * gridSize; // Approximate node height

    // Calculate height of physical outputs node based on number of ports
    // Each port takes about 30px, plus header and padding
    final physicalNodeHeight =
        (physicalOutputs.length * 30.0 + 60.0); // Header + padding

    // Position physical outputs to the right with 1 grid square gap
    final x = ((maxX + gapInGrids * gridSize) / gridSize).round() * gridSize;

    // Center vertically relative to algorithm bounding box
    // Account for the physical node's own height
    final algorithmCenterY = (minY + maxY) / 2;
    final y =
        ((algorithmCenterY - physicalNodeHeight / 2) / gridSize).round() *
        gridSize;

    positions['physical_outputs'] = NodePosition(x: x, y: y);

    return positions;
  }

  /// Analyze connections to determine which column each algorithm should be in,
  /// minimizing right-to-left (backtracking) edges. Vertical slot order is
  /// enforced elsewhere and not changed here.
  /// Returns a map of algorithm ID to column index (0 = leftmost)
  Map<String, int> _assignAlgorithmsToColumns(
    List<RoutingAlgorithm> algorithms,
    List<Connection> connections,
  ) {
    final assignments = <String, int>{};

    if (algorithms.isEmpty) return assignments;

    // Build helpers
    final idByPort = <String, String>{}; // portId -> algorithmId
    final indexById = <String, int>{};
    for (final a in algorithms) {
      indexById[a.id] = a.index;
      for (final p in a.inputPorts) {
        idByPort[p.id] = a.id;
      }
      for (final p in a.outputPorts) {
        idByPort[p.id] = a.id;
      }
    }

    // Separate forward edges (slot increases) and feedback edges (slot decreases)
    final forward = <String, Set<String>>{}; // u -> {v}
    final feedback = <String, Set<String>>{}; // u -> {v}
    for (final a in algorithms) {
      forward[a.id] = {};
      feedback[a.id] = {};
    }
    for (final c in connections) {
      if (c.sourcePortId.contains('hw_') ||
          c.destinationPortId.contains('hw_')) {
        continue;
      }
      final u = idByPort[c.sourcePortId];
      final v = idByPort[c.destinationPortId];
      if (u == null || v == null || u == v) continue;
      final ui = indexById[u] ?? 0;
      final vi = indexById[v] ?? 0;
      if (ui <= vi) {
        forward[u]!.add(v);
      } else {
        feedback[u]!.add(v);
      }
    }

    // Initial columns: longest path depth using only forward edges
    final memo = <String, int>{};
    int depthOf(String id) {
      if (memo.containsKey(id)) return memo[id]!;
      int best = 0;
      for (final v in forward[id]!) {
        best = math.max(best, depthOf(v) + 1);
      }
      memo[id] = best;
      return best;
    }

    for (final a in algorithms) {
      assignments[a.id] = depthOf(a.id);
    }

    // Iteratively reduce backtracking by pulling sources left, while
    // re-enforcing forward constraints (v >= u + 1 for forward edges)
    bool changed = true;
    int iterations = 0;
    while (changed && iterations < 10) {
      changed = false;
      iterations++;

      // Pull sources of feedback edges leftwards up to their dest column
      for (final u in feedback.keys) {
        final uCol = assignments[u] ?? 0;
        for (final v in feedback[u]!) {
          final vCol = assignments[v] ?? 0;
          if (uCol > vCol) {
            assignments[u] = vCol;
            changed = true;
          }
        }
      }

      // Re-enforce forward constraints
      for (final u in forward.keys) {
        final uCol = assignments[u] ?? 0;
        for (final v in forward[u]!) {
          final desired = uCol + 1;
          if ((assignments[v] ?? 0) < desired) {
            assignments[v] = desired;
            changed = true;
          }
        }
      }
    }

    // Normalize columns to 0..N-1 (dense)
    final unique = assignments.values.toSet().toList()..sort();
    final remap = <int, int>{};
    for (var i = 0; i < unique.length; i++) {
      remap[unique[i]] = i;
    }
    for (final id in assignments.keys) {
      assignments[id] = remap[assignments[id]!]!;
    }

    return assignments;
  }

  /// Calculate the maximum dependency depth for an algorithm (memoized)
  // ignore: unused_element
  int _calculateMaxDependencyDepth(
    String algorithmId,
    Map<String, Set<String>> dependencies,
    Map<String, int> memo,
  ) {
    // Return memoized result if available
    if (memo.containsKey(algorithmId)) {
      return memo[algorithmId]!;
    }

    final deps = dependencies[algorithmId] ?? {};
    if (deps.isEmpty) {
      // No dependencies means depth 0 (leftmost column)
      memo[algorithmId] = 0;
      return 0;
    }

    // Find the maximum depth among all dependencies
    int maxDepth = 0;
    for (final depId in deps) {
      final depDepth = _calculateMaxDependencyDepth(depId, dependencies, memo);
      if (depDepth >= maxDepth) {
        maxDepth =
            depDepth +
            1; // This node is one level deeper than its deepest dependency
      }
    }

    memo[algorithmId] = maxDepth;
    return maxDepth;
  }

  /// Position algorithms based on column assignments and slot ordering
  Map<String, NodePosition> _positionAlgorithmsByColumn(
    List<RoutingAlgorithm> sortedAlgorithms,
    Map<String, int> columnAssignments,
  ) {
    final positions = <String, NodePosition>{};

    if (sortedAlgorithms.isEmpty) return positions;

    // Grid-based spacing (compact + non-overlapping using estimated sizes)
    const double gridSize = 50.0;
    const double colGapPx =
        50.0; // min horizontal gap between columns (1 grid square)
    const double rowGapPx =
        50.0; // min vertical gap between algorithms (1 grid square)

    // Estimate node sizes from port counts and algorithm name
    double estimateWidth(RoutingAlgorithm a) {
      // Algorithm nodes use IntrinsicWidth, so they size to content
      // Title bar has: icon(24) + gap(8) + text + spacer + buttons(~100)
      // Port area has: labels on both sides + ports + padding

      // Estimate based on algorithm name with typical font metrics
      final titleWidth =
          a.algorithm.name.length * 8.0 + 150.0; // name + icons/buttons

      // Estimate based on longest port label
      double maxLabelWidth = 100.0; // minimum for short labels
      for (final port in a.inputPorts) {
        maxLabelWidth = math.max(maxLabelWidth, port.name.length * 7.0);
      }
      for (final port in a.outputPorts) {
        maxLabelWidth = math.max(maxLabelWidth, port.name.length * 7.0);
      }

      // Port area width: left labels + gap + ports + gap + right labels + padding
      final portAreaWidth = maxLabelWidth * 2 + 100.0;

      // Use the larger of title width or port area width
      return math.max(math.max(titleWidth, portAreaWidth), 200.0);
    }

    double estimateHeight(RoutingAlgorithm a) {
      const header = 52.0;
      const padding = 16.0;
      const row = 28.0;
      final rows = math.max(a.inputPorts.length, a.outputPorts.length);
      return header + padding + rows * row;
    }

    // Determine number of columns
    int maxColumn = 0;
    for (final col in columnAssignments.values) {
      if (col > maxColumn) maxColumn = col;
    }

    // Column widths based on widest node in each column
    final columnMaxWidth = List<double>.filled(maxColumn + 1, 0.0);
    for (final a in sortedAlgorithms) {
      final c = columnAssignments[a.id] ?? 0;
      columnMaxWidth[c] = math.max(columnMaxWidth[c], estimateWidth(a));
    }

    // Column positions centered horizontally
    double totalColumnsWidth = 0.0;
    for (var c = 0; c <= maxColumn; c++) {
      totalColumnsWidth += columnMaxWidth[c];
      if (c < maxColumn) totalColumnsWidth += colGapPx;
    }
    final startX = (canvasWidth / 2) - (totalColumnsWidth / 2);
    final columnLeftX = List<double>.filled(maxColumn + 1, 0.0);
    double runX = startX;
    for (var c = 0; c <= maxColumn; c++) {
      columnLeftX[c] = runX;
      runX += columnMaxWidth[c] + (c < maxColumn ? colGapPx : 0.0);
    }

    // Total stacked height for vertical centering (strict slot order)
    double totalHeight = 0.0;
    for (var i = 0; i < sortedAlgorithms.length; i++) {
      totalHeight += estimateHeight(sortedAlgorithms[i]);
      if (i < sortedAlgorithms.length - 1) totalHeight += rowGapPx;
    }
    final baseY = (canvasHeight / 2) - (totalHeight / 2);

    // Place algorithms in slot order, centered within their columns, no overlaps
    double yCursor = baseY;
    for (final a in sortedAlgorithms) {
      final c = columnAssignments[a.id] ?? 0;
      final w = estimateWidth(a);
      final h = estimateHeight(a);
      final left = columnLeftX[c] + (columnMaxWidth[c] - w) / 2;
      final xSnap = (left / gridSize).round() * gridSize;
      final ySnap = (yCursor / gridSize).round() * gridSize;
      positions[a.id] = NodePosition(x: xSnap, y: ySnap);
      yCursor += h + rowGapPx;
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
          pos1Start,
          pos1End,
          pos2Start,
          pos2End,
        );

        if (intersection != null) {
          final severity = _calculateOverlapSeverity(
            pos1Start,
            pos1End,
            pos2Start,
            pos2End,
            intersection,
          );

          overlaps.add(
            ConnectionOverlap(
              connection1Id: conn1.id,
              connection2Id: conn2.id,
              intersectionPoint: intersection,
              severity: severity,
            ),
          );
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
      return NodePosition(x: x1 + t * (x2 - x1), y: y1 + t * (y2 - y1));
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
      math.pow(line1End.x - line1Start.x, 2) +
          math.pow(line1End.y - line1Start.y, 2),
    );
    final line2Length = math.sqrt(
      math.pow(line2End.x - line2Start.x, 2) +
          math.pow(line2End.y - line2Start.y, 2),
    );

    final distToLine1Mid = math.sqrt(
      math.pow(intersection.x - line1MidX, 2) +
          math.pow(intersection.y - line1MidY, 2),
    );
    final distToLine2Mid = math.sqrt(
      math.pow(intersection.x - line2MidX, 2) +
          math.pow(intersection.y - line2MidY, 2),
    );

    // Higher severity when intersection is near the middle of both lines
    final line1Severity =
        1.0 - (distToLine1Mid / (line1Length / 2)).clamp(0.0, 1.0);
    final line2Severity =
        1.0 - (distToLine2Mid / (line2Length / 2)).clamp(0.0, 1.0);

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

    // Skip optimization for now since we're focusing on column-based layout
    // This can be enhanced later if needed
    return optimizedPositions;
  }

  /// Find optimal position for a specific algorithm based on its connections
  // ignore: unused_element
  NodePosition _findOptimalPositionForAlgorithm(
    RoutingAlgorithm algorithm,
    List<Connection> connections,
    Map<String, NodePosition> allPositions,
  ) {
    // Find all connections involving this algorithm
    final algorithmConnections = connections.where((connection) {
      final sourceIsAlgoPort =
          algorithm.inputPorts.any(
            (port) => port.id == connection.sourcePortId,
          ) ||
          algorithm.outputPorts.any(
            (port) => port.id == connection.sourcePortId,
          );
      final destIsAlgoPort =
          algorithm.inputPorts.any(
            (port) => port.id == connection.destinationPortId,
          ) ||
          algorithm.outputPorts.any(
            (port) => port.id == connection.destinationPortId,
          );

      return sourceIsAlgoPort || destIsAlgoPort;
    }).toList();

    if (algorithmConnections.isEmpty) {
      // No connections, keep original position based on slot order
      return allPositions[algorithm.id] ??
          NodePosition(
            x: algorithmCenterX,
            y: 100.0 + algorithm.index * nodeSpacingY,
          );
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
      return allPositions[algorithm.id] ??
          NodePosition(
            x: algorithmCenterX,
            y: 100.0 + algorithm.index * nodeSpacingY,
          );
    }

    // Calculate ideal position as center of mass
    final idealX = totalX / connectedNodeCount;
    final idealY = totalY / connectedNodeCount;

    // Constrain position to reasonable bounds and maintain some slot ordering influence
    final slotOrderY = 100.0 + algorithm.index * nodeSpacingY;
    final constrainedX = idealX.clamp(150.0, canvasWidth - 150.0);
    final constrainedY = (idealY * 0.7 + slotOrderY * 0.3).clamp(
      50.0,
      canvasHeight - 50.0,
    );

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
    final overlapRatio =
        overlaps.length / connections.length.clamp(1, double.infinity);

    return (1.0 - overlapRatio).clamp(0.0, 1.0);
  }
}
