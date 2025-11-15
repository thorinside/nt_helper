import 'package:nt_helper/domain/sysex/responses/sysex_response.dart';
import 'package:nt_helper/domain/sysex/sysex_utils.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';

class AllParameterValuesResponse extends SysexResponse {
  AllParameterValuesResponse(super.data);

  @override
  AllParameterValues parse() {
    var algorithmIndex = decode8(data.sublist(0, 1));
    return AllParameterValues(
      algorithmIndex: algorithmIndex,
      values: [
        for (int offset = 1; offset < data.length; offset += 3)
          ParameterValue(
            algorithmIndex: algorithmIndex,
            parameterNumber: offset ~/ 3,
            value: _extractValue(data, offset),
            isDisabled: _extractDisabledFlag(data[offset]),
          ),
      ],
    );
  }

  /// Extracts the 16-bit signed value from a 21-bit parameter encoding,
  /// masking out the flag bits (16-20) before decoding.
  /// The byte0 contains both value bits 14-15 and flag bits 16-20.
  /// We need to mask out the flag bits to get the correct value.
  int _extractValue(List<int> data, int offset) {
    // Mask out flag bits (bits 16-20) from byte0 to preserve only value bits (14-15)
    // byte0 layout: [b6 b5 b4 b3 b2] [b1 b0]
    //                ↑ flag bits     ↑ value bits 14-15
    final maskedByte0 = data[offset] & 0x03; // Keep only bits 0-1 (value bits 14-15)
    final maskedData = [maskedByte0, data[offset + 1], data[offset + 2]];
    return decode16(maskedData, 0);
  }

  /// Extracts the disabled flag from the first byte of a 21-bit parameter value.
  /// The 21-bit encoding splits as: bits 0-15 (value), bits 16-20 (flag).
  /// Returns true if flag == 1 (disabled), false otherwise.
  bool _extractDisabledFlag(int byte0) {
    final flag = (byte0 >> 2) & 0x1F;
    return flag == 1;
  }
}
