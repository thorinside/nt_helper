import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nt_helper/poly_multisample/decent_sampler_converter.dart';
import 'package:nt_helper/poly_multisample/poly_multisample_parser.dart';
import 'package:nt_helper/poly_multisample/poly_multisample_models.dart';
import 'package:nt_helper/ui/poly_multisample/poly_decent_import_cubit.dart';
import 'package:nt_helper/ui/poly_multisample/poly_multisample_builder_cubit.dart';

Future<PolyStagedImport?> showPolyDecentImportDialog(
  BuildContext context, {
  required String sourcePath,
  PolyMultisampleBuilderCubit? previewCubit,
  @visibleForTesting PolyDecentImportCubit? cubit,
}) {
  return showDialog<PolyStagedImport>(
    context: context,
    builder: (context) {
      final provided = cubit;
      if (provided != null) {
        return BlocProvider.value(
          value: provided,
          child: _PolyDecentImportDialog(previewCubit: previewCubit),
        );
      }
      return BlocProvider(
        create: (_) => PolyDecentImportCubit()..analyzeSource(sourcePath),
        child: _PolyDecentImportDialog(previewCubit: previewCubit),
      );
    },
  );
}

class _PolyDecentImportDialog extends StatelessWidget {
  const _PolyDecentImportDialog({required this.previewCubit});

  final PolyMultisampleBuilderCubit? previewCubit;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return BlocBuilder<PolyDecentImportCubit, PolyDecentImportState>(
      builder: (context, state) {
        final cubit = context.read<PolyDecentImportCubit>();
        return AlertDialog(
          title: const Text('Import Decent Sampler'),
          content: SizedBox(
            width: 640,
            height: 560,
            child: _DialogBody(
              state: state,
              cubit: cubit,
              previewCubit: previewCubit,
              colorScheme: colorScheme,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed:
                  state.status == PolyDecentImportStatus.staging ||
                      !state.canContinue
                  ? null
                  : () async {
                      await cubit.continueImport();
                      if (!context.mounted) return;
                      if (cubit.state.status ==
                          PolyDecentImportStatus.completed) {
                        Navigator.of(context).pop(cubit.state.stagedImport);
                      }
                    },
              child: const Text('Import'),
            ),
          ],
        );
      },
    );
  }
}

class _DialogBody extends StatelessWidget {
  const _DialogBody({
    required this.state,
    required this.cubit,
    required this.previewCubit,
    required this.colorScheme,
  });

  final PolyDecentImportState state;
  final PolyDecentImportCubit cubit;
  final PolyMultisampleBuilderCubit? previewCubit;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    switch (state.status) {
      case PolyDecentImportStatus.initial:
      case PolyDecentImportStatus.analyzing:
        return Semantics(
          liveRegion: true,
          child: const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 12),
                Text('Analyzing Decent source…'),
              ],
            ),
          ),
        );
      case PolyDecentImportStatus.failure:
        return Text(state.error ?? 'Analysis failed.');
      case PolyDecentImportStatus.ready:
      case PolyDecentImportStatus.staging:
      case PolyDecentImportStatus.completed:
        final analysis = state.analysis;
        if (analysis == null) return const Text('Analysis failed.');
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(analysis.structureSummary),
              const SizedBox(height: 12),
              if (analysis.presets.length > 1) ...[
                Semantics(
                  header: true,
                  child: Text(
                    'Presets',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                for (final preset in analysis.presets)
                  CheckboxListTile(
                    dense: true,
                    title: Text(preset.name),
                    subtitle: Text(
                      '${preset.groupCount} groups, ${preset.sampleCount} samples',
                    ),
                    value: state.selectedPresetNames.contains(preset.name),
                    onChanged: (_) => cubit.togglePreset(preset.name),
                  ),
                const SizedBox(height: 12),
              ],
              Text(
                'Group handling',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              RadioGroup<DecentSamplerGroupHandling>(
                groupValue: state.groupHandling,
                onChanged: (value) {
                  if (value != null) cubit.setGroupHandling(value);
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final handling in DecentSamplerGroupHandling.values)
                      RadioListTile<DecentSamplerGroupHandling>(
                        dense: true,
                        value: handling,
                        title: Text(_handlingLabel(handling)),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              _ModeEditor(
                state: state,
                analysis: analysis,
                cubit: cubit,
                previewCubit: previewCubit,
              ),
              SwitchListTile(
                title: const Text('Preserve XML mapping'),
                value: state.preserveXmlMapping,
                onChanged: cubit.setPreserveXmlMapping,
              ),
              SwitchListTile(
                title: const Text('Include unmapped samples'),
                value: state.addUnmapped,
                onChanged: cubit.setAddUnmapped,
              ),
              if (state.warnings.isNotEmpty)
                Semantics(
                  liveRegion: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final warning in state.warnings)
                        Text(
                          warning,
                          style: TextStyle(color: colorScheme.error),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        );
    }
  }
}

class _ModeEditor extends StatelessWidget {
  const _ModeEditor({
    required this.state,
    required this.analysis,
    required this.cubit,
    required this.previewCubit,
  });

  final PolyDecentImportState state;
  final DecentSamplerImportAnalysis analysis;
  final PolyDecentImportCubit cubit;
  final PolyMultisampleBuilderCubit? previewCubit;

  @override
  Widget build(BuildContext context) {
    return switch (state.groupHandling) {
      DecentSamplerGroupHandling.velocityLayers => Column(
        children: [
          for (final group in analysis.groups)
            _GroupRow(
              group: group,
              previewCubit: previewCubit,
              trailing: _IntStepper(
                label: 'Velocity',
                value:
                    state.groupVelocityLayers[group.key] ??
                    group.defaultVelocityLayer,
                onChanged: (value) => cubit.setGroupVelocity(group.key, value),
              ),
            ),
        ],
      ),
      DecentSamplerGroupHandling.keyRanges => Column(
        children: [
          for (final group in analysis.groups)
            _GroupRangeRow(
              group: group,
              state: state,
              cubit: cubit,
              previewCubit: previewCubit,
            ),
        ],
      ),
      DecentSamplerGroupHandling.selectedGroup => RadioGroup<String?>(
        groupValue: state.selectedGroupKey,
        onChanged: cubit.setSelectedGroup,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final group in analysis.groups)
              RadioListTile<String?>(
                dense: true,
                value: group.key,
                title: Text(group.name),
                subtitle: Text(group.structureSummary),
              ),
          ],
        ),
      ),
      DecentSamplerGroupHandling.selectedTags ||
      DecentSamplerGroupHandling.tagMapping => Column(
        children: [
          for (final tag in analysis.tags)
            _TagRow(
              tag: tag,
              state: state,
              cubit: cubit,
              previewCubit: previewCubit,
            ),
        ],
      ),
      DecentSamplerGroupHandling.auto ||
      DecentSamplerGroupHandling.splitFolders => const Align(
        alignment: Alignment.centerLeft,
        child: Text('No further options.'),
      ),
    };
  }
}

