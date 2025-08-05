/// Represents a file in a preset package with conflict information
class PackageFile {
  final String relativePath;
  final String targetPath;
  final int size;
  final bool hasConflict;
  final FileAction action;

  const PackageFile({
    required this.relativePath,
    required this.targetPath,
    required this.size,
    required this.hasConflict,
    this.action = FileAction.install,
  });

  String get filename => relativePath.split('/').last;

  bool get shouldInstall => action == FileAction.install;
  bool get shouldSkip => action == FileAction.skip;

  PackageFile copyWith({
    String? relativePath,
    String? targetPath,
    int? size,
    bool? hasConflict,
    FileAction? action,
  }) {
    return PackageFile(
      relativePath: relativePath ?? this.relativePath,
      targetPath: targetPath ?? this.targetPath,
      size: size ?? this.size,
      hasConflict: hasConflict ?? this.hasConflict,
      action: action ?? this.action,
    );
  }
}

/// Actions that can be taken for a file during package installation
enum FileAction {
  install, // Install the file (overwrite if exists)
  skip, // Skip installing this file
}

/// Status of a file during installation
enum FileStatus {
  pending, // Not yet processed
  installing, // Currently being installed
  completed, // Successfully installed
  skipped, // User chose to skip
  failed, // Installation failed
}
