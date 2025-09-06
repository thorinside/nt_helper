import 'package:nt_helper/core/routing/models/connection.dart';
import 'package:nt_helper/core/routing/models/port.dart';

/// Service for managing automatic bus assignments for connections
class ConnectionBusManager {
  // Bus assignment ranges
  static const int physicalInputBusStart = 1;   // Buses 1-12 for physical inputs
  static const int physicalOutputBusStart = 13; // Buses 13-20 for physical outputs
  static const int auxBusStart = 21;             // Buses 21-28 for aux connections
  static const int maxBus = 28;

  // Track bus assignments
  final Set<int> _assignedBuses = <int>{};
  final Map<String, int> _connectionBusMap = <String, int>{};

  /// Assign a bus to a connection automatically
  int? assignBus(Connection connection, Port sourcePort, Port targetPort) {
    // Check if connection already has a bus assignment
    if (_connectionBusMap.containsKey(connection.id)) {
      return _connectionBusMap[connection.id];
    }

    int? busNumber;

    // Determine bus assignment strategy based on connection type
    switch (connection.connectionType) {
      case ConnectionType.hardwareInput:
        // Physical input connections use buses 1-12
        busNumber = _assignPhysicalInputBus(targetPort);
        break;
        
      case ConnectionType.hardwareOutput:
        // Physical output connections use buses 13-20
        busNumber = _assignPhysicalOutputBus(sourcePort);
        break;
        
      case ConnectionType.algorithmToAlgorithm:
        // Algorithm-to-algorithm connections use aux buses 21-28
        busNumber = _assignAuxBus();
        break;
        
      case ConnectionType.partialOutputToBus:
        // Partial output connections use aux buses 21-28
        busNumber = _assignAuxBus();
        break;
        
      case ConnectionType.partialBusToInput:
        // Partial input connections use aux buses 21-28
        busNumber = _assignAuxBus();
        break;
    }

    if (busNumber != null) {
      _assignedBuses.add(busNumber);
      _connectionBusMap[connection.id] = busNumber;
    }

    return busNumber;
  }

  /// Assign a physical input bus (1-12)
  int? _assignPhysicalInputBus(Port inputPort) {
    // Try to use the port's preferred bus if available
    if (inputPort.busValue != null && 
        inputPort.busValue! >= physicalInputBusStart && 
        inputPort.busValue! < physicalOutputBusStart &&
        !_assignedBuses.contains(inputPort.busValue!)) {
      return inputPort.busValue!;
    }

    // Find next available physical input bus
    for (int bus = physicalInputBusStart; bus < physicalOutputBusStart; bus++) {
      if (!_assignedBuses.contains(bus)) {
        return bus;
      }
    }

    return null; // No available physical input buses
  }

  /// Assign a physical output bus (13-20)
  int? _assignPhysicalOutputBus(Port outputPort) {
    // Try to use the port's preferred bus if available
    if (outputPort.busValue != null && 
        outputPort.busValue! >= physicalOutputBusStart && 
        outputPort.busValue! < auxBusStart &&
        !_assignedBuses.contains(outputPort.busValue!)) {
      return outputPort.busValue!;
    }

    // Find next available physical output bus
    for (int bus = physicalOutputBusStart; bus < auxBusStart; bus++) {
      if (!_assignedBuses.contains(bus)) {
        return bus;
      }
    }

    return null; // No available physical output buses
  }

  /// Assign an auxiliary bus (21-28) for algorithm-to-algorithm connections
  int? _assignAuxBus() {
    // Find next available aux bus
    for (int bus = auxBusStart; bus <= maxBus; bus++) {
      if (!_assignedBuses.contains(bus)) {
        return bus;
      }
    }

    return null; // No available aux buses
  }

  /// Release a bus assignment
  void releaseBus(String connectionId) {
    final busNumber = _connectionBusMap.remove(connectionId);
    if (busNumber != null) {
      _assignedBuses.remove(busNumber);
    }
  }

  /// Get the bus assignment for a connection
  int? getBusForConnection(String connectionId) {
    return _connectionBusMap[connectionId];
  }

  /// Check if a bus is available
  bool isBusAvailable(int busNumber) {
    return busNumber >= 1 && busNumber <= maxBus && !_assignedBuses.contains(busNumber);
  }

  /// Get all assigned buses
  Set<int> get assignedBuses => Set.unmodifiable(_assignedBuses);

  /// Get available buses in a range
  List<int> getAvailableBuses({int start = 1, int end = maxBus}) {
    final available = <int>[];
    for (int bus = start; bus <= end; bus++) {
      if (!_assignedBuses.contains(bus)) {
        available.add(bus);
      }
    }
    return available;
  }

  /// Get available physical input buses (1-12)
  List<int> get availablePhysicalInputBuses => 
      getAvailableBuses(start: physicalInputBusStart, end: physicalOutputBusStart - 1);

  /// Get available physical output buses (13-20)
  List<int> get availablePhysicalOutputBuses => 
      getAvailableBuses(start: physicalOutputBusStart, end: auxBusStart - 1);

  /// Get available aux buses (21-28)
  List<int> get availableAuxBuses => 
      getAvailableBuses(start: auxBusStart, end: maxBus);

  /// Force assign a specific bus (bypasses availability checks)
  bool forceAssignBus(String connectionId, int busNumber) {
    if (busNumber < 1 || busNumber > maxBus) return false;

    // Release any existing assignment
    releaseBus(connectionId);

    // Assign the new bus
    _assignedBuses.add(busNumber);
    _connectionBusMap[connectionId] = busNumber;
    return true;
  }

  /// Get bus usage statistics
  Map<String, dynamic> getBusStatistics() {
    return {
      'totalBuses': maxBus,
      'assignedBuses': _assignedBuses.length,
      'availableBuses': maxBus - _assignedBuses.length,
      'physicalInputBusesUsed': _assignedBuses
          .where((bus) => bus >= physicalInputBusStart && bus < physicalOutputBusStart)
          .length,
      'physicalOutputBusesUsed': _assignedBuses
          .where((bus) => bus >= physicalOutputBusStart && bus < auxBusStart)
          .length,
      'auxBusesUsed': _assignedBuses
          .where((bus) => bus >= auxBusStart && bus <= maxBus)
          .length,
      'utilizationPercent': (_assignedBuses.length / maxBus * 100).round(),
    };
  }

  /// Clear all bus assignments
  void clear() {
    _assignedBuses.clear();
    _connectionBusMap.clear();
  }

  /// Initialize bus assignments from existing connections
  void initializeFromConnections(List<Connection> connections) {
    clear();
    
    for (final connection in connections) {
      if (connection.busNumber != null) {
        _assignedBuses.add(connection.busNumber!);
        _connectionBusMap[connection.id] = connection.busNumber!;
      }
    }
  }
}
