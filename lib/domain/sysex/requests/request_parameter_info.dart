import 'dart:typed_data';

import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'package:nt_helper/domain/sysex/sysex_message.dart';
import 'package:nt_helper/domain/sysex/sysex_utils.dart';

class RequestParameterInfoMessage extends SysexMessage {
  final int algorithmIndex;
  final int parameterNumber;

  RequestParameterInfoMessage(
      {required int sysExId,
      required this.algorithmIndex,
      required this.parameterNumber})
      : super(sysExId);

  @override
  Uint8List encode() {
    final bytes = <int>[
      ...buildHeader(sysExId),
      DistingNTRequestMessageType.requestParameterInfo.value,
      algorithmIndex & 0x7F,
      ...encode16(parameterNumber),
      ...buildFooter(),
    ];
    return Uint8List.fromList(bytes);
  }
} 