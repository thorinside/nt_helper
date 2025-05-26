import 'dart:convert';
import 'dart:io';
import 'dart:typed_data'; // Import for Uint8List
import 'package:nt_helper/models/parsed_preset_data.dart'
    as model; // Import model with alias
import 'package:path/path.dart' as p; // For p.basename
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
// Import for docman if on Android
import 'package:docman/docman.dart' as docman;

class PresetParserUtils {
  /// Parses a Disting NT preset JSON file from the given [filePathOrUri].
  ///
  /// [sdCardRootPathOrUri] is the path or URI of the SD card's root directory.
  /// [knownRelativePath] is the pre-calculated relative path of the file
  /// with respect to the 'presets' directory, especially for Android URIs.
  /// Extracts top-level metadata and prepares for detailed slot parsing.
  /// Returns a [model.ParsedPresetData] object if successful, or `null` if an error occurs.
  static Future<model.ParsedPresetData?> parsePresetFile(String filePathOrUri,
      {String? sdCardRootPathOrUri, String? knownRelativePath}) async {
    String fileContent;
    Map<String, dynamic> jsonData;
    String fileNameToDisplay = p.basename(filePathOrUri);

    try {
      if (!kIsWeb &&
          Platform.isAndroid &&
          filePathOrUri.startsWith('content://')) {
        final docFile = await docman.DocumentFile.fromUri(filePathOrUri);
        if (docFile == null || !docFile.exists || !docFile.isFile) {
          debugPrint(
              'DocMan: File not found or not a file: $filePathOrUri (exists: ${docFile?.exists}, isFile: ${docFile?.isFile})');
          return null;
        }
        fileNameToDisplay = docFile.name ?? fileNameToDisplay;
        final Uint8List? bytes = await docFile.read();
        if (bytes == null) {
          debugPrint('DocMan: Failed to read bytes from $filePathOrUri');
          return null;
        }
        fileContent = utf8.decode(bytes);
      } else {
        final file = File(filePathOrUri);
        if (!await file.exists()) {
          debugPrint('File not found: $filePathOrUri');
          return null;
        }
        fileContent = await file.readAsString();
      }
    } on FileSystemException catch (e) {
      debugPrint(
          'FileSystemException while reading file $fileNameToDisplay: ${e.message} (OS Error: ${e.osError?.message})');
      return null;
    } catch (e) {
      debugPrint('Unexpected error reading file $fileNameToDisplay: $e');
      return null;
    }

    try {
      jsonData = jsonDecode(fileContent) as Map<String, dynamic>;
    } on FormatException catch (e) {
      debugPrint(
          'Error parsing JSON from $fileNameToDisplay (FormatException): ${e.message}');
      return null;
    } catch (e) {
      debugPrint('Unexpected error parsing JSON from $fileNameToDisplay: $e');
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
                descriptionLines = lines.join('\n');
              }
            }
            if (descriptionLines != null) break;
          }
        }
      }

      String relativePathValue;

      if (knownRelativePath != null && knownRelativePath.isNotEmpty) {
        // If knownRelativePath is provided (primarily for Android URIs), use it directly.
        // Ensure it's not an absolute path by mistake, though the scanning logic should ensure this.
        relativePathValue = knownRelativePath;
        // Make sure to normalize slashes for consistency if coming from mixed sources
        // Although p.join in FileSystemUtils should handle this for Android.
        // For desktop, p.relative already normalizes.
        relativePathValue = p.normalize(relativePathValue);
      } else if (sdCardRootPathOrUri != null &&
          !filePathOrUri.startsWith('content://') &&
          filePathOrUri.startsWith(sdCardRootPathOrUri)) {
        // Original logic for desktop/file paths if knownRelativePath is not given
        String pathRelativeToRoot =
            p.relative(filePathOrUri, from: sdCardRootPathOrUri);
        if (pathRelativeToRoot.startsWith(p.join('presets', ''))) {
          relativePathValue = p.relative(pathRelativeToRoot, from: 'presets');
        } else {
          relativePathValue = pathRelativeToRoot;
          debugPrint(
              "Warning: Preset file $filePathOrUri not in a 'presets' subdir relative to root $sdCardRootPathOrUri");
        }
      } else {
        // Fallback: if no knownRelativePath and not a clear desktop path structure,
        // default to the filename. This was the problematic part for Android before.
        // This branch should ideally not be hit for Android if scanning provides knownRelativePath.
        String? docManNameOnFallback;
        if (!kIsWeb &&
            Platform.isAndroid &&
            filePathOrUri.startsWith('content://')) {
          try {
            final tempDoc = await docman.DocumentFile.fromUri(filePathOrUri);
            docManNameOnFallback = tempDoc?.name;
          } catch (_) {}
        }
        relativePathValue = docManNameOnFallback ?? p.basename(filePathOrUri);
        debugPrint(
            "Warning: Using fallback relativePath (filename: $relativePathValue) for $filePathOrUri. knownRelativePath was not provided.");
      }

      return model.ParsedPresetData(
        relativePath: relativePathValue,
        fileName: fileNameToDisplay,
        absolutePathAtScanTime: filePathOrUri,
        algorithmName: jsonPresetName.trim(),
        notes: descriptionLines,
        otherMetadataJson: fileContent,
      );
    } catch (e, s) {
      debugPrint(
          'Error during data extraction from preset JSON ($fileNameToDisplay): $e\nStackTrace: $s');
      return null;
    }
  }
}
