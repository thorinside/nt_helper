import 'dart:convert';
import 'dart:io';
import 'dart:typed_data'; // Import for Uint8List
import 'package:nt_helper/models/parsed_preset_data.dart'
    as model; // Import model with alias
import 'package:path/path.dart' as p; // For p.basename
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
// Import for docman if on Android
import 'package:docman/docman.dart' as docman;
import 'package:nt_helper/util/in_app_logger.dart'; // Added for InAppLogger

class PresetParserUtils {
  /// Parses a Disting NT preset JSON file from the given [filePathOrUri].
  ///
  /// [sdCardRootPathOrUri] is the path or URI of the SD card's root directory.
  /// Extracts top-level metadata and prepares for detailed slot parsing.
  /// Returns a [model.ParsedPresetData] object if successful, or `null` if an error occurs.
  static Future<model.ParsedPresetData?> parsePresetFile(String filePathOrUri,
      {String? sdCardRootPathOrUri}) async {
    // Entry logs
    print("--- PresetParserUtils.parsePresetFile --- ENTRY ---");
    InAppLogger().log("--- PresetParserUtils.parsePresetFile --- ENTRY ---");

    final logger = InAppLogger();
    logger.log(
        'parsePresetFile args: URI: $filePathOrUri, sdCardRoot: $sdCardRootPathOrUri');

    String fileContent;
    Map<String, dynamic> jsonData;
    String fileNameToDisplay; // Will be set below

    // Determine fileNameToDisplay early, before potential errors in reading
    if (!kIsWeb &&
        Platform.isAndroid &&
        filePathOrUri.startsWith('content://')) {
      try {
        final docFileForName = await docman.DocumentFile.fromUri(filePathOrUri);
        fileNameToDisplay = docFileForName?.name ?? p.basename(filePathOrUri);
      } catch (_) {
        fileNameToDisplay = p.basename(filePathOrUri); // Fallback
      }
    } else if (!kIsWeb &&
        Platform.isIOS &&
        filePathOrUri.startsWith('file://')) {
      try {
        Uri uri = Uri.parse(filePathOrUri);
        fileNameToDisplay = p.basename(uri.toFilePath());
      } catch (_) {
        fileNameToDisplay = p.basename(filePathOrUri); // Fallback
      }
    } else {
      fileNameToDisplay = p.basename(filePathOrUri);
    }
    logger.log('Determined fileNameToDisplay: $fileNameToDisplay');

    try {
      if (!kIsWeb &&
          Platform.isAndroid &&
          filePathOrUri.startsWith('content://')) {
        final docFile = await docman.DocumentFile.fromUri(filePathOrUri);
        if (docFile == null || !docFile.exists || !docFile.isFile) {
          debugPrint(
              'DocMan: File not found or not a file: $filePathOrUri (exists: ${docFile?.exists}, isFile: ${docFile?.isFile})');
          logger.log('DocMan: File not found or not a file for $filePathOrUri');
          return null;
        }
        // fileNameToDisplay already set
        final Uint8List? bytes = await docFile.read();
        if (bytes == null) {
          debugPrint('DocMan: Failed to read bytes from $filePathOrUri');
          logger.log('DocMan: Failed to read bytes from $filePathOrUri');
          return null;
        }
        fileContent = utf8.decode(bytes);
      } else if (!kIsWeb &&
          (Platform.isIOS ||
              Platform.isMacOS ||
              Platform.isLinux ||
              Platform.isWindows)) {
        // Desktop and iOS use file paths (potentially from file:// URIs)
        Uri uri = Uri.parse(filePathOrUri); // filePathOrUri is a file:/// URI
        final file = File(uri.toFilePath());
        if (!await file.exists()) {
          debugPrint('File not found: ${file.path}');
          logger.log('File not found: ${file.path}');
          return null;
        }
        // fileNameToDisplay already set
        fileContent = await file.readAsString();
      } else {
        // Fallback for web or other unexpected scenarios
        debugPrint(
            'Unsupported platform or URI scheme for file reading: $filePathOrUri');
        logger.log(
            'Unsupported platform or URI scheme for file reading: $filePathOrUri');
        return null; // Or handle web if it becomes a requirement
      }
    } on FileSystemException catch (e) {
      debugPrint(
          'FileSystemException while reading file $fileNameToDisplay: ${e.message} (OS Error: ${e.osError?.message})');
      logger.log('FileSystemException for $fileNameToDisplay: ${e.message}');
      return null;
    } catch (e, s) {
      debugPrint('Unexpected error reading file $fileNameToDisplay: $e\\n$s');
      logger.log('Unexpected error reading file $fileNameToDisplay: $e\\n$s');
      return null;
    }

    try {
      jsonData = jsonDecode(fileContent) as Map<String, dynamic>;
    } on FormatException catch (e) {
      debugPrint(
          'Error parsing JSON from $fileNameToDisplay (FormatException): ${e.message}');
      logger.log(
          'Error parsing JSON from $fileNameToDisplay (FormatException): ${e.message}');
      return null;
    } catch (e, s) {
      debugPrint(
          'Unexpected error parsing JSON from $fileNameToDisplay: $e\\n$s');
      logger.log(
          'Unexpected error parsing JSON from $fileNameToDisplay: $e\\n$s');
      return null;
    }

    try {
      final String jsonPresetName =
          jsonData['name'] as String? ?? 'Unnamed Preset';

      String? descriptionLines;
      final dynamic slotsRaw = jsonData['slots'];
      if (slotsRaw is List<dynamic>) {
        for (var slotData in slotsRaw) {
          if (slotData is Map<String, dynamic> && slotData['guid'] == 'note') {
            final dynamic linesRaw = slotData['lines'];
            if (linesRaw is List<dynamic>) {
              final lines = linesRaw
                  .map((line) => line.toString().trim())
                  .where((line) => line.isNotEmpty)
                  .toList();
              if (lines.isNotEmpty) {
                descriptionLines = lines.join('\\n');
              }
            }
            if (descriptionLines != null) break;
          }
        }
      }

      String relativePathValue;

      if (sdCardRootPathOrUri == null || sdCardRootPathOrUri.isEmpty) {
        logger.log(
            "Warning: sdCardRootPathOrUri is null or empty. Using filename as relativePath.");
        relativePathValue = fileNameToDisplay;
      } else {
        if (!kIsWeb &&
            Platform.isAndroid &&
            sdCardRootPathOrUri.startsWith('content://') &&
            filePathOrUri.startsWith('content://')) {
          // Android with content URIs
          Uri fileUri = Uri.parse(filePathOrUri);
          // We try to find "presets/" in the file URI path segments
          // This is often more reliable than trying to subtract opaque content URI paths.
          List<String> fileSegments = fileUri.pathSegments;
          int presetsIndex = -1;
          // Iterate through segments to find the "presets" directory robustly
          // Segments can be like: tree, PRIMARY%3AMyFiles, document, PRIMARY%3AMyFiles%2Fpresets%2FUser%2FMyPreset.json
          // Or sometimes more direct like: ... msf:presets, User, MyPreset.json
          for (int i = 0; i < fileSegments.length; i++) {
            // Decode segment before comparison as it might be URL encoded e.g. PRIMARY%3AMyFiles%2Fpresets
            String decodedSegment = Uri.decodeComponent(fileSegments[i]);
            // Check if the decoded segment contains 'presets' or ends with 'presets'
            // This handles cases like "MyFiles/presets" or just "presets"
            if (decodedSegment.toLowerCase().contains('presets')) {
              // More robustly, check if this segment *ends* with presets or is 'presets'
              // or if splitting by '/' gives 'presets' as the last part.
              var parts = decodedSegment.split('/');
              if (parts.last.toLowerCase() == 'presets') {
                presetsIndex = i;
                break;
              }
            }
          }

          if (presetsIndex != -1 && presetsIndex + 1 < fileSegments.length) {
            relativePathValue =
                p.joinAll(fileSegments.sublist(presetsIndex + 1));
            logger.log(
                "Android content URI - Extracted relative path from segments: $relativePathValue");
          } else {
            // If "presets" segment not found clearly, check if the entire path after host somehow contains presets/...
            String fullPathPart = fileUri
                .path; // e.g. /tree/PRIMARY%3AMusic%2Fpresets%2FUser%2FMyPreset.json/document/PRIMARY%3AMusic%2Fpresets%2FUser%2FMyPreset.json
            int presetsInFullPathIndex =
                fullPathPart.toLowerCase().indexOf("/presets/");
            if (presetsInFullPathIndex != -1) {
              relativePathValue = Uri.decodeComponent(fullPathPart
                  .substring(presetsInFullPathIndex + "/presets/".length));
              logger.log(
                  "Android content URI - Extracted relative path from full path part: $relativePathValue");
            } else {
              logger.log(
                  "Warning: Android could not determine relative path from content URIs using segments or full path. Root: $sdCardRootPathOrUri, File: $filePathOrUri. Using filename as fallback: $fileNameToDisplay");
              relativePathValue = fileNameToDisplay;
            }
          }
        } else if ((!kIsWeb &&
                (Platform.isIOS ||
                    Platform.isMacOS ||
                    Platform.isLinux ||
                    Platform.isWindows)) &&
            sdCardRootPathOrUri.startsWith('file://') &&
            filePathOrUri.startsWith('file://')) {
          // iOS, Desktop with file URIs
          Uri rootUri = Uri.parse(sdCardRootPathOrUri);
          Uri fileUri = Uri.parse(filePathOrUri);

          String rootPath = rootUri.toFilePath();
          String filePath = fileUri.toFilePath();

          // Ensure rootPath ends with a separator for correct p.join
          String normalizedRootPath = rootPath.endsWith(p.separator)
              ? rootPath
              : rootPath + p.separator;
          String presetsDirInRoot = p.join(normalizedRootPath, 'presets');

          logger.log(
              "File URI - rootPath: $rootPath, filePath: $filePath, presetsDirInRoot: $presetsDirInRoot");

          if (filePath
              .toLowerCase()
              .startsWith(presetsDirInRoot.toLowerCase())) {
            // p.relative can be case-sensitive on some platforms, ensure consistency or handle it.
            // Here, we're making presetsDirInRoot lowercase for the startWith check,
            // but p.relative will use the original casing from presetsDirInRoot.
            relativePathValue = p.relative(filePath, from: presetsDirInRoot);
          } else {
            logger.log(
                "Warning: File path $filePath not in 'presets' subdir ($presetsDirInRoot) relative to root $rootPath. Using filename.");
            relativePathValue = fileNameToDisplay;
          }
        } else {
          logger.log(
              "Warning: Unhandled URI scheme or platform for relative path calculation. Root: $sdCardRootPathOrUri, File: $filePathOrUri. Using filename.");
          relativePathValue = fileNameToDisplay;
        }
      }

      // Normalize slashes for consistency
      relativePathValue = p.normalize(relativePathValue);
      logger.log("Calculated relativePathValue: $relativePathValue");

      return model.ParsedPresetData(
        relativePath: relativePathValue,
        fileName: fileNameToDisplay,
        absolutePathAtScanTime: filePathOrUri, // This is the full URI
        algorithmName: jsonPresetName.trim(),
        notes: descriptionLines,
        otherMetadataJson: fileContent,
      );
    } catch (e, s) {
      debugPrint(
          'Error during data extraction from preset JSON ($fileNameToDisplay): $e\\nStackTrace: $s');
      logger.log(
          'Error during data extraction from preset JSON ($fileNameToDisplay): $e\\n$s');
      return null;
    }
  }
}
