import 'package:flutter/foundation.dart';
import 'package:nt_helper/cubit/routing_editor_state.dart';
import 'package:nt_helper/core/routing/models/connection.dart';

/// Validation result for connection attempts
class ConnectionValidationResult {
  final bool isValid;
  final String? errorMessage;
  final List<String> warnings;
  final Map<String, dynamic> metadata;

  const ConnectionValidationResult({
    required this.isValid,
    this.errorMessage,
    this.warnings = const [],
    this.metadata = const {},
  });

  ConnectionValidationResult.valid({
    this.warnings = const [],
    this.metadata = const {},
  })  : isValid = true,
        errorMessage = null;

  ConnectionValidationResult.invalid({
    required String error,
    this.warnings = const [],
    this.metadata = const {},
  })  : isValid = false,
        errorMessage = error;
}

/// Service for validating interactive connections in real-time
class InteractiveConnectionValidator {
  /// Validate a potential connection during drag operations
  static ConnectionValidationResult validateDragConnection({
    required Port sourcePort,
    required Port targetPort,
    required List<Connection> existingConnections,
    required List<RoutingAlgorithm> algorithms,
  }) {
    debugPrint('Validating drag connection: ${sourcePort.name} -> ${targetPort.name}');

    // Rule 1: Port compatibility - Output ports can only connect to input ports
    final portCompatibilityResult = _validatePortCompatibility(sourcePort, targetPort);
    if (!portCompatibilityResult.isValid) {
      return portCompatibilityResult;
    }

    // Rule 2: Signal type matching
    final signalTypeResult = _validateSignalTypes(sourcePort, targetPort);
    if (!signalTypeResult.isValid) {
      return signalTypeResult;
    }

    // Rule 3: Self-connection prevention
    final selfConnectionResult = _validateSelfConnection(sourcePort, targetPort, algorithms);
    if (!selfConnectionResult.isValid) {
      return selfConnectionResult;
    }

    // Rule 4: Duplicate prevention
    final duplicateResult = _validateDuplicate(sourcePort, targetPort, existingConnections);
    if (!duplicateResult.isValid) {
      return duplicateResult;
    }

    // All validations passed
    return ConnectionValidationResult.valid(
      metadata: {
        'sourcePortId': sourcePort.id,
        'targetPortId': targetPort.id,
        'sourcePortType': sourcePort.type.toString(),
        'targetPortType': targetPort.type.toString(),
      },
    );
  }

  /// Validate connection with full context including bus availability
  static ConnectionValidationResult validateFullConnection({
    required Port sourcePort,
    required Port targetPort,
    required List<Connection> existingConnections,
    required List<RoutingAlgorithm> algorithms,
    required List<RoutingBus> buses,
  }) {
    // First run basic drag validation
    final basicValidation = validateDragConnection(
      sourcePort: sourcePort,
      targetPort: targetPort,
      existingConnections: existingConnections,
      algorithms: algorithms,
    );

    if (!basicValidation.isValid) {
      return basicValidation;
    }

    // Rule 5: Bus availability
    final busAvailabilityResult = _validateBusAvailability(
      sourcePort,
      targetPort,
      existingConnections,
      buses,
    );
    if (!busAvailabilityResult.isValid) {
      return busAvailabilityResult;
    }

    return ConnectionValidationResult.valid(
      metadata: {
        ...basicValidation.metadata,
        'busValidation': busAvailabilityResult.metadata,
      },
    );
  }

  /// Rule 1: Validate port direction compatibility
  static ConnectionValidationResult _validatePortCompatibility(Port sourcePort, Port targetPort) {
    if (sourcePort.direction == targetPort.direction) {
      return ConnectionValidationResult.invalid(
        error: 'Cannot connect ${sourcePort.direction.name} to ${targetPort.direction.name}. '
               'Connections must be from output to input or input to output.',
      );
    }
    return ConnectionValidationResult.valid();
  }

  /// Rule 2: Validate signal type compatibility
  static ConnectionValidationResult _validateSignalTypes(Port sourcePort, Port targetPort) {
    if (_arePortTypesCompatible(sourcePort.type, targetPort.type)) {
      return ConnectionValidationResult.valid();
    }

    return ConnectionValidationResult.invalid(
      error: 'Incompatible signal types: ${sourcePort.type.name} cannot connect to ${targetPort.type.name}',
    );
  }

