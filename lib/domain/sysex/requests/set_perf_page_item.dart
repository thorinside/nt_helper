import 'dart:typed_data';

import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'package:nt_helper/domain/sysex/sysex_message.dart';
import 'package:nt_helper/domain/sysex/sysex_utils.dart';
import 'package:nt_helper/models/performance_page_item.dart';

/// Set a performance page item (SysEx 0x58, firmware v1.16+).
///
/// Disabled: F0 ... 58 [version=1] [item] [0] F7
/// Enabled:  F0 ... 58 [version=1] [item] [1] [slot] [param 3B] [min 3B] [max 3B] [s1...] [0x00] [s2...] [0x00] F7
class SetPerfPageItemMessage extends SysexMessage {
  final PerformancePageItem item;

  SetPerfPageItemMessage({
    required super.sysExId,
    required this.item,
  });

  /// Clamp a character to the SysEx 7-bit safe range (0x01-0x7E).
  static int _clampChar(int c) => c.clamp(0x01, 0x7E);

  /// Encode a string as SysEx-safe bytes followed by a null terminator.
  static List<int> _encodeString(String s) {
    return [...s.codeUnits.map(_clampChar), 0x00];
  }

  @override
  Uint8List encode() {
    final bytes = <int>[
      ...buildHeader(sysExId),
      DistingNTRequestMessageType.setPerfPageItem.value,
      1, // version
      item.itemIndex & 0x7F,
    ];

    if (!item.enabled) {
      bytes.add(0); // flags = disabled
    } else {
      bytes.add(1); // flags = enabled
      bytes.add(item.slotIndex & 0x7F);
      bytes.addAll(encode16(item.parameterNumber));
      bytes.addAll(encode16(item.min));
      bytes.addAll(encode16(item.max));
      bytes.addAll(_encodeString(item.upperLabel));
      bytes.addAll(_encodeString(item.lowerLabel));
    }

    bytes.addAll(buildFooter());
    return Uint8List.fromList(bytes);
  }
}
