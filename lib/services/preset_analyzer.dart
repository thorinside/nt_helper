import '../models/collected_file.dart';
import '../models/preset_dependencies.dart';

/// Analyzes preset JSON files to extract dependencies
class PresetAnalyzer {
  static PresetDependencies analyzeDependencies(
      Map<String, dynamic> presetData) {
    final dependencies = PresetDependencies();

    if (presetData['slots'] != null) {
      for (final slot in presetData['slots']) {
        _analyzeSlot(slot, dependencies);
      }
    }

    return dependencies;
  }

  static void _analyzeSlot(Map<String, dynamic> slot, PresetDependencies deps) {
    final guid = slot['guid']?.toString();
    if (guid == null) return;

    // Check for community plugins (GUIDs with uppercase characters)
    if (RegExp(r'[A-Z]').hasMatch(guid)) {
      deps.communityPlugins.add(guid);
    }

    // Three Pot algorithm programs
    if (guid == 'spin' && slot['program'] != null) {
      deps.threePotPrograms.add(slot['program']);
    }

    // Lua Script algorithm files
    if (guid == 'lua' && slot['script'] != null) {
      deps.luaScripts.add(slot['script']);
    }

    // Wavetables
    if (slot['wavetable'] != null) {
      deps.wavetables.add(slot['wavetable']);
    }

    // Sample folders and FM banks from timbres
    if (slot['timbres'] != null) {
      for (final timbre in slot['timbres']) {
        if (timbre['folder'] != null) {
          // Determine if it's a multisample or regular sample based on algorithm
          if (guid == 'pyms') {
            // Poly Multisample algorithm
            deps.multisampleFolders.add(timbre['folder']);
          } else {
            deps.sampleFolders.add(timbre['folder']);
          }
        }
        if (timbre['bank'] != null) {
          deps.fmBanks.add(timbre['bank']);
        }
      }
    }

    // Individual samples from triggers
    if (slot['triggers'] != null) {
      for (final trigger in slot['triggers']) {
        if (trigger['folder'] != null && trigger['sample'] != null) {
          deps.sampleFiles.add('${trigger['folder']}/${trigger['sample']}');
        }
      }
    }

    // Granulator samples
    if (slot['sample'] != null && slot['sample'].toString().trim().isNotEmpty) {
      deps.granulatorSamples.add(slot['sample']);
    }
  }

  /// Generate a report of what was included in the package
  static String generatePackageReport(
      PresetDependencies dependencies, List<CollectedFile> collectedFiles) {
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

    if (missing.isEmpty) {
      return 'All dependencies found! Package contains ${collectedFiles.length} files.';
    } else {
      return 'Package created with ${collectedFiles.length} files. Missing: ${missing.join(', ')}';
    }
  }
}
