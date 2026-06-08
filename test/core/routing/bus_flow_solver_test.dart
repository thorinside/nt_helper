import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/core/routing/bus_flow_solver.dart';

SlotBusUsage _slot(
  String id,
  int index, {
  Set<int> reads = const {},
  Set<int> writes = const {},
}) => SlotBusUsage(
  id: id,
  index: index,
  name: id.toUpperCase(),
  reads: reads,
  writes: writes,
);

void main() {
  group('BusFlowSolver', () {
    test('single / empty slot needs no reorder', () {
      expect(BusFlowSolver([]).solve().order, isEmpty);
      final one = BusFlowSolver([_slot('a', 0, writes: {21})]).solve();
      expect(one.order, ['a']);
      expect(one.reorderNeeded, isFalse);
    });

    test('already-valid order is left untouched', () {
      // A writes aux 21 (slot 0), B reads it (slot 1): writer already above.
      final sol = BusFlowSolver([
        _slot('a', 0, writes: {21}),
        _slot('b', 1, reads: {21}),
      ]).solve();

      expect(sol.order, ['a', 'b']);
      expect(sol.reorderNeeded, isFalse);
      expect(sol.backwardEdges, isEmpty);
    });

    test('reorders so a writer precedes its reader', () {
      // A reads aux 21 (slot 0) but B writes it (slot 1): B must move above A.
      final sol = BusFlowSolver([
        _slot('a', 0, reads: {21}),
        _slot('b', 1, writes: {21}),
      ]).solve();

      expect(sol.order, ['b', 'a']);
      expect(sol.reorderNeeded, isTrue);
      expect(sol.backwardEdges, isEmpty);
    });

    test('physical input bus reads never force a reorder (hardware-seeded)', () {
      // A reads input bus 1; B writes bus 1 below it. No reorder: bus 1 is fed
      // by the hardware jack regardless of slot order.
      final sol = BusFlowSolver([
        _slot('a', 0, reads: {1}),
        _slot('b', 1, writes: {1}),
      ]).solve();

      expect(sol.order, ['a', 'b']);
      expect(sol.reorderNeeded, isFalse);
      expect(sol.backwardEdges, isEmpty);
    });

    test('reading an undriven bus does not force a reorder', () {
      // Nothing writes aux 21, so reading it cannot be fixed by reordering.
      final sol = BusFlowSolver([
        _slot('a', 0, reads: {21}),
        _slot('b', 1, writes: {22}),
      ]).solve();

      expect(sol.order, ['a', 'b']);
      expect(sol.reorderNeeded, isFalse);
      expect(sol.backwardEdges, isEmpty);
    });

    test('a reader is placed below all writers of its buses', () {
      // A (slot 0) and C (slot 2) both write aux 21; B (slot 1) reads it.
      // B must end up after both writers.
      final sol = BusFlowSolver([
        _slot('a', 0, writes: {21}),
        _slot('b', 1, reads: {21}),
        _slot('c', 2, writes: {21}),
      ]).solve();

      expect(sol.order, ['a', 'c', 'b']);
      expect(sol.reorderNeeded, isTrue);
      expect(sol.backwardEdges, isEmpty);
    });

    test('a feedback cycle degrades to a backward edge, not an error', () {
      // A: read 21, write 22 ; B: read 22, write 21  -> mutual dependency.
      final sol = BusFlowSolver([
        _slot('a', 0, reads: {21}, writes: {22}),
        _slot('b', 1, reads: {22}, writes: {21}),
      ]).solve();

      // Order stays as-is (cycle can't be satisfied either way).
      expect(sol.order, ['a', 'b']);
      // One dependency must resolve late: B writes 21, A reads 21, B is below A.
      expect(sol.backwardEdges, contains(
        const BusFlowEdge(fromId: 'b', toId: 'a', bus: 21),
      ));
    });
  });
}
