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

enum WavFadeCurve { linear, equalPower, exponential, sCurve }

class WavFadeShaper {
  const WavFadeShaper._();

  static double apply(
    double value,
    WavFadeCurve curve, {
    double strength = 0.5,
  }) {
    final x = value.clamp(0.0, 1.0).toDouble();
    final s = strength.clamp(0.0, 1.0).toDouble();
    return switch (curve) {
      WavFadeCurve.linear => x,
      WavFadeCurve.equalPower => _equalPower(x, s),
      WavFadeCurve.exponential => _exponential(x, s),
      WavFadeCurve.sCurve => _sCurve(x, s),
    }.clamp(0.0, 1.0).toDouble();
  }

  static double _equalPower(double x, double strength) {
    final normal = math.sin(x * math.pi / 2);
    final strong = math.sqrt(1 - math.pow(1 - x, 2).toDouble());
    return _shapeStrength(x, strength, normal, strong);
  }

  static double _exponential(double x, double strength) {
    final normal = x * x;
    final strong = math.pow(x, 4.0).toDouble();
    return _shapeStrength(x, strength, normal, strong);
  }

  static double _sCurve(double x, double strength) {
    final normal = x * x * (3 - 2 * x);
    final strong = _normalizedSigmoid(x, 4.2);
    return _shapeStrength(x, strength, normal, strong);
  }

  static double _normalizedSigmoid(double x, double curve) {
    if (curve <= 0) return x;
    final scale = _tanh(curve / 2);
    if (scale == 0) return x;
    return 0.5 + _tanh(curve * (x - 0.5)) / (2 * scale);
  }

  static double _tanh(double x) {
    final e = math.exp(2 * x);
    return (e - 1) / (e + 1);
  }

  static double _shapeStrength(
    double linear,
    double strength,
    double normal,
    double strong,
  ) {
    if (strength <= 0.5) {
      return _lerpDouble(linear, normal, strength / 0.5);
    }
    return _lerpDouble(normal, strong, (strength - 0.5) / 0.5);
  }

  static double _lerpDouble(double a, double b, double t) {
    return a + (b - a) * t.clamp(0.0, 1.0);
  }
}

class WavRenderOptions {
  const WavRenderOptions({
    required this.trimStartFrame,
    required this.trimEndFrame,
    this.fadeInFrames = 0,
    this.fadeOutFrames = 0,
    this.fadeInCurve = WavFadeCurve.linear,
    this.fadeOutCurve = WavFadeCurve.linear,
    this.fadeInStrength = 0.5,
    this.fadeOutStrength = 0.5,
    this.gainDb = 0,
    this.normalizePeakDb,
  });

  final int trimStartFrame;
  final int trimEndFrame;
  final int fadeInFrames;
  final int fadeOutFrames;
  final WavFadeCurve fadeInCurve;
  final WavFadeCurve fadeOutCurve;
  final double fadeInStrength;
  final double fadeOutStrength;
  final double gainDb;
  final double? normalizePeakDb;
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

class WavAudioRenderer {
  static Uint8List renderPitchedPreview(
    Uint8List bytes, {
    required double pitchRatio,
  }) {
    if (bytes.length < 44) {
      throw const FormatException('WAV file is too small.');
    }
    if (WavMetadataReader._tag(bytes, 0) != 'RIFF' ||
        WavMetadataReader._tag(bytes, 8) != 'WAVE') {
      throw const FormatException('Not a RIFF/WAVE file.');
    }

    final data = ByteData.sublistView(bytes);
    final chunks = _readChunks(bytes, data);
    _FmtChunk? fmt;
    _DataChunk? audio;
    for (final chunk in chunks) {
      if (chunk.id == 'fmt ') {
        fmt = WavMetadataReader._readFmt(data, chunk.start, chunk.size);
      } else if (chunk.id == 'data') {
        audio = _DataChunk(start: chunk.start, size: chunk.size);
      }
    }
    if (fmt == null || audio == null) {
      throw const FormatException('WAV fmt/data chunks not found.');
    }
    if (!_isSupportedFormat(fmt)) {
      throw FormatException(
        'Unsupported WAV format ${fmt.format}/${fmt.bitsPerSample}.',
      );
    }

    final bytesPerSample = (fmt.bitsPerSample / 8).ceil();
    final bytesPerFrame = bytesPerSample * fmt.channels;
    final frameCount = audio.size ~/ bytesPerFrame;
    if (frameCount <= 0) {
      throw const FormatException('WAV has no audio frames.');
    }

    final safePitchRatio = pitchRatio.isFinite && pitchRatio > 0
        ? pitchRatio
        : 1.0;
    final renderedFrameCount = math.max(
      1,
      (frameCount / safePitchRatio).ceil(),
    );
    final renderedSamples = List<double>.filled(
      renderedFrameCount * fmt.channels,
      0,
    );

    for (var frame = 0; frame < renderedFrameCount; frame++) {
      final sourcePosition = frame * safePitchRatio;
      final lowerFrame = sourcePosition.floor().clamp(0, frameCount - 1);
      final upperFrame = (lowerFrame + 1).clamp(0, frameCount - 1);
      final fraction = (sourcePosition - lowerFrame).clamp(0.0, 1.0);
      for (var channel = 0; channel < fmt.channels; channel++) {
        final lowerOffset =
            audio.start + lowerFrame * bytesPerFrame + channel * bytesPerSample;
        final upperOffset =
            audio.start + upperFrame * bytesPerFrame + channel * bytesPerSample;
        final lower = WavMetadataReader._readSample(
          data,
          lowerOffset,
          fmt.bitsPerSample,
          fmt.format,
        );
        final upper = WavMetadataReader._readSample(
          data,
          upperOffset,
          fmt.bitsPerSample,
          fmt.format,
        );
        renderedSamples[frame * fmt.channels + channel] =
            lower + (upper - lower) * fraction;
      }
    }

    return _buildPcm16Wave(
      sampleRate: fmt.sampleRate,
      channels: fmt.channels,
      samples: renderedSamples,
    );
  }

