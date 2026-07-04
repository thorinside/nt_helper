import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nt_helper/domain/i_disting_midi_manager.dart';
import 'package:nt_helper/poly_multisample/decent_sampler_converter.dart';
import 'package:nt_helper/poly_multisample/poly_audio_preview_service.dart';
import 'package:nt_helper/poly_multisample/poly_multisample_models.dart';
import 'package:nt_helper/poly_multisample/poly_multisample_parser.dart';
import 'package:nt_helper/poly_multisample/poly_sample_apply_service.dart';
import 'package:nt_helper/poly_multisample/poly_sample_folder_service.dart';
import 'package:nt_helper/poly_multisample/poly_sample_hardware_service.dart';
import 'package:nt_helper/poly_multisample/poly_sample_import_service.dart';
import 'package:nt_helper/poly_multisample/poly_sample_preferences_service.dart';
import 'package:nt_helper/poly_multisample/wav_metadata.dart';
import 'package:nt_helper/ui/poly_multisample/poly_multisample_builder_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockDistingMidiManager extends Mock implements IDistingMidiManager {}

void main() {
  group('PolyMultisampleBuilderCubit', () {
    late Directory tempRoot;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      tempRoot = Directory.systemTemp.createTempSync(
        'poly_multisample_builder_cubit_test_',
      );
    });

    tearDown(() {
      if (tempRoot.existsSync()) {
        tempRoot.deleteSync(recursive: true);
      }
    });

    test('loads remembered folders into state on construction', () async {
      SharedPreferences.setMockInitialValues({
        'poly_multisample.lastLocalFolder': '/tmp/a',
        'poly_multisample.lastWavExportFolder': '/tmp/b',
      });
      final service = await PolySamplePreferencesService.create();
      final cubit = PolyMultisampleBuilderCubit(
        preferencesService: service,
        previewService: PolyAudioPreviewService(adapter: _FakePreviewAdapter()),
      );
      addTearDown(cubit.close);

      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.lastLocalFolder, '/tmp/a');
      expect(cubit.state.lastWavExportFolder, '/tmp/b');
    });

    test('rememberSourceFolder persists and emits', () async {
      SharedPreferences.setMockInitialValues({});
      final service = await PolySamplePreferencesService.create();
      final cubit = PolyMultisampleBuilderCubit(
        preferencesService: service,
        previewService: PolyAudioPreviewService(adapter: _FakePreviewAdapter()),
      );
      addTearDown(cubit.close);

      await cubit.rememberSourceFolder('/tmp/src');

      expect(cubit.state.lastSourceFolder, '/tmp/src');
      expect(service.lastSourceFolder, '/tmp/src');
    });

    test('adoptStagedImport sets an import draft instrument', () async {
      final cubit = PolyMultisampleBuilderCubit(
        previewService: PolyAudioPreviewService(adapter: _FakePreviewAdapter()),
      );
      addTearDown(cubit.close);

      await cubit.adoptStagedImport(
        const PolyStagedImport(
          name: 'Imported Piano',
          sourceLabel: '/input/Piano.dspreset',
          regions: [
            PolySampleRegion(
              path: '/tmp/A_C3.wav',
              fileName: 'A_C3.wav',
              displayName: 'A_C3.wav',
            ),
            PolySampleRegion(
              path: '/tmp/B_D3.wav',
              fileName: 'B_D3.wav',
              displayName: 'B_D3.wav',
            ),
          ],
          warnings: ['Check mapping'],
        ),
      );

      expect(cubit.state.sourceMode, PolySampleSourceMode.importDraft);
      expect(cubit.state.editedRegions, hasLength(2));
      expect(cubit.state.warnings, contains('Check mapping'));
      expect(cubit.state.currentInstrument!.name, 'Imported Piano');
    });

    test('addStagedRegions merges without duplicating paths', () async {
      final cubit = PolyMultisampleBuilderCubit(
        previewService: PolyAudioPreviewService(adapter: _FakePreviewAdapter()),
      );
      addTearDown(cubit.close);

      await cubit.adoptStagedImport(
        const PolyStagedImport(
          name: 'Imported Piano',
          sourceLabel: '/input/Piano.dspreset',
          regions: [
            PolySampleRegion(
              path: '/tmp/A_C3.wav',
              fileName: 'A_C3.wav',
              displayName: 'A_C3.wav',
            ),
            PolySampleRegion(
              path: '/tmp/B_D3.wav',
              fileName: 'B_D3.wav',
              displayName: 'B_D3.wav',
            ),
          ],
        ),
      );

      await cubit.addStagedRegions(
        const PolyStagedImport(
          name: 'More Piano',
          sourceLabel: '/input/More.dspreset',
          regions: [
            PolySampleRegion(
              path: '/tmp/B_D3.wav',
              fileName: 'B_D3.wav',
              displayName: 'B_D3.wav',
            ),
            PolySampleRegion(
              path: '/tmp/C_E3.wav',
              fileName: 'C_E3.wav',
              displayName: 'C_E3.wav',
            ),
          ],
        ),
      );

      expect(cubit.state.editedRegions.map((region) => region.path).toSet(), {
        '/tmp/A_C3.wav',
        '/tmp/B_D3.wav',
        '/tmp/C_E3.wav',
      });
      expect(cubit.state.editedRegions, hasLength(3));
    });

    test('addStagedRegions is a no-op without an instrument', () async {
      final cubit = PolyMultisampleBuilderCubit(
        previewService: PolyAudioPreviewService(adapter: _FakePreviewAdapter()),
      );
      addTearDown(cubit.close);

      await cubit.addStagedRegions(
        const PolyStagedImport(
          name: 'More Piano',
          sourceLabel: '/input/More.dspreset',
          regions: [
            PolySampleRegion(
              path: '/tmp/C_E3.wav',
              fileName: 'C_E3.wav',
              displayName: 'C_E3.wav',
            ),
          ],
        ),
      );

      expect(cubit.state.currentInstrument, isNull);
      expect(cubit.state.editedRegions, isEmpty);
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

    test('saveDestructiveWav forwards fade curve and strength', () {
      const draft = PolyWaveformDraft(
        fadeInCurve: WavFadeCurve.sCurve,
        fadeOutCurve: WavFadeCurve.equalPower,
        fadeInStrength: 0.8,
        fadeOutStrength: 0.2,
        normalizePeakDb: -0.3,
      );

      final unchanged = draft.copyWith();

      expect(unchanged.fadeInCurve, WavFadeCurve.sCurve);
      expect(unchanged.fadeOutCurve, WavFadeCurve.equalPower);
      expect(unchanged.fadeInStrength, 0.8);
      expect(unchanged.fadeOutStrength, 0.2);
      expect(unchanged.normalizePeakDb, -0.3);

      final clearedNormalize = draft.copyWith(clearNormalize: true);

      expect(clearedNormalize.normalizePeakDb, isNull);
      expect(clearedNormalize.fadeInCurve, WavFadeCurve.sCurve);
      expect(clearedNormalize.fadeOutCurve, WavFadeCurve.equalPower);
      expect(clearedNormalize.fadeInStrength, 0.8);
      expect(clearedNormalize.fadeOutStrength, 0.2);
    });

    test('downloads hardware samples to a local preview cache', () async {
      final adapter = _FakePreviewAdapter();
      final previewService = PolyAudioPreviewService(adapter: adapter);
      final cubit = PolyMultisampleBuilderCubit(
        hardwareService: const _PreviewHardwareService(),
        previewService: previewService,
      );
      final manager = _MockDistingMidiManager();
      addTearDown(cubit.close);

      await cubit.loadHardwareFolder(manager, '/samples/Piano');
      await cubit.playOrStopPreview(
        '/samples/Piano/Piano_C3.wav',
        manager: manager,
      );

      expect(
        cubit.state.previewState.visiblePath,
        '/samples/Piano/Piano_C3.wav',
      );
      expect(adapter.playedPaths.single, isNot('/samples/Piano/Piano_C3.wav'));
      expect(File(adapter.playedPaths.single).readAsBytesSync(), [1, 2, 3]);

      await cubit.playOrStopPreview(
        '/samples/Piano/Piano_C3.wav',
        manager: manager,
      );

      expect(cubit.state.previewState.visiblePath, isNull);
      expect(adapter.stopCount, 1);
    });

    test('custom draft save refuses to overwrite an existing sample', () async {
      final sourceFolder = Directory('${tempRoot.path}/source')
        ..createSync(recursive: true);
      final outputFolder = Directory('${tempRoot.path}/output')
        ..createSync(recursive: true);
      File('${sourceFolder.path}/SoftPiano_C3.wav').writeAsBytesSync([1, 2, 3]);
      final existingOutput = File('${outputFolder.path}/SoftPiano_C3.wav')
        ..writeAsBytesSync([9]);
      final cubit = PolyMultisampleBuilderCubit(
        previewService: PolyAudioPreviewService(adapter: _FakePreviewAdapter()),
      );
      addTearDown(cubit.close);

      await cubit.loadLocalFolder(sourceFolder.path);
      await cubit.saveCustomDraft(outputFolder.path);

      expect(cubit.state.error, contains('already exists'));
      expect(existingOutput.readAsBytesSync(), [9]);
      expect(
        File(
          '${outputFolder.path}/poly_multisample_build_report.txt',
        ).existsSync(),
        isFalse,
      );
    });

    test(
      'custom draft save refuses output inside staged import temp root',
      () async {
        final tempImport = Directory('${tempRoot.path}/temp_import')
          ..createSync(recursive: true);
        final outputFolder = Directory('${tempImport.path}/export')
          ..createSync(recursive: true);
        final cubit = PolyMultisampleBuilderCubit(
          importService: _TempRootImportService(tempImport.path),
          previewService: PolyAudioPreviewService(
            adapter: _FakePreviewAdapter(),
          ),
        );
        addTearDown(cubit.close);

        await cubit.stageDecentSource(
          '/input/Preset.dspreset',
          const DecentSamplerConvertOptions(),
        );
        await cubit.saveCustomDraft(outputFolder.path);

        expect(cubit.state.error, contains('outside the staged import'));
        expect(tempImport.existsSync(), isTrue);
        expect(outputFolder.existsSync(), isTrue);
      },
    );

    test(
      'custom draft save refuses symlink output inside staged import temp root',
      () async {
        final tempImport = Directory('${tempRoot.path}/temp_import_symlinked')
          ..createSync(recursive: true);
        final symlink = Link('${tempRoot.path}/linked_import')
          ..createSync(tempImport.path);
        final outputFolder = Directory('${symlink.path}/export')
          ..createSync(recursive: true);
        final cubit = PolyMultisampleBuilderCubit(
          importService: _TempRootImportService(tempImport.path),
          previewService: PolyAudioPreviewService(
            adapter: _FakePreviewAdapter(),
          ),
        );
        addTearDown(cubit.close);

        await cubit.stageDecentSource(
          '/input/Preset.dspreset',
          const DecentSamplerConvertOptions(),
        );
        await cubit.saveCustomDraft(outputFolder.path);

        expect(cubit.state.error, contains('outside the staged import'));
        expect(tempImport.existsSync(), isTrue);
        expect(outputFolder.existsSync(), isTrue);
      },
    );

    test(
      'hardware folder list clears a previously loaded instrument',
      () async {
        final sample = File('${tempRoot.path}/SoftPiano_C3.wav')
          ..writeAsBytesSync([1, 2, 3]);
        final cubit = PolyMultisampleBuilderCubit(
          hardwareService: const _EmptyHardwareService(),
          previewService: PolyAudioPreviewService(
            adapter: _FakePreviewAdapter(),
          ),
        );
        addTearDown(cubit.close);

        await cubit.loadLocalFolder(tempRoot.path);
        expect(cubit.state.currentInstrument, isNotNull);
        expect(cubit.state.currentInstrument!.regions.single.path, sample.path);

        await cubit.loadHardwareFolderList(_MockDistingMidiManager());

        expect(cubit.state.sourceMode, PolySampleSourceMode.hardware);
        expect(cubit.state.status, PolyMultisampleLoadStatus.ready);
        expect(cubit.state.currentInstrument, isNull);
        expect(cubit.state.editedRegions, isEmpty);
        expect(cubit.state.baselineRegions, isEmpty);
        expect(cubit.state.hardwareFolders, isEmpty);
      },
    );

    test('ignores delayed scan completion after close', () async {
      final folderService = _DelayedFolderService();
      final cubit = PolyMultisampleBuilderCubit(
        folderService: folderService,
        previewService: PolyAudioPreviewService(adapter: _FakePreviewAdapter()),
      );

      final load = cubit.loadLocalFolder(tempRoot.path);
      await cubit.close();
      folderService.complete(
        PolySampleFolderScanResult(
          sourcePath: tempRoot.path,
          audioFileCount: 0,
          ignoredFileCount: 0,
          scannedItemCount: 0,
          largeFolderThreshold: 2000,
          isLargeFolder: false,
          instrument: PolySampleInstrument(
            name: 'Closed',
            sourcePath: tempRoot.path,
            regions: const [],
          ),
        ),
      );

      await expectLater(load, completes);
    });

    test('cleans staged import temp roots on close', () async {
      final tempImport = Directory('${tempRoot.path}/import_temp')
        ..createSync(recursive: true);
      File('${tempImport.path}/SoftPiano_C3.wav').writeAsBytesSync([1, 2, 3]);
      final cubit = PolyMultisampleBuilderCubit(
        importService: _TempRootImportService(tempImport.path),
        previewService: PolyAudioPreviewService(adapter: _FakePreviewAdapter()),
      );

      await cubit.stageDecentSource(
        '/input/Preset.dspreset',
        const DecentSamplerConvertOptions(),
      );
      expect(tempImport.existsSync(), isTrue);

      await cubit.close();

      expect(tempImport.existsSync(), isFalse);
    });

    test(
      'cleans delayed import temp roots when closed before staging completes',
      () async {
        final tempImport = Directory('${tempRoot.path}/delayed_import_temp')
          ..createSync(recursive: true);
        File('${tempImport.path}/SoftPiano_C3.wav').writeAsBytesSync([1, 2, 3]);
        final importService = _DelayedImportService();
        final cubit = PolyMultisampleBuilderCubit(
          importService: importService,
          previewService: PolyAudioPreviewService(
            adapter: _FakePreviewAdapter(),
          ),
        );

        final staging = cubit.stageDecentSource(
          '/input/Preset.dspreset',
          const DecentSamplerConvertOptions(),
        );
        await cubit.close();
        importService.complete(tempImport.path);
        await expectLater(staging, completes);

        expect(tempImport.existsSync(), isFalse);
      },
    );

    test(
      'defers import temp cleanup while a custom draft save is active',
      () async {
        final tempImport = Directory('${tempRoot.path}/save_import_temp')
          ..createSync(recursive: true);
        final sample = File('${tempImport.path}/SoftPiano_C3.wav')
          ..writeAsBytesSync([1, 2, 3]);
        final outputFolder = Directory('${tempRoot.path}/save_output')
          ..createSync(recursive: true);
        final applyService = _BlockingApplyService();
        final cubit = PolyMultisampleBuilderCubit(
          importService: _TempRootImportService(tempImport.path),
          applyService: applyService,
          previewService: PolyAudioPreviewService(
            adapter: _FakePreviewAdapter(),
          ),
        );

        await cubit.stageDecentSource(
          '/input/Preset.dspreset',
          const DecentSamplerConvertOptions(),
        );
        final save = cubit.saveCustomDraft(outputFolder.path);
        await applyService.started.future;
        await cubit.close();

        expect(tempImport.existsSync(), isTrue);
        expect(sample.existsSync(), isTrue);

        applyService.complete();
        await expectLater(save, completes);

        expect(tempImport.existsSync(), isFalse);
      },
    );

    test(
      'defers replaced import temp cleanup while a custom draft save is active',
      () async {
        final firstTemp = Directory('${tempRoot.path}/first_import_temp')
          ..createSync(recursive: true);
        final firstSample = File('${firstTemp.path}/SoftPiano_C3.wav')
          ..writeAsBytesSync([1, 2, 3]);
        final secondTemp = Directory('${tempRoot.path}/second_import_temp')
          ..createSync(recursive: true);
        File('${secondTemp.path}/SoftPiano_D3.wav').writeAsBytesSync([4, 5, 6]);
        final outputFolder = Directory('${tempRoot.path}/replace_output')
          ..createSync(recursive: true);
        final importService = _QueuedImportService([
          firstTemp.path,
          secondTemp.path,
        ]);
        final applyService = _BlockingApplyService();
        final cubit = PolyMultisampleBuilderCubit(
          importService: importService,
          applyService: applyService,
          previewService: PolyAudioPreviewService(
            adapter: _FakePreviewAdapter(),
          ),
        );

        await cubit.stageDecentSource(
          '/input/First.dspreset',
          const DecentSamplerConvertOptions(),
        );
        final save = cubit.saveCustomDraft(outputFolder.path);
        await applyService.started.future;
        await cubit.stageDecentSource(
          '/input/Second.dspreset',
          const DecentSamplerConvertOptions(),
        );

        expect(firstTemp.existsSync(), isTrue);
        expect(firstSample.existsSync(), isTrue);
        expect(secondTemp.existsSync(), isTrue);

        applyService.complete();
        await expectLater(save, completes);

        expect(firstTemp.existsSync(), isFalse);
        expect(secondTemp.existsSync(), isTrue);
        expect(cubit.state.sourceMode, PolySampleSourceMode.importDraft);
        expect(cubit.state.currentInstrument?.sourcePath, secondTemp.path);
        await cubit.close();
        expect(secondTemp.existsSync(), isFalse);
      },
    );

    test('does not let stale save use a newer import draft', () async {
      final firstTemp = Directory('${tempRoot.path}/first_stale_save_temp')
        ..createSync(recursive: true);
      File('${firstTemp.path}/SoftPiano_C3.wav').writeAsBytesSync([1, 2, 3]);
      final secondTemp = Directory('${tempRoot.path}/second_stale_save_temp')
        ..createSync(recursive: true);
      File('${secondTemp.path}/SoftPiano_D3.wav').writeAsBytesSync([4, 5, 6]);
      final outputFolder = Directory('${tempRoot.path}/stale_save_output')
        ..createSync(recursive: true);
      final importService = _QueuedImportService([
        firstTemp.path,
        secondTemp.path,
      ]);
      final applyService = _RecordingApplyService();
      final cubit = PolyMultisampleBuilderCubit(
        importService: importService,
        applyService: applyService,
        previewService: PolyAudioPreviewService(adapter: _FakePreviewAdapter()),
      );

      await cubit.stageDecentSource(
        '/input/First.dspreset',
        const DecentSamplerConvertOptions(),
      );
      final save = cubit.saveCustomDraft(outputFolder.path);
      await applyService.started.future;
      await cubit.stageDecentSource(
        '/input/Second.dspreset',
        const DecentSamplerConvertOptions(),
      );
      applyService.complete();
      await expectLater(save, completes);

      expect(
        applyService.plans.single.additions.single.sourcePath,
        startsWith(firstTemp.path),
      );
      expect(cubit.state.currentInstrument?.sourcePath, secondTemp.path);
      expect(
        outputFolder.listSync().whereType<File>().map(
          (file) => file.uri.pathSegments.last,
        ),
        contains('SoftPiano_C3.wav'),
      );
    });

    test(
      'latest concurrent import wins when imports complete out of order',
      () async {
        final firstTemp = Directory('${tempRoot.path}/slow_import_temp')
          ..createSync(recursive: true);
        final secondTemp = Directory('${tempRoot.path}/fast_import_temp')
          ..createSync(recursive: true);
        final importService = _TwoStageImportService();
        final cubit = PolyMultisampleBuilderCubit(
          importService: importService,
          previewService: PolyAudioPreviewService(
            adapter: _FakePreviewAdapter(),
          ),
        );
        addTearDown(cubit.close);

        final first = cubit.stageDecentSource(
          '/input/Slow.dspreset',
          const DecentSamplerConvertOptions(),
        );
        final second = cubit.stageDecentSource(
          '/input/Fast.dspreset',
          const DecentSamplerConvertOptions(),
        );

        importService.completeSecond(secondTemp.path);
        await second;
        expect(cubit.state.currentInstrument?.sourcePath, secondTemp.path);

        importService.completeFirst(firstTemp.path);
        await first;

        expect(cubit.state.currentInstrument?.sourcePath, secondTemp.path);
        expect(firstTemp.existsSync(), isFalse);
        expect(secondTemp.existsSync(), isTrue);
      },
    );
  });
}

