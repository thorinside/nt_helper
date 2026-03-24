import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nt_helper/core/routing/bus_spec.dart';
import 'package:nt_helper/core/routing/models/port.dart';
import 'package:nt_helper/cubit/routing_editor_cubit.dart';
import 'package:nt_helper/cubit/routing_editor_state.dart';
import 'package:nt_helper/models/routing_information.dart';
import 'package:nt_helper/util/routing_analyzer.dart';

/// OG-style signal flow table visualization for the routing editor.
///
/// Displays routing as a matrix: slots as rows, buses as columns, with
/// color-coded signal propagation and symbols for input/output/replace.
class RoutingTableView extends StatefulWidget {
  const RoutingTableView({super.key});

  @override
  State<RoutingTableView> createState() => _RoutingTableViewState();
}

class _RoutingTableViewState extends State<RoutingTableView> {
  // Signal flow colors
  static const Color _color1 = Color(0xFFb3fff0); // Cyan/mint
  static const Color _color2 = Color(0xFFFFD9A3); // Gold/warm

  static const double _cellWidth = 32;
  static const double _cellHeight = 28;


  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RoutingEditorCubit, RoutingEditorState>(
      buildWhen: (prev, curr) {
        // Only rebuild when algorithm/connection data actually changes,
        // not on zoom, pan, focus, or other UI-only state changes.
        if (prev is! RoutingEditorStateLoaded ||
            curr is! RoutingEditorStateLoaded) {
          return true;
        }
        return prev.algorithms != curr.algorithms ||
            prev.connections != curr.connections ||
            prev.portOutputModes != curr.portOutputModes ||
            prev.hasExtendedAuxBuses != curr.hasExtendedAuxBuses;
      },
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
              _buildTable(
            context,
            algorithms: algorithms,
            portOutputModes: portOutputModes,
            hasExtendedAuxBuses: hasExtendedAuxBuses,
          ),
        );
      },
    );
  }

  /// Build [RoutingInformation] from the routing editor's algorithm/port data.
  List<RoutingInformation> _buildRoutingFromEditorState(
    List<RoutingAlgorithm> algorithms,
    Map<String, OutputMode> portOutputModes,
  ) {
    final sorted = List<RoutingAlgorithm>.from(algorithms)
      ..sort((a, b) => a.index.compareTo(b.index));

    return sorted.map((algo) {
      int inputMask = 0;
      int outputMask = 0;
      int replaceMask = 0;

      for (final port in algo.inputPorts) {
        final bus = port.busValue;
        if (bus != null && bus > 0 && bus <= BusSpec.extendedMax) {
          inputMask |= (1 << bus);
        }
      }

      for (final port in algo.outputPorts) {
        final bus = port.busValue;
        if (bus != null && bus > 0 && bus <= BusSpec.extendedMax) {
          outputMask |= (1 << bus);
          final mode = portOutputModes[port.id] ?? port.outputMode;
          if (mode == OutputMode.replace) {
            replaceMask |= (1 << bus);
          }
        }
      }

      return RoutingInformation(
        algorithmIndex: algo.index,
        routingInfo: [inputMask, outputMask, replaceMask, 0, 0, 0],
        algorithmName: algo.algorithm.name,
      );
    }).toList();
  }

  Widget _buildTable(
    BuildContext context, {
    required List<RoutingAlgorithm> algorithms,
    required Map<String, OutputMode> portOutputModes,
    required bool hasExtendedAuxBuses,
  }) {
    final routing =
        _buildRoutingFromEditorState(algorithms, portOutputModes);
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
    final numBuses = _computeVisibleBusCount(signals, routing,
        hasExtendedAuxBuses: hasExtendedAuxBuses);

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color1 = isDark ? const Color(0xFF1A6B5C) : _color1;
    final color2 = isDark ? const Color(0xFF8B4A3A) : _color2;
    final colours = [
      isDark ? const Color(0xFF1E1E1E) : const Color(0xFFFFFFFF),
      color1,
      color2,
      isDark ? const Color(0xFF252525) : const Color(0xFFFCFCFC),
      _darken(color1, isDark ? 0.8 : 0.9),
      _darken(color2, isDark ? 0.8 : 0.9),
    ];

    // Pre-compute text styles once instead of per-cell
    final headerStyle =
        theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold);
    final slotNameStyle =
        theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600);
    final cellStyle = theme.textTheme.labelSmall;
    final symbolStyle = theme.textTheme.labelSmall?.copyWith(fontSize: 13);
    final pinnedBg = isDark ? const Color(0xFF333333) : const Color(0xFFF0F0F0);
    final slotBg = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF0F0F0);
    final usedBg = isDark ? const Color(0xFF505050) : const Color(0xFFD0D0D0);
    final unusedBg = isDark ? const Color(0xFF303030) : const Color(0xFFF0F0F0);

    final pinnedRows = <TableRow>[];
    final mainRows = <TableRow>[];

    // Header row (top)
    pinnedRows.add(TableRow(children: [
      Container(
        height: _cellHeight,
        constraints: const BoxConstraints(minWidth: 80),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        alignment: Alignment.centerLeft,
        color: pinnedBg,
        child: Text('Algorithm', style: headerStyle),
      ),
    ]));
    mainRows.add(TableRow(
      children: [
        for (int ch = 1; ch <= numBuses; ch++)
          Container(
            width: _cellWidth,
            height: _cellHeight,
            alignment: Alignment.center,
            color: _headerBg(ch, isDark),
            child: Text(_columnLabel(ch), style: headerStyle),
          ),
      ],
    ));

    for (int s = 0; s < slotCount; s++) {
      final info = routing[s];
      final rowBefore = signals[s];
      final rowAfter = signals[s + 1];
      final inMask = analyzer.getNetInputMask(info);
      final outMask = info.routingInfo[1];
      final replaceMask = info.routingInfo[2];
      final usedMask =
          info.routingInfo[0] | info.routingInfo[1] | info.routingInfo[5];

      // Signal-above row
      pinnedRows.add(TableRow(children: [SizedBox(height: _cellHeight)]));
      mainRows.add(TableRow(
        children: [
          for (int ch = 1; ch <= numBuses; ch++)
            _signalAboveCell(ch, rowBefore, inMask, colours, isDark),
        ],
      ));

      // Slot row
      pinnedRows.add(TableRow(children: [
        Container(
          height: _cellHeight,
          constraints: const BoxConstraints(minWidth: 80),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          alignment: Alignment.centerLeft,
          color: slotBg,
          child: Text(
            '${info.algorithmIndex + 1}. ${info.algorithmName}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: slotNameStyle,
          ),
        ),
      ]));
      mainRows.add(TableRow(
        children: [
          for (int ch = 1; ch <= numBuses; ch++)
            _slotCell(ch, signalsBefore: rowBefore, usedMask: usedMask,
                colours: colours, usedBg: usedBg, unusedBg: unusedBg,
                cellStyle: cellStyle),
        ],
      ));

      // Signal-below row
      pinnedRows.add(TableRow(children: [SizedBox(height: _cellHeight)]));
      mainRows.add(TableRow(
        children: [
          for (int ch = 1; ch <= numBuses; ch++)
            _signalBelowCell(ch, rowAfter, outMask, replaceMask, colours,
                symbolStyle),
        ],
      ));
    }

    // Header row (bottom)
    pinnedRows.add(TableRow(children: [
      Container(
        height: _cellHeight,
        constraints: const BoxConstraints(minWidth: 80),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        alignment: Alignment.centerLeft,
        color: pinnedBg,
        child: Text('Algorithm', style: headerStyle),
      ),
    ]));
    mainRows.add(TableRow(
      children: [
        for (int ch = 1; ch <= numBuses; ch++)
          Container(
            width: _cellWidth,
            height: _cellHeight,
            alignment: Alignment.center,
            color: _headerBg(ch, isDark),
            child: Text(_columnLabel(ch), style: headerStyle),
          ),
      ],
    ));

    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(overscroll: false),
      child: SingleChildScrollView(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pinned algorithm name column — scrolls with the main table
            Table(
              border: TableBorder(
                right: BorderSide(color: theme.dividerColor),
                horizontalInside:
                    BorderSide(color: theme.dividerColor, width: 0.5),
              ),
              columnWidths: const {0: IntrinsicColumnWidth()},
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              children: pinnedRows,
            ),
            // Bus columns — horizontal scroll only
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
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
          ],
        ),
      ),
    );
  }

  Widget _signalAboveCell(int ch, List<int> rowBefore, int inMask,
      List<Color> colours, bool isDark) {
    final usesChannel = (inMask & (1 << ch)) != 0;
    final signalLevel = ch < rowBefore.length ? rowBefore[ch] : 0;
    final bgColor = colours[signalLevel + 3 * (ch & 1)];

    if (!usesChannel) {
      return Container(width: _cellWidth, height: _cellHeight, color: bgColor);
    }
    final unprovided = signalLevel == 0;
    return Container(
      width: _cellWidth,
      height: _cellHeight,
      alignment: Alignment.center,
      color: bgColor,
      child: Text(
        '\u2193',
        style: TextStyle(
          fontSize: 13,
          color: unprovided ? Colors.red.shade800 : null,
          fontWeight: unprovided ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _slotCell(int ch,
      {required List<int> signalsBefore,
      required int usedMask,
      required List<Color> colours,
      required Color usedBg,
      required Color unusedBg,
      required TextStyle? cellStyle}) {
    final levelBefore = ch < signalsBefore.length ? signalsBefore[ch] : 0;
    final isUsed = (usedMask & (1 << ch)) != 0;

    final Color bgColor;
    if (isUsed) {
      bgColor = usedBg;
    } else if (levelBefore > 0) {
      bgColor = colours[levelBefore + 3 * (ch & 1)];
    } else {
      bgColor = unusedBg;
    }

    if (!isUsed) {
      return Container(width: _cellWidth, height: _cellHeight, color: bgColor);
    }
    return Container(
      width: _cellWidth,
      height: _cellHeight,
      alignment: Alignment.center,
      color: bgColor,
      child: Text(_condensedChannelLabel(ch), style: cellStyle),
    );
  }

  Widget _signalBelowCell(int ch, List<int> rowAfter, int outMask,
      int replaceMask, List<Color> colours, TextStyle? symbolStyle) {
    final signalLevel = ch < rowAfter.length ? rowAfter[ch] : 0;
    final bgColor = colours[signalLevel + 3 * (ch & 1)];
    final hasOutput = (outMask & (1 << ch)) != 0;

    if (!hasOutput) {
      return Container(width: _cellWidth, height: _cellHeight, color: bgColor);
    }
    final replaced = (replaceMask & (1 << ch)) != 0;
    return Container(
      width: _cellWidth,
      height: _cellHeight,
      alignment: Alignment.center,
      color: bgColor,
      child: Text(replaced ? '\u2533' : '+', style: symbolStyle),
    );
  }

  int _computeVisibleBusCount(
    List<List<int>> signals,
    List<RoutingInformation> routing, {
    required bool hasExtendedAuxBuses,
  }) {
    final maxBus = hasExtendedAuxBuses ? BusSpec.extendedMax : BusSpec.max;
    int highestUsed = BusSpec.outputMax;
    for (final info in routing) {
      final usedMask =
          info.routingInfo[0] | info.routingInfo[1] | info.routingInfo[5];
      for (int ch = maxBus; ch > highestUsed; ch--) {
        if ((usedMask & (1 << ch)) != 0) {
          highestUsed = ch;
          break;
        }
      }
    }
    final last = signals.last;
    for (int i = maxBus; i > highestUsed; i--) {
      if (i < last.length && last[i] != 0) {
        highestUsed = i;
        break;
      }
    }
    return highestUsed;
  }

  Color _headerBg(int ch, bool isDark) {
    if (ch <= BusSpec.inputMax) {
      return isDark ? const Color(0xFF2E2E2E) : const Color(0xFFB8B8B8);
    }
    if (ch <= BusSpec.outputMax) {
      return isDark ? const Color(0xFF484848) : const Color(0xFFDCDCDC);
    }
    return isDark ? const Color(0xFF383838) : const Color(0xFFC8C8C8);
  }

  String _columnLabel(int ch) {
    if (ch <= BusSpec.inputMax) return 'I$ch';
    if (ch <= BusSpec.outputMax) return 'O${ch - BusSpec.inputMax}';
    return 'A${ch - BusSpec.outputMax}';
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
