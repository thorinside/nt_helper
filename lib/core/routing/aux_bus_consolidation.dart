/// Pure, signal-preserving planner for AUX bus consolidation ("Optimize AUX
/// Buses"). Packs AUX buses whose usage spans don't overlap in slot-time onto a
/// single physical bus, inserting a Replace boundary at the start of each
/// stacked-above session so the sessions stay isolated.
///
/// Invariants (why this never changes the audio):
/// - Two buses may share a number only if their occupied slot ranges are
///   disjoint — one session ends (its last read) strictly before the other
///   begins (its first write). Overlapping buses are left alone.
/// - Within a kept bus the sessions are ordered low→high by slot. Every session
///   except the lowest gets Replace set on its FIRST source only — that wipes
///   the previous session's residue before this session's reads. Sources in the
///   middle of a session (intentional Add mixes, e.g. an effects send summing
///   several inputs) are never touched, so mixes are preserved.
/// - A bus whose lowest-slot port is a read (a read below its first write —
///   feedback or a silence-read) is excluded entirely: stacking anything below
///   it would change what that read sees.
library;

/// A single algorithm parameter currently assigned to an AUX bus.
class AuxBusPort {
  /// Algorithm/slot index in evaluation order (lower runs first).
  final int slot;

  /// The bus-assignment parameter number (rewritten when the port moves).
  final int busParameterNumber;

  /// True for an output (writes the bus), false for an input (reads it).
  final bool isSource;

  /// Whether this source has an Add/Replace mode parameter.
  final bool canReplace;

  /// Whether this source is currently in Replace mode.
  final bool isReplace;

  /// The source's mode parameter number, when [canReplace].
  final int? modeParameterNumber;

  const AuxBusPort({
    required this.slot,
    required this.busParameterNumber,
    required this.isSource,
    this.canReplace = false,
    this.isReplace = false,
    this.modeParameterNumber,
  });
}

/// All ports currently assigned to one AUX bus.
class AuxBusUsage {
  final int bus;
  final List<AuxBusPort> ports;
  const AuxBusUsage({required this.bus, required this.ports});
}

/// Reassign a port from [fromBus] to [toBus].
class AuxPortMove {
  final int slot;
  final int busParameterNumber;
  final int fromBus;
  final int toBus;
  const AuxPortMove({
    required this.slot,
    required this.busParameterNumber,
    required this.fromBus,
    required this.toBus,
  });
}

/// Set a source's mode parameter to Replace (the session boundary).
class AuxReplaceMode {
  final int slot;
  final int modeParameterNumber;
  const AuxReplaceMode({required this.slot, required this.modeParameterNumber});
}

/// One freed bus: its ports move onto [keepBus], with optional boundary
/// Replace writes.
class AuxBusMerge {
  final int keepBus;
  final int freeBus;
  final List<AuxPortMove> moves;
  final List<AuxReplaceMode> replaces;
  const AuxBusMerge({
    required this.keepBus,
    required this.freeBus,
    required this.moves,
    required this.replaces,
  });
}

/// Build the set of safe merges. Returns one [AuxBusMerge] per freed bus; an
/// empty list means nothing can be safely consolidated.
List<AuxBusMerge> planAuxBusConsolidation(List<AuxBusUsage> buses) {
  final sessions = <_Session>[];
  for (final b in buses) {
    if (b.ports.isEmpty) continue;

    AuxBusPort? firstSource;
    var lo = b.ports.first.slot;
    var hi = b.ports.first.slot;
    for (final p in b.ports) {
      if (p.slot < lo) lo = p.slot;
      if (p.slot > hi) hi = p.slot;
      if (p.isSource && (firstSource == null || p.slot < firstSource.slot)) {
        firstSource = p;
      }
    }
    if (firstSource == null) continue; // read-only bus: never a source

    // Ineligible if a read sits below the first write (feedback / silence-read):
    // stacking anything below it would change what that read sees.
    if (lo < firstSource.slot) continue;

    sessions.add(
      _Session(bus: b.bus, lo: lo, hi: hi, firstSource: firstSource, ports: b.ports),
    );
  }

  // Greedily pack sessions into clusters of pairwise slot-disjoint sessions.
  // Processing in ascending start order means a session can only ever stack
  // ABOVE a cluster's current top, so disjointness reduces to lo > top.hi.
  sessions.sort((a, b) => a.lo.compareTo(b.lo));
  final clusters = <_Cluster>[];
  for (final s in sessions) {
    _Cluster? target;
    for (final c in clusters) {
      // A stacked-above session needs Replace capability to start a clean
      // boundary; the bottom of a cluster never does.
      if (s.lo > c.top && s.firstSource.canReplace) {
        target = c;
        break;
      }
    }
    if (target == null) {
      clusters.add(_Cluster(s));
    } else {
      target.add(s);
    }
  }

  final merges = <AuxBusMerge>[];
  for (final c in clusters) {
    if (c.members.length < 2) continue;
    final keep = c.members.first.bus; // the bottom (lowest start) session
    for (final s in c.members.skip(1)) {
      final moves = [
        for (final p in s.ports)
          AuxPortMove(
            slot: p.slot,
            busParameterNumber: p.busParameterNumber,
            fromBus: s.bus,
            toBus: keep,
          ),
      ];
      final replaces = <AuxReplaceMode>[];
      final fs = s.firstSource;
      if (!fs.isReplace && fs.modeParameterNumber != null) {
        replaces.add(
          AuxReplaceMode(slot: fs.slot, modeParameterNumber: fs.modeParameterNumber!),
        );
      }
      merges.add(
        AuxBusMerge(keepBus: keep, freeBus: s.bus, moves: moves, replaces: replaces),
      );
    }
  }
  return merges;
}

class _Session {
  final int bus;
  final int lo;
  final int hi;
  final AuxBusPort firstSource;
  final List<AuxBusPort> ports;
  _Session({
    required this.bus,
    required this.lo,
    required this.hi,
    required this.firstSource,
    required this.ports,
  });
}

class _Cluster {
  final List<_Session> members;
  int top;
  _Cluster(_Session bottom)
    : members = [bottom],
      top = bottom.hi;
  void add(_Session s) {
    members.add(s);
    if (s.hi > top) top = s.hi;
  }
}
