import 'dart:io'; // Required for Directory, FileSystemEntity, and Platform
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p; // For joining paths
import 'package:flutter/foundation.dart'
    show kIsWeb; // To check for web platform and for debug prints
import 'package:nt_helper/util/in_app_logger.dart'; // Added for InAppLogger
import 'package:security_scoped_resource/security_scoped_resource.dart'; // Added for iOS scoped access

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
    final logger = InAppLogger();
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
      logger.log('Error picking directory: $e');
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
    final logger = InAppLogger();
    try {
      final dir = Directory(path);
      if (await dir.exists()) {
        return await dir.list().toList();
      }
      return [];
    } catch (e) {
      logger.log('Error listing directory contents for $path: $e');
      return [];
    }
  }

  /// Checks if the given path or DocumentFile appears to be a valid Disting NT SD card root.
  ///
  /// For Android, `pathOrDocumentFile` is expected to be a `docman.DocumentFile` representing the root.
  /// For other platforms, it's a `String` path.
  /// Currently checks for the existence of a subdirectory named "presets".
  static Future<bool> isValidDistingSdCard(dynamic pathOrDocumentFile) async {
    final logger = InAppLogger();
    if (kIsWeb) return false;

    if (pathOrDocumentFile is docman.DocumentFile) {
      // Android with docman.DocumentFile
      try {
        final presetsDir = await pathOrDocumentFile.find('presets');
        if (presetsDir != null && presetsDir.exists && presetsDir.isDirectory) {
          return true;
        }
      } catch (e) {
        logger.log('Error validating Disting SD card (DocFile): $e');
        return false;
      }
    } else if (pathOrDocumentFile is String) {
      // Desktop/other platform path
      final presetsPath = p.join(pathOrDocumentFile, 'presets');
      final presetsDir = Directory(presetsPath);
      try {
        return await presetsDir.exists();
      } catch (e) {
        logger.log(
            'Error validating Disting SD card (String path): $e - Path: $presetsPath');
        return false;
      }
    }
    logger.log(
        'isValidDistingSdCard: Invalid type for pathOrDocumentFile: ${pathOrDocumentFile.runtimeType}');
    return false;
  }

  // Helper for recursive listing with DocMan
  static Future<void> _findPresetFilesRecursiveDocman(
      docman.DocumentFile parent,
      List<(String uri, String relativePath)> allFiles,
      String currentRelativePath,
      {int currentDepth = 0,
      int maxDepth = 10}) async {
    final logger = InAppLogger();
    logger.log(
        '[DocManRecursive] Entering for: ${parent.name ?? parent.uri.toString()}, Depth: $currentDepth');
    if (currentDepth > maxDepth) {
      logger.log(
          '[DocManRecursive] Max recursion depth reached for docman directory: ${parent.uri}');
      return;
    }

    try {
      logger.log(
          '[DocManRecursive] Attempting to list documents for ${parent.name ?? parent.uri.toString()}');
      final List<docman.DocumentFile> documentsInDirectory =
          await parent.listDocuments();
      logger.log(
          '[DocManRecursive] Got ${documentsInDirectory.length} documents for ${parent.name ?? parent.uri.toString()}');

      if (documentsInDirectory.isEmpty) {
        logger.log(
            '[DocManRecursive] Directory is empty: ${parent.name ?? parent.uri.toString()}');
      }

      for (final docFile in documentsInDirectory) {
        logger.log(
            '[DocManRecursive] Processing item: ${docFile.name ?? docFile.uri.toString()}, isDirectory: ${docFile.isDirectory}');
        if (docFile.isDirectory) {
          await _findPresetFilesRecursiveDocman(docFile, allFiles,
              p.join(currentRelativePath, docFile.name ?? 'unknown_dir'),
              currentDepth: currentDepth + 1, maxDepth: maxDepth);
        } else if (docFile.isFile &&
            (docFile.name?.toLowerCase().endsWith('.json') ?? false)) {
          String actualRelativePath =
              p.join(currentRelativePath, docFile.name ?? 'unknown_file.json');
          logger.log('[DocManRecursive] Added JSON file: $actualRelativePath');
          allFiles.add((docFile.uri.toString(), actualRelativePath));
        }
      }
      logger.log(
          '[DocManRecursive] Exiting for: ${parent.name ?? parent.uri.toString()}');
    } catch (e, s) {
      logger.log(
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
    final logger = InAppLogger(); // Get logger instance

    if (presetsDirIdentifier == null) {
      logger.log('findPresetFiles: Presets directory identifier is null.');
      return presetFiles;
    }

    try {
      if (presetsDirIdentifier is docman.DocumentFile) {
        // Android Path (DocMan)
        if (!presetsDirIdentifier.isDirectory) {
          logger.log(
              'Provided DocumentFile is not a directory: ${presetsDirIdentifier.name}');
          return presetFiles;
        }
        try {
          String initialRelativePathForAndroid =
              presetsDirIdentifier.name ?? 'presets';
          await _findPresetFilesRecursiveDocman(
              presetsDirIdentifier, presetFiles, initialRelativePathForAndroid);
        } catch (e) {
          logger.log(
              '[findPresetFiles] Error from _findPresetFilesRecursiveDocman: $e');
        }
      } else if (presetsDirIdentifier is String) {
        // iOS / Desktop Path (String path)
        logger.log(
            "findPresetFiles (iOS/Desktop): Received presetsDirIdentifier (string path): $presetsDirIdentifier");
        final directory = Directory(presetsDirIdentifier);
        bool accessGranted = false;

        if (!kIsWeb && Platform.isIOS) {
          logger.log(
              "findPresetFiles (iOS): Attempting to start security scoped access for $presetsDirIdentifier");
          try {
            accessGranted = await SecurityScopedResource.instance
                .startAccessingSecurityScopedResource(directory);
            logger.log(
                "findPresetFiles (iOS): Security scoped access granted: $accessGranted for $presetsDirIdentifier");
            if (!accessGranted) {
              logger.log(
                  "findPresetFiles (iOS): Failed to gain security scoped access to $presetsDirIdentifier. Check entitlements and user permissions.");
              // No need to stop access if it wasn't granted
              return presetFiles;
            }
          } catch (e, s) {
            logger.log(
                "findPresetFiles (iOS): Error during startAccessingSecurityScopedResource for $presetsDirIdentifier: $e\nStackTrace: $s");
            // No need to stop access if it failed to start
            return presetFiles;
          }
        } else {
          // For non-iOS (Desktop), assume direct access is fine (or already handled by entitlements like on macOS for user-selected folders)
          accessGranted = true;
        }

        // Proceed only if access is granted (either by scoped resource on iOS or assumed for desktop)
        if (accessGranted) {
          try {
            final bool directoryExists = await directory.exists();
            logger.log(
                "findPresetFiles (iOS/Desktop): Directory $presetsDirIdentifier exists: $directoryExists");

            if (!directoryExists) {
              logger.log(
                  'findPresetFiles (iOS/Desktop): Presets directory not found at path: $presetsDirIdentifier');
              return presetFiles;
            }

            logger.log(
                "findPresetFiles (iOS/Desktop): Starting recursive list for $presetsDirIdentifier");
            int entityCount = 0;
            int jsonFileCount = 0;

            await for (final entity
                in directory.list(recursive: true, followLinks: false)) {
              entityCount++;
              logger.log(
                  "findPresetFiles (iOS/Desktop): Found entity: ${entity.path} (type: ${entity.runtimeType})");
              if (entity is File &&
                  entity.path.toLowerCase().endsWith('.json')) {
                jsonFileCount++;
                logger.log(
                    "findPresetFiles (iOS/Desktop): Found JSON file: ${entity.path}");
                String pathWithinPresets =
                    p.relative(entity.path, from: presetsDirIdentifier);
                String finalRelativePath =
                    p.join(p.basename(presetsDirIdentifier), pathWithinPresets);
                presetFiles.add((entity.path, finalRelativePath));
              }
            }
            logger.log(
                "findPresetFiles (iOS/Desktop): Finished recursive list. Total entities processed: $entityCount. JSON files added: ${jsonFileCount}.");
          } finally {
            if (!kIsWeb && Platform.isIOS && accessGranted) {
              // Only stop access if it was started for iOS
              logger.log(
                  "findPresetFiles (iOS): Attempting to stop security scoped access for $presetsDirIdentifier");
              try {
                await SecurityScopedResource.instance
                    .stopAccessingSecurityScopedResource(directory);
                logger.log(
                    "findPresetFiles (iOS): Security scoped access stopped for $presetsDirIdentifier");
              } catch (e, s) {
                logger.log(
                    "findPresetFiles (iOS): Error during stopAccessingSecurityScopedResource for $presetsDirIdentifier: $e\nStackTrace: $s");
              }
            }
          }
        } // end if(accessGranted)
      } else {
        logger.log(
            'findPresetFiles: Unsupported type for presetsDirIdentifier: ${presetsDirIdentifier.runtimeType}');
        return presetFiles;
      }
    } catch (e, s) {
      logger.log(
          'findPresetFiles: Outer catch - Error scanning for preset files: $e\nStackTrace: $s');
    }
    return presetFiles;
  }
}
