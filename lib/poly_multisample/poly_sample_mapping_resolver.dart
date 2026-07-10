import 'dart:math' as math;

import 'package:nt_helper/poly_multisample/poly_multisample_models.dart';
import 'package:path/path.dart' as p;

enum PolySampleMappingIssueKind {
  naturalOutOfMidiRange,
  switchOutOfMidiRange,
  impossibleRange,
  naturalOutsideRange,
  variantSwitchMismatch,
  overlappingRange,
}

class PolySampleMappingIssue {
  const PolySampleMappingIssue({
    required this.kind,
    required this.mapping,
    this.other,
  });

  final PolySampleMappingIssueKind kind;
  final PolySampleResolvedMapping mapping;
  final PolySampleResolvedMapping? other;
}

class PolySampleResolvedMapping {
  const PolySampleResolvedMapping({
    required this.region,
    required this.naturalMidi,
    required this.lowMidi,
    required this.highMidi,
    required this.naturalIsAutomatic,
    required this.switchIsAutomatic,
  });

  final PolySampleRegion region;
  final int naturalMidi;
  final int? lowMidi;
  final int? highMidi;
  final bool naturalIsAutomatic;
  final bool switchIsAutomatic;

  bool get isPlayable {
    final low = lowMidi;
    final high = highMidi;
    return naturalMidi >= 0 &&
        naturalMidi <= 127 &&
        low != null &&
        high != null &&
        low >= 0 &&
        low <= 127 &&
        high >= 0 &&
        high <= 127 &&
        low <= high;
  }
}

class PolySampleMappingResolution {
  const PolySampleMappingResolution({
    required this.mappings,
    required this.byPath,
    required this.issues,
  });

  const PolySampleMappingResolution.empty()
    : mappings = const [],
      byPath = const {},
      issues = const [];

  final List<PolySampleResolvedMapping> mappings;
  final Map<String, PolySampleResolvedMapping> byPath;
  final List<PolySampleMappingIssue> issues;

  PolySampleResolvedMapping? mappingForPath(String path) => byPath[path];

  PolySampleResolvedMapping? mappingForRegion(PolySampleRegion region) {
    return mappingForPath(region.path);
  }

  List<PolySampleMappingIssue> issuesForPath(String path) {
    return List.unmodifiable(
      issues.where(
        (issue) =>
            issue.mapping.region.path == path ||
            issue.other?.region.path == path,
      ),
    );
  }

  List<PolySampleResolvedMapping> get playableMappings {
    return List.unmodifiable(mappings.where((mapping) => mapping.isPlayable));
  }

  int get mappedCount => playableMappings.length;

  int get warningCount => issues.length;

  List<int> get velocityLanes {
    final lanes =
        playableMappings
            .map((mapping) => mapping.region.velocityLayer ?? 1)
            .toSet()
            .toList()
          ..sort();
    return lanes.isEmpty ? const [1] : List.unmodifiable(lanes.reversed);
  }

  (int, int)? get midiExtents {
    final playable = playableMappings;
    if (playable.isEmpty) return null;
    var minimum = 127;
    var maximum = 0;
    for (final mapping in playable) {
      minimum = math.min(minimum, mapping.lowMidi!);
      maximum = math.max(maximum, mapping.highMidi!);
    }
    return (minimum, maximum);
  }
}

class PolySampleMappingResolver {
  const PolySampleMappingResolver();

  PolySampleMappingResolution resolve(List<PolySampleRegion> regions) {
    final sourceIndexes = <String, int>{};
    for (var index = 0; index < regions.length; index++) {
      final path = regions[index].path;
      if (sourceIndexes.containsKey(path)) {
        throw ArgumentError('Duplicate poly sample path: $path');
      }
      sourceIndexes[path] = index;
    }

    final supported = [
      for (final region in regions)
        if (!region.currentIssues.contains(PolySampleIssue.unsupportedFileType))
          region,
    ];
    final familyExactNames = <String, String>{};
    final familyForPath = <String, String>{};
    for (final region in supported) {
      if (region.rootMidi != null) continue;
      final exactKey = _rootlessFamilyKey(region.displayName);
      final foldedKey = exactKey.toLowerCase();
      familyForPath[region.path] = foldedKey;
      final currentExact = familyExactNames[foldedKey];
      if (currentExact == null || exactKey.compareTo(currentExact) < 0) {
        familyExactNames[foldedKey] = exactKey;
      }
    }

    final sortedFamilies = familyExactNames.entries.toList()
      ..sort((a, b) {
        final folded = a.key.compareTo(b.key);
        return folded != 0 ? folded : a.value.compareTo(b.value);
      });
    final automaticNaturals = <String, int>{
      for (var index = 0; index < sortedFamilies.length; index++)
        sortedFamilies[index].key: 48 + index,
    };

    final naturalForPath = <String, int>{};
    for (final region in supported) {
      naturalForPath[region.path] =
          region.rootMidi ?? automaticNaturals[familyForPath[region.path]]!;
    }
    final inRangeNaturals =
        naturalForPath.values
            .where((natural) => natural >= 0 && natural <= 127)
            .toSet()
            .toList()
          ..sort();
    final automaticLows = <int, int>{};
    for (var index = 0; index < inRangeNaturals.length; index++) {
      final natural = inRangeNaturals[index];
      automaticLows[natural] = index == 0
          ? 0
          : automaticSwitchPoint(
              lowerNatural: inRangeNaturals[index - 1],
              higherNatural: natural,
            );
    }

    final lowForPath = <String, int?>{};
    for (final region in supported) {
      final natural = naturalForPath[region.path]!;
      lowForPath[region.path] = natural < 0 || natural > 127
          ? null
          : region.switchPoint ?? automaticLows[natural];
    }
    final minimumLowByNatural = <int, int>{};
    for (final region in supported) {
      final natural = naturalForPath[region.path]!;
      final low = lowForPath[region.path];
      if (natural < 0 || natural > 127 || low == null) continue;
      final current = minimumLowByNatural[natural];
      minimumLowByNatural[natural] = current == null
          ? low
          : math.min(current, low);
    }

    final highByNatural = <int, int>{};
    for (var index = 0; index < inRangeNaturals.length; index++) {
      final natural = inRangeNaturals[index];
      highByNatural[natural] = index == inRangeNaturals.length - 1
          ? 127
          : minimumLowByNatural[inRangeNaturals[index + 1]]! - 1;
    }

    final mappings = <PolySampleResolvedMapping>[
      for (final region in supported)
        PolySampleResolvedMapping(
          region: region,
          naturalMidi: naturalForPath[region.path]!,
          lowMidi: lowForPath[region.path],
          highMidi: highByNatural[naturalForPath[region.path]],
          naturalIsAutomatic: region.rootMidi == null,
          switchIsAutomatic: region.switchPoint == null,
        ),
    ];
    final issues = _buildIssues(mappings);
    final unmodifiableMappings = List<PolySampleResolvedMapping>.unmodifiable(
      mappings,
    );
    return PolySampleMappingResolution(
      mappings: unmodifiableMappings,
      byPath: Map<String, PolySampleResolvedMapping>.unmodifiable({
        for (final mapping in unmodifiableMappings)
          mapping.region.path: mapping,
      }),
      issues: List<PolySampleMappingIssue>.unmodifiable(issues),
    );
  }