class _EmptyHardwareService extends PolySampleHardwareService {
  const _EmptyHardwareService();

  @override
  Future<List<String>> listSampleFolders(IDistingMidiManager manager) async {
    return const [];
  }
}

class _PreviewHardwareService extends PolySampleHardwareService {
  const _PreviewHardwareService();

  @override
  Future<PolySampleInstrument> readSampleFolder(
    IDistingMidiManager manager,
    String folderPath,
  ) async {
    return const PolySampleInstrument(
      name: 'Piano',
      sourcePath: '/samples/Piano',
      regions: [
        PolySampleRegion(
          path: '/samples/Piano/Piano_C3.wav',
          fileName: 'Piano_C3.wav',
          displayName: 'Piano_C3.wav',
          rootMidi: 48,
          rootName: 'C3',
        ),
      ],
    );
  }

  @override
  Future<Uint8List?> downloadSampleBytes(
    IDistingMidiManager manager,
    String path,
  ) async {
    return Uint8List.fromList([1, 2, 3]);
  }
}

class _DelayedFolderService extends PolySampleFolderService {
  final _completer = Completer<PolySampleFolderScanResult>();

  @override
  Future<PolySampleFolderScanResult> scanLocalFolder(
    String directoryPath, {
    int largeFolderThreshold = 2000,
    bool includeLargeFolders = false,
    bool useIsolate = true,
    void Function(PolySampleFolderScanProgress progress)? onProgress,
  }) {
    return _completer.future;
  }

