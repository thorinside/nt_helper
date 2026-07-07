import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:nt_helper/core/routing/bus_color_palette.dart';
import 'package:nt_helper/core/routing/bus_spec.dart';

/// Compact, color-coded bus picker for the Bus Lanes view.
///
/// Replaces the long `showMenu` dropdown with a grouped tile grid. Categories
/// are Inputs, Outputs, Aux, and (optionally) ES-5. Each tile is a 48×34
/// chip painted from [BusColorPalette.baseColor] for that bus.
///
/// Tapping a tile pops the dialog with the selected bus number; tapping
/// outside or pressing Esc dismisses with no selection.
class BusPickerDialog extends StatefulWidget {
  /// Display name of the port being routed (e.g. "Input 1", "Clock Out").
  final String portLabel;

  /// The port's current bus assignment (0 = None). Shown in the footer.
  final int currentBus;

  /// Complete bus list supplied for display.
  ///
  /// The dialog inserts [currentBus] when needed so the current assignment is
  /// visible even if the caller omitted it from this list.
  final List<int> availableBuses;

  /// Whether ES-5 buses are valid targets for this port.
  final bool showEs5;

  /// Label formatter matching the bus-lanes legend (I1, O3, A12, ES1…).
  final String Function(int) busLabel;

  const BusPickerDialog({
    super.key,
    required this.portLabel,
    required this.currentBus,
    required this.availableBuses,
    required this.showEs5,
    required this.busLabel,
  });

  @override
  State<BusPickerDialog> createState() => _BusPickerDialogState();
}

class _BusPickerDialogState extends State<BusPickerDialog> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _currentBusKey = GlobalKey();
  late final List<int> _inputs;
  late final List<int> _outputs;
  late final List<int> _aux;
  late final List<int> _es5;

  @override
  void initState() {
    super.initState();

    final displayBuses = widget.availableBuses.where((b) => b > 0).toSet();
    if (widget.currentBus > 0) displayBuses.add(widget.currentBus);

    final es5Set = widget.showEs5
        ? displayBuses
              .where((b) => BusSpec.isEs5(b) || BusSpec.isEs5Extended(b))
              .toSet()
        : <int>{};

    _inputs = displayBuses.where(BusSpec.isPhysicalInput).toList()..sort();
    _outputs = displayBuses.where(BusSpec.isPhysicalOutput).toList()..sort();
    _es5 = es5Set.toList()..sort();
    _aux =
        displayBuses
            .where((b) => b >= BusSpec.auxMin && !es5Set.contains(b))
            .toList()
          ..sort();

    WidgetsBinding.instance.addPostFrameCallback((_) => _centerCurrentBus());
  }

  void _centerCurrentBus() {
    if (widget.currentBus <= 0) return;
    final currentContext = _currentBusKey.currentContext;
    if (currentContext == null) return;
    Scrollable.ensureVisible(
      currentContext,
      alignment: 0.5,
      duration: Duration.zero,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Semantics(
            namesRoute: true,
            label: 'Bus picker',
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Row(
                    children: [
                      ExcludeSemantics(
                        child: Icon(
                          Icons.route_rounded,
                          size: 20,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Route ${widget.portLabel}',
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: math.min(
                        MediaQuery.sizeOf(context).height * 0.65,
                        420.0,
                      ),
                    ),
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_inputs.isNotEmpty)
                            _section('Inputs', _inputs, theme),
                          if (_outputs.isNotEmpty)
                            _section('Outputs', _outputs, theme),
                          if (_aux.isNotEmpty) _section('Aux', _aux, theme),
                          if (_es5.isNotEmpty) _section('ES-5', _es5, theme),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Currently: ${widget.currentBus == 0 ? "None" : widget.busLabel(widget.currentBus)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _section(String header, List<int> buses, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                header,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              for (final bus in buses)
                _BusTile(
                  key: bus == widget.currentBus ? _currentBusKey : null,
                  bus: bus,
                  label: widget.busLabel(bus),
                  selected: bus == widget.currentBus,
                  onTap: bus == widget.currentBus
                      ? null
                      : () => Navigator.of(context).pop(bus),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BusTile extends StatefulWidget {
  final int bus;
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  const _BusTile({
    super.key,
    required this.bus,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_BusTile> createState() => _BusTileState();
}

class _BusTileState extends State<_BusTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final baseColor = BusColorPalette.baseColor(widget.bus, isDark: isDark);
    final borderColor = widget.selected ? theme.colorScheme.primary : baseColor;
    final borderWidth = widget.selected ? 3.0 : (_hovered ? 2.0 : 1.5);
    final fillAlpha = widget.selected ? 0.45 : (_hovered ? 0.35 : 0.18);
    return Semantics(
      label: widget.selected
          ? 'Current bus ${widget.label}'
          : 'Route to ${widget.label}',
      button: true,
      selected: widget.selected,
      enabled: widget.onTap != null,
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: BorderSide(color: borderColor, width: borderWidth),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: widget.onTap,
          onHover: (h) {
            if (h != _hovered) setState(() => _hovered = h);
          },
          child: Container(
            width: 48,
            height: 34,
            decoration: BoxDecoration(
              color: baseColor.withValues(alpha: fillAlpha),
              borderRadius: BorderRadius.circular(6),
            ),
            alignment: Alignment.center,
            child: Text(
              widget.label,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
        ),
      ),
    );
  }
}
