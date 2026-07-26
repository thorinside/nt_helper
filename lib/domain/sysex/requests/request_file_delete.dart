import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'package:nt_helper/domain/sd_card_operation.dart';
import 'dart:typed_data';

import 'package:nt_helper/domain/sysex/sysex_message.dart';

import 'package:nt_helper/domain/sysex/sysex_utils.dart';

class RequestFileDeleteMessage extends SysexMessage {
  final String path;

  RequestFileDeleteMessage({required super.sysExId, required this.path});

  @override
  Uint8List encode() {
    final pathBytes = path.codeUnits;
    final payload = [SdCardOperation.fileDelete.code, ...pathBytes];
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
