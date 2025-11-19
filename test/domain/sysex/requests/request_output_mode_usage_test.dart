import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/domain/sysex/requests/request_output_mode_usage.dart';

void main() {
  group('RequestOutputModeUsageMessage', () {
    test('encodes message correctly with parameter 0', () {
      final message = RequestOutputModeUsageMessage(
        sysExId: 1,
        algorithmIndex: 0,
        parameterNumber: 0,
      );

      final encoded = message.encode();

      // Expected: [0xF0, 0x00, 0x21, 0x27, 0x6D, 0x01, 0x55, 0x00, 0x00, 0x00, 0x00, 0xF7]
      expect(encoded[0], 0xF0); // SysEx start
      expect(encoded[1], 0x00); // Manufacturer ID byte 1
      expect(encoded[2], 0x21); // Manufacturer ID byte 2
      expect(encoded[3], 0x27); // Manufacturer ID byte 3
      expect(encoded[4], 0x6D); // Disting NT prefix
      expect(encoded[5], 0x01); // SysEx ID
      expect(encoded[6], 0x55); // Message type (requestOutputModeUsage)
      expect(encoded[7], 0x00); // Algorithm index
      expect(encoded[8], 0x00); // Parameter high bits
      expect(encoded[9], 0x00); // Parameter mid bits
      expect(encoded[10], 0x00); // Parameter low bits
      expect(encoded[11], 0xF7); // SysEx end
    });

    test('encodes message correctly with parameter 42', () {
      final message = RequestOutputModeUsageMessage(
        sysExId: 1,
        algorithmIndex: 2,
        parameterNumber: 42,
      );

      final encoded = message.encode();

      // Parameter 42 = 0x002A
      // p_high = (42 >> 14) & 0x3 = 0
      // p_mid = (42 >> 7) & 0x7F = 0
      // p_low = 42 & 0x7F = 42 (0x2A)
      expect(encoded[6], 0x55); // Message type
      expect(encoded[7], 0x02); // Algorithm index
      expect(encoded[8], 0x00); // Parameter high bits
      expect(encoded[9], 0x00); // Parameter mid bits
      expect(encoded[10], 0x2A); // Parameter low bits (42)
    });

    test('encodes message correctly with parameter 1000', () {
      final message = RequestOutputModeUsageMessage(
        sysExId: 1,
        algorithmIndex: 5,
        parameterNumber: 1000,
      );

      final encoded = message.encode();

      // Parameter 1000 = 0x03E8
      // p_high = (1000 >> 14) & 0x3 = 0
      // p_mid = (1000 >> 7) & 0x7F = 7
      // p_low = 1000 & 0x7F = 104 (0x68)
      expect(encoded[7], 0x05); // Algorithm index
      expect(encoded[8], 0x00); // Parameter high bits
      expect(encoded[9], 0x07); // Parameter mid bits
      expect(encoded[10], 0x68); // Parameter low bits
    });

    test('encodes message correctly with large parameter number', () {
      final message = RequestOutputModeUsageMessage(
        sysExId: 1,
        algorithmIndex: 0,
        parameterNumber: 16383, // Max 14-bit value
      );

      final encoded = message.encode();

      // Parameter 16383 = 0x3FFF
      // p_high = (16383 >> 14) & 0x3 = 0
      // p_mid = (16383 >> 7) & 0x7F = 127 (0x7F)
      // p_low = 16383 & 0x7F = 127 (0x7F)
      expect(encoded[8], 0x00); // Parameter high bits
      expect(encoded[9], 0x7F); // Parameter mid bits (max 7-bit)
      expect(encoded[10], 0x7F); // Parameter low bits (max 7-bit)
    });
  });
}
