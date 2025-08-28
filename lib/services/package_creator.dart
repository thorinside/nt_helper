import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:nt_helper/interfaces/preset_file_system.dart';
import 'package:nt_helper/models/preset_dependencies.dart';
import 'package:nt_helper/models/collected_file.dart';
import 'package:nt_helper/models/package_config.dart';
import 'package:nt_helper/db/database.dart';
import 'preset_analyzer.dart';
import 'file_collector.dart';

/// Creates preset packages with all dependencies
class PackageCreator {
  final PresetFileSystem fileSystem;
  final AppDatabase database;

  PackageCreator(this.fileSystem, this.database);

  Future<Uint8List> createPackage({
    required String presetFilePath, // e.g., "presets/MyPreset.json"
    required PackageConfig config,
    void Function(String status)? onProgress,
  }) async {
    try {
      onProgress?.call('Loading preset...');

      // Load and parse preset JSON
      final presetBytes = await fileSystem.readFile(presetFilePath);
      if (presetBytes == null) {
        throw Exception('Preset file not found: $presetFilePath');
      }

      final presetJson = utf8.decode(presetBytes);
      final presetData = jsonDecode(presetJson) as Map<String, dynamic>;
      final presetFilename = presetFilePath.split('/').last;

      onProgress?.call('Analyzing dependencies...');

      // Analyze dependencies
      final dependencies = PresetAnalyzer.analyzeDependencies(presetData);

      onProgress?.call('Collecting files...');

      // Collect dependency files
      final fileCollector = FileCollector(fileSystembase);
      final dependencyFiles = await fileCollector.collectDependencies(
        dependencies,
        config: config,
      );

      onProgress?.call('Creating package...');

      // Create archive
      final archive = Archive();

      // Add preset JSON file to root/presets/
      archive.addFile(
        ArchiveFile(
          'root/presets/$presetFilename',
          presetBytes.length,
          presetBytes,
        ),
      );

      // Add dependency files maintaining folder structure under root/
      for (final file in dependencyFiles) {
        archive.addFile(
          ArchiveFile(
            'root/${file.relativePath}',
            file.bytes.length,
            file.bytes,
          ),
        );
      }

      // Add manifest file to top level
      final manifest = _createManifest(
        presetData,
        presetFilename,
        dependencies,
        dependencyFiles,
        config,
      );
      archive.addFile(
        ArchiveFile('manifest.json', manifest.length, manifest.codeUnits),
      );

      // Add README to top level if requested
      if (config.includeReadme) {
        final readme = _createReadme(
          presetData,
          presetFilename,
          dependencies,
          config,
        );
        archive.addFile(
          ArchiveFile('README.md', readme.length, readme.codeUnits),
        );
      }

      onProgress?.call('Compressing...');

      // Create ZIP
      final zipEncoder = ZipEncoder();
      final zipBytes = zipEncoder.encode(archive);

      onProgress?.call('Complete!');

      // Print summary report
      final report = PresetAnalyzer.generatePackageReport(
        dependencies,
        dependencyFiles,
      );
      debugPrint(report);

      return Uint8List.fromList(zipBytes);
    } catch (e) {
      onProgress?.call('Error: $e');
      rethrow;
    }
  }

  String _createManifest(
    Map<String, dynamic> presetData,
    String filename,
    PresetDependencies dependencies,
    List<CollectedFile> files,
    PackageConfig config,
  ) {
    final manifest = {
      'preset': {
        'name': presetData['name']?.toString().trim() ?? 'Unknown',
        'author': presetData['author']?.toString().trim() ?? 'Unknown',
        'version': presetData['version'] ?? 1,
        'filename': filename,
      },
      'dependencies': {
        'wavetables': dependencies.wavetables.toList(),
        'sampleFolders': dependencies.sampleFolders.toList(),
        'multisampleFolders': dependencies.multisampleFolders.toList(),
        'fmBanks': dependencies.fmBanks.toList(),
        'threePotPrograms': dependencies.threePotPrograms.toList(),
        'luaScripts': dependencies.luaScripts.toList(),
        'communityPlugins': dependencies.communityPlugins.toList(),
        'totalCount': dependencies.totalCount,
      },
      'package': {
        'fileCount': files.length + 1, // +1 for preset file
        'totalSize': files.fold<int>(0, (sum, file) => sum + file.size),
        'includedFiles': files.map((f) => f.relativePath).toList(),
      },
      'installation': {
        'targetPaths': {
          'preset': '/presets/',
          'wavetables': '/wavetables/',
          'samples': '/samples/',
          'multisamples': '/multisamples/',
          'fmBanks': '/FMSYX/',
          'midi': '/midi/',
          'threePot': '/programs/three_pot/',
          'lua': '/programs/lua/',
          'plugins': '/programs/plug-ins/',
        },
        'instructions':
            config.includeCommunityPlugins && dependencies.hasCommunityPlugins
            ? [
                'Extract this package to a temporary folder',
                'Copy the entire contents of the root/ folder to the root of your SD card',
                'The preset will be installed to /presets/',
                'All dependencies including community plugins will be installed to their correct locations',
                'Community plugins are included in this package in /programs/plug-ins/',
                'Load the preset on your Disting NT using the Load Preset function',
              ]
            : [
                'Extract this package to a temporary folder',
                'Copy the entire contents of the root/ folder to the root of your SD card',
                'The preset will be installed to /presets/',
                'All dependencies will be installed to their correct locations',
                'Community plugins (if any) must be installed separately in /programs/plug-ins/',
                'Load the preset on your Disting NT using the Load Preset function',
              ],
      },
      'packageInfo': {
        'createdAt': DateTime.now().toIso8601String(),
        'packager': 'nt_helper Preset Packager v1.0',
      },
    };

    return jsonEncode(manifest);
  }

