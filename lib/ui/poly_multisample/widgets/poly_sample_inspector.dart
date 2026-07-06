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
import 'package:nt_helper/ui/widgets/split_stepper_control.dart';
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
          _WaveformSection(state: state, region: region, cubit: cubit),
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
    final label = sampleDisplayLabel(region, state.editedRegions);
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
                  manager: manager,
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
                  manager: manager,
                )
              : null,
        ),
        Expanded(
          child: Semantics(
            header: true,
            child: Text(
              label,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          title: const Text('Auto-preview'),
          value: state.autoPreview,
          onChanged: cubit.setAutoPreview,
        ),
        Row(
          children: [
            const Icon(Icons.volume_down),
            Expanded(
              child: Semantics(
                label: 'Preview gain',
                value: '${state.previewGainDb.round()} dB',
                child: Slider(
                  min: -36,
                  max: 6,
                  divisions: 42,
                  value: state.previewGainDb,
                  label: '${state.previewGainDb.round()} dB',
                  semanticFormatterCallback: (value) => '${value.round()} dB',
                  onChanged: cubit.setPreviewGain,
                ),
              ),
            ),
            Text('${state.previewGainDb.round()} dB'),
          ],
        ),
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

class _WaveformSection extends StatelessWidget {
  const _WaveformSection({
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
    if (!canEdit) {
      return const Align(
        alignment: Alignment.centerLeft,
        child: Text('Waveform editing needs a local or mounted WAV file.'),
      );
    }
    final overview = state.waveformSummaries[region.path];
    final loading = state.waveformLoadingPaths.contains(region.path);
    final failed = state.waveformFailedPaths.contains(region.path);
    if (overview == null) {
      if (!loading && !failed) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          cubit.loadWaveform(region.path);
        });
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(
              'Waveform',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          const SizedBox(height: 8),
          Text('Editing ${sampleDisplayLabel(region, state.editedRegions)}'),
          const SizedBox(height: 8),
          if (failed)
            Semantics(
              liveRegion: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Waveform loading failed.'),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () => cubit.loadWaveform(region.path),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry waveform'),
                  ),
                ],
              ),
            )
          else
            Semantics(
              liveRegion: true,
              child: const Text('Loading waveform...'),
            ),
        ],
      );
    }

    final loopDraft =
        state.loopDrafts[region.path] ??
        PolyWaveformDraft(
          loopStart: overview.loopStart,
          loopEnd: overview.loopEnd,
        );
    final wavDraft =
        state.wavEditDrafts[region.path] ??
        PolyWaveformDraft(trimStart: 0, trimEnd: overview.frameCount - 1);
    final maxFrame = math.max(0, overview.frameCount - 1);
    final loopChanged =
        loopDraft.loopStart != overview.loopStart ||
        loopDraft.loopEnd != overview.loopEnd;
    final label = sampleDisplayLabel(region, state.editedRegions);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            'Waveform',
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        const SizedBox(height: 8),
        Text('Editing $label', overflow: TextOverflow.ellipsis),
        const SizedBox(height: 8),
        Tooltip(
          message:
              'Click to set trim start/end. Command/Ctrl-click or right-click to set loop start/end.',
          child: PolyWaveformEditor(
            overview: overview,
            mode: PolyWaveformEditorMode.trim,
            startFrame: wavDraft.trimStart ?? 0,
            endFrame: wavDraft.trimEnd ?? maxFrame,
            loopStartFrame: loopDraft.loopStart,
            loopEndFrame: loopDraft.loopEnd,
            onChanged: (start, end) {
              cubit.updateWavEditDraft(
                region.path,
                wavDraft.copyWith(trimStart: start, trimEnd: end),
              );
            },
            onLoopChanged: (start, end) {
              cubit.updateLoopDraft(
                region.path,
                loopDraft.copyWith(loopStart: start, loopEnd: end),
              );
            },
          ),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          title: const Text('Loop enabled'),
          value: loopDraft.loopStart != null && loopDraft.loopEnd != null,
          onChanged: (enabled) {
            cubit.updateLoopDraft(
              region.path,
              enabled
                  ? loopDraft.copyWith(
                      loopStart: loopDraft.loopStart ?? 0,
                      loopEnd: loopDraft.loopEnd ?? maxFrame,
                    )
                  : loopDraft.copyWith(
                      clearLoopStart: true,
                      clearLoopEnd: true,
                    ),
            );
          },
        ),
        if (loopDraft.loopStart != null && loopDraft.loopEnd != null) ...[
          _FrameNudgeRow(
            label: 'Loop start',
            value: loopDraft.loopStart ?? 0,
            onNudge: (delta) => cubit.updateLoopDraft(
              region.path,
              loopDraft.copyWith(
                loopStart: ((loopDraft.loopStart ?? 0) + delta)
                    .clamp(0, math.max(0, (loopDraft.loopEnd ?? maxFrame) - 1))
                    .toInt(),
              ),
            ),
          ),
          _FrameNudgeRow(
            label: 'Loop end',
            value: loopDraft.loopEnd ?? maxFrame,
            onNudge: (delta) => cubit.updateLoopDraft(
              region.path,
              loopDraft.copyWith(
                loopEnd: ((loopDraft.loopEnd ?? maxFrame) + delta)
                    .clamp(
                      math.min(maxFrame, (loopDraft.loopStart ?? 0) + 1),
                      maxFrame,
                    )
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
        _FrameNudgeRow(
          label: 'Trim start',
          value: wavDraft.trimStart ?? 0,
          onNudge: (delta) => cubit.updateWavEditDraft(
            region.path,
            wavDraft.copyWith(
              trimStart: ((wavDraft.trimStart ?? 0) + delta)
                  .clamp(0, math.max(0, (wavDraft.trimEnd ?? maxFrame) - 1))
                  .toInt(),
            ),
          ),
        ),
        _FrameNudgeRow(
          label: 'Trim end',
          value: wavDraft.trimEnd ?? maxFrame,
          onNudge: (delta) => cubit.updateWavEditDraft(
            region.path,
            wavDraft.copyWith(
              trimEnd: ((wavDraft.trimEnd ?? maxFrame) + delta)
                  .clamp(
                    math.min(maxFrame, (wavDraft.trimStart ?? 0) + 1),
                    maxFrame,
                  )
                  .toInt(),
            ),
          ),
        ),
        _FadeRow(
          label: 'Fade in',
          overview: overview,
          frames: wavDraft.fadeInFrames,
          curve: wavDraft.fadeInCurve,
          strength: wavDraft.fadeInStrength,
          onFramesChanged: (frames) => cubit.updateWavEditDraft(
            region.path,
            wavDraft.copyWith(fadeInFrames: frames),
          ),
          onCurveChanged: (curve) => cubit.updateWavEditDraft(
            region.path,
            wavDraft.copyWith(fadeInCurve: curve),
          ),
          onStrengthChanged: (strength) => cubit.updateWavEditDraft(
            region.path,
            wavDraft.copyWith(fadeInStrength: strength),
          ),
        ),
        _FadeRow(
          label: 'Fade out',
          overview: overview,
          frames: wavDraft.fadeOutFrames,
          curve: wavDraft.fadeOutCurve,
          strength: wavDraft.fadeOutStrength,
          onFramesChanged: (frames) => cubit.updateWavEditDraft(
            region.path,
            wavDraft.copyWith(fadeOutFrames: frames),
          ),
          onCurveChanged: (curve) => cubit.updateWavEditDraft(
            region.path,
            wavDraft.copyWith(fadeOutCurve: curve),
          ),
          onStrengthChanged: (strength) => cubit.updateWavEditDraft(
            region.path,
            wavDraft.copyWith(fadeOutStrength: strength),
          ),
        ),
        Row(
          children: [
            const SizedBox(width: 92, child: Text('Gain')),
            Expanded(
              child: Semantics(
                label: 'Audio gain',
                value: '${wavDraft.gainDb.toStringAsFixed(1)} dB',
                child: Slider(
                  key: const ValueKey('poly-wav-gain-slider'),
                  min: -24,
                  max: 24,
                  divisions: 96,
                  value: wavDraft.gainDb,
                  label: '${wavDraft.gainDb.toStringAsFixed(1)} dB',
                  semanticFormatterCallback: (value) =>
                      '${value.toStringAsFixed(1)} dB',
                  onChanged: (value) => cubit.updateWavEditDraft(
                    region.path,
                    wavDraft.copyWith(gainDb: value),
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 56,
              child: Text('${wavDraft.gainDb.toStringAsFixed(1)} dB'),
            ),
          ],
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          title: const Text('Normalize'),
          value: wavDraft.normalizePeakDb != null,
          onChanged: (enabled) => cubit.updateWavEditDraft(
            region.path,
            enabled
                ? wavDraft.copyWith(normalizePeakDb: -0.3)
                : wavDraft.copyWith(clearNormalize: true),
          ),
        ),
        Row(
          children: [
            const SizedBox(width: 92, child: Text('Peak')),
            Expanded(
              child: Semantics(
                label: 'Normalize peak',
                value:
                    '${(wavDraft.normalizePeakDb ?? -0.3).toStringAsFixed(1)} dB',
                child: Slider(
                  min: -24,
                  max: 0,
                  divisions: 48,
                  value: wavDraft.normalizePeakDb ?? -0.3,
                  label:
                      '${(wavDraft.normalizePeakDb ?? -0.3).toStringAsFixed(1)} dB',
                  semanticFormatterCallback: (value) =>
                      '${value.toStringAsFixed(1)} dB',
                  onChanged: wavDraft.normalizePeakDb == null
                      ? null
                      : (value) => cubit.updateWavEditDraft(
                          region.path,
                          wavDraft.copyWith(normalizePeakDb: value),
                        ),
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
              child: const Text('Save as...'),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: Text('Overwrite $label?'),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label),
          Semantics(
            label: '$label length',
            value: '${ms.round()} ms',
            child: Slider(
              min: 0,
              max: 5000,
              divisions: 100,
              value: ms.clamp(0, 5000).toDouble(),
              label: '${ms.round()} ms',
              semanticFormatterCallback: (value) => '${value.round()} ms',
              onChanged: (value) {
                onFramesChanged((value / 1000 * overview.sampleRate).round());
              },
            ),
          ),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('$label curve:'),
                  const SizedBox(width: 8),
                  DropdownButton<WavFadeCurve>(
                    value: curve,
                    items: [
                      for (final value in WavFadeCurve.values)
                        DropdownMenuItem(
                          value: value,
                          child: Text(_curveLabel(value)),
                        ),
                    ],
                    onChanged: (value) {
                      if (value != null) onCurveChanged(value);
                    },
                  ),
                ],
              ),
              SizedBox(
                width: 180,
                child: Semantics(
                  label: '$label strength',
                  value: strength.toStringAsFixed(2),
                  child: Slider(
                    min: 0,
                    max: 1,
                    divisions: 20,
                    value: strength,
                    label: strength.toStringAsFixed(2),
                    semanticFormatterCallback: (value) =>
                        value.toStringAsFixed(2),
                    onChanged: onStrengthChanged,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
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
          const SizedBox(width: 8),
          SplitStepperControl(
            label: label,
            valueLabel: value,
            onDecrement: onMinus,
            onIncrement: onPlus,
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
        SplitStepperControl.largeAndSmall(
          label: label,
          valueLabel: '$value frames',
          smallStepLabel: '1',
          largeStepLabel: '100',
          smallStepSemanticsLabel: '1 frame',
          largeStepSemanticsLabel: '100 frames',
          onLargeDecrement: () => onNudge(-100),
          onSmallDecrement: () => onNudge(-1),
          onSmallIncrement: () => onNudge(1),
          onLargeIncrement: () => onNudge(100),
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
