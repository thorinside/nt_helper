import 'package:nt_helper/models/sd_card_file_system.dart';
import 'package:nt_helper/domain/sysex/responses/sysex_response.dart';
import 'dart:convert'; // For ascii

class DirectoryListingResponse extends SysexResponse {
  DirectoryListingResponse(super.payload);

  int _extractShort(List<int> data) {
    if (data.length < 3) return 0;
    return (data[0] << 14) | (data[1] << 7) | (data[2]);
  }

  int _extractInt(List<int> data) {
    if (data.length < 10) return 0;
    int size = 0;
    for (int j = 0; j < 10; ++j) {
      size += (data[j] << ((9 - j) * 7));
    }
    return size;
  }

  @override
  DirectoryListing parse() {
    final entries = <DirectoryEntry>[];
    var i = 0;
    while (i < data.length) {
      final remaining = data.length - i;
      if (remaining < 18) {
        break;
      }

      final attributes = data[i++];
      final date = _extractShort(data.sublist(i, i + 3));
      i += 3;
      final time = _extractShort(data.sublist(i, i + 3));
      i += 3;
      final size = _extractInt(data.sublist(i, i + 10));
      i += 10;

      final nameBytes = <int>[];
      while (i < data.length) {
        final byte = data[i++];
        if (byte == 0) {
          break;
        }
        nameBytes.add(byte);
      }

      if (nameBytes.isEmpty) {
        break;
      }

      var name = ascii.decode(nameBytes);
      if ((attributes & 0x10) != 0) {
        name += '/';
      }
      entries.add(DirectoryEntry(
          name: name,
          attributes: attributes,
          date: date,
          time: time,
          size: size));
    }
    return DirectoryListing(entries: entries);
  }
}
