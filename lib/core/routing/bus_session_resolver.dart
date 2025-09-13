import 'models/port.dart';

/// Resolves bus contribution "sessions" based on slot order and OutputMode.
///
/// Rules:
/// - Slots execute in ascending order (0..N-1).
/// - A write with OutputMode.replace starts a new session at its slot.
/// - Writes with OutputMode.add contribute to the current session.
/// - A reader at slot k sees contributors from the most recent replace < k
///   (including that replace writer) plus any add writers in (replaceSlot, k).
/// - If there is no replace < k, the session is seeded by the hardware input
///   (for physical input buses) or silence; add writers < k all contribute.
class BusSessionResolver {
  final Map<int, List<_Write>> _busWrites; // bus -> sorted writes by slot
  final int totalSlots; // number of algorithm slots in evaluation order

  // Private constructor to avoid exposing private types in public API
  BusSessionResolver._(Map<int, List<_Write>> busWrites, this.totalSlots)
    : _busWrites = {
        for (final e in busWrites.entries)
          e.key: List<_Write>.from(e.value)
            ..sort((a, b) => a.slot.compareTo(b.slot)),
      };

  /// Returns portIds of writers that contribute to the value read at [readerSlot]
  /// on [bus]. Slots >= readerSlot never contribute.
  Set<String> contributorsForReader(int bus, int readerSlot) {
    final writes = _busWrites[bus];
    if (writes == null || writes.isEmpty) return <String>{};

    final contributing = <String>{};

    // Find the last replace before readerSlot
    int? lastReplaceSlot;
    String? lastReplacePortId;
    for (final w in writes) {
      if (w.slot >= readerSlot) break;
      if (w.mode == OutputMode.replace) {
        lastReplaceSlot = w.slot;
        lastReplacePortId = w.portId;
      }
    }

    if (lastReplaceSlot != null) {
      // Include the replace writer
      if (lastReplacePortId != null) contributing.add(lastReplacePortId);
      // Include add writers after the replace and before reader
      for (final w in writes) {
        if (w.slot <= lastReplaceSlot) continue;
        if (w.slot >= readerSlot) break;
        if (w.mode == OutputMode.add) contributing.add(w.portId);
      }
    } else {
      // No replace before reader: include all add writers before reader
      for (final w in writes) {
        if (w.slot >= readerSlot) break;
        if (w.mode == OutputMode.add) contributing.add(w.portId);
      }
    }

    return contributing;
  }

  /// True if the hardware input seed would contribute to [bus] at [readerSlot].
  /// Equivalent to "no replace writer occurs before readerSlot".
  bool hardwareSeedContributes(int bus, int readerSlot) {
    final writes = _busWrites[bus];
    if (writes == null || writes.isEmpty) return true; // no writers yet
    for (final w in writes) {
      if (w.slot >= readerSlot) break;
      if (w.mode == OutputMode.replace) return false;
    }
    return true;
  }

  /// Returns the final contributors seen by hardware outputs at end of frame.
  /// This is contributorsForReader(bus, totalSlots), i.e., after the last slot.
  Set<String> finalContributors(int bus) {
    return contributorsForReader(bus, totalSlots);
  }
}

/// Internal immutable write record
class _Write {
  final int slot;
  final String portId;
  final OutputMode mode;
  const _Write({required this.slot, required this.portId, required this.mode});
}

/// Helper to build writes from raw tuples without exposing _Write outside.
class BusSessionBuilder {
  final Map<int, List<_Write>> _busWrites = {};

  void addWrite({
    required int bus,
    required int slot,
    required String portId,
    required OutputMode? mode,
  }) {
    final effective = mode ?? OutputMode.add; // default to ADD when unspecified
    _busWrites
        .putIfAbsent(bus, () => <_Write>[])
        .add(_Write(slot: slot, portId: portId, mode: effective));
  }

  BusSessionResolver build({required int totalSlots}) =>
      BusSessionResolver._(_busWrites, totalSlots);
}
