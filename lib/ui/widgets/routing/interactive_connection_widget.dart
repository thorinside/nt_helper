import 'package:flutter/material.dart';
import 'package:nt_helper/core/platform/platform_interaction_service.dart';
import 'package:nt_helper/core/routing/models/connection.dart';
import 'package:nt_helper/cubit/routing_editor_cubit.dart';

/// Widget that handles platform-specific interactions for connection deletion
/// 
/// This widget wraps connection visualization and provides:
/// - Desktop: Hover-based delete icons
/// - Mobile: Tap-based selection with confirmation dialogs
class InteractiveConnectionWidget extends StatefulWidget {
  const InteractiveConnectionWidget({
    super.key,
    required this.connection,
    required this.routingEditorCubit,
    required this.child,
    this.platformService,
  });

  final Connection connection;
  final RoutingEditorCubit routingEditorCubit;
  final Widget child;
  final PlatformInteractionService? platformService;

  @override
  State<InteractiveConnectionWidget> createState() => _InteractiveConnectionWidgetState();
}

class _InteractiveConnectionWidgetState extends State<InteractiveConnectionWidget>
    with SingleTickerProviderStateMixin {
  late final PlatformInteractionService _platformService;
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  
  bool _isHovering = false;
  bool _isSelected = false;

  @override
  void initState() {
    super.initState();
    _platformService = widget.platformService ?? PlatformInteractionService();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onHoverEnter() {
    if (!_platformService.supportsHoverInteractions()) return;
    
    setState(() {
      _isHovering = true;
    });
    _animationController.forward();
  }

  void _onHoverExit() {
    if (!_platformService.supportsHoverInteractions()) return;
    
    setState(() {
      _isHovering = false;
    });
    _animationController.reverse();
  }

  void _onTap() {
    if (_platformService.supportsHoverInteractions()) {
      // Desktop: Direct delete on click (when hovering)
      if (_isHovering) {
        _deleteConnection();
      }
    } else {
      // Mobile: Toggle selection
      setState(() {
        _isSelected = !_isSelected;
      });
      
      if (_isSelected) {
        _showDeleteConfirmationDialog();
      }
    }
  }

  void _onLongPress() {
    if (!_platformService.shouldUseTouchInteractions()) return;
    
    // Mobile long press: Show delete confirmation
    _showDeleteConfirmationDialog();
  }

  Future<void> _deleteConnection() async {
    try {
      await widget.routingEditorCubit.deleteConnectionWithSmartBusLogic(
        widget.connection.id,
      );
      
      // Reset interaction state after successful deletion
      if (mounted) {
        setState(() {
          _isHovering = false;
          _isSelected = false;
        });
        _animationController.reset();
      }
    } catch (e) {
      debugPrint('Error deleting connection: $e');
      // Error handling is done in the cubit
    }
  }

  Future<void> _showDeleteConfirmationDialog() async {
    final shouldDelete = await showDialog<bool>(
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
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      await _deleteConnection();
    } else {
      // Reset selection if cancelled
      setState(() {
        _isSelected = false;
      });
    }
  }

  Widget _buildDeleteButton() {
    if (!_isHovering && !_isSelected) return const SizedBox.shrink();

    final minSize = _platformService.getMinimumTouchTargetSize();
    
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return Opacity(
            opacity: _platformService.supportsHoverInteractions() 
                ? _fadeAnimation.value 
                : (_isSelected ? 1.0 : 0.0),
            child: Center(
              child: Container(
                width: minSize,
                height: minSize,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.error.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.close,
                  color: Theme.of(context).colorScheme.onError,
                  size: minSize * 0.5,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget interactiveChild = widget.child;

    // Wrap with appropriate gesture detectors based on platform
    if (_platformService.supportsHoverInteractions()) {
      // Desktop: Mouse hover and click
      interactiveChild = MouseRegion(
        onEnter: (_) => _onHoverEnter(),
        onExit: (_) => _onHoverExit(),
        child: GestureDetector(
          onTap: _onTap,
          behavior: HitTestBehavior.opaque,
          child: interactiveChild,
        ),
      );
    } else {
      // Mobile: Tap and long press
      interactiveChild = GestureDetector(
        onTap: _onTap,
        onLongPress: _onLongPress,
        behavior: HitTestBehavior.opaque,
        child: interactiveChild,
      );
    }

    // Add selection highlight for mobile
    if (_isSelected && _platformService.shouldUseTouchInteractions()) {
      interactiveChild = Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: interactiveChild,
      );
    }

    return Stack(
      children: [
        interactiveChild,
        _buildDeleteButton(),
      ],
    );
  }
}