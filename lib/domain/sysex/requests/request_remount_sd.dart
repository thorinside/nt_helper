import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'dart:typed_data';

import 'package:nt_helper/domain/sysex/sysex_message.dart';
import 'package:nt_helper/domain/sysex/sysex_utils.dart';

/// Requests the Disting NT hardware to remount the MicroSD file system.
/// This refreshes the file system without a full reboot, useful after
/// external changes to the SD card contents.
///
/// Message format: [F0, 00 21 27, 6D, sysExId, 7A, 06, checksum, F7]
/// - 0x7A = SD card operation
/// - 0x06 = Remount operation
///
/// The response is always success.
class RequestRemountSdMessage extends SysexMessage {
  RequestRemountSdMessage({required super.sysExId});

  @override
  Uint8List encode() {
    final payload = [6]; // kOpRemount
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
