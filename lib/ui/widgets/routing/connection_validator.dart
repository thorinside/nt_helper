import 'package:nt_helper/core/routing/models/port.dart';

/// Validates connections between ports in the routing system.
///
/// This class enforces hardware constraints for the Disting NT module,
/// preventing invalid connections and identifying special connection types
/// like ghost connections.
class ConnectionValidator {
  /// Validates whether a connection between two ports is allowed.
  ///
  /// Returns true if the connection is valid according to hardware constraints.
  ///
  /// Valid connections include:
  /// - Physical Input → Algorithm Input
  /// - Algorithm Output → Physical Output
  /// - Algorithm Output → Algorithm Input
  /// - Algorithm Output → Physical Input/Output (Ghost Connection)
  ///
  /// Invalid connections include:
  /// - Physical Input → Physical Output (hardware limitation)
  /// - Physical Output → Physical Input
  /// - Same node internal connections (would create feedback loops)
  static bool isValidConnection(Port source, Port target) {
    // Check basic port direction compatibility first
    if (!_arePortDirectionsCompatible(source, target)) {
      return false;
    }

    final sourceIsPhysical = source.isPhysical;
    final targetIsPhysical = target.isPhysical;
    final sourceIsAlgorithm = !sourceIsPhysical;
    final targetIsAlgorithm = !targetIsPhysical;

    // Prevent same-node connections (feedback loops)
    if (_isSameNodeConnection(source, target)) {
      return false;
    }

    // Handle bidirectional ports specially
    if (source.direction == PortDirection.bidirectional ||
        target.direction == PortDirection.bidirectional) {
      // Bidirectional algorithm ports can connect to other algorithm ports
      if (sourceIsAlgorithm && targetIsAlgorithm) {
        return true;
      }
      // Bidirectional algorithm ports can connect to physical ports
      if ((sourceIsAlgorithm && targetIsPhysical) ||
          (sourceIsPhysical && targetIsAlgorithm)) {
        return true;
      }
      // But still prevent physical-to-physical
      if (sourceIsPhysical && targetIsPhysical) {
        return false;
      }
    }

    // Valid: Physical Input → Algorithm Input
    if (sourceIsPhysical &&
        targetIsAlgorithm &&
        source.direction == PortDirection.output &&
        target.direction == PortDirection.input) {
      return true;
    }

    // Valid: Algorithm Output → Physical Output (direct connection)
    if (sourceIsAlgorithm &&
        targetIsPhysical &&
        source.direction == PortDirection.output &&
        target.direction == PortDirection.input) {
      return true;
    }

    // Valid: Algorithm Output → Algorithm Input
    if (sourceIsAlgorithm &&
        targetIsAlgorithm &&
        source.direction == PortDirection.output &&
        target.direction == PortDirection.input) {
      return true;
    }

    // Valid: Algorithm Output → Physical Input (Ghost Connection)
    // Note: Physical inputs have PortDirection.output because they are sources
    if (sourceIsAlgorithm &&
        targetIsPhysical &&
        source.direction == PortDirection.output &&
        target.direction == PortDirection.output &&
        target.jackType == 'input') {
      return true;
    }

    // Invalid: Physical to Physical connections
    if (sourceIsPhysical && targetIsPhysical) {
      return false;
    }

    // All other combinations are invalid
    return false;
  }

  /// Checks if two ports have compatible directions for connection.
  static bool _arePortDirectionsCompatible(Port source, Port target) {
    // Standard connection: output to input
    if (source.direction == PortDirection.output &&
        target.direction == PortDirection.input) {
      return true;
    }

    // Ghost connection special case: algorithm output to physical input
    // Physical inputs have output direction (they are sources)
    if (source.direction == PortDirection.output &&
        target.direction == PortDirection.output &&
        target.isPhysical &&
        target.jackType == 'input') {
      return true;
    }

    // Bidirectional ports can connect to anything
    if (source.direction == PortDirection.bidirectional ||
        target.direction == PortDirection.bidirectional) {
      return true;
    }

    return false;
  }

