import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'dart:typed_data';

import 'package:nt_helper/domain/sysex/sysex_message.dart';
import 'package:nt_helper/domain/sysex/sysex_utils.dart';

class MoveAlgorithmMessage extends SysexMessage {
  final int fromIndex;
  final int toIndex;

  MoveAlgorithmMessage(
      {required super.sysExId, required this.fromIndex, required this.toIndex});

  @override
  Uint8List encode() {
    final bytes = <int>[
      ...buildHeader(sysExId),
      DistingNTRequestMessageType.moveAlgorithm.value,
      fromIndex & 0x7F,
      toIndex & 0x7F,
      ...buildFooter(),
    ];
    return Uint8List.fromList(bytes);
  }
}
