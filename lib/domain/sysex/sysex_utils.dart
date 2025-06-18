import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'dart:typed_data';

List<int> buildHeader(int distingSysExId) {
  return [
    kSysExStart, ...kExpertSleepersManufacturerId, // 00 21 27
    kDistingNTPrefix, // 6D
    (distingSysExId & 0x7F), // <SysEx ID> is 7-bit
  ];
}

/// Conclude the SysEx message.
List<int> buildFooter() {
  return [kSysExEnd];
}

List<int> encode16(int value) {
  // Ensure 16-bit range
  final int v = value & 0xFFFF;
  final int ms2 = (v >> 14) & 0x03; // top 2 bits
  final int mid7 = (v >> 7) & 0x7F; // next 7 bits
  final int ls7 = v & 0x7F; // final 7 bits
  return [ms2, mid7, ls7];
}

/// The reverse: parse 3 bytes of 7-bit data into a 16-bit integer.
int decode16(List<int> data, int offset) {
  var v =
      (data[offset + 0] << 14) | (data[offset + 1] << 7) | (data[offset + 2]);
  // Ensure the value is treated as a signed 16-bit integer
  if (v & 0x8000 != 0) {
    v -= 0x10000;
  }
  return v;
}

/// Similar approach for 32-bit if needed (e.g. set real-time clock).
/// The doc says "32 bit number" but doesn't explicitly define
/// 7-bit splitting. The existing tools do typically use 7-bit expansions.
/// Here is a hypothetical approach:
List<int> encode32(int value) {
  // Force into 32-bit range (in Dart, int can be bigger).
  final v = value & 0xFFFFFFFF;

  // The JS shifts by multiples of 7 bits.
  // That implies each of the "middle" bytes is storing 7 bits,
  // and the last byte stores up to 4 bits (to make a total of 32).
  //
  // bit layout: [bits 28..31] [bits 21..27] [bits 14..20] [bits 7..13] [bits 0..6]
  //
  // Starting from the least-significant bits:
  final b0 = v & 0x7F; // bits 0..6
  final b1 = (v >> 7) & 0x7F; // bits 7..13
  final b2 = (v >> 14) & 0x7F; // bits 14..20
  final b3 = (v >> 21) & 0x7F; // bits 21..27
  final b4 = (v >> 28) & 0x0F; // bits 28..31

  // The JS implementation sends MSB first.
  return [b4, b3, b2, b1, b0];
}

int decode32(List<int> bytes, int offset) {
  final b0 = bytes[offset + 0]; // LSB
  final b1 = bytes[offset + 1];
  final b2 = bytes[offset + 2];
  final b3 = bytes[offset + 3];
  final b4 = bytes[offset + 4]; // MSB

  return (b0 & 0x7F) |
      ((b1 & 0x7F) << 7) |
      ((b2 & 0x7F) << 14) |
      ((b3 & 0x7F) << 21) |
      ((b4 & 0x0F) << 28);
}

int decode8(Uint8List payload) {
  return payload[0].toInt();
}

/// Calculates the checksum for a given payload.
/// The payload should start from the opcode/command byte.
int calculateChecksum(List<int> payload) {
  int sum = 0;
  for (final byte in payload) {
    sum += byte;
  }
  return (-sum) & 0x7F;
}

/// Encodes a list of bytes into their 4-bit nybble representation.
List<int> bytesToNybbles(List<int> bytes) {
  final nybbles = <int>[];
  for (final byte in bytes) {
    nybbles.add((byte >> 4) & 0x0F);
    nybbles.add(byte & 0x0F);
  }
  return nybbles;
}

Uint8List nybblesToBytes(List<int> nybbles) {
  final bytes = <int>[];
  for (var i = 0; i < nybbles.length; i += 2) {
    if (i + 1 < nybbles.length) {
      final msb = nybbles[i] & 0x0F;
      final lsb = nybbles[i + 1] & 0x0F;
      bytes.add((msb << 4) | lsb);
    }
  }
  return Uint8List.fromList(bytes);
}
