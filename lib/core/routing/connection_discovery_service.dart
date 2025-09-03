import 'package:flutter/foundation.dart';
import 'algorithm_routing.dart';
import 'models/port.dart';
import 'models/connection.dart';
import '../../ui/widgets/routing/bus_label_formatter.dart';

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
    
    // Track matched ports to identify unmatched ones for partial connections
    final matchedPorts = <String>{};
    
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
        // Mark these input ports as matched
        for (final input in inputs) {
          matchedPorts.add(input.portId);
        }
      }
      
      // Create hardware output connections (buses 13-20)
      if (isHardwareOutput && outputs.isNotEmpty) {
        connections.addAll(_createHardwareOutputConnections(busNumber, outputs));
        // Mark these output ports as matched
        for (final output in outputs) {
          matchedPorts.add(output.portId);
        }
      }
      
      // Create algorithm-to-algorithm connections (ANY bus with both inputs and outputs)
      if (outputs.isNotEmpty && inputs.isNotEmpty) {
        connections.addAll(_createAlgorithmConnections(busNumber, outputs, inputs));
        // Mark all algorithm ports involved in connections as matched
        for (final output in outputs) {
          for (final input in inputs) {
            if (output.algorithmId != input.algorithmId) {
              matchedPorts.add(output.portId);
              matchedPorts.add(input.portId);
            }
          }
        }
      }
    }
    
    // Create partial connections for unmatched ports with non-zero bus values
    final partialConnections = _createPartialConnections(busRegistry, matchedPorts);
    connections.addAll(partialConnections);
    
    debugPrint('[ConnectionDiscovery] Created ${connections.length - partialConnections.length} full connections');
    debugPrint('[ConnectionDiscovery] Created ${partialConnections.length} partial connections');
    debugPrint('[ConnectionDiscovery] Total connections: ${connections.length}');
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
        debugPrint('[ConnectionDiscovery]   ${isOutput ? 'Output' : 'Input'} port ${port.id}: bus=$busValue, outputMode=${port.outputMode}');
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
            outputMode: port.outputMode,
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
        connectionType: ConnectionType.hardwareInput,
        busNumber: busNumber,
        algorithmId: input.algorithmId,
        algorithmIndex: input.algorithmIndex,
        parameterNumber: input.parameterNumber,
        signalType: _toSignalType(input.portType),
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
        connectionType: ConnectionType.hardwareOutput,
        busNumber: busNumber,
        algorithmId: output.algorithmId,
        algorithmIndex: output.algorithmIndex,
        parameterNumber: output.parameterNumber,
        signalType: _toSignalType(output.portType),
        isOutput: true,
        outputMode: output.outputMode,
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
            connectionType: ConnectionType.algorithmToAlgorithm,
            busNumber: busNumber,
            algorithmId: output.algorithmId,
            algorithmIndex: output.algorithmIndex,
            parameterNumber: output.parameterNumber,
            signalType: _toSignalType(output.portType),
            isBackwardEdge: isBackwardEdge,
            isOutput: true,
            outputMode: output.outputMode,
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
  
  
  /// Converts PortType to SignalType enum
  static SignalType _toSignalType(PortType type) {
    switch (type) {
      case PortType.audio:
        return SignalType.audio;
      case PortType.cv:
        return SignalType.cv;
      case PortType.gate:
        return SignalType.gate;
      case PortType.clock:
        return SignalType.trigger; // Map clock to trigger
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
      c.connectionType == ConnectionType.hardwareInput ||
      c.connectionType == ConnectionType.hardwareOutput
    ).length;
    final algoConnections = connections.where((c) => 
      c.connectionType == ConnectionType.algorithmToAlgorithm
    ).length;
    final partialConnections = connections.where((c) => c.isPartial).length;
    
    debugPrint('[ConnectionDiscovery]   Hardware connections: $hwConnections');
    debugPrint('[ConnectionDiscovery]   Algorithm-to-algorithm: $algoConnections');
    debugPrint('[ConnectionDiscovery]   Partial connections: $partialConnections');
  }
  
  /// Creates partial connections for unmatched ports with non-zero bus values
  static List<Connection> _createPartialConnections(
    Map<int, List<_PortAssignment>> busRegistry,
    Set<String> matchedPorts,
  ) {
    final partialConnections = <Connection>[];
    
    debugPrint('[ConnectionDiscovery] Creating partial connections for unmatched ports');
    
    // Process each bus to find unmatched ports
    for (final entry in busRegistry.entries) {
      final busNumber = entry.key;
      final assignments = entry.value;
      
      // Find unmatched ports (those with non-zero bus values that weren't matched)
      final unmatchedPorts = assignments.where((assignment) => 
        !matchedPorts.contains(assignment.portId)
      ).toList();
      
      if (unmatchedPorts.isEmpty) continue;
      
      debugPrint('[ConnectionDiscovery] Bus $busNumber has ${unmatchedPorts.length} unmatched ports');
      
      // Create partial connections for each unmatched port
      for (final port in unmatchedPorts) {
        final busLabel = _generateBusLabel(busNumber);
        final partialConnection = _createPartialConnection(port, busNumber, busLabel);
        partialConnections.add(partialConnection);
        
        debugPrint('[ConnectionDiscovery]   Created partial connection: ${port.portId} -> $busLabel');
      }
    }
    
    return partialConnections;
  }
  
  /// Creates a single partial connection for an unmatched port
  static Connection _createPartialConnection(
    _PortAssignment portAssignment,
    int busNumber,
    String busLabel,
  ) {
    // Create unique IDs for the bus endpoint
    final busPortId = 'bus_${busNumber}_endpoint';
    
    // Determine connection direction based on port type
    final String sourcePortId;
    final String destinationPortId;
    final ConnectionType connectionType;
    
    if (portAssignment.isOutput) {
      // Output port connects TO bus
      sourcePortId = portAssignment.portId;
      destinationPortId = busPortId;
      connectionType = ConnectionType.partialOutputToBus;
    } else {
      // Input port connects FROM bus  
      sourcePortId = busPortId;
      destinationPortId = portAssignment.portId;
      connectionType = ConnectionType.partialBusToInput;
    }
    
    return Connection(
      id: 'partial_conn_${portAssignment.portId}_bus_$busNumber',
      sourcePortId: sourcePortId,
      destinationPortId: destinationPortId,
      connectionType: connectionType,
      isPartial: true,
      busNumber: busNumber,
      busLabel: busLabel,
      algorithmId: portAssignment.algorithmId,
      algorithmIndex: portAssignment.algorithmIndex,
      parameterNumber: portAssignment.parameterNumber,
      parameterName: portAssignment.parameterName,
      portName: portAssignment.portName,
      signalType: _toSignalType(portAssignment.portType),
      isOutput: portAssignment.isOutput,
    );
  }
  
  /// Generates a human-readable bus label for the given bus number
  static String _generateBusLabel(int busNumber) {
    // Use the centralized BusLabelFormatter for consistent labeling across the app
    // This ensures all bus labels follow the same format: I1-I12, O1-O8, A1-A8
    return BusLabelFormatter.formatBusNumber(busNumber) ?? 'Bus$busNumber';
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
  final OutputMode? outputMode;
  
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
    this.outputMode,
  });
}