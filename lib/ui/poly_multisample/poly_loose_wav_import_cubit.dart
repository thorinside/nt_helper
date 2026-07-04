import 'package:bloc/bloc.dart';
import 'package:nt_helper/poly_multisample/poly_multisample_models.dart';
import 'package:nt_helper/poly_multisample/poly_sample_import_service.dart';

enum PolyLooseWavImportStatus { initial, ready, staging, completed, failure }

class PolyLooseWavImportState {
  const PolyLooseWavImportState({
    this.status = PolyLooseWavImportStatus.initial,
    this.paths = const [],
    this.selectedPaths = const {},
    this.mappingOptions = const PolyLooseWavMappingOptions(),
    this.warnings = const [],
    this.error,
    this.stagedImport,
  });

  final PolyLooseWavImportStatus status;
  final List<String> paths;
  final Set<String> selectedPaths;
  final PolyLooseWavMappingOptions mappingOptions;
  final List<String> warnings;
  final String? error;
  final PolyStagedImport? stagedImport;

  bool get canContinue =>
      status == PolyLooseWavImportStatus.ready && selectedPaths.isNotEmpty;

  PolyLooseWavImportState copyWith({
    PolyLooseWavImportStatus? status,
    List<String>? paths,
    Set<String>? selectedPaths,
    PolyLooseWavMappingOptions? mappingOptions,
    List<String>? warnings,
    String? error,
    bool clearError = false,
    PolyStagedImport? stagedImport,
  }) {
    return PolyLooseWavImportState(
      status: status ?? this.status,
      paths: paths ?? this.paths,
      selectedPaths: selectedPaths ?? this.selectedPaths,
      mappingOptions: mappingOptions ?? this.mappingOptions,
      warnings: warnings ?? this.warnings,
      error: clearError ? null : error ?? this.error,
      stagedImport: stagedImport ?? this.stagedImport,
    );
  }
}

class PolyLooseWavImportCubit extends Cubit<PolyLooseWavImportState> {
  PolyLooseWavImportCubit({PolySampleImportService? importService})
    : _importService = importService ?? PolySampleImportService(),
      super(const PolyLooseWavImportState());

  final PolySampleImportService _importService;

  Future<void> setFiles(List<String> paths) async {
    final uniquePaths = paths.toSet().toList()..sort();
    emit(
      state.copyWith(
        status: PolyLooseWavImportStatus.ready,
        paths: uniquePaths,
        selectedPaths: uniquePaths.toSet(),
        clearError: true,
      ),
    );
  }

  void setMappingOptions(PolyLooseWavMappingOptions options) {
    emit(state.copyWith(mappingOptions: options, clearError: true));
  }

  void toggleSelection(String path) {
    final next = Set<String>.from(state.selectedPaths);
    if (!next.add(path)) {
      next.remove(path);
    }
    emit(state.copyWith(selectedPaths: next, clearError: true));
  }

  void selectAll() {
    emit(state.copyWith(selectedPaths: state.paths.toSet(), clearError: true));
  }

  void clearSelection() {
    emit(state.copyWith(selectedPaths: const {}, clearError: true));
  }

  Future<void> continueImport() async {
    if (!state.canContinue) {
      emit(state.copyWith(error: 'Select at least one WAV file to continue.'));
      return;
    }

    emit(
      state.copyWith(
        status: PolyLooseWavImportStatus.staging,
        clearError: true,
      ),
    );
    try {
      final selected = [
        for (final path in state.paths)
          if (state.selectedPaths.contains(path)) path,
      ];
      final staged = await _importService.stageLooseFiles(
        selected,
        state.mappingOptions,
      );
      emit(
        state.copyWith(
          status: PolyLooseWavImportStatus.completed,
          warnings: staged.warnings,
          stagedImport: staged,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: PolyLooseWavImportStatus.failure,
          error: error.toString(),
        ),
      );
    }
  }
}
