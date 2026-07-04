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
    this.selectedPresetNames = const {},
    this.selectedGroupKey,
    this.selectedTagKeys = const {},
    this.groupVelocityLayers = const {},
    this.groupRoundRobins = const {},
    this.tagKeyRanges = const {},
    this.tagVelocityLayers = const {},
    this.tagRoundRobins = const {},
    this.preserveXmlMapping = false,
    this.addUnmapped = false,
    this.warnings = const [],
    this.error,
    this.stagedImport,
  });

  final PolyDecentImportStatus status;
  final String? sourcePath;
  final DecentSamplerImportAnalysis? analysis;
  final DecentSamplerGroupHandling groupHandling;
  final Map<String, DecentSamplerTagKeyRange> manualGroupRanges;
  final Set<String> selectedPresetNames;
  final String? selectedGroupKey;
  final Set<String> selectedTagKeys;
  final Map<String, int> groupVelocityLayers;
  final Map<String, int> groupRoundRobins;
  final Map<String, DecentSamplerTagKeyRange> tagKeyRanges;
  final Map<String, int> tagVelocityLayers;
  final Map<String, int> tagRoundRobins;
  final bool preserveXmlMapping;
  final bool addUnmapped;
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
    Set<String>? selectedPresetNames,
    String? selectedGroupKey,
    bool clearSelectedGroupKey = false,
    Set<String>? selectedTagKeys,
    Map<String, int>? groupVelocityLayers,
    Map<String, int>? groupRoundRobins,
    Map<String, DecentSamplerTagKeyRange>? tagKeyRanges,
    Map<String, int>? tagVelocityLayers,
    Map<String, int>? tagRoundRobins,
    bool? preserveXmlMapping,
    bool? addUnmapped,
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
      selectedPresetNames: selectedPresetNames ?? this.selectedPresetNames,
      selectedGroupKey: clearSelectedGroupKey
          ? null
          : selectedGroupKey ?? this.selectedGroupKey,
      selectedTagKeys: selectedTagKeys ?? this.selectedTagKeys,
      groupVelocityLayers: groupVelocityLayers ?? this.groupVelocityLayers,
      groupRoundRobins: groupRoundRobins ?? this.groupRoundRobins,
      tagKeyRanges: tagKeyRanges ?? this.tagKeyRanges,
      tagVelocityLayers: tagVelocityLayers ?? this.tagVelocityLayers,
      tagRoundRobins: tagRoundRobins ?? this.tagRoundRobins,
      preserveXmlMapping: preserveXmlMapping ?? this.preserveXmlMapping,
      addUnmapped: addUnmapped ?? this.addUnmapped,
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
      final tagRanges = {
        for (final tag in analysis.tags)
          tag.key: DecentSamplerTagKeyRange(
            lowMidi: tag.defaultLowMidi,
            rootMidi: tag.defaultRootMidi,
            highMidi: tag.defaultHighMidi,
          ),
      };
      final handling = analysis.recommendedGroupHandling;
      emit(
        state.copyWith(
          status: PolyDecentImportStatus.ready,
          analysis: analysis,
          groupHandling: handling,
          manualGroupRanges: ranges,
          tagKeyRanges: tagRanges,
          selectedPresetNames: {
            for (final preset in analysis.presets) preset.name,
          },
          warnings: _warningsFor(
            handling: handling,
            groupRanges: ranges,
            tagRanges: tagRanges,
            selectedTagKeys: state.selectedTagKeys,
            analysis: analysis,
          ),
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
      handling: handling,
      groupRanges: state.manualGroupRanges,
      tagRanges: state.tagKeyRanges,
      selectedTagKeys: state.selectedTagKeys,
      analysis: state.analysis,
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
        warnings: _warningsFor(
          handling: state.groupHandling,
          groupRanges: nextRanges,
          tagRanges: state.tagKeyRanges,
          selectedTagKeys: state.selectedTagKeys,
          analysis: state.analysis,
        ),
        clearError: true,
      ),
    );
  }

  void togglePreset(String name) {
    final next = Set<String>.from(state.selectedPresetNames);
    if (!next.add(name)) next.remove(name);
    emit(state.copyWith(selectedPresetNames: next, clearError: true));
  }

  void setSelectedGroup(String? key) {
    emit(
      state.copyWith(
        selectedGroupKey: key,
        clearSelectedGroupKey: key == null,
        clearError: true,
      ),
    );
  }

  void toggleTag(String key) {
    final next = Set<String>.from(state.selectedTagKeys);
    if (!next.add(key)) next.remove(key);
    emit(
      state.copyWith(
        selectedTagKeys: next,
        warnings: _warningsFor(
          handling: state.groupHandling,
          groupRanges: state.manualGroupRanges,
          tagRanges: state.tagKeyRanges,
          selectedTagKeys: next,
          analysis: state.analysis,
        ),
        clearError: true,
      ),
    );
  }

  void setGroupVelocity(String groupKey, int layer) {
    final next = Map<String, int>.from(state.groupVelocityLayers)
      ..[groupKey] = layer;
    emit(state.copyWith(groupVelocityLayers: next, clearError: true));
  }

  void setGroupRoundRobin(String groupKey, int lane) {
    final next = Map<String, int>.from(state.groupRoundRobins)
      ..[groupKey] = lane;
    emit(state.copyWith(groupRoundRobins: next, clearError: true));
  }

  void setTagRange(String tagKey, DecentSamplerTagKeyRange range) {
    final nextRanges = Map<String, DecentSamplerTagKeyRange>.from(
      state.tagKeyRanges,
    )..[tagKey] = range;
    emit(
      state.copyWith(
        tagKeyRanges: nextRanges,
        warnings: _warningsFor(
          handling: state.groupHandling,
          groupRanges: state.manualGroupRanges,
          tagRanges: nextRanges,
          selectedTagKeys: state.selectedTagKeys,
          analysis: state.analysis,
        ),
        clearError: true,
      ),
    );
  }

  void setTagVelocity(String tagKey, int layer) {
    final next = Map<String, int>.from(state.tagVelocityLayers)
      ..[tagKey] = layer;
    emit(state.copyWith(tagVelocityLayers: next, clearError: true));
  }

  void setTagRoundRobin(String tagKey, int lane) {
    final next = Map<String, int>.from(state.tagRoundRobins)..[tagKey] = lane;
    emit(state.copyWith(tagRoundRobins: next, clearError: true));
  }

  void setPreserveXmlMapping(bool enabled) {
    emit(state.copyWith(preserveXmlMapping: enabled, clearError: true));
  }

  void setAddUnmapped(bool enabled) {
    emit(state.copyWith(addUnmapped: enabled, clearError: true));
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
          selectedPresetNames: state.selectedPresetNames.toList(),
          selectedGroupKey: state.selectedGroupKey,
          selectedTagKeys: state.selectedTagKeys.toList(),
          groupVelocityLayers: state.groupVelocityLayers,
          groupKeyRanges: state.manualGroupRanges,
          groupRoundRobins: state.groupRoundRobins,
          tagVelocityLayers: state.tagVelocityLayers,
          tagKeyRanges: state.tagKeyRanges,
          tagRoundRobins: state.tagRoundRobins,
          preserveXmlMapping: state.preserveXmlMapping,
          addUnmapped: state.addUnmapped,
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

List<String> _warningsFor({
  required DecentSamplerGroupHandling handling,
  required Map<String, DecentSamplerTagKeyRange> groupRanges,
  required Map<String, DecentSamplerTagKeyRange> tagRanges,
  required Set<String> selectedTagKeys,
  required DecentSamplerImportAnalysis? analysis,
}) {
  final groupNames = {
    for (final group in analysis?.groups ?? const <DecentSamplerGroupInfo>[])
      group.key: group.name,
  };
  final ranges = switch (handling) {
    DecentSamplerGroupHandling.keyRanges => groupRanges,
    DecentSamplerGroupHandling.selectedTags => Map.fromEntries(
      tagRanges.entries.where((entry) => selectedTagKeys.contains(entry.key)),
    ),
    _ => const <String, DecentSamplerTagKeyRange>{},
  };
  if (ranges.isEmpty) return const [];
  final tagNames = {
    for (final tag in analysis?.tags ?? const <DecentSamplerTag>[])
      tag.key: tag.label,
  };
  final names = handling == DecentSamplerGroupHandling.selectedTags
      ? tagNames
      : groupNames;
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
          '${names[a.key] ?? a.key} and ${names[b.key] ?? b.key} '
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
