import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'dart:typed_data';

import 'package:nt_helper/domain/sysex/sysex_message.dart';
import 'package:nt_helper/domain/sysex/sysex_utils.dart';

class SavePresetMessage extends SysexMessage {
  final int option;

  SavePresetMessage({required super.sysExId, this.option = 0});

  @override
  Uint8List encode() {
    final bytes = <int>[
      ...buildHeader(sysExId),
      DistingNTRequestMessageType.savePreset.value,
      option & 0x7F,
      ...buildFooter(),
    ];
    return Uint8List.fromList(bytes);
  }
}
