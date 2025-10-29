import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/core/routing/clock_divider_algorithm_routing.dart';
import 'package:nt_helper/core/routing/models/port.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';

void main() {
  group('Clock Divider ES-5 Direct Routing Tests', () {
    // Helper function to create Clock Divider test slot
    Slot createClockDividerSlot({
      required int channelCount,
      required List<
        ({
          int channel,
          int enable,
          int es5Expander,
          int es5Output,
          int output,
        })
      > channelConfigs,
      int algorithmIndex = 0,
    }) {
      final parameters = <ParameterInfo>[];
      final values = <ParameterValue>[];

      int paramNum = 0;

      // Create per-channel parameters
      for (int channel = 1; channel <= channelCount; channel++) {
        final config = channelConfigs.firstWhere(
          (c) => c.channel == channel,
          orElse: () => (
            channel: channel,
            enable: 1,
            es5Expander: 0,
            es5Output: channel,
            output: 13,
          ),
        );

        // Enable parameter
        final enableParamNum = paramNum++;
        parameters.add(
          ParameterInfo(
            algorithmIndex: algorithmIndex,
            parameterNumber: enableParamNum,
            name: '$channel:Enable',
            min: 0,
            max: 1,
            defaultValue: 1,
            unit: 1,
            powerOfTen: 0,
          ),
        );
        values.add(
          ParameterValue(
            algorithmIndex: algorithmIndex,
            parameterNumber: enableParamNum,
            value: config.enable,
          ),
        );

        // ES-5 Expander parameter
        final es5ExpanderParamNum = paramNum++;
        parameters.add(
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
        );
        values.add(
          ParameterValue(
            algorithmIndex: algorithmIndex,
            parameterNumber: es5ExpanderParamNum,
            value: config.es5Expander,
          ),
        );

        // ES-5 Output parameter
        final es5OutputParamNum = paramNum++;
        parameters.add(
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
        );
        values.add(
          ParameterValue(
            algorithmIndex: algorithmIndex,
            parameterNumber: es5OutputParamNum,
            value: config.es5Output,
          ),
        );

        // Output parameter
        final outputParamNum = paramNum++;
        parameters.add(
          ParameterInfo(
            algorithmIndex: algorithmIndex,
            parameterNumber: outputParamNum,
            name: '$channel:Output',
            min: 13,
            max: 20,
            defaultValue: 13,
            unit: 1,
            powerOfTen: 0,
          ),
        );
        values.add(
          ParameterValue(
            algorithmIndex: algorithmIndex,
            parameterNumber: outputParamNum,
            value: config.output,
          ),
        );
      }

      // Add Clock input parameter (shared across all channels)
      parameters.add(
        ParameterInfo(
          algorithmIndex: algorithmIndex,
          parameterNumber: paramNum,
          name: 'Clock input',
          min: 1,
          max: 12,
          defaultValue: 1,
          unit: 1,
          powerOfTen: 0,
        ),
      );
      values.add(
        ParameterValue(
          algorithmIndex: algorithmIndex,
          parameterNumber: paramNum,
          value: 1,
        ),
      );

      return Slot(
        algorithm: Algorithm(
          algorithmIndex: algorithmIndex,
          guid: 'clkd',
          name: 'Clock Divider',
        ),
        routing: RoutingInfo(algorithmIndex: algorithmIndex, routingInfo: []),
        pages: ParameterPages(algorithmIndex: algorithmIndex, pages: []),
        parameters: parameters,
        values: values,
        enums: const [],
        mappings: const [],
        valueStrings: const [],
      );
    }

    group('Multichannel ES-5 Tests', () {
      test('All 8 channels with all ES-5 active', () {
        final slot = createClockDividerSlot(
          channelCount: 8,
          channelConfigs: [
            for (int i = 1; i <= 8; i++)
              (
                channel: i,
                enable: 1,
                es5Expander: 1,
                es5Output: i,
                output: 13,
              ),
          ],
        );

        final routing = ClockDividerAlgorithmRouting.createFromSlot(
          slot,
          ioParameters: {'Clock input': 1},
          algorithmUuid: 'test-uuid-clkd',
        );

        final outputPorts = routing.outputPorts;

        expect(outputPorts, hasLength(8));
        for (int i = 0; i < 8; i++) {
          expect(outputPorts[i].name, equals('Ch${i + 1} → ES-5 ${i + 1}'));
          expect(outputPorts[i].busParam, equals('es5_direct'));
          expect(outputPorts[i].channelNumber, equals(i + 1));
          expect(outputPorts[i].type, equals(PortType.gate));
        }
      });

      test('All 8 channels with all normal outputs', () {
        final slot = createClockDividerSlot(
          channelCount: 8,
          channelConfigs: [
            for (int i = 1; i <= 8; i++)
              (
                channel: i,
                enable: 1,
                es5Expander: 0,
                es5Output: i,
                output: 12 + i,
              ),
          ],
        );

        final routing = ClockDividerAlgorithmRouting.createFromSlot(
          slot,
          ioParameters: {'Clock input': 1},
          algorithmUuid: 'test-uuid-clkd',
        );

        final outputPorts = routing.outputPorts;

        expect(outputPorts, hasLength(8));
        for (int i = 0; i < 8; i++) {
          expect(outputPorts[i].name, equals('Channel ${i + 1}'));
          expect(outputPorts[i].busValue, equals(13 + i));
          expect(outputPorts[i].type, equals(PortType.gate));
        }
      });

      test('Mixed: channels 1-4 ES-5, channels 5-8 normal', () {
        final slot = createClockDividerSlot(
          channelCount: 8,
          channelConfigs: [
            for (int i = 1; i <= 4; i++)
              (
                channel: i,
                enable: 1,
                es5Expander: 1,
                es5Output: i,
                output: 13,
              ),
            for (int i = 5; i <= 8; i++)
              (
                channel: i,
                enable: 1,
                es5Expander: 0,
                es5Output: i,
                output: 12 + i,
              ),
          ],
        );

        final routing = ClockDividerAlgorithmRouting.createFromSlot(
          slot,
          ioParameters: {'Clock input': 1},
          algorithmUuid: 'test-uuid-clkd',
        );

        final outputPorts = routing.outputPorts;

        expect(outputPorts, hasLength(8));

        // Check first 4 channels (ES-5)
        for (int i = 0; i < 4; i++) {
          expect(outputPorts[i].name, equals('Ch${i + 1} → ES-5 ${i + 1}'));
          expect(outputPorts[i].busParam, equals('es5_direct'));
          expect(outputPorts[i].channelNumber, equals(i + 1));
        }

        // Check last 4 channels (normal)
        for (int i = 4; i < 8; i++) {
          expect(outputPorts[i].name, equals('Channel ${i + 1}'));
          expect(outputPorts[i].busValue, equals(12 + i + 1));
          expect(outputPorts[i].busParam, isNull);
        }
      });
    });

    group('Channel Filtering Tests', () {
      test('Channels 1-4 enabled, 5-8 disabled → 4 ports', () {
        final slot = createClockDividerSlot(
          channelCount: 8,
          channelConfigs: [
            for (int i = 1; i <= 4; i++)
              (
                channel: i,
                enable: 1,
                es5Expander: 0,
                es5Output: i,
                output: 12 + i,
              ),
            for (int i = 5; i <= 8; i++)
              (
                channel: i,
                enable: 0,
                es5Expander: 0,
                es5Output: i,
                output: 12 + i,
              ),
          ],
        );

        final routing = ClockDividerAlgorithmRouting.createFromSlot(
          slot,
          ioParameters: {'Clock input': 1},
          algorithmUuid: 'test-uuid-clkd',
        );

        final outputPorts = routing.outputPorts;

        expect(outputPorts, hasLength(4));
        for (int i = 0; i < 4; i++) {
          expect(outputPorts[i].name, equals('Channel ${i + 1}'));
        }
      });

      test('Only channel 1 enabled → 1 port', () {
        final slot = createClockDividerSlot(
          channelCount: 8,
          channelConfigs: [
            (channel: 1, enable: 1, es5Expander: 1, es5Output: 1, output: 13),
            for (int i = 2; i <= 8; i++)
              (
                channel: i,
                enable: 0,
                es5Expander: 0,
                es5Output: i,
                output: 12 + i,
              ),
          ],
        );

        final routing = ClockDividerAlgorithmRouting.createFromSlot(
          slot,
          ioParameters: {'Clock input': 1},
          algorithmUuid: 'test-uuid-clkd',
        );

        final outputPorts = routing.outputPorts;

        expect(outputPorts, hasLength(1));
        expect(outputPorts[0].name, equals('Ch1 → ES-5 1'));
        expect(outputPorts[0].busParam, equals('es5_direct'));
      });

      test('All channels disabled → 0 ports', () {
        final slot = createClockDividerSlot(
          channelCount: 8,
          channelConfigs: [
            for (int i = 1; i <= 8; i++)
              (
                channel: i,
                enable: 0,
                es5Expander: 0,
                es5Output: i,
                output: 12 + i,
              ),
          ],
        );

        final routing = ClockDividerAlgorithmRouting.createFromSlot(
          slot,
          ioParameters: {'Clock input': 1},
          algorithmUuid: 'test-uuid-clkd',
        );

        final outputPorts = routing.outputPorts;

        expect(outputPorts, hasLength(0));
      });
    });

    group('Input Port Tests', () {
      test('Creates shared Clock input port', () {
        final slot = createClockDividerSlot(
          channelCount: 8,
          channelConfigs: [
            for (int i = 1; i <= 8; i++)
              (
                channel: i,
                enable: 1,
                es5Expander: 0,
                es5Output: i,
                output: 12 + i,
              ),
          ],
        );

        final routing = ClockDividerAlgorithmRouting.createFromSlot(
          slot,
          ioParameters: {'Clock input': 1},
          algorithmUuid: 'test-uuid-clkd',
        );

        final inputPorts = routing.inputPorts;

        expect(inputPorts, hasLength(1));
        expect(inputPorts[0].name, equals('Clock input'));
        expect(inputPorts[0].busValue, equals(1));
        expect(inputPorts[0].type, equals(PortType.clock));
        expect(inputPorts[0].direction, equals(PortDirection.input));
      });
    });

    group('Factory Method Tests', () {
      test('canHandle returns true for Clock Divider (clkd)', () {
        final slot = createClockDividerSlot(
          channelCount: 1,
          channelConfigs: [
            (channel: 1, enable: 1, es5Expander: 0, es5Output: 1, output: 13),
          ],
        );

        expect(ClockDividerAlgorithmRouting.canHandle(slot), isTrue);
      });

      test('canHandle returns false for other algorithms', () {
        final slot = Slot(
          algorithm: Algorithm(
            algorithmIndex: 0,
            guid: 'clck',
            name: 'Clock',
          ),
          routing: RoutingInfo(algorithmIndex: 0, routingInfo: []),
          pages: ParameterPages(algorithmIndex: 0, pages: []),
          parameters: [],
          values: [],
          enums: const [],
          mappings: const [],
          valueStrings: const [],
        );

        expect(ClockDividerAlgorithmRouting.canHandle(slot), isFalse);
      });
    });
  });
}
