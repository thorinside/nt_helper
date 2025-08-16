import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:nt_helper/models/algorithm_port.dart';
import 'package:nt_helper/models/connection.dart';
import 'package:nt_helper/models/node_position.dart';

part 'node_routing_state.freezed.dart';

@freezed
sealed class NodeRoutingState with _$NodeRoutingState {
  const factory NodeRoutingState.initial() = NodeRoutingStateInitial;
  
  const factory NodeRoutingState.loading() = NodeRoutingStateLoading;
  
  const factory NodeRoutingState.loaded({
    required Map<int, NodePosition> nodePositions,
    required List<Connection> connections,
    required Map<int, List<AlgorithmPort>> algorithmPorts,
    required Set<String> connectedPorts,
    required Map<int, String> algorithmNames,
    Connection? previewConnection,
    String? hoveredConnectionId,
    Set<int>? selectedNodes,
    String? errorMessage,
  }) = NodeRoutingStateLoaded;
  
  const factory NodeRoutingState.error({
    required String message,
  }) = NodeRoutingStateError;
}