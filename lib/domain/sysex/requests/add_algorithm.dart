import 'package:nt_helper/domain/disting_nt_sysex.dart';import 'dart:typed_data';


import 'package:nt_helper/domain/sysex/sysex_message.dart';
import 'package:nt_helper/domain/sysex/sysex_utils.dart';

class AddAlgorithmMessage extends SysexMessage {
  final String guid;
  final List<int> specifications;

  AddAlgorithmMessage(
      {required super.sysExId, required this.guid, required this.specifications});

  @override
  Uint8List encode() {
    final bytes = <int>[
      ...buildHeader(sysExId),
      DistingNTRequestMessageType.addAlgorithm.value,
      ...guid.codeUnits,
      for (int i = 0; i < specifications.length; i++)
        ...encode16(specifications[i]),
      ...buildFooter(),
    ];
    return Uint8List.fromList(bytes);
  }
} 