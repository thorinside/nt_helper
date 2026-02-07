import 'package:flutter/material.dart';
import 'package:nt_helper/models/flash_progress.dart';
import 'package:nt_helper/models/flash_stage.dart';

/// Animated diagram showing the firmware update flow:
/// Computer → Connection Line → Disting NT
///
/// The connection line animates based on the current flash stage.
class FirmwareFlowDiagram extends StatefulWidget {
  final FlashProgress progress;

  const FirmwareFlowDiagram({super.key, required this.progress});

  @override
  State<FirmwareFlowDiagram> createState() => _FirmwareFlowDiagramState();
}

class _FirmwareFlowDiagramState extends State<FirmwareFlowDiagram>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _getStageDescription() {
    if (widget.progress.isError) {
      return 'Error during firmware update';
    }
    switch (widget.progress.stage) {
      case FlashStage.sdpConnect:
        return 'Connecting to Disting NT';
      case FlashStage.blCheck:
        return 'Checking bootloader';
      case FlashStage.sdpUpload:
        return 'Uploading firmware to device';
      case FlashStage.write:
        return 'Writing firmware to flash memory';
      case FlashStage.configure:
        return 'Configuring device';
      case FlashStage.reset:
        return 'Resetting device';
      case FlashStage.complete:
        return 'Firmware update complete';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if animations should be disabled
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    final semanticDescription = _getStageDescription();

    if (reduceMotion) {
      // Static version for reduced motion
      return Semantics(
        label: 'Firmware update diagram: $semanticDescription',
        liveRegion: true,
        child: CustomPaint(
          painter: _FlowDiagramPainter(
            stage: widget.progress.stage,
            isError: widget.progress.isError,
            animationValue: 0.5,
            theme: Theme.of(context),
          ),
          size: const Size(double.infinity, 150),
        ),
      );
    }

    return Semantics(
      label: 'Firmware update diagram: $semanticDescription',
      liveRegion: true,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _FlowDiagramPainter(
              stage: widget.progress.stage,
              isError: widget.progress.isError,
              animationValue: _controller.value,
              theme: Theme.of(context),
            ),
            size: const Size(double.infinity, 150),
          );
        },
      ),
    );
  }
}

class _FlowDiagramPainter extends CustomPainter {
  final FlashStage stage;
  final bool isError;
  final double animationValue;
  final ThemeData theme;

  _FlowDiagramPainter({
    required this.stage,
    required this.isError,
    required this.animationValue,
    required this.theme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height / 2;
    final iconSize = 50.0;
    final padding = 40.0;

    // Positions
    final computerX = padding + iconSize / 2;
    final distingX = size.width - padding - iconSize / 2;
    final lineStart = computerX + iconSize / 2 + 10;
    final lineEnd = distingX - iconSize / 2 - 10;

    // Draw computer icon
    _drawComputerIcon(canvas, Offset(computerX, centerY), iconSize);

    // Draw connection line
    _drawConnectionLine(canvas, lineStart, lineEnd, centerY);

    // Draw Disting NT icon
    _drawDistingIcon(canvas, Offset(distingX, centerY), iconSize);

    // Draw status indicator on line
    _drawStatusIndicator(canvas, lineStart, lineEnd, centerY);
  }

  void _drawComputerIcon(Canvas canvas, Offset center, double size) {
    final paint = Paint()
      ..color = theme.colorScheme.onSurface
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Monitor body
    final monitorRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center.translate(0, -5), width: size, height: size * 0.7),
      const Radius.circular(4),
    );
    canvas.drawRRect(monitorRect, paint);

