import 'dart:typed_data';

import 'package:nt_helper/domain/sysex/ascii.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'package:nt_helper/domain/sysex/sysex_message.dart';
import 'package:nt_helper/domain/sysex/sysex_utils.dart';

class LoadPresetMessage extends SysexMessage {
  final String presetName;
  final bool append;

  LoadPresetMessage(
      {required int sysExId, required this.presetName, required this.append})
      : super(sysExId);

  @override
  Uint8List encode() {
    final bytes = <int>[
      ...buildHeader(sysExId),
      DistingNTRequestMessageType.loadPreset.value,
      append ? 1 : 0,
      ...encodeNullTerminatedAscii(presetName),
      ...buildFooter(),
    ];
    return Uint8List.fromList(bytes);
  }
} 