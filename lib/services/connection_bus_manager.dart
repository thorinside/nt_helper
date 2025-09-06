import 'package:flutter/foundation.dart';
import 'package:nt_helper/cubit/routing_editor_state.dart';
import 'package:nt_helper/core/routing/models/connection.dart';

/// Service for managing automatic bus assignment for connections
class ConnectionBusManager {
  /// Physical input bus range (1-12)
  static const int physicalInputBusStart = 1;
  static const int physicalInputBusEnd = 12;

  /// Physical output bus range (13-20)
  static const int physicalOutputBusStart = 13;
  static const int physicalOutputBusEnd = 20;

  /// Aux bus range for algorithm-to-algorithm connections (21-28)
  static const int auxBusStart = 21;
  static const int auxBusEnd = 28;

  /// Assign appropriate bus numbers to a new connection
  static Map<String, dynamic> assignBus({
    required Connection connection,
    required Port sourcePort,
    required Port targetPort,
    required List<Connection> existingConnections,
  }) {
    debugPrint('Assigning bus for connection: ${sourcePort.name} -> ${targetPort.name}');

    // Determine connection type and assign bus accordingly
    final connectionType = _determineConnectionType(sourcePort, targetPort);
    int? assignedBus;
    String? conflictReason;

    switch (connectionType) {
      case ConnectionType.hardwareInput:
        assignedBus = _assignPhysicalInputBus(sourcePort, existingConnections);
        break;
      case ConnectionType.hardwareOutput:
        assignedBus = _assignPhysicalOutputBus(targetPort, existingConnections);
        break;
      case ConnectionType.algorithmToAlgorithm:
        assignedBus = _assignAuxBus(existingConnections);
        break;
      case ConnectionType.partialOutputToBus:
      case ConnectionType.partialBusToInput:
        // Handle partial connections - use aux bus
        assignedBus = _assignAuxBus(existingConnections);
        break;
    }

    // Check for conflicts
    if (assignedBus != null) {
      conflictReason = _checkBusConflicts(assignedBus, existingConnections);
    }

    return {
      'busNumber': assignedBus,
      'connectionType': connectionType,
      'hasConflict': conflictReason != null,
      'conflictReason': conflictReason,
      'isValid': assignedBus != null && conflictReason == null,
    };
  }

  /// Assign bus number for physical input connection
  static int? _assignPhysicalInputBus(
    Port inputPort,
    List<Connection> existingConnections,
  ) {
    // For hardware inputs, use the port's physical number if available
    if (inputPort.id.startsWith('hw_in_')) {
      final portNumberStr = inputPort.id.replaceAll('hw_in_', '');
      final portNumber = int.tryParse(portNumberStr);
      if (portNumber != null && 
          portNumber >= physicalInputBusStart && 
          portNumber <= physicalInputBusEnd) {
        return portNumber;
      }
    }

    // Find first available input bus
    for (int bus = physicalInputBusStart; bus <= physicalInputBusEnd; bus++) {
      if (!_isBusUsed(bus, existingConnections)) {
        return bus;
      }
    }

    return null; // No available input buses
  }

  /// Assign bus number for physical output connection
  static int? _assignPhysicalOutputBus(
    Port outputPort,
    List<Connection> existingConnections,
  ) {
    // For hardware outputs, use the port's physical number if available
    if (outputPort.id.startsWith('hw_out_')) {
      final portNumberStr = outputPort.id.replaceAll('hw_out_', '');
      final portNumber = int.tryParse(portNumberStr);
      if (portNumber != null) {
        // Map to output bus range (13-20)
        final busNumber = physicalOutputBusStart + portNumber - 1;
        if (busNumber <= physicalOutputBusEnd) {
          return busNumber;
        }
      }
    }

    // Find first available output bus
    for (int bus = physicalOutputBusStart; bus <= physicalOutputBusEnd; bus++) {
      if (!_isBusUsed(bus, existingConnections)) {
        return bus;
      }
    }

    return null; // No available output buses
  }

