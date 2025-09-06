import 'dart:ui';
import 'package:nt_helper/core/routing/models/connection.dart';
import 'package:nt_helper/core/routing/models/port.dart';
import 'package:nt_helper/cubit/routing_editor_state.dart' as editor_state;

/// Validation result for connection operations
class ConnectionValidationResult {
  final bool isValid;
  final String? errorMessage;
  final String? warningMessage;
  final List<String> suggestions;

  const ConnectionValidationResult({
    required this.isValid,
    this.errorMessage,
    this.warningMessage,
    this.suggestions = const [],
  });

  /// Create a valid result
  factory ConnectionValidationResult.valid() {
    return const ConnectionValidationResult(isValid: true);
  }

  /// Create a valid result with warnings
  factory ConnectionValidationResult.validWithWarning(String warning) {
    return ConnectionValidationResult(
      isValid: true,
      warningMessage: warning,
    );
  }

  /// Create an invalid result
  factory ConnectionValidationResult.invalid(String error, {List<String>? suggestions}) {
    return ConnectionValidationResult(
      isValid: false,
      errorMessage: error,
      suggestions: suggestions ?? [],
    );
  }
}

/// Service for validating connection operations during drag-and-drop
class InteractiveConnectionValidator {
  
  /// Validate a connection creation during drag operation
  static ConnectionValidationResult validateConnectionCreation({
    required Port sourcePort,
    required Port targetPort,
    required editor_state.RoutingEditorStateLoaded currentState,
    bool isDragOperation = false,
  }) {
    // 1. Basic direction validation
    if (sourcePort.direction == targetPort.direction) {
      return ConnectionValidationResult.invalid(
        'Cannot connect ports of the same direction',
        suggestions: [
          'Connect output ports to input ports',
          'Drag from an output port to an input port',
        ],
      );
    }

    // Normalize connection direction (output -> input)
    final (outputPort, inputPort) = sourcePort.direction == PortDirection.output
        ? (sourcePort, targetPort)
        : (targetPort, sourcePort);

    // 2. Port type compatibility validation
    final typeCompatibility = _validatePortTypeCompatibility(outputPort.type, inputPort.type);
    if (!typeCompatibility.isValid) {
      return typeCompatibility;
    }

    // 3. Check for duplicate connections
    final duplicateCheck = _checkForDuplicateConnection(
      outputPort.id,
      inputPort.id,
      currentState.connections,
    );
    if (!duplicateCheck.isValid) {
      return duplicateCheck;
    }

    // 4. Bus availability validation
    final busValidation = _validateBusAvailability(currentState);
    if (!busValidation.isValid) {
      return busValidation;
    }

    // 5. Hardware limitation checks
    final hardwareLimits = _validateHardwareLimitations(
      outputPort,
      inputPort,
      currentState,
    );
    if (!hardwareLimits.isValid) {
      return hardwareLimits;
    }

    // 6. Performance impact validation (for large numbers of connections)
    final performanceCheck = _validatePerformanceImpact(currentState);
    if (!performanceCheck.isValid) {
      return performanceCheck;
    }

    return ConnectionValidationResult.valid();
  }

  /// Validate connection deletion
  static ConnectionValidationResult validateConnectionDeletion({
    required String connectionId,
    required editor_state.RoutingEditorStateLoaded currentState,
  }) {
    // Find the connection
    final connection = currentState.connections
        .where((conn) => conn.id == connectionId)
        .firstOrNull;

    if (connection == null) {
      return ConnectionValidationResult.invalid(
        'Connection not found',
        suggestions: ['Refresh the routing view'],
      );
    }

    // Check if connection is part of a critical routing path
    final criticalPathCheck = _validateCriticalPathDeletion(connection, currentState);
    if (!criticalPathCheck.isValid) {
      return criticalPathCheck;
    }

    return ConnectionValidationResult.valid();
  }

  /// Validate port type compatibility
  static ConnectionValidationResult _validatePortTypeCompatibility(
    PortType outputType,
    PortType inputType,
  ) {
    // Exact type matches are always valid
    if (outputType == inputType) {
      return ConnectionValidationResult.valid();
    }

    // Audio and CV are interchangeable
    if ((outputType == PortType.audio && inputType == PortType.cv) ||
        (outputType == PortType.cv && inputType == PortType.audio)) {
      return ConnectionValidationResult.validWithWarning(
        'Audio/CV type mismatch - connection allowed but may affect signal quality',
      );
    }

    // Gate and trigger compatibility
    if ((outputType == PortType.gate && inputType == PortType.clock) ||
        (outputType == PortType.clock && inputType == PortType.gate)) {
      return ConnectionValidationResult.valid();
    }

    // Other type mismatches are invalid
    return ConnectionValidationResult.invalid(
      'Incompatible port types: ${outputType.name} → ${inputType.name}',
      suggestions: [
        'Connect ${outputType.name} outputs to ${outputType.name} inputs',
        'Use compatible port types (audio ↔ cv, gate ↔ trigger)',
      ],
    );
  }

