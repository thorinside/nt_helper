import 'package:nt_helper/interfaces/preset_file_system.dart';
import 'package:nt_helper/models/preset_dependencies.dart';
import 'package:nt_helper/models/collected_file.dart';
import 'package:nt_helper/models/collection_result.dart';
import 'package:nt_helper/models/package_config.dart';

/// Collects dependency files from the file system
class FileCollector {
  final PresetFileSystem fileSystem;

  FileCollector(this.fileSystem);

  /// 50 MB hard ceiling per file. Anything larger is skipped with a
  /// warning — a Disting NT preset is unlikely to need files this big,
  /// and including them blows out package size and SysEx upload time.
  static const int maxFileSize = 50 * 1024 * 1024;

  Future<CollectionResult> collectDependencies(
    PresetDependencies dependencies, {
    PackageConfig? config,
  }) async {
    final List<CollectedFile> files = [];
    final List<String> warnings = [];

    // Collect wavetable folders. Wavetables on the SD card live as
    // directories under /wavetables/<name>/ that contain the actual
    // .wav slices. The slot-level `wavetable` field is just the folder
    // name. Recurse into the folder and pull every .wav file.
    if (config?.includeWavetables != false) {
      for (final wavetable in dependencies.wavetables) {
        await _collectWavetableFolder(wavetable, files, warnings);
      }
    }

    // Collect sample and multisample folders
    if (config?.includeSamples != false) {
      await _collectFolder(
        dependencies.sampleFolders,
        'samples',
        files,
        warnings,
      );

      await _collectFolder(
        dependencies.multisampleFolders,
        'multisamples',
        files,
        warnings,
      );

      // Trigger-style sample-player files: each entry is `<folder>/<file>`
      // relative to /samples/.
      for (final relPath in dependencies.sampleFiles) {
        final samplePath = 'samples/$relPath';
        await _collectFile(samplePath, files, warnings, label: 'sample');
      }

      // Granulator and similar single-sample references. The slot-level
      // `sample` field stores a value that may be either a bare filename
      // (e.g. "kick.wav") or an already-relative path (e.g.
      // "drums/kick.wav") under /samples/.
      for (final sample in dependencies.granulatorSamples) {
        final samplePath = 'samples/$sample';
        await _collectFile(
          samplePath,
          files,
          warnings,
          label: 'granulator sample',
        );
      }
    }

    // Collect FM bank files
    if (config?.includeFMBanks != false) {
      for (final bank in dependencies.fmBanks) {
        final bankPath = 'FMSYX/$bank';
        await _collectFile(bankPath, files, warnings, label: 'FM bank');
      }
    }

    // Collect Three Pot program files
    if (config?.includeThreePot != false) {
      for (final program in dependencies.threePotPrograms) {
        final programPath = 'programs/three_pot/$program';
        await _collectFile(
          programPath,
          files,
          warnings,
          label: 'Three Pot program',
        );
      }
    }

    // Collect Lua script files
    if (config?.includeLua != false) {
      for (final script in dependencies.luaScripts) {
        final scriptPath = 'programs/lua/$script';
        await _collectFile(
          scriptPath,
          files,
          warnings,
          label: 'Lua script',
        );
      }
    }

    // Collect MIDI files (if any algorithm populates this)
    for (final midi in dependencies.midiFiles) {
      final midiPath = 'midi/$midi';
      await _collectFile(midiPath, files, warnings, label: 'MIDI file');
    }

    // Collect community plugin files (if enabled).
    //
    // Plugin paths come from live AlgorithmInfo records (see
    // PresetAnalyzer.extractPluginPaths). The full library is passed in,
    // so `pluginPaths` contains every plugin installed on the NT — we
    // only package the subset that the preset actually references
    // (dependencies.communityPlugins), otherwise every export would try
    // to read every plugin.
    //
    // Matching is done on trimmed GUIDs since the preset JSON can store
    // a trailing-space-padded 4-char GUID while AlgorithmInfo may return
    // the trimmed form (or vice versa).
    if (config?.includeCommunityPlugins == true) {
      final referenced = {
        for (final g in dependencies.communityPlugins) g.trim(): g,
      };
      final collectedRefs = <String>{};

      for (final entry in dependencies.pluginPaths.entries) {
        final trimmed = entry.key.trim();
        if (!referenced.containsKey(trimmed)) continue;
        final pluginPath = entry.value;

        try {
          final bytes = await fileSystem.readFile(pluginPath);
          if (bytes != null) {
            if (bytes.length > maxFileSize) {
              warnings.add(
                'Skipping oversized plugin: $pluginPath '
                '(${_formatBytes(bytes.length)}, max ${_formatBytes(maxFileSize)})',
              );
            } else {
              files.add(CollectedFile(pluginPath, bytes));
              collectedRefs.add(trimmed);
            }
          } else {
            warnings.add(
              'Plugin file not found at path from hardware: $pluginPath '
              '(GUID: ${entry.key})',
            );
          }
        } catch (e) {
          warnings.add(
            'Error reading plugin ${entry.key} at $pluginPath: $e',
          );
        }
      }

      // Warn about any community-plugin GUID referenced by the preset
      // that we didn't package. Either the plugin isn't installed on
      // the connected NT, or its filename path failed to resolve above.
      for (final entry in referenced.entries) {
        if (collectedRefs.contains(entry.key)) continue;
        final originalGuid = entry.value;
        // Skip if a "not found" warning already exists for this GUID
        // (we'd have emitted one during the loop above).
        if (dependencies.pluginPaths.keys
            .any((k) => k.trim() == entry.key)) {
          continue;
        }
        warnings.add(
          'Community plugin $originalGuid is not installed on the '
          'connected Disting NT — cannot include it in the package.',
        );
      }
    }

    return CollectionResult(files: files, warnings: warnings);
  }

