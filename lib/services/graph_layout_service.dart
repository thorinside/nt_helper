import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:nt_helper/models/algorithm_port.dart';
import 'package:nt_helper/models/connection.dart';
import 'package:nt_helper/models/node_position.dart';

class GraphLayoutService {
  static const double nodeWidth = 200.0;
  static const double nodeHeight = 120.0;
  static const double minSpacing = 50.0;
  static const double canvasPadding = 100.0;

  /// Calculate initial positions for all nodes using hierarchical + force-directed layout
  static Map<int, NodePosition> calculateInitialLayout({
    required List<int> algorithmIndices,
    required Map<int, String> algorithmNames,
    required Map<int, List<AlgorithmPort>> algorithmPorts,
    required List<Connection> connections,
    required Size canvasSize,
  }) {
    // Start with hierarchical layout based on signal flow
    var positions = _hierarchicalLayout(
      algorithmIndices,
      algorithmNames,
      algorithmPorts,
      connections,
      canvasSize,
    );

    // Apply force-directed refinement to reduce edge crossings
    positions = _applyForceDirectedRefinement(positions, connections);

    // Ensure no overlaps
    _resolveOverlaps(positions);

    return positions;
  }

  /// Create hierarchical layout based on signal flow dependencies
  static Map<int, NodePosition> _hierarchicalLayout(
    List<int> algorithmIndices,
    Map<int, String> algorithmNames,
    Map<int, List<AlgorithmPort>> algorithmPorts,
    List<Connection> connections,
    Size canvasSize,
  ) {
    final positions = <int, NodePosition>{};

    // Calculate node layers based on signal flow
    final layers = _assignLayers(algorithmIndices, connections);
    final maxLayer = layers.values.fold(0, math.max);

    // Group nodes by layer
    final nodesByLayer = <int, List<int>>{};
    for (final entry in layers.entries) {
      nodesByLayer[entry.value] ??= [];
      nodesByLayer[entry.value]!.add(entry.key);
    }

    // Position nodes layer by layer
    final layerSpacing = maxLayer > 0 
        ? (canvasSize.width - 2 * canvasPadding) / (maxLayer + 1)
        : canvasSize.width / 2;

    for (final entry in nodesByLayer.entries) {
      final layer = entry.key;
      final nodesInLayer = entry.value;

      final x = canvasPadding + layer * layerSpacing;
      final nodeSpacing = nodesInLayer.length > 1
          ? (canvasSize.height - 2 * canvasPadding) / (nodesInLayer.length + 1)
          : canvasSize.height / 2;

      for (int i = 0; i < nodesInLayer.length; i++) {
        final algorithmIndex = nodesInLayer[i];
        final y = canvasPadding + (i + 1) * nodeSpacing;

        // Adjust node height based on port count
        final ports = algorithmPorts[algorithmIndex] ?? [];
        final adjustedHeight = math.max(nodeHeight, 60.0 + ports.length * 20.0);

        positions[algorithmIndex] = NodePosition(
          algorithmIndex: algorithmIndex,
          x: x - nodeWidth / 2,
          y: y - adjustedHeight / 2,
          width: nodeWidth,
          height: adjustedHeight,
        );
      }
    }

    return positions;
  }

  /// Assign layer numbers based on longest path from sources
  static Map<int, int> _assignLayers(
    List<int> algorithmIndices,
    List<Connection> connections,
  ) {
    final layers = <int, int>{};
    final dependencies = <int, Set<int>>{};

    // Build dependency graph
    for (final index in algorithmIndices) {
      dependencies[index] = <int>{};
    }

    for (final conn in connections) {
      dependencies[conn.targetAlgorithmIndex]!.add(conn.sourceAlgorithmIndex);
    }

    // Assign layers using longest path algorithm
    int assignLayer(int node) {
      if (layers.containsKey(node)) return layers[node]!;

      int maxDepth = 0;
      for (final dep in dependencies[node]!) {
        maxDepth = math.max(maxDepth, assignLayer(dep) + 1);
      }

      layers[node] = maxDepth;
      return maxDepth;
    }

    for (final index in algorithmIndices) {
      assignLayer(index);
    }

    return layers;
  }

