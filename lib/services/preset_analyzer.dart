import '../models/collected_file.dart';
import '../models/preset_dependencies.dart';
import '../domain/disting_nt_sysex.dart';

/// Analyzes preset JSON files to extract dependencies
class PresetAnalyzer {
  /// Extracts plugin file paths from AlgorithmInfo objects.
  /// Call this with live slot data to populate pluginPaths for direct SD card reads.
  /// Returns a map of plugin GUID to SD card file path.
  static Map<String, String> extractPluginPaths(
    List<AlgorithmInfo> algorithmInfos,
  ) {
    final paths = <String, String>{};
    for (final info in algorithmInfos) {
      if (info.isPlugin && info.filename != null && info.filename!.isNotEmpty) {
        paths[info.guid] = info.filename!;
      }
    }
    return paths;
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
    if (slot['triggers'] != null) {
      for (final trigger in slot['triggers']) {
        if (trigger['folder'] != null && trigger['sample'] != null) {
          deps.sampleFiles.add('${trigger['folder']}/${trigger['sample']}');
        }
      }
    }

    // Granulator-style top-level sample reference (file under /samples/).
    if (slot['sample'] != null && slot['sample'].toString().trim().isNotEmpty) {
      deps.granulatorSamples.add(slot['sample']);
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

    // Check for missing trigger sample files
    for (final relPath in dependencies.sampleFiles) {
      if (!foundFiles.contains('samples/$relPath')) {
        missing.add('samples/$relPath');
      }
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
