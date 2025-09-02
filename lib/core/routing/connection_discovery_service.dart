import 'package:flutter/foundation.dart';
import 'algorithm_routing.dart';
import 'models/port.dart';
import 'models/connection.dart';

/// Service for discovering connections between algorithms based on shared bus assignments.
/// 
/// This service analyzes AlgorithmRouting instances to discover connections
/// based on bus values stored in port metadata. It supports:
/// - Hardware connections (buses 1-12 inputs, 13-20 outputs)
/// - Algorithm-to-algorithm connections (any shared bus)
class ConnectionDiscoveryService {
  /// Discovers all connections from a list of AlgorithmRouting instances.
  /// 
  /// Parameters:
  /// - [routings]: List of AlgorithmRouting instances to analyze
  /// 
  /// Returns a list of Connection objects representing discovered connections
  static List<Connection> discoverConnections(List<AlgorithmRouting> routings) {
    final connections = <Connection>[];
    
    debugPrint('[ConnectionDiscovery] Starting discovery for ${routings.length} algorithms');
    
    // Build a bus registry mapping bus numbers to ports
    final busRegistry = <int, List<_PortAssignment>>{};
    
    // Process all algorithms to build the bus registry
    for (int i = 0; i < routings.length; i++) {
      final routing = routings[i];
      final algorithmId = _extractAlgorithmId(routing);
      
      debugPrint('[ConnectionDiscovery] Processing algorithm $i ($algorithmId)');
      
      // Register input ports
      _registerPorts(routing.inputPorts, algorithmId, i, false, busRegistry);
      
      // Register output ports
      _registerPorts(routing.outputPorts, algorithmId, i, true, busRegistry);
    }
    
    // Debug: Print bus registry summary
    _logBusRegistrySummary(busRegistry);
    
    // Create connections based on bus assignments
    for (final entry in busRegistry.entries) {
      final busNumber = entry.key;
      final assignments = entry.value;
      
      // Separate outputs and inputs
      final outputs = assignments.where((a) => a.isOutput).toList();
      final inputs = assignments.where((a) => !a.isOutput).toList();
      
      // Determine if this is a hardware bus
      final isHardwareInput = busNumber >= 1 && busNumber <= 12;
      final isHardwareOutput = busNumber >= 13 && busNumber <= 20;
      
      // Create hardware input connections (buses 1-12)
      if (isHardwareInput && inputs.isNotEmpty) {
        connections.addAll(_createHardwareInputConnections(busNumber, inputs));
      }
      
      // Create hardware output connections (buses 13-20)
      if (isHardwareOutput && outputs.isNotEmpty) {
        connections.addAll(_createHardwareOutputConnections(busNumber, outputs));
      }
      
      // Create algorithm-to-algorithm connections (ANY bus with both inputs and outputs)
      if (outputs.isNotEmpty && inputs.isNotEmpty) {
        connections.addAll(_createAlgorithmConnections(busNumber, outputs, inputs));
      }
    }
    
    debugPrint('[ConnectionDiscovery] Created ${connections.length} total connections');
    _logConnectionSummary(connections);
    
    return connections;
  }
  
  /// Registers ports in the bus registry based on their bus values
  static void _registerPorts(
    List<Port> ports, 
    String algorithmId, 
    int algorithmIndex, 
    bool isOutput, 
    Map<int, List<_PortAssignment>> busRegistry,
  ) {
    for (final port in ports) {
      final busValue = port.metadata?['busValue'] as int?;
      if (busValue != null && busValue > 0) {
        debugPrint('[ConnectionDiscovery]   ${isOutput ? 'Output' : 'Input'} port ${port.id}: bus=$busValue');
        busRegistry.putIfAbsent(busValue, () => []).add(
          _PortAssignment(
            algorithmId: algorithmId,
            algorithmIndex: algorithmIndex,
            portId: port.id,
            portName: port.name,
            parameterName: port.metadata?['busParam'] as String? ?? '',
            parameterNumber: port.metadata?['parameterNumber'] as int? ?? 0,
            isOutput: isOutput,
            portType: port.type,
            busValue: busValue,
          ),
        );
      }
    }
  }
  
  /// Creates hardware input connections (physical hardware to algorithm inputs)
  static List<Connection> _createHardwareInputConnections(int busNumber, List<_PortAssignment> inputs) {
    final connections = <Connection>[];
    final hwPortId = 'hw_in_$busNumber';
    
    for (final input in inputs) {
      connections.add(Connection(
        id: 'conn_${hwPortId}_to_${input.portId}',
        sourcePortId: hwPortId,
        destinationPortId: input.portId,
        properties: {
          'connectionType': 'hardware_input',
          'busNumber': busNumber,
          'targetAlgorithmId': input.algorithmId,
          'targetParameterNumber': input.parameterNumber,
          'signalType': _toSignalTypeName(input.portType),
        },
      ));
    }
    
    return connections;
  }
  
