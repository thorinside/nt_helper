import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

class PresetBrowserDialog extends StatefulWidget {
  final DistingCubit distingCubit;

  const PresetBrowserDialog({super.key, required this.distingCubit});

  @override
  State<PresetBrowserDialog> createState() => _PresetBrowserDialogState();
}

class _PresetBrowserDialogState extends State<PresetBrowserDialog> {
  // Drag and drop state
  bool _isDragOver = false;
  bool _isInstallingPackage = false;

  // Package analysis state (used for conflict detection and installation)
  PackageAnalysis? _currentAnalysis;
  Uint8List? _currentPackageData;

  @override
  void initState() {
    super.initState();
    // Load root directory when dialog opens
    context.read<PresetBrowserCubit>().loadRootDirectory();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    // Build the main content first
    Widget content = AlertDialog(
      title: Row(
        children: [
          const Text('Browse Presets'),
          const Spacer(),
          // Navigation controls
          BlocBuilder<PresetBrowserCubit, PresetBrowserState>(
            builder: (context, state) {
              return Row(
                children: [
                  // Back button
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
                  // Sort toggle
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
            // Main content area
            Expanded(
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
                          )
                        : ThreePanelNavigator(
                            leftPanelItems: loaded.leftPanelItems,
                            centerPanelItems: loaded.centerPanelItems,
                            rightPanelItems: loaded.rightPanelItems,
                            selectedLeftItem: loaded.selectedLeftItem,
                            selectedCenterItem: loaded.selectedCenterItem,
                            selectedRightItem: loaded.selectedRightItem,
                            onItemSelected: _handleItemSelected,
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
            // Progress indicator bar
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

                      // Extract plugin paths from AlgorithmInfo for slots in the preset
                      Map<String, String>? pluginPaths;
                      final state = widget.distingCubit.state;
                      if (state is DistingStateSynchronized) {
                        // Get algorithm indices from current preset's slots
                        final slotAlgorithmIndices = state.slots
                            .map((s) => s.algorithm.algorithmIndex)
                            .toSet();
                        // Filter to only AlgorithmInfos used in slots
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
    );

    // Only add drag and drop on desktop platforms
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
      // Go to root
      cubit.loadRootDirectory();
    } else {
      cubit.navigateToPathSegment(index);
    }
  }

  void _handleRefresh() {
    final cubit = context.read<PresetBrowserCubit>();
    cubit.clearCache();

    // Refresh current directory
    final state = cubit.state;
    state.maybeMap(
      loaded: (loaded) {
        if (loaded.drillPath != null && loaded.drillPath!.isNotEmpty) {
          // Reload current drill path
          cubit.navigateToPathSegment((loaded.breadcrumbs?.length ?? 1) - 1);
        } else {
          cubit.loadRootDirectory();
        }
      },
      orElse: () => cubit.loadRootDirectory(),
    );
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

    // Filter for supported files (zip packages only for E3.2)
    final supportedFiles = details.files.where((file) {
      final lowerPath = file.path.toLowerCase();
      return lowerPath.endsWith('.zip');
    }).toList();

    if (supportedFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please drop a preset package (.zip)'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (supportedFiles.length > 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please drop only one file at a time'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final file = supportedFiles.first;
    _processPackageFile(file);
  }

  Future<void> _processPackageFile(XFile file) async {
    setState(() {
      _isInstallingPackage = true;
    });

    try {
      // Read file data
      final fileBytes = await file.readAsBytes();

      // Validate and analyze the package
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

      // Analyze the package
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

      // Store analysis results and package data
      setState(() {
        _currentAnalysis = analysis;
        _currentPackageData = fileBytes;
      });

      // Story E3.3: Detect file conflicts with SD card
      final conflictDetector = FileConflictDetector(widget.distingCubit);
      final analysisWithConflicts = await conflictDetector.detectConflicts(
        analysis,
      );

      setState(() {
        _currentAnalysis = analysisWithConflicts;
      });

      // Story E3.4: Show the install dialog
      if (!mounted) return;

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => PackageInstallDialog(
          analysis: _currentAnalysis!,
          packageData: _currentPackageData!,
          distingCubit: widget.distingCubit,
          onInstall: () {
            Navigator.of(dialogContext).pop(); // Close PackageInstallDialog
            Navigator.of(context).pop(); // Close PresetBrowserDialog
          },
          onCancel: () {
            Navigator.of(dialogContext).pop();
          },
        ),
      );

      // Clear state after dialog closes
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
                  'Drop preset package here',
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

class ThreePanelNavigator extends StatelessWidget {
  final List<DirectoryEntry> leftPanelItems;
  final List<DirectoryEntry> centerPanelItems;
  final List<DirectoryEntry> rightPanelItems;
  final DirectoryEntry? selectedLeftItem;
  final DirectoryEntry? selectedCenterItem;
  final DirectoryEntry? selectedRightItem;
  final Function(DirectoryEntry, PanelPosition) onItemSelected;

  const ThreePanelNavigator({
    super.key,
    required this.leftPanelItems,
    required this.centerPanelItems,
    required this.rightPanelItems,
    this.selectedLeftItem,
    this.selectedCenterItem,
    this.selectedRightItem,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: DirectoryPanel(
            items: leftPanelItems,
            selectedItem: selectedLeftItem,
            onItemTap: (item) => onItemSelected(item, PanelPosition.left),
            position: PanelPosition.left,
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          child: DirectoryPanel(
            items: centerPanelItems,
            selectedItem: selectedCenterItem,
            onItemTap: (item) => onItemSelected(item, PanelPosition.center),
            position: PanelPosition.center,
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          child: DirectoryPanel(
            items: rightPanelItems,
            selectedItem: selectedRightItem,
            onItemTap: (item) => onItemSelected(item, PanelPosition.right),
            position: PanelPosition.right,
          ),
        ),
      ],
    );
  }
}

class DirectoryPanel extends StatelessWidget {
  final List<DirectoryEntry> items;
  final DirectoryEntry? selectedItem;
  final Function(DirectoryEntry) onItemTap;
  final PanelPosition position;

  const DirectoryPanel({
    super.key,
    required this.items,
    required this.selectedItem,
    required this.onItemTap,
    required this.position,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Container(
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
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: Theme.of(context).dividerColor, width: 0.5),
      ),
      child: ListView.builder(
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          final isSelected = item == selectedItem;

          // Clean up the display name
          String displayName = item.name;
          if (displayName.endsWith('/')) {
            displayName = displayName.substring(0, displayName.length - 1);
          }

          final isJsonPreset =
              !item.isDirectory && item.name.toLowerCase().endsWith('.json');
          final isParentDir = item.name == '..';

          return ListTile(
            leading: Icon(
              isParentDir
                  ? Icons.folder_open
                  : item.isDirectory
                  ? Icons.folder
                  : isJsonPreset
                  ? Icons.music_note
                  : Icons.insert_drive_file,
              color: isParentDir
                  ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.7)
                  : item.isDirectory
                  ? Theme.of(context).colorScheme.primary
                  : isJsonPreset
                  ? Theme.of(context).colorScheme.tertiary
                  : Theme.of(context).colorScheme.secondary,
            ),
            title: Text(
              displayName,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            subtitle: !item.isDirectory
                ? Text(
                    _formatFileSize(item.size),
                    style: const TextStyle(fontSize: 12),
                  )
                : null,
            selected: isSelected,
            selectedTileColor: Theme.of(context).colorScheme.primaryContainer,
            onTap: () => onItemTap(item),
            dense: true,
          );
        },
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