class _GroupRow extends StatelessWidget {
  const _GroupRow({
    required this.group,
    required this.previewCubit,
    required this.trailing,
  });

  final DecentSamplerGroupInfo group;
  final PolyMultisampleBuilderCubit? previewCubit;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(group.name)),
        _PreviewButton(
          path: group.previewSourcePath,
          previewCubit: previewCubit,
        ),
        trailing,
      ],
    );
  }
}

class _GroupRangeRow extends StatelessWidget {
  const _GroupRangeRow({
    required this.group,
    required this.state,
    required this.cubit,
    required this.previewCubit,
  });

  final DecentSamplerGroupInfo group;
  final PolyDecentImportState state;
  final PolyDecentImportCubit cubit;
  final PolyMultisampleBuilderCubit? previewCubit;

  @override
  Widget build(BuildContext context) {
    final range =
        state.manualGroupRanges[group.key] ??
        DecentSamplerTagKeyRange(
          lowMidi: group.defaultLowMidi,
          rootMidi: group.defaultRootMidi,
          highMidi: group.defaultHighMidi,
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Checkbox(
              value: range.enabled,
              onChanged: (enabled) => cubit.updateGroupRange(
                group.key,
                _rangeWith(range, enabled: enabled ?? true),
              ),
            ),
            Expanded(child: Text(group.name)),
            _PreviewButton(
              path: group.previewSourcePath,
              previewCubit: previewCubit,
            ),
          ],
        ),
        Wrap(
          spacing: 8,
          children: [
            _NoteStepper(
              label: 'Low',
              value: range.lowMidi,
              onChanged: (value) => cubit.updateGroupRange(
                group.key,
                _rangeWith(range, lowMidi: value),
              ),
            ),
            _NoteStepper(
              label: 'Root',
              value: range.rootMidi,
              onChanged: (value) => cubit.updateGroupRange(
                group.key,
                _rangeWith(range, rootMidi: value),
              ),
            ),
            _NoteStepper(
              label: 'High',
              value: range.highMidi,
              onChanged: (value) => cubit.updateGroupRange(
                group.key,
                _rangeWith(range, highMidi: value),
              ),
            ),
            _IntStepper(
              label: 'RR',
              value: state.groupRoundRobins[group.key] ?? 1,
              onChanged: (value) => cubit.setGroupRoundRobin(group.key, value),
            ),
          ],
        ),
      ],
    );
  }
}

class _TagRow extends StatelessWidget {
  const _TagRow({
    required this.tag,
    required this.state,
    required this.cubit,
    required this.previewCubit,
  });

  final DecentSamplerTag tag;
  final PolyDecentImportState state;
  final PolyDecentImportCubit cubit;
  final PolyMultisampleBuilderCubit? previewCubit;

