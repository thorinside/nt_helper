import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/domain/sysex/requests/set_perf_page_item.dart';
import 'package:nt_helper/models/performance_page_item.dart';

void main() {
  group('SetPerfPageItemMessage', () {
    test('encodes disabled item', () {
      final item = PerformancePageItem.empty(5);
      final message = SetPerfPageItemMessage(
        sysExId: 1,
        item: item,
      );

      final encoded = message.encode();

      expect(encoded[0], 0xF0);
      expect(encoded[6], 0x58); // Message type (setPerfPageItem)
      expect(encoded[7], 1); // version
      expect(encoded[8], 5); // item index
      expect(encoded[9], 0); // flags = disabled
      expect(encoded[10], 0xF7);
    });

    test('encodes enabled item with labels', () {
      final item = PerformancePageItem(
        itemIndex: 3,
        enabled: true,
        slotIndex: 2,
        parameterNumber: 42,
        min: 0,
        max: 127,
        upperLabel: 'Freq',
        lowerLabel: 'VCO',
      );
      final message = SetPerfPageItemMessage(
        sysExId: 1,
        item: item,
      );

      final encoded = message.encode();

      expect(encoded[6], 0x58); // Message type
      expect(encoded[7], 1); // version
      expect(encoded[8], 3); // item index
      expect(encoded[9], 1); // flags = enabled
      expect(encoded[10], 2); // slot index

      // Parameter 42 encoded as 3 bytes
      expect(encoded[11], 0x00); // param high
      expect(encoded[12], 0x00); // param mid
      expect(encoded[13], 42); // param low

      // Min 0 encoded as 3 bytes
      expect(encoded[14], 0x00);
      expect(encoded[15], 0x00);
      expect(encoded[16], 0x00);

      // Max 127 encoded as 3 bytes
      expect(encoded[17], 0x00);
      expect(encoded[18], 0x00);
      expect(encoded[19], 127);

      // "Freq" + null terminator
      expect(encoded[20], 'F'.codeUnitAt(0));
      expect(encoded[21], 'r'.codeUnitAt(0));
      expect(encoded[22], 'e'.codeUnitAt(0));
      expect(encoded[23], 'q'.codeUnitAt(0));
      expect(encoded[24], 0x00);

      // "VCO" + null terminator
      expect(encoded[25], 'V'.codeUnitAt(0));
      expect(encoded[26], 'C'.codeUnitAt(0));
      expect(encoded[27], 'O'.codeUnitAt(0));
      expect(encoded[28], 0x00);

      expect(encoded[29], 0xF7);
    });

    test('encodes enabled item with empty labels', () {
      final item = PerformancePageItem(
        itemIndex: 0,
        enabled: true,
        slotIndex: 0,
        parameterNumber: 0,
        min: -100,
        max: 100,
        upperLabel: '',
        lowerLabel: '',
      );
      final message = SetPerfPageItemMessage(
        sysExId: 1,
        item: item,
      );

      final encoded = message.encode();

      // After header(7) + version(1) + item(1) + flags(1) + slot(1) + param(3) + min(3) + max(3) = 20
      expect(encoded[20], 0x00); // empty s1 null terminator
      expect(encoded[21], 0x00); // empty s2 null terminator
      expect(encoded[22], 0xF7);
    });
  });
}
