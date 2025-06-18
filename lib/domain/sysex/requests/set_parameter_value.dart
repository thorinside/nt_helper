import 'package:nt_helper/domain/disting_nt_sysex.dart';import 'dart:typed_data';


import 'package:nt_helper/domain/sysex/sysex_message.dart';
import 'package:nt_helper/domain/sysex/sysex_utils.dart';

class SetParameterValueMessage extends SysexMessage {
  final int algorithmIndex;
  final int parameterNumber;
  final int value;

  SetParameterValueMessage(
      {required super.sysExId,
      required this.algorithmIndex,
      required this.parameterNumber,
      required this.value})
     ;

  @override
  Uint8List encode() {
    final bytes = <int>[
      ...buildHeader(sysExId),
      DistingNTRequestMessageType.setParameterValue.value,
      algorithmIndex & 0x7F,
      ...encode16(parameterNumber),
      ...encode16(value),
      ...buildFooter(),
    ];
    return Uint8List.fromList(bytes);
  }
} 