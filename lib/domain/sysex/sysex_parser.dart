import 'dart:typed_data';

import 'package:nt_helper/domain/disting_nt_sysex.dart';

/// A generic function to parse an incoming SysEx message from the disting NT.
/// Returns null if it's not a valid or recognized message.
/// Otherwise returns a structure describing the message type & payload.
DistingNTParsedMessage? decodeDistingNTSysEx(Uint8List data) {
  // 1) Basic sanity check
  if (data.length < 6) return null;
  if (data.first != kSysExStart || data.last != kSysExEnd) return null;

  // 2) Check manufacturer ID
  if (data[1] != kExpertSleepersManufacturerId[0] ||
      data[2] != kExpertSleepersManufacturerId[1] ||
      data[3] != kExpertSleepersManufacturerId[2]) {
    return null;
  }

  // 3) Check 6D prefix
  if (data[4] != kDistingNTPrefix) return null;

  // 4) The next byte is the SysEx ID for the module
  final distingSysExId = data[5] & 0x7F;
  if (data.length < 8) {
    // Must have at least one more byte for the message type
    return null;
  }

  // 5) The next byte after that is the message type
  final messageTypeByte = data[6] & 0x7F;
  final msgType = DistingNTRespMessageType.fromByte(messageTypeByte);

  // 6) The payload is everything between that byte and the final 0xF7,
  // but usually after the messageType we parse based on the command.
  final payload = data.sublist(7, data.length - 1); // slice out the end

  return DistingNTParsedMessage(
    sysExId: distingSysExId,
    messageType: msgType,
    payload: payload,
    rawBytes: data,
  );
}

/// A simple container for the parsed result.
class DistingNTParsedMessage {
  final int sysExId; // Which module ID
  final DistingNTRespMessageType messageType;
  final Uint8List payload; // The raw data after messageType
  final Uint8List rawBytes; // Full SysEx

  DistingNTParsedMessage({
    required this.sysExId,
    required this.messageType,
    required this.payload,
    required this.rawBytes,
  });

  @override
  String toString() {
    return 'DistingNTParsedMessage(sysExId: $sysExId, '
        'type: $messageType, payloadLen: ${payload.length}, raw: ${rawBytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join(' ')})';
  }
} 