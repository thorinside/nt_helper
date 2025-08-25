import 'package:dart_elf/dart_elf.dart';
import 'package:flutter/foundation.dart';
import 'package:nt_helper/interfaces/preset_file_system.dart';

/// Exception thrown during GUID extraction
class GuidExtractionException implements Exception {
  final String message;
  const GuidExtractionException(this.message);

  @override
  String toString() => 'GuidExtractionException: $message';
}

/// Represents a plugin GUID extracted from an ELF file
class PluginGuid {
  final String guid;
  final int rawValue;

  const PluginGuid({required this.guid, required this.rawValue});

  /// Check if GUID contains at least one uppercase letter (community plugin)
  bool get isCommunityPlugin => guid.chars.any((c) => c.isUppercase);

  /// Check if GUID is all lowercase (factory/system algorithm)
  bool get isFactoryAlgorithm =>
      guid.chars.every((c) => c.isLowercase || !c.isLetter);

  @override
  String toString() =>
      'PluginGuid(guid: $guid, raw: 0x${rawValue.toRadixString(16).padLeft(8, '0').toUpperCase()})';
}

/// Service for extracting plugin GUIDs from ELF .o files
class ElfGuidExtractor {
  /// Convert a 32-bit integer to a 4-character GUID string
  /// This matches the NT_MULTICHAR macro: (a<<0) | (b<<8) | (c<<16) | (d<<24)
  static String _guidFromU32(int value) {
    final bytes = [
      (value & 0xFF),
      ((value >> 8) & 0xFF),
      ((value >> 16) & 0xFF),
      ((value >> 24) & 0xFF),
    ];

    // Convert bytes to ASCII characters, handling non-printable chars
    final chars = bytes.map((b) {
      if (b >= 32 && b <= 126) {
        // Printable ASCII range
        return String.fromCharCode(b);
      } else {
        return '?';
      }
    }).join();

    return chars;
  }

  /// Extract plugin GUID from ELF bytes
  static Future<PluginGuid> extractGuidFromBytes(
    Uint8List bytes,
    String fileName,
  ) async {
    try {
      // Parse the ELF file from bytes
      final reader = ElfReader.fromBytes(bytes);

      // Find the factory symbol
      // Look for either "_ZL7factory" (mangled) or "factory" (unmangled)
      ElfSymbol? factorySymbol;

      // Check symbol table section
      if (reader.symbolTableSection != null) {
        final symbolTable = reader.symbolTableSection!;
        final stringTable = reader.stringTable;

        for (final symbol in symbolTable.symbols) {
          final name = stringTable?.at(symbol.nindex) ?? '';
          if (name == '_ZL7factory' || name == 'factory') {
            factorySymbol = symbol;
            break;
          }
        }
      }

      // If not found in symbol table, check dynamic symbol table
      if (factorySymbol == null && reader.dynamicSymbolTableSection != null) {
        final dynamicSymbolTable = reader.dynamicSymbolTableSection!;
        final dynamicStringTable = reader.dynamicStringTable;

        for (final symbol in dynamicSymbolTable.symbols) {
          final name = dynamicStringTable?.at(symbol.nindex) ?? '';
          if (name == '_ZL7factory' || name == 'factory') {
            factorySymbol = symbol;
            break;
          }
        }
      }

      if (factorySymbol == null) {
        throw GuidExtractionException('Factory symbol not found in $fileName');
      }

      // Get the section containing the factory symbol
      final sectionIndex = factorySymbol.shndx;
      if (sectionIndex >= reader.sections.length) {
        throw GuidExtractionException(
          'Invalid section index for factory symbol',
        );
      }

      final section = reader.sections[sectionIndex];

      // Calculate offset within section
      final symbolAddress = factorySymbol.value;
      final sectionAddress = section.header.addr;

      if (symbolAddress < sectionAddress) {
        throw GuidExtractionException('Invalid factory symbol address');
      }

      final offset = (symbolAddress - sectionAddress).toInt();

      // Get section data
      final sectionData = section.data();

      // Ensure we have enough data for the GUID (first 4 bytes of the factory struct)
      if (offset + 4 > sectionData.length) {
        throw GuidExtractionException('Not enough data for GUID extraction');
      }

      // Extract the GUID as a 32-bit little-endian integer
      // The _NT_factory struct starts with: uint32_t guid;
      final guidBytes = sectionData.sublist(offset, offset + 4);
      final rawGuid = ByteData.sublistView(
        Uint8List.fromList(guidBytes),
      ).getUint32(0, Endian.little);

      // Convert to string representation
      final guidString = _guidFromU32(rawGuid);

      // Validate that we got a reasonable GUID (4 ASCII characters)
      if (guidString.length != 4) {
        throw GuidExtractionException(
          'GUID must be exactly 4 characters, got: $guidString',
        );
      }

      debugPrint('Extracted GUID "$guidString" from $fileName');

      return PluginGuid(guid: guidString, rawValue: rawGuid);
    } catch (e) {
      if (e is GuidExtractionException) rethrow;
      throw GuidExtractionException(
        'Failed to extract GUID from $fileName: $e',
      );
    }
  }

  /// Scan a directory for .o files and extract GUIDs using PresetFileSystem
  /// Returns a Map of GUID -> relative file path
  static Future<Map<String, String>> scanPluginDirectory(
    PresetFileSystem fileSystem,
    String directoryPath,
  ) async {
    final result = <String, String>{};

    try {
      debugPrint('Scanning plugin directory: $directoryPath');

      // List all files in the plugin directory
      final allFiles = await fileSystem.listFiles(
        directoryPath,
        recursive: true,
      );

      // Filter for .o files
      final pluginFiles = allFiles
          .where((path) => path.endsWith('.o'))
          .toList();

      debugPrint('Found ${pluginFiles.length} .o files to process');

      for (final filePath in pluginFiles) {
        try {
          debugPrint('Processing plugin file: $filePath');

          // Read the file via SYSEX
          final fileBytes = await fileSystem.readFile(filePath);
          if (fileBytes == null) {
            debugPrint('Failed to read file: $filePath');
            continue;
          }

          // Extract GUID from the file bytes
          final pluginGuid = await extractGuidFromBytes(fileBytes, filePath);
          result[pluginGuid.guid] = filePath;

          debugPrint(
            'Found ${pluginGuid.isCommunityPlugin ? 'community' : 'factory'} plugin: ${pluginGuid.guid} -> $filePath',
          );
        } catch (e) {
          debugPrint('Failed to extract GUID from $filePath: $e');
          // Continue processing other files
        }
      }

      debugPrint(
        'Plugin scan complete. Found ${result.length} plugins with GUIDs',
      );
    } catch (e) {
      debugPrint('Error scanning plugin directory $directoryPath: $e');
    }

    return result;
  }
}

// Extension to make character checking easier
extension on String {
  Iterable<String> get chars => split('');
}

extension on String {
  bool get isUppercase => this == toUpperCase();
  bool get isLowercase => this == toLowerCase();
  bool get isLetter => RegExp(r'[a-zA-Z]').hasMatch(this);
}
