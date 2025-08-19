import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
// import 'package:nt_helper/domain/disting_nt_sysex.dart'; // For future TDD phases
// import 'package:nt_helper/models/connection.dart'; // For future TDD phases
import 'package:nt_helper/models/tidy_result.dart';
import 'package:nt_helper/services/auto_routing_service.dart';

import 'tidy_hardware_sync_test.mocks.dart';

@GenerateMocks([DistingCubit])
void main() {
  // Configure Mockito to provide dummy values
  provideDummy<DistingState>(const DistingStateInitial());

  group('AutoRoutingService - Hardware Tidy Sync', () {
    late AutoRoutingService autoRoutingService;
    late MockDistingCubit mockCubit;

    setUp(() {
      mockCubit = MockDistingCubit();
      autoRoutingService = AutoRoutingService(mockCubit);
    });

    test('should handle hardware sync failure gracefully', () async {
      // Setup state that will cause sync to fail
      when(mockCubit.state).thenReturn(const DistingStateInitial());

      final tidyResult = TidyResult.success(
        originalConnections: const [],
        optimizedConnections: const [],
        busesFreed: 0,
        changes: const {},
      );

      // Should handle invalid state gracefully
      expect(
        () => autoRoutingService.applyTidyResult(tidyResult),
        throwsA(isA<Exception>()),
      );
    });

    test('should validate tidy result before applying', () async {
      // Setup initial state (invalid for hardware sync)
      when(mockCubit.state).thenReturn(const DistingStateInitial());

      // Create invalid tidy result (failed optimization)
      final invalidResult = TidyResult.failed('Optimization failed');

      // Should reject invalid tidy results
      expect(
        () => autoRoutingService.applyTidyResult(invalidResult),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('should handle empty changes gracefully', () async {
      // Setup initial state (invalid for hardware sync)
      when(mockCubit.state).thenReturn(const DistingStateInitial());

      final tidyResult = TidyResult.success(
        originalConnections: const [],
        optimizedConnections: const [],
        busesFreed: 0,
        changes: const {},
      );

      // Should still fail due to invalid state, but not due to empty changes
      expect(
        () => autoRoutingService.applyTidyResult(tidyResult),
        throwsA(isA<Exception>()),
      );
    });

    test('should require synchronized state for hardware updates', () async {
      // Test with connected but not synchronized state
      when(mockCubit.state).thenReturn(const DistingStateInitial());

      final tidyResult = TidyResult.success(
        originalConnections: const [],
        optimizedConnections: const [],
        busesFreed: 1,
        changes: const {
          'test_conn': BusChange(
            connectionId: 'test_conn',
            oldBus: 21,
            newBus: 22,
            oldReplaceMode: false,
            newReplaceMode: true,
            reason: 'Test optimization',
          ),
        },
      );

      // Should throw exception due to unsynchronized state
      expect(
        () => autoRoutingService.applyTidyResult(tidyResult),
        throwsA(allOf(
          isA<Exception>(),
          predicate<Exception>((e) => e.toString().contains('Hardware not synchronized')),
        )),
      );
    });
  });
}