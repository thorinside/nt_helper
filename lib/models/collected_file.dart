import 'dart:typed_data';

/// Represents a file that has been collected for packaging
class CollectedFile {
  final String relativePath;
  final Uint8List bytes;

  CollectedFile(this.relativePath, this.bytes);

  int get size => bytes.length;

  String get filename => relativePath.split('/').last;
}
