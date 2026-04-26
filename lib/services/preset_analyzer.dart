import '../models/collected_file.dart';
import '../models/preset_dependencies.dart';
import '../domain/disting_nt_sysex.dart';

/// Analyzes preset JSON files to extract dependencies
class PresetAnalyzer {
  /// Extracts plugin file paths from AlgorithmInfo objects.
  /// Call this with live slot data to populate pluginPaths for direct SD card reads.
  /// Returns a map of plugin GUID to SD card file path (normalized to include
  /// the plugin directory prefix if the firmware returned a bare filename).
  static Map<String, String> extractPluginPaths(
    List<AlgorithmInfo> algorithmInfos,
  ) {
    final paths = <String, String>{};
    for (final info in algorithmInfos) {
      if (info.isPlugin && info.filename != null && info.filename!.isNotEmpty) {
        paths[info.guid] = _normalizePluginPath(info.filename!);
      }
    }
    return paths;
  }

  /// Normalizes `AlgorithmInfo.filename` into a full SD-card-relative
  /// path. The firmware strips the standard directory prefix
  /// (`programs/plug-ins/`, `programs/lua/`, `programs/three_pot/`) from
  /// the filename to save null-terminated-string bytes in the SysEx
  /// payload, so we have to add it back. A filename may still contain
  /// subfolder components (e.g. `corrupter/corrupter.o`), which we treat
  /// as relative to the canonical plugin directory.
  static String _normalizePluginPath(String filename) {
    final lower = filename.toLowerCase();

    // If the firmware did return a full path from the SD root, trust it.
    if (lower.startsWith('programs/')) return filename;

    if (lower.endsWith('.lua')) return 'programs/lua/$filename';
    if (lower.endsWith('.3pot')) return 'programs/three_pot/$filename';
    // Default: compiled C++ plugins (.o) and anything unknown live in
    // /programs/plug-ins/. Subfolder paths like `corrupter/corrupter.o`
    // are relative to plug-ins.
    return 'programs/plug-ins/$filename';
  }

  static PresetDependencies analyzeDependencies(
    Map<String, dynamic> presetData,
  ) {
    final dependencies = PresetDependencies();

    if (presetData['slots'] != null) {
      for (final slot in presetData['slots']) {
        _analyzeSlot(slot, dependencies);
      }
    }

    return dependencies;
  }

  /// Algorithm GUIDs (4-char, padded with trailing space) that use
  /// `timbres[].folder` to reference a multisample folder under
  /// `/multisamples/`. All other algorithms with a `timbres[].folder`
  /// field reference a sample folder under `/samples/`.
  static const _multisampleGuids = <String>{'pyms'};

  /// Algorithm GUIDs that use a top-level `folder` field to reference a
  /// multisample folder under `/multisamples/`. `pymu` is the current
  /// Poly Multisample (firmware >= 1.10); unlike `pyms` it has no
  /// `timbres[]` array — just one folder per slot.
  static const _topLevelMultisampleGuids = <String>{'pymu'};

  /// Algorithm GUIDs that consume MIDI files from `/MIDI/`. Selection is
  /// by parameter-array index into a runtime directory listing, so we
  /// bundle the entire `MIDI/` tree and let the destination NT pick the
  /// same index.
  static const _midiUsingGuids = <String>{'midp'};

  /// Algorithm GUIDs that consume Scala / KBM tuning files from `/scl/`
  /// and `/kbm/`. Same indexed-selection rationale as `_midiUsingGuids`.
  /// Verified by scanning `docs/algorithms/*.json` for `Microtuning` /
  /// `Scala .scl` / `Scala .kbm` parameters.
  static const _scaleUsingGuids = <String>{
    'quan', // Quantizer
    'trak', // Tracker
    'ssjw', // Seaside Jawari
    'pyfm', // Poly FM
    'tuns', // Tuner (simple)
    'tunf', // Tuner (fancy)
  };

