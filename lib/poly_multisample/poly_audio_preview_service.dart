import 'dart:async';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';

abstract class PolyAudioPreviewAdapter {
  Stream<void> get completed;

  Future<void> play(String path, {required double volume});

  Future<void> stop();

  Future<void> dispose();
}

class AudioplayersPreviewAdapter implements PolyAudioPreviewAdapter {
  AudioplayersPreviewAdapter({AudioPlayer? player})
    : _player = player ?? AudioPlayer();

  final AudioPlayer _player;

  @override
  Stream<void> get completed => _player.onPlayerComplete;

  @override
  Future<void> play(String path, {required double volume}) async {
    await _player.setVolume(volume);
    await _player.play(DeviceFileSource(path));
  }

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> dispose() => _player.dispose();
}

class PolyAudioPreviewState {
  const PolyAudioPreviewState({
    this.playingPath,
    this.displayPath,
    this.playingMidiNote,
    this.sourcePlayback,
    this.gainDb = 0,
  });

  final String? playingPath;
  final String? displayPath;
  final int? playingMidiNote;
  final PolyAudioPreviewSourcePlayback? sourcePlayback;
  final double gainDb;

  bool get isPlaying => playingPath != null;

  String? get visiblePath => displayPath ?? playingPath;
}

class PolyAudioPreviewSourcePlayback {
  const PolyAudioPreviewSourcePlayback({
    required this.sourcePath,
    required this.startedAt,
    required this.startFrame,
    required this.endFrame,
    required this.sampleRate,
    this.pitchRatio = 1,
    this.loopStartFrame,
    this.loopEndFrame,
  });

  final String sourcePath;
  final DateTime startedAt;
  final int startFrame;
  final int endFrame;
  final int sampleRate;
  final double pitchRatio;
  final int? loopStartFrame;
  final int? loopEndFrame;

  int frameAt(DateTime now) {
    final boundedStart = math.max(0, startFrame);
    final boundedEnd = math.max(boundedStart, endFrame);
    if (sampleRate <= 0) return boundedStart;
    final elapsedSeconds =
        now.difference(startedAt).inMicroseconds /
        Duration.microsecondsPerSecond;
    final sourceFrames =
        elapsedSeconds * sampleRate * (pitchRatio.isFinite ? pitchRatio : 1);
    var frame = boundedStart + sourceFrames.floor();
    final loopStart = loopStartFrame;
    final loopEnd = loopEndFrame;
    if (loopStart != null &&
        loopEnd != null &&
        loopEnd > loopStart &&
        boundedStart <= loopEnd &&
        frame > loopEnd) {
      final loopLength = loopEnd - loopStart + 1;
      frame = loopStart + ((frame - loopStart) % loopLength);
    }
    return frame.clamp(boundedStart, boundedEnd).toInt();
  }
}

class PolyAudioPreviewService {
  PolyAudioPreviewService({PolyAudioPreviewAdapter? adapter})
    : _adapter = adapter {
    if (adapter != null) {
      _completionSub = adapter.completed.listen((_) {
        _setState(PolyAudioPreviewState(gainDb: state.gainDb));
      });
    }
  }

  PolyAudioPreviewAdapter? _adapter;
  final _stateController = StreamController<PolyAudioPreviewState>.broadcast(
    sync: true,
  );
  StreamSubscription<void>? _completionSub;

  PolyAudioPreviewState _state = const PolyAudioPreviewState();

  PolyAudioPreviewState get state => _state;

  Stream<PolyAudioPreviewState> get states => _stateController.stream;

  Future<void> playOrStopPreview(
    String path, {
    double gainDb = 0,
    String? displayPath,
    int? playingMidiNote,
    PolyAudioPreviewSourcePlayback? sourcePlayback,
  }) async {
    final adapter = _ensureAdapter();
    final visiblePath = displayPath ?? path;
    if (state.visiblePath == visiblePath) {
      await stop();
      return;
    }
    if (state.isPlaying) {
      await adapter.stop();
    }
    final volume = _volumeFromGainDb(gainDb);
    await adapter.play(path, volume: volume);
    _setState(
      PolyAudioPreviewState(
        playingPath: path,
        displayPath: displayPath,
        playingMidiNote: playingMidiNote,
        sourcePlayback: sourcePlayback,
        gainDb: gainDb,
      ),
    );
  }

  Future<void> restartPreview(
    String path, {
    double gainDb = 0,
    String? displayPath,
    int? playingMidiNote,
    PolyAudioPreviewSourcePlayback? sourcePlayback,
  }) async {
    final adapter = _ensureAdapter();
    if (state.isPlaying) {
      await adapter.stop();
    }
    final volume = _volumeFromGainDb(gainDb);
    await adapter.play(path, volume: volume);
    _setState(
      PolyAudioPreviewState(
        playingPath: path,
        displayPath: displayPath,
        playingMidiNote: playingMidiNote,
        sourcePlayback: sourcePlayback,
        gainDb: gainDb,
      ),
    );
  }

  Future<void> stop() async {
    if (!state.isPlaying) return;
    await _adapter?.stop();
    _setState(PolyAudioPreviewState(gainDb: state.gainDb));
  }

  Future<void> dispose() async {
    await _completionSub?.cancel();
    await _adapter?.dispose();
    await _stateController.close();
  }

  PolyAudioPreviewAdapter _ensureAdapter() {
    final existing = _adapter;
    if (existing != null) return existing;
    final created = AudioplayersPreviewAdapter();
    _adapter = created;
    _completionSub = created.completed.listen((_) {
      _setState(PolyAudioPreviewState(gainDb: state.gainDb));
    });
    return created;
  }

  void _setState(PolyAudioPreviewState state) {
    _state = state;
    if (!_stateController.isClosed) {
      _stateController.add(state);
    }
  }
}

double _volumeFromGainDb(double gainDb) {
  return math.pow(10, gainDb / 20).toDouble().clamp(0.0, 1.0);
}
