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
import 'package:nt_helper/poly_multisample/poly_sample_upload_service.dart';
import 'package:nt_helper/poly_multisample/poly_wav_service.dart';
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

    test(
      'loads remembered mounted upload folder into state on construction',
      () async {
        SharedPreferences.setMockInitialValues({
          'poly_multisample.lastMountedUploadFolder':
              '/Volumes/NT/samples/Piano',
        });
        final service = await PolySamplePreferencesService.create();
        final cubit = PolyMultisampleBuilderCubit(
          preferencesService: service,
          previewService: PolyAudioPreviewService(
            adapter: _FakePreviewAdapter(),
          ),
        );
        addTearDown(cubit.close);

        await Future<void>.delayed(Duration.zero);

        expect(
          cubit.state.lastMountedUploadFolder,
          '/Volumes/NT/samples/Piano',
        );
      },
    );

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

    test('applyChanges stops preview when replacing the same path', () async {
      final existing = File('${tempRoot.path}/SoftPiano_C3.wav')
        ..writeAsBytesSync([1, 2, 3]);
      final sourceDir = Directory('${tempRoot.path}/source')
        ..createSync(recursive: true);
      final replacement = File('${sourceDir.path}/SoftPiano_C3.wav')
        ..writeAsBytesSync([4, 5, 6]);
      final adapter = _FakePreviewAdapter();
      final previewService = PolyAudioPreviewService(adapter: adapter);
      final cubit = _ExposedPolyMultisampleBuilderCubit(
        previewService: previewService,
      );
      addTearDown(cubit.close);
      await cubit.playOrStopPreview(existing.path);
      await Future<void>.delayed(Duration.zero);

      final baseline = PolySampleRegion(
        path: existing.path,
        fileName: 'SoftPiano_C3.wav',
        displayName: 'SoftPiano_C3.wav',
        rootMidi: 48,
      );
      final edited = PolySampleRegion(
        path: replacement.path,
        fileName: 'SoftPiano_C3.wav',
        displayName: 'SoftPiano_C3.wav',
        rootMidi: 48,
      );
      cubit.setTestState(
        cubit.state.copyWith(
          sourceMode: PolySampleSourceMode.local,
          currentInstrument: PolySampleInstrument(
            name: 'Piano',
            sourcePath: tempRoot.path,
            regions: [baseline],
          ),
          baselineRegions: [baseline],
          editedRegions: [edited],
          selectedPaths: {replacement.path},
          focusedPath: replacement.path,
        ),
      );

      await cubit.applyChanges();
      await Future<void>.delayed(Duration.zero);

      expect(adapter.stopCount, 1);
      expect(cubit.state.previewState.visiblePath, isNull);
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

    test('auto-preview plays a newly selected wav region', () async {
      final adapter = _FakePreviewAdapter();
      final previewService = PolyAudioPreviewService(adapter: adapter);
      final cubit = PolyMultisampleBuilderCubit(
        wavService: const _FakeWavService(),
        previewService: previewService,
      );
      addTearDown(cubit.close);

      cubit.setAutoPreview(true);
      cubit.selectRegion('/tmp/a.wav', PolyRegionSelectionMode.replace);
      await Future<void>.delayed(Duration.zero);

      expect(adapter.playedPaths, ['/tmp/a.wav']);
    });

    test('deselecting a wav does not auto-preview or load waveform', () async {
      final adapter = _FakePreviewAdapter();
      final wavService = _RecordingWavService();
      final cubit = _ExposedPolyMultisampleBuilderCubit(
        wavService: wavService,
        previewService: PolyAudioPreviewService(adapter: adapter),
      );
      addTearDown(cubit.close);
      cubit.setTestState(
        const PolyMultisampleBuilderState(
          sourceMode: PolySampleSourceMode.local,
          autoPreview: true,
          selectedPaths: {'/tmp/a.wav'},
          focusedPath: '/tmp/a.wav',
        ),
      );

      cubit.selectRegion('/tmp/a.wav', PolyRegionSelectionMode.toggle);
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.selectedPaths, isEmpty);
      expect(cubit.state.focusedPath, isNull);
      expect(adapter.playedPaths, isEmpty);
      expect(wavService.loadedPaths, isEmpty);
    });

    test('auto-preview stops when selecting a non-wav sample', () async {
      final adapter = _FakePreviewAdapter();
      final previewService = PolyAudioPreviewService(adapter: adapter);
      final cubit = _ExposedPolyMultisampleBuilderCubit(
        previewService: previewService,
      );
      addTearDown(cubit.close);
      await previewService.playOrStopPreview('/tmp/a.wav');
      await Future<void>.delayed(Duration.zero);
      cubit.setTestState(
        cubit.state.copyWith(
          sourceMode: PolySampleSourceMode.local,
          autoPreview: true,
          editedRegions: const [
            PolySampleRegion(
              path: '/tmp/a.wav',
              fileName: 'a.wav',
              displayName: 'a.wav',
            ),
            PolySampleRegion(
              path: '/tmp/b.aif',
              fileName: 'b.aif',
              displayName: 'b.aif',
            ),
          ],
        ),
      );

      cubit.selectRegion('/tmp/b.aif', PolyRegionSelectionMode.replace);
      await Future<void>.delayed(Duration.zero);

      expect(adapter.playedPaths, ['/tmp/a.wav']);
      expect(adapter.stopCount, 1);
    });

    test('mapping edits clamp values and can focus the edited row', () {
      final cubit = _ExposedPolyMultisampleBuilderCubit(
        previewService: PolyAudioPreviewService(adapter: _FakePreviewAdapter()),
      );
      addTearDown(cubit.close);
      cubit.setTestState(
        const PolyMultisampleBuilderState(
          editedRegions: [
            PolySampleRegion(
              path: '/tmp/a.wav',
              fileName: 'a.wav',
              displayName: 'a.wav',
            ),
            PolySampleRegion(
              path: '/tmp/b.wav',
              fileName: 'b.wav',
              displayName: 'b.wav',
            ),
          ],
          selectedPaths: {'/tmp/a.wav'},
          focusedPath: '/tmp/a.wav',
        ),
      );

      cubit.updateRoot('/tmp/b.wav', -4, focusRegion: true);
      cubit.updateRangeLow('/tmp/b.wav', -1);
      cubit.updateRangeHigh('/tmp/b.wav', 200);
      cubit.updateVelocity('/tmp/b.wav', 0);
      cubit.updateRoundRobin('/tmp/b.wav', 0);

      expect(cubit.state.selectedPaths, {'/tmp/b.wav'});
      expect(cubit.state.focusedPath, '/tmp/b.wav');
      final region = cubit.state.editedRegions.singleWhere(
        (region) => region.path == '/tmp/b.wav',
      );
      expect(region.rootMidi, 0);
      expect(region.rootName, 'C-1');
      expect(region.rangeLow, 0);
      expect(region.rangeHigh, 127);
      expect(region.velocityLayer, 1);
      expect(region.roundRobin, 1);
    });

    test(
      'auto-preview restarts the edited wav after mapping changes',
      () async {
        final adapter = _FakePreviewAdapter();
        final previewService = PolyAudioPreviewService(adapter: adapter);
        final cubit = _ExposedPolyMultisampleBuilderCubit(
          previewService: previewService,
        );
        addTearDown(cubit.close);
        cubit.setTestState(
          const PolyMultisampleBuilderState(
            sourceMode: PolySampleSourceMode.local,
            autoPreview: true,
            editedRegions: [
              PolySampleRegion(
                path: '/tmp/a.wav',
                fileName: 'a.wav',
                displayName: 'a.wav',
              ),
            ],
            selectedPaths: {'/tmp/a.wav'},
            focusedPath: '/tmp/a.wav',
          ),
        );

        await cubit.playOrStopPreview('/tmp/a.wav');
        cubit.updateRoot('/tmp/a.wav', 61);
        await Future<void>.delayed(Duration.zero);

        expect(adapter.playedPaths, ['/tmp/a.wav', '/tmp/a.wav']);
        expect(adapter.stopCount, 1);
      },
    );

    test(
      'auto-preview stops visible preview for non-wav mapping edits',
      () async {
        final adapter = _FakePreviewAdapter();
        final previewService = PolyAudioPreviewService(adapter: adapter);
        final cubit = _ExposedPolyMultisampleBuilderCubit(
          previewService: previewService,
        );
        addTearDown(cubit.close);
        cubit.setTestState(
          const PolyMultisampleBuilderState(
            sourceMode: PolySampleSourceMode.local,
            autoPreview: true,
            editedRegions: [
              PolySampleRegion(
                path: '/tmp/a.wav',
                fileName: 'a.wav',
                displayName: 'a.wav',
              ),
              PolySampleRegion(
                path: '/tmp/b.aif',
                fileName: 'b.aif',
                displayName: 'b.aif',
              ),
            ],
            selectedPaths: {'/tmp/b.aif'},
            focusedPath: '/tmp/b.aif',
          ),
        );

        await cubit.playOrStopPreview('/tmp/a.wav');
        cubit.updateVelocity('/tmp/b.aif', 2);
        await Future<void>.delayed(Duration.zero);

        expect(adapter.playedPaths, ['/tmp/a.wav']);
        expect(adapter.stopCount, 1);
      },
    );

    test('stale hardware mapping auto-preview request does not play', () async {
      final manager = _MockDistingMidiManager();
      final adapter = _FakePreviewAdapter();
      final hardwareService = _QueuedPreviewHardwareService();
      final previewService = PolyAudioPreviewService(adapter: adapter);
      final cubit = _ExposedPolyMultisampleBuilderCubit(
        hardwareService: hardwareService,
        previewService: previewService,
      );
      addTearDown(cubit.close);
      cubit.setTestState(
        const PolyMultisampleBuilderState(
          sourceMode: PolySampleSourceMode.hardware,
          autoPreview: true,
          editedRegions: [
            PolySampleRegion(
              path: '/samples/Piano/Piano_C3.wav',
              fileName: 'Piano_C3.wav',
              displayName: 'Piano_C3.wav',
              rootMidi: 48,
              rootName: 'C3',
            ),
          ],
          selectedPaths: {'/samples/Piano/Piano_C3.wav'},
          focusedPath: '/samples/Piano/Piano_C3.wav',
        ),
      );

      cubit.updateRoot('/samples/Piano/Piano_C3.wav', 49, manager: manager);
      await Future<void>.delayed(Duration.zero);
      expect(hardwareService.completers.length, 1);
      cubit.updateRoot('/samples/Piano/Piano_C3.wav', 50, manager: manager);
      await Future<void>.delayed(Duration.zero);
      expect(hardwareService.completers.length, 2);
      hardwareService.complete(1, [2]);
      await Future<void>.delayed(Duration.zero);
      hardwareService.complete(0, [1]);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(adapter.playedPaths.length, 1);
      expect(File(adapter.playedPaths.single).readAsBytesSync(), [2]);
      expect(cubit.state.editedRegions.single.rootMidi, 50);
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

    test('saveLoopMetadata refreshes an existing waveform summary', () async {
      final wavService = _RecordingWavService();
      final cubit = _ExposedPolyMultisampleBuilderCubit(
        wavService: wavService,
        previewService: PolyAudioPreviewService(adapter: _FakePreviewAdapter()),
      );
      addTearDown(cubit.close);
      cubit.setTestState(
        PolyMultisampleBuilderState(
          waveformSummaries: {'/tmp/a.wav': _overviewWithFrameCount(1000)},
          loopDrafts: const {
            '/tmp/a.wav': PolyWaveformDraft(loopStart: 100, loopEnd: 900),
          },
        ),
      );

      await cubit.saveLoopMetadata('/tmp/a.wav');

      expect(wavService.savedLoops, {'/tmp/a.wav': (100, 900)});
      expect(wavService.loadedPaths, ['/tmp/a.wav']);
      expect(cubit.state.loopDrafts, isNot(contains('/tmp/a.wav')));
    });

    test('saveLoopMetadata reports failures and preserves drafts', () async {
      final wavService = _FailingWavService(saveLoopFails: true);
      final cubit = _ExposedPolyMultisampleBuilderCubit(
        wavService: wavService,
        previewService: PolyAudioPreviewService(adapter: _FakePreviewAdapter()),
      );
      addTearDown(cubit.close);
      cubit.setTestState(
        PolyMultisampleBuilderState(
          loopDrafts: const {
            '/tmp/a.wav': PolyWaveformDraft(loopStart: 100, loopEnd: 900),
          },
        ),
      );

      await cubit.saveLoopMetadata('/tmp/a.wav');

      expect(cubit.state.loopDrafts, contains('/tmp/a.wav'));
      expect(cubit.state.error, contains('save loop failed'));
    });

    test('no-op loop draft is removed instead of staying dirty', () {
      final cubit = _ExposedPolyMultisampleBuilderCubit(
        previewService: PolyAudioPreviewService(adapter: _FakePreviewAdapter()),
      );
      addTearDown(cubit.close);
      cubit.setTestState(
        PolyMultisampleBuilderState(
          waveformSummaries: {'/tmp/a.wav': _overviewWithFrameCount(1000)},
        ),
      );

      cubit.updateLoopDraft(
        '/tmp/a.wav',
        const PolyWaveformDraft(loopStart: 100, loopEnd: 900),
      );
      expect(cubit.state.isDirty, isTrue);

      cubit.updateLoopDraft('/tmp/a.wav', const PolyWaveformDraft());

      expect(cubit.state.loopDrafts, isNot(contains('/tmp/a.wav')));
      expect(cubit.state.isDirty, isFalse);
    });

    test('discardChanges clears waveform drafts', () {
      final cubit = _ExposedPolyMultisampleBuilderCubit(
        previewService: PolyAudioPreviewService(adapter: _FakePreviewAdapter()),
      );
      addTearDown(cubit.close);
      cubit.setTestState(
        const PolyMultisampleBuilderState(
          currentInstrument: PolySampleInstrument(
            name: 'Piano',
            sourcePath: '/tmp',
            regions: [
              PolySampleRegion(
                path: '/tmp/a.wav',
                fileName: 'a.wav',
                displayName: 'a.wav',
              ),
            ],
          ),
          baselineRegions: [
            PolySampleRegion(
              path: '/tmp/a.wav',
              fileName: 'a.wav',
              displayName: 'a.wav',
            ),
          ],
          editedRegions: [
            PolySampleRegion(
              path: '/tmp/a.wav',
              fileName: 'a.wav',
              displayName: 'a.wav',
            ),
          ],
          wavEditDrafts: {'/tmp/a.wav': PolyWaveformDraft(trimStart: 10)},
        ),
      );

      expect(cubit.state.isDirty, isTrue);

      cubit.discardChanges();

      expect(cubit.state.wavEditDrafts, isEmpty);
      expect(cubit.state.loopDrafts, isEmpty);
      expect(cubit.state.isDirty, isFalse);
    });

    test('removeSelectedRegions clears waveform state for removed paths', () {
      final cubit = _ExposedPolyMultisampleBuilderCubit(
        previewService: PolyAudioPreviewService(adapter: _FakePreviewAdapter()),
      );
      addTearDown(cubit.close);
      cubit.setTestState(
        PolyMultisampleBuilderState(
          currentInstrument: const PolySampleInstrument(
            name: 'Piano',
            sourcePath: '/tmp',
            regions: [
              PolySampleRegion(
                path: '/tmp/a.wav',
                fileName: 'a.wav',
                displayName: 'a.wav',
              ),
              PolySampleRegion(
                path: '/tmp/b.wav',
                fileName: 'b.wav',
                displayName: 'b.wav',
              ),
            ],
          ),
          baselineRegions: const [
            PolySampleRegion(
              path: '/tmp/a.wav',
              fileName: 'a.wav',
              displayName: 'a.wav',
            ),
            PolySampleRegion(
              path: '/tmp/b.wav',
              fileName: 'b.wav',
              displayName: 'b.wav',
            ),
          ],
          editedRegions: const [
            PolySampleRegion(
              path: '/tmp/a.wav',
              fileName: 'a.wav',
              displayName: 'a.wav',
            ),
            PolySampleRegion(
              path: '/tmp/b.wav',
              fileName: 'b.wav',
              displayName: 'b.wav',
            ),
          ],
          selectedPaths: const {'/tmp/a.wav'},
          focusedPath: '/tmp/a.wav',
          waveformSummaries: {
            '/tmp/a.wav': _overviewWithFrameCount(1000),
            '/tmp/b.wav': _overviewWithFrameCount(1000),
          },
          loopDrafts: const {
            '/tmp/a.wav': PolyWaveformDraft(loopStart: 10, loopEnd: 100),
            '/tmp/b.wav': PolyWaveformDraft(loopStart: 20, loopEnd: 200),
          },
          wavEditDrafts: const {
            '/tmp/a.wav': PolyWaveformDraft(trimStart: 10),
            '/tmp/b.wav': PolyWaveformDraft(trimStart: 20),
          },
        ),
      );

      cubit.removeSelectedRegions();

      expect(cubit.state.editedRegions.map((region) => region.path), [
        '/tmp/b.wav',
      ]);
      expect(cubit.state.loopDrafts, isNot(contains('/tmp/a.wav')));
      expect(cubit.state.wavEditDrafts, isNot(contains('/tmp/a.wav')));
      expect(cubit.state.waveformSummaries, isNot(contains('/tmp/a.wav')));
      expect(cubit.state.loopDrafts, contains('/tmp/b.wav'));
      expect(cubit.state.wavEditDrafts, contains('/tmp/b.wav'));
      expect(cubit.state.waveformSummaries, contains('/tmp/b.wav'));
    });

    test('removeSelectedRegions stops preview for removed sample', () async {
      final adapter = _FakePreviewAdapter();
      final previewService = PolyAudioPreviewService(adapter: adapter);
      final cubit = _ExposedPolyMultisampleBuilderCubit(
        previewService: previewService,
      );
      addTearDown(cubit.close);
      await previewService.playOrStopPreview('/tmp/a.wav');
      await Future<void>.delayed(Duration.zero);
      cubit.setTestState(
        cubit.state.copyWith(
          currentInstrument: const PolySampleInstrument(
            name: 'Piano',
            sourcePath: '/tmp',
            regions: [
              PolySampleRegion(
                path: '/tmp/a.wav',
                fileName: 'a.wav',
                displayName: 'a.wav',
              ),
            ],
          ),
          baselineRegions: const [
            PolySampleRegion(
              path: '/tmp/a.wav',
              fileName: 'a.wav',
              displayName: 'a.wav',
            ),
          ],
          editedRegions: const [
            PolySampleRegion(
              path: '/tmp/a.wav',
              fileName: 'a.wav',
              displayName: 'a.wav',
            ),
          ],
          selectedPaths: const {'/tmp/a.wav'},
          focusedPath: '/tmp/a.wav',
        ),
      );

      cubit.removeSelectedRegions();
      await Future<void>.delayed(Duration.zero);

      expect(adapter.stopCount, 1);
      expect(cubit.state.previewState.visiblePath, isNull);
    });

    test('clearDraft stops preview for cleared sample', () async {
      final adapter = _FakePreviewAdapter();
      final previewService = PolyAudioPreviewService(adapter: adapter);
      final cubit = _ExposedPolyMultisampleBuilderCubit(
        previewService: previewService,
      );
      addTearDown(cubit.close);
      await previewService.playOrStopPreview('/tmp/a.wav');
      await Future<void>.delayed(Duration.zero);
      cubit.setTestState(
        cubit.state.copyWith(
          currentInstrument: const PolySampleInstrument(
            name: 'Piano',
            sourcePath: '/tmp',
            regions: [
              PolySampleRegion(
                path: '/tmp/a.wav',
                fileName: 'a.wav',
                displayName: 'a.wav',
              ),
            ],
          ),
          editedRegions: const [
            PolySampleRegion(
              path: '/tmp/a.wav',
              fileName: 'a.wav',
              displayName: 'a.wav',
            ),
          ],
          selectedPaths: const {'/tmp/a.wav'},
          focusedPath: '/tmp/a.wav',
        ),
      );

      cubit.clearDraft();
      await Future<void>.delayed(Duration.zero);

      expect(adapter.stopCount, 1);
      expect(cubit.state.previewState.visiblePath, isNull);
    });

    test('applyChanges refuses to clear unsaved waveform drafts', () async {
      final applyService = _RecordingApplyService();
      final cubit = _ExposedPolyMultisampleBuilderCubit(
        applyService: applyService,
        previewService: PolyAudioPreviewService(adapter: _FakePreviewAdapter()),
      );
      addTearDown(cubit.close);
      cubit.setTestState(
        const PolyMultisampleBuilderState(
          sourceMode: PolySampleSourceMode.local,
          currentInstrument: PolySampleInstrument(
            name: 'Piano',
            sourcePath: '/tmp',
            regions: [
              PolySampleRegion(
                path: '/tmp/a.wav',
                fileName: 'a.wav',
                displayName: 'a.wav',
              ),
            ],
          ),
          baselineRegions: [
            PolySampleRegion(
              path: '/tmp/a.wav',
              fileName: 'a.wav',
              displayName: 'a.wav',
            ),
          ],
          editedRegions: [
            PolySampleRegion(
              path: '/tmp/a.wav',
              fileName: 'a.wav',
              displayName: 'a.wav',
            ),
          ],
          wavEditDrafts: {'/tmp/a.wav': PolyWaveformDraft(trimStart: 10)},
        ),
      );

      await cubit.applyChanges();

      expect(applyService.plans, isEmpty);
      expect(cubit.state.wavEditDrafts, contains('/tmp/a.wav'));
      expect(cubit.state.error, contains('Save or discard waveform edits'));
    });

    test(
      'uploadViaMountedSd persists destination and emits success effect',
      () async {
        final uploadService = _FakeUploadService();
        final cubit = _ExposedPolyMultisampleBuilderCubit(
          uploadService: uploadService,
          previewService: PolyAudioPreviewService(
            adapter: _FakePreviewAdapter(),
          ),
        );
        addTearDown(cubit.close);
        cubit.setTestState(
          const PolyMultisampleBuilderState(
            sourceMode: PolySampleSourceMode.importDraft,
            currentInstrument: PolySampleInstrument(
              name: 'Piano',
              sourcePath: '/tmp/Piano',
              regions: [
                PolySampleRegion(
                  path: '/tmp/Piano/Piano_C3.wav',
                  fileName: 'Piano_C3.wav',
                  displayName: 'Piano_C3.wav',
                  rootMidi: 48,
                ),
              ],
            ),
            editedRegions: [
              PolySampleRegion(
                path: '/tmp/Piano/Piano_C3.wav',
                fileName: 'Piano_C3.wav',
                displayName: 'Piano_C3.wav',
                rootMidi: 48,
              ),
            ],
          ),
        );

        await cubit.uploadViaMountedSd('/Volumes/NT/samples/Piano');

        expect(uploadService.mountedDestination, '/Volumes/NT/samples/Piano');
        expect(
          cubit.state.lastMountedUploadFolder,
          '/Volumes/NT/samples/Piano',
        );
        expect(
          cubit.state.activeOperation,
          PolyMultisampleActiveOperation.none,
        );
        expect(
          cubit.state.effect,
          'Uploaded sample folder to /Volumes/NT/samples/Piano.',
        );
      },
    );

    test('uploadViaSysEx targets sanitized instrument folder', () async {
      final uploadService = _FakeUploadService();
      final cubit = _ExposedPolyMultisampleBuilderCubit(
        uploadService: uploadService,
        previewService: PolyAudioPreviewService(adapter: _FakePreviewAdapter()),
      );
      addTearDown(cubit.close);
      cubit.setTestState(
        const PolyMultisampleBuilderState(
          sourceMode: PolySampleSourceMode.local,
          currentInstrument: PolySampleInstrument(
            name: 'Piano/Bad:*Name',
            sourcePath: '/tmp/Piano',
            regions: [
              PolySampleRegion(
                path: '/tmp/Piano/Piano_C3.wav',
                fileName: 'Piano_C3.wav',
                displayName: 'Piano_C3.wav',
                rootMidi: 48,
              ),
            ],
          ),
          editedRegions: [
            PolySampleRegion(
              path: '/tmp/Piano/Piano_C3.wav',
              fileName: 'Piano_C3.wav',
              displayName: 'Piano_C3.wav',
              rootMidi: 48,
            ),
          ],
        ),
      );

      await cubit.uploadViaSysEx(_MockDistingMidiManager());

      expect(uploadService.hardwareFolder, '/samples/Piano_Bad__Name');
      expect(
        cubit.state.effect,
        'Uploaded sample folder to /samples/Piano_Bad__Name.',
      );
    });

    test('uploadViaSysEx reports corrected file count in effect', () async {
      final uploadService = _FakeUploadService(
        result: const PolySampleUploadResult(
          filesUploaded: 1,
          bytesUploaded: 3,
          correctedFiles: 2,
        ),
      );
      final cubit = _ExposedPolyMultisampleBuilderCubit(
        uploadService: uploadService,
        previewService: PolyAudioPreviewService(adapter: _FakePreviewAdapter()),
      );
      addTearDown(cubit.close);
      cubit.setTestState(
        const PolyMultisampleBuilderState(
          sourceMode: PolySampleSourceMode.local,
          currentInstrument: PolySampleInstrument(
            name: 'Piano',
            sourcePath: '/tmp/Piano',
            regions: [
              PolySampleRegion(
                path: '/tmp/Piano/Piano_C3.wav',
                fileName: 'Piano_C3.wav',
                displayName: 'Piano_C3.wav',
                rootMidi: 48,
              ),
            ],
          ),
          editedRegions: [
            PolySampleRegion(
              path: '/tmp/Piano/Piano_C3.wav',
              fileName: 'Piano_C3.wav',
              displayName: 'Piano_C3.wav',
              rootMidi: 48,
            ),
          ],
        ),
      );

      await cubit.uploadViaSysEx(_MockDistingMidiManager());

      expect(
        cubit.state.effect,
        'Uploaded sample folder to /samples/Piano and corrected 2 files.',
      );
    });

    test('upload guards hardware source mode', () async {
      final uploadService = _FakeUploadService();
      final cubit = _ExposedPolyMultisampleBuilderCubit(
        uploadService: uploadService,
        previewService: PolyAudioPreviewService(adapter: _FakePreviewAdapter()),
      );
      addTearDown(cubit.close);
      cubit.setTestState(
        const PolyMultisampleBuilderState(
          sourceMode: PolySampleSourceMode.hardware,
          currentInstrument: PolySampleInstrument(
            name: 'Piano',
            sourcePath: '/samples/Piano',
            regions: [],
          ),
          editedRegions: [
            PolySampleRegion(
              path: '/samples/Piano/Piano_C3.wav',
              fileName: 'Piano_C3.wav',
              displayName: 'Piano_C3.wav',
            ),
          ],
        ),
      );

      await cubit.uploadViaMountedSd('/Volumes/NT/samples/Piano');

      expect(uploadService.mountedCalls, 0);
      expect(
        cubit.state.error,
        'Open or import a local sample folder before uploading.',
      );
    });

    test('upload guards pending waveform edits', () async {
      final uploadService = _FakeUploadService();
      final cubit = _ExposedPolyMultisampleBuilderCubit(
        uploadService: uploadService,
        previewService: PolyAudioPreviewService(adapter: _FakePreviewAdapter()),
      );
      addTearDown(cubit.close);
      cubit.setTestState(
        const PolyMultisampleBuilderState(
          sourceMode: PolySampleSourceMode.local,
          currentInstrument: PolySampleInstrument(
            name: 'Piano',
            sourcePath: '/tmp/Piano',
            regions: [],
          ),
          editedRegions: [
            PolySampleRegion(
              path: '/tmp/Piano/Piano_C3.wav',
              fileName: 'Piano_C3.wav',
              displayName: 'Piano_C3.wav',
            ),
          ],
          wavEditDrafts: {
            '/tmp/Piano/Piano_C3.wav': PolyWaveformDraft(trimStart: 10),
          },
        ),
      );

      await cubit.uploadViaSysEx(_MockDistingMidiManager());

      expect(uploadService.sysexCalls, 0);
      expect(
        cubit.state.error,
        'Save or discard waveform edits before uploading this sample set.',
      );
    });

    test('upload surfaces transport errors', () async {
      final uploadService = _FakeUploadService(
        error: const PolySampleUploadException('boom'),
      );
      final cubit = _ExposedPolyMultisampleBuilderCubit(
        uploadService: uploadService,
        previewService: PolyAudioPreviewService(adapter: _FakePreviewAdapter()),
      );
      addTearDown(cubit.close);
      cubit.setTestState(
        const PolyMultisampleBuilderState(
          sourceMode: PolySampleSourceMode.local,
          currentInstrument: PolySampleInstrument(
            name: 'Piano',
            sourcePath: '/tmp/Piano',
            regions: [],
          ),
          editedRegions: [
            PolySampleRegion(
              path: '/tmp/Piano/Piano_C3.wav',
              fileName: 'Piano_C3.wav',
              displayName: 'Piano_C3.wav',
            ),
          ],
        ),
      );

      await cubit.uploadViaMountedSd('/Volumes/NT/samples/Piano');

      expect(cubit.state.activeOperation, PolyMultisampleActiveOperation.none);
      expect(cubit.state.error, 'boom');
    });

    test(
      'stale upload success is ignored after returning to sources',
      () async {
        final completer = Completer<void>();
        final uploadService = _FakeUploadService(completer: completer);
        final cubit = _ExposedPolyMultisampleBuilderCubit(
          uploadService: uploadService,
          previewService: PolyAudioPreviewService(
            adapter: _FakePreviewAdapter(),
          ),
        );
        addTearDown(cubit.close);
        cubit.setTestState(
          const PolyMultisampleBuilderState(
            sourceMode: PolySampleSourceMode.local,
            currentInstrument: PolySampleInstrument(
              name: 'Piano',
              sourcePath: '/tmp/Piano',
              regions: [],
            ),
            editedRegions: [
              PolySampleRegion(
                path: '/tmp/Piano/Piano_C3.wav',
                fileName: 'Piano_C3.wav',
                displayName: 'Piano_C3.wav',
              ),
            ],
          ),
        );

        final upload = cubit.uploadViaMountedSd('/Volumes/NT/samples/Piano');
        await Future<void>.delayed(Duration.zero);
        await cubit.returnToSources();
        completer.complete();
        await upload;

        expect(cubit.state.currentInstrument, isNull);
        expect(cubit.state.effect, isNull);
      },
    );

    test('saveCustomDraft refuses to clear unsaved waveform drafts', () async {
      final cubit = _ExposedPolyMultisampleBuilderCubit(
        previewService: PolyAudioPreviewService(adapter: _FakePreviewAdapter()),
      );
      addTearDown(cubit.close);
      cubit.setTestState(
        const PolyMultisampleBuilderState(
          sourceMode: PolySampleSourceMode.customDraft,
          currentInstrument: PolySampleInstrument(
            name: 'Draft',
            sourcePath: '/tmp/draft',
            regions: [
              PolySampleRegion(
                path: '/tmp/a.wav',
                fileName: 'a.wav',
                displayName: 'a.wav',
              ),
            ],
          ),
          editedRegions: [
            PolySampleRegion(
              path: '/tmp/a.wav',
              fileName: 'a.wav',
              displayName: 'a.wav',
            ),
          ],
          loopDrafts: {
            '/tmp/a.wav': PolyWaveformDraft(loopStart: 10, loopEnd: 100),
          },
        ),
      );

      await cubit.saveCustomDraft('${tempRoot.path}/out');

      expect(cubit.state.loopDrafts, contains('/tmp/a.wav'));
      expect(cubit.state.error, contains('Save or discard waveform edits'));
    });

    test(
      'overwrite destructive wav refreshes an existing waveform summary',
      () async {
        final wavService = _RecordingWavService();
        final cubit = _ExposedPolyMultisampleBuilderCubit(
          wavService: wavService,
          previewService: PolyAudioPreviewService(
            adapter: _FakePreviewAdapter(),
          ),
        );
        addTearDown(cubit.close);
        cubit.setTestState(
          PolyMultisampleBuilderState(
            waveformSummaries: {'/tmp/a.wav': _overviewWithFrameCount(1000)},
            wavEditDrafts: const {
              '/tmp/a.wav': PolyWaveformDraft(trimStart: 0, trimEnd: 999),
            },
          ),
        );

        await cubit.saveDestructiveWav('/tmp/a.wav', '/tmp/a.wav', true);

        expect(wavService.savedTargets, ['/tmp/a.wav']);
        expect(wavService.loadedPaths, ['/tmp/a.wav']);
        expect(cubit.state.wavEditDrafts, isNot(contains('/tmp/a.wav')));
      },
    );

    test('saveDestructiveWav reports failures and preserves drafts', () async {
      final wavService = _FailingWavService(saveWavFails: true);
      final cubit = _ExposedPolyMultisampleBuilderCubit(
        wavService: wavService,
        previewService: PolyAudioPreviewService(adapter: _FakePreviewAdapter()),
      );
      addTearDown(cubit.close);
      cubit.setTestState(
        PolyMultisampleBuilderState(
          waveformSummaries: {'/tmp/a.wav': _overviewWithFrameCount(1000)},
          wavEditDrafts: const {'/tmp/a.wav': PolyWaveformDraft(trimStart: 10)},
        ),
      );

      await cubit.saveDestructiveWav('/tmp/a.wav', '/tmp/a.wav', true);

      expect(cubit.state.wavEditDrafts, contains('/tmp/a.wav'));
      expect(cubit.state.error, contains('save wav failed'));
    });

    test(
      'waveform load completion preserves a newer active operation',
      () async {
        final wavService = _DelayedWavService();
        final cubit = _ExposedPolyMultisampleBuilderCubit(
          wavService: wavService,
          previewService: PolyAudioPreviewService(
            adapter: _FakePreviewAdapter(),
          ),
        );
        addTearDown(cubit.close);

        final load = cubit.loadWaveform('/tmp/a.wav');
        expect(
          cubit.state.activeOperation,
          PolyMultisampleActiveOperation.waveform,
        );
        expect(cubit.state.waveformLoadingPaths, contains('/tmp/a.wav'));

        cubit.setTestState(
          cubit.state.copyWith(
            activeOperation: PolyMultisampleActiveOperation.applying,
          ),
        );
        wavService.complete(_overviewWithFrameCount(2000));
        await load;

        expect(
          cubit.state.activeOperation,
          PolyMultisampleActiveOperation.applying,
        );
        expect(cubit.state.waveformLoadingPaths, isNot(contains('/tmp/a.wav')));
        expect(cubit.state.waveformSummaries, contains('/tmp/a.wav'));
      },
    );

    test(
      'stale waveform load completion is ignored after returning to sources',
      () async {
        final wavService = _DelayedWavService();
        final cubit = _ExposedPolyMultisampleBuilderCubit(
          wavService: wavService,
          previewService: PolyAudioPreviewService(
            adapter: _FakePreviewAdapter(),
          ),
        );
        addTearDown(cubit.close);

        final load = cubit.loadWaveform('/tmp/a.wav');
        await cubit.returnToSources();
        wavService.complete(_overviewWithFrameCount(2000));
        await load;

        expect(cubit.state.waveformSummaries, isNot(contains('/tmp/a.wav')));
        expect(cubit.state.waveformLoadingPaths, isEmpty);
      },
    );

    test(
      'older same-path waveform load cannot overwrite forced refresh',
      () async {
        final wavService = _QueuedWavService();
        final cubit = _ExposedPolyMultisampleBuilderCubit(
          wavService: wavService,
          previewService: PolyAudioPreviewService(
            adapter: _FakePreviewAdapter(),
          ),
        );
        addTearDown(cubit.close);

        final first = cubit.loadWaveform('/tmp/a.wav');
        final second = cubit.loadWaveform('/tmp/a.wav', force: true);
        expect(wavService.completers, hasLength(2));

        wavService.completers[1].complete(_overviewWithFrameCount(2000));
        await second;
        wavService.completers[0].complete(_overviewWithFrameCount(1000));
        await first;

        expect(cubit.state.waveformSummaries['/tmp/a.wav']!.frameCount, 2000);
      },
    );

    test(
      'mapping edit during waveform load clears stale loading state',
      () async {
        final wavService = _DelayedWavService();
        final cubit = _ExposedPolyMultisampleBuilderCubit(
          wavService: wavService,
          previewService: PolyAudioPreviewService(
            adapter: _FakePreviewAdapter(),
          ),
        );
        addTearDown(cubit.close);
        cubit.setTestState(
          const PolyMultisampleBuilderState(
            currentInstrument: PolySampleInstrument(
              name: 'Piano',
              sourcePath: '/tmp',
              regions: [
                PolySampleRegion(
                  path: '/tmp/a.wav',
                  fileName: 'a.wav',
                  displayName: 'a.wav',
                ),
              ],
            ),
            editedRegions: [
              PolySampleRegion(
                path: '/tmp/a.wav',
                fileName: 'a.wav',
                displayName: 'a.wav',
              ),
            ],
          ),
        );

        final load = cubit.loadWaveform('/tmp/a.wav');
        cubit.updateRoot('/tmp/a.wav', 60);
        wavService.complete(_overviewWithFrameCount(2000));
        await load;

        expect(cubit.state.waveformLoadingPaths, isEmpty);
        expect(cubit.state.waveformSummaries, isNot(contains('/tmp/a.wav')));
      },
    );

    test('forced waveform refresh failure removes stale summary', () async {
      final wavService = _FailingWavService();
      final cubit = _ExposedPolyMultisampleBuilderCubit(
        wavService: wavService,
        previewService: PolyAudioPreviewService(adapter: _FakePreviewAdapter()),
      );
      addTearDown(cubit.close);
      cubit.setTestState(
        PolyMultisampleBuilderState(
          waveformSummaries: {'/tmp/a.wav': _overviewWithFrameCount(1000)},
        ),
      );

      await cubit.loadWaveform('/tmp/a.wav', force: true);

      expect(cubit.state.waveformSummaries, isNot(contains('/tmp/a.wav')));
      expect(cubit.state.waveformFailedPaths, contains('/tmp/a.wav'));
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

    test('custom draft save reopens the output as a local folder', () async {
      final sourceFolder = Directory('${tempRoot.path}/source_local')
        ..createSync(recursive: true);
      final outputFolder = Directory('${tempRoot.path}/saved_local')
        ..createSync(recursive: true);
      File('${sourceFolder.path}/SoftPiano_C3.wav').writeAsBytesSync([1, 2, 3]);
      final cubit = PolyMultisampleBuilderCubit(
        previewService: PolyAudioPreviewService(adapter: _FakePreviewAdapter()),
      );
      addTearDown(cubit.close);

      await cubit.loadLocalFolder(sourceFolder.path);
      await cubit.saveCustomDraft(outputFolder.path);

      expect(cubit.state.sourceMode, PolySampleSourceMode.local);
      expect(cubit.state.isDirty, isFalse);
      expect(cubit.state.currentInstrument?.sourcePath, outputFolder.path);
      expect(cubit.state.lastCustomOutputFolder, outputFolder.parent.path);
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
        expect(cubit.state.lastCustomOutputFolder, isNull);
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

    test('ignores delayed local scan after returning to sources', () async {
      final folderService = _DelayedFolderService();
      final cubit = PolyMultisampleBuilderCubit(
        folderService: folderService,
        previewService: PolyAudioPreviewService(adapter: _FakePreviewAdapter()),
      );
      addTearDown(cubit.close);

      final load = cubit.loadLocalFolder(tempRoot.path);
      await Future<void>.delayed(Duration.zero);
      await cubit.returnToSources();
      folderService.complete(
        PolySampleFolderScanResult(
          sourcePath: tempRoot.path,
          audioFileCount: 1,
          ignoredFileCount: 0,
          scannedItemCount: 1,
          largeFolderThreshold: 2000,
          isLargeFolder: false,
          instrument: PolySampleInstrument(
            name: 'Stale',
            sourcePath: tempRoot.path,
            regions: const [
              PolySampleRegion(
                path: '/tmp/stale.wav',
                fileName: 'stale.wav',
                displayName: 'stale.wav',
              ),
            ],
          ),
        ),
      );
      await load;

      expect(cubit.state.sourceMode, PolySampleSourceMode.none);
      expect(cubit.state.status, PolyMultisampleLoadStatus.idle);
      expect(cubit.state.currentInstrument, isNull);
    });

    test('ignores delayed local scan after hardware list starts', () async {
      final folderService = _DelayedFolderService();
      final hardwareService = _DelayedHardwareService();
      final cubit = PolyMultisampleBuilderCubit(
        folderService: folderService,
        hardwareService: hardwareService,
        previewService: PolyAudioPreviewService(adapter: _FakePreviewAdapter()),
      );
      addTearDown(cubit.close);
      final manager = _MockDistingMidiManager();

      final localLoad = cubit.loadLocalFolder(tempRoot.path);
      await Future<void>.delayed(Duration.zero);
      final hardwareList = cubit.loadHardwareFolderList(manager);
      hardwareService.completeFolders(const ['/samples/Piano']);
      await hardwareList;
      folderService.complete(
        PolySampleFolderScanResult(
          sourcePath: tempRoot.path,
          audioFileCount: 1,
          ignoredFileCount: 0,
          scannedItemCount: 1,
          largeFolderThreshold: 2000,
          isLargeFolder: false,
          instrument: PolySampleInstrument(
            name: 'Stale',
            sourcePath: tempRoot.path,
            regions: const [
              PolySampleRegion(
                path: '/tmp/stale.wav',
                fileName: 'stale.wav',
                displayName: 'stale.wav',
              ),
            ],
          ),
        ),
      );
      await localLoad;

      expect(cubit.state.sourceMode, PolySampleSourceMode.hardware);
      expect(cubit.state.hardwareFolders, ['/samples/Piano']);
      expect(cubit.state.currentInstrument, isNull);
    });

    test(
      'ignores delayed hardware folder after returning to sources',
      () async {
        final hardwareService = _DelayedHardwareService();
        final cubit = PolyMultisampleBuilderCubit(
          hardwareService: hardwareService,
          previewService: PolyAudioPreviewService(
            adapter: _FakePreviewAdapter(),
          ),
        );
        addTearDown(cubit.close);
        final manager = _MockDistingMidiManager();

        final load = cubit.loadHardwareFolder(manager, '/samples/Piano');
        await Future<void>.delayed(Duration.zero);
        await cubit.returnToSources();
        hardwareService.completeInstrument(
          const PolySampleInstrument(
            name: 'Piano',
            sourcePath: '/samples/Piano',
            regions: [
              PolySampleRegion(
                path: '/samples/Piano/Piano_C3.wav',
                fileName: 'Piano_C3.wav',
                displayName: 'Piano_C3.wav',
              ),
            ],
          ),
        );
        await load;

        expect(cubit.state.sourceMode, PolySampleSourceMode.none);
        expect(cubit.state.status, PolyMultisampleLoadStatus.idle);
        expect(cubit.state.currentInstrument, isNull);
      },
    );

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

class _QueuedPreviewHardwareService extends PolySampleHardwareService {
  final completers = <Completer<Uint8List?>>[];

  @override
  Future<Uint8List?> downloadSampleBytes(
    IDistingMidiManager manager,
    String path,
  ) {
    final completer = Completer<Uint8List?>();
    completers.add(completer);
    return completer.future;
  }

  void complete(int index, List<int> bytes) {
    completers[index].complete(Uint8List.fromList(bytes));
  }
}

class _DelayedHardwareService extends PolySampleHardwareService {
  final _folders = Completer<List<String>>();
  final _instrument = Completer<PolySampleInstrument>();

  @override
  Future<List<String>> listSampleFolders(IDistingMidiManager manager) {
    return _folders.future;
  }

  @override
  Future<PolySampleInstrument> readSampleFolder(
    IDistingMidiManager manager,
    String folderPath,
  ) {
    return _instrument.future;
  }

  void completeFolders(List<String> folders) {
    _folders.complete(folders);
  }

  void completeInstrument(PolySampleInstrument instrument) {
    _instrument.complete(instrument);
  }
}

class _FakeUploadService extends PolySampleUploadService {
  _FakeUploadService({this.result, this.error, this.completer});

  final PolySampleUploadResult? result;
  final Object? error;
  final Completer<void>? completer;
  String? mountedDestination;
  String? hardwareFolder;
  int mountedCalls = 0;
  int sysexCalls = 0;

  @override
  Future<PolySampleUploadResult> uploadMountedSd({
    required List<PolySampleRegion> regions,
    required String destinationFolder,
    PolySampleUploadProgress? onProgress,
  }) async {
    mountedCalls++;
    mountedDestination = destinationFolder;
    onProgress?.call('Uploading fake sample...');
    await completer?.future;
    final error = this.error;
    if (error != null) throw error;
    return result ??
        const PolySampleUploadResult(
          filesUploaded: 1,
          bytesUploaded: 3,
          correctedFiles: 0,
        );
  }

  @override
  Future<PolySampleUploadResult> uploadSysEx({
    required IDistingMidiManager manager,
    required List<PolySampleRegion> regions,
    required String hardwareFolder,
    PolySampleUploadProgress? onProgress,
  }) async {
    sysexCalls++;
    this.hardwareFolder = hardwareFolder;
    onProgress?.call('Uploading fake sample...');
    await completer?.future;
    final error = this.error;
    if (error != null) throw error;
    return result ??
        const PolySampleUploadResult(
          filesUploaded: 1,
          bytesUploaded: 3,
          correctedFiles: 0,
        );
  }
}

class _FakeWavService extends PolyWavService {
  const _FakeWavService();

  @override
  Future<WavOverview> loadWaveform(String path, {int peakCount = 360}) async {
    return WavOverview(
      sampleRate: 44100,
      frameCount: 1000,
      peaks: List<WavPeak>.filled(4, const WavPeak(min: -0.5, max: 0.5)),
      zeroCrossings: const [0, 999],
    );
  }
}

class _RecordingWavService extends PolyWavService {
  final loadedPaths = <String>[];
  final savedTargets = <String>[];
  final savedLoops = <String, (int, int)>{};

  @override
  Future<WavOverview> loadWaveform(String path, {int peakCount = 360}) async {
    loadedPaths.add(path);
    return _overviewWithFrameCount(2000);
  }

  @override
  Future<void> saveLoopMetadata(
    String path, {
    required int loopStart,
    required int loopEnd,
  }) async {
    savedLoops[path] = (loopStart, loopEnd);
  }

  @override
  Future<void> saveDestructiveWav(
    String sourcePath,
    String targetPath,
    WavRenderOptions options, {
    bool overwriteConfirmed = false,
  }) async {
    savedTargets.add(targetPath);
  }
}

class _DelayedWavService extends PolyWavService {
  final _completer = Completer<WavOverview>();

  @override
  Future<WavOverview> loadWaveform(String path, {int peakCount = 360}) {
    return _completer.future;
  }

  void complete(WavOverview overview) {
    _completer.complete(overview);
  }
}

class _QueuedWavService extends PolyWavService {
  final completers = <Completer<WavOverview>>[];

  @override
  Future<WavOverview> loadWaveform(String path, {int peakCount = 360}) {
    final completer = Completer<WavOverview>();
    completers.add(completer);
    return completer.future;
  }
}

class _FailingWavService extends PolyWavService {
  const _FailingWavService({
    this.saveLoopFails = false,
    this.saveWavFails = false,
  });

  final bool saveLoopFails;
  final bool saveWavFails;

  @override
  Future<WavOverview> loadWaveform(String path, {int peakCount = 360}) {
    throw const PolyWavServiceException('load failed');
  }

  @override
  Future<void> saveLoopMetadata(
    String path, {
    required int loopStart,
    required int loopEnd,
  }) async {
    if (saveLoopFails) {
      throw const PolyWavServiceException('save loop failed');
    }
  }

  @override
  Future<void> saveDestructiveWav(
    String sourcePath,
    String targetPath,
    WavRenderOptions options, {
    bool overwriteConfirmed = false,
  }) async {
    if (saveWavFails) {
      throw const PolyWavServiceException('save wav failed');
    }
  }
}

WavOverview _overviewWithFrameCount(int frameCount) {
  return WavOverview(
    sampleRate: 44100,
    frameCount: frameCount,
    peaks: List<WavPeak>.filled(4, const WavPeak(min: -0.5, max: 0.5)),
    zeroCrossings: [0, frameCount - 1],
  );
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

class _ExposedPolyMultisampleBuilderCubit extends PolyMultisampleBuilderCubit {
  _ExposedPolyMultisampleBuilderCubit({
    super.applyService,
    super.hardwareService,
    super.wavService,
    super.previewService,
    super.uploadService,
  });

  void setTestState(PolyMultisampleBuilderState state) {
    emit(state);
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
