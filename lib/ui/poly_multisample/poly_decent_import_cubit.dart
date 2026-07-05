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
    this.editedTagRangeKeys = const {},
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
  final Set<String> editedTagRangeKeys;
  final Map<String, int> tagVelocityLayers;
  final Map<String, int> tagRoundRobins;
  final bool preserveXmlMapping;
  final bool addUnmapped;
  final List<String> warnings;
  final String? error;
  final PolyStagedImport? stagedImport;

  bool get canContinue {
    if (status != PolyDecentImportStatus.ready || warnings.isNotEmpty) {
      return false;
    }
    if ((analysis?.presets.length ?? 0) > 1 && selectedPresetNames.isEmpty) {
      return false;
    }
    if (groupHandling == DecentSamplerGroupHandling.selectedGroup &&
        selectedGroupKey == null) {
      return false;
    }
    if ((groupHandling == DecentSamplerGroupHandling.selectedTags ||
            groupHandling == DecentSamplerGroupHandling.tagMapping) &&
        selectedTagKeys.isEmpty) {
      return false;
    }
    if (groupHandling == DecentSamplerGroupHandling.keyRanges &&
        !_hasEnabledRanges(manualGroupRanges.values)) {
      return false;
    }
    return true;
  }

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
    Set<String>? editedTagRangeKeys,
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
      editedTagRangeKeys: editedTagRangeKeys ?? this.editedTagRangeKeys,
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
      final selectedGroupKey =
          handling == DecentSamplerGroupHandling.selectedGroup
          ? analysis.groups.firstOrNull?.key
          : null;
      emit(
        state.copyWith(
          status: PolyDecentImportStatus.ready,
          analysis: analysis,
          groupHandling: handling,
          manualGroupRanges: ranges,
          tagKeyRanges: tagRanges,
          editedTagRangeKeys: const {},
          selectedGroupKey: selectedGroupKey,
          clearSelectedGroupKey: selectedGroupKey == null,
          selectedPresetNames: {
            for (final preset in analysis.presets) preset.name,
          },
          warnings: _warningsFor(
            handling: handling,
            groupRanges: ranges,
            tagRanges: tagRanges,
            editedTagRangeKeys: const {},
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
    final selectedGroupKey =
        handling == DecentSamplerGroupHandling.selectedGroup
        ? state.selectedGroupKey ?? state.analysis?.groups.firstOrNull?.key
        : null;
    final warnings = _warningsFor(
      handling: handling,
      groupRanges: state.manualGroupRanges,
      tagRanges: state.tagKeyRanges,
      editedTagRangeKeys: state.editedTagRangeKeys,
      selectedTagKeys: state.selectedTagKeys,
      analysis: state.analysis,
    );
    emit(
      state.copyWith(
        groupHandling: handling,
        selectedGroupKey: selectedGroupKey,
        clearSelectedGroupKey:
            handling != DecentSamplerGroupHandling.selectedGroup,
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
          editedTagRangeKeys: state.editedTagRangeKeys,
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
          editedTagRangeKeys: state.editedTagRangeKeys,
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
    final nextRanges =
        Map<String, DecentSamplerTagKeyRange>.from(state.tagKeyRanges)
          ..[tagKey] = DecentSamplerTagKeyRange(
            lowMidi: range.lowMidi,
            rootMidi: range.rootMidi,
            highMidi: range.highMidi,
            enabled: true,
          );
    final nextEditedKeys = {...state.editedTagRangeKeys, tagKey};
    emit(
      state.copyWith(
        tagKeyRanges: nextRanges,
        editedTagRangeKeys: nextEditedKeys,
        warnings: _warningsFor(
          handling: state.groupHandling,
          groupRanges: state.manualGroupRanges,
          tagRanges: nextRanges,
          editedTagRangeKeys: nextEditedKeys,
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
          selectedGroupKeys: _selectedGroupKeysForOptions(state),
          selectedTagKeys: _usesTagOptions(state.groupHandling)
              ? state.selectedTagKeys.toList()
              : const [],
          groupVelocityLayers: _groupVelocityLayersForOptions(state),
          groupKeyRanges: state.manualGroupRanges,
          groupRoundRobins:
              state.groupHandling == DecentSamplerGroupHandling.keyRanges
              ? state.groupRoundRobins
              : const {},
          tagVelocityLayers: _usesTagOptions(state.groupHandling)
              ? state.tagVelocityLayers
              : const {},
          tagKeyRanges: _usesTagOptions(state.groupHandling)
              ? _tagKeyRangesForOptions(state)
              : const {},
          tagRoundRobins: _usesTagOptions(state.groupHandling)
              ? state.tagRoundRobins
              : const {},
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

bool _usesTagOptions(DecentSamplerGroupHandling handling) {
  return handling == DecentSamplerGroupHandling.tagMapping ||
      handling == DecentSamplerGroupHandling.selectedTags;
}

List<String> _selectedGroupKeysForOptions(PolyDecentImportState state) {
  final groups = state.analysis?.groups ?? const <DecentSamplerGroupInfo>[];
  switch (state.groupHandling) {
    case DecentSamplerGroupHandling.velocityLayers:
      return [for (final group in groups) group.key];
    case DecentSamplerGroupHandling.keyRanges:
      return [
        for (final group in groups)
          if (state.manualGroupRanges[group.key]?.enabled ?? false) group.key,
      ];
    case DecentSamplerGroupHandling.auto:
    case DecentSamplerGroupHandling.tagMapping:
    case DecentSamplerGroupHandling.splitFolders:
    case DecentSamplerGroupHandling.selectedGroup:
    case DecentSamplerGroupHandling.selectedTags:
      return const [];
  }
}

Map<String, DecentSamplerTagKeyRange> _tagKeyRangesForOptions(
  PolyDecentImportState state,
) {
  final selected = state.selectedTagKeys;
  if (state.groupHandling == DecentSamplerGroupHandling.selectedTags) {
    return {
      for (final entry in state.tagKeyRanges.entries)
        if (selected.contains(entry.key)) entry.key: entry.value,
    };
  }
  if (state.groupHandling == DecentSamplerGroupHandling.tagMapping) {
    return {
      for (final entry in state.tagKeyRanges.entries)
        if (selected.contains(entry.key) &&
            state.editedTagRangeKeys.contains(entry.key))
          entry.key: entry.value,
    };
  }
  return const {};
}

Map<String, int> _groupVelocityLayersForOptions(PolyDecentImportState state) {
  return state.groupHandling == DecentSamplerGroupHandling.velocityLayers
      ? state.groupVelocityLayers
      : const {};
}

bool _hasEnabledRanges(Iterable<DecentSamplerTagKeyRange> ranges) {
  return ranges.any((range) => range.enabled);
}

List<String> _warningsFor({
  required DecentSamplerGroupHandling handling,
  required Map<String, DecentSamplerTagKeyRange> groupRanges,
  required Map<String, DecentSamplerTagKeyRange> tagRanges,
  required Set<String> editedTagRangeKeys,
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
    DecentSamplerGroupHandling.tagMapping => Map.fromEntries(
      tagRanges.entries.where(
        (entry) =>
            selectedTagKeys.contains(entry.key) &&
            editedTagRangeKeys.contains(entry.key),
      ),
    ),
    _ => const <String, DecentSamplerTagKeyRange>{},
  };
  if (ranges.isEmpty) return const [];
  final tagNames = {
    for (final tag in analysis?.tags ?? const <DecentSamplerTag>[])
      tag.key: tag.label,
  };
  final names =
      handling == DecentSamplerGroupHandling.selectedTags ||
          handling == DecentSamplerGroupHandling.tagMapping
      ? tagNames
      : groupNames;
  final warnings = <String>[];
  final entries = ranges.entries
      .where((entry) => entry.value.enabled)
      .toList(growable: false);
  for (final entry in entries) {
    final range = entry.value;
    final name = names[entry.key] ?? entry.key;
    if (range.lowMidi > range.highMidi) {
      warnings.add('$name has an invalid key range.');
    } else if (range.rootMidi < range.lowMidi ||
        range.rootMidi > range.highMidi) {
      warnings.add('$name root note is outside the key range.');
    }
  }
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
