import 'package:flutter/foundation.dart';
import 'package:nt_helper/domain/sysex/ascii.dart';
import 'package:nt_helper/domain/sysex/responses/sysex_response.dart';

class MessageResponse extends SysexResponse {
  MessageResponse(Uint8List data) : super(data);

  @override
  String parse() {
    return decodeNullTerminatedAscii(data, 0).value;
  }
} 