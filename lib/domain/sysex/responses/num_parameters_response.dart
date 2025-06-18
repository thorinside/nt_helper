import 'package:nt_helper/domain/sysex/responses/sysex_response.dart';
import 'package:nt_helper/domain/sysex/sysex_utils.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';

class NumParametersResponse extends SysexResponse {
  late final NumParameters numParameters;

  NumParametersResponse(super.data);

  @override
  NumParameters parse() {
    // Basic length check: algorithm index (1) + encoded num params (3) = 4
    if (data.length < 4) {
      throw ArgumentError(
          "Invalid data length for NumParameters: ${data.length}, expected at least 4.");
    }
    var algorithmIndex = data[0].toInt();
    // Correct slice: sublist(1, 4) gets 3 bytes (index 1, 2, 3)
    var numParameters = decode16(data.sublist(1, 4), 0);

    return NumParameters(
      algorithmIndex: algorithmIndex,
      numParameters: numParameters,
    );
  }
} 