  /// Creates hardware output connections (algorithm outputs to physical hardware)
  static List<Connection> _createHardwareOutputConnections(int busNumber, List<_PortAssignment> outputs) {
    final connections = <Connection>[];
    final hwPortId = 'hw_out_${busNumber - 12}';  // Bus 13->hw_out_1, etc.
    
    for (final output in outputs) {
      connections.add(Connection(
        id: 'conn_${output.portId}_to_$hwPortId',
        sourcePortId: output.portId,
        destinationPortId: hwPortId,
        properties: {
          'connectionType': 'hardware_output',
          'busNumber': busNumber,
          'sourceAlgorithmId': output.algorithmId,
          'sourceParameterNumber': output.parameterNumber,
          'signalType': _toSignalTypeName(output.portType),
        },
      ));
    }
    
    return connections;
  }
  
  /// Creates algorithm-to-algorithm connections
  static List<Connection> _createAlgorithmConnections(
    int busNumber, 
    List<_PortAssignment> outputs, 
    List<_PortAssignment> inputs,
  ) {
    final connections = <Connection>[];
    
    debugPrint('[ConnectionDiscovery] Bus $busNumber has potential algo-to-algo connections');
    for (final output in outputs) {
      for (final input in inputs) {
        // Skip self-connections
        if (output.algorithmId != input.algorithmId) {
          debugPrint('[ConnectionDiscovery]   Creating: ${output.algorithmId} -> ${input.algorithmId}');
          
          // Check for backward edge (output from later algorithm to earlier algorithm)
          final isBackwardEdge = output.algorithmIndex > input.algorithmIndex;
          
          connections.add(Connection(
            id: 'conn_${output.portId}_to_${input.portId}',
            sourcePortId: output.portId,
            destinationPortId: input.portId,
            properties: {
              'connectionType': 'algorithm_to_algorithm',
              'busNumber': busNumber,
              'sourceAlgorithmId': output.algorithmId,
              'targetAlgorithmId': input.algorithmId,
              'sourceParameterNumber': output.parameterNumber,
              'targetParameterNumber': input.parameterNumber,
              'isBackwardEdge': isBackwardEdge,
              'signalType': _toSignalTypeName(output.portType),
            },
          ));
        }
      }
    }
    
    return connections;
  }
  
  /// Extracts algorithm ID from routing instance
  static String _extractAlgorithmId(AlgorithmRouting routing) {
    // Try to get algorithm UUID from properties if available
    if (routing.inputPorts.isNotEmpty) {
      final firstPort = routing.inputPorts.first;
      if (firstPort.id.contains('_param_')) {
        return firstPort.id.split('_param_').first;
      }
    }
    if (routing.outputPorts.isNotEmpty) {
      final firstPort = routing.outputPorts.first;
      if (firstPort.id.contains('_param_')) {
        return firstPort.id.split('_param_').first;
      }
    }
    
    // Fallback
    return 'algo_${routing.hashCode}';
  }
  
  /// Converts PortType to signal type name
  static String _toSignalTypeName(PortType portType) {
    switch (portType) {
      case PortType.audio:
        return 'audio';
      case PortType.cv:
        return 'cv';
      case PortType.gate:
        return 'gate';
      case PortType.clock:
        return 'clock';
    }
  }
  
  /// Logs bus registry summary for debugging
  static void _logBusRegistrySummary(Map<int, List<_PortAssignment>> busRegistry) {
    debugPrint('[ConnectionDiscovery] Bus registry summary:');
    for (final entry in busRegistry.entries) {
      final busNumber = entry.key;
      final assignments = entry.value;
      final outputs = assignments.where((a) => a.isOutput).length;
      final inputs = assignments.where((a) => !a.isOutput).length;
      debugPrint('[ConnectionDiscovery]   Bus $busNumber: $outputs outputs, $inputs inputs');
    }
  }
  
  /// Logs connection summary for debugging
  static void _logConnectionSummary(List<Connection> connections) {
    final hwConnections = connections.where((c) => 
      c.properties?['connectionType'] == 'hardware_input' ||
      c.properties?['connectionType'] == 'hardware_output'
    ).length;
    final algoConnections = connections.where((c) => 
      c.properties?['connectionType'] == 'algorithm_to_algorithm'
    ).length;
    
    debugPrint('[ConnectionDiscovery]   Hardware connections: $hwConnections');
    debugPrint('[ConnectionDiscovery]   Algorithm-to-algorithm: $algoConnections');
  }
}

/// Internal class to track port assignments in the bus registry
class _PortAssignment {
  final String algorithmId;
  final int algorithmIndex;
  final String portId;
  final String portName;
  final String parameterName;
  final int parameterNumber;
  final bool isOutput;
  final PortType portType;
  final int busValue;
  
  _PortAssignment({
    required this.algorithmId,
    required this.algorithmIndex,
    required this.portId,
    required this.portName,
    required this.parameterName,
    required this.parameterNumber,
    required this.isOutput,
    required this.portType,
    required this.busValue,
  });
}