import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

bool isPdfPath(String filePath) =>
    path.extension(filePath).toLowerCase() == '.pdf';

Future<String?> searchablePdfOrTextContent(File file) async {
  if (isPdfPath(file.path)) {
    final extracted = extractPdfText(await file.readAsBytes());
    return extracted.trim().isEmpty ? null : extracted;
  }
  try {
    return await file.readAsString();
  } on FormatException {
    return null;
  }
}

String extractPdfText(List<int> bytes) {
  final pdf = latin1.decode(bytes, allowInvalid: true);
  final chunks = <String>[];
  final streamPattern = RegExp(r'stream\r?\n(.*?)\r?\nendstream', dotAll: true);

  for (final match in streamPattern.allMatches(pdf)) {
    final start = match.start;
    final dictStart = start > 600 ? start - 600 : 0;
    final dictionary = pdf.substring(dictStart, start);
    List<int> streamBytes = latin1.encode(match.group(1) ?? '');

    if (dictionary.contains('/FlateDecode')) {
      try {
        streamBytes = ZLibDecoder().convert(streamBytes);
      } on FormatException {
        continue;
      }
    } else if (dictionary.contains('/DCTDecode') ||
        dictionary.contains('/JPXDecode') ||
        dictionary.contains('/CCITTFaxDecode')) {
      continue;
    }

    final streamText = latin1.decode(streamBytes, allowInvalid: true);
    final extracted = _extractTextOperators(streamText);
    if (extracted.isNotEmpty) chunks.add(extracted);
  }

  return chunks.join('\n').replaceAll(RegExp(r'[ \t]+\n'), '\n').trim();
}

String _extractTextOperators(String contentStream) {
  final chunks = <String>[];
  final literalTj = RegExp(r'\(((?:\\.|[^\\)])*)\)\s*Tj', dotAll: true);
  for (final match in literalTj.allMatches(contentStream)) {
    chunks.add(_decodePdfLiteral(match.group(1) ?? ''));
  }

  final hexTj = RegExp(r'<([0-9A-Fa-f\s]+)>\s*Tj', dotAll: true);
  for (final match in hexTj.allMatches(contentStream)) {
    chunks.add(_decodePdfHex(match.group(1) ?? ''));
  }

  final tjArray = RegExp(r'\[(.*?)\]\s*TJ', dotAll: true);
  final arrayLiteral = RegExp(r'\(((?:\\.|[^\\)])*)\)', dotAll: true);
  final arrayHex = RegExp(r'<([0-9A-Fa-f\s]+)>', dotAll: true);
  for (final match in tjArray.allMatches(contentStream)) {
    final body = match.group(1) ?? '';
    final text = StringBuffer();
    for (final literal in arrayLiteral.allMatches(body)) {
      text.write(_decodePdfLiteral(literal.group(1) ?? ''));
    }
    for (final hex in arrayHex.allMatches(body)) {
      text.write(_decodePdfHex(hex.group(1) ?? ''));
    }
    if (text.isNotEmpty) chunks.add(text.toString());
  }

  return chunks
      .map((chunk) => chunk.replaceAll(RegExp(r'\s+'), ' ').trim())
      .where((chunk) => chunk.isNotEmpty)
      .join('\n');
}

String _decodePdfLiteral(String value) {
  final out = StringBuffer();
  for (var i = 0; i < value.length; i++) {
    final char = value[i];
    if (char != r'\') {
      out.write(char);
      continue;
    }
    if (i + 1 >= value.length) break;
    final next = value[++i];
    if (next == 'n') {
      out.write('\n');
    } else if (next == 'r') {
      out.write('\r');
    } else if (next == 't') {
      out.write('\t');
    } else if (next == 'b') {
      out.write('\b');
    } else if (next == 'f') {
      out.write('\f');
    } else if (next == '(' || next == ')' || next == r'\') {
      out.write(next);
    } else if (_isOctalDigit(next)) {
      final octal = StringBuffer(next);
      for (var j = 0; j < 2 && i + 1 < value.length; j++) {
        final candidate = value[i + 1];
        if (!_isOctalDigit(candidate)) break;
        octal.write(candidate);
        i++;
      }
      out.writeCharCode(int.parse(octal.toString(), radix: 8));
    } else {
      out.write(next);
    }
  }
  return out.toString();
}

bool _isOctalDigit(String value) =>
    value.length == 1 &&
    value.codeUnitAt(0) >= 0x30 &&
    value.codeUnitAt(0) <= 0x37;

String _decodePdfHex(String value) {
  final cleaned = value.replaceAll(RegExp(r'\s+'), '');
  if (cleaned.isEmpty) return '';
  final padded = cleaned.length.isOdd ? '${cleaned}0' : cleaned;
  final bytes = <int>[];
  for (var i = 0; i < padded.length; i += 2) {
    bytes.add(int.parse(padded.substring(i, i + 2), radix: 16));
  }
  if (bytes.length >= 2 && bytes[0] == 0xfe && bytes[1] == 0xff) {
    final codeUnits = <int>[];
    for (var i = 2; i + 1 < bytes.length; i += 2) {
      codeUnits.add((bytes[i] << 8) | bytes[i + 1]);
    }
    return String.fromCharCodes(codeUnits);
  }
  return latin1.decode(bytes, allowInvalid: true);
}