  static void _analyzeSlot(Map<String, dynamic> slot, PresetDependencies deps) {
    final rawGuid = slot['guid']?.toString();
    if (rawGuid == null) return;
    // Hardware GUIDs are 4 chars, padded with trailing spaces
    // (e.g. 'lua ' for the Lua Scripter). Trim for comparisons but
    // preserve the original for community-plugin path lookups.
    final guid = rawGuid.trim();

    // Check for community plugins (GUIDs with uppercase characters).
    // Preserve the raw GUID as that is the key the file collector
    // and database lookup match against.
    if (RegExp(r'[A-Z]').hasMatch(guid)) {
      deps.communityPlugins.add(rawGuid);
    }

    // Three Pot algorithm programs (.3pot files in /programs/three_pot/).
    if (guid == 'spin' && slot['program'] != null) {
      deps.threePotPrograms.add(slot['program']);
    }

    // Lua Script algorithm files (.lua in /programs/lua/).
    // The slot field is `program` (not `script`), and the GUID is
    // `'lua '` (with trailing space) before trimming.
    if (guid == 'lua' && slot['program'] != null) {
      deps.luaScripts.add(slot['program']);
    }

    // Wavetables (folder under /wavetables/).
    if (slot['wavetable'] != null) {
      deps.wavetables.add(slot['wavetable']);
    }

    // Sample folders, multisample folders, and FM banks from timbres.
    if (slot['timbres'] != null) {
      for (final timbre in slot['timbres']) {
        if (timbre['folder'] != null) {
          if (_multisampleGuids.contains(guid)) {
            deps.multisampleFolders.add(timbre['folder']);
          } else {
            deps.sampleFolders.add(timbre['folder']);
          }
        }
        if (timbre['bank'] != null) {
          final bank = timbre['bank'].toString();
          // Built-in FM banks are firmware-synthesized (e.g. "<built-in 2>")
          // and have no corresponding file under /FMSYX/.
          if (!bank.startsWith('<built-in')) {
            deps.fmBanks.add(bank);
          }
        }
      }
    }

    // Individual samples from triggers (sample-player style algorithms).
    // Stored as `<folder>/<sample>` relative to `/samples/`.
    //
    // The `sample` field can also hold a firmware token like `<MULTISAMPLE>`
    // — in that case the algorithm picks a file from the folder at runtime
    // by pitch/velocity/round-robin, and the destination NT needs the
    // whole folder to do the same. We treat any `<…>` token as a folder
    // reference rather than a single-file reference.
    if (slot['triggers'] != null) {
      for (final trigger in slot['triggers']) {
        final folder = trigger['folder']?.toString().trim();
        final sample = trigger['sample']?.toString().trim();
        if (folder == null || folder.isEmpty) continue;

        if (sample == null || sample.isEmpty || sample.startsWith('<')) {
          deps.sampleFolders.add(folder);
        } else {
          deps.sampleFiles.add('$folder/$sample');
        }
      }
    }

    // Granulator-style top-level sample reference (file under /samples/).
    if (slot['sample'] != null && slot['sample'].toString().trim().isNotEmpty) {
      deps.granulatorSamples.add(slot['sample']);
    }

    // Top-level `folder` field for algorithms that reference a single
    // multisample folder per slot (e.g. `pymu` Poly Multisample).
    // The `saveFolder` / `saveFilename` fields on the same slot are the
    // *record destination*, not an existing dependency, so we skip them.
    if (_topLevelMultisampleGuids.contains(guid) &&
        slot['folder'] != null &&
        slot['folder'].toString().trim().isNotEmpty) {
      deps.multisampleFolders.add(slot['folder']);
    }

    // Whole-tree bundling for algorithms that reference files by
    // parameter-array index (no name strings in the JSON to resolve).
    if (_midiUsingGuids.contains(guid)) {
      deps.bundleMidiTree = true;
    }
    if (_scaleUsingGuids.contains(guid)) {
      deps.bundleSclTree = true;
      deps.bundleKbmTree = true;
    }
  }

  /// Generate a report of what was included in the package
  static String generatePackageReport(
    PresetDependencies dependencies,
    List<CollectedFile> collectedFiles,
  ) {
    final foundFiles = collectedFiles.map((f) => f.relativePath).toSet();
    final missing = <String>[];

    // Check for missing wavetables
    for (final wavetable in dependencies.wavetables) {
      if (!foundFiles.contains('wavetables/$wavetable.wav')) {
        missing.add('wavetables/$wavetable.wav');
      }
    }

    // Check for missing Three Pot programs
    for (final program in dependencies.threePotPrograms) {
      if (!foundFiles.contains('programs/three_pot/$program')) {
        missing.add('programs/three_pot/$program');
      }
    }

    // Check for missing Lua scripts
    for (final script in dependencies.luaScripts) {
      if (!foundFiles.contains('programs/lua/$script')) {
        missing.add('programs/lua/$script');
      }
    }

    // Check for missing trigger sample files. After the `<MULTISAMPLE>`
    // fix, `sampleFiles` only contains explicit-filename triggers, so a
    // path-presence check is the right shape here.
    for (final relPath in dependencies.sampleFiles) {
      if (!foundFiles.contains('samples/$relPath')) {
        missing.add('samples/$relPath');
      }
    }

    // Check for missing sample folders. Folder-style deps (including
    // `<MULTISAMPLE>` triggers) need at least one collected file under the
    // canonical path; if none arrived, the folder genuinely doesn't exist
    // on the SD card.
    for (final folder in dependencies.sampleFolders) {
      final hasAny = foundFiles.any((p) => p.startsWith('samples/$folder/'));
      if (!hasAny) missing.add('samples/$folder/');
    }

    // Check for missing multisample folders.
    for (final folder in dependencies.multisampleFolders) {
      final hasAny = foundFiles.any(
        (p) => p.startsWith('multisamples/$folder/'),
      );
      if (!hasAny) missing.add('multisamples/$folder/');
    }

    // Check for missing granulator samples
    for (final sample in dependencies.granulatorSamples) {
      if (!foundFiles.contains('samples/$sample')) {
        missing.add('samples/$sample');
      }
    }

    // Check for missing FM banks
    for (final bank in dependencies.fmBanks) {
      if (!foundFiles.contains('FMSYX/$bank')) {
        missing.add('FMSYX/$bank');
      }
    }

    if (missing.isEmpty) {
      return 'All dependencies found! Package contains ${collectedFiles.length} files.';
    } else {
      return 'Package created with ${collectedFiles.length} files. Missing: ${missing.join(', ')}';
    }
  }
}
