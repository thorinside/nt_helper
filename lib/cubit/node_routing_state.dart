import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:nt_helper/models/algorithm_port.dart';
import 'package:nt_helper/models/connection.dart';
import 'package:nt_helper/models/connection_preview.dart';
import 'package:nt_helper/models/node_position.dart';
import 'package:nt_helper/models/port_layout.dart';
import 'package:nt_helper/models/tidy_result.dart';

part 'node_routing_state.freezed.dart';

@freezed
sealed class NodeRoutingState with _$NodeRoutingState {
  const factory NodeRoutingState.initial() = NodeRoutingStateInitial;
  
  const factory NodeRoutingState.loading() = NodeRoutingStateLoading;
  
  const factory NodeRoutingState.optimizing() = NodeRoutingStateOptimizing;
  
  const factory NodeRoutingState.loaded({
    required Map<int, NodePosition> nodePositions,
    required List<Connection> connections,
    required Map<int, PortLayout> portLayouts,
    required Set<String> connectedPorts,
    required Map<int, String> algorithmNames,
    required Map<String, Offset> portPositions, // algorithmIndex_portId -> Offset
    @Default(false) bool hasUserRepositioned,
    ConnectionPreview? connectionPreview,
    String? hoveredConnectionId,
    String? hoveredLabelId, // Currently hovered label ID for mode toggle
    Set<int>? selectedNodes,
    Map<String, bool>? portHoverStates, // portId -> isHovered
    String? errorMessage,
    @Default({}) Set<String> pendingConnections, // Connection IDs being created
    @Default({}) Set<String> failedConnections, // Connection IDs that failed
    @Default({}) Map<String, DateTime> operationTimestamps, // For timeout tracking
    @Deprecated('Use portLayouts instead') Map<int, List<AlgorithmPort>>? algorithmPorts,
    TidyResult? lastTidyResult, // Result of the last tidy operation
    @Default(0) int totalBusesFreed, // Cumulative buses freed across all tidy operations
  }) = NodeRoutingStateLoaded;
  
  const factory NodeRoutingState.error({
    required String message,
  }) = NodeRoutingStateError;
}

extension NodeRoutingStateLoadedExtensions on NodeRoutingStateLoaded {
  /// Calculate optimization efficiency as a ratio of buses freed to total connections
  double get optimizationEfficiency {
    if (connections.isEmpty) return 0.0;
    return totalBusesFreed / connections.length;
  }
}