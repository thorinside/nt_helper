import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/poly_multisample/poly_multisample_models.dart';
import 'package:nt_helper/ui/poly_multisample/dialogs/poly_decent_import_dialog.dart';
import 'package:nt_helper/ui/poly_multisample/dialogs/poly_loose_wav_import_dialog.dart';
import 'package:nt_helper/ui/poly_multisample/poly_multisample_builder_cubit.dart';
import 'package:nt_helper/ui/poly_multisample/poly_samples_editor_view.dart';
import 'package:nt_helper/ui/poly_multisample/poly_samples_landing_view.dart';
import 'package:path/path.dart' as p;

class PolySamplesScreen extends StatelessWidget {
  const PolySamplesScreen({super.key, required this.distingCubit});

  final DistingCubit distingCubit;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PolyMultisampleBuilderCubit(),
      child: PolySamplesView(distingCubit: distingCubit),
    );
  }
}

class PolySamplesView extends StatelessWidget {
  const PolySamplesView({super.key, required this.distingCubit});

  final DistingCubit distingCubit;

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
        final hasUnsavedWork =
            state.isDirty ||
            ((state.sourceMode == PolySampleSourceMode.importDraft ||
                    state.sourceMode == PolySampleSourceMode.customDraft) &&
                state.editedRegions.isNotEmpty);
        return PopScope(
          canPop: !hasUnsavedWork,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop || !hasUnsavedWork) return;
            _confirmDiscardChanges(context);
          },
          child: Scaffold(
            appBar: AppBar(title: const Text('Samples')),
            body: _body(context, state),
          ),
        );
      },
    );
  }

  Widget _body(BuildContext context, PolyMultisampleBuilderState state) {
    final cubit = context.read<PolyMultisampleBuilderCubit>();
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
      return PolyLargeFolderView(
        messages: state.warnings,
        onChooseSmaller: () => _openLocal(context),
        onImportSubset: () => _import(context),
      );
    }

    if (state.hardwareFolders.isNotEmpty && state.currentInstrument == null) {
      return PolyHardwareFolderList(
        folders: state.hardwareFolders,
        onOpen: (folder) {
          final manager = distingCubit.disting();
          if (manager != null) cubit.loadHardwareFolder(manager, folder);
        },
        onBack: cubit.returnToSources,
      );
    }

    if (state.sourceMode == PolySampleSourceMode.hardware &&
        state.status == PolyMultisampleLoadStatus.ready &&
        state.currentInstrument == null) {
      return const _HardwareEmptyState();
    }

    if (state.currentInstrument == null) {
      return PolySamplesLandingView(
        state: state,
        onOpenHardware: () => _openHardware(context),
        onOpenLocal: () => _openLocal(context),
        onImport: () => _import(context),
        onOpenRecent: state.lastLocalFolder == null
            ? null
            : () => cubit.loadLocalFolder(state.lastLocalFolder!),
        onStartEmptyDraft: cubit.startEmptyDraft,
      );
    }

    return PolySamplesEditorView(
      state: state,
      manager: distingCubit.disting(),
      onAddFiles: () => _addFiles(context),
      onAddFolder: () => _addFolder(context),
      onSaveAs: () => _saveAs(context),
      onBackToSources: cubit.returnToSources,
    );
  }

  Future<void> _openHardware(BuildContext context) async {
    final cubit = context.read<PolyMultisampleBuilderCubit>();
    final manager = distingCubit.disting();
    if (manager == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Connect to Disting NT to browse samples.'),
        ),
      );
      return;
    }
    await cubit.loadHardwareFolderList(manager);
  }

  Future<void> _openLocal(BuildContext context) async {
    final cubit = context.read<PolyMultisampleBuilderCubit>();
    final path = await FilePicker.getDirectoryPath(
      dialogTitle: 'Open sample folder',
      initialDirectory: cubit.state.lastLocalFolder,
    );
    if (path == null || !context.mounted) return;
    await cubit.loadLocalFolder(path);
  }

  Future<void> _import(BuildContext context) async {
    final cubit = context.read<PolyMultisampleBuilderCubit>();
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

    PolyStagedImport? staged;
    final single = paths.length == 1 ? paths.single : null;
    final lower = single?.toLowerCase();
    if (single != null &&
        (lower!.endsWith('.dspreset') ||
            lower.endsWith('.dslibrary') ||
            lower.endsWith('.zip'))) {
      await cubit.rememberSourceFolder(p.dirname(single));
      if (!context.mounted) return;
      staged = await showPolyDecentImportDialog(
        context,
        sourcePath: single,
        previewCubit: cubit,
      );
    } else {
      final audioPaths = [
        for (final path in paths)
          if (isSupportedAudioName(p.basename(path))) path,
      ];
      staged = await showPolyLooseWavImportDialog(context, paths: audioPaths);
    }
    if (staged != null) await cubit.adoptStagedImport(staged);
  }

  Future<void> _addFiles(BuildContext context) async {
    final cubit = context.read<PolyMultisampleBuilderCubit>();
    final result = await FilePicker.pickFiles(
      dialogTitle: 'Add samples',
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: const ['wav', 'aif', 'aiff'],
    );
    if (result == null || !context.mounted) return;
    final paths = <String>[
      for (final file in result.files)
        if (file.path != null) file.path!,
    ];
    final staged = await showPolyLooseWavImportDialog(context, paths: paths);
    if (staged != null) await cubit.addStagedRegions(staged);
  }

  Future<void> _addFolder(BuildContext context) async {
    final cubit = context.read<PolyMultisampleBuilderCubit>();
    final path = await FilePicker.getDirectoryPath(dialogTitle: 'Add samples');
    if (path == null || !context.mounted) return;
    final directory = Directory(path);
    final entries = directory.listSync();
    final hasDecentPreset = entries.whereType<File>().any(
      (file) => file.path.toLowerCase().endsWith('.dspreset'),
    );
    PolyStagedImport? staged;
    if (hasDecentPreset) {
      staged = await showPolyDecentImportDialog(
        context,
        sourcePath: path,
        previewCubit: cubit,
      );
    } else {
      final paths = <String>[];
      await for (final entity in directory.list(recursive: true)) {
        if (entity is File && isSupportedAudioName(p.basename(entity.path))) {
          paths.add(entity.path);
        }
      }
      if (!context.mounted) return;
      staged = await showPolyLooseWavImportDialog(context, paths: paths);
    }
    if (staged != null) await cubit.addStagedRegions(staged);
  }

  Future<void> _saveAs(BuildContext context) async {
    final cubit = context.read<PolyMultisampleBuilderCubit>();
    final path = await FilePicker.getDirectoryPath(
      dialogTitle: 'Save samples to folder',
      initialDirectory: cubit.state.lastCustomOutputFolder,
    );
    if (path == null) return;
    await cubit.saveCustomDraft(path);
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

Future<void> _confirmDiscardChanges(BuildContext context) async {
  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text('You have unsaved sample changes. Discard them?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Discard'),
          ),
        ],
      );
    },
  );
}
