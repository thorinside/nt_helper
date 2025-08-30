import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/ui/widgets/routing/accessibility_colors.dart';
// No direct dependency on RoutingEditorWidget static members

/// A draggable widget representing an algorithm node in the routing editor.
/// 
/// Features:
/// - Draggable with precise coordinate transforms
/// - Title bar showing algorithm name and slot number
/// - Toolbar with up/down/delete actions
/// - Input and output connection points
/// - Theme-aware styling
class AlgorithmNodeWidget extends StatefulWidget {
  final String algorithmName;
  final int slotNumber;
  // Position is now handled by parent Positioned widget
  final Offset position;
  // Optional leading icon for the top bar
  final Widget? leadingIcon;
  final bool isSelected;
  final Function(Offset)? onPositionChanged;
  final VoidCallback? onDragStart;
  final VoidCallback? onDragEnd;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;
  final int inputCount;
  final int outputCount;
  
  const AlgorithmNodeWidget({
    super.key,
    required this.algorithmName,
    required this.slotNumber,
    required this.position,
    this.leadingIcon,
    this.isSelected = false,
    this.onPositionChanged,
    this.onDragStart,
    this.onDragEnd,
    this.onMoveUp,
    this.onMoveDown,
    this.onDelete,
    this.onTap,
    this.inputCount = 2,
    this.outputCount = 2,
  });
  
  @override
  State<AlgorithmNodeWidget> createState() => _AlgorithmNodeWidgetState();
}

class _AlgorithmNodeWidgetState extends State<AlgorithmNodeWidget> {
  bool _isDragging = false;
  // Track drag start and initial position for stable deltas
  Offset _dragStartGlobal = Offset.zero;
  Offset _initialPosition = Offset.zero;
  
