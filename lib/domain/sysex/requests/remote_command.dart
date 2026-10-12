import 'dart:typed_data';

import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'package:nt_helper/domain/sysex/sysex_message.dart';
import 'package:nt_helper/domain/sysex/sysex_utils.dart';
import 'package:nt_helper/models/remote_action.dart';

/// One representable remote subcommand. Large encoder movements are split by
/// the live manager before reaching this encoder, keeping packets at 12 bytes
/// or less (well below the 1024-byte SysEx limit).
final class RemoteCommandMessage extends SysexMessage {
  RemoteCommandMessage({required super.sysExId, required this.action});

  final RemoteAction action;

  @override
  Uint8List encode() {
    if (sysExId < 0 || sysExId > 0x7F) {
      throw RangeError.range(sysExId, 0, 0x7F, 'sysExId');
    }
    action.validate();
    if (action case RemoteEncoderTurn(:final delta)) {
      if (delta < -64 || delta > 63) {
        throw RangeError.range(delta, -64, 63, 'delta');
      }
    }
    final payload = switch (action) {
      RemotePush(:final index) => [0x01, index],
      RemoteRelease(:final index) => [0x02, index],
      RemoteEncoderTurn(:final index, :final delta) => [
        0x03,
        index,
        delta & 0x7F,
      ],
      RemotePotTurn(:final index, :final value) => [
        0x04,
        index,
        value & 0x7F,
        value >> 7,
      ],
    };
    return Uint8List.fromList([
      ...buildHeader(sysExId),
      DistingNTRequestMessageType.remoteControl.value,
      ...payload,
      ...buildFooter(),
    ]);
  }
}
