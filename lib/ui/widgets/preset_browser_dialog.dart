import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nt_helper/cubit/preset_browser_cubit.dart';
import 'package:nt_helper/models/sd_card_file_system.dart';
import 'package:nt_helper/ui/widgets/load_preset_dialog.dart';

class PresetBrowserDialog extends StatefulWidget {
  const PresetBrowserDialog({super.key});

  @override
  State<PresetBrowserDialog> createState() => _PresetBrowserDialogState();
}

class _PresetBrowserDialogState extends State<PresetBrowserDialog> {
  @override
  void initState() {
    super.initState();
    // Load root directory when dialog opens
    context.read<PresetBrowserCubit>().loadRootDirectory();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
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
                            icon: const Icon(Icons.arrow_back),
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
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.6,
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
                    loaded: (loaded) => ThreePanelNavigator(
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
            return ElevatedButton(
              onPressed: selectedPath.isNotEmpty
                  ? () {
                      Navigator.of(context).pop({
                        'sdCardPath': selectedPath,
                        'action': PresetAction.load,
                        'displayName': selectedPath.split('/').last,
                      });
                    }
                  : null,
              child: const Text('Load'),
            );
          },
        ),
      ],
    );
  }

  void _handleItemSelected(DirectoryEntry item, PanelPosition position) {
    final cubit = context.read<PresetBrowserCubit>();

    if (item.isDirectory) {
      cubit.selectDirectory(item, position);
    } else {
      cubit.selectFile(item, position);
      // Update the state to enable the Load button
      setState(() {});
    }
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

          return ListTile(
            leading: Icon(
              item.isDirectory
                  ? Icons.folder
                  : isJsonPreset
                  ? Icons.music_note
                  : Icons.insert_drive_file,
              color: item.isDirectory
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
