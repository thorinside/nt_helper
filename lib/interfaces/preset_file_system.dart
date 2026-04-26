import 'dart:typed_data';

/// One entry returned by [PresetFileSystem.listEntries] — a file path
/// alongside its byte size as reported by the SD card directory listing.
/// Used by the package-size estimator so it can pre-compute byte totals
/// without downloading every file.
class FileEntryInfo {
  final String path;
  final int size;

  const FileEntryInfo({required this.path, required this.size});
}

/// Interface for file system operations
abstract class PresetFileSystem {
  /// Read file contents as bytes
  Future<Uint8List?> readFile(String relativePath);

  /// List all files in a directory (recursively if specified)
  Future<List<String>> listFiles(
    String directoryPath, {
    bool recursive = false,
  });

  /// List files with sizes from the directory's metadata. Default impl
  /// falls back to [listFiles] and reports size as 0 for each entry —
  /// implementations backed by SD-card directory listings should override.
  Future<List<FileEntryInfo>> listEntries(
    String directoryPath, {
    bool recursive = false,
  }) async {
    final paths = await listFiles(directoryPath, recursive: recursive);
    return [for (final p in paths) FileEntryInfo(path: p, size: 0)];
  }

  /// Look up the size of a single file. Default impl reads the parent
  /// directory listing and matches by name. Returns null if not found.
  Future<int?> getFileSize(String relativePath) async {
    final slash = relativePath.lastIndexOf('/');
    if (slash <= 0) return null;
    final parent = relativePath.substring(0, slash);
    final entries = await listEntries(parent);
    for (final e in entries) {
      if (e.path == relativePath) return e.size;
    }
    return null;
  }
}
