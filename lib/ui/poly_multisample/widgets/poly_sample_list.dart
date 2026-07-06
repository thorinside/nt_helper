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
  static const _itemExtent = 64.0;
  static const _horizontalPadding = 4.0;
  static const _verticalPadding = 6.0;
  static const _leadingExtent = 32.0;
  static const _previewButtonExtent = 40.0;
  static const _contentGap = 4.0;
  static const _filenameStepperGap = 16.0;
  static const _minFilenameExtent = 220.0;
  static const _minStepperStripExtent = 132.0;
  static const _stepperStripPreferredExtent = 760.0;
  static const _stepperGap = 4.0;

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

  double _stepperStripWidth(double rowWidth) {
    const fixedWidth =
        _leadingExtent +
        _contentGap +
        _filenameStepperGap +
        _contentGap +
        _previewButtonExtent;
    final available = math.max(0.0, rowWidth - fixedWidth);
    final widthAfterPreferredFilename = available - _minFilenameExtent;
    final targetWidth = math.max(
      _minStepperStripExtent,
      widthAfterPreferredFilename,
    );
    return math.min(
      _stepperStripPreferredExtent,
      math.min(available, targetWidth),
    );
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
        final steppers = [
          _InlineSampleStepper(
            stepperKey: ValueKey('poly-sample-stepper-${region.path}-root'),
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
            stepperKey: ValueKey('poly-sample-stepper-${region.path}-low'),
            label: 'Low',
            value: PolyMultisampleParser.midiToNoteName(low),
            sampleLabel: label,
            onDecrease: () =>
                widget.onUpdateRangeLow(region.path, _clampMidi(low - 1)),
            onIncrease: () =>
                widget.onUpdateRangeLow(region.path, _clampMidi(low + 1)),
          ),
          _InlineSampleStepper(
            stepperKey: ValueKey('poly-sample-stepper-${region.path}-high'),
            label: 'High',
            value: PolyMultisampleParser.midiToNoteName(high),
            sampleLabel: label,
            onDecrease: () =>
                widget.onUpdateRangeHigh(region.path, _clampMidi(high - 1)),
            onIncrease: () =>
                widget.onUpdateRangeHigh(region.path, _clampMidi(high + 1)),
          ),
          _InlineSampleStepper(
            stepperKey: ValueKey('poly-sample-stepper-${region.path}-vel'),
            label: 'Vel',
            value: '$velocity',
            sampleLabel: label,
            onDecrease: () =>
                widget.onUpdateVelocity(region.path, math.max(1, velocity - 1)),
            onIncrease: () =>
                widget.onUpdateVelocity(region.path, velocity + 1),
          ),
          _InlineSampleStepper(
            stepperKey: ValueKey('poly-sample-stepper-${region.path}-rr'),
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
        ];
        return Semantics(
          container: true,
          explicitChildNodes: true,
          selected: selected,
          button: true,
          enabled: true,
          label:
              '$label, root $rootLabel, low $lowLabel, high $highLabel, velocity $velocity, RR $roundRobin',
          onTap: () => widget.onSelect(region.path, _selectionMode()),
          child: Material(
            color: selected
                ? Theme.of(
                    context,
                  ).colorScheme.secondaryContainer.withValues(alpha: 0.36)
                : Colors.transparent,
            child: InkWell(
              excludeFromSemantics: true,
              onTap: () => widget.onSelect(region.path, _selectionMode()),
              child: Padding(
                key: ValueKey('poly-sample-row-${region.path}'),
                padding: const EdgeInsets.symmetric(
                  horizontal: _horizontalPadding,
                  vertical: _verticalPadding,
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final stepperStripWidth = _stepperStripWidth(
                      constraints.maxWidth,
                    );

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox.square(
                          dimension: _leadingExtent,
                          child: Center(
                            child: Icon(
                              issues.isEmpty
                                  ? Icons.graphic_eq
                                  : Icons.warning_amber,
                              semanticLabel: issues.isEmpty
                                  ? 'Mapped sample'
                                  : 'Sample warning',
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: _contentGap),
                        Expanded(
                          child: Align(
                            key: ValueKey(
                              'poly-sample-filename-area-${region.path}',
                            ),
                            alignment: Alignment.centerLeft,
                            child: Text(
                              label,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        const SizedBox(width: _filenameStepperGap),
                        SizedBox(
                          key: ValueKey(
                            'poly-sample-stepper-strip-${region.path}',
                          ),
                          width: stepperStripWidth,
                          height: _InlineSampleStepper.height,
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              return SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    minWidth: constraints.maxWidth,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      for (
                                        var stepperIndex = 0;
                                        stepperIndex < steppers.length;
                                        stepperIndex++
                                      ) ...[
                                        if (stepperIndex > 0)
                                          const SizedBox(width: _stepperGap),
                                        steppers[stepperIndex],
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: _contentGap),
                        SizedBox.square(
                          key: ValueKey('poly-sample-preview-${region.path}'),
                          dimension: _previewButtonExtent,
                          child: Center(
                            child: IconButton(
                              tooltip: playing
                                  ? 'Stop preview'
                                  : 'Preview sample',
                              icon: Icon(
                                playing ? Icons.stop : Icons.play_arrow,
                              ),
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints.tightFor(
                                width: _previewButtonExtent,
                                height: _previewButtonExtent,
                              ),
                              onPressed:
                                  region.path.toLowerCase().endsWith('.wav')
                                  ? () => widget.onPreview(region.path)
                                  : null,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _InlineSampleStepper extends StatelessWidget {
  const _InlineSampleStepper({
    required this.stepperKey,
    required this.label,
    required this.value,
    required this.sampleLabel,
    required this.onDecrease,
    required this.onIncrease,
  });

  static const height = 32.0;
  static const _buttonExtent = 32.0;
  static const _iconSize = 18.0;

  final Key? stepperKey;
  final String label;
  final String value;
  final String sampleLabel;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      key: stepperKey,
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
        child: SizedBox(
          height: height,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _button(
                  context,
                  'Decrease $label for $sampleLabel',
                  Icons.remove,
                  onDecrease,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Center(
                    child: Text(
                      '$label $value',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
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
      ),
    );
  }

  Widget _button(
    BuildContext context,
    String tooltip,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return SizedBox.square(
      key: ValueKey('poly-sample-stepper-button-$tooltip'),
      dimension: _buttonExtent,
      child: IconButton(
        tooltip: tooltip,
        icon: Icon(icon, size: _iconSize),
        visualDensity: VisualDensity.compact,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.tightFor(
          width: _buttonExtent,
          height: _buttonExtent,
        ),
        style: IconButton.styleFrom(
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        onPressed: onPressed,
      ),
    );
  }
}

int _clampMidi(int value) => value.clamp(0, 127).toInt();
