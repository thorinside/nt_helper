/// Test program to examine parameter flag bits in SysEx messages.
///
/// This is a utility to decode raw SysEx parameter value messages and
/// identify which parameters have the flag set in bits 16-20.
///
/// Usage: Paste hex dump of a 0x44 (AllParameterValues) SysEx message below.

void main() {
  print('Parameter Flag Test - Examining SysEx 0x44 Message');
  print('=' * 70);
  print('');

  // Actual hex dump from Clock algorithm (slot 1)
  // Format: F0 00 21 27 6D <sysexId> 44 <payload> F7
  final String hexDump = '''
F0 00 21 27 6D 00 44 01 00 00 00 00 00 00 00 09
30 00 00 01 00 00 04 00 00 02 04 00 01 04 00 02
00 00 00 00 00 00 00 00 00 00 00 00 00 00 01 04
00 0F 04 00 01 00 00 00 00 00 09 00 00 00 00 00
32 00 00 01 00 00 00 04 00 0A 00 00 01 00 00 01
00 00 01 04 00 10 04 00 01 00 00 00 00 00 06 00
00 00 00 00 32 00 00 01 00 00 00 04 00 0A 00 00
01 00 00 02 00 00 01 04 00 11 04 00 01 00 00 00
00 00 09 00 00 00 00 00 32 00 00 01 00 00 00 04
00 0A 00 00 01 00 00 03 00 00 00 00 00 12 00 00
01 00 00 00 00 00 09 00 00 00 00 00 32 00 00 01
00 00 00 04 00 0A 00 00 00 04 00 01 00 00 00 00
00 13 00 00 01 00 00 00 00 00 09 00 00 00 00 00
32 00 00 01 00 00 00 04 00 0A 00 00 00 04 00 01
F7
  ''';

  if (hexDump.contains('PASTE_HEX_DUMP_HERE')) {
    print('To use this tool:');
    print('1. Connect to the hardware');
    print('2. Use a MIDI monitor to capture the 0x44 response message');
    print('3. Paste the hex dump in this file (hexDump variable)');
    print('4. Run this test again');
    print('');
    print('Alternatively, use test data below for validation...');
    print('');

    // Create test data to demonstrate the analysis
    demonstrateWithTestData();
  } else {
    analyzeHexDump(hexDump);
  }
}

void demonstrateWithTestData() {
  print('Demonstrating with test data:');
  print('-' * 70);

  // Test cases: different flag bit patterns
  final testCases = [
    {'name': 'No flag', 'bytes': [0x00, 0x00, 0x64], 'expectedFlag': 0},
    {'name': 'Flag = 1', 'bytes': [0x04, 0x00, 0x64], 'expectedFlag': 1},
    {'name': 'Flag = 31', 'bytes': [0x7C, 0x00, 0x64], 'expectedFlag': 31},
    {'name': 'Value = -100', 'bytes': [0x03, 0x7F, 0x1C], 'expectedFlag': 0},
  ];

  print('Test# | Name          | Byte0 | Byte1 | Byte2 | Flag | Value');
  print('-' * 70);

  for (var i = 0; i < testCases.length; i++) {
    final test = testCases[i];
    final bytes = test['bytes'] as List<int>;
    final result = analyzeParameterBytes(bytes[0], bytes[1], bytes[2]);

    print('${(i + 1).toString().padLeft(5)} | '
          '${(test['name'] as String).padRight(13)} | '
          '${bytes[0].toRadixString(16).padLeft(5)} | '
          '${bytes[1].toRadixString(16).padLeft(5)} | '
          '${bytes[2].toRadixString(16).padLeft(5)} | '
          '${result['flag'].toString().padLeft(4)} | '
          '${result['value']}');
  }
  print('=' * 70);
}

void analyzeHexDump(String hexDump) {
  // Parse hex dump and analyze
  final bytes = parseHexDump(hexDump);

  if (bytes.isEmpty) {
    print('ERROR: Invalid hex dump');
    return;
  }

  print('Full message: ${bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}');
  print('');

  // Validate it's a SysEx message
  if (bytes[0] != 0xF0) {
    print('ERROR: Not a SysEx message (should start with F0)');
    return;
  }

  if (bytes[bytes.length - 1] != 0xF7) {
    print('ERROR: Not a valid SysEx message (should end with F7)');
    return;
  }

  // Extract payload (skip header: F0 00 21 27 6D <sysexId> 44)
  // Payload starts at index 7, ends before F7
  final payload = bytes.sublist(7, bytes.length - 1);

  if (payload.isEmpty) {
    print('ERROR: Empty payload');
    return;
  }

  final algorithmIndex = payload[0];
  print('Algorithm Index: $algorithmIndex');
  print('');

  print('Parameter Analysis:');
  print('-' * 70);
  print('Param# | Byte0 | Byte1 | Byte2 | Flag  | Value   | Analysis');
  print('-' * 70);

  for (int offset = 1; offset < payload.length; offset += 3) {
    if (offset + 2 >= payload.length) break;

    final paramNumber = (offset - 1) ~/ 3;
    final byte0 = payload[offset];
    final byte1 = payload[offset + 1];
    final byte2 = payload[offset + 2];

    final result = analyzeParameterBytes(byte0, byte1, byte2);
    final hasFlag = result['flag'] != 0;
    final analysis = hasFlag ? '<<< FLAG SET!' : '';

    print('${paramNumber.toString().padLeft(6)} | '
          '${byte0.toRadixString(16).padLeft(5)} | '
          '${byte1.toRadixString(16).padLeft(5)} | '
          '${byte2.toRadixString(16).padLeft(5)} | '
          '${result['flag'].toString().padLeft(5)} | '
          '${result['value'].toString().padLeft(7)} | '
          '$analysis');
  }

  print('=' * 70);
}

Map<String, int> analyzeParameterBytes(int byte0, int byte1, int byte2) {
  // Decode the value (standard 16-bit decode)
  final rawValue = (byte0 << 14) | (byte1 << 7) | byte2;
  var value = rawValue;
  if (value & 0x8000 != 0) {
    value -= 0x10000; // Sign extend
  }

  // Extract the flag bits
  // The 21-bit value is: [byte0 bits 0-6][byte1 bits 0-6][byte2 bits 0-6]
  // Bits 0-15 are the value: [byte0 bits 0-1][byte1 bits 0-6][byte2 bits 0-6]
  // Bits 16-20 are potential flags: [byte0 bits 2-6]
  final flag = (byte0 >> 2) & 0x1F;

  return {'flag': flag, 'value': value};
}

List<int> parseHexDump(String hexDump) {
  final bytes = <int>[];
  final parts = hexDump.trim().split(RegExp(r'\s+'));

  for (final part in parts) {
    if (part.isEmpty) continue;
    try {
      final byte = int.parse(part, radix: 16);
      bytes.add(byte);
    } catch (e) {
      // Skip invalid parts
    }
  }

  return bytes;
}