  void complete(PolySampleFolderScanResult result) {
    _completer.complete(result);
  }
}

class _TempRootImportService extends PolySampleImportService {
  _TempRootImportService(this.tempRoot);

  final String tempRoot;

  @override
  Future<PolyStagedImport> stageDecentSource(
    String path, {
    DecentSamplerConvertOptions options = const DecentSamplerConvertOptions(),
    String? outputParentPath,
  }) async {
    return PolyStagedImport(
      name: 'Imported',
      sourceLabel: path,
      regions: const [],
      tempRoots: [tempRoot],
    );
  }
}

class _DelayedImportService extends PolySampleImportService {
  final _completer = Completer<PolyStagedImport>();

  @override
  Future<PolyStagedImport> stageDecentSource(
    String path, {
    DecentSamplerConvertOptions options = const DecentSamplerConvertOptions(),
    String? outputParentPath,
  }) {
    return _completer.future;
  }

  void complete(String tempRoot) {
    _completer.complete(
      PolyStagedImport(
        name: 'Imported',
        sourceLabel: '/input/Preset.dspreset',
        regions: const [],
        tempRoots: [tempRoot],
      ),
    );
  }
}

class _QueuedImportService extends PolySampleImportService {
  _QueuedImportService(this.tempRoots);

  final List<String> tempRoots;
  var _index = 0;

