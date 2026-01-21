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

  /// Check if a symbol name represents a Factory symbol.
  /// Handles multiple naming patterns:
  /// - "_ZL7factory" - static factory variable (mangled)
  /// - "factory" - unmangled factory variable
  /// - "_ZN*FactoryE" - C++ namespaced Factory (e.g., "_ZN9DirSeqAlg7FactoryE")
  static bool _isFactorySymbol(String name) {
    if (name == '_ZL7factory' || name == 'factory') {
      return true;
    }
    // Match C++ namespaced Factory symbols like "_ZN9DirSeqAlg7FactoryE"
    // Pattern: _ZN followed by length-prefixed names, ending with "FactoryE"
    if (name.startsWith('_ZN') && name.endsWith('FactoryE')) {
      return true;
    }
    return false;
  }

  /// Extract a GUID from a factory symbol in an ELF file.
  /// Returns null if the GUID cannot be extracted from this symbol.
  static PluginGuid? _extractGuidFromSymbol(
    ElfReader reader,
    ElfSymbol symbol,
    String symbolName,
  ) {
    try {
      // Get the section containing the factory symbol
      final sectionIndex = symbol.shndx;
      if (sectionIndex >= reader.sections.length) {
        return null;
      }

      final section = reader.sections[sectionIndex];

      // Calculate offset within section
      final symbolAddress = symbol.value;
      final sectionAddress = section.header.addr;

      if (symbolAddress < sectionAddress) {
        return null;
      }

      final offset = (symbolAddress - sectionAddress).toInt();

      // Get section data
      final sectionData = section.data();

      // Ensure we have enough data for the GUID (first 4 bytes of the factory struct)
      if (offset + 4 > sectionData.length) {
        return null;
      }

      // Extract the GUID as a 32-bit little-endian integer
      // The _NT_factory struct starts with: uint32_t guid;
      final guidBytes = sectionData.sublist(offset, offset + 4);
      final rawGuid = ByteData.sublistView(
        Uint8List.fromList(guidBytes),
      ).getUint32(0, Endian.little);

      // Convert to string representation
      final guidString = _guidFromU32(rawGuid);

      // Validate that we got a reasonable GUID (4 printable ASCII characters)
      if (guidString.length != 4 || guidString.contains('?')) {
        return null;
      }

      return PluginGuid(guid: guidString, rawValue: rawGuid);
    } catch (e) {
      return null;
    }
  }

  /// Extract ALL plugin GUIDs from ELF bytes.
  /// A single .o file can contain multiple algorithms, each with its own Factory.
  static Future<List<PluginGuid>> extractAllGuidsFromBytes(
    Uint8List bytes,
    String fileName,
  ) async {
    try {
      // Parse the ELF file from bytes
      final reader = ElfReader.fromBytes(bytes);
      final guids = <PluginGuid>[];

      // Collect all factory symbols from the symbol table
      if (reader.symbolTableSection != null) {
        final symbolTable = reader.symbolTableSection!;
        final stringTable = reader.stringTable;

        for (final symbol in symbolTable.symbols) {
          final name = stringTable?.at(symbol.nindex) ?? '';
          if (_isFactorySymbol(name)) {
            final guid = _extractGuidFromSymbol(reader, symbol, name);
            if (guid != null) {
              guids.add(guid);
            }
          }
        }
      }

      // Also check dynamic symbol table
      if (reader.dynamicSymbolTableSection != null) {
        final dynamicSymbolTable = reader.dynamicSymbolTableSection!;
        final dynamicStringTable = reader.dynamicStringTable;

        for (final symbol in dynamicSymbolTable.symbols) {
          final name = dynamicStringTable?.at(symbol.nindex) ?? '';
          if (_isFactorySymbol(name)) {
            final guid = _extractGuidFromSymbol(reader, symbol, name);
            // Avoid duplicates
            if (guid != null && !guids.any((g) => g.guid == guid.guid)) {
              guids.add(guid);
            }
          }
        }
      }

      if (guids.isEmpty) {
        throw GuidExtractionException('No Factory symbols found in $fileName');
      }

      return guids;
    } catch (e) {
      if (e is GuidExtractionException) rethrow;
      throw GuidExtractionException(
        'Failed to extract GUIDs from $fileName: $e',
      );
    }
  }

  /// Extract plugin GUID from ELF bytes (returns first GUID for backwards compatibility)
  static Future<PluginGuid> extractGuidFromBytes(
    Uint8List bytes,
    String fileName,
  ) async {
    final guids = await extractAllGuidsFromBytes(bytes, fileName);
    return guids.first;
  }

  /// Scan a directory for .o files and extract GUIDs using PresetFileSystem
  /// Returns a Map of GUID -> relative file path
  /// Note: A single .o file can contain multiple algorithms (GUIDs)
  static Future<Map<String, String>> scanPluginDirectory(
    PresetFileSystem fileSystem,
    String directoryPath,
  ) async {
    final result = <String, String>{};

    try {
      // List all files in the plugin directory
      final allFiles = await fileSystem.listFiles(
        directoryPath,
        recursive: true,
      );

      // Filter for .o files
      final pluginFiles = allFiles
          .where((path) => path.endsWith('.o'))
          .toList();

      for (final filePath in pluginFiles) {
        try {
          // Read the file via SYSEX
          final fileBytes = await fileSystem.readFile(filePath);
          if (fileBytes == null) {
            continue;
          }

          // Extract ALL GUIDs from the file (multi-algorithm plugins)
          final pluginGuids = await extractAllGuidsFromBytes(
            fileBytes,
            filePath,
          );
          for (final guid in pluginGuids) {
            result[guid.guid] = filePath;
          }
        } catch (e) {
          // Continue processing other files
        }
      }
    } catch (e) {
      // Intentionally empty
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
