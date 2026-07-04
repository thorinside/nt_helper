import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/poly_multisample/poly_sample_folder_service.dart';

void main() {
  group('PolySampleFolderService', () {
    late Directory tempRoot;

    setUp(() {
      tempRoot = Directory.systemTemp.createTempSync(
        'poly_sample_folder_service_test_',
      );
    });

    tearDown(() {
      if (tempRoot.existsSync()) {
        tempRoot.deleteSync(recursive: true);
      }
    });

    test('scans local folders recursively and ignores sidecars', () async {
      final folder = Directory('${tempRoot.path}/SoftPiano')
        ..createSync(recursive: true);
      final nested = Directory('${folder.path}/Layer A')..createSync();
      File(
        '${folder.path}/SoftPiano_C3_SW48_V2_RR3.wav',
      ).writeAsBytesSync(const []);
      File('${nested.path}/SoftPiano_D3_V1.aif').writeAsBytesSync(const []);
      File('${folder.path}/.DS_Store').writeAsStringSync('junk');
      File('${folder.path}/._SoftPiano_E3.wav').writeAsBytesSync(const []);
      File('${folder.path}/notes.txt').writeAsStringSync('ignore me');

      final progressEvents = <PolySampleFolderScanProgress>[];

      final result = await PolySampleFolderService().scanLocalFolder(
        folder.path,
        onProgress: progressEvents.add,
      );

      expect(result.isLargeFolder, isFalse);
      expect(result.audioFileCount, 2);
      expect(result.ignoredFileCount, 3);
      expect(result.instrument, isNotNull);
      expect(result.instrument!.name, 'SoftPiano');
      expect(result.instrument!.regions.map((region) => region.displayName), [
        'SoftPiano_C3_SW48_V2_RR3.wav',
        'Layer A/SoftPiano_D3_V1.aif',
      ]);
      expect(result.instrument!.regions.first.rootMidi, 48);
      expect(result.instrument!.regions.first.switchPoint, 48);
      expect(result.instrument!.regions.first.velocityLayer, 2);
      expect(result.instrument!.regions.first.roundRobin, 3);
      expect(progressEvents, isNotEmpty);
      expect(progressEvents.last.audioFileCount, 2);
    });

    test('returns a large-folder summary above the threshold', () async {
      final folder = Directory('${tempRoot.path}/Huge')..createSync();
      File('${folder.path}/Huge_C3.wav').writeAsBytesSync(const []);
      File('${folder.path}/Huge_D3.wav').writeAsBytesSync(const []);

      final result = await PolySampleFolderService().scanLocalFolder(
        folder.path,
        largeFolderThreshold: 1,
      );

      expect(result.isLargeFolder, isTrue);
      expect(result.largeFolderThreshold, 1);
      expect(result.audioFileCount, 2);
      expect(result.instrument, isNull);
    });
  });
}
