import 'package:nt_helper/models/sd_card_file_system.dart';
import 'package:nt_helper/domain/sysex/responses/sysex_response.dart';
import 'dart:convert'; // For ascii

class DirectoryListingResponse extends SysexResponse {
  DirectoryListingResponse(super.payload);

  @override
  DirectoryListing parse() {
    final entries = <DirectoryEntry>[];
    var i = 0;
    while (i < data.length) {
      if (i + 1 > data.length) break;

      final isDirectory = data[i] == 1;
      i++;

      final nameBytes = <int>[];
      while (i < data.length && data[i] != 0) {
        nameBytes.add(data[i]);
        i++;
      }

      if (nameBytes.isNotEmpty) {
        final name = ascii.decode(nameBytes);
        entries.add(DirectoryEntry(name: name, isDirectory: isDirectory));
      }
      i++; // Move past null terminator
    }
    return DirectoryListing(entries: entries);
  }
}
