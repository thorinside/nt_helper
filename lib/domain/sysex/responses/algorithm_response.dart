import 'package:flutter/foundation.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'package:nt_helper/domain/sysex/responses/sysex_response.dart';

class AlgorithmResponse extends SysexResponse {
  AlgorithmResponse(Uint8List data) : super(data);

  @override
  Algorithm parse() {
    return Algorithm(
      algorithmIndex: data[0].toInt(),
      guid: String.fromCharCodes(data.sublist(1, 5)),
      name: String.fromCharCodes(
        data.sublist(5).takeWhile((value) => value != 0),
      ).trim(),
    );
  }
} 