# Algorithm Connections Spec (Condensed)

**Goal**: Visualize algorithm-to-algorithm connections in routing editor based on shared bus assignments.

**Key Points**:
- Auto-discover connections where algorithm output bus = input bus (1–28 max)
- Support up to 32 algorithm slots (0–31)
- Invalid connections (source slot ≥ target slot) shown in red; valid connections use the source output port type color (no per-port hue changes)
- Bus mapping: 1–12 (physical inputs), 13–20 (physical outputs), 21–28 (aux/internal)
- Integrate with existing `RoutingEditorWidget` + `ConnectionCanvas` (no custom painter)
- Real-time updates when parameters change
- Excludes existing physical I/O connections (no duplication)

**Implementation**:
- New `AlgorithmConnection` data model
- `AlgorithmConnectionService` for discovery (shared bus-resolution utility)
- Enhanced `@lib/cubit/routing_editor_cubit.dart` integration with `algorithmConnections` in state
- Additional `ConnectionCanvas` layer for algorithm connections

**Success**: All algorithm connections visible with clear valid/invalid indication; colors follow the source output port type (no per-port hue changes).