  static int automaticSwitchPoint({
    required int lowerNatural,
    required int higherNatural,
  }) {
    if (higherNatural <= lowerNatural) {
      throw ArgumentError('higherNatural must be greater than lowerNatural');
    }
    final gap = higherNatural - lowerNatural - 1;
    return lowerNatural + math.max(1, gap ~/ 2);
  }

  static String _rootlessFamilyKey(String displayName) {
    final normalized = p.posix.normalize(displayName.replaceAll('\\', '/'));
    final parent = p.posix.dirname(normalized);
    final originalStem = p.posix.basenameWithoutExtension(normalized);
    final stripped = originalStem
        .replaceAll(RegExp(r'_(?:V|RR)\d+(?=_|$)', caseSensitive: false), '')
        .replaceFirst(RegExp(r'[_\-\s]+$'), '');
    final stem = stripped.isEmpty ? originalStem : stripped;
    return parent == '.' ? stem : p.posix.join(parent, stem);
  }

  static List<PolySampleMappingIssue> _buildIssues(
    List<PolySampleResolvedMapping> mappings,
  ) {
    final issues = <PolySampleMappingIssue>[];
    for (final mapping in mappings) {
      final natural = mapping.naturalMidi;
      final low = mapping.lowMidi;
      final high = mapping.highMidi;
      if (natural < 0 || natural > 127) {
        issues.add(
          PolySampleMappingIssue(
            kind: PolySampleMappingIssueKind.naturalOutOfMidiRange,
            mapping: mapping,
          ),
        );
      }
      final switchPoint = mapping.region.switchPoint;
      if (switchPoint != null && (switchPoint < 0 || switchPoint > 127)) {
        issues.add(
          PolySampleMappingIssue(
            kind: PolySampleMappingIssueKind.switchOutOfMidiRange,
            mapping: mapping,
          ),
        );
      }
      if (low != null && high != null && low > high) {
        issues.add(
          PolySampleMappingIssue(
            kind: PolySampleMappingIssueKind.impossibleRange,
            mapping: mapping,
          ),
        );
      }
      if (natural >= 0 &&
          natural <= 127 &&
          low != null &&
          high != null &&
          (natural < low || natural > high)) {
        issues.add(
          PolySampleMappingIssue(
            kind: PolySampleMappingIssueKind.naturalOutsideRange,
            mapping: mapping,
          ),
        );
      }
    }

    for (var first = 0; first < mappings.length; first++) {
      for (var second = first + 1; second < mappings.length; second++) {
        final a = mappings[first];
        final b = mappings[second];
        if (a.naturalMidi == b.naturalMidi && a.lowMidi != b.lowMidi) {
          issues.add(
            PolySampleMappingIssue(
              kind: PolySampleMappingIssueKind.variantSwitchMismatch,
              mapping: a,
              other: b,
            ),
          );
        }
      }
    }

    for (var first = 0; first < mappings.length; first++) {
      for (var second = first + 1; second < mappings.length; second++) {
        final a = mappings[first];
        final b = mappings[second];
        if (!a.isPlayable || !b.isPlayable) continue;
        if ((a.region.velocityLayer ?? 1) != (b.region.velocityLayer ?? 1) ||
            (a.region.roundRobin ?? 1) != (b.region.roundRobin ?? 1)) {
          continue;
        }
        if (math.max(a.lowMidi!, b.lowMidi!) <=
            math.min(a.highMidi!, b.highMidi!)) {
          issues.add(
            PolySampleMappingIssue(
              kind: PolySampleMappingIssueKind.overlappingRange,
              mapping: a,
              other: b,
            ),
          );
        }
      }
    }
    return issues;
  }
}
