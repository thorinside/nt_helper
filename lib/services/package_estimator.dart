import 'package:nt_helper/interfaces/preset_file_system.dart';
import 'package:nt_helper/models/package_config.dart';
import 'package:nt_helper/models/preset_dependencies.dart';

/// Pre-export size summary for the package-export dialog. Lets the user
/// see what they're committing to (especially folder-of-multisamples
/// reads, which can pull dozens of files over slow SysEx) before clicking
/// Export.
class PackageSizeEstimate {
  final int totalBytes;
  final int fileCount;
  final List<FolderSize> folders;
  final List<String> warnings;

  const PackageSizeEstimate({
    required this.totalBytes,
    required this.fileCount,
    required this.folders,
    required this.warnings,
  });

  /// True if every dependency was successfully sized (no missing folders,
  /// no read errors). When false the totals are still valid but represent
  /// a lower bound.
  bool get isComplete => warnings.isEmpty;
}

/// One labeled section in a [PackageSizeEstimate], e.g. "Multisample
/// folders (2)". `path` is a category label, not a real filesystem path.
class FolderSize {
  final String path;
  final int fileCount;
  final int bytes;

  const FolderSize({
    required this.path,
    required this.fileCount,
    required this.bytes,
  });
}

/// Walks the dependency tree against the SD card and totals the byte
/// counts. Cheap when the FS implementation has size metadata in its
/// directory listings (the live SysEx implementation does); falls back
/// gracefully when sizes aren't available (returns whatever total it can).
class PackageEstimator {
  final PresetFileSystem fileSystem;

  PackageEstimator(this.fileSystem);

  Future<PackageSizeEstimate> estimate(
    PresetDependencies deps, {
    PackageConfig config = const PackageConfig(),
  }) async {
    final folders = <FolderSize>[];
    final warnings = <String>[];
    var totalBytes = 0;
    var fileCount = 0;

    Future<FolderSize?> sumFolder(
      String label,
      String path, {
      Set<String>? extensions,
    }) async {
      try {
        final entries = await fileSystem.listEntries(path, recursive: true);
        var bytes = 0;
        var count = 0;
        for (final e in entries) {
          if (extensions != null) {
            final ext = e.path.toLowerCase().split('.').last;
            if (!extensions.contains(ext)) continue;
          }
          bytes += e.size;
          count++;
        }
        if (count == 0) return null;
        return FolderSize(path: label, fileCount: count, bytes: bytes);
      } catch (e) {
        warnings.add('Could not size $label ($path): $e');
        return null;
      }
    }

    Future<int?> sumFile(String path) async {
      try {
        return await fileSystem.getFileSize(path);
      } catch (_) {
        return null;
      }
    }

    void add(FolderSize? f) {
      if (f == null) return;
      folders.add(f);
      totalBytes += f.bytes;
      fileCount += f.fileCount;
    }

    if (config.includeWavetables) {
      for (final wt in deps.wavetables) {
        final folder = await sumFolder(
          'wavetables/$wt',
          'wavetables/$wt',
        );
        if (folder != null) {
          add(folder);
        } else {
          // Try single-file fallback (matches FileCollector behavior).
          final flatPath = wt.toLowerCase().endsWith('.wav')
              ? 'wavetables/$wt'
              : 'wavetables/$wt.wav';
          final size = await sumFile(flatPath);
          if (size != null) {
            add(FolderSize(path: flatPath, fileCount: 1, bytes: size));
          } else {
            warnings.add('Wavetable not found: $wt');
          }
        }
      }
    }

    if (config.includeSamples) {
      for (final folder in deps.sampleFolders) {
        final f = await sumFolder('samples/$folder', 'samples/$folder');
        if (f == null) {
          warnings.add('Sample folder not found: samples/$folder');
        } else {
          add(f);
        }
      }
      for (final folder in deps.multisampleFolders) {
        final f = await sumFolder(
          'multisamples/$folder',
          'multisamples/$folder',
        );
        if (f == null) {
          warnings.add('Multisample folder not found: multisamples/$folder');
        } else {
          add(f);
        }
      }
      for (final relPath in deps.sampleFiles) {
        final size = await sumFile('samples/$relPath');
        if (size != null) {
          add(FolderSize(
            path: 'samples/$relPath',
            fileCount: 1,
            bytes: size,
          ));
        } else {
          warnings.add('Sample not found: samples/$relPath');
        }
      }
      for (final s in deps.granulatorSamples) {
        final size = await sumFile('samples/$s');
        if (size != null) {
          add(FolderSize(
            path: 'samples/$s',
            fileCount: 1,
            bytes: size,
          ));
        } else {
          warnings.add('Granulator sample not found: samples/$s');
        }
      }
    }

    if (config.includeFMBanks) {
      for (final bank in deps.fmBanks) {
        final size = await sumFile('FMSYX/$bank');
        if (size != null) {
          add(FolderSize(
            path: 'FMSYX/$bank',
            fileCount: 1,
            bytes: size,
          ));
        } else {
          warnings.add('FM bank not found: FMSYX/$bank');
        }
      }
    }

    if (config.includeThreePot) {
      for (final p in deps.threePotPrograms) {
        final size = await sumFile('programs/three_pot/$p');
        if (size != null) {
          add(FolderSize(
            path: 'programs/three_pot/$p',
            fileCount: 1,
            bytes: size,
          ));
        } else {
          warnings.add('Three Pot program not found: programs/three_pot/$p');
        }
      }
    }

    if (config.includeLua) {
      for (final s in deps.luaScripts) {
        final size = await sumFile('programs/lua/$s');
        if (size != null) {
          add(FolderSize(
            path: 'programs/lua/$s',
            fileCount: 1,
            bytes: size,
          ));
        } else {
          warnings.add('Lua script not found: programs/lua/$s');
        }
      }
    }

    if (deps.bundleMidiTree && config.includeMidiTree) {
      add(await sumFolder('MIDI/', 'MIDI', extensions: const {'mid', 'midi'}));
    }
    if (deps.bundleSclTree && config.includeScales) {
      add(await sumFolder('scl/', 'scl', extensions: const {'scl'}));
    }
    if (deps.bundleKbmTree && config.includeScales) {
      add(await sumFolder('kbm/', 'kbm', extensions: const {'kbm'}));
    }

    if (config.includeCommunityPlugins) {
      for (final entry in deps.pluginPaths.entries) {
        final trimmed = entry.key.trim();
        final referenced = deps.communityPlugins.any(
          (g) => g.trim() == trimmed,
        );
        if (!referenced) continue;
        final size = await sumFile(entry.value);
        if (size != null) {
          add(FolderSize(
            path: entry.value,
            fileCount: 1,
            bytes: size,
          ));
        } else {
          warnings.add('Plugin not found: ${entry.value}');
        }
      }
    }

    return PackageSizeEstimate(
      totalBytes: totalBytes,
      fileCount: fileCount,
      folders: folders,
      warnings: warnings,
    );
  }
}