  static Uint8List render(Uint8List bytes, WavRenderOptions options) {
    if (bytes.length < 44) {
      throw const FormatException('WAV file is too small.');
    }
    if (WavMetadataReader._tag(bytes, 0) != 'RIFF' ||
        WavMetadataReader._tag(bytes, 8) != 'WAVE') {
      throw const FormatException('Not a RIFF/WAVE file.');
    }

    final data = ByteData.sublistView(bytes);
    final chunks = _readChunks(bytes, data);
    _FmtChunk? fmt;
    _DataChunk? audio;
    _SampleLoop? loop;
    for (final chunk in chunks) {
      if (chunk.id == 'fmt ') {
        fmt = WavMetadataReader._readFmt(data, chunk.start, chunk.size);
      } else if (chunk.id == 'data') {
        audio = _DataChunk(start: chunk.start, size: chunk.size);
      } else if (chunk.id == 'smpl') {
        loop = WavMetadataReader._readFirstSampleLoop(
          data,
          chunk.start,
          chunk.size,
        );
      }
    }
    if (fmt == null || audio == null) {
      throw const FormatException('WAV fmt/data chunks not found.');
    }
    if (!_isSupportedFormat(fmt)) {
      throw FormatException(
        'Unsupported WAV format ${fmt.format}/${fmt.bitsPerSample}.',
      );
    }

    final bytesPerSample = (fmt.bitsPerSample / 8).ceil();
    final bytesPerFrame = bytesPerSample * fmt.channels;
    final frameCount = audio.size ~/ bytesPerFrame;
    if (frameCount <= 0) {
      throw const FormatException('WAV has no audio frames.');
    }

    final start = options.trimStartFrame.clamp(0, frameCount - 1).toInt();
    final endInclusive = options.trimEndFrame
        .clamp(start, frameCount - 1)
        .toInt();
    final renderedFrameCount = endInclusive - start + 1;
    final renderedSamples = List<double>.filled(
      renderedFrameCount * fmt.channels,
      0,
    );

    final gain = math.pow(10, options.gainDb / 20).toDouble();
    var peak = 0.0;
    for (var frame = 0; frame < renderedFrameCount; frame++) {
      final sourceFrame = start + frame;
      final fade = _fadeGain(
        frame: frame,
        frameCount: renderedFrameCount,
        fadeInFrames: options.fadeInFrames,
        fadeOutFrames: options.fadeOutFrames,
        fadeInCurve: options.fadeInCurve,
        fadeOutCurve: options.fadeOutCurve,
        fadeInStrength: options.fadeInStrength,
        fadeOutStrength: options.fadeOutStrength,
      );
      for (var channel = 0; channel < fmt.channels; channel++) {
        final sampleOffset =
            audio.start +
            sourceFrame * bytesPerFrame +
            channel * bytesPerSample;
        final sample =
            WavMetadataReader._readSample(
              data,
              sampleOffset,
              fmt.bitsPerSample,
              fmt.format,
            ) *
            gain *
            fade;
        final index = frame * fmt.channels + channel;
        renderedSamples[index] = sample;
        peak = math.max(peak, sample.abs());
      }
    }

    final normalizePeakDb = options.normalizePeakDb;
    if (normalizePeakDb != null && peak > 0) {
      final target = math.pow(10, normalizePeakDb / 20).toDouble();
      final factor = target / peak;
      for (var index = 0; index < renderedSamples.length; index++) {
        renderedSamples[index] *= factor;
      }
    }

    final renderedAudio = _encodeAudio(
      renderedSamples,
      fmt: fmt,
      bytesPerSample: bytesPerSample,
    );
    final rebuilt = _rebuildWave(bytes, chunks, renderedAudio);
    if (loop == null) {
      return rebuilt;
    }

    final loopStart = (loop.start - start).clamp(0, renderedFrameCount - 1);
    final loopEnd = (loop.end - start).clamp(loopStart, renderedFrameCount - 1);
    return WavMetadataWriter.writeSmplLoop(
      rebuilt,
      loopStart: loopStart.toInt(),
      loopEnd: loopEnd.toInt(),
    );
  }

