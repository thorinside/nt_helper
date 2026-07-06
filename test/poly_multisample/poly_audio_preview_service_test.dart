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

    test(
      'restartPreview restarts the same visible path without toggling',
      () async {
        final adapter = _FakePreviewAdapter();
        final service = PolyAudioPreviewService(adapter: adapter);
        addTearDown(service.dispose);

        await service.restartPreview(
          '/tmp/rendered-a.wav',
          displayPath: '/tmp/source.wav',
        );
        await service.restartPreview(
          '/tmp/rendered-a.wav',
          displayPath: '/tmp/source.wav',
        );

        expect(adapter.playedPaths, [
          '/tmp/rendered-a.wav',
          '/tmp/rendered-a.wav',
        ]);
        expect(adapter.stopCount, 1);
        expect(service.state.visiblePath, '/tmp/source.wav');
      },
    );

    test('uses display path for toggling cached hardware previews', () async {
      final adapter = _FakePreviewAdapter();
      final service = PolyAudioPreviewService(adapter: adapter);
      addTearDown(service.dispose);

      await service.playOrStopPreview(
        '/tmp/cache/a.wav',
        displayPath: '/samples/Piano/a.wav',
      );
      expect(service.state.playingPath, '/tmp/cache/a.wav');
      expect(service.state.visiblePath, '/samples/Piano/a.wav');

      await service.playOrStopPreview(
        '/tmp/cache/a.wav',
        displayPath: '/samples/Piano/a.wav',
      );

      expect(service.state.playingPath, isNull);
      expect(service.state.visiblePath, isNull);
      expect(adapter.stopCount, 1);
    });

    test(
      'source playback maps elapsed time to source frames and loop wrap',
      () {
        final playback = PolyAudioPreviewSourcePlayback(
          sourcePath: '/tmp/source.wav',
          startedAt: DateTime(2026),
          startFrame: 100,
          endFrame: 999,
          sampleRate: 1000,
          pitchRatio: 2,
          loopStartFrame: 300,
          loopEndFrame: 399,
        );

        expect(
          playback.frameAt(
            DateTime(2026).add(const Duration(milliseconds: 100)),
          ),
          300,
        );
        expect(
          playback.frameAt(
            DateTime(2026).add(const Duration(milliseconds: 200)),
          ),
          300,
        );
      },
    );
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
