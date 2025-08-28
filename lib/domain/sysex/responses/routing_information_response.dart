import 'package:nt_helper/domain/sysex/responses/sysex_response.dart';
import 'package:nt_helper/domain/sysex/sysex_utils.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';

class RoutingInformationResponse extends SysexResponse {
  RoutingInformationResponse(super.data);

  @override
  RoutingInfo parse() {
    final algorithmIndex = data[0];
    final routing = <int>[];
    var offset = 1;
    for (var i = 0; i < 6; i++) {
      routing.add(decode32(offset));
      offset += 5;
    }

    return RoutingInfo(algorithmIndex: algorithmIndex, routingInfo: routing);
  }
}
