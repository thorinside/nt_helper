import 'dart:io';
import 'dart:math' as math;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nt_helper/domain/i_disting_midi_manager.dart';
import 'package:nt_helper/poly_multisample/poly_multisample_models.dart';
import 'package:nt_helper/poly_multisample/poly_multisample_parser.dart';
import 'package:nt_helper/poly_multisample/wav_metadata.dart';
import 'package:nt_helper/ui/poly_multisample/poly_multisample_builder_cubit.dart';
import 'package:nt_helper/ui/poly_multisample/poly_region_math.dart';
import 'package:nt_helper/ui/poly_multisample/widgets/poly_waveform_editor.dart';
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _HeaderRow(state: state, region: region, manager: manager),
          const SizedBox(height: 12),
          _PreviewControls(state: state),
          const SizedBox(height: 16),
          _MappingSection(state: state, region: region, cubit: cubit),
          const SizedBox(height: 8),
          _LoopSection(state: state, region: region, cubit: cubit),
          const SizedBox(height: 8),
          _EditAudioSection(state: state, region: region, cubit: cubit),
        ],
      ),
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

class _EditAudioSection extends StatelessWidget {
  const _EditAudioSection({
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
      title: const Text('Edit audio'),
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
              ? _EditAudioEditor(state: state, region: region, cubit: cubit)
              : const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Audio editing needs a local or mounted folder.'),
                ),
        ),
      ],
    );
  }
}

class _EditAudioEditor extends StatelessWidget {
  const _EditAudioEditor({
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
        state.wavEditDrafts[region.path] ??
        PolyWaveformDraft(trimStart: 0, trimEnd: overview.frameCount - 1);
    final maxFrame = math.max(0, overview.frameCount - 1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PolyWaveformEditor(
          overview: overview,
          mode: PolyWaveformEditorMode.trim,
          startFrame: draft.trimStart ?? 0,
          endFrame: draft.trimEnd ?? maxFrame,
          onChanged: (start, end) {
            cubit.updateWavEditDraft(
              region.path,
              draft.copyWith(trimStart: start, trimEnd: end),
            );
          },
        ),
        _FrameNudgeRow(
          label: 'Trim start',
          value: draft.trimStart ?? 0,
          onNudge: (delta) => cubit.updateWavEditDraft(
            region.path,
            draft.copyWith(
              trimStart: ((draft.trimStart ?? 0) + delta)
                  .clamp(0, maxFrame)
                  .toInt(),
            ),
          ),
        ),
        _FrameNudgeRow(
          label: 'Trim end',
          value: draft.trimEnd ?? maxFrame,
          onNudge: (delta) => cubit.updateWavEditDraft(
            region.path,
            draft.copyWith(
              trimEnd: ((draft.trimEnd ?? maxFrame) + delta)
                  .clamp(0, maxFrame)
                  .toInt(),
            ),
          ),
        ),
        _FadeRow(
          label: 'Fade in',
          overview: overview,
          frames: draft.fadeInFrames,
          curve: draft.fadeInCurve,
          strength: draft.fadeInStrength,
          onFramesChanged: (frames) => cubit.updateWavEditDraft(
            region.path,
            draft.copyWith(fadeInFrames: frames),
          ),
          onCurveChanged: (curve) => cubit.updateWavEditDraft(
            region.path,
            draft.copyWith(fadeInCurve: curve),
          ),
          onStrengthChanged: (strength) => cubit.updateWavEditDraft(
            region.path,
            draft.copyWith(fadeInStrength: strength),
          ),
        ),
        _FadeRow(
          label: 'Fade out',
          overview: overview,
          frames: draft.fadeOutFrames,
          curve: draft.fadeOutCurve,
          strength: draft.fadeOutStrength,
          onFramesChanged: (frames) => cubit.updateWavEditDraft(
            region.path,
            draft.copyWith(fadeOutFrames: frames),
          ),
          onCurveChanged: (curve) => cubit.updateWavEditDraft(
            region.path,
            draft.copyWith(fadeOutCurve: curve),
          ),
          onStrengthChanged: (strength) => cubit.updateWavEditDraft(
            region.path,
            draft.copyWith(fadeOutStrength: strength),
          ),
        ),
        Row(
          children: [
            const SizedBox(width: 92, child: Text('Gain')),
            Expanded(
              child: Slider(
                key: const ValueKey('poly-wav-gain-slider'),
                min: -24,
                max: 24,
                divisions: 96,
                value: draft.gainDb,
                label: '${draft.gainDb.toStringAsFixed(1)} dB',
                onChanged: (value) => cubit.updateWavEditDraft(
                  region.path,
                  draft.copyWith(gainDb: value),
                ),
              ),
            ),
            SizedBox(
              width: 56,
              child: Text('${draft.gainDb.toStringAsFixed(1)} dB'),
            ),
          ],
        ),
        Row(
          children: [
            const Text('Normalize'),
            Switch(
              value: draft.normalizePeakDb != null,
              onChanged: (enabled) => cubit.updateWavEditDraft(
                region.path,
                enabled
                    ? draft.copyWith(normalizePeakDb: -0.3)
                    : draft.copyWith(clearNormalize: true),
              ),
            ),
            Expanded(
              child: Slider(
                min: -24,
                max: 0,
                divisions: 48,
                value: draft.normalizePeakDb ?? -0.3,
                onChanged: draft.normalizePeakDb == null
                    ? null
                    : (value) => cubit.updateWavEditDraft(
                        region.path,
                        draft.copyWith(normalizePeakDb: value),
                      ),
              ),
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            OutlinedButton(
              onPressed: () async {
                final target = await FilePicker.saveFile(
                  dialogTitle: 'Save edited WAV as',
                  fileName: p.basename(region.path),
                  initialDirectory: state.lastWavExportFolder,
                  type: FileType.custom,
                  allowedExtensions: const ['wav'],
                );
                if (target == null) return;
                await cubit.saveDestructiveWav(region.path, target, true);
              },
              child: const Text('Save as…'),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: Text('Overwrite ${p.basename(region.path)}?'),
                      content: const Text(
                        'This permanently changes the audio file.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('Overwrite'),
                        ),
                      ],
                    );
                  },
                );
                if (confirmed != true) return;
                await cubit.saveDestructiveWav(region.path, region.path, true);
                await cubit.loadWaveform(region.path);
              },
              child: const Text('Overwrite'),
            ),
          ],
        ),
      ],
    );
  }
}

