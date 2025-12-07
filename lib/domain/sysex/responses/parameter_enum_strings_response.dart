import 'package:nt_helper/domain/sysex/ascii.dart';
import 'package:nt_helper/domain/sysex/responses/sysex_response.dart';
import 'package:nt_helper/domain/sysex/sysex_utils.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';

class ParameterEnumStringsResponse extends SysexResponse {
  late final ParameterEnumStrings parameterEnumStrings;

  ParameterEnumStringsResponse(super.data);

  @override
  ParameterEnumStrings parse() {
    try {
      // Validate minimum data length (algorithmIndex + parameterNumber + count)
      if (data.length < 5) {
        return ParameterEnumStrings.filler();
      }

      final algorithmIndex = decode8(data);
      final parameterNumber = decode16(data, 1);
      final count = decode8(data.sublist(4, 5));

      // Validate count is reasonable
      if (count < 0 || count > 256) {
        return ParameterEnumStrings(
          algorithmIndex: algorithmIndex,
          parameterNumber: parameterNumber,
          values: const [],
        );
      }

      int start = 5;
      final values = <String>[];

      for (int i = 0; i < count; i++) {
        // Check bounds before parsing each string
        if (start >= data.length) {
          // Firmware bug: data truncated. Pad with unique placeholder strings.
          while (values.length < count) {
            values.add('${values.length}'); // Use index as placeholder
          }
          break;
        }
        try {
          ParseResult result = decodeNullTerminatedAscii(data, start);
          values.add(result.value);
          start = result.nextOffset;
        } catch (e) {
          // If parsing a string fails, pad remaining with placeholders
          while (values.length < count) {
            values.add('${values.length}'); // Use index as placeholder
          }
          break;
        }
      }

      return ParameterEnumStrings(
        algorithmIndex: algorithmIndex,
        parameterNumber: parameterNumber,
        values: values,
      );
    } catch (e) {
      // If anything goes wrong, return an empty filler
      return ParameterEnumStrings.filler();
    }
  }
}
