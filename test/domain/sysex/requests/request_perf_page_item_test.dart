import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/domain/sysex/requests/request_perf_page_item.dart';

void main() {
  group('RequestPerfPageItemMessage', () {
    test('encodes message for item 0', () {
      final message = RequestPerfPageItemMessage(
        sysExId: 1,
        itemIndex: 0,
      );

      final encoded = message.encode();

      expect(encoded[0], 0xF0); // SysEx start
      expect(encoded[1], 0x00); // Manufacturer ID byte 1
      expect(encoded[2], 0x21); // Manufacturer ID byte 2
      expect(encoded[3], 0x27); // Manufacturer ID byte 3
      expect(encoded[4], 0x6D); // Disting NT prefix
      expect(encoded[5], 0x01); // SysEx ID
      expect(encoded[6], 0x57); // Message type (requestPerfPageItem)
      expect(encoded[7], 0x00); // Item index 0
      expect(encoded[8], 0xF7); // SysEx end
    });

    test('encodes message for item 29', () {
      final message = RequestPerfPageItemMessage(
        sysExId: 2,
        itemIndex: 29,
      );

      final encoded = message.encode();

      expect(encoded[5], 0x02); // SysEx ID
      expect(encoded[6], 0x57); // Message type
      expect(encoded[7], 29); // Item index 29
    });

    test('masks item index to 7 bits', () {
      final message = RequestPerfPageItemMessage(
        sysExId: 1,
        itemIndex: 0xFF,
      );

      final encoded = message.encode();

      expect(encoded[7], 0x7F); // Masked to 7 bits
    });
  });
}
