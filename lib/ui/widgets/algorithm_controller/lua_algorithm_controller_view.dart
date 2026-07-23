import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nt_helper/algorithm_controller/algorithm_controller.dart';
import 'package:nt_helper/algorithm_controller/lua_algorithm_controller_engine.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/domain/parameter_number_lookup.dart';
import 'package:nt_helper/ui/widgets/algorithm_controller/algorithm_controller_section_controller.dart';

typedef AlgorithmControllerSourceLoader = Future<String> Function(String path);

class LuaAlgorithmControllerView extends StatefulWidget {
  const LuaAlgorithmControllerView({
    super.key,
    required this.definition,
    required this.slot,
    required this.slotIndex,
    required this.units,
    required this.sectionController,
    this.engine = const LuaAlgorithmControllerEngine(),
    this.sourceLoader,
    this.onError,
  });

  final AlgorithmControllerDefinition definition;
  final Slot slot;
  final int slotIndex;
  final List<String> units;
  final AlgorithmControllerSectionController sectionController;
  final LuaAlgorithmControllerEngine engine;
  final AlgorithmControllerSourceLoader? sourceLoader;
  final ValueChanged<String>? onError;

  @override
  State<LuaAlgorithmControllerView> createState() =>
      _LuaAlgorithmControllerViewState();
}

class _LuaAlgorithmControllerViewState
    extends State<LuaAlgorithmControllerView> {
  String? _source;
  AlgorithmControllerDocument? _document;
  String? _error;
  String? _lastReportedError;
  bool _loading = true;
  int _loadGeneration = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_loadSource());
  }

  @override
  void didUpdateWidget(covariant LuaAlgorithmControllerView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.definition.assetPath != widget.definition.assetPath ||
        oldWidget.sourceLoader != widget.sourceLoader) {
      _loading = true;
      _document = null;
      _error = null;
      unawaited(_loadSource());
      return;
    }

    if (!identical(oldWidget.slot, widget.slot) ||
        oldWidget.slotIndex != widget.slotIndex ||
        oldWidget.units != widget.units) {
      _evaluateSource();
    }
  }

  Future<void> _loadSource() async {
    final generation = ++_loadGeneration;
    try {
      final loader = widget.sourceLoader ?? rootBundle.loadString;
      final source = await loader(widget.definition.assetPath);
      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        _source = source;
        _loading = false;
        _evaluateSource();
      });
    } catch (error) {
      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        _loading = false;
        _setError('Could not load ${widget.definition.name}: $error');
      });
    }
  }

  void _evaluateSource() {
    final source = _source;
    if (source == null) return;
    try {
      _document = widget.engine.evaluate(
        source: source,
        slot: widget.slot,
        slotIndex: widget.slotIndex,
        units: widget.units,
      );
      _error = null;
      _lastReportedError = null;
    } catch (error) {
      _document = null;
      _setError(error.toString());
    }
  }

  void _setError(String message) {
    _error = message;
    if (_lastReportedError == message) return;
    _lastReportedError = message;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onError?.call(message);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Center(
        child: Semantics(
          liveRegion: true,
          label: 'Loading algorithm controller',
          child: const CircularProgressIndicator(),
        ),
      );
    }

    final error = _error;
    if (error != null) {
      return Center(
        child: Semantics(
          liveRegion: true,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.extension_off_rounded,
                  color: Theme.of(context).colorScheme.error,
                  size: 40,
                ),
                const SizedBox(height: 12),
                Text(
                  error,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final document = _document;
    if (document == null) return const SizedBox.shrink();
    return AlgorithmControllerDocumentView(
      document: document,
      slot: widget.slot,
      slotIndex: widget.slotIndex,
      sectionController: widget.sectionController,
    );
  }
}

class AlgorithmControllerDocumentView extends StatefulWidget {
  const AlgorithmControllerDocumentView({
    super.key,
    required this.document,
    required this.slot,
    required this.slotIndex,
    required this.sectionController,
  });

  final AlgorithmControllerDocument document;
  final Slot slot;
  final int slotIndex;
  final AlgorithmControllerSectionController sectionController;

  @override
  State<AlgorithmControllerDocumentView> createState() =>
      _AlgorithmControllerDocumentViewState();
}

class _AlgorithmControllerDocumentViewState
    extends State<AlgorithmControllerDocumentView> {
  @override
  void initState() {
    super.initState();
    _synchronizeSections();
  }

  @override
  void didUpdateWidget(covariant AlgorithmControllerDocumentView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.document, widget.document) ||
        oldWidget.sectionController != widget.sectionController) {
      _synchronizeSections();
    }
  }

  void _synchronizeSections() {
    final sections = <AlgorithmControllerSectionReference>[];
    _collectSections(widget.document.root, path: 'root', sections: sections);
    widget.sectionController.synchronizeSections(sections);
  }

  void _collectSections(
    AlgorithmControllerNode node, {
    required String path,
    required List<AlgorithmControllerSectionReference> sections,
  }) {
    switch (node) {
      case AlgorithmControllerColumn(:final children):
      case AlgorithmControllerRow(:final children):
        for (var index = 0; index < children.length; index++) {
          _collectSections(
            children[index],
            path: '$path/$index',
            sections: sections,
          );
        }
      case AlgorithmControllerSection(:final title, :final children):
        sections.add((path: path, title: title));
        for (var index = 0; index < children.length; index++) {
          _collectSections(
            children[index],
            path: '$path/$index',
            sections: sections,
          );
        }
      case AlgorithmControllerText():
      case AlgorithmControllerSlider():
      case AlgorithmControllerChoice():
      case AlgorithmControllerToggle():
      case AlgorithmControllerButton():
      case AlgorithmControllerDivider():
      case AlgorithmControllerSpacer():
      case AlgorithmControllerCanvas():
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return _AlgorithmControllerDocumentBody(
      document: widget.document,
      slot: widget.slot,
      slotIndex: widget.slotIndex,
      sectionController: widget.sectionController,
    );
  }
}

