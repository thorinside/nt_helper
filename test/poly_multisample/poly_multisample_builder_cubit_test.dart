import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/poly_multisample/poly_audio_preview_service.dart';
import 'package:nt_helper/ui/poly_multisample/poly_multisample_builder_cubit.dart';

void main() {
  group('PolyMultisampleBuilderCubit', () {
    late Directory tempRoot;

    setUp(() {
      tempRoot = Directory.systemTemp.createTempSync(
        'poly_multisample_builder_cubit_test_',
      );
    });

    tearDown(() {
      if (tempRoot.existsSync()) {
        tempRoot.deleteSync(recursive: true);
      }
    });

    test('loads, selects, edits, and applies a local sample folder', () async {
      final sample = File('${tempRoot.path}/SoftPiano_C3.wav')
        ..writeAsBytesSync([1, 2, 3]);
      final previewService = PolyAudioPreviewService(
        adapter: _FakePreviewAdapter(),
      );
      final cubit = PolyMultisampleBuilderCubit(previewService: previewService);
      addTearDown(cubit.close);

      await cubit.loadLocalFolder(tempRoot.path);
      expect(cubit.state.status, PolyMultisampleLoadStatus.ready);
      expect(cubit.state.currentInstrument!.regions.single.rootMidi, 48);

      cubit.selectRegion(sample.path, PolyRegionSelectionMode.replace);
      cubit.updateRoot(sample.path, 50);
      expect(cubit.state.isDirty, isTrue);

      await cubit.applyChanges();

      expect(cubit.state.error, isNull);
      final filesAfterApply = tempRoot
          .listSync()
          .whereType<File>()
          .map((file) => file.uri.pathSegments.last)
          .toList();
      expect(filesAfterApply, contains('SoftPiano_D3.wav'));
      expect(sample.existsSync(), isFalse);
      expect(cubit.state.isDirty, isFalse);
    });

    test('mirrors audio preview state from the preview service', () async {
      final adapter = _FakePreviewAdapter();
      final previewService = PolyAudioPreviewService(adapter: adapter);
      final cubit = PolyMultisampleBuilderCubit(previewService: previewService);
      addTearDown(cubit.close);

      await cubit.playOrStopPreview('/tmp/a.wav');

      expect(cubit.state.previewState.playingPath, '/tmp/a.wav');
      expect(adapter.playedPaths, ['/tmp/a.wav']);
    });
  });
}

class _FakePreviewAdapter implements PolyAudioPreviewAdapter {
  final playedPaths = <String>[];
  var stopCount = 0;

  @override
  Stream<void> get completed => const Stream.empty();

  @override
  Future<void> play(String path, {required double volume}) async {
    playedPaths.add(path);
  }

  @override
  Future<void> stop() async {
    stopCount++;
  }

  @override
  Future<void> dispose() async {}
}
