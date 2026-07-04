import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nt_helper/domain/i_disting_midi_manager.dart';
import 'package:nt_helper/poly_multisample/decent_sampler_converter.dart';
import 'package:nt_helper/poly_multisample/poly_multisample_models.dart';
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
      listenWhen: (previous, current) =>
          previous.effectId != current.effectId ||
          previous.error != current.error,
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
                  previous.sourceMode != current.sourceMode,
              builder: (context, state) {
                final applying =
                    state.activeOperation ==
                    PolyMultisampleActiveOperation.applying;
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
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

    final instrument = state.currentInstrument;
    if (instrument == null) {
      return _EmptySamplesState(manager: manager);
    }

    return _InstrumentEditor(state: state, instrument: instrument);
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
  const _InstrumentEditor({required this.state, required this.instrument});

  final PolyMultisampleBuilderState state;
  final PolySampleInstrument instrument;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _InstrumentStats(instrument: instrument, isDirty: state.isDirty),
        if (state.warnings.isNotEmpty)
          _WarningPanel(title: 'Warnings', messages: state.warnings),
        _KeyMap(regions: state.editedRegions),
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
  const _KeyMap({required this.regions});

  final List<PolySampleRegion> regions;

  @override
  Widget build(BuildContext context) {
    final mapped = regions.where((region) => region.rootMidi != null).toList();
    return Semantics(
      label: 'Sample key map with ${mapped.length} mapped samples',
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final region in mapped)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Tooltip(
                  message: region.displayName,
                  child: Chip(
                    visualDensity: VisualDensity.compact,
                    label: Text(region.rootName ?? '?'),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SampleRegionTile extends StatelessWidget {
  const _SampleRegionTile({required this.region, required this.selected});

  final PolySampleRegion region;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PolyMultisampleBuilderCubit>();
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
          tooltip: 'Preview sample',
          icon: const Icon(Icons.play_arrow),
          onPressed: region.path.toLowerCase().endsWith('.wav')
              ? () => cubit.playOrStopPreview(region.path)
              : null,
        ),
        onTap: () =>
            cubit.selectRegion(region.path, PolyRegionSelectionMode.replace),
      ),
    );
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
