import 'dart:typed_data';

import 'package:nt_helper/models/packed_mapping_data.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'package:nt_helper/domain/sysex/sysex_message.dart';
import 'package:nt_helper/domain/sysex/sysex_utils.dart';

class SetMidiMappingMessage extends SysexMessage {
  final int algorithmIndex;
  final int parameterNumber;
  final PackedMappingData data;

  SetMidiMappingMessage(
      {required int sysExId,
      required this.algorithmIndex,
      required this.parameterNumber,
      required this.data})
      : super(sysExId);

  @override
  Uint8List encode() {
    final payload = data.encodeMIDIPackedData();
    final bytes = <int>[
      ...buildHeader(sysExId),
      DistingNTRequestMessageType.setMidiMapping.value,
      algorithmIndex & 0x7F,
      ...encode16(parameterNumber),
      data.version & 0x7F,
      ...payload,
      ...buildFooter(),
    ];
    return Uint8List.fromList(bytes);
  }
} 