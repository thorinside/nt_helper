import 'package:flutter/material.dart';
import 'package:nt_helper/core/routing/models/port.dart' as core_port;

/// Visual indicator for port output mode (Add/Replace)
class PortModeIndicator extends StatelessWidget {
  final core_port.OutputMode mode;
  final bool isVisible;
  final double size;

  const PortModeIndicator({
    super.key,
    required this.mode,
    this.isVisible = true,
    this.size = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final isReplaceMode = mode == core_port.OutputMode.replace;
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isReplaceMode 
            ? Colors.orange.withValues(alpha: 0.9)
            : Colors.blue.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(size / 2),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Center(
        child: Text(
          isReplaceMode ? 'R' : 'A',
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.6,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

/// Animated port mode toggle widget for output ports
class PortModeToggle extends StatefulWidget {
  final core_port.OutputMode currentMode;
  final ValueChanged<core_port.OutputMode> onModeChanged;
  final String portName;
  final bool enabled;

  const PortModeToggle({
    super.key,
    required this.currentMode,
    required this.onModeChanged,
    required this.portName,
    this.enabled = true,
  });

  @override
  State<PortModeToggle> createState() => _PortModeToggleState();
}

class _PortModeToggleState extends State<PortModeToggle>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleMode() {
    if (!widget.enabled) return;

    // Animate the toggle
    _animationController.forward().then((_) {
      _animationController.reverse();
    });

    // Toggle the mode
    final newMode = widget.currentMode == core_port.OutputMode.add
        ? core_port.OutputMode.replace
        : core_port.OutputMode.add;
    
    widget.onModeChanged(newMode);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isReplaceMode = widget.currentMode == core_port.OutputMode.replace;

    return Tooltip(
      message: 'Toggle output mode for ${widget.portName}\n'
          'Current: ${isReplaceMode ? 'Replace' : 'Add'}\n'
          'Tap to switch to ${isReplaceMode ? 'Add' : 'Replace'} mode',
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: GestureDetector(
              onTap: _toggleMode,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isReplaceMode
                      ? Colors.orange.withValues(alpha: 0.1)
                      : Colors.blue.withValues(alpha: 0.1),
                  border: Border.all(
                    color: isReplaceMode
                        ? Colors.orange.withValues(alpha: 0.5)
                        : Colors.blue.withValues(alpha: 0.5),
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PortModeIndicator(
                      mode: widget.currentMode,
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isReplaceMode ? 'Replace' : 'Add',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isReplaceMode
                            ? Colors.orange.shade700
                            : Colors.blue.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Extension to add mode indicator suffix to port names
extension PortModeExtension on String {
  /// Add mode indicator suffix to port name
  String withModeIndicator(core_port.OutputMode mode) {
    final suffix = mode == core_port.OutputMode.replace ? ' (R)' : ' (A)';
    return '$this$suffix';
  }
}

/// Helper widget for showing mode change feedback
class PortModeSnackbar {
  static void show(
    BuildContext context, {
    required String portName,
    required core_port.OutputMode newMode,
  }) {
    final modeText = newMode == core_port.OutputMode.replace ? 'Replace' : 'Add';
    final color = newMode == core_port.OutputMode.replace 
        ? Colors.orange 
        : Colors.blue;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PortModeIndicator(mode: newMode, size: 18),
            const SizedBox(width: 8),
            Text('$portName mode changed to $modeText'),
          ],
        ),
        backgroundColor: color.withValues(alpha: 0.9),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}