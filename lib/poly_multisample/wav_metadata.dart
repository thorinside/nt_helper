import 'dart:math' as math;
import 'dart:typed_data';

class WavOverview {
  const WavOverview({
    required this.sampleRate,
    required this.frameCount,
    required this.peaks,
    required this.zeroCrossings,
    this.loopStart,
    this.loopEnd,
  });

  final int sampleRate;
  final int frameCount;
  final List<WavPeak> peaks;
  final List<int> zeroCrossings;
  final int? loopStart;
  final int? loopEnd;

  double get durationSeconds =>
      sampleRate <= 0 ? 0 : frameCount / sampleRate.toDouble();

  int nearestZeroCrossing(int frame, {int searchRadius = 4096}) {
    final clamped = frame.clamp(0, math.max(0, frameCount - 1)).toInt();
    if (zeroCrossings.isEmpty) return clamped;

    var low = 0;
    var high = zeroCrossings.length;
    while (low < high) {
      final mid = (low + high) >> 1;
      if (zeroCrossings[mid] < clamped) {
        low = mid + 1;
      } else {
        high = mid;
      }
    }

    int? best;
    for (final index in [low - 1, low]) {
      if (index < 0 || index >= zeroCrossings.length) continue;
      final candidate = zeroCrossings[index];
      final distance = (candidate - clamped).abs();
      if (distance > searchRadius) continue;
      if (best == null || distance < (best - clamped).abs()) {
        best = candidate;
      }
    }
    return best ?? clamped;
  }
}

class WavPeak {
  const WavPeak({required this.min, required this.max});

  final double min;
  final double max;
}

class WavMetadataReader {
  static WavOverview? parse(Uint8List bytes, {int peakCount = 360}) {
    if (bytes.length < 44) return null;
    final data = ByteData.sublistView(bytes);
    if (_tag(bytes, 0) != 'RIFF' || _tag(bytes, 8) != 'WAVE') return null;

    _FmtChunk? fmt;
    _DataChunk? audio;
    int? loopStart;
    int? loopEnd;

    var offset = 12;
    while (offset + 8 <= bytes.length) {
      final id = _tag(bytes, offset);
      final size = data.getUint32(offset + 4, Endian.little);
      final start = offset + 8;
      final end = start + size;
      if (end > bytes.length) break;

      if (id == 'fmt ') {
        fmt = _readFmt(data, start, size);
      } else if (id == 'data') {
        audio = _DataChunk(start: start, size: size);
      } else if (id == 'smpl') {
        final loop = _readFirstSampleLoop(data, start, size);
        loopStart = loop?.start;
        loopEnd = loop?.end;
      }

      offset = end + (size.isOdd ? 1 : 0);
    }

    if (fmt == null || audio == null) return null;
    if (fmt.channels <= 0 || fmt.bitsPerSample <= 0) return null;
    final bytesPerSample = (fmt.bitsPerSample / 8).ceil();
    final bytesPerFrame = bytesPerSample * fmt.channels;
    if (bytesPerFrame <= 0) return null;
    final frameCount = audio.size ~/ bytesPerFrame;
    if (frameCount <= 0) return null;

    final analysis = _analyzeAudio(
      data: data,
      audioStart: audio.start,
      frameCount: frameCount,
      channels: fmt.channels,
      bitsPerSample: fmt.bitsPerSample,
      format: fmt.format,
      peakCount: peakCount,
    );

    return WavOverview(
      sampleRate: fmt.sampleRate,
      frameCount: frameCount,
      peaks: analysis.peaks,
      zeroCrossings: analysis.zeroCrossings,
      loopStart: loopStart,
      loopEnd: loopEnd,
    );
  }

  static _FmtChunk? _readFmt(ByteData data, int start, int size) {
    if (size < 16) return null;
    return _FmtChunk(
      format: data.getUint16(start, Endian.little),
      channels: data.getUint16(start + 2, Endian.little),
      sampleRate: data.getUint32(start + 4, Endian.little),
      bitsPerSample: data.getUint16(start + 14, Endian.little),
    );
  }

