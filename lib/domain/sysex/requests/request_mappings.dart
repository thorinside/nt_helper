import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'dart:typed_data';

import 'package:nt_helper/domain/sysex/sysex_message.dart';
import 'package:nt_helper/domain/sysex/sysex_utils.dart';

class RequestMappingsMessage extends SysexMessage
    implements HasAlgorithmIndex, HasParameterNumber {
  @override
  final int algorithmIndex;
  @override
  final int parameterNumber;

  RequestMappingsMessage({
    required super.sysExId,
    required this.algorithmIndex,
    required this.parameterNumber,
  });

  @override
  Uint8List encode() {
    final bytes = <int>[
      ...buildHeader(sysExId),
      DistingNTRequestMessageType.requestMappings.value,
      algorithmIndex & 0x7F,
      ...encode16(parameterNumber),
      ...buildFooter(),
    ];
    return Uint8List.fromList(bytes);
  }
}
