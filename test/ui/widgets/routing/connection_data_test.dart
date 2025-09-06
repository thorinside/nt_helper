import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/core/routing/models/connection.dart';
import 'package:nt_helper/ui/widgets/routing/connection_painter.dart';

void main() {
  group('ConnectionData', () {
    late Connection mockConnection;

    setUp(() {
      mockConnection = Connection(
        id: 'test_connection',
        sourcePortId: 'source_port',
        destinationPortId: 'destination_port',
        connectionType: ConnectionType.algorithmToAlgorithm,
      );
    });

    test('should create ConnectionData with hover callbacks', () {
      bool hoverCalled = false;
      bool tapCalled = false;

      final connectionData = ConnectionData(
        connection: mockConnection,
        sourcePosition: const Offset(10, 20),
        destinationPosition: const Offset(100, 200),
        onLabelHover: (isHovering) {
          hoverCalled = true;
        },
        onLabelTap: () {
          tapCalled = true;
        },
      );

      expect(connectionData.connection, equals(mockConnection));
      expect(connectionData.sourcePosition, equals(const Offset(10, 20)));
      expect(connectionData.destinationPosition, equals(const Offset(100, 200)));
      expect(connectionData.onLabelHover, isNotNull);
      expect(connectionData.onLabelTap, isNotNull);

      // Test callback invocation
      connectionData.onLabelHover!(true);
      connectionData.onLabelTap!();

      expect(hoverCalled, isTrue);
      expect(tapCalled, isTrue);
    });

    test('should create ConnectionData without hover callbacks', () {
      final connectionData = ConnectionData(
        connection: mockConnection,
        sourcePosition: const Offset(10, 20),
        destinationPosition: const Offset(100, 200),
      );

      expect(connectionData.onLabelHover, isNull);
      expect(connectionData.onLabelTap, isNull);
    });
  });
}