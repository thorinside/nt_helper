import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import '../models/package_analysis.dart';
import '../models/package_file.dart';

/// Service for analyzing preset package zip files
class PresetPackageAnalyzer {
  /// Analyze a zip file and extract package information
  static Future<PackageAnalysis> analyzePackage(Uint8List zipBytes) async {
    try {

      // Decode the archive
      final archive = ZipDecoder().decodeBytes(zipBytes);

      // Find and parse manifest.json
      final manifestFile = archive.files
          .where((file) => file.isFile)
          .firstWhere(
            (file) => file.name == 'manifest.json',
            orElse: () => throw Exception('manifest.json not found in package'),
          );

      final manifestContent = utf8.decode(manifestFile.content as List<int>);
      final manifest = jsonDecode(manifestContent) as Map<String, dynamic>;

      // Extract package metadata from manifest
      final presetInfo = manifest['preset'] as Map<String, dynamic>? ?? {};
      final packageName =
          presetInfo['filename'] as String? ?? 'Unknown Package';
      final presetName = presetInfo['name'] as String? ?? 'Unknown Preset';
      final author = presetInfo['author'] as String? ?? 'Unknown Author';
      final version = presetInfo['version']?.toString() ?? '1';

      // Find all files in the root/ directory
      final rootFiles = archive.files
          .where((file) => file.isFile && file.name.startsWith('root/'))
          .toList();


      // Convert archive files to PackageFile objects
      final packageFiles = <PackageFile>[];
      for (final file in rootFiles) {
        // Remove 'root/' prefix to get target path
        final targetPath = file.name.substring(5); // Remove 'root/'

        // Skip empty paths
        if (targetPath.isEmpty) continue;

        final packageFile = PackageFile(
          relativePath: file.name,
          targetPath: targetPath,
          size: file.size,
          hasConflict: false, // Will be updated by conflict detector
        );

        packageFiles.add(packageFile);
      }


      return PackageAnalysis(
        packageName: packageName,
        presetName: presetName,
        author: author,
        version: version,
        files: packageFiles,
        manifest: manifest,
        isValid: true,
      );
    } catch (e, stackTrace) {
      debugPrintStack(stackTrace: stackTrace);

      return PackageAnalysis.invalid(
        errorMessage: 'Failed to analyze package: $e',
      );
    }
  }

  /// Validate that a zip file has the expected structure
  static Future<bool> isValidPackage(Uint8List zipBytes) async {
    try {
      final archive = ZipDecoder().decodeBytes(zipBytes);

      // Check for required files
      final hasManifest = archive.files.any((f) => f.name == 'manifest.json');
      final hasRootDirectory = archive.files.any(
        (f) => f.name.startsWith('root/'),
      );

      return hasManifest && hasRootDirectory;
    } catch (e) {
      return false;
    }
  }

  /// Extract specific file content from the package
  static Future<Uint8List?> extractFile(
    Uint8List zipBytes,
    String filePath,
  ) async {
    try {
      final archive = ZipDecoder().decodeBytes(zipBytes);
      final file = archive.files
          .where((f) => f.isFile)
          .firstWhere(
            (f) => f.name == filePath,
            orElse: () => throw Exception('File not found: $filePath'),
          );

      return Uint8List.fromList(file.content as List<int>);
    } catch (e) {
      return null;
    }
  }

  /// Get all files that would be extracted to a specific directory
  static List<PackageFile> getFilesForDirectory(
    PackageAnalysis analysis,
    String directory,
  ) {
    return analysis.files
        .where((file) => file.targetPath.startsWith('$directory/'))
        .toList();
  }

  /// Get a summary of the package contents by directory
  static Map<String, int> getDirectorySummary(PackageAnalysis analysis) {
    final summary = <String, int>{};

    for (final file in analysis.files) {
      final directory = file.targetPath.split('/').first;
      summary[directory] = (summary[directory] ?? 0) + 1;
    }

    return summary;
  }
}
