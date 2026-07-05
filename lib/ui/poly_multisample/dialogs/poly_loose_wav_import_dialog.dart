import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nt_helper/poly_multisample/poly_multisample_models.dart';
import 'package:nt_helper/poly_multisample/poly_multisample_parser.dart';
import 'package:nt_helper/ui/poly_multisample/poly_loose_wav_import_cubit.dart';
import 'package:path/path.dart' as p;

Future<PolyStagedImport?> showPolyLooseWavImportDialog(
  BuildContext context, {
  required List<String> paths,
}) {
  return showDialog<PolyStagedImport>(
    context: context,
    builder: (context) {
      return BlocProvider(
        create: (_) => PolyLooseWavImportCubit()..setFiles(paths),
        child: const _PolyLooseWavImportDialog(),
      );
    },
  );
}

class _PolyLooseWavImportDialog extends StatelessWidget {
  const _PolyLooseWavImportDialog();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return BlocBuilder<PolyLooseWavImportCubit, PolyLooseWavImportState>(
      builder: (context, state) {
        final cubit = context.read<PolyLooseWavImportCubit>();
        return AlertDialog(
          title: const Text('Import WAV files'),
          content: SizedBox(
            width: 520,
            height: 480,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      TextButton(
                        onPressed: cubit.selectAll,
                        child: const Text('All'),
                      ),
                      TextButton(
                        onPressed: cubit.clearSelection,
                        child: const Text('None'),
                      ),
                    ],
                  ),
                  for (final path in state.paths)
                    CheckboxListTile(
                      dense: true,
                      title: Text(p.basename(path)),
                      subtitle: Text(p.dirname(path)),
                      value: state.selectedPaths.contains(path),
                      onChanged: (_) => cubit.toggleSelection(path),
                    ),
                  const SizedBox(height: 8),
                  RadioGroup<PolyLooseWavMappingMode>(
                    groupValue: state.mappingOptions.mode,
                    onChanged: (mode) {
                      if (mode == null) return;
                      cubit.setMappingOptions(
                        PolyLooseWavMappingOptions(
                          mode: mode,
                          startMidi: state.mappingOptions.startMidi,
                        ),
                      );
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final mode in PolyLooseWavMappingMode.values)
                          RadioListTile<PolyLooseWavMappingMode>(
                            dense: true,
                            value: mode,
                            title: Text(_mappingModeLabel(mode)),
                          ),
                      ],
                    ),
                  ),
                  if (_showsStartNote(state.mappingOptions.mode))
                    _StartNoteRow(options: state.mappingOptions),
                  if (state.error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        state.error!,
                        style: TextStyle(color: colorScheme.error),
                      ),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed:
                  state.status == PolyLooseWavImportStatus.staging ||
                      !state.canContinue
                  ? null
                  : () async {
                      await cubit.continueImport();
                      if (!context.mounted) return;
                      if (cubit.state.status ==
                          PolyLooseWavImportStatus.completed) {
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

class _StartNoteRow extends StatelessWidget {
  const _StartNoteRow({required this.options});

  final PolyLooseWavMappingOptions options;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PolyLooseWavImportCubit>();
    return Row(
      children: [
        Text(
          'Start note: ${PolyMultisampleParser.midiToNoteName(options.startMidi)}',
        ),
        IconButton(
          tooltip: 'Decrease start note',
          onPressed: () => cubit.setMappingOptions(
            PolyLooseWavMappingOptions(
              mode: options.mode,
              startMidi: (options.startMidi - 1).clamp(0, 127).toInt(),
            ),
          ),
          icon: const Icon(Icons.remove),
        ),
        IconButton(
          tooltip: 'Increase start note',
          onPressed: () => cubit.setMappingOptions(
            PolyLooseWavMappingOptions(
              mode: options.mode,
              startMidi: (options.startMidi + 1).clamp(0, 127).toInt(),
            ),
          ),
          icon: const Icon(Icons.add),
        ),
      ],
    );
  }
}

String _mappingModeLabel(PolyLooseWavMappingMode mode) {
  return switch (mode) {
    PolyLooseWavMappingMode.preserve => 'Use note names from file names',
    PolyLooseWavMappingMode.unmapped => 'Leave unmapped',
    PolyLooseWavMappingMode.chromaticSpread =>
      'Spread chromatically from start note',
    PolyLooseWavMappingMode.roundRobinStack =>
      'Stack as round robins on one note',
    PolyLooseWavMappingMode.velocityLayers =>
      'Stack as velocity layers on one note',
  };
}

bool _showsStartNote(PolyLooseWavMappingMode mode) {
  return switch (mode) {
    PolyLooseWavMappingMode.preserve ||
    PolyLooseWavMappingMode.unmapped => false,
    PolyLooseWavMappingMode.chromaticSpread ||
    PolyLooseWavMappingMode.roundRobinStack ||
    PolyLooseWavMappingMode.velocityLayers => true,
  };
}
