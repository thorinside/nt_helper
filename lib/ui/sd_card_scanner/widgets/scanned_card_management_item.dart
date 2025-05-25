import 'package:flutter/material.dart';

class ScannedCardManagementItem extends StatefulWidget {
  final String cardName;
  final DateTime? lastScanDate;
  final int presetCount;
  final VoidCallback onRescan;
  final VoidCallback onRemove;

  const ScannedCardManagementItem({
    super.key,
    required this.cardName,
    this.lastScanDate,
    required this.presetCount,
    required this.onRescan,
    required this.onRemove,
  });

  @override
  State<ScannedCardManagementItem> createState() =>
      _ScannedCardManagementItemState();
}

class _ScannedCardManagementItemState extends State<ScannedCardManagementItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final cardElevation = _isHovered ? 8.0 : 2.0;
    final titleColor =
        _isHovered ? Theme.of(context).colorScheme.primary : null;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Card(
        elevation: cardElevation,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
        child: InkWell(
          onTap: () {
            // TODO: Implement tap action, e.g., view card details or load presets from this card
            debugPrint('Card ${widget.cardName} tapped');
          },
          borderRadius: BorderRadius.circular(12.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.cardName,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: titleColor, // Apply hover color to title
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.calendar_today_outlined,
                        size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      widget.lastScanDate != null
                          ? 'Last Scanned: ${widget.lastScanDate!.toIso8601String().substring(0, 10)}'
                          : 'Last Scanned: N/A',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Colors.grey[700]),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.folder_zip_outlined,
                        size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      'Presets: ${widget.presetCount}',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Colors.grey[700]),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.refresh),
                      onPressed: widget.onRescan,
                      label: const Text('Rescan'),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                        icon: Icon(Icons.delete_outline,
                            color: Colors.redAccent[100]),
                        label: Text('Remove',
                            style: TextStyle(color: Colors.redAccent[100])),
                        onPressed: widget.onRemove,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.redAccent[100],
                        )),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
