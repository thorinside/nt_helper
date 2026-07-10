import 'package:nt_helper/poly_multisample/poly_multisample_models.dart';
import 'package:nt_helper/poly_multisample/poly_multisample_parser.dart';
import 'package:nt_helper/poly_multisample/poly_sample_mapping_resolver.dart';
import 'package:nt_helper/ui/poly_multisample/poly_multisample_builder_cubit.dart';
import 'package:path/path.dart' as p;

List<String> mappingWarningMessages(
  List<PolySampleRegion> regions,
  PolySampleMappingResolution resolution,
) {
  final messages = <String>[
    for (final region in regions)
      if (region.currentIssues.contains(PolySampleIssue.unsupportedFileType))
        'Unsupported sample: ${region.displayName} has an unsupported file type.',
  ];
  for (final issue in resolution.issues) {
    final mapping = issue.mapping;
    final region = mapping.region;
    final other = issue.other;
    messages.add(switch (issue.kind) {
      PolySampleMappingIssueKind.naturalOutOfMidiRange =>
        'Mapping impossible: ${region.displayName} natural MIDI ${mapping.naturalMidi} is outside 0-127.',
      PolySampleMappingIssueKind.switchOutOfMidiRange =>
        'Mapping impossible: ${region.displayName} Low MIDI ${region.switchPoint} is outside 0-127.',
      PolySampleMappingIssueKind.impossibleRange =>
        'Mapping impossible: ${region.displayName} has low ${_noteLabel(mapping.lowMidi!)} above high ${_noteLabel(mapping.highMidi!)}.',
      PolySampleMappingIssueKind.naturalOutsideRange =>
        'Mapping impossible: ${region.displayName} natural ${_noteLabel(mapping.naturalMidi)} is outside ${_noteLabel(mapping.lowMidi!)} to ${_noteLabel(mapping.highMidi!)}.',
      PolySampleMappingIssueKind.variantSwitchMismatch =>
        'Mapping mismatch: ${region.displayName} and ${other!.region.displayName} share natural ${_noteLabel(mapping.naturalMidi)} but use different Low values.',
      PolySampleMappingIssueKind.overlappingRange =>
        'Mapping overlap: ${region.displayName} overlaps ${other!.region.displayName} on velocity ${region.velocityLayer ?? 1}, RR ${region.roundRobin ?? 1}.',
    });
  }
  return messages;
}

String _noteLabel(int midi) => midi >= 0 && midi <= 127
    ? PolyMultisampleParser.midiToNoteName(midi)
    : 'MIDI $midi';

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
