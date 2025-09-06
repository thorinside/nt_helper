import 'package:flutter/material.dart';

/// A dismissible error notification that appears as an overlay
class ErrorNotification extends StatefulWidget {
  final String message;
  final VoidCallback onDismiss;
  final Duration? autoHideDuration;

  const ErrorNotification({
    super.key,
    required this.message,
    required this.onDismiss,
    this.autoHideDuration,
  });

  @override
  State<ErrorNotification> createState() => _ErrorNotificationState();
}

class _ErrorNotificationState extends State<ErrorNotification>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    // Start entrance animation
    _animationController.forward();

    // Auto-hide if duration is specified
    if (widget.autoHideDuration != null) {
      Future.delayed(widget.autoHideDuration!, () {
        if (mounted) {
          _dismiss();
        }
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _dismiss() async {
    await _animationController.reverse();
    if (mounted) {
      widget.onDismiss();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 20,
      right: 20,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 300),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red[50],
                border: Border.all(color: Colors.red[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Colors.red[700],
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.message,
                      style: TextStyle(
                        color: Colors.red[700],
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _dismiss,
                    child: Icon(
                      Icons.close,
                      color: Colors.red[700],
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Manager for showing and hiding error notifications
class ErrorNotificationManager extends StatefulWidget {
  final Widget child;

  const ErrorNotificationManager({
    super.key,
    required this.child,
  });

  static ErrorNotificationManagerState? of(BuildContext context) {
    return context.findAncestorStateOfType<ErrorNotificationManagerState>();
  }

  @override
  State<ErrorNotificationManager> createState() => ErrorNotificationManagerState();
}

class ErrorNotificationManagerState extends State<ErrorNotificationManager> {
  final List<String> _activeErrors = [];

  void showError(String message, {Duration? autoHideDuration}) {
    setState(() {
      // Avoid duplicate messages
      if (!_activeErrors.contains(message)) {
        _activeErrors.add(message);
      }
    });

    // Auto-hide after duration if specified
    if (autoHideDuration != null) {
      Future.delayed(autoHideDuration, () {
        hideError(message);
      });
    }
  }

  void hideError(String message) {
    setState(() {
      _activeErrors.remove(message);
    });
  }

  void clearAllErrors() {
    setState(() {
      _activeErrors.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        // Show error notifications
        ..._activeErrors.asMap().entries.map((entry) {
          final index = entry.key;
          final message = entry.value;
          
          return Positioned(
            top: 20 + (index * 80), // Stack multiple notifications
            right: 20,
            child: ErrorNotification(
              message: message,
              autoHideDuration: const Duration(seconds: 5),
              onDismiss: () => hideError(message),
            ),
          );
        }),
      ],
    );
  }
}

/// Extension to easily show error notifications
extension ErrorNotificationExtension on BuildContext {
  void showErrorNotification(String message, {Duration? autoHideDuration}) {
    final manager = ErrorNotificationManager.of(this);
    manager?.showError(message, autoHideDuration: autoHideDuration);
  }

  void hideErrorNotification(String message) {
    final manager = ErrorNotificationManager.of(this);
    manager?.hideError(message);
  }

  void clearAllErrorNotifications() {
    final manager = ErrorNotificationManager.of(this);
    manager?.clearAllErrors();
  }
}