import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/domain/sysex/responses/perf_page_item_response.dart';

void main() {
  group('PerfPageItemResponse', () {
    test('parses disabled item', () {
      final payload = Uint8List.fromList([
        1, // version
        5, // item index
        0, // flags = disabled
      ]);

      final response = PerfPageItemResponse(payload);
      final result = response.parse();

      expect(result.itemIndex, 5);
      expect(result.enabled, false);
      expect(result.slotIndex, 0);
      expect(result.parameterNumber, 0);
    });

    test('parses enabled item with labels', () {
      final payload = Uint8List.fromList([
        1, // version
        3, // item index
        1, // flags = enabled
        2, // slot index
        0x00, 0x00, 42, // parameter 42
        0x00, 0x00, 0x00, // min 0
        0x00, 0x00, 127, // max 127
        ...'Freq'.codeUnits, 0x00, // upper label
        ...'VCO'.codeUnits, 0x00, // lower label
      ]);

      final response = PerfPageItemResponse(payload);
      final result = response.parse();

      expect(result.itemIndex, 3);
      expect(result.enabled, true);
      expect(result.slotIndex, 2);
      expect(result.parameterNumber, 42);
      expect(result.min, 0);
      expect(result.max, 127);
      expect(result.upperLabel, 'Freq');
      expect(result.lowerLabel, 'VCO');
    });

    test('parses enabled item with empty labels', () {
      final payload = Uint8List.fromList([
        1, // version
        0, // item index
        1, // flags = enabled
        0, // slot index
        0x00, 0x00, 0x00, // parameter 0
        0x00, 0x00, 0x00, // min 0
        0x00, 0x01, 0x00, // max 128
        0x00, // empty upper label
        0x00, // empty lower label
      ]);

      final response = PerfPageItemResponse(payload);
      final result = response.parse();

      expect(result.enabled, true);
      expect(result.max, 128);
      expect(result.upperLabel, '');
      expect(result.lowerLabel, '');
    });

    test('parses item with negative min value', () {
      // min = -100 = 0xFF9C as unsigned 16-bit
      // encode16(-100): v = -100 & 0xFFFF = 0xFF9C = 65436
      // ms2 = (65436 >> 14) & 0x03 = 3
      // mid7 = (65436 >> 7) & 0x7F = 0x7F (127)
      // ls7 = 65436 & 0x7F = 0x1C (28)
      final payload = Uint8List.fromList([
        1, // version
        0, // item index
        1, // flags = enabled
        0, // slot index
        0x00, 0x00, 0x00, // parameter 0
        3, 127, 28, // min -100 encoded
        0x00, 0x00, 100, // max 100
        0x00, // empty upper label
        0x00, // empty lower label
      ]);

      final response = PerfPageItemResponse(payload);
      final result = response.parse();

      expect(result.min, -100);
      expect(result.max, 100);
    });
  });
}
