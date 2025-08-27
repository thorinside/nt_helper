part of 'routing_editor_cubit.dart';

/// Represents different types of ports in the routing system
enum PortType {
  audio,
  cv,
  gate,
  trigger,
}

/// Represents direction of signal flow
enum PortDirection {
  input,
  output,
}

/// Represents a port in the routing system
@freezed
sealed class Port with _$Port {
  const factory Port({
    required String id, // Unique identifier
    required String name, // Display name
    required PortType type,
    required PortDirection direction,
  }) = _Port;
}

/// Represents a connection between two ports
@freezed
sealed class Connection with _$Connection {
  const factory Connection({
    required String sourcePortId,
    required String targetPortId,
  }) = _Connection;
}

/// Represents an algorithm with its routing ports
@freezed
sealed class RoutingAlgorithm with _$RoutingAlgorithm {
  const factory RoutingAlgorithm({
    required int index,
    required Algorithm algorithm,
    required List<Port> inputPorts,
    required List<Port> outputPorts,
  }) = _RoutingAlgorithm;
}

/// State of the routing editor
@freezed
sealed class RoutingEditorState with _$RoutingEditorState {
  /// Initial state when routing editor is first created
  const factory RoutingEditorState.initial() = RoutingEditorStateInitial;

  /// State when hardware is disconnected
  const factory RoutingEditorState.disconnected() = RoutingEditorStateDisconnected;

  /// State when connecting to hardware
  const factory RoutingEditorState.connecting() = RoutingEditorStateConnecting;

  /// State when routing data is being refreshed
  const factory RoutingEditorState.refreshing() = RoutingEditorStateRefreshing;

  /// State when routing data is loaded and ready for visualization
  const factory RoutingEditorState.loaded({
    required List<Port> physicalInputs, // 12 physical input ports
    required List<Port> physicalOutputs, // 8 physical output ports
    required List<RoutingAlgorithm> algorithms, // Algorithms with their ports
    required List<Connection> connections, // All routing connections
  }) = RoutingEditorStateLoaded;

  /// State when an error occurs
  const factory RoutingEditorState.error(String message) = RoutingEditorStateError;
}