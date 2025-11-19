import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'dart:typed_data';

import 'package:nt_helper/domain/sysex/sysex_message.dart';
import 'package:nt_helper/domain/sysex/sysex_utils.dart';

/// Request output mode usage information for a parameter (SysEx 0x55).
///
/// Queries the hardware for the list of parameters affected by an output mode
/// control parameter. The response indicates which parameters' output routing
/// is controlled by the specified mode parameter.
///
/// Message format:
/// [0xF0, 0x00, 0x21, 0x27, 0x6D, sysExId, 0x55, slot, p_high, p_mid, p_low, 0xF7]
///
/// Where parameter number is encoded as three 7-bit bytes:
/// - p_high: (parameterNumber >> 14) & 0x3 (bits 14-15)
/// - p_mid: (parameterNumber >> 7) & 0x7F (bits 7-13)
/// - p_low: parameterNumber & 0x7F (bits 0-6)
class RequestOutputModeUsageMessage extends SysexMessage
    implements HasAlgorithmIndex, HasParameterNumber {
  @override
  final int algorithmIndex;
  @override
  final int parameterNumber;

  RequestOutputModeUsageMessage({
    required super.sysExId,
    required this.algorithmIndex,
    required this.parameterNumber,
  });

  @override
  Uint8List encode() {
    final bytes = <int>[
      ...buildHeader(sysExId),
      DistingNTRequestMessageType.requestOutputModeUsage.value,
      algorithmIndex & 0x7F,
      ...encode16(parameterNumber),
      ...buildFooter(),
    ];
    return Uint8List.fromList(bytes);
  }
}
