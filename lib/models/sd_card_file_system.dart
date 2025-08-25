import 'dart:typed_data';

class DirectoryEntry {
  final String name;
  final int attributes;
  final int date;
  final int time;
  final int size;

  DirectoryEntry({
    required this.name,
    required this.attributes,
    required this.date,
    required this.time,
    required this.size,
  });

  bool get isDirectory => (attributes & 0x10) != 0;
}

class DirectoryListing {
  final List<DirectoryEntry> entries;

  DirectoryListing({required this.entries});
}

class FileChunk {
  final int offset;
  final Uint8List data;

  FileChunk({required this.offset, required this.data});
}

class SdCardStatus {
  final bool success;
  final String message;

  SdCardStatus({required this.success, required this.message});
}
