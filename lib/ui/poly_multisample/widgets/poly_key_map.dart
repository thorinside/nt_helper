import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:nt_helper/poly_multisample/poly_multisample_models.dart';
import 'package:nt_helper/poly_multisample/poly_multisample_parser.dart';
import 'package:nt_helper/ui/poly_multisample/poly_region_math.dart';

class PolyKeyMap extends StatefulWidget {
  const PolyKeyMap({
    super.key,
    required this.regions,
    required this.selectedPath,
    required this.onSelect,
    this.height = 180,
  });

  final List<PolySampleRegion> regions;
  final String? selectedPath;
  final ValueChanged<PolySampleRegion> onSelect;
  final double height;

  @override
  State<PolyKeyMap> createState() => _PolyKeyMapState();
}

class _PolyKeyMapState extends State<PolyKeyMap> {
  final ScrollController _scrollController = ScrollController();
  String? _pendingAutoScrollPath;

  @override
  void initState() {
    super.initState();
    _pendingAutoScrollPath = widget.selectedPath;
  }

  @override
  void didUpdateWidget(covariant PolyKeyMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedPath != widget.selectedPath) {
      _pendingAutoScrollPath = widget.selectedPath;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollHorizontally(PointerSignalEvent event) {
    if (event is! PointerScrollEvent || !_scrollController.hasClients) {
      return;
    }
    final delta = event.scrollDelta.dx.abs() > event.scrollDelta.dy.abs()
        ? event.scrollDelta.dx
        : event.scrollDelta.dy;
    final next = (_scrollController.offset + delta).clamp(
      _scrollController.position.minScrollExtent,
      _scrollController.position.maxScrollExtent,
    );
    _scrollController.jumpTo(next);
  }

  void _scheduleSelectedScroll(Size canvasSize, int minMidi, int maxMidi) {
    final selectedPath = _pendingAutoScrollPath;
    if (selectedPath == null) return;
    _pendingAutoScrollPath = null;
    final selected = widget.regions
        .where(
          (region) => region.path == selectedPath && region.rootMidi != null,
        )
        .firstOrNull;
    if (selected == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final layout = _PolyKeyMapLayout(
        canvasSize,
        velocityLanes(widget.regions),
      );
      final span = math.max(1, maxMidi - minMidi + 1);
      final rootX =
          layout.left + ((selected.rootMidi! - minMidi) / span) * layout.width;
      final viewportWidth = _scrollController.position.viewportDimension;
      final current = _scrollController.offset;
      if (rootX >= current && rootX <= current + viewportWidth) return;
      final target = (rootX - viewportWidth / 2).clamp(
        _scrollController.position.minScrollExtent,
        _scrollController.position.maxScrollExtent,
      );
      _scrollController.jumpTo(target);
    });
  }

