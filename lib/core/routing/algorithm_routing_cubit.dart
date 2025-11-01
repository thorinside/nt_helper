import 'package:flutter_bloc/flutter_bloc.dart';
import 'algorithm_routing.dart';
import 'models/routing_state.dart';
import 'models/connection.dart';

/// Cubit for managing algorithm routing state.
///
/// This cubit provides a reactive way to manage routing operations,
/// including port creation, connection management, and state updates.
/// It wraps an AlgorithmRouting implementation and exposes state changes
/// through the BLoC pattern.
///
/// Example usage:
/// ```dart
/// final cubit = AlgorithmRoutingCubit(myAlgorithm);
/// cubit.stream.listen((state) {
///   // React to state changes
///
/// });
///
/// cubit.initializeRouting();
/// cubit.connectPorts(sourcePort, destinationPort);
/// ```
class AlgorithmRoutingCubit extends Cubit<RoutingState> {
  /// Creates an AlgorithmRoutingCubit with an algorithm implementation
  AlgorithmRoutingCubit(this._algorithm) : super(const RoutingState()) {
    _initialize();
  }

  final AlgorithmRouting _algorithm;

  /// Initializes the routing system
  void _initialize() {
    emit(state.withStatus(RoutingSystemStatus.initializing));

    try {
      // Get ports from the algorithm
      final inputPorts = _algorithm.inputPorts;
      final outputPorts = _algorithm.outputPorts;

      // Update state with generated ports
      final newState = state
          .withUpdatedPorts(inputPorts: inputPorts, outputPorts: outputPorts)
          .withStatus(RoutingSystemStatus.ready);

      emit(newState);
    } catch (e) {
      emit(
        state.withStatus(
          RoutingSystemStatus.error,
          errorMessage: 'Failed to initialize routing: $e',
        ),
      );
    }
  }

  /// Attempts to create a connection between two ports
  void connectPorts(String sourcePortId, String destinationPortId) {
    if (!state.isReady) {
      return;
    }

    emit(state.withStatus(RoutingSystemStatus.updating));

    try {
      // Find the ports
      final sourcePort = state.findPortById(sourcePortId);
      final destinationPort = state.findPortById(destinationPortId);

      if (sourcePort == null || destinationPort == null) {
        emit(
          state.withStatus(
            RoutingSystemStatus.error,
            errorMessage:
                'Port not found: source=$sourcePortId, destination=$destinationPortId',
          ),
        );
        return;
      }

      // Attempt to create connection using the algorithm
      final connection = _algorithm.addConnection(sourcePort, destinationPort);

      if (connection != null) {
        // Add connection to state
        final newState = state
            .withAddedConnection(connection)
            .withStatus(RoutingSystemStatus.ready);

        emit(newState);
        _algorithm.updateState(newState);
      } else {
        emit(
          state.withStatus(
            RoutingSystemStatus.error,
            errorMessage:
                'Invalid connection between ${sourcePort.name} and ${destinationPort.name}',
          ),
        );
      }
    } catch (e) {
      emit(
        state.withStatus(
          RoutingSystemStatus.error,
          errorMessage: 'Failed to connect ports: $e',
        ),
      );
    }
  }

  /// Attempts to create a connection between two ports with detailed validation
  void connectPortsWithValidation(
    String sourcePortId,
    String destinationPortId,
  ) {
    if (!state.isReady) {
      return;
    }

    emit(state.withStatus(RoutingSystemStatus.updating));

    try {
      // Find the ports
      final sourcePort = state.findPortById(sourcePortId);
      final destinationPort = state.findPortById(destinationPortId);

      if (sourcePort == null || destinationPort == null) {
        emit(
          state.withStatus(
            RoutingSystemStatus.error,
            errorMessage:
                'Port not found: source=$sourcePortId, destination=$destinationPortId',
          ),
        );
        return;
      }

      // Get detailed validation results
      final validationResult = _algorithm.validateConnectionDetailed(
        sourcePort,
        destinationPort,
      );

      if (validationResult.isValid) {
        // Create connection
        final connection = Connection(
          id: '${sourcePort.id}_${destinationPort.id}',
          sourcePortId: sourcePort.id,
          destinationPortId: destinationPort.id,
          connectionType: ConnectionType.algorithmToAlgorithm,
          createdAt: DateTime.now(),
        );

        // Add connection to state
        final newState = state
            .withAddedConnection(connection)
            .withStatus(RoutingSystemStatus.ready);

        emit(newState);
        _algorithm.updateState(newState);

        // Warnings are part of validationResult but not logged
      } else {
        // Connection is invalid - emit error with detailed information
        final errorMessages = validationResult.errors
            .map((error) => error.message)
            .join('; ');

        emit(
          state.withStatus(
            RoutingSystemStatus.error,
            errorMessage: 'Connection validation failed: $errorMessages',
          ),
        );

        // Errors are part of validationResult and included in errorMessages above
      }
    } catch (e) {
      emit(
        state.withStatus(
          RoutingSystemStatus.error,
          errorMessage: 'Failed to connect ports: $e',
        ),
      );
    }
  }

