import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/domain/sysex/responses/parameter_value_response.dart';
import 'package:nt_helper/domain/sysex/responses/all_parameter_values_response.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'dart:typed_data';

void main() {
  group('ParameterValueResponse disabled flag extraction', () {
    test('extracts isDisabled=false when flag=0 (byte0=0x00)', () {
      // Format: [algorithmIndex, param# byte0, param# byte1, param# byte2, value byte0, value byte1, value byte2]
      // byte0=0x00 -> flag=(0x00 >> 2) & 0x1F = 0 -> isDisabled=false
      final data = Uint8List.fromList([0x01, 0x00, 0x00, 0x05, 0x00, 0x00, 0x64]);
      final response = ParameterValueResponse(data);
      final result = response.parse();

      expect(result.isDisabled, false);
      expect(result.value, 100); // 0x00 0x00 0x64 = 100
    });

    test('extracts isDisabled=true when flag=1 (byte0=0x04)', () {
      // byte0=0x04 -> flag=(0x04 >> 2) & 0x1F = 1 -> isDisabled=true
      // After masking: byte0 & 0x03 = 0x00, so value should still be 100
      final data = Uint8List.fromList([0x01, 0x00, 0x00, 0x05, 0x04, 0x00, 0x64]);
      final response = ParameterValueResponse(data);
      final result = response.parse();

      expect(result.isDisabled, true);
      expect(result.value, 100); // Value should be correctly extracted despite flag bit
    });

    test('extracts isDisabled=false when flag=2 (byte0=0x08)', () {
      // byte0=0x08 -> flag=(0x08 >> 2) & 0x1F = 2 -> isDisabled=false
      // After masking: byte0 & 0x03 = 0x00, so value should still be 100
      final data = Uint8List.fromList([0x01, 0x00, 0x00, 0x05, 0x08, 0x00, 0x64]);
      final response = ParameterValueResponse(data);
      final result = response.parse();

      expect(result.isDisabled, false);
      expect(result.value, 100); // Value should be correctly extracted despite flag bit
    });

    test('extracts isDisabled=false when flag=3 (byte0=0x0C)', () {
      // byte0=0x0C -> flag=(0x0C >> 2) & 0x1F = 3 -> isDisabled=false
      // After masking: byte0 & 0x03 = 0x00, so value should still be 100
      final data = Uint8List.fromList([0x01, 0x00, 0x00, 0x05, 0x0C, 0x00, 0x64]);
      final response = ParameterValueResponse(data);
      final result = response.parse();

      expect(result.isDisabled, false);
      expect(result.value, 100); // Value should be correctly extracted despite flag bit
    });
  });

  group('AllParameterValuesResponse disabled flag extraction', () {
    test('extracts isDisabled state for multiple parameters', () {
      // Format: [algorithmIndex, param0 byte0, byte1, byte2, param1 byte0, byte1, byte2, ...]
      final data = Uint8List.fromList([
        0x01, // algorithm index
        0x00, 0x00, 0x64, // param 0: flag=0, value=100, isDisabled=false
        0x04, 0x00, 0x32, // param 1: flag=1, value=50, isDisabled=true (mask removes flag bit)
        0x08, 0x00, 0x0A, // param 2: flag=2, value=10, isDisabled=false (mask removes flag bit)
      ]);
      final response = AllParameterValuesResponse(data);
      final result = response.parse();

      expect(result.values.length, 3);

      // Parameter 0: not disabled, value=100
      expect(result.values[0].isDisabled, false);
      expect(result.values[0].parameterNumber, 0);
      expect(result.values[0].value, 100);

      // Parameter 1: disabled, value=50 (flag bits masked out)
      expect(result.values[1].isDisabled, true);
      expect(result.values[1].parameterNumber, 1);
      expect(result.values[1].value, 50);

      // Parameter 2: not disabled, value=10 (flag bits masked out)
      expect(result.values[2].isDisabled, false);
      expect(result.values[2].parameterNumber, 2);
      expect(result.values[2].value, 10);
    });
  });

  group('ParameterValue equality with isDisabled', () {
    test('two ParameterValues with same isDisabled are equal', () {
      final value1 = ParameterValue(
        algorithmIndex: 0,
        parameterNumber: 5,
        value: 100,
        isDisabled: false,
      );
      final value2 = ParameterValue(
        algorithmIndex: 0,
        parameterNumber: 5,
        value: 100,
        isDisabled: false,
      );

      expect(value1, equals(value2));
      expect(value1.hashCode, equals(value2.hashCode));
    });

    test('two ParameterValues with different isDisabled are not equal', () {
      final value1 = ParameterValue(
        algorithmIndex: 0,
        parameterNumber: 5,
        value: 100,
        isDisabled: false,
      );
      final value2 = ParameterValue(
        algorithmIndex: 0,
        parameterNumber: 5,
        value: 100,
        isDisabled: true,
      );

      expect(value1, isNot(equals(value2)));
      expect(value1.hashCode, isNot(equals(value2.hashCode)));
    });
  });

  group('ParameterValue offline/default behavior', () {
    test('ParameterValue defaults to isDisabled=false when not specified', () {
      final value = ParameterValue(
        algorithmIndex: 0,
        parameterNumber: 5,
        value: 100,
      );

      expect(value.isDisabled, isFalse);
    });

    test('ParameterValue.filler() defaults to isDisabled=false', () {
      final value = ParameterValue.filler();

      expect(value.isDisabled, isFalse);
    });
  });
}
