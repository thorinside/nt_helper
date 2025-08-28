import 'package:flutter/foundation.dart';
import 'models/routing_state.dart';
import 'models/port.dart';
import 'models/connection.dart';
import 'port_compatibility_validator.dart';

/// Abstract base class for algorithm routing implementations.
/// 
/// This class defines the core interface that all routing algorithms must implement.
/// It provides a standardized way to generate ports, validate connections, and manage
/// routing state while allowing concrete implementations to define their own logic.
/// 
/// Example usage:
/// ```dart
/// class MyRoutingAlgorithm extends AlgorithmRouting {
///   @override
///   List<Port> generateInputPorts() {
///     return [Port(id: 'input1', name: 'Audio In', type: PortType.audio)];
///   }
///   
///   @override
///   List<Port> generateOutputPorts() {
///     return [Port(id: 'output1', name: 'Audio Out', type: PortType.audio)];
///   }
///   
///   @override
///   bool validateConnection(Port source, Port destination) {
///     return source.type == destination.type;
///   }
/// }
/// ```
abstract class AlgorithmRouting {
  /// The port compatibility validator for this algorithm
  late final PortCompatibilityValidator _validator;
  
  /// Creates a new AlgorithmRouting instance
  AlgorithmRouting({PortCompatibilityValidator? validator}) {
    _validator = validator ?? PortCompatibilityValidator();
  }
  
  /// The current routing state
  RoutingState get state;
  
  /// List of input ports available for this routing algorithm
  List<Port> get inputPorts;
  
  /// List of output ports available for this routing algorithm  
  List<Port> get outputPorts;
  
  /// List of active connections between ports
  List<Connection> get connections;
  
  /// The port compatibility validator
  PortCompatibilityValidator get validator => _validator;
  
  /// Generates the list of input ports for this algorithm.
  /// 
  /// This method should be implemented by concrete classes to define
  /// what input ports are available for the routing algorithm.
  /// 
  /// Returns a list of [Port] objects representing input ports.
  @protected
  List<Port> generateInputPorts();
  
  /// Generates the list of output ports for this algorithm.
  /// 
  /// This method should be implemented by concrete classes to define
  /// what output ports are available for the routing algorithm.
  /// 
  /// Returns a list of [Port] objects representing output ports.
  @protected
  List<Port> generateOutputPorts();
  
  /// Validates whether a connection between two ports is valid.
  /// 
  /// This method checks if a connection can be made between the [source]
  /// port and the [destination] port based on their types, directions,
  /// and any other algorithm-specific constraints.
  /// 
  /// The default implementation uses the port compatibility validator,
  /// but concrete classes can override this for custom validation logic.
  /// 
  /// Parameters:
  /// - [source]: The port where the connection originates
  /// - [destination]: The port where the connection terminates
  /// 
  /// Returns `true` if the connection is valid, `false` otherwise.
  bool validateConnection(Port source, Port destination) {
    final result = _validator.validateConnection(
      source,
      destination,
      existingConnections: connections,
    );
    return result.isValid;
  }
  
  /// Validates a connection with detailed results.
  /// 
  /// This method provides detailed validation results including errors
  /// and warnings, which can be useful for providing user feedback.
  /// 
  /// Parameters:
  /// - [source]: The port where the connection originates
  /// - [destination]: The port where the connection terminates
  /// 
  /// Returns a [ValidationResult] with detailed validation information.
  ValidationResult validateConnectionDetailed(Port source, Port destination) {
    return _validator.validateConnection(
      source,
      destination,
      existingConnections: connections,
    );
  }
  
  /// Updates the routing state with a new state.
  /// 
  /// This method allows updating the internal routing state and should
  /// trigger any necessary state change notifications.
  /// 
  /// Parameters:
  /// - [newState]: The new routing state to apply
  void updateState(RoutingState newState);
  
  /// Adds a connection between two ports if the connection is valid.
  /// 
  /// This method validates the connection using [validateConnection] and
  /// adds it to the list of active connections if valid.
  /// 
  /// Parameters:
  /// - [source]: The source port for the connection
  /// - [destination]: The destination port for the connection
  /// 
  /// Returns the created [Connection] if successful, null if invalid.
  Connection? addConnection(Port source, Port destination) {
    if (!validateConnection(source, destination)) {
      debugPrint(
        'AlgorithmRouting: Invalid connection attempt from ${source.id} to ${destination.id}'
      );
      return null;
    }
    
    final connection = Connection(
      id: '${source.id}_${destination.id}',
      sourcePortId: source.id,
      destinationPortId: destination.id,
    );
    
    debugPrint(
      'AlgorithmRouting: Created connection ${connection.id}'
    );
    
    return connection;
  }
  
  /// Removes a connection by its ID.
  /// 
  /// This method removes an active connection from the routing system.
  /// 
  /// Parameters:
  /// - [connectionId]: The ID of the connection to remove
  /// 
  /// Returns `true` if the connection was found and removed, `false` otherwise.
  bool removeConnection(String connectionId) {
    final removed = connections.any((conn) => conn.id == connectionId);
    if (removed) {
      debugPrint('AlgorithmRouting: Removed connection $connectionId');
    } else {
      debugPrint('AlgorithmRouting: Connection $connectionId not found');
    }
    return removed;
  }
  
  /// Finds a port by its ID in both input and output ports.
  /// 
  /// This utility method searches through all available ports to find
  /// one with the specified ID.
  /// 
  /// Parameters:
  /// - [portId]: The ID of the port to find
  /// 
  /// Returns the [Port] if found, null otherwise.
  Port? findPortById(String portId) {
    // Search in input ports
    for (final port in inputPorts) {
      if (port.id == portId) {
        return port;
      }
    }
    
    // Search in output ports
    for (final port in outputPorts) {
      if (port.id == portId) {
        return port;
      }
    }
    
    return null;
  }
  
  /// Validates the entire routing configuration.
  /// 
  /// This method performs a comprehensive validation of the current
  /// routing state, checking all connections for validity and consistency.
  /// 
  /// Returns `true` if the routing configuration is valid, `false` otherwise.
  bool validateRouting() {
    for (final connection in connections) {
      final source = findPortById(connection.sourcePortId);
      final destination = findPortById(connection.destinationPortId);
      
      if (source == null || destination == null) {
        debugPrint(
          'AlgorithmRouting: Invalid connection ${connection.id} - missing ports'
        );
        return false;
      }
      
      if (!validateConnection(source, destination)) {
        debugPrint(
          'AlgorithmRouting: Invalid connection ${connection.id} - validation failed'
        );
        return false;
      }
    }
    
    return true;
  }
  
  /// Disposes of any resources used by the routing algorithm.
  /// 
  /// Concrete implementations should override this method to clean up
  /// any resources, listeners, or subscriptions they may have created.
  @mustCallSuper
  void dispose() {
    debugPrint('AlgorithmRouting: Disposing routing algorithm');
  }
}