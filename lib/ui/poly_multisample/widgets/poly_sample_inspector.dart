import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nt_helper/domain/i_disting_midi_manager.dart';
import 'package:nt_helper/poly_multisample/poly_multisample_models.dart';
import 'package:nt_helper/poly_multisample/poly_multisample_parser.dart';
import 'package:nt_helper/ui/poly_multisample/poly_multisample_builder_cubit.dart';
import 'package:nt_helper/ui/poly_multisample/poly_region_math.dart';
import 'package:path/path.dart' as p;

class PolySampleInspector extends StatelessWidget {
  const PolySampleInspector({
    super.key,
    required this.state,
    required this.manager,
  });

  final PolyMultisampleBuilderState state;
  final IDistingMidiManager? manager;

  @override
  Widget build(BuildContext context) {
    final region = selectedRegionFor(state);
    if (region == null) {
      return const Center(child: Text('No sample selected'));
    }
    final cubit = context.read<PolyMultisampleBuilderCubit>();
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _HeaderRow(state: state, region: region, manager: manager),
        const SizedBox(height: 12),
        _PreviewControls(state: state),
        const SizedBox(height: 16),
        _MappingSection(state: state, region: region, cubit: cubit),
        const SizedBox(height: 8),
        _LoopSection(state: state, region: region, cubit: cubit),
      ],
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({
    required this.state,
    required this.region,
    required this.manager,
  });

  final PolyMultisampleBuilderState state;
  final PolySampleRegion region;
  final IDistingMidiManager? manager;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PolyMultisampleBuilderCubit>();
    final index = state.editedRegions.indexWhere(
      (candidate) => candidate.path == region.path,
    );
    final playing = state.previewState.visiblePath == region.path;
    final canPreview = region.path.toLowerCase().endsWith('.wav');
    final canReveal = _isLocalPath(state, region);
    return Row(
      children: [
        IconButton(
          tooltip: 'Previous sample',
          icon: const Icon(Icons.chevron_left),
          onPressed: index > 0
              ? () => cubit.selectRegion(
                  state.editedRegions[index - 1].path,
                  PolyRegionSelectionMode.replace,
                )
              : null,
        ),
        IconButton(
          tooltip: 'Next sample',
          icon: const Icon(Icons.chevron_right),
          onPressed: index >= 0 && index < state.editedRegions.length - 1
              ? () => cubit.selectRegion(
                  state.editedRegions[index + 1].path,
                  PolyRegionSelectionMode.replace,
                )
              : null,
        ),
        Expanded(
          child: Semantics(
            header: true,
            child: Text(
              region.displayName,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
        ),
        IconButton.filledTonal(
          tooltip: playing ? 'Stop preview' : 'Preview sample',
          onPressed: canPreview
              ? () => cubit.playOrStopPreview(region.path, manager: manager)
              : null,
          icon: Icon(playing ? Icons.stop : Icons.play_arrow),
        ),
        IconButton(
          tooltip: 'Reveal in file manager',
          icon: const Icon(Icons.folder_open),
          onPressed: canReveal
              ? () => _revealFolder(context, region.path)
              : null,
        ),
      ],
    );
  }
}

class _PreviewControls extends StatelessWidget {
  const _PreviewControls({required this.state});

  final PolyMultisampleBuilderState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PolyMultisampleBuilderCubit>();
    return Row(
      children: [
        const Text('Auto-preview'),
        Switch(value: state.autoPreview, onChanged: cubit.setAutoPreview),
        const Icon(Icons.volume_down),
        Expanded(
          child: Slider(
            min: -36,
            max: 6,
            divisions: 42,
            value: state.previewGainDb,
            label: '${state.previewGainDb.round()} dB',
            onChanged: cubit.setPreviewGain,
          ),
        ),
        Text('${state.previewGainDb.round()} dB'),
      ],
    );
  }
}

class _MappingSection extends StatelessWidget {
  const _MappingSection({
    required this.state,
    required this.region,
    required this.cubit,
  });

  final PolyMultisampleBuilderState state;
  final PolySampleRegion region;
  final PolyMultisampleBuilderCubit cubit;

  @override
  Widget build(BuildContext context) {
    final root = region.rootMidi ?? 60;
    final low = effectiveLow(region);
    final high = effectiveHigh(region, state.editedRegions);
    final velocity = region.velocityLayer ?? 1;
    final roundRobin = region.roundRobin ?? 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text('Mapping', style: Theme.of(context).textTheme.titleSmall),
        ),
        const SizedBox(height: 8),
        _StepRow(
          label: 'Root',
          value: region.rootMidi == null
              ? 'Unset'
              : PolyMultisampleParser.midiToNoteName(root),
          onMinus: () => cubit.updateRoot(region.path, root - 1),
          onPlus: () => cubit.updateRoot(region.path, root + 1),
        ),
        _StepRow(
          label: 'Low',
          value: PolyMultisampleParser.midiToNoteName(low),
          onMinus: () => cubit.updateRangeLow(region.path, low - 1),
          onPlus: () => cubit.updateRangeLow(region.path, low + 1),
        ),
        _StepRow(
          label: 'High',
          value: PolyMultisampleParser.midiToNoteName(high),
          onMinus: () => cubit.updateRangeHigh(region.path, high - 1),
          onPlus: () => cubit.updateRangeHigh(region.path, high + 1),
        ),
        _StepRow(
          label: 'Velocity',
          value: '$velocity',
          onMinus: () =>
              cubit.updateVelocity(region.path, math.max(1, velocity - 1)),
          onPlus: () => cubit.updateVelocity(region.path, velocity + 1),
        ),
        _StepRow(
          label: 'Round robin',
          value: '$roundRobin',
          onMinus: () =>
              cubit.updateRoundRobin(region.path, math.max(1, roundRobin - 1)),
          onPlus: () => cubit.updateRoundRobin(region.path, roundRobin + 1),
        ),
      ],
    );
  }
}

