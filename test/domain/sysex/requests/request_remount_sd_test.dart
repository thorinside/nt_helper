import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/domain/sysex/requests/request_remount_sd.dart';
import 'package:nt_helper/domain/sysex/sysex_utils.dart';

void main() {
  test('encodes the full-remount selector required by the NT protocol', () {
    final encoded = RequestRemountSdMessage(sysExId: 0).encode();

    expect(encoded, [
      0xF0,
      0x00,
      0x21,
      0x27,
      0x6D,
      0x00,
      0x7A,
      0x06,
      0x00,
      calculateChecksum([0x06, 0x00]),
      0xF7,
    ]);
  });
}
