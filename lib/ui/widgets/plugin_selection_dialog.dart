import 'package:flutter/material.dart';
import 'package:nt_helper/models/gallery_models.dart';

/// Dialog for selecting individual plugins from a collection
class PluginSelectionDialog extends StatefulWidget {
  final GalleryPlugin plugin;
  final List<CollectionPlugin> availablePlugins;
  final Function(List<CollectionPlugin> selectedPlugins) onSelectionChanged;

  const PluginSelectionDialog({
    super.key,
    required this.plugin,
    required this.availablePlugins,
    required this.onSelectionChanged,
  });

  @override
  State<PluginSelectionDialog> createState() => _PluginSelectionDialogState();
}

class _PluginSelectionDialogState extends State<PluginSelectionDialog> {
  late List<CollectionPlugin> plugins;
  late List<CollectionPlugin> filteredPlugins;
  TextEditingController searchController = TextEditingController();
  bool selectAll = true;

  @override
  void initState() {
    super.initState();
    plugins = widget.availablePlugins.map((p) => p.copyWith()).toList();
    filteredPlugins = List.from(plugins);
    searchController.addListener(_filterPlugins);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void _filterPlugins() {
    setState(() {
      final query = searchController.text.toLowerCase();
      if (query.isEmpty) {
        filteredPlugins = List.from(plugins);
      } else {
        filteredPlugins = plugins
            .where(
              (plugin) =>
                  plugin.name.toLowerCase().contains(query) ||
                  (plugin.description?.toLowerCase().contains(query) ?? false),
            )
            .toList();
      }
    });
  }

  void _toggleSelectAll() {
    setState(() {
      selectAll = !selectAll;
      for (int i = 0; i < plugins.length; i++) {
        plugins[i] = plugins[i].copyWith(selected: selectAll);
      }
      _filterPlugins(); // Refresh filtered list
    });
  }

  void _togglePlugin(int index) {
    setState(() {
      final pluginIndex = plugins.indexOf(filteredPlugins[index]);
      if (pluginIndex >= 0) {
        plugins[pluginIndex] = plugins[pluginIndex].copyWith(
          selected: !plugins[pluginIndex].selected,
        );
      }
      _filterPlugins(); // Refresh filtered list
    });
  }

  int get selectedCount => plugins.where((p) => p.selected).length;

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (dlgContext) {
        return AlertDialog(
          title: Row(
            children: [
              ExcludeSemantics(
                child: Icon(_getPluginIcon(widget.plugin.type)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Select Plugins: ${widget.plugin.name}',
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 500,
            height: 600,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Plugin info
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.plugin.description,
                          style: Theme.of(dlgContext).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Collection contains ${plugins.length} plugins',
                          style: Theme.of(dlgContext).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  dlgContext,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Search bar
                TextField(
                  controller: searchController,
                  decoration: const InputDecoration(
                    hintText: 'Search plugins...',
                    prefixIcon: ExcludeSemantics(child: Icon(Icons.search)),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // Selection controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        '$selectedCount of ${plugins.length} selected',
                        style: Theme.of(dlgContext).textTheme.bodySmall,
                      ),
                    ),
                    TextButton(
                      onPressed: _toggleSelectAll,
                      child: Text(selectAll ? 'Deselect All' : 'Select All'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Plugin list
                Expanded(
                  child: ListView.builder(
                    itemCount: filteredPlugins.length,
                    itemBuilder: (context, index) {
                      final plugin = filteredPlugins[index];
                      return Card(
                        child: CheckboxListTile(
                          value: plugin.selected,
                          onChanged: (value) => _togglePlugin(index),
                          title: Text(plugin.name),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  ExcludeSemantics(
                                    child: Icon(
                                      _getFileTypeIcon(plugin.fileType),
                                      size: 16,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    plugin.fileType.toUpperCase(),
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                  if (plugin.fileSize != null) ...[
                                    const SizedBox(width: 8),
                                    Text(
                                      _formatFileSize(plugin.fileSize!),
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                    ),
                                  ],
                                ],
                              ),
                              if (plugin.description != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  plugin.description!,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                      ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                          dense: true,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dlgContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: selectedCount > 0
                  ? () {
                      widget.onSelectionChanged(plugins);
                      Navigator.of(dlgContext).pop();
                    }
                  : null,
              child: Text(
                selectedCount > 0
                    ? 'Install Selected ($selectedCount)'
                    : 'Select at least one plugin',
              ),
            ),
          ],
        );
      },
    );
  }

  IconData _getPluginIcon(GalleryPluginType type) {
    switch (type) {
      case GalleryPluginType.lua:
        return Icons.code;
      case GalleryPluginType.threepot:
        return Icons.tune;
      case GalleryPluginType.cpp:
        return Icons.memory;
    }
  }

  IconData _getFileTypeIcon(String fileType) {
    switch (fileType.toLowerCase()) {
      case 'o':
        return Icons.memory;
      case 'lua':
        return Icons.code;
      case '3pot':
        return Icons.tune;
      default:
        return Icons.insert_drive_file;
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }
}
