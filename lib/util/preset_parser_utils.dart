import 'dart:convert';
import 'dart:io';
import 'package:nt_helper/models/parsed_preset_data.dart'
    as model; // Import model with alias
import 'package:path/path.dart' as p; // For p.basename

class PresetParserUtils {
  /// Parses a Disting NT preset JSON file from the given [filePath].
  ///
  /// Extracts top-level metadata and prepares for detailed slot parsing.
  /// Returns a [model.ParsedPresetData] object if successful, or `null` if an error occurs.
  static Future<model.ParsedPresetData?> parsePresetFile(String filePath,
      {String? sdCardRootPath}) async {
    String fileContent;
    Map<String, dynamic> jsonData;

    try {
      final file = File(filePath);
      if (!await file.exists()) {
        print('File not found: $filePath');
        return null;
      }
      fileContent = await file.readAsString();
    } on FileSystemException catch (e) {
      print(
          'FileSystemException while reading file $filePath: ${e.message} (OS Error: ${e.osError?.message})');
      return null;
    } catch (e) {
      print('Unexpected error reading file $filePath: $e');
      return null;
    }

    try {
      jsonData = jsonDecode(fileContent) as Map<String, dynamic>;
    } on FormatException catch (e) {
      print(
          'Error parsing JSON from $filePath (FormatException): ${e.message}');
      return null;
    } catch (e) {
      print('Unexpected error parsing JSON from $filePath: $e');
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

      String relativePathValue = filePath;
      if (sdCardRootPath != null && filePath.startsWith(sdCardRootPath)) {
        relativePathValue = p.relative(filePath, from: sdCardRootPath);
      }

      return model.ParsedPresetData(
        relativePath: relativePathValue,
        fileName: p.basename(filePath),
        absolutePathAtScanTime: filePath,
        algorithmName: jsonPresetName.trim(),
        notes: descriptionLines,
        otherMetadataJson: fileContent,
      );
    } catch (e, s) {
      print(
          'Error during data extraction from preset JSON ($filePath): $e\nStackTrace: $s');
      return null;
    }
  }
}
