import 'package:flutter/foundation.dart';
import 'algorithm_routing.dart';
import 'es5_encoder_algorithm_routing.dart';
import 'models/port.dart';
import 'models/connection.dart';
import 'bus_spec.dart';
import 'bus_session_resolver.dart';
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

    debugPrint(
      '[ConnectionDiscovery] Starting discovery for ${routings.length} algorithms',
    );

    // Build a bus registry mapping bus numbers to ports
    final busRegistry = <int, List<_PortAssignment>>{};

    // Process all algorithms to build the bus registry
    for (int i = 0; i < routings.length; i++) {
      final routing = routings[i];
      final algorithmId = _extractAlgorithmId(routing);

      debugPrint(
        '[ConnectionDiscovery] Processing algorithm $i ($algorithmId)',
      );

      // Register input ports
      _registerPorts(routing.inputPorts, algorithmId, i, false, busRegistry);

      // Register output ports
      _registerPorts(routing.outputPorts, algorithmId, i, true, busRegistry);
    }

    // Debug: Print bus registry summary
    _logBusRegistrySummary(busRegistry);

    // Track matched ports to identify unmatched ones for partial connections
    final matchedPorts = <String>{};

    final totalSlots = routings.length;

    // Create connections based on bus assignments, but session-aware
    for (final entry in busRegistry.entries) {
      final busNumber = entry.key;
      final assignments = entry.value;

      // Separate outputs and inputs
      final outputs = assignments.where((a) => a.isOutput).toList();
      final inputs = assignments.where((a) => !a.isOutput).toList();

      // Build session resolver from output writes on this bus
      final builder = BusSessionBuilder();
      for (final o in outputs) {
        builder.addWrite(
          bus: busNumber,
          slot: o.algorithmIndex,
          portId: o.portId,
          mode: o.outputMode,
        );
      }
      final resolver = builder.build(totalSlots: totalSlots);

      final isHardwareInput = BusSpec.isPhysicalInput(busNumber);
      final isHardwareOutput =
          BusSpec.isPhysicalOutput(busNumber) || BusSpec.isEs5(busNumber);

      // Algorithm-to-algorithm: connect only from contributing writers for each reader slot
      if (outputs.isNotEmpty && inputs.isNotEmpty) {
        for (final input in inputs) {
          final contributingPortIds = resolver.contributorsForReader(
            busNumber,
            input.algorithmIndex,
          );
          if (contributingPortIds.isEmpty) continue;

          for (final output in outputs) {
            if (!contributingPortIds.contains(output.portId)) continue;
            if (output.algorithmId == input.algorithmId) continue; // no self

            // Ensure forward order (contributors always have lower slot)
            if (output.algorithmIndex >= input.algorithmIndex) continue;

            connections.add(
              Connection(
                id: 'conn_${output.portId}_to_${input.portId}',
                sourcePortId: output.portId,
                destinationPortId: input.portId,
                connectionType: ConnectionType.algorithmToAlgorithm,
                busNumber: busNumber,
                algorithmId: output.algorithmId,
                algorithmIndex: output.algorithmIndex,
                parameterNumber: output.parameterNumber,
                signalType: _toSignalType(output.portType),
                isBackwardEdge: false,
                isOutput: true,
                outputMode: output.outputMode,
              ),
            );

            matchedPorts.add(output.portId);
            matchedPorts.add(input.portId);
          }
        }
      }

      // Hardware input (buses 1-12): only contributes until first replace before reader
      if (isHardwareInput && inputs.isNotEmpty) {
        for (final input in inputs) {
          final contributes = resolver.hardwareSeedContributes(
            busNumber,
            input.algorithmIndex,
          );
          if (!contributes) continue;
          connections.addAll(
            _createHardwareInputConnections(busNumber, [input]),
          );
          matchedPorts.add(input.portId);
        }
      }

      // Hardware output (buses 13-20, ES-5): only from final contributors at end of frame
      if (isHardwareOutput && outputs.isNotEmpty) {
        final finalPortIds = resolver.finalContributors(busNumber);
        if (finalPortIds.isNotEmpty) {
          final selectedOutputs = outputs
              .where((o) => finalPortIds.contains(o.portId))
              .toList();
          connections.addAll(
            _createHardwareOutputConnections(busNumber, selectedOutputs),
          );
          for (final o in selectedOutputs) {
            matchedPorts.add(o.portId);
          }
        }
      }
    }

    // Create ES-5 Encoder mirror connections
    for (final routing in routings) {
      if (routing is ES5EncoderAlgorithmRouting) {
        connections.addAll(_createEs5EncoderConnections(routing));
      }
    }

    // Create ES-5 direct connections for Clock/Euclidean algorithms
    for (final routing in routings) {
      connections.addAll(_createEs5DirectConnections(routing));
    }

    // Create partial connections for unmatched ports with non-zero bus values
    final partialConnections = _createPartialConnections(
      busRegistry,
      matchedPorts,
    );
    connections.addAll(partialConnections);

    debugPrint(
      '[ConnectionDiscovery] Created ${connections.length - partialConnections.length} full connections',
    );
    debugPrint(
      '[ConnectionDiscovery] Created ${partialConnections.length} partial connections',
    );
    debugPrint(
      '[ConnectionDiscovery] Total connections: ${connections.length}',
    );
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
      final busValue = port.busValue;
      if (busValue != null && busValue > 0) {
        debugPrint(
          '[ConnectionDiscovery]   ${isOutput ? 'Output' : 'Input'} port ${port.id}: bus=$busValue, outputMode=${port.outputMode}',
        );
        busRegistry
            .putIfAbsent(busValue, () => [])
            .add(
              _PortAssignment(
                algorithmId: algorithmId,
                algorithmIndex: algorithmIndex,
                portId: port.id,
                portName: port.name,
                parameterName: port.busParam ?? '',
                parameterNumber: port.parameterNumber ?? 0,
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
  static List<Connection> _createHardwareInputConnections(
    int busNumber,
    List<_PortAssignment> inputs,
  ) {
    final connections = <Connection>[];
    final hwPortId = 'hw_in_$busNumber';

    for (final input in inputs) {
      connections.add(
        Connection(
          id: 'conn_${hwPortId}_to_${input.portId}',
          sourcePortId: hwPortId,
          destinationPortId: input.portId,
          connectionType: ConnectionType.hardwareInput,
          busNumber: busNumber,
          algorithmId: input.algorithmId,
          algorithmIndex: input.algorithmIndex,
          parameterNumber: input.parameterNumber,
          signalType: _toSignalType(input.portType),
        ),
      );
    }

    return connections;
  }

  /// Creates hardware output connections (algorithm outputs to physical hardware)
  static List<Connection> _createHardwareOutputConnections(
    int busNumber,
    List<_PortAssignment> outputs,
  ) {
    final connections = <Connection>[];

    // Check for ES-5 buses first (29-30)
    if (BusSpec.isEs5(busNumber)) {
      final es5PortId = busNumber == 29 ? 'es5_L' : 'es5_R';

      debugPrint(
        '[ConnectionDiscovery] Creating ES-5 connections: bus $busNumber -> $es5PortId',
      );

      for (final output in outputs) {
        connections.add(
          Connection(
            id: 'conn_${output.portId}_to_$es5PortId',
            sourcePortId: output.portId,
            destinationPortId: es5PortId,
            connectionType: ConnectionType.hardwareOutput,
            busNumber: busNumber,
            algorithmId: output.algorithmId,
            algorithmIndex: output.algorithmIndex,
            parameterNumber: output.parameterNumber,
            signalType: SignalType.audio, // ES-5 L/R are audio
            isOutput: true,
            outputMode: output.outputMode,
          ),
        );
      }
      return connections;
    }

    // Standard hardware output logic (buses 13-20)
    final hwPortId = 'hw_out_${busNumber - 12}'; // Bus 13->hw_out_1, etc.

    for (final output in outputs) {
      connections.add(
        Connection(
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
        ),
      );
    }

    return connections;
  }

  /// Creates ES-5 Encoder mirror connections from output ports to ES-5 hardware ports
  static List<Connection> _createEs5EncoderConnections(
    ES5EncoderAlgorithmRouting routing,
  ) {
    final connections = <Connection>[];

    debugPrint(
      '[ConnectionDiscovery] Creating ES-5 Encoder mirror connections',
    );

    for (final outputPort in routing.outputPorts) {
      if (outputPort.busParam == ES5EncoderAlgorithmRouting.mirrorBusParam &&
          outputPort.channelNumber != null) {
        final es5PortId = 'es5_${outputPort.channelNumber}';

        connections.add(
          Connection(
            id: 'conn_${outputPort.id}_to_$es5PortId',
            sourcePortId: outputPort.id,
            destinationPortId: es5PortId,
            connectionType: ConnectionType.algorithmToAlgorithm,
            algorithmId: routing.algorithmUuid ?? ES5EncoderAlgorithmRouting.defaultAlgorithmUuid,
            signalType: SignalType.gate,
            description: 'ES-5 Encoder mirror connection',
          ),
        );

        debugPrint(
          '[ConnectionDiscovery]   Mirror: ${outputPort.id} -> $es5PortId',
        );
      }
    }

    debugPrint(
      '[ConnectionDiscovery] Created ${connections.length} ES-5 Encoder mirror connections',
    );

    return connections;
  }

  /// Creates ES-5 direct connections for Clock/Euclidean algorithms
  ///
  /// When Clock or Euclidean algorithms have ES-5 Expander active,
  /// their outputs connect directly to ES-5 ports, bypassing normal bus routing.
  static List<Connection> _createEs5DirectConnections(
    AlgorithmRouting routing,
  ) {
    final connections = <Connection>[];

    for (final outputPort in routing.outputPorts) {
      if (outputPort.busParam == 'es5_direct' &&
          outputPort.channelNumber != null) {
        final es5PortId = 'es5_${outputPort.channelNumber}';

        connections.add(
          Connection(
            id: 'conn_${outputPort.id}_to_$es5PortId',
            sourcePortId: outputPort.id,
            destinationPortId: es5PortId,
            connectionType: ConnectionType.algorithmToAlgorithm,
            algorithmId: routing.algorithmUuid!,
            signalType: SignalType.gate,
            description: 'ES-5 direct connection',
          ),
        );

        debugPrint(
          '[ConnectionDiscovery]   ES-5 Direct: ${outputPort.id} -> $es5PortId',
        );
      }
    }

    if (connections.isNotEmpty) {
      debugPrint(
        '[ConnectionDiscovery] Created ${connections.length} ES-5 direct connections',
      );
    }

    return connections;
  }

  // Removed legacy _createAlgorithmConnections; discovery is now session-aware

  /// Extracts algorithm ID from routing instance
  static String _extractAlgorithmId(AlgorithmRouting routing) {
    // Use the stable algorithmUuid from the routing instance
    if (routing.algorithmUuid != null) {
      return routing.algorithmUuid!;
    }

    // Fallback: Try to extract from port IDs (for backward compatibility)
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

    // Last resort fallback (should rarely be used now)
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
  static void _logBusRegistrySummary(
    Map<int, List<_PortAssignment>> busRegistry,
  ) {
    debugPrint('[ConnectionDiscovery] Bus registry summary:');
    for (final entry in busRegistry.entries) {
      final busNumber = entry.key;
      final assignments = entry.value;
      final outputs = assignments.where((a) => a.isOutput).length;
      final inputs = assignments.where((a) => !a.isOutput).length;
      debugPrint(
        '[ConnectionDiscovery]   Bus $busNumber: $outputs outputs, $inputs inputs',
      );
    }
  }

  /// Logs connection summary for debugging
  static void _logConnectionSummary(List<Connection> connections) {
    final hwConnections = connections
        .where(
          (c) =>
              c.connectionType == ConnectionType.hardwareInput ||
              c.connectionType == ConnectionType.hardwareOutput,
        )
        .length;
    final algoConnections = connections
        .where((c) => c.connectionType == ConnectionType.algorithmToAlgorithm)
        .length;
    final partialConnections = connections.where((c) => c.isPartial).length;

    debugPrint('[ConnectionDiscovery]   Hardware connections: $hwConnections');
    debugPrint(
      '[ConnectionDiscovery]   Algorithm-to-algorithm: $algoConnections',
    );
    debugPrint(
      '[ConnectionDiscovery]   Partial connections: $partialConnections',
    );
  }

  /// Creates partial connections for unmatched ports with non-zero bus values
  static List<Connection> _createPartialConnections(
    Map<int, List<_PortAssignment>> busRegistry,
    Set<String> matchedPorts,
  ) {
    final partialConnections = <Connection>[];

    debugPrint(
      '[ConnectionDiscovery] Creating partial connections for unmatched ports',
    );

    // Process each bus to find unmatched ports
    for (final entry in busRegistry.entries) {
      final busNumber = entry.key;
      final assignments = entry.value;

      // Find unmatched ports (those with non-zero bus values that weren't matched)
      final unmatchedPorts = assignments
          .where((assignment) => !matchedPorts.contains(assignment.portId))
          .toList();

      if (unmatchedPorts.isEmpty) continue;

      debugPrint(
        '[ConnectionDiscovery] Bus $busNumber has ${unmatchedPorts.length} unmatched ports',
      );

      // Create partial connections for each unmatched port
      for (final port in unmatchedPorts) {
        // For unmatched OUTPUT ports, include output mode in the label
        // so replace mode shows as "O# R" or "A# R". Inputs ignore mode.
        final String busLabel = port.isOutput
            ? (BusLabelFormatter.formatBusLabelWithMode(
                    busNumber,
                    port.outputMode,
                  ) ??
                  'Bus$busNumber')
            : (BusLabelFormatter.formatBusNumber(busNumber) ?? 'Bus$busNumber');

        final partialConnection = _createPartialConnection(
          port,
          busNumber,
          busLabel,
        );
        partialConnections.add(partialConnection);

        debugPrint(
          '[ConnectionDiscovery]   Created partial connection: ${port.portId} -> $busLabel',
        );
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