  static _SampleLoop? _readFirstSampleLoop(ByteData data, int start, int size) {
    if (size < 60) return null;
    final loopCount = data.getUint32(start + 28, Endian.little);
    if (loopCount == 0) return null;
    final loopStart = start + 36;
    return _SampleLoop(
      start: data.getUint32(loopStart + 8, Endian.little),
      end: data.getUint32(loopStart + 12, Endian.little),
    );
  }

  static _WaveAnalysis _analyzeAudio({
    required ByteData data,
    required int audioStart,
    required int frameCount,
    required int channels,
    required int bitsPerSample,
    required int format,
    required int peakCount,
  }) {
    final count = math.min(peakCount, frameCount);
    final framesPerPeak = math.max(1, (frameCount / count).ceil());
    final peaks = <WavPeak>[];
    final zeroCrossings = <int>[];
    final bytesPerSample = (bitsPerSample / 8).ceil();
    final bytesPerFrame = bytesPerSample * channels;
    double? previous;

    for (var bucket = 0; bucket < count; bucket++) {
      final frameStart = bucket * framesPerPeak;
      final frameEnd = math.min(frameCount, frameStart + framesPerPeak);
      var minValue = 1.0;
      var maxValue = -1.0;
      for (var frame = frameStart; frame < frameEnd; frame++) {
        var mixed = 0.0;
        for (var channel = 0; channel < channels; channel++) {
          final sampleOffset =
              audioStart + frame * bytesPerFrame + channel * bytesPerSample;
          mixed += _readSample(data, sampleOffset, bitsPerSample, format);
        }
        mixed = (mixed / channels).clamp(-1.0, 1.0);
        final last = previous;
        if (last != null &&
            ((last < 0 && mixed >= 0) || (last > 0 && mixed <= 0))) {
          zeroCrossings.add(frame);
        }
        previous = mixed;
        minValue = math.min(minValue, mixed);
        maxValue = math.max(maxValue, mixed);
      }
      peaks.add(WavPeak(min: minValue, max: maxValue));
    }
    return _WaveAnalysis(peaks: peaks, zeroCrossings: zeroCrossings);
  }

  static double _readSample(
    ByteData data,
    int offset,
    int bitsPerSample,
    int format,
  ) {
    if (format == 3 && bitsPerSample == 32) {
      return data.getFloat32(offset, Endian.little).clamp(-1.0, 1.0);
    }
    return switch (bitsPerSample) {
      8 => ((data.getUint8(offset) - 128) / 128).clamp(-1.0, 1.0),
      16 => (data.getInt16(offset, Endian.little) / 32768).clamp(-1.0, 1.0),
      24 => (_readInt24(data, offset) / 8388608).clamp(-1.0, 1.0),
      32 => (data.getInt32(offset, Endian.little) / 2147483648).clamp(
        -1.0,
        1.0,
      ),
      _ => 0.0,
    };
  }

  static int _readInt24(ByteData data, int offset) {
    var value =
        data.getUint8(offset) |
        (data.getUint8(offset + 1) << 8) |
        (data.getUint8(offset + 2) << 16);
    if ((value & 0x800000) != 0) value |= ~0xffffff;
    return value;
  }

  static String _tag(Uint8List bytes, int offset) {
    return String.fromCharCodes(bytes.sublist(offset, offset + 4));
  }
}

