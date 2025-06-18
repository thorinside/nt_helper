import 'dart:typed_data';

import 'package:nt_helper/domain/sysex/ascii.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'package:nt_helper/domain/sysex/sysex_message.dart';
import 'package:nt_helper/domain/sysex/sysex_utils.dart';

class SetPresetNameMessage extends SysexMessage {
  final String newName;

  SetPresetNameMessage({required int sysExId, required this.newName})
      : super(sysExId);

  @override
  Uint8List encode() {
    final bytes = <int>[
      ...buildHeader(sysExId),
      DistingNTRequestMessageType.setPresetName.value,
      ...encodeNullTerminatedAscii(newName),
      ...buildFooter(),
    ];
    return Uint8List.fromList(bytes);
  }
} 