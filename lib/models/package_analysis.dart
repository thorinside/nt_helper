import 'package_file.dart';

/// Result of analyzing a preset package zip file
class PackageAnalysis {
  final String packageName;
  final String presetName;
  final String author;
  final String version;
  final List<PackageFile> files;
  final Map<String, dynamic> manifest;
  final bool isValid;
  final String? errorMessage;

  const PackageAnalysis({
    required this.packageName,
    required this.presetName,
    required this.author,
    required this.version,
    required this.files,
    required this.manifest,
    required this.isValid,
    this.errorMessage,
  });

  /// Invalid package constructor
  const PackageAnalysis.invalid({
    required this.errorMessage,
  })  : packageName = '',
        presetName = '',
        author = '',
        version = '',
        files = const [],
        manifest = const {},
        isValid = false;

  /// Total number of files in the package
  int get totalFiles => files.length;

  /// Number of files that have conflicts
  int get conflictCount => files.where((f) => f.hasConflict).length;

  /// Number of files that will be installed
  int get installCount => files.where((f) => f.shouldInstall).length;

  /// Number of files that will be skipped
  int get skipCount => files.where((f) => f.shouldSkip).length;

  /// Whether there are any conflicts to resolve
  bool get hasConflicts => conflictCount > 0;

  /// Whether the package is ready for installation
  bool get canInstall => isValid && files.isNotEmpty;

  /// Get files grouped by their target directory
  Map<String, List<PackageFile>> get filesByDirectory {
    final Map<String, List<PackageFile>> grouped = {};
    for (final file in files) {
      final dir = file.targetPath.split('/').first;
      grouped.putIfAbsent(dir, () => []).add(file);
    }
    return grouped;
  }

  /// Update file actions
  PackageAnalysis copyWith({
    List<PackageFile>? files,
  }) {
    return PackageAnalysis(
      packageName: packageName,
      presetName: presetName,
      author: author,
      version: version,
      files: files ?? this.files,
      manifest: manifest,
      isValid: isValid,
      errorMessage: errorMessage,
    );
  }
}