  static bool _isSupportedFormat(_FmtChunk fmt) {
    if (fmt.channels <= 0) return false;
    if (fmt.format == 3) return fmt.bitsPerSample == 32;
    if (fmt.format != 1) return false;
    return const {8, 16, 24, 32}.contains(fmt.bitsPerSample);
  }

  static List<_WaveChunk> _readChunks(Uint8List bytes, ByteData data) {
    final chunks = <_WaveChunk>[];
    var offset = 12;
    while (offset + 8 <= bytes.length) {
      final id = WavMetadataReader._tag(bytes, offset);
      final size = data.getUint32(offset + 4, Endian.little);
      final start = offset + 8;
      final end = start + size;
      if (end > bytes.length) break;
      chunks.add(_WaveChunk(id: id, offset: offset, start: start, size: size));
      offset = end + (size.isOdd ? 1 : 0);
    }
    return chunks;
  }

  static double _fadeGain({
    required int frame,
    required int frameCount,
    required int fadeInFrames,
    required int fadeOutFrames,
    required WavFadeCurve fadeInCurve,
    required WavFadeCurve fadeOutCurve,
    required double fadeInStrength,
    required double fadeOutStrength,
  }) {
    var gain = 1.0;
    if (fadeInFrames > 0 && frame < fadeInFrames) {
      gain *= _curve(
        frame / fadeInFrames,
        fadeInCurve,
        strength: fadeInStrength,
      );
    }
    if (fadeOutFrames > 0 && frame >= frameCount - fadeOutFrames) {
      final remaining = frameCount - 1 - frame;
      gain *= _curve(
        remaining / fadeOutFrames,
        fadeOutCurve,
        strength: fadeOutStrength,
      );
    }
    return gain.clamp(0.0, 1.0);
  }

  static double _curve(
    double value,
    WavFadeCurve curve, {
    required double strength,
  }) {
    return WavFadeShaper.apply(value, curve, strength: strength);
  }

  static Uint8List _buildPcm16Wave({
    required int sampleRate,
    required int channels,
    required List<double> samples,
  }) {
    final renderedAudio = Uint8List(samples.length * 2);
    final audioData = ByteData.sublistView(renderedAudio);
    for (var index = 0; index < samples.length; index++) {
      audioData.setInt16(
        index * 2,
        (samples[index].clamp(-1.0, 1.0) * 32767).round().clamp(-32768, 32767),
        Endian.little,
      );
    }

    final fmtBody = ByteData(16)
      ..setUint16(0, 1, Endian.little)
      ..setUint16(2, channels, Endian.little)
      ..setUint32(4, sampleRate, Endian.little)
      ..setUint32(8, sampleRate * channels * 2, Endian.little)
      ..setUint16(12, channels * 2, Endian.little)
      ..setUint16(14, 16, Endian.little);

    final body = BytesBuilder(copy: false)
      ..add(_ascii('WAVE'))
      ..add(_ascii('fmt '))
      ..add(WavMetadataWriter._u32(16))
      ..add(fmtBody.buffer.asUint8List())
      ..add(_ascii('data'))
      ..add(WavMetadataWriter._u32(renderedAudio.length))
      ..add(renderedAudio);
    if (renderedAudio.length.isOdd) body.addByte(0);

    final bodyBytes = body.toBytes();
    return (BytesBuilder(copy: false)
          ..add(_ascii('RIFF'))
          ..add(WavMetadataWriter._u32(bodyBytes.length))
          ..add(bodyBytes))
        .toBytes();
  }

