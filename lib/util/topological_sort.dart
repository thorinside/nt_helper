import 'dart:collection';

class TopologicalSort {
  /// Performs topological sorting using Kahn's algorithm
  /// Returns the ordered list of algorithm indices
  static List<int> topologicalSort(Map<int, Set<int>> adjacencyList) {
    final inDegree = <int, int>{};
    final queue = Queue<int>();
    final result = <int>[];

    // Calculate in-degrees
    for (final node in adjacencyList.keys) {
      inDegree[node] ??= 0;
      for (final neighbor in adjacencyList[node]!) {
        inDegree[neighbor] = (inDegree[neighbor] ?? 0) + 1;
      }
    }

    // Add nodes with no dependencies
    inDegree.forEach((node, degree) {
      if (degree == 0) queue.add(node);
    });

    // Process queue
    while (queue.isNotEmpty) {
      final node = queue.removeFirst();
      result.add(node);

      for (final neighbor in adjacencyList[node] ?? <int>{}) {
        inDegree[neighbor] = inDegree[neighbor]! - 1;
        if (inDegree[neighbor] == 0) {
          queue.add(neighbor);
        }
      }
    }

    if (result.length != adjacencyList.length) {
      throw CycleDetectedException('Cycle detected in routing graph');
    }

    return result;
  }

  /// Detects cycles in the graph using DFS
  static bool detectCycles(Map<int, Set<int>> adjacencyList) {
    final visited = <int>{};
    final recursionStack = <int>{};

    bool hasCycle(int node) {
      visited.add(node);
      recursionStack.add(node);

      for (final neighbor in adjacencyList[node] ?? <int>{}) {
        if (!visited.contains(neighbor)) {
          if (hasCycle(neighbor)) return true;
        } else if (recursionStack.contains(neighbor)) {
          return true; // Found cycle
        }
      }

      recursionStack.remove(node);
      return false;
    }

    for (final node in adjacencyList.keys) {
      if (!visited.contains(node)) {
        if (hasCycle(node)) return true;
      }
    }

    return false;
  }

  /// Finds and returns the cycle path if one exists
  static List<int>? findCyclePath(Map<int, Set<int>> adjacencyList) {
    final visited = <int>{};
    final recursionStack = <int>{};
    final parent = <int, int?>{};

    List<int>? findCycle(int node) {
      visited.add(node);
      recursionStack.add(node);

      for (final neighbor in adjacencyList[node] ?? <int>{}) {
        if (!visited.contains(neighbor)) {
          parent[neighbor] = node;
          final cycle = findCycle(neighbor);
          if (cycle != null) return cycle;
        } else if (recursionStack.contains(neighbor)) {
          // Found cycle - reconstruct path
          final cycle = <int>[neighbor];
          int current = node;
          while (current != neighbor) {
            cycle.add(current);
            current = parent[current]!;
          }
          return cycle.reversed.toList();
        }
      }

      recursionStack.remove(node);
      return null;
    }

    for (final node in adjacencyList.keys) {
      if (!visited.contains(node)) {
        final cycle = findCycle(node);
        if (cycle != null) return cycle;
      }
    }

    return null;
  }
}

class CycleDetectedException implements Exception {
  final String message;
  final List<int>? cyclePath;

  CycleDetectedException(this.message, [this.cyclePath]);

  @override
  String toString() => 'CycleDetectedException: $message';
}