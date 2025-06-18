import 'package:flutter/foundation.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'package:nt_helper/domain/sysex/ascii.dart';
import 'package:nt_helper/domain/sysex/responses/sysex_response.dart';
import 'package:nt_helper/domain/sysex/sysex_utils.dart';

class ParameterValueStringResponse extends SysexResponse {
  ParameterValueStringResponse(Uint8List data) : super(data);

  @override
  ParameterValueString parse() {
    return ParameterValueString(
      algorithmIndex: decode8(data.sublist(0, 1)),
      parameterNumber: decode16(data, 1),
      value: decodeNullTerminatedAscii(data, 4).value,
    );
  }
} 