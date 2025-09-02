import 'package:nt_helper/cubit/routing_editor_cubit.dart';

/// Validates connections for slot ordering violations.
/// 
/// This validator checks algorithm-to-algorithm connections to ensure they
/// follow the Disting NT's processing order constraints. Connections from
/// higher-numbered algorithm slots to lower-numbered slots are marked as
/// invalid since they violate the sequential processing order.
/// 
/// Physical connections (to/from hardware inputs/outputs) are always
/// considered valid regardless of algorithm slot positions.
class ConnectionValidator {
  /// Validates a list of connections for slot ordering violations.
  /// 
  /// For each connection between algorithms, checks if the source algorithm's
  /// slot index is greater than the target algorithm's slot index. If so,
  /// the connection is marked as invalid by adding an 'isInvalidOrder' flag
  /// to its properties.
  /// 
  /// Physical connections (those involving hw_in_* or hw_out_* ports) are
  /// skipped and remain valid.
  /// 
  /// Returns a new list of connections with validation flags added to their
  /// properties. Original connection data is preserved.
  static List<Connection> validateConnections(
    List<Connection> connections,
    List<RoutingAlgorithm> algorithms,
  ) {
    return connections.map((connection) {
      // Skip validation for physical connections
      if (isPhysicalConnection(connection)) {
        return connection;
      }
      
      // Find source and target algorithm indices
      final sourceIndex = findAlgorithmIndex(
        connection.sourcePortId,
        algorithms,
      );
      final targetIndex = findAlgorithmIndex(
        connection.targetPortId,
        algorithms,
      );
      
      // Check if connection violates slot ordering
      if (sourceIndex != null && 
          targetIndex != null && 
          sourceIndex > targetIndex) {
        // Mark connection as backward edge (violates slot ordering)
        return connection.copyWith(
          isBackwardEdge: true,
        );
      }
      
      // Connection is valid or involves unknown ports
      return connection;
    }).toList();
  }
  
  /// Checks if a connection involves physical hardware ports.
  /// 
  /// Physical connections include:
  /// - Connections from hardware inputs (hw_in_*)
  /// - Connections to hardware outputs (hw_out_*)
  /// 
  /// These connections are always valid regardless of algorithm slot ordering.
  static bool isPhysicalConnection(Connection connection) {
    return connection.sourcePortId.startsWith('hw_in_') ||
           connection.sourcePortId.startsWith('hw_out_') ||
           connection.targetPortId.startsWith('hw_in_') ||
           connection.targetPortId.startsWith('hw_out_');
  }
  
  /// Finds the algorithm index (slot number) for a given port ID.
  /// 
  /// Searches through all algorithms to find which one contains the
  /// specified port (either as an input or output port).
  /// 
  /// Returns the algorithm's index if found, or null if the port
  /// doesn't belong to any algorithm (e.g., physical ports or unknown IDs).
  static int? findAlgorithmIndex(
    String portId,
    List<RoutingAlgorithm> algorithms,
  ) {
    for (final algorithm in algorithms) {
      // Check input ports
      if (algorithm.inputPorts.any((port) => port.id == portId)) {
        return algorithm.index;
      }
      
      // Check output ports
      if (algorithm.outputPorts.any((port) => port.id == portId)) {
        return algorithm.index;
      }
    }
    
    // Port not found in any algorithm
    return null;
  }
}