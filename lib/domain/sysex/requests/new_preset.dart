import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'dart:typed_data';

import 'package:nt_helper/domain/sysex/sysex_message.dart';
import 'package:nt_helper/domain/sysex/sysex_utils.dart';

class NewPresetMessage extends SysexMessage {
  NewPresetMessage({required super.sysExId});

  @override
  Uint8List encode() {
    final bytes = <int>[
      ...buildHeader(sysExId),
      DistingNTRequestMessageType.newPreset.value,
      ...buildFooter(),
    ];
    return Uint8List.fromList(bytes);
  }
}
