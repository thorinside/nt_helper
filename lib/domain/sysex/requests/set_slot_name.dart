import 'dart:typed_data';

import 'package:nt_helper/domain/sysex/ascii.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'package:nt_helper/domain/sysex/sysex_message.dart';
import 'package:nt_helper/domain/sysex/sysex_utils.dart';

class SetSlotNameMessage extends SysexMessage {
  final int algorithmIndex;
  final String name;

  SetSlotNameMessage(
      {required int sysExId, required this.algorithmIndex, required this.name})
      : super(sysExId);

  @override
  Uint8List encode() {
    final bytes = <int>[
      ...buildHeader(sysExId),
      DistingNTRequestMessageType.setSlotName.value,
      algorithmIndex & 0x7F,
      ...encodeNullTerminatedAscii(name),
      ...buildFooter(),
    ];
    return Uint8List.fromList(bytes);
  }
} 