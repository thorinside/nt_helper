import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:nt_helper/models/algorithm_port.dart';
import 'package:nt_helper/models/connection.dart';
import 'package:nt_helper/models/connection_preview.dart';
import 'package:nt_helper/models/node_position.dart';
import 'package:nt_helper/models/port_layout.dart';

part 'node_routing_state.freezed.dart';

@freezed
sealed class NodeRoutingState with _$NodeRoutingState {
  const factory NodeRoutingState.initial() = NodeRoutingStateInitial;
  
  const factory NodeRoutingState.loading() = NodeRoutingStateLoading;
  
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
    Set<int>? selectedNodes,
    Map<String, bool>? portHoverStates, // portId -> isHovered
    String? errorMessage,
    @Default({}) Set<String> pendingConnections, // Connection IDs being created
    @Default({}) Set<String> failedConnections, // Connection IDs that failed
    @Default({}) Map<String, DateTime> operationTimestamps, // For timeout tracking
    @Deprecated('Use portLayouts instead') Map<int, List<AlgorithmPort>>? algorithmPorts,
  }) = NodeRoutingStateLoaded;
  
  const factory NodeRoutingState.error({
    required String message,
  }) = NodeRoutingStateError;
}