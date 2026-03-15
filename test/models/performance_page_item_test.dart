import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/models/performance_page_item.dart';

void main() {
  group('PerformancePageItem', () {
    test('empty factory creates disabled item', () {
      final item = PerformancePageItem.empty(5);
      expect(item.itemIndex, 5);
      expect(item.enabled, false);
      expect(item.slotIndex, 0);
      expect(item.parameterNumber, 0);
      expect(item.min, 0);
      expect(item.max, 0);
      expect(item.upperLabel, '');
      expect(item.lowerLabel, '');
    });

    test('copyWith updates fields', () {
      final item = PerformancePageItem.empty(0);
      final updated = item.copyWith(
        enabled: true,
        slotIndex: 2,
        parameterNumber: 42,
        min: -100,
        max: 100,
        upperLabel: 'Test',
        lowerLabel: 'Label',
      );

      expect(updated.itemIndex, 0);
      expect(updated.enabled, true);
      expect(updated.slotIndex, 2);
      expect(updated.parameterNumber, 42);
      expect(updated.min, -100);
      expect(updated.max, 100);
      expect(updated.upperLabel, 'Test');
      expect(updated.lowerLabel, 'Label');
    });

    test('equality works correctly', () {
      final a = PerformancePageItem(
        itemIndex: 0,
        enabled: true,
        slotIndex: 1,
        parameterNumber: 5,
        min: 0,
        max: 127,
        upperLabel: 'A',
        lowerLabel: 'B',
      );
      final b = PerformancePageItem(
        itemIndex: 0,
        enabled: true,
        slotIndex: 1,
        parameterNumber: 5,
        min: 0,
        max: 127,
        upperLabel: 'A',
        lowerLabel: 'B',
      );
      final c = a.copyWith(max: 255);

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
      expect(a.hashCode, b.hashCode);
    });
  });
}
