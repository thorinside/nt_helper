import 'package:nt_helper/domain/sysex/ascii.dart';
import 'package:nt_helper/domain/sysex/responses/sysex_response.dart';
import 'package:nt_helper/domain/sysex/sysex_utils.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';

class ParameterEnumStringsResponse extends SysexResponse {
  late final ParameterEnumStrings parameterEnumStrings;

  ParameterEnumStringsResponse(super.data);

  @override
  ParameterEnumStrings parse() {
    int start = 5;
    return ParameterEnumStrings(
      algorithmIndex: decode8(data),
      parameterNumber: decode16(data, 1),
      values: List.generate(decode8(data.sublist(4, 5)), (i) {
        ParseResult result = decodeNullTerminatedAscii(data, start);
        start = result.nextOffset;
        return result.value;
      }),
    );
  }
} 