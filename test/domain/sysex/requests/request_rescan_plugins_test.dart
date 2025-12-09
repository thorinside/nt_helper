import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/domain/sysex/requests/request_rescan_plugins.dart';

void main() {
  group('RequestRescanPluginsMessage', () {
    test('encodes message with correct byte sequence', () {
      final message = RequestRescanPluginsMessage(sysExId: 1);

      final encoded = message.encode();

      // Expected format: [F0, 00 21 27, 6D, sysExId, 7A, 08, checksum, F7]
      // Checksum = (-8) & 0x7F = 0x78
      expect(encoded[0], 0xF0); // SysEx start
      expect(encoded[1], 0x00); // Manufacturer ID byte 1
      expect(encoded[2], 0x21); // Manufacturer ID byte 2
      expect(encoded[3], 0x27); // Manufacturer ID byte 3
      expect(encoded[4], 0x6D); // Disting NT prefix
      expect(encoded[5], 0x01); // SysEx ID
      expect(encoded[6], 0x7A); // SD card operation command byte
      expect(encoded[7], 0x08); // kOpRescan opcode
      expect(encoded[8], 0x78); // Checksum: (-8) & 0x7F = 0x78
      expect(encoded[9], 0xF7); // SysEx end
    });

    test('encodes correctly with different sysExId', () {
      final message = RequestRescanPluginsMessage(sysExId: 42);

      final encoded = message.encode();

      expect(encoded[5], 42); // SysEx ID
      expect(encoded[6], 0x7A); // SD card operation
      expect(encoded[7], 0x08); // kOpRescan opcode
      expect(encoded[8], 0x78); // Checksum unchanged
    });

    test('checksum calculation is correct', () {
      // The checksum for opcode 8 should be (-8) & 0x7F = 0x78
      // Verify: -8 in two's complement 8-bit is 0xF8
      // 0xF8 & 0x7F = 0x78 (120)
      final message = RequestRescanPluginsMessage(sysExId: 0);
      final encoded = message.encode();

      // Manual verification: payload is [8], sum is 8, checksum is (-8) & 0x7F
      expect(encoded[8], 0x78);
    });

    test('message length is exactly 10 bytes', () {
      final message = RequestRescanPluginsMessage(sysExId: 0);
      final encoded = message.encode();

      // F0, 00, 21, 27, 6D, sysExId, 7A, 08, checksum, F7 = 10 bytes
      expect(encoded.length, 10);
    });

    test('sysExId is masked to 7 bits', () {
      // SysEx IDs must be 7-bit (0-127), so 0xFF should become 0x7F
      final message = RequestRescanPluginsMessage(sysExId: 0xFF);
      final encoded = message.encode();

      expect(encoded[5], 0x7F); // 0xFF & 0x7F = 0x7F
    });
  });
}
