import 'package:freezed_annotation/freezed_annotation.dart';
import 'port.dart';
import 'connection.dart';

part 'routing_state.freezed.dart';
part 'routing_state.g.dart';

/// Enum representing the overall status of the routing system
@JsonEnum()
enum RoutingSystemStatus {
  /// System is not initialized
  uninitialized,

  /// System is initializing
  initializing,

  /// System is ready for use
  ready,

  /// System is processing routing changes
  updating,

  /// System has encountered an error
  error,

  /// System is being shut down
  disposing,
}

/// Immutable data class representing the complete state of the routing system.
///
/// This class holds all the information about ports, connections, and the
/// overall system status. It's designed to work seamlessly with Cubit state
/// management and supports efficient state updates through immutable patterns.
///
/// Example:
/// ```dart
/// final state = RoutingState(
///   status: RoutingSystemStatus.ready,
///   inputPorts: [audioInput1, cvInput1],
///   outputPorts: [audioOutput1, gateOutput1],
///   connections: [connection1, connection2],
/// );
/// ```
@freezed
sealed class RoutingState with _$RoutingState {
  const factory RoutingState({
    /// Current status of the routing system
    @Default(RoutingSystemStatus.uninitialized) RoutingSystemStatus status,

    /// List of all available input ports
    @Default([]) List<Port> inputPorts,

    /// List of all available output ports
    @Default([]) List<Port> outputPorts,

    /// List of all active connections
    @Default([]) List<Connection> connections,

    /// Optional error message if status is error
    String? errorMessage,

    /// Timestamp when the state was created
    DateTime? createdAt,

    /// Timestamp when the state was last updated
    DateTime? lastUpdated,

    /// Whether the routing system is in read-only mode
    @Default(false) bool isReadOnly,

    /// Configuration parameters for the routing system
    Map<String, dynamic>? configuration,

    /// Additional metadata for the routing state
    Map<String, dynamic>? metadata,
  }) = _RoutingState;

  /// Creates a RoutingState from JSON
  factory RoutingState.fromJson(Map<String, dynamic> json) =>
      _$RoutingStateFromJson(json);

  const RoutingState._();

  /// Returns true if the system is ready for routing operations
  bool get isReady => status == RoutingSystemStatus.ready;

  /// Returns true if the system is currently updating
  bool get isUpdating => status == RoutingSystemStatus.updating;

  /// Returns true if the system has an error
  bool get hasError => status == RoutingSystemStatus.error;

  /// Returns true if the system is initializing
  bool get isInitializing => status == RoutingSystemStatus.initializing;

  /// Returns all ports (input and output combined)
  List<Port> get allPorts => [...inputPorts, ...outputPorts];

  /// Returns the total number of active connections
  int get activeConnectionCount =>
      connections.where((conn) => conn.isActive).length;

  /// Returns the total number of connections with errors
  int get errorConnectionCount =>
      connections.where((conn) => conn.hasError).length;

  /// Finds a port by its ID
  Port? findPortById(String portId) {
    for (final port in allPorts) {
      if (port.id == portId) {
        return port;
      }
    }
    return null;
  }

  /// Finds a connection by its ID
  Connection? findConnectionById(String connectionId) {
    for (final connection in connections) {
      if (connection.id == connectionId) {
        return connection;
      }
    }
    return null;
  }

  /// Returns all connections for a specific port
  List<Connection> getConnectionsForPort(String portId) {
    return connections
        .where(
          (conn) =>
              conn.sourcePortId == portId || conn.destinationPortId == portId,
        )
        .toList();
  }

  /// Returns all input connections for a specific port
  List<Connection> getInputConnectionsForPort(String portId) {
    return connections
        .where((conn) => conn.destinationPortId == portId)
        .toList();
  }

  /// Returns all output connections for a specific port
  List<Connection> getOutputConnectionsForPort(String portId) {
    return connections.where((conn) => conn.sourcePortId == portId).toList();
  }

  /// Creates a copy with updated status
  RoutingState withStatus(
    RoutingSystemStatus newStatus, {
    String? errorMessage,
  }) {
    return copyWith(
      status: newStatus,
      errorMessage: errorMessage,
      lastUpdated: DateTime.now(),
    );
  }

  /// Creates a copy with an added connection
  RoutingState withAddedConnection(Connection connection) {
    return copyWith(
      connections: [...connections, connection],
      lastUpdated: DateTime.now(),
    );
  }

  /// Creates a copy with a removed connection
  RoutingState withRemovedConnection(String connectionId) {
    return copyWith(
      connections: connections
          .where((conn) => conn.id != connectionId)
          .toList(),
      lastUpdated: DateTime.now(),
    );
  }

  /// Creates a copy with updated connection
  RoutingState withUpdatedConnection(Connection updatedConnection) {
    final updatedConnections = connections.map((conn) {
      return conn.id == updatedConnection.id ? updatedConnection : conn;
    }).toList();

    return copyWith(
      connections: updatedConnections,
      lastUpdated: DateTime.now(),
    );
  }

  /// Creates a copy with updated ports
  RoutingState withUpdatedPorts({
    List<Port>? inputPorts,
    List<Port>? outputPorts,
  }) {
    return copyWith(
      inputPorts: inputPorts ?? this.inputPorts,
      outputPorts: outputPorts ?? this.outputPorts,
      lastUpdated: DateTime.now(),
    );
  }

  /// Validates the current routing state
  bool validateState() {
    // Check if all connections reference valid ports
    for (final connection in connections) {
      final source = findPortById(connection.sourcePortId);
      final destination = findPortById(connection.destinationPortId);

      if (source == null || destination == null) {
        return false;
      }
    }

    return true;
  }
}
