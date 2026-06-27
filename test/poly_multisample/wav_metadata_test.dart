import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/poly_multisample/wav_metadata.dart';

void main() {
  group('WavMetadataReader', () {
    test('reads PCM waveform peaks and first smpl loop', () {
      final bytes = _pcm16WavWithLoop(
        samples: [-32768, -12000, 0, 12000, 32767, 12000, 0, -12000],
        loopStart: 2,
        loopEnd: 6,
      );

      final overview = WavMetadataReader.parse(bytes, peakCount: 4);

      expect(overview, isNotNull);
      expect(overview!.sampleRate, 44100);
      expect(overview.frameCount, 8);
      expect(overview.loopStart, 2);
      expect(overview.loopEnd, 6);
      expect(overview.peaks, hasLength(4));
      expect(overview.peaks.first.min, lessThan(0));
      expect(overview.peaks[2].max, greaterThan(0.9));
      expect(overview.zeroCrossings, containsAll([2, 6]));
      expect(overview.nearestZeroCrossing(3, searchRadius: 4), 2);
    });

    test('writes smpl loop metadata', () {
      final bytes = _pcm16Wav(
        samples: [-32768, -12000, 0, 12000, 32767, 12000, 0, -12000],
      );

      final updated = WavMetadataWriter.writeSmplLoop(
        bytes,
        loopStart: 1,
        loopEnd: 5,
      );
      final overview = WavMetadataReader.parse(updated);

      expect(overview, isNotNull);
      expect(overview!.loopStart, 1);
      expect(overview.loopEnd, 5);
      expect(overview.frameCount, 8);
    });

    test('replaces existing smpl loop metadata', () {
      final bytes = _pcm16WavWithLoop(
        samples: [-32768, -12000, 0, 12000, 32767, 12000, 0, -12000],
        loopStart: 2,
        loopEnd: 6,
      );

      final updated = WavMetadataWriter.writeSmplLoop(
        bytes,
        loopStart: 3,
        loopEnd: 7,
      );
      final overview = WavMetadataReader.parse(updated);

      expect(overview, isNotNull);
      expect(overview!.loopStart, 3);
      expect(overview.loopEnd, 7);
      expect(overview.frameCount, 8);
    });
  });
}

Uint8List _pcm16Wav({required List<int> samples}) {
  final fmtChunk = BytesBuilder()
    ..add(_ascii('fmt '))
    ..add(_u32(16))
    ..add(_u16(1))
    ..add(_u16(1))
    ..add(_u32(44100))
    ..add(_u32(44100 * 2))
    ..add(_u16(2))
    ..add(_u16(16));

  final sampleData = BytesBuilder();
  for (final sample in samples) {
    sampleData.add(_i16(sample));
  }
  final dataBytes = sampleData.toBytes();
  final dataChunk = BytesBuilder()
    ..add(_ascii('data'))
    ..add(_u32(dataBytes.length))
    ..add(dataBytes);

  final body = BytesBuilder()
    ..add(_ascii('WAVE'))
    ..add(fmtChunk.toBytes())
    ..add(dataChunk.toBytes());
  final bodyBytes = body.toBytes();

  return (BytesBuilder()
        ..add(_ascii('RIFF'))
        ..add(_u32(bodyBytes.length))
        ..add(bodyBytes))
      .toBytes();
}

Uint8List _pcm16WavWithLoop({
  required List<int> samples,
  required int loopStart,
  required int loopEnd,
}) {
  final fmtChunk = BytesBuilder()
    ..add(_ascii('fmt '))
    ..add(_u32(16))
    ..add(_u16(1))
    ..add(_u16(1))
    ..add(_u32(44100))
    ..add(_u32(44100 * 2))
    ..add(_u16(2))
    ..add(_u16(16));

  final smplChunk = BytesBuilder()
    ..add(_ascii('smpl'))
    ..add(_u32(60))
    ..add(_u32(0))
    ..add(_u32(0))
    ..add(_u32(0))
    ..add(_u32(60))
    ..add(_u32(0))
    ..add(_u32(0))
    ..add(_u32(0))
    ..add(_u32(1))
    ..add(_u32(0))
    ..add(_u32(0))
    ..add(_u32(0))
    ..add(_u32(loopStart))
    ..add(_u32(loopEnd))
    ..add(_u32(0))
    ..add(_u32(0));

  final sampleData = BytesBuilder();
  for (final sample in samples) {
    sampleData.add(_i16(sample));
  }
  final dataBytes = sampleData.toBytes();
  final dataChunk = BytesBuilder()
    ..add(_ascii('data'))
    ..add(_u32(dataBytes.length))
    ..add(dataBytes);

  final body = BytesBuilder()
    ..add(_ascii('WAVE'))
    ..add(fmtChunk.toBytes())
    ..add(smplChunk.toBytes())
    ..add(dataChunk.toBytes());
  final bodyBytes = body.toBytes();

  return (BytesBuilder()
        ..add(_ascii('RIFF'))
        ..add(_u32(bodyBytes.length))
        ..add(bodyBytes))
      .toBytes();
}

Uint8List _ascii(String value) => Uint8List.fromList(value.codeUnits);

Uint8List _u16(int value) {
  final data = ByteData(2)..setUint16(0, value, Endian.little);
  return data.buffer.asUint8List();
}

Uint8List _i16(int value) {
  final data = ByteData(2)..setInt16(0, value, Endian.little);
  return data.buffer.asUint8List();
}

Uint8List _u32(int value) {
  final data = ByteData(4)..setUint32(0, value, Endian.little);
  return data.buffer.asUint8List();
}
