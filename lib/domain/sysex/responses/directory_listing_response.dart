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
    // Expected payload: status (1 byte), subcommand (1 byte), then directory data.
    // In the raw SysEx, this corresponds to data[7][8], and then the rest.
    if (data.length < 2) {
      throw ArgumentError(
        "Invalid payload length for DirectoryListingResponse: ${data.length}, expected at least 2 for status and subcommand.",
      );
    }

    final status = data[0]; // Status byte within this payload
    final subCommand = data[1]; // Subcommand byte within this payload

    if (status != 0x00 || subCommand != 0x01) {
      // If status is not OK (0x00) or subcommand is not Directory Listing (0x01),
      // this is not a valid directory listing response as expected.
      // For now, return an empty listing or throw an error.
      // Based on the JS, errors are handled at a higher level, so an empty list is appropriate for invalid/non-success.
      // Alternatively, we could map this to respError and handle in SysexParser, but per your guidance,
      // parsing should happen here.
      return DirectoryListing(entries: []);
    }

    final directoryData = data.sublist(
      2,
    ); // Actual directory data starts from index 2 of *this* payload

    final entries = <DirectoryEntry>[];
    var i = 0;
    while (i < directoryData.length) {
      final remaining = directoryData.length - i;
      if (remaining < 18) {
        break;
      }

      final attributes = directoryData[i++];
      final date = _extractShort(directoryData.sublist(i, i + 3));
      i += 3;
      final time = _extractShort(directoryData.sublist(i, i + 3));
      i += 3;
      final size = _extractInt(directoryData.sublist(i, i + 10));
      i += 10;

      final nameBytes = <int>[];
      while (i < directoryData.length) {
        final byte = directoryData[i++];
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
      entries.add(
        DirectoryEntry(
          name: name,
          attributes: attributes,
          date: date,
          time: time,
          size: size,
        ),
      );
    }
    return DirectoryListing(entries: entries);
  }
}
