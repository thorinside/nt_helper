import 'dart:io';

enum PolySampleIssue { missingRootNote, unsupportedFileType }

class PolySampleRegion {
  const PolySampleRegion({
    required this.path,
    required this.fileName,
    required this.displayName,
    this.rootMidi,
    this.rootName,
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
  final int? switchPoint;
  final int? velocityLayer;
  final int? roundRobin;
  final int? loopStart;
  final int? loopEnd;
  final List<PolySampleIssue> issues;

  bool get hasLoop => loopStart != null && loopEnd != null;

  bool get isMapped => rootMidi != null;

  PolySampleRegion copyWith({
    String? path,
    String? fileName,
    String? displayName,
    int? rootMidi,
    String? rootName,
    int? switchPoint,
    int? velocityLayer,
    int? roundRobin,
    int? loopStart,
    int? loopEnd,
    List<PolySampleIssue>? issues,
    bool clearSwitchPoint = false,
  }) {
    return PolySampleRegion(
      path: path ?? this.path,
      fileName: fileName ?? this.fileName,
      displayName: displayName ?? this.displayName,
      rootMidi: rootMidi ?? this.rootMidi,
      rootName: rootName ?? this.rootName,
      switchPoint: clearSwitchPoint ? null : switchPoint ?? this.switchPoint,
      velocityLayer: velocityLayer ?? this.velocityLayer,
      roundRobin: roundRobin ?? this.roundRobin,
      loopStart: loopStart ?? this.loopStart,
      loopEnd: loopEnd ?? this.loopEnd,
      issues: issues ?? this.issues,
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
      regions.where((region) => region.issues.isNotEmpty).length;

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
        .where((s) => s.isNotEmpty)
        .last;
  }
}
