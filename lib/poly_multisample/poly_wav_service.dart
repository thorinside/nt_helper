import 'dart:io';
import 'dart:typed_data';

import 'wav_metadata.dart';

class PolyWavServiceException implements Exception {
  const PolyWavServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}

class PolyWavService {
  const PolyWavService();

  Future<WavOverview> loadWaveform(String path, {int peakCount = 360}) async {
    final bytes = await File(path).readAsBytes();
    final overview = WavMetadataReader.parse(bytes, peakCount: peakCount);
    if (overview == null) {
      throw PolyWavServiceException('Could not parse WAV file $path.');
    }
    return overview;
  }

  Future<void> saveLoopMetadata(
    String path, {
    required int loopStart,
    required int loopEnd,
  }) async {
    final file = File(path);
    final bytes = await file.readAsBytes();
    final updated = WavMetadataWriter.writeSmplLoop(
      bytes,
      loopStart: loopStart,
      loopEnd: loopEnd,
    );
    await file.writeAsBytes(updated, flush: true);
  }

  Future<void> removeLoopMetadata(String path) async {
    final file = File(path);
    final bytes = await file.readAsBytes();
    final updated = WavMetadataWriter.removeSmplLoop(bytes);
    await file.writeAsBytes(updated, flush: true);
  }

  Future<void> saveDestructiveWav(
    String sourcePath,
    String targetPath,
    WavRenderOptions options, {
    bool overwriteConfirmed = false,
  }) async {
    final target = File(targetPath);
    if (await target.exists() && !overwriteConfirmed) {
      throw PolyWavServiceException('$targetPath already exists.');
    }
    final rendered = await renderDestructiveWav(sourcePath, options);
    await target.parent.create(recursive: true);
    await target.writeAsBytes(rendered, flush: true);
  }

  Future<Uint8List> renderDestructiveWav(
    String sourcePath,
    WavRenderOptions options,
  ) async {
    final sourceBytes = await File(sourcePath).readAsBytes();
    return WavAudioRenderer.render(sourceBytes, options);
  }
}