  /// Assign bus number for algorithm-to-algorithm connection
  static int? _assignAuxBus(List<Connection> existingConnections) {
    // Find first available aux bus
    for (int bus = auxBusStart; bus <= auxBusEnd; bus++) {
      if (!_isBusUsed(bus, existingConnections)) {
        return bus;
      }
    }

    return null; // No available aux buses
  }

  /// Check if a bus number is already in use
  static bool _isBusUsed(int busNumber, List<Connection> connections) {
    return connections.any((conn) => conn.busId == busNumber.toString());
  }

  /// Check for potential bus conflicts
  static String? _checkBusConflicts(
    int busNumber,
    List<Connection> existingConnections,
  ) {
    final conflictingConnections = existingConnections
        .where((conn) => conn.busId == busNumber.toString())
        .toList();

    if (conflictingConnections.isEmpty) return null;

    // Check for specific conflict types
    if (conflictingConnections.length >= 2) {
      return 'Bus $busNumber is already used by ${conflictingConnections.length} connections';
    }

    return null;
  }

  /// Determine connection type based on port characteristics
  static ConnectionType _determineConnectionType(Port sourcePort, Port targetPort) {
    final isSourceHardware = sourcePort.id.startsWith('hw_');
    final isTargetHardware = targetPort.id.startsWith('hw_');

    if (isSourceHardware && !isTargetHardware) {
      return ConnectionType.hardwareInput;
    } else if (!isSourceHardware && isTargetHardware) {
      return ConnectionType.hardwareOutput;
    } else {
      return ConnectionType.algorithmToAlgorithm;
    }
  }

  /// Get available buses for a specific connection type
  static List<int> getAvailableBuses({
    required ConnectionType connectionType,
    required List<Connection> existingConnections,
  }) {
    final availableBuses = <int>[];
    int start, end;

    switch (connectionType) {
      case ConnectionType.hardwareInput:
        start = physicalInputBusStart;
        end = physicalInputBusEnd;
        break;
      case ConnectionType.hardwareOutput:
        start = physicalOutputBusStart;
        end = physicalOutputBusEnd;
        break;
      case ConnectionType.algorithmToAlgorithm:
      case ConnectionType.partialOutputToBus:
      case ConnectionType.partialBusToInput:
        start = auxBusStart;
        end = auxBusEnd;
        break;
    }

    for (int bus = start; bus <= end; bus++) {
      if (!_isBusUsed(bus, existingConnections)) {
        availableBuses.add(bus);
      }
    }

    return availableBuses;
  }

  /// Get bus utilization statistics
  static Map<String, dynamic> getBusUtilization(List<Connection> connections) {
    final inputBusesUsed = <int>{};
    final outputBusesUsed = <int>{};
    final auxBusesUsed = <int>{};

    for (final connection in connections) {
      final busId = connection.busId;
      if (busId != null) {
        final busNumber = int.tryParse(busId);
        if (busNumber != null) {
          if (busNumber >= physicalInputBusStart && busNumber <= physicalInputBusEnd) {
            inputBusesUsed.add(busNumber);
          } else if (busNumber >= physicalOutputBusStart && busNumber <= physicalOutputBusEnd) {
            outputBusesUsed.add(busNumber);
          } else if (busNumber >= auxBusStart && busNumber <= auxBusEnd) {
            auxBusesUsed.add(busNumber);
          }
        }
      }
    }

    return {
      'inputBusesUsed': inputBusesUsed.length,
      'inputBusesTotal': physicalInputBusEnd - physicalInputBusStart + 1,
      'outputBusesUsed': outputBusesUsed.length,
      'outputBusesTotal': physicalOutputBusEnd - physicalOutputBusStart + 1,
      'auxBusesUsed': auxBusesUsed.length,
      'auxBusesTotal': auxBusEnd - auxBusStart + 1,
      'totalBusesUsed': inputBusesUsed.length + outputBusesUsed.length + auxBusesUsed.length,
      'totalBusesAvailable': (physicalInputBusEnd - physicalInputBusStart + 1) +
                             (physicalOutputBusEnd - physicalOutputBusStart + 1) +
                             (auxBusEnd - auxBusStart + 1),
    };
  }
}