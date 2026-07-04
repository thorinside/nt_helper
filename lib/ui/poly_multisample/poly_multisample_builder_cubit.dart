import 'dart:async';
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:path/path.dart' as p;

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
import 'package:nt_helper/poly_multisample/poly_wav_service.dart';
import 'package:nt_helper/poly_multisample/wav_metadata.dart';

enum PolySampleSourceMode { none, local, hardware, importDraft, customDraft }

enum PolyMultisampleLoadStatus { idle, loading, largeFolder, ready, failure }

enum PolyMultisampleActiveOperation {
  none,
  scanning,
  loadingHardware,
  stagingImport,
  applying,
  waveform,
  preview,
  saving,
}

enum PolyRegionSelectionMode { replace, toggle, additive, range }

enum PolyWaveformMode { hidden, loop, destructive }

class PolyMultisampleBuilderState {
  const PolyMultisampleBuilderState({
    this.sourceMode = PolySampleSourceMode.none,
    this.status = PolyMultisampleLoadStatus.idle,
    this.activeOperation = PolyMultisampleActiveOperation.none,
    this.progressText,
    this.currentInstrument,
    this.baselineRegions = const [],
    this.editedRegions = const [],
    this.selectedPaths = const {},
    this.focusedPath,
    this.mapRevision = 0,
    this.hardwareFolders = const [],
    this.decentAnalysis,
    this.warnings = const [],
    this.error,
    this.effect,
    this.effectId = 0,
    this.waveformMode = PolyWaveformMode.hidden,
    this.waveformSummaries = const {},
    this.loopDrafts = const {},
    this.wavEditDrafts = const {},
    this.previewState = const PolyAudioPreviewState(),
    this.previewGainDb = 0,
    this.autoPreview = false,
    this.lastLocalFolder,
    this.lastSourceFolder,
    this.lastImportOutputFolder,
    this.lastCustomOutputFolder,
    this.lastWavExportFolder,
  });

  final PolySampleSourceMode sourceMode;
  final PolyMultisampleLoadStatus status;
  final PolyMultisampleActiveOperation activeOperation;
  final String? progressText;
  final PolySampleInstrument? currentInstrument;
  final List<PolySampleRegion> baselineRegions;
  final List<PolySampleRegion> editedRegions;
  final Set<String> selectedPaths;
  final String? focusedPath;
  final int mapRevision;
  final List<String> hardwareFolders;
  final DecentSamplerImportAnalysis? decentAnalysis;
  final List<String> warnings;
  final String? error;
  final String? effect;
  final int effectId;
  final PolyWaveformMode waveformMode;
  final Map<String, WavOverview> waveformSummaries;
  final Map<String, PolyWaveformDraft> loopDrafts;
  final Map<String, PolyWaveformDraft> wavEditDrafts;
  final PolyAudioPreviewState previewState;
  final double previewGainDb;
  final bool autoPreview;
  final String? lastLocalFolder;
  final String? lastSourceFolder;
  final String? lastImportOutputFolder;
  final String? lastCustomOutputFolder;
  final String? lastWavExportFolder;

  bool get isDirty =>
      _fingerprintRegions(baselineRegions) !=
      _fingerprintRegions(editedRegions);