  Future<void> _collectFile(
    String path,
    List<CollectedFile> files,
    List<String> warnings, {
    required String label,
  }) async {
    try {
      final bytes = await fileSystem.readFile(path);
      if (bytes == null) {
        warnings.add('$label not found on SD card: $path');
        return;
      }
      if (bytes.length > maxFileSize) {
        warnings.add(
          'Skipping oversized $label: $path '
          '(${_formatBytes(bytes.length)}, max ${_formatBytes(maxFileSize)})',
        );
        return;
      }
      files.add(CollectedFile(path, bytes));
    } catch (e) {
      warnings.add('Error reading $label $path: $e');
    }
  }

  Future<void> _collectWavetableFolder(
    String wavetable,
    List<CollectedFile> files,
    List<String> warnings,
  ) async {
    final folderPath = 'wavetables/$wavetable';
    try {
      // First try treating the wavetable as a folder of .wav slices
      // (the format actually used by the Disting NT firmware).
      final folderFiles = await fileSystem.listFiles(
        folderPath,
        recursive: true,
      );
      var collectedAny = false;
      for (final filePath in folderFiles) {
        if (_isAudioFile(filePath)) {
          await _collectFile(
            filePath,
            files,
            warnings,
            label: 'wavetable file',
          );
          collectedAny = true;
        }
      }
      if (collectedAny) return;

      // Fallback: a single-file wavetable at the /wavetables/ root.
      // The slot field may already include the extension (e.g.
      // `"wavetable": "01-Gentle Speech.wav"`) — don't double it up.
      final flatPath = _isAudioFile(folderPath) ? folderPath : '$folderPath.wav';
      await _collectFile(flatPath, files, warnings, label: 'wavetable');
    } catch (e) {
      warnings.add('Error reading wavetable $wavetable: $e');
    }
  }

  Future<void> _collectFolder(
    Set<String> folders,
    String basePath,
    List<CollectedFile> files,
    List<String> warnings,
  ) async {
    for (final folder in folders) {
      final folderPath = '$basePath/$folder';
      try {
        final folderFiles = await fileSystem.listFiles(
          folderPath,
          recursive: true,
        );
        for (final filePath in folderFiles) {
          if (_isAudioFile(filePath)) {
            await _collectFile(
              filePath,
              files,
              warnings,
              label: 'sample',
            );
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
