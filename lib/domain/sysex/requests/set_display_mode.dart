import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'dart:typed_data';

import 'package:nt_helper/domain/sysex/sysex_message.dart';
import 'package:nt_helper/domain/sysex/sysex_utils.dart';

class SetDisplayModeMessage extends SysexMessage {
  final DisplayMode displayMode;

  SetDisplayModeMessage({required super.sysExId, required this.displayMode});

  @override
  Uint8List encode() {
    final bytes = <int>[
      ...buildHeader(sysExId),
      DistingNTRequestMessageType.setDisplayMode.value,
      displayMode.value & 0x7F,
      ...buildFooter()
    ];
    return Uint8List.fromList(bytes);
  }
}
