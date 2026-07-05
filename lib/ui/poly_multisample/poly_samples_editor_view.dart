import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nt_helper/domain/i_disting_midi_manager.dart';
import 'package:nt_helper/poly_multisample/poly_multisample_models.dart';
import 'package:nt_helper/ui/poly_multisample/poly_multisample_builder_cubit.dart';
import 'package:nt_helper/ui/poly_multisample/poly_region_math.dart';
import 'package:nt_helper/ui/poly_multisample/widgets/poly_key_map.dart';
import 'package:nt_helper/ui/poly_multisample/widgets/poly_sample_inspector.dart';
import 'package:nt_helper/ui/poly_multisample/widgets/poly_sample_list.dart';

class PolySamplesEditorView extends StatelessWidget {
  const PolySamplesEditorView({
    super.key,
    required this.state,
    required this.manager,
    required this.onAddFiles,
    required this.onAddFolder,
    required this.onSaveAs,
    required this.onBackToSources,
  });

  final PolyMultisampleBuilderState state;
  final IDistingMidiManager? manager;
  final VoidCallback onAddFiles;
  final VoidCallback onAddFolder;
  final VoidCallback onSaveAs;
  final VoidCallback onBackToSources;

  @override
  Widget build(BuildContext context) {
    final instrument = state.currentInstrument;
    if (instrument == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Toolbar(
          state: state,
          instrument: instrument,
          manager: manager,
          onAddFiles: onAddFiles,
          onAddFolder: onAddFolder,
          onSaveAs: onSaveAs,
          onBackToSources: onBackToSources,
        ),
        if (state.warnings.isNotEmpty)
          _WarningPanel(title: 'Warnings', messages: state.warnings),
        Expanded(
          child: _EditorBody(state: state, manager: manager),
        ),
      ],
    );
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.state,
    required this.instrument,
    required this.manager,
    required this.onAddFiles,
    required this.onAddFolder,
    required this.onSaveAs,
    required this.onBackToSources,
  });

  final PolyMultisampleBuilderState state;
  final PolySampleInstrument instrument;
  final IDistingMidiManager? manager;
  final VoidCallback onAddFiles;
  final VoidCallback onAddFolder;
  final VoidCallback onSaveAs;
  final VoidCallback onBackToSources;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PolyMultisampleBuilderCubit>();
    final applying =
        state.activeOperation == PolyMultisampleActiveOperation.applying;
    final saving =
        state.activeOperation == PolyMultisampleActiveOperation.saving;
    final draftMode =
        state.sourceMode == PolySampleSourceMode.importDraft ||
        state.sourceMode == PolySampleSourceMode.customDraft;
    final canSaveMappingChanges =
        !state.hasWaveformDrafts && state.hasRegionChanges;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Tooltip(
                message: 'Back to sample sources',
                child: OutlinedButton.icon(
                  onPressed: onBackToSources,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Sources'),
                ),
              ),
              Semantics(
                header: true,
                child: Text(
                  instrument.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Text('${instrument.regions.length} samples'),
              Text('${instrument.mappedCount} mapped'),
              if (instrument.warningCount > 0)
                Text('${instrument.warningCount} warnings'),
              if (state.isDirty) const Chip(label: Text('Unsaved changes')),
              if (draftMode)
                FilledButton.icon(
                  onPressed:
                      state.editedRegions.isNotEmpty &&
                          !state.hasWaveformDrafts &&
                          !saving
                      ? onSaveAs
                      : null,
                  icon: const Icon(Icons.save_as),
                  label: const Text('Save As…'),
                )
              else
                FilledButton.icon(
                  onPressed: canSaveMappingChanges && !applying
                      ? () => cubit.applyChanges(manager)
                      : null,
                  icon: applying
                      ? const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check),
                  label: const Text('Apply'),
                ),
              TextButton.icon(
                onPressed: state.isDirty ? cubit.discardChanges : null,
                icon: const Icon(Icons.undo),
                label: const Text('Discard'),
              ),
              PopupMenuButton<String>(
                tooltip: 'More sample actions',
                icon: const Icon(Icons.more_horiz),
                onSelected: (value) {
                  switch (value) {
                    case 'add_files':
                      onAddFiles();
                      break;
                    case 'add_folder':
                      onAddFolder();
                      break;
                    case 'remove_selected':
                      cubit.removeSelectedRegions();
                      break;
                    case 'clear_all':
                      cubit.clearDraft();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'add_files',
                    child: Text('Add files…'),
                  ),
                  const PopupMenuItem(
                    value: 'add_folder',
                    child: Text('Add folder…'),
                  ),
                  PopupMenuItem(
                    value: 'remove_selected',
                    enabled: state.selectedPaths.isNotEmpty,
                    child: const Text('Remove selected'),
                  ),
                  PopupMenuItem(
                    value: 'clear_all',
                    enabled: state.editedRegions.isNotEmpty,
                    child: const Text('Clear all'),
                  ),
                ],
              ),
            ],
          ),
          if (state.hasWaveformDrafts) ...[
            const SizedBox(height: 8),
            Semantics(
              liveRegion: true,
              child: Text(
                'Save or discard waveform edits before applying or saving this sample set.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EditorBody extends StatelessWidget {
  const _EditorBody({required this.state, required this.manager});

  final PolyMultisampleBuilderState state;
  final IDistingMidiManager? manager;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PolyMultisampleBuilderCubit>();
    return LayoutBuilder(
      builder: (context, constraints) {
        final selected = selectedRegionFor(state);
        final keyMap = PolyKeyMap(
          regions: state.editedRegions,
          selectedPath: selected?.path,
          onSelect: (region) => cubit.selectRegion(
            region.path,
            PolyRegionSelectionMode.replace,
            manager: manager,
          ),
        );
        final sampleList = PolySampleList(
          regions: state.editedRegions,
          selectedPaths: state.selectedPaths,
          focusedPath: state.focusedPath,
          previewVisiblePath: state.previewState.visiblePath,
          onSelect: (path, mode) =>
              cubit.selectRegion(path, mode, manager: manager),
          onPreview: (path) => cubit.playOrStopPreview(path, manager: manager),
        );
        final inspector = PolySampleInspector(state: state, manager: manager);
        if (constraints.maxWidth >= 900) {
          return Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    keyMap,
                    Expanded(child: sampleList),
                  ],
                ),
              ),
              SizedBox(width: 320, child: inspector),
            ],
          );
        }
        return Column(
          children: [
            PolyKeyMap(
              height: 140,
              regions: state.editedRegions,
              selectedPath: selected?.path,
              onSelect: (region) => cubit.selectRegion(
                region.path,
                PolyRegionSelectionMode.replace,
                manager: manager,
              ),
            ),
            Expanded(flex: 3, child: sampleList),
            const Divider(height: 1),
            Expanded(flex: 2, child: inspector),
          ],
        );
      },
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
