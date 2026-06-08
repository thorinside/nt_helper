# Bus Lanes — a bus-centric, self-solving routing view

## Context

Users report the routing editor's default node-graph view (algorithm nodes + sockets joined by patch-cable wires) misrepresents how the Disting NT actually routes signal. The hardware is **bus-based**: a bus is a vertical "tube" running top→bottom through the ordered slots. Each algorithm **samples** (reads) the tube or **writes** to it in **Add** (mix into current flow) or **Replace** (cap the tube and start a fresh flow downward). Signal only flows from lower slots to higher slots.

We will add a **new graphical "Bus Lanes" view mode** that renders buses as colored vertical wires and makes the bus model directly manipulable. Confirmed scope (full vision, one deliverable):

- **Colored bus wires.** Each bus has a unique color. Empty buses are pale full-height wires. A read shows a tap off the wire. An **Add** write onto an already-driven bus uses a **darker shade** of that bus's color (signals accumulate). A **Replace** write **changes the color** and the previous wire **ends abruptly**, with a fresh wire starting below (the cap → new flow).
- **Draggable reordering with resistance.** Drag an algorithm up/down; deliberate "resistance" (hysteresis) before each slot step so the user must mean it. Executes via adjacent swaps.
- **Connect inputs/outputs to any bus.** Drag a port onto a bus wire to assign it. Outputs feed any bus; inputs read any bus.
- **Auto-solve the flow.** From the chosen connections, compute a valid slot order (every reader's bus is driven by an earlier slot) and apply it. Manual drag remains as an override.
- **Auto-reorder on connect.** If a new connection isn't valid yet (its bus is only written by a later slot), the app **moves algorithms automatically** to fix it, then shows a **snackbar explaining what moved and why, with an Undo action**.
- **Bouncy swap animation.** Whenever bands change slots — drag, auto-solve, or auto-reorder — they spring to their new positions with a bouncy easing rather than jumping.

## What already exists — reuse, do not rebuild

The tube/cap model is already in the data layer; reordering and parameter writes already exist. The new work is a rendering+gesture layer plus a flow solver/planner on top.

| Need | Reuse | Path |
|------|-------|------|
| Add/Replace per output port; bus number + role per port | `Port.outputMode`, `Port.busValue`, `effectiveRole`, `PortRole` | `lib/core/routing/models/port.dart` |
| Signal level propagation down each bus (sessions, replace=new session, dead-signal strip) | `RoutingAnalyzer` | `lib/util/routing_analyzer.dart` |
| Bus ranges/labels/grouping (in 1-12 / out 13-20 / aux 21+ / es5), extended aux | `BusSpec` | `lib/core/routing/bus_spec.dart` |
| `algorithms`→in/out/replace masks (already written for the table) | `_buildRoutingFromEditorState` (extract & share) | `lib/ui/widgets/routing/routing_table_view.dart:82` |
| Reorder primitive: adjacent swap, optimistic + verified, returns new index | `DistingCubit.moveAlgorithmUp/Down(index)` | `lib/cubit/disting_cubit.dart:435`; impl `disting_cubit_algorithm_ops.dart:417` |
| Proven multi-swap "walk to slot N" loop | MCP insert-at-slot loop | `lib/mcp/tools/disting_tools.dart:540` |
| Toggle Add/Replace | `RoutingEditorCubit.togglePortOutputMode(portId:)` | `lib/cubit/routing_editor_cubit.dart:2164` |
| Assign / change / clear a bus | `createConnection` (:371), `updateConnection` (:1784), `deleteConnectionWithSmartBusLogic` (:2722); low-level `DistingCubit.updateParameterValue` | `lib/cubit/routing_editor_cubit.dart` |
| Backward-edge (feedback) modeling + visibility setting | `Connection.isBackwardEdge`, `SettingsService.showBackwardConnectionsNotifier` | core/services |
| View-mode toggle + persistence (pattern to extend) | `_RoutingViewMode` enum, `_setViewMode`, `_buildViewModeButton`, build branch | `lib/ui/widgets/routing/routing_editor_widget.dart:41,155,~1089,~1629` |
| Snackbar pattern | `ScaffoldMessenger.of(context).showSnackBar` + add `SnackBarAction(label:'Undo')` | e.g. `lib/ui/synchronized_screen.dart:727` |
| Accessible color palette | `AccessibilityColors` | (per memory; in routing painter/port_widget) |

## Design

### New core logic (pure Dart, unit-tested) — `lib/core/routing/`
- **`bus_flow_solver.dart`** — input: algorithms with their read buses and write buses+modes (from `RoutingEditorStateLoaded.algorithms` / the shared mask builder). Builds a precedence DAG: edge `writer → reader` whenever a writer drives a non-physical bus that another algorithm reads. Outputs:
  - per-connection validity for the *current* order (is each reader's driver above it, or is the bus a physical input / undriven?);
  - a **target order** (list of algorithm IDs) via topological sort satisfying writer-before-reader; **cycles are broken by leaving one edge backward** (frame-delayed feedback, already modeled by `isBackwardEdge`) and reported, never by failing.
- **`slot_reorder_planner.dart`** — pure function `planSwaps(currentOrder, targetOrder) → List<SwapStep>` (each step = up/down at an index), using the "walk one algorithm at a time" approach the MCP loop already uses. Used for both apply and undo (undo = plan from current→previous).
- **`bus_color_palette.dart`** — deterministic bus→base-color map (stable across rebuilds), with `shadeForAdd(baseColor, depth)` (darker per accumulated writer) and `colorForSession(bus, sessionIndex)` (new color after each Replace). Pale tint for empty buses. Prefer `AccessibilityColors` primitives for contrast.

### Cubit orchestration — extend `RoutingEditorCubit` (it already holds `_distingCubit`)
- **`applyReorder(List<String> targetOrder) → ReorderResult`** — executes the planned swaps by awaiting `_distingCubit.moveAlgorithmUp/Down`; returns the *previous* order (the undo token) plus a human description of what moved. Keeps orchestration in the cubit ("cubit orchestrates, widget displays").
- Connect-with-autosolve helper that: writes the bus assignment (reuse `createConnection`/`updateConnection`/`updateParameterValue`), runs `BusFlowSolver`, and if invalid calls `applyReorder`, returning enough detail for the snackbar + undo (undo reverts **both** the assignment and the reorder).

### View — `lib/ui/widgets/routing/bus_lanes_view.dart` + `bus_lanes_painter.dart`
- `BlocBuilder<RoutingEditorCubit, RoutingEditorState>` with the table's `buildWhen` (rebuild on `algorithms`/`connections`/`portOutputModes`/`hasExtendedAuxBuses`). Reads `DistingCubit` for moves/param writes.
- Layout mirrors the table's grid topology (bus→column/rail x, slot→band y), horizontal scroll for many buses.
- **Bouncy reorder animation:** bands are `AnimatedPositioned` keyed by the cubit's stable algorithm IDs (`generateStableAlgorithmIds`), so when the order changes the *same* band springs to its new y with a bouncy curve (e.g. `Curves.easeOutBack`/`elasticOut`, ~300–400ms) — or a spring `AnimationController` if more physicality is wanted. Because moves emit optimistic state immediately, this single mechanism covers drag, auto-solve, and auto-reorder. The dragged band follows the pointer and settles with the same spring on release.
- **Painter** draws: pale empty rails; colored driven rails segmented by `RoutingAnalyzer` sessions; Replace = color change + abrupt end of prior segment + new segment below; Add = darker shade; taps for reads (red when the bus is undriven at that point).
- **Gestures** (widget captures, delegates to cubit):
  - vertical drag on a band → reorder with **resistance** (accumulate dy; only swap when past ~60–70% of a row past the neighbor midpoint; optional haptic) → `moveAlgorithmUp/Down`.
  - drag a port onto a rail / tap an intersection → assign bus → connect-with-autosolve helper → snackbar + Undo on auto-move.
  - tap a write glyph → `togglePortOutputMode`.
  - long-press a tap → clear (`deleteConnectionWithSmartBusLogic`).

### Wire into the existing view switcher
Add `busLanes` to `_RoutingViewMode` (+ `fromString`), a menu item in `_buildViewModeButton`, and a render branch — persistence is automatic via `_setViewMode`.

### Shared refactor
Extract `_buildRoutingFromEditorState` (table) into a shared static (e.g. `RoutingInformation.fromEditorAlgorithms(...)` or a `lib/util/` helper); table and bus view both use it.

## Files

**New:** `lib/core/routing/bus_flow_solver.dart`, `lib/core/routing/slot_reorder_planner.dart`, `lib/core/routing/bus_color_palette.dart`, `lib/ui/widgets/routing/bus_lanes_view.dart`, `lib/ui/widgets/routing/bus_lanes_painter.dart`.

**Modify:** `lib/cubit/routing_editor_cubit.dart` (`applyReorder` + connect-with-autosolve helper), `lib/ui/widgets/routing/routing_editor_widget.dart` (enum + menu + branch + import), `lib/ui/widgets/routing/routing_table_view.dart` (use shared mask builder).

**Tests:** `test/core/routing/bus_flow_solver_test.dart` (valid order, reorder needed, physical-input bus, undriven bus, cycle→backward edge), `test/core/routing/slot_reorder_planner_test.dart` (swap sequences + undo round-trip), `test/ui/widgets/routing/bus_lanes_view_test.dart` (rails/taps/caps render; tap toggles mode; invalid connect triggers reorder + snackbar — mirror `test/ui/widgets/routing/routing_editor_widget_test.dart`), plus the extracted mask-builder unit test. Existing routing tests must stay green.

## Build order (single deliverable, but staged to de-risk)
1. Extract & share the mask builder (no behavior change; table still renders identically).
2. `bus_flow_solver` + `slot_reorder_planner` + tests (pure logic first — the riskiest part).
3. `RoutingEditorCubit.applyReorder` + connect-with-autosolve (+ undo).
4. `bus_color_palette` + `bus_lanes_painter` + `bus_lanes_view` read-only render; add 4th view mode.
5. Interactions: drag-reorder with resistance; assign-bus-with-autosolve + snackbar/Undo; toggle Add/Replace; clear.

## Risks / decisions to confirm during build
- **Solver cycle policy:** unsolvable (feedback) cases must degrade to a marked backward edge, never an error or infinite reorder. Validate against a known feedback preset.
- **Round-trips:** auto-reorder across many slots = several sequential swaps (optimistic emits are instant; only the last 2s verification runs). Acceptable and matches existing MCP behavior; keep the moved-distance small where possible (move the fewest algorithms).
- **Undo scope:** Undo reverts both the bus assignment and the reorder to restore the prior state.
- **Color count/accessibility:** up to 28 (or 64 extended) buses need distinguishable, accessible colors; reuse `AccessibilityColors` and shading rather than 64 unique hues — likely color by bus *group* + shade, with strong distinction for Replace.

## Verification
- `flutter analyze` → zero warnings (hard rule).
- `flutter test` → new solver/planner/view tests + extracted-helper test pass; all existing routing tests still pass.
- `flutter run -d macos` (or hot reload over DTD if already running — do not restart a running app). In a demo/offline preset with a shared-bus read and at least one Replace:
  - **Render:** colored rails; pale empties; Add = darker shade; Replace = new color with the prior wire ending abruptly; reads show taps (red on undriven). Bus Lanes and the Signal Flow table agree on which buses are read/written/replaced.
  - **Drag reorder:** dragging a band reorders only after deliberate resistance; bands **spring** to their new positions with the bouncy easing (no jump); order persists (offline) / reaches hardware (connected).
  - **Connect + autosolve:** connecting an input to a bus written below auto-moves the algorithm, the rails reflow, and a snackbar explains the move with a working **Undo** that restores order *and* the assignment.
  - **Toggle:** tapping a write flips Add↔Replace and the shade/color updates.
  - **Feedback:** a deliberate cycle produces a marked backward edge, not an error.
