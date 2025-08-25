import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'package:nt_helper/domain/sysex/responses/directory_listing_response.dart';
import 'package:nt_helper/domain/sysex/responses/number_of_algorithms_response.dart';
import 'package:nt_helper/domain/sysex/responses/lua_output_response.dart';
import 'package:nt_helper/domain/sysex/responses/sysex_response.dart';
import 'package:nt_helper/domain/sysex/sysex_parser.dart';
import 'package:nt_helper/domain/sysex/requests/execute_lua.dart';
import 'package:nt_helper/domain/sysex/requests/install_lua.dart';
import 'package:nt_helper/domain/sysex/requests/set_parameter_string.dart';
import 'package:nt_helper/models/sd_card_file_system.dart';

void main() {
  group('Sysex Message Decoding', () {
    test('should decode directory listing response correctly', () {
      final hexString =
          'f0 00 21 27 6d 00 7a 00 01 50 01 33 0d 00 03 2b 00 00 00 00 00 00 00 00 00 00 46 4d 53 59 58 00 50 01 33 06 00 3c 32 00 00 00 00 00 00 00 00 00 00 69 6d 70 75 6c 73 65 73 00 50 01 20 39 00 3d 47 00 00 00 00 00 00 00 00 00 00 6b 62 6d 00 50 01 33 06 00 31 0d 00 00 00 00 00 00 00 00 00 00 4c 4f 53 54 2e 44 49 52 00 50 01 32 09 00 43 75 00 00 00 00 00 00 00 00 00 00 4d 49 44 49 00 50 01 31 41 00 71 6c 00 00 00 00 00 00 00 00 00 00 4d 54 53 00 50 01 33 0d 00 03 2b 00 00 00 00 00 00 00 00 00 00 6d 75 6c 74 69 73 61 6d 70 6c 65 73 00 50 01 33 06 00 4b 21 00 00 00 00 00 00 00 00 00 00 70 72 65 73 65 74 73 00 50 01 32 0f 02 7d 08 00 00 00 00 00 00 00 00 00 00 70 72 65 73 65 74 73 20 66 6f 72 20 74 68 65 20 64 69 73 74 69 6e 67 20 45 58 00 50 01 34 7a 02 11 07 00 00 00 00 00 00 00 00 00 00 70 72 6f 67 72 61 6d 73 00 50 01 33 0d 00 03 24 00 00 00 00 00 00 00 00 00 00 72 65 63 6f 72 64 69 6e 67 73 00 50 01 33 08 01 26 44 00 00 00 00 00 00 00 00 00 00 73 61 6d 70 6c 65 73 00 50 01 32 09 00 42 28 00 00 00 00 00 00 00 00 00 00 73 63 6c 00 50 01 33 06 00 4b 3b 00 00 00 00 00 00 00 00 00 00 75 69 5f 73 63 72 69 70 74 73 00 50 01 32 09 00 42 13 00 00 00 00 00 00 00 00 00 00 77 61 76 65 74 61 62 6c 65 73 00 00 f7';
      final bytes = Uint8List.fromList(
        hexString.split(' ').map((s) => int.parse(s, radix: 16)).toList(),
      );

      final parsedMessage = decodeDistingNTSysEx(bytes);
      expect(parsedMessage, isNotNull);

      final response = parsedMessage!.messageType.createResponse(
        parsedMessage.payload,
      );
      expect(response, isNotNull);

      final directoryListing = response!.parse() as DirectoryListing;

      expect(directoryListing.entries, isNotEmpty);
      expect(directoryListing.entries.length, 15);
      expect(directoryListing.entries.first.name, 'FMSYX/');
      expect(directoryListing.entries.first.isDirectory, isTrue);
    });

    test('should decode number of algorithms response correctly', () {
      // f0 00 21 27 6d 00 30 00 00 7f f7
      // Header: f0 00 21 27 6d 00
      // Command: 30 (CMD_NUM_ALGOS)
      // Data: 7f
      // Checksum: (implied by previous fix to be handled externally or ignored for this data)
      // End: f7
      final hexString = 'f0 00 21 27 6d 00 30 00 00 7f f7';
      final bytes = Uint8List.fromList(
        hexString.split(' ').map((s) => int.parse(s, radix: 16)).toList(),
      );

      final parsedMessage = decodeDistingNTSysEx(bytes);
      expect(parsedMessage, isNotNull);
      expect(
        parsedMessage!.messageType,
        DistingNTRespMessageType.respNumAlgorithms,
      );

      final response = parsedMessage.messageType.createResponse(
        parsedMessage.payload,
      );
      expect(response, isNotNull);

      final numAlgorithms = response!.parse();
      expect(numAlgorithms, 127); // 0x7F in decimal
    });
  });

  group('New Sysex Message Encoding', () {
    test('should encode Execute Lua message correctly', () {
      final message = ExecuteLuaMessage(
        sysExId: 0,
        luaScript: 'print("Hello World")',
      );

      final encoded = message.encode();

      // Check header
      expect(encoded[0], 0xF0); // SysEx start
      expect(encoded[1], 0x00); // Manufacturer ID
      expect(encoded[2], 0x21);
      expect(encoded[3], 0x27);
      expect(encoded[4], 0x6D); // Disting NT prefix
      expect(encoded[5], 0x00); // SysEx ID
      expect(encoded[6], 0x08); // Execute Lua command

      // Check footer
      expect(encoded.last, 0xF7); // SysEx end

      // Check that script is included
      final scriptStart = 7;
      final scriptEnd = encoded.length - 1;
      final scriptBytes = encoded.sublist(scriptStart, scriptEnd);
      final decodedScript = String.fromCharCodes(scriptBytes);
      expect(decodedScript, 'print("Hello World")');
    });

    test('should encode Install Lua message correctly', () {
      final message = InstallLuaMessage(
        sysExId: 0,
        algorithmIndex: 5,
        luaScript: 'output("test")',
      );

      final encoded = message.encode();

      // Check header
      expect(encoded[0], 0xF0); // SysEx start
      expect(encoded[1], 0x00); // Manufacturer ID
      expect(encoded[2], 0x21);
      expect(encoded[3], 0x27);
      expect(encoded[4], 0x6D); // Disting NT prefix
      expect(encoded[5], 0x00); // SysEx ID
      expect(encoded[6], 0x09); // Install Lua command
      expect(encoded[7], 0x05); // Algorithm index (7-bit)

      // Check footer
      expect(encoded.last, 0xF7); // SysEx end

      // Check that script is included
      final scriptStart = 8;
      final scriptEnd = encoded.length - 1;
      final scriptBytes = encoded.sublist(scriptStart, scriptEnd);
      final decodedScript = String.fromCharCodes(scriptBytes);
      expect(decodedScript, 'output("test")');
    });

    test('should encode Set Parameter String message correctly', () {
      final message = SetParameterStringMessage(
        sysExId: 0,
        algorithmIndex: 3,
        parameterNumber: 1,
        value: 'test_string',
      );

      final encoded = message.encode();

      // Check header
      expect(encoded[0], 0xF0); // SysEx start
      expect(encoded[1], 0x00); // Manufacturer ID
      expect(encoded[2], 0x21);
      expect(encoded[3], 0x27);
      expect(encoded[4], 0x6D); // Disting NT prefix
      expect(encoded[5], 0x00); // SysEx ID
      expect(encoded[6], 0x53); // Set Parameter String command
      expect(encoded[7], 0x03); // Algorithm index (7-bit)

      // Check 16-bit parameter number encoding (parameter 1 = 0x0001)
      expect(encoded[8], 0x00); // MSB 2 bits
      expect(encoded[9], 0x00); // Mid 7 bits
      expect(encoded[10], 0x01); // LSB 7 bits

      // Check that string value is included with null terminator
      final stringStart = 11;
      final stringEnd = encoded.length - 2; // Before null terminator and F7
      final stringBytes = encoded.sublist(stringStart, stringEnd);
      final decodedString = String.fromCharCodes(stringBytes);
      expect(decodedString, 'test_string');

      // Check null terminator
      expect(encoded[encoded.length - 2], 0x00);

      // Check footer
      expect(encoded.last, 0xF7); // SysEx end
    });
  });
}

extension on DistingNTRespMessageType {
  SysexResponse? createResponse(Uint8List payload) {
    // A simplified factory for testing purposes
    switch (this) {
      case DistingNTRespMessageType.respDirectoryListing:
        return DirectoryListingResponse(payload);
      case DistingNTRespMessageType.respNumAlgorithms:
        return NumberOfAlgorithmsResponse(payload);
      case DistingNTRespMessageType.respLuaOutput:
        return LuaOutputResponse(payload);
      default:
        return null;
    }
  }
}
