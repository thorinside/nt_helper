import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'package:nt_helper/core/routing/models/connection.dart';
import 'package:nt_helper/core/routing/models/port.dart' as core_port;
import 'package:nt_helper/core/platform/connection_deletion_state.dart';

part 'routing_editor_state.freezed.dart';

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


/// Represents status of a routing bus
enum BusStatus {
  /// Bus is available for assignment
  available,
  /// Bus is assigned and active
  assigned,
  /// Bus has an error
  error,
}

/// Represents a port in the routing system
@freezed
sealed class Port with _$Port {
  const factory Port({
    required String id, // Unique identifier
    required String name, // Display name
    required PortType type,
    required PortDirection direction,
    int? busNumber, // Bus number this port is connected to (1-28)
    String? parameterName, // Name of the parameter controlling this port's bus assignment
  }) = _Port;
}


/// Represents a routing bus for signal distribution
@freezed
sealed class RoutingBus with _$RoutingBus {
  const factory RoutingBus({
    required String id,
    required String name,
    required BusStatus status,
    @Default([]) List<String> connectionIds,
    @Default(core_port.OutputMode.replace) core_port.OutputMode defaultOutputMode,
    @Default(1.0) double masterGain,
    DateTime? createdAt,
    DateTime? modifiedAt,
  }) = _RoutingBus;
}

/// Represents an algorithm with its routing ports
@freezed
sealed class RoutingAlgorithm with _$RoutingAlgorithm {
  const factory RoutingAlgorithm({
    /// Stable unique identifier for this algorithm instance
    required String id,
    /// Current slot index (0-7), can change when algorithms are reordered
    required int index,
    /// The algorithm definition
    required Algorithm algorithm,
    /// Input ports for this algorithm
    required List<Port> inputPorts,
    /// Output ports for this algorithm
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

  /// State when saving or loading persistent state
  const factory RoutingEditorState.persisting() = RoutingEditorStatePersisting;

  /// State when syncing with hardware
  const factory RoutingEditorState.syncing() = RoutingEditorStateSyncing;

  /// State when routing data is loaded and ready for visualization
  const factory RoutingEditorState.loaded({
    required List<Port> physicalInputs, // 12 physical input ports
    required List<Port> physicalOutputs, // 8 physical output ports
    required List<RoutingAlgorithm> algorithms, // Algorithms with their ports
    required List<Connection> connections, // All routing connections
    @Default([]) List<RoutingBus> buses, // Available routing buses
    @Default({}) Map<String, core_port.OutputMode> portOutputModes, // Output modes per port
    @Default(false) bool isHardwareSynced, // Hardware sync status
    @Default(false) bool isPersistenceEnabled, // State persistence status
    @Default(ConnectionDeletionState.initial()) ConnectionDeletionState deletionState, // Connection deletion interaction state
    DateTime? lastSyncTime, // Last hardware sync timestamp
    DateTime? lastPersistTime, // Last persistence save timestamp
    String? lastError, // Last error message
  }) = RoutingEditorStateLoaded;

  /// State when an error occurs
  const factory RoutingEditorState.error(String message) = RoutingEditorStateError;

}