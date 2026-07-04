import 'package:bloc/bloc.dart';
import 'package:nt_helper/poly_multisample/decent_sampler_converter.dart';
import 'package:nt_helper/poly_multisample/poly_multisample_models.dart';
import 'package:nt_helper/poly_multisample/poly_sample_import_service.dart';

enum PolyDecentImportStatus {
  initial,
  analyzing,
  ready,
  staging,
  completed,
  failure,
}

class PolyDecentImportState {
  const PolyDecentImportState({
    this.status = PolyDecentImportStatus.initial,
    this.sourcePath,
    this.analysis,
    this.groupHandling = DecentSamplerGroupHandling.auto,
    this.manualGroupRanges = const {},
    this.warnings = const [],
    this.error,
    this.stagedImport,
  });

  final PolyDecentImportStatus status;
  final String? sourcePath;
  final DecentSamplerImportAnalysis? analysis;
  final DecentSamplerGroupHandling groupHandling;
  final Map<String, DecentSamplerTagKeyRange> manualGroupRanges;
  final List<String> warnings;
  final String? error;
  final PolyStagedImport? stagedImport;

  bool get canContinue =>
      status == PolyDecentImportStatus.ready && warnings.isEmpty;

  PolyDecentImportState copyWith({
    PolyDecentImportStatus? status,
    String? sourcePath,
    DecentSamplerImportAnalysis? analysis,
    DecentSamplerGroupHandling? groupHandling,
    Map<String, DecentSamplerTagKeyRange>? manualGroupRanges,
    List<String>? warnings,
    String? error,
    bool clearError = false,
    PolyStagedImport? stagedImport,
  }) {
    return PolyDecentImportState(
      status: status ?? this.status,
      sourcePath: sourcePath ?? this.sourcePath,
      analysis: analysis ?? this.analysis,
      groupHandling: groupHandling ?? this.groupHandling,
      manualGroupRanges: manualGroupRanges ?? this.manualGroupRanges,
      warnings: warnings ?? this.warnings,
      error: clearError ? null : error ?? this.error,
      stagedImport: stagedImport ?? this.stagedImport,
    );
  }
}

class PolyDecentImportCubit extends Cubit<PolyDecentImportState> {
  PolyDecentImportCubit({PolySampleImportService? importService})
    : _importService = importService ?? PolySampleImportService(),
      super(const PolyDecentImportState());

  final PolySampleImportService _importService;

  Future<void> analyzeSource(String path) async {
    emit(
      state.copyWith(
        status: PolyDecentImportStatus.analyzing,
        sourcePath: path,
        warnings: const [],
        clearError: true,
      ),
    );
    try {
      final analysis = await _importService.analyzeDecentSource(path);
      final ranges = {
        for (final group in analysis.groups)
          group.key: DecentSamplerTagKeyRange(
            lowMidi: group.defaultLowMidi,
            rootMidi: group.defaultRootMidi,
            highMidi: group.defaultHighMidi,
          ),
      };
      final handling = analysis.recommendedGroupHandling;
      emit(
        state.copyWith(
          status: PolyDecentImportStatus.ready,
          analysis: analysis,
          groupHandling: handling,
          manualGroupRanges: ranges,
          warnings: _warningsFor(handling, ranges, analysis),
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: PolyDecentImportStatus.failure,
          error: error.toString(),
        ),
      );
    }
  }

  void setGroupHandling(DecentSamplerGroupHandling handling) {
    final warnings = _warningsFor(
      handling,
      state.manualGroupRanges,
      state.analysis,
    );
    emit(
      state.copyWith(
        groupHandling: handling,
        warnings: warnings,
        clearError: true,
      ),
    );
  }

  void updateGroupRange(String groupKey, DecentSamplerTagKeyRange range) {
    final nextRanges = Map<String, DecentSamplerTagKeyRange>.from(
      state.manualGroupRanges,
    )..[groupKey] = range;
    emit(
      state.copyWith(
        manualGroupRanges: nextRanges,
        warnings: _warningsFor(state.groupHandling, nextRanges, state.analysis),
        clearError: true,
      ),
    );
  }

  Future<void> continueImport() async {
    if (!state.canContinue) {
      emit(
        state.copyWith(
          error: state.warnings.isEmpty
              ? 'Decent import is not ready.'
              : 'Resolve Decent manual overlap warnings before continuing.',
        ),
      );
      return;
    }

    final sourcePath = state.sourcePath;
    if (sourcePath == null) {
      emit(state.copyWith(error: 'No Decent source selected.'));
      return;
    }

    emit(
      state.copyWith(status: PolyDecentImportStatus.staging, clearError: true),
    );
    try {
      final staged = await _importService.stageDecentSource(
        sourcePath,
        options: DecentSamplerConvertOptions(
          groupHandling: state.groupHandling,
          groupKeyRanges: state.manualGroupRanges,
        ),
      );
      emit(
        state.copyWith(
          status: PolyDecentImportStatus.completed,
          stagedImport: staged,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: PolyDecentImportStatus.failure,
          error: error.toString(),
        ),
      );
    }
  }
}

List<String> _warningsFor(
  DecentSamplerGroupHandling handling,
  Map<String, DecentSamplerTagKeyRange> ranges,
  DecentSamplerImportAnalysis? analysis,
) {
  if (handling != DecentSamplerGroupHandling.keyRanges) return const [];
  final groupNames = {
    for (final group in analysis?.groups ?? const <DecentSamplerGroupInfo>[])
      group.key: group.name,
  };
  final warnings = <String>[];
  final entries = ranges.entries
      .where((entry) => entry.value.enabled)
      .toList(growable: false);
  for (var i = 0; i < entries.length; i++) {
    for (var j = i + 1; j < entries.length; j++) {
      final a = entries[i];
      final b = entries[j];
      if (_rangesOverlap(a.value, b.value)) {
        warnings.add(
          '${groupNames[a.key] ?? a.key} and ${groupNames[b.key] ?? b.key} '
          'overlap. Adjust manual key ranges before continuing.',
        );
      }
    }
  }
  return warnings;
}

bool _rangesOverlap(DecentSamplerTagKeyRange a, DecentSamplerTagKeyRange b) {
  return a.lowMidi <= b.highMidi && b.lowMidi <= a.highMidi;
}