  @override
  Widget build(BuildContext context) {
    final mappedCount = widget.regions
        .where((region) => region.rootMidi != null)
        .length;
    final extents = midiExtents(widget.regions);
    final minMidi = extents == null ? 24 : math.max(0, extents.$1 - 6);
    final maxMidi = extents == null ? 96 : math.min(127, extents.$2 + 6);
    return Semantics(
      container: true,
      label: 'Keyboard map with $mappedCount mapped samples',
      child: SizedBox(
        height: widget.height,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final canvasWidth = math.max(
              constraints.maxWidth,
              (maxMidi - minMidi) * 14.0 + 80,
            );
            final canvasSize = Size(canvasWidth, constraints.maxHeight);
            _scheduleSelectedScroll(canvasSize, minMidi, maxMidi);
            return Listener(
              onPointerSignal: _scrollHorizontally,
              child: SingleChildScrollView(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: canvasWidth,
                  height: canvasSize.height,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapUp: (details) {
                      final region = _regionAtPosition(
                        details.localPosition,
                        canvasSize,
                        widget.regions,
                        minMidi,
                        maxMidi,
                      );
                      if (region != null) widget.onSelect(region);
                    },
                    child: CustomPaint(
                      painter: _PolyKeyMapPainter(
                        regions: widget.regions,
                        selectedPath: widget.selectedPath,
                        minMidi: minMidi,
                        maxMidi: maxMidi,
                        colorScheme: Theme.of(context).colorScheme,
                      ),
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

PolySampleRegion? _regionAtPosition(
  Offset position,
  Size size,
  List<PolySampleRegion> regions,
  int minMidi,
  int maxMidi,
) {
  final layout = _PolyKeyMapLayout(size, velocityLanes(regions));
  if (!layout.zoneRect.contains(position)) return null;
  final span = math.max(1, maxMidi - minMidi + 1);
  final midi = (minMidi + ((position.dx - layout.left) / layout.width) * span)
      .floor()
      .clamp(minMidi, maxMidi);
  final laneIndex = ((position.dy - layout.zoneTop) / layout.laneHeight)
      .floor()
      .clamp(0, layout.lanes.length - 1);
  final velocity = layout.lanes[laneIndex];
  final matches = regions.where((region) {
    if (region.rootMidi == null) return false;
    return (region.velocityLayer ?? 1) == velocity &&
        midi >= effectiveLow(region) &&
        midi <= effectiveHigh(region, regions);
  }).toList();
  if (matches.isEmpty) return null;
  matches.sort((a, b) {
    final rootCompare = (a.rootMidi ?? 0).compareTo(b.rootMidi ?? 0);
    if (rootCompare != 0) return rootCompare;
    return (a.roundRobin ?? 1).compareTo(b.roundRobin ?? 1);
  });
  return matches.first;
}

class _PolyKeyMapLayout {
  _PolyKeyMapLayout(Size size, this.lanes)
    : left = lanes.length > 1 ? 52 : 16,
      right = size.width - 16,
      zoneTop = 24,
      keyboardTop = size.height - 42,
      keyboardBottom = size.height - 8 {
    width = math.max(1, right - left);
    zoneBottom = keyboardTop - 8;
    laneHeight = math.max(1, (zoneBottom - zoneTop) / lanes.length);
    zoneRect = Rect.fromLTRB(left, zoneTop, right, zoneBottom);
  }

  final List<int> lanes;
  final double left;
  final double right;
  final double zoneTop;
  final double keyboardTop;
  final double keyboardBottom;
  late final double width;
  late final double zoneBottom;
  late final double laneHeight;
  late final Rect zoneRect;
}

class _PolyKeyMapPainter extends CustomPainter {
  _PolyKeyMapPainter({
    required this.regions,
    required this.selectedPath,
    required this.minMidi,
    required this.maxMidi,
    required this.colorScheme,
  });

  final List<PolySampleRegion> regions;
  final String? selectedPath;
  final int minMidi;
  final int maxMidi;
  final ColorScheme colorScheme;

  @override
  void paint(Canvas canvas, Size size) {
    final lanes = velocityLanes(regions);
    final layout = _PolyKeyMapLayout(size, lanes);
    final span = math.max(1, maxMidi - minMidi + 1);
    final gridPaint = Paint()
      ..color = colorScheme.outlineVariant.withValues(alpha: 0.45)
      ..strokeWidth = 1;
    final fillPaint = Paint()
      ..color = colorScheme.surfaceContainerHighest.withValues(alpha: 0.28);

    final title = TextPainter(
      text: TextSpan(
        text: 'Keyboard',
        style: TextStyle(
          color: colorScheme.onSurfaceVariant,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    title.paint(canvas, const Offset(14, 6));

    for (var i = 0; i < lanes.length; i++) {
      final top = layout.zoneTop + i * layout.laneHeight;
      final bottom = top + layout.laneHeight;
      if (i.isOdd) {
        canvas.drawRect(Rect.fromLTRB(0, top, size.width, bottom), fillPaint);
      }
      if (lanes.length > 1) {
        final laneLabel = TextPainter(
          text: TextSpan(
            text: 'V${lanes[i]}',
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        laneLabel.paint(
          canvas,
          Offset(14, top + (layout.laneHeight - laneLabel.height) / 2),
        );
      }
      canvas.drawLine(
        Offset(layout.left, bottom),
        Offset(layout.right, bottom),
        gridPaint,
      );
    }

    for (var midi = minMidi; midi <= maxMidi; midi++) {
      final x = layout.left + ((midi - minMidi) / span) * layout.width;
      if (midi % 12 == 0) {
        canvas.drawLine(
          Offset(x, layout.zoneTop),
          Offset(x, layout.keyboardBottom),
          gridPaint,
        );
      }
    }

    for (final region in regions.where((region) => region.rootMidi != null)) {
      final laneIndex = lanes.indexOf(region.velocityLayer ?? 1);
      final lane = laneIndex < 0 ? 0 : laneIndex;
      final x0 =
          layout.left +
          ((effectiveLow(region) - minMidi) / span) * layout.width;
      final x1 =
          layout.left +
          ((effectiveHigh(region, regions) + 1 - minMidi) / span) *
              layout.width;
      final y0 = layout.zoneTop + lane * layout.laneHeight;
      final rect = Rect.fromLTRB(
        x0 + 1,
        y0 + 2,
        x1 - 1,
        y0 + layout.laneHeight - 2,
      );
      final selected = region.path == selectedPath;
      canvas.drawRect(
        rect,
        Paint()
          ..color = selected
              ? colorScheme.tertiary.withValues(alpha: 0.70)
              : colorScheme.primary.withValues(alpha: 0.36),
      );
      if (selected) {
        canvas.drawRect(
          rect.deflate(1),
          Paint()
            ..color = colorScheme.onSurface
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      }
      if (rect.width > 26) {
        final label =
            region.rootName ??
            PolyMultisampleParser.midiToNoteName(region.rootMidi!);
        final text = TextPainter(
          text: TextSpan(
            text: label,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 10,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          maxLines: 1,
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: rect.width - 6);
        text.paint(
          canvas,
          Offset(rect.left + 3, rect.center.dy - text.height / 2),
        );
      }
    }

    final keyboardRect = Rect.fromLTRB(
      layout.left,
      layout.keyboardTop,
      layout.right,
      layout.keyboardBottom,
    );
    canvas.drawRect(
      keyboardRect,
      Paint()..color = colorScheme.surfaceContainerHighest,
    );
    for (var midi = minMidi; midi <= maxMidi; midi++) {
      final x0 = layout.left + ((midi - minMidi) / span) * layout.width;
      final x1 = layout.left + ((midi + 1 - minMidi) / span) * layout.width;
      final note = midi % 12;
      final black =
          note == 1 || note == 3 || note == 6 || note == 8 || note == 10;
      if (black) {
        canvas.drawRect(
          Rect.fromLTRB(
            x0 + (x1 - x0) * 0.18,
            layout.keyboardTop,
            x1 - (x1 - x0) * 0.18,
            layout.keyboardTop +
                (layout.keyboardBottom - layout.keyboardTop) * 0.62,
          ),
          Paint()..color = colorScheme.onSurface,
        );
      } else {
        canvas.drawRect(
          Rect.fromLTRB(x0, layout.keyboardTop, x1, layout.keyboardBottom),
          Paint()
            ..color = colorScheme.surface
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.8,
        );
      }
      if (midi % 12 == 0) {
        final octave = TextPainter(
          text: TextSpan(
            text: PolyMultisampleParser.midiToNoteName(midi),
            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 10),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        octave.paint(canvas, Offset(x0 + 3, layout.keyboardBottom - 15));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PolyKeyMapPainter oldDelegate) {
    return oldDelegate.regions != regions ||
        oldDelegate.selectedPath != selectedPath ||
        oldDelegate.minMidi != minMidi ||
        oldDelegate.maxMidi != maxMidi ||
        oldDelegate.colorScheme != colorScheme;
  }
}
