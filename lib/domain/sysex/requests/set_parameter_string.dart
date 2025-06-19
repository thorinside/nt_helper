import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'dart:typed_data';
import 'dart:convert';

import 'package:nt_helper/domain/sysex/sysex_message.dart';
import 'package:nt_helper/domain/sysex/sysex_utils.dart';

class SetParameterStringMessage extends SysexMessage
    implements HasAlgorithmIndex, HasParameterNumber {
  @override
  final int algorithmIndex;
  @override
  final int parameterNumber;
  final String value;

  SetParameterStringMessage({
    required super.sysExId,
    required this.algorithmIndex,
    required this.parameterNumber,
    required this.value,
  });

  @override
  Uint8List encode() {
    // Convert string value to ASCII bytes
    final valueBytes = utf8.encode(value);

    final bytes = <int>[
      ...buildHeader(sysExId),
      DistingNTRequestMessageType.setParameterString.value,
      algorithmIndex & 0x7F, // Algorithm index (7-bit)
      ...encode16(parameterNumber), // 16-bit parameter number
      ...valueBytes, // ASCII text
      0x00, // Null terminator
      ...buildFooter(),
    ];
    return Uint8List.fromList(bytes);
  }
}
