import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nt_helper/poly_multisample/poly_multisample_models.dart';
import 'package:nt_helper/poly_multisample/poly_multisample_parser.dart';
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
    required this.onUpdateRoot,
    required this.onUpdateRangeLow,
    required this.onUpdateRangeHigh,
    required this.onUpdateVelocity,
    required this.onUpdateRoundRobin,
  });

  final List<PolySampleRegion> regions;
  final Set<String> selectedPaths;
  final String? focusedPath;
  final String? previewVisiblePath;
  final void Function(String path, PolyRegionSelectionMode mode) onSelect;
  final ValueChanged<String> onPreview;
  final void Function(String path, int midi) onUpdateRoot;
  final void Function(String path, int midi) onUpdateRangeLow;
  final void Function(String path, int midi) onUpdateRangeHigh;
  final void Function(String path, int layer) onUpdateVelocity;
  final void Function(String path, int lane) onUpdateRoundRobin;

  @override
  State<PolySampleList> createState() => _PolySampleListState();
}

class _PolySampleListState extends State<PolySampleList> {
  static const _itemExtent = 84.0;

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
        final root = region.rootMidi ?? 60;
        final low = effectiveLow(region);
        final high = effectiveHigh(region, widget.regions);
        final velocity = region.velocityLayer ?? 1;
        final roundRobin = region.roundRobin ?? 1;
        final rootLabel = region.rootName ?? 'unmapped';
        final lowLabel = PolyMultisampleParser.midiToNoteName(low);
        final highLabel = PolyMultisampleParser.midiToNoteName(high);
        return Semantics(
          selected: selected,
          label:
              '$label, root $rootLabel, low $lowLabel, high $highLabel, velocity $velocity, RR $roundRobin',
          child: ListTile(
            dense: true,
            selected: selected,
            leading: Icon(
              issues.isEmpty ? Icons.graphic_eq : Icons.warning_amber,
              semanticLabel: issues.isEmpty
                  ? 'Mapped sample'
                  : 'Sample warning',
              size: 20,
            ),
            title: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                _InlineSampleStepper(
                  label: 'Root',
                  value: region.rootMidi == null
                      ? 'Unset'
                      : PolyMultisampleParser.midiToNoteName(root),
                  sampleLabel: label,
                  onDecrease: () =>
                      widget.onUpdateRoot(region.path, _clampMidi(root - 1)),
                  onIncrease: () =>
                      widget.onUpdateRoot(region.path, _clampMidi(root + 1)),
                ),
                _InlineSampleStepper(
                  label: 'Low',
                  value: PolyMultisampleParser.midiToNoteName(low),
                  sampleLabel: label,
                  onDecrease: () =>
                      widget.onUpdateRangeLow(region.path, _clampMidi(low - 1)),
                  onIncrease: () =>
                      widget.onUpdateRangeLow(region.path, _clampMidi(low + 1)),
                ),
                _InlineSampleStepper(
                  label: 'High',
                  value: PolyMultisampleParser.midiToNoteName(high),
                  sampleLabel: label,
                  onDecrease: () => widget.onUpdateRangeHigh(
                    region.path,
                    _clampMidi(high - 1),
                  ),
                  onIncrease: () => widget.onUpdateRangeHigh(
                    region.path,
                    _clampMidi(high + 1),
                  ),
                ),
                _InlineSampleStepper(
                  label: 'Vel',
                  value: '$velocity',
                  sampleLabel: label,
                  onDecrease: () => widget.onUpdateVelocity(
                    region.path,
                    math.max(1, velocity - 1),
                  ),
                  onIncrease: () =>
                      widget.onUpdateVelocity(region.path, velocity + 1),
                ),
                _InlineSampleStepper(
                  label: 'RR',
                  value: '$roundRobin',
                  sampleLabel: label,
                  onDecrease: () => widget.onUpdateRoundRobin(
                    region.path,
                    math.max(1, roundRobin - 1),
                  ),
                  onIncrease: () =>
                      widget.onUpdateRoundRobin(region.path, roundRobin + 1),
                ),
              ],
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

class _InlineSampleStepper extends StatelessWidget {
  const _InlineSampleStepper({
    required this.label,
    required this.value,
    required this.sampleLabel,
    required this.onDecrease,
    required this.onIncrease,
  });

  final String label;
  final String value;
  final String sampleLabel;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: '$label $value for $sampleLabel',
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          borderRadius: BorderRadius.circular(999),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _button(
                context,
                'Decrease $label for $sampleLabel',
                Icons.remove,
                onDecrease,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  '$label $value',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
              _button(
                context,
                'Increase $label for $sampleLabel',
                Icons.add,
                onIncrease,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _button(
    BuildContext context,
    String tooltip,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return IconButton(
      tooltip: tooltip,
      icon: Icon(icon, size: 14),
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 24, height: 24),
      style: IconButton.styleFrom(
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      onPressed: onPressed,
    );
  }
}

int _clampMidi(int value) => value.clamp(0, 127).toInt();
