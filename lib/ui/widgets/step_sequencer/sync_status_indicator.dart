import 'package:flutter/material.dart';

/// Sync status states for parameter synchronization
enum SyncStatus {
  /// All parameters synced with hardware
  synced,

  /// User actively editing, debounce pending
  editing,

  /// MIDI write in progress
  syncing,

  /// MIDI write failed
  error,

  /// Hardware disconnected, editing locally
  offline,
}

/// Displays sync status for Step Sequencer parameter changes
///
/// Shows a colored indicator dot with optional text label (desktop/tablet only).
/// Colors indicate current sync state:
/// - Green (synced): All changes written to hardware
/// - Orange (editing): User actively editing, pending debounce
/// - Blue (syncing): MIDI write in progress
/// - Red (error): Write failed, retry button appears
///
/// Supports responsive layouts:
/// - Desktop/Tablet (width > 768px): Dot + text label + retry button
/// - Mobile (width ≤ 768px): Dot only (compact)
class SyncStatusIndicator extends StatelessWidget {
  final SyncStatus status;
  final String? errorMessage;
  final VoidCallback? onRetry;

  const SyncStatusIndicator({
    super.key,
    required this.status,
    this.errorMessage,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width <= 768;
    final statusText = _getStatusText(status);
    final semanticLabel = 'Sync status: $statusText'
        '${status == SyncStatus.error && errorMessage != null ? ". Error: $errorMessage" : ""}';

    return Semantics(
      label: semanticLabel,
      liveRegion: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ExcludeSemantics(
            child: Container(
              width: isMobile ? 8 : 12,
              height: isMobile ? 8 : 12,
              decoration: BoxDecoration(
                color: _getStatusColor(status),
                shape: BoxShape.circle,
              ),
            ),
          ),
          if (!isMobile) ...[
            const SizedBox(width: 8),
            ExcludeSemantics(
              child: Text(
                statusText,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
            ),
          ],
          if (status == SyncStatus.error && onRetry != null) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.refresh, size: 16, semanticLabel: 'Retry failed writes'),
              onPressed: onRetry,
              tooltip: 'Retry failed writes',
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(),
            ),
          ],
        ],
      ),
    );
  }

  Color _getStatusColor(SyncStatus status) {
    switch (status) {
      case SyncStatus.synced:
        return const Color(0xFF10b981); // green
      case SyncStatus.editing:
        return const Color(0xFFf59e0b); // orange
      case SyncStatus.syncing:
        return const Color(0xFF3b82f6); // blue
      case SyncStatus.error:
        return const Color(0xFFef4444); // red
      case SyncStatus.offline:
        return const Color(0xFFf59e0b); // orange
    }
  }

  String _getStatusText(SyncStatus status) {
    switch (status) {
      case SyncStatus.synced:
        return 'Synced';
      case SyncStatus.editing:
        return 'Editing...';
      case SyncStatus.syncing:
        return 'Syncing...';
      case SyncStatus.error:
        return 'Error';
      case SyncStatus.offline:
        return 'Offline';
    }
  }
}
