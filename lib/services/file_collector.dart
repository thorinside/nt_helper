import 'package:nt_helper/interfaces/preset_file_system.dart';
import 'package:nt_helper/models/preset_dependencies.dart';
import 'package:nt_helper/models/collected_file.dart';

/// Collects dependency files from the file system
class FileCollector {
  final PresetFileSystem fileSystem;

  FileCollector(this.fileSystem);

  Future<List<CollectedFile>> collectDependencies(PresetDependencies dependencies) async {
    final List<CollectedFile> files = [];
    final List<String> warnings = [];
    const maxFileSize = 50 * 1024 * 1024; // 50MB limit per file

    // Collect wavetable files
    for (final wavetable in dependencies.wavetables) {
      final wavetablePath = 'wavetables/$wavetable.wav';
      try {
        if (await fileSystem.fileExists(wavetablePath)) {
          final bytes = await fileSystem.readFile(wavetablePath);
          if (bytes.length > maxFileSize) {
            warnings.add('Skipping large wavetable: $wavetable.wav (${_formatBytes(bytes.length)})');
            continue;
          }
          files.add(CollectedFile(wavetablePath, bytes));
        } else {
          warnings.add('Missing wavetable: $wavetable.wav');
        }
      } catch (e) {
        warnings.add('Error reading wavetable $wavetable.wav: $e');
      }
    }

    // Collect sample folders
    await _collectFolder(dependencies.sampleFolders, 'samples', files, warnings, maxFileSize);

    // Collect multisample folders
    await _collectFolder(dependencies.multisampleFolders, 'multisamples', files, warnings, maxFileSize);

    // Collect FM bank files
    for (final bank in dependencies.fmBanks) {
      final bankPath = 'FMSYX/$bank';
      try {
        if (await fileSystem.fileExists(bankPath)) {
          final bytes = await fileSystem.readFile(bankPath);
          files.add(CollectedFile(bankPath, bytes));
        } else {
          warnings.add('Missing FM bank: $bank');
        }
      } catch (e) {
        warnings.add('Error reading FM bank $bank: $e');
      }
    }

    // Collect Three Pot program files
    for (final program in dependencies.threePotPrograms) {
      final programPath = 'programs/three_pot/$program';
      try {
        if (await fileSystem.fileExists(programPath)) {
          final bytes = await fileSystem.readFile(programPath);
          files.add(CollectedFile(programPath, bytes));
        } else {
          warnings.add('Missing Three Pot program: $program');
        }
      } catch (e) {
        warnings.add('Error reading Three Pot program $program: $e');
      }
    }

    // Collect Lua script files
    for (final script in dependencies.luaScripts) {
      final scriptPath = 'programs/lua/$script';
      try {
        if (await fileSystem.fileExists(scriptPath)) {
          final bytes = await fileSystem.readFile(scriptPath);
          files.add(CollectedFile(scriptPath, bytes));
        } else {
          warnings.add('Missing Lua script: $script');
        }
      } catch (e) {
        warnings.add('Error reading Lua script $script: $e');
      }
    }

    // Log warnings if any
    if (warnings.isNotEmpty) {
      print('Package warnings: ${warnings.join(', ')}');
    }

    return files;
  }

  Future<void> _collectFolder(
      Set<String> folders,
      String basePath,
      List<CollectedFile> files,
      List<String> warnings,
      int maxFileSize
      ) async {
    for (final folder in folders) {
      final folderPath = '$basePath/$folder';
      try {
        final folderFiles = await fileSystem.listFiles(folderPath, recursive: true);
        for (final filePath in folderFiles) {
          if (_isAudioFile(filePath)) {
            final bytes = await fileSystem.readFile(filePath);
            if (bytes.length > maxFileSize) {
              warnings.add('Skipping large file: $filePath (${_formatBytes(bytes.length)})');
              continue;
            }
            files.add(CollectedFile(filePath, bytes));
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