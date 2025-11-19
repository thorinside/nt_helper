import 'package:nt_helper/domain/sysex/responses/sysex_response.dart';
import 'package:nt_helper/domain/sysex/sysex_utils.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';

/// Response parser for output mode usage data (SysEx 0x55).
///
/// Parses the hardware response that indicates which parameters are affected
/// by an output mode control parameter.
///
/// Response format:
/// [0xF0, 0x00, 0x21, 0x27, 0x6D, sysExId, 0x55, slot,
///  source_high, source_mid, source_low, count,
///  affected_1_high, affected_1_mid, affected_1_low,
///  affected_2_high, affected_2_mid, affected_2_low,
///  ...,
///  0xF7]
///
/// Where:
/// - source_high/mid/low: Source parameter number (mode control) as 3 7-bit bytes
/// - count: Number of affected parameters
/// - affected_N_high/mid/low: Each affected parameter as 3 7-bit bytes
class OutputModeUsageResponse extends SysexResponse {
  late final OutputModeUsage outputModeUsage;

  OutputModeUsageResponse(super.data);

  @override
  OutputModeUsage parse() {
    // Extract algorithm index (slot)
    final algorithmIndex = decode8(data.sublist(0, 1));

    // Extract source parameter number (the mode control parameter)
    // Bytes 1-3: source parameter encoded as 16-bit value in three 7-bit bytes
    final sourceParameterNumber = decode16Unsigned(data, 1);

    // Byte 4: Number of affected parameters
    final count = data[4];

    // Extract list of affected parameter numbers
    final affectedParameterNumbers = <int>[];
    for (int i = 0; i < count; i++) {
      // Each parameter number is 3 bytes, starting at offset 5
      final offset = 5 + (i * 3);
      if (offset + 2 < data.length) {
        final paramNum = decode16Unsigned(data, offset);
        affectedParameterNumbers.add(paramNum);
      }
    }

    return OutputModeUsage(
      algorithmIndex: algorithmIndex,
      parameterNumber: sourceParameterNumber,
      affectedParameterNumbers: affectedParameterNumbers,
    );
  }
}