  /// Rule 3: Prevent algorithm from connecting to itself
  static ConnectionValidationResult _validateSelfConnection(
    Port sourcePort,
    Port targetPort,
    List<RoutingAlgorithm> algorithms,
  ) {
    final sourceAlgorithm = _findAlgorithmForPort(sourcePort, algorithms);
    final targetAlgorithm = _findAlgorithmForPort(targetPort, algorithms);

    if (sourceAlgorithm != null && 
        targetAlgorithm != null && 
        sourceAlgorithm.id == targetAlgorithm.id) {
      return ConnectionValidationResult.invalid(
        error: 'Cannot connect algorithm to itself: ${sourceAlgorithm.algorithm.name}',
      );
    }

    return ConnectionValidationResult.valid();
  }

  /// Rule 4: Prevent duplicate connections
  static ConnectionValidationResult _validateDuplicate(
    Port sourcePort,
    Port targetPort,
    List<Connection> existingConnections,
  ) {
    final existingConnection = existingConnections.any((conn) =>
        conn.sourcePortId == sourcePort.id && 
        conn.destinationPortId == targetPort.id);

    if (existingConnection) {
      return ConnectionValidationResult.invalid(
        error: 'Connection already exists between ${sourcePort.name} and ${targetPort.name}',
      );
    }

    return ConnectionValidationResult.valid();
  }

  /// Rule 5: Validate bus availability
  static ConnectionValidationResult _validateBusAvailability(
    Port sourcePort,
    Port targetPort,
    List<Connection> existingConnections,
    List<RoutingBus> buses,
  ) {
    // For now, assume buses are available
    // This would be enhanced with actual bus assignment logic
    final availableBuses = buses.where((bus) => bus.status == BusStatus.available).toList();
    
    if (availableBuses.isEmpty) {
      return ConnectionValidationResult.invalid(
        error: 'No available buses for connection',
        metadata: {'availableBusCount': 0},
      );
    }

    return ConnectionValidationResult.valid(
      metadata: {
        'availableBusCount': availableBuses.length,
        'recommendedBus': availableBuses.first.id,
      },
    );
  }

  /// Check if port types are compatible for connection
  static bool _arePortTypesCompatible(PortType sourceType, PortType targetType) {
    // Same types are always compatible
    if (sourceType == targetType) return true;

    // Audio and CV are often interchangeable
    if ((sourceType == PortType.audio && targetType == PortType.cv) ||
        (sourceType == PortType.cv && targetType == PortType.audio)) {
      return true;
    }

    // Gate and trigger can be compatible
    if ((sourceType == PortType.gate && targetType == PortType.trigger) ||
        (sourceType == PortType.trigger && targetType == PortType.gate)) {
      return true;
    }

    return false;
  }

  /// Find the algorithm that owns a specific port
  static RoutingAlgorithm? _findAlgorithmForPort(Port port, List<RoutingAlgorithm> algorithms) {
    for (final algorithm in algorithms) {
      if (algorithm.inputPorts.any((p) => p.id == port.id) ||
          algorithm.outputPorts.any((p) => p.id == port.id)) {
        return algorithm;
      }
    }
    return null;
  }

  /// Validate multiple connections at once (batch validation)
  static List<ConnectionValidationResult> validateMultipleConnections({
    required List<Map<String, Port>> connectionPairs,
    required List<Connection> existingConnections,
    required List<RoutingAlgorithm> algorithms,
    required List<RoutingBus> buses,
  }) {
    final results = <ConnectionValidationResult>[];

    for (final pair in connectionPairs) {
      final sourcePort = pair['source']!;
      final targetPort = pair['target']!;

      final result = validateFullConnection(
        sourcePort: sourcePort,
        targetPort: targetPort,
        existingConnections: existingConnections,
        algorithms: algorithms,
        buses: buses,
      );

      results.add(result);
    }

    return results;
  }

  /// Get validation summary for UI feedback
  static Map<String, dynamic> getValidationSummary(List<ConnectionValidationResult> results) {
    final validCount = results.where((r) => r.isValid).length;
    final invalidCount = results.length - validCount;
    final allWarnings = results.expand((r) => r.warnings).toList();

    return {
      'totalConnections': results.length,
      'validConnections': validCount,
      'invalidConnections': invalidCount,
      'hasWarnings': allWarnings.isNotEmpty,
      'warningCount': allWarnings.length,
      'allWarnings': allWarnings,
    };
  }
}