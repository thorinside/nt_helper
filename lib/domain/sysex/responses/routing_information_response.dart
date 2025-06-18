import 'package:flutter/foundation.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'package:nt_helper/domain/sysex/responses/sysex_response.dart';
import 'package:nt_helper/domain/sysex/sysex_utils.dart';

class RoutingInformationResponse extends SysexResponse {
  RoutingInformationResponse(Uint8List data) : super(data);

  @override
  RoutingInfo parse() {
    int offset = 1;
    return RoutingInfo(
      algorithmIndex: decode8(data.sublist(0, 1)),
      routingInfo: List.generate(6, (i) {
        final value = decode32(data, offset);
        offset += 5;
        return value;
      }),
    );
  }
} 