  /// Check for duplicate connections
  static ConnectionValidationResult _checkForDuplicateConnection(
    String sourcePortId,
    String targetPortId,
    List<Connection> existingConnections,
  ) {
    final duplicate = existingConnections
        .where((conn) => 
            conn.sourcePortId == sourcePortId && 
            conn.destinationPortId == targetPortId)
        .firstOrNull;

    if (duplicate != null) {
      return ConnectionValidationResult.invalid(
        'Connection already exists between these ports',
        suggestions: [
          'Delete the existing connection first',
          'Modify the existing connection properties instead',
        ],
      );
    }

    return ConnectionValidationResult.valid();
  }

  /// Validate bus availability
  static ConnectionValidationResult _validateBusAvailability(
    editor_state.RoutingEditorStateLoaded currentState,
  ) {
    const maxBuses = 28;
    final currentBusCount = currentState.connections
        .where((conn) => conn.busNumber != null)
        .map((conn) => conn.busNumber!)
        .toSet()
        .length;

    if (currentBusCount >= maxBuses) {
      return ConnectionValidationResult.invalid(
        'No available buses for new connections ($currentBusCount/$maxBuses used)',
        suggestions: [
          'Delete unused connections to free up buses',
          'Combine multiple connections on the same bus',
        ],
      );
    }

    if (currentBusCount >= maxBuses * 0.9) {
      return ConnectionValidationResult.validWithWarning(
        'Bus usage is high ($currentBusCount/$maxBuses used)',
      );
    }

    return ConnectionValidationResult.valid();
  }

  /// Validate hardware limitations
  static ConnectionValidationResult _validateHardwareLimitations(
    Port outputPort,
    Port inputPort,
    editor_state.RoutingEditorStateLoaded currentState,
  ) {
    // Check for excessive fan-out (one output connected to many inputs)
    final fanOutCount = currentState.connections
        .where((conn) => conn.sourcePortId == outputPort.id)
        .length;

    if (fanOutCount >= 8) {
      return ConnectionValidationResult.invalid(
        'Output port has too many connections (${fanOutCount + 1}/8)',
        suggestions: [
          'Use a splitter or multiple algorithm',
          'Remove some existing connections from this output',
        ],
      );
    }

    if (fanOutCount >= 5) {
      return ConnectionValidationResult.validWithWarning(
        'High fan-out detected (${fanOutCount + 1} connections from one output)',
      );
    }

    // Check for multiple inputs to one input port (should be prevented by design)
    final inputConnections = currentState.connections
        .where((conn) => conn.destinationPortId == inputPort.id)
        .length;

    if (inputConnections > 0) {
      return ConnectionValidationResult.invalid(
        'Input port already has a connection',
        suggestions: [
          'Disconnect the existing input connection first',
          'Use add mode instead of replace mode if supported',
        ],
      );
    }

    return ConnectionValidationResult.valid();
  }

  /// Validate performance impact
  static ConnectionValidationResult _validatePerformanceImpact(
    editor_state.RoutingEditorStateLoaded currentState,
  ) {
    const maxRecommendedConnections = 100;
    final connectionCount = currentState.connections.length;

    if (connectionCount >= maxRecommendedConnections) {
      return ConnectionValidationResult.validWithWarning(
        'High connection count may impact performance (${connectionCount + 1}+ connections)',
      );
    }

    return ConnectionValidationResult.valid();
  }

  /// Validate critical path deletion
  static ConnectionValidationResult _validateCriticalPathDeletion(
    Connection connection,
    editor_state.RoutingEditorStateLoaded currentState,
  ) {
    // Check if this connection is the only path between hardware I/O
    final isHardwareConnection = connection.connectionType == ConnectionType.hardwareInput ||
                                connection.connectionType == ConnectionType.hardwareOutput;

    if (isHardwareConnection) {
      // Count other hardware connections to the same ports
      final relatedConnections = currentState.connections.where((conn) =>
          conn.id != connection.id &&
          (conn.sourcePortId == connection.sourcePortId || 
           conn.destinationPortId == connection.destinationPortId)
      ).length;

      if (relatedConnections == 0) {
        return ConnectionValidationResult.validWithWarning(
          'Deleting this connection will disconnect hardware I/O',
        );
      }
    }

    return ConnectionValidationResult.valid();
  }

  /// Real-time validation during drag operations
  static ConnectionValidationResult validateDragTarget({
    required Port sourcePort,
    required Port? targetPort,
    required editor_state.RoutingEditorStateLoaded currentState,
    required Offset dragPosition,
  }) {
    if (targetPort == null) {
      return ConnectionValidationResult.invalid(
        'No valid drop target at this position',
        suggestions: ['Drag to a compatible port'],
      );
    }

    return validateConnectionCreation(
      sourcePort: sourcePort,
      targetPort: targetPort,
      currentState: currentState,
      isDragOperation: true,
    );
  }
}