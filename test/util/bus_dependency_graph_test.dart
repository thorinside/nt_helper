import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/models/connection.dart';
import 'package:nt_helper/util/bus_dependency_graph.dart';

void main() {
  group('BusDependencyGraph', () {
    late BusDependencyGraph graph;

    setUp(() {
      graph = BusDependencyGraph();
    });

    test('should track bus readers correctly', () {
      final connection = Connection(
        id: 'test_connection',
        sourceAlgorithmIndex: 0,
        sourcePortId: 'out',
        targetAlgorithmIndex: 1,
        targetPortId: 'in',
        assignedBus: 21,
        replaceMode: false,
      );
      
      graph.addConnection(connection);
      
      expect(graph.getBusReaders(21), contains(1));
      expect(graph.getBusWriters(21), contains(0));
    });

    test('should track bus writers correctly', () {
      final connection = Connection(
        id: 'test_connection',
        sourceAlgorithmIndex: 2,
        sourcePortId: 'output',
        targetAlgorithmIndex: 3,
        targetPortId: 'input',
        assignedBus: 22,
        replaceMode: false,
      );
      
      graph.addConnection(connection);
      
      expect(graph.getBusWriters(22), contains(2));
      expect(graph.getBusReaders(22), contains(3));
    });

    test('should identify when bus can be safely replaced', () {
      // Slot 0 writes to bus 21
      // Slot 1 reads bus 21 and wants to replace it
      // This should be safe since slot 1 comes after slot 0
      final connection1 = Connection(
        id: 'conn1',
        sourceAlgorithmIndex: 0,
        sourcePortId: 'out',
        targetAlgorithmIndex: 1,
        targetPortId: 'in',
        assignedBus: 21,
        replaceMode: false,
      );
      
      graph.addConnection(connection1);
      
      expect(graph.canSafelyReplace(21, atSlot: 1), isTrue);
    });

    test('should identify unsafe replacement scenarios', () {
      // Slot 0 writes to bus 21
      // Slot 1 wants to replace bus 21
      // Slot 2 still needs to read original signal - UNSAFE!
      final connection1 = Connection(
        id: 'conn1',
        sourceAlgorithmIndex: 0,
        sourcePortId: 'out',
        targetAlgorithmIndex: 2, // Target in slot 2
        targetPortId: 'in',
        assignedBus: 21,
        replaceMode: false,
      );
      
      graph.addConnection(connection1);
      
      expect(graph.canSafelyReplace(21, atSlot: 1), isFalse);
    });

    test('should find available buses after replacement', () {
      // Set up a scenario where bus 21 becomes available after replacement
      final connection1 = Connection(
        id: 'conn1',
        sourceAlgorithmIndex: 0,
        sourcePortId: 'out',
        targetAlgorithmIndex: 1,
        targetPortId: 'in',
        assignedBus: 21,
        replaceMode: false,
      );
      
      final connection2 = Connection(
        id: 'conn2',
        sourceAlgorithmIndex: 1,
        sourcePortId: 'out',
        targetAlgorithmIndex: 2,
        targetPortId: 'in',
        assignedBus: 21,
        replaceMode: true, // Replace mode frees the bus
      );
      
      graph.addConnection(connection1);
      graph.addConnection(connection2);
      
      expect(graph.getAvailableBusesAfterSlot(1), contains(21));
    });

    test('should find all replacement opportunities', () {
      // Create a complex scenario with multiple replacement opportunities
      final connections = [
        Connection(
          id: 'conn1',
          sourceAlgorithmIndex: 0,
          sourcePortId: 'out',
          targetAlgorithmIndex: 1,
          targetPortId: 'in',
          assignedBus: 21,
          replaceMode: false,
        ),
        Connection(
          id: 'conn2',
          sourceAlgorithmIndex: 1,
          sourcePortId: 'out',
          targetAlgorithmIndex: 2,
          targetPortId: 'in',
          assignedBus: 22,
          replaceMode: false,
        ),
      ];
      
      for (final conn in connections) {
        graph.addConnection(conn);
      }
      
      final opportunities = graph.findReplacementOpportunities();
      
      expect(opportunities, isNotEmpty);
      expect(opportunities.first.bus, isIn([21, 22]));
    });

    test('should handle physical I/O nodes correctly', () {
      // Physical input connection (algorithmIndex -2)
      final physicalInputConn = Connection(
        id: 'physical_in',
        sourceAlgorithmIndex: -2,
        sourcePortId: 'physical_input_1',
        targetAlgorithmIndex: 0,
        targetPortId: 'in',
        assignedBus: 1,
        replaceMode: false,
      );
      
      graph.addConnection(physicalInputConn);
      
      // Physical nodes don't affect replacement safety
      expect(graph.canSafelyReplace(1, atSlot: 0), isTrue);
    });

    test('should track bus lifetimes accurately', () {
      final connection = Connection(
        id: 'lifetime_test',
        sourceAlgorithmIndex: 0,
        sourcePortId: 'out',
        targetAlgorithmIndex: 2,
        targetPortId: 'in',
        assignedBus: 21,
        replaceMode: false,
      );
      
      graph.addConnection(connection);
      
      final lifetime = graph.getBusLifetime(21);
      expect(lifetime.startSlot, equals(0));
      expect(lifetime.endSlot, equals(2));
    });

    test('should detect circular dependencies', () {
      // This would be invalid but we should handle it gracefully
      final connection1 = Connection(
        id: 'circular1',
        sourceAlgorithmIndex: 0,
        sourcePortId: 'out',
        targetAlgorithmIndex: 1,
        targetPortId: 'in',
        assignedBus: 21,
        replaceMode: false,
      );
      
      final connection2 = Connection(
        id: 'circular2',
        sourceAlgorithmIndex: 1,
        sourcePortId: 'out',
        targetAlgorithmIndex: 0,
        targetPortId: 'in2',
        assignedBus: 22,
        replaceMode: false,
      );
      
      graph.addConnection(connection1);
      graph.addConnection(connection2);
      
      // Should handle gracefully without throwing
      expect(() => graph.findReplacementOpportunities(), returnsNormally);
    });

    test('should handle empty graph', () {
      expect(graph.getBusReaders(21), isEmpty);
      expect(graph.getBusWriters(21), isEmpty);
      expect(graph.canSafelyReplace(21, atSlot: 0), isTrue);
      expect(graph.getAvailableBusesAfterSlot(0), isEmpty);
      expect(graph.findReplacementOpportunities(), isEmpty);
    });

    test('should handle maximum slot count', () {
      // Test with 32 algorithms (maximum)
      final connections = <Connection>[];
      for (int i = 0; i < 31; i++) {
        connections.add(Connection(
          id: 'max_test_$i',
          sourceAlgorithmIndex: i,
          sourcePortId: 'out',
          targetAlgorithmIndex: i + 1,
          targetPortId: 'in',
          assignedBus: 21 + (i % 8), // Cycle through AUX buses
          replaceMode: false,
        ));
      }
      
      for (final conn in connections) {
        graph.addConnection(conn);
      }
      
      // Should handle large graphs efficiently
      expect(() => graph.findReplacementOpportunities(), returnsNormally);
    });
  });

  group('BusUsage', () {
    test('should track reads and writes separately', () {
      final usage = BusUsage();
      
      usage.addRead(5);
      usage.addWrite(10);
      usage.setReplaceMode(10, true);
      
      expect(usage.reads, contains(5));
      expect(usage.writes, contains(10));
      expect(usage.getReplaceMode(10), isTrue);
    });
  });

  group('ReplacementOpportunity', () {
    test('should be created with correct properties', () {
      final opportunity = ReplacementOpportunity(
        bus: 21,
        slot: 1,
        freedAfterSlot: 1,
        potentialReusers: [2, 3, 4],
      );
      
      expect(opportunity.bus, equals(21));
      expect(opportunity.slot, equals(1));
      expect(opportunity.freedAfterSlot, equals(1));
      expect(opportunity.potentialReusers, equals([2, 3, 4]));
    });
  });

  group('BusLifetime', () {
    test('should calculate lifetime correctly', () {
      final lifetime = BusLifetime(
        bus: 21,
        startSlot: 0,
        endSlot: 3,
        canReuse: true,
      );
      
      expect(lifetime.bus, equals(21));
      expect(lifetime.startSlot, equals(0));
      expect(lifetime.endSlot, equals(3));
      expect(lifetime.canReuse, isTrue);
      expect(lifetime.duration, equals(4)); // 0, 1, 2, 3 = 4 slots
    });
  });
}