  PolyMultisampleBuilderState copyWith({
    PolySampleSourceMode? sourceMode,
    PolyMultisampleLoadStatus? status,
    PolyMultisampleActiveOperation? activeOperation,
    String? progressText,
    bool clearProgressText = false,
    PolySampleInstrument? currentInstrument,
    bool clearCurrentInstrument = false,
    List<PolySampleRegion>? baselineRegions,
    List<PolySampleRegion>? editedRegions,
    Set<String>? selectedPaths,
    String? focusedPath,
    bool clearFocusedPath = false,
    int? mapRevision,
    List<String>? hardwareFolders,
    DecentSamplerImportAnalysis? decentAnalysis,
    List<String>? warnings,
    String? error,
    bool clearError = false,
    String? effect,
    bool clearEffect = false,
    int? effectId,
    PolyWaveformMode? waveformMode,
    Map<String, WavOverview>? waveformSummaries,
    Map<String, PolyWaveformDraft>? loopDrafts,
    Map<String, PolyWaveformDraft>? wavEditDrafts,
    PolyAudioPreviewState? previewState,
    double? previewGainDb,
    bool? autoPreview,
    String? lastLocalFolder,
    String? lastSourceFolder,
    String? lastImportOutputFolder,
    String? lastCustomOutputFolder,
    String? lastWavExportFolder,
  }) {
    return PolyMultisampleBuilderState(
      sourceMode: sourceMode ?? this.sourceMode,
      status: status ?? this.status,
      activeOperation: activeOperation ?? this.activeOperation,
      progressText: clearProgressText
          ? null
          : progressText ?? this.progressText,
      currentInstrument: clearCurrentInstrument
          ? null
          : currentInstrument ?? this.currentInstrument,
      baselineRegions: baselineRegions ?? this.baselineRegions,
      editedRegions: editedRegions ?? this.editedRegions,
      selectedPaths: selectedPaths ?? this.selectedPaths,
      focusedPath: clearFocusedPath ? null : focusedPath ?? this.focusedPath,
      mapRevision: mapRevision ?? this.mapRevision,
      hardwareFolders: hardwareFolders ?? this.hardwareFolders,
      decentAnalysis: decentAnalysis ?? this.decentAnalysis,
      warnings: warnings ?? this.warnings,
      error: clearError ? null : error ?? this.error,
      effect: clearEffect ? null : effect ?? this.effect,
      effectId: effectId ?? this.effectId,
      waveformMode: waveformMode ?? this.waveformMode,
      waveformSummaries: waveformSummaries ?? this.waveformSummaries,
      loopDrafts: loopDrafts ?? this.loopDrafts,
      wavEditDrafts: wavEditDrafts ?? this.wavEditDrafts,
      previewState: previewState ?? this.previewState,
      previewGainDb: previewGainDb ?? this.previewGainDb,
      autoPreview: autoPreview ?? this.autoPreview,
      lastLocalFolder: lastLocalFolder ?? this.lastLocalFolder,
      lastSourceFolder: lastSourceFolder ?? this.lastSourceFolder,
      lastImportOutputFolder:
          lastImportOutputFolder ?? this.lastImportOutputFolder,
      lastCustomOutputFolder:
          lastCustomOutputFolder ?? this.lastCustomOutputFolder,
      lastWavExportFolder: lastWavExportFolder ?? this.lastWavExportFolder,
    );
  }
}

class PolyMultisampleBuilderCubit extends Cubit<PolyMultisampleBuilderState> {
  PolyMultisampleBuilderCubit({
    PolySampleFolderService? folderService,
    PolySampleHardwareService? hardwareService,
    PolySampleImportService? importService,
    PolySampleApplyService? applyService,
    PolyWavService? wavService,
    PolyAudioPreviewService? previewService,
    PolySamplePreferencesService? preferencesService,
  }) : _folderService = folderService ?? const PolySampleFolderService(),
       _hardwareService = hardwareService ?? const PolySampleHardwareService(),
       _importService = importService ?? PolySampleImportService(),
       _applyService = applyService ?? const PolySampleApplyService(),
       _wavService = wavService ?? const PolyWavService(),
       _previewService = previewService ?? PolyAudioPreviewService(),
       _preferencesService = preferencesService,
       super(const PolyMultisampleBuilderState()) {
    _previewSub = _previewService.states.listen((previewState) {
      emit(state.copyWith(previewState: previewState));
    });
    unawaited(_loadPreferences());
  }

  final PolySampleFolderService _folderService;
  final PolySampleHardwareService _hardwareService;
  final PolySampleImportService _importService;
  final PolySampleApplyService _applyService;
  final PolyWavService _wavService;
  final PolyAudioPreviewService _previewService;
  PolySamplePreferencesService? _preferencesService;
  late final StreamSubscription<PolyAudioPreviewState> _previewSub;
  final List<String> _ownedTempRoots = [];
  final List<String> _pendingTempRootsToCleanup = [];
  final Map<String, String> _hardwarePreviewCache = {};
  final List<String> _hardwarePreviewRoots = [];
  var _rootConsumingOperationCount = 0;
  var _cleanupAfterOperations = false;
  var _isClosing = false;
  var _contentRevision = 0;
  var _importSequence = 0;

  @override
  void emit(PolyMultisampleBuilderState state) {
    if (_isClosing || isClosed) return;
    super.emit(state);
  }

  Future<PolySamplePreferencesService> _prefs() async {
    final existing = _preferencesService;
    if (existing != null) return existing;
    final created = await PolySamplePreferencesService.create();
    _preferencesService = created;
    return created;
  }

  Future<void> _loadPreferences() async {
    final prefs = await _prefs();
    if (_isClosing || isClosed) return;
    if (prefs.lastLocalFolder == null &&
        prefs.lastSourceFolder == null &&
        prefs.lastImportOutputFolder == null &&
        prefs.lastCustomOutputFolder == null &&
        prefs.lastWavExportFolder == null) {
      return;
    }
    emit(
      state.copyWith(
        lastLocalFolder: prefs.lastLocalFolder,
        lastSourceFolder: prefs.lastSourceFolder,
        lastImportOutputFolder: prefs.lastImportOutputFolder,
        lastCustomOutputFolder: prefs.lastCustomOutputFolder,
        lastWavExportFolder: prefs.lastWavExportFolder,
      ),
    );
  }