class _LoopSection extends StatelessWidget {
  const _LoopSection({
    required this.state,
    required this.region,
    required this.cubit,
  });

  final PolyMultisampleBuilderState state;
  final PolySampleRegion region;
  final PolyMultisampleBuilderCubit cubit;

  @override
  Widget build(BuildContext context) {
    final canEdit =
        _isLocalPath(state, region) &&
        region.path.toLowerCase().endsWith('.wav');
    return ExpansionTile(
      title: const Text('Loop points'),
      onExpansionChanged: (expanded) {
        if (expanded &&
            canEdit &&
            state.waveformSummaries[region.path] == null) {
          cubit.loadWaveform(region.path);
        }
      },
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: canEdit
              ? _LoopEditor(state: state, region: region, cubit: cubit)
              : const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Loop editing needs a local or mounted folder.'),
                ),
        ),
      ],
    );
  }
}

class _LoopEditor extends StatelessWidget {
  const _LoopEditor({
    required this.state,
    required this.region,
    required this.cubit,
  });

  final PolyMultisampleBuilderState state;
  final PolySampleRegion region;
  final PolyMultisampleBuilderCubit cubit;

  @override
  Widget build(BuildContext context) {
    final overview = state.waveformSummaries[region.path];
    if (overview == null) {
      return const LinearProgressIndicator();
    }
    final draft =
        state.loopDrafts[region.path] ??
        PolyWaveformDraft(
          loopStart: overview.loopStart,
          loopEnd: overview.loopEnd,
        );
    final loopEnabled = draft.loopStart != null && draft.loopEnd != null;
    final loopChanged =
        draft.loopStart != overview.loopStart ||
        draft.loopEnd != overview.loopEnd;
    final maxFrame = math.max(0, overview.frameCount - 1);
    return Column(
      children: [
        SwitchListTile(
          title: const Text('Loop enabled'),
          value: loopEnabled,
          onChanged: (enabled) {
            cubit.updateLoopDraft(
              region.path,
              enabled
                  ? draft.copyWith(
                      loopStart: overview.loopStart ?? 0,
                      loopEnd: overview.loopEnd ?? maxFrame,
                    )
                  : draft.copyWith(clearLoopStart: true, clearLoopEnd: true),
            );
          },
        ),
        if (loopEnabled) ...[
          _FrameNudgeRow(
            label: 'Loop start',
            value: draft.loopStart ?? 0,
            onNudge: (delta) => cubit.updateLoopDraft(
              region.path,
              draft.copyWith(
                loopStart: ((draft.loopStart ?? 0) + delta)
                    .clamp(0, maxFrame)
                    .toInt(),
              ),
            ),
          ),
          _FrameNudgeRow(
            label: 'Loop end',
            value: draft.loopEnd ?? maxFrame,
            onNudge: (delta) => cubit.updateLoopDraft(
              region.path,
              draft.copyWith(
                loopEnd: ((draft.loopEnd ?? maxFrame) + delta)
                    .clamp(0, maxFrame)
                    .toInt(),
              ),
            ),
          ),
        ],
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton(
            onPressed: loopChanged
                ? () async => cubit.saveLoopMetadata(region.path)
                : null,
            child: const Text('Save loop'),
          ),
        ),
      ],
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.label,
    required this.value,
    required this.onMinus,
    required this.onPlus,
  });

  final String label;
  final String value;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label $value',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: $value'),
          const SizedBox(width: 4),
          IconButton(
            tooltip: 'Decrease $label',
            visualDensity: VisualDensity.compact,
            onPressed: onMinus,
            icon: const Icon(Icons.remove, size: 18),
          ),
          IconButton(
            tooltip: 'Increase $label',
            visualDensity: VisualDensity.compact,
            onPressed: onPlus,
            icon: const Icon(Icons.add, size: 18),
          ),
        ],
      ),
    );
  }
}

class _FrameNudgeRow extends StatelessWidget {
  const _FrameNudgeRow({
    required this.label,
    required this.value,
    required this.onNudge,
  });

  final String label;
  final int value;
  final ValueChanged<int> onNudge;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text('$label: $value')),
        for (final delta in const [-100, -1, 1, 100])
          IconButton(
            tooltip: '$label ${delta.isNegative ? '' : '+'}$delta frames',
            visualDensity: VisualDensity.compact,
            onPressed: () => onNudge(delta),
            icon: Icon(delta.isNegative ? Icons.remove : Icons.add, size: 18),
          ),
      ],
    );
  }
}

bool _isLocalPath(PolyMultisampleBuilderState state, PolySampleRegion region) {
  return !(state.sourceMode == PolySampleSourceMode.hardware &&
      region.path.startsWith('/'));
}

Future<void> _revealFolder(BuildContext context, String path) async {
  try {
    final folder = p.dirname(path);
    if (Platform.isWindows) {
      await Process.run('explorer.exe', [folder]);
    } else if (Platform.isMacOS) {
      await Process.run('open', [folder]);
    } else {
      await Process.run('xdg-open', [folder]);
    }
  } catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Could not open folder: $error')));
  }
}
