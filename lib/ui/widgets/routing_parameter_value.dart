import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import 'package:nt_helper/core/routing/bus_color_palette.dart';
import 'package:nt_helper/core/routing/bus_spec.dart';
import 'package:nt_helper/ui/widgets/routing/bus_label_formatter.dart';
import 'package:nt_helper/ui/widgets/routing/bus_picker_dialog.dart';

/// Value editor for I/O (routing) parameters.
///
/// I/O parameters carry a bus number as their value. Instead of the long
/// flat [DropdownMenu] used for ordinary enums, this control renders a
/// color-coded chip showing the current bus label and opens the same
/// [BusPickerDialog] used by the Bus Lanes canvas, so users can find and
/// select inputs/outputs/aux/ES-5 buses with the grouped, centered picker.
class RoutingParameterValue extends StatelessWidget {
  /// Display name of the parameter (e.g. "Output 1").
  final String portLabel;

  /// Current bus value of the parameter (0 = None/Off).
  final int currentBus;

  /// Smallest raw value accepted by the backing parameter.
  final int parameterMin;

  /// Largest raw value accepted by the backing parameter.
  final int parameterMax;

  /// Whether ES-5 expansion buses are valid targets (USB Audio "from Host").
  final bool showEs5;

  /// Whether the device firmware exposes the extended aux/ES-5 bus range.
  final bool hasExtendedAuxBuses;

  /// Whether the parameter permits bus 0 (None/Off) as a valid value.
  ///
  /// Some I/O parameters have a non-zero minimum (e.g. an input that must be
  /// assigned) and therefore cannot be fully disconnected. When this is `true`,
  /// a small "disconnect" (x) affordance is shown next to the chip and a "None"
  /// tile is offered in the bus picker.
  final bool canDisconnect;

  /// Whether the control is interactive.
  final bool enabled;

  /// Called with the newly selected bus number.
  final ValueChanged<int> onValueChanged;

  const RoutingParameterValue({
    super.key,
    required this.portLabel,
    required this.currentBus,
    this.parameterMin = BusSpec.min,
    this.parameterMax = BusSpec.max,
    required this.showEs5,
    required this.hasExtendedAuxBuses,
    this.canDisconnect = false,
    this.enabled = true,
    required this.onValueChanged,
  });

  String _busLabel(int bus) {
    if (bus <= 0) return 'None';
    return BusLabelFormatter.formatBusValue(
      bus,
      hasExtendedAuxBuses: hasExtendedAuxBuses,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final label = _busLabel(currentBus);

    final Color borderColor;
    final Color fillColor;
    final Color foreground;
    if (currentBus > 0) {
      final base = BusColorPalette.baseColor(currentBus, isDark: isDark);
      borderColor = base;
      fillColor = base.withValues(alpha: isDark ? 0.42 : 0.22);
      foreground = isDark
          ? const Color(0xFFFFFFFF)
          : theme.colorScheme.onSurface;
    } else {
      borderColor = theme.colorScheme.outline;
      fillColor = theme.colorScheme.surfaceContainerHighest;
      foreground = theme.colorScheme.onSurface;
    }

    final textStyle = (theme.textTheme.labelLarge ?? const TextStyle())
        .copyWith(fontWeight: FontWeight.w700, color: foreground);

    final showDisconnect = canDisconnect && currentBus > 0 && enabled;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          label: '$portLabel: $label',
          button: true,
          enabled: enabled,
          child: ExcludeSemantics(
            child: Opacity(
              opacity: enabled ? 1.0 : 0.5,
              child: IgnorePointer(
                ignoring: !enabled,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _openPicker(context),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: fillColor,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: borderColor, width: 1.5),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.route_rounded,
                            size: 16,
                            color: foreground,
                            semanticLabel: '',
                          ),
                          const SizedBox(width: 6),
                          Text(label, style: textStyle),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (showDisconnect) ...[
          const SizedBox(width: 4),
          Semantics(
            label: 'Disconnect $portLabel',
            button: true,
            child: ExcludeSemantics(
              child: _DisconnectButton(
                onPressed: () {
                  onValueChanged(0);
                  SemanticsService.sendAnnouncement(
                    View.of(context),
                    '$portLabel: None',
                    TextDirection.ltr,
                  );
                },
              ),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _openPicker(BuildContext context) async {
    final buses = _availableBuses();
    if (buses.isEmpty) return;

    final choice = await showDialog<int>(
      context: context,
      builder: (ctx) => BusPickerDialog(
        portLabel: portLabel,
        currentBus: currentBus,
        availableBuses: buses,
        showEs5: showEs5,
        canDisconnect: canDisconnect,
        busLabel: _busLabel,
      ),
    );
    if (choice == null) return;
    if (choice == currentBus) return;
    onValueChanged(choice);

    if (context.mounted) {
      SemanticsService.sendAnnouncement(
        View.of(context),
        '$portLabel: ${_busLabel(choice)}',
        TextDirection.ltr,
      );
    }
  }

  List<int> _availableBuses() {
    final low = parameterMin <= parameterMax ? parameterMin : parameterMax;
    final high = parameterMin <= parameterMax ? parameterMax : parameterMin;
    final auxMax = hasExtendedAuxBuses
        ? BusSpec.auxMaxExtended
        : BusSpec.auxMax;
    final es5Min = hasExtendedAuxBuses
        ? BusSpec.es5MinExtended
        : BusSpec.es5Min;
    final es5Max = hasExtendedAuxBuses
        ? BusSpec.es5MaxExtended
        : BusSpec.es5Max;

    final buses = <int>[];
    void addRange(int from, int to) {
      final start = from.clamp(low, high).toInt();
      final end = to.clamp(low, high).toInt();
      if (start > end) return;
      for (var b = start; b <= end; b++) {
        buses.add(b);
      }
    }

    addRange(BusSpec.inputMin, BusSpec.inputMax);
    addRange(BusSpec.outputMin, BusSpec.outputMax);
    addRange(BusSpec.auxMin, auxMax);
    if (showEs5) addRange(es5Min, es5Max);
    return buses;
  }
}

/// Small "disconnect" (x) affordance shown beside an I/O parameter chip when
/// the parameter permits bus 0 (None).
class _DisconnectButton extends StatefulWidget {
  final VoidCallback onPressed;
  const _DisconnectButton({required this.onPressed});

  @override
  State<_DisconnectButton> createState() => _DisconnectButtonState();
}

class _DisconnectButtonState extends State<_DisconnectButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.onSurfaceVariant;
    return Material(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: BorderSide(
          color: _hovered ? theme.colorScheme.outline : Colors.transparent,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: widget.onPressed,
        onHover: (h) {
          if (h != _hovered) setState(() => _hovered = h);
        },
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(Icons.close_rounded, size: 16, color: color),
        ),
      ),
    );
  }
}
