import 'package:nt_helper/domain/sysex/responses/sysex_response.dart';
import 'package:nt_helper/domain/sysex/sysex_utils.dart';
import 'package:nt_helper/models/performance_page_item.dart';

/// Response parser for performance page item data (SysEx 0x57).
///
/// Response payload (after command byte):
/// [version=1] [item] [flags]
///   if flags & 1:
///     [slot] [param_h] [param_m] [param_l]
///     [min_h] [min_m] [min_l]
///     [max_h] [max_m] [max_l]
///     [s1 chars...] [0x00]
///     [s2 chars...] [0x00]
class PerfPageItemResponse extends SysexResponse {
  PerfPageItemResponse(super.data);

  @override
  PerformancePageItem parse() {
    // data[0] = version (should be 1)
    final itemIndex = data[1];
    final flags = data[2];

    if ((flags & 1) == 0) {
      return PerformancePageItem.empty(itemIndex);
    }

    final slotIndex = data[3];
    final parameterNumber = decode16(data, 4);
    final min = decode16(data, 7);
    final max = decode16(data, 10);

    // Parse null-terminated strings starting at offset 13
    var offset = 13;
    final s1 = _readNullTerminatedString(offset);
    offset += s1.length + 1; // +1 for null terminator
    final s2 = _readNullTerminatedString(offset);

    return PerformancePageItem(
      itemIndex: itemIndex,
      enabled: true,
      slotIndex: slotIndex,
      parameterNumber: parameterNumber,
      min: min,
      max: max,
      upperLabel: s1,
      lowerLabel: s2,
    );
  }

  String _readNullTerminatedString(int offset) {
    final chars = <int>[];
    for (var i = offset; i < data.length; i++) {
      if (data[i] == 0x00) break;
      chars.add(data[i]);
    }
    return String.fromCharCodes(chars);
  }
}
