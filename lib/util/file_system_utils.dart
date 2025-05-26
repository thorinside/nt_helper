import 'dart:io'; // Required for Directory, FileSystemEntity, and Platform
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p; // For joining paths
import 'package:flutter/foundation.dart'
    show kIsWeb, debugPrint; // To check for web platform and for debug prints

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
      debugPrint('Error picking directory: $e');
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
      debugPrint('Error listing directory contents for $path: $e');
      return [];
    }
  }

  /// Checks if the given path or DocumentFile appears to be a valid Disting NT SD card root.
  ///
  /// For Android, `pathOrDocumentFile` is expected to be a `docman.DocumentFile` representing the root.
  /// For other platforms, it's a `String` path.
  /// Currently checks for the existence of a subdirectory named "presets".
  static Future<bool> isValidDistingSdCard(dynamic pathOrDocumentFile) async {
    try {
      if (pathOrDocumentFile == null) return false;

      if (pathOrDocumentFile is docman.DocumentFile) {
        // Android SAF path
        // Check if a "presets" directory exists within the selected DocumentFile
        final presetsDirDocFile = await pathOrDocumentFile.find('presets');
        return presetsDirDocFile != null && presetsDirDocFile.isDirectory;
      } else if (pathOrDocumentFile is String) {
        // Desktop/other platform path
        final presetsPath = p.join(pathOrDocumentFile, 'presets');
        final presetsDir = Directory(presetsPath);
        return await presetsDir.exists();
      }
      return false;
    } catch (e) {
      debugPrint('Error validating Disting SD card: $e');
      return false;
    }
  }

  // Helper for recursive listing with DocMan
  static Future<void> _findPresetFilesRecursiveDocman(
    docman.DocumentFile directory, // This is a DocumentFile
    List<String> presetFiles,
  ) async {
    try {
      final List<docman.DocumentFile> documents =
          await directory.listDocuments();
      for (final doc in documents) {
        if (doc.isFile &&
            doc.name != null &&
            doc.name!.toLowerCase().endsWith('.json')) {
          presetFiles.add(doc.uri.toString());
        }
        if (doc.isDirectory) {
          await _findPresetFilesRecursiveDocman(doc, presetFiles);
        }
      }
    } catch (e) {
      debugPrint('Error during recursive DocMan scan in ${directory.name}: $e');
    }
  }

  /// Recursively finds all .json files within the given directory.
  ///
  /// For Android, `presetsDirIdentifier` is expected to be a `docman.DocumentFile` representing the 'presets' directory.
  /// For other platforms, it's a `String` path to the 'presets' directory.
  /// Returns a list of full file paths (or URIs for Android) for all files ending with '.json'.
  static Future<List<String>> findPresetFiles(
      dynamic presetsDirIdentifier) async {
    final List<String> presetFiles = [];

    if (presetsDirIdentifier == null) {
      debugPrint('Presets directory identifier is null.');
      return presetFiles;
    }

    try {
      if (presetsDirIdentifier is docman.DocumentFile) {
        // Android SAF path (DocumentFile for 'presets' dir)
        if (!presetsDirIdentifier.isDirectory) {
          debugPrint(
              'Provided DocumentFile is not a directory: ${presetsDirIdentifier.name}');
          return presetFiles;
        }
        await _findPresetFilesRecursiveDocman(
            presetsDirIdentifier, presetFiles);
      } else if (presetsDirIdentifier is String) {
        // Desktop/other platform path
        final directory = Directory(presetsDirIdentifier);
        if (!await directory.exists()) {
          debugPrint('Presets directory not found: $presetsDirIdentifier');
          return presetFiles;
        }
        await for (final entity
            in directory.list(recursive: true, followLinks: false)) {
          if (entity is File && entity.path.toLowerCase().endsWith('.json')) {
            presetFiles.add(entity.path);
          }
        }
      } else {
        debugPrint(
            'Unsupported type for presetsDirIdentifier: ${presetsDirIdentifier.runtimeType}');
        return presetFiles;
      }
    } catch (e) {
      debugPrint('Error scanning for preset files: $e');
      // Return any files found so far
    }
    return presetFiles;
  }
}
