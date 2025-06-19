import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'dart:typed_data';

import 'package:nt_helper/domain/sysex/sysex_message.dart';
import 'package:nt_helper/domain/sysex/sysex_utils.dart';

class RequestParameterPagesMessage extends SysexMessage
    implements HasAlgorithmIndex {
  @override
  final int algorithmIndex;

  RequestParameterPagesMessage(
      {required super.sysExId, required this.algorithmIndex});

  @override
  Uint8List encode() {
    final bytes = <int>[
      ...buildHeader(sysExId),
      DistingNTRequestMessageType.requestParameterPages.value,
      algorithmIndex & 0x7F,
      ...buildFooter(),
    ];
    return Uint8List.fromList(bytes);
  }
}
