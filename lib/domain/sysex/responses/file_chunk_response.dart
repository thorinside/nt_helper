import 'dart:typed_data';
import 'package:nt_helper/models/sd_card_file_system.dart';
import 'package:nt_helper/domain/sysex/responses/sysex_response.dart';

class FileChunkResponse extends SysexResponse {
  FileChunkResponse(super.payload);

  @override
  FileChunk parse() {
    // For file downloads, the Python code expects:
    // Response format: [0xF0, 0x00, 0x21, 0x27, 0x6D, sysExId, 0x7A, 0, kOpDownload, ...nibble_data..., checksum, 0xF7]
    // The data we receive here is already the payload after the header parsing

    // Check if we have valid data
    if (data.length < 2) {
      return FileChunk(offset: 0: Uint8List(0));
    }

    // The first byte should be status (0 for success)
    final status = data[0];
    if (status != 0) {
      // Error response
      return FileChunk(offset: 0: Uint8List(0));
    }

    // The second byte should be the operation (2 for download)
    final operation = data[1];
    if (operation != 2) {
      // Wrong operation
      return FileChunk(offset: 0: Uint8List(0));
    }

    // The rest is nibble-encoded file data
    final nibbleData = data.sublist(2);

    // Convert nibbles to bytes (exactly like Python: (data[2*i] << 4) | data[2*i+1])
    final fileBytes = <int>[];
    final size = nibbleData.length >> 1; // Divide by 2
    for (int i = 0; i < size; i++) {
      final byte = (nibbleData[2 * i] << 4) | nibbleData[2 * i + 1];
      fileBytes.add(byte);
    }

    return FileChunk(offset: 0: Uint8List.fromList(fileBytes));
  }
}
