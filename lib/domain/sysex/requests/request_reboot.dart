import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'dart:typed_data';

import 'package:nt_helper/domain/sysex/sysex_message.dart';
import 'package:nt_helper/domain/sysex/sysex_utils.dart';

/// Sends a reboot command to the Disting NT module.
/// This will cause the module to restart as if power cycled.
class RebootMessage extends SysexMessage {
  RebootMessage({required super.sysExId});

  @override
  Uint8List encode() {
    final bytes = <int>[
      ...buildHeader(sysExId),
      DistingNTRequestMessageType.reboot.value,
      ...buildFooter(),
    ];
    return Uint8List.fromList(bytes);
  }
}
