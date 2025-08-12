import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'package:nt_helper/mcp/tools/disting_tools.dart';
import 'package:nt_helper/services/disting_controller.dart';

import 'enum_parameter_test.mocks.dart';

@GenerateMocks([DistingController])
void main() {
  group('MCP Enum Parameter Support', () {
    late MockDistingController mockController;
    late DistingTools tools;

    setUp(() {
      mockController = MockDistingController();
      tools = DistingTools(mockController);
    });

    test('setParameterValue accepts enum string and converts to index', () async {
      // Mock parameter info for an enum parameter (unit = 1)
      final paramInfo = ParameterInfo(
        algorithmIndex: 0,
        parameterNumber: 0,
        name: 'Source',
        min: 0,
        max: 2,
        defaultValue: 0,
        unit: 1, // enum parameter
        powerOfTen: 0,
      );

      // Mock enum strings
      final enumStrings = ParameterEnumStrings(
        algorithmIndex: 0,
        parameterNumber: 0,
        values: ['Internal', 'External', 'MIDI'],
      );

      final algorithm = Algorithm(
        algorithmIndex: 0,
        guid: 'test-guid',
        name: 'Test Algorithm',
      );

      when(mockController.getParametersForSlot(0))
          .thenAnswer((_) async => [paramInfo]);
      when(mockController.getAlgorithmInSlot(0))
          .thenAnswer((_) async => algorithm);
      when(mockController.getParameterEnumStrings(0, 0))
          .thenAnswer((_) async => enumStrings);
      when(mockController.updateParameterValue(0, 0, 2))
          .thenAnswer((_) async {});

      final result = await tools.setParameterValue({
        'slot_index': 0,
        'parameter_number': 0,
        'value': 'MIDI', // String enum value should convert to index 2
      });

      // Verify the controller was called with the correct index (2)
      verify(mockController.updateParameterValue(0, 0, 2)).called(1);

      // Verify the response indicates success
      expect(result, contains('"success":true'));
    });

    test('setParameterValue rejects invalid enum string', () async {
      // Mock parameter info for an enum parameter (unit = 1)
      final paramInfo = ParameterInfo(
        algorithmIndex: 0,
        parameterNumber: 0,
        name: 'Source',
        min: 0,
        max: 2,
        defaultValue: 0,
        unit: 1, // enum parameter
        powerOfTen: 0,
      );

      // Mock enum strings
      final enumStrings = ParameterEnumStrings(
        algorithmIndex: 0,
        parameterNumber: 0,
        values: ['Internal', 'External', 'MIDI'],
      );

      final algorithm = Algorithm(
        algorithmIndex: 0,
        guid: 'test-guid',
        name: 'Test Algorithm',
      );

      when(mockController.getParametersForSlot(0))
          .thenAnswer((_) async => [paramInfo]);
      when(mockController.getAlgorithmInSlot(0))
          .thenAnswer((_) async => algorithm);
      when(mockController.getParameterEnumStrings(0, 0))
          .thenAnswer((_) async => enumStrings);

      final result = await tools.setParameterValue({
        'slot_index': 0,
        'parameter_number': 0,
        'value': 'InvalidValue',
      });

      // Verify no parameter update was called
      verifyNever(mockController.updateParameterValue(any, any, any));

      // Verify the response indicates error
      expect(result, contains('"success":false'));
      expect(result, contains('Invalid enum value'));
    });

    test('setParameterValue still accepts numeric values for enum parameters', () async {
      // Mock parameter info for an enum parameter (unit = 1)
      final paramInfo = ParameterInfo(
        algorithmIndex: 0,
        parameterNumber: 0,
        name: 'Source',
        min: 0,
        max: 2,
        defaultValue: 0,
        unit: 1, // enum parameter
        powerOfTen: 0,
      );

      when(mockController.getParametersForSlot(0))
          .thenAnswer((_) async => [paramInfo]);
      when(mockController.updateParameterValue(0, 0, 1))
          .thenAnswer((_) async {});

      final result = await tools.setParameterValue({
        'slot_index': 0,
        'parameter_number': 0,
        'value': 1, // Numeric value should work directly
      });

      // Verify the controller was called with the numeric value
      verify(mockController.updateParameterValue(0, 0, 1)).called(1);

      // Verify the response indicates success
      expect(result, contains('"success":true'));
    });
  });
}