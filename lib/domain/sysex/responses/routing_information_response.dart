import 'package:nt_helper/domain/sysex/responses/sysex_response.dart';
import 'package:nt_helper/domain/sysex/sysex_utils.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';

class RoutingInformationResponse extends SysexResponse {
  RoutingInformationResponse(super.data);

  @override
  RoutingInfo parse() {
    final algorithmIndex = data[0];
    final routing = <int>[];
    final isLongFormat = data.length > 31;
    var offset = 1;

    for (var i = 0; i < 6; i++) {
      var d = decode35(data, offset);
      if (isLongFormat) {
        offset += 5;
        d |= decode35(data, offset) << 35;
      } else {
        d >>= 1;
      }
      offset += 5;
      routing.add(d);
    }

    return RoutingInfo(algorithmIndex: algorithmIndex, routingInfo: routing);
  }
}
