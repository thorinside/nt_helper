import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/cubit/routing_editor_cubit.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'package:nt_helper/core/routing/models/connection.dart';
import 'package:nt_helper/core/routing/models/connection_metadata.dart';
import 'package:nt_helper/core/routing/models/port_metadata.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('Unified Connection Discovery', () {
    // Helper to create parameter info
    ParameterInfo createParam({
      required int parameterNumber,
      required String name,
      int algorithmIndex = 0,
      int min = 0,
      int max = 28,
      int defaultValue = 0,
    }) {
      return ParameterInfo(
        algorithmIndex: algorithmIndex,
        parameterNumber: parameterNumber,
        name: name,
        min: min,
        max: max,
        defaultValue: defaultValue,
        unit: 1,
        powerOfTen: 0,
      );
    }

    // Helper to create parameter value
    ParameterValue createValue({
      required int parameterNumber,
      required int value,
      int algorithmIndex = 0,
    }) {
      return ParameterValue(
        algorithmIndex: algorithmIndex,
        parameterNumber: parameterNumber,
        value: value,
      );
    }

    // Helper to create a test slot with parameters
    Slot createSlotWithParams({
      required Algorithm algorithm,
      required List<ParameterInfo> parameters,
      required List<ParameterValue> values,
      int algorithmIndex = 0,
    }) {
      return Slot(
        algorithm: algorithm,
        routing: RoutingInfo(algorithmIndex: algorithmIndex, routingInfo: []),
        pages: ParameterPages(algorithmIndex: algorithmIndex, pages: []),
        parameters: parameters,
        values: values,
        enums: const [],
        mappings: const [],
        valueStrings: const [],
      );
    }

    test('discovers hardware input connections', () {
      // Algorithm with an input connected to hardware input 1
      final algorithm = Algorithm(
        algorithmIndex: 0,
        guid: 'test_algo',
        name: 'Test Algorithm',
      );

      final slots = [
        createSlotWithParams(
          algorithm: algorithm,
          parameters: [
            createParam(parameterNumber: 10, name: 'Audio input'),
          ],
          values: [
            createValue(parameterNumber: 10, value: 1), // Connected to hardware input 1
          ],
        ),
      ];

      final algorithms = [
        RoutingAlgorithm(
          id: 'algo_test_algo_1',
          index: 0,
          algorithm: algorithm,
          inputPorts: [
            const Port(
              id: 'algo_test_algo_1_port_10',
              name: 'Audio input',
              type: PortType.audio,
              direction: PortDirection.input,
              busNumber: 1,
              parameterName: 'Audio input',
            ),
          ],
          outputPorts: const [],
        ),
      ];

      final connections = RoutingEditorCubit.discoverUnifiedConnections(
        slots: slots,
        algorithms: algorithms,
        algorithmIds: ['algo_test_algo_1'],
      );

      expect(connections.length, 1);
      
      final connection = connections.first;
      expect(connection.sourcePortId, 'hw_in_1');
      expect(connection.destinationPortId, 'algo_test_algo_1_port_10');
      
      final metadata = connection.properties!['metadata'] as ConnectionMetadata;
      expect(metadata.connectionClass, ConnectionClass.hardware);
      expect(metadata.busNumber, 1);
      expect(metadata.signalType, SignalType.audio);
      expect(metadata.targetAlgorithmId, 'algo_test_algo_1');
      expect(metadata.targetParameterNumber, 10);
    });

    test('discovers hardware output connections', () {
      final algorithm = Algorithm(
        algorithmIndex: 0,
        guid: 'output_algo',
        name: 'Output Algorithm',
      );

      final slots = [
        createSlotWithParams(
          algorithm: algorithm,
          parameters: [
            createParam(parameterNumber: 23, name: 'Left output'),
          ],
          values: [
            createValue(parameterNumber: 23, value: 13), // Connected to hardware output 1 (bus 13)
          ],
        ),
      ];

      final algorithms = [
        RoutingAlgorithm(
          id: 'algo_output_algo_1',
          index: 0,
          algorithm: algorithm,
          outputPorts: [
            const Port(
              id: 'algo_output_algo_1_port_23',
              name: 'Left output',
              type: PortType.audio,
              direction: PortDirection.output,
              busNumber: 13,
              parameterName: 'Left output',
            ),
          ],
          inputPorts: const [],
        ),
      ];

      final connections = RoutingEditorCubit.discoverUnifiedConnections(
        slots: slots,
        algorithms: algorithms,
        algorithmIds: ['algo_output_algo_1'],
      );

      expect(connections.length, 1);
      
      final connection = connections.first;
      expect(connection.sourcePortId, 'algo_output_algo_1_port_23');
      expect(connection.destinationPortId, 'hw_out_1');
      
      final metadata = connection.properties!['metadata'] as ConnectionMetadata;
      expect(metadata.connectionClass, ConnectionClass.hardware);
      expect(metadata.busNumber, 13);
      expect(metadata.signalType, SignalType.audio);
      expect(metadata.sourceAlgorithmId, 'algo_output_algo_1');
      expect(metadata.sourceParameterNumber, 23);
    });

    test('discovers algorithm to algorithm connections', () {
      final algo1 = Algorithm(
        algorithmIndex: 0,
        guid: 'source_algo',
        name: 'Source Algorithm',
      );

      final algo2 = Algorithm(
        algorithmIndex: 1,
        guid: 'target_algo',
        name: 'Target Algorithm',
      );

      final slots = [
        createSlotWithParams(
          algorithm: algo1,
          algorithmIndex: 0,
          parameters: [
            createParam(parameterNumber: 30, name: 'Audio output'),
          ],
          values: [
            createValue(parameterNumber: 30, value: 25), // Using internal bus 25
          ],
        ),
        createSlotWithParams(
          algorithm: algo2,
          algorithmIndex: 1,
          parameters: [
            createParam(parameterNumber: 15, name: 'Audio input', algorithmIndex: 1),
          ],
          values: [
            createValue(parameterNumber: 15, value: 25, algorithmIndex: 1), // Connected to same bus 25
          ],
        ),
      ];

      final algorithms = [
        RoutingAlgorithm(
          id: 'algo_source_algo_1',
          index: 0,
          algorithm: algo1,
          outputPorts: [
            const Port(
              id: 'algo_source_algo_1_port_30',
              name: 'Audio output',
              type: PortType.audio,
              direction: PortDirection.output,
              busNumber: 25,
              parameterName: 'Audio output',
            ),
          ],
          inputPorts: const [],
        ),
        RoutingAlgorithm(
          id: 'algo_target_algo_1',
          index: 1,
          algorithm: algo2,
          inputPorts: [
            const Port(
              id: 'algo_target_algo_1_port_15',
              name: 'Audio input',
              type: PortType.audio,
              direction: PortDirection.input,
              busNumber: 25,
              parameterName: 'Audio input',
            ),
          ],
          outputPorts: const [],
        ),
      ];

      final connections = RoutingEditorCubit.discoverUnifiedConnections(
        slots: slots,
        algorithms: algorithms,
        algorithmIds: ['algo_source_algo_1', 'algo_target_algo_1'],
      );

      expect(connections.length, 1);
      
      final connection = connections.first;
      expect(connection.sourcePortId, 'algo_source_algo_1_port_30');
      expect(connection.destinationPortId, 'algo_target_algo_1_port_15');
      
      final metadata = connection.properties!['metadata'] as ConnectionMetadata;
      expect(metadata.connectionClass, ConnectionClass.algorithm);
      expect(metadata.busNumber, 25);
      expect(metadata.signalType, SignalType.audio);
      expect(metadata.sourceAlgorithmId, 'algo_source_algo_1');
      expect(metadata.targetAlgorithmId, 'algo_target_algo_1');
      expect(metadata.sourceParameterNumber, 30);
      expect(metadata.targetParameterNumber, 15);
    });

    test('handles multiple connections on same bus', () {
      // Two algorithms outputting to the same bus (mixing scenario)
      final algo1 = Algorithm(
        algorithmIndex: 0,
        guid: 'mixer1',
        name: 'Mixer 1',
      );

      final algo2 = Algorithm(
        algorithmIndex: 1,
        guid: 'mixer2',
        name: 'Mixer 2',
      );

      final slots = [
        createSlotWithParams(
          algorithm: algo1,
          algorithmIndex: 0,
          parameters: [
            createParam(parameterNumber: 20, name: 'Mix output'),
          ],
          values: [
            createValue(parameterNumber: 20, value: 15), // Both output to bus 15 (hardware output 3)
          ],
        ),
        createSlotWithParams(
          algorithm: algo2,
          algorithmIndex: 1,
          parameters: [
            createParam(parameterNumber: 21, name: 'Mix output', algorithmIndex: 1),
          ],
          values: [
            createValue(parameterNumber: 21, value: 15, algorithmIndex: 1), // Same bus
          ],
        ),
      ];

      final algorithms = [
        RoutingAlgorithm(
          id: 'algo_mixer1_1',
          index: 0,
          algorithm: algo1,
          outputPorts: [
            const Port(
              id: 'algo_mixer1_1_port_20',
              name: 'Mix output',
              type: PortType.audio,
              direction: PortDirection.output,
              busNumber: 15,
              parameterName: 'Mix output',
            ),
          ],
          inputPorts: const [],
        ),
        RoutingAlgorithm(
          id: 'algo_mixer2_1',
          index: 1,
          algorithm: algo2,
          outputPorts: [
            const Port(
              id: 'algo_mixer2_1_port_21',
              name: 'Mix output',
              type: PortType.audio,
              direction: PortDirection.output,
              busNumber: 15,
              parameterName: 'Mix output',
            ),
          ],
          inputPorts: const [],
        ),
      ];

      final connections = RoutingEditorCubit.discoverUnifiedConnections(
        slots: slots,
        algorithms: algorithms,
        algorithmIds: ['algo_mixer1_1', 'algo_mixer2_1'],
      );

      // Should create two connections to the hardware output
      expect(connections.length, 2);
      
      // Both should connect to hardware output 3
      expect(connections.every((c) => c.destinationPortId == 'hw_out_3'), true);
      
      // Check source ports
      final sourcePorts = connections.map((c) => c.sourcePortId).toSet();
      expect(sourcePorts, {'algo_mixer1_1_port_20', 'algo_mixer2_1_port_21'});
      
      // All should be hardware connections to bus 15
      for (final connection in connections) {
        final connMeta = connection.properties!['metadata'] as ConnectionMetadata;
        expect(connMeta.connectionClass, ConnectionClass.hardware);
        expect(connMeta.busNumber, 15);
      }
    });

    test('detects backward edges in algorithm connections', () {
      // Algorithm in slot 2 outputs to algorithm in slot 1 (backward edge)
      final algo1 = Algorithm(
        algorithmIndex: 0,
        guid: 'early_algo',
        name: 'Early Algorithm',
      );

      final algo2 = Algorithm(
        algorithmIndex: 1,
        guid: 'late_algo',
        name: 'Late Algorithm',
      );

      final slots = [
        createSlotWithParams(
          algorithm: algo1,
          algorithmIndex: 0,
          parameters: [
            createParam(parameterNumber: 10, name: 'Feedback input'),
          ],
          values: [
            createValue(parameterNumber: 10, value: 26), // Internal bus
          ],
        ),
        createSlotWithParams(
          algorithm: algo2,
          algorithmIndex: 1,
          parameters: [
            createParam(parameterNumber: 20, name: 'Feedback output', algorithmIndex: 1),
          ],
          values: [
            createValue(parameterNumber: 20, value: 26, algorithmIndex: 1), // Same bus - creates backward edge
          ],
        ),
      ];

      final algorithms = [
        RoutingAlgorithm(
          id: 'algo_early_algo_1',
          index: 0,
          algorithm: algo1,
          inputPorts: [
            const Port(
              id: 'algo_early_algo_1_port_10',
              name: 'Feedback input',
              type: PortType.audio,
              direction: PortDirection.input,
              busNumber: 26,
              parameterName: 'Feedback input',
            ),
          ],
          outputPorts: const [],
        ),
        RoutingAlgorithm(
          id: 'algo_late_algo_1',
          index: 1,
          algorithm: algo2,
          outputPorts: [
            const Port(
              id: 'algo_late_algo_1_port_20',
              name: 'Feedback output',
              type: PortType.audio,
              direction: PortDirection.output,
              busNumber: 26,
              parameterName: 'Feedback output',
            ),
          ],
          inputPorts: const [],
        ),
      ];

      final connections = RoutingEditorCubit.discoverUnifiedConnections(
        slots: slots,
        algorithms: algorithms,
        algorithmIds: ['algo_early_algo_1', 'algo_late_algo_1'],
      );

      expect(connections.length, 1);
      
      final connection = connections.first;
      expect(connection.sourcePortId, 'algo_late_algo_1_port_20');
      expect(connection.destinationPortId, 'algo_early_algo_1_port_10');
      
      final metadata = connection.properties!['metadata'] as ConnectionMetadata;
      expect(metadata.connectionClass, ConnectionClass.algorithm);
      expect(metadata.isBackwardEdge, true); // Should detect backward edge
    });

    test('ignores unconnected ports (bus 0)', () {
      final algorithm = Algorithm(
        algorithmIndex: 0,
        guid: 'unconnected',
        name: 'Unconnected Algorithm',
      );

      final slots = [
        createSlotWithParams(
          algorithm: algorithm,
          parameters: [
            createParam(parameterNumber: 10, name: 'Unused input'),
            createParam(parameterNumber: 20, name: 'Unused output'),
          ],
          values: [
            createValue(parameterNumber: 10, value: 0), // Bus 0 = not connected
            createValue(parameterNumber: 20, value: 0), // Bus 0 = not connected
          ],
        ),
      ];

      final algorithms = [
        RoutingAlgorithm(
          id: 'algo_unconnected_1',
          index: 0,
          algorithm: algorithm,
          inputPorts: [
            const Port(
              id: 'algo_unconnected_1_port_10',
              name: 'Unused input',
              type: PortType.audio,
              direction: PortDirection.input,
              busNumber: null, // Not connected
              parameterName: 'Unused input',
            ),
          ],
          outputPorts: [
            const Port(
              id: 'algo_unconnected_1_port_20',
              name: 'Unused output',
              type: PortType.audio,
              direction: PortDirection.output,
              busNumber: null, // Not connected
              parameterName: 'Unused output',
            ),
          ],
        ),
      ];

      final connections = RoutingEditorCubit.discoverUnifiedConnections(
        slots: slots,
        algorithms: algorithms,
        algorithmIds: ['algo_unconnected_1'],
      );

      // Should not create any connections for bus 0
      expect(connections.isEmpty, true);
    });
  });
}