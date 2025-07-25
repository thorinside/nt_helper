import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'dart:typed_data';

import 'package:nt_helper/domain/sysex/sysex_message.dart';
import 'package:nt_helper/domain/sysex/sysex_utils.dart';

class RequestRoutingInformationMessage extends SysexMessage
    implements HasAlgorithmIndex {
  @override
  final int algorithmIndex;

  RequestRoutingInformationMessage(
      {required super.sysExId, required this.algorithmIndex});

  @override
  Uint8List encode() {
    final bytes = <int>[
      ...buildHeader(sysExId),
      DistingNTRequestMessageType.requestRouting.value,
      (algorithmIndex & 0x7F),
      ...buildFooter(),
    ];
    return Uint8List.fromList(bytes);
  }
}
