import 'package:nt_helper/domain/sysex/ascii.dart';
import 'package:nt_helper/domain/sysex/responses/sysex_response.dart';
import 'package:nt_helper/domain/sysex/sysex_utils.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';

class ParameterInfoResponse extends SysexResponse {
  late final ParameterInfo parameterInfo;

  ParameterInfoResponse(super.data);

  @override
  ParameterInfo parse() {
    return ParameterInfo(
      algorithmIndex: decode8(data.sublist(0, 1)),
      parameterNumber: decode16(1),
      min: decode16(4),
      max: decode16(7),
      defaultValue: decode16(10),
      unit: decode8(data.sublist(13, 14)),
      name: decodeNullTerminatedAscii(14).value,
      powerOfTen: data.last,
    );
  }
}
