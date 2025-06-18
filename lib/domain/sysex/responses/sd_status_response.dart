import 'package:nt_helper/models/sd_card_file_system.dart';
import 'package:nt_helper/domain/sysex/responses/sysex_response.dart';
import 'dart:convert'; // For ascii

class SdStatusResponse extends SysexResponse {
  SdStatusResponse(super.payload);

  @override
  SdCardStatus parse() {
    if (data.isEmpty) {
      return SdCardStatus(success: false, message: 'Empty status response');
    }

    final success = data[0] == 1;
    String message = 'Unknown status';

    if (data.length > 1) {
      final messageBytes = data.sublist(1);
      // Find null terminator if it exists
      final nullIdx = messageBytes.indexOf(0);
      if (nullIdx != -1) {
        message = ascii.decode(messageBytes.sublist(0, nullIdx));
      } else {
        message = ascii.decode(messageBytes);
      }
    }

    return SdCardStatus(success: success, message: message);
  }
}
