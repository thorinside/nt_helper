import 'package:flutter/foundation.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'package:nt_helper/domain/sysex/ascii.dart';
import 'package:nt_helper/domain/sysex/responses/sysex_response.dart';
import 'package:nt_helper/domain/sysex/sysex_utils.dart';

class ParameterInfoResponse extends SysexResponse {
  ParameterInfoResponse(Uint8List data) : super(data);

  @override
  ParameterInfo parse() {
    return ParameterInfo(
      algorithmIndex: decode8(data.sublist(0, 1)),
      parameterNumber: decode16(data, 1),
      min: decode16(data, 4),
      max: decode16(data, 7),
      defaultValue: decode16(data, 10),
      unit: decode8(data.sublist(13, 14)),
      name: decodeNullTerminatedAscii(data, 14).value,
      powerOfTen: data.last,
    );
  }
} 