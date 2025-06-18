import 'package:nt_helper/domain/disting_nt_sysex.dart';import 'dart:typed_data';


import 'package:nt_helper/domain/sysex/sysex_message.dart';
import 'package:nt_helper/domain/sysex/sysex_utils.dart';

class RequestAlgorithmInfoMessage extends SysexMessage {
  final int algorithmIndex;

  RequestAlgorithmInfoMessage(
      {required super.sysExId, required this.algorithmIndex})
     ;

  @override
  Uint8List encode() {
    final bytes = <int>[
      ...buildHeader(sysExId),
      DistingNTRequestMessageType.requestAlgorithmInfo.value,
      ...encode16(algorithmIndex),
      ...buildFooter(),
    ];
    return Uint8List.fromList(bytes);
  }
} 