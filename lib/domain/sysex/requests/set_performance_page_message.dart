import 'dart:typed_data';

import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'package:nt_helper/domain/sysex/sysex_message.dart';
import 'package:nt_helper/domain/sysex/sysex_utils.dart';

/// SysEx message to set a parameter's performance page assignment.
///
/// Message format:
/// F0 00 21 27 6D [sysExId] 54 [slot] [p_high] [p_mid] [p_low] [version] [index] F7
///
/// - slot: Slot index (0-31)
/// - p_high, p_mid, p_low: Parameter number encoded as 3 bytes (7-bit each)
/// - version: Mapping version (5)
/// - index: Performance page index (0-15, where 0 = not assigned)
class SetPerformancePageMessage extends SysexMessage {
  final int slotIndex;
  final int parameterNumber;
  final int perfPageIndex;

  SetPerformancePageMessage({
    required super.sysExId,
    required this.slotIndex,
    required this.parameterNumber,
    required this.perfPageIndex,
  });

  @override
  Uint8List encode() {
    // Clamp perfPageIndex to valid range (0-15)
    final clampedPerfPageIndex = perfPageIndex.clamp(0, 15);

    final bytes = <int>[
      ...buildHeader(sysExId),
      DistingNTRequestMessageType.setPerformancePageMapping.value,
      slotIndex & 0x7F,
      ...encode16(parameterNumber),
      5, // mapping version
      clampedPerfPageIndex & 0x7F,
      ...buildFooter(),
    ];
    return Uint8List.fromList(bytes);
  }
}
