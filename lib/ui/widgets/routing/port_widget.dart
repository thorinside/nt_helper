import 'package:flutter/material.dart';
import 'package:nt_helper/core/routing/models/port.dart';

/// Enum for configurable label positioning relative to port
enum PortLabelPosition {
  /// Label on the left side of the port
  left,
  /// Label on the right side of the port
  right,
}

/// Enum for port rendering style
enum PortStyle {
  /// Simple circular dot style used in algorithm nodes
  dot,
  /// Jack socket style used in physical I/O nodes
  jack,
}

/// A reusable port widget for displaying connection points in routing nodes.
/// 
/// This widget provides a consistent visual representation for ports across
/// algorithm nodes and physical I/O nodes. It includes configurable label
/// positioning, rendering styles, and callback support for position resolution.
class PortWidget extends StatefulWidget {
  /// The text label for the port
  final String label;
  
  /// Whether this is an input port (affects visual styling)
  final bool isInput;
  
  /// Optional unique identifier for the port
  final String? portId;
  
  /// Optional Port model for richer functionality
  final Port? port;
  
  /// Configurable position of the label relative to the port
  final PortLabelPosition labelPosition;
  
  /// Visual style for rendering the port
  final PortStyle style;
  
  /// Theme data to use for styling the port
  final ThemeData? theme;
  
  /// Callback to report the port's global center position after layout
  final void Function(String portId, Offset globalCenter, bool isInput)? onPortPositionResolved;
  
  /// Callback for port tap events
  final VoidCallback? onTap;
  
  /// Callback for drag start events
  final VoidCallback? onDragStart;
  
  /// Callback for drag update events
  final void Function(Offset position)? onDragUpdate;
  
  /// Callback for drag end events
  final void Function(Offset position)? onDragEnd;
  
  /// Callback for mouse hover enter events  
  final VoidCallback? onHoverEnter;
  
  /// Callback for mouse hover exit events
  final VoidCallback? onHoverExit;
  
  /// Whether this port is currently connected to other ports
  final bool isConnected;
  
  /// List of connection IDs that involve this port
  final List<String> connectionIds;
  
  /// Direct callback to routing cubit for connection operations
  final void Function(String portId, String action)? onRoutingAction;
  
  const PortWidget({
    super.key,
    required this.label,
    required this.isInput,
    this.portId,
    this.port,
    this.labelPosition = PortLabelPosition.right,
    this.style = PortStyle.dot,
    this.theme,
    this.onPortPositionResolved,
    this.onTap,
    this.onDragStart,
    this.onDragUpdate,
    this.onDragEnd,
    this.onHoverEnter,
    this.onHoverExit,
    this.isConnected = false,
    this.connectionIds = const [],
    this.onRoutingAction,
  });
  
  @override
  State<PortWidget> createState() => _PortWidgetState();
}

class _PortWidgetState extends State<PortWidget> {
  late final GlobalKey _dotKey;
  
  @override
  void initState() {
    super.initState();
    _dotKey = GlobalKey();
  }
  