    // Monitor stand
    final standPath = Path()
      ..moveTo(center.dx - 8, center.dy + size * 0.35 - 5)
      ..lineTo(center.dx + 8, center.dy + size * 0.35 - 5)
      ..lineTo(center.dx + 12, center.dy + size * 0.5)
      ..lineTo(center.dx - 12, center.dy + size * 0.5)
      ..close();
    canvas.drawPath(standPath, paint);
  }

  void _drawDistingIcon(Canvas canvas, Offset center, double size) {
    final paint = Paint()
      ..color = theme.colorScheme.onSurface
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Module body (tall rectangle like a Eurorack module)
    final moduleRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: size * 0.5, height: size),
      const Radius.circular(3),
    );
    canvas.drawRRect(moduleRect, paint);

    // Screen/display area
    final screenRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center.translate(0, -size * 0.2), width: size * 0.35, height: size * 0.25),
      const Radius.circular(2),
    );
    canvas.drawRRect(screenRect, paint);

    // Knobs (3 circles)
    final knobPaint = Paint()
      ..color = theme.colorScheme.onSurface
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center.translate(0, size * 0.15), 4, knobPaint);
    canvas.drawCircle(center.translate(-8, size * 0.35), 3, knobPaint);
    canvas.drawCircle(center.translate(8, size * 0.35), 3, knobPaint);
  }

  void _drawConnectionLine(Canvas canvas, double startX, double endX, double y) {
    final lineColor = isError
        ? theme.colorScheme.error
        : _getLineColor();

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    // Determine line style based on stage
    if (stage == FlashStage.sdpConnect) {
      // Dashed line while connecting
      _drawDashedLine(canvas, startX, endX, y, linePaint);
    } else {
      // Solid line once connected
      canvas.drawLine(Offset(startX, y), Offset(endX, y), linePaint);
    }
  }

  void _drawDashedLine(Canvas canvas, double startX, double endX, double y, Paint paint) {
    const dashWidth = 8.0;
    const dashSpace = 6.0;
    double currentX = startX;

    while (currentX < endX) {
      final nextX = (currentX + dashWidth).clamp(startX, endX);
      canvas.drawLine(Offset(currentX, y), Offset(nextX, y), paint);
      currentX += dashWidth + dashSpace;
    }
  }

  void _drawStatusIndicator(Canvas canvas, double lineStart, double lineEnd, double y) {
    if (isError) {
      // Error X mark
      _drawErrorMark(canvas, (lineStart + lineEnd) / 2, y);
      return;
    }

    if (stage == FlashStage.complete) {
      // Checkmark for complete
      _drawCheckmark(canvas, (lineStart + lineEnd) / 2, y);
      return;
    }

    // Animated flow dots for uploading/writing
    if (stage == FlashStage.sdpUpload || stage == FlashStage.write) {
      _drawFlowDots(canvas, lineStart, lineEnd, y);
    } else if (stage == FlashStage.sdpConnect) {
      // Pulsing dot for connecting
      _drawPulsingDot(canvas, (lineStart + lineEnd) / 2, y);
    }
  }

  void _drawFlowDots(Canvas canvas, double lineStart, double lineEnd, double y) {
    final dotPaint = Paint()
      ..color = theme.colorScheme.primary
      ..style = PaintingStyle.fill;

    final lineLength = lineEnd - lineStart;
    const numDots = 4;
    const dotRadius = 4.0;

    for (int i = 0; i < numDots; i++) {
      final basePosition = (animationValue + i / numDots) % 1.0;
      final x = lineStart + basePosition * lineLength;

      // Fade in/out at edges
      double opacity = 1.0;
      final edgeFade = lineLength * 0.15;
      if (x - lineStart < edgeFade) {
        opacity = (x - lineStart) / edgeFade;
      } else if (lineEnd - x < edgeFade) {
        opacity = (lineEnd - x) / edgeFade;
      }

      canvas.drawCircle(
        Offset(x, y),
        dotRadius,
        dotPaint..color = theme.colorScheme.primary.withValues(alpha: opacity),
      );
    }
  }

  void _drawPulsingDot(Canvas canvas, double x, double y) {
    final pulseSize = 6 + (animationValue * 4);
    final opacity = 1.0 - (animationValue * 0.5);

    final dotPaint = Paint()
      ..color = theme.colorScheme.primary.withValues(alpha: opacity)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(x, y), pulseSize, dotPaint);
  }

  void _drawCheckmark(Canvas canvas, double x, double y) {
    final paint = Paint()
      ..color = theme.colorScheme.primary
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Draw circle background
    final bgPaint = Paint()
      ..color = theme.colorScheme.primaryContainer
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(x, y), 16, bgPaint);

    // Draw checkmark
    final path = Path()
      ..moveTo(x - 8, y)
      ..lineTo(x - 2, y + 6)
      ..lineTo(x + 8, y - 6);
    canvas.drawPath(path, paint);
  }

  void _drawErrorMark(Canvas canvas, double x, double y) {
    final paint = Paint()
      ..color = theme.colorScheme.error
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Draw circle background
    final bgPaint = Paint()
      ..color = theme.colorScheme.errorContainer
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(x, y), 16, bgPaint);

    // Draw X
    canvas.drawLine(Offset(x - 6, y - 6), Offset(x + 6, y + 6), paint);
    canvas.drawLine(Offset(x + 6, y - 6), Offset(x - 6, y + 6), paint);
  }

  Color _getLineColor() {
    switch (stage) {
      case FlashStage.sdpConnect:
        return theme.colorScheme.outline;
      case FlashStage.blCheck:
      case FlashStage.sdpUpload:
      case FlashStage.write:
        return theme.colorScheme.primary;
      case FlashStage.configure:
      case FlashStage.reset:
      case FlashStage.complete:
        return theme.colorScheme.primary;
    }
  }

  @override
  bool shouldRepaint(covariant _FlowDiagramPainter oldDelegate) {
    return oldDelegate.stage != stage ||
        oldDelegate.isError != isError ||
        oldDelegate.animationValue != animationValue;
  }
}
