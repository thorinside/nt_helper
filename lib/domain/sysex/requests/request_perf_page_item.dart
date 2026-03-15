import 'dart:typed_data';

import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'package:nt_helper/domain/sysex/sysex_message.dart';
import 'package:nt_helper/domain/sysex/sysex_utils.dart';

/// Request a performance page item (SysEx 0x57, firmware v1.16+).
///
/// Message format:
/// F0 00 21 27 6D [sysExId] 57 [item 0-29] F7
class RequestPerfPageItemMessage extends SysexMessage {
  final int itemIndex;

  RequestPerfPageItemMessage({
    required super.sysExId,
    required this.itemIndex,
  });

  @override
  Uint8List encode() {
    final bytes = <int>[
      ...buildHeader(sysExId),
      DistingNTRequestMessageType.requestPerfPageItem.value,
      itemIndex & 0x7F,
      ...buildFooter(),
    ];
    return Uint8List.fromList(bytes);
  }
}