class WavMetadataWriter {
  static Uint8List writeSmplLoop(
    Uint8List bytes, {
    required int loopStart,
    required int loopEnd,
  }) {
    if (bytes.length < 44) {
      throw const FormatException('WAV file is too small.');
    }
    if (WavMetadataReader._tag(bytes, 0) != 'RIFF' ||
        WavMetadataReader._tag(bytes, 8) != 'WAVE') {
      throw const FormatException('Not a RIFF/WAVE file.');
    }

    final data = ByteData.sublistView(bytes);
    _FmtChunk? fmt;
    _ChunkBounds? smpl;

    var offset = 12;
    while (offset + 8 <= bytes.length) {
      final id = WavMetadataReader._tag(bytes, offset);
      final size = data.getUint32(offset + 4, Endian.little);
      final start = offset + 8;
      final end = start + size;
      if (end > bytes.length) break;

      if (id == 'fmt ') {
        fmt = WavMetadataReader._readFmt(data, start, size);
      } else if (id == 'smpl') {
        smpl = _ChunkBounds(offset: offset, size: size);
      }

      offset = end + (size.isOdd ? 1 : 0);
    }

    if (fmt == null) {
      throw const FormatException('WAV fmt chunk not found.');
    }

    final safeStart = math.max(0, loopStart);
    final safeEnd = math.max(safeStart, loopEnd);
    final chunk = _buildSmplChunk(
      sampleRate: fmt.sampleRate,
      loopStart: safeStart,
      loopEnd: safeEnd,
    );

    final builder = BytesBuilder(copy: false);
    if (smpl == null) {
      builder.add(bytes);
      builder.add(chunk);
    } else {
      final chunkEnd = smpl.offset + 8 + smpl.size + (smpl.size.isOdd ? 1 : 0);
      builder
        ..add(bytes.sublist(0, smpl.offset))
        ..add(chunk)
        ..add(bytes.sublist(chunkEnd));
    }

    final updated = builder.toBytes();
    final updatedData = ByteData.sublistView(updated);
    updatedData.setUint32(4, updated.length - 8, Endian.little);
    return updated;
  }

  static Uint8List _buildSmplChunk({
    required int sampleRate,
    required int loopStart,
    required int loopEnd,
  }) {
    final samplePeriod = sampleRate <= 0 ? 0 : 1000000000 ~/ sampleRate;
    final body = BytesBuilder(copy: false)
      ..add(_u32(0)) // manufacturer
      ..add(_u32(0)) // product
      ..add(_u32(samplePeriod))
      ..add(_u32(60)) // MIDI unity note
      ..add(_u32(0)) // MIDI pitch fraction
      ..add(_u32(0)) // SMPTE format
      ..add(_u32(0)) // SMPTE offset
      ..add(_u32(1)) // sample loop count
      ..add(_u32(0)) // sampler data
      ..add(_u32(0)) // cue point id
      ..add(_u32(0)) // forward loop
      ..add(_u32(loopStart))
      ..add(_u32(loopEnd))
      ..add(_u32(0)) // fraction
      ..add(_u32(0)); // play count
    final bodyBytes = body.toBytes();
    return (BytesBuilder(copy: false)
          ..add(Uint8List.fromList('smpl'.codeUnits))
          ..add(_u32(bodyBytes.length))
          ..add(bodyBytes))
        .toBytes();
  }

  static Uint8List _u32(int value) {
    final data = ByteData(4)..setUint32(0, value, Endian.little);
    return data.buffer.asUint8List();
  }
}

class _FmtChunk {
  const _FmtChunk({
    required this.format,
    required this.channels,
    required this.sampleRate,
    required this.bitsPerSample,
  });

  final int format;
  final int channels;
  final int sampleRate;
  final int bitsPerSample;
}

class _ChunkBounds {
  const _ChunkBounds({required this.offset, required this.size});

  final int offset;
  final int size;
}

class _DataChunk {
  const _DataChunk({required this.start, required this.size});

  final int start;
  final int size;
}

class _SampleLoop {
  const _SampleLoop({required this.start, required this.end});

  final int start;
  final int end;
}

class _WaveAnalysis {
  const _WaveAnalysis({required this.peaks, required this.zeroCrossings});

  final List<WavPeak> peaks;
  final List<int> zeroCrossings;
}
