import 'dart:typed_data';

import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'package:nt_helper/domain/sysex/sysex_message.dart';
import 'package:nt_helper/domain/sysex/sysex_utils.dart';

class SetRealTimeClockMessage extends SysexMessage {
  final int unixTimeSeconds;

  SetRealTimeClockMessage({required int sysExId, required this.unixTimeSeconds})
      : super(sysExId);

  @override
  Uint8List encode() {
    final timeBytes = encode32(unixTimeSeconds);
    final bytes = <int>[
      ...buildHeader(sysExId),
      DistingNTRequestMessageType.setRealTimeClock.value,
      ...timeBytes,
      ...buildFooter(),
    ];
    return Uint8List.fromList(bytes);
  }
} 