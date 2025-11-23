import 'package:flutter/material.dart';

/// CustomPainter for efficient pitch bar rendering
///
/// Renders a vertical bar with:
/// - Dark teal gradient background (bottom to top)
/// - Bright teal fill from bottom to pitch level
class PitchBarPainter extends CustomPainter {
  final int pitchValue; // 0-127 MIDI note

  // Teal color scheme
  static const darkTeal = Color(0xFF0f766e);
  static const darkerTeal = Color(0xFF115e59);
  static const brightTeal = Color(0xFF5eead4);

  const PitchBarPainter({
    required this.pitchValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw dark teal gradient background
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [darkTeal, darkerTeal],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      bgPaint,
    );

    // Draw bright teal fill from bottom to pitch level
    final fillHeight = (pitchValue / 127.0) * size.height;
    final fillPaint = Paint()..color = brightTeal;

    canvas.drawRect(
      Rect.fromLTWH(0, size.height - fillHeight, size.width, fillHeight),
      fillPaint,
    );
  }

  @override
  bool shouldRepaint(covariant PitchBarPainter oldDelegate) {
    // Only repaint if pitch value changes
    return pitchValue != oldDelegate.pitchValue;
  }
}
