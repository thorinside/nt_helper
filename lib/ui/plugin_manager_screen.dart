import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/models/plugin_info.dart';

/// A screen for managing plugins and extensions for the NT Helper app.
/// This provides a centralized location for plugin installation, configuration, and management.
class PluginManagerScreen extends StatefulWidget {
  final DistingCubit distingCubit;

  const PluginManagerScreen({
    super.key,
    required this.distingCubit,
  });

  @override
  State<PluginManagerScreen> createState() => _PluginManagerScreenState();
}

class _PluginManagerScreenState extends State<PluginManagerScreen> {
  int _selectedIndex = 0;
  bool _isLoading = false;
  String? _error;

  final List<String> _sections = [
    'Installed',
    'Available',
    'Settings',
  ];

  // Plugin data
  List<PluginInfo> _luaPlugins = [];
  List<PluginInfo> _threePotPlugins = [];
  List<PluginInfo> _cppPlugins = [];

  // Expansion state for collapsible sections
  bool _luaExpanded = true;
  bool _threePotExpanded = true;
  bool _cppExpanded = true;

  @override
  void initState() {
    super.initState();
    _loadInstalledPlugins();
  }

  Future<void> _loadInstalledPlugins() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        widget.distingCubit.fetchLuaPlugins(),
        widget.distingCubit.fetch3potPlugins(),
        widget.distingCubit.fetchCppPlugins(),
      ]);

      setState(() {
        _luaPlugins = results[0];
        _threePotPlugins = results[1];
        _cppPlugins = results[2];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load plugins: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _installPlugin() async {
    try {
      // Only show file picker on desktop platforms
      if (!kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.windows ||
              defaultTargetPlatform == TargetPlatform.macOS ||
              defaultTargetPlatform == TargetPlatform.linux)) {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['lua', '3pot', 'o'],
          allowMultiple: false,
        );

        if (result != null && result.files.isNotEmpty) {
          final file = result.files.first;
          final fileName = file.name;

          // Try to get bytes directly first, then fall back to reading from path
          Uint8List? fileBytes = file.bytes;

          if (fileBytes == null && file.path != null) {
            // On desktop platforms, we might need to read from the file path
            try {
              final fileData = await File(file.path!).readAsBytes();
              fileBytes = Uint8List.fromList(fileData);
            } catch (e) {
              throw Exception('Failed to read file from path: $e');
            }
          }

          if (fileBytes == null) {
            throw Exception(
                'Failed to read file data - no bytes or path available');
          }

          // Show progress dialog
          if (mounted) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => _buildUploadProgressDialog(fileName),
            );
          }

          try {
            await widget.distingCubit.installPlugin(
              fileName,
              fileBytes,
              onProgress: (progress) {
                // Progress callback for future use
              },
            );

            // Close progress dialog
            if (mounted) {
              Navigator.of(context).pop();

              // Show success message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Successfully installed "$fileName"'),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                ),
              );

              // Refresh plugin list
              await _loadInstalledPlugins();
            }
          } catch (e) {
            // Close progress dialog
            if (mounted) {
              Navigator.of(context).pop();

              // Show error message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to install "$fileName": $e'),
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
              );
            }
          }
        }
      } else {
        // Show message for unsupported platforms
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'File installation is only available on desktop platforms'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting file: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Widget _buildUploadProgressDialog(String fileName) {
    return AlertDialog(
      title: const Text('Installing Plugin'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Installing "$fileName"...'),
          const SizedBox(height: 16),
          const LinearProgressIndicator(),
          const SizedBox(height: 8),
          const Text('This may take a few moments'),
        ],
      ),
    );
  }

  Future<void> _deletePlugin(PluginInfo plugin) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Plugin'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete "${plugin.name}"?'),
            const SizedBox(height: 8),
            Text(
              'This action cannot be undone.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      // Optimistically remove the plugin from the UI immediately
      setState(() {
        switch (plugin.type) {
          case PluginType.lua:
            _luaPlugins.removeWhere((p) => p.path == plugin.path);
            break;
          case PluginType.threePot:
            _threePotPlugins.removeWhere((p) => p.path == plugin.path);
            break;
          case PluginType.cpp:
            _cppPlugins.removeWhere((p) => p.path == plugin.path);
            break;
        }
      });

      // Show immediate feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Deleting "${plugin.name}"...'),
          duration: const Duration(seconds: 2),
        ),
      );

      try {
        // Send delete command (fire-and-forget, assumes success)
        await widget.distingCubit.deletePlugin(plugin);

        // Refresh the plugin list in the background to verify deletion
        // Use a slight delay to allow the device to process the delete
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            _loadInstalledPlugins();
          }
        });
      } catch (e) {
        // If the delete command fails, add the plugin back to the list
        if (mounted) {
          setState(() {
            switch (plugin.type) {
              case PluginType.lua:
                _luaPlugins.add(plugin);
                _luaPlugins.sort((a, b) =>
                    a.name.toLowerCase().compareTo(b.name.toLowerCase()));
                break;
              case PluginType.threePot:
                _threePotPlugins.add(plugin);
                _threePotPlugins.sort((a, b) =>
                    a.name.toLowerCase().compareTo(b.name.toLowerCase()));
                break;
              case PluginType.cpp:
                _cppPlugins.add(plugin);
                _cppPlugins.sort((a, b) =>
                    a.name.toLowerCase().compareTo(b.name.toLowerCase()));
                break;
            }
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('Error sending delete command for "${plugin.name}": $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plugin Manager'),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        actions: [
          if (_selectedIndex == 0) // Only show install button on Installed tab
            IconButton(
              onPressed: _installPlugin,
              icon: const Icon(Icons.add),
              tooltip: 'Install Plugin from File',
            ),
        ],
      ),
      body: Row(
        children: [
          // Sidebar
          Padding(
            padding: const EdgeInsets.only(top: 24.0),
            child: NavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              labelType: NavigationRailLabelType.all,
              destinations: _sections.map((section) {
                return NavigationRailDestination(
                  icon: _getIconForSection(section),
                  label: Text(section),
                );
              }).toList(),
            ),
          ),

          const VerticalDivider(thickness: 1, width: 1),

          // Main content
          Expanded(
            child: _buildMainContent(),
          ),
        ],
      ),
    );
  }

  Widget _getIconForSection(String section) {
    switch (section) {
      case 'Installed':
        return const Icon(Icons.extension);
      case 'Available':
        return const Icon(Icons.download);
      case 'Settings':
        return const Icon(Icons.settings);
      default:
        return const Icon(Icons.help);
    }
  }

  Widget _buildMainContent() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading plugins...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _loadInstalledPlugins,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    switch (_selectedIndex) {
      case 0:
        return _buildInstalledPluginsView();
      case 1:
        return _buildAvailablePluginsView();
      case 2:
        return _buildSettingsView();
      default:
        return const Center(child: Text('Unknown section'));
    }
  }

  Widget _buildInstalledPluginsView() {
    final allPlugins = [..._luaPlugins, ..._threePotPlugins, ..._cppPlugins];

    if (allPlugins.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.extension_off, size: 64),
            const SizedBox(height: 16),
            const Text('No plugins installed'),
            const SizedBox(height: 8),
            Text(
              'Use the + button above to install plugin files (.lua, .3pot, .o)',
              style: TextStyle(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _installPlugin,
              icon: const Icon(Icons.add),
              label: const Text('Install Plugin'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadInstalledPlugins,
      child: ExpansionTileTheme(
        data: const ExpansionTileThemeData(
          shape: RoundedRectangleBorder(
            side: BorderSide.none,
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
          children: [
            if (_luaPlugins.isNotEmpty)
              _buildPluginTypeSection('Lua Scripts', _luaPlugins, Icons.code),
            if (_threePotPlugins.isNotEmpty)
              _buildPluginTypeSection(
                  '3pot Plugins', _threePotPlugins, Icons.tune),
            if (_cppPlugins.isNotEmpty)
              _buildPluginTypeSection('C++ Plugins', _cppPlugins, Icons.memory),
          ],
        ),
      ),
    );
  }

  Widget _buildPluginTypeSection(
      String title, List<PluginInfo> plugins, IconData icon) {
    // Determine which expansion state to use based on the title
    bool isExpanded;
    void Function(bool) onExpansionChanged;

    switch (title) {
      case 'Lua Scripts':
        isExpanded = _luaExpanded;
        onExpansionChanged =
            (expanded) => setState(() => _luaExpanded = expanded);
        break;
      case '3pot Plugins':
        isExpanded = _threePotExpanded;
        onExpansionChanged =
            (expanded) => setState(() => _threePotExpanded = expanded);
        break;
      case 'C++ Plugins':
        isExpanded = _cppExpanded;
        onExpansionChanged =
            (expanded) => setState(() => _cppExpanded = expanded);
        break;
      default:
        isExpanded = true;
        onExpansionChanged = (_) {};
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        initiallyExpanded: isExpanded,
        onExpansionChanged: onExpansionChanged,
        leading: Icon(icon, size: 20),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${plugins.length}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ],
        ),
        children: plugins.map((plugin) => _buildPluginCard(plugin)).toList(),
      ),
    );
  }

  Widget _buildPluginCard(PluginInfo plugin) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
          child: Icon(
            _getIconForPluginType(plugin.type),
            color: theme.colorScheme.primary,
          ),
        ),
        title: Text(plugin.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(plugin.path),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  _formatFileSize(plugin.sizeBytes),
                  style: theme.textTheme.bodySmall,
                ),
                if (plugin.lastModified != null) ...[
                  const Text(' • '),
                  Text(
                    _formatDate(plugin.lastModified!),
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () => _showPluginDetails(plugin),
              tooltip: 'Plugin Details',
            ),
            IconButton(
              icon: Icon(
                Icons.delete_outline,
                color: theme.colorScheme.error,
              ),
              onPressed: () => _deletePlugin(plugin),
              tooltip: 'Delete Plugin',
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  IconData _getIconForPluginType(PluginType type) {
    switch (type) {
      case PluginType.lua:
        return Icons.code;
      case PluginType.threePot:
        return Icons.tune;
      case PluginType.cpp:
        return Icons.memory;
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showPluginDetails(PluginInfo plugin) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(plugin.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Type', plugin.type.displayName),
            _buildDetailRow('Path', plugin.path),
            _buildDetailRow('Size', _formatFileSize(plugin.sizeBytes)),
            if (plugin.lastModified != null)
              _buildDetailRow('Modified', _formatDate(plugin.lastModified!)),
            const SizedBox(height: 8),
            Text(
              plugin.type.description,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailablePluginsView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.download, size: 64),
          SizedBox(height: 16),
          Text('Available Plugins'),
          SizedBox(height: 8),
          Text(
            'Plugin marketplace coming soon',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.settings, size: 64),
          SizedBox(height: 16),
          Text('Plugin Settings'),
          SizedBox(height: 8),
          Text(
            'Configuration options coming soon',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
