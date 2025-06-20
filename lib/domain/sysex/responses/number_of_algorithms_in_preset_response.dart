import 'package:nt_helper/domain/sysex/responses/sysex_response.dart';
import 'package:nt_helper/domain/sysex/sysex_utils.dart';

class NumberOfAlgorithmsInPresetResponse extends SysexResponse {
  NumberOfAlgorithmsInPresetResponse(super.data);

  @override
  int parse() {
    return decode8(data);
  }
}
