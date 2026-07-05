import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nt_helper/poly_multisample/poly_multisample_models.dart';
import 'package:nt_helper/ui/poly_multisample/poly_multisample_builder_cubit.dart';
import 'package:nt_helper/ui/poly_multisample/poly_region_math.dart';

class PolySampleList extends StatefulWidget {
  const PolySampleList({
    super.key,
    required this.regions,
    required this.selectedPaths,
    required this.focusedPath,
    required this.previewVisiblePath,
    required this.onSelect,
    required this.onPreview,
  });

  final List<PolySampleRegion> regions;
  final Set<String> selectedPaths;
  final String? focusedPath;
  final String? previewVisiblePath;
  final void Function(String path, PolyRegionSelectionMode mode) onSelect;
  final ValueChanged<String> onPreview;

  @override
  State<PolySampleList> createState() => _PolySampleListState();
}

class _PolySampleListState extends State<PolySampleList> {
  static const _itemExtent = 56.0;

  final ScrollController _scrollController = ScrollController();
  String? _pendingFocusedPath;

  @override
  void initState() {
    super.initState();
    _pendingFocusedPath = widget.focusedPath;
  }

  @override
  void didUpdateWidget(covariant PolySampleList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusedPath != widget.focusedPath) {
      _pendingFocusedPath = widget.focusedPath;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  PolyRegionSelectionMode _selectionMode() {
    final pressed = HardwareKeyboard.instance.logicalKeysPressed;
    if (pressed.contains(LogicalKeyboardKey.shiftLeft) ||
        pressed.contains(LogicalKeyboardKey.shiftRight)) {
      return PolyRegionSelectionMode.range;
    }
    if (pressed.contains(LogicalKeyboardKey.controlLeft) ||
        pressed.contains(LogicalKeyboardKey.controlRight) ||
        pressed.contains(LogicalKeyboardKey.metaLeft) ||
        pressed.contains(LogicalKeyboardKey.metaRight)) {
      return PolyRegionSelectionMode.toggle;
    }
    return PolyRegionSelectionMode.replace;
  }

  void _scheduleFocusScroll() {
    final focusedPath = _pendingFocusedPath;
    if (focusedPath == null) return;
    _pendingFocusedPath = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final index = widget.regions.indexWhere(
        (region) => region.path == focusedPath,
      );
      if (index < 0) return;
      final itemStart = index * _itemExtent;
      final itemEnd = itemStart + _itemExtent;
      final visibleStart = _scrollController.offset;
      final visibleEnd =
          visibleStart + _scrollController.position.viewportDimension;
      if (itemStart >= visibleStart && itemEnd <= visibleEnd) return;
      final target = itemStart.clamp(
        _scrollController.position.minScrollExtent,
        _scrollController.position.maxScrollExtent,
      );
      _scrollController.jumpTo(target);
    });
  }

  @override
  Widget build(BuildContext context) {
    _scheduleFocusScroll();
    return ListView.builder(
      controller: _scrollController,
      itemExtent: _itemExtent,
      itemCount: widget.regions.length,
      itemBuilder: (context, index) {
        final region = widget.regions[index];
        final label = sampleDisplayLabel(region, widget.regions);
        final selected = widget.selectedPaths.contains(region.path);
        final playing = widget.previewVisiblePath == region.path;
        final issues = region.currentIssues;
        return Semantics(
          selected: selected,
          label: '$label, root ${region.rootName ?? 'unmapped'}',
          child: ListTile(
            dense: true,
            selected: selected,
            leading: Icon(
              issues.isEmpty ? Icons.graphic_eq : Icons.warning_amber,
              semanticLabel: issues.isEmpty
                  ? 'Mapped sample'
                  : 'Sample warning',
            ),
            title: Text(label),
            subtitle: Text(
              [
                'Root ${region.rootName ?? 'unmapped'}',
                if (region.velocityLayer != null) 'V${region.velocityLayer}',
                if (region.roundRobin != null) 'RR${region.roundRobin}',
                if (issues.isNotEmpty)
                  'Issues: ${issues.map((issue) => issue.name).join(', ')}',
              ].join('  '),
            ),
            trailing: IconButton(
              tooltip: playing ? 'Stop preview' : 'Preview sample',
              icon: Icon(playing ? Icons.stop : Icons.play_arrow),
              onPressed: region.path.toLowerCase().endsWith('.wav')
                  ? () => widget.onPreview(region.path)
                  : null,
            ),
            onTap: () => widget.onSelect(region.path, _selectionMode()),
          ),
        );
      },
    );
  }
}
