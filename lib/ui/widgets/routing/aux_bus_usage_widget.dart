import 'package:flutter/material.dart';
import 'package:nt_helper/core/routing/bus_spec.dart';
import 'package:nt_helper/cubit/routing_editor_state.dart';
import 'package:nt_helper/ui/widgets/routing/bus_label_formatter.dart';

class AuxBusUsageWidget extends StatelessWidget {
  final Map<int, AuxBusUsageInfo> auxBusUsage;
  final bool hasExtendedAuxBuses;
  final int? focusedBusNumber;
  final ValueChanged<int> onBusTapped;

  const AuxBusUsageWidget({
    super.key,
    required this.auxBusUsage,
    required this.hasExtendedAuxBuses,
    required this.focusedBusNumber,
    required this.onBusTapped,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;
    final auxCeiling = BusSpec.auxMaxForFirmware(
      hasExtendedAuxBuses: hasExtendedAuxBuses,
    );

    // Collect all valid AUX bus numbers
    final busList = <int>[];
    for (int b = BusSpec.auxMin; b <= auxCeiling; b++) {
      if (BusSpec.isAux(b)) busList.add(b);
    }

    // Layout: single row for 8, 4 rows of 11 for extended
    final int columns = hasExtendedAuxBuses ? 11 : busList.length;

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int row = 0; row * columns < busList.length; row++)
            Padding(
              padding: EdgeInsets.only(top: row > 0 ? 2.0 : 0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int col = 0;
                      col < columns && row * columns + col < busList.length;
                      col++)
                    Padding(
                      padding: EdgeInsets.only(left: col > 0 ? 2.0 : 0),
                      child: _BusSquare(
                        busNumber: busList[row * columns + col],
                        info: auxBusUsage[busList[row * columns + col]],
                        isFocused:
                            focusedBusNumber == busList[row * columns + col],
                        colorScheme: colorScheme,
                        brightness: brightness,
                        onTap: onBusTapped,
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _BusSquare extends StatelessWidget {
  final int busNumber;
  final AuxBusUsageInfo? info;
  final bool isFocused;
  final ColorScheme colorScheme;
  final Brightness brightness;
  final ValueChanged<int> onTap;

  const _BusSquare({
    required this.busNumber,
    required this.info,
    required this.isFocused,
    required this.colorScheme,
    required this.brightness,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final sessions = info?.sessionCount ?? 0;
    final isEmpty = sessions == 0;

    final Color fillColor;
    if (isEmpty) {
      fillColor = Colors.transparent;
    } else if (sessions == 1) {
      fillColor =
          brightness == Brightness.dark ? Colors.green[400]! : Colors.green[600]!;
    } else if (sessions == 2) {
      fillColor =
          brightness == Brightness.dark ? Colors.amber[400]! : Colors.amber[600]!;
    } else {
      fillColor = colorScheme.error;
    }

    final borderColor =
        isFocused ? colorScheme.primary : colorScheme.outlineVariant;
    final borderWidth = isFocused ? 2.0 : 1.0;

    final label = BusLabelFormatter.formatBusValue(busNumber);
    final tooltip = _buildTooltip(label);

    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 400),
      child: GestureDetector(
        onTap: () => onTap(busNumber),
        child: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: fillColor,
            borderRadius: BorderRadius.circular(2),
            border: Border.all(color: borderColor, width: borderWidth),
          ),
        ),
      ),
    );
  }

  String _buildTooltip(String label) {
    if (info == null || info!.sessionCount == 0) {
      return '$label: unused';
    }

    final sources = info!.sourceNames;
    final dests = info!.destNames;

    if (sources.isEmpty && dests.isEmpty) {
      return '$label: in use';
    }

    final lines = <String>[label];
    if (sources.isNotEmpty && dests.isNotEmpty) {
      for (final src in sources) {
        for (final dst in dests) {
          lines.add('$src -> $dst');
        }
      }
    } else if (sources.isNotEmpty) {
      for (final src in sources) {
        lines.add('$src (no readers)');
      }
    } else {
      for (final dst in dests) {
        lines.add('(no writers) -> $dst');
      }
    }
    return lines.join('\n');
  }
}
