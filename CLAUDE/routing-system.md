# Routing System

The routing editor uses an object-oriented framework for data-driven routing visualization:

## Architecture
- **Source of Truth**: `DistingCubit` exposes synchronized `Slot`s (algorithm + parameters + values)
- **OO Framework**: `lib/core/routing/` contains all routing logic
  - `AlgorithmRouting.fromSlot()` factory creates routing instances from live Slot data
  - Specialized implementations: `PolyAlgorithmRouting`, `MultiChannelAlgorithmRouting`, etc.
  - `ConnectionDiscoveryService` discovers connections via bus assignments (1-12 inputs, 13-20 outputs)
- **State Management**: `RoutingEditorCubit` orchestrates the framework, stores computed state
- **Visualization**: `RoutingEditorWidget` purely displays pre-computed data

## Key Principles
- All routing logic lives in the OO framework (`lib/core/routing/`)
- Connections are discovered automatically via shared bus assignments
- Port model uses typesafe direct properties (no generic metadata maps)
- The visualization layer contains no business logic

## Important Files
- `lib/core/routing/algorithm_routing.dart` – Base class and factory
- `lib/core/routing/connection_discovery_service.dart` – Connection discovery
- `lib/cubit/routing_editor_cubit.dart` – State orchestration
- `lib/ui/widgets/routing/routing_editor_widget.dart` – Visualization only
