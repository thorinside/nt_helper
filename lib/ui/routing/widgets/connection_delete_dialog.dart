import 'package:flutter/material.dart';
import 'package:nt_helper/core/routing/models/connection.dart';

/// Dialog for confirming connection deletion on touch devices
class ConnectionDeleteDialog extends StatelessWidget {
  final Connection connection;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  final String? sourcePortName;
  final String? targetPortName;

  const ConnectionDeleteDialog({
    super.key,
    required this.connection,
    required this.onConfirm,
    required this.onCancel,
    this.sourcePortName,
    this.targetPortName,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AlertDialog(
      icon: Icon(
        Icons.delete_outline,
        color: theme.colorScheme.error,
        size: 32,
      ),
      title: const Text('Delete Connection'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Are you sure you want to delete this connection?'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'From: ${sourcePortName ?? connection.sourcePortId}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.arrow_downward,
                      size: 16,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'To: ${targetPortName ?? connection.destinationPortId}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                if (connection.gain != 1.0) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Gain: ${connection.gain.toStringAsFixed(2)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
                if (connection.outputMode != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Mode: ${connection.outputMode.toString().split('.').last}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This action cannot be undone.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: onCancel,
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: onConfirm,
          style: FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.error,
            foregroundColor: theme.colorScheme.onError,
          ),
          child: const Text('Delete'),
        ),
      ],
    );
  }

  /// Show the connection delete dialog
  static Future<bool?> show(
    BuildContext context, {
    required Connection connection,
    String? sourcePortName,
    String? targetPortName,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => ConnectionDeleteDialog(
        connection: connection,
        sourcePortName: sourcePortName,
        targetPortName: targetPortName,
        onConfirm: () => Navigator.of(context).pop(true),
        onCancel: () => Navigator.of(context).pop(false),
      ),
    );
  }
}

/// Overlay widget for showing delete icon on connection hover
class ConnectionDeleteOverlay extends StatelessWidget {
  final Offset position;
  final VoidCallback onDelete;
  final bool isVisible;

  const ConnectionDeleteOverlay({
    super.key,
    required this.position,
    required this.onDelete,
    this.isVisible = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();

    return Positioned(
      left: position.dx - 16,
      top: position.dy - 16,
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(16),
        color: Theme.of(context).colorScheme.error,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onDelete,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).colorScheme.onError.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Icon(
              Icons.close,
              color: Theme.of(context).colorScheme.onError,
              size: 18,
            ),
          ),
        ),
      ),
    );
  }
}

/// Snackbar for showing connection deletion feedback
class ConnectionDeleteSnackbar {
  static void show(
    BuildContext context, {
    required String message,
    VoidCallback? onUndo,
    Duration duration = const Duration(seconds: 4),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
        action: onUndo != null
            ? SnackBarAction(
                label: 'Undo',
                onPressed: onUndo,
              )
            : null,
      ),
    );
  }
}