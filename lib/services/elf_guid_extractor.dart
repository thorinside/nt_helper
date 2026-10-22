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

/// Facts about an ELF object that decide whether the Disting NT can load it
/// as a plug-in. Produced by [ElfGuidExtractor.inspectPluginObject].
class PluginObjectInfo {
  const PluginObjectInfo({
    required this.is32Bit,
    required this.isLittleEndian,
    required this.machine,
    required this.fileType,
    required this.hasPluginEntry,
    required this.guids,
  });

  /// True for ELFCLASS32.
  final bool is32Bit;

  /// True for ELFDATA2LSB.
  final bool isLittleEndian;

  /// The `e_machine` value; the NT needs [ElfArchitectureIdentifier.arm].
  final ElfArchitectureIdentifier machine;

  /// The `e_type` value; the NT needs [ElfFileType.relocatable].
  final ElfFileType fileType;

  /// Whether `pluginEntry` is defined (not merely referenced).
  final bool hasPluginEntry;

  /// GUIDs of the recognised factory symbols, without duplicates.
  final List<PluginGuid> guids;

  /// Whether the header matches the NT's Cortex-M7 target: 32-bit,
  /// little-endian ARM.
  bool get isArm32LittleEndian =>
      is32Bit && isLittleEndian && machine == ElfArchitectureIdentifier.arm;
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

  /// Collects the GUIDs of every recognised factory symbol in [reader],
  /// from the static and dynamic symbol tables, without duplicates.
  static List<PluginGuid> _collectGuids(ElfReader reader) {
    final guids = <PluginGuid>[];
    void scan(ElfSymbolTableSection? table, ElfStringTable? names) {
      if (table == null) return;
      for (final symbol in table.symbols) {
        final name = names?.at(symbol.nindex) ?? '';
        if (!_isFactorySymbol(name)) continue;
        final guid = _extractGuidFromSymbol(reader, symbol, name);
        if (guid != null && !guids.any((g) => g.guid == guid.guid)) {
          guids.add(guid);
        }
      }
    }

    scan(reader.symbolTableSection, reader.stringTable);
    scan(reader.dynamicSymbolTableSection, reader.dynamicStringTable);
    return guids;
  }

  /// Extract ALL plugin GUIDs from ELF bytes.
  /// A single .o file can contain multiple algorithms, each with its own Factory.
  static Future<List<PluginGuid>> extractAllGuidsFromBytes(
    Uint8List bytes,
    String fileName,
  ) async {
    try {
      final guids = _collectGuids(ElfReader.fromBytes(bytes));
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

  /// Name of the symbol the Disting NT calls to enter a C++ plug-in, as
  /// declared by distingNT_API's `NT_DECLARE_PLUGIN`.
  static const pluginEntrySymbol = 'pluginEntry';

  /// Reads, in one ELF parse, everything needed to judge whether [bytes]
  /// can be loaded as a Disting NT plug-in: word size, byte order, machine,
  /// file type, whether [pluginEntrySymbol] is defined, and the factory GUIDs.
  ///
  /// Throws [GuidExtractionException] when the bytes are not a readable ELF.
  static PluginObjectInfo inspectPluginObject(
    Uint8List bytes,
    String fileName,
  ) {
    try {
      final reader = ElfReader.fromBytes(bytes);
      final header = reader.header;
      var hasPluginEntry = false;
      final symbols = reader.symbolTableSection;
      if (symbols != null) {
        final names = reader.stringTable;
        hasPluginEntry = symbols.symbols.any(
          (symbol) =>
              symbol.shndx != 0 &&
              names?.at(symbol.nindex) == pluginEntrySymbol,
        );
      }
      return PluginObjectInfo(
        is32Bit: header.word == ElfWordSize.word32Bit,
        isLittleEndian: header.endian == Endian.little,
        machine: header.arch,
        fileType: header.type,
        hasPluginEntry: hasPluginEntry,
        guids: _collectGuids(reader),
      );
    } catch (e) {
      throw GuidExtractionException('$fileName is not a readable ELF file: $e');
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
