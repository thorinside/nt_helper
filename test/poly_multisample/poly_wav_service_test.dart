import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/poly_multisample/poly_wav_service.dart';
import 'package:nt_helper/poly_multisample/wav_metadata.dart';

void main() {
  group('PolyWavService', () {
    late Directory tempRoot;

    setUp(() {
      tempRoot = Directory.systemTemp.createTempSync('poly_wav_service_test_');
    });

    tearDown(() {
      if (tempRoot.existsSync()) {
        tempRoot.deleteSync(recursive: true);
      }
    });

    test('loads waveform summaries and saves/removes loop metadata', () async {
      final wav = File('${tempRoot.path}/loop.wav')
        ..writeAsBytesSync(_pcm16Wav(samples: [0, 1000, 0, -1000]));
      final service = const PolyWavService();

      final overview = await service.loadWaveform(wav.path, peakCount: 2);
      expect(overview.frameCount, 4);
      expect(overview.peaks, hasLength(2));

      await service.saveLoopMetadata(wav.path, loopStart: 1, loopEnd: 3);
      expect((await service.loadWaveform(wav.path)).loopStart, 1);

      await service.removeLoopMetadata(wav.path);
      expect((await service.loadWaveform(wav.path)).loopStart, isNull);
    });

    test(
      'renders destructive edits and requires overwrite confirmation',
      () async {
        final source = File('${tempRoot.path}/source.wav')
          ..writeAsBytesSync(_pcm16Wav(samples: [100, 200, 300, 400]));
        final target = File('${tempRoot.path}/target.wav')
          ..writeAsBytesSync([1]);
        final service = const PolyWavService();

        expect(
          service.saveDestructiveWav(
            source.path,
            target.path,
            const WavRenderOptions(trimStartFrame: 1, trimEndFrame: 2),
          ),
          throwsA(isA<PolyWavServiceException>()),
        );

        await service.saveDestructiveWav(
          source.path,
          target.path,
          const WavRenderOptions(trimStartFrame: 1, trimEndFrame: 2),
          overwriteConfirmed: true,
        );

        expect((await service.loadWaveform(target.path)).frameCount, 2);
      },
    );
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

Uint8List _ascii(String value) => Uint8List.fromList(value.codeUnits);

Uint8List _u16(int value) {
  final data = ByteData(2)..setUint16(0, value, Endian.little);
  return data.buffer.asUint8List();
}

Uint8List _u32(int value) {
  final data = ByteData(4)..setUint32(0, value, Endian.little);
  return data.buffer.asUint8List();
}

Uint8List _i16(int value) {
  final data = ByteData(2)..setInt16(0, value, Endian.little);
  return data.buffer.asUint8List();
}
