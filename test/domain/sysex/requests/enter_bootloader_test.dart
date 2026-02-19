import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/domain/sysex/requests/enter_bootloader.dart';

void main() {
  group('EnterBootloaderMessage', () {
    test('encodes message with correct byte sequence', () {
      final message = EnterBootloaderMessage(sysExId: 1);
      final encoded = message.encode();

      // Expected: F0 00 21 27 6D 01 7F 7F F7
      expect(encoded, [0xF0, 0x00, 0x21, 0x27, 0x6D, 0x01, 0x7F, 0x7F, 0xF7]);
    });

    test('differs from reboot by having extra 0x7F payload byte', () {
      final message = EnterBootloaderMessage(sysExId: 0);
      final encoded = message.encode();

      // Reboot would be: F0 00 21 27 6D 00 7F F7 (8 bytes)
      // Bootloader is:   F0 00 21 27 6D 00 7F 7F F7 (9 bytes)
      expect(encoded.length, 9);
      expect(encoded[6], 0x7F); // reboot opcode
      expect(encoded[7], 0x7F); // extra payload byte for bootloader
      expect(encoded[8], 0xF7); // SysEx end
    });

    test('sysExId is masked to 7 bits', () {
      final message = EnterBootloaderMessage(sysExId: 0xFF);
      final encoded = message.encode();

      expect(encoded[5], 0x7F);
    });
  });
}
