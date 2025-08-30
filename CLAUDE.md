# nt_helper - Disting NT MIDI Helper

Cross-platform Flutter application for managing Disting NT Eurorack module presets and algorithms.

## Core Concepts

**Purpose:** MIDI SysEx communication with Disting NT hardware for preset management, algorithm loading, and parameter control.

**Platforms:** Linux, macOS, iOS, Android, Windows with desktop drag-drop and backup features.

**Operation Modes:** Demo (no hardware), Offline (cached data), Connected (live MIDI).

## Architecture Patterns

**State Management:** Cubit pattern for application state.

**MIDI Layer:** Interface-based design with multiple implementations (mock, offline, live).

**Database:** Drift ORM for local data persistence.

**MCP Integration:** Model Context Protocol server for external tool access.

## Routing Visualization (Current Architecture)

The routing editor is strictly data-driven and unidirectional:

- Source of truth: `DistingCubit` exposes synchronized `Slot`s (algorithm + parameters + values).
- Port computation: `RoutingEditorCubit` derives routing metadata from each `Slot` and instantiates routing via `RoutingFactory`.
  - Polyphonic (lib/core/routing/poly_algorithm_routing.dart):
    - Gates: Only gates with a non-zero bus (“Gate input N”) create a Gate N port and exactly `Gate N CV count` CV ports on consecutive busses (hinted via metadata).
    - Extra inputs: Adds known CV/audio inputs present in the slot (e.g., “Wave input”, “Pitchbend input”, “Root CV”, “Arp reset”, “Audio input”).
    - Outputs: Creates ports for algorithm output parameters (e.g., “Left/mono output”, “Left output”, “Right output”, “Output bus”, “Odd output”, “Even output”).
  - Multi-channel: handled by `MultiChannelAlgorithmRouting` when applicable.
- View-only canvas: `RoutingCanvas` enumerates and displays the precomputed ports; it does not make routing decisions.
  - Auto-refresh: The canvas rebuilds when `RoutingEditorStateLoaded.algorithms` changes, including port list diffs (ids, names, types, directions).

Important removals (old approaches):
- `PortExtractionService` and `AutoRoutingService` have been removed. Do not reintroduce alternate extraction paths — always derive ports from `Slot` in `RoutingEditorCubit` and use `AlgorithmRouting` to enumerate them.

Key files:
- `lib/cubit/routing_editor_cubit.dart` – builds routing metadata from Slot, instantiates routing, stores ports in state.
- `lib/core/routing/poly_algorithm_routing.dart` – gate-driven CV and declared outputs logic for polysynths.
- `lib/core/routing/multi_channel_algorithm_routing.dart` – width/multi-channel routing.
- `lib/ui/widgets/routing/routing_editor_widget.dart` – renders ports and connections from state; no business logic.

### Visualization Flow (Diagram)

```
┌──────────────────┐       ┌──────────────────────┐        ┌────────────────────────┐
│  DistingCubit    │       │  RoutingEditorCubit  │        │      RoutingFactory     │
│  (Synchronized   │  →    │  (derive from Slot)  │   →    │  (create AlgorithmRouting│
│  Slots: params & │       │  - gateInputs        │        │   Poly/Multi)            │
│  values)         │       │  - gateCvCounts      │        └──────────────┬─────────┘
└──────────┬───────┘       │  - extraInputs                         │
           │               │  - outputs                             │
           │               └─────────────────────────────────────────┘
           │                                                     ports
           │                                                       ↓
           │                                         ┌────────────────────────┐
           │                                         │  AlgorithmRouting      │
           │                                         │  - PolyAlgorithmRouting│
           │                                         │    (gate-driven CV,    │
           │                                         │     declared outputs)  │
           │                                         │  - MultiChannelRouting │
           │                                         └──────────────┬─────────┘
           │                                                     input/output
           │                                                         ports
           │                                                           ↓
           │                                         ┌────────────────────────┐
           └────────────────────────────────────────▶│  RoutingCanvas (view)  │
                                                     │  render only           │
                                                     └────────────────────────┘
```

### Do / Don't

Do
- Derive routing inputs/outputs only from live Slot parameters in `RoutingEditorCubit`.
- Use `RoutingFactory` + `AlgorithmRouting` (Poly/Multi) to enumerate ports.
- For polysynths, follow “gate-driven CV” rules:
  - Only gates with bus > 0 create ports.
  - Create exactly `Gate N CV count` CV ports per connected gate (consecutive bus rule).
  - Add known extra inputs (Wave, Pitchbend, Audio, Root CV, Arp reset) when present.
  - Create outputs from output bus params (Left/Right, Output bus, Odd/Even).
- Keep `RoutingCanvas` view-only. It should only enumerate and display ports from state.
- Ensure the canvas rebuilds when algorithm port lists change (auto-refresh UX).

Don't
- Don’t use `PortExtractionService` or `AutoRoutingService` (they’re removed).
- Don’t infer ports from Specifications or docs for visualization — they’re for build-time constraints, not live routing UI.
- Don’t generate mock “Voice N In/Out” or “Poly Mix Out” ports.
- Don’t put routing decision logic in the canvas layer.

## Development Standards

**Code Quality:** Zero tolerance for `flutter analyze` errors.

**Debugging:** Always use `debugPrint()`, never `print()`.

**Workflow:** Feature branches required, PR approval needed.

## Task Master AI Instructions
**Import Task Master's development workflow commands and guidelines, treat as if import is in the main CLAUDE.md file.**
@./.taskmaster/CLAUDE.md
