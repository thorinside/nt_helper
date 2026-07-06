import 'dart:typed_data';
import 'package:nt_helper/domain/sysex/sysex_message.dart';
import 'package:nt_helper/domain/sysex/sysex_utils.dart';

class RequestFileDownloadMessage extends SysexMessage {
  final String path;
  final int? position;
  final int? count;

  RequestFileDownloadMessage({
    required super.sysExId,
    required this.path,
    this.position,
    this.count,
  }) : assert((position == null) == (count == null)),
       assert(position == null || position >= 0),
       assert(count == null || (count >= 0 && count <= 512));

  @override
  Uint8List encode() {
    final pathBytes = encodeSysExAsciiPath(path);

    final message = <int>[
      0xF0, 0x00, 0x21, 0x27, 0x6D, sysExId, 0x7A,
      2, // Header + opcode (kOpDownload = 2)
      ...pathBytes,
    ];

    final position = this.position;
    final count = this.count;
    if (position != null && count != null) {
      message.add(0);
      message.addAll(_encodeCount(position));
      message.addAll(_encodeCount(count));
    }

    // Calculate checksum (sum of bytes from position 7 onwards, then negate and mask)
    int sum = 0;
    for (int i = 7; i < message.length; i++) {
      sum += message[i];
    }
    final checksum = (-sum) & 0x7f;

    message.add(checksum);
    message.add(0xF7);

    return Uint8List.fromList(message);
  }
}

List<int> _encodeCount(int value) {
  return [
    0,
    0,
    0,
    0,
    0,
    (value >> 28) & 0x0f,
    (value >> 21) & 0x7f,
    (value >> 14) & 0x7f,
    (value >> 7) & 0x7f,
    value & 0x7f,
  ];
}
