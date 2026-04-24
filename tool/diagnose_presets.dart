// Diagnostic sweep over a directory of preset .json files.
//
// For every preset under the given root, runs PresetAnalyzer and then
// looks at the *raw slot JSON* for any string-valued field that *looks*
// like a file reference (has a known extension or contains a path
// separator) but did NOT end up in any of the analyzer's dependency
// sets. Those are candidates for new analyzer support — algorithm
// types whose file fields the analyzer is silently ignoring.
//
// Also reports any dependency-set entries that don't have a matching
// file on disk under the expected SD folder, so we can catch presets
// that reference files the user no longer has.
//
// Run with:
//   fvm dart run tool/diagnose_presets.dart "/Users/nealsanche/Desktop/DISTING NT"

import 'dart:convert';
import 'dart:io';

import 'package:nt_helper/services/preset_analyzer.dart';

const _fileExtensions = <String>{
  '.wav',
  '.aif',
  '.aiff',
  '.lua',
  '.elf',
  '.syx',
  '.mid',
  '.midi',
  '.3pot',
};

/// Walks an arbitrary JSON value and yields every string value paired
/// with the slash-joined path of keys/indexes that produced it.
Iterable<MapEntry<String, String>> _walkStrings(
  dynamic node, [
  String path = '',
]) sync* {
  if (node is String) {
    yield MapEntry(path, node);
  } else if (node is Map) {
    for (final entry in node.entries) {
      final next = path.isEmpty ? '${entry.key}' : '$path.${entry.key}';
      yield* _walkStrings(entry.value, next);
    }
  } else if (node is List) {
    for (var i = 0; i < node.length; i++) {
      final next = '$path[$i]';
      yield* _walkStrings(node[i], next);
    }
  }
}

bool _looksLikeFileRef(String value) {
  if (value.isEmpty) return false;
  final lower = value.toLowerCase();
  for (final ext in _fileExtensions) {
    if (lower.endsWith(ext)) return true;
  }
  // Path-like: contains a slash and at least one alpha segment, but no
  // whitespace runs typical of human-readable strings. A bare folder
  // name (no slash, no extension) won't be flagged here — analyzer
  // already pulls those out via `timbres[].folder` / `wavetable`.
  if (value.contains('/') && !value.contains(' / ')) {
    return true;
  }
  return false;
}

bool _isKnownDependency(
  String value,
  Set<String> allDeps,
) {
  if (allDeps.contains(value)) return true;
  // Some fields are stored bare (filename only) while the analyzer
  // composes paths (e.g. trigger `<folder>/<sample>`). Match by suffix
  // / containment so we don't false-positive on those.
  for (final dep in allDeps) {
    if (dep.endsWith(value) || value.endsWith(dep)) return true;
    if (dep.contains(value) || value.contains(dep)) return true;
  }
  return false;
}