  /// Removes a connection by its ID
  void disconnectPorts(String connectionId) {
    if (!state.isReady && state.status != RoutingSystemStatus.error) {
      return;
    }

    emit(state.withStatus(RoutingSystemStatus.updating));

    try {
      final connection = state.findConnectionById(connectionId);

      if (connection == null) {
        emit(
          state.withStatus(
            RoutingSystemStatus.error,
            errorMessage: 'Connection not found: $connectionId',
          ),
        );
        return;
      }

      // Remove connection from algorithm
      final removed = _algorithm.removeConnection(connectionId);

      if (removed) {
        // Remove connection from state
        final newState = state
            .withRemovedConnection(connectionId)
            .withStatus(RoutingSystemStatus.ready);

        emit(newState);
        _algorithm.updateState(newState);
      } else {
        emit(
          state.withStatus(
            RoutingSystemStatus.error,
            errorMessage: 'Failed to remove connection: $connectionId',
          ),
        );
      }
    } catch (e) {
      emit(
        state.withStatus(
          RoutingSystemStatus.error,
          errorMessage: 'Failed to disconnect ports: $e',
        ),
      );
    }
  }

  /// Updates a connection's properties
  void updateConnection(
    String connectionId, {
    double? gain,
    bool? isMuted,
    bool? isInverted,
  }) {
    if (!state.isReady) {
      return;
    }

    emit(state.withStatus(RoutingSystemStatus.updating));

    try {
      final connection = state.findConnectionById(connectionId);

      if (connection == null) {
        emit(
          state.withStatus(
            RoutingSystemStatus.error,
            errorMessage: 'Connection not found: $connectionId',
          ),
        );
        return;
      }

      // Create updated connection
      var updatedConnection = connection;

      if (gain != null) {
        updatedConnection = updatedConnection.withGain(gain);
      }

      if (isMuted != null) {
        updatedConnection = updatedConnection.copyWith(isMuted: isMuted);
      }

      if (isInverted != null) {
        updatedConnection = updatedConnection.copyWith(isInverted: isInverted);
      }

      // Update state with modified connection
      final newState = state
          .withUpdatedConnection(updatedConnection)
          .withStatus(RoutingSystemStatus.ready);

      emit(newState);
      _algorithm.updateState(newState);
    } catch (e) {
      emit(
        state.withStatus(
          RoutingSystemStatus.error,
          errorMessage: 'Failed to update connection: $e',
        ),
      );
    }
  }

  /// Validates the entire routing configuration
  void validateRouting() {
    if (!state.isReady && state.status != RoutingSystemStatus.error) {
      return;
    }

    emit(state.withStatus(RoutingSystemStatus.updating));

    try {
      final isValid = _algorithm.validateRouting();

      if (isValid) {
        emit(state.withStatus(RoutingSystemStatus.ready));
      } else {
        emit(
          state.withStatus(
            RoutingSystemStatus.error,
            errorMessage:
                'Routing validation failed - invalid connections detected',
          ),
        );
      }
    } catch (e) {
      emit(
        state.withStatus(
          RoutingSystemStatus.error,
          errorMessage: 'Failed to validate routing: $e',
        ),
      );
    }
  }

  /// Clears all connections and returns to ready state
  void clearAllConnections() {
    if (!state.isReady && state.status != RoutingSystemStatus.error) {
      return;
    }

    emit(state.withStatus(RoutingSystemStatus.updating));

    try {
      // Clear all connections
      final newState = state
          .copyWith(connections: [])
          .withStatus(RoutingSystemStatus.ready);

      emit(newState);
      _algorithm.updateState(newState);
    } catch (e) {
      emit(
        state.withStatus(
          RoutingSystemStatus.error,
          errorMessage: 'Failed to clear connections: $e',
        ),
      );
    }
  }

  /// Resets the routing system to initial state
  void resetRouting() {
    emit(const RoutingState());
    _initialize();
  }

  /// Returns the underlying algorithm instance (for advanced use cases)
  AlgorithmRouting get algorithm => _algorithm;

  @override
  void onChange(Change<RoutingState> change) {
    super.onChange(change);
  }

  @override
  Future<void> close() {
    _algorithm.dispose();
    return super.close();
  }
}