class _FadeRow extends StatelessWidget {
  const _FadeRow({
    required this.label,
    required this.overview,
    required this.frames,
    required this.curve,
    required this.strength,
    required this.onFramesChanged,
    required this.onCurveChanged,
    required this.onStrengthChanged,
  });

  final String label;
  final WavOverview overview;
  final int frames;
  final WavFadeCurve curve;
  final double strength;
  final ValueChanged<int> onFramesChanged;
  final ValueChanged<WavFadeCurve> onCurveChanged;
  final ValueChanged<double> onStrengthChanged;

  @override
  Widget build(BuildContext context) {
    final ms = overview.sampleRate <= 0
        ? 0.0
        : frames / overview.sampleRate * 1000;
    return Row(
      children: [
        SizedBox(width: 92, child: Text(label)),
        Expanded(
          child: Slider(
            min: 0,
            max: 5000,
            divisions: 100,
            value: ms.clamp(0, 5000).toDouble(),
            onChanged: (value) {
              onFramesChanged((value / 1000 * overview.sampleRate).round());
            },
          ),
        ),
        DropdownButton<WavFadeCurve>(
          value: curve,
          items: [
            for (final value in WavFadeCurve.values)
              DropdownMenuItem(value: value, child: Text(_curveLabel(value))),
          ],
          onChanged: (value) {
            if (value != null) onCurveChanged(value);
          },
        ),
        SizedBox(
          width: 120,
          child: Slider(
            min: 0,
            max: 1,
            divisions: 20,
            value: strength,
            onChanged: onStrengthChanged,
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

String _curveLabel(WavFadeCurve curve) {
  return switch (curve) {
    WavFadeCurve.linear => 'Linear',
    WavFadeCurve.equalPower => 'Equal power',
    WavFadeCurve.exponential => 'Exponential',
    WavFadeCurve.sCurve => 'S-curve',
  };
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
