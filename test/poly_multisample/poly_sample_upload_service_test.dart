import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nt_helper/domain/i_disting_midi_manager.dart';
import 'package:nt_helper/models/sd_card_file_system.dart';
import 'package:nt_helper/poly_multisample/poly_multisample_models.dart';
import 'package:nt_helper/poly_multisample/poly_sample_upload_service.dart';

class MockDistingMidiManager extends Mock implements IDistingMidiManager {}

void main() {
  late Directory tempRoot;
  late PolySampleUploadService service;

  setUpAll(() {
    registerFallbackValue(Uint8List(0));
  });

  setUp(() {
    tempRoot = Directory.systemTemp.createTempSync(
      'poly_sample_upload_service_test_',
    );
    service = const PolySampleUploadService();
  });

  tearDown(() {
    if (tempRoot.existsSync()) {
      tempRoot.deleteSync(recursive: true);
    }
  });

  test('buildUploadFiles rejects duplicate target names', () {
    final sourceA = File('${tempRoot.path}/a/Piano_C3.wav')
      ..createSync(recursive: true);
    final sourceB = File('${tempRoot.path}/b/Piano_C3.wav')
      ..createSync(recursive: true);

    expect(
      () => service.buildUploadFiles(
        regions: [
          PolySampleRegion(
            path: sourceA.path,
            fileName: 'Piano_C3.wav',
            displayName: 'Piano_C3.wav',
            rootMidi: 48,
          ),
          PolySampleRegion(
            path: sourceB.path,
            fileName: 'Piano_C3.wav',
            displayName: 'Piano_C3.wav',
            rootMidi: 48,
          ),
        ],
        targetFolder: '${tempRoot.path}/dest',
      ),
      throwsA(
        isA<PolySampleUploadException>().having(
          (error) => error.message,
          'message',
          contains('Multiple samples target Piano_C3.wav'),
        ),
      ),
    );
  });

  test(
    'uploadMountedSd copies renamed files and preserves unrelated files',
    () async {
      final sourceDir = Directory('${tempRoot.path}/source')..createSync();
      final destinationDir = Directory('${tempRoot.path}/dest')..createSync();
      final source = File('${sourceDir.path}/Piano_C3.wav')
        ..writeAsBytesSync([1, 2, 3]);
      final target = File('${destinationDir.path}/Piano_C3.wav')
        ..writeAsBytesSync([9, 9, 9]);
      final unrelated = File('${destinationDir.path}/unrelated.txt')
        ..writeAsStringSync('keep');

      await service.uploadMountedSd(
        regions: [
          PolySampleRegion(
            path: source.path,
            fileName: 'Piano_C3.wav',
            displayName: 'Piano_C3.wav',
            rootMidi: 48,
          ),
        ],
        destinationFolder: destinationDir.path,
      );

      expect(await target.readAsBytes(), [1, 2, 3]);
      expect(unrelated.existsSync(), isTrue);
    },
  );

  test(
    'uploadMountedSd skips same source and target path without deleting',
    () async {
      final destinationDir = Directory('${tempRoot.path}/dest')..createSync();
      final source = File('${destinationDir.path}/Piano_C3.wav')
        ..writeAsBytesSync([1, 2, 3]);

      await service.uploadMountedSd(
        regions: [
          PolySampleRegion(
            path: source.path,
            fileName: 'Piano_C3.wav',
            displayName: 'Piano_C3.wav',
            rootMidi: 48,
          ),
        ],
        destinationFolder: destinationDir.path,
      );

      expect(await source.readAsBytes(), [1, 2, 3]);
    },
  );

  test('uploadSysEx creates parents uploads and verifies bytes', () async {
    final manager = MockDistingMidiManager();
    final source = File('${tempRoot.path}/Piano_C3.wav')
      ..writeAsBytesSync([1, 2, 3]);
    when(
      () => manager.requestDirectoryCreate(any()),
    ).thenAnswer((_) async => SdCardStatus(success: true, message: 'created'));
    when(
      () => manager.requestFileUpload(any(), any()),
    ).thenAnswer((_) async => SdCardStatus(success: true, message: 'uploaded'));
    when(
      () => manager.requestFileDownload('/samples/Piano/Nested/Piano_C3.wav'),
    ).thenAnswer((_) async => Uint8List.fromList([1, 2, 3]));

    final result = await service.uploadSysEx(
      manager: manager,
      regions: [
        PolySampleRegion(
          path: source.path,
          fileName: 'Piano_C3.wav',
          displayName: 'Piano_C3.wav',
          rootMidi: 48,
        ),
      ],
      hardwareFolder: '/samples/Piano/Nested',
    );

    verify(() => manager.requestDirectoryCreate('/samples/Piano')).called(1);
    verify(
      () => manager.requestDirectoryCreate('/samples/Piano/Nested'),
    ).called(1);
    verify(
      () => manager.requestFileUpload(
        '/samples/Piano/Nested/Piano_C3.wav',
        any(),
      ),
    ).called(1);
    expect(result.correctedFiles, 0);
  });

  test('uploadSysEx corrects mismatched hardware bytes once', () async {
    final manager = MockDistingMidiManager();
    final source = File('${tempRoot.path}/Piano_C3.wav')
      ..writeAsBytesSync([1, 2, 3]);
    var downloadCount = 0;
    when(
      () => manager.requestDirectoryCreate(any()),
    ).thenAnswer((_) async => SdCardStatus(success: true, message: 'created'));
    when(
      () => manager.requestFileUpload(any(), any()),
    ).thenAnswer((_) async => SdCardStatus(success: true, message: 'uploaded'));
    when(
      () => manager.requestFileDownload('/samples/Piano/Piano_C3.wav'),
    ).thenAnswer((_) async {
      downloadCount++;
      return Uint8List.fromList(downloadCount == 1 ? [9, 9, 9] : [1, 2, 3]);
    });

    final result = await service.uploadSysEx(
      manager: manager,
      regions: [
        PolySampleRegion(
          path: source.path,
          fileName: 'Piano_C3.wav',
          displayName: 'Piano_C3.wav',
          rootMidi: 48,
        ),
      ],
      hardwareFolder: '/samples/Piano',
    );

    verify(
      () => manager.requestFileUpload('/samples/Piano/Piano_C3.wav', any()),
    ).called(2);
    expect(result.correctedFiles, 1);
  });

  test(
    'uploadSysEx throws when verification still differs after correction',
    () async {
      final manager = MockDistingMidiManager();
      final source = File('${tempRoot.path}/Piano_C3.wav')
        ..writeAsBytesSync([1, 2, 3]);
      when(() => manager.requestDirectoryCreate(any())).thenAnswer(
        (_) async => SdCardStatus(success: true, message: 'created'),
      );
      when(() => manager.requestFileUpload(any(), any())).thenAnswer(
        (_) async => SdCardStatus(success: true, message: 'uploaded'),
      );
      when(
        () => manager.requestFileDownload('/samples/Piano/Piano_C3.wav'),
      ).thenAnswer((_) async => Uint8List.fromList([9, 9, 9]));

      expect(
        () => service.uploadSysEx(
          manager: manager,
          regions: [
            PolySampleRegion(
              path: source.path,
              fileName: 'Piano_C3.wav',
              displayName: 'Piano_C3.wav',
              rootMidi: 48,
            ),
          ],
          hardwareFolder: '/samples/Piano',
        ),
        throwsA(
          isA<PolySampleUploadException>().having(
            (error) => error.message,
            'message',
            contains('Verification failed for /samples/Piano/Piano_C3.wav'),
          ),
        ),
      );
    },
  );

  test('uploadSysEx treats null download as a correctable mismatch', () async {
    final manager = MockDistingMidiManager();
    final source = File('${tempRoot.path}/Piano_C3.wav')
      ..writeAsBytesSync([1, 2, 3]);
    var downloadCount = 0;
    when(
      () => manager.requestDirectoryCreate(any()),
    ).thenAnswer((_) async => SdCardStatus(success: true, message: 'created'));
    when(
      () => manager.requestFileUpload(any(), any()),
    ).thenAnswer((_) async => SdCardStatus(success: true, message: 'uploaded'));
    when(
      () => manager.requestFileDownload('/samples/Piano/Piano_C3.wav'),
    ).thenAnswer((_) async {
      downloadCount++;
      if (downloadCount == 1) return null;
      return Uint8List.fromList([1, 2, 3]);
    });

    final result = await service.uploadSysEx(
      manager: manager,
      regions: [
        PolySampleRegion(
          path: source.path,
          fileName: 'Piano_C3.wav',
          displayName: 'Piano_C3.wav',
          rootMidi: 48,
        ),
      ],
      hardwareFolder: '/samples/Piano',
    );

    expect(result.correctedFiles, 1);
  });

  test('uploadSysEx throws on failed upload status', () async {
    final manager = MockDistingMidiManager();
    final source = File('${tempRoot.path}/Piano_C3.wav')
      ..writeAsBytesSync([1, 2, 3]);
    when(
      () => manager.requestDirectoryCreate(any()),
    ).thenAnswer((_) async => SdCardStatus(success: true, message: 'created'));
    when(
      () => manager.requestFileUpload('/samples/Piano/Piano_C3.wav', any()),
    ).thenAnswer((_) async => SdCardStatus(success: false, message: 'nope'));

    expect(
      () => service.uploadSysEx(
        manager: manager,
        regions: [
          PolySampleRegion(
            path: source.path,
            fileName: 'Piano_C3.wav',
            displayName: 'Piano_C3.wav',
            rootMidi: 48,
          ),
        ],
        hardwareFolder: '/samples/Piano',
      ),
      throwsA(
        isA<PolySampleUploadException>().having(
          (error) => error.message,
          'message',
          contains('Hardware upload /samples/Piano/Piano_C3.wav failed: nope'),
        ),
      ),
    );
  });
}
