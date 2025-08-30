import 'package:flutter/material.dart';
// No direct dependency on RoutingEditorWidget static members

/// Base class for connection panel widgets (input/output)
abstract class ConnectionPanelWidget extends StatefulWidget {
  final String title;
  final int connectionCount;
  final Offset position;
  final Function(Offset)? onPositionChanged;
  final Function(int index, Offset globalPosition)? onConnectionDragStart;
  final Function(int index, Offset globalPosition)? onConnectionDragUpdate;
  final Function(int index)? onConnectionDragEnd;
  final Map<int, bool> activeConnections;
  
  const ConnectionPanelWidget({
    super.key,
    required this.title,
    required this.connectionCount,
    required this.position,
    this.onPositionChanged,
    this.onConnectionDragStart,
    this.onConnectionDragUpdate,
    this.onConnectionDragEnd,
    this.activeConnections = const {},
  });
}

/// Widget representing an input panel with draggable connection points
class InputPanelWidget extends ConnectionPanelWidget {
  const InputPanelWidget({
    super.key,
    required super.connectionCount,
    required super.position,
    super.onPositionChanged,
    super.onConnectionDragStart,
    super.onConnectionDragUpdate,
    super.onConnectionDragEnd,
    super.activeConnections,
  }) : super(title: 'Inputs');
  
  @override
  State<InputPanelWidget> createState() => _InputPanelWidgetState();
}

class _InputPanelWidgetState extends _ConnectionPanelWidgetState<InputPanelWidget> {
  @override
  String getConnectionLabel(int index) => 'I${index + 1}';
  
  @override
  bool get isInputPanel => true;
}

/// Widget representing an output panel with draggable connection points
class OutputPanelWidget extends ConnectionPanelWidget {
  const OutputPanelWidget({
    super.key,
    required super.connectionCount,
    required super.position,
    super.onPositionChanged,
    super.onConnectionDragStart,
    super.onConnectionDragUpdate,
    super.onConnectionDragEnd,
    super.activeConnections,
  }) : super(title: 'Outputs');
  
  @override
  State<OutputPanelWidget> createState() => _OutputPanelWidgetState();
}

class _OutputPanelWidgetState extends _ConnectionPanelWidgetState<OutputPanelWidget> {
  @override
  String getConnectionLabel(int index) => 'O${index + 1}';
  
  @override
  bool get isInputPanel => false;
}

/// Base state class for connection panel widgets
abstract class _ConnectionPanelWidgetState<T extends ConnectionPanelWidget> 
    extends State<T> {
  bool _isDragging = false;
  Offset _dragOffset = Offset.zero;
  int? _activeConnectionIndex;
  
  // Abstract methods to be implemented by subclasses
  String getConnectionLabel(int index);
  bool get isInputPanel;
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Positioned(
      left: widget.position.dx,
      top: widget.position.dy,
      child: GestureDetector(
        onPanStart: _handlePanelDragStart,
        onPanUpdate: _handlePanelDragUpdate,
        onPanEnd: _handlePanelDragEnd,
        child: AnimatedContainer(
          duration: _isDragging ? Duration.zero : const Duration(milliseconds: 150),
          width: 120,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.5),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: _isDragging ? 0.3 : 0.1),
                blurRadius: _isDragging ? 8 : 4,
                offset: Offset(0, _isDragging ? 4 : 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTitleBar(theme),
              _buildConnectionPoints(theme),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildTitleBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
      ),
      child: Text(
        widget.title,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
  
  Widget _buildConnectionPoints(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          widget.connectionCount,
          (index) => _buildConnectionPoint(theme, index),
        ),
      ),
    );
  }
  
  Widget _buildConnectionPoint(ThemeData theme, int index) {
    final isActive = widget.activeConnections[index] ?? false;
    final label = getConnectionLabel(index);
    
    return Semantics(
      label: '$label connection point',
      hint: isActive ? 'Connected' : 'Available for connection',
      button: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: GestureDetector(
          onPanStart: (details) => _handleConnectionDragStart(index, details),
          onPanUpdate: (details) => _handleConnectionDragUpdate(index, details),
          onPanEnd: (details) => _handleConnectionDragEnd(index),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: isInputPanel 
                ? MainAxisAlignment.start 
                : MainAxisAlignment.end,
            children: [
              if (!isInputPanel) ...[
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: isActive ? 16 : 14,
                height: isActive ? 16 : 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive
                      ? (isInputPanel ? theme.colorScheme.primary : theme.colorScheme.secondary)
                      : theme.colorScheme.surface,
                  border: Border.all(
                    color: isActive
                        ? (isInputPanel ? theme.colorScheme.primary : theme.colorScheme.secondary)
                        : theme.colorScheme.outline,
                    width: isActive ? 2 : 1,
                  ),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: (isInputPanel 
                                ? theme.colorScheme.primary 
                                : theme.colorScheme.secondary).withValues(alpha: 0.4),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
                child: isActive
                    ? Center(
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: theme.colorScheme.onPrimary,
                          ),
                        ),
                      )
                    : null,
              ),
              if (isInputPanel) ...[
                const SizedBox(width: 8),
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
  
  // Panel dragging handlers
  void _handlePanelDragStart(DragStartDetails details) {
    setState(() {
      _isDragging = true;
      _dragOffset = details.localPosition;
    });
    debugPrint('${widget.title}Panel: Panel drag started at ${details.localPosition}');
  }
  
  void _handlePanelDragUpdate(DragUpdateDetails details) {
    if (!_isDragging || _activeConnectionIndex != null) return;
    
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
      snappedPosition.dx.clamp(0, canvasSize - 120),
      snappedPosition.dy.clamp(0, canvasSize - 200),
    );
    
    widget.onPositionChanged?.call(constrainedPosition);
    
    debugPrint('${widget.title}Panel: Dragging to ${constrainedPosition.dx},${constrainedPosition.dy}');
  }
  
  void _handlePanelDragEnd(DragEndDetails details) {
    setState(() {
      _isDragging = false;
    });
    debugPrint('${widget.title}Panel: Panel drag ended');
  }
  
  // Connection point dragging handlers
  void _handleConnectionDragStart(int index, DragStartDetails details) {
    setState(() {
      _activeConnectionIndex = index;
    });
    
    // Convert to global coordinates for accurate canvas mapping
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final globalPosition = renderBox.localToGlobal(details.localPosition);
      widget.onConnectionDragStart?.call(index, globalPosition);
      debugPrint('${widget.title}Panel: Connection ${getConnectionLabel(index)} drag started at $globalPosition');
    }
  }
  
  void _handleConnectionDragUpdate(int index, DragUpdateDetails details) {
    if (_activeConnectionIndex != index) return;
    
    widget.onConnectionDragUpdate?.call(index, details.globalPosition);
    debugPrint('${widget.title}Panel: Connection ${getConnectionLabel(index)} dragging at ${details.globalPosition}');
  }
  
  void _handleConnectionDragEnd(int index) {
    setState(() {
      _activeConnectionIndex = null;
    });
    
    widget.onConnectionDragEnd?.call(index);
    debugPrint('${widget.title}Panel: Connection ${getConnectionLabel(index)} drag ended');
  }
  
  // Removed dependency on RoutingEditorWidget static values
}
