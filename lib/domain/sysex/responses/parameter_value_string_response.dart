import 'package:nt_helper/domain/sysex/ascii.dart';
import 'package:nt_helper/domain/sysex/responses/sysex_response.dart';
import 'package:nt_helper/domain/sysex/sysex_utils.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';

class ParameterValueStringResponse extends SysexResponse {
  late final ParameterValueString parameterValueString;

  ParameterValueStringResponse(super.data);

  @override
  ParameterValueString parse() {
    return ParameterValueString(
      algorithmIndex: decode8(data.sublist(0, 1)),
      parameterNumber: decode16(1),
      value: decodeNullTerminatedAscii(4).value,
    );
  }
}
