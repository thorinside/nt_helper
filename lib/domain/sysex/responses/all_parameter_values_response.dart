import 'package:flutter/foundation.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'package:nt_helper/domain/sysex/responses/sysex_response.dart';
import 'package:nt_helper/domain/sysex/sysex_utils.dart';

class AllParameterValuesResponse extends SysexResponse {
  AllParameterValuesResponse(Uint8List data) : super(data);

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
              value: decode16(data, offset)),
      ],
    );
  }
} 