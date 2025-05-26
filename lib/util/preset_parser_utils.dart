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
  /// Extracts top-level metadata and prepares for detailed slot parsing.
  /// Returns a [model.ParsedPresetData] object if successful, or `null` if an error occurs.
  static Future<model.ParsedPresetData?> parsePresetFile(String filePathOrUri,
      {String? sdCardRootPathOrUri}) async {
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

      String relativePathValue = fileNameToDisplay; // Default to just filename
      // Calculate relativePath based on the 'presets' directory.
      // This assumes filePathOrUri contains enough info to derive this.
      // For file paths, it's filePathOrUri relative to sdCardRootPathOrUri/presets.
      // For content URIs, this is trickier. The current structure in the BLoC passes
      // the file's direct URI. We need to ensure `ParsedPresetData.relativePath`
      // correctly reflects the path *within* the `presets` folder.

      // If sdCardRootPathOrUri is provided and filePathOrUri is a file path:
      if (sdCardRootPathOrUri != null &&
          !filePathOrUri.startsWith('content://') &&
          filePathOrUri.startsWith(sdCardRootPathOrUri)) {
        String pathRelativeToRoot =
            p.relative(filePathOrUri, from: sdCardRootPathOrUri);
        // We expect files to be in a subdirectory like 'presets/bank1/file.json'
        // So, if pathRelativeToRoot is 'presets/bank1/file.json', we want 'bank1/file.json'
        if (pathRelativeToRoot.startsWith(p.join('presets', ''))) {
          relativePathValue = p.relative(pathRelativeToRoot, from: 'presets');
        } else {
          // Fallback or error: file is not in a 'presets' subdirectory as expected from root
          relativePathValue = pathRelativeToRoot; // Or handle as an error/log
          debugPrint(
              "Warning: Preset file $filePathOrUri not in a 'presets' subdir relative to root $sdCardRootPathOrUri");
        }
      } else if (filePathOrUri.startsWith('content://')) {
        // For content URIs, determining relative path to a virtual 'presets' folder is complex
        // without more context about the URI structure from DocMan or how the picker was used.
        // The filename is often the best we can get easily unless DocMan provides parent info.
        // The BLoC logic aims to get the file identifier (URI) from FileSystemUtils.findPresetFiles,
        // which itself gets it from DocMan's DocumentFile.uri.
        // For now, ParsedPresetData.fileName will hold the name, and absolutePathAtScanTime the URI.
        // The relativePath might need to be reconstructed differently or stored if DocMan can provide it.
        // For Disting, presets are often like: presets/BankA/01_MyPreset.json
        // The URI might not directly reflect this structure easily for p.relative.
        // We rely on the filename for now for `relativePathValue` in this case.
        // A more robust solution might involve storing the display path from SAF picker if it has relative structure.
        String? docManName;
        if (!kIsWeb && Platform.isAndroid) {
          try {
            final tempDoc = await docman.DocumentFile.fromUri(filePathOrUri);
            docManName = tempDoc?.name;
          } catch (_) {}
        }
        relativePathValue = docManName ?? p.basename(filePathOrUri);
      }

      return model.ParsedPresetData(
        relativePath:
            relativePathValue, // This is now more carefully considered
        fileName:
            fileNameToDisplay, // This is the actual file name, e.g., "01_MyPreset.json"
        absolutePathAtScanTime: filePathOrUri, // Store the full path or URI
        algorithmName: jsonPresetName.trim(),
        notes: descriptionLines,
        otherMetadataJson: fileContent, // Store the raw JSON content
      );
    } catch (e, s) {
      debugPrint(
          'Error during data extraction from preset JSON ($fileNameToDisplay): $e\nStackTrace: $s');
      return null;
    }
  }
}
