import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/core/routing/connection_discovery_service.dart';
import 'package:nt_helper/core/routing/es5_encoder_algorithm_routing.dart';
import 'package:nt_helper/core/routing/models/connection.dart';
import 'package:nt_helper/core/routing/models/port.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';

void main() {
  group('ES-5 Encoder Mirror Tests', () {
    // Helper function to create ES-5 Encoder test slot
    Slot createEs5EncoderSlot({
      required List<int> enabledChannels,
      int algorithmIndex = 0,
    }) {
      final pages = <ParameterPage>[];
      final parameters = <ParameterInfo>[];
      final values = <ParameterValue>[];

      // Create pages and parameters for 8 channels
      for (int channel = 1; channel <= 8; channel++) {
        final pageParams = <int>[];

        // Each channel has 4 parameters: Enable, Input, Expander, Output
        final enableParamNum = (channel - 1) * 4;
        final inputParamNum = (channel - 1) * 4 + 1;
        final expanderParamNum = (channel - 1) * 4 + 2;
        final outputParamNum = (channel - 1) * 4 + 3;

        pageParams.addAll([
          enableParamNum,
          inputParamNum,
          expanderParamNum,
          outputParamNum,
        ]);

        pages.add(
          ParameterPage(name: 'Channel $channel', parameters: pageParams),
        );

        // Create parameter definitions
        parameters.addAll([
          ParameterInfo(
            algorithmIndex: algorithmIndex,
            parameterNumber: enableParamNum,
            name: 'Enable',
            min: 0,
            max: 1,
            defaultValue: 0,
            unit: 1,
            powerOfTen: 0,
          ),
          ParameterInfo(
            algorithmIndex: algorithmIndex,
            parameterNumber: inputParamNum,
            name: 'Input',
            min: 1,
            max: 28,
            defaultValue: 1,
            unit: 1,
            powerOfTen: 0,
          ),
          ParameterInfo(
            algorithmIndex: algorithmIndex,
            parameterNumber: expanderParamNum,
            name: 'Expander',
            min: 1,
            max: 6,
            defaultValue: 1,
            unit: 1,
            powerOfTen: 0,
          ),
          ParameterInfo(
            algorithmIndex: algorithmIndex,
            parameterNumber: outputParamNum,
            name: 'Output',
            min: 1,
            max: 8,
            defaultValue: channel,
            unit: 1,
            powerOfTen: 0,
          ),
        ]);

        // Create values
        final isEnabled = enabledChannels.contains(channel);
        values.addAll([
          ParameterValue(
            algorithmIndex: algorithmIndex,
            parameterNumber: enableParamNum,
            value: isEnabled ? 1 : 0,
          ),
          ParameterValue(
            algorithmIndex: algorithmIndex,
            parameterNumber: inputParamNum,
            value: channel, // Use different buses for testing
          ),
          ParameterValue(
            algorithmIndex: algorithmIndex,
            parameterNumber: expanderParamNum,
            value: 1,
          ),
          ParameterValue(
            algorithmIndex: algorithmIndex,
            parameterNumber: outputParamNum,
            value: channel,
          ),
        ]);
      }

      return Slot(
        algorithm: Algorithm(
          algorithmIndex: algorithmIndex,
          guid: 'es5e',
          name: 'ES-5 Encoder',
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

    group('Output Port Generation', () {
      test('generates output ports for all enabled channels', () {
        final slot = createEs5EncoderSlot(
          enabledChannels: [1, 2, 3, 4, 5, 6, 7, 8],
        );

        final routing = ES5EncoderAlgorithmRouting.createFromSlot(
          slot,
          algorithmUuid: 'es5e_test',
        );

        // All 8 channels should have output ports
        expect(routing.outputPorts.length, equals(8));

        // Verify port properties
        for (int i = 0; i < 8; i++) {
          final port = routing.outputPorts[i];
          final channelNumber = i + 1;

          expect(port.id, equals('es5e_test_channel_${channelNumber}_output'));
          expect(port.name, equals('To ES-5 $channelNumber'));
          expect(port.type, equals(PortType.cv));
          expect(port.direction, equals(PortDirection.output));
          expect(port.channelNumber, equals(channelNumber));
          expect(port.busParam, equals('es5_encoder_mirror'));
        }
      });

      test('generates output ports only for selective enabled channels', () {
        final slot = createEs5EncoderSlot(
          enabledChannels: [1, 3, 5], // Only odd channels enabled
        );

        final routing = ES5EncoderAlgorithmRouting.createFromSlot(
          slot,
          algorithmUuid: 'es5e_test',
        );

        // Only 3 channels should have output ports
        expect(routing.outputPorts.length, equals(3));

        // Verify only the enabled channels have outputs
        expect(routing.outputPorts.any((p) => p.channelNumber == 1), isTrue);
        expect(routing.outputPorts.any((p) => p.channelNumber == 3), isTrue);
        expect(routing.outputPorts.any((p) => p.channelNumber == 5), isTrue);

        // Disabled channels should not have outputs
        expect(routing.outputPorts.any((p) => p.channelNumber == 2), isFalse);
        expect(routing.outputPorts.any((p) => p.channelNumber == 4), isFalse);
      });

      test('generates no output ports when all channels are disabled', () {
        final slot = createEs5EncoderSlot(
          enabledChannels: [], // No channels enabled
        );

        final routing = ES5EncoderAlgorithmRouting.createFromSlot(
          slot,
          algorithmUuid: 'es5e_test',
        );

        // No output ports should be created
        expect(routing.outputPorts.length, equals(0));
      });
    });

    group('Connection Discovery', () {
      test('creates mirror connections for all enabled channels', () {
        final slot = createEs5EncoderSlot(
          enabledChannels: [1, 2, 3, 4, 5, 6, 7, 8],
        );

        final routing = ES5EncoderAlgorithmRouting.createFromSlot(
          slot,
          algorithmUuid: 'es5e_test',
        );

        final connections = ConnectionDiscoveryService.discoverConnections([
          routing,
        ]);

        // Should have 8 mirror connections (one per channel)
        final mirrorConnections = connections.where(
          (c) =>
              c.connectionType == ConnectionType.algorithmToAlgorithm &&
              c.description == 'ES-5 Encoder mirror connection',
        );

        expect(mirrorConnections.length, equals(8));

        // Verify each connection
        for (int channel = 1; channel <= 8; channel++) {
          final conn = mirrorConnections.firstWhere(
            (c) => c.destinationPortId == 'es5_$channel',
          );

          expect(
            conn.sourcePortId,
            equals('es5e_test_channel_${channel}_output'),
          );
          expect(conn.signalType, equals(SignalType.gate));
          expect(conn.algorithmId, equals('es5e_test'));
        }
      });

      test('creates mirror connections only for enabled channels', () {
        final slot = createEs5EncoderSlot(
          enabledChannels: [2, 4, 6, 8], // Even channels only
        );

        final routing = ES5EncoderAlgorithmRouting.createFromSlot(
          slot,
          algorithmUuid: 'es5e_test',
        );

        final connections = ConnectionDiscoveryService.discoverConnections([
          routing,
        ]);

        final mirrorConnections = connections.where(
          (c) =>
              c.connectionType == ConnectionType.algorithmToAlgorithm &&
              c.description == 'ES-5 Encoder mirror connection',
        );

        expect(mirrorConnections.length, equals(4));

        // Verify enabled channels have connections
        expect(
          mirrorConnections.any((c) => c.destinationPortId == 'es5_2'),
          isTrue,
        );
        expect(
          mirrorConnections.any((c) => c.destinationPortId == 'es5_4'),
          isTrue,
        );
        expect(
          mirrorConnections.any((c) => c.destinationPortId == 'es5_6'),
          isTrue,
        );
        expect(
          mirrorConnections.any((c) => c.destinationPortId == 'es5_8'),
          isTrue,
        );

        // Verify disabled channels have no connections
        expect(
          mirrorConnections.any((c) => c.destinationPortId == 'es5_1'),
          isFalse,
        );
        expect(
          mirrorConnections.any((c) => c.destinationPortId == 'es5_3'),
          isFalse,
        );
      });

      test('creates no connections when all channels are disabled', () {
        final slot = createEs5EncoderSlot(enabledChannels: []);

        final routing = ES5EncoderAlgorithmRouting.createFromSlot(
          slot,
          algorithmUuid: 'es5e_test',
        );

        final connections = ConnectionDiscoveryService.discoverConnections([
          routing,
        ]);

        final mirrorConnections = connections.where(
          (c) =>
              c.connectionType == ConnectionType.algorithmToAlgorithm &&
              c.description == 'ES-5 Encoder mirror connection',
        );

        expect(mirrorConnections.length, equals(0));
      });

      test('visual flow: Input Bus → ES-5 Encoder → ES-5 Port', () {
        final slot = createEs5EncoderSlot(enabledChannels: [1]);

        final routing = ES5EncoderAlgorithmRouting.createFromSlot(
          slot,
          algorithmUuid: 'es5e_test',
        );

        final connections = ConnectionDiscoveryService.discoverConnections([
          routing,
        ]);

        // Should have hardware input connection (bus → encoder input)
        final hwInputConn = connections.firstWhere(
          (c) =>
              c.connectionType == ConnectionType.hardwareInput &&
              c.destinationPortId == 'es5e_test_channel_1_input',
        );
        expect(hwInputConn.sourcePortId, equals('hw_in_1'));
        expect(hwInputConn.busNumber, equals(1));

        // Should have mirror connection (encoder output → ES-5 port)
        final mirrorConn = connections.firstWhere(
          (c) =>
              c.connectionType == ConnectionType.algorithmToAlgorithm &&
              c.destinationPortId == 'es5_1',
        );
        expect(mirrorConn.sourcePortId, equals('es5e_test_channel_1_output'));
        expect(mirrorConn.signalType, equals(SignalType.gate));
      });
    });
  });
}
