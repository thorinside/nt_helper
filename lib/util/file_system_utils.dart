import 'dart:io'; // Required for Directory, FileSystemEntity, and Platform
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p; // For joining paths
import 'package:flutter/foundation.dart'
    show kIsWeb; // To check for web platform and for debug prints
import 'package:flutter/services.dart'; // Added for PlatformException
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
    InAppLogger().log(
        "pickSdCardRootDirectory called (targeting SD Card ROOT directory)");
    if (kIsWeb) {
      InAppLogger().log("Web platform not supported for directory picking.");
      return null;
    }

    if (Platform.isIOS) {
      InAppLogger()
          .log("iOS: Picking SD Card ROOT directory with IosFileAccessService");
      try {
        final String? path =
            await _iosFileAccessService.pickDirectoryAndCreateBookmark();
        if (path != null) {
          InAppLogger().log(
              "iOS: Picked and bookmarked SD Card ROOT directory path: $path");
        } else {
          InAppLogger()
              .log("iOS: SD Card ROOT directory picking cancelled or failed.");
        }
        return path;
      } catch (e) {
        InAppLogger().log("Error picking SD Card ROOT directory on iOS: $e");
        return null;
      }
    } else if (Platform.isAndroid) {
      try {
        InAppLogger()
            .log("Android: Picking SD Card ROOT directory with docman");
        final docman.DocumentFile? directory =
            await docman.DocMan.pick.directory();
        if (directory != null) {
          InAppLogger().log(
              "Android: Picked SD Card ROOT directory: ${directory.uri}, name: ${directory.name}");
          return directory;
        } else {
          InAppLogger().log(
              "Android: SD Card ROOT directory picking cancelled or failed.");
          return null;
        }
      } catch (e) {
        InAppLogger()
            .log("Error picking SD Card ROOT directory on Android: $e");
        return null;
      }
    }
    // For Desktop (macOS, Windows, Linux)
    InAppLogger()
        .log("Desktop: Picking SD Card ROOT directory with FilePicker");
    try {
      final String? directoryPath = await FilePicker.platform.getDirectoryPath(
        dialogTitle:
            'Please select the SD Card Root Directory', // Changed title
      );
      if (directoryPath != null) {
        InAppLogger()
            .log("Desktop: Picked SD Card ROOT directory path: $directoryPath");
      } else {
        InAppLogger().log(
            "Desktop: SD Card ROOT directory picking cancelled or failed (directoryPath is null).");
      }
      return directoryPath;
    } on PlatformException catch (pe) {
      InAppLogger().log(
          "Desktop: PlatformException picking SD Card ROOT directory: ${pe.code} - ${pe.message} - ${pe.details}");
      return null;
    } catch (e, s) {
      InAppLogger()
          .log("Desktop: Generic error picking SD Card ROOT directory: $e\n$s");
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

  /// Checks if the combination of SD card root and relative presets path points to a valid presets directory.
  ///
  /// For Android, `sdCardRootIdentifier` is a `docman.DocumentFile` (root), `relativePresetsPath` is String.
  /// For other platforms, both are `String` paths.
  /// For iOS, `sessionId` MUST be provided and non-null.
  static Future<bool> isValidDistingSdCard(
      dynamic sdCardRootIdentifier, String relativePresetsPath,
      {String? sessionId}) async {
    InAppLogger().log(
        "isValidDistingSdCard: root=${sdCardRootIdentifier.runtimeType}, relPath='$relativePresetsPath', iOS_sessionId='$sessionId'");

    if (sdCardRootIdentifier == null || relativePresetsPath.isEmpty) {
      InAppLogger().log(
          "isValidDistingSdCard: Root identifier is null or relativePresetsPath is empty. Invalid.");
      return false;
    }

    if (!kIsWeb && Platform.isIOS) {
      final logger = InAppLogger();
      if (sessionId == null) {
        logger.log(
            "iOS: isValidDistingSdCard - CRITICAL: sessionId is null. This should not happen as BLoC manages the session.");
        return false; // Session ID is mandatory for iOS operations now
      }
      // sdCardRootIdentifier for iOS is the bookmarked path string, also used as initial sessionId by BLoC.
      // However, the actual listing should use the passed 'sessionId' for clarity and consistency.
      final String fullPresetsPath =
          p.join(sdCardRootIdentifier as String, relativePresetsPath);
      logger.log(
          "iOS: isValidDistingSdCard - Validating $fullPresetsPath in session $sessionId");
      try {
        final List<String>? presetsContents =
            await _iosFileAccessService.listDirectoryInSession(
                sessionId: sessionId, directoryPathToList: fullPresetsPath);
        final bool isValid = presetsContents != null;
        logger.log(
            "iOS: isValidDistingSdCard - Listing ${isValid ? "succeeded (count: ${presetsContents?.length})" : "failed (null list)"}. Valid directory: $isValid");
        return isValid;
      } catch (e) {
        logger.log(
            "iOS: isValidDistingSdCard - Error listing $fullPresetsPath in session $sessionId: $e");
        return false;
      }
    } else if (!kIsWeb &&
        Platform.isAndroid &&
        sdCardRootIdentifier is docman.DocumentFile) {
      // Android with SAF
      InAppLogger().log(
          "Android: Checking presets dir. Root: ${sdCardRootIdentifier.uri}, Relative: $relativePresetsPath");
      docman.DocumentFile? currentDoc = sdCardRootIdentifier;
      final pathSegments =
          relativePresetsPath.split('/').where((s) => s.isNotEmpty);

      for (final segment in pathSegments) {
        final nextDoc = await currentDoc?.find(segment);
        if (nextDoc == null || !nextDoc.isDirectory || !nextDoc.exists) {
          InAppLogger().log(
              "Android: Segment '$segment' not found or not a directory in path $relativePresetsPath from root ${sdCardRootIdentifier.uri}");
          return false;
        }
        currentDoc = nextDoc;
      }
      final bool canReadValue = currentDoc?.canRead ?? false;
      InAppLogger().log(
          "Android: Successfully navigated to ${currentDoc?.uri}. Valid: $canReadValue");
      return canReadValue;
    } else if (sdCardRootIdentifier is String) {
      // Desktop platforms
      final String fullPresetsPath =
          p.join(sdCardRootIdentifier, relativePresetsPath);
      InAppLogger()
          .log("Desktop: Constructed full presets path: $fullPresetsPath");
      final dir = Directory(fullPresetsPath);
      final bool exists = await dir.exists();
      InAppLogger().log(
          "Desktop: Presets directory $fullPresetsPath ${exists ? "exists" : "does not exist"}. Valid: $exists");
      return exists;
    }
    InAppLogger().log(
        "isValidDistingSdCard: Unhandled platform or invalid sdCardRootIdentifier type: ${sdCardRootIdentifier.runtimeType}");
    return false;
  }

  // Helper for recursive listing with DocMan
  static Future<void> _findPresetFilesRecursiveDocman(
      docman.DocumentFile directory,
      String currentRelativePathWithinPresets,
      List<String> presetFilesList,
      String conceptualPresetsFolderName) async {
    final documents = await directory.listDocuments();
    for (final doc in documents) {
      final String entryName = doc.name ?? 'unknown';

      if (doc.isDirectory) {
        String nextRelativePathWithinPresets;
        if (currentRelativePathWithinPresets.isEmpty) {
          nextRelativePathWithinPresets = entryName;
        } else {
          nextRelativePathWithinPresets =
              p.join(currentRelativePathWithinPresets, entryName);
        }
        InAppLogger().log(
            "Android (Recursive): Entering directory: $entryName, nextRelativePathWithinPresets: $nextRelativePathWithinPresets");
        await _findPresetFilesRecursiveDocman(
            doc,
            nextRelativePathWithinPresets,
            presetFilesList,
            conceptualPresetsFolderName);
      } else if (entryName.toLowerCase().endsWith('.json')) {
        InAppLogger().log(
            "Android (Recursive): Found JSON file: ${doc.uri}, Name: $entryName, currentRelativePath: $currentRelativePathWithinPresets");
        presetFilesList.add(doc.uri.toString());
      }
    }
  }

  // iOS recursive helper
  static Future<void> _findPresetFilesRecursiveIos(
    String sessionId,
    String currentDirectoryAbsolutePath,
    List<String> presetFileFullUris,
  ) async {
    final logger = InAppLogger();
    // logger.log("iOS Recursive: Listing $currentDirectoryAbsolutePath (session ID: $sessionId)");

    List<String>? entries;
    try {
      entries = await _iosFileAccessService.listDirectoryInSession(
          sessionId: sessionId,
          directoryPathToList: currentDirectoryAbsolutePath);
    } catch (e) {
      logger.log(
          "iOS Recursive: Error listing $currentDirectoryAbsolutePath in session $sessionId: $e");
      return;
    }

    if (entries == null) {
      logger.log(
          "iOS Recursive: Failed to list $currentDirectoryAbsolutePath in session $sessionId (null entries).");
      return;
    }

    // logger.log("iOS Recursive: Found ${entries.length} entries in $currentDirectoryAbsolutePath: $entries");

    for (final String entryNameWithPotentialSlash in entries) {
      final String entryAbsolutePath = p.join(
          currentDirectoryAbsolutePath,
          entryNameWithPotentialSlash.endsWith('/')
              ? entryNameWithPotentialSlash.substring(
                  0, entryNameWithPotentialSlash.length - 1)
              : entryNameWithPotentialSlash);

      if (entryNameWithPotentialSlash.endsWith('/')) {
        await _findPresetFilesRecursiveIos(
            sessionId, entryAbsolutePath, presetFileFullUris);
      } else if (entryNameWithPotentialSlash.toLowerCase().endsWith('.json')) {
        final fileUri = Uri.file(entryAbsolutePath);
        presetFileFullUris.add(fileUri.toString());
      }
    }
  }

  /// Recursively finds all .json files within the specified presets directory.
  ///
  /// `sdCardRootIdentifier` is the path/URI to the SD card root.
  /// `relativePresetsPath` is the path from the SD card root to the presets directory.
  /// For iOS, `sessionId` MUST be provided and non-null.
  /// Returns a list of full URI strings for all files ending with '.json'.
  static Future<List<String>> findPresetFiles(
      dynamic sdCardRootIdentifier, String relativePresetsPath,
      {String? sessionId}) async {
    InAppLogger().log(
        "findPresetFiles: root=${sdCardRootIdentifier.runtimeType}, relPath='$relativePresetsPath', iOS_sessionId='$sessionId'");
    final List<String> presetFiles = [];

    if (sdCardRootIdentifier == null || relativePresetsPath.isEmpty) {
      InAppLogger().log(
          "findPresetFiles: Root identifier or relativePresetsPath is empty. Returning empty list.");
      return presetFiles;
    }

    if (!kIsWeb && Platform.isIOS) {
      final logger = InAppLogger();
      if (sessionId == null) {
        logger.log(
            "iOS: findPresetFiles - CRITICAL: sessionId is null. This should not happen.");
        return presetFiles; // Session ID is mandatory
      }
      // sdCardRootIdentifier for iOS is the bookmarked path string.
      final String fullPresetsPath =
          p.join(sdCardRootIdentifier as String, relativePresetsPath);
      logger.log(
          "iOS: findPresetFiles - Searching in $fullPresetsPath within session $sessionId");
      try {
        await _findPresetFilesRecursiveIos(
            sessionId, fullPresetsPath, presetFiles);
      } catch (e) {
        logger.log(
            "iOS: findPresetFiles - Error during recursive find for session $sessionId: $e");
      }
      logger.log(
          "findPresetFiles (iOS): Completed search. Found ${presetFiles.length} files.");
      return presetFiles;
    } else if (!kIsWeb &&
        Platform.isAndroid &&
        sdCardRootIdentifier is docman.DocumentFile) {
      // Android with SAF
      InAppLogger().log(
          "Android: Finding presets. Root: ${sdCardRootIdentifier.uri}, Relative: $relativePresetsPath");
      docman.DocumentFile? presetsDocFileDir = sdCardRootIdentifier;
      final pathSegments =
          relativePresetsPath.split('/').where((s) => s.isNotEmpty);
      for (final segment in pathSegments) {
        final nextDoc = await presetsDocFileDir?.find(segment);
        if (nextDoc == null || !nextDoc.isDirectory || !nextDoc.exists) {
          InAppLogger().log(
              "Android: Segment '$segment' for presets path not found. Root: ${sdCardRootIdentifier.uri}, Relative: $relativePresetsPath");
          return presetFiles;
        }
        presetsDocFileDir = nextDoc;
      }

      if (presetsDocFileDir != null &&
          presetsDocFileDir.exists &&
          presetsDocFileDir.isDirectory) {
        await _findPresetFilesRecursiveDocman(
            presetsDocFileDir,
            '',
            presetFiles,
            p.basename(relativePresetsPath.replaceAll(RegExp(r'/$'), '')));
      } else {
        InAppLogger().log(
            "Android: Final presets directory DocumentFile not found at $relativePresetsPath from ${sdCardRootIdentifier.uri}");
      }
    } else if (sdCardRootIdentifier is String) {
      // Desktop platforms
      InAppLogger().log(
          "Desktop: Finding preset files in directory: ${p.join(sdCardRootIdentifier, relativePresetsPath)}");
      final directory =
          Directory(p.join(sdCardRootIdentifier, relativePresetsPath));
      if (await directory.exists()) {
        final files = directory.list(recursive: true, followLinks: false);
        await for (final FileSystemEntity entity in files) {
          if (entity is File && entity.path.toLowerCase().endsWith('.json')) {
            presetFiles.add(entity.uri.toString());
          }
        }
      } else {
        InAppLogger().log(
            "Desktop: Presets directory does not exist at ${directory.path}");
      }
    }
    InAppLogger().log(
        "findPresetFiles finished. Found ${presetFiles.length} preset files from ${sdCardRootIdentifier.runtimeType} root / relative $relativePresetsPath.");
    return presetFiles;
  }

  /// Reads the content of a file given its URI or full path.
  /// For iOS, `sdCardRootIdentifier` is the bookmarked path, which is used as the `sessionId`. The other iOS-specific params are not used.
  static Future<Uint8List?> readFileBytes(String fileUriOrFullPath,
      {String?
          sdCardRootIdentifier, // Used for iOS, this is the bookmarked root path (session ID)
      String? relativePresetsPath, // NO LONGER USED FOR iOS in this function
      String?
          knownRelativePathFromPresetsDir // NO LONGER USED FOR iOS in this function
      }) async {
    final logger = InAppLogger();
    // logger.log('readFileBytes called for: $fileUriOrFullPath, iOS session ID (from sdCardRootIdentifier): $sdCardRootIdentifier'); // Simplified log

    if (!kIsWeb && Platform.isIOS) {
      if (sdCardRootIdentifier == null) {
        logger.log(
            "iOS: readFileBytes - CRITICAL: sdCardRootIdentifier (sessionId) is null. Cannot proceed.");
        return null;
      }
      final String sessionId = sdCardRootIdentifier;
      final String absoluteFilePathToRead = fileUriOrFullPath;
      // logger.log("iOS: Reading file $absoluteFilePathToRead in session $sessionId");
      try {
        final Uint8List? fileData =
            await _iosFileAccessService.readFileInSession(
                sessionId: sessionId, filePathToRead: absoluteFilePathToRead);
        return fileData;
      } catch (e) {
        logger.log(
            "iOS: Error reading file $absoluteFilePathToRead in session $sessionId: $e");
        return null;
      }
    } else if (!kIsWeb &&
        Platform.isAndroid &&
        fileUriOrFullPath.startsWith('content://')) {
      // Android SAF
      try {
        final docFile = await docman.DocumentFile.fromUri(fileUriOrFullPath);
        if (docFile == null || !docFile.exists || !docFile.isFile) {
          logger.log(
              "Android: File not found or not a file (SAF): $fileUriOrFullPath");
          return null;
        }
        return await docFile.read();
      } catch (e) {
        logger.log("Android: Error reading file (SAF) $fileUriOrFullPath: $e");
        return null;
      }
    } else {
      // Desktop platforms or fallback if fileUriOrFullPath is a file:// URI
      try {
        Uri uri = Uri.parse(fileUriOrFullPath);
        if (!uri.isScheme('file')) {
          // Ensure it's a file URI for dart:io
          logger.log(
              "Desktop/Fallback: readFileBytes - Not a file URI, cannot read with dart:io: $fileUriOrFullPath");
          return null;
        }
        final file = File(uri.toFilePath());
        if (!await file.exists()) {
          logger.log(
              "Desktop/Fallback: File not found by dart:io: ${uri.toFilePath()}");
          return null;
        }
        return await file.readAsBytes();
      } catch (e) {
        logger
            .log("Desktop/Fallback: Error reading file $fileUriOrFullPath: $e");
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
    return fileIdentifier; // For file:// URIs, the full path is usually fine or can be basenamed by caller
  }
}