  @override
  Future<PolyStagedImport> stageDecentSource(
    String path, {
    DecentSamplerConvertOptions options = const DecentSamplerConvertOptions(),
    String? outputParentPath,
  }) async {
    final tempRoot = tempRoots[_index++];
    return PolyStagedImport(
      name: 'Imported $_index',
      sourceLabel: path,
      regions: [
        PolyMultisampleParser.parseFile(
          File(
            '$tempRoot/${_index == 1 ? 'SoftPiano_C3.wav' : 'SoftPiano_D3.wav'}',
          ),
          basePath: tempRoot,
        ),
      ],
      tempRoots: [tempRoot],
    );
  }
}

class _TwoStageImportService extends PolySampleImportService {
  final _first = Completer<PolyStagedImport>();
  final _second = Completer<PolyStagedImport>();
  var _callCount = 0;

  @override
  Future<PolyStagedImport> stageDecentSource(
    String path, {
    DecentSamplerConvertOptions options = const DecentSamplerConvertOptions(),
    String? outputParentPath,
  }) {
    _callCount++;
    return _callCount == 1 ? _first.future : _second.future;
  }

  void completeFirst(String tempRoot) {
    _first.complete(
      PolyStagedImport(
        name: 'Slow',
        sourceLabel: '/input/Slow.dspreset',
        regions: const [],
        tempRoots: [tempRoot],
      ),
    );
  }

  void completeSecond(String tempRoot) {
    _second.complete(
      PolyStagedImport(
        name: 'Fast',
        sourceLabel: '/input/Fast.dspreset',
        regions: const [],
        tempRoots: [tempRoot],
      ),
    );
  }
}

class _BlockingApplyService extends PolySampleApplyService {
  final started = Completer<void>();
  final _finish = Completer<void>();

  @override
  Future<void> applyLocalPlan(PolySampleApplyPlan plan) async {
    if (!started.isCompleted) started.complete();
    await _finish.future;
  }

  void complete() {
    _finish.complete();
  }
}

class _RecordingApplyService extends PolySampleApplyService {
  final plans = <PolySampleApplyPlan>[];
  final started = Completer<void>();
  final _finish = Completer<void>();

  @override
  Future<void> applyLocalPlan(PolySampleApplyPlan plan) async {
    plans.add(plan);
    if (!started.isCompleted) started.complete();
    await super.applyLocalPlan(plan);
    await _finish.future;
  }

  void complete() {
    _finish.complete();
  }
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
