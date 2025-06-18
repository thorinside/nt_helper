import 'package:flutter/foundation.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'package:nt_helper/domain/sysex/responses/sysex_response.dart';
import 'package:nt_helper/domain/sysex/sysex_utils.dart';
import 'package:nt_helper/models/packed_mapping_data.dart';

class MappingResponse extends SysexResponse {
  MappingResponse(Uint8List data) : super(data);

  @override
  Mapping parse() {
    return Mapping(
      algorithmIndex: decode8(data),
      parameterNumber: decode16(data, 1),
      packedMappingData: PackedMappingData.fromBytes(
          decode8(data.sublist(4, 5)), data.sublist(5)),
    );
  }
} 