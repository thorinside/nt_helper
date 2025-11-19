import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/core/routing/clock_algorithm_routing.dart';
import 'package:nt_helper/core/routing/euclidean_algorithm_routing.dart';
import 'package:nt_helper/core/routing/connection_discovery_service.dart';
import 'package:nt_helper/core/routing/models/connection.dart';
import 'package:nt_helper/core/routing/models/port.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';

void main() {
  group('Clock/Euclidean ES-5 Direct Routing Tests', () {
    // Helper function to create Clock test slot
    Slot createClockSlot({
      required int channelCount,
      required List<({int channel, int es5Expander, int es5Output, int output})>
      channelConfigs,
      int algorithmIndex = 0,
    }) {
      final pages = <ParameterPage>[];
      final parameters = <ParameterInfo>[];
      final values = <ParameterValue>[];

      int paramNum = 0;

      // Create parameters for each output channel (prefixed with channel number)
      for (int channel = 1; channel <= channelCount; channel++) {
        // Each channel has 3 parameters: ES-5 Expander, ES-5 Output, Output
        final es5ExpanderParamNum = paramNum++;
        final es5OutputParamNum = paramNum++;
        final outputParamNum = paramNum++;

        // Create parameter definitions with channel prefix
        parameters.addAll([
          ParameterInfo(
            algorithmIndex: algorithmIndex,
            parameterNumber: es5ExpanderParamNum,
            name: '$channel:ES-5 Expander',
            min: 0,
            max: 6,
            defaultValue: 0,
            unit: 1,
            powerOfTen: 0,
          ),
          ParameterInfo(
            algorithmIndex: algorithmIndex,
            parameterNumber: es5OutputParamNum,
            name: '$channel:ES-5 Output',
            min: 1,
            max: 8,
            defaultValue: channel,
            unit: 1,
            powerOfTen: 0,
          ),
          ParameterInfo(
            algorithmIndex: algorithmIndex,
            parameterNumber: outputParamNum,
            name: '$channel:Output',
            min: 1,
            max: 28,
            defaultValue: 13,
            unit: 1,
            powerOfTen: 0,
          ),
        ]);

        // Find config for this channel
        final config = channelConfigs.firstWhere(
          (c) => c.channel == channel,
          orElse: () => (
            channel: channel,
            es5Expander: 0,
            es5Output: channel,
            output: 13,
          ),
        );

        // Create values
        values.addAll([
          ParameterValue(
            algorithmIndex: algorithmIndex,
            parameterNumber: es5ExpanderParamNum,
            value: config.es5Expander,
          ),
          ParameterValue(
            algorithmIndex: algorithmIndex,
            parameterNumber: es5OutputParamNum,
            value: config.es5Output,
          ),
          ParameterValue(
            algorithmIndex: algorithmIndex,
            parameterNumber: outputParamNum,
            value: config.output,
          ),
        ]);
      }

      return Slot(
        algorithm: Algorithm(
          algorithmIndex: algorithmIndex,
          guid: 'clck',
          name: 'Clock',
        ),
        routing: RoutingInfo(algorithmIndex: algorithmIndex, routingInfo: []),
        pages: ParameterPages(algorithmIndex: algorithmIndex, pages: pages),
        parameters: parameters,
        values: values,
        enums: const [],
        mappings: const [],
        valueStrings: const [],
      );
    }

    // Helper function to create Euclidean test slot
    Slot createEuclideanSlot({
      required int channelCount,
      required List<({int channel, int es5Expander, int es5Output, int output})>
      channelConfigs,
      int algorithmIndex = 0,
    }) {
      final pages = <ParameterPage>[];
      final parameters = <ParameterInfo>[];
      final values = <ParameterValue>[];

      int paramNum = 0;

      // Create parameters for each channel (prefixed with channel number)
      for (int channel = 1; channel <= channelCount; channel++) {
        // Each channel has 3 parameters: ES-5 Expander, ES-5 Output, Output
        final es5ExpanderParamNum = paramNum++;
        final es5OutputParamNum = paramNum++;
        final outputParamNum = paramNum++;

        // Create parameter definitions with channel prefix
        parameters.addAll([
          ParameterInfo(
            algorithmIndex: algorithmIndex,
            parameterNumber: es5ExpanderParamNum,
            name: '$channel:ES-5 Expander',
            min: 0,
            max: 6,
            defaultValue: 0,
            unit: 1,
            powerOfTen: 0,
          ),
          ParameterInfo(
            algorithmIndex: algorithmIndex,
            parameterNumber: es5OutputParamNum,
            name: '$channel:ES-5 Output',
            min: 1,
            max: 8,
            defaultValue: channel,
            unit: 1,
            powerOfTen: 0,
          ),
          ParameterInfo(
            algorithmIndex: algorithmIndex,
            parameterNumber: outputParamNum,
            name: '$channel:Output',
            min: 1,
            max: 28,
            defaultValue: 13,
            unit: 1,
            powerOfTen: 0,
          ),
        ]);

        // Find config for this channel
        final config = channelConfigs.firstWhere(
          (c) => c.channel == channel,
          orElse: () => (
            channel: channel,
            es5Expander: 0,
            es5Output: channel,
            output: 13,
          ),
        );

        // Create values
        values.addAll([
          ParameterValue(
            algorithmIndex: algorithmIndex,
            parameterNumber: es5ExpanderParamNum,
            value: config.es5Expander,
          ),
          ParameterValue(
            algorithmIndex: algorithmIndex,
            parameterNumber: es5OutputParamNum,
            value: config.es5Output,
          ),
          ParameterValue(
            algorithmIndex: algorithmIndex,
            parameterNumber: outputParamNum,
            value: config.output,
          ),
        ]);
      }

      return Slot(
        algorithm: Algorithm(
          algorithmIndex: algorithmIndex,
          guid: 'eucp',
          name: 'Euclidean',
        ),
        routing: RoutingInfo(algorithmIndex: algorithmIndex, routingInfo: []),
        pages: ParameterPages(algorithmIndex: algorithmIndex, pages: pages),
        parameters: parameters,
        values: values,
        enums: const [],
        mappings: const [],
        valueStrings: const [],
      );
    }

    group('Clock Algorithm', () {
      group('Normal Mode (ES-5 Expander = 0)', () {
        test('creates normal output ports using Output parameter', () {
          final slot = createClockSlot(
            channelCount: 4,
            channelConfigs: [
              (channel: 1, es5Expander: 0, es5Output: 1, output: 13),
              (channel: 2, es5Expander: 0, es5Output: 2, output: 14),
              (channel: 3, es5Expander: 0, es5Output: 3, output: 15),
              (channel: 4, es5Expander: 0, es5Output: 4, output: 16),
            ],
          );

          final routing = ClockAlgorithmRouting.createFromSlot(
            slot,
            ioParameters: {},
            algorithmUuid: 'clock_test',
          );

          // Should have 4 normal output ports
          expect(routing.outputPorts.length, equals(4));

          // Verify each port uses normal bus routing
          for (int i = 0; i < 4; i++) {
            final port = routing.outputPorts[i];
            final channel = i + 1;

            expect(port.id, equals('clock_test_channel_${channel}_output'));
            expect(port.type, equals(PortType.cv));
            expect(port.direction, equals(PortDirection.output));
            expect(port.busValue, equals(13 + i));
            expect(port.busParam, isNull);
            expect(port.channelNumber, equals(channel));
          }
        });

        test('skips channels with Output = 0', () {
          final slot = createClockSlot(
            channelCount: 3,
            channelConfigs: [
              (channel: 1, es5Expander: 0, es5Output: 1, output: 13),
              (
                channel: 2,
                es5Expander: 0,
                es5Output: 2,
                output: 0,
              ), // No output
              (channel: 3, es5Expander: 0, es5Output: 3, output: 15),
            ],
          );

          final routing = ClockAlgorithmRouting.createFromSlot(
            slot,
            ioParameters: {},
            algorithmUuid: 'clock_test',
          );

          // Should have 2 output ports (channel 2 skipped)
          expect(routing.outputPorts.length, equals(2));

          // Verify channel 2 is not present
          expect(routing.outputPorts.any((p) => p.channelNumber == 2), isFalse);
        });
      });

      group('ES-5 Mode (ES-5 Expander > 0)', () {
        test('creates ES-5 direct output ports, ignoring Output parameter', () {
          final slot = createClockSlot(
            channelCount: 4,
            channelConfigs: [
              (
                channel: 1,
                es5Expander: 1,
                es5Output: 1,
                output: 13,
              ), // Output ignored
              (
                channel: 2,
                es5Expander: 1,
                es5Output: 2,
                output: 14,
              ), // Output ignored
              (
                channel: 3,
                es5Expander: 1,
                es5Output: 3,
                output: 15,
              ), // Output ignored
              (
                channel: 4,
                es5Expander: 1,
                es5Output: 4,
                output: 16,
              ), // Output ignored
            ],
          );

          final routing = ClockAlgorithmRouting.createFromSlot(
            slot,
            ioParameters: {},
            algorithmUuid: 'clock_test',
          );

          // Should have 4 ES-5 direct output ports
          expect(routing.outputPorts.length, equals(4));

          // Verify each port uses ES-5 direct routing
          for (int i = 0; i < 4; i++) {
            final port = routing.outputPorts[i];
            final channel = i + 1;

            expect(port.id, equals('clock_test_channel_${channel}_es5_output'));
            expect(port.type, equals(PortType.cv));
            expect(port.direction, equals(PortDirection.output));
            expect(port.busParam, equals('es5_direct'));
            expect(port.channelNumber, equals(channel)); // ES-5 Output value
            expect(port.busValue, isNull); // No normal bus assignment
          }
        });

        test('Output parameter is completely ignored when ES-5 active', () {
          final slot = createClockSlot(
            channelCount: 2,
            channelConfigs: [
              (
                channel: 1,
                es5Expander: 1,
                es5Output: 5,
                output: 0,
              ), // Output=0 ignored
              (
                channel: 2,
                es5Expander: 1,
                es5Output: 7,
                output: 999,
              ), // Output=999 ignored
            ],
          );

          final routing = ClockAlgorithmRouting.createFromSlot(
            slot,
            ioParameters: {},
            algorithmUuid: 'clock_test',
          );

          // Should have 2 ES-5 direct ports despite Output parameter values
          expect(routing.outputPorts.length, equals(2));

          // Verify ES-5 routing is used
          final port1 = routing.outputPorts[0];
          expect(port1.busParam, equals('es5_direct'));
          expect(port1.channelNumber, equals(5));

          final port2 = routing.outputPorts[1];
          expect(port2.busParam, equals('es5_direct'));
          expect(port2.channelNumber, equals(7));
        });

        test('uses ES-5 Output parameter to determine ES-5 port', () {
          final slot = createClockSlot(
            channelCount: 3,
            channelConfigs: [
              (channel: 1, es5Expander: 1, es5Output: 3, output: 13),
              (channel: 2, es5Expander: 1, es5Output: 7, output: 14),
              (channel: 3, es5Expander: 1, es5Output: 1, output: 15),
            ],
          );

          final routing = ClockAlgorithmRouting.createFromSlot(
            slot,
            ioParameters: {},
            algorithmUuid: 'clock_test',
          );

          expect(routing.outputPorts.length, equals(3));

          // Verify ES-5 Output values are used for channelNumber
          expect(routing.outputPorts[0].channelNumber, equals(3));
          expect(routing.outputPorts[1].channelNumber, equals(7));
          expect(routing.outputPorts[2].channelNumber, equals(1));
        });
      });

      group('Mixed Mode', () {
        test('handles channels with different ES-5 Expander settings', () {
          final slot = createClockSlot(
            channelCount: 4,
            channelConfigs: [
              (channel: 1, es5Expander: 0, es5Output: 1, output: 13), // Normal
              (channel: 2, es5Expander: 1, es5Output: 5, output: 14), // ES-5
              (channel: 3, es5Expander: 0, es5Output: 3, output: 15), // Normal
              (channel: 4, es5Expander: 1, es5Output: 2, output: 16), // ES-5
            ],
          );

          final routing = ClockAlgorithmRouting.createFromSlot(
            slot,
            ioParameters: {},
            algorithmUuid: 'clock_test',
          );

          expect(routing.outputPorts.length, equals(4));

          // Channel 1: Normal mode
          expect(routing.outputPorts[0].busParam, isNull);
          expect(routing.outputPorts[0].busValue, equals(13));

          // Channel 2: ES-5 mode
          expect(routing.outputPorts[1].busParam, equals('es5_direct'));
          expect(routing.outputPorts[1].channelNumber, equals(5));

          // Channel 3: Normal mode
          expect(routing.outputPorts[2].busParam, isNull);
          expect(routing.outputPorts[2].busValue, equals(15));

          // Channel 4: ES-5 mode
          expect(routing.outputPorts[3].busParam, equals('es5_direct'));
          expect(routing.outputPorts[3].channelNumber, equals(2));
        });
      });

      group('Connection Discovery', () {
        test('creates ES-5 direct connections for ES-5 mode channels', () {
          final slot = createClockSlot(
            channelCount: 2,
            channelConfigs: [
              (channel: 1, es5Expander: 1, es5Output: 3, output: 13),
              (channel: 2, es5Expander: 1, es5Output: 7, output: 14),
            ],
          );

          final routing = ClockAlgorithmRouting.createFromSlot(
            slot,
            ioParameters: {},
            algorithmUuid: 'clock_test',
          );

          final connections = ConnectionDiscoveryService.discoverConnections([
            routing,
          ]);

          // Should have 2 ES-5 direct connections
          final es5DirectConnections = connections.where(
            (c) =>
                c.connectionType == ConnectionType.algorithmToAlgorithm &&
                c.description == 'ES-5 direct connection',
          );

          expect(es5DirectConnections.length, equals(2));

          // Verify channel 1 → ES-5 port 3
          final conn1 = es5DirectConnections.firstWhere(
            (c) => c.sourcePortId == 'clock_test_channel_1_es5_output',
          );
          expect(conn1.destinationPortId, equals('es5_3'));
          expect(conn1.signalType, equals(SignalType.gate));

          // Verify channel 2 → ES-5 port 7
          final conn2 = es5DirectConnections.firstWhere(
            (c) => c.sourcePortId == 'clock_test_channel_2_es5_output',
          );
          expect(conn2.destinationPortId, equals('es5_7'));
          expect(conn2.signalType, equals(SignalType.gate));
        });

        test('creates normal connections for normal mode channels', () {
          final slot = createClockSlot(
            channelCount: 2,
            channelConfigs: [
              (channel: 1, es5Expander: 0, es5Output: 1, output: 13),
              (channel: 2, es5Expander: 0, es5Output: 2, output: 14),
            ],
          );

          final routing = ClockAlgorithmRouting.createFromSlot(
            slot,
            ioParameters: {},
            algorithmUuid: 'clock_test',
          );

          final connections = ConnectionDiscoveryService.discoverConnections([
            routing,
          ]);

          // Should have hardware output connections
          final hwOutputConnections = connections.where(
            (c) => c.connectionType == ConnectionType.hardwareOutput,
          );

          expect(hwOutputConnections.length, equals(2));

          // Verify connections to hardware outputs
          expect(
            hwOutputConnections.any((c) => c.destinationPortId == 'hw_out_1'),
            isTrue,
          );
          expect(
            hwOutputConnections.any((c) => c.destinationPortId == 'hw_out_2'),
            isTrue,
          );
        });
      });
    });

    group('Euclidean Algorithm', () {
      test('follows identical pattern as Clock for ES-5 routing', () {
        final slot = createEuclideanSlot(
          channelCount: 3,
          channelConfigs: [
            (channel: 1, es5Expander: 0, es5Output: 1, output: 13), // Normal
            (channel: 2, es5Expander: 1, es5Output: 4, output: 14), // ES-5
            (channel: 3, es5Expander: 1, es5Output: 8, output: 15), // ES-5
          ],
        );

        final routing = EuclideanAlgorithmRouting.createFromSlot(
          slot,
          ioParameters: {},
          algorithmUuid: 'euclidean_test',
        );

        expect(routing.outputPorts.length, equals(3));

        // Channel 1: Normal mode
        expect(routing.outputPorts[0].busValue, equals(13));
        expect(routing.outputPorts[0].busParam, isNull);

        // Channel 2: ES-5 mode
        expect(routing.outputPorts[1].busParam, equals('es5_direct'));
        expect(routing.outputPorts[1].channelNumber, equals(4));

        // Channel 3: ES-5 mode
        expect(routing.outputPorts[2].busParam, equals('es5_direct'));
        expect(routing.outputPorts[2].channelNumber, equals(8));
      });

      test('creates ES-5 direct connections', () {
        final slot = createEuclideanSlot(
          channelCount: 2,
          channelConfigs: [
            (channel: 1, es5Expander: 1, es5Output: 2, output: 13),
            (channel: 2, es5Expander: 1, es5Output: 6, output: 14),
          ],
        );

        final routing = EuclideanAlgorithmRouting.createFromSlot(
          slot,
          ioParameters: {},
          algorithmUuid: 'euclidean_test',
        );

        final connections = ConnectionDiscoveryService.discoverConnections([
          routing,
        ]);

        final es5DirectConnections = connections.where(
          (c) =>
              c.connectionType == ConnectionType.algorithmToAlgorithm &&
              c.description == 'ES-5 direct connection',
        );

        expect(es5DirectConnections.length, equals(2));

        // Verify connections to correct ES-5 ports
        expect(
          es5DirectConnections.any((c) => c.destinationPortId == 'es5_2'),
          isTrue,
        );
        expect(
          es5DirectConnections.any((c) => c.destinationPortId == 'es5_6'),
          isTrue,
        );
      });
    });
  });
}
