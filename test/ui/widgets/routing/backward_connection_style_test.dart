import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/core/routing/models/connection.dart';
import 'package:nt_helper/ui/widgets/routing/connection_painter.dart';

ConnectionData _connData({
  String id = 'c',
  bool isBackwardEdge = false,
  bool isPartial = false,
  bool isGhost = false,
  bool isSelected = false,
  ConnectionType connectionType = ConnectionType.algorithmToAlgorithm,
}) {
  return ConnectionData(
    connection: Connection(
      id: id,
      sourcePortId: 'src',
      destinationPortId: 'dst',
      connectionType: connectionType,
      isBackwardEdge: isBackwardEdge,
      isPartial: isPartial,
      isGhostConnection: isGhost,
    ),
    sourcePosition: const Offset(0, 0),
    destinationPosition: const Offset(100, 0),
    isSelected: isSelected,
  );
}

void main() {
  group('Backward connection styling', () {
    test('kBackwardEdgeColor is the agreed bright orange (#FF8800)', () {
      expect(kBackwardEdgeColor, const Color(0xFFFF8800));
    });

    group('classifyVisualType precedence', () {
      test('backward edge classifies as invalid', () {
        expect(
          ConnectionPainter.classifyVisualType(
            _connData(isBackwardEdge: true),
          ),
          ConnectionVisualType.invalid,
        );
      });

      test('partial backward edge classifies as partial (not invalid)', () {
        expect(
          ConnectionPainter.classifyVisualType(
            _connData(isBackwardEdge: true, isPartial: true),
          ),
          ConnectionVisualType.partial,
        );
      });

      test('selected backward edge classifies as selected', () {
        expect(
          ConnectionPainter.classifyVisualType(
            _connData(isBackwardEdge: true, isSelected: true),
          ),
          ConnectionVisualType.selected,
        );
      });

      test('ghost connection classifies as ghost', () {
        expect(
          ConnectionPainter.classifyVisualType(_connData(isGhost: true)),
          ConnectionVisualType.ghost,
        );
      });

      test('plain connection classifies as regular', () {
        expect(
          ConnectionPainter.classifyVisualType(_connData()),
          ConnectionVisualType.regular,
        );
      });
    });

    group('resolved style color', () {
      ConnectionPainter painterFor(ConnectionData conn, {ThemeData? theme}) {
        return ConnectionPainter(
          connections: [conn],
          theme: theme ?? ThemeData.light(),
          showLabels: false,
        );
      }

      test('backward edge uses kBackwardEdgeColor in light theme', () {
        final conn = _connData(isBackwardEdge: true);
        final painter = painterFor(conn);
        expect(
          painter.debugResolveStyleColor(conn).toARGB32(),
          kBackwardEdgeColor.toARGB32(),
        );
      });

      test('backward edge uses kBackwardEdgeColor in dark theme', () {
        final conn = _connData(isBackwardEdge: true);
        final painter = painterFor(conn, theme: ThemeData.dark());
        expect(
          painter.debugResolveStyleColor(conn).toARGB32(),
          kBackwardEdgeColor.toARGB32(),
        );
      });
    });
  });
}
