import 'dart:typed_data';

/// Interface for file system operations
abstract class PresetFileSystem {
  /// Read file contents as bytes
  Future<Uint8List?> readFile(String relativePath);

  /// List all files in a directory (recursively if specified)
  Future<List<String>> listFiles(String directoryPath,
      {bool recursive = false});
}
