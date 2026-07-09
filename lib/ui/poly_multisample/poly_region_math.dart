import 'dart:math' as math;

import 'package:nt_helper/poly_multisample/poly_multisample_models.dart';
import 'package:nt_helper/poly_multisample/poly_multisample_parser.dart';
import 'package:nt_helper/ui/poly_multisample/poly_multisample_builder_cubit.dart';
import 'package:path/path.dart' as p;

int effectiveLow(PolySampleRegion region) {
  return (region.rangeLow ?? region.switchPoint ?? region.rootMidi ?? 0)
      .clamp(0, 127)
      .toInt();
}

int effectiveHigh(PolySampleRegion region, List<PolySampleRegion> regions) {
  final explicit = region.rangeHigh;
  if (explicit != null) return explicit.clamp(0, 127).toInt();
  final low = effectiveLow(region);
  final velocity = region.velocityLayer ?? 1;
  final laterLows =
      regions
          .where(
            (candidate) =>
                candidate.rootMidi != null &&
                (candidate.velocityLayer ?? 1) == velocity &&
                effectiveLow(candidate) > low,
          )
          .map(effectiveLow)
          .toList()
        ..sort();
  if (laterLows.isEmpty) return 127;
  return math.max(low, laterLows.first - 1);
}

(int, int)? midiExtents(List<PolySampleRegion> regions) {
  final mapped = regions.where((region) => region.rootMidi != null).toList();
  if (mapped.isEmpty) return null;
  var minMidi = 127;
  var maxMidi = 0;
  for (final region in mapped) {
    minMidi = math.min(minMidi, effectiveLow(region));
    maxMidi = math.max(maxMidi, effectiveHigh(region, regions));
    minMidi = math.min(minMidi, region.rootMidi!);
    maxMidi = math.max(maxMidi, region.rootMidi!);
  }
  return (minMidi, maxMidi);
}

List<int> velocityLanes(List<PolySampleRegion> regions) {
  final lanes =
      regions
          .where((region) => region.rootMidi != null)
          .map((region) => region.velocityLayer ?? 1)
          .toSet()
          .toList()
        ..sort();
  return lanes.isEmpty ? const [1] : lanes.reversed.toList();
}

List<String> mappingWarnings(List<PolySampleRegion> regions) {
  final warnings = <String>[];

  int lowFor(PolySampleRegion region) {
    return (region.rangeLow ?? region.switchPoint ?? region.rootMidi ?? 0)
        .clamp(0, 127)
        .toInt();
  }

  int highFor(PolySampleRegion region) {
    final explicit = region.rangeHigh;
    if (explicit != null) return explicit.clamp(0, 127).toInt();
    final low = lowFor(region);
    final velocity = region.velocityLayer ?? 1;
    final rr = region.roundRobin ?? 1;
    final laterLows =
        regions
            .where(
              (candidate) =>
                  candidate.rootMidi != null &&
                  (candidate.velocityLayer ?? 1) == velocity &&
                  (candidate.roundRobin ?? 1) == rr &&
                  lowFor(candidate) > low,
            )
            .map(lowFor)
            .toList()
          ..sort();
    if (laterLows.isEmpty) return 127;
    return math.max(low, laterLows.first - 1);
  }

  for (final region in regions) {
    final low = lowFor(region);
    final high = highFor(region);
    if (low > high) {
      warnings.add(
        'Mapping impossible: ${region.displayName} has low ${_noteLabel(low)} above high ${_noteLabel(high)}.',
      );
    }
  }
  for (final region in regions) {
    final root = region.rootMidi;
    if (root == null) continue;
    final low = lowFor(region);
    final high = highFor(region);
    if (root < low || root > high) {
      warnings.add(
        'Mapping impossible: ${region.displayName} root ${_noteLabel(root)} is outside ${_noteLabel(low)}–${_noteLabel(high)}.',
      );
    }
  }
  for (var i = 0; i < regions.length; i++) {
    final a = regions[i];
    if (a.rootMidi == null) continue;
    final lowA = lowFor(a);
    final highA = highFor(a);
    final velocityA = a.velocityLayer ?? 1;
    final rrA = a.roundRobin ?? 1;
    for (var j = i + 1; j < regions.length; j++) {
      final b = regions[j];
      if (b.rootMidi == null) continue;
      if ((b.velocityLayer ?? 1) != velocityA || (b.roundRobin ?? 1) != rrA) {
        continue;
      }
      final lowB = lowFor(b);
      final highB = highFor(b);
      final overlapLow = math.max(lowA, lowB);
      final overlapHigh = math.min(highA, highB);
      if (overlapLow <= overlapHigh) {
        warnings.add(
          'Mapping overlap: ${a.displayName} overlaps ${b.displayName} on velocity $velocityA, RR $rrA.',
        );
      }
    }
  }

  return warnings;
}

String _noteLabel(int midi) => PolyMultisampleParser.midiToNoteName(midi);

PolySampleRegion? selectedRegionFor(PolyMultisampleBuilderState state) {
  final focused = state.focusedPath;
  if (focused != null) {
    for (final region in state.editedRegions) {
      if (region.path == focused) return region;
    }
  }
  if (state.selectedPaths.isNotEmpty) {
    final path = state.selectedPaths.first;
    for (final region in state.editedRegions) {
      if (region.path == path) return region;
    }
  }
  return null;
}

String sampleDisplayLabel(
  PolySampleRegion region,
  List<PolySampleRegion> regions,
) {
  final duplicatePaths = [
    for (final candidate in regions)
      if (candidate.displayName == region.displayName) candidate.path,
  ];
  if (duplicatePaths.length < 2) return region.displayName;
  final normalizedPath = p.normalize(region.path);
  final commonRoot = _commonDirectory(duplicatePaths.map(p.normalize));
  final label = p.relative(normalizedPath, from: commonRoot);
  return label == '.' ? region.displayName : label.replaceAll('\\', '/');
}

String _commonDirectory(Iterable<String> paths) {
  final splitPaths = [for (final path in paths) p.split(p.dirname(path))];
  if (splitPaths.isEmpty) return '.';
  final common = <String>[];
  for (var index = 0; index < splitPaths.first.length; index++) {
    final segment = splitPaths.first[index];
    if (splitPaths.every(
      (parts) => index < parts.length && parts[index] == segment,
    )) {
      common.add(segment);
    } else {
      break;
    }
  }
  if (common.isEmpty) return '.';
  return p.joinAll(common);
}
