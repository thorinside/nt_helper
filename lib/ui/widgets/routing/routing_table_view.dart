import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nt_helper/core/routing/bus_spec.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/cubit/routing_editor_cubit.dart';
import 'package:nt_helper/cubit/routing_editor_state.dart';
import 'package:nt_helper/models/routing_information.dart';
import 'package:nt_helper/util/routing_analyzer.dart';

/// OG-style signal flow table visualization for the routing editor.
///
/// Displays routing as a matrix: slots as rows, buses as columns, with
/// color-coded signal propagation and symbols for input/output/replace.
/// Matches the visual style of the original Disting NT preset editor.
class RoutingTableView extends StatelessWidget {
  const RoutingTableView({super.key});

  // OG preset editor default colors
  static const Color _color1 = Color(0xFFb3fff0); // Cyan/mint
  static const Color _color2 = Color(0xFFd9ffb3); // Light green

  static const double _cellWidth = 32;
  static const double _cellHeight = 28;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RoutingEditorCubit, RoutingEditorState>(
      builder: (context, state) {
        return state.when(
          initial: () => const Center(child: Text('Initializing...')),
          disconnected: () => const Center(child: Text('Disconnected')),
          loaded: (
            physicalInputs,
            physicalOutputs,
            es5Inputs,
            algorithms,
            connections,
            buses,
            portOutputModes,
            nodePositions,
            zoomLevel,
            panOffset,
            isHardwareSynced,
            isPersistenceEnabled,
            lastSyncTime,
            lastPersistTime,
            lastError,
            subState,
            focusedAlgorithmIds,
            cascadeScrollTarget,
            auxBusUsage,
            hasExtendedAuxBuses,
          ) =>
              _buildTable(context, hasExtendedAuxBuses: hasExtendedAuxBuses),
        );
      },
    );
  }

  Widget _buildTable(BuildContext context,
      {required bool hasExtendedAuxBuses}) {
    final routing = context.read<DistingCubit>().buildRoutingInformation();
    if (routing.isEmpty) {
      return Center(
        child: Text(
          'No algorithms loaded.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      );
    }

    final analyzer = RoutingAnalyzer(routing: routing);
    final slotCount = routing.length;
    final signals = analyzer.signals;
    final usageNeeded = analyzer.usageNeeded;
    final numBuses =
        _computeVisibleBusCount(signals, hasExtendedAuxBuses: hasExtendedAuxBuses);

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color1 = isDark ? _color1.withAlpha(180) : _color1;
    final color2 = isDark ? _color2.withAlpha(180) : _color2;
    final colours = [
      isDark ? const Color(0xFF1E1E1E) : const Color(0xFFFFFFFF), // level 0 even
      color1, // level 1 even
      color2, // level 2 even
      isDark ? const Color(0xFF2A2A2A) : const Color(0xFFFCFCFC), // level 0 odd
      _darken(color1), // level 1 odd
      _darken(color2), // level 2 odd
    ];

    final pinnedRows = <TableRow>[];
    final mainRows = <TableRow>[];

    // Group header row
    _addGroupHeaderRow(pinnedRows, mainRows, numBuses, theme);

    // Column number header row
    _addColumnHeaderRow(pinnedRows, mainRows, numBuses, theme);

    for (int s = 0; s < slotCount; s++) {
      final info = routing[s];
      final rowBefore = signals[s];
      final rowAfter = signals[s + 1];

      // Signal-above row (arrows showing inputs)
      _addSignalAboveRow(
        pinnedRows,
        mainRows,
        s,
        numBuses,
        rowBefore,
        info,
        analyzer,
        colours,
        theme,
      );

      // Slot row (algorithm name + used buses)
      _addSlotRow(
        pinnedRows,
        mainRows,
        s,
        numBuses,
        info,
        rowBefore,
        usageNeeded[s + 1],
        colours,
        theme,
      );

      // Signal-below row (output symbols)
      _addSignalBelowRow(
        pinnedRows,
        mainRows,
        s,
        numBuses,
        rowAfter,
        info,
        colours,
        theme,
      );
    }

    // Repeat headers at bottom
    _addColumnHeaderRow(pinnedRows, mainRows, numBuses, theme);
    _addGroupHeaderRow(pinnedRows, mainRows, numBuses, theme);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Pinned algorithm name column
        SingleChildScrollView(
          child: Table(
            border: TableBorder(
              right: BorderSide(color: theme.dividerColor),
              horizontalInside: BorderSide(color: theme.dividerColor, width: 0.5),
            ),
            columnWidths: const {0: IntrinsicColumnWidth()},
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: pinnedRows,
          ),
        ),
        // Scrollable bus columns
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              child: Table(
                border: TableBorder(
                  verticalInside:
                      BorderSide(color: theme.dividerColor, width: 0.5),
                  horizontalInside:
                      BorderSide(color: theme.dividerColor, width: 0.5),
                ),
                columnWidths: {
                  for (int i = 0; i < numBuses; i++)
                    i: const FixedColumnWidth(_cellWidth),
                },
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                children: mainRows,
              ),
            ),
          ),
        ),
      ],
    );
  }

  int _computeVisibleBusCount(List<List<int>> signals,
      {required bool hasExtendedAuxBuses}) {
    final maxBus = hasExtendedAuxBuses ? BusSpec.extendedMax : BusSpec.max;
    final last = signals.last;
    int numBuses = maxBus;
    // Trim unused aux buses from the right
    final auxStart = BusSpec.auxMin;
    for (int i = numBuses; i >= auxStart; i--) {
      if (i < last.length && last[i] != 0) break;
      numBuses = i - 1;
    }
    // Always show at least through the outputs
    if (numBuses < BusSpec.outputMax) numBuses = BusSpec.outputMax;
    return numBuses;
  }

  void _addGroupHeaderRow(List<TableRow> pinnedRows, List<TableRow> mainRows,
      int numBuses, ThemeData theme) {
    final inputCount = BusSpec.inputMax - BusSpec.inputMin + 1; // 12
    final outputCount = BusSpec.outputMax - BusSpec.outputMin + 1; // 8
    final auxCount = numBuses - BusSpec.outputMax; // remaining

    pinnedRows.add(TableRow(children: [
      SizedBox(height: _cellHeight),
    ]));

    final cells = <Widget>[];
    // Inputs group
    cells.add(_groupHeaderCell('Inputs', inputCount, const Color(0xFFC0C0C0), theme));
    // Outputs group
    cells.add(_groupHeaderCell('Outputs', outputCount, const Color(0xFFE0E0E0), theme));
    // Aux group
    if (auxCount > 0) {
      cells.add(_groupHeaderCell('Aux', auxCount, const Color(0xFFC0C0C0), theme));
    }

    mainRows.add(TableRow(children: cells));
  }

  Widget _groupHeaderCell(
      String label, int colSpan, Color bgColor, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final effectiveBg = isDark ? bgColor.withAlpha(60) : bgColor;
    return Container(
      width: _cellWidth * colSpan,
      height: _cellHeight,
      alignment: Alignment.center,
      color: effectiveBg,
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _addColumnHeaderRow(List<TableRow> pinnedRows, List<TableRow> mainRows,
      int numBuses, ThemeData theme) {
    pinnedRows.add(TableRow(children: [
      _pinnedHeaderCell('Algorithm', theme),
    ]));

    final cells = <Widget>[];
    for (int ch = 1; ch <= numBuses; ch++) {
      Color bgColor;
      if (ch <= BusSpec.inputMax) {
        bgColor = const Color(0xFFC0C0C0);
      } else if (ch <= BusSpec.outputMax) {
        bgColor = const Color(0xFFE0E0E0);
      } else {
        bgColor = const Color(0xFFC0C0C0);
      }
      final isDark = theme.brightness == Brightness.dark;
      final effectiveBg = isDark ? bgColor.withAlpha(60) : bgColor;

      cells.add(Container(
        width: _cellWidth,
        height: _cellHeight,
        alignment: Alignment.center,
        color: effectiveBg,
        child: Text(
          _columnLabel(ch),
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ));
    }
    mainRows.add(TableRow(children: cells));
  }

  Widget _pinnedHeaderCell(String text, ThemeData theme) {
    return Container(
      height: _cellHeight,
      constraints: const BoxConstraints(minWidth: 80),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.centerLeft,
      color: theme.brightness == Brightness.dark
          ? const Color(0xFF2A2A2A)
          : const Color(0xFFF0F0F0),
      child: Text(
        text,
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _addSignalAboveRow(
    List<TableRow> pinnedRows,
    List<TableRow> mainRows,
    int slotIndex,
    int numBuses,
    List<int> rowBefore,
    RoutingInformation info,
    RoutingAnalyzer analyzer,
    List<Color> colours,
    ThemeData theme,
  ) {
    pinnedRows.add(TableRow(children: [
      SizedBox(height: _cellHeight),
    ]));

    final inMask = analyzer.getNetInputMask(info);
    final cells = <Widget>[];
    for (int ch = 1; ch <= numBuses; ch++) {
      final usesChannel = (inMask & (1 << ch)) != 0;
      final signalLevel = ch < rowBefore.length ? rowBefore[ch] : 0;
      final unprovided = usesChannel && signalLevel == 0;
      final bgColor = colours[signalLevel + 3 * (ch & 1)];

      cells.add(Container(
        width: _cellWidth,
        height: _cellHeight,
        alignment: Alignment.center,
        color: bgColor,
        child: usesChannel
            ? Text(
                '\u2193', // ↓
                style: TextStyle(
                  fontSize: 13,
                  color: unprovided ? Colors.red.shade800 : null,
                  fontWeight:
                      unprovided ? FontWeight.bold : FontWeight.normal,
                ),
              )
            : null,
      ));
    }
    mainRows.add(TableRow(children: cells));
  }

  void _addSlotRow(
    List<TableRow> pinnedRows,
    List<TableRow> mainRows,
    int slotIndex,
    int numBuses,
    RoutingInformation info,
    List<int> signalsBefore,
    List<bool> usageNeededAfter,
    List<Color> colours,
    ThemeData theme,
  ) {
    pinnedRows.add(TableRow(children: [
      Container(
        height: _cellHeight,
        constraints: const BoxConstraints(minWidth: 80),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        alignment: Alignment.centerLeft,
        color: theme.brightness == Brightness.dark
            ? const Color(0xFF2A2A2A)
            : const Color(0xFFF0F0F0),
        child: Text(
          '${info.algorithmIndex + 1}. ${info.algorithmName}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ]));

    final usedMask =
        info.routingInfo[0] | info.routingInfo[1] | info.routingInfo[5];
    final cells = <Widget>[];
    for (int ch = 1; ch <= numBuses; ch++) {
      final levelBefore = ch < signalsBefore.length ? signalsBefore[ch] : 0;
      final isUsed = (usedMask & (1 << ch)) != 0;
      final isDark = theme.brightness == Brightness.dark;

      Color bgColor;
      if (isUsed) {
        bgColor = isDark ? const Color(0xFF505050) : const Color(0xFFD0D0D0);
      } else if (levelBefore > 0) {
        bgColor = colours[levelBefore + 3 * (ch & 1)];
      } else {
        bgColor = isDark ? const Color(0xFF303030) : const Color(0xFFF0F0F0);
      }

      final label = isUsed ? _condensedChannelLabel(ch) : '';

      cells.add(Container(
        width: _cellWidth,
        height: _cellHeight,
        alignment: Alignment.center,
        color: bgColor,
        child: Text(
          label,
          style: theme.textTheme.labelSmall,
        ),
      ));
    }
    mainRows.add(TableRow(children: cells));
  }

  void _addSignalBelowRow(
    List<TableRow> pinnedRows,
    List<TableRow> mainRows,
    int slotIndex,
    int numBuses,
    List<int> rowAfter,
    RoutingInformation info,
    List<Color> colours,
    ThemeData theme,
  ) {
    pinnedRows.add(TableRow(children: [
      SizedBox(height: _cellHeight),
    ]));

    final outMask = info.routingInfo[1];
    final replaceMask = info.routingInfo[2];
    final cells = <Widget>[];
    for (int ch = 1; ch <= numBuses; ch++) {
      final signalLevel = ch < rowAfter.length ? rowAfter[ch] : 0;
      final bgColor = colours[signalLevel + 3 * (ch & 1)];
      final hasOutput = (outMask & (1 << ch)) != 0;
      final replaced = (replaceMask & (1 << ch)) != 0;
      final symbol = hasOutput ? (replaced ? '\u2533' : '+') : '';

      cells.add(Container(
        width: _cellWidth,
        height: _cellHeight,
        alignment: Alignment.center,
        color: bgColor,
        child: Text(
          symbol,
          style: theme.textTheme.labelSmall?.copyWith(fontSize: 13),
        ),
      ));
    }
    mainRows.add(TableRow(children: cells));
  }

  String _columnLabel(int ch) {
    if (ch <= BusSpec.inputMax) return '$ch';
    if (ch <= BusSpec.outputMax) return '${ch - BusSpec.inputMax}';
    return '${ch - BusSpec.outputMax}';
  }

  String _condensedChannelLabel(int ch) {
    int c = ch;
    if (c > BusSpec.inputMax) {
      c -= BusSpec.inputMax;
      if (c > (BusSpec.outputMax - BusSpec.inputMax)) {
        c -= (BusSpec.outputMax - BusSpec.inputMax);
      }
    }
    return '$c';
  }

  Color _darken(Color c, [double factor = 0.9]) {
    return Color.fromRGBO(
      ((c.r * 255.0).round() * factor).round().clamp(0, 255),
      ((c.g * 255.0).round() * factor).round().clamp(0, 255),
      ((c.b * 255.0).round() * factor).round().clamp(0, 255),
      1.0,
    );
  }
}
