import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'dart:typed_data';

import 'package:nt_helper/domain/sysex/sysex_message.dart';
import 'package:nt_helper/domain/sysex/sysex_utils.dart';

class RequestDirectoryCreateMessage extends SysexMessage {
  final String path;

  RequestDirectoryCreateMessage({
    required super.sysExId,
    required this.path,
  });

  @override
  Uint8List encode() {
    final pathBytes = path.codeUnits;
    final payload = [
      7, // Opcode for new folder/directory creation (kOpNewFolder)
      ...pathBytes,
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
