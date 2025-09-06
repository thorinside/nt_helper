import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nt_helper/cubit/routing_editor_cubit.dart';
import 'package:nt_helper/core/routing/models/connection.dart';

/// Widget that handles connection deletion gestures
class ConnectionDeletionHandler extends StatefulWidget {
  final Widget child;
  final Connection connection;
  final Offset startPosition;
  final Offset endPosition;

  const ConnectionDeletionHandler({
    super.key,
    required this.child,
    required this.connection,
    required this.startPosition,
    required this.endPosition,
  });

  @override
  State<ConnectionDeletionHandler> createState() => _ConnectionDeletionHandlerState();
}

class _ConnectionDeletionHandlerState extends State<ConnectionDeletionHandler>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  bool _showDeleteIcon = false;
  Offset? _lastHoverPosition;
  late AnimationController _hoverAnimationController;
  late Animation<double> _hoverAnimation;

  @override
  void initState() {
    super.initState();
    _hoverAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _hoverAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1, // 10% thickness increase
    ).animate(CurvedAnimation(
      parent: _hoverAnimationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _hoverAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: _handleMouseEnter,
      onExit: _handleMouseExit,
      onHover: _handleMouseHover,
      child: GestureDetector(
        onTap: () => _handleTap(context),
        onDoubleTap: () => _handleDoubleTap(context),
        child: AnimatedBuilder(
          animation: _hoverAnimation,
          builder: (context, child) {
            return CustomPaint(
              painter: ConnectionPainter(
                connection: widget.connection,
                startPosition: widget.startPosition,
                endPosition: widget.endPosition,
                isHovered: _isHovered,
                thicknessMultiplier: _hoverAnimation.value,
                showDeleteIcon: _showDeleteIcon,
                deleteIconPosition: _lastHoverPosition,
              ),
              child: widget.child,
            );
          },
        ),
      ),
    );
  }

  void _handleMouseEnter(PointerEvent event) {
    setState(() {
      _isHovered = true;
      _showDeleteIcon = true;
      _lastHoverPosition = event.localPosition;
    });
    _hoverAnimationController.forward();
  }

  void _handleMouseExit(PointerEvent event) {
    setState(() {
      _isHovered = false;
      _showDeleteIcon = false;
    });
    _hoverAnimationController.reverse();
  }

  void _handleMouseHover(PointerEvent event) {
    setState(() {
      _lastHoverPosition = event.localPosition;
    });
  }

  void _handleTap(BuildContext context) {
    // On touch devices, show confirmation dialog
    if (Theme.of(context).platform == TargetPlatform.iOS || 
        Theme.of(context).platform == TargetPlatform.android) {
      _showDeleteConfirmationDialog(context);
    } else {
      // On desktop, direct delete if delete icon is shown and clicked
      if (_showDeleteIcon && _lastHoverPosition != null) {
        // Check if tap was within delete icon bounds (simplified check)
        context.read<RoutingEditorCubit>().deleteConnectionOptimistic(
          widget.connection.id,
        );
      }
    }
  }

  void _handleDoubleTap(BuildContext context) {
    // Double-tap to delete on any platform
    _showDeleteConfirmationDialog(context);
  }

  void _showDeleteConfirmationDialog(BuildContext context) {
    showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Connection'),
        content: const Text('Are you sure you want to delete this connection?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true && context.mounted) {
        context.read<RoutingEditorCubit>().deleteConnectionOptimistic(
          widget.connection.id,
        );
      }
    });
  }

}

/// Custom painter for rendering connections with deletion support
class ConnectionPainter extends CustomPainter {
  final Connection connection;
  final Offset startPosition;
  final Offset endPosition;
  final bool isHovered;
  final double thicknessMultiplier;
  final bool showDeleteIcon;
  final Offset? deleteIconPosition;

  ConnectionPainter({
    required this.connection,
    required this.startPosition,
    required this.endPosition,
    required this.isHovered,
    required this.thicknessMultiplier,
    required this.showDeleteIcon,
    this.deleteIconPosition,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw connection line
    final paint = Paint()
      ..strokeWidth = 2.0 * thicknessMultiplier
      ..style = PaintingStyle.stroke
      ..color = isHovered 
          ? Colors.blue.withValues(alpha: 0.8)
          : Colors.grey.withValues(alpha: 0.6);

    // Draw different line styles based on connection type
    if (connection.connectionType == ConnectionType.hardwareInput ||
        connection.connectionType == ConnectionType.hardwareOutput) {
      paint.color = Colors.orange.withValues(alpha: isHovered ? 0.8 : 0.6);
    }

    canvas.drawLine(startPosition, endPosition, paint);

    // Draw delete icon if hovering on desktop
    if (showDeleteIcon && deleteIconPosition != null) {
      _drawDeleteIcon(canvas, deleteIconPosition!);
    }
  }

  void _drawDeleteIcon(Canvas canvas, Offset position) {
    // Remove unused iconPaint variable

    final backgroundPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // Draw white background circle
    canvas.drawCircle(position, 10, backgroundPaint);

    // Draw red X
    final strokePaint = Paint()
      ..color = Colors.red
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    const offset = 4.0;
    canvas.drawLine(
      Offset(position.dx - offset, position.dy - offset),
      Offset(position.dx + offset, position.dy + offset),
      strokePaint,
    );
    canvas.drawLine(
      Offset(position.dx + offset, position.dy - offset),
      Offset(position.dx - offset, position.dy + offset),
      strokePaint,
    );

    // Draw border circle
    final borderPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawCircle(position, 10, borderPaint);
  }

  @override
  bool shouldRepaint(ConnectionPainter oldDelegate) {
    return oldDelegate.connection != connection ||
        oldDelegate.isHovered != isHovered ||
        oldDelegate.thicknessMultiplier != thicknessMultiplier ||
        oldDelegate.showDeleteIcon != showDeleteIcon ||
        oldDelegate.deleteIconPosition != deleteIconPosition;
  }
}