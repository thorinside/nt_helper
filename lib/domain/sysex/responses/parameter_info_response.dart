import 'package:nt_helper/domain/sysex/ascii.dart';
import 'package:nt_helper/domain/sysex/responses/sysex_response.dart';
import 'package:nt_helper/domain/sysex/sysex_utils.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';

class ParameterInfoResponse extends SysexResponse {
  late final ParameterInfo parameterInfo;

  ParameterInfoResponse(super.data);

  @override
  ParameterInfo parse() {
    final nameResult = decodeNullTerminatedAscii(data, 14);
    final flagsOffset = nameResult.nextOffset;
    final flagsByte = flagsOffset < data.length ? data[flagsOffset] : 0;

    // Extract both powerOfTen and ioFlags from the flags byte.
    // Bit layout of flags byte:
    //   Bits 0-1: powerOfTen (scaling: 10^n where n=0-3)
    //   Bits 2-5: ioFlags (I/O metadata):
    //     - Bit 2 (value 1): Parameter is an input
    //     - Bit 3 (value 2): Parameter is an output
    //     - Bit 4 (value 4): Audio signal (true) vs CV signal (false)
    //     - Bit 5 (value 8): Parameter controls output mode
    final powerOfTen = -(flagsByte & 0x3); // Bits 0-1, negate for division
    final ioFlags = (flagsByte >> 2) & 0xF; // Bits 2-5

    return ParameterInfo(
      algorithmIndex: decode8(data.sublist(0, 1)),
      parameterNumber: decode16(data, 1),
      min: decode16(data, 4),
      max: decode16(data, 7),
      defaultValue: decode16(data, 10),
      unit: decode8(data.sublist(13, 14)),
      name: nameResult.value,
      powerOfTen: powerOfTen,
      ioFlags: ioFlags,
    );
  }
}
