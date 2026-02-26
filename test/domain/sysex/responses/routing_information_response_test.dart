import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/domain/sysex/responses/routing_information_response.dart';

void main() {
  group('RoutingInformationResponse', () {
    test('parses short format (v1.14) with all zeros', () {
      // 1 byte algorithmIndex + 6 entries × 5 bytes = 31 bytes
      final payload = Uint8List.fromList([
        0x02, // algorithmIndex = 2
        ...List.filled(30, 0), // 6 × 5 bytes of zeros
      ]);

      final response = RoutingInformationResponse(payload);
      final result = response.parse();

      expect(result.algorithmIndex, 2);
      expect(result.routingInfo.length, 6);
      for (final entry in result.routingInfo) {
        expect(entry, 0);
      }
    });

    test('parses short format (v1.14) with known data', () {
      // Short format: each 5-byte group encodes 35 bits, result >>= 1
      // To get routing value X, the encoded 35-bit value is X << 1
      // Let's encode value 0x1234 (desired routing value)
      // Encoded = 0x1234 << 1 = 0x2468
      // 0x2468 in 7-bit groups (LSB first):
      //   b0 = 0x2468 & 0x7F = 0x68
      //   b1 = (0x2468 >> 7) & 0x7F = 0x48 >> 0 = (0x2468 >> 7) = 0x48 & 0x7F = 0x48
      //   b2 = (0x2468 >> 14) & 0x7F = 0
      //   b3 = 0, b4 = 0
      final encoded = 0x1234 << 1; // 0x2468
      final b0 = encoded & 0x7F; // 0x68
      final b1 = (encoded >> 7) & 0x7F; // 0x48
      final b2 = (encoded >> 14) & 0x7F; // 0
      final b3 = (encoded >> 21) & 0x7F; // 0
      final b4 = (encoded >> 28) & 0x7F; // 0

      final payload = Uint8List.fromList([
        0x00, // algorithmIndex = 0
        b0, b1, b2, b3, b4, // entry 0 → should decode to 0x1234
        ...List.filled(25, 0), // entries 1-5 are zero
      ]);

      final response = RoutingInformationResponse(payload);
      final result = response.parse();

      expect(result.algorithmIndex, 0);
      expect(result.routingInfo[0], 0x1234);
      for (var i = 1; i < 6; i++) {
        expect(result.routingInfo[i], 0);
      }
    });

    test('parses long format (v1.15+) with all zeros', () {
      // 1 byte algorithmIndex + 6 entries × 10 bytes = 61 bytes (> 31)
      final payload = Uint8List.fromList([
        0x03, // algorithmIndex = 3
        ...List.filled(60, 0), // 6 × 10 bytes of zeros
      ]);

      final response = RoutingInformationResponse(payload);
      final result = response.parse();

      expect(result.algorithmIndex, 3);
      expect(result.routingInfo.length, 6);
      for (final entry in result.routingInfo) {
        expect(entry, 0);
      }
    });

    test('parses long format (v1.15+) with low bits only', () {
      // Long format: two 5-byte groups per entry
      // d = decode35(low) | (decode35(high) << 35)
      // Encode value 0xABCD in the low group only
      final value = 0xABCD;
      final b0 = value & 0x7F;
      final b1 = (value >> 7) & 0x7F;
      final b2 = (value >> 14) & 0x7F;
      final b3 = (value >> 21) & 0x7F;
      final b4 = (value >> 28) & 0x7F;

      final payload = Uint8List.fromList([
        0x01, // algorithmIndex = 1
        // Entry 0: low group then high group
        b0, b1, b2, b3, b4, // low 35 bits
        0, 0, 0, 0, 0, // high 35 bits (all zero)
        // Entries 1-5: all zero
        ...List.filled(50, 0),
      ]);

      final response = RoutingInformationResponse(payload);
      final result = response.parse();

      expect(result.algorithmIndex, 1);
      expect(result.routingInfo[0], 0xABCD);
    });

    test('parses long format (v1.15+) with high bits', () {
      // Long format: d = decode35(low) | (decode35(high) << 35)
      // Put value 1 in the high group → result = 1 << 35
      final payload = Uint8List.fromList([
        0x00, // algorithmIndex = 0
        // Entry 0: low group (zero), high group (1)
        0, 0, 0, 0, 0, // low 35 bits
        1, 0, 0, 0, 0, // high 35 bits: decode35 = 1
        // Entries 1-5: all zero
        ...List.filled(50, 0),
      ]);

      final response = RoutingInformationResponse(payload);
      final result = response.parse();

      expect(result.routingInfo[0], 1 << 35);
    });

    test('parses long format with combined low and high bits', () {
      // Low value = 0x7F (127), high value = 0x03
      // Result = 0x7F | (0x03 << 35)
      final payload = Uint8List.fromList([
        0x00,
        // Entry 0
        0x7F, 0, 0, 0, 0, // low: 127
        0x03, 0, 0, 0, 0, // high: 3
        // Entries 1-5
        ...List.filled(50, 0),
      ]);

      final response = RoutingInformationResponse(payload);
      final result = response.parse();

      expect(result.routingInfo[0], 0x7F | (0x03 << 35));
    });

    test('format detection threshold at exactly 31 bytes', () {
      // 31 bytes = short format (data.length > 31 is false)
      final shortPayload = Uint8List.fromList([
        0x00,
        ...List.filled(30, 0),
      ]);
      expect(shortPayload.length, 31);

      final shortResponse = RoutingInformationResponse(shortPayload);
      final shortResult = shortResponse.parse();
      expect(shortResult.routingInfo.length, 6);

      // 32 bytes = long format (data.length > 31 is true)
      // Need 61 bytes for full long format parse
      final longPayload = Uint8List.fromList([
        0x00,
        ...List.filled(60, 0),
      ]);
      expect(longPayload.length, 61);

      final longResponse = RoutingInformationResponse(longPayload);
      final longResult = longResponse.parse();
      expect(longResult.routingInfo.length, 6);
    });

    test('short format right-shifts by 1 to remove padding', () {
      // Encode a value where bit 0 is set (the padding bit)
      // decode35 returns 0x03 (binary 11), >>= 1 gives 0x01
      final payload = Uint8List.fromList([
        0x00,
        0x03, 0, 0, 0, 0, // entry 0: decode35=3, >>1 = 1
        ...List.filled(25, 0),
      ]);

      final response = RoutingInformationResponse(payload);
      final result = response.parse();

      expect(result.routingInfo[0], 1);
    });
  });
}
