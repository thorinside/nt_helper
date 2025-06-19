import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'package:nt_helper/domain/sysex/responses/directory_listing_response.dart';
import 'package:nt_helper/domain/sysex/responses/sysex_response.dart';
import 'package:nt_helper/domain/sysex/sysex_parser.dart';
import 'package:nt_helper/models/sd_card_file_system.dart';

void main() {
  group('Sysex Message Decoding', () {
    test('should decode directory listing response correctly', () {
      final hexString =
          'f0 00 21 27 6d 00 7a 00 01 50 01 33 0d 00 03 2b 00 00 00 00 00 00 00 00 00 00 46 4d 53 59 58 00 50 01 33 06 00 3c 32 00 00 00 00 00 00 00 00 00 00 69 6d 70 75 6c 73 65 73 00 50 01 20 39 00 3d 47 00 00 00 00 00 00 00 00 00 00 6b 62 6d 00 50 01 33 06 00 31 0d 00 00 00 00 00 00 00 00 00 00 4c 4f 53 54 2e 44 49 52 00 50 01 32 09 00 43 75 00 00 00 00 00 00 00 00 00 00 4d 49 44 49 00 50 01 31 41 00 71 6c 00 00 00 00 00 00 00 00 00 00 4d 54 53 00 50 01 33 0d 00 03 2b 00 00 00 00 00 00 00 00 00 00 6d 75 6c 74 69 73 61 6d 70 6c 65 73 00 50 01 33 06 00 4b 21 00 00 00 00 00 00 00 00 00 00 70 72 65 73 65 74 73 00 50 01 32 0f 02 7d 08 00 00 00 00 00 00 00 00 00 00 70 72 65 73 65 74 73 20 66 6f 72 20 74 68 65 20 64 69 73 74 69 6e 67 20 45 58 00 50 01 34 7a 02 11 07 00 00 00 00 00 00 00 00 00 00 70 72 6f 67 72 61 6d 73 00 50 01 33 0d 00 03 24 00 00 00 00 00 00 00 00 00 00 72 65 63 6f 72 64 69 6e 67 73 00 50 01 33 08 01 26 44 00 00 00 00 00 00 00 00 00 00 73 61 6d 70 6c 65 73 00 50 01 32 09 00 42 28 00 00 00 00 00 00 00 00 00 00 73 63 6c 00 50 01 33 06 00 4b 3b 00 00 00 00 00 00 00 00 00 00 75 69 5f 73 63 72 69 70 74 73 00 50 01 32 09 00 42 13 00 00 00 00 00 00 00 00 00 00 77 61 76 65 74 61 62 6c 65 73 00 00 f7';
      final bytes = Uint8List.fromList(
          hexString.split(' ').map((s) => int.parse(s, radix: 16)).toList());

      final parsedMessage = decodeDistingNTSysEx(bytes);
      expect(parsedMessage, isNotNull);

      final response =
          parsedMessage!.messageType.createResponse(parsedMessage.payload);
      expect(response, isNotNull);

      final directoryListing = response!.parse() as DirectoryListing;

      expect(directoryListing.entries, isNotEmpty);
      expect(directoryListing.entries.length, 15);
      expect(directoryListing.entries.first.name, 'FMSYX/');
      expect(directoryListing.entries.first.isDirectory, isTrue);
    });
  });
}

extension on DistingNTRespMessageType {
  SysexResponse? createResponse(Uint8List payload) {
    // A simplified factory for testing purposes
    switch (this) {
      case DistingNTRespMessageType.respDirectoryListing:
        return DirectoryListingResponse(payload);
      // Add other response types here if needed for tests
      default:
        return null;
    }
  }
}
