import 'package:nt_helper/domain/sysex/responses/sysex_response.dart';
import 'package:nt_helper/domain/sysex/sysex_utils.dart';

class NumberOfAlgorithmsResponse extends SysexResponse {
  NumberOfAlgorithmsResponse(super.data);

  @override
  int parse() {
    // The number of algorithms is a 16-bit encoded value, requiring 3 bytes.
    if (data.length < 3) {
      throw ArgumentError(
          "Invalid data length for NumberOfAlgorithms: ${data.length}, expected at least 3.");
    }
    // Decode the 16-bit value from the first 3 bytes of the payload.
    return decode16(data.sublist(0, 3), 0);
  }
}
