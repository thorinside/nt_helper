import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/services/elf_guid_extractor.dart';

void main() {
  group('ElfGuidExtractor', () {
    group('extractAllGuidsFromBytes', () {
      test('extracts multiple GUIDs from multi-algorithm plugin', () async {
        // DirectionalSequencer plugin by AgentTerror (@NerdRoger) has two algorithms:
        // - DirSeqAlg::Factory (ATds)
        // - DirSeqModMatrixAlg::Factory (ATdm)
        final pluginFile = File('test/fixtures/plugins/directionalSequencer.o');
        final bytes = Uint8List.fromList(await pluginFile.readAsBytes());

        final guids = await ElfGuidExtractor.extractAllGuidsFromBytes(
          bytes,
          'directionalSequencer.o',
        );

        // Should find exactly 2 GUIDs
        expect(guids.length, 2);

        // Extract just the GUID strings
        final guidStrings = guids.map((g) => g.guid).toSet();

        // Verify the expected GUIDs are present
        expect(guidStrings, containsAll(['ATds', 'ATdm']));

        // Both should be community plugins (have uppercase letters)
        for (final guid in guids) {
          expect(guid.isCommunityPlugin, isTrue);
        }
      });

      test('extractGuidFromBytes returns first GUID for compatibility', () async {
        final pluginFile = File('test/fixtures/plugins/directionalSequencer.o');
        final bytes = Uint8List.fromList(await pluginFile.readAsBytes());

        final guid = await ElfGuidExtractor.extractGuidFromBytes(
          bytes,
          'directionalSequencer.o',
        );

        // Should return a valid GUID
        expect(guid.guid.length, 4);
        expect(guid.isCommunityPlugin, isTrue);
      });
    });

    group('_isFactorySymbol pattern matching', () {
      // Test the symbol matching logic indirectly through the extractor
      test('handles C++ namespaced Factory symbols', () async {
        // The directionalSequencer.o has symbols like:
        // _ZN9DirSeqAlg7FactoryE
        // _ZN18DirSeqModMatrixAlg7FactoryE
        final pluginFile = File('test/fixtures/plugins/directionalSequencer.o');
        final bytes = Uint8List.fromList(await pluginFile.readAsBytes());

        final guids = await ElfGuidExtractor.extractAllGuidsFromBytes(
          bytes,
          'directionalSequencer.o',
        );

        // If we found 2 GUIDs, the namespaced pattern matching worked
        expect(guids.length, 2);
      });
    });

    group('PluginGuid', () {
      test('isCommunityPlugin returns true for uppercase GUIDs', () {
        const guid = PluginGuid(guid: 'Test', rawValue: 0);
        expect(guid.isCommunityPlugin, isTrue);
      });

      test('isCommunityPlugin returns false for lowercase GUIDs', () {
        const guid = PluginGuid(guid: 'test', rawValue: 0);
        expect(guid.isCommunityPlugin, isFalse);
      });

      test('isFactoryAlgorithm returns true for lowercase GUIDs', () {
        const guid = PluginGuid(guid: 'satu', rawValue: 0);
        expect(guid.isFactoryAlgorithm, isTrue);
      });

      test('isFactoryAlgorithm returns false for uppercase GUIDs', () {
        const guid = PluginGuid(guid: 'Satu', rawValue: 0);
        expect(guid.isFactoryAlgorithm, isFalse);
      });

      test('toString formats GUID correctly', () {
        const guid = PluginGuid(guid: 'Test', rawValue: 0x74736554);
        expect(guid.toString(), contains('Test'));
        expect(guid.toString(), contains('74736554'));
      });
    });

    group('error handling', () {
      test('throws GuidExtractionException for invalid ELF data', () async {
        final invalidBytes = Uint8List.fromList([0, 1, 2, 3, 4, 5]);

        expect(
          () => ElfGuidExtractor.extractAllGuidsFromBytes(
            invalidBytes,
            'invalid.o',
          ),
          throwsA(isA<GuidExtractionException>()),
        );
      });

      test('throws GuidExtractionException when no Factory found', () async {
        // Create minimal valid ELF header but with no factory symbols
        // This is a simplified test - in practice we'd need a proper ELF without Factory
        final emptyElf = Uint8List.fromList([
          0x7f, 0x45, 0x4c, 0x46, // ELF magic
          0x01, // 32-bit
          0x01, // Little endian
          0x01, // ELF version
          0x00, // OS/ABI
          ...List.filled(8, 0), // Padding
          0x01, 0x00, // Type: relocatable
          0x28, 0x00, // Machine: ARM
          0x01, 0x00, 0x00, 0x00, // Version
          ...List.filled(36, 0), // Rest of header
        ]);

        expect(
          () => ElfGuidExtractor.extractAllGuidsFromBytes(emptyElf, 'empty.o'),
          throwsA(isA<GuidExtractionException>()),
        );
      });
    });
  });
}
