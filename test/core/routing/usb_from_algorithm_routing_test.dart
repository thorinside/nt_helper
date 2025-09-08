import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/core/routing/algorithm_routing.dart';
import 'package:nt_helper/core/routing/usb_from_algorithm_routing.dart';
import 'package:nt_helper/core/routing/models/port.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';

void main() {
  group('UsbFromAlgorithmRouting Tests', () {
    // Helper function to create test slots
    Slot createSlot({
      required Algorithm algorithm,
      required List<ParameterInfo> parameters,
      List<ParameterValue> values = const [],
      List<ParameterEnumStrings> enums = const [],
      int algorithmIndex = 0,
    }) {
      return Slot(
        algorithm: algorithm,
        routing: RoutingInfo(algorithmIndex: algorithmIndex, routingInfo: []),
        pages: ParameterPages(algorithmIndex: algorithmIndex, pages: []),
        parameters: parameters,
        values: values,
        enums: enums,
        mappings: const [],
        valueStrings: const [],
      );
    }

    group('Port Extraction', () {
      test('should extract 8 output ports from to parameters', () {
        // Create a slot with USB Audio algorithm parameters
        final slot = createSlot(
          algorithm: Algorithm(
            algorithmIndex: 0,
            guid: 'usbf',
            name: 'USB Audio (From Host)',
          ),
          parameters: [
            // 8 'to' parameters for output destinations
            for (int i = 1; i <= 8; i++)
              ParameterInfo(
                algorithmIndex: 0,
                parameterNumber: i - 1,
                name: 'Ch$i to',
                min: 0,
                max: 30, // Extended range including ES-5
                defaultValue: 0,
                unit: 1, // Enum type
                powerOfTen: 0,
              ),
            // 8 'mode' parameters for Add/Replace
            for (int i = 1; i <= 8; i++)
              ParameterInfo(
                algorithmIndex: 0,
                parameterNumber: i + 7,
                name: 'Ch$i mode',
                min: 0,
                max: 1,
                defaultValue: 0,
                unit: 1, // Enum type
                powerOfTen: 0,
              ),
          ],
          values: [
            // Set some bus values for testing
            ParameterValue(algorithmIndex: 0, parameterNumber: 0, value: 13), // Ch1 to Output 1
            ParameterValue(algorithmIndex: 0, parameterNumber: 1, value: 14), // Ch2 to Output 2
            ParameterValue(algorithmIndex: 0, parameterNumber: 2, value: 5),  // Ch3 to Aux 1
            ParameterValue(algorithmIndex: 0, parameterNumber: 3, value: 29), // Ch4 to ES-5 L
            ParameterValue(algorithmIndex: 0, parameterNumber: 4, value: 30), // Ch5 to ES-5 R
            // Mode values
            ParameterValue(algorithmIndex: 0, parameterNumber: 8, value: 1),  // Ch1 mode = Replace
            ParameterValue(algorithmIndex: 0, parameterNumber: 9, value: 0),  // Ch2 mode = Add
          ],
          enums: [
            // Enum values for 'to' parameters
            for (int i = 0; i < 8; i++)
              ParameterEnumStrings(
                algorithmIndex: 0,
                parameterNumber: i,
                values: [
                  'None',
                  'Input 1', 'Input 2', 'Input 3', 'Input 4',
                  'Input 5', 'Input 6', 'Input 7', 'Input 8',
                  'Input 9', 'Input 10', 'Input 11', 'Input 12',
                  'Output 1', 'Output 2', 'Output 3', 'Output 4',
                  'Output 5', 'Output 6', 'Output 7', 'Output 8',
                  'Aux 1', 'Aux 2', 'Aux 3', 'Aux 4',
                  'Aux 5', 'Aux 6', 'Aux 7', 'Aux 8',
                  'ES-5 L', 'ES-5 R',
                ],
              ),
            // Enum values for 'mode' parameters
            for (int i = 8; i < 16; i++)
              ParameterEnumStrings(
                algorithmIndex: 0,
                parameterNumber: i,
                values: ['Add', 'Replace'],
              ),
          ],
        );

        // Create routing from slot
        final routing = UsbFromAlgorithmRouting.createFromSlot(
          slot,
          algorithmUuid: 'test_usb_1',
        );

        // Verify no input ports (USB Audio has no inputs)
        expect(routing.inputPorts, isEmpty);

        // Verify 8 output ports
        expect(routing.outputPorts, hasLength(8));

        // Check specific ports
        final port1 = routing.outputPorts[0];
        expect(port1.name, equals('USB Channel 1'));
        expect(port1.type, equals(PortType.audio));
        expect(port1.direction, equals(PortDirection.output));
        expect(port1.busValue, equals(13)); // Output 1
        expect(port1.outputMode, equals(OutputMode.replace)); // Mode = Replace

        final port2 = routing.outputPorts[1];
        expect(port2.name, equals('USB Channel 2'));
        expect(port2.busValue, equals(14)); // Output 2
        expect(port2.outputMode, equals(OutputMode.add)); // Mode = Add

        final port3 = routing.outputPorts[2];
        expect(port3.name, equals('USB Channel 3'));
        expect(port3.busValue, equals(5)); // Aux 1

        final port4 = routing.outputPorts[3];
        expect(port4.name, equals('USB Channel 4'));
        expect(port4.busValue, equals(29)); // ES-5 L

        final port5 = routing.outputPorts[4];
        expect(port5.name, equals('USB Channel 5'));
        expect(port5.busValue, equals(30)); // ES-5 R
      });

      test('should handle unconnected channels (bus value 0)', () {
        final slot = createSlot(
          algorithm: Algorithm(
            algorithmIndex: 0,
            guid: 'usbf',
            name: 'USB Audio (From Host)',
          ),
          parameters: [
            // Only define first 2 channels as connected
            for (int i = 1; i <= 8; i++)
              ParameterInfo(
                algorithmIndex: 0,
                parameterNumber: i - 1,
                name: 'Ch$i to',
                min: 0,
                max: 30,
                defaultValue: 0,
                unit: 1,
                powerOfTen: 0,
              ),
            for (int i = 1; i <= 8; i++)
              ParameterInfo(
                algorithmIndex: 0,
                parameterNumber: i + 7,
                name: 'Ch$i mode',
                min: 0,
                max: 1,
                defaultValue: 0,
                unit: 1,
                powerOfTen: 0,
              ),
          ],
          values: [
            ParameterValue(algorithmIndex: 0, parameterNumber: 0, value: 13), // Ch1 connected
            ParameterValue(algorithmIndex: 0, parameterNumber: 1, value: 14), // Ch2 connected
            // Ch3-8 default to 0 (None)
          ],
        );

        final routing = UsbFromAlgorithmRouting.createFromSlot(
          slot,
          algorithmUuid: 'test_usb_2',
        );

        // Should still have 8 ports even if some are unconnected
        expect(routing.outputPorts, hasLength(8));

        // Check unconnected ports have bus value 0
        expect(routing.outputPorts[2].busValue, equals(0)); // Ch3 unconnected
        expect(routing.outputPorts[7].busValue, equals(0)); // Ch8 unconnected
      });
    });

    group('Factory Integration', () {
      test('should be created by factory for usbf GUID', () {
        final slot = createSlot(
          algorithm: Algorithm(
            algorithmIndex: 0,
            guid: 'usbf',
            name: 'USB Audio (From Host)',
          ),
          parameters: [
            for (int i = 1; i <= 8; i++)
              ParameterInfo(
                algorithmIndex: 0,
                parameterNumber: i - 1,
                name: 'Ch$i to',
                min: 0,
                max: 30,
                defaultValue: 0,
                unit: 1,
                powerOfTen: 0,
              ),
            for (int i = 1; i <= 8; i++)
              ParameterInfo(
                algorithmIndex: 0,
                parameterNumber: i + 7,
                name: 'Ch$i mode',
                min: 0,
                max: 1,
                defaultValue: 0,
                unit: 1,
                powerOfTen: 0,
              ),
          ],
        );

        // Factory should detect 'usbf' and create UsbFromAlgorithmRouting
        final routing = AlgorithmRouting.fromSlot(slot);

        expect(routing, isA<UsbFromAlgorithmRouting>());
        expect(routing.outputPorts, hasLength(8));
      });

      test('should not be created for other GUIDs', () {
        final slot = createSlot(
          algorithm: Algorithm(
            algorithmIndex: 0,
            guid: 'other',
            name: 'Some Other Algorithm',
          ),
          parameters: [
            ParameterInfo(
              algorithmIndex: 0,
              parameterNumber: 0,
              name: 'Audio input',
              min: 0,
              max: 28,
              defaultValue: 0,
              unit: 1,
              powerOfTen: 0,
            ),
          ],
        );

        final routing = AlgorithmRouting.fromSlot(slot);

        expect(routing, isNot(isA<UsbFromAlgorithmRouting>()));
      });
    });

    group('Extended Bus Values', () {
      test('should handle ES-5 L/R bus values (29-30)', () {
        final slot = createSlot(
          algorithm: Algorithm(
            algorithmIndex: 0,
            guid: 'usbf',
            name: 'USB Audio (From Host)',
          ),
          parameters: [
            for (int i = 1; i <= 8; i++)
              ParameterInfo(
                algorithmIndex: 0,
                parameterNumber: i - 1,
                name: 'Ch$i to',
                min: 0,
                max: 30,
                defaultValue: 0,
                unit: 1,
                powerOfTen: 0,
              ),
            for (int i = 1; i <= 8; i++)
              ParameterInfo(
                algorithmIndex: 0,
                parameterNumber: i + 7,
                name: 'Ch$i mode',
                min: 0,
                max: 1,
                defaultValue: 0,
                unit: 1,
                powerOfTen: 0,
              ),
          ],
          values: [
            ParameterValue(algorithmIndex: 0, parameterNumber: 0, value: 29), // ES-5 L
            ParameterValue(algorithmIndex: 0, parameterNumber: 1, value: 30), // ES-5 R
          ],
        );

        final routing = UsbFromAlgorithmRouting.createFromSlot(
          slot,
          algorithmUuid: 'test_usb_es5',
        );

        // Verify ES-5 bus values are preserved
        expect(routing.outputPorts[0].busValue, equals(29));
        expect(routing.outputPorts[1].busValue, equals(30));
      });
    });
  });
}