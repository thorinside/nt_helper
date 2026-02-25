import 'dart:convert';

import 'package:cross_file/cross_file.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/cubit/preset_browser_cubit.dart';
import 'package:nt_helper/interfaces/impl/preset_file_system_impl.dart';
import 'package:nt_helper/models/package_analysis.dart';
import 'package:nt_helper/models/sd_card_file_system.dart';
import 'package:nt_helper/services/file_conflict_detector.dart';
import 'package:nt_helper/services/preset_package_analyzer.dart';
import 'package:nt_helper/models/preset_action.dart';
import 'package:nt_helper/ui/widgets/mobile_drill_down_navigator.dart';
import 'package:nt_helper/ui/widgets/package_install_dialog.dart';
import 'package:nt_helper/ui/widgets/preset_package_dialog.dart';
import 'package:nt_helper/utils/responsive.dart';
import 'package:nt_helper/services/preset_analyzer.dart';

enum _FileAction { download, upload, newFolder, rename, delete, view }

class _DeleteSelectedIntent extends Intent {
  const _DeleteSelectedIntent();
}

class PresetBrowserDialog extends StatefulWidget {
  final DistingCubit distingCubit;

  const PresetBrowserDialog({super.key, required this.distingCubit});

  @override
  State<PresetBrowserDialog> createState() => _PresetBrowserDialogState();
}

class _PresetBrowserDialogState extends State<PresetBrowserDialog> {
  bool _isDragOver = false;
  bool _isInstallingPackage = false;
  double? _uploadProgress;

  PackageAnalysis? _currentAnalysis;
  Uint8List? _currentPackageData;

