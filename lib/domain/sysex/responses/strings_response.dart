import 'package:flutter/foundation.dart';
import 'package:nt_helper/domain/sysex/ascii.dart';
import 'package:nt_helper/domain/sysex/responses/sysex_response.dart';
import 'package:nt_helper/domain/sysex/sysex_utils.dart';

class StringsResponse extends SysexResponse {
  StringsResponse(Uint8List data) : super(data);

  @override
  List<String> parse() {
    int numStrings = decode8(data);
    int start = 1;
    return List.generate(numStrings, (i) {
      var value = decodeNullTerminatedAscii(data, start);
      start = value.nextOffset;
      return value.value;
    });
  }
} 