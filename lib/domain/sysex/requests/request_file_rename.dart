import 'package:nt_helper/domain/disting_nt_sysex.dart';import 'dart:typed_data';

import 'package:nt_helper/domain/sysex/sysex_message.dart';

import 'package:nt_helper/domain/sysex/sysex_utils.dart';

class RequestFileRenameMessage extends SysexMessage {
  final String oldPath;
  final String newPath;

  RequestFileRenameMessage({
    required super.sysExId,
    required this.oldPath,
    required this.newPath,
  });

  @override
  Uint8List encode() {
    final oldPathBytes = oldPath.codeUnits;
    final newPathBytes = newPath.codeUnits;
    final payload = [
      5, // Opcode for rename
      ...oldPathBytes,
      0, // Null terminator
      ...newPathBytes,
      0, // Null terminator
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