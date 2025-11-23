import 'package:flutter/material.dart';
import 'package:nt_helper/ui/widgets/step_sequencer/pitch_bar_painter.dart';

/// Individual step column widget showing pitch bar, velocity, and step number
class StepColumnWidget extends StatelessWidget {
  final int stepIndex; // 0-indexed
  final int pitchValue; // 0-127 MIDI note
  final int velocityValue; // 0-127
  final bool isActive;
  final VoidCallback? onTap; // Callback for tap gesture

  const StepColumnWidget({
    super.key,
    required this.stepIndex,
    required this.pitchValue,
    required this.velocityValue,
    required this.isActive,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Teal color scheme
    const primaryTeal = Color(0xFF14b8a6);
    final borderColor = isActive ? primaryTeal : _getBorderColor(isDark);
    final borderWidth = isActive ? 2.0 : 1.0;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: isActive
              ? primaryTeal.withValues(alpha: 0.2)
              : _getBackgroundColor(isDark),
          border: Border.all(
            color: borderColor,
            width: borderWidth,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Step number (1-indexed for display)
          Text(
            '${stepIndex + 1}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: _getTextColor(isDark),
            ),
          ),
          const SizedBox(height: 4),

          // Pitch bar
          Expanded(
            child: SizedBox(
              width: double.infinity,
              child: CustomPaint(
                painter: PitchBarPainter(
                  pitchValue: pitchValue,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),

          // Velocity indicator
          Container(
            width: double.infinity,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.grey.shade800,
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: velocityValue / 127.0,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF5eead4), // brightTeal
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const SizedBox(height: 2),

          // Velocity value text
          Text(
            velocityValue.toString(),
            style: TextStyle(
              fontSize: 10,
              color: _getTextColor(isDark),
            ),
          ),
        ],
        ),
      ),
    );
  }

  Color _getBackgroundColor(bool isDark) {
    return isDark ? Colors.grey.shade900 : Colors.grey.shade50;
  }

  Color _getBorderColor(bool isDark) {
    return isDark ? Colors.grey.shade700 : Colors.grey.shade300;
  }

  Color _getTextColor(bool isDark) {
    return isDark ? Colors.grey.shade400 : Colors.grey.shade700;
  }
}
