import 'package:flutter/material.dart';

class ScanningProgressCard extends StatelessWidget {
  final double progress;
  final int filesProcessed;
  final int totalFiles;
  final String currentFile;
  final VoidCallback onCancel;

  const ScanningProgressCard({
    super.key,
    required this.progress,
    required this.filesProcessed,
    required this.totalFiles,
    required this.currentFile,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Scanning SD Card...',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 10, // Make the progress bar thicker
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.primary),
                  ),
                ),
                const SizedBox(width: 16),
                Text('${(progress * 100).toStringAsFixed(0)}%',
                    style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Files: $filesProcessed / $totalFiles',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Current: $currentFile',
              style: Theme.of(context).textTheme.bodySmall,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.cancel_outlined),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[400], // Warning color
                  foregroundColor:
                      Colors.white, // Text color for warning button
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  textStyle: Theme.of(context).textTheme.labelLarge,
                ),
                onPressed: onCancel,
                label: const Text('Cancel Scan'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
