import 'dart:typed_data';

import 'package:nt_helper/models/packed_mapping_data.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'package:nt_helper/domain/sysex/sysex_message.dart';
import 'package:nt_helper/domain/sysex/sysex_utils.dart';

class SetI2CMappingMessage extends SysexMessage {
  final int algorithmIndex;
  final int parameterNumber;
  final PackedMappingData data;

  SetI2CMappingMessage(
      {required int sysExId,
      required this.algorithmIndex,
      required this.parameterNumber,
      required this.data})
      : super(sysExId);

  @override
  Uint8List encode() {
    final bytes = <int>[
      ...buildHeader(sysExId),
      DistingNTRequestMessageType.setI2CMapping.value,
      algorithmIndex & 0x7F,
      ...encode16(parameterNumber),
      data.version & 0x7F,
      ...data.encodeI2CPackedData(),
      ...buildFooter(),
    ];
    return Uint8List.fromList(bytes);
  }
} 