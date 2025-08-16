import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/models/connection.dart';
import 'package:nt_helper/services/auto_routing_service.dart';

@GenerateMocks([DistingCubit])
import 'auto_routing_service_test.mocks.dart';

void main() {
  group('AutoRoutingService', () {
    late MockDistingCubit mockCubit;
    late AutoRoutingService service;

    setUp(() {
      mockCubit = MockDistingCubit();
      service = AutoRoutingService(mockCubit);
    });

    test('should find available aux bus when all are free', () {
      final existingConnections = <Connection>[];
      
      final result = service.findAvailableAuxBus(existingConnections);
      
      expect(result, equals(21)); // First aux bus
    });

    test('should find next available aux bus when some are used', () {
      final existingConnections = [
        Connection(
          id: 'test1',
          sourceAlgorithmIndex: 0,
          sourcePortId: 'out',
          targetAlgorithmIndex: 1,
          targetPortId: 'in',
          assignedBus: 21,
          replaceMode: true,
          isValid: true,
        ),
        Connection(
          id: 'test2',
          sourceAlgorithmIndex: 2,
          sourcePortId: 'out',
          targetAlgorithmIndex: 3,
          targetPortId: 'in',
          assignedBus: 22,
          replaceMode: true,
          isValid: true,
        ),
      ];
      
      final result = service.findAvailableAuxBus(existingConnections);
      
      expect(result, equals(23)); // Next available aux bus
    });

    test('should use output buses when aux buses are full', () {
      final existingConnections = <Connection>[];
      
      // Fill all aux buses (21-28)
      for (int i = 21; i <= 28; i++) {
        existingConnections.add(Connection(
          id: 'aux_$i',
          sourceAlgorithmIndex: i - 21,
          sourcePortId: 'out',
          targetAlgorithmIndex: i - 20,
          targetPortId: 'in',
          assignedBus: i,
          replaceMode: true,
          isValid: true,
        ));
      }
      
      final result = service.findAvailableAuxBus(existingConnections);
      
      expect(result, equals(13)); // First output bus
    });

    test('should throw exception when all buses are used', () {
      final existingConnections = <Connection>[];
      
      // Fill all buses (1-28)
      for (int i = 1; i <= 28; i++) {
        existingConnections.add(Connection(
          id: 'bus_$i',
          sourceAlgorithmIndex: i,
          sourcePortId: 'out',
          targetAlgorithmIndex: i + 1,
          targetPortId: 'in',
          assignedBus: i,
          replaceMode: true,
          isValid: true,
        ));
      }
      
      expect(
        () => service.findAvailableAuxBus(existingConnections),
        throwsA(isA<InsufficientBusesException>()),
      );
    });

    test('should assign bus for connection', () async {
      final existingConnections = <Connection>[];
      
      final result = await service.assignBusForConnection(
        sourceAlgorithmIndex: 0,
        sourcePortId: 'audio_out',
        targetAlgorithmIndex: 1,
        targetPortId: 'audio_in',
        existingConnections: existingConnections,
      );
      
      expect(result.sourceBus, equals(21)); // First aux bus
      expect(result.replaceMode, equals(true));
      expect(result.edgeLabel, equals('A1 R'));
      expect(result.parameterUpdates, hasLength(2));
      expect(result.parameterUpdates[0].algorithmIndex, equals(0));
      expect(result.parameterUpdates[1].algorithmIndex, equals(1));
    });

    test('should generate correct edge labels for different buses', () async {
      // Test with different existing connections to force different bus assignments
      final result1 = await service.assignBusForConnection(
        sourceAlgorithmIndex: 0,
        sourcePortId: 'out',
        targetAlgorithmIndex: 1,
        targetPortId: 'in',
        existingConnections: [],
      );
      
      expect(result1.edgeLabel, equals('A1 R')); // First aux bus with replace mode
    });
  });
}