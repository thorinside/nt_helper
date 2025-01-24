import 'dart:convert';
import 'dart:typed_data';

class ParseResult {
  final String value;
  final int nextOffset;

  ParseResult(this.value, this.nextOffset);
}

/// Parse a null-terminated ASCII string from [bytes] starting at [start].
/// Returns the decoded [String] and the next offset (the byte after the null).
ParseResult decodeNullTerminatedAscii(Uint8List bytes, int start) {
  int i = start;
  // Find the null terminator (0x00), or the end of the buffer.
  while (i < bytes.length && bytes[i] != 0) {
    i++;
  }

  // Decode the substring from [start .. i).
  final str = ascii.decode(bytes.sublist(start, i), allowInvalid: true);

  // If we found a null terminator, skip it. Otherwise, i == bytes.length.
  final nextOffset = (i < bytes.length) ? i + 1 : i;

  return ParseResult(str, nextOffset);
}

/// Encodes a [String] into a null-terminated ASCII representation.
/// Returns a [Uint8List] containing the encoded bytes.
Uint8List encodeNullTerminatedAscii(String input) {
  // Encode the string to ASCII bytes.
  final asciiBytes = ascii.encode(input);

  // Append a null terminator (0x00).
  final encodedBytes = Uint8List(asciiBytes.length + 1)
    ..setRange(0, asciiBytes.length, asciiBytes)
    ..[asciiBytes.length] = 0x00;

  return encodedBytes;
}
