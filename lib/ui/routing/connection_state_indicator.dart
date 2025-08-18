import 'package:flutter/material.dart';

/// Widget for showing connection state (pending/confirmed/failed)
class ConnectionStateIndicator extends StatefulWidget {
  final bool isPending;
  final bool isFailed;
  final VoidCallback? onRetry;
  
  const ConnectionStateIndicator({
    super.key,
    this.isPending = false,
    this.isFailed = false,
    this.onRetry,
  });

  @override
  State<ConnectionStateIndicator> createState() => _ConnectionStateIndicatorState();
}

class _ConnectionStateIndicatorState extends State<ConnectionStateIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _opacityAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _opacityAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.linear,
    ));

    if (widget.isPending) {
      _animationController.repeat();
    }
  }

  @override
  void didUpdateWidget(ConnectionStateIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isPending != oldWidget.isPending) {
      if (widget.isPending) {
        _animationController.repeat();
      } else {
        _animationController.stop();
        _animationController.reset();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isFailed) {
      return _buildFailedIndicator();
    } else if (widget.isPending) {
      return _buildPendingIndicator();
    } else {
      return _buildConfirmedIndicator();
    }
  }

  Widget _buildPendingIndicator() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.orange.withValues(alpha: _opacityAnimation.value),
          ),
          child: Transform.rotate(
            angle: _rotationAnimation.value * 2 * 3.14159,
            child: const Icon(
              Icons.refresh,
              size: 12,
              color: Colors.white,
            ),
          ),
        );
      },
    );
  }

  Widget _buildFailedIndicator() {
    return GestureDetector(
      onTap: widget.onRetry,
      child: Container(
        width: 16,
        height: 16,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.red,
        ),
        child: widget.onRetry != null
            ? const Icon(
                Icons.refresh,
                size: 12,
                color: Colors.white,
              )
            : const Icon(
                Icons.error,
                size: 12,
                color: Colors.white,
              ),
      ),
    );
  }

  Widget _buildConfirmedIndicator() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 300),
      tween: Tween<double>(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.green.withValues(alpha: value * 0.8),
          ),
          child: Transform.scale(
            scale: value,
            child: const Icon(
              Icons.check,
              size: 12,
              color: Colors.white,
            ),
          ),
        );
      },
    );
  }
}