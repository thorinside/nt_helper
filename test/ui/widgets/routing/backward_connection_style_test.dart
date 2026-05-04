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
  });
}
