import 'dart:typed_data';
import 'package:nt_helper/domain/sysex/sysex_message.dart';

class RequestFileDownloadMessage extends SysexMessage {
  final String path;

  RequestFileDownloadMessage({required super.sysExId, required this.path});

  @override
  Uint8List encode() {
    final pathBytes = path.codeUnits;

    // Build the message exactly like the Python code
    final message = <int>[
      0xF0, 0x00, 0x21, 0x27, 0x6D, sysExId, 0x7A,
      2, // Header + opcode (kOpDownload = 2)
      ...pathBytes,
    ];

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
