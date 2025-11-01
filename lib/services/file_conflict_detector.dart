import 'package:flutter/foundation.dart';
import '../models/package_analysis.dart';
import '../models/package_file.dart';
import '../cubit/disting_cubit.dart';

/// Service for detecting file conflicts when installing preset packages
class FileConflictDetector {
  final DistingCubit distingCubit;

  FileConflictDetector(this.distingCubit);

  /// Check for file conflicts between package files and existing SD card files
  Future<PackageAnalysis> detectConflicts(PackageAnalysis analysis) async {
    if (!analysis.isValid) {
      return analysis;
    }

    final state = distingCubit.state;
    if (state is! DistingStateSynchronized || state.offline) {
      // Return analysis without conflict detection
      return analysis;
    }

    try {
      final updatedFiles = <PackageFile>[];

      // Group files by directory for efficient scanning
      final filesByDirectory = analysis.filesByDirectory;

      for (final entry in filesByDirectory.entries) {
        final directory = entry.key;
        final filesInDir = entry.value;

        // Get existing files in this directory
        final existingFiles = await _getExistingFilesInDirectory('/$directory');

        // Check each file for conflicts
        for (final file in filesInDir) {
          final filename = file.filename;
          final hasConflict = existingFiles.contains(filename);

          final updatedFile = file.copyWith(hasConflict: hasConflict);
          updatedFiles.add(updatedFile);

          if (hasConflict) {}
        }
      }

      updatedFiles.where((f) => f.hasConflict).length;

      return analysis.copyWith(files: updatedFiles);
    } catch (e, stackTrace) {
      debugPrintStack(stackTrace: stackTrace);

      // Return original analysis if conflict detection fails
      return analysis;
    }
  }

  /// Get list of existing files in a specific directory on the SD card
  Future<Set<String>> _getExistingFilesInDirectory(String directoryPath) async {
    final files = <String>{};

    try {
      final disting = distingCubit.disting();
      if (disting == null) {
        return files;
      }

      await disting.requestWake();
      final listing = await disting.requestDirectoryListing(directoryPath);

      if (listing != null) {
        for (final entry in listing.entries) {
          if (!entry.isDirectory) {
            files.add(entry.name);
          }
        }
      } else {}
    } catch (e) {
      // Don't throw - just return empty set to avoid blocking installation
    }

    return files;
  }

  /// Check if a specific file exists on the SD card
  Future<bool> fileExists(String filePath) async {
    try {
      final directory =
          '/${filePath.split('/').take(filePath.split('/').length - 1).join('/')}';
      final filename = filePath.split('/').last;

      final existingFiles = await _getExistingFilesInDirectory(directory);
      return existingFiles.contains(filename);
    } catch (e) {
      return false;
    }
  }

  /// Get directories that need to be checked for a package
  static Set<String> getRequiredDirectories(PackageAnalysis analysis) {
    final directories = <String>{};

    for (final file in analysis.files) {
      final parts = file.targetPath.split('/');
      if (parts.isNotEmpty) {
        directories.add(parts.first);
      }
    }

    return directories;
  }

  /// Update file action for a specific file in the analysis
  static PackageAnalysis updateFileAction(
    PackageAnalysis analysis,
    String targetPath,
    FileAction action,
  ) {
    final updatedFiles = analysis.files.map((file) {
      if (file.targetPath == targetPath) {
        return file.copyWith(action: action);
      }
      return file;
    }).toList();

    return analysis.copyWith(files: updatedFiles);
  }

  /// Set action for all conflicting files
  static PackageAnalysis setActionForConflicts(
    PackageAnalysis analysis,
    FileAction action,
  ) {
    final updatedFiles = analysis.files.map((file) {
      if (file.hasConflict) {
        return file.copyWith(action: action);
      }
      return file;
    }).toList();

    return analysis.copyWith(files: updatedFiles);
  }

  /// Set action for all files
  static PackageAnalysis setActionForAllFiles(
    PackageAnalysis analysis,
    FileAction action,
  ) {
    final updatedFiles = analysis.files.map((file) {
      return file.copyWith(action: action);
    }).toList();

    return analysis.copyWith(files: updatedFiles);
  }
}
