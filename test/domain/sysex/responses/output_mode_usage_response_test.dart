import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/domain/sysex/responses/output_mode_usage_response.dart';

void main() {
  group('OutputModeUsageResponse', () {
    test('parses response with no affected parameters', () {
      // Payload: [slot, source_high, source_mid, source_low, count]
      // Slot 0, source parameter 42, count 0
      final payload = Uint8List.fromList([
        0x00, // Slot 0
        0x00, // Source param high bits
        0x00, // Source param mid bits
        0x2A, // Source param low bits (42)
        0x00, // Count: 0 affected parameters
      ]);

      final response = OutputModeUsageResponse(payload);
      final result = response.parse();

      expect(result.algorithmIndex, 0);
      expect(result.parameterNumber, 42);
      expect(result.affectedParameterNumbers, isEmpty);
    });

    test('parses response with single affected parameter', () {
      // Slot 0, source parameter 42, affects parameter 100
      final payload = Uint8List.fromList([
        0x00, // Slot 0
        0x00, // Source param high bits
        0x00, // Source param mid bits
        0x2A, // Source param low bits (42)
        0x01, // Count: 1 affected parameter
        0x00, // Affected param 100 high bits
        0x00, // Affected param 100 mid bits
        0x64, // Affected param 100 low bits (100 = 0x64)
      ]);

      final response = OutputModeUsageResponse(payload);
      final result = response.parse();

      expect(result.algorithmIndex, 0);
      expect(result.parameterNumber, 42);
      expect(result.affectedParameterNumbers.length, 1);
      expect(result.affectedParameterNumbers[0], 100);
    });

    test('parses response with multiple affected parameters', () {
      // Slot 2, source parameter 10, affects parameters [100, 101, 102, 103]
      final payload = Uint8List.fromList([
        0x02, // Slot 2
        0x00, // Source param high bits
        0x00, // Source param mid bits
        0x0A, // Source param low bits (10)
        0x04, // Count: 4 affected parameters
        // Parameter 100
        0x00, 0x00, 0x64,
        // Parameter 101
        0x00, 0x00, 0x65,
        // Parameter 102
        0x00, 0x00, 0x66,
        // Parameter 103
        0x00, 0x00, 0x67,
      ]);

      final response = OutputModeUsageResponse(payload);
      final result = response.parse();

      expect(result.algorithmIndex, 2);
      expect(result.parameterNumber, 10);
      expect(result.affectedParameterNumbers.length, 4);
      expect(result.affectedParameterNumbers, [100, 101, 102, 103]);
    });

    test('parses response with large parameter numbers', () {
      // Source parameter 1000, affects parameter 2000
      final payload = Uint8List.fromList([
        0x05, // Slot 5
        // Source parameter 1000 = 0x03E8
        0x00, // high: 0
        0x07, // mid: 7
        0x68, // low: 104 (0x68)
        0x01, // Count: 1
        // Affected parameter 2000 = 0x07D0
        0x00, // high: 0
        0x0F, // mid: 15
        0x50, // low: 80 (0x50)
      ]);

      final response = OutputModeUsageResponse(payload);
      final result = response.parse();

      expect(result.algorithmIndex, 5);
      expect(result.parameterNumber, 1000);
      expect(result.affectedParameterNumbers.length, 1);
      expect(result.affectedParameterNumbers[0], 2000);
    });
  });
}