  @override
  void initState() {
    super.initState();
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Reserve enough width for ~50 title characters plus actions
    final titleStyle = theme.textTheme.titleSmall ?? const TextStyle(fontSize: 14);
    // Reserve space for roughly 20 characters to keep titles readable without oversizing
    final reservedTitle = '#${widget.slotNumber} ${'W' * 20}';
    final reservedTitleWidth = _measureTextWidth(reservedTitle, titleStyle);
    final actionsCount = (widget.onMoveUp != null ? 1 : 0) + (widget.onMoveDown != null ? 1 : 0) + 1; // +1 for overflow
    const iconButtonWidth = 48.0; // Material minimum tap target
    final actionsWidth = actionsCount * iconButtonWidth;
    final leadingWidth = widget.leadingIcon != null ? 18.0 + 8.0 : 0.0; // icon + spacing
    const horizontalPadding = 16.0; // 8 left + 8 right from title bar padding
    const portsMinWidth = 280.0; // two 120px jacks + 40px spacing
    final minNodeWidth = (reservedTitleWidth + actionsWidth + leadingWidth + horizontalPadding).clamp(portsMinWidth, 2000.0);

    return GestureDetector(
        onTap: () {
          widget.onTap?.call();
        },
        onPanStart: _handleDragStart,
        onPanUpdate: _handleDragUpdate,
        onPanEnd: _handleDragEnd,
        child: AnimatedContainer(
          duration: _isDragging ? Duration.zero : const Duration(milliseconds: 150),
          constraints: BoxConstraints(minWidth: minNodeWidth),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: widget.isSelected 
                ? AccessibilityColors.ensureContrast(
                    theme.colorScheme.primary,
                    theme.colorScheme.surface,
                    minRatio: AccessibilityColors.wcagAANormal,
                  )
                : theme.colorScheme.outline.withValues(alpha: 0.7), // Higher alpha for better visibility
              width: widget.isSelected ? 3 : 1, // Thicker border when selected
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: _isDragging ? 0.3 : 0.1),
                blurRadius: _isDragging ? 8 : 4,
                offset: Offset(0, _isDragging ? 4 : 2),
              ),
            ],
          ),
          child: IntrinsicWidth(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildTitleBar(theme),
                _buildPorts(theme),
              ],
            ),
          ),
        ),
      );
  }

  double _measureTextWidth(String text, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: double.infinity);
    return painter.size.width;
  }
  
  Widget _buildTitleBar(ThemeData theme) {
    // Use app bar theming for better readability and consistency
    final backgroundColor = theme.appBarTheme.backgroundColor ?? theme.colorScheme.surfaceContainerHigh;
    final foregroundColor = theme.appBarTheme.foregroundColor ?? theme.colorScheme.onSurface;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.leadingIcon != null) ...[
            IconTheme(
              data: IconThemeData(color: foregroundColor, size: 18),
              child: widget.leadingIcon!,
            ),
            const SizedBox(width: 8),
          ],
          // Title with slot number pre-pended
          Expanded(
            child: Text(
              '#${widget.slotNumber} ${widget.algorithmName}',
              style: theme.textTheme.titleSmall?.copyWith(
                color: foregroundColor,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              softWrap: false,
            ),
          ),
          // Up to three actions as icons (show Up/Down if provided)
          if (widget.onMoveUp != null)
            IconButton(
              tooltip: 'Move Up',
              icon: const Icon(Icons.arrow_upward, size: 18),
              onPressed: widget.onMoveUp,
            ),
          if (widget.onMoveDown != null)
            IconButton(
              tooltip: 'Move Down',
              icon: const Icon(Icons.arrow_downward, size: 18),
              onPressed: widget.onMoveDown,
            ),
          // Overflow menu: only delete here
          PopupMenuButton<String>(
            tooltip: 'More',
            icon: Icon(Icons.more_vert, size: 18, color: foregroundColor),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'delete',
                enabled: widget.onDelete != null,
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 18, color: theme.colorScheme.error),
                    const SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: theme.colorScheme.error)),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'delete') {
                _handleDelete();
              }
            },
          ),
        ],
      ),
    );
  }
  
  // Removed old overflow-only toolbar; actions are now visible icon buttons with delete in overflow
  
  Widget _buildPorts(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Input ports
          Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(widget.inputCount, (index) => 
              _buildPort(theme, 'I${index + 1}', true),
            ),
          ),
          const SizedBox(width: 40),
          // Output ports
          Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(widget.outputCount, (index) => 
              _buildPort(theme, 'O${index + 1}', false),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPort(ThemeData theme, String label, bool isInput) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isInput) ...[
            Text(
              label,
              style: theme.textTheme.labelSmall,
            ),
            const SizedBox(width: 4),
          ],
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isInput ? theme.colorScheme.primary : theme.colorScheme.secondary,
              border: Border.all(
                color: theme.colorScheme.outline,
                width: 1,
              ),
            ),
          ),
          if (isInput) ...[
            const SizedBox(width: 4),
            Text(
              label,
              style: theme.textTheme.labelSmall,
            ),
          ],
        ],
      ),
    );
  }
  
  void _handleDragStart(DragStartDetails details) {
    // Intentionally no haptic/audio/visual feedback on drag start
    
    setState(() {
      _isDragging = true;
      _dragStartGlobal = details.globalPosition;
      _initialPosition = widget.position;
    });

    // Notify parent that a drag has begun
    widget.onDragStart?.call();
  }
  
  // Toolbar action handlers removed; actions call callbacks directly
  
  void _handleDelete() async {
    debugPrint('AlgorithmNodeWidget: Deleting algorithm #${widget.slotNumber}');
    
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Algorithm'),
        content: Text('Are you sure you want to delete "${widget.algorithmName}" from slot #${widget.slotNumber}?'),
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
    
    if (confirmed != true) {
      debugPrint('AlgorithmNodeWidget: Delete cancelled by user');
      return;
    }
    
    if (!mounted) return;
    final cubit = context.read<DistingCubit>();
    try {
      // Slot numbers are 1-indexed, but the cubit uses 0-indexed
      final algorithmIndex = widget.slotNumber - 1;
      
      await cubit.onRemoveAlgorithm(algorithmIndex);
      widget.onDelete?.call();
      _showFeedback('Algorithm deleted');
      debugPrint('AlgorithmNodeWidget: Successfully deleted algorithm');
    } catch (e) {
      debugPrint('AlgorithmNodeWidget: Error deleting algorithm: $e');
      _showFeedback('Failed to delete algorithm: $e', isError: true);
    }
  }
  
  void _showFeedback(String message, {bool isError = false}) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError 
            ? Theme.of(context).colorScheme.error
            : Theme.of(context).colorScheme.primary,
        duration: const Duration(seconds: 2),
      ),
    );
  }
  
  void _handleDragUpdate(DragUpdateDetails details) {
    if (!_isDragging) return;
    // Compute new position from drag delta relative to drag start
    final dragDelta = details.globalPosition - _dragStartGlobal;
    final newPosition = _initialPosition + dragDelta;
    
    // Snap to grid
    const double gridSize = 50.0;
    final snappedPosition = Offset(
      (newPosition.dx / gridSize).round() * gridSize,
      (newPosition.dy / gridSize).round() * gridSize,
    );
    
    // Constrain to canvas bounds
    const double canvasSize = 5000.0;
    final constrainedPosition = Offset(
      snappedPosition.dx.clamp(0.0, canvasSize - 200),
      snappedPosition.dy.clamp(0.0, canvasSize - 100),
    );
    
    widget.onPositionChanged?.call(constrainedPosition);
  }
  
  void _handleDragEnd(DragEndDetails details) {
    setState(() {
      _isDragging = false;
    });

    // Notify parent that drag ended
    widget.onDragEnd?.call();
  }
}

// Removed dependency on RoutingEditorWidget static values
