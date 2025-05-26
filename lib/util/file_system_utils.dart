import 'dart:io'; // Required for Directory, FileSystemEntity, and Platform
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p; // For joining paths
import 'package:flutter/foundation.dart'
    show kIsWeb; // To check for web platform and for debug prints
import 'package:nt_helper/util/in_app_logger.dart'; // Added for InAppLogger
import 'package:security_scoped_resource/security_scoped_resource.dart'; // Added for iOS scoped access
import 'package:nt_helper/services/ios_file_access_service.dart'; // Import the new service

// Import for docman
import 'package:docman/docman.dart' as docman;

class FileSystemUtils {
  /// Static instance for iOS file access
  static final IosFileAccessService _iosFileAccessService =
      IosFileAccessService();

  /// Allows the user to pick a directory using the native file explorer.
  ///
  /// Returns the selected directory path as a [String] for non-Android platforms,
  /// or a [docman.DocumentFile] for Android if a directory is picked via SAF.
  /// Returns `null` if the user cancels the dialog.
  static Future<dynamic?> pickSdCardRootDirectory() async {
    InAppLogger().log("pickSdCardRootDirectory called");
    if (kIsWeb) {
      InAppLogger().log("Web platform not supported for SD card picking.");
      return null;
    }

    if (Platform.isAndroid) {
      try {
        InAppLogger().log("Android: Picking directory with docman");
        final docman.DocumentFile? directory =
            await docman.DocMan.pick.directory();
        if (directory != null) {
          InAppLogger().log(
              "Android: Picked directory: ${directory.uri}, name: ${directory.name}");
          InAppLogger().log(
              "Android: Directory picked. Assuming permission granted for URI: ${directory.uri}");
          return directory;
        } else {
          InAppLogger().log("Android: Directory picking cancelled or failed.");
          return null;
        }
      } catch (e) {
        InAppLogger().log("Error picking directory on Android: $e");
        return null;
      }
    } else if (Platform.isIOS) {
      InAppLogger().log("iOS: Picking directory with IosFileAccessService");
      try {
        final String? path =
            await _iosFileAccessService.pickDirectoryAndStoreBookmark();
        if (path != null) {
          InAppLogger().log("iOS: Picked and bookmarked directory path: $path");
        } else {
          InAppLogger().log("iOS: Directory picking cancelled or failed.");
        }
        return path;
      } catch (e) {
        InAppLogger().log("Error picking directory on iOS: $e");
        return null;
      }
    }
    InAppLogger().log("Desktop: Picking directory with FilePicker");
    try {
      final String? directoryPath = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Please select the SD card root directory',
      );
      if (directoryPath != null) {
        InAppLogger().log("Desktop: Picked directory path: $directoryPath");
      } else {
        InAppLogger().log("Desktop: Directory picking cancelled or failed.");
      }
      return directoryPath;
    } catch (e) {
      InAppLogger().log("Error picking directory on Desktop: $e");
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
  static Future<bool> isValidDistingSdCard(dynamic sdCardRootIdentifier) async {
    InAppLogger().log(
        "isValidDistingSdCard called with identifier: $sdCardRootIdentifier");
    if (sdCardRootIdentifier == null) {
      InAppLogger().log("SD card root identifier is null.");
      return false;
    }

    if (sdCardRootIdentifier is docman.DocumentFile) {
      InAppLogger().log(
          "Android: Checking for 'presets' directory in DocumentFile: ${sdCardRootIdentifier.uri}");
      final presetsDir = await sdCardRootIdentifier.find("presets");
      final bool isValid =
          presetsDir != null && presetsDir.isDirectory && presetsDir.exists;
      InAppLogger().log(
          "Android: 'presets' directory ${isValid ? "found" : "not found or not a directory"}.");
      return isValid;
    } else if (sdCardRootIdentifier is String) {
      if (Platform.isIOS) {
        InAppLogger().log(
            "iOS: Checking for 'presets' directory in bookmarked path: $sdCardRootIdentifier");
        final List<Map<String, String>>? files = await _iosFileAccessService
            .listBookmarkedDirectoryContents(sdCardRootIdentifier);
        if (files != null) {
          for (final fileEntry in files) {
            if (fileEntry['relativePath']?.startsWith('presets/') ?? false) {
              InAppLogger().log("iOS: Found 'presets/' in relative paths.");
              return true;
            }
          }
          InAppLogger().log("iOS: 'presets/' not found in relative paths.");
          return false;
        } else {
          InAppLogger().log(
              "iOS: Failed to list contents for checking 'presets' directory.");
          return false;
        }
      } else {
        final String sdCardPath = sdCardRootIdentifier;
        InAppLogger().log(
            "Desktop: Checking for 'presets' directory in path: $sdCardPath");
        final presetsDirPath = p.join(sdCardPath, 'presets');
        final bool isValid = await Directory(presetsDirPath).exists();
        InAppLogger().log(
            "Desktop: 'presets' directory ${isValid ? "found" : "not found"}. Path: $presetsDirPath");
        return isValid;
      }
    }
    InAppLogger().log(
        "Invalid sdCardRootIdentifier type: ${sdCardRootIdentifier.runtimeType}");
    return false;
  }

  // Helper for recursive listing with DocMan
  static Future<void> _findPresetFilesRecursiveDocman(
      docman.DocumentFile directory,
      String currentRelativePathWithinPresets,
      List<(String uri, String relativePath)> presetFilesList,
      String presetsFolderName) async {
    final documents = await directory.listDocuments();
    for (final doc in documents) {
      final String entryName = doc.name ?? 'unknown';
      String itemRelativePathWithinPresets;
      if (currentRelativePathWithinPresets.isEmpty) {
        itemRelativePathWithinPresets = entryName;
      } else {
        itemRelativePathWithinPresets =
            p.join(currentRelativePathWithinPresets, entryName);
      }

      if (doc.isDirectory) {
        InAppLogger().log(
            "Android (Recursive): Entering directory: $entryName, currentRelativePathWithinPresets: $itemRelativePathWithinPresets");
        await _findPresetFilesRecursiveDocman(doc,
            itemRelativePathWithinPresets, presetFilesList, presetsFolderName);
      } else if (entryName.toLowerCase().endsWith('.json')) {
        final String fullRelativePath =
            p.join(presetsFolderName, itemRelativePathWithinPresets);
        InAppLogger().log(
            "Android (Recursive): Found JSON file: ${doc.uri}, Name: $entryName, Full Relative Path: $fullRelativePath");
        presetFilesList.add((doc.uri.toString(), fullRelativePath));
      }
    }
  }

  /// Recursively finds all .json files within the given directory.
  ///
  /// For Android, `presetsDirIdentifier` is expected to be a `docman.DocumentFile` representing the 'presets' directory.
  /// For other platforms, it's a `String` path to the 'presets' directory.
  /// Returns a list of tuples (uri, relativePath) for all files ending with '.json'.
  static Future<List<(String uri, String relativePath)>> findPresetFiles(
      dynamic sdCardRootIdentifier, String presetsFolderName) async {
    InAppLogger().log(
        "findPresetFiles called with identifier: $sdCardRootIdentifier, presetsFolderName: $presetsFolderName");
    final List<(String uri, String relativePath)> presetFiles = [];

    if (sdCardRootIdentifier == null) {
      InAppLogger()
          .log("SD card root identifier is null. Returning empty list.");
      return presetFiles;
    }

    if (sdCardRootIdentifier is docman.DocumentFile) {
      InAppLogger().log(
          "Android: Finding preset files in DocumentFile: ${sdCardRootIdentifier.uri}");
      final presetsDocFileDir =
          await sdCardRootIdentifier.find(presetsFolderName);
      if (presetsDocFileDir != null &&
          presetsDocFileDir.exists &&
          presetsDocFileDir.isDirectory) {
        InAppLogger().log(
            "Android: Found '$presetsFolderName' directory. Starting recursive search.");
        await _findPresetFilesRecursiveDocman(
            presetsDocFileDir, '', presetFiles, presetsFolderName);
      } else {
        InAppLogger().log(
            "Android: '$presetsFolderName' directory not found or not a directory.");
      }
    } else if (sdCardRootIdentifier is String) {
      final String rootPath = sdCardRootIdentifier;
      if (Platform.isIOS) {
        InAppLogger()
            .log("iOS: Finding preset files in bookmarked path: $rootPath");
        final List<Map<String, String>>? allFiles = await _iosFileAccessService
            .listBookmarkedDirectoryContents(rootPath);
        if (allFiles != null) {
          for (final fileEntry in allFiles) {
            final String fileUri = fileEntry['uri']!;
            final String relativePath = fileEntry['relativePath']!;
            InAppLogger().log(
                "iOS: Found file URI: $fileUri, Relative path: $relativePath");
            if (relativePath.startsWith('$presetsFolderName/') &&
                relativePath.toLowerCase().endsWith('.json')) {
              InAppLogger()
                  .log("iOS: Added preset file: $relativePath (URI: $fileUri)");
              presetFiles.add((fileUri, relativePath));
            }
          }
        } else {
          InAppLogger().log("iOS: Failed to list files from bookmarked path.");
        }
      } else {
        InAppLogger().log("Desktop: Finding preset files in path: $rootPath");
        final presetsDirPath = p.join(rootPath, presetsFolderName);
        final directory = Directory(presetsDirPath);
        if (await directory.exists()) {
          InAppLogger().log(
              "Desktop: '$presetsFolderName' directory exists. Starting recursive search.");
          final files = directory.list(recursive: true, followLinks: false);
          await for (final FileSystemEntity entity in files) {
            if (entity is File && entity.path.toLowerCase().endsWith('.json')) {
              final relativePath = p.relative(entity.path, from: rootPath);
              InAppLogger().log(
                  "Desktop: Found file: ${entity.path}, Relative path: $relativePath");
              presetFiles.add((entity.uri.toString(), relativePath));
            }
          }
        } else {
          InAppLogger().log(
              "Desktop: '$presetsFolderName' directory does not exist at $presetsDirPath");
        }
      }
    }
    InAppLogger().log(
        "findPresetFiles finished. Found ${presetFiles.length} preset files.");
    return presetFiles;
  }

  static Future<Uint8List?> readFileBytes(
    String
        fileUriOrPath, // On Android, this is DocumentFile URI. On Desktop/iOS, it's a file path/URI.
    String? knownRelativePath, // Used by iOS
    String sdCardRootIdentifier, // Used by iOS (bookmarkedPath)
  ) async {
    InAppLogger().log(
        "readFileBytes called with fileUriOrPath: $fileUriOrPath, knownRelativePath: $knownRelativePath, sdCardRootIdentifier: $sdCardRootIdentifier");
    if (Platform.isAndroid) {
      if (fileUriOrPath.startsWith('content://')) {
        try {
          InAppLogger().log(
              "Android: Reading file from DocumentFile URI: $fileUriOrPath");
          // Assuming that if we have the fileUriOrPath (a content URI),
          // and it was derived from a previously picked root (sdCardRootIdentifier),
          // the permission is implicitly available. Explicit root permission checks were problematic.

          final docman.DocumentFile? docFile =
              await docman.DocumentFile.fromUri(
                  fileUriOrPath); // fileUriOrPath is already a String URI

          if (docFile != null && docFile.exists && docFile.isFile) {
            final Uint8List? bytes = await docFile.read();
            if (bytes != null) {
              InAppLogger().log(
                  "Android: Successfully read ${bytes.lengthInBytes} bytes.");
              return bytes;
            } else {
              InAppLogger().log(
                  "Android: docFile.read() returned null for $fileUriOrPath");
              return null;
            }
          } else {
            InAppLogger().log(
                "Android: File does not exist, is not a file, or DocumentFile.fromUri returned null for path: $fileUriOrPath");
            return null;
          }
        } catch (e) {
          InAppLogger().log("Android: Error reading DocumentFile: $e");
          return null;
        }
      } else {
        InAppLogger().log(
            "Android: fileUriOrPath is not a content URI: $fileUriOrPath. This indicates an issue with how URIs are passed.");
        return null;
      }
    } else if (Platform.isIOS) {
      if (knownRelativePath == null) {
        InAppLogger().log(
            "iOS: knownRelativePath is null. Cannot read file without it.");
        return null;
      }
      InAppLogger().log(
          "iOS: Reading file using IosFileAccessService. Bookmarked path: $sdCardRootIdentifier, Relative path: $knownRelativePath");
      try {
        final Uint8List? bytes = await _iosFileAccessService.readBookmarkedFile(
            sdCardRootIdentifier, knownRelativePath);
        if (bytes != null) {
          InAppLogger()
              .log("iOS: Successfully read ${bytes.lengthInBytes} bytes.");
        } else {
          InAppLogger().log("iOS: readBookmarkedFile returned null.");
        }
        return bytes;
      } catch (e) {
        InAppLogger()
            .log("iOS: Error reading file with IosFileAccessService: $e");
        return null;
      }
    } else {
      InAppLogger().log("Desktop: Reading file from path: $fileUriOrPath");
      try {
        // On desktop, fileUriOrPath is expected to be a direct file path.
        final file = File(fileUriOrPath);
        if (await file.exists()) {
          final Uint8List bytes = await file.readAsBytes();
          InAppLogger()
              .log("Desktop: Successfully read ${bytes.lengthInBytes} bytes.");
          return bytes;
        } else {
          InAppLogger()
              .log("Desktop: File does not exist at path: $fileUriOrPath");
          return null;
        }
      } catch (e) {
        InAppLogger().log("Desktop: Error reading file: $e");
        return null;
      }
    }
  }

  // Helper to convert file URL (content:// or file://) to a displayable name or path fragment
  static String getDisplayPath(String fileIdentifier) {
    if (fileIdentifier.startsWith('content://')) {
      try {
        final uri = Uri.parse(fileIdentifier);
        return uri.pathSegments.isNotEmpty
            ? uri.pathSegments.last
            : fileIdentifier;
      } catch (_) {
        return fileIdentifier;
      }
    }
    return fileIdentifier;
  }
}
