import 'dart:typed_data';

class DirectoryEntry {
  final String name;
  final bool isDirectory;

  DirectoryEntry({required this.name, required this.isDirectory});
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
