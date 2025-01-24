import 'dart:math';

import 'package:flutter/material.dart';
import 'package:nt_helper/models/routing_information.dart';

class RoutingTableWidget extends StatelessWidget {
  final List<RoutingInformation> routing;
  final Color color1; // Base color for level=1 signals
  final Color color2; // Base color for level=2 signals
  final bool showSignals;
  final bool showMappings;

  // We still fix each channel cell’s width + height for consistency
  static const double _cellWidth = 32;
  static const double _cellHeight = 32;

  const RoutingTableWidget({
    super.key,
    required this.routing,
    this.color1 = const Color(0xffffc000), // Similar to JS "golden"
    this.color2 = const Color(0xff40c0ff), // Similar to JS "lightBlue-ish"
    this.showSignals = true,
    this.showMappings = false,
  });

  @override
  Widget build(BuildContext context) {
    // 1) Build the signal arrays + usage checks
    final slotCount = routing.length;
    final signals = _buildForwardSignals(slotCount);
    _applyStripSignals(slotCount, signals);
    final usageNeeded = _buildUsageNeeded(slotCount);

    // 2) Build the final list of TableRows: 3 rows per slot + 2 headers
    final allRows = <TableRow>[];
    // a) top header
    allRows.add(_buildHeaderRow());

    // b) for each slot => rowAbove, rowSlot, rowBelow
    for (int s = 0; s < slotCount; s++) {
      final info = routing[s];
      final rowBefore = signals[s];
      final rowAfter = signals[s + 1];

      // rowAbove
      allRows.add(
        TableRow(
          children: [
            // pinned col, empty
            _buildSlotCell('', slotName: false),
            for (int ch = 1; ch <= 28; ch++)
              _buildSignalAboveCell(
                slotIndex: s,
                channel: ch,
                signalLevel: rowBefore[ch],
                info: info,
              ),
          ],
        ),
      );

      // rowSlot
      allRows.add(
        TableRow(
          children: [
            // pinned col with slot/algorithm name
            _buildSlotCell(
              '${info.algorithmIndex + 1}. ${info.algorithmName}',
              slotName: true,
            ),
            for (int ch = 1; ch <= 28; ch++)
              _buildSlotUsageCell(
                slotIndex: s,
                channel: ch,
                info: info,
                signalsBefore: rowBefore,
                signalsAfter: rowAfter,
                usageNeededAfter: usageNeeded[s + 1],
              ),
          ],
        ),
      );

      // rowBelow
      allRows.add(
        TableRow(
          children: [
            _buildSlotCell('', slotName: false),
            for (int ch = 1; ch <= 28; ch++)
              _buildSignalBelowCell(
                slotIndex: s,
                channel: ch,
                signalLevel: rowAfter[ch],
                info: info,
              ),
          ],
        ),
      );
    }

    // c) bottom header
    allRows.add(_buildHeaderRow());

    // 3) We create TWO tables in a Row so that we can "pin" the first column
    //    horizontally. The pinned column is just the first cell of each row,
    //    while the main area has channels 1..28 in a horizontally scrollable area.

    // First, build the pinned column (first cell each row)
    final pinnedColumnRows = <TableRow>[];
    final mainAreaRows = <TableRow>[];

    for (final row in allRows) {
      if (row.children.isEmpty) {
        pinnedColumnRows.add(TableRow(children: [const SizedBox()]));
        mainAreaRows.add(TableRow(children: [const SizedBox()]));
        continue;
      }
      final pinnedCell = row.children.first;
      final otherCells = row.children.skip(1).toList();

      pinnedColumnRows.add(TableRow(children: [pinnedCell]));
      mainAreaRows.add(TableRow(children: otherCells));
    }

    // 4) Return a Row with a pinned table (no scrolling) on the left,
    //    and a horizontally scrollable table on the right.
    //    We do NOT wrap either in a vertical scroller—parent is responsible for that.
    return Row(
      children: [
        // Pinned column (no scrolling)
        Table(
          border: TableBorder(
            left: BorderSide.none,
            right: BorderSide(color: Colors.grey.shade300),
            verticalInside: BorderSide(color: Colors.grey.shade300),
            horizontalInside: BorderSide(color: Colors.grey.shade300),
          ),
          columnWidths: const {
            0: IntrinsicColumnWidth(), // auto-size pinned column
          },
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: pinnedColumnRows,
        ),

        // Right side: horizontally scrollable channels
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Table(
              border: TableBorder(
                verticalInside: BorderSide(color: Colors.grey.shade300),
                horizontalInside: BorderSide(color: Colors.grey.shade300),
              ),
              columnWidths: {
                for (int i = 0; i <= 28; i++)
                  i: const FixedColumnWidth(_cellWidth),
              },
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              children: mainAreaRows,
            ),
          ),
        ),
      ],
    );
  }

  //----------------------------------------------------------------------------
  // 1) Build forward "signals"
  //----------------------------------------------------------------------------
  List<List<int>> _buildForwardSignals(int slotCount) {
    final signals = [
      [
        0,
        1,
        1,
        1,
        1,
        1,
        1,
        1,
        1,
        1,
        1,
        1,
        1,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0
      ]
    ];

    for (int s = 0; s < slotCount; s++) {
      final info = routing[s];
      final rowBefore = signals.last;
      final rowAfter = List<int>.from(rowBefore);

      final outMask = info.routingInfo[1];
      final replaceMask = info.routingInfo[2];

      for (int ch = 1; ch <= 28; ch++) {
        int v = rowBefore[ch];
        final hasOutput = (outMask & (1 << ch)) != 0;
        final replaced = (replaceMask & (1 << ch)) != 0;

        if (hasOutput) {
          if (replaced) {
            v = v + 1;
            if (v > 2) v = 1;
          } else if (v == 0) {
            v = 1;
          }
        }
        rowAfter[ch] = v;
      }
      signals.add(rowAfter);
    }

    return signals;
  }

  //----------------------------------------------------------------------------
  // 2) Strip signals that go nowhere (bottom-up)
  //----------------------------------------------------------------------------
  void _applyStripSignals(int slotCount, List<List<int>> signals) {
    for (int ch = 1; ch <= 28; ch++) {
      if (showSignals && (ch == 13)) {
        ch = 21;
      }
      bool hasInput = false;
      for (int s = slotCount; s >= 0; s--) {
        if (s < slotCount) {
          final info = routing[s];
          final inMask = _netInputMask(info);
          final replaceMask = info.routingInfo[2];
          if ((replaceMask & (1 << ch)) != 0) {
            hasInput = false;
          }
          if ((inMask & (1 << ch)) != 0) {
            hasInput = true;
          }
        }
        if (!hasInput) {
          signals[s][ch] = 0;
        }
      }
    }
  }

  //----------------------------------------------------------------------------
  // 3) Build usageNeeded array (for orphan detection)
  //----------------------------------------------------------------------------
  List<List<bool>> _buildUsageNeeded(int slotCount) {
    final usageNeeded = List.generate(
      slotCount + 1,
      (_) => List<bool>.filled(29, false),
    );
    for (int s = slotCount - 1; s >= 0; s--) {
      final info = routing[s];
      final inMask = _netInputMask(info);
      final replaceMask = info.routingInfo[2];
      for (int ch = 1; ch <= 28; ch++) {
        final neededBelow = usageNeeded[s + 1][ch];
        final replacedHere = (replaceMask & (1 << ch)) != 0;
        final slotNeedsCh = (inMask & (1 << ch)) != 0;
        usageNeeded[s][ch] = slotNeedsCh || (neededBelow && !replacedHere);
      }
    }
    return usageNeeded;
  }

  //----------------------------------------------------------------------------
  // Header row
  //----------------------------------------------------------------------------
  TableRow _buildHeaderRow() {
    return TableRow(
      children: [
        _buildHeaderCell('Algorithm'),
        for (int ch = 1; ch <= 28; ch++) _buildHeaderCell(_channelLabel(ch)),
      ],
    );
  }

  Widget _buildHeaderCell(String text) {
    return Container(
      alignment: Alignment.center,
      width: _cellWidth,
      height: _cellHeight,
      child: Text(
        text,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
      ),
    );
  }

  //----------------------------------------------------------------------------
  // Pinned column cell
  //----------------------------------------------------------------------------
  Widget _buildSlotCell(String text, {required bool slotName}) {
    // We fix the height so it aligns with the main table rows.
    return Container(
      alignment: slotName ? Alignment.centerLeft : Alignment.center,
      height: _cellHeight,
      constraints: const BoxConstraints(minWidth: 60),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        softWrap: false,
        style: TextStyle(
          fontSize: 12,
          fontWeight: slotName ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }

  //----------------------------------------------------------------------------
  // "Above" row cell => arrow "↓" if slot uses channel as input
  // red if unprovided
  //----------------------------------------------------------------------------
  Widget _buildSignalAboveCell({
    required int slotIndex,
    required int channel,
    required int signalLevel,
    required RoutingInformation info,
  }) {
    final inMask = _netInputMask(info);
    final usesChannel = (inMask & (1 << channel)) != 0;
    final unprovided = usesChannel && signalLevel == 0;

    final bgColor = _cellColor(signalLevel, channel);
    final arrow = usesChannel ? '↓' : '';

    return Container(
      width: _cellWidth,
      height: _cellHeight,
      alignment: Alignment.center,
      color: bgColor,
      child: Text(
        arrow,
        style: TextStyle(
          fontSize: 11,
          color: unprovided ? Colors.red.shade800 : Colors.black,
          fontWeight: unprovided ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  //----------------------------------------------------------------------------
  // Slot row cell => highlight orphaned outputs, show channel # if used
  //----------------------------------------------------------------------------
  Widget _buildSlotUsageCell({
    required int slotIndex,
    required int channel,
    required RoutingInformation info,
    required List<int> signalsBefore,
    required List<int> signalsAfter,
    required List<bool> usageNeededAfter,
  }) {
    final usedMask =
        info.routingInfo[0] | info.routingInfo[1] | info.routingInfo[5];
    final outMask = info.routingInfo[1];

    final levelBefore = signalsBefore[channel];
    final isUsed = (usedMask & (1 << channel)) != 0;
    final hasOutput = (outMask & (1 << channel)) != 0;
    final orphaned = hasOutput && !usageNeededAfter[channel];

    final bgColor = _cellColor(levelBefore, channel);

    // If used => label with condensed channel # (JS style)
    final label = isUsed ? _condensedChannelLabel(channel) : '';

    return Container(
      width: _cellWidth,
      height: _cellHeight,
      alignment: Alignment.center,
      color: bgColor,
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          //color: orphaned ? Colors.orange.shade800 : Colors.black,
          fontWeight: orphaned ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  //----------------------------------------------------------------------------
  // "Below" row cell => "+" or "┳" if output mask is set
  //----------------------------------------------------------------------------
  Widget _buildSignalBelowCell({
    required int slotIndex,
    required int channel,
    required int signalLevel,
    required RoutingInformation info,
  }) {
    final outMask = info.routingInfo[1];
    final replaceMask = info.routingInfo[2];
    final hasOutput = (outMask & (1 << channel)) != 0;
    final replaced = (replaceMask & (1 << channel)) != 0;
    final symbol = hasOutput ? (replaced ? '┳' : '+') : '';

    final bgColor = _cellColor(signalLevel, channel);

    return Container(
      width: _cellWidth,
      height: _cellHeight,
      alignment: Alignment.center,
      color: bgColor,
      child: Text(symbol, style: const TextStyle(fontSize: 13)),
    );
  }

  //----------------------------------------------------------------------------
  // netInputMask => combine inputMask & mappingMask if showSignals/mappings
  //----------------------------------------------------------------------------
  int _netInputMask(RoutingInformation r) {
    final inputMask = r.routingInfo[0];
    final mappingMask = r.routingInfo[5];
    if (showSignals && showMappings) return inputMask | mappingMask;
    if (showSignals) return inputMask;
    if (showMappings) return mappingMask;
    return 0;
  }

  //----------------------------------------------------------------------------
  // Colors mimic JS approach: level=0 => white/fcfcfc, level=1 => color1/darken, level=2 => color2/darken
  //----------------------------------------------------------------------------
  Color _cellColor(int level, int colIndex) {
    final isOdd = (colIndex % 2 == 1);
    if (level == 0) {
      return isOdd ? const Color(0xfffcfcfc) : const Color(0xffffffff);
    } else if (level == 1) {
      return isOdd ? _darken(color1) : color1;
    } else {
      return isOdd ? _darken(color2) : color2;
    }
  }

  Color _darken(Color c, [double factor = 0.9]) {
    return Color.from(
        alpha: c.a,
        red: max(0, c.r * factor),
        green: max(0, c.g * factor),
        blue: max(0, c.b * factor));
  }

  //----------------------------------------------------------------------------
  // Channel label for headers: I1..I12, O1..O8, A1..A8
  //----------------------------------------------------------------------------
  String _channelLabel(int ch) {
    if (ch <= 12) return 'I$ch';
    if (ch <= 20) return 'O${ch - 12}';
    return 'A${ch - 20}';
  }

  //----------------------------------------------------------------------------
  // Condensed label for slot usage: 1..12 => 1..12, 13..20 => 1..8, 21..28 => 1..8
  //----------------------------------------------------------------------------
  String _condensedChannelLabel(int ch) {
    int c = ch;
    if (c > 12) {
      c -= 12;
      if (c > 8) {
        c -= 8;
      }
    }
    return '$c';
  }
}
