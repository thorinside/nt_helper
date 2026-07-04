import 'dart:io';

enum PolySampleIssue { missingRootNote, unsupportedFileType }

class PolySampleRegion {
  const PolySampleRegion({
    required this.path,
    required this.fileName,
    required this.displayName,
    this.rootMidi,
    this.rootName,
    this.rangeLow,
    this.rangeHigh,
    this.switchPoint,
    this.velocityLayer,
    this.roundRobin,
    this.loopStart,
    this.loopEnd,
    this.issues = const [],
  });

  final String path;
  final String fileName;
  final String displayName;
  final int? rootMidi;
  final String? rootName;
  final int? rangeLow;
  final int? rangeHigh;
  final int? switchPoint;
  final int? velocityLayer;
  final int? roundRobin;
  final int? loopStart;
  final int? loopEnd;
  final List<PolySampleIssue> issues;

  List<PolySampleIssue> get currentIssues {
    final current = <PolySampleIssue>[];
    final supported = isSupportedAudioName(fileName);
    if (!supported || issues.contains(PolySampleIssue.unsupportedFileType)) {
      current.add(PolySampleIssue.unsupportedFileType);
    }
    if (rootMidi == null && supported) {
      current.add(PolySampleIssue.missingRootNote);
    }
    return current;
  }

  bool get hasLoop => loopStart != null && loopEnd != null;

  bool get isMapped => rootMidi != null;

  PolySampleRegion copyWith({
    String? path,
    String? fileName,
    String? displayName,
    int? rootMidi,
    String? rootName,
    int? rangeLow,
    int? rangeHigh,
    int? switchPoint,
    int? velocityLayer,
    int? roundRobin,
    int? loopStart,
    int? loopEnd,
    List<PolySampleIssue>? issues,
    bool clearRoot = false,
    bool clearRangeLow = false,
    bool clearRangeHigh = false,
    bool clearSwitchPoint = false,
    bool clearVelocityLayer = false,
    bool clearRoundRobin = false,
    bool clearLoop = false,
  }) {
    final next = PolySampleRegion(
      path: path ?? this.path,
      fileName: fileName ?? this.fileName,
      displayName: displayName ?? this.displayName,
      rootMidi: clearRoot ? null : rootMidi ?? this.rootMidi,
      rootName: clearRoot ? null : rootName ?? this.rootName,
      rangeLow: clearRangeLow ? null : rangeLow ?? this.rangeLow,
      rangeHigh: clearRangeHigh ? null : rangeHigh ?? this.rangeHigh,
      switchPoint: clearSwitchPoint ? null : switchPoint ?? this.switchPoint,
      velocityLayer: clearVelocityLayer
          ? null
          : velocityLayer ?? this.velocityLayer,
      roundRobin: clearRoundRobin ? null : roundRobin ?? this.roundRobin,
      loopStart: clearLoop ? null : loopStart ?? this.loopStart,
      loopEnd: clearLoop ? null : loopEnd ?? this.loopEnd,
      issues: issues ?? this.issues,
    );
    return next.copyWithIssues(next.currentIssues);
  }

  PolySampleRegion copyWithIssues(List<PolySampleIssue> issues) {
    return PolySampleRegion(
      path: path,
      fileName: fileName,
      displayName: displayName,
      rootMidi: rootMidi,
      rootName: rootName,
      rangeLow: rangeLow,
      rangeHigh: rangeHigh,
      switchPoint: switchPoint,
      velocityLayer: velocityLayer,
      roundRobin: roundRobin,
      loopStart: loopStart,
      loopEnd: loopEnd,
      issues: issues,
    );
  }
}

class PolySampleInstrument {
  const PolySampleInstrument({
    required this.name,
    required this.sourcePath,
    required this.regions,
  });

  final String name;
  final String sourcePath;
  final List<PolySampleRegion> regions;

  int get mappedCount => regions.where((region) => region.isMapped).length;

  int get warningCount =>
      regions.where((region) => region.currentIssues.isNotEmpty).length;

  List<int> get velocityLayers {
    final layers = regions
        .map((region) => region.velocityLayer ?? 1)
        .toSet()
        .toList();
    layers.sort();
    return layers;
  }

  PolySampleInstrument copyWith({
    String? name,
    String? sourcePath,
    List<PolySampleRegion>? regions,
  }) {
    return PolySampleInstrument(
      name: name ?? this.name,
      sourcePath: sourcePath ?? this.sourcePath,
      regions: regions ?? this.regions,
    );
  }

  static String nameFromDirectory(String path) {
    final normalized = path.replaceAll('\\', Platform.pathSeparator);
    return normalized
        .split(Platform.pathSeparator)
        .where((segment) => segment.isNotEmpty)
        .last;
  }
}

class PolySampleFileAddition {
  const PolySampleFileAddition({
    required this.sourcePath,
    required this.toPath,
    required this.region,
  });

  final String sourcePath;
  final String toPath;
  final PolySampleRegion region;
}

class PolySampleFileRemoval {
  const PolySampleFileRemoval({required this.path, required this.region});

  final String path;
  final PolySampleRegion region;
}

class PolySampleFileRename {
  const PolySampleFileRename({
    required this.fromPath,
    required this.toPath,
    required this.region,
  });

  final String fromPath;
  final String toPath;
  final PolySampleRegion region;
}

class PolySampleApplyConflict {
  const PolySampleApplyConflict({required this.path, required this.message});

  final String path;
  final String message;
}

class PolySampleApplyPlan {
  const PolySampleApplyPlan({
    this.additions = const [],
    this.removals = const [],
    this.renames = const [],
    this.conflicts = const [],
  });

  final List<PolySampleFileAddition> additions;
  final List<PolySampleFileRemoval> removals;
  final List<PolySampleFileRename> renames;
  final List<PolySampleApplyConflict> conflicts;

  bool get hasConflicts => conflicts.isNotEmpty;

  bool get hasChanges =>
      additions.isNotEmpty || removals.isNotEmpty || renames.isNotEmpty;
}

class PolyWaveformDraft {
  const PolyWaveformDraft({
    this.loopStart,
    this.loopEnd,
    this.trimStart,
    this.trimEnd,
    this.fadeInFrames = 0,
    this.fadeOutFrames = 0,
    this.gainDb = 0,
    this.normalizePeakDb,
  });

  final int? loopStart;
  final int? loopEnd;
  final int? trimStart;
  final int? trimEnd;
  final int fadeInFrames;
  final int fadeOutFrames;
  final double gainDb;
  final double? normalizePeakDb;
}

class PolyStagedImport {
  const PolyStagedImport({
    required this.name,
    required this.sourceLabel,
    required this.regions,
    this.tempRoots = const [],
    this.warnings = const [],
  });

  final String name;
  final String sourceLabel;
  final List<PolySampleRegion> regions;
  final List<String> tempRoots;
  final List<String> warnings;
}

enum PolyLooseWavMappingMode {
  preserve,
  unmapped,
  chromaticSpread,
  roundRobinStack,
  velocityLayers,
}

class PolyLooseWavMappingOptions {
  const PolyLooseWavMappingOptions({
    this.mode = PolyLooseWavMappingMode.preserve,
    this.startMidi = 60,
  });

  final PolyLooseWavMappingMode mode;
  final int startMidi;
}

bool isSupportedAudioName(String fileName) {
  final lower = fileName.toLowerCase();
  return lower.endsWith('.wav') ||
      lower.endsWith('.aif') ||
      lower.endsWith('.aiff');
}
