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
import 'package:nt_helper/util/file_system_utils.dart'; // Import FileSystemUtils

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

    String fileContent =
        ""; // Initialize to empty, might be populated if read succeeds
    Map<String, dynamic>?
        jsonData; // Initialize to null, populated if JSON parse succeeds
    String fileNameToDisplay; // Will be set below
    String relativePathValue; // Will be set below

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

    // Calculate relativePathValue early, as it only depends on paths
    if (sdCardRootPathOrUri == null || sdCardRootPathOrUri.isEmpty) {
      logger.log(
          "Warning: sdCardRootPathOrUri is null or empty. Using filename as relativePath.");
      relativePathValue = fileNameToDisplay;
    } else {
      // Common case: calculate path relative to the provided SD card root.
      if (!kIsWeb &&
          Platform.isAndroid &&
          sdCardRootPathOrUri.startsWith('content://') &&
          filePathOrUri.startsWith('content://')) {
        // Android Content URIs
        String rootUriStr = sdCardRootPathOrUri;
        String fileUriStr = filePathOrUri;
        if (rootUriStr.endsWith('/')) {
          rootUriStr = rootUriStr.substring(0, rootUriStr.length - 1);
        }
        Uri rootUri = Uri.parse(sdCardRootPathOrUri);
        Uri fileUri = Uri.parse(filePathOrUri);
        String fileUriDecodedPath = Uri.decodeComponent(fileUri.path);
        String rootUriDecodedPath = Uri.decodeComponent(rootUri.path);
        String fileRelevantPathPart = fileUriDecodedPath
            .substring(fileUriDecodedPath.indexOf('/', 1) + 1);
        String rootRelevantPathPart = rootUriDecodedPath
            .substring(rootUriDecodedPath.indexOf('/', 1) + 1);

        if (fileRelevantPathPart.startsWith(rootRelevantPathPart)) {
          relativePathValue =
              fileRelevantPathPart.substring(rootRelevantPathPart.length);
          if (relativePathValue.startsWith('/')) {
            relativePathValue = relativePathValue.substring(1);
          }
          if (relativePathValue.isEmpty) {
            logger.log(
                "Warning: Android relative path calculation resulted in empty string. Root: $sdCardRootPathOrUri, File: $filePathOrUri. Using filename $fileNameToDisplay as fallback.");
            relativePathValue = fileNameToDisplay;
          } else {
            logger.log(
                "Android Content URI - Calculated relative path: $relativePathValue (Root: $rootUriStr, File: $fileUriStr)");
          }
        } else {
          logger.log(
              "Warning: Android could not determine relative path. Root: $sdCardRootPathOrUri, File: $filePathOrUri. Root relevant part: $rootRelevantPathPart, File relevant part: $fileRelevantPathPart. Using filename $fileNameToDisplay as fallback.");
          relativePathValue = fileNameToDisplay;
        }
      } else if ((!kIsWeb &&
              (Platform.isIOS ||
                  Platform.isMacOS ||
                  Platform.isLinux ||
                  Platform.isWindows)) &&
          (sdCardRootPathOrUri.startsWith('file://') ||
              p.isAbsolute(sdCardRootPathOrUri)) &&
          (filePathOrUri.startsWith('file://') ||
              p.isAbsolute(filePathOrUri))) {
        String rootPath;
        String filePath;
        if (sdCardRootPathOrUri.startsWith('file://')) {
          rootPath = Uri.parse(sdCardRootPathOrUri).toFilePath();
        } else {
          rootPath = sdCardRootPathOrUri;
        }
        if (filePathOrUri.startsWith('file://')) {
          filePath = Uri.parse(filePathOrUri).toFilePath();
        } else {
          filePath = filePathOrUri;
        }
        rootPath = p.normalize(rootPath);
        filePath = p.normalize(filePath);
        logger.log(
            "File URI/Path - Normalized Root: $rootPath, Normalized File: $filePath");
        if (p.isWithin(rootPath, filePath)) {
          relativePathValue = p.relative(filePath, from: rootPath);
          logger.log(
              "File URI/Path - Calculated relative path: $relativePathValue");
        } else {
          logger.log(
              "Warning: File path $filePath is not within root path $rootPath. Using filename $fileNameToDisplay as fallback.");
          relativePathValue = fileNameToDisplay;
        }
      } else {
        logger.log(
            "Warning: Unhandled URI scheme, platform, or paths for relative path calculation. Root: $sdCardRootPathOrUri, File: $filePathOrUri. Using filename $fileNameToDisplay as fallback.");
        relativePathValue = fileNameToDisplay;
      }
    }
    relativePathValue = p.normalize(relativePathValue);
    logger.log("Early calculated relativePathValue: $relativePathValue");

    // Default values for metadata - used if parsing fails
    String algorithmNameToUse = fileNameToDisplay; // Fallback to filename
    String? notesToUse;
    String?
        otherMetadataJsonToUse; // Or consider: '{"error":"failed to parse"}';

    try {
      Uint8List? fileBytes;
      if (!kIsWeb && Platform.isIOS) {
        // *** FIX: Use FileSystemUtils.readFileBytes for iOS ***
        // sdCardRootPathOrUri is the session ID for iOS
        fileBytes = await FileSystemUtils.readFileBytes(filePathOrUri,
            sdCardRootIdentifier: sdCardRootPathOrUri);
      } else if (!kIsWeb &&
          Platform.isAndroid &&
          filePathOrUri.startsWith('content://')) {
        // Android SAF - Use FileSystemUtils.readFileBytes which handles docman
        fileBytes = await FileSystemUtils.readFileBytes(filePathOrUri);
      } else if (!kIsWeb) {
        // Desktop and other non-Android/iOS cases using dart:io
        fileBytes = await FileSystemUtils.readFileBytes(filePathOrUri);
      } else {
        // Web is not supported for file system access
        throw UnsupportedError("Unsupported platform for file reading: Web");
      }

      if (fileBytes == null) {
        throw FileSystemException("Failed to read file bytes", filePathOrUri);
      }
      fileContent = utf8.decode(fileBytes);

      // Attempt to parse JSON
      jsonData = jsonDecode(fileContent) as Map<String, dynamic>;

      // If JSON parsing was successful, try to extract detailed metadata
      final String? parsedJsonPresetName = jsonData['name'] as String?;
      if (parsedJsonPresetName != null &&
          parsedJsonPresetName.trim().isNotEmpty) {
        algorithmNameToUse = parsedJsonPresetName.trim();
      }

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
                notesToUse = lines.join('\\n');
              }
            }
            if (notesToUse != null) break;
          }
        }
      }
      // Use the full successfully read content as metadata if parsing was successful
      otherMetadataJsonToUse = fileContent;

      logger.log(
          "Successfully read and parsed JSON for $fileNameToDisplay. Algorithm: $algorithmNameToUse");
    } on FileSystemException catch (e) {
      logger.log(
          'FileSystemException for $fileNameToDisplay (while reading content): ${e.message}. Using fallback metadata.');
      // Fallback values are already set, fileContent will remain empty or be from a previous attempt if structured differently
      // For robustness, ensure otherMetadataJsonToUse is null if content reading failed for this specific preset.
      otherMetadataJsonToUse = null;
    } on FormatException catch (e) {
      logger.log(
          'FormatException for $fileNameToDisplay (while parsing JSON): ${e.message}. Using fallback metadata.');
      // Fallback values are already set
      otherMetadataJsonToUse =
          null; // Content was read but not valid JSON for this preset
    } catch (e, s) {
      logger.log(
          'Unexpected error processing file content for $fileNameToDisplay: $e\\n$s. Using fallback metadata.');
      otherMetadataJsonToUse = null; // General error
    }

    // Always return a ParsedPresetData object, using fallbacks if necessary
    logger.log(
        "Final relativePathValue for $fileNameToDisplay: $relativePathValue");
    return model.ParsedPresetData(
      relativePath: relativePathValue,
      fileName: fileNameToDisplay,
      absolutePathAtScanTime: filePathOrUri, // This is the full URI
      algorithmName: algorithmNameToUse, // Uses filename or parsed name
      notes: notesToUse, // Uses null or parsed notes
      otherMetadataJson:
          otherMetadataJsonToUse, // Uses null or full file content
    );
  }
}
