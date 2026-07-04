import 'dart:math' as math;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nt_helper/domain/i_disting_midi_manager.dart';
import 'package:nt_helper/poly_multisample/decent_sampler_converter.dart';
import 'package:nt_helper/poly_multisample/poly_multisample_models.dart';
import 'package:nt_helper/poly_multisample/poly_multisample_parser.dart';
import 'package:nt_helper/ui/poly_multisample/poly_multisample_builder_cubit.dart';

class PolyMultisampleBuilderScreen extends StatelessWidget {
  const PolyMultisampleBuilderScreen({super.key, this.manager});

  final IDistingMidiManager? manager;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PolyMultisampleBuilderCubit(),
      child: PolyMultisampleBuilderView(manager: manager),
    );
  }
}

class PolyMultisampleBuilderView extends StatelessWidget {
  const PolyMultisampleBuilderView({super.key, this.manager});

  final IDistingMidiManager? manager;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<
      PolyMultisampleBuilderCubit,
      PolyMultisampleBuilderState
    >(
      listenWhen: (previous, current) {
        final hasNewEffect = previous.effectId != current.effectId;
        final hasNewError =
            previous.error != current.error && current.error != null;
        return hasNewEffect || hasNewError;
      },
      listener: (context, state) {
        final error = state.error;
        if (error != null) {
          SemanticsService.sendAnnouncement(
            View.of(context),
            error,
            TextDirection.ltr,
          );
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(error)));
          return;
        }
        final effect = state.effect;
        if (effect != null) {
          SemanticsService.sendAnnouncement(
            View.of(context),
            effect,
            TextDirection.ltr,
          );
        }
      },
      builder: (context, state) {
        return Semantics(
          label: 'Samples workspace',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SamplesHeader(manager: manager),
              Expanded(
                child: _SamplesBody(state: state, manager: manager),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SamplesHeader extends StatelessWidget {
  const _SamplesHeader({required this.manager});

  final IDistingMidiManager? manager;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PolyMultisampleBuilderCubit>();
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Semantics(
              header: true,
              child: Text(
                'Samples',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            FilledButton.icon(
              icon: const Icon(Icons.sd_storage),
              label: const Text('NT Hardware'),
              onPressed: () => _loadHardware(context, manager),
            ),
            OutlinedButton.icon(
              icon: const Icon(Icons.folder_open),
              label: const Text('Local'),
              onPressed: () => _loadLocal(context),
            ),
            OutlinedButton.icon(
              icon: const Icon(Icons.file_upload),
              label: const Text('Import'),
              onPressed: () => _importFiles(context),
            ),
            BlocBuilder<
              PolyMultisampleBuilderCubit,
              PolyMultisampleBuilderState
            >(
              buildWhen: (previous, current) =>
                  previous.isDirty != current.isDirty ||
                  previous.activeOperation != current.activeOperation ||
                  previous.sourceMode != current.sourceMode ||
                  previous.currentInstrument != current.currentInstrument,
              builder: (context, state) {
                final applying =
                    state.activeOperation ==
                    PolyMultisampleActiveOperation.applying;
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Back to sample sources',
                      onPressed: state.currentInstrument == null
                          ? null
                          : cubit.returnToSources,
                      icon: const Icon(Icons.arrow_back),
                    ),
                    const SizedBox(width: 4),
                    TextButton.icon(
                      icon: const Icon(Icons.undo),
                      label: const Text('Discard'),
                      onPressed: state.isDirty ? cubit.discardChanges : null,
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      icon: applying
                          ? const SizedBox.square(
                              dimension: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check),
                      label: const Text('Apply'),
                      onPressed: state.isDirty && !applying
                          ? () => cubit.applyChanges(manager)
                          : null,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SamplesBody extends StatelessWidget {
  const _SamplesBody({required this.state, required this.manager});

  final PolyMultisampleBuilderState state;
  final IDistingMidiManager? manager;

  @override
  Widget build(BuildContext context) {
    if (state.status == PolyMultisampleLoadStatus.loading) {
      return Center(
        child: Semantics(
          liveRegion: true,
          label: state.progressText ?? 'Loading samples',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(state.progressText ?? 'Loading samples...'),
            ],
          ),
        ),
      );
    }

    if (state.status == PolyMultisampleLoadStatus.largeFolder) {
      return _WarningPanel(
        title: 'Large sample folder',
        messages: state.warnings,
      );
    }

    if (state.hardwareFolders.isNotEmpty && state.currentInstrument == null) {
      return _HardwareFolderList(
        folders: state.hardwareFolders,
        manager: manager,
      );
    }

    if (state.sourceMode == PolySampleSourceMode.hardware &&
        state.status == PolyMultisampleLoadStatus.ready &&
        state.currentInstrument == null) {
      return const _HardwareEmptyState();
    }

    final instrument = state.currentInstrument;
    if (instrument == null) {
      return _EmptySamplesState(manager: manager);
    }

    return _InstrumentEditor(
      state: state,
      instrument: instrument,
      manager: manager,
    );
  }
}

class _HardwareEmptyState extends StatelessWidget {
  const _HardwareEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Semantics(
        container: true,
        liveRegion: true,
        label: 'No sample folders found on /samples.',
        child: const ExcludeSemantics(
          child: Text('No sample folders found on /samples.'),
        ),
      ),
    );
  }
}

class _EmptySamplesState extends StatelessWidget {
  const _EmptySamplesState({required this.manager});

  final IDistingMidiManager? manager;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Semantics(
                header: true,
                child: Text(
                  'Build or edit a Disting NT multisample folder',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  _SourceAction(
                    icon: Icons.sd_storage,
                    label: 'NT Hardware',
                    onPressed: () => _loadHardware(context, manager),
                  ),
                  _SourceAction(
                    icon: Icons.folder_open,
                    label: 'Local',
                    onPressed: () => _loadLocal(context),
                  ),
                  _SourceAction(
                    icon: Icons.file_upload,
                    label: 'Import',
                    onPressed: () => _importFiles(context),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SourceAction extends StatelessWidget {
  const _SourceAction({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonalIcon(
      icon: Icon(icon),
      label: Text(label),
      onPressed: onPressed,
    );
  }
}

class _HardwareFolderList extends StatelessWidget {
  const _HardwareFolderList({required this.folders, required this.manager});

  final List<String> folders;
  final IDistingMidiManager? manager;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PolyMultisampleBuilderCubit>();
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: folders.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final folder = folders[index];
        return ListTile(
          leading: const Icon(Icons.folder),
          title: Text(folder),
          onTap: manager == null
              ? null
              : () => cubit.loadHardwareFolder(manager!, folder),
        );
      },
    );
  }
}

class _InstrumentEditor extends StatelessWidget {
  const _InstrumentEditor({
    required this.state,
    required this.instrument,
    required this.manager,
  });

  final PolyMultisampleBuilderState state;
  final PolySampleInstrument instrument;
  final IDistingMidiManager? manager;

  @override
  Widget build(BuildContext context) {
    final selected = _selectedRegionFor(state);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _InstrumentStats(instrument: instrument, isDirty: state.isDirty),
        if (state.warnings.isNotEmpty)
          _WarningPanel(title: 'Warnings', messages: state.warnings),
        _KeyMap(
          regions: state.editedRegions,
          selectedPath: selected?.path,
          onSelect: (region) => context
              .read<PolyMultisampleBuilderCubit>()
              .selectRegion(region.path, PolyRegionSelectionMode.replace),
        ),
        _SelectedSampleControls(region: selected, manager: manager),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            itemCount: state.editedRegions.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final region = state.editedRegions[index];
              return _SampleRegionTile(
                region: region,
                selected: state.selectedPaths.contains(region.path),
                manager: manager,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _InstrumentStats extends StatelessWidget {
  const _InstrumentStats({required this.instrument, required this.isDirty});

  final PolySampleInstrument instrument;
  final bool isDirty;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Wrap(
        spacing: 16,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Semantics(
            header: true,
            child: Text(
              instrument.name,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          Text('${instrument.regions.length} samples'),
          Text('${instrument.mappedCount} mapped'),
          Text('${instrument.warningCount} warnings'),
          if (isDirty)
            const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.edit, size: 16),
                SizedBox(width: 4),
                Text('Unsaved changes'),
              ],
            ),
        ],
      ),
    );
  }
}

class _KeyMap extends StatelessWidget {
  const _KeyMap({
    required this.regions,
    required this.selectedPath,
    required this.onSelect,
  });

  final List<PolySampleRegion> regions;
  final String? selectedPath;
  final ValueChanged<PolySampleRegion> onSelect;

  @override
  Widget build(BuildContext context) {
    final mapped = regions.where((region) => region.rootMidi != null).toList();
    final extents = _midiExtents(regions);
    final minMidi = extents == null ? 24 : math.max(0, extents.$1 - 6);
    final maxMidi = extents == null ? 96 : math.min(127, extents.$2 + 6);
    return Semantics(
      container: true,
      label: 'Keyboard map with ${mapped.length} mapped samples',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        child: SizedBox(
          height: 156,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final size = Size(constraints.maxWidth, constraints.maxHeight);
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapUp: (details) {
                    final region = _regionAtKeyboardPosition(
                      details.localPosition,
                      size,
                      regions,
                      minMidi,
                      maxMidi,
                    );
                    if (region != null) onSelect(region);
                  },
                  child: CustomPaint(
                    painter: _SimpleKeyboardPainter(
                      regions: regions,
                      selectedPath: selectedPath,
                      minMidi: minMidi,
                      maxMidi: maxMidi,
                      colorScheme: Theme.of(context).colorScheme,
                    ),
                    child: const SizedBox.expand(),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _SampleRegionTile extends StatelessWidget {
  const _SampleRegionTile({
    required this.region,
    required this.selected,
    required this.manager,
  });

  final PolySampleRegion region;
  final bool selected;
  final IDistingMidiManager? manager;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PolyMultisampleBuilderCubit>();
    final playing =
        context.select<PolyMultisampleBuilderCubit, String?>(
          (cubit) => cubit.state.previewState.visiblePath,
        ) ==
        region.path;
    final issues = region.currentIssues;
    return Semantics(
      selected: selected,
      label: '${region.displayName}, root ${region.rootName ?? 'unmapped'}',
      child: ListTile(
        selected: selected,
        leading: Icon(
          issues.isEmpty ? Icons.graphic_eq : Icons.warning_amber,
          semanticLabel: issues.isEmpty ? 'Mapped sample' : 'Sample warning',
        ),
        title: Text(region.displayName),
        subtitle: Text(
          [
            'Root ${region.rootName ?? 'unmapped'}',
            if (region.velocityLayer != null) 'V${region.velocityLayer}',
            if (region.roundRobin != null) 'RR${region.roundRobin}',
            if (issues.isNotEmpty)
              'Issues: ${issues.map((issue) => issue.name).join(', ')}',
          ].join('  '),
        ),
        trailing: IconButton(
          tooltip: playing ? 'Stop preview' : 'Preview sample',
          icon: Icon(playing ? Icons.stop : Icons.play_arrow),
          onPressed: region.path.toLowerCase().endsWith('.wav')
              ? () => cubit.playOrStopPreview(region.path, manager: manager)
              : null,
        ),
        onTap: () =>
            cubit.selectRegion(region.path, PolyRegionSelectionMode.replace),
      ),
    );
  }
}

class _SelectedSampleControls extends StatelessWidget {
  const _SelectedSampleControls({required this.region, required this.manager});

  final PolySampleRegion? region;
  final IDistingMidiManager? manager;

  @override
  Widget build(BuildContext context) {
    final selected = region;
    if (selected == null) {
      return const SizedBox.shrink();
    }
    final cubit = context.read<PolyMultisampleBuilderCubit>();
    final playing =
        context.select<PolyMultisampleBuilderCubit, String?>(
          (cubit) => cubit.state.previewState.visiblePath,
        ) ==
        selected.path;
    final root = selected.rootMidi ?? 60;
    final low = _effectiveLow(selected);
    final high = _effectiveHigh(
      selected,
      context.read<PolyMultisampleBuilderCubit>().state.editedRegions,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Wrap(
            spacing: 10,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 260),
                child: Text(
                  selected.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              IconButton.filledTonal(
                tooltip: playing ? 'Stop preview' : 'Preview sample',
                onPressed: selected.path.toLowerCase().endsWith('.wav')
                    ? () => cubit.playOrStopPreview(
                        selected.path,
                        manager: manager,
                      )
                    : null,
                icon: Icon(playing ? Icons.stop : Icons.play_arrow),
              ),
              _StepControl(
                label: 'Root',
                value: selected.rootMidi == null
                    ? 'Unset'
                    : PolyMultisampleParser.midiToNoteName(root),
                onMinus: () => cubit.updateRoot(selected.path, root - 1),
                onPlus: () => cubit.updateRoot(selected.path, root + 1),
              ),
              _StepControl(
                label: 'Low',
                value: PolyMultisampleParser.midiToNoteName(low),
                onMinus: () => cubit.updateRangeLow(selected.path, low - 1),
                onPlus: () => cubit.updateRangeLow(selected.path, low + 1),
              ),
              _StepControl(
                label: 'High',
                value: PolyMultisampleParser.midiToNoteName(high),
                onMinus: () => cubit.updateRangeHigh(selected.path, high - 1),
                onPlus: () => cubit.updateRangeHigh(selected.path, high + 1),
              ),
              _StepControl(
                label: 'V',
                value: '${selected.velocityLayer ?? 1}',
                onMinus: () => cubit.updateVelocity(
                  selected.path,
                  math.max(1, (selected.velocityLayer ?? 1) - 1),
                ),
                onPlus: () => cubit.updateVelocity(
                  selected.path,
                  (selected.velocityLayer ?? 1) + 1,
                ),
              ),
              _StepControl(
                label: 'RR',
                value: '${selected.roundRobin ?? 1}',
                onMinus: () => cubit.updateRoundRobin(
                  selected.path,
                  math.max(1, (selected.roundRobin ?? 1) - 1),
                ),
                onPlus: () => cubit.updateRoundRobin(
                  selected.path,
                  (selected.roundRobin ?? 1) + 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepControl extends StatelessWidget {
  const _StepControl({
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

PolySampleRegion? _selectedRegionFor(PolyMultisampleBuilderState state) {
  final focused = state.focusedPath;
  if (focused != null) {
    for (final region in state.editedRegions) {
      if (region.path == focused) return region;
    }
  }
  if (state.selectedPaths.isNotEmpty) {
    final path = state.selectedPaths.first;
    for (final region in state.editedRegions) {
      if (region.path == path) return region;
    }
  }
  return state.editedRegions.isEmpty ? null : state.editedRegions.first;
}

int _effectiveLow(PolySampleRegion region) {
  return (region.rangeLow ?? region.switchPoint ?? region.rootMidi ?? 0)
      .clamp(0, 127)
      .toInt();
}

int _effectiveHigh(PolySampleRegion region, List<PolySampleRegion> regions) {
  final explicit = region.rangeHigh;
  if (explicit != null) return explicit.clamp(0, 127).toInt();
  final low = _effectiveLow(region);
  final velocity = region.velocityLayer ?? 1;
  final laterLows =
      regions
          .where(
            (candidate) =>
                candidate.rootMidi != null &&
                (candidate.velocityLayer ?? 1) == velocity &&
                _effectiveLow(candidate) > low,
          )
          .map(_effectiveLow)
          .toList()
        ..sort();
  if (laterLows.isEmpty) return 127;
  return math.max(low, laterLows.first - 1);
}

(int, int)? _midiExtents(List<PolySampleRegion> regions) {
  final mapped = regions.where((region) => region.rootMidi != null).toList();
  if (mapped.isEmpty) return null;
  var minMidi = 127;
  var maxMidi = 0;
  for (final region in mapped) {
    minMidi = math.min(minMidi, _effectiveLow(region));
    maxMidi = math.max(maxMidi, _effectiveHigh(region, regions));
    minMidi = math.min(minMidi, region.rootMidi!);
    maxMidi = math.max(maxMidi, region.rootMidi!);
  }
  return (minMidi, maxMidi);
}

List<int> _velocityLanes(List<PolySampleRegion> regions) {
  final lanes =
      regions
          .where((region) => region.rootMidi != null)
          .map((region) => region.velocityLayer ?? 1)
          .toSet()
          .toList()
        ..sort();
  return lanes.isEmpty ? const [1] : lanes.reversed.toList();
}

PolySampleRegion? _regionAtKeyboardPosition(
  Offset position,
  Size size,
  List<PolySampleRegion> regions,
  int minMidi,
  int maxMidi,
) {
  final layout = _KeyboardLayout(size, _velocityLanes(regions));
  if (!layout.zoneRect.contains(position)) return null;
  final span = math.max(1, maxMidi - minMidi + 1);
  final midi = (minMidi + ((position.dx - layout.left) / layout.width) * span)
      .floor()
      .clamp(minMidi, maxMidi);
  final laneIndex = ((position.dy - layout.zoneTop) / layout.laneHeight)
      .floor()
      .clamp(0, layout.lanes.length - 1);
  final velocity = layout.lanes[laneIndex];
  final matches = regions.where((region) {
    if (region.rootMidi == null) return false;
    return (region.velocityLayer ?? 1) == velocity &&
        midi >= _effectiveLow(region) &&
        midi <= _effectiveHigh(region, regions);
  }).toList();
  if (matches.isEmpty) return null;
  matches.sort((a, b) {
    final rootCompare = (a.rootMidi ?? 0).compareTo(b.rootMidi ?? 0);
    if (rootCompare != 0) return rootCompare;
    return (a.roundRobin ?? 1).compareTo(b.roundRobin ?? 1);
  });
  return matches.first;
}

class _KeyboardLayout {
  _KeyboardLayout(Size size, this.lanes)
    : left = lanes.length > 1 ? 52 : 16,
      right = size.width - 16,
      zoneTop = 24,
      keyboardTop = size.height - 42,
      keyboardBottom = size.height - 8 {
    width = math.max(1, right - left);
    zoneBottom = keyboardTop - 8;
    laneHeight = math.max(1, (zoneBottom - zoneTop) / lanes.length);
    zoneRect = Rect.fromLTRB(left, zoneTop, right, zoneBottom);
  }

  final List<int> lanes;
  final double left;
  final double right;
  final double zoneTop;
  final double keyboardTop;
  final double keyboardBottom;
  late final double width;
  late final double zoneBottom;
  late final double laneHeight;
  late final Rect zoneRect;
}

class _SimpleKeyboardPainter extends CustomPainter {
  _SimpleKeyboardPainter({
    required this.regions,
    required this.selectedPath,
    required this.minMidi,
    required this.maxMidi,
    required this.colorScheme,
  });

  final List<PolySampleRegion> regions;
  final String? selectedPath;
  final int minMidi;
  final int maxMidi;
  final ColorScheme colorScheme;

  @override
  void paint(Canvas canvas, Size size) {
    final lanes = _velocityLanes(regions);
    final layout = _KeyboardLayout(size, lanes);
    final span = math.max(1, maxMidi - minMidi + 1);
    final gridPaint = Paint()
      ..color = colorScheme.outlineVariant.withValues(alpha: 0.45)
      ..strokeWidth = 1;
    final fillPaint = Paint()
      ..color = colorScheme.surfaceContainerHighest.withValues(alpha: 0.28);

    final title = TextPainter(
      text: TextSpan(
        text: 'Keyboard',
        style: TextStyle(
          color: colorScheme.onSurfaceVariant,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    title.paint(canvas, const Offset(14, 6));

    for (var i = 0; i < lanes.length; i++) {
      final top = layout.zoneTop + i * layout.laneHeight;
      final bottom = top + layout.laneHeight;
      if (i.isOdd) {
        canvas.drawRect(Rect.fromLTRB(0, top, size.width, bottom), fillPaint);
      }
      if (lanes.length > 1) {
        final laneLabel = TextPainter(
          text: TextSpan(
            text: 'V${lanes[i]}',
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        laneLabel.paint(
          canvas,
          Offset(14, top + (layout.laneHeight - laneLabel.height) / 2),
        );
      }
      canvas.drawLine(
        Offset(layout.left, bottom),
        Offset(layout.right, bottom),
        gridPaint,
      );
    }

    for (var midi = minMidi; midi <= maxMidi; midi++) {
      final x = layout.left + ((midi - minMidi) / span) * layout.width;
      if (midi % 12 == 0) {
        canvas.drawLine(
          Offset(x, layout.zoneTop),
          Offset(x, layout.keyboardBottom),
          gridPaint,
        );
      }
    }

    for (final region in regions.where((region) => region.rootMidi != null)) {
      final laneIndex = lanes.indexOf(region.velocityLayer ?? 1);
      final lane = laneIndex < 0 ? 0 : laneIndex;
      final x0 =
          layout.left +
          ((_effectiveLow(region) - minMidi) / span) * layout.width;
      final x1 =
          layout.left +
          ((_effectiveHigh(region, regions) + 1 - minMidi) / span) *
              layout.width;
      final y0 = layout.zoneTop + lane * layout.laneHeight;
      final rect = Rect.fromLTRB(
        x0 + 1,
        y0 + 2,
        x1 - 1,
        y0 + layout.laneHeight - 2,
      );
      final selected = region.path == selectedPath;
      canvas.drawRect(
        rect,
        Paint()
          ..color = selected
              ? colorScheme.tertiary.withValues(alpha: 0.70)
              : colorScheme.primary.withValues(alpha: 0.36),
      );
      if (selected) {
        canvas.drawRect(
          rect.deflate(1),
          Paint()
            ..color = colorScheme.onSurface
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      }
      if (rect.width > 26) {
        final label =
            region.rootName ??
            PolyMultisampleParser.midiToNoteName(region.rootMidi!);
        final text = TextPainter(
          text: TextSpan(
            text: label,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 10,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          maxLines: 1,
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: rect.width - 6);
        text.paint(
          canvas,
          Offset(rect.left + 3, rect.center.dy - text.height / 2),
        );
      }
    }

    final keyboardRect = Rect.fromLTRB(
      layout.left,
      layout.keyboardTop,
      layout.right,
      layout.keyboardBottom,
    );
    canvas.drawRect(
      keyboardRect,
      Paint()..color = colorScheme.surfaceContainerHighest,
    );
    for (var midi = minMidi; midi <= maxMidi; midi++) {
      final x0 = layout.left + ((midi - minMidi) / span) * layout.width;
      final x1 = layout.left + ((midi + 1 - minMidi) / span) * layout.width;
      final note = midi % 12;
      final black =
          note == 1 || note == 3 || note == 6 || note == 8 || note == 10;
      if (black) {
        canvas.drawRect(
          Rect.fromLTRB(
            x0 + (x1 - x0) * 0.18,
            layout.keyboardTop,
            x1 - (x1 - x0) * 0.18,
            layout.keyboardTop +
                (layout.keyboardBottom - layout.keyboardTop) * 0.62,
          ),
          Paint()..color = colorScheme.onSurface,
        );
      } else {
        canvas.drawRect(
          Rect.fromLTRB(x0, layout.keyboardTop, x1, layout.keyboardBottom),
          Paint()
            ..color = colorScheme.surface
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.8,
        );
      }
      if (midi % 12 == 0) {
        final octave = TextPainter(
          text: TextSpan(
            text: PolyMultisampleParser.midiToNoteName(midi),
            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 10),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        octave.paint(canvas, Offset(x0 + 3, layout.keyboardBottom - 15));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SimpleKeyboardPainter oldDelegate) {
    return oldDelegate.regions != regions ||
        oldDelegate.selectedPath != selectedPath ||
        oldDelegate.minMidi != minMidi ||
        oldDelegate.maxMidi != maxMidi ||
        oldDelegate.colorScheme != colorScheme;
  }
}

class _WarningPanel extends StatelessWidget {
  const _WarningPanel({required this.title, required this.messages});

  final String title;
  final List<String> messages;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).colorScheme.outline),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(Icons.warning_amber),
                    const SizedBox(width: 8),
                    Semantics(
                      header: true,
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                for (final message in messages) Text(message),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> _loadHardware(
  BuildContext context,
  IDistingMidiManager? manager,
) async {
  if (manager == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Connect to Disting NT to browse samples.')),
    );
    return;
  }
  await context.read<PolyMultisampleBuilderCubit>().loadHardwareFolderList(
    manager,
  );
}

Future<void> _loadLocal(BuildContext context) async {
  final path = await FilePicker.getDirectoryPath(
    dialogTitle: 'Open sample folder',
  );
  if (path == null || !context.mounted) return;
  await context.read<PolyMultisampleBuilderCubit>().loadLocalFolder(path);
}

Future<void> _importFiles(BuildContext context) async {
  final result = await FilePicker.pickFiles(
    dialogTitle: 'Import samples',
    allowMultiple: true,
    type: FileType.custom,
    allowedExtensions: const [
      'wav',
      'aif',
      'aiff',
      'dspreset',
      'dslibrary',
      'zip',
    ],
  );
  if (result == null || !context.mounted) return;
  final paths = <String>[
    for (final file in result.files)
      if (file.path != null) file.path!,
  ];
  if (paths.isEmpty) return;
  final cubit = context.read<PolyMultisampleBuilderCubit>();
  final first = paths.length == 1 ? paths.first.toLowerCase() : null;
  if (first != null &&
      (first.endsWith('.dspreset') ||
          first.endsWith('.dslibrary') ||
          first.endsWith('.zip'))) {
    await cubit.stageDecentSource(
      paths.single,
      const DecentSamplerConvertOptions(),
    );
    return;
  }
  await cubit.stageLooseFiles(paths, const PolyLooseWavMappingOptions());
}
