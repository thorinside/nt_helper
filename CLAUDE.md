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

The routing editor uses a comprehensive object-oriented framework for data-driven routing:

- **Source of truth**: `DistingCubit` exposes synchronized `Slot`s (algorithm + parameters + values).
- **OO Framework**: `lib/core/routing/` provides a complete routing framework:
  - `AlgorithmRouting` abstract base class with factory method `AlgorithmRouting.fromSlot()`
  - `PolyAlgorithmRouting` for polyphonic algorithms (gate-driven CV, declared outputs)
  - `MultiChannelAlgorithmRouting` for multi-channel/width-based algorithms
  - `ConnectionDiscoveryService` automatically discovers connections from shared bus assignments:
    - Hardware inputs: buses 1-12 connect physical inputs to algorithm ports
    - Hardware outputs: buses 13-20 connect algorithm ports to physical outputs  
    - Algorithm-to-algorithm: any shared bus creates connections between algorithms
  - `RoutingFactory` creates appropriate routing instances based on metadata
  - `Port` and `Connection` models with typesafe direct properties
- **State Management**: `RoutingEditorCubit` uses the OO framework to:
  - Call `AlgorithmRouting.fromSlot()` to create routing instances from live `Slot` data
  - Use `ConnectionDiscoveryService.discoverConnections()` for automatic connection discovery
  - Store computed ports and connections in state for visualization
- **Visualization Layer**: `RoutingEditorWidget` purely displays pre-computed routing data; contains no routing business logic.

Important architectural principles:
- All routing logic lives in the OO framework in `lib/core/routing/`
- `RoutingEditorCubit` orchestrates the framework but doesn't contain routing logic
- Connections are discovered automatically via shared bus assignments (not manual extraction)
- `RoutingEditorWidget` is purely a visualization layer

Key files:
- `lib/core/routing/algorithm_routing.dart` – abstract base class and factory method for creating routing instances
- `lib/core/routing/connection_discovery_service.dart` – automatic connection discovery from bus assignments
- `lib/core/routing/poly_algorithm_routing.dart` – polyphonic algorithm routing implementation
- `lib/core/routing/multi_channel_algorithm_routing.dart` – multi-channel algorithm routing implementation
- `lib/core/routing/routing_factory.dart` – factory for creating routing instances from metadata
- `lib/core/routing/models/` – `Port`, `Connection`, and related model classes
- `lib/cubit/routing_editor_cubit.dart` – orchestrates the OO framework, stores routing state
- `lib/ui/widgets/routing/routing_editor_widget.dart` – visualization layer only

### Visualization Flow (Diagram)

```
┌──────────────────┐
│  DistingCubit    │
│  (Synchronized   │
│  Slots: params & │
│  values)         │
└─────────┬────────┘
          │ Slot data
          ▼
┌─────────────────────┐         ┌─────────────────────────────┐
│ RoutingEditorCubit  │   →     │      OO Framework           │
│ (orchestrates       │         │  lib/core/routing/          │
│  framework)         │         │                             │
└─────────┬───────────┘         │  ┌─────────────────────────┐ │
          │                     │  │ AlgorithmRouting        │ │
          │                     │  │ .fromSlot() factory     │ │
          │                     │  └─────────┬───────────────┘ │
          │                     │            │                 │
          │                     │            ▼                 │
          │                     │  ┌─────────────────────────┐ │
          │                     │  │ PolyAlgorithmRouting    │ │
          │                     │  │ MultiChannelRouting     │ │
          │                     │  └─────────┬───────────────┘ │
          │                     │            │ ports           │
          │                     │            ▼                 │
          │                     │  ┌─────────────────────────┐ │
          │                     │  │ ConnectionDiscovery     │ │
          │                     │  │ Service (bus-based)     │ │
          │                     │  └─────────┬───────────────┘ │
          │                     └────────────┼─────────────────┘
          │                                  │ connections
          ▼                                  ▼
┌─────────────────────┐          ┌─────────────────────────┐
│ RoutingEditorState  │          │  RoutingEditorWidget    │
│ (ports &            │    →     │  (visualization only)   │
│  connections)       │          │                         │
└─────────────────────┘          └─────────────────────────┘
```

### Do / Don't

Do
- Use the OO framework in `lib/core/routing/` for all routing logic
- Call `AlgorithmRouting.fromSlot()` factory method to create routing instances from live `Slot` data
- Use `ConnectionDiscoveryService.discoverConnections()` for automatic connection discovery based on bus assignments
- Let the framework handle port creation and connection logic - don't duplicate this in the cubit
- Keep `RoutingEditorWidget` purely as a visualization layer with no routing business logic
- Use the `RoutingFactory` pattern for creating appropriate routing implementations
- Trust the automatic bus-based connection discovery (buses 1-12 for inputs, 13-20 for outputs)
- Store only computed results (ports, connections) in `RoutingEditorState`

Don't
- Don't add routing logic directly to `RoutingEditorCubit` - use the OO framework instead
- Don't use removed services like `PortExtractionService` or `AutoRoutingService`
- Don't manually extract ports or manage connections - let `ConnectionDiscoveryService` handle it
- Don't infer ports from Specifications or docs for visualization — they're for build-time constraints, not live routing UI
- Don't put routing decision logic in the visualization layer (`RoutingEditorWidget`)
- Don't bypass the `AlgorithmRouting.fromSlot()` factory method - it ensures proper routing instance creation
- Don't create manual connections - trust the automatic bus-based discovery system

### Port Model Direct Properties

The Port model uses typesafe direct properties instead of generic metadata maps. Examples of direct property access:

**Polyphonic Properties:**
```dart
final port = Port(
  id: 'poly_voice_1',
  name: 'Voice 1 Gate',
  type: PortType.gate,
  direction: PortDirection.input,
  isPolyVoice: true,
  voiceNumber: 1,
  busValue: 4,
  isVirtualCV: false,
);

// Access properties directly
if (port.isPolyVoice) {
  final voice = port.voiceNumber; // Type-safe int?
  final bus = port.busValue;      // Type-safe int?
}
```

**Multi-Channel Properties:**
```dart
final stereoPort = Port(
  id: 'stereo_left',
  name: 'Channel 1 Left',
  type: PortType.audio,
  direction: PortDirection.input,
  isMultiChannel: true,
  channelNumber: 1,
  isStereoChannel: true,
  stereoSide: 'left',
  isMasterMix: false,
);

// Check channel properties
if (stereoPort.isMultiChannel && stereoPort.isStereoChannel) {
  final side = stereoPort.stereoSide; // Type-safe String?
  final channel = stereoPort.channelNumber; // Type-safe int?
}
```

**Bus Assignment Properties:**
```dart
final busPort = Port(
  id: 'cv_input',
  name: 'CV Input',
  type: PortType.cv,
  direction: PortDirection.input,
  busValue: 5,
  busParam: 'frequency',
  parameterNumber: 10,
);

// Access bus information
final bus = busPort.busValue;           // int?
final paramName = busPort.busParam;     // String?
final paramNum = busPort.parameterNumber; // int?
```

## Development Standards

**Code Quality:** Zero tolerance for `flutter analyze` errors.

**Debugging:** Always use `debugPrint()`, never `print()`.

**Workflow:** Feature branches required, PR approval needed.

## Task Master AI Instructions
**Import Task Master's development workflow commands and guidelines, treat as if import is in the main CLAUDE.md file.**
@./.taskmaster/CLAUDE.md