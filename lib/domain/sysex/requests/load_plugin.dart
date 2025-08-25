import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'dart:typed_data';

import 'package:nt_helper/domain/sysex/sysex_message.dart';
import 'package:nt_helper/domain/sysex/sysex_utils.dart';

class LoadPluginMessage extends SysexMessage {
  final String guid;

  LoadPluginMessage({required super.sysExId, required this.guid});

  @override
  Uint8List encode() {
    final bytes = <int>[
      ...buildHeader(sysExId),
      DistingNTRequestMessageType.loadPlugin.value,
      ...guid.codeUnits,
      ...buildFooter(),
    ];
    return Uint8List.fromList(bytes);
  }
}
