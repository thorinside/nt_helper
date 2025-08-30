import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/core/routing/routing_service_locator.dart';
import 'package:nt_helper/services/haptic_feedback_service.dart';
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
  final Offset position;
  final bool isSelected;
  final Function(Offset)? onPositionChanged;
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
    this.isSelected = false,
    this.onPositionChanged,
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
  Offset _dragOffset = Offset.zero;
  late IHapticFeedbackService _hapticFeedback;
  
  @override
  void initState() {
    super.initState();
    _hapticFeedback = RoutingServiceLocator.hapticFeedbackService;
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Positioned(
      left: widget.position.dx,
      top: widget.position.dy,
      child: GestureDetector(
        onTap: () {
          // Provide light haptic feedback for node selection
          _hapticFeedback.lightImpact(context);
          widget.onTap?.call();
        },
        onPanStart: _handleDragStart,
        onPanUpdate: _handleDragUpdate,
        onPanEnd: _handleDragEnd,
        child: AnimatedContainer(
          duration: _isDragging ? Duration.zero : const Duration(milliseconds: 150),
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
      ),
    );
  }
  
  Widget _buildTitleBar(ThemeData theme) {
    // Ensure proper contrast for the title bar background
    final backgroundColor = AccessibilityColors.ensureContrast(
      theme.colorScheme.primary.withValues(alpha: 0.15), // Slightly higher alpha
      theme.colorScheme.surface,
      minRatio: AccessibilityColors.wcagAALarge, // Use large text standard
    );
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
          // Slot number badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '#${widget.slotNumber}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Algorithm name
          Expanded(
            child: Text(
              widget.algorithmName,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: AccessibilityColors.ensureContrast(
                  theme.colorScheme.onSurface,
                  backgroundColor,
                  minRatio: AccessibilityColors.wcagAANormal,
                ),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Toolbar
          _buildToolbar(theme),
        ],
      ),
    );
  }
  
  Widget _buildToolbar(ThemeData theme) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert,
        size: 18,
        color: theme.colorScheme.onSurface,
      ),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'up',
          enabled: widget.onMoveUp != null && widget.slotNumber > 1,
          child: const Row(
            children: [
              Icon(Icons.arrow_upward, size: 18),
              SizedBox(width: 8),
              Text('Move Up'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'down',
          enabled: widget.onMoveDown != null,
          child: const Row(
            children: [
              Icon(Icons.arrow_downward, size: 18),
              SizedBox(width: 8),
              Text('Move Down'),
            ],
          ),
        ),
        const PopupMenuDivider(),
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
        debugPrint('AlgorithmNodeWidget: Toolbar action selected: $value');
        switch (value) {
          case 'up':
            _handleMoveUp();
            break;
          case 'down':
            _handleMoveDown();
            break;
          case 'delete':
            _handleDelete();
            break;
        }
      },
    );
  }
  
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
    // Provide medium haptic feedback for drag start
    _hapticFeedback.mediumImpact(context);
    
    setState(() {
      _isDragging = true;
      _dragOffset = details.localPosition;
    });
    debugPrint('AlgorithmNodeWidget: Drag started at ${details.localPosition}');
  }
  
  // Toolbar action handlers integrated with DistingCubit
  void _handleMoveUp() async {
    // Provide light haptic feedback for button interaction
    _hapticFeedback.lightImpact(context);
    
    debugPrint('AlgorithmNodeWidget: Moving algorithm #${widget.slotNumber} up');
    
    final cubit = context.read<DistingCubit>();
    try {
      // Slot numbers are 1-indexed, but the cubit uses 0-indexed
      final algorithmIndex = widget.slotNumber - 1;
      
      if (algorithmIndex <= 0) {
        debugPrint('AlgorithmNodeWidget: Cannot move first algorithm up');
        _showFeedback('Cannot move the first algorithm up', isError: true);
        return;
      }
      
      await cubit.moveAlgorithmUp(algorithmIndex);
      widget.onMoveUp?.call();
      _showFeedback('Moved algorithm up');
      debugPrint('AlgorithmNodeWidget: Successfully moved algorithm up');
    } catch (e) {
      debugPrint('AlgorithmNodeWidget: Error moving algorithm up: $e');
      _showFeedback('Failed to move algorithm: $e', isError: true);
    }
  }
  
  void _handleMoveDown() async {
    // Provide light haptic feedback for button interaction
    _hapticFeedback.lightImpact(context);
    
    debugPrint('AlgorithmNodeWidget: Moving algorithm #${widget.slotNumber} down');
    
    final cubit = context.read<DistingCubit>();
    try {
      // Slot numbers are 1-indexed, but the cubit uses 0-indexed
      final algorithmIndex = widget.slotNumber - 1;
      
      await cubit.moveAlgorithmDown(algorithmIndex);
      widget.onMoveDown?.call();
      _showFeedback('Moved algorithm down');
      debugPrint('AlgorithmNodeWidget: Successfully moved algorithm down');
    } catch (e) {
      debugPrint('AlgorithmNodeWidget: Error moving algorithm down: $e');
      _showFeedback('Failed to move algorithm: $e', isError: true);
    }
  }
  
  void _handleDelete() async {
    // Provide medium haptic feedback for important delete action
    _hapticFeedback.mediumImpact(context);
    
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
    
    // Calculate new position with accurate coordinate transform
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    
    final RenderBox? parentBox = renderBox.parent as RenderBox?;
    if (parentBox == null) return;
    
    // Get the global position and convert to parent's local coordinates
    final globalPosition = details.globalPosition;
    final localPosition = parentBox.globalToLocal(globalPosition);
    
    // Calculate the new position accounting for the drag offset
    final newPosition = Offset(
      localPosition.dx - _dragOffset.dx,
      localPosition.dy - _dragOffset.dy,
    );
    
    // Snap to grid
    const double gridSize = 50.0;
    final snappedPosition = Offset(
      (newPosition.dx / gridSize).round() * gridSize,
      (newPosition.dy / gridSize).round() * gridSize,
    );
    
    // Constrain to canvas bounds
    const double canvasSize = 5000.0;
    final constrainedPosition = Offset(
      snappedPosition.dx.clamp(0, canvasSize - 200),
      snappedPosition.dy.clamp(0, canvasSize - 100),
    );
    
    widget.onPositionChanged?.call(constrainedPosition);
    
    debugPrint('AlgorithmNodeWidget: Dragging to ${constrainedPosition.dx},${constrainedPosition.dy}');
  }
  
  void _handleDragEnd(DragEndDetails details) {
    setState(() {
      _isDragging = false;
    });
    debugPrint('AlgorithmNodeWidget: Drag ended');
  }
}

// Removed dependency on RoutingEditorWidget static values