  static Uint8List _encodeAudio(
    List<double> samples, {
    required _FmtChunk fmt,
    required int bytesPerSample,
  }) {
    final out = Uint8List(samples.length * bytesPerSample);
    final data = ByteData.sublistView(out);
    for (var index = 0; index < samples.length; index++) {
      final offset = index * bytesPerSample;
      final sample = samples[index].clamp(-1.0, 1.0);
      if (fmt.format == 3 && fmt.bitsPerSample == 32) {
        data.setFloat32(offset, sample, Endian.little);
        continue;
      }
      switch (fmt.bitsPerSample) {
        case 8:
          data.setUint8(offset, ((sample * 127) + 128).round().clamp(0, 255));
          break;
        case 16:
          data.setInt16(
            offset,
            (sample * 32767).round().clamp(-32768, 32767),
            Endian.little,
          );
          break;
        case 24:
          _writeInt24(data, offset, (sample * 8388607).round());
          break;
        case 32:
          data.setInt32(
            offset,
            (sample * 2147483647).round().clamp(-2147483648, 2147483647),
            Endian.little,
          );
          break;
      }
    }
    return out;
  }

  static void _writeInt24(ByteData data, int offset, int value) {
    final clamped = value.clamp(-8388608, 8388607);
    final unsigned = clamped < 0 ? clamped + 0x1000000 : clamped;
    data
      ..setUint8(offset, unsigned & 0xff)
      ..setUint8(offset + 1, (unsigned >> 8) & 0xff)
      ..setUint8(offset + 2, (unsigned >> 16) & 0xff);
  }

  static Uint8List _rebuildWave(
    Uint8List original,
    List<_WaveChunk> chunks,
    Uint8List renderedAudio,
  ) {
    final body = BytesBuilder(copy: false)..add(_ascii('WAVE'));
    for (final chunk in chunks) {
      if (chunk.id == 'data') {
        body
          ..add(_ascii('data'))
          ..add(WavMetadataWriter._u32(renderedAudio.length))
          ..add(renderedAudio);
        if (renderedAudio.length.isOdd) body.addByte(0);
      } else if (chunk.id != 'smpl') {
        final paddedEnd = chunk.start + chunk.size + (chunk.size.isOdd ? 1 : 0);
        body.add(original.sublist(chunk.offset, paddedEnd));
      }
    }
    final bodyBytes = body.toBytes();
    return (BytesBuilder(copy: false)
          ..add(_ascii('RIFF'))
          ..add(WavMetadataWriter._u32(bodyBytes.length))
          ..add(bodyBytes))
        .toBytes();
  }

  static Uint8List _ascii(String value) => Uint8List.fromList(value.codeUnits);
}

class WavMetadataWriter {
  static Uint8List removeSmplLoop(Uint8List bytes) {
    if (bytes.length < 44) {
      throw const FormatException('WAV file is too small.');
    }
    if (WavMetadataReader._tag(bytes, 0) != 'RIFF' ||
        WavMetadataReader._tag(bytes, 8) != 'WAVE') {
      throw const FormatException('Not a RIFF/WAVE file.');
    }

    final data = ByteData.sublistView(bytes);
    _ChunkBounds? smpl;
    var offset = 12;
    while (offset + 8 <= bytes.length) {
      final id = WavMetadataReader._tag(bytes, offset);
      final size = data.getUint32(offset + 4, Endian.little);
      final start = offset + 8;
      final end = start + size;
      if (end > bytes.length) break;
      if (id == 'smpl') {
        smpl = _ChunkBounds(offset: offset, size: size);
        break;
      }
      offset = end + (size.isOdd ? 1 : 0);
    }

    if (smpl == null) return bytes;
    final chunkEnd = smpl.offset + 8 + smpl.size + (smpl.size.isOdd ? 1 : 0);
    final builder = BytesBuilder(copy: false)
      ..add(bytes.sublist(0, smpl.offset))
      ..add(bytes.sublist(chunkEnd));
    final updated = builder.toBytes();
    final updatedData = ByteData.sublistView(updated);
    updatedData.setUint32(4, updated.length - 8, Endian.little);
    return updated;
  }

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

class _WaveChunk {
  const _WaveChunk({
    required this.id,
    required this.offset,
    required this.start,
    required this.size,
  });

  final String id;
  final int offset;
  final int start;
  final int size;
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
