import 'package:flutter/widgets.dart';

class ParameterValueEditTraversalEntry {
  const ParameterValueEditTraversalEntry({
    required this.id,
    required this.order,
    required this.enterEditMode,
  });

  final Object id;
  final double order;
  final VoidCallback enterEditMode;
}

class ParameterValueEditTraversalScope extends StatefulWidget {
  const ParameterValueEditTraversalScope({super.key, required this.child});

  final Widget child;

  static ParameterValueEditTraversalScopeState? maybeOf(BuildContext context) {
    return context
        .findAncestorStateOfType<ParameterValueEditTraversalScopeState>();
  }

  @override
  State<ParameterValueEditTraversalScope> createState() =>
      ParameterValueEditTraversalScopeState();
}

class ParameterValueEditTraversalScopeState
    extends State<ParameterValueEditTraversalScope> {
  final Map<Object, ParameterValueEditTraversalEntry> _entries = {};

  void register(ParameterValueEditTraversalEntry entry) {
    _entries[entry.id] = entry;
  }

  void unregister(Object id) {
    _entries.remove(id);
  }

  bool moveFrom(Object id, {required bool reverse}) {
    if (_entries.isEmpty) return false;

    final entries = _entries.values.toList()
      ..sort((a, b) {
        final orderCompare = a.order.compareTo(b.order);
        if (orderCompare != 0) return orderCompare;
        return a.id.hashCode.compareTo(b.id.hashCode);
      });

    final currentIndex = entries.indexWhere((entry) => entry.id == id);
    if (currentIndex < 0) return false;

    final nextIndex = reverse
        ? (currentIndex - 1 + entries.length) % entries.length
        : (currentIndex + 1) % entries.length;
    entries[nextIndex].enterEditMode();
    return true;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
