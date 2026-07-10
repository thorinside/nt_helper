import 'dart:io';

import 'package:path/path.dart' as p;

import 'decent_sampler_converter.dart';
import 'poly_multisample_models.dart';
import 'poly_multisample_parser.dart';
import 'poly_sample_folder_service.dart';

class PolySampleImportService {
  PolySampleImportService({
    DecentSamplerConverter? decentConverter,
    PolySampleFolderService? folderService,
  }) : _decentConverter = decentConverter ?? DecentSamplerConverter(),
       _folderService = folderService ?? const PolySampleFolderService();

  final DecentSamplerConverter _decentConverter;
  final PolySampleFolderService _folderService;

  Future<DecentSamplerImportAnalysis> analyzeDecentSource(String path) {
    return _decentConverter.analyze(sourcePath: path);
  }

  Future<PolyStagedImport> stageDecentSource(
    String path, {
    DecentSamplerConvertOptions options = const DecentSamplerConvertOptions(),
    String? outputParentPath,
  }) async {
    final tempRoot =
        outputParentPath == null
              ? await Directory.systemTemp.createTemp('nt_helper_poly_decent_')
              : Directory(outputParentPath)
          ..createSync(recursive: true);
    final result = await _decentConverter.convert(
      sourcePath: path,
      outputParentPath: tempRoot.path,
      options: options,
    );
    final regions = <PolySampleRegion>[];
    for (final folder in result.outputFolders) {
      final scan = await _folderService.scanLocalFolder(
        folder,
        includeLargeFolders: true,
      );
      regions.addAll(scan.instrument?.regions ?? const []);
    }
    PolyMultisampleParser.sortRegions(regions);
    return PolyStagedImport(
      name: result.outputFolders.isEmpty
          ? _sourceName(path)
          : p.basename(result.outputFolders.first),
      sourceLabel: path,
      regions: regions,
      tempRoots: [tempRoot.path],
      warnings: [...result.warnings, ...result.decisions],
    );
  }

  Future<PolyStagedImport> stageLooseFolder(
    String path,
    PolyLooseWavMappingOptions options,
  ) async {
    final scan = await _folderService.scanLocalFolder(
      path,
      includeLargeFolders: true,
    );
    final regions = _applyLooseMapping(
      scan.instrument?.regions ?? const [],
      options,
    );
    return PolyStagedImport(
      name: PolySampleInstrument.nameFromDirectory(path),
      sourceLabel: path,
      regions: regions,
      warnings: scan.isLargeFolder ? [scan.summary] : const [],
    );
  }

  Future<PolyStagedImport> stageLooseFiles(
    List<String> paths,
    PolyLooseWavMappingOptions options,
  ) async {
    final regions = <PolySampleRegion>[];
    final warnings = <String>[];
    for (final path in paths) {
      final name = p.basename(path);
      if (!PolyMultisampleParser.isSupportedAudioName(name)) {
        warnings.add('Ignored unsupported file $name.');
        continue;
      }
      regions.add(PolyMultisampleParser.parseFile(File(path)));
    }
    PolyMultisampleParser.sortRegions(regions);
    return PolyStagedImport(
      name: _looseImportName(paths),
      sourceLabel: paths.length == 1 ? paths.single : '${paths.length} files',
      regions: _applyLooseMapping(regions, options),
      warnings: warnings,
    );
  }

  Future<void> cleanupOwnedTempRoots(List<String> tempRoots) async {
    for (final root in tempRoots) {
      final dir = Directory(root);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    }
  }

  List<PolySampleRegion> _applyLooseMapping(
    List<PolySampleRegion> regions,
    PolyLooseWavMappingOptions options,
  ) {
    final sorted = List<PolySampleRegion>.from(regions);
    PolyMultisampleParser.sortRegions(sorted);
    return switch (options.mode) {
      PolyLooseWavMappingMode.preserve => sorted,
      PolyLooseWavMappingMode.automaticNotes => [
        for (final region in sorted)
          region.copyWith(clearRoot: true, clearSwitchPoint: true),
      ],
      PolyLooseWavMappingMode.chromaticSpread => [
        for (var i = 0; i < sorted.length; i++)
          sorted[i].copyWith(
            rootMidi: options.startMidi + i,
            rootName: PolyMultisampleParser.midiToNoteName(
              options.startMidi + i,
            ),
            clearSwitchPoint: true,
            clearVelocityLayer: true,
            clearRoundRobin: true,
          ),
      ],
      PolyLooseWavMappingMode.roundRobinStack => [
        for (var i = 0; i < sorted.length; i++)
          sorted[i].copyWith(
            rootMidi: options.startMidi,
            rootName: PolyMultisampleParser.midiToNoteName(options.startMidi),
            roundRobin: i + 1,
            clearSwitchPoint: true,
            clearVelocityLayer: true,
          ),
      ],
      PolyLooseWavMappingMode.velocityLayers => [
        for (var i = 0; i < sorted.length; i++)
          sorted[i].copyWith(
            rootMidi: options.startMidi,
            rootName: PolyMultisampleParser.midiToNoteName(options.startMidi),
            velocityLayer: i + 1,
            clearSwitchPoint: true,
            clearRoundRobin: true,
          ),
      ],
    };
  }
}

String _sourceName(String path) {
  final source = FileSystemEntity.isDirectorySync(path)
      ? p.basename(path)
      : p.basenameWithoutExtension(path);
  return source.trim().isEmpty ? 'Imported Samples' : source;
}

String _looseImportName(List<String> paths) {
  if (paths.isEmpty) return 'Loose WAV Import';
  final parents = {for (final path in paths) p.dirname(path)};
  if (parents.length == 1) {
    return PolySampleInstrument.nameFromDirectory(parents.single);
  }
  return 'Loose WAV Import';
}
