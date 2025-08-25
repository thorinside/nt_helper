import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/util/topological_sort.dart';

void main() {
  group('TopologicalSort', () {
    test('should sort simple linear graph', () {
      final adjacencyList = <int, Set<int>>{
        0: {1},
        1: {2},
        2: <int>{},
      };

      final result = TopologicalSort.topologicalSort(adjacencyList);
      expect(result, [0, 1, 2]);
    });

    test('should sort branching graph', () {
      final adjacencyList = <int, Set<int>>{
        0: {1, 2},
        1: {3},
        2: {3},
        3: <int>{},
      };

      final result = TopologicalSort.topologicalSort(adjacencyList);
      expect(result.indexOf(0), lessThan(result.indexOf(1)));
      expect(result.indexOf(0), lessThan(result.indexOf(2)));
      expect(result.indexOf(1), lessThan(result.indexOf(3)));
      expect(result.indexOf(2), lessThan(result.indexOf(3)));
    });

    test('should detect cycle', () {
      final adjacencyList = <int, Set<int>>{
        0: {1},
        1: {2},
        2: {0},
      };

      expect(
        () => TopologicalSort.topologicalSort(adjacencyList),
        throwsA(isA<CycleDetectedException>()),
      );
    });

    test('should detect no cycles in valid graph', () {
      final adjacencyList = <int, Set<int>>{
        0: {1, 2},
        1: {3},
        2: {3},
        3: <int>{},
      };

      expect(TopologicalSort.detectCycles(adjacencyList), false);
    });

    test('should detect cycles correctly', () {
      final adjacencyList = <int, Set<int>>{
        0: {1},
        1: {2},
        2: {0},
      };

      expect(TopologicalSort.detectCycles(adjacencyList), true);
    });

    test('should find cycle path', () {
      final adjacencyList = <int, Set<int>>{
        0: {1},
        1: {2},
        2: {0},
      };

      final cyclePath = TopologicalSort.findCyclePath(adjacencyList);
      expect(cyclePath, isNotNull);
      expect(cyclePath, contains(0));
      expect(cyclePath, contains(1));
      expect(cyclePath, contains(2));
    });

    test('should handle empty graph', () {
      final adjacencyList = <int, Set<int>>{};
      final result = TopologicalSort.topologicalSort(adjacencyList);
      expect(result, isEmpty);
    });

    test('should handle single node graph', () {
      final adjacencyList = <int, Set<int>>{0: <int>{}};
      final result = TopologicalSort.topologicalSort(adjacencyList);
      expect(result, [0]);
    });
  });
}
