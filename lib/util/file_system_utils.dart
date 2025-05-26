import 'dart:io'; // Required for Directory, FileSystemEntity, and Platform
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p; // For joining paths
import 'package:flutter/foundation.dart'
    show kIsWeb; // To check for web platform and for debug prints
import 'package:nt_helper/util/in_app_logger.dart'; // Added for InAppLogger

// Import for docman
import 'package:docman/docman.dart' as docman;

class FileSystemUtils {
  /// Allows the user to pick a directory using the native file explorer.
  ///
  /// Returns the selected directory path as a [String] for non-Android platforms,
  /// or a [docman.DocumentFile] for Android if a directory is picked via SAF.
  /// Returns `null` if the user cancels the dialog.
  static Future<dynamic?> pickSdCardRootDirectory() async {
    // Return type changed to dynamic?
    try {
      if (!kIsWeb && Platform.isAndroid) {
        // Use DocMan for Android to pick a directory via SAF
        // This grants persistent permission to the selected directory tree.
        final docman.DocumentFile? pickedDir = await docman.DocMan.pick.directory(
            // Optionally, you can set an initial URI if you have one.
            // initDir: 'content://com.android.externalstorage.documents/tree/primary%3ASDCARD_ROOT_HINT',
            );
        return pickedDir; // This is a DocumentFile
      } else {
        // Use file_picker for other platforms
        String? directoryPath = await FilePicker.platform.getDirectoryPath();
        return directoryPath; // This is a String
      }
    } catch (e) {
      InAppLogger().log('Error picking directory: $e');
      return null;
    }
  }

  /// Lists the contents (files and directories) of a given directory path.
  ///
  /// Returns a list of [FileSystemEntity] objects.
  /// Returns an empty list if the directory doesn't exist or an error occurs.
  static Future<List<FileSystemEntity>> listDirectoryContents(
      String path) async {
    // This method might not be needed if using DocMan for directory listing on Android
    // or could be adapted for non-Android platforms.
    try {
      final dir = Directory(path);
      if (await dir.exists()) {
        return await dir.list().toList();
      }
      return [];
    } catch (e) {
      InAppLogger().log('Error listing directory contents for $path: $e');
      return [];
    }
  }

  /// Checks if the given path or DocumentFile appears to be a valid Disting NT SD card root.
  ///
  /// For Android, `pathOrDocumentFile` is expected to be a `docman.DocumentFile` representing the root.
  /// For other platforms, it's a `String` path.
  /// Currently checks for the existence of a subdirectory named "presets".
  static Future<bool> isValidDistingSdCard(dynamic pathOrDocumentFile) async {
    if (kIsWeb) return false;

    if (pathOrDocumentFile is docman.DocumentFile) {
      // Android with docman.DocumentFile
      try {
        final presetsDir = await pathOrDocumentFile.find('presets');
        if (presetsDir != null && presetsDir.exists && presetsDir.isDirectory) {
          return true;
        }
      } catch (e) {
        InAppLogger().log('Error validating Disting SD card: $e');
        return false;
      }
    } else if (pathOrDocumentFile is String) {
      // Desktop/other platform path
      final presetsPath = p.join(pathOrDocumentFile, 'presets');
      final presetsDir = Directory(presetsPath);
      return await presetsDir.exists();
    }
    return false;
  }

  // Helper for recursive listing with DocMan
  static Future<void> _findPresetFilesRecursiveDocman(
      docman.DocumentFile parent,
      List<(String uri, String relativePath)> allFiles,
      String currentRelativePath,
      {int currentDepth = 0,
      int maxDepth = 10}) async {
    InAppLogger().log(
        '[DocManRecursive] Entering for: ${parent.name ?? parent.uri.toString()}, Depth: $currentDepth');
    if (currentDepth > maxDepth) {
      InAppLogger().log(
          '[DocManRecursive] Max recursion depth reached for docman directory: ${parent.uri}');
      return;
    }

    try {
      InAppLogger().log(
          '[DocManRecursive] Attempting to list documents for ${parent.name ?? parent.uri.toString()}');
      final List<docman.DocumentFile> documentsInDirectory =
          await parent.listDocuments();
      InAppLogger().log(
          '[DocManRecursive] Got ${documentsInDirectory.length} documents for ${parent.name ?? parent.uri.toString()}');

      if (documentsInDirectory.isEmpty) {
        InAppLogger().log(
            '[DocManRecursive] Directory is empty: ${parent.name ?? parent.uri.toString()}');
      }

      for (final docFile in documentsInDirectory) {
        InAppLogger().log(
            '[DocManRecursive] Processing item: ${docFile.name ?? docFile.uri.toString()}, isDirectory: ${docFile.isDirectory}');
        if (docFile.isDirectory) {
          await _findPresetFilesRecursiveDocman(docFile, allFiles,
              p.join(currentRelativePath, docFile.name ?? 'unknown_dir'),
              currentDepth: currentDepth + 1, maxDepth: maxDepth);
        } else if (docFile.isFile &&
            (docFile.name?.toLowerCase().endsWith('.json') ?? false)) {
          String actualRelativePath =
              p.join(currentRelativePath, docFile.name ?? 'unknown_file.json');
          InAppLogger()
              .log('[DocManRecursive] Added JSON file: $actualRelativePath');
          allFiles.add((docFile.uri.toString(), actualRelativePath));
        }
      }
      InAppLogger().log(
          '[DocManRecursive] Exiting for: ${parent.name ?? parent.uri.toString()}');
    } catch (e, s) {
      InAppLogger().log(
          '[DocManRecursive] Error during recursive DocMan scan in ${parent.name ?? parent.uri.toString()}: $e\nStackTrace: $s');
      rethrow;
    }
  }

