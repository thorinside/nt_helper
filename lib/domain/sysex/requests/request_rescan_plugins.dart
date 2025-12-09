import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'dart:typed_data';

import 'package:nt_helper/domain/sysex/sysex_message.dart';
import 'package:nt_helper/domain/sysex/sysex_utils.dart';

/// Requests the Disting NT hardware to rescan its plug-ins folder.
/// This is used after C++ plugin (.o file) installation to make newly
/// installed plugins immediately available without rebooting.
///
/// Message format: [F0, 00 21 27, 6D, sysExId, 7A, 08, checksum, F7]
/// - 0x7A = SD card operation
/// - 0x08 = kOpRescan (rescan plug-ins operation)
///
/// Fire-and-forget: no response expected.
class RequestRescanPluginsMessage extends SysexMessage {
  RequestRescanPluginsMessage({required super.sysExId});

  @override
  Uint8List encode() {
    final payload = [8]; // kOpRescan
    final checksum = calculateChecksum(payload);

    return Uint8List.fromList([
      ...buildHeader(sysExId),
      DistingNTRequestMessageType.sdCardOperation.value,
      ...payload,
      checksum,
      ...buildFooter(),
    ]);
  }
}