  @override
  Widget build(BuildContext context) {
    final effectiveTheme = widget.theme ?? Theme.of(context);
    
    Widget portWidget;
    
    switch (widget.style) {
      case PortStyle.dot:
        portWidget = _buildDotStyle(effectiveTheme);
        break;
      case PortStyle.jack:
        portWidget = _buildJackStyle(effectiveTheme);
        break;
    }
    
    // Add gesture detection for interaction callbacks
    if (widget.onTap != null || widget.onDragStart != null || 
        widget.onDragUpdate != null || widget.onDragEnd != null) {
      portWidget = GestureDetector(
        onTap: widget.onTap,
        onPanStart: widget.onDragStart != null ? (_) => widget.onDragStart!() : null,
        onPanUpdate: widget.onDragUpdate != null ? (details) => widget.onDragUpdate!(details.globalPosition) : null,
        onPanEnd: widget.onDragEnd != null ? (details) => widget.onDragEnd!(details.velocity.pixelsPerSecond) : null,
        child: portWidget,
      );
    }
    
    return portWidget;
  }
  
  
  /// Builds the simple dot style port (for algorithm nodes)
  Widget _buildDotStyle(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        children: _buildPortElements(theme),
      ),
    );
  }
  
  /// Builds the jack socket style port (for physical I/O nodes)
  Widget _buildJackStyle(ThemeData theme) {
    // For now, use a simpler jack representation
    // This could be enhanced to use the full JackConnectionWidget functionality
    
    Widget jackDot = Container(
      key: _dotKey,
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: widget.isInput ? theme.colorScheme.primary : theme.colorScheme.secondary,
        border: Border.all(
          color: theme.colorScheme.outline,
          width: 2,
        ),
      ),
    );
    
    // Add hover detection only to the jack dot when routing action callback is provided
    if (widget.onRoutingAction != null) {
      jackDot = MouseRegion(
        onEnter: (_) {
          widget.onHoverEnter?.call();
          // Notify routing cubit about hover start - it will determine if port is connected
          if (widget.portId != null) {
            widget.onRoutingAction?.call(widget.portId!, 'hover_start');
          }
        },
        onExit: (_) {
          widget.onHoverExit?.call();
          // Notify routing cubit about hover end
          if (widget.portId != null) {
            widget.onRoutingAction?.call(widget.portId!, 'hover_end');
          }
        },
        child: jackDot,
      );
    }
    
    return Container(
      width: 120,
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: widget.labelPosition == PortLabelPosition.left 
            ? MainAxisAlignment.start 
            : MainAxisAlignment.end,
        children: [
          if (widget.labelPosition == PortLabelPosition.left) ...[
            Expanded(
              child: Text(
                widget.label,
                style: theme.textTheme.labelSmall,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
          ],
          jackDot,
          if (widget.labelPosition == PortLabelPosition.right) ...[
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.label,
                style: theme.textTheme.labelSmall,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _schedulePortPositionResolution();
  }
  
  @override
  void didUpdateWidget(covariant PortWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _schedulePortPositionResolution();
  }
  
  /// Builds the port elements based on label position
  List<Widget> _buildPortElements(ThemeData theme) {
    final portDot = _buildPortDot(theme);
    final portLabel = _buildPortLabel(theme);
    
    switch (widget.labelPosition) {
      case PortLabelPosition.left:
        return [
          portLabel,
          const SizedBox(width: 4),
          portDot,
        ];
      case PortLabelPosition.right:
        return [
          portDot,
          const SizedBox(width: 4),
          portLabel,
        ];
    }
  }
  
  /// Builds the visual port dot/circle
  Widget _buildPortDot(ThemeData theme) {
    Widget dot = Container(
      key: _dotKey,
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: widget.isInput ? theme.colorScheme.primary : theme.colorScheme.secondary,
        border: Border.all(
          color: theme.colorScheme.outline,
          width: 1,
        ),
      ),
    );
    
    // Add hover detection only to the dot when routing action callback is provided
    if (widget.onRoutingAction != null) {
      dot = MouseRegion(
        onEnter: (_) {
          widget.onHoverEnter?.call();
          // Notify routing cubit about hover start - it will determine if port is connected
          if (widget.portId != null) {
            widget.onRoutingAction?.call(widget.portId!, 'hover_start');
          }
        },
        onExit: (_) {
          widget.onHoverExit?.call();
          // Notify routing cubit about hover end
          if (widget.portId != null) {
            widget.onRoutingAction?.call(widget.portId!, 'hover_end');
          }
        },
        child: dot,
      );
    }
    
    return dot;
  }
  
  /// Builds the port label text
  Widget _buildPortLabel(ThemeData theme) {
    return Text(
      widget.label,
      style: theme.textTheme.labelSmall,
    );
  }
  
  /// Schedules port position resolution after the next frame
  void _schedulePortPositionResolution() {
    if (widget.onPortPositionResolved == null || widget.portId == null) return;
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _dotKey.currentContext;
      if (ctx == null) return;
      
      final render = ctx.findRenderObject() as RenderBox?;
      if (render == null || !render.attached) return;
      
      final topLeft = render.localToGlobal(Offset.zero);
      final size = render.size; // 12x12
      final center = topLeft + Offset(size.width / 2, size.height / 2);
      
      widget.onPortPositionResolved!(widget.portId!, center, widget.isInput);
    });
  }
}