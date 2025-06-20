import 'package:nt_helper/domain/sysex/ascii.dart';
import 'package:nt_helper/domain/sysex/responses/sysex_response.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';

class ParameterPagesResponse extends SysexResponse {
  late final ParameterPages parameterPages;
  ParameterPagesResponse(super.data);

  @override
  ParameterPages parse() {
    var algorithmIndex = data[0].toInt();
    var numPages = data[1].toInt();
    int offset = 2;
    return ParameterPages(
      algorithmIndex: algorithmIndex,
      pages: List.generate(
        numPages,
        (_) {
          final strInfo = decodeNullTerminatedAscii(data, offset);
          offset = strInfo.nextOffset;
          final name = strInfo.value;
          final numParameters = data[offset++];
          final parameterNumbers = List.generate(numParameters, (_) {
            return data[offset++] << 7 | data[offset++];
          });
          return ParameterPage(name: name, parameters: parameterNumbers);
        },
      ),
    );
  }
}
