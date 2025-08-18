import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:nt_helper/domain/i_disting_midi_manager.dart';
import 'package:nt_helper/domain/parameter_update_queue.dart';

@GenerateMocks([IDistingMidiManager])
import 'parameter_update_queue_test.mocks.dart';

void main() {
  group('ParameterUpdateQueue - Timing Optimizations', () {
    late MockIDistingMidiManager mockMidiManager;
    late ParameterUpdateQueue queue;

    setUp(() {
      mockMidiManager = MockIDistingMidiManager();
    });

    tearDown(() {
      queue.dispose();
    });

    group('timing configuration', () {
      test('should use optimized default timing intervals', () {
        queue = ParameterUpdateQueue(midiManager: mockMidiManager);

        // Verify the optimized timing values from the PRP
        expect(queue.processingInterval, equals(const Duration(milliseconds: 5)));
        expect(queue.operationInterval, equals(const Duration(milliseconds: 25)));
      });

      test('should accept custom timing intervals', () {
        const customProcessingInterval = Duration(milliseconds: 10);
        const customOperationInterval = Duration(milliseconds: 50);
        
        queue = ParameterUpdateQueue(
          midiManager: mockMidiManager,
          processingInterval: customProcessingInterval,
          operationInterval: customOperationInterval,
        );

        expect(queue.processingInterval, equals(customProcessingInterval));
        expect(queue.operationInterval, equals(customOperationInterval));
      });

      test('should validate optimized intervals are faster than old defaults', () {
        queue = ParameterUpdateQueue(midiManager: mockMidiManager);

        // Old defaults were 10ms processing, 50ms operation
        const oldProcessingInterval = Duration(milliseconds: 10);
        const oldOperationInterval = Duration(milliseconds: 50);

        // New optimized values should be faster
        expect(queue.processingInterval, lessThan(oldProcessingInterval));
        expect(queue.operationInterval, lessThan(oldOperationInterval));
      });
    });

    group('basic functionality', () {
      test('should accept callback function parameter', () {
        queue = ParameterUpdateQueue(
          midiManager: mockMidiManager,
          onParameterStringUpdated: (algorithmIndex, parameterNumber, value) {
            // Callback is set
          },
        );

        // Should create successfully with callback
        expect(queue.processingInterval, equals(const Duration(milliseconds: 5)));
        expect(queue.operationInterval, equals(const Duration(milliseconds: 25)));
      });

      test('should work without callback parameter', () {
        queue = ParameterUpdateQueue(
          midiManager: mockMidiManager,
          // No callback provided
        );

        // Should create successfully without callback
        expect(queue.processingInterval, equals(const Duration(milliseconds: 5)));
        expect(queue.operationInterval, equals(const Duration(milliseconds: 25)));
      });

      test('should handle dispose correctly', () {
        queue = ParameterUpdateQueue(midiManager: mockMidiManager);
        
        // Should not throw when disposing
        expect(() => queue.dispose(), returnsNormally);
      });

      test('should handle updateParameter calls', () {
        queue = ParameterUpdateQueue(midiManager: mockMidiManager);
        
        // Should not throw when updating parameters
        expect(() => queue.updateParameter(
          algorithmIndex: 1,
          parameterNumber: 31,
          value: 100,
          needsStringUpdate: true,
        ), returnsNormally);
      });
    });
  });
}