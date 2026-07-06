import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/domain/sysex/requests/request_file_upload_chunk.dart';
import 'package:nt_helper/domain/sysex/sysex_utils.dart';

void main() {
  group('RequestFileUploadChunkMessage', () {
    test('encodes upstream SD upload chunk format', () {
      final message = RequestFileUploadChunkMessage(
        sysExId: 2,
        path: '/samples/Piano/C3.wav',
        position: 512,
        data: Uint8List.fromList([0x00, 0x7F, 0x80, 0xFF]),
        createAlways: true,
      );

      final encoded = message.encode();
      final pathBytes = '/samples/Piano/C3.wav'.codeUnits;
      final payload = encoded.sublist(7, encoded.length - 2);

      expect(encoded.sublist(0, 7), [0xF0, 0x00, 0x21, 0x27, 0x6D, 2, 0x7A]);
      expect(payload.first, 4);
      expect(payload.sublist(1, 1 + pathBytes.length), pathBytes);
      var offset = 1 + pathBytes.length;
      expect(payload[offset++], 0);
      expect(payload[offset++], 1);
      expect(payload.sublist(offset, offset + 10), [
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        4,
        0,
      ]);
      offset += 10;
      expect(payload.sublist(offset, offset + 10), [
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        4,
      ]);
      offset += 10;
      expect(payload.sublist(offset), [0, 0, 7, 15, 8, 0, 15, 15]);
      expect(encoded[encoded.length - 2], calculateChecksum(payload));
      expect(encoded.last, 0xF7);
    });

    test('rejects paths that cannot be represented as SysEx data bytes', () {
      final message = RequestFileUploadChunkMessage(
        sysExId: 0,
        path: '/samples/Piano/é.wav',
        position: 0,
        data: Uint8List(0),
      );

      expect(message.encode, throwsA(isA<FormatException>()));
    });
  });
}
