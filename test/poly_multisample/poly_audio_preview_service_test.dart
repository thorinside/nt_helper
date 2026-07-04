import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/poly_multisample/poly_audio_preview_service.dart';

void main() {
  group('PolyAudioPreviewService', () {
    test('plays, toggles stop, and clears state on completion', () async {
      final adapter = _FakePreviewAdapter();
      final service = PolyAudioPreviewService(adapter: adapter);
      addTearDown(service.dispose);

      await service.playOrStopPreview('/tmp/a.wav', gainDb: -6);
      expect(service.state.playingPath, '/tmp/a.wav');
      expect(adapter.playedPaths, ['/tmp/a.wav']);
      expect(adapter.volumes.single, closeTo(0.501, 0.01));

      await service.playOrStopPreview('/tmp/a.wav', gainDb: -6);
      expect(service.state.playingPath, isNull);
      expect(adapter.stopCount, 1);

      await service.playOrStopPreview('/tmp/b.wav');
      adapter.complete();
      await pumpEventQueue();

      expect(service.state.playingPath, isNull);
    });
  });
}

class _FakePreviewAdapter implements PolyAudioPreviewAdapter {
  final playedPaths = <String>[];
  final volumes = <double>[];
  var stopCount = 0;
  final _completedController = StreamController<void>.broadcast();

  @override
  Stream<void> get completed => _completedController.stream;

  @override
  Future<void> play(String path, {required double volume}) async {
    playedPaths.add(path);
    volumes.add(volume);
  }

  @override
  Future<void> stop() async {
    stopCount++;
  }

  @override
  Future<void> dispose() async {
    await _completedController.close();
  }

  void complete() {
    _completedController.add(null);
  }
}
