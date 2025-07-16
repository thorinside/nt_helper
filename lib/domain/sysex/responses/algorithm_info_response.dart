import 'package:nt_helper/domain/sysex/responses/sysex_response.dart';
import 'package:nt_helper/domain/sysex/sysex_utils.dart';
import 'package:nt_helper/domain/sysex/ascii.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';

class AlgorithmInfoResponse extends SysexResponse {
  AlgorithmInfoResponse(super.data);

  @override
  AlgorithmInfo parse() {
    int offset = 0;

    // 1) Decode the 16-bit algorithm index (2 bytes).
    final algorithmIndex = decode16(data, offset);
    offset += 2;

    // 2) Skip 1 byte at index 2 (if your data format specifies this gap).
    offset += 1;

    // 3) Decode the 4-byte GUID.
    final guid = String.fromCharCodes(data.sublist(offset, offset + 4));
    offset += 4;

    // 4) Decode the number of specifications (1 byte).
    final numSpecifications = data[offset];
    offset += 1;

    // 5) Decode each specification, each occupying 3 + 3 + 3 + 1 = 10 bytes.
    final specs = List.generate(numSpecifications, (_) {
      final min = decode16(data, offset);
      offset += 3;

      final max = decode16(data, offset);
      offset += 3;

      final defaultValue = decode16(data, offset);
      offset += 3;

      final type = data[offset];
      offset += 1;

      return Specification(
        min: min,
        max: max,
        defaultValue: defaultValue,
        type: type,
        name: "", // We'll fill in names next
      );
    });

    // 6) Decode the main algorithm name (null-terminated ASCII).
    final nameStr = decodeNullTerminatedAscii(data, offset);
    offset = nameStr.nextOffset;
    final algorithmName = nameStr.value;

    // 7) Decode each specification's display name (also null-terminated).
    final specNames = List.generate(numSpecifications, (_) {
      final str = decodeNullTerminatedAscii(data, offset);
      offset = str.nextOffset;
      return str.value;
    });

    // 8) Attach the names to the corresponding Specifications.
    final updatedSpecs = specs.asMap().entries.map((entry) {
      final i = entry.key;
      final spec = entry.value;
      return Specification(
        min: spec.min,
        max: spec.max,
        defaultValue: spec.defaultValue,
        type: spec.type,
        name: specNames[i],
      );
    }).toList();

    // 9) Decode plugin flags (isPlugin and isLoaded) if available
    bool isPlugin = false;
    bool isLoaded = true;
    
    if (offset < data.length) {
      isPlugin = data[offset] != 0;
      offset += 1;
    }
    
    if (offset < data.length) {
      isLoaded = data[offset] != 0;
      offset += 1;
    }

    // 10) Build and return the final AlgorithmInfo object.
    return AlgorithmInfo(
      algorithmIndex: algorithmIndex,
      guid: guid,
      specifications: updatedSpecs,
      name: algorithmName,
      isPlugin: isPlugin,
      isLoaded: isLoaded,
    );
  }
}
