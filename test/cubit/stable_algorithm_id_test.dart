import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/cubit/routing_editor_cubit.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('Stable Algorithm ID Generation', () {
    test('generates stable algorithm IDs without slot index', () {
      // Create test algorithms with GUIDs
      final algorithm1 = Algorithm(
        algorithmIndex: 0,
        guid: 'abc123',
        name: 'Test Algorithm 1',
      );

      final algorithm2 = Algorithm(
        algorithmIndex: 1,
        guid: 'xyz789',
        name: 'Test Algorithm 2',
      );

      // Create slots with algorithms
      final slots = [
        Slot(
          algorithm: algorithm1,
          routing: RoutingInfo(algorithmIndex: 0, routingInfo: []),
          pages: ParameterPages(algorithmIndex: 0, pages: []),
          parameters: const [],
          values: const [],
          enums: const [],
          mappings: const [],
          valueStrings: const [],
        ),
        Slot(
          algorithm: algorithm2,
          routing: RoutingInfo(algorithmIndex: 0, routingInfo: []),
          pages: ParameterPages(algorithmIndex: 0, pages: []),
          parameters: const [],
          values: const [],
          enums: const [],
          mappings: const [],
          valueStrings: const [],
        ),
      ];

      // Test the static method directly
      final cubit = RoutingEditorCubit(null); // We won't use the cubit lifecycle
      final algorithmIds = cubit.generateStableAlgorithmIds(slots);

      // Check that IDs are based on GUID and instance count, not slot index
      expect(algorithmIds.length, 2);
      expect(algorithmIds[0], 'algo_abc123_1');
      expect(algorithmIds[1], 'algo_xyz789_1');

      // IDs should not contain slot index '0' or '1'
      expect(algorithmIds[0].contains('_0'), false);
      expect(algorithmIds[1].contains('_1_xyz'), false);
    });

    test('handles duplicate algorithms with instance counters', () {
      final algorithm = Algorithm(
        algorithmIndex: 0,
        guid: 'same123',
        name: 'Duplicate Algorithm',
      );

      final slots = [
        Slot(
          algorithm: algorithm,
          routing: RoutingInfo(algorithmIndex: 0, routingInfo: []),
          pages: ParameterPages(algorithmIndex: 0, pages: []),
          parameters: const [],
          values: const [],
          enums: const [],
          mappings: const [],
          valueStrings: const [],
        ),
        Slot(
          algorithm: algorithm,
          routing: RoutingInfo(algorithmIndex: 0, routingInfo: []),
          pages: ParameterPages(algorithmIndex: 0, pages: []),
          parameters: const [],
          values: const [],
          enums: const [],
          mappings: const [],
          valueStrings: const [],
        ),
        Slot(
          algorithm: algorithm,
          routing: RoutingInfo(algorithmIndex: 0, routingInfo: []),
          pages: ParameterPages(algorithmIndex: 0, pages: []),
          parameters: const [],
          values: const [],
          enums: const [],
          mappings: const [],
          valueStrings: const [],
        ),
      ];

      final cubit = RoutingEditorCubit(null);
      final algorithmIds = cubit.generateStableAlgorithmIds(slots);

      // Each instance should get a unique counter
      expect(algorithmIds.length, 3);
      expect(algorithmIds[0], 'algo_same123_1');
      expect(algorithmIds[1], 'algo_same123_2');
      expect(algorithmIds[2], 'algo_same123_3');
    });

    test('algorithm IDs remain stable when algorithms are reordered', () {
      final algorithm1 = Algorithm(
        algorithmIndex: 0,
        guid: 'aaa111',
        name: 'Algorithm A',
      );

      final algorithm2 = Algorithm(
        algorithmIndex: 1,
        guid: 'bbb222',
        name: 'Algorithm B',
      );

      final createSlot = (Algorithm algo) => Slot(
            algorithm: algo,
            routing: RoutingInfo(algorithmIndex: 0, routingInfo: []),
            pages: ParameterPages(algorithmIndex: 0, pages: []),
            parameters: const [],
            values: const [],
            enums: const [],
            mappings: const [],
            valueStrings: const [],
          );

      // Original order
      final slotsOriginal = [
        createSlot(algorithm1),
        createSlot(algorithm2),
      ];

      final cubit = RoutingEditorCubit(null);
      final idsOriginal = cubit.generateStableAlgorithmIds(slotsOriginal);

      // Swapped order (simulating move up/down)
      final slotsSwapped = [
        createSlot(algorithm2),
        createSlot(algorithm1),
      ];

      final idsSwapped = cubit.generateStableAlgorithmIds(slotsSwapped);

      // Algorithm IDs should remain the same regardless of slot position
      expect(idsOriginal[0], 'algo_aaa111_1');
      expect(idsOriginal[1], 'algo_bbb222_1');
      expect(idsSwapped[0], 'algo_bbb222_1'); // B is now in slot 0
      expect(idsSwapped[1], 'algo_aaa111_1'); // A is now in slot 1
    });

    test('generates stable port IDs using algorithm UUID', () {
      final algorithmId = 'algo_test456_1';

      final cubit = RoutingEditorCubit(null);
      // Generate port ID
      final portId = cubit.generatePortId(
        algorithmId: algorithmId,
        parameterNumber: 23,
        portType: 'output',
      );

      // Port ID should be simple and stable
      expect(portId, 'algo_test456_1_port_23');
    });
  });
}