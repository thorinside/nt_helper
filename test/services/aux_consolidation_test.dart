import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:nt_helper/cubit/node_routing_cubit.dart';
import 'package:nt_helper/cubit/node_routing_state.dart';
import 'package:nt_helper/models/connection.dart';
import 'package:nt_helper/services/auto_routing_service.dart';
import 'package:nt_helper/services/bus_tidy_optimizer.dart';

import 'bus_tidy_optimizer_test.mocks.dart';

@GenerateMocks([NodeRoutingCubit, AutoRoutingService])
void main() {
  // Configure Mockito to provide dummy values for sealed classes
  provideDummy<NodeRoutingState>(const NodeRoutingState.initial());
  
  group('Aux Bus Consolidation - Real Scenario', () {
    late MockNodeRoutingCubit mockCubit;
    late MockAutoRoutingService mockRoutingService;
    late BusTidyOptimizer optimizer;

    setUp(() {
      mockCubit = MockNodeRoutingCubit();
      mockRoutingService = MockAutoRoutingService();
      optimizer = BusTidyOptimizer(mockCubit, mockRoutingService);
    });

    test('should consolidate non-overlapping Aux buses from routing analysis', () async {
      // This represents the exact scenario from the routing analysis image
      // where we have multiple Aux buses with non-overlapping usage
      final connections = [
        // Lua Script (slot 1) outputs
        Connection(
          id: 'lua_to_vco_gate',
          sourceAlgorithmIndex: 1,
          sourcePortId: 'gate',
          targetAlgorithmIndex: 3,
          targetPortId: 'gate',
          assignedBus: 23, // A3
          replaceMode: false,
        ),
        Connection(
          id: 'lua_to_vco_voct',
          sourceAlgorithmIndex: 1,
          sourcePortId: 'voct',
          targetAlgorithmIndex: 3,
          targetPortId: 'pitch',
          assignedBus: 22, // A2
          replaceMode: false,
        ),
        
        // Envelope (slot 2) output
        Connection(
          id: 'env_to_vcf',
          sourceAlgorithmIndex: 2,
          sourcePortId: 'output',
          targetAlgorithmIndex: 4,
          targetPortId: 'resonance',
          assignedBus: 26, // A6
          replaceMode: false,
        ),
        
        // VCO (slot 3) outputs
        Connection(
          id: 'vco_to_vcf',
          sourceAlgorithmIndex: 3,
          sourcePortId: 'output',
          targetAlgorithmIndex: 4,
          targetPortId: 'audio',
          assignedBus: 25, // A5
          replaceMode: false,
        ),
        // Removed vco_wave_to_envelope as it violates execution order (3 → 2)
        
        // VCF (slot 4) output
        Connection(
          id: 'vcf_to_vca',
          sourceAlgorithmIndex: 4,
          sourcePortId: 'lowpass',
          targetAlgorithmIndex: 5,
          targetPortId: 'input',
          assignedBus: 27, // A7
          replaceMode: false,
        ),
        
        // Attenuverter (slot 6) output  
        Connection(
          id: 'atten_to_delay',
          sourceAlgorithmIndex: 6,
          sourcePortId: 'output',
          targetAlgorithmIndex: 8,
          targetPortId: 'input',
          assignedBus: 24, // A4 - reused after envelope reads it
          replaceMode: false,
        ),
        
        // Delay (slot 8) output
        Connection(
          id: 'delay_to_phaser',
          sourceAlgorithmIndex: 8,
          sourcePortId: 'output',
          targetAlgorithmIndex: 9,
          targetPortId: 'input',
          assignedBus: 25, // A5 - reused after VCF reads it
          replaceMode: false,
        ),
        
        // LFO (slot 7) output
        Connection(
          id: 'lfo_to_reverb',
          sourceAlgorithmIndex: 7,
          sourcePortId: 'output',
          targetAlgorithmIndex: 10,
          targetPortId: 'input',
          assignedBus: 28, // A8
          replaceMode: false,
        ),
      ];

      when(mockCubit.state).thenReturn(NodeRoutingState.loaded(
        nodePositions: const {},
        connections: connections,
        portLayouts: const {},
        connectedPorts: const {},
        algorithmNames: const {},
        portPositions: const {},
      ));

      debugPrint('\n=== TEST: Starting optimization ===');
      debugPrint('Original connections: ${connections.length}');
      final auxBuses = connections
          .where((c) => c.assignedBus >= 21 && c.assignedBus <= 28)
          .map((c) => c.assignedBus)
          .toSet()
          .toList()..sort();
      debugPrint('Original Aux buses in use: $auxBuses');
      
      final result = await optimizer.tidyConnections();

      // Debug output
      debugPrint('\n=== TEST: Optimization complete ===');
      debugPrint('Result success: ${result.success}');
      debugPrint('Buses freed: ${result.busesFreed}');
      debugPrint('Changes: ${result.changes.length}');
      for (final change in result.changes.values) {
        debugPrint('  ${change.connectionId}: bus ${change.oldBus} -> ${change.newBus}, replace: ${change.oldReplaceMode} -> ${change.newReplaceMode}');
      }
      
      expect(result.success, isTrue);
      expect(result.busesFreed, greaterThan(0), 
        reason: 'Should consolidate at least some Aux buses');
      
      // Should have moved connections to fewer buses
      final optimizedBuses = result.optimizedConnections
          .where((c) => c.assignedBus >= 21 && c.assignedBus <= 28)
          .map((c) => c.assignedBus)
          .toSet();
      final originalBuses = connections
          .where((c) => c.assignedBus >= 21 && c.assignedBus <= 28)
          .map((c) => c.assignedBus)
          .toSet();
      
      debugPrint('Original Aux buses: $originalBuses');
      debugPrint('Optimized Aux buses: $optimizedBuses');
      
      expect(optimizedBuses.length, lessThan(originalBuses.length),
        reason: 'Should use fewer Aux buses after optimization');
      
      // All consolidated connections should have Replace mode
      for (final conn in result.optimizedConnections) {
        if (result.changes.containsKey(conn.id) && 
            result.changes[conn.id]!.oldBus != result.changes[conn.id]!.newBus) {
          expect(conn.replaceMode, isTrue,
            reason: 'Consolidated connections should have Replace mode');
        }
      }
    });
  });
}