  @override
  Widget build(BuildContext context) {
    final selected = state.selectedTagKeys.contains(tag.key);
    final range =
        state.tagKeyRanges[tag.key] ??
        DecentSamplerTagKeyRange(
          lowMidi: tag.defaultLowMidi,
          rootMidi: tag.defaultRootMidi,
          highMidi: tag.defaultHighMidi,
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CheckboxListTile(
          dense: true,
          title: Text(tag.label),
          subtitle: Text('${tag.sampleCount} samples  ${tag.noteRange}'),
          value: selected,
          secondary: _PreviewButton(
            path: tag.previewSourcePath,
            previewCubit: previewCubit,
          ),
          onChanged: (_) => cubit.toggleTag(tag.key),
        ),
        if (selected &&
            state.groupHandling == DecentSamplerGroupHandling.selectedTags)
          Padding(
            padding: const EdgeInsets.only(left: 32),
            child: Wrap(
              spacing: 8,
              children: [
                _NoteStepper(
                  label: 'Low',
                  value: range.lowMidi,
                  onChanged: (value) => cubit.setTagRange(
                    tag.key,
                    _rangeWith(range, lowMidi: value),
                  ),
                ),
                _NoteStepper(
                  label: 'Root',
                  value: range.rootMidi,
                  onChanged: (value) => cubit.setTagRange(
                    tag.key,
                    _rangeWith(range, rootMidi: value),
                  ),
                ),
                _NoteStepper(
                  label: 'High',
                  value: range.highMidi,
                  onChanged: (value) => cubit.setTagRange(
                    tag.key,
                    _rangeWith(range, highMidi: value),
                  ),
                ),
                _IntStepper(
                  label: 'Velocity',
                  value:
                      state.tagVelocityLayers[tag.key] ??
                      tag.defaultVelocityLayer,
                  onChanged: (value) => cubit.setTagVelocity(tag.key, value),
                ),
                _IntStepper(
                  label: 'RR',
                  value: state.tagRoundRobins[tag.key] ?? 1,
                  onChanged: (value) => cubit.setTagRoundRobin(tag.key, value),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _PreviewButton extends StatelessWidget {
  const _PreviewButton({required this.path, required this.previewCubit});

  final String? path;
  final PolyMultisampleBuilderCubit? previewCubit;

  @override
  Widget build(BuildContext context) {
    final cubit = previewCubit;
    final samplePath = path;
    if (cubit == null || samplePath == null) return const SizedBox.shrink();
    final playing = cubit.state.previewState.visiblePath == samplePath;
    return IconButton(
      tooltip: playing ? 'Stop preview' : 'Preview sample',
      icon: Icon(playing ? Icons.stop : Icons.play_arrow),
      onPressed: () => cubit.playOrStopPreview(samplePath),
    );
  }
}

class _NoteStepper extends StatelessWidget {
  const _NoteStepper({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$label: ${PolyMultisampleParser.midiToNoteName(value)}'),
        IconButton(
          tooltip: 'Decrease $label',
          visualDensity: VisualDensity.compact,
          onPressed: () => onChanged((value - 1).clamp(0, 127).toInt()),
          icon: const Icon(Icons.remove, size: 18),
        ),
        IconButton(
          tooltip: 'Increase $label',
          visualDensity: VisualDensity.compact,
          onPressed: () => onChanged((value + 1).clamp(0, 127).toInt()),
          icon: const Icon(Icons.add, size: 18),
        ),
      ],
    );
  }
}

class _IntStepper extends StatelessWidget {
  const _IntStepper({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$label: $value'),
        IconButton(
          tooltip: 'Decrease $label',
          visualDensity: VisualDensity.compact,
          onPressed: () => onChanged(math.max(1, value - 1)),
          icon: const Icon(Icons.remove, size: 18),
        ),
        IconButton(
          tooltip: 'Increase $label',
          visualDensity: VisualDensity.compact,
          onPressed: () => onChanged(value + 1),
          icon: const Icon(Icons.add, size: 18),
        ),
      ],
    );
  }
}

String _handlingLabel(DecentSamplerGroupHandling handling) {
  return switch (handling) {
    DecentSamplerGroupHandling.auto => 'Automatic (recommended)',
    DecentSamplerGroupHandling.tagMapping => 'Map groups by tags',
    DecentSamplerGroupHandling.velocityLayers => 'Groups as velocity layers',
    DecentSamplerGroupHandling.keyRanges => 'Groups as manual key ranges',
    DecentSamplerGroupHandling.splitFolders =>
      'Split groups into separate folders',
    DecentSamplerGroupHandling.selectedGroup => 'Import one group only',
    DecentSamplerGroupHandling.selectedTags => 'Import selected tags only',
  };
}

DecentSamplerTagKeyRange _rangeWith(
  DecentSamplerTagKeyRange range, {
  int? lowMidi,
  int? rootMidi,
  int? highMidi,
  bool? enabled,
}) {
  return DecentSamplerTagKeyRange(
    lowMidi: lowMidi ?? range.lowMidi,
    rootMidi: rootMidi ?? range.rootMidi,
    highMidi: highMidi ?? range.highMidi,
    enabled: enabled ?? range.enabled,
  );
}