  @override
  void initState() {
    super.initState();
    context.read<PresetBrowserCubit>().loadRootDirectory();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    Widget content = Shortcuts(
      shortcuts: <ShortcutActivator, Intent>{
        const SingleActivator(LogicalKeyboardKey.delete): const _DeleteSelectedIntent(),
        const SingleActivator(LogicalKeyboardKey.backspace): const _DeleteSelectedIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _DeleteSelectedIntent: CallbackAction<_DeleteSelectedIntent>(
            onInvoke: (_) {
              _deleteSelectedItem();
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          child: AlertDialog(
            title: Row(
              children: [
                const Text('File Browser'),
                const Spacer(),
                BlocBuilder<PresetBrowserCubit, PresetBrowserState>(
                  builder: (context, state) {
                    return Row(
                      children: [
                        state.maybeMap(
                          loaded: (loaded) => loaded.navigationHistory.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.arrow_back, semanticLabel: 'Back'),
                                  onPressed: () {
                                    context.read<PresetBrowserCubit>().navigateBack();
                                  },
                                  tooltip: 'Back',
                                )
                              : const SizedBox.shrink(),
                          orElse: () => const SizedBox.shrink(),
                        ),
                        state.maybeMap(
                          loaded: (loaded) => IconButton(
                            icon: Icon(
                              loaded.sortByDate
                                  ? Icons.date_range
                                  : Icons.sort_by_alpha,
                              semanticLabel: loaded.sortByDate
                                  ? 'Sort by date'
                                  : 'Sort alphabetically',
                            ),
                            onPressed: () {
                              context.read<PresetBrowserCubit>().toggleSortMode();
                            },
                            tooltip: loaded.sortByDate
                                ? 'Sort by date'
                                : 'Sort alphabetically',
                          ),
                          orElse: () => const SizedBox.shrink(),
                        ),
                      ],
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.close, semanticLabel: 'Close'),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Close',
                ),
              ],
            ),
            content: SizedBox(
              width: isMobile
                  ? MediaQuery.of(context).size.width * 0.95
                  : MediaQuery.of(context).size.width * 0.8,
              height: isMobile
                  ? MediaQuery.of(context).size.height * 0.7
                  : MediaQuery.of(context).size.height * 0.6,
              child: Column(
                children: [
                  // Desktop breadcrumb bar
                  if (!isMobile)
                    BlocBuilder<PresetBrowserCubit, PresetBrowserState>(
                      builder: (context, state) {
                        return state.maybeMap(
                          loaded: (loaded) =>
                              _buildDesktopBreadcrumbs(context, loaded),
                          orElse: () => const SizedBox.shrink(),
                        );
                      },
                    ),
                  if (_uploadProgress != null)
                    LinearProgressIndicator(
                      value: _uploadProgress,
                      minHeight: 2,
                    ),
                  Expanded(
                    child: ClipRect(
                    child: BlocBuilder<PresetBrowserCubit, PresetBrowserState>(
                      builder: (context, state) {
                        return state.map(
                          initial: (_) =>
                              const Center(child: CircularProgressIndicator()),
                          loading: (_) =>
                              const Center(child: CircularProgressIndicator()),
                          loaded: (loaded) => isMobile
                              ? MobileDrillDownNavigator(
                                  items:
                                      loaded.currentDrillItems ??
                                      loaded.leftPanelItems,
                                  selectedItem: loaded.selectedDrillItem,
                                  breadcrumbs: loaded.breadcrumbs ?? [],
                                  onItemTap: _handleMobileItemTap,
                                  onBreadcrumbTap: _handleBreadcrumbTap,
                                  onRefresh: _handleRefresh,
                                  onLongPress: (entry) {
                                    final drillPath =
                                        loaded.drillPath ?? loaded.currentPath;
                                    _showContextMenuAtCenter(entry, drillPath);
                                  },
                                )
                              : ThreePanelNavigator(
                                  leftPanelItems: loaded.leftPanelItems,
                                  centerPanelItems: loaded.centerPanelItems,
                                  rightPanelItems: loaded.rightPanelItems,
                                  selectedLeftItem: loaded.selectedLeftItem,
                                  selectedCenterItem: loaded.selectedCenterItem,
                                  selectedRightItem: loaded.selectedRightItem,
                                  onItemSelected: _handleItemSelected,
                                  currentPath: loaded.currentPath,
                                  onContextMenu: _handleContextMenu,
                                ),
                          error: (error) => Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  color: Colors.red,
                                  size: 48,
                                ),
                                const SizedBox(height: 16),
                                Text(error.message, textAlign: TextAlign.center),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () {
                                    context
                                        .read<PresetBrowserCubit>()
                                        .loadRootDirectory();
                                  },
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  ),
                  BlocBuilder<PresetBrowserCubit, PresetBrowserState>(
                    builder: (context, state) {
                      return state.maybeMap(
                        loading: (_) => const SizedBox(
                          height: 8,
                          child: LinearProgressIndicator(),
                        ),
                        orElse: () => const SizedBox(height: 8),
                      );
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Cancel'),
              ),
              BlocBuilder<PresetBrowserCubit, PresetBrowserState>(
                builder: (context, state) {
                  final selectedPath = context
                      .read<PresetBrowserCubit>()
                      .getSelectedPath();
                  final isPresetFile =
                      selectedPath.isNotEmpty &&
                      selectedPath.toLowerCase().endsWith('.json');
                  final isMobile = Responsive.isMobile(context);

                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isPresetFile && !isMobile) ...[
                        OutlinedButton(
                          onPressed: () async {
                            Navigator.of(context).pop();

                            Map<String, String>? pluginPaths;
                            final state = widget.distingCubit.state;
                            if (state is DistingStateSynchronized) {
                              final slotAlgorithmIndices = state.slots
                                  .map((s) => s.algorithm.algorithmIndex)
                                  .toSet();
                              final slotAlgorithms = state.algorithms
                                  .where((a) =>
                                      slotAlgorithmIndices.contains(a.algorithmIndex))
                                  .toList();
                              pluginPaths =
                                  PresetAnalyzer.extractPluginPaths(slotAlgorithms);
                            }

                            await showDialog<void>(
                              context: context,
                              builder: (dialogContext) => PresetPackageDialog(
                                presetFilePath: selectedPath,
                                fileSystem: PresetFileSystemImpl(
                                  widget.distingCubit.requireDisting(),
                                ),
                                database: widget.distingCubit.database,
                                pluginPaths: pluginPaths,
                              ),
                            );
                          },
                          child: const Text('Export'),
                        ),
                        const SizedBox(width: 8),
                      ],
                      ElevatedButton(
                        onPressed: isPresetFile
                            ? () {
                                Navigator.of(context).pop({
                                  'sdCardPath': selectedPath,
                                  'action': PresetAction.load,
                                  'displayName': selectedPath.split('/').last,
                                });
                              }
                            : null,
                        child: const Text('Load'),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );

    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.macOS ||
            defaultTargetPlatform == TargetPlatform.linux)) {
      return DropTarget(
        onDragDone: _handleDragDone,
        onDragEntered: _handleDragEntered,
        onDragExited: _handleDragExited,
        child: Stack(
          children: [
            content,
            if (_isDragOver) _buildDragOverlay(),
            if (_isInstallingPackage) _buildInstallOverlay(),
          ],
        ),
      );
    }

    return content;
  }

  Widget _buildDesktopBreadcrumbs(BuildContext context, dynamic loaded) {
    final currentPath = loaded.currentPath as String;
    final breadcrumbs = _getBreadcrumbsFromPath(currentPath);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 0.5,
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            Semantics(
              label: 'Navigate to root',
              button: true,
              child: InkWell(
                onTap: () {
                  context.read<PresetBrowserCubit>().navigateToAbsolutePath('/');
                },
                child: Tooltip(
                  message: 'Go to root',
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Icon(
                      Icons.home,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ),
            ...breadcrumbs.asMap().entries.map((entry) {
              final index = entry.key;
              final segment = entry.value;
              final isLast = index == breadcrumbs.length - 1;
              final pathUpTo = '/${breadcrumbs.take(index + 1).join('/')}';

              return Row(
                children: [
                  ExcludeSemantics(
                    child: Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Tooltip(
                    message: pathUpTo,
                    child: InkWell(
                      onTap: isLast
                          ? null
                          : () {
                              context
                                  .read<PresetBrowserCubit>()
                                  .navigateToAbsolutePath(pathUpTo);
                            },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8.0,
                          vertical: 8.0,
                        ),
                        child: Text(
                          segment,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight:
                                isLast ? FontWeight.bold : FontWeight.normal,
                            color: isLast
                                ? Theme.of(context).colorScheme.onSurfaceVariant
                                : Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  List<String> _getBreadcrumbsFromPath(String path) {
    if (path == '/' || path.isEmpty) return [];
    return path.split('/').where((s) => s.isNotEmpty).toList();
  }

  void _handleItemSelected(DirectoryEntry item, PanelPosition position) {
    final cubit = context.read<PresetBrowserCubit>();

    if (item.isDirectory) {
      cubit.selectDirectory(item, position);
    } else {
      cubit.selectFile(item, position);
    }
  }

  void _handleMobileItemTap(DirectoryEntry item) {
    final cubit = context.read<PresetBrowserCubit>();

    if (item.isDirectory) {
      cubit.navigateIntoDirectory(item);
    } else {
      cubit.selectDrillItem(item);
    }
  }

  void _handleBreadcrumbTap(int index) {
    final cubit = context.read<PresetBrowserCubit>();

    if (index == -1) {
      cubit.loadRootDirectory();
    } else {
      cubit.navigateToPathSegment(index);
    }
  }

  void _handleRefresh() {
    final cubit = context.read<PresetBrowserCubit>();
    cubit.clearCache();

    final state = cubit.state;
    state.maybeMap(
      loaded: (loaded) {
        if (loaded.drillPath != null && loaded.drillPath!.isNotEmpty) {
          cubit.navigateToPathSegment((loaded.breadcrumbs?.length ?? 1) - 1);
        } else {
          cubit.loadRootDirectory();
        }
      },
      orElse: () => cubit.loadRootDirectory(),
    );
  }

  void _handleContextMenu(
    DirectoryEntry entry,
    Offset position,
    String panelPath,
  ) {
    if (entry.name == '..') return;
    _showContextMenu(entry, position, panelPath);
  }

  void _showContextMenuAtCenter(DirectoryEntry entry, String panelPath) {
    if (entry.name == '..') return;
    final box = context.findRenderObject() as RenderBox;
    final center = box.localToGlobal(
      Offset(box.size.width / 2, box.size.height / 2),
    );
    _showContextMenu(entry, center, panelPath);
  }

  void _showContextMenu(
    DirectoryEntry entry,
    Offset position,
    String panelPath,
  ) {
    final cubit = context.read<PresetBrowserCubit>();
    final entryPath = cubit.getEntryPath(entry, panelPath);
    final isFile = !entry.isDirectory;
    final isTextFile = _isTextFile(entry.name);

    final items = <PopupMenuEntry<_FileAction>>[];

    if (isTextFile) {
      items.add(const PopupMenuItem(
        value: _FileAction.view,
        child: ListTile(
          leading: Icon(Icons.visibility),
          title: Text('View'),
          dense: true,
          contentPadding: EdgeInsets.zero,
        ),
      ));
    }

    if (isFile) {
      items.add(const PopupMenuItem(
        value: _FileAction.download,
        child: ListTile(
          leading: Icon(Icons.download),
          title: Text('Download'),
          dense: true,
          contentPadding: EdgeInsets.zero,
        ),
      ));
    }

    items.addAll([
      const PopupMenuItem(
        value: _FileAction.upload,
        child: ListTile(
          leading: Icon(Icons.upload),
          title: Text('Upload Here'),
          dense: true,
          contentPadding: EdgeInsets.zero,
        ),
      ),
      const PopupMenuItem(
        value: _FileAction.newFolder,
        child: ListTile(
          leading: Icon(Icons.create_new_folder),
          title: Text('New Folder'),
          dense: true,
          contentPadding: EdgeInsets.zero,
        ),
      ),
      const PopupMenuItem(
        value: _FileAction.rename,
        child: ListTile(
          leading: Icon(Icons.edit),
          title: Text('Rename'),
          dense: true,
          contentPadding: EdgeInsets.zero,
        ),
      ),
      const PopupMenuItem(
        value: _FileAction.delete,
        child: ListTile(
          leading: Icon(Icons.delete),
          title: Text('Delete'),
          dense: true,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    ]);

    showMenu<_FileAction>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx + 1,
        position.dy + 1,
      ),
      items: items,
    ).then((action) {
      if (action == null) return;
      switch (action) {
        case _FileAction.download:
          _downloadFile(entryPath, entry.name);
        case _FileAction.upload:
          final targetDir =
              entry.isDirectory ? entryPath : panelPath;
          _uploadFileAction(targetDir);
        case _FileAction.newFolder:
          final targetDir =
              entry.isDirectory ? entryPath : panelPath;
          _createFolderAction(targetDir);
        case _FileAction.rename:
          _renameAction(entryPath, entry.name);
        case _FileAction.delete:
          _deleteAction(entryPath, entry.name);
        case _FileAction.view:
          _viewTextFile(entryPath, entry.name);
      }
    });
  }

  bool _isTextFile(String name) {
    final lower = name.toLowerCase();
    return lower.endsWith('.txt') || lower.endsWith('.md');
  }

  Future<void> _downloadFile(String path, String fileName) async {
    final cubit = context.read<PresetBrowserCubit>();

    try {
      final data = await cubit.downloadFile(path);
      if (data == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to download file'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Save $fileName',
        fileName: fileName,
        bytes: data,
      );

      if (result != null && mounted) {
        SemanticsService.sendAnnouncement(
          View.of(context),
          'Downloaded $fileName',
          TextDirection.ltr,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Downloaded $fileName')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _uploadFileAction(String targetDirectory) async {
    final cubit = context.read<PresetBrowserCubit>();
    final result = await FilePicker.platform.pickFiles();
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    if (file.bytes == null && file.path == null) return;

    final Uint8List bytes;
    if (file.bytes != null) {
      bytes = file.bytes!;
    } else {
      final xfile = XFile(file.path!);
      bytes = await xfile.readAsBytes();
    }

    try {
      setState(() => _uploadProgress = 0);
      await cubit.uploadFile(targetDirectory, file.name, bytes,
        onProgress: (progress) {
          if (mounted) setState(() => _uploadProgress = progress);
        },
      );
      if (mounted) {
        setState(() => _uploadProgress = null);
        SemanticsService.sendAnnouncement(View.of(context),
          'Uploaded ${file.name}',
          TextDirection.ltr,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Uploaded ${file.name}')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _uploadProgress = null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _createFolderAction(String parentDirectory) async {
    final cubit = context.read<PresetBrowserCubit>();
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Semantics(
          header: true,
          child: const Text('New Folder'),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Folder name',
            hintText: 'Enter folder name',
          ),
          onSubmitted: (value) => Navigator.of(context).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (name == null || name.trim().isEmpty) return;

    try {
      await cubit.createDirectory(parentDirectory, name.trim());
      if (mounted) {
        SemanticsService.sendAnnouncement(View.of(context),
          'Created folder ${name.trim()}',
          TextDirection.ltr,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Created folder ${name.trim()}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create folder: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _renameAction(String fullPath, String currentName) async {
    final cubit = context.read<PresetBrowserCubit>();
    final cleanName = currentName.endsWith('/')
        ? currentName.substring(0, currentName.length - 1)
        : currentName;
    final controller = TextEditingController(text: cleanName);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Semantics(
          header: true,
          child: const Text('Rename'),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'New name',
          ),
          onSubmitted: (value) => Navigator.of(context).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Rename'),
          ),
        ],
      ),
    );

    if (newName == null || newName.trim().isEmpty || newName.trim() == cleanName) {
      return;
    }

    try {
      await cubit.renameEntry(fullPath, newName.trim());
      if (mounted) {
        SemanticsService.sendAnnouncement(View.of(context),
          'Renamed to ${newName.trim()}',
          TextDirection.ltr,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Renamed to ${newName.trim()}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rename failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteAction(String fullPath, String name) async {
    final cubit = context.read<PresetBrowserCubit>();
    final cleanName = name.endsWith('/')
        ? name.substring(0, name.length - 1)
        : name;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Semantics(
          header: true,
          child: const Text('Delete'),
        ),
        content: Text('Delete "$cleanName"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await cubit.deleteEntry(fullPath);
      if (mounted) {
        SemanticsService.sendAnnouncement(View.of(context),
          'Deleted $cleanName',
          TextDirection.ltr,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Deleted $cleanName')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Delete failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _deleteSelectedItem() {
    final cubit = context.read<PresetBrowserCubit>();
    final selectedPath = cubit.getSelectedPath();
    if (selectedPath.isEmpty) return;

    final name = selectedPath.split('/').last;
    _deleteAction(selectedPath, name);
  }

  Future<void> _viewTextFile(String path, String fileName) async {
    final cubit = context.read<PresetBrowserCubit>();

    try {
      final data = await cubit.downloadFile(path);
      if (data == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to download file for preview'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final text = utf8.decode(data, allowMalformed: true);
      final isMarkdown = fileName.toLowerCase().endsWith('.md');

      if (!mounted) return;

      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Semantics(
            header: true,
            child: Text(fileName),
          ),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.6,
            height: MediaQuery.of(context).size.height * 0.5,
            child: isMarkdown
                ? Markdown(data: text)
                : SingleChildScrollView(
                    child: SelectableText(
                      text,
                      style: const TextStyle(fontFamily: 'monospace'),
                    ),
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to view file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Drag and drop handlers
  void _handleDragEntered(DropEventDetails details) {
    setState(() {
      _isDragOver = true;
    });
  }

  void _handleDragExited(DropEventDetails details) {
    setState(() {
      _isDragOver = false;
    });
  }

  void _handleDragDone(DropDoneDetails details) {
    setState(() {
      _isDragOver = false;
    });

    if (details.files.isEmpty) return;

    if (details.files.length > 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please drop only one file at a time'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final file = details.files.first;
    final lowerPath = file.path.toLowerCase();

    if (lowerPath.endsWith('.zip')) {
      _processPackageFile(file);
    } else {
      _uploadDroppedFile(file);
    }
  }

  Future<void> _uploadDroppedFile(XFile file) async {
    final cubit = context.read<PresetBrowserCubit>();
    final bytes = await file.readAsBytes();
    final fileName = file.path.split('/').last.split('\\').last;
    final targetDir = cubit.getSelectedDirectoryPath();

    try {
      setState(() => _uploadProgress = 0);
      await cubit.uploadFile(targetDir, fileName, bytes,
        onProgress: (progress) {
          if (mounted) setState(() => _uploadProgress = progress);
        },
      );
      if (mounted) {
        setState(() => _uploadProgress = null);
        SemanticsService.sendAnnouncement(View.of(context),
          'Uploaded $fileName',
          TextDirection.ltr,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Uploaded $fileName')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _uploadProgress = null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _processPackageFile(XFile file) async {
    setState(() {
      _isInstallingPackage = true;
    });

    try {
      final fileBytes = await file.readAsBytes();

      final isValid = await PresetPackageAnalyzer.isValidPackage(fileBytes);
      if (!isValid) {
        setState(() {
          _isInstallingPackage = false;
        });
        _showValidationErrorDialog(
          'Invalid Package Format',
          'The dropped file is not a valid preset package. Please ensure it contains a manifest.json file and a root/ directory with the preset files.',
        );
        return;
      }

      final analysis = await PresetPackageAnalyzer.analyzePackage(fileBytes);
      if (!analysis.isValid) {
        setState(() {
          _isInstallingPackage = false;
        });
        _showValidationErrorDialog(
          'Package Analysis Failed',
          analysis.errorMessage ?? 'Unable to analyze the package contents.',
        );
        return;
      }

      setState(() {
        _currentAnalysis = analysis;
        _currentPackageData = fileBytes;
      });

      final conflictDetector = FileConflictDetector(widget.distingCubit);
      final analysisWithConflicts = await conflictDetector.detectConflicts(
        analysis,
      );

      setState(() {
        _currentAnalysis = analysisWithConflicts;
      });

      if (!mounted) return;

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => PackageInstallDialog(
          analysis: _currentAnalysis!,
          packageData: _currentPackageData!,
          distingCubit: widget.distingCubit,
          onInstall: () {
            Navigator.of(dialogContext).pop();
            Navigator.of(context).pop();
          },
          onCancel: () {
            Navigator.of(dialogContext).pop();
          },
        ),
      );

      setState(() {
        _currentAnalysis = null;
        _currentPackageData = null;
        _isInstallingPackage = false;
      });
    } catch (e, stackTrace) {
      debugPrintStack(stackTrace: stackTrace);

      setState(() {
        _isInstallingPackage = false;
      });

      _showValidationErrorDialog(
        'Package Processing Error',
        'An unexpected error occurred while processing the package:\n\n$e',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isInstallingPackage = false;
        });
      }
    }
  }

  void _showValidationErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error, color: Theme.of(context).colorScheme.error),
            const SizedBox(width: 8),
            Expanded(child: Text(title)),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(message, style: Theme.of(context).textTheme.bodyMedium),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildDragOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.blue.withValues(alpha: 0.1),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.upload_file,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Drop file to upload',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInstallOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.5),
        child: const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class ThreePanelNavigator extends StatefulWidget {
  final List<DirectoryEntry> leftPanelItems;
  final List<DirectoryEntry> centerPanelItems;
  final List<DirectoryEntry> rightPanelItems;
  final DirectoryEntry? selectedLeftItem;
  final DirectoryEntry? selectedCenterItem;
  final DirectoryEntry? selectedRightItem;
  final Function(DirectoryEntry, PanelPosition) onItemSelected;
  final String currentPath;
  final Function(DirectoryEntry, Offset, String panelPath)? onContextMenu;

  const ThreePanelNavigator({
    super.key,
    required this.leftPanelItems,
    required this.centerPanelItems,
    required this.rightPanelItems,
    this.selectedLeftItem,
    this.selectedCenterItem,
    this.selectedRightItem,
    required this.onItemSelected,
    required this.currentPath,
    this.onContextMenu,
  });

  @override
  State<ThreePanelNavigator> createState() => _ThreePanelNavigatorState();
}

class _ThreePanelNavigatorState extends State<ThreePanelNavigator> {
  final FocusNode _leftFocusNode = FocusNode();
  final FocusNode _centerFocusNode = FocusNode();
  final FocusNode _rightFocusNode = FocusNode();

  @override
  void dispose() {
    _leftFocusNode.dispose();
    _centerFocusNode.dispose();
    _rightFocusNode.dispose();
    super.dispose();
  }

  String _cleanName(String name) {
    return name.endsWith('/') ? name.substring(0, name.length - 1) : name;
  }

  String _joinPath(String base, String child) {
    if (base.endsWith('/')) return '$base$child';
    return '$base/$child';
  }

  @override
  Widget build(BuildContext context) {
    final leftPath = widget.currentPath;

    String centerPath = widget.currentPath;
    if (widget.selectedLeftItem != null && widget.selectedLeftItem!.isDirectory) {
      centerPath = _joinPath(widget.currentPath, _cleanName(widget.selectedLeftItem!.name));
    }

    String rightPath = centerPath;
    if (widget.selectedCenterItem != null && widget.selectedCenterItem!.isDirectory) {
      rightPath = _joinPath(centerPath, _cleanName(widget.selectedCenterItem!.name));
    }

    return Row(
      children: [
        Expanded(
          child: DirectoryPanel(
            items: widget.leftPanelItems,
            selectedItem: widget.selectedLeftItem,
            onItemTap: (item) => widget.onItemSelected(item, PanelPosition.left),
            position: PanelPosition.left,
            currentPath: leftPath,
            onContextMenu: widget.onContextMenu,
            focusNode: _leftFocusNode,
            nextPanelFocusNode: _centerFocusNode,
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          child: DirectoryPanel(
            items: widget.centerPanelItems,
            selectedItem: widget.selectedCenterItem,
            onItemTap: (item) => widget.onItemSelected(item, PanelPosition.center),
            position: PanelPosition.center,
            currentPath: centerPath,
            onContextMenu: widget.onContextMenu,
            focusNode: _centerFocusNode,
            nextPanelFocusNode: _rightFocusNode,
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          child: DirectoryPanel(
            items: widget.rightPanelItems,
            selectedItem: widget.selectedRightItem,
            onItemTap: (item) => widget.onItemSelected(item, PanelPosition.right),
            position: PanelPosition.right,
            currentPath: rightPath,
            onContextMenu: widget.onContextMenu,
            focusNode: _rightFocusNode,
          ),
        ),
      ],
    );
  }
}

IconData _getFileIcon(String name) {
  final lower = name.toLowerCase();
  if (lower.endsWith('.scl') || lower.endsWith('.kbm')) return Icons.tune;
  if (lower.endsWith('.wav') || lower.endsWith('.aif')) return Icons.graphic_eq;
  if (lower.endsWith('.lua') ||
      lower.endsWith('.3pot') ||
      lower.endsWith('.o')) {
    return Icons.code;
  }
  if (lower.endsWith('.zip')) return Icons.folder_zip;
  if (lower.endsWith('.json')) return Icons.music_note;
  return Icons.insert_drive_file;
}

class DirectoryPanel extends StatefulWidget {
  final List<DirectoryEntry> items;
  final DirectoryEntry? selectedItem;
  final Function(DirectoryEntry) onItemTap;
  final PanelPosition position;
  final String currentPath;
  final Function(DirectoryEntry, Offset, String panelPath)? onContextMenu;
  final FocusNode? focusNode;
  final FocusNode? nextPanelFocusNode;

  const DirectoryPanel({
    super.key,
    required this.items,
    required this.selectedItem,
    required this.onItemTap,
    required this.position,
    required this.currentPath,
    this.onContextMenu,
    this.focusNode,
    this.nextPanelFocusNode,
  });

  @override
  State<DirectoryPanel> createState() => _DirectoryPanelState();
}

class _DirectoryPanelState extends State<DirectoryPanel> {
  FocusNode? _ownedFocusNode;
  FocusNode get _focusNode => widget.focusNode ?? (_ownedFocusNode ??= FocusNode());
  final ScrollController _scrollController = ScrollController();
  int _focusedIndex = 0;
  bool _showKeyboardFocus = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _ownedFocusNode?.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(DirectoryPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusNode != oldWidget.focusNode) {
      oldWidget.focusNode?.removeListener(_onFocusChange);
      _focusNode.addListener(_onFocusChange);
    }
    if (widget.items != oldWidget.items) {
      _focusedIndex = 0;
    }
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      setState(() => _showKeyboardFocus = true);
      _announceCurrentItem();
    } else {
      setState(() => _showKeyboardFocus = false);
    }
  }

  void _announceCurrentItem() {
    if (_focusedIndex < 0 || _focusedIndex >= widget.items.length) return;
    final item = widget.items[_focusedIndex];
    final label = _semanticLabel(item);
    SemanticsService.sendAnnouncement(
      View.of(context),
      label,
      TextDirection.ltr,
    );
  }

  String _semanticLabel(DirectoryEntry item) {
    String displayName = item.name;
    if (displayName.endsWith('/')) {
      displayName = displayName.substring(0, displayName.length - 1);
    }
    if (item.isDirectory) return 'Folder: $displayName';
    final fileInfo = _formatFileInfo(item);
    return 'File: $displayName, $fileInfo';
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    if (widget.items.isEmpty) return KeyEventResult.ignored;

    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      if (_focusedIndex < widget.items.length - 1) {
        setState(() {
          _focusedIndex++;
          _showKeyboardFocus = true;
        });
        _scrollToFocused();
        _announceCurrentItem();
      }
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      if (_focusedIndex > 0) {
        setState(() {
          _focusedIndex--;
          _showKeyboardFocus = true;
        });
        _scrollToFocused();
        _announceCurrentItem();
      }
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.space) {
      if (_focusedIndex >= 0 && _focusedIndex < widget.items.length) {
        final item = widget.items[_focusedIndex];
        widget.onItemTap(item);
        if (item.isDirectory && widget.nextPanelFocusNode != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            widget.nextPanelFocusNode!.requestFocus();
          });
        }
      }
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.home) {
      setState(() {
        _focusedIndex = 0;
        _showKeyboardFocus = true;
      });
      _scrollToFocused();
      _announceCurrentItem();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.end) {
      setState(() {
        _focusedIndex = widget.items.length - 1;
        _showKeyboardFocus = true;
      });
      _scrollToFocused();
      _announceCurrentItem();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  void _scrollToFocused() {
    if (!_scrollController.hasClients) return;
    // Use approximate item height for smooth scrolling
    const itemHeight = 52.0;
    final targetOffset = _focusedIndex * itemHeight;
    final viewportHeight = _scrollController.position.viewportDimension;
    final currentOffset = _scrollController.offset;

    if (targetOffset < currentOffset) {
      _scrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
      );
    } else if (targetOffset + itemHeight > currentOffset + viewportHeight) {
      _scrollController.animateTo(
        targetOffset + itemHeight - viewportHeight,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final panelLabel = switch (widget.position) {
      PanelPosition.left => 'Left panel',
      PanelPosition.center => 'Center panel',
      PanelPosition.right => 'Right panel',
    };

    if (widget.items.isEmpty) {
      return Semantics(
        label: '$panelLabel, empty',
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border.all(color: Theme.of(context).dividerColor, width: 0.5),
          ),
          child: const Center(
            child: Text(
              'Empty',
              style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
            ),
          ),
        ),
      );
    }

    return Semantics(
      label: '$panelLabel, ${widget.items.length} items',
      child: Focus(
        focusNode: _focusNode,
        onKeyEvent: _handleKeyEvent,
        child: FocusTraversalGroup(
          descendantsAreTraversable: false,
          child: Container(
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
              border: Border.all(
                color: _showKeyboardFocus && _focusNode.hasFocus
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).dividerColor,
                width: _showKeyboardFocus && _focusNode.hasFocus ? 2.0 : 0.5,
              ),
            ),
            child: Material(
              color: Theme.of(context).colorScheme.surface,
              child: ListView.builder(
                controller: _scrollController,
                itemCount: widget.items.length,
                itemBuilder: (context, index) =>
                    _buildItem(context, index),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildItem(BuildContext context, int index) {
    final item = widget.items[index];
    final isSelected = item == widget.selectedItem;
    final isKeyboardFocused =
        _showKeyboardFocus && _focusNode.hasFocus && index == _focusedIndex;

    String displayName = item.name;
    if (displayName.endsWith('/')) {
      displayName = displayName.substring(0, displayName.length - 1);
    }

    final isParentDir = item.name == '..';

    final icon = isParentDir
        ? Icons.folder_open
        : item.isDirectory
        ? Icons.folder
        : _getFileIcon(item.name);

    final isJsonPreset =
        !item.isDirectory && item.name.toLowerCase().endsWith('.json');

    final iconColor = isParentDir
        ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.7)
        : item.isDirectory
        ? Theme.of(context).colorScheme.primary
        : isJsonPreset
        ? Theme.of(context).colorScheme.tertiary
        : Theme.of(context).colorScheme.secondary;

    final fileInfo = !item.isDirectory ? _formatFileInfo(item) : null;

    Widget tile = Container(
      decoration: isKeyboardFocused
          ? BoxDecoration(
              border: Border.all(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(4),
            )
          : null,
      child: ListTile(
        leading: Icon(icon, color: iconColor),
        title: Text(
          displayName,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: fileInfo != null
            ? Text(fileInfo, style: const TextStyle(fontSize: 12))
            : null,
        selected: isSelected,
        selectedTileColor: Theme.of(context).colorScheme.primaryContainer,
        onTap: () {
          setState(() {
            _focusedIndex = index;
            _showKeyboardFocus = false;
          });
          widget.onItemTap(item);
        },
        dense: true,
      ),
    );

    if (!isParentDir && widget.onContextMenu != null) {
      tile = GestureDetector(
        onSecondaryTapUp: (details) {
          widget.onContextMenu!(item, details.globalPosition, widget.currentPath);
        },
        onLongPressEnd: (details) {
          widget.onContextMenu!(item, details.globalPosition, widget.currentPath);
        },
        child: tile,
      );
    }

    return tile;
  }

  static String _formatFileInfo(DirectoryEntry entry) {
    final size = _formatFileSize(entry.size);
    final dateTime = _formatFatDateTime(entry.date, entry.time);
    if (dateTime != null) return '$size · $dateTime';
    return size;
  }

  static String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  static String? _formatFatDateTime(int fatDate, int fatTime) {
    if (fatDate == 0) return null;
    final day = fatDate & 0x1F;
    final month = (fatDate >> 5) & 0x0F;
    final year = ((fatDate >> 9) & 0x7F) + 1980;
    if (month < 1 || month > 12 || day < 1 || day > 31) return null;
    final hour = (fatTime >> 11) & 0x1F;
    final minute = (fatTime >> 5) & 0x3F;
    final dt = DateTime(year, month, day, hour, minute);
    return DateFormat.yMMMd().add_jm().format(dt);
  }
}
