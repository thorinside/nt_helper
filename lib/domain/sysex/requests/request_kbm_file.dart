import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'dart:typed_data';

import 'package:nt_helper/domain/sysex/sysex_message.dart';
import 'package:nt_helper/domain/sysex/sysex_utils.dart';

class RequestKbmFileMessage extends SysexMessage {
  final String filePath;

  RequestKbmFileMessage({
    required super.sysExId,
    required this.filePath,
  });

  @override
  Uint8List encode() {
    final pathBytes = filePath.codeUnits;
    final payload = [
      ...pathBytes,
      0, // Null terminator
    ];
    final checksum = calculateChecksum(payload);

    return Uint8List.fromList([
      ...buildHeader(sysExId),
      DistingNTRequestMessageType.kbmFile.value,
      ...payload,
      checksum,
      ...buildFooter(),
    ]);
  }
}