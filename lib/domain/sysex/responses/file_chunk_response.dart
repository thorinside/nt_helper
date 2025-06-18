import 'dart:typed_data';
import 'package:nt_helper/models/sd_card_file_system.dart';
import 'package:nt_helper/domain/sysex/responses/sysex_response.dart';
import 'package:nt_helper/domain/sysex/sysex_utils.dart'; // for decode32

class FileChunkResponse extends SysexResponse {
  FileChunkResponse(super.payload);

  @override
  FileChunk parse() {
    if (data.length < 5) {
      // Not enough data for offset. A zero-length data might signify end of file.
      return FileChunk(offset: 0, data: Uint8List(0));
    }
    // The offset is a 32-bit integer encoded in the first 5 bytes.
    final offset = decode32(data, 0);

    // The rest of the payload is the nybble-encoded file data chunk.
    final nybbleData = data.sublist(5);
    final chunkData = nybblesToBytes(nybbleData);

    return FileChunk(offset: offset, data: chunkData);
  }
}
