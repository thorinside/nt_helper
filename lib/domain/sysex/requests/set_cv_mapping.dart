import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'dart:typed_data';

import 'package:nt_helper/models/packed_mapping_data.dart';

import 'package:nt_helper/domain/sysex/sysex_message.dart';
import 'package:nt_helper/domain/sysex/sysex_utils.dart';

class SetCVMappingMessage extends SysexMessage
    implements HasAlgorithmIndex, HasParameterNumber {
  @override
  final int algorithmIndex;
  @override
  final int parameterNumber;
  final PackedMappingData data;

  SetCVMappingMessage({
    required super.sysExId,
    required this.algorithmIndex,
    required this.parameterNumber,
    required this.data,
  });

  @override
  Uint8List encode() {
    final bytes = <int>[
      ...buildHeader(sysExId),
      DistingNTRequestMessageType.setMapping.value,
      algorithmIndex & 0x7F,
      ...encode16(parameterNumber),
      data.version & 0x7F,
      ...data.encodeCVPackedData(),
      ...buildFooter(),
    ];
    return Uint8List.fromList(bytes);
  }
}
