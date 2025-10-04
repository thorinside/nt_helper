import 'package:flutter/material.dart';
import 'package:nt_helper/models/sd_card_file_system.dart';

class MobileDrillDownNavigator extends StatelessWidget {
  final List<DirectoryEntry> items;
  final DirectoryEntry? selectedItem;
  final List<String> breadcrumbs;
  final Function(DirectoryEntry) onItemTap;
  final Function(int) onBreadcrumbTap;
  final VoidCallback onRefresh;

  const MobileDrillDownNavigator({
    super.key,
    required this.items,
    this.selectedItem,
    required this.breadcrumbs,
    required this.onItemTap,
    required this.onBreadcrumbTap,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Breadcrumb navigation
        if (breadcrumbs.isNotEmpty)
          Container(
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
                  // Root icon/button
                  InkWell(
                    onTap: () => onBreadcrumbTap(-1),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Icon(
                        Icons.home,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  // Breadcrumb segments
                  ...breadcrumbs.asMap().entries.map((entry) {
                    final index = entry.key;
                    final segment = entry.value;
                    final isLast = index == breadcrumbs.length - 1;

                    return Row(
                      children: [
                        Icon(
                          Icons.chevron_right,
                          size: 16,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        InkWell(
                          onTap: isLast ? null : () => onBreadcrumbTap(index),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8.0,
                              vertical: 8.0,
                            ),
                            child: Text(
                              segment,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isLast ? FontWeight.bold : FontWeight.normal,
                                color: isLast
                                    ? Theme.of(context).colorScheme.onSurfaceVariant
                                    : Theme.of(context).colorScheme.primary,
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
          ),

        // Directory listing
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async => onRefresh(),
            child: items.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 100),
                      Center(
                        child: Text(
                          'Empty directory',
                          style: TextStyle(
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
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
                          size: 28,
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
                            fontSize: 16,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        subtitle: !item.isDirectory
                            ? Text(
                                _formatFileSize(item.size),
                                style: const TextStyle(fontSize: 13),
                              )
                            : null,
                        trailing: item.isDirectory
                            ? Icon(
                                Icons.chevron_right,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              )
                            : null,
                        selected: isSelected,
                        selectedTileColor: Theme.of(context).colorScheme.primaryContainer,
                        onTap: () => onItemTap(item),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 4.0,
                        ),
                        minVerticalPadding: 8.0,
                      );
                    },
                  ),
          ),
        ),
      ],
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