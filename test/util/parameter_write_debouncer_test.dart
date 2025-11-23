import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/util/parameter_write_debouncer.dart';

void main() {
  group('ParameterWriteDebouncer Tests', () {
    late ParameterWriteDebouncer debouncer;

    setUp(() {
      debouncer = ParameterWriteDebouncer();
    });

    tearDown(() {
      debouncer.dispose();
    });

    test('schedules callback after delay', () async {
      bool callbackExecuted = false;

      debouncer.schedule('test', () {
        callbackExecuted = true;
      }, const Duration(milliseconds: 50));

      // Callback should not execute immediately
      expect(callbackExecuted, isFalse);

      // Wait for delay to pass
      await Future.delayed(const Duration(milliseconds: 100));

      // Callback should have executed
      expect(callbackExecuted, isTrue);
    });

    test('debounces rapid calls - only executes final callback', () async {
      int callCount = 0;
      int lastValue = 0;

      // Simulate rapid slider movements
      for (int i = 0; i < 10; i++) {
        debouncer.schedule('test', () {
          callCount++;
          lastValue = i;
        }, const Duration(milliseconds: 50));

        // Small delay between calls (simulating drag)
        await Future.delayed(const Duration(milliseconds: 5));
      }

      // Wait for debounce delay to complete
      await Future.delayed(const Duration(milliseconds: 100));

      // Should only execute once with final value
      expect(callCount, equals(1));
      expect(lastValue, equals(9));
    });

    test('handles multiple keys independently', () async {
      int key1CallCount = 0;
      int key2CallCount = 0;

      debouncer.schedule('key1', () {
        key1CallCount++;
      }, const Duration(milliseconds: 50));

      debouncer.schedule('key2', () {
        key2CallCount++;
      }, const Duration(milliseconds: 50));

      await Future.delayed(const Duration(milliseconds: 100));

      // Both callbacks should execute once
      expect(key1CallCount, equals(1));
      expect(key2CallCount, equals(1));
    });

    test('dispose cancels all pending timers', () async {
      bool callbackExecuted = false;

      debouncer.schedule('test', () {
        callbackExecuted = true;
      }, const Duration(milliseconds: 50));

      // Dispose before delay completes
      debouncer.dispose();

      // Wait for original delay
      await Future.delayed(const Duration(milliseconds: 100));

      // Callback should NOT have executed
      expect(callbackExecuted, isFalse);
    });

    test('pendingCount tracks active timers', () {
      expect(debouncer.pendingCount, equals(0));

      debouncer.schedule('key1', () {}, const Duration(milliseconds: 100));
      expect(debouncer.pendingCount, equals(1));

      debouncer.schedule('key2', () {}, const Duration(milliseconds: 100));
      expect(debouncer.pendingCount, equals(2));

      // Scheduling with same key should replace, not add
      debouncer.schedule('key1', () {}, const Duration(milliseconds: 100));
      expect(debouncer.pendingCount, equals(2));
    });

    test('clears pending count after execution', () async {
      debouncer.schedule('test', () {}, const Duration(milliseconds: 50));
      expect(debouncer.pendingCount, equals(1));

      await Future.delayed(const Duration(milliseconds: 100));

      expect(debouncer.pendingCount, equals(0));
    });
  });
}
