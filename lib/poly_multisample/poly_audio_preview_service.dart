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
    this.gainDb = 0,
  });

  final String? playingPath;
  final String? displayPath;
  final int? playingMidiNote;
  final double gainDb;

  bool get isPlaying => playingPath != null;

  String? get visiblePath => displayPath ?? playingPath;
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
        gainDb: gainDb,
      ),
    );
  }

  Future<void> restartPreview(
    String path, {
    double gainDb = 0,
    String? displayPath,
    int? playingMidiNote,
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
