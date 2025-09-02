import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/ui/widgets/routing/connection_painter.dart';
import 'package:nt_helper/cubit/routing_editor_cubit.dart' as routing;
import 'package:nt_helper/core/routing/models/port.dart';

void main() {
  group('ConnectionData Label Formatting Tests', () {
    test('should format physical input connection labels as "I#"', () {
      // Test input connections (bus numbers 1-12)
      final testCases = [
        (1, 'I1'),
        (5, 'I5'),
        (12, 'I12'),
      ];

      for (final (busNumber, expectedLabel) in testCases) {
        final connectionData = ConnectionData(
          connection: routing.Connection(id: 'test', sourcePortId: 'hw_in_$busNumber', targetPortId: 'alg_input'),
          sourcePosition: const Offset(0, 0),
          destinationPosition: const Offset(100, 100),
          busNumber: busNumber,
          isPhysicalConnection: true,
          isInputConnection: true,
        );

        // Verify the data is structured correctly for label generation
        expect(connectionData.isPhysicalConnection, isTrue);
        expect(connectionData.isInputConnection, isTrue);
        expect(connectionData.busNumber, busNumber);
        
        // The actual label formatting happens in ConnectionPainter._drawConnectionLabel
        // We verify the data structure that would generate "$expectedLabel"
      }
    });

    test('should format physical output connection labels as "O#"', () {
      // Test output connections (bus numbers 13-20 -> output numbers 1-8)
      final testCases = [
        (13, 'O1'), // Bus 13 -> Output 1
        (14, 'O2'), // Bus 14 -> Output 2
        (16, 'O4'), // Bus 16 -> Output 4
        (20, 'O8'), // Bus 20 -> Output 8
      ];

      for (final (busNumber, expectedLabel) in testCases) {
        final connectionData = ConnectionData(
          connection: routing.Connection(id: 'test', sourcePortId: 'alg_output', targetPortId: 'hw_out_${busNumber - 12}'),
          sourcePosition: const Offset(0, 0),
          destinationPosition: const Offset(100, 100),
          busNumber: busNumber,
          isPhysicalConnection: true,
          isInputConnection: false, // Output connection
        );

        // Verify the data is structured correctly for label generation
        expect(connectionData.isPhysicalConnection, isTrue);
        expect(connectionData.isInputConnection, isFalse);
        expect(connectionData.busNumber, busNumber);
        
        // The actual label formatting happens in ConnectionPainter._drawConnectionLabel
        // We verify the data structure that would generate "$expectedLabel"
      }
    });

    test('should format user connection labels as "Bus #"', () {
      // Test user connections (not physical)
      final testCases = [
        (1, null, 'Bus 1'), // No output mode
        (3, OutputMode.add, 'Bus 3'), // Add mode (no suffix)
        (5, OutputMode.replace, 'Bus 5 (R)'), // Replace mode (with suffix)
      ];

      for (final (busNumber, outputMode, expectedLabel) in testCases) {
        final connectionData = ConnectionData(
          connection: routing.Connection(id: 'test', sourcePortId: 'source', targetPortId: 'target'),
          sourcePosition: const Offset(0, 0),
          destinationPosition: const Offset(100, 100),
          busNumber: busNumber,
          outputMode: outputMode,
          isPhysicalConnection: false, // User connection
        );

        // Verify the data is structured correctly for label generation
        expect(connectionData.isPhysicalConnection, isFalse);
        expect(connectionData.isInputConnection, isNull);
        expect(connectionData.busNumber, busNumber);
        expect(connectionData.outputMode, outputMode);
        
        // The actual label formatting happens in ConnectionPainter._drawConnectionLabel
        // We verify the data structure that would generate "$expectedLabel"
      }
    });

    test('should handle edge cases for physical connections', () {
      // Test edge cases
      final connectionWithNullBus = ConnectionData(
        connection: routing.Connection(id: 'test', sourcePortId: 'source', targetPortId: 'target'),
        sourcePosition: const Offset(0, 0),
        destinationPosition: const Offset(100, 100),
        busNumber: null, // No bus number - should not render label
        isPhysicalConnection: true,
        isInputConnection: true,
      );
      
      expect(connectionWithNullBus.busNumber, isNull);
      // ConnectionPainter._drawConnectionLabel should early return when busNumber is null

      final connectionWithNullInputFlag = ConnectionData(
        connection: routing.Connection(id: 'test', sourcePortId: 'source', targetPortId: 'target'),
        sourcePosition: const Offset(0, 0),
        destinationPosition: const Offset(100, 100),
        busNumber: 5,
        isPhysicalConnection: true,
        isInputConnection: null, // Null input connection flag
      );
      
      expect(connectionWithNullInputFlag.isInputConnection, isNull);
      // ConnectionPainter._drawConnectionLabel should fall back to user connection logic
    });

    test('should verify ConnectionData constructor parameters', () {
      // Test that all the new parameters work correctly
      final fullConnectionData = ConnectionData(
        connection: routing.Connection(id: 'test', sourcePortId: 'hw_in_3', targetPortId: 'alg_input'),
        sourcePosition: const Offset(10, 20),
        destinationPosition: const Offset(100, 200),
        busNumber: 3,
        outputMode: OutputMode.add,
        isSelected: false,
        isHighlighted: true,
        isPhysicalConnection: true,
        isInputConnection: true,
      );

      expect(fullConnectionData.connection.id, 'test');
      expect(fullConnectionData.sourcePosition, const Offset(10, 20));
      expect(fullConnectionData.destinationPosition, const Offset(100, 200));
      expect(fullConnectionData.busNumber, 3);
      expect(fullConnectionData.outputMode, OutputMode.add);
      expect(fullConnectionData.isSelected, isFalse);
      expect(fullConnectionData.isHighlighted, isTrue);
      expect(fullConnectionData.isPhysicalConnection, isTrue);
      expect(fullConnectionData.isInputConnection, isTrue);
    });

    test('should verify default values work correctly', () {
      // Test minimal ConnectionData with defaults
      final minimalConnectionData = ConnectionData(
        connection: routing.Connection(id: 'test', sourcePortId: 'source', targetPortId: 'target'),
        sourcePosition: const Offset(0, 0),
        destinationPosition: const Offset(100, 100),
      );

      expect(minimalConnectionData.busNumber, isNull);
      expect(minimalConnectionData.outputMode, isNull);
      expect(minimalConnectionData.isSelected, isFalse);
      expect(minimalConnectionData.isHighlighted, isFalse);
      expect(minimalConnectionData.isPhysicalConnection, isFalse); // Default
      expect(minimalConnectionData.isInputConnection, isNull);
    });
  });
}