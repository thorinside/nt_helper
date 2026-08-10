import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/ui/midi_listener/midi_message_decoder.dart';

void main() {
  group('decodeMidiChannelMessages', () {
    test('decodes a complete NRPN sequence from one packet', () {
      final messages = decodeMidiChannelMessages([
        0xB2,
        99,
        0,
        0xB2,
        98,
        42,
        0xB2,
        6,
        32,
        0xB2,
        38,
        127,
      ]);

      expect(messages, [
        (statusByte: 0xB2, data1: 99, data2: 0),
        (statusByte: 0xB2, data1: 98, data2: 42),
        (statusByte: 0xB2, data1: 6, data2: 32),
        (statusByte: 0xB2, data1: 38, data2: 127),
      ]);
    });

    test('supports running status and interleaved realtime bytes', () {
      final messages = decodeMidiChannelMessages([
        0xB0,
        99,
        0,
        0xF8,
        98,
        42,
        6,
        64,
      ]);

      expect(messages, [
        (statusByte: 0xB0, data1: 99, data2: 0),
        (statusByte: 0xB0, data1: 98, data2: 42),
        (statusByte: 0xB0, data1: 6, data2: 64),
      ]);
    });

    test('decodes one-data-byte channel messages', () {
      expect(decodeMidiChannelMessages([0xD4, 80]), [
        (statusByte: 0xD4, data1: 80, data2: null),
      ]);
    });

    test('drops incomplete and system messages', () {
      expect(
        decodeMidiChannelMessages([0xB0, 99, 0, 0xF0, 1, 2, 0xF7, 0x90, 60]),
        [(statusByte: 0xB0, data1: 99, data2: 0)],
      );
    });
  });
}
