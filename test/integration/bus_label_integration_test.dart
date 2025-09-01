import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/ui/widgets/routing/connection_painter.dart';
import 'package:nt_helper/cubit/routing_editor_cubit.dart' as routing;
import 'package:nt_helper/core/routing/models/connection_metadata.dart';

void main() {
  group('Bus Label Integration', () {
    group('Bus Number Propagation', () {
      test('should propagate bus number from ConnectionMetadata to ConnectionData', () {
        // Create a connection with metadata
        final connection = routing.Connection(
          id: 'test_connection',
          sourcePortId: 'algo1_out',
          targetPortId: 'algo2_in',
          properties: {
            'busNumber': 5,
          },
        );

        // Create ConnectionData with bus number
        final connectionData = ConnectionData(
          connection: connection,
          sourcePosition: const Offset(100, 100),
          destinationPosition: const Offset(300, 100),
          busNumber: 5,
        );

        expect(connectionData.busNumber, 5);
        expect(ConnectionPainter.formatBusLabel(connectionData.busNumber), 'I5');
      });

      test('should handle input bus connections (1-12)', () {
        for (int bus = 1; bus <= 12; bus++) {
          final connection = routing.Connection(
            id: 'input_connection_$bus',
            sourcePortId: 'physical_input_$bus',
            targetPortId: 'algo_in_$bus',
            properties: {
              'busNumber': bus,
            },
          );

          final connectionData = ConnectionData(
            connection: connection,
            sourcePosition: Offset(50.0 * bus, 100),
            destinationPosition: Offset(50.0 * bus, 200),
            busNumber: bus,
            isPhysicalConnection: true,
            isInputConnection: true,
          );

          final label = ConnectionPainter.formatBusLabel(connectionData.busNumber);
          expect(label, 'I$bus');
        }
      });

      test('should handle output bus connections (13-20)', () {
        for (int bus = 13; bus <= 20; bus++) {
          final connection = routing.Connection(
            id: 'output_connection_$bus',
            sourcePortId: 'algo_out_$bus',
            targetPortId: 'physical_output_$bus',
            properties: {
              'busNumber': bus,
            },
          );

          final connectionData = ConnectionData(
            connection: connection,
            sourcePosition: Offset(50.0 * bus, 100),
            destinationPosition: Offset(50.0 * bus, 200),
            busNumber: bus,
            isPhysicalConnection: true,
            isInputConnection: false,
          );

          final outputNumber = bus - 12;
          final label = ConnectionPainter.formatBusLabel(connectionData.busNumber);
          expect(label, 'O$outputNumber');
        }
      });

      test('should handle auxiliary bus connections (21-28)', () {
        for (int bus = 21; bus <= 28; bus++) {
          final connection = routing.Connection(
            id: 'aux_connection_$bus',
            sourcePortId: 'algo1_out',
            targetPortId: 'algo2_in',
            properties: {
              'busNumber': bus,
            },
          );

          final connectionData = ConnectionData(
            connection: connection,
            sourcePosition: Offset(50.0 * bus, 100),
            destinationPosition: Offset(50.0 * bus, 200),
            busNumber: bus,
            isPhysicalConnection: false,
          );

          final auxNumber = bus - 20;
          final label = ConnectionPainter.formatBusLabel(connectionData.busNumber);
          expect(label, 'A$auxNumber');
        }
      });

      test('should handle connections with no bus number', () {
        final connection = routing.Connection(
          id: 'no_bus_connection',
          sourcePortId: 'algo1_out',
          targetPortId: 'algo2_in',
        );

        final connectionData = ConnectionData(
          connection: connection,
          sourcePosition: const Offset(100, 100),
          destinationPosition: const Offset(300, 100),
          busNumber: null,
        );

        expect(connectionData.busNumber, isNull);
        expect(ConnectionPainter.formatBusLabel(connectionData.busNumber), '');
      });
    });

    group('ConnectionMetadata Integration', () {
      test('should extract bus number from ConnectionMetadata', () {
        final metadata = ConnectionMetadata(
          connectionClass: ConnectionClass.algorithm,
          busNumber: 15,
          signalType: SignalType.audio,
          sourceAlgorithmId: 'algo1',
          targetAlgorithmId: 'algo2',
        );

        expect(metadata.busNumber, 15);
        
        // Format as output bus (15 is in the 13-20 range)
        final label = ConnectionPainter.formatBusLabel(metadata.busNumber);
        expect(label, 'O3'); // Bus 15 = Output 3
      });

      test('should handle hardware connection metadata', () {
        final inputMetadata = ConnectionMetadata(
          connectionClass: ConnectionClass.hardware,
          busNumber: 3,
          signalType: SignalType.cv,
        );

        expect(inputMetadata.busNumber, 3);
        expect(ConnectionPainter.formatBusLabel(inputMetadata.busNumber), 'I3');

        final outputMetadata = ConnectionMetadata(
          connectionClass: ConnectionClass.hardware,
          busNumber: 18,
          signalType: SignalType.audio,
        );

        expect(outputMetadata.busNumber, 18);
        expect(ConnectionPainter.formatBusLabel(outputMetadata.busNumber), 'O6');
      });

      test('should handle algorithm connection metadata', () {
        final algoMetadata = ConnectionMetadata(
          connectionClass: ConnectionClass.algorithm,
          busNumber: 25,
          signalType: SignalType.gate,
          sourceAlgorithmId: 'source_algo',
          targetAlgorithmId: 'target_algo',
        );

        expect(algoMetadata.busNumber, 25);
        expect(ConnectionPainter.formatBusLabel(algoMetadata.busNumber), 'A5');
      });
    });
  });
}