  /// Checks if two ports belong to the same node (would create a feedback loop).
  static bool _isSameNodeConnection(Port source, Port target) {
    // Extract node ID from port ID
    // Port IDs follow patterns like "node_1_in_1" or "hw_in_1"
    final sourceNodeId = _extractNodeId(source.id);
    final targetNodeId = _extractNodeId(target.id);

    if (sourceNodeId == null || targetNodeId == null) {
      return false;
    }

    return sourceNodeId == targetNodeId;
  }

  /// Extracts the node ID from a port ID.
  static String? _extractNodeId(String portId) {
    // Handle hardware ports (hw_in_1, hw_out_1)
    if (portId.startsWith('hw_')) {
      // Hardware inputs and outputs are different nodes
      if (portId.startsWith('hw_in')) return 'hw_inputs';
      if (portId.startsWith('hw_out')) return 'hw_outputs';
      return null;
    }

    // Handle algorithm node ports (node_1_in_1, node_1_out_1)
    final parts = portId.split('_');
    if (parts.length >= 3) {
      // Return the node identifier (e.g., "node_1")
      return '${parts[0]}_${parts[1]}';
    }

    return null;
  }

  /// Returns a human-readable error message for invalid connection attempts.
  static String getValidationError(Port source, Port target) {
    final sourceIsPhysical = source.isPhysical;
    final targetIsPhysical = target.isPhysical;

    // Physical to physical connections
    if (sourceIsPhysical && targetIsPhysical) {
      return 'Direct physical-to-physical connections are not supported. '
          'Signals must be routed through algorithms.';
    }

    // Same node connections
    if (_isSameNodeConnection(source, target)) {
      return 'Cannot connect a node to itself - this would create a feedback loop.';
    }

    // Direction mismatch
    if (!_arePortDirectionsCompatible(source, target)) {
      return 'Port directions are incompatible. You can only connect outputs to inputs.';
    }

    // Type mismatch
    if (!source.isCompatibleWith(target)) {
      return 'Port types are incompatible. ${source.type.name} cannot connect to ${target.type.name}.';
    }

    return 'These ports cannot be connected. Check port directions and types.';
  }

  /// Determines if a connection represents a ghost connection.
  ///
  /// Ghost connections occur when an algorithm output connects to a physical I/O,
  /// making the signal available to other algorithms through that physical port.
  static bool isGhostConnection(Port source, Port target) {
    final sourceIsAlgorithm = !source.isPhysical;
    final targetIsPhysical = target.isPhysical;

    // Ghost connection: Algorithm output → Physical input
    if (sourceIsAlgorithm &&
        targetIsPhysical &&
        source.direction == PortDirection.output &&
        target.jackType == 'input') {
      return true;
    }

    // Note: Algorithm output → Physical output is a direct connection, not ghost
    // The physical output receives the signal directly

    return false;
  }

  /// Returns a description of the connection type.
  static String getConnectionDescription(Port source, Port target) {
    if (!isValidConnection(source, target)) {
      return 'Invalid connection';
    }

    if (isGhostConnection(source, target)) {
      final targetType = target.jackType ?? 'port';
      final targetIndex = target.hardwareIndex ?? '';
      return 'Ghost signal on physical $targetType $targetIndex - available to other algorithms';
    }

    final sourceIsPhysical = source.isPhysical;
    final targetIsPhysical = target.isPhysical;

    if (sourceIsPhysical && !targetIsPhysical) {
      return 'Hardware input to algorithm';
    }

    if (!sourceIsPhysical && targetIsPhysical) {
      return 'Algorithm output to hardware';
    }

    if (!sourceIsPhysical && !targetIsPhysical) {
      return 'Algorithm to algorithm routing';
    }

    return 'Direct signal routing';
  }

  /// Validates port type compatibility with additional hardware-specific rules.
  static bool arePortTypesCompatible(Port source, Port target) {
    // Use the built-in port compatibility check first
    if (!source.isCompatibleWith(target)) {
      return false;
    }

    // Additional hardware-specific rules can be added here
    // For example, certain physical ports might have restrictions

    return true;
  }
}
