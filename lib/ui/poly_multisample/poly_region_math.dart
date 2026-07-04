import 'dart:math' as math;

import 'package:nt_helper/poly_multisample/poly_multisample_models.dart';
import 'package:nt_helper/ui/poly_multisample/poly_multisample_builder_cubit.dart';

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
  return state.editedRegions.isEmpty ? null : state.editedRegions.first;
}
