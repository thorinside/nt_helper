import 'dart:io';
import 'dart:isolate';

import 'package:path/path.dart' as p;

import 'poly_multisample_models.dart';
import 'poly_multisample_parser.dart';

class PolySampleFolderScanProgress {
  const PolySampleFolderScanProgress({
    required this.scannedItemCount,
    required this.audioFileCount,
    required this.ignoredFileCount,
  });

  final int scannedItemCount;
  final int audioFileCount;
  final int ignoredFileCount;
}

class PolySampleFolderScanResult {
  const PolySampleFolderScanResult({
    required this.sourcePath,
    required this.audioFileCount,
    required this.ignoredFileCount,
    required this.scannedItemCount,
    required this.largeFolderThreshold,
    required this.isLargeFolder,
    this.instrument,
  });

  final String sourcePath;
  final int audioFileCount;
  final int ignoredFileCount;
  final int scannedItemCount;
  final int largeFolderThreshold;
  final bool isLargeFolder;
  final PolySampleInstrument? instrument;

  String get summary {
    if (!isLargeFolder) {
      return 'Found $audioFileCount audio file(s).';
    }
    return 'Found $audioFileCount audio file(s), which is above the '
        '$largeFolderThreshold file review threshold.';
  }
}

class PolySampleFolderService {
  const PolySampleFolderService();

  Future<PolySampleFolderScanResult> scanLocalFolder(
    String directoryPath, {
    int largeFolderThreshold = 2000,
    bool includeLargeFolders = false,
    bool useIsolate = true,
    void Function(PolySampleFolderScanProgress progress)? onProgress,
  }) async {
    if (useIsolate && onProgress == null) {
      return Isolate.run(
        () => _scanLocalFolder(
          directoryPath,
          largeFolderThreshold: largeFolderThreshold,
          includeLargeFolders: includeLargeFolders,
        ),
      );
    }

    return _scanLocalFolder(
      directoryPath,
      largeFolderThreshold: largeFolderThreshold,
      includeLargeFolders: includeLargeFolders,
      onProgress: onProgress,
    );
  }
}

Future<PolySampleFolderScanResult> _scanLocalFolder(
  String directoryPath, {
  required int largeFolderThreshold,
  required bool includeLargeFolders,
  void Function(PolySampleFolderScanProgress progress)? onProgress,
}) async {
  final dir = Directory(directoryPath);
  final regions = <PolySampleRegion>[];
  var scannedItemCount = 0;
  var audioFileCount = 0;
  var ignoredFileCount = 0;
  var exceededLargeThreshold = false;

  await for (final entity in dir.list(recursive: true, followLinks: false)) {
    scannedItemCount++;
    if (entity is! File) {
      _emitProgress(
        onProgress,
        scannedItemCount,
        audioFileCount,
        ignoredFileCount,
      );
      continue;
    }

    final name = p.basename(entity.path);
    if (_shouldIgnoreFileName(name)) {
      ignoredFileCount++;
      _emitProgress(
        onProgress,
        scannedItemCount,
        audioFileCount,
        ignoredFileCount,
      );
      continue;
    }

    if (!PolyMultisampleParser.isSupportedAudioName(name)) {
      ignoredFileCount++;
      _emitProgress(
        onProgress,
        scannedItemCount,
        audioFileCount,
        ignoredFileCount,
      );
      continue;
    }

    audioFileCount++;
    if (audioFileCount > largeFolderThreshold) {
      exceededLargeThreshold = true;
    }

    if (!exceededLargeThreshold || includeLargeFolders) {
      final region = PolyMultisampleParser.parseFile(
        entity,
        basePath: directoryPath,
      );
      regions.add(
        region.copyWith(displayName: region.displayName.replaceAll('\\', '/')),
      );
    }

    _emitProgress(
      onProgress,
      scannedItemCount,
      audioFileCount,
      ignoredFileCount,
    );
  }

  final isLargeFolder = exceededLargeThreshold && !includeLargeFolders;
  PolySampleInstrument? instrument;
  if (!isLargeFolder) {
    PolyMultisampleParser.sortRegions(regions);
    instrument = PolySampleInstrument(
      name: PolySampleInstrument.nameFromDirectory(directoryPath),
      sourcePath: directoryPath,
      regions: regions,
    );
  }

  return PolySampleFolderScanResult(
    sourcePath: directoryPath,
    audioFileCount: audioFileCount,
    ignoredFileCount: ignoredFileCount,
    scannedItemCount: scannedItemCount,
    largeFolderThreshold: largeFolderThreshold,
    isLargeFolder: isLargeFolder,
    instrument: instrument,
  );
}

bool _shouldIgnoreFileName(String name) {
  return name == '.DS_Store' ||
      name.startsWith('._') ||
      name.endsWith('.asd') ||
      name.endsWith('.reapeaks');
}

void _emitProgress(
  void Function(PolySampleFolderScanProgress progress)? onProgress,
  int scannedItemCount,
  int audioFileCount,
  int ignoredFileCount,
) {
  onProgress?.call(
    PolySampleFolderScanProgress(
      scannedItemCount: scannedItemCount,
      audioFileCount: audioFileCount,
      ignoredFileCount: ignoredFileCount,
    ),
  );
}
