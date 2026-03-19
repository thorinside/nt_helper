import 'package:nt_helper/domain/sysex/ascii.dart';
import 'package:nt_helper/domain/sysex/responses/sysex_response.dart';

class MessageResponse extends SysexResponse {
  MessageResponse(super.data);

  @override
  String parse() {
    final first = decodeNullTerminatedAscii(data, 0);
    if (first.nextOffset < data.length) {
      final second = decodeNullTerminatedAscii(data, first.nextOffset);
      if (second.value.isNotEmpty) {
        return '${first.value}\n${second.value}';
      }
    }
    return first.value;
  }
}