  Future<void> loadLocalFolder(String path) async {
    _contentRevision++;
    await _cleanupOwnedTempRootsExceptPath(path);
    unawaited(_prefs().then((service) => service.setLastLocalFolder(path)));
    emit(
      state.copyWith(
        sourceMode: PolySampleSourceMode.local,
        status: PolyMultisampleLoadStatus.loading,
        activeOperation: PolyMultisampleActiveOperation.scanning,
        progressText: 'Scanning sample folder...',
        lastLocalFolder: path,
        clearError: true,
      ),
    );
    try {
      final result = await _folderService.scanLocalFolder(
        path,
        onProgress: (progress) {
          emit(
            state.copyWith(
              progressText:
                  'Scanning sample folder... ${progress.scannedItemCount} items checked, ${progress.audioFileCount} audio files found',
            ),
          );
        },
      );
      if (result.isLargeFolder || result.instrument == null) {
        emit(
          state.copyWith(
            status: PolyMultisampleLoadStatus.largeFolder,
            activeOperation: PolyMultisampleActiveOperation.none,
            warnings: [result.summary],
            clearCurrentInstrument: true,
          ),
        );
        return;
      }
      _setInstrument(
        result.instrument!,
        sourceMode: PolySampleSourceMode.local,
        warnings: const [],
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: PolyMultisampleLoadStatus.failure,
          activeOperation: PolyMultisampleActiveOperation.none,
          error: error.toString(),
        ),
      );
    }
  }

  Future<void> loadHardwareFolderList(IDistingMidiManager manager) async {
    _contentRevision++;
    await _cleanupOwnedTempRoots();
    emit(
      state.copyWith(
        sourceMode: PolySampleSourceMode.hardware,
        status: PolyMultisampleLoadStatus.loading,
        activeOperation: PolyMultisampleActiveOperation.loadingHardware,
        progressText: 'Reading /samples...',
        clearCurrentInstrument: true,
        baselineRegions: const [],
        editedRegions: const [],
        selectedPaths: const {},
        clearFocusedPath: true,
        warnings: const [],
        clearError: true,
      ),
    );
    try {
      final folders = await _hardwareService.listSampleFolders(manager);
      emit(
        state.copyWith(
          status: PolyMultisampleLoadStatus.ready,
          activeOperation: PolyMultisampleActiveOperation.none,
          hardwareFolders: folders,
          clearProgressText: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: PolyMultisampleLoadStatus.failure,
          activeOperation: PolyMultisampleActiveOperation.none,
          error: error.toString(),
        ),
      );
    }
  }

  Future<void> loadHardwareFolder(
    IDistingMidiManager manager,
    String path,
  ) async {
    emit(
      state.copyWith(
        sourceMode: PolySampleSourceMode.hardware,
        status: PolyMultisampleLoadStatus.loading,
        activeOperation: PolyMultisampleActiveOperation.loadingHardware,
        progressText: 'Reading $path...',
        clearError: true,
      ),
    );
    try {
      final instrument = await _hardwareService.readSampleFolder(manager, path);
      _setInstrument(instrument, sourceMode: PolySampleSourceMode.hardware);
    } catch (error) {
      emit(
        state.copyWith(
          status: PolyMultisampleLoadStatus.failure,
          activeOperation: PolyMultisampleActiveOperation.none,
          error: error.toString(),
        ),
      );
    }
  }

  void startEmptyDraft() {
    _setInstrument(
      const PolySampleInstrument(
        name: 'Untitled Samples',
        sourcePath: '',
        regions: [],
      ),
      sourceMode: PolySampleSourceMode.customDraft,
    );
  }

  Future<void> stageLooseFiles(
    List<String> paths,
    PolyLooseWavMappingOptions mappingOptions,
  ) async {
    await _stageImport(
      () => _importService.stageLooseFiles(paths, mappingOptions),
    );
  }

  Future<void> stageLooseFolder(
    String path,
    PolyLooseWavMappingOptions mappingOptions,
  ) async {
    await _stageImport(
      () => _importService.stageLooseFolder(path, mappingOptions),
    );
  }

  Future<DecentSamplerImportAnalysis?> analyzeDecentSource(String path) async {
    emit(
      state.copyWith(
        activeOperation: PolyMultisampleActiveOperation.stagingImport,
        progressText: 'Analyzing Decent source...',
        lastSourceFolder: path,
        clearError: true,
      ),
    );
    try {
      final analysis = await _importService.analyzeDecentSource(path);
      emit(
        state.copyWith(
          activeOperation: PolyMultisampleActiveOperation.none,
          decentAnalysis: analysis,
          clearProgressText: true,
        ),
      );
      return analysis;
    } catch (error) {
      emit(
        state.copyWith(
          activeOperation: PolyMultisampleActiveOperation.none,
          error: error.toString(),
        ),
      );
      return null;
    }
  }

  Future<void> stageDecentSource(
    String path,
    DecentSamplerConvertOptions options,
  ) async {
    await _stageImport(
      () => _importService.stageDecentSource(path, options: options),
    );
  }

  void selectRegion(String path, PolyRegionSelectionMode mode) {
    final selected = Set<String>.from(state.selectedPaths);
    switch (mode) {
      case PolyRegionSelectionMode.replace:
        selected
          ..clear()
          ..add(path);
      case PolyRegionSelectionMode.toggle:
        if (!selected.add(path)) selected.remove(path);
      case PolyRegionSelectionMode.additive:
        selected.add(path);
      case PolyRegionSelectionMode.range:
        selected
          ..clear()
          ..addAll(_rangeSelection(path));
    }
    emit(state.copyWith(selectedPaths: selected, focusedPath: path));
  }

  void updateRoot(String path, int midi) {
    _updateRegion(path, (region) {
      return region.copyWith(
        rootMidi: midi,
        rootName: PolyMultisampleParser.midiToNoteName(midi),
      );
    });
  }

  void updateRangeLow(String path, int midi) {
    _updateRegion(path, (region) => region.copyWith(rangeLow: midi));
  }

  void updateRangeHigh(String path, int midi) {
    _updateRegion(path, (region) => region.copyWith(rangeHigh: midi));
  }

  void updateVelocity(String path, int layer) {
    _updateRegion(path, (region) => region.copyWith(velocityLayer: layer));
  }

  void updateRoundRobin(String path, int lane) {
    _updateRegion(path, (region) => region.copyWith(roundRobin: lane));
  }

  void removeSelectedRegions() {
    final selected = state.selectedPaths;
    final nextRegions = state.editedRegions
        .where((region) => !selected.contains(region.path))
        .toList();
    _replaceEditedRegions(nextRegions, selectedPaths: const {});
  }

  void clearDraft() {
    final instrument = state.currentInstrument;
    if (instrument == null) return;
    _setInstrument(
      instrument.copyWith(regions: const []),
      sourceMode: state.sourceMode,
      baselineRegions: const [],
    );
  }

  void discardChanges() {
    final instrument = state.currentInstrument;
    if (instrument == null) return;
    _replaceEditedRegions(
      List<PolySampleRegion>.from(state.baselineRegions),
      selectedPaths: const {},
    );
  }

  Future<void> returnToSources() async {
    _contentRevision++;
    await _previewService.stop();
    await _cleanupHardwarePreviewRoots();
    final keepHardwareFolders =
        state.sourceMode == PolySampleSourceMode.hardware &&
        state.hardwareFolders.isNotEmpty;
    emit(
      state.copyWith(
        sourceMode: keepHardwareFolders
            ? PolySampleSourceMode.hardware
            : PolySampleSourceMode.none,
        status: keepHardwareFolders
            ? PolyMultisampleLoadStatus.ready
            : PolyMultisampleLoadStatus.idle,
        activeOperation: PolyMultisampleActiveOperation.none,
        clearProgressText: true,
        clearCurrentInstrument: true,
        baselineRegions: const [],
        editedRegions: const [],
        selectedPaths: const {},
        clearFocusedPath: true,
        hardwareFolders: keepHardwareFolders ? state.hardwareFolders : const [],
        warnings: const [],
        waveformSummaries: const {},
        loopDrafts: const {},
        wavEditDrafts: const {},
        clearError: true,
      ),
    );
  }

  Future<void> rememberSourceFolder(String path) async {
    final prefs = await _prefs();
    await prefs.setLastSourceFolder(path);
    emit(state.copyWith(lastSourceFolder: path));
  }

  Future<void> rememberImportOutputFolder(String path) async {
    final prefs = await _prefs();
    await prefs.setLastImportOutputFolder(path);
    emit(state.copyWith(lastImportOutputFolder: path));
  }

  Future<void> saveCustomDraft(String outputFolder) async {
    final operationRevision = _contentRevision;
    final instrumentName = state.currentInstrument?.name ?? 'Untitled';
    final editedRegions = List<PolySampleRegion>.from(state.editedRegions);
    emit(
      state.copyWith(
        activeOperation: PolyMultisampleActiveOperation.saving,
        lastCustomOutputFolder: outputFolder,
        clearError: true,
      ),
    );
    unawaited(
      _prefs().then(
        (service) => service.setLastCustomOutputFolder(outputFolder),
      ),
    );
    _beginRootConsumingOperation();
    var didSave = false;
    final rootsUsedBySave = List<String>.from(_ownedTempRoots);
    try {
      if (await _isWithinAnyRoot(outputFolder, rootsUsedBySave)) {
        throw const PolySampleApplyException(
          'Choose an output folder outside the staged import.',
        );
      }
      final existingPaths = await _existingLocalAudioPaths(outputFolder);
      if (operationRevision != _contentRevision) {
        emit(
          state.copyWith(activeOperation: PolyMultisampleActiveOperation.none),
        );
        return;
      }
      final plan = _applyService.buildPlan(
        baselineRegions: const [],
        editedRegions: editedRegions,
        targetFolder: outputFolder,
        existingPaths: existingPaths,
      );
      await _applyService.applyLocalPlan(plan);
      await _writeBuildReport(
        outputFolder,
        instrumentName: instrumentName,
        regions: editedRegions,
      );
      final scan = await _folderService.scanLocalFolder(
        outputFolder,
        includeLargeFolders: true,
      );
      if (operationRevision == _contentRevision) {
        _setInstrument(
          scan.instrument ??
              PolySampleInstrument(
                name: PolySampleInstrument.nameFromDirectory(outputFolder),
                sourcePath: outputFolder,
                regions: const [],
              ),
          sourceMode: PolySampleSourceMode.customDraft,
          effect: 'Saved custom sample draft.',
        );
      }
      didSave = true;
    } catch (error) {
      emit(
        state.copyWith(
          activeOperation: PolyMultisampleActiveOperation.none,
          error: error.toString(),
        ),
      );
    } finally {
      if (didSave) {
        await _cleanupTempRoots(rootsUsedBySave);
        _ownedTempRoots.removeWhere(rootsUsedBySave.contains);
        _pendingTempRootsToCleanup.removeWhere(rootsUsedBySave.contains);
      }
      await _endRootConsumingOperation();
    }
  }

  Future<void> applyChanges([IDistingMidiManager? manager]) async {
    final instrument = state.currentInstrument;
    if (instrument == null) return;
    final operationRevision = _contentRevision;
    final sourceMode = state.sourceMode;
    final baselineRegions = List<PolySampleRegion>.from(state.baselineRegions);
    final editedRegions = List<PolySampleRegion>.from(state.editedRegions);
    emit(
      state.copyWith(
        activeOperation: PolyMultisampleActiveOperation.applying,
        clearError: true,
      ),
    );
    _beginRootConsumingOperation();
    try {
      if (sourceMode == PolySampleSourceMode.hardware) {
        if (manager == null) {
          throw const PolySampleHardwareException(
            'A MIDI manager is required for hardware apply.',
          );
        }
        final plan = _hardwareService.buildHardwarePlan(
          baselineRegions: baselineRegions,
          editedRegions: editedRegions,
          targetFolder: instrument.sourcePath,
        );
        await _hardwareService.applyPlan(manager, plan);
        final refreshed = await _hardwareService.readSampleFolder(
          manager,
          instrument.sourcePath,
        );
        if (operationRevision == _contentRevision) {
          _setInstrument(
            refreshed,
            sourceMode: PolySampleSourceMode.hardware,
            effect: 'Applied hardware sample changes.',
          );
        }
        return;
      }

      final existingPaths = await _existingLocalAudioPaths(
        instrument.sourcePath,
      );
      if (operationRevision != _contentRevision) {
        emit(
          state.copyWith(activeOperation: PolyMultisampleActiveOperation.none),
        );
        return;
      }
      final plan = _applyService.buildPlan(
        baselineRegions: baselineRegions,
        editedRegions: editedRegions,
        targetFolder: instrument.sourcePath,
        existingPaths: existingPaths,
      );
      await _applyService.applyLocalPlan(plan);
      final refreshed = await _folderService.scanLocalFolder(
        instrument.sourcePath,
        includeLargeFolders: true,
      );
      if (operationRevision == _contentRevision) {
        _setInstrument(
          refreshed.instrument ??
              instrument.copyWith(regions: List.from(editedRegions)),
          sourceMode: sourceMode,
          effect: 'Applied sample changes.',
        );
      }
    } catch (error) {
      emit(
        state.copyWith(
          activeOperation: PolyMultisampleActiveOperation.none,
          error: error.toString(),
        ),
      );
    } finally {
      await _endRootConsumingOperation();
    }
  }

  Future<void> loadWaveform(String path) async {
    emit(
      state.copyWith(
        activeOperation: PolyMultisampleActiveOperation.waveform,
        clearError: true,
      ),
    );
    try {
      final overview = await _wavService.loadWaveform(path);
      final summaries = Map<String, WavOverview>.from(state.waveformSummaries)
        ..[path] = overview;
      emit(
        state.copyWith(
          activeOperation: PolyMultisampleActiveOperation.none,
          waveformSummaries: summaries,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          activeOperation: PolyMultisampleActiveOperation.none,
          error: error.toString(),
        ),
      );
    }
  }

  void setWaveformMode(PolyWaveformMode mode) {
    emit(state.copyWith(waveformMode: mode));
  }

  void updateLoopDraft(String path, PolyWaveformDraft draft) {
    emit(
      state.copyWith(
        loopDrafts: Map<String, PolyWaveformDraft>.from(state.loopDrafts)
          ..[path] = draft,
      ),
    );
  }

  Future<void> saveLoopMetadata(String path) async {
    final draft = state.loopDrafts[path];
    if (draft == null || draft.loopStart == null || draft.loopEnd == null) {
      await _wavService.removeLoopMetadata(path);
    } else {
      await _wavService.saveLoopMetadata(
        path,
        loopStart: draft.loopStart!,
        loopEnd: draft.loopEnd!,
      );
    }
    await loadWaveform(path);
  }

  void updateWavEditDraft(String path, PolyWaveformDraft draft) {
    emit(
      state.copyWith(
        wavEditDrafts: Map<String, PolyWaveformDraft>.from(state.wavEditDrafts)
          ..[path] = draft,
      ),
    );
  }

  Future<void> saveDestructiveWav(
    String path,
    String targetPath,
    bool overwriteConfirmed,
  ) async {
    final draft = state.wavEditDrafts[path] ?? const PolyWaveformDraft();
    final overview =
        state.waveformSummaries[path] ?? await _wavService.loadWaveform(path);
    await _wavService.saveDestructiveWav(
      path,
      targetPath,
      WavRenderOptions(
        trimStartFrame: draft.trimStart ?? 0,
        trimEndFrame: draft.trimEnd ?? overview.frameCount - 1,
        fadeInFrames: draft.fadeInFrames,
        fadeOutFrames: draft.fadeOutFrames,
        fadeInCurve: draft.fadeInCurve,
        fadeOutCurve: draft.fadeOutCurve,
        fadeInStrength: draft.fadeInStrength,
        fadeOutStrength: draft.fadeOutStrength,
        gainDb: draft.gainDb,
        normalizePeakDb: draft.normalizePeakDb,
      ),
      overwriteConfirmed: overwriteConfirmed,
    );
    final wavExportFolder = p.dirname(targetPath);
    unawaited(
      _prefs().then(
        (service) => service.setLastWavExportFolder(wavExportFolder),
      ),
    );
    emit(
      state.copyWith(
        lastWavExportFolder: wavExportFolder,
        effect: 'Saved edited WAV.',
        effectId: state.effectId + 1,
        clearError: true,
      ),
    );
  }

  Future<void> playOrStopPreview(
    String path, {
    IDistingMidiManager? manager,
  }) async {
    try {
      if (_isHardwarePreviewPath(path)) {
        if (manager == null) {
          throw const PolySampleHardwareException(
            'Connect to Disting NT to preview hardware samples.',
          );
        }
        final localPath = await _cachedHardwarePreviewPath(manager, path);
        await _previewService.playOrStopPreview(
          localPath,
          displayPath: path,
          gainDb: state.previewGainDb,
        );
        return;
      }
      await _previewService.playOrStopPreview(
        path,
        gainDb: state.previewGainDb,
      );
    } catch (error) {
      emit(state.copyWith(error: error.toString()));
    }
  }

  void setPreviewGain(double db) {
    emit(state.copyWith(previewGainDb: db));
  }

  void setAutoPreview(bool enabled) {
    emit(state.copyWith(autoPreview: enabled));
  }

  @override
  Future<void> close() async {
    _isClosing = true;
    await _previewSub.cancel();
    await _previewService.dispose();
    await _cleanupHardwarePreviewRoots();
    if (_rootConsumingOperationCount > 0) {
      _cleanupAfterOperations = true;
    } else {
      await _cleanupOwnedTempRoots();
    }
    return super.close();
  }

  Future<void> _stageImport(Future<PolyStagedImport> Function() stage) async {
    _contentRevision++;
    final sequence = ++_importSequence;
    emit(
      state.copyWith(
        sourceMode: PolySampleSourceMode.importDraft,
        status: PolyMultisampleLoadStatus.loading,
        activeOperation: PolyMultisampleActiveOperation.stagingImport,
        progressText: 'Staging import...',
        clearError: true,
      ),
    );
    try {
      final staged = await stage();
      if (_isClosing || isClosed) {
        await _importService.cleanupOwnedTempRoots(staged.tempRoots);
        return;
      }
      if (sequence != _importSequence) {
        await _importService.cleanupOwnedTempRoots(staged.tempRoots);
        return;
      }
      await _replaceOwnedTempRoots(staged.tempRoots);
      _setInstrument(
        PolySampleInstrument(
          name: staged.name,
          sourcePath: staged.tempRoots.isNotEmpty
              ? staged.tempRoots.first
              : staged.sourceLabel,
          regions: staged.regions,
        ),
        sourceMode: PolySampleSourceMode.importDraft,
        warnings: staged.warnings,
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: PolyMultisampleLoadStatus.failure,
          activeOperation: PolyMultisampleActiveOperation.none,
          error: error.toString(),
        ),
      );
    }
  }

  Future<void> _replaceOwnedTempRoots(List<String> roots) async {
    if (_rootConsumingOperationCount > 0) {
      _pendingTempRootsToCleanup.addAll(_ownedTempRoots);
      _ownedTempRoots.clear();
    } else {
      await _cleanupOwnedTempRoots();
    }
    _ownedTempRoots.addAll(roots);
  }

  Future<void> _cleanupOwnedTempRoots() async {
    final roots = [..._pendingTempRootsToCleanup, ..._ownedTempRoots];
    if (roots.isEmpty) return;
    _pendingTempRootsToCleanup.clear();
    _ownedTempRoots.clear();
    await _cleanupTempRoots(roots);
  }

  Future<void> _cleanupOwnedTempRootsExceptPath(String path) async {
    final keptRoots = <String>[];
    final cleanupRoots = <String>[];
    for (final root in _ownedTempRoots) {
      if (await _isWithinAnyRoot(path, [root])) {
        keptRoots.add(root);
      } else {
        cleanupRoots.add(root);
      }
    }
    cleanupRoots.addAll(_pendingTempRootsToCleanup);
    _pendingTempRootsToCleanup.clear();
    _ownedTempRoots
      ..clear()
      ..addAll(keptRoots);
    if (_rootConsumingOperationCount > 0) {
      _pendingTempRootsToCleanup.addAll(cleanupRoots);
      return;
    }
    await _cleanupTempRoots(cleanupRoots);
  }

  Future<void> _cleanupTempRoots(List<String> roots) async {
    if (roots.isEmpty) return;
    await _importService.cleanupOwnedTempRoots(roots);
  }

  bool _isHardwarePreviewPath(String path) {
    return state.sourceMode == PolySampleSourceMode.hardware &&
        path.startsWith('/');
  }

  Future<String> _cachedHardwarePreviewPath(
    IDistingMidiManager manager,
    String path,
  ) async {
    final existing = _hardwarePreviewCache[path];
    if (existing != null && await File(existing).exists()) {
      return existing;
    }
    final bytes = await _hardwareService.downloadSampleBytes(manager, path);
    if (bytes == null) {
      throw PolySampleHardwareException('Could not download $path.');
    }
    final root = await Directory.systemTemp.createTemp(
      'nt_helper_poly_preview_',
    );
    _hardwarePreviewRoots.add(root.path);
    final safeName = p
        .basename(path)
        .replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final file = File(p.join(root.path, safeName));
    await file.writeAsBytes(bytes, flush: true);
    _hardwarePreviewCache[path] = file.path;
    return file.path;
  }

  Future<void> _cleanupHardwarePreviewRoots() async {
    final roots = List<String>.from(_hardwarePreviewRoots);
    _hardwarePreviewRoots.clear();
    _hardwarePreviewCache.clear();
    for (final root in roots) {
      try {
        final dir = Directory(root);
        if (await dir.exists()) {
          await dir.delete(recursive: true);
        }
      } on FileSystemException {
        // Best-effort cleanup only.
      }
    }
  }

  Future<bool> _isWithinAnyRoot(String path, List<String> roots) async {
    final normalizedPath = p.normalize(path);
    for (final root in roots) {
      final normalizedRoot = p.normalize(root);
      if (normalizedPath == normalizedRoot ||
          p.isWithin(normalizedRoot, normalizedPath)) {
        return true;
      }
      try {
        final resolvedPath = await _resolvePathThroughExistingAncestor(path);
        final resolvedRoot = await Directory(root).resolveSymbolicLinks();
        if (resolvedPath == resolvedRoot ||
            p.isWithin(resolvedRoot, resolvedPath)) {
          return true;
        }
      } on FileSystemException {
        // Fall back to the lexical check above when either path is missing.
      }
    }
    return false;
  }

  Future<String> _resolvePathThroughExistingAncestor(String path) async {
    final pathsToAppend = <String>[];
    var current = Directory(path);
    while (!await current.exists()) {
      pathsToAppend.add(p.basename(current.path));
      final parent = current.parent;
      if (parent.path == current.path) {
        throw FileSystemException('No existing ancestor', path);
      }
      current = parent;
    }
    var resolved = await current.resolveSymbolicLinks();
    for (final segment in pathsToAppend.reversed) {
      resolved = p.join(resolved, segment);
    }
    return p.normalize(resolved);
  }

  void _beginRootConsumingOperation() {
    _rootConsumingOperationCount++;
  }

  Future<void> _endRootConsumingOperation() async {
    if (_rootConsumingOperationCount > 0) {
      _rootConsumingOperationCount--;
    }
    if ((_isClosing || isClosed) &&
        _rootConsumingOperationCount == 0 &&
        _cleanupAfterOperations) {
      _cleanupAfterOperations = false;
      await _cleanupOwnedTempRoots();
      return;
    }
    if (_rootConsumingOperationCount == 0 &&
        _pendingTempRootsToCleanup.isNotEmpty) {
      final roots = List<String>.from(_pendingTempRootsToCleanup);
      _pendingTempRootsToCleanup.clear();
      await _cleanupTempRoots(roots);
    }
  }

  void _setInstrument(
    PolySampleInstrument instrument, {
    required PolySampleSourceMode sourceMode,
    List<PolySampleRegion>? baselineRegions,
    List<String> warnings = const [],
    String? effect,
  }) {
    _contentRevision++;
    final regions = List<PolySampleRegion>.from(instrument.regions);
    emit(
      state.copyWith(
        sourceMode: sourceMode,
        status: PolyMultisampleLoadStatus.ready,
        activeOperation: PolyMultisampleActiveOperation.none,
        currentInstrument: instrument.copyWith(regions: regions),
        baselineRegions:
            baselineRegions ?? List<PolySampleRegion>.from(regions),
        editedRegions: List<PolySampleRegion>.from(regions),
        selectedPaths: regions.isEmpty
            ? const <String>{}
            : {regions.first.path},
        focusedPath: regions.isEmpty ? null : regions.first.path,
        clearFocusedPath: regions.isEmpty,
        mapRevision: state.mapRevision + 1,
        warnings: warnings,
        effect: effect,
        effectId: effect == null ? state.effectId : state.effectId + 1,
        clearProgressText: true,
        clearError: true,
      ),
    );
  }

  void _updateRegion(
    String path,
    PolySampleRegion Function(PolySampleRegion region) update,
  ) {
    final next = [
      for (final region in state.editedRegions)
        region.path == path ? update(region) : region,
    ];
    _replaceEditedRegions(next);
  }

  void _replaceEditedRegions(
    List<PolySampleRegion> regions, {
    Set<String>? selectedPaths,
  }) {
    _contentRevision++;
    PolyMultisampleParser.sortRegions(regions);
    final instrument = state.currentInstrument;
    emit(
      state.copyWith(
        currentInstrument: instrument?.copyWith(regions: regions),
        editedRegions: List<PolySampleRegion>.from(regions),
        selectedPaths: selectedPaths ?? state.selectedPaths,
        mapRevision: state.mapRevision + 1,
      ),
    );
  }

  Iterable<String> _rangeSelection(String path) {
    final focused = state.focusedPath;
    if (focused == null) return [path];
    final start = state.editedRegions.indexWhere(
      (region) => region.path == focused,
    );
    final end = state.editedRegions.indexWhere((region) => region.path == path);
    if (start < 0 || end < 0) return [path];
    final low = start < end ? start : end;
    final high = start < end ? end : start;
    return state.editedRegions
        .sublist(low, high + 1)
        .map((region) => region.path);
  }

  Future<Set<String>> _existingLocalAudioPaths(String folder) async {
    final dir = Directory(folder);
    if (!await dir.exists()) return const {};
    final paths = <String>{};
    await for (final entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is! File) continue;
      if (!PolyMultisampleParser.isSupportedAudioName(
        p.basename(entity.path),
      )) {
        continue;
      }
      paths.add(p.normalize(entity.path));
    }
    return paths;
  }

  Future<void> _writeBuildReport(
    String outputFolder, {
    required String instrumentName,
    required List<PolySampleRegion> regions,
  }) async {
    final buffer = StringBuffer()
      ..writeln('Poly Multisample Build Report')
      ..writeln('Instrument: $instrumentName')
      ..writeln('Samples: ${regions.length}')
      ..writeln();
    for (final region in regions) {
      buffer.writeln(
        '${region.displayName} root=${region.rootName ?? 'unmapped'} '
        'velocity=${region.velocityLayer ?? '-'} rr=${region.roundRobin ?? '-'}',
      );
    }
    await Directory(outputFolder).create(recursive: true);
    await File(
      p.join(outputFolder, 'poly_multisample_build_report.txt'),
    ).writeAsString(buffer.toString(), flush: true);
  }
}

String _fingerprintRegions(List<PolySampleRegion> regions) {
  final parts = [
    for (final region in regions)
      [
        region.path,
        region.fileName,
        region.displayName,
        region.rootMidi,
        region.rootName,
        region.rangeLow,
        region.rangeHigh,
        region.switchPoint,
        region.velocityLayer,
        region.roundRobin,
        region.loopStart,
        region.loopEnd,
      ].join('|'),
  ]..sort();
  return parts.join('\n');
}