void main(List<String> args) async {
  if (args.isEmpty) {
    stderr.writeln(
      'Usage: dart run tool/diagnose_presets.dart <sdcard-root>',
    );
    exit(64);
  }
  final root = Directory(args.first);
  if (!root.existsSync()) {
    stderr.writeln('Directory not found: ${root.path}');
    exit(66);
  }

  final presetsDir = Directory('${root.path}/presets');
  if (!presetsDir.existsSync()) {
    stderr.writeln('No /presets/ subfolder under ${root.path}');
    exit(66);
  }

  final presetFiles = presetsDir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.toLowerCase().endsWith('.json'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  stdout.writeln('Scanning ${presetFiles.length} preset(s) under ${presetsDir.path}\n');

  var presetsWithUnclassified = 0;
  var presetsWithMissingFiles = 0;
  final guidsWithUnclassified = <String, Set<String>>{};

  for (final file in presetFiles) {
    final relName = file.path.replaceFirst('${root.path}/', '');
    Map<String, dynamic> json;
    try {
      json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    } catch (e) {
      stdout.writeln('!! $relName — failed to parse: $e');
      continue;
    }

    final deps = PresetAnalyzer.analyzeDependencies(json);
    final allDeps = <String>{
      ...deps.wavetables,
      ...deps.sampleFolders,
      ...deps.sampleFiles,
      ...deps.granulatorSamples,
      ...deps.multisampleFolders,
      ...deps.fmBanks,
      ...deps.threePotPrograms,
      ...deps.luaScripts,
      ...deps.midiFiles,
      ...deps.communityPlugins,
    };

    // Walk every slot looking for string-valued fields that look like
    // file references but aren't in any dep set.
    final unclassified = <String, ({String guid, String value})>{};
    final slots = json['slots'];
    if (slots is List) {
      for (final slot in slots) {
        if (slot is! Map) continue;
        final guid = (slot['guid']?.toString() ?? '').trim();
        for (final entry in _walkStrings(slot)) {
          // Skip the GUID itself and the algorithm name.
          if (entry.key == 'guid' || entry.key == 'name') continue;
          final value = entry.value;
          if (!_looksLikeFileRef(value)) continue;
          if (_isKnownDependency(value, allDeps)) continue;
          unclassified[entry.key] = (guid: guid, value: value);
        }
      }
    }

    // Cross-check: do the files the analyzer claimed actually exist?
    final missing = <String>[];
    for (final w in deps.wavetables) {
      // Analyzer stores wavetable as bare name; both `.wav` and folder
      // forms exist in the wild. Treat either as present.
      final folder = Directory('${root.path}/wavetables/$w');
      final waveFile = File('${root.path}/wavetables/$w.wav');
      if (!folder.existsSync() && !waveFile.existsSync()) {
        missing.add('wavetables/$w');
      }
    }
    for (final f in deps.sampleFolders) {
      if (!Directory('${root.path}/samples/$f').existsSync()) {
        missing.add('samples/$f/');
      }
    }
    for (final p in deps.sampleFiles) {
      if (!File('${root.path}/samples/$p').existsSync()) {
        missing.add('samples/$p');
      }
    }
    for (final s in deps.granulatorSamples) {
      if (!File('${root.path}/samples/$s').existsSync()) {
        missing.add('samples/$s');
      }
    }
    for (final m in deps.multisampleFolders) {
      if (!Directory('${root.path}/multisamples/$m').existsSync()) {
        missing.add('multisamples/$m/');
      }
    }
    for (final b in deps.fmBanks) {
      if (!File('${root.path}/FMSYX/$b').existsSync()) {
        missing.add('FMSYX/$b');
      }
    }
    for (final p in deps.threePotPrograms) {
      if (!File('${root.path}/programs/three_pot/$p').existsSync()) {
        missing.add('programs/three_pot/$p');
      }
    }
    for (final s in deps.luaScripts) {
      if (!File('${root.path}/programs/lua/$s').existsSync()) {
        missing.add('programs/lua/$s');
      }
    }

    if (unclassified.isEmpty && missing.isEmpty) continue;

    stdout.writeln('-- $relName');
    if (unclassified.isNotEmpty) {
      presetsWithUnclassified++;
      stdout.writeln('   unclassified file refs (analyzer ignores these):');
      for (final entry in unclassified.entries) {
        final (:guid, :value) = entry.value;
        stdout.writeln(
          '     guid=${guid.isEmpty ? '(none)' : "'$guid'"} '
          'path=${entry.key}  value="$value"',
        );
        guidsWithUnclassified.putIfAbsent(guid, () => {}).add(entry.key);
      }
    }
    if (missing.isNotEmpty) {
      presetsWithMissingFiles++;
      stdout.writeln('   files referenced but not present on SD:');
      for (final m in missing) {
        stdout.writeln('     $m');
      }
    }
    stdout.writeln();
  }

  stdout.writeln('=== summary ===');
  stdout.writeln(
    'presets with unclassified file refs: $presetsWithUnclassified '
    '/ ${presetFiles.length}',
  );
  stdout.writeln(
    'presets with missing-on-disk deps:    $presetsWithMissingFiles '
    '/ ${presetFiles.length}',
  );
  if (guidsWithUnclassified.isNotEmpty) {
    stdout.writeln('\nunclassified-by-guid (these need analyzer support):');
    final sorted = guidsWithUnclassified.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    for (final entry in sorted) {
      stdout.writeln(
        "  '${entry.key}': ${entry.value.toList()..sort()}",
      );
    }
  }
}
