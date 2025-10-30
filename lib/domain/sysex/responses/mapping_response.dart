import 'package:nt_helper/domain/sysex/responses/sysex_response.dart';
import 'package:nt_helper/domain/sysex/sysex_utils.dart';
import 'package:nt_helper/models/packed_mapping_data.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';

class MappingResponse extends SysexResponse {
  late final Mapping mapping;

  MappingResponse(super.data);

  @override
  Mapping parse() {
    final algorithmIndex = decode8(data);
    final parameterNumber = decode16(data, 1);
    final version = decode8(data.sublist(4, 5));
    final mappingData = data.sublist(5);


    return Mapping(
      algorithmIndex: algorithmIndex,
      parameterNumber: parameterNumber,
      packedMappingData: PackedMappingData.fromBytes(version, mappingData),
    );
  }
}
