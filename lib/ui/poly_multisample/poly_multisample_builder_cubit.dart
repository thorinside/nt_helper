import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

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
import 'package:nt_helper/poly_multisample/poly_sample_upload_service.dart';
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
  uploading,
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
    this.waveformLoadingPaths = const {},
    this.waveformFailedPaths = const {},
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
    this.lastMountedUploadFolder,
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
  final Set<String> waveformLoadingPaths;
  final Set<String> waveformFailedPaths;
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
  final String? lastMountedUploadFolder;

  bool get hasRegionChanges =>
      _fingerprintRegions(baselineRegions) !=
      _fingerprintRegions(editedRegions);

  bool get hasWaveformDrafts =>
      loopDrafts.isNotEmpty || wavEditDrafts.isNotEmpty;

  bool get isDirty => hasRegionChanges || hasWaveformDrafts;

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
    Set<String>? waveformLoadingPaths,
    Set<String>? waveformFailedPaths,
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
    String? lastMountedUploadFolder,
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
      waveformLoadingPaths: waveformLoadingPaths ?? this.waveformLoadingPaths,
      waveformFailedPaths: waveformFailedPaths ?? this.waveformFailedPaths,
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
      lastMountedUploadFolder:
          lastMountedUploadFolder ?? this.lastMountedUploadFolder,
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
    PolySampleUploadService? uploadService,
    FutureOr<Uint8List> Function(Uint8List bytes, double pitchRatio)?
    notePreviewRenderer,
  }) : _folderService = folderService ?? const PolySampleFolderService(),
       _hardwareService = hardwareService ?? const PolySampleHardwareService(),
       _importService = importService ?? PolySampleImportService(),
       _applyService = applyService ?? const PolySampleApplyService(),
       _wavService = wavService ?? const PolyWavService(),
       _previewService = previewService ?? PolyAudioPreviewService(),
       _preferencesService = preferencesService,
       _uploadService = uploadService ?? const PolySampleUploadService(),
       _notePreviewRenderer =
           notePreviewRenderer ??
           ((bytes, pitchRatio) => WavAudioRenderer.renderPitchedPreview(
             bytes,
             pitchRatio: pitchRatio,
           )),
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
  final PolySampleUploadService _uploadService;
  final FutureOr<Uint8List> Function(Uint8List bytes, double pitchRatio)
  _notePreviewRenderer;
  late final StreamSubscription<PolyAudioPreviewState> _previewSub;
  final List<String> _ownedTempRoots = [];
  final List<String> _pendingTempRootsToCleanup = [];
  final Map<String, String> _hardwarePreviewCache = {};
  final List<String> _hardwarePreviewRoots = [];
  final Map<String, int> _waveformLoadTokens = {};
  final Map<String, String> _notePreviewCache = {};
  final Map<String, Future<String>> _notePreviewRenderInFlight = {};
  final List<String> _notePreviewRoots = [];
  final Map<String, int> _notePreviewRoundRobinCursor = {};
  var _notePreviewRequest = 0;
  var _notePreviewGeneration = 0;
  var _rootConsumingOperationCount = 0;
  var _cleanupAfterOperations = false;
  var _isClosing = false;
  var _contentRevision = 0;
  var _autoPreviewRequest = 0;
  var _loopEditPreviewRequest = 0;
  Timer? _loopEditPreviewDebounce;
  var _hardwarePreviewInFlight = false;
  var _importSequence = 0;
  var _waveformLoadSequence = 0;

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
        prefs.lastWavExportFolder == null &&
        prefs.lastMountedUploadFolder == null) {
      return;
    }
    emit(
      state.copyWith(
        lastLocalFolder: prefs.lastLocalFolder,
        lastSourceFolder: prefs.lastSourceFolder,
        lastImportOutputFolder: prefs.lastImportOutputFolder,
        lastCustomOutputFolder: prefs.lastCustomOutputFolder,
        lastWavExportFolder: prefs.lastWavExportFolder,
        lastMountedUploadFolder: prefs.lastMountedUploadFolder,
      ),
    );
  }

  Future<void> loadLocalFolder(String path) async {
    final operationRevision = ++_contentRevision;
    await _cleanupOwnedTempRootsExceptPath(path);
    if (operationRevision != _contentRevision) return;
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
          if (operationRevision != _contentRevision) return;
          emit(
            state.copyWith(
              progressText:
                  'Scanning sample folder... ${progress.scannedItemCount} items checked, ${progress.audioFileCount} audio files found',
            ),
          );
        },
      );
      if (operationRevision != _contentRevision) {
        emit(
          state.copyWith(activeOperation: PolyMultisampleActiveOperation.none),
        );
        return;
      }
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
    final operationRevision = ++_contentRevision;
    await _cleanupOwnedTempRoots();
    if (operationRevision != _contentRevision) return;
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
      if (operationRevision != _contentRevision) {
        emit(
          state.copyWith(activeOperation: PolyMultisampleActiveOperation.none),
        );
        return;
      }
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
    final operationRevision = ++_contentRevision;
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
      if (operationRevision != _contentRevision) {
        emit(
          state.copyWith(activeOperation: PolyMultisampleActiveOperation.none),
        );
        return;
      }
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

  Future<void> adoptStagedImport(PolyStagedImport staged) async {
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
  }

  Future<void> addStagedRegions(PolyStagedImport staged) async {
    if (state.currentInstrument == null) return;
    _ownedTempRoots.addAll(staged.tempRoots);
    final existing = state.editedRegions.map((region) => region.path).toSet();
    final next = [
      ...state.editedRegions,
      ...staged.regions.where((region) => !existing.contains(region.path)),
    ];
    _replaceEditedRegions(next);
    if (staged.warnings.isNotEmpty) {
      emit(state.copyWith(warnings: [...state.warnings, ...staged.warnings]));
    }
  }

  void selectRegion(
    String path,
    PolyRegionSelectionMode mode, {
    IDistingMidiManager? manager,
    bool autoPreviewSelection = true,
  }) {
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
    final selectedPath = selected.contains(path) ? path : selected.lastOrNull;
    emit(
      state.copyWith(
        selectedPaths: selected,
        focusedPath: selectedPath,
        clearFocusedPath: selectedPath == null,
      ),
    );
    final autoPreviewRequestId = state.autoPreview
        ? ++_autoPreviewRequest
        : _autoPreviewRequest;
    if (!selected.contains(path)) {
      if (state.previewState.visiblePath == path) {
        unawaited(_previewService.stop());
      }
      return;
    }
    if (state.autoPreview && autoPreviewSelection) {
      if (path.toLowerCase().endsWith('.wav')) {
        if (state.previewState.visiblePath != path) {
          unawaited(
            _playAutoPreview(
              path,
              requestId: autoPreviewRequestId,
              manager: manager,
              restartVisiblePreview: false,
            ),
          );
        }
      } else if (state.previewState.visiblePath != null) {
        unawaited(_previewService.stop());
      }
    }
    if (_isLocalEditableWav(path) &&
        !state.waveformSummaries.containsKey(path)) {
      unawaited(loadWaveform(path));
    }
  }

  void updateRoot(
    String path,
    int midi, {
    IDistingMidiManager? manager,
    bool focusRegion = false,
  }) {
    final clampedMidi = midi.clamp(0, 127).toInt();
    final updated = _updateRegion(
      path,
      (region) {
        return region.copyWith(
          rootMidi: clampedMidi,
          rootName: PolyMultisampleParser.midiToNoteName(clampedMidi),
        );
      },
      selectedPaths: focusRegion ? {path} : null,
      focusedPathOverride: focusRegion ? path : null,
    );
    if (updated) {
      _autoPreviewMappingEdit(path, manager: manager);
    }
  }

  void updateRangeLow(
    String path,
    int midi, {
    IDistingMidiManager? manager,
    bool focusRegion = false,
  }) {
    final clampedMidi = midi.clamp(0, 127).toInt();
    final updated = _updateRegion(
      path,
      (region) => region.copyWith(rangeLow: clampedMidi),
      selectedPaths: focusRegion ? {path} : null,
      focusedPathOverride: focusRegion ? path : null,
    );
    if (updated) {
      _autoPreviewMappingEdit(path, manager: manager);
    }
  }

  void updateRangeHigh(
    String path,
    int midi, {
    IDistingMidiManager? manager,
    bool focusRegion = false,
  }) {
    final clampedMidi = midi.clamp(0, 127).toInt();
    final updated = _updateRegion(
      path,
      (region) => region.copyWith(rangeHigh: clampedMidi),
      selectedPaths: focusRegion ? {path} : null,
      focusedPathOverride: focusRegion ? path : null,
    );
    if (updated) {
      _autoPreviewMappingEdit(path, manager: manager);
    }
  }

  void updateVelocity(
    String path,
    int layer, {
    IDistingMidiManager? manager,
    bool focusRegion = false,
  }) {
    final clampedLayer = math.max(1, layer);
    final updated = _updateRegion(
      path,
      (region) => region.copyWith(velocityLayer: clampedLayer),
      selectedPaths: focusRegion ? {path} : null,
      focusedPathOverride: focusRegion ? path : null,
    );
    if (updated) {
      _autoPreviewMappingEdit(path, manager: manager);
    }
  }

  void updateRoundRobin(
    String path,
    int lane, {
    IDistingMidiManager? manager,
    bool focusRegion = false,
  }) {
    final clampedLane = math.max(1, lane);
    final updated = _updateRegion(
      path,
      (region) => region.copyWith(roundRobin: clampedLane),
      selectedPaths: focusRegion ? {path} : null,
      focusedPathOverride: focusRegion ? path : null,
    );
    if (updated) {
      _autoPreviewMappingEdit(path, manager: manager);
    }
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
    emit(state.copyWith(loopDrafts: const {}, wavEditDrafts: const {}));
  }

  Future<void> returnToSources() async {
    _contentRevision++;
    _notePreviewRequest++;
    _loopEditPreviewRequest++;
    _loopEditPreviewDebounce?.cancel();
    await _previewService.stop();
    await _cleanupHardwarePreviewRoots();
    await _cleanupNotePreviewRoots();
    emit(
      state.copyWith(
        sourceMode: PolySampleSourceMode.none,
        status: PolyMultisampleLoadStatus.idle,
        activeOperation: PolyMultisampleActiveOperation.none,
        clearProgressText: true,
        clearCurrentInstrument: true,
        baselineRegions: const [],
        editedRegions: const [],
        selectedPaths: const {},
        clearFocusedPath: true,
        hardwareFolders: const [],
        warnings: const [],
        waveformSummaries: const {},
        waveformLoadingPaths: const {},
        waveformFailedPaths: const {},
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
    if (state.hasWaveformDrafts) {
      emit(
        state.copyWith(
          activeOperation: PolyMultisampleActiveOperation.none,
          error:
              'Save or discard waveform edits before saving this sample set.',
        ),
      );
      return;
    }
    final operationRevision = _contentRevision;
    final instrumentName = state.currentInstrument?.name ?? 'Untitled';
    final editedRegions = List<PolySampleRegion>.from(state.editedRegions);
    emit(
      state.copyWith(
        activeOperation: PolyMultisampleActiveOperation.saving,
        clearError: true,
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
        final outputParentFolder = p.dirname(outputFolder);
        unawaited(
          _prefs().then(
            (service) => service.setLastCustomOutputFolder(outputParentFolder),
          ),
        );
        _setInstrument(
          scan.instrument ??
              PolySampleInstrument(
                name: PolySampleInstrument.nameFromDirectory(outputFolder),
                sourcePath: outputFolder,
                regions: const [],
              ),
          sourceMode: PolySampleSourceMode.local,
          effect: 'Saved custom sample draft.',
        );
        emit(state.copyWith(lastCustomOutputFolder: outputParentFolder));
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

  String mountedSdDestinationForSelection(String mountedSdFolder) {
    final instrumentName = state.currentInstrument?.name ?? 'Untitled';
    return _mountedSdDestinationFolder(mountedSdFolder, instrumentName);
  }

  String mountedSdSuggestedFolderName() {
    return _safeHardwareFolderName(state.currentInstrument?.name ?? 'Untitled');
  }

  Future<void> uploadViaMountedSd(
    String mountedSdFolder, {
    bool useSelectedFolder = false,
  }) async {
    final instrument = state.currentInstrument;
    if (instrument == null) return;
    if (state.sourceMode == PolySampleSourceMode.hardware) {
      emit(
        state.copyWith(
          activeOperation: PolyMultisampleActiveOperation.none,
          error: 'Open or import a local sample folder before uploading.',
        ),
      );
      return;
    }
    if (state.editedRegions.isEmpty) {
      emit(
        state.copyWith(
          activeOperation: PolyMultisampleActiveOperation.none,
          error: 'There are no samples to upload.',
        ),
      );
      return;
    }
    if (state.hasWaveformDrafts) {
      emit(
        state.copyWith(
          activeOperation: PolyMultisampleActiveOperation.none,
          error:
              'Save or discard waveform edits before uploading this sample set.',
        ),
      );
      return;
    }

    final operationRevision = _contentRevision;
    final editedRegions = List<PolySampleRegion>.from(state.editedRegions);
    final destinationFolder = useSelectedFolder
        ? p.normalize(mountedSdFolder)
        : _mountedSdDestinationFolder(mountedSdFolder, instrument.name);
    emit(
      state.copyWith(
        activeOperation: PolyMultisampleActiveOperation.uploading,
        progressText: 'Uploading sample folder...',
        clearError: true,
      ),
    );
    try {
      await _uploadService.uploadMountedSd(
        regions: editedRegions,
        destinationFolder: destinationFolder,
        onProgress: (message) {
          if (operationRevision != _contentRevision) return;
          emit(state.copyWith(progressText: message));
        },
      );
      final prefs = await _prefs();
      await prefs.setLastMountedUploadFolder(mountedSdFolder);
      if (operationRevision != _contentRevision) return;
      emit(
        state.copyWith(
          activeOperation: PolyMultisampleActiveOperation.none,
          clearProgressText: true,
          lastMountedUploadFolder: mountedSdFolder,
          effect: 'Uploaded sample folder to $destinationFolder.',
          effectId: state.effectId + 1,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          activeOperation: PolyMultisampleActiveOperation.none,
          clearProgressText: true,
          error: error.toString(),
        ),
      );
    }
  }

  Future<void> uploadViaSysEx(IDistingMidiManager manager) async {
    final instrument = state.currentInstrument;
    if (instrument == null) return;
    if (state.sourceMode == PolySampleSourceMode.hardware) {
      emit(
        state.copyWith(
          activeOperation: PolyMultisampleActiveOperation.none,
          error: 'Open or import a local sample folder before uploading.',
        ),
      );
      return;
    }
    if (state.editedRegions.isEmpty) {
      emit(
        state.copyWith(
          activeOperation: PolyMultisampleActiveOperation.none,
          error: 'There are no samples to upload.',
        ),
      );
      return;
    }
    if (state.hasWaveformDrafts) {
      emit(
        state.copyWith(
          activeOperation: PolyMultisampleActiveOperation.none,
          error:
              'Save or discard waveform edits before uploading this sample set.',
        ),
      );
      return;
    }

    final operationRevision = _contentRevision;
    final editedRegions = List<PolySampleRegion>.from(state.editedRegions);
    final hardwareFolder = p.posix.join(
      '/multisamples',
      _safeHardwareFolderName(instrument.name),
    );
    emit(
      state.copyWith(
        activeOperation: PolyMultisampleActiveOperation.uploading,
        progressText: 'Uploading sample folder...',
        clearError: true,
      ),
    );
    try {
      final result = await _uploadService.uploadSysEx(
        regions: editedRegions,
        manager: manager,
        hardwareFolder: hardwareFolder,
        onProgress: (message) {
          if (operationRevision != _contentRevision) return;
          emit(state.copyWith(progressText: message));
        },
      );
      if (operationRevision != _contentRevision) return;
      if (result.failedVerificationFiles > 0) {
        emit(
          state.copyWith(
            activeOperation: PolyMultisampleActiveOperation.none,
            clearProgressText: true,
            error:
                'Uploaded sample folder to $hardwareFolder, but ${result.failedVerificationFiles} uploaded file check(s) failed.',
          ),
        );
        return;
      }
      emit(
        state.copyWith(
          activeOperation: PolyMultisampleActiveOperation.none,
          clearProgressText: true,
          effect: 'Uploaded sample folder to $hardwareFolder.',
          effectId: state.effectId + 1,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          activeOperation: PolyMultisampleActiveOperation.none,
          clearProgressText: true,
          error: error.toString(),
        ),
      );
    }
  }

  Future<void> applyChanges([IDistingMidiManager? manager]) async {
    final instrument = state.currentInstrument;
    if (instrument == null) return;
    if (state.hasWaveformDrafts) {
      emit(
        state.copyWith(
          activeOperation: PolyMultisampleActiveOperation.none,
          error:
              'Save or discard waveform edits before applying sample changes.',
        ),
      );
      return;
    }
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
        final shouldStopPreview = state.previewState.visiblePath != null;
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
            forceStopPreview: shouldStopPreview,
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
      final shouldStopPreview = _localPlanTouchesPath(
        plan,
        state.previewState.visiblePath,
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
          forceStopPreview: shouldStopPreview,
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

  Future<void> loadWaveform(String path, {bool force = false}) async {
    final operationRevision = _contentRevision;
    if (!force &&
        (state.waveformSummaries.containsKey(path) ||
            state.waveformLoadingPaths.contains(path))) {
      return;
    }
    final token = ++_waveformLoadSequence;
    _waveformLoadTokens[path] = token;
    emit(
      state.copyWith(
        activeOperation:
            state.activeOperation == PolyMultisampleActiveOperation.none
            ? PolyMultisampleActiveOperation.waveform
            : state.activeOperation,
        waveformSummaries: force
            ? (Map<String, WavOverview>.from(state.waveformSummaries)
                ..remove(path))
            : state.waveformSummaries,
        waveformLoadingPaths: {...state.waveformLoadingPaths, path},
        waveformFailedPaths: Set<String>.from(state.waveformFailedPaths)
          ..remove(path),
        clearError: true,
      ),
    );
    try {
      final overview = await _wavService.loadWaveform(path);
      if (operationRevision != _contentRevision) {
        _clearStaleWaveformLoad(path, token);
        return;
      }
      if (_waveformLoadTokens[path] != token) {
        return;
      }
      final summaries = Map<String, WavOverview>.from(state.waveformSummaries)
        ..[path] = overview;
      emit(
        state.copyWith(
          activeOperation:
              state.activeOperation == PolyMultisampleActiveOperation.waveform
              ? PolyMultisampleActiveOperation.none
              : state.activeOperation,
          waveformSummaries: summaries,
          waveformLoadingPaths: Set<String>.from(state.waveformLoadingPaths)
            ..remove(path),
          waveformFailedPaths: Set<String>.from(state.waveformFailedPaths)
            ..remove(path),
        ),
      );
    } catch (error) {
      if (operationRevision != _contentRevision) {
        _clearStaleWaveformLoad(path, token);
        return;
      }
      if (_waveformLoadTokens[path] != token) {
        return;
      }
      emit(
        state.copyWith(
          activeOperation:
              state.activeOperation == PolyMultisampleActiveOperation.waveform
              ? PolyMultisampleActiveOperation.none
              : state.activeOperation,
          waveformLoadingPaths: Set<String>.from(state.waveformLoadingPaths)
            ..remove(path),
          waveformFailedPaths: {...state.waveformFailedPaths, path},
          error: error.toString(),
        ),
      );
    }
  }

  void _clearStaleWaveformLoad(String path, int token) {
    if (_waveformLoadTokens[path] != token ||
        !state.waveformLoadingPaths.contains(path)) {
      return;
    }
    emit(
      state.copyWith(
        activeOperation:
            state.activeOperation == PolyMultisampleActiveOperation.waveform
            ? PolyMultisampleActiveOperation.none
            : state.activeOperation,
        waveformLoadingPaths: Set<String>.from(state.waveformLoadingPaths)
          ..remove(path),
      ),
    );
  }

  bool _isLocalEditableWav(String path) {
    return path.toLowerCase().endsWith('.wav') &&
        !(state.sourceMode == PolySampleSourceMode.hardware &&
            path.startsWith('/'));
  }

  bool _loopDraftChanged(PolyWaveformDraft draft, WavOverview overview) {
    return draft.loopStart != overview.loopStart ||
        draft.loopEnd != overview.loopEnd;
  }

  bool _wavEditDraftChanged(PolyWaveformDraft draft, WavOverview overview) {
    final maxFrame = math.max(0, overview.frameCount - 1);
    return (draft.trimStart ?? 0) != 0 ||
        (draft.trimEnd ?? maxFrame) != maxFrame ||
        draft.fadeInFrames != 0 ||
        draft.fadeOutFrames != 0 ||
        draft.fadeInCurve != WavFadeCurve.linear ||
        draft.fadeOutCurve != WavFadeCurve.linear ||
        draft.fadeInStrength != 0.5 ||
        draft.fadeOutStrength != 0.5 ||
        draft.gainDb != 0 ||
        draft.normalizePeakDb != null;
  }

  void setWaveformMode(PolyWaveformMode mode) {
    emit(state.copyWith(waveformMode: mode));
  }

  void updateLoopDraft(String path, PolyWaveformDraft draft) {
    final overview = state.waveformSummaries[path];
    final snappedDraft = overview == null
        ? draft
        : _snapLoopDraftToZeroCrossings(draft, overview);
    final previousDraft = overview == null
        ? state.loopDrafts[path]
        : state.loopDrafts[path] ??
              PolyWaveformDraft(
                loopStart: overview.loopStart,
                loopEnd: overview.loopEnd,
              );
    final loopPointsChanged =
        previousDraft?.loopStart != snappedDraft.loopStart ||
        previousDraft?.loopEnd != snappedDraft.loopEnd;
    final nextDrafts = Map<String, PolyWaveformDraft>.from(state.loopDrafts);
    if (overview != null && !_loopDraftChanged(snappedDraft, overview)) {
      nextDrafts.remove(path);
    } else {
      nextDrafts[path] = snappedDraft;
    }
    emit(state.copyWith(loopDrafts: nextDrafts));
    if (overview != null &&
        loopPointsChanged &&
        snappedDraft.loopStart != null &&
        snappedDraft.loopEnd != null &&
        File(path).existsSync()) {
      _scheduleLoopEditPreview(path, snappedDraft, overview);
    }
  }

  PolyWaveformDraft _snapLoopDraftToZeroCrossings(
    PolyWaveformDraft draft,
    WavOverview overview,
  ) {
    final loopStart = draft.loopStart;
    final loopEnd = draft.loopEnd;
    if (loopStart == null || loopEnd == null) return draft;
    final maxFrame = math.max(0, overview.frameCount - 1);
    final rawStart = loopStart.clamp(0, math.max(0, loopEnd - 1)).toInt();
    final snappedStart = _nearestZeroCrossingInRange(
      overview,
      rawStart,
      minFrame: 0,
      maxFrame: math.max(0, loopEnd - 1),
    );
    final minEndFrame = math.min(maxFrame, snappedStart + 1);
    final rawEnd = loopEnd.clamp(minEndFrame, maxFrame).toInt();
    final snappedEnd = _nearestZeroCrossingInRange(
      overview,
      rawEnd,
      minFrame: minEndFrame,
      maxFrame: maxFrame,
    );
    return draft.copyWith(loopStart: snappedStart, loopEnd: snappedEnd);
  }

  int _nearestZeroCrossingInRange(
    WavOverview overview,
    int frame, {
    required int minFrame,
    required int maxFrame,
  }) {
    final frameLimit = math.max(0, overview.frameCount - 1);
    final lowerFrame = minFrame.clamp(0, frameLimit).toInt();
    final upperFrame = maxFrame.clamp(lowerFrame, frameLimit).toInt();
    final clampedFrame = frame.clamp(lowerFrame, upperFrame).toInt();
    final zeroCrossings = overview.zeroCrossings;
    if (zeroCrossings.isEmpty) return clampedFrame;

    var low = 0;
    var high = zeroCrossings.length;
    while (low < high) {
      final mid = (low + high) >> 1;
      if (zeroCrossings[mid] < clampedFrame) {
        low = mid + 1;
      } else {
        high = mid;
      }
    }

    int? best;
    for (final index in [low - 1, low]) {
      if (index < 0 || index >= zeroCrossings.length) continue;
      final candidate = zeroCrossings[index];
      if (candidate < lowerFrame || candidate > upperFrame) continue;
      final distance = (candidate - clampedFrame).abs();
      if (best == null || distance < (best - clampedFrame).abs()) {
        best = candidate;
      }
    }
    return best ?? clampedFrame;
  }

  void _scheduleLoopEditPreview(
    String path,
    PolyWaveformDraft draft,
    WavOverview overview,
  ) {
    final requestId = ++_loopEditPreviewRequest;
    _loopEditPreviewDebounce?.cancel();
    _loopEditPreviewDebounce = Timer(const Duration(milliseconds: 80), () {
      unawaited(
        _playLoopEditPreview(path, draft, overview, requestId: requestId),
      );
    });
  }

  Future<void> _playLoopEditPreview(
    String path,
    PolyWaveformDraft draft,
    WavOverview overview, {
    required int requestId,
  }) async {
    try {
      if (_isHardwarePreviewPath(path) ||
          !path.toLowerCase().endsWith('.wav')) {
        return;
      }
      final loopStart = draft.loopStart;
      final loopEnd = draft.loopEnd;
      if (loopStart == null || loopEnd == null) return;
      final bytes = await File(path).readAsBytes();
      if (requestId != _loopEditPreviewRequest || _isClosing) return;
      final prepared = _preparedKeyboardPreviewBytes(path, bytes);
      final looped = WavMetadataWriter.writeSmplLoop(
        prepared,
        loopStart: loopStart,
        loopEnd: loopEnd,
      );
      final preRollFrames = math.min(512, math.max(0, loopEnd - loopStart));
      final previewStart = math.max(0, loopEnd - preRollFrames);
      final loopLength = math.max(1, loopEnd - loopStart + 1);
      final rendered = WavAudioRenderer.renderPitchedPreview(
        looped,
        pitchRatio: 1,
        previewStartFrame: previewStart,
        renderedFrameLimit: math.min(
          math.max(overview.sampleRate ~/ 2, 1),
          preRollFrames + loopLength * 2,
        ),
      );
      if (requestId != _loopEditPreviewRequest || _isClosing) return;
      final root = await Directory.systemTemp.createTemp(
        'nt_helper_poly_note_preview_',
      );
      if (requestId != _loopEditPreviewRequest || _isClosing) {
        await _deleteNotePreviewRoot(root.path);
        return;
      }
      _notePreviewRoots.add(root.path);
      final output = File(p.join(root.path, 'loop-preview.wav'));
      await output.writeAsBytes(rendered, flush: true);
      if (requestId != _loopEditPreviewRequest || _isClosing) {
        _notePreviewRoots.remove(root.path);
        await _deleteNotePreviewRoot(root.path);
        return;
      }
      await _previewService.restartPreview(
        output.path,
        displayPath: path,
        gainDb: state.previewGainDb,
      );
    } catch (error) {
      if (requestId == _loopEditPreviewRequest && !_isClosing) {
        emit(state.copyWith(error: error.toString()));
      }
    }
  }

  Future<void> saveLoopMetadata(String path) async {
    try {
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
      emit(
        state.copyWith(
          loopDrafts: Map<String, PolyWaveformDraft>.from(state.loopDrafts)
            ..remove(path),
        ),
      );
      await loadWaveform(path, force: true);
    } catch (error) {
      emit(
        state.copyWith(
          activeOperation: PolyMultisampleActiveOperation.none,
          error: error.toString(),
        ),
      );
    }
  }

  void updateWavEditDraft(String path, PolyWaveformDraft draft) {
    final overview = state.waveformSummaries[path];
    final nextDrafts = Map<String, PolyWaveformDraft>.from(state.wavEditDrafts);
    if (overview != null && !_wavEditDraftChanged(draft, overview)) {
      nextDrafts.remove(path);
    } else {
      nextDrafts[path] = draft;
    }
    emit(state.copyWith(wavEditDrafts: nextDrafts));
  }

  Future<void> saveDestructiveWav(
    String path,
    String targetPath,
    bool overwriteConfirmed,
  ) async {
    try {
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
          wavEditDrafts: p.normalize(path) == p.normalize(targetPath)
              ? (Map<String, PolyWaveformDraft>.from(state.wavEditDrafts)
                  ..remove(path))
              : state.wavEditDrafts,
          effect: 'Saved edited WAV.',
          effectId: state.effectId + 1,
          clearError: true,
        ),
      );
      if (p.normalize(path) == p.normalize(targetPath)) {
        await loadWaveform(path, force: true);
      }
    } catch (error) {
      emit(
        state.copyWith(
          activeOperation: PolyMultisampleActiveOperation.none,
          error: error.toString(),
        ),
      );
    }
  }

  Future<void> playOrStopPreview(
    String path, {
    IDistingMidiManager? manager,
  }) async {
    _loopEditPreviewRequest++;
    _loopEditPreviewDebounce?.cancel();
    try {
      if (_isHardwarePreviewPath(path)) {
        if (manager == null) {
          throw const PolySampleHardwareException(
            'Connect to Disting NT to preview hardware samples.',
          );
        }
        final localPath = await _cachedHardwarePreviewPath(manager, path);
        if (localPath == null) return;
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

  Future<void> playKeyboardNotePreview(int midi) async {
    await startKeyboardNotePreview(midi);
  }

  Future<void> startKeyboardNotePreview(int midi) async {
    final clampedMidi = midi.clamp(0, 127).toInt();
    _loopEditPreviewRequest++;
    _loopEditPreviewDebounce?.cancel();
    final requestId = ++_notePreviewRequest;
    try {
      if (_hasDirectHardwareWavPreviewCandidate(clampedMidi)) {
        emit(
          state.copyWith(
            error:
                'Keyboard note preview is only available for local or mounted WAV files.',
          ),
        );
        return;
      }

      final match = _resolveKeyboardNotePreviewRegion(clampedMidi);
      if (match == null) {
        emit(
          state.copyWith(
            error:
                'No local WAV sample is mapped to ${PolyMultisampleParser.midiToNoteName(clampedMidi)}.',
          ),
        );
        return;
      }

      selectRegion(
        match.region.path,
        PolyRegionSelectionMode.replace,
        autoPreviewSelection: false,
      );
      if (requestId != _notePreviewRequest || _isClosing) return;

      final renderedPath = await _renderedKeyboardNotePreviewPath(
        match.region,
        clampedMidi,
      );
      if (requestId != _notePreviewRequest || _isClosing) return;

      final nextCursor =
          (_notePreviewRoundRobinCursor[match.roundRobinCursorKey] ?? 0) + 1;
      _notePreviewRoundRobinCursor[match.roundRobinCursorKey] = nextCursor;
      final sourcePlayback = await _keyboardPreviewSourcePlayback(
        match.region,
        clampedMidi,
      );
      if (requestId != _notePreviewRequest || _isClosing) return;
      await _previewService.restartPreview(
        renderedPath,
        displayPath: match.region.path,
        playingMidiNote: clampedMidi,
        sourcePlayback: sourcePlayback,
        gainDb: state.previewGainDb,
      );
    } on _StaleNotePreviewRequest {
      return;
    } catch (error) {
      if (requestId == _notePreviewRequest && !_isClosing) {
        emit(state.copyWith(error: error.toString()));
      }
    }
  }

  Future<void> stopKeyboardNotePreview() async {
    _notePreviewRequest++;
    _loopEditPreviewRequest++;
    _loopEditPreviewDebounce?.cancel();
    if (state.previewState.playingMidiNote == null) {
      return;
    }
    try {
      await _previewService.stop();
    } catch (error) {
      emit(state.copyWith(error: error.toString()));
    }
  }

  Future<void> stopPreview() async {
    try {
      await _previewService.stop();
    } catch (error) {
      emit(state.copyWith(error: error.toString()));
    }
  }

  void _autoPreviewMappingEdit(String path, {IDistingMidiManager? manager}) {
    if (!state.autoPreview) return;
    final requestId = ++_autoPreviewRequest;
    if (!path.toLowerCase().endsWith('.wav')) {
      if (state.previewState.visiblePath != null) {
        unawaited(_previewService.stop());
      }
      return;
    }
    unawaited(
      _playAutoPreview(
        path,
        requestId: requestId,
        manager: manager,
        restartVisiblePreview: true,
      ),
    );
  }

  Future<void> _playAutoPreview(
    String path, {
    required int requestId,
    IDistingMidiManager? manager,
    required bool restartVisiblePreview,
  }) async {
    try {
      if (_isHardwarePreviewPath(path)) {
        if (manager == null) {
          throw const PolySampleHardwareException(
            'Connect to Disting NT to preview hardware samples.',
          );
        }
        final localPath = await _cachedHardwarePreviewPath(manager, path);
        if (localPath == null) return;
        if (requestId != _autoPreviewRequest || _isClosing) return;
        if (restartVisiblePreview && state.previewState.visiblePath == path) {
          await _previewService.stop();
        }
        if (requestId != _autoPreviewRequest || _isClosing) return;
        await _previewService.playOrStopPreview(
          localPath,
          displayPath: path,
          gainDb: state.previewGainDb,
        );
        return;
      }
      if (requestId != _autoPreviewRequest || _isClosing) return;
      if (restartVisiblePreview && state.previewState.visiblePath == path) {
        await _previewService.stop();
      }
      if (requestId != _autoPreviewRequest || _isClosing) return;
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
    if (!enabled) _autoPreviewRequest++;
    emit(state.copyWith(autoPreview: enabled));
  }

  @override
  Future<void> close() async {
    _isClosing = true;
    _notePreviewRequest++;
    _loopEditPreviewRequest++;
    _loopEditPreviewDebounce?.cancel();
    await _previewSub.cancel();
    await _previewService.dispose();
    await _cleanupHardwarePreviewRoots();
    await _cleanupNotePreviewRoots();
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
      await adoptStagedImport(staged);
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

  _KeyboardNotePreviewMatch? _resolveKeyboardNotePreviewRegion(int midi) {
    final allRegions = state.editedRegions;
    final candidates = [
      for (final region in allRegions)
        if (region.rootMidi != null &&
            _isLocalMountedWavPreviewPath(region.path) &&
            _notePreviewEffectiveLow(region) <= midi &&
            _notePreviewEffectiveHigh(region, allRegions) >= midi)
          region,
    ];
    if (candidates.isEmpty) return null;

    final focusedPath = state.focusedPath;
    int? velocityLane;
    if (focusedPath != null) {
      final focused = candidates.where((region) => region.path == focusedPath);
      if (focused.isNotEmpty) {
        velocityLane = focused.first.velocityLayer ?? 1;
      }
    }
    if (velocityLane == null && state.selectedPaths.isNotEmpty) {
      final selectedPath = state.selectedPaths.first;
      final selected = candidates.where(
        (region) => region.path == selectedPath,
      );
      if (selected.isNotEmpty) {
        velocityLane = selected.first.velocityLayer ?? 1;
      }
    }
    velocityLane ??=
        candidates.any((region) => (region.velocityLayer ?? 1) == 1)
        ? 1
        : candidates
              .map((region) => region.velocityLayer ?? 1)
              .reduce(math.min);

    final laneCandidates = [
      for (final region in candidates)
        if ((region.velocityLayer ?? 1) == velocityLane) region,
    ];
    laneCandidates.sort((a, b) {
      final lowA = _notePreviewEffectiveLow(a);
      final lowB = _notePreviewEffectiveLow(b);
      final highA = _notePreviewEffectiveHigh(a, allRegions);
      final highB = _notePreviewEffectiveHigh(b, allRegions);
      final spanCompare = (highA - lowA).compareTo(highB - lowB);
      if (spanCompare != 0) return spanCompare;
      final lowCompare = lowB.compareTo(lowA);
      if (lowCompare != 0) return lowCompare;
      final rootCompare = (a.rootMidi! - midi).abs().compareTo(
        (b.rootMidi! - midi).abs(),
      );
      if (rootCompare != 0) return rootCompare;
      final rrCompare = (a.roundRobin ?? 1).compareTo(b.roundRobin ?? 1);
      if (rrCompare != 0) return rrCompare;
      return a.displayName.compareTo(b.displayName);
    });

    final primary = laneCandidates.first;
    final groupLow = _notePreviewEffectiveLow(primary);
    final groupHigh = _notePreviewEffectiveHigh(primary, allRegions);
    final groupVelocity = primary.velocityLayer ?? 1;
    final roundRobinGroup =
        [
          for (final region in laneCandidates)
            if (_notePreviewEffectiveLow(region) == groupLow &&
                _notePreviewEffectiveHigh(region, allRegions) == groupHigh &&
                (region.velocityLayer ?? 1) == groupVelocity)
              region,
        ]..sort((a, b) {
          final rrCompare = (a.roundRobin ?? 1).compareTo(b.roundRobin ?? 1);
          if (rrCompare != 0) return rrCompare;
          final nameCompare = a.displayName.compareTo(b.displayName);
          if (nameCompare != 0) return nameCompare;
          return a.path.compareTo(b.path);
        });
    final cursorKey = '$groupLow:$groupHigh:$groupVelocity';
    final cursor = _notePreviewRoundRobinCursor[cursorKey] ?? 0;
    return _KeyboardNotePreviewMatch(
      region: roundRobinGroup[cursor % roundRobinGroup.length],
      roundRobinCursorKey: cursorKey,
    );
  }

  int _notePreviewEffectiveLow(PolySampleRegion region) {
    return (region.rangeLow ?? region.switchPoint ?? region.rootMidi ?? 0)
        .clamp(0, 127)
        .toInt();
  }

  int _notePreviewEffectiveHigh(
    PolySampleRegion region,
    List<PolySampleRegion> regions,
  ) {
    final explicit = region.rangeHigh;
    if (explicit != null) return explicit.clamp(0, 127).toInt();
    final low = _notePreviewEffectiveLow(region);
    final velocity = region.velocityLayer ?? 1;
    final laterLows =
        regions
            .where(
              (candidate) =>
                  candidate.rootMidi != null &&
                  (candidate.velocityLayer ?? 1) == velocity &&
                  _notePreviewEffectiveLow(candidate) > low,
            )
            .map(_notePreviewEffectiveLow)
            .toList()
          ..sort();
    if (laterLows.isEmpty) return 127;
    return math.max(low, laterLows.first - 1);
  }

  bool _isLocalMountedWavPreviewPath(String path) {
    return path.toLowerCase().endsWith('.wav') &&
        !(state.sourceMode == PolySampleSourceMode.hardware &&
            path.startsWith('/'));
  }

  bool _hasDirectHardwareWavPreviewCandidate(int midi) {
    if (state.sourceMode != PolySampleSourceMode.hardware) return false;
    return state.editedRegions.any(
      (region) =>
          region.rootMidi != null &&
          region.path.startsWith('/') &&
          region.path.toLowerCase().endsWith('.wav') &&
          _notePreviewEffectiveLow(region) <= midi &&
          _notePreviewEffectiveHigh(region, state.editedRegions) >= midi,
    );
  }

  String _previewDraftFingerprint(String path) {
    final loop = state.loopDrafts[path];
    final edit = state.wavEditDrafts[path];
    return [
      loop?.loopStart,
      loop?.loopEnd,
      edit?.trimStart,
      edit?.trimEnd,
      edit?.fadeInFrames,
      edit?.fadeOutFrames,
      edit?.fadeInCurve.name,
      edit?.fadeOutCurve.name,
      edit?.fadeInStrength,
      edit?.fadeOutStrength,
      edit?.gainDb,
      edit?.normalizePeakDb,
    ].join(':');
  }

  Uint8List _preparedKeyboardPreviewBytes(String path, Uint8List bytes) {
    var prepared = bytes;
    final overview =
        state.waveformSummaries[path] ?? WavMetadataReader.parse(bytes);
    final loopDraft = state.loopDrafts[path];
    final loopStart = loopDraft?.loopStart ?? overview?.loopStart;
    final loopEnd = loopDraft?.loopEnd ?? overview?.loopEnd;
    if (loopDraft != null &&
        (loopDraft.loopStart == null || loopDraft.loopEnd == null)) {
      prepared = WavMetadataWriter.removeSmplLoop(prepared);
    } else if (loopStart != null && loopEnd != null) {
      prepared = WavMetadataWriter.writeSmplLoop(
        prepared,
        loopStart: loopStart,
        loopEnd: loopEnd,
      );
    }

    final edit = state.wavEditDrafts[path];
    if (edit == null) return prepared;
    final maxFrame = math.max(0, (overview?.frameCount ?? 1) - 1);
    return WavAudioRenderer.render(
      prepared,
      WavRenderOptions(
        trimStartFrame: edit.trimStart ?? 0,
        trimEndFrame: edit.trimEnd ?? maxFrame,
        fadeInFrames: edit.fadeInFrames,
        fadeOutFrames: edit.fadeOutFrames,
        fadeInCurve: edit.fadeInCurve,
        fadeOutCurve: edit.fadeOutCurve,
        fadeInStrength: edit.fadeInStrength,
        fadeOutStrength: edit.fadeOutStrength,
        gainDb: edit.gainDb,
        normalizePeakDb: edit.normalizePeakDb,
      ),
    );
  }

  Future<PolyAudioPreviewSourcePlayback?> _keyboardPreviewSourcePlayback(
    PolySampleRegion region,
    int midi,
  ) async {
    final overview =
        state.waveformSummaries[region.path] ??
        WavMetadataReader.parse(await File(region.path).readAsBytes());
    if (overview == null || region.rootMidi == null) return null;
    final maxFrame = math.max(0, overview.frameCount - 1);
    final edit = state.wavEditDrafts[region.path];
    final startFrame = (edit?.trimStart ?? 0).clamp(0, maxFrame).toInt();
    final endFrame = (edit?.trimEnd ?? maxFrame)
        .clamp(startFrame, maxFrame)
        .toInt();
    final loopDraft = state.loopDrafts[region.path];
    final (loopStart, loopEnd) = loopDraft != null
        ? (loopDraft.loopStart, loopDraft.loopEnd)
        : (overview.loopStart, overview.loopEnd);
    return PolyAudioPreviewSourcePlayback(
      sourcePath: region.path,
      startedAt: DateTime.now(),
      startFrame: startFrame,
      endFrame: endFrame,
      sampleRate: overview.sampleRate,
      pitchRatio: math.pow(2, (midi - region.rootMidi!) / 12).toDouble(),
      loopStartFrame: loopStart,
      loopEndFrame: loopEnd,
    );
  }

  Future<String> _renderedKeyboardNotePreviewPath(
    PolySampleRegion region,
    int midi,
  ) async {
    final generation = _notePreviewGeneration;
    final file = File(region.path);
    final stat = await file.stat();
    final cacheKey = [
      p.normalize(region.path),
      stat.modified.millisecondsSinceEpoch,
      stat.size,
      region.rootMidi,
      midi,
      _previewDraftFingerprint(region.path),
    ].join('|');
    final cachedPath = _notePreviewCache[cacheKey];
    if (cachedPath != null && await File(cachedPath).exists()) {
      return cachedPath;
    }
    final existing = _notePreviewRenderInFlight[cacheKey];
    if (existing != null) return existing;

    final future = (() async {
      final bytes = await file.readAsBytes();
      final preparedBytes = _preparedKeyboardPreviewBytes(region.path, bytes);
      final pitchRatio = math.pow(2, (midi - region.rootMidi!) / 12).toDouble();
      final rendered = await Future<Uint8List>.value(
        _notePreviewRenderer(preparedBytes, pitchRatio),
      );
      if (generation != _notePreviewGeneration || _isClosing) {
        throw const _StaleNotePreviewRequest();
      }
      final root = await Directory.systemTemp.createTemp(
        'nt_helper_poly_note_preview_',
      );
      if (generation != _notePreviewGeneration || _isClosing) {
        await _deleteNotePreviewRoot(root.path);
        throw const _StaleNotePreviewRequest();
      }
      _notePreviewRoots.add(root.path);
      final output = File(p.join(root.path, 'preview.wav'));
      await output.writeAsBytes(rendered, flush: true);
      if (generation != _notePreviewGeneration || _isClosing) {
        _notePreviewRoots.remove(root.path);
        await _deleteNotePreviewRoot(root.path);
        throw const _StaleNotePreviewRequest();
      }
      _notePreviewCache[cacheKey] = output.path;
      return output.path;
    })();
    _notePreviewRenderInFlight[cacheKey] = future;
    try {
      return await future;
    } finally {
      if (identical(_notePreviewRenderInFlight[cacheKey], future)) {
        _notePreviewRenderInFlight.remove(cacheKey);
      }
    }
  }

  Future<void> _cleanupNotePreviewRoots() async {
    _notePreviewGeneration++;
    final roots = List<String>.from(_notePreviewRoots);
    _notePreviewRoots.clear();
    _notePreviewCache.clear();
    _notePreviewRenderInFlight.clear();
    for (final root in roots) {
      await _deleteNotePreviewRoot(root);
    }
  }

  Future<void> _deleteNotePreviewRoot(String root) async {
    try {
      final dir = Directory(root);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    } on FileSystemException {
      // Best-effort cleanup only.
    }
  }

  Future<String?> _cachedHardwarePreviewPath(
    IDistingMidiManager manager,
    String path,
  ) async {
    final existing = _hardwarePreviewCache[path];
    if (existing != null && await File(existing).exists()) {
      return existing;
    }
    if (_hardwarePreviewInFlight) return null;
    _hardwarePreviewInFlight = true;
    try {
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
    } finally {
      _hardwarePreviewInFlight = false;
    }
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
    bool forceStopPreview = false,
  }) {
    _contentRevision++;
    final regions = List<PolySampleRegion>.from(instrument.regions);
    final previewVisiblePath = state.previewState.visiblePath;
    final shouldStopPreview =
        previewVisiblePath != null &&
        (forceStopPreview ||
            !regions.any((region) => region.path == previewVisiblePath));
    if (shouldStopPreview) {
      unawaited(_previewService.stop());
    }
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
        waveformSummaries: const {},
        waveformLoadingPaths: const {},
        waveformFailedPaths: const {},
        loopDrafts: const {},
        wavEditDrafts: const {},
        previewState: shouldStopPreview
            ? PolyAudioPreviewState(gainDb: state.previewState.gainDb)
            : state.previewState,
        effect: effect,
        effectId: effect == null ? state.effectId : state.effectId + 1,
        clearProgressText: true,
        clearError: true,
      ),
    );
  }

  bool _updateRegion(
    String path,
    PolySampleRegion Function(PolySampleRegion region) update, {
    Set<String>? selectedPaths,
    String? focusedPathOverride,
  }) {
    var matched = false;
    final next = [
      for (final region in state.editedRegions)
        if (region.path == path) ...[update(region)] else region,
    ];
    matched = state.editedRegions.any((region) => region.path == path);
    if (!matched) return false;
    _replaceEditedRegions(
      next,
      selectedPaths: selectedPaths,
      focusedPathOverride: focusedPathOverride,
    );
    return true;
  }

  void _replaceEditedRegions(
    List<PolySampleRegion> regions, {
    Set<String>? selectedPaths,
    String? focusedPathOverride,
  }) {
    _contentRevision++;
    PolyMultisampleParser.sortRegions(regions);
    final instrument = state.currentInstrument;
    final remainingPaths = {for (final region in regions) region.path};
    final nextSelectedPaths = (selectedPaths ?? state.selectedPaths)
        .where(remainingPaths.contains)
        .toSet();
    final focusedPath =
        focusedPathOverride != null &&
            remainingPaths.contains(focusedPathOverride)
        ? focusedPathOverride
        : remainingPaths.contains(state.focusedPath)
        ? state.focusedPath
        : nextSelectedPaths.firstOrNull;
    final previewVisiblePath = state.previewState.visiblePath;
    final shouldStopPreview =
        previewVisiblePath != null &&
        !remainingPaths.contains(previewVisiblePath);
    if (shouldStopPreview) {
      unawaited(_previewService.stop());
    }
    Map<String, T> pruneMap<T>(Map<String, T> values) {
      return {
        for (final entry in values.entries)
          if (remainingPaths.contains(entry.key)) entry.key: entry.value,
      };
    }

    emit(
      state.copyWith(
        currentInstrument: instrument?.copyWith(regions: regions),
        editedRegions: List<PolySampleRegion>.from(regions),
        selectedPaths: nextSelectedPaths,
        focusedPath: focusedPath,
        clearFocusedPath: focusedPath == null,
        waveformSummaries: pruneMap(state.waveformSummaries),
        waveformLoadingPaths: state.waveformLoadingPaths
            .where(remainingPaths.contains)
            .toSet(),
        waveformFailedPaths: state.waveformFailedPaths
            .where(remainingPaths.contains)
            .toSet(),
        loopDrafts: pruneMap(state.loopDrafts),
        wavEditDrafts: pruneMap(state.wavEditDrafts),
        previewState: shouldStopPreview
            ? PolyAudioPreviewState(gainDb: state.previewState.gainDb)
            : state.previewState,
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

  bool _localPlanTouchesPath(PolySampleApplyPlan plan, String? path) {
    if (path == null) return false;
    final normalized = p.normalize(path);
    return plan.additions.any(
          (addition) =>
              p.normalize(addition.sourcePath) == normalized ||
              p.normalize(addition.toPath) == normalized,
        ) ||
        plan.removals.any(
          (removal) => p.normalize(removal.path) == normalized,
        ) ||
        plan.renames.any(
          (rename) =>
              p.normalize(rename.fromPath) == normalized ||
              p.normalize(rename.toPath) == normalized,
        );
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

class _StaleNotePreviewRequest implements Exception {
  const _StaleNotePreviewRequest();
}

class _KeyboardNotePreviewMatch {
  const _KeyboardNotePreviewMatch({
    required this.region,
    required this.roundRobinCursorKey,
  });

  final PolySampleRegion region;
  final String roundRobinCursorKey;
}

String _safeHardwareFolderName(String name) {
  final sanitized = name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
  return sanitized.isEmpty ? 'Untitled' : sanitized;
}

String _mountedSdDestinationFolder(
  String mountedSdFolder,
  String instrumentName,
) {
  final safeName = _safeHardwareFolderName(instrumentName);
  final normalized = p.normalize(mountedSdFolder);
  final basename = p.basename(normalized);
  final parent = p.dirname(normalized);
  final parentBasename = p.basename(parent);

  if (basename == safeName &&
      (parentBasename == 'samples' || parentBasename == 'multisamples')) {
    return p.join(p.dirname(parent), 'multisamples', safeName);
  }
  if (basename == 'samples' || basename == 'multisamples') {
    return p.join(parent, 'multisamples', safeName);
  }
  return p.join(normalized, 'multisamples', safeName);
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
