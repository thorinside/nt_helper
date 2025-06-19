import 'package:nt_helper/domain/sysex/responses/sysex_response.dart';
import 'dart:convert';

class LuaOutputResponse extends SysexResponse {
  LuaOutputResponse(super.data);

  @override
  String parse() {
    // The output text is ASCII, ending when the SysEx ends (no extra null before F7)
    // Convert the raw bytes to ASCII string
    return utf8.decode(data);
  }
}