  /// Apply force-directed refinement to improve layout
  static Map<int, NodePosition> _applyForceDirectedRefinement(
    Map<int, NodePosition> positions,
    List<Connection> connections, {
    int iterations = 50,
  }) {
    final newPositions = Map<int, NodePosition>.from(positions);

    for (int iter = 0; iter < iterations; iter++) {
      final forces = <int, Offset>{};

      // Initialize forces
      for (final pos in newPositions.values) {
        forces[pos.algorithmIndex] = Offset.zero;
      }

      // Apply spring forces for connected nodes
      for (final conn in connections) {
        final source = newPositions[conn.sourceAlgorithmIndex];
        final target = newPositions[conn.targetAlgorithmIndex];

        if (source != null && target != null) {
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
            const idealDistance = 250.0;
            final force = delta / distance * (distance - idealDistance) * 0.01;

            forces[conn.sourceAlgorithmIndex] = 
              forces[conn.sourceAlgorithmIndex]! + force;
            forces[conn.targetAlgorithmIndex] = 
              forces[conn.targetAlgorithmIndex]! - force;
          }
        }
      }

      // Apply repulsion forces between all nodes
      final nodeList = newPositions.values.toList();
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
          final distance = math.max(delta.distance, 10.0);

          final repulsion = delta / distance * (5000.0 / (distance * distance));

          forces[node1.algorithmIndex] = 
            forces[node1.algorithmIndex]! - repulsion;
          forces[node2.algorithmIndex] = 
            forces[node2.algorithmIndex]! + repulsion;
        }
      }

      // Apply forces with damping
      for (final entry in forces.entries) {
        final pos = newPositions[entry.key]!;
        final force = entry.value * 0.5; // Damping factor

        newPositions[entry.key] = pos.copyWith(
          x: pos.x + force.dx,
          y: pos.y + force.dy,
        );
      }
    }

    return newPositions;
  }

  /// Resolve overlapping nodes
  static void _resolveOverlaps(Map<int, NodePosition> positions) {
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
              final push = delta / delta.distance * minSpacing;

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

  /// Layout nodes in a simple grid if hierarchical layout fails
  static Map<int, NodePosition> fallbackGridLayout(
    List<int> algorithmIndices,
    Map<int, String> algorithmNames,
    Map<int, List<AlgorithmPort>> algorithmPorts,
    Size canvasSize,
  ) {
    final positions = <int, NodePosition>{};
    
    // Calculate grid dimensions
    final nodeCount = algorithmIndices.length;
    final cols = math.sqrt(nodeCount).ceil();
    final rows = (nodeCount / cols).ceil();
    
    final cellWidth = (canvasSize.width - 2 * canvasPadding) / cols;
    final cellHeight = (canvasSize.height - 2 * canvasPadding) / rows;
    
    for (int i = 0; i < algorithmIndices.length; i++) {
      final algorithmIndex = algorithmIndices[i];
      final row = i ~/ cols;
      final col = i % cols;
      
      final x = canvasPadding + col * cellWidth + (cellWidth - nodeWidth) / 2;
      final y = canvasPadding + row * cellHeight + (cellHeight - nodeHeight) / 2;
      
      // Adjust node height based on port count
      final ports = algorithmPorts[algorithmIndex] ?? [];
      final adjustedHeight = math.max(nodeHeight, 60.0 + ports.length * 20.0);
      
      positions[algorithmIndex] = NodePosition(
        algorithmIndex: algorithmIndex,
        x: x,
        y: y,
        width: nodeWidth,
        height: adjustedHeight,
      );
    }
    
    return positions;
  }
}