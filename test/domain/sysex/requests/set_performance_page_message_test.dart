import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'package:nt_helper/domain/sysex/requests/set_performance_page_message.dart';

void main() {
  group('SetPerformancePageMessage', () {
    test('encodes correctly with all fields', () {
      final message = SetPerformancePageMessage(
        sysExId: 0,
        slotIndex: 5,
        parameterNumber: 42,
        perfPageIndex: 3,
      );

      final encoded = message.encode();

      // Verify header: F0 00 21 27 6D [sysExId]
      expect(encoded[0], equals(0xF0)); // SysEx start
      expect(encoded[1], equals(0x00)); // Manufacturer ID byte 1
      expect(encoded[2], equals(0x21)); // Manufacturer ID byte 2
      expect(encoded[3], equals(0x27)); // Manufacturer ID byte 3
      expect(encoded[4], equals(0x6D)); // Disting NT prefix
      expect(encoded[5], equals(0x00)); // sysExId

      // Verify message type
      expect(encoded[6], equals(0x54)); // setPerformancePageMapping

      // Verify slot index
      expect(encoded[7], equals(0x05)); // slotIndex = 5

      // Verify parameter number (42 encoded as 3 bytes)
      // 42 = 0x002A
      // p_high = (42 >> 14) & 3 = 0
      // p_mid = (42 >> 7) & 0x7F = 0
      // p_low = 42 & 0x7F = 42
      expect(encoded[8], equals(0x00)); // p_high
      expect(encoded[9], equals(0x00)); // p_mid
      expect(encoded[10], equals(0x2A)); // p_low = 42

      // Verify mapping version
      expect(encoded[11], equals(0x05)); // version = 5

      // Verify performance page index
      expect(encoded[12], equals(0x03)); // perfPageIndex = 3

      // Verify footer
      expect(encoded[13], equals(0xF7)); // SysEx end
    });

    test('encodes with larger parameter number', () {
      final message = SetPerformancePageMessage(
        sysExId: 1,
        slotIndex: 10,
        parameterNumber: 1000,
        perfPageIndex: 15,
      );

      final encoded = message.encode();

      // Verify parameter number (1000 encoded as 3 bytes)
      // 1000 = 0x03E8
      // p_high = (1000 >> 14) & 3 = 0
      // p_mid = (1000 >> 7) & 0x7F = 7
      // p_low = 1000 & 0x7F = 104
      expect(encoded[8], equals(0x00)); // p_high
      expect(encoded[9], equals(0x07)); // p_mid
      expect(encoded[10], equals(0x68)); // p_low = 104 (0x68)
    });

    test('all data bytes are 7-bit safe', () {
      final message = SetPerformancePageMessage(
        sysExId: 127,
        slotIndex: 31,
        parameterNumber: 16383,
        perfPageIndex: 15,
      );

      final encoded = message.encode();

      // Skip header (F0) and footer (F7), check all data bytes
      for (int i = 1; i < encoded.length - 1; i++) {
        expect(
          encoded[i],
          lessThan(0x80),
          reason: 'Byte at index $i (${encoded[i]}) is not 7-bit safe',
        );
      }
    });

    test('message type constant is correct', () {
      expect(
        DistingNTRequestMessageType.setPerformancePageMapping.value,
        equals(0x54),
      );
    });

    test('encodes with zero perfPageIndex (not assigned)', () {
      final message = SetPerformancePageMessage(
        sysExId: 0,
        slotIndex: 0,
        parameterNumber: 0,
        perfPageIndex: 0,
      );

      final encoded = message.encode();

      // Verify perfPageIndex = 0 (not assigned)
      expect(encoded[12], equals(0x00));
    });

    test('encodes with max valid perfPageIndex', () {
      final message = SetPerformancePageMessage(
        sysExId: 0,
        slotIndex: 0,
        parameterNumber: 0,
        perfPageIndex: 15,
      );

      final encoded = message.encode();

      // Verify perfPageIndex = 15
      expect(encoded[12], equals(0x0F));
    });

    test('clamps perfPageIndex above valid range to 15', () {
      final message = SetPerformancePageMessage(
        sysExId: 0,
        slotIndex: 0,
        parameterNumber: 0,
        perfPageIndex: 100, // Out of range
      );

      final encoded = message.encode();

      // Verify perfPageIndex clamped to 15
      expect(encoded[12], equals(0x0F));
    });

    test('clamps negative perfPageIndex to 0', () {
      final message = SetPerformancePageMessage(
        sysExId: 0,
        slotIndex: 0,
        parameterNumber: 0,
        perfPageIndex: -5, // Negative
      );

      final encoded = message.encode();

      // Verify perfPageIndex clamped to 0
      expect(encoded[12], equals(0x00));
    });
  });
}