class _AlgorithmControllerDocumentBody extends StatelessWidget {
  const _AlgorithmControllerDocumentBody({
    required this.document,
    required this.slot,
    required this.slotIndex,
    required this.sectionController,
  });

  final AlgorithmControllerDocument document;
  final Slot slot;
  final int slotIndex;
  final AlgorithmControllerSectionController sectionController;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Semantics(
              header: true,
              child: Text(
                document.title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
          ),
          _buildNode(context, document.root, path: 'root'),
        ],
      ),
    );
  }

  Widget _buildNode(
    BuildContext context,
    AlgorithmControllerNode node, {
    required String path,
  }) {
    return switch (node) {
      AlgorithmControllerColumn node => Padding(
        padding: EdgeInsets.all(node.padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: _withGaps(
            [
              for (var index = 0; index < node.children.length; index++)
                _buildNode(context, node.children[index], path: '$path/$index'),
            ],
            node.gap,
            Axis.vertical,
          ),
        ),
      ),
      AlgorithmControllerRow node => Wrap(
        spacing: node.gap,
        runSpacing: node.gap,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          for (var index = 0; index < node.children.length; index++)
            _buildNode(context, node.children[index], path: '$path/$index'),
        ],
      ),
      AlgorithmControllerSection node => _buildSection(context, node, path),
      AlgorithmControllerText node => _buildText(context, node),
      AlgorithmControllerSlider node => _buildSlider(context, node),
      AlgorithmControllerChoice node => _buildChoice(context, node),
      AlgorithmControllerToggle node => _buildToggle(context, node),
      AlgorithmControllerButton node => _buildButton(context, node),
      AlgorithmControllerDivider() => const Divider(),
      AlgorithmControllerSpacer node => SizedBox(height: node.size),
      AlgorithmControllerCanvas node => _buildCanvas(context, node),
    };
  }

  Widget _buildSection(
    BuildContext context,
    AlgorithmControllerSection node,
    String path,
  ) {
    final expansionController = sectionController.controllerFor(path);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        key: ValueKey('algorithm-controller-section:$path'),
        controller: expansionController,
        initiallyExpanded: expansionController.isExpanded,
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        shape: const RoundedRectangleBorder(side: BorderSide.none),
        collapsedShape: const RoundedRectangleBorder(side: BorderSide.none),
        title: Semantics(
          header: true,
          child: Text(
            node.title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        subtitle: switch (node.subtitle) {
          final subtitle? => Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          null => null,
        },
        children: _withGaps(
          [
            for (var index = 0; index < node.children.length; index++)
              _buildNode(context, node.children[index], path: '$path/$index'),
          ],
          10,
          Axis.vertical,
        ),
      ),
    );
  }

  Widget _buildText(BuildContext context, AlgorithmControllerText node) {
    final theme = Theme.of(context).textTheme;
    final style = switch (node.style) {
      'title' => theme.titleLarge,
      'subtitle' => theme.titleMedium,
      'caption' => theme.bodySmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      _ => theme.bodyMedium,
    };
    final align = switch (node.align) {
      'center' => TextAlign.center,
      'end' => TextAlign.end,
      _ => TextAlign.start,
    };
    return Text(node.text, style: style, textAlign: align);
  }

  Widget _buildSlider(BuildContext context, AlgorithmControllerSlider node) {
    final binding = _binding(node.parameterNumber);
    if (binding == null) {
      return _missingParameter(context, node.label, node.parameterNumber);
    }

    final minimum = (node.minimum ?? binding.minimum).clamp(
      binding.minimum,
      binding.maximum,
    );
    final maximum = (node.maximum ?? binding.maximum).clamp(
      binding.minimum,
      binding.maximum,
    );
    final validRange = minimum < maximum;
    final value = validRange ? binding.value.clamp(minimum, maximum) : minimum;
    final enabled = node.enabled && !binding.disabled && validRange;
    final divisions = validRange && maximum - minimum <= 256
        ? maximum - minimum
        : null;
    final displayValue = _formattedValue(binding, value);

    return MergeSemantics(
      child: Row(
        children: [
          SizedBox(
            width: 88,
            child: Text(
              node.label,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          Expanded(
            child: Slider(
              value: value.toDouble(),
              min: minimum.toDouble(),
              max: validRange ? maximum.toDouble() : minimum.toDouble() + 1,
              divisions: divisions,
              label: displayValue,
              semanticFormatterCallback: (newValue) =>
                  '${node.label} '
                  '${_formattedValue(binding, newValue.round())}',
              onChanged: enabled
                  ? (newValue) => _writeParameter(
                      context,
                      node.parameterNumber,
                      newValue.round(),
                      changing: true,
                    )
                  : null,
              onChangeEnd: enabled
                  ? (newValue) => _writeParameter(
                      context,
                      node.parameterNumber,
                      newValue.round(),
                      changing: false,
                    )
                  : null,
            ),
          ),
          SizedBox(
            width: 96,
            child: Text(
              displayValue,
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChoice(BuildContext context, AlgorithmControllerChoice node) {
    final binding = _binding(node.parameterNumber);
    if (binding == null) {
      return _missingParameter(context, node.label, node.parameterNumber);
    }
    final enumValues = binding.enumValues;
    final complete =
        binding.minimum >= 0 &&
        binding.maximum < enumValues.length &&
        [
          for (var value = binding.minimum; value <= binding.maximum; value++)
            enumValues[value],
        ].every((label) => label.isNotEmpty);
    if (!complete) {
      return _buildSlider(
        context,
        AlgorithmControllerSlider(
          label: node.label,
          parameterNumber: node.parameterNumber,
          enabled: node.enabled,
        ),
      );
    }

    final enabled = node.enabled && !binding.disabled;
    return Semantics(
      container: true,
      label: '${node.label} choices',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(node.label, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (
                var value = binding.minimum;
                value <= binding.maximum;
                value++
              )
                Semantics(
                  button: true,
                  selected: binding.value == value,
                  label: '${node.label}: ${enumValues[value]}',
                  child: ExcludeSemantics(
                    child: ChoiceChip(
                      label: Text(enumValues[value]),
                      selected: binding.value == value,
                      onSelected: enabled
                          ? (selected) {
                              if (!selected || binding.value == value) return;
                              _writeParameter(
                                context,
                                node.parameterNumber,
                                value,
                                changing: false,
                              );
                              SemanticsService.sendAnnouncement(
                                View.of(context),
                                '${node.label} ${enumValues[value]} selected',
                                Directionality.of(context),
                              );
                            }
                          : null,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToggle(BuildContext context, AlgorithmControllerToggle node) {
    final binding = _binding(node.parameterNumber);
    if (binding == null) {
      return _missingParameter(context, node.label, node.parameterNumber);
    }
    final enabled = node.enabled && !binding.disabled;
    return SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      title: Text(node.label),
      value: binding.value == node.onValue,
      onChanged: enabled
          ? (selected) => _writeParameter(
              context,
              node.parameterNumber,
              selected ? node.onValue : node.offValue,
              changing: false,
            )
          : null,
    );
  }

  Widget _buildButton(BuildContext context, AlgorithmControllerButton node) {
    final binding = _binding(node.action.parameterNumber);
    final enabled = node.enabled && binding != null && !binding.disabled;
    final onPressed = enabled
        ? () => _performAction(context, node.action)
        : null;
    return switch (node.style) {
      'text' => TextButton(onPressed: onPressed, child: Text(node.label)),
      'outlined' => OutlinedButton(
        onPressed: onPressed,
        child: Text(node.label),
      ),
      _ => FilledButton(onPressed: onPressed, child: Text(node.label)),
    };
  }

  Widget _buildCanvas(BuildContext context, AlgorithmControllerCanvas node) {
    final colorScheme = Theme.of(context).colorScheme;
    return Semantics(
      image: true,
      label: node.semanticsLabel,
      child: ExcludeSemantics(
        child: AspectRatio(
          aspectRatio: node.aspectRatio.clamp(0.25, 20),
          child: CustomPaint(
            painter: _AlgorithmControllerCanvasPainter(
              shapes: node.shapes,
              colorScheme: colorScheme,
            ),
          ),
        ),
      ),
    );
  }

  Widget _missingParameter(BuildContext context, String label, int number) {
    return Text(
      '$label is unavailable (parameter $number)',
      style: TextStyle(color: Theme.of(context).colorScheme.error),
    );
  }

  ({
    int minimum,
    int maximum,
    int value,
    bool disabled,
    List<String> enumValues,
    String displayValue,
  })?
  _binding(int parameterNumber) {
    final info = slot.parameters.byParameterNumber(parameterNumber);
    if (info == null) return null;
    final value = slot.values.byParameterNumber(parameterNumber);
    final enums = slot.enums.byParameterNumber(parameterNumber);
    final valueString = slot.valueStrings.byParameterNumber(parameterNumber);
    return (
      minimum: info.min,
      maximum: info.max,
      value: value?.value ?? info.defaultValue,
      disabled: value?.isDisabled ?? false,
      enumValues: [
        for (final enumValue in enums?.values ?? const <String>[])
          enumValue.trim(),
      ],
      displayValue: valueString?.value.trim() ?? '',
    );
  }

  String _formattedValue(
    ({
      int minimum,
      int maximum,
      int value,
      bool disabled,
      List<String> enumValues,
      String displayValue,
    })
    binding,
    int value,
  ) {
    if (value == binding.value && binding.displayValue.isNotEmpty) {
      return binding.displayValue;
    }
    if (value >= 0 &&
        value < binding.enumValues.length &&
        binding.enumValues[value].isNotEmpty) {
      return binding.enumValues[value];
    }
    return value.toString();
  }

  void _performAction(BuildContext context, AlgorithmControllerAction action) {
    final binding = _binding(action.parameterNumber);
    if (binding == null) return;
    final value = switch (action.type) {
      AlgorithmControllerActionType.setParameter => action.value!,
      AlgorithmControllerActionType.adjustParameter =>
        binding.value + action.delta!,
    };
    _writeParameter(
      context,
      action.parameterNumber,
      value.clamp(binding.minimum, binding.maximum),
      changing: false,
    );
  }

  void _writeParameter(
    BuildContext context,
    int parameterNumber,
    int value, {
    required bool changing,
  }) {
    final binding = _binding(parameterNumber);
    if (binding == null) return;
    unawaited(
      context.read<DistingCubit>().updateParameterValue(
        algorithmIndex: slotIndex,
        parameterNumber: parameterNumber,
        value: value.clamp(binding.minimum, binding.maximum),
        userIsChangingTheValue: changing,
      ),
    );
  }

  List<Widget> _withGaps(List<Widget> children, double gap, Axis axis) {
    if (children.length < 2 || gap <= 0) return children;
    final result = <Widget>[];
    for (var index = 0; index < children.length; index++) {
      if (index > 0) {
        result.add(
          axis == Axis.vertical ? SizedBox(height: gap) : SizedBox(width: gap),
        );
      }
      result.add(children[index]);
    }
    return result;
  }
}

final class _AlgorithmControllerCanvasPainter extends CustomPainter {
  const _AlgorithmControllerCanvasPainter({
    required this.shapes,
    required this.colorScheme,
  });

  final List<AlgorithmControllerCanvasShape> shapes;
  final ColorScheme colorScheme;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Offset.zero & size);
    final scale = math.min(size.width, size.height);
    for (final shape in shapes) {
      switch (shape) {
        case AlgorithmControllerCircle shape:
          final center = Offset(shape.x * size.width, shape.y * size.height);
          final radius = shape.radius * scale;
          _paintFillAndStroke(
            canvas,
            Path()..addOval(Rect.fromCircle(center: center, radius: radius)),
            fill: shape.fill,
            stroke: shape.stroke,
            strokeWidth: shape.strokeWidth,
          );
        case AlgorithmControllerLine shape:
          canvas.drawLine(
            Offset(shape.x1 * size.width, shape.y1 * size.height),
            Offset(shape.x2 * size.width, shape.y2 * size.height),
            Paint()
              ..color = _color(shape.stroke)
              ..style = PaintingStyle.stroke
              ..strokeCap = StrokeCap.round
              ..strokeWidth = shape.strokeWidth,
          );
        case AlgorithmControllerRectangle shape:
          final rect = Rect.fromLTWH(
            shape.x * size.width,
            shape.y * size.height,
            shape.width * size.width,
            shape.height * size.height,
          );
          _paintFillAndStroke(
            canvas,
            Path()..addRRect(
              RRect.fromRectAndRadius(
                rect,
                Radius.circular(shape.radius * scale),
              ),
            ),
            fill: shape.fill,
            stroke: shape.stroke,
            strokeWidth: shape.strokeWidth,
          );
      }
    }
  }

  void _paintFillAndStroke(
    Canvas canvas,
    Path path, {
    required String? fill,
    required String? stroke,
    required double strokeWidth,
  }) {
    if (fill != null) {
      canvas.drawPath(
        path,
        Paint()
          ..color = _color(fill)
          ..style = PaintingStyle.fill,
      );
    }
    if (stroke != null && strokeWidth > 0) {
      canvas.drawPath(
        path,
        Paint()
          ..color = _color(stroke)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth,
      );
    }
  }

  Color _color(String token) {
    return switch (token) {
      'primary' => colorScheme.primary,
      'on_primary' => colorScheme.onPrimary,
      'secondary' => colorScheme.secondary,
      'tertiary' => colorScheme.tertiary,
      'surface' => colorScheme.surface,
      'surface_container' => colorScheme.surfaceContainer,
      'surface_container_highest' => colorScheme.surfaceContainerHighest,
      'on_surface' => colorScheme.onSurface,
      'on_surface_variant' => colorScheme.onSurfaceVariant,
      'outline' => colorScheme.outline,
      'error' => colorScheme.error,
      'transparent' => Colors.transparent,
      _ => _hexColor(token) ?? colorScheme.outline,
    };
  }

  Color? _hexColor(String value) {
    final hex = value.startsWith('#') ? value.substring(1) : value;
    if (hex.length != 6 && hex.length != 8) return null;
    final parsed = int.tryParse(hex, radix: 16);
    if (parsed == null) return null;
    return Color(hex.length == 6 ? 0xff000000 | parsed : parsed);
  }

  @override
  bool shouldRepaint(covariant _AlgorithmControllerCanvasPainter oldDelegate) {
    return oldDelegate.shapes != shapes ||
        oldDelegate.colorScheme != colorScheme;
  }
}