  String _createReadme(
    Map<String, dynamic> presetData,
    String filename,
    PresetDependencies dependencies,
    PackageConfig config,
  ) {
    final name = presetData['name']?.toString().trim() ?? 'Unknown';
    final author = presetData['author']?.toString().trim() ?? 'Unknown';

    final buffer = StringBuffer();

    buffer.writeln('# $name\n');
    buffer.writeln('**Author:** $author');
    buffer.writeln(
      '**Packaged:** ${DateTime.now().toString().split(' ')[0]}\n',
    );

    buffer.writeln('## Installation');
    buffer.writeln('1. Extract this package to a temporary folder');
    buffer.writeln(
      '2. Copy the entire contents of the `root/` folder to the root of your Disting NT SD card',
    );
    buffer.writeln(
      '3. The preset will be automatically placed in `/presets/$filename`',
    );
    buffer.writeln(
      '4. All dependencies will be installed to their correct locations',
    );
    buffer.writeln(
      '5. Load the preset on your Disting NT using the Load Preset function\n',
    );

    buffer.writeln('## Contents');
    buffer.writeln(
      'This package contains the preset file and all required dependencies:\n',
    );

    if (dependencies.wavetables.isNotEmpty) {
      buffer.writeln('### Wavetables (${dependencies.wavetables.length})');
      for (final wt in dependencies.wavetables) {
        buffer.writeln('- $wt');
      }
      buffer.writeln();
    }

    if (dependencies.sampleFolders.isNotEmpty) {
      buffer.writeln(
        '### Sample Folders (${dependencies.sampleFolders.length})',
      );
      for (final folder in dependencies.sampleFolders) {
        buffer.writeln('- $folder/');
      }
      buffer.writeln();
    }

    if (dependencies.multisampleFolders.isNotEmpty) {
      buffer.writeln(
        '### Multisample Folders (${dependencies.multisampleFolders.length})',
      );
      for (final folder in dependencies.multisampleFolders) {
        buffer.writeln('- $folder/');
      }
      buffer.writeln();
    }

    if (dependencies.fmBanks.isNotEmpty) {
      buffer.writeln('### FM Banks (${dependencies.fmBanks.length})');
      for (final bank in dependencies.fmBanks) {
        buffer.writeln('- $bank');
      }
      buffer.writeln();
    }

    if (dependencies.threePotPrograms.isNotEmpty) {
      buffer.writeln(
        '### Three Pot Programs (${dependencies.threePotPrograms.length})',
      );
      for (final program in dependencies.threePotPrograms) {
        buffer.writeln('- $program');
      }
      buffer.writeln();
    }

    if (dependencies.luaScripts.isNotEmpty) {
      buffer.writeln('### Lua Scripts (${dependencies.luaScripts.length})');
      for (final script in dependencies.luaScripts) {
        buffer.writeln('- $script');
      }
      buffer.writeln();
    }

    if (dependencies.communityPlugins.isNotEmpty) {
      buffer.writeln(
        '### Community Plugins (${dependencies.communityPlugins.length})',
      );
      for (final plugin in dependencies.communityPlugins) {
        if (config.includeCommunityPlugins) {
          buffer.writeln('- $plugin (included in package)');
        } else {
          buffer.writeln('- $plugin (requires separate installation)');
        }
      }
      buffer.writeln();
      if (config.includeCommunityPlugins) {
        buffer.writeln(
          '**Note:** Community plugins are included in this package and will be installed to `/programs/plug-ins/`.\n',
        );
      } else {
        buffer.writeln(
          '**Important:** Community plugins must be installed separately according to their individual documentation.\n',
        );
      }
    }

    buffer.writeln('## Notes');
    buffer.writeln(
      '- Ensure you have sufficient space on your SD card for all sample content',
    );
    buffer.writeln(
      '- Some samples may require specific folder structures to work correctly',
    );
    buffer.writeln(
      '- This package was created with nt_helper Preset Packager\n',
    );

    buffer.writeln('## Requirements');
    buffer.writeln('- Expert Sleepers Disting NT with compatible firmware');
    buffer.writeln('- SD card with sufficient free space');
    buffer.writeln('- All sample content referenced by this preset\n');

    buffer.writeln('---');
    buffer.writeln('Generated by nt_helper Preset Packager v1.0');

    return buffer.toString();
  }
}
