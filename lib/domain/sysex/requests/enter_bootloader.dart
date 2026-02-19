import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'dart:typed_data';

import 'package:nt_helper/domain/sysex/sysex_message.dart';
import 'package:nt_helper/domain/sysex/sysex_utils.dart';

/// Sends an enter-bootloader command to the Disting NT module.
/// This causes the module to reboot directly into bootloader (serial downloader) mode,
/// ready for firmware flashing. Requires firmware 1.15+.
///
/// SysEx format: F0 00 21 27 6D [sysExId] 7F 7F F7
/// (Same as reboot but with an extra 0x7F payload byte.)
class EnterBootloaderMessage extends SysexMessage {
  EnterBootloaderMessage({required super.sysExId});

  @override
  Uint8List encode() {
    final bytes = <int>[
      ...buildHeader(sysExId),
      DistingNTRequestMessageType.reboot.value,
      0x7F,
      ...buildFooter(),
    ];
    return Uint8List.fromList(bytes);
  }
}
