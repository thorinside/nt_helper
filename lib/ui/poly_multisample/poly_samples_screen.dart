import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/poly_multisample/poly_multisample_models.dart';
import 'package:nt_helper/ui/poly_multisample/dialogs/poly_decent_import_dialog.dart';
import 'package:nt_helper/ui/poly_multisample/dialogs/poly_loose_wav_import_dialog.dart';
import 'package:nt_helper/ui/poly_multisample/dialogs/poly_sample_upload_dialog.dart';
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
        final hasUnsavedWork = _hasUnsavedWork(state);
        return PopScope(
          canPop: !hasUnsavedWork,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop || !hasUnsavedWork) return;
            _confirmDiscardChanges(
              context,
              onDiscard: () async {
                final cubit = context.read<PolyMultisampleBuilderCubit>();
                if (cubit.state.sourceMode ==
                        PolySampleSourceMode.importDraft ||
                    cubit.state.sourceMode ==
                        PolySampleSourceMode.customDraft) {
                  await cubit.returnToSources();
                } else {
                  cubit.discardChanges();
                }
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (context.mounted) Navigator.of(context).pop();
                });
              },
            );
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
      onUpload: () => _upload(context),
      onBackToSources: () => _backToSources(context, state),
    );
  }

  Future<void> _backToSources(
    BuildContext context,
    PolyMultisampleBuilderState state,
  ) async {
    final cubit = context.read<PolyMultisampleBuilderCubit>();
    if (!_hasUnsavedWork(state)) {
      await cubit.returnToSources();
      return;
    }
    await _confirmDiscardChanges(context, onDiscard: cubit.returnToSources);
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
      initialDirectory: cubit.state.lastSourceFolder,
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
    await cubit.rememberSourceFolder(p.dirname(paths.first));
    if (!context.mounted) return;

    PolyStagedImport? staged;
    final single = paths.length == 1 ? paths.single : null;
    final lower = single?.toLowerCase();
    if (single != null &&
        (lower!.endsWith('.dspreset') ||
            lower.endsWith('.dslibrary') ||
            lower.endsWith('.zip'))) {
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

  Future<void> _upload(BuildContext context) async {
    final cubit = context.read<PolyMultisampleBuilderCubit>();
    final manager = distingCubit.disting();
    final choice = await showPolySampleUploadPathDialog(
      context,
      sysexAvailable: manager != null,
    );
    if (choice == null || !context.mounted) return;
    switch (choice.path) {
      case PolySampleUploadPath.sysex:
        await cubit.uploadViaSysEx(
          manager!,
          verifyAfterUpload: choice.verifyAfterUpload,
        );
        break;
      case PolySampleUploadPath.mountedSd:
        final destination = await FilePicker.getDirectoryPath(
          dialogTitle: 'Upload samples to mounted SD-card folder',
          initialDirectory:
              cubit.state.lastMountedUploadFolder ??
              cubit.state.lastCustomOutputFolder ??
              (cubit.state.lastLocalFolder == null
                  ? null
                  : p.dirname(cubit.state.lastLocalFolder!)),
        );
        if (destination == null || !context.mounted) return;
        await cubit.uploadViaMountedSd(destination);
        break;
    }
  }

  Future<void> _saveAs(BuildContext context) async {
    final cubit = context.read<PolyMultisampleBuilderCubit>();
    final path = await _chooseSaveFolder(context, cubit);
    if (path == null) return;
    await cubit.saveCustomDraft(path);
  }
}

Future<String?> _chooseSaveFolder(
  BuildContext context,
  PolyMultisampleBuilderCubit cubit,
) async {
  return showDialog<String>(
    context: context,
    builder: (dialogContext) {
      return _SaveFolderDialog(
        initialParent:
            cubit.state.lastCustomOutputFolder ??
            (cubit.state.lastLocalFolder == null
                ? null
                : p.dirname(cubit.state.lastLocalFolder!)) ??
            Directory.current.path,
        initialName:
            cubit.state.currentInstrument?.name.replaceAll(
              RegExp(r'[\\/:*?"<>|]'),
              '_',
            ) ??
            'Untitled',
      );
    },
  );
}

class _SaveFolderDialog extends StatefulWidget {
  const _SaveFolderDialog({
    required this.initialParent,
    required this.initialName,
  });

  final String initialParent;
  final String initialName;

  @override
  State<_SaveFolderDialog> createState() => _SaveFolderDialogState();
}

class _SaveFolderDialogState extends State<_SaveFolderDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _parentController;
  late final TextEditingController _nameController;
  String? _createError;

  @override
  void initState() {
    super.initState();
    _parentController = TextEditingController(text: widget.initialParent);
    _nameController = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _parentController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Save samples as folder'),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _parentController,
                  decoration: InputDecoration(
                    labelText: 'Parent folder',
                    suffixIcon: IconButton(
                      tooltip: 'Browse parent folder',
                      icon: const Icon(Icons.folder_open),
                      onPressed: () async {
                        final path = await FilePicker.getDirectoryPath(
                          dialogTitle: 'Choose parent folder',
                          initialDirectory: _parentController.text,
                        );
                        if (path != null) _parentController.text = path;
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Choose a parent folder.';
                    }
                    if (!Directory(value.trim()).existsSync()) {
                      return 'Parent folder does not exist.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'New or existing folder name',
                  ),
                  validator: (value) {
                    if (_createError != null) return _createError;
                    final name = value?.trim() ?? '';
                    if (name.isEmpty) return 'Enter a folder name.';
                    if (name == '.' || name == '..') {
                      return 'Enter a folder name, not a relative path.';
                    }
                    if (name.contains(RegExp(r'[\\/:*?"<>|]'))) {
                      return 'Folder name contains invalid characters.';
                    }
                    return null;
                  },
                ),
                if (_createError != null) ...[
                  const SizedBox(height: 8),
                  Semantics(
                    label: 'Folder creation failed: $_createError',
                    liveRegion: true,
                    child: ExcludeSemantics(
                      child: Text(
                        _createError!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            setState(() {
              _createError = null;
            });
            if (!(_formKey.currentState?.validate() ?? false)) return;
            final path = p.join(
              _parentController.text.trim(),
              _nameController.text.trim(),
            );
            try {
              Directory(path).createSync(recursive: true);
            } catch (error) {
              setState(() {
                _createError = 'Could not create folder: $error';
              });
              _formKey.currentState?.validate();
              return;
            }
            Navigator.of(context).pop(path);
          },
          child: const Text('Save'),
        ),
      ],
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

Future<void> _confirmDiscardChanges(
  BuildContext context, {
  required Future<void> Function() onDiscard,
}) async {
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
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await onDiscard();
            },
            child: const Text('Discard'),
          ),
        ],
      );
    },
  );
}

bool _hasUnsavedWork(PolyMultisampleBuilderState state) {
  return state.isDirty ||
      ((state.sourceMode == PolySampleSourceMode.importDraft ||
              state.sourceMode == PolySampleSourceMode.customDraft) &&
          state.editedRegions.isNotEmpty);
}
