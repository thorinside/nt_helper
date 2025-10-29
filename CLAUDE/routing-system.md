# Routing System

The routing editor uses an object-oriented framework for data-driven routing visualization:

## Architecture
- **Source of Truth**: `DistingCubit` exposes synchronized `Slot`s (algorithm + parameters + values)
- **OO Framework**: `lib/core/routing/` contains all routing logic
  - `AlgorithmRouting.fromSlot()` factory creates routing instances from live Slot data
  - Specialized implementations: `PolyAlgorithmRouting`, `MultiChannelAlgorithmRouting`, `Es5DirectOutputAlgorithmRouting`, etc.
  - `ConnectionDiscoveryService` discovers connections via bus assignments (1-12 inputs, 13-20 outputs)
- **State Management**: `RoutingEditorCubit` orchestrates the framework, stores computed state
- **Visualization**: `RoutingEditorWidget` purely displays pre-computed data

## ES-5 Direct Output Support (Epic 4 - Completed 2025-10-28)

Five algorithms support ES-5 direct output routing, where outputs can route directly to ES-5 expander hardware:

1. **Clock** (clck) - Single-channel clock generator
2. **Euclidean** (eucp) - Multi-channel Euclidean rhythm generator
3. **Clock Multiplier** (clkm) - Single-channel clock multiplier
4. **Clock Divider** (clkd) - Multi-channel clock divider
5. **Poly CV** (pycv) - Polyphonic MIDI/CV converter (gates only)

**Base Class**: `lib/core/routing/es5_direct_output_algorithm_routing.dart`
- Handles dual-mode output logic (ES-5 direct vs. normal bus routing)
- Provides `createConfigFromSlot()` helper for factory creation
- Uses `es5_direct` bus marker for connection discovery

**Dual-Mode Behavior**:
- When "ES-5 Expander" parameter > 0: Output routes to ES-5 port (normal Output parameter ignored)
- When "ES-5 Expander" parameter = 0: Output uses normal bus assignment
- Poly CV special case: ES-5 applies to gate outputs only; pitch/velocity CVs use normal buses

## Key Principles
- All routing logic lives in the OO framework (`lib/core/routing/`)
- Connections are discovered automatically via shared bus assignments
- Port model uses typesafe direct properties (no generic metadata maps)
- The visualization layer contains no business logic
- ES-5 algorithms use dual-mode output: direct to ES-5 when configured, or normal bus routing

## Important Files
- `lib/core/routing/algorithm_routing.dart` – Base class and factory
- `lib/core/routing/es5_direct_output_algorithm_routing.dart` – ES-5 base class
- `lib/core/routing/connection_discovery_service.dart` – Connection discovery
- `lib/cubit/routing_editor_cubit.dart` – State orchestration
- `lib/ui/widgets/routing/routing_editor_widget.dart` – Visualization only

## ES-5 Implementation Files
- `lib/core/routing/clock_algorithm_routing.dart` - Clock (clck)
- `lib/core/routing/euclidean_algorithm_routing.dart` - Euclidean (eucp)
- `lib/core/routing/clock_multiplier_algorithm_routing.dart` - Clock Multiplier (clkm)
- `lib/core/routing/clock_divider_algorithm_routing.dart` - Clock Divider (clkd)
- `lib/core/routing/poly_algorithm_routing.dart` - Poly CV (pycv) with selective ES-5

## Test Coverage
- `test/core/routing/clock_euclidean_es5_test.dart` - Clock and Euclidean tests
- `test/core/routing/clock_multiplier_es5_test.dart` - Clock Multiplier tests
- `test/core/routing/clock_divider_es5_test.dart` - Clock Divider tests
- `test/core/routing/poly_cv_es5_test.dart` - Poly CV ES-5 tests
