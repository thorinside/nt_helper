import 'dart:typed_data';
import 'package:nt_helper/domain/sysex/sysex_message.dart';

class RequestFileUploadChunkMessage extends SysexMessage {
  final String path;
  final int position;
  final Uint8List data;
  final bool createAlways;

  RequestFileUploadChunkMessage({
    required super.sysExId,
    required this.path,
    required this.position,
    required this.data,
    this.createAlways = false,
  });

  @override
  Uint8List encode() {
    final pathBytes = path.codeUnits;
    final count = data.length;

    // Build the message exactly like the Python code
    final message = <int>[
      0xF0, 0x00, 0x21, 0x27, 0x6D, sysExId, 0x7A, 4, // Header + opcode
      ...pathBytes,
      0, // Null terminator
      createAlways ? 1 : 0, // Create always flag
      // Position encoding (35-bit special format from Python)
      0, // ( position >> 63 ) & 0x7f - always 0
      0, // ( position >> 56 ) & 0x7f - always 0
      0, // ( position >> 49 ) & 0x7f - always 0
      0, // ( position >> 42 ) & 0x7f - always 0
      0, // ( position >> 35 ) & 0x7f - always 0
      (position >> 28) & 0x0f, // Note: 0x0f not 0x7f
      (position >> 21) & 0x7f,
      (position >> 14) & 0x7f,
      (position >> 7) & 0x7f,
      (position >> 0) & 0x7f,

      // Count encoding (same 35-bit format)
      0, // ( count >> 63 ) & 0x7f - always 0
      0, // ( count >> 56 ) & 0x7f - always 0
      0, // ( count >> 49 ) & 0x7f - always 0
      0, // ( count >> 42 ) & 0x7f - always 0
      0, // ( count >> 35 ) & 0x7f - always 0
      (count >> 28) & 0x0f, // Note: 0x0f not 0x7f
      (count >> 21) & 0x7f,
      (count >> 14) & 0x7f,
      (count >> 7) & 0x7f,
      (count >> 0) & 0x7f,
    ];

    // Add data as nibbles (exactly like Python: split each byte into two 4-bit nibbles)
    for (int i = 0; i < data.length; i++) {
      final byte = data[i];
      message.add((byte >> 4) & 0xf); // High nibble
      message.add(byte & 0xf); // Low nibble
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
