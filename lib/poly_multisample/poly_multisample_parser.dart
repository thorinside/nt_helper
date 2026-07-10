import 'dart:io';

import 'package:nt_helper/poly_multisample/poly_sample_mapping_resolver.dart';
import 'package:path/path.dart' as p;

import 'poly_multisample_models.dart';

class PolyMultisampleParser {
  static final RegExp _notePattern = RegExp(
    r'(?:^|[_\-\s])([A-Ga-g](?:#|b)?-?\d+)(?=$|[_\-\s])',
  );
  static final RegExp _switchPattern = RegExp(r'(?:^|_)SW(\d+)(?=$|_)');
  static final RegExp _velocityPattern = RegExp(r'(?:^|_)V(\d+)(?=$|_)');
  static final RegExp _roundRobinPattern = RegExp(r'(?:^|_)RR(\d+)(?=$|_)');

  static const _noteOffsets = <String, int>{
    'C': 0,
    'C#': 1,
    'DB': 1,
    'D': 2,
    'D#': 3,
    'EB': 3,
    'E': 4,
    'F': 5,
    'F#': 6,
    'GB': 6,
    'G': 7,
    'G#': 8,
    'AB': 8,
    'A': 9,
    'A#': 10,
    'BB': 10,
    'B': 11,
  };

  static const _sharpNames = [
    'C',
    'C#',
    'D',
    'D#',
    'E',
    'F',
    'F#',
    'G',
    'G#',
    'A',
    'A#',
    'B',
  ];

  static PolySampleRegion parseFile(File file, {String? basePath}) {
    final fileName = p.basename(file.path);
    final displayName = basePath == null
        ? fileName
        : p.relative(file.path, from: basePath);
    return _parseAudioPath(
      path: file.path,
      fileName: fileName,
      displayName: displayName,
    );
  }

  static PolySampleRegion parsePath(String path, {String? basePath}) {
    final normalized = path.replaceAll('\\', '/');
    final normalizedBase = basePath?.replaceAll('\\', '/');
    final fileName = p.posix.basename(normalized);
    final displayName = normalizedBase == null
        ? fileName
        : p.posix.relative(normalized, from: normalizedBase);
    return _parseAudioPath(
      path: normalized,
      fileName: fileName,
      displayName: displayName,
    );
  }

  static bool isSupportedAudioName(String fileName) {
    return isSupportedAudioNameForPolySample(fileName);
  }

  static PolySampleRegion _parseAudioPath({
    required String path,
    required String fileName,
    required String displayName,
  }) {
    final stem = p.basenameWithoutExtension(fileName).trim();
    final issues = <PolySampleIssue>[];
    final supported = isSupportedAudioNameForPolySample(fileName);
    if (!supported) {
      issues.add(PolySampleIssue.unsupportedFileType);
    }

    final rootName = _findRootName(stem);
    final rootMidi = rootName == null ? null : noteNameToMidi(rootName);
    return PolySampleRegion(
      path: path,
      fileName: fileName,
      displayName: displayName,
      rootMidi: rootMidi,
      rootName: rootMidi == null ? null : midiToNoteName(rootMidi),
      switchPoint: _parseIntTag(_switchPattern, stem),
      velocityLayer: _parseIntTag(_velocityPattern, stem),
      roundRobin: _parseIntTag(_roundRobinPattern, stem),
      issues: issues,
    );
  }

  static String? _findRootName(String stem) {
    final normalized = stem.replaceAll(RegExp(r'\s+'), '_');
    final matches = _notePattern.allMatches(normalized).toList();
    if (matches.isEmpty) return null;
    return matches.last.group(1);
  }

  static int? _parseIntTag(RegExp pattern, String stem) {
    final normalized = stem.toUpperCase();
    final match = pattern.firstMatch(normalized);
    if (match == null) return null;
    return int.tryParse(match.group(1)!);
  }

  static int? noteNameToMidi(String? noteName) {
    if (noteName == null) return null;
    final match = RegExp(r'^([A-Ga-g])([#b]?)(-?\d+)$').firstMatch(noteName);
    if (match == null) return null;
    final note =
        '${match.group(1)!.toUpperCase()}${match.group(2)!.toUpperCase()}';
    final octave = int.tryParse(match.group(3)!);
    final offset = _noteOffsets[note];
    if (octave == null || offset == null) return null;
    return (octave + 1) * 12 + offset;
  }

  static String midiToNoteName(int midi) {
    final note = _sharpNames[midi % 12];
    final octave = midi ~/ 12 - 1;
    return '$note$octave';
  }

  static void sortRegions(List<PolySampleRegion> regions) {
    final resolution = const PolySampleMappingResolver().resolve(regions);
    regions.sort((a, b) {
      final mappingA = resolution.mappingForRegion(a);
      final mappingB = resolution.mappingForRegion(b);
      final playableCompare = (mappingA?.isPlayable == true ? 0 : 1).compareTo(
        mappingB?.isPlayable == true ? 0 : 1,
      );
      if (playableCompare != 0) return playableCompare;
      final naturalCompare = (mappingA?.naturalMidi ?? 999).compareTo(
        mappingB?.naturalMidi ?? 999,
      );
      if (naturalCompare != 0) return naturalCompare;
      final velocityCompare = (a.velocityLayer ?? 1).compareTo(
        b.velocityLayer ?? 1,
      );
      if (velocityCompare != 0) return velocityCompare;
      final rrCompare = (a.roundRobin ?? 1).compareTo(b.roundRobin ?? 1);
      if (rrCompare != 0) return rrCompare;
      final foldedNameCompare = a.displayName.toLowerCase().compareTo(
        b.displayName.toLowerCase(),
      );
      if (foldedNameCompare != 0) return foldedNameCompare;
      final exactNameCompare = a.displayName.compareTo(b.displayName);
      if (exactNameCompare != 0) return exactNameCompare;
      return a.path.compareTo(b.path);
    });
  }
}

bool isSupportedAudioNameForPolySample(String fileName) {
  return isSupportedAudioName(fileName);
}
