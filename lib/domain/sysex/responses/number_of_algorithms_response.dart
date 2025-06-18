import 'package:nt_helper/domain/sysex/responses/sysex_response.dart';
import 'package:nt_helper/domain/sysex/sysex_utils.dart';

class NumberOfAlgorithmsResponse extends SysexResponse {
  NumberOfAlgorithmsResponse(super.data);

  @override
  int parse() {
    // Basic length check: encoded num algos (3)
    if (data.length < 3) {
      throw ArgumentError(
          "Invalid data length for NumberOfAlgorithms: ${data.length}, expected at least 3.");
    }
    // Correct slice: sublist(0, 3) gets 3 bytes (index 0, 1, 2)
    return decode16(data.sublist(0, 3), 0);
  }
} 