  /// Recursively finds all .json files within the given directory.
  ///
  /// For Android, `presetsDirIdentifier` is expected to be a `docman.DocumentFile` representing the 'presets' directory.
  /// For other platforms, it's a `String` path to the 'presets' directory.
  /// Returns a list of tuples (uri, relativePath) for all files ending with '.json'.
  static Future<List<(String uri, String relativePath)>> findPresetFiles(
      dynamic presetsDirIdentifier) async {
    final List<(String uri, String relativePath)> presetFiles = [];

    if (presetsDirIdentifier == null) {
      InAppLogger()
          .log('findPresetFiles: Presets directory identifier is null.');
      return presetFiles;
    }

    try {
      if (presetsDirIdentifier is docman.DocumentFile) {
        if (!presetsDirIdentifier.isDirectory) {
          InAppLogger().log(
              'Provided DocumentFile is not a directory: ${presetsDirIdentifier.name}');
          return presetFiles;
        }
        try {
          String initialRelativePathForAndroid =
              presetsDirIdentifier.name ?? 'presets';
          await _findPresetFilesRecursiveDocman(
              presetsDirIdentifier, presetFiles, initialRelativePathForAndroid);
        } catch (e) {
          InAppLogger().log(
              '[findPresetFiles] Error from _findPresetFilesRecursiveDocman: $e');
        }
      } else if (presetsDirIdentifier is String) {
        // --- iOS/Desktop Path ---
        InAppLogger().log(
            "findPresetFiles (iOS/Desktop): Received presetsDirIdentifier (string path): $presetsDirIdentifier");
        final directory = Directory(presetsDirIdentifier);

        final bool directoryExists = await directory.exists();
        InAppLogger().log(
            "findPresetFiles (iOS/Desktop): Directory $presetsDirIdentifier exists: $directoryExists");

        if (!directoryExists) {
          InAppLogger().log(
              'findPresetFiles (iOS/Desktop): Presets directory not found at path: $presetsDirIdentifier');
          return presetFiles;
        }

        InAppLogger().log(
            "findPresetFiles (iOS/Desktop): Starting recursive list for $presetsDirIdentifier");
        int entityCount = 0;
        int jsonFileCount = 0;

        await for (final entity
            in directory.list(recursive: true, followLinks: false)) {
          entityCount++;
          InAppLogger().log(
              "findPresetFiles (iOS/Desktop): Found entity: ${entity.path} (type: ${entity.runtimeType})");
          if (entity is File && entity.path.toLowerCase().endsWith('.json')) {
            jsonFileCount++;
            InAppLogger().log(
                "findPresetFiles (iOS/Desktop): Found JSON file: ${entity.path}");
            String pathWithinPresets =
                p.relative(entity.path, from: presetsDirIdentifier);
            String finalRelativePath =
                p.join(p.basename(presetsDirIdentifier), pathWithinPresets);
            presetFiles.add((entity.path, finalRelativePath));
          }
        }
        InAppLogger().log(
            "findPresetFiles (iOS/Desktop): Finished recursive list. Total entities processed: $entityCount. JSON files added: ${jsonFileCount}.");
      } else {
        InAppLogger().log(
            'findPresetFiles: Unsupported type for presetsDirIdentifier: ${presetsDirIdentifier.runtimeType}');
        return presetFiles;
      }
    } catch (e, s) {
      InAppLogger().log(
          'findPresetFiles: Error scanning for preset files: $e\nStackTrace: $s');
    }
    return presetFiles;
  }
}
