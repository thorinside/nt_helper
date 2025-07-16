import 'package:flutter/foundation.dart';
import 'package:nt_helper/interfaces/preset_file_system.dart';
import 'package:nt_helper/models/preset_dependencies.dart';
import 'package:nt_helper/models/collected_file.dart';
import 'package:nt_helper/models/package_config.dart';
import 'package:nt_helper/util/extensions.dart';
import 'package:nt_helper/db/database.dart';

/// Collects dependency files from the file system
class FileCollector {
  final PresetFileSystem fileSystem;
  final AppDatabase database;

  FileCollector(this.fileSystem, this.database);

  Future<List<CollectedFile>> collectDependencies(
      PresetDependencies dependencies,
      {PackageConfig? config}) async {
    final List<CollectedFile> files = [];
    final List<String> warnings = [];
    const maxFileSize = 50 * 1024 * 1024; // 50MB limit per file

    // Collect wavetable files
    for (final wavetable in dependencies.wavetables) {
      final wavetablePath = 'wavetables/$wavetable.wav';
      try {
        (await fileSystem.readFile(wavetablePath))?.let((bytes) {
          if (bytes.length > maxFileSize) {
            warnings.add(
                'Skipping large wavetable: $wavetable.wav (${_formatBytes(bytes.length)})');
          }
          files.add(CollectedFile(wavetablePath, bytes));
        });
      } catch (e) {
        warnings.add('Error reading wavetable $wavetable.wav: $e');
      }
    }

    // Collect sample folders
    await _collectFolder(
        dependencies.sampleFolders, 'samples', files, warnings, maxFileSize);

    // Collect multisample folders
    await _collectFolder(dependencies.multisampleFolders, 'multisamples', files,
        warnings, maxFileSize);

    // Collect FM bank files
    for (final bank in dependencies.fmBanks) {
      final bankPath = 'FMSYX/$bank';
      try {
        (await fileSystem.readFile(bankPath))?.let((bytes) {
          files.add(CollectedFile(bankPath, bytes));
        });
      } catch (e) {
        warnings.add('Error reading FM bank $bank: $e');
      }
    }

    // Collect Three Pot program files
    for (final program in dependencies.threePotPrograms) {
      final programPath = 'programs/three_pot/$program';
      try {
        (await fileSystem.readFile(programPath))?.let((bytes) {
          files.add(CollectedFile(programPath, bytes));
        });
      } catch (e) {
        warnings.add('Error reading Three Pot program $program: $e');
      }
    }

    // Collect Lua script files
    for (final script in dependencies.luaScripts) {
      final scriptPath = 'programs/lua/$script';
      try {
        (await fileSystem.readFile(scriptPath))?.let((bytes) {
          files.add(CollectedFile(scriptPath, bytes));
        });
      } catch (e) {
        warnings.add('Error reading Lua script $script: $e');
      }
    }

    // Collect community plugin files (if enabled)
    if (config?.includeCommunityPlugins == true) {
      // Get plugin file paths from database
      final guidToPathMap = await database.metadataDao
          .getPluginFilePathsByGuids(dependencies.communityPlugins);

      for (final pluginGuid in dependencies.communityPlugins) {
        final pluginPath = guidToPathMap[pluginGuid];
        if (pluginPath != null) {
          try {
            (await fileSystem.readFile(pluginPath))?.let((bytes) {
              files.add(CollectedFile(pluginPath, bytes));
            });
          } catch (e) {
            warnings.add(
                'Error reading community plugin $pluginGuid at $pluginPath: $e');
          }
        } else {
          warnings.add(
              'Community plugin $pluginGuid not found locally. File path not available in database.');
        }
      }
    }

    // Log warnings if any
    if (warnings.isNotEmpty) {
      debugPrint('Package warnings: ${warnings.join(', ')}');
    }

    return files;
  }

  Future<void> _collectFolder(Set<String> folders, String basePath,
      List<CollectedFile> files, List<String> warnings, int maxFileSize) async {
    for (final folder in folders) {
      final folderPath = '$basePath/$folder';
      try {
        final folderFiles =
            await fileSystem.listFiles(folderPath, recursive: true);
        for (final filePath in folderFiles) {
          if (_isAudioFile(filePath)) {
            (await fileSystem.readFile(filePath))?.let((bytes) {
              if (bytes.length > maxFileSize) {
                warnings.add(
                    'Skipping large file: $filePath (${_formatBytes(bytes.length)})');
              }
              files.add(CollectedFile(filePath, bytes));
            });
          }
        }
      } catch (e) {
        warnings.add('Error reading folder $folder: $e');
      }
    }
  }

  static bool _isAudioFile(String path) {
    final ext = path.toLowerCase().split('.').last;
    return ['wav', 'aiff', 'aif', 'flac'].contains(ext);
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }
}
