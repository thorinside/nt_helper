import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:nt_helper/poly_multisample/wav_metadata.dart';

enum PolyWaveformEditorMode { loop, trim }

class PolyWaveformEditor extends StatefulWidget {
  const PolyWaveformEditor({
    super.key,
    required this.overview,
    required this.mode,
    required this.startFrame,
    required this.endFrame,
    required this.onChanged,
    this.height = 120,
  });

  final WavOverview overview;
  final PolyWaveformEditorMode mode;
  final int? startFrame;
  final int? endFrame;
  final void Function(int startFrame, int endFrame) onChanged;
  final double height;

  @override
  State<PolyWaveformEditor> createState() => _PolyWaveformEditorState();
}

class _PolyWaveformEditorState extends State<PolyWaveformEditor> {
  _WaveformHandle? _activeHandle;

  int get _start => widget.startFrame ?? 0;
  int get _end =>
      widget.endFrame ?? math.max(0, widget.overview.frameCount - 1);

  void _beginDrag(Offset position, double width) {
    final startX = _frameToX(_start, width);
    final endX = _frameToX(_end, width);
    final startDistance = (position.dx - startX).abs();
    final endDistance = (position.dx - endX).abs();
    if (math.min(startDistance, endDistance) > 24) {
      _activeHandle = null;
      return;
    }
    _activeHandle = startDistance <= endDistance
        ? _WaveformHandle.start
        : _WaveformHandle.end;
  }

  void _updateDrag(Offset position, double width) {
    final handle = _activeHandle;
    if (handle == null) return;
    final maxFrame = math.max(0, widget.overview.frameCount - 1);
    final rawFrame =
        ((position.dx.clamp(0, width) / math.max(1, width)) *
                widget.overview.frameCount)
            .round();
    final snapped = widget.overview.nearestZeroCrossing(rawFrame);
    final start = _start;
    final end = _end;
    switch (handle) {
      case _WaveformHandle.start:
        widget.onChanged(snapped.clamp(0, end - 1).toInt(), end);
      case _WaveformHandle.end:
        widget.onChanged(start, snapped.clamp(start + 1, maxFrame).toInt());
    }
  }

  double _frameToX(int frame, double width) {
    return (frame / math.max(1, widget.overview.frameCount)) * width;
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Waveform editor',
      child: SizedBox(
        height: widget.height,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragStart: (details) {
                _beginDrag(details.localPosition, width);
              },
              onHorizontalDragUpdate: (details) {
                _updateDrag(details.localPosition, width);
              },
              child: CustomPaint(
                painter: _PolyWaveformPainter(
                  overview: widget.overview,
                  mode: widget.mode,
                  startFrame: _start,
                  endFrame: _end,
                  colorScheme: Theme.of(context).colorScheme,
                ),
                child: const SizedBox.expand(),
              ),
            );
          },
        ),
      ),
    );
  }
}

enum _WaveformHandle { start, end }

class _PolyWaveformPainter extends CustomPainter {
  const _PolyWaveformPainter({
    required this.overview,
    required this.mode,
    required this.startFrame,
    required this.endFrame,
    required this.colorScheme,
  });

  final WavOverview overview;
  final PolyWaveformEditorMode mode;
  final int startFrame;
  final int endFrame;
  final ColorScheme colorScheme;

  @override
  void paint(Canvas canvas, Size size) {
    final maxFrame = math.max(1, overview.frameCount);
    final startX = (startFrame / maxFrame) * size.width;
    final endX = (endFrame / maxFrame) * size.width;
    final selectedRect = Rect.fromLTRB(startX, 0, endX, size.height);
    switch (mode) {
      case PolyWaveformEditorMode.loop:
        canvas.drawRect(
          selectedRect,
          Paint()..color = colorScheme.tertiary.withValues(alpha: 0.25),
        );
      case PolyWaveformEditorMode.trim:
        final shade = Paint()
          ..color = colorScheme.onSurface.withValues(alpha: 0.25);
        canvas.drawRect(Rect.fromLTRB(0, 0, startX, size.height), shade);
        canvas.drawRect(Rect.fromLTRB(endX, 0, size.width, size.height), shade);
    }

    final waveformPaint = Paint()
      ..color = colorScheme.primary
      ..strokeWidth = 1;
    final centerY = size.height / 2;
    final halfHeight = size.height / 2;
    for (var i = 0; i < overview.peaks.length; i++) {
      final peak = overview.peaks[i];
      final x = overview.peaks.length <= 1
          ? 0.0
          : (i / (overview.peaks.length - 1)) * size.width;
      final y0 = centerY - peak.max.clamp(-1.0, 1.0) * halfHeight;
      final y1 = centerY - peak.min.clamp(-1.0, 1.0) * halfHeight;
      canvas.drawLine(Offset(x, y0), Offset(x, y1), waveformPaint);
    }

    final handlePaint = Paint()
      ..color = colorScheme.tertiary
      ..strokeWidth = 2;
    canvas.drawLine(
      Offset(startX, 0),
      Offset(startX, size.height),
      handlePaint,
    );
    canvas.drawLine(Offset(endX, 0), Offset(endX, size.height), handlePaint);
  }

  @override
  bool shouldRepaint(covariant _PolyWaveformPainter oldDelegate) {
    return oldDelegate.overview != overview ||
        oldDelegate.mode != mode ||
        oldDelegate.startFrame != startFrame ||
        oldDelegate.endFrame != endFrame ||
        oldDelegate.colorScheme != colorScheme;
  }
}
