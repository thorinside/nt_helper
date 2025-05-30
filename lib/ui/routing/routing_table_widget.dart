import 'package:flutter/material.dart';
import 'package:nt_helper/models/routing_information.dart';
import 'package:nt_helper/util/routing_analyzer.dart';

class RoutingTableWidget extends StatelessWidget {
  final List<RoutingInformation> routing;
  final Color color1;
  final Color color2;
  final bool showSignals;
  final bool showMappings;

  static const double _cellWidth = 32;
  static const double _cellHeight = 32;

  const RoutingTableWidget({
    super.key,
    required this.routing,
    this.color1 = const Color(0xffffc000), // Golden
    this.color2 = const Color(0xff40c0ff), // Light Blue
    this.showSignals = true,
    this.showMappings = false,
  });

  @override
  Widget build(BuildContext context) {
    final analyzer = RoutingAnalyzer(
      routing: routing,
      showSignals: showSignals,
      showMappings: showMappings,
    );

    final slotCount = routing.length;
    final signals = analyzer.signals; // From analyzer
    final usageNeeded = analyzer.usageNeeded; // From analyzer

    final allRows = <TableRow>[];
    allRows.add(_buildHeaderRow());

    for (int s = 0; s < slotCount; s++) {
      final info = routing[s];
      final rowBefore = signals[s];
      final rowAfter = signals[s + 1];

      allRows.add(
        TableRow(
          children: [
            _buildSlotCell('', slotName: false),
            for (int ch = 1; ch <= 28; ch++)
              _buildSignalAboveCell(
                slotIndex: s,
                channel: ch,
                signalLevel: rowBefore[ch],
                info: info,
                analyzer: analyzer, // Pass analyzer instance
              ),
          ],
        ),
      );

      allRows.add(
        TableRow(
          children: [
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

    allRows.add(_buildHeaderRow());

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

    return Row(
      children: [
        Table(
          border: TableBorder(
            left: BorderSide.none,
            right: BorderSide(color: Colors.grey.shade300),
            verticalInside: BorderSide(color: Colors.grey.shade300),
            horizontalInside: BorderSide(color: Colors.grey.shade300),
          ),
          columnWidths: const {
            0: IntrinsicColumnWidth(),
          },
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: pinnedColumnRows,
        ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Table(
              border: TableBorder(
                verticalInside: BorderSide(color: Colors.grey.shade300),
                horizontalInside: BorderSide(color: Colors.grey.shade300),
              ),
              columnWidths: {
                for (int i = 0; i < 28; i++) // 28 channels for the main table
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
      width:
          (text == 'Algorithm') ? null : _cellWidth, // Pinned col can auto-size
      height: _cellHeight,
      padding: (text == 'Algorithm')
          ? const EdgeInsets.symmetric(horizontal: 4)
          : null,
      child: Text(
        text,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildSlotCell(String text, {required bool slotName}) {
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

  Widget _buildSignalAboveCell({
    required int slotIndex,
    required int channel,
    required int signalLevel,
    required RoutingInformation info,
    required RoutingAnalyzer analyzer, // Analyzer instance passed here
  }) {
    final inMask = analyzer.getNetInputMask(info); // Use analyzer
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
          fontWeight: orphaned ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

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
    return Color.fromRGBO(
      (c.red * factor).round().clamp(0, 255),
      (c.green * factor).round().clamp(0, 255),
      (c.blue * factor).round().clamp(0, 255),
      1.0,
    );
  }

  String _channelLabel(int ch) {
    if (ch <= 12) return 'I$ch';
    if (ch <= 20) return 'O${ch - 12}';
    return 'A${ch - 20}';
  }

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
