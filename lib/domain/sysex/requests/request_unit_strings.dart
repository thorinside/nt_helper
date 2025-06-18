import 'dart:typed_data';

import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'package:nt_helper/domain/sysex/sysex_message.dart';
import 'package:nt_helper/domain/sysex/sysex_utils.dart';

class RequestUnitStringsMessage extends SysexMessage {
  RequestUnitStringsMessage({required int sysExId}) : super(sysExId);

  @override
  Uint8List encode() {
    final bytes = <int>[
      ...buildHeader(sysExId),
      DistingNTRequestMessageType.requestUnitStrings.value,
      ...buildFooter(),
    ];
    return Uint8List.fromList(bytes);
  }
} 