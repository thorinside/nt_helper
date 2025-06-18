import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'dart:typed_data';

import 'package:nt_helper/domain/sysex/sysex_message.dart';

import 'package:nt_helper/domain/sysex/sysex_utils.dart';

class RequestFileUploadMessage extends SysexMessage {
  final String path;
  final int fileSize;
  final Uint8List data;

  RequestFileUploadMessage({
    required super.sysExId,
    required this.path,
    required this.fileSize,
    required this.data,
  });

  @override
  Uint8List encode() {
    final pathBytes = path.codeUnits;
    final count = data.length;
    final positionBytes = encode32(0);
    final countBytes = encode32(count);
    final nybbleData = bytesToNybbles(data);

    final payload = [
      4, // Opcode for upload
      ...pathBytes,
      0, // Null terminator
      0,
      ...positionBytes,
      ...countBytes,
      ...nybbleData,
    ];
    final checksum = calculateChecksum(payload);

    return Uint8List.fromList([
      ...buildHeader(sysExId),
      DistingNTRequestMessageType.sdCardOperation.value,
      ...payload,
      checksum,
      ...buildFooter(),
    ]);
  }
}
