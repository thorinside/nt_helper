# nt_helper Brownfield Architecture Document

## Introduction

This document captures the CURRENT STATE of the **nt_helper** Flutter application, a cross-platform tool for managing Expert Sleepers Disting NT Eurorack module presets via MIDI SysEx communication. This architecture document is designed specifically for AI agents tasked with **maintaining and extending** the existing codebase.

**Critical Philosophy**: This codebase is mature and well-structured. New features should leverage existing services, state management patterns, and infrastructure rather than reinventing solutions. Understanding what exists is more important than building something new.

### Document Scope

Comprehensive documentation of the entire system with emphasis on:
- **Routing Graph System** - Signal flow visualization and connection discovery
- **SysEx Command Architecture** - MIDI communication layer
- **IDistingMidiManager Hierarchy** - Mock, Offline, and Live implementations
- **MCP Server Integration** - External tool access via Model Context Protocol

### Change Log

| Date | Version | Description | Author |
|------|---------|-------------|--------|
| 2025-09-30 | 1.0 | Initial brownfield analysis | BMad Master |
| 2025-11-18 | 1.1 | Epic 7 I/O metadata architecture updates | Winston (Architect) |

## Quick Reference - Key Files and Entry Points

### Critical Files for Understanding the System

**Main Entry Point**:
- `lib/main.dart` - App initialization, window management, database setup, routing service locator

**Core State Management**:
- `lib/cubit/disting_cubit.dart` - Primary application state (1000+ lines, central to everything)
- `lib/cubit/disting_state.dart` - State variants (initial, selectDevice, connected, synchronized)
- `lib/cubit/routing_editor_cubit.dart` - Routing visualization state management

**MIDI Communication Layer**:
- `lib/domain/i_disting_midi_manager.dart` - Abstract interface defining all MIDI operations
- `lib/domain/disting_midi_manager.dart` - Live hardware implementation
- `lib/domain/mock_disting_midi_manager.dart` - Demo mode implementation
- `lib/domain/offline_disting_midi_manager.dart` - Offline mode with cached data
- `lib/domain/disting_nt_sysex.dart` - SysEx message definitions and data structures

**SysEx Request Implementations** (47 total):
- `lib/domain/sysex/requests/` - Each file implements one SysEx command type
- Example: `request_parameter_info.dart`, `set_parameter_value.dart`, `add_algorithm.dart`

**Routing System (Object-Oriented Framework)**:
- `lib/core/routing/algorithm_routing.dart` - Abstract base class for algorithm routing
- `lib/core/routing/connection_discovery_service.dart` - Discovers connections via bus assignments
- `lib/core/routing/poly_algorithm_routing.dart` - Polyphonic algorithm routing
- `lib/core/routing/multi_channel_algorithm_routing.dart` - Multi-channel routing
- `lib/core/routing/models/port.dart` - Port model with direct properties (no metadata maps)
- `lib/core/routing/models/connection.dart` - Connection between ports

**MCP Server**:
- `lib/services/mcp_server_service.dart` - HTTP-based MCP server with multi-client support
- `lib/services/disting_controller.dart` - Abstract interface for MCP tools
- `lib/services/disting_controller_impl.dart` - Implementation of controller interface
- `lib/mcp/tools/algorithm_tools.dart` - MCP tool implementations for algorithms
- `lib/mcp/tools/disting_tools.dart` - MCP tool implementations for device control

**Database Layer**:
- `lib/db/database.dart` - Drift ORM setup, schema version 7
- `lib/db/tables.dart` - Table definitions
- `lib/db/daos/metadata_dao.dart` - Algorithm metadata access
- `lib/db/daos/presets_dao.dart` - Preset data access

**Main UI Screens**:
- `lib/ui/synchronized_screen.dart` - Primary interface when connected to hardware
- `lib/ui/widgets/routing/routing_editor_widget.dart` - Routing visualization (display only, no logic)
- `lib/ui/gallery_screen.dart` - Plugin marketplace browser
- `lib/ui/plugin_manager_screen.dart` - Installed plugins management

**Critical Services**:
- `lib/services/algorithm_metadata_service.dart` - Algorithm metadata management
- `lib/services/metadata_sync_service.dart` - Syncs algorithm data from hardware/API
- `lib/services/settings_service.dart` - Application settings persistence

## High Level Architecture

### Technical Summary

**Project Type**: Cross-platform Flutter application
**Primary Purpose**: MIDI SysEx communication with Disting NT hardware for preset management, algorithm loading, and parameter control
**Operation Modes**:
- Demo (Mock) - No hardware required, simulated data
- Offline - Cached algorithm data, no live hardware
- Connected - Live MIDI communication with Disting NT

**Current Version**: 1.55.1+124
**Minimum Dart SDK**: 3.8.1
**Flutter Version**: 3.35.1 (from GitHub Actions)

### Actual Tech Stack

| Category | Technology | Version | Notes |
|----------|------------|---------|-------|
| Framework | Flutter | 3.35.1 | Cross-platform (Linux, macOS, iOS, Android, Windows) |
| Language | Dart | >=3.8.1 | Null-safe |
| State Management | flutter_bloc | ^9.1.1 | Cubit pattern throughout |
| Database | Drift ORM | ^2.28.1 | SQLite with type-safe queries |
| MIDI | flutter_midi_command | ^0.5.3 | Custom Linux fork via git override |
| MCP Server | mcp_dart | git | Model Context Protocol implementation |
| Code Generation | freezed | ^3.2.0 | Immutable state classes |
| Code Generation | json_serializable | ^6.10.0 | JSON serialization |
| Code Generation | build_runner | ^2.7.1 | Dart code generation |
| Window Management | bitsdojo_window | 0.1.6 | Desktop window control |
| Testing | mocktail | ^1.0.4 | Mocking framework |
| Testing | bloc_test | ^10.0.0 | Bloc testing utilities |

**Key Dependencies**:
- `collection` ^1.19.1 - Collection utilities
- `equatable` ^2.0.7 - Value equality
- `uuid` ^4.5.1 - Unique identifiers
- `crypto` ^3.0.6 - Hashing and secure random
- `file_picker` ^10.3.2 - File selection dialogs
- `desktop_drop` ^0.6.1 - Drag & drop support
- `universal_ble` ^0.9.11 - Bluetooth connectivity
- `uvccamera` ^0.0.13 - USB video device access (for NT display capture)

### Repository Structure Reality Check

- **Type**: Single repository (monorepo structure)
- **Package Manager**: Standard `flutter pub`
- **Notable**: Dependency override for custom Linux MIDI implementation via git

## Source Tree and Module Organization

### Project Structure (Actual)

```text
nt_helper/
├── lib/
│   ├── main.dart                    # App entry point, initialization
│   ├── disting_app.dart             # Root widget, theme, routing
│   ├── constants.dart               # App constants
│   │
│   ├── cubit/                       # State management (Cubit pattern)
│   │   ├── disting_cubit.dart       # PRIMARY STATE - central to everything
│   │   ├── disting_state.dart       # State variants (freezed)
│   │   ├── routing_editor_cubit.dart # Routing visualization state
│   │   ├── routing_editor_state.dart
│   │   ├── video_frame_cubit.dart   # Device display capture
│   │   └── preset_browser_cubit.dart
│   │
│   ├── domain/                      # MIDI communication layer
│   │   ├── i_disting_midi_manager.dart        # Interface (abstract)
│   │   ├── disting_midi_manager.dart          # Live hardware
│   │   ├── mock_disting_midi_manager.dart     # Demo mode
│   │   ├── offline_disting_midi_manager.dart  # Offline with cache
│   │   ├── disting_nt_sysex.dart             # SysEx data structures
│   │   ├── disting_message_scheduler.dart     # Request queuing & retry
│   │   ├── parameter_update_queue.dart        # Batch parameter updates
│   │   │
│   │   ├── sysex/
│   │   │   ├── requests/           # 47 SysEx command implementations
│   │   │   │   ├── request_parameter_info.dart
│   │   │   │   ├── set_parameter_value.dart
│   │   │   │   ├── add_algorithm.dart
│   │   │   │   └── ... (44 more)
│   │   │   └── responses/          # Response parsers
│   │   │
│   │   └── video/                  # USB video capture
│   │       ├── usb_video_manager.dart
│   │       └── video_stream_state.dart
│   │
│   ├── core/                        # Core business logic
│   │   ├── platform/               # Platform-specific implementations
│   │   │
│   │   └── routing/                # ROUTING FRAMEWORK (OO design)
│   │       ├── algorithm_routing.dart              # Abstract base class
│   │       ├── connection_discovery_service.dart   # Discovers connections
│   │       ├── poly_algorithm_routing.dart         # Polyphonic routing
│   │       ├── multi_channel_algorithm_routing.dart
│   │       ├── usb_from_algorithm_routing.dart
│   │       ├── es5_encoder_algorithm_routing.dart
│   │       ├── port_compatibility_validator.dart
│   │       ├── bus_session_resolver.dart          # Bus session management
│   │       ├── bus_spec.dart                      # Bus specifications
│   │       │
│   │       ├── models/             # Routing data models
│   │       │   ├── port.dart       # Port with direct properties
│   │       │   ├── connection.dart
│   │       │   └── routing_state.dart
│   │       │
│   │       └── services/           # Routing services
│   │           ├── algorithm_connection_service.dart
│   │           └── connection_validator.dart
│   │
│   ├── services/                    # Application services
│   │   ├── mcp_server_service.dart         # MCP HTTP server
│   │   ├── disting_controller.dart         # MCP interface (abstract)
│   │   ├── disting_controller_impl.dart    # MCP implementation
│   │   ├── algorithm_metadata_service.dart # Algorithm metadata
│   │   ├── metadata_sync_service.dart      # Hardware/API sync
│   │   ├── settings_service.dart           # App settings
│   │   ├── gallery_service.dart            # Plugin marketplace
│   │   ├── package_creator.dart            # Preset package creation
│   │   └── ... (20+ more services)
│   │
│   ├── db/                          # Database layer (Drift ORM)
│   │   ├── database.dart           # Schema definition, migrations
│   │   ├── tables.dart             # Table definitions
│   │   ├── daos/                   # Data Access Objects
│   │   │   ├── metadata_dao.dart
│   │   │   ├── presets_dao.dart
│   │   │   └── plugin_installations_dao.dart
│   │   └── migrations/             # Schema migrations
│   │
│   ├── mcp/                         # MCP tool implementations
│   │   └── tools/
│   │       ├── algorithm_tools.dart  # Algorithm MCP tools
│   │       └── disting_tools.dart    # Device control MCP tools
│   │
│   ├── models/                      # Data models (freezed + json_serializable)
│   │   ├── algorithm_metadata.dart
│   │   ├── algorithm_parameter.dart
│   │   ├── algorithm_port.dart
│   │   ├── algorithm_connection.dart
│   │   ├── packed_mapping_data.dart
│   │   ├── routing_information.dart
│   │   ├── cpu_usage.dart
│   │   ├── gallery_models.dart     # Plugin marketplace models
│   │   └── ... (40+ models)
│   │
│   ├── ui/                          # UI layer
│   │   ├── synchronized_screen.dart         # Main screen
│   │   ├── add_algorithm_screen.dart
│   │   ├── gallery_screen.dart              # Plugin marketplace
│   │   ├── plugin_manager_screen.dart
│   │   ├── performance_screen.dart
│   │   │
│   │   └── widgets/
│   │       └── routing/            # Routing visualization
│   │           ├── routing_editor_widget.dart  # DISPLAY ONLY
│   │           ├── routing_canvas.dart
│   │           └── ... (routing UI components)
│   │
│   ├── util/                        # Utilities
│   │   ├── in_app_logger.dart
│   │   └── extensions.dart
│   │
│   └── generated/                   # Generated code (build_runner)
│
├── test/                            # Test suite (52 test files)
│   ├── cubit/                       # Cubit tests
│   ├── domain/                      # MIDI layer tests
│   ├── services/                    # Service tests
│   ├── core/                        # Core logic tests
│   │   └── routing/                 # Routing framework tests
│   └── ui/                          # UI tests
│
├── docs/                            # Documentation
│   ├── algorithms/                  # Algorithm metadata (190 files)
│   ├── features/                    # Feature documentation
│   ├── specs/                       # Technical specs
│   ├── audit/                       # Audit reports
│   ├── schema/                      # JSON schemas
│   ├── routing_editor_implementation.md
│   ├── routing_special_cases.md
│   ├── manual-1.10.0.md            # Firmware manual
│   └── ... (extensive documentation)
│
├── CLAUDE/                          # BMAD-METHOD agent documentation
│   ├── index.md                    # Documentation index
│   ├── agents.md                   # Agent definitions
│   ├── tasks.md                    # Task definitions
│   └── ... (70+ documentation files)
│
├── scripts/                         # Build and utility scripts
│   ├── generate_algorithm_stubs.py
│   ├── populate_algorithm_stubs.py
│   ├── sync_params_from_manual.py
│   └── ... (Python scripts for algorithm metadata)
│
├── .github/workflows/               # CI/CD
│   ├── macos-build.yml             # macOS build & notarization
│   ├── ios-build.yml               # iOS build & TestFlight
│   └── tag-build.yml               # Release builds
│
├── assets/                          # Asset bundles
│   ├── metadata/                   # Algorithm metadata JSON
│   └── mcp_docs/                   # MCP documentation
│
├── pubspec.yaml                     # Flutter dependencies
├── analysis_options.yaml            # Linter configuration
├── CLAUDE.md                        # Project instructions (checked in)
├── CLAUDE.local.md                  # Local instructions (not checked in)
└── README.md                        # User-facing documentation
```

### Key Modules and Their Purpose

**State Management** (`lib/cubit/`):
- **DistingCubit** - THE central state manager. Manages MIDI connections, algorithm loading, parameter updates, preset management, CPU monitoring, and video capture. Everything flows through this.
- **RoutingEditorCubit** - Watches DistingCubit for synchronized state, processes routing data into visual representation

**MIDI Layer** (`lib/domain/`):
- **IDistingMidiManager** - Interface defining all 50+ MIDI operations
- **DistingMidiManager** - Live hardware implementation using flutter_midi_command
- **MockDistingMidiManager** - Demo mode with simulated responses
- **OfflineDistingMidiManager** - Offline mode using cached database data
- **DistingMessageScheduler** - Request queue, retry logic, timeout handling

**Routing Framework** (`lib/core/routing/`):
- **AlgorithmRouting** - Abstract base class, factory method creates specialized instances
- **ConnectionDiscoveryService** - Discovers connections via bus assignments (1-12 inputs, 13-20 outputs)
- Specialized implementations for different algorithm types (poly, multi-channel, USB, ES5)

**Services** (`lib/services/`):
- **McpServerService** - HTTP server for Model Context Protocol, multi-client support
- **DistingControllerImpl** - MCP tool backend, delegates to DistingCubit
- **AlgorithmMetadataService** - Loads and manages algorithm metadata from database
- **MetadataSyncService** - Syncs algorithm metadata from hardware or remote API

**Database** (`lib/db/`):
- **AppDatabase** - Drift ORM, schema version 7
- Tables: Algorithms, Parameters, Presets, PluginInstallations, MetadataCache
- DAOs provide typed queries and operations

## Critical Architecture: Routing Graph System

### Overview

The routing system visualizes signal flow between algorithms in a preset. It is **data-driven** and **object-oriented**, with clear separation between:
1. **Data Source**: DistingCubit exposes synchronized Slot data
2. **Business Logic**: OO framework in `lib/core/routing/`
3. **State Management**: RoutingEditorCubit orchestrates the framework
4. **Visualization**: RoutingEditorWidget displays pre-computed state

**CRITICAL**: The visualization layer contains **no business logic**. All routing logic lives in the OO framework.

### Key Components

**AlgorithmRouting Base Class** (`lib/core/routing/algorithm_routing.dart`):
```dart
abstract class AlgorithmRouting {
  RoutingState get state;
  List<Port> get inputPorts;
  List<Port> get outputPorts;
  List<Connection> get connections;

  List<Port> generateInputPorts();
  List<Port> generateOutputPorts();
  bool validateConnection(Port source, Port destination);
}
```

**Factory Pattern**:
- `AlgorithmRouting.fromSlot(Slot slot)` - Creates correct routing instance based on algorithm GUID
- Specialized implementations: `PolyAlgorithmRouting`, `MultiChannelAlgorithmRouting`, `UsbFromAlgorithmRouting`, `Es5EncoderAlgorithmRouting`

**Connection Discovery** (`lib/core/routing/connection_discovery_service.dart`):
- Discovers connections via **shared bus assignments**
- Hardware I/O: Buses 1-12 (inputs), 13-20 (outputs), 35-42 (ES5)
- Algorithm-to-algorithm: Any shared bus number
- Uses `BusSessionResolver` for session-aware connection logic

**Port Model** (`lib/core/routing/models/port.dart`):
- Uses **direct properties**, not generic metadata maps
- Type-safe access to bus numbers, output modes, etc.
- Example properties: `busNumber`, `outputMode`, `parameterNumber`

**RoutingEditorCubit** (`lib/cubit/routing_editor_cubit.dart`):
- Watches `DistingCubit.stream` for synchronized state
- Creates `AlgorithmRouting` instances via factory
- Calls `ConnectionDiscoveryService.discoverConnections()`
- Emits `RoutingEditorState.loaded()` with ports and connections
- Persists node positions to SharedPreferences

### How to Fix Routing Graph Bugs

1. **Identify the symptom**:
   - Missing connections? Check `ConnectionDiscoveryService`
   - Wrong port labels? Check the specific `AlgorithmRouting` subclass
   - Connection validation errors? Check `PortCompatibilityValidator`

2. **Locate the responsible component**:
   - **Port generation**: `AlgorithmRouting.generateInputPorts()` / `generateOutputPorts()`
   - **Connection discovery**: `ConnectionDiscoveryService.discoverConnections()`
   - **Bus session logic**: `BusSessionResolver` and `BusSessionBuilder`
   - **Validation**: `PortCompatibilityValidator.validateConnection()`

3. **Add tests**:
   - Unit tests: `test/core/routing/`
   - Integration tests: Create a test preset with the problematic configuration
   - Use `MockDistingMidiManager` to simulate hardware state

4. **Debug process**:
   - Enable routing debug prints in `ConnectionDiscoveryService`
   - Check `RoutingEditorCubit._processSynchronizedState()` for state flow
   - Verify bus assignments in Slot routing data
   - Use MCP `get_routing` tool to inspect live routing state

### ES-5 Direct Output Support

**Epic 4 Completion** (2025-10-28): Extended ES-5 direct output routing support to three additional algorithms added in firmware 1.12:

- **Clock Multiplier** (clkm) - Single-channel clock multiplier with ES-5 direct output
- **Clock Divider** (clkd) - Multi-channel clock divider with per-channel ES-5 configuration
- **Poly CV** (pycv) - Polyphonic MIDI/CV converter with ES-5 support for gate outputs only

**All ES-5-Capable Algorithms** (5 total):
1. **Clock** (clck) - Single-channel clock generator
2. **Euclidean** (eucp) - Multi-channel Euclidean rhythm generator
3. **Clock Multiplier** (clkm) - Single-channel clock multiplier
4. **Clock Divider** (clkd) - Multi-channel clock divider
5. **Poly CV** (pycv) - Polyphonic MIDI/CV converter (gates only)

**Base Class**: `lib/core/routing/es5_direct_output_algorithm_routing.dart`
- Handles dual-mode output logic: ES-5 direct vs. normal bus routing
- Provides `createConfigFromSlot()` helper for factory creation
- Uses `es5_direct` bus marker for connection discovery
- Algorithms determine output routing based on "ES-5 Expander" parameter value:
  - When ES-5 Expander > 0: Output routes to ES-5 port (normal Output parameter ignored)
  - When ES-5 Expander = 0: Output uses normal bus assignment

**Factory Registration**: `lib/core/routing/algorithm_routing.dart:309-330`
- Registration order: Clock, Euclidean, Clock Multiplier, Clock Divider, Poly CV
- Each implementation provides `canHandle()` and `createFromSlot()` methods
- Poly CV registered earlier via GUID prefix check (around line 280)

**ES-5 Implementation Files**:
- `lib/core/routing/clock_algorithm_routing.dart` - Clock (clck)
- `lib/core/routing/euclidean_algorithm_routing.dart` - Euclidean (eucp)
- `lib/core/routing/clock_multiplier_algorithm_routing.dart` - Clock Multiplier (clkm)
- `lib/core/routing/clock_divider_algorithm_routing.dart` - Clock Divider (clkd)
- `lib/core/routing/poly_algorithm_routing.dart` - Poly CV (pycv) with selective ES-5

**Special Case - Poly CV**: ES-5 applies to gate outputs only, not pitch/velocity CVs. When ES-5 Expander is configured, only the gate signals route directly to ES-5 hardware; pitch and velocity CVs continue using normal bus routing.

**Test Coverage**: `test/core/routing/clock_euclidean_es5_test.dart` and related test files provide comprehensive coverage of ES-5 routing behavior, dual-mode switching, and per-channel configuration.

### Epic 7: I/O Metadata Infrastructure (In Development)

**Goal**: Transition routing framework from pattern matching to hardware-provided I/O metadata.

**Current State (Pattern Matching - To Be Replaced)**:

The routing framework currently infers port properties via parameter name patterns:

```dart
// lib/core/routing/multi_channel_algorithm_routing.dart (to be removed)
final lowerName = paramName.toLowerCase();
final isOutput = lowerName.contains('output') ||
                 (lowerName.contains('out') && !lowerName.contains('input'));

String portType = 'audio';
if (lowerName.contains('cv') || lowerName.contains('gate') || lowerName.contains('clock')) {
  portType = 'cv';
}

final hasMatchingModeParameter = modeParameters?.containsKey('$paramName mode') ?? false;
```

**Problems:**
- Fragile: Breaks if parameter names change
- Incomplete: Can't handle non-standard naming
- Artificial: `gate`/`clock` types don't exist in hardware
- No offline support: Pattern matching requires parameter names only available online

**Hardware I/O Flags - Epic 7 Progress**:

SysEx 0x43 (Parameter Info) now provides I/O metadata in the last byte:

**Bit Layout:**
```
Bits 0-1: powerOfTen (10^n scaling where n = 0-3)
Bits 2-5: ioFlags (4-bit field):
  Bit 0 (value 1): isInput - Parameter is an input
  Bit 1 (value 2): isOutput - Parameter is an output
  Bit 2 (value 4): isAudio - Audio signal (true) vs CV (false)
  Bit 3 (value 8): isOutputMode - Parameter controls output mode
```

**Output Mode Usage (SysEx 0x55 - New)**:

Explicitly maps mode control parameters to affected outputs:

```
Request:  [0xF0, 0x00, 0x21, 0x27, 0x6D, sysExId, 0x55, slot, p_high, p_mid, p_low, 0xF7]
Response: [0xF0, ..., 0x55, slot, source_param, count, affected_1, affected_2, ..., 0xF7]
```

**Epic 7 Implementation Sequence:**

1. **Story 7.3**: Extract I/O flags from SysEx into `ParameterInfo` (runtime)
2. **Story 7.4**: Query output mode usage via SysEx 0x55 and store in `Slot.outputModeMap`
3. **Story 7.7**: Add `ioFlags` column to database schema
4. **Story 7.8**: Generate metadata bundle with I/O flags from hardware
5. **Story 7.9**: Upgrade existing databases with I/O flags
6. **Story 7.5**: Replace I/O pattern matching with flag-based logic
7. **Story 7.6**: Replace output mode pattern matching with usage data

**Benefits:**
- Data-driven port configuration (no heuristics)
- Accurate routing for all algorithms
- Offline mode support via bundled metadata
- Future-proof as firmware evolves

**Status**: Stories 7.1-7.7 are implemented (runtime parsing plus offline storage via the new `ioFlags` column). Stories 7.8-7.9 remain outstanding to regenerate the bundled metadata and backfill existing installs, so offline mode still sees `ioFlags = 0` until those stories land.

**Reference**: See `docs/epic-7-context.md` for complete technical details.

### Important Files

- `lib/core/routing/algorithm_routing.dart` - Base class and factory
- `lib/core/routing/connection_discovery_service.dart` - Connection discovery
- `lib/core/routing/es5_direct_output_algorithm_routing.dart` - ES-5 base class
- `lib/cubit/routing_editor_cubit.dart` - State orchestration
- `lib/ui/widgets/routing/routing_editor_widget.dart` - Visualization only
- `docs/routing_editor_implementation.md` - Implementation details
- `docs/routing_special_cases.md` - Edge cases and workarounds
- `docs/epic-7-context.md` - Epic 7 I/O metadata technical context

## Critical Architecture: SysEx Command System

### Overview

All communication with the Disting NT hardware uses MIDI SysEx (System Exclusive) messages. The architecture is:
1. **Message Definitions**: `lib/domain/disting_nt_sysex.dart`
2. **Request Implementations**: `lib/domain/sysex/requests/` (47 command types)
3. **Scheduler**: `lib/domain/disting_message_scheduler.dart` (queuing, retry, timeout)
4. **Manager**: `lib/domain/disting_midi_manager.dart` (high-level operations)

### SysEx Message Structure

**Format**:
```
[0xF0] [0x00, 0x21, 0x27] [0x6D] [SysExId] [MessageType] [Payload...] [0xF7]
 Start  Expert Sleepers    NT    Device ID  Command      Data         End
```

**Constants** (`lib/domain/disting_nt_sysex.dart`):
- `kSysExStart` = 0xF0
- `kSysExEnd` = 0xF7
- `kExpertSleepersManufacturerId` = [0x00, 0x21, 0x27]
- `kDistingNTPrefix` = 0x6D

**Epic 7 Addition - Output Mode Usage Query (SysEx 0x55)**:

New message type for querying which parameters are affected by mode control parameters:

**Request Format:**
```
[0xF0, 0x00, 0x21, 0x27, 0x6D, sysExId, 0x55, slot, p_high, p_mid, p_low, 0xF7]
```
- Queries which parameters are affected by a mode control parameter
- Parameter number encoded as 16-bit value in three 7-bit bytes

**Response Format:**
```
[0xF0, 0x00, 0x21, 0x27, 0x6D, sysExId, 0x55, slot,
 source_high, source_mid, source_low,  // Mode control parameter
 count,                                 // Number of affected parameters
 affected_1_high, affected_1_mid, affected_1_low,  // First affected param
 ...
 0xF7]
```

**Purpose**: Explicitly maps mode parameters to their controlled outputs, replacing pattern matching like `'$paramName mode'`. Enables accurate Add/Replace mode visualization in routing editor.

**Implementation**: See Story 7.4 in Epic 7 (docs/epic-7-context.md)

### How to Add a New SysEx Command

**Step 1**: Define message type enum

In `lib/domain/disting_nt_sysex.dart`, add to `DistingNTRequestMessageType`:
```dart
enum DistingNTRequestMessageType {
  // ... existing types
  requestMyNewCommand(0x??, hasResponse: true),
}
```

**Step 2**: Create request message class

Create `lib/domain/sysex/requests/request_my_new_command.dart`:
```dart
import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'dart:typed_data';
import 'package:nt_helper/domain/sysex/sysex_message.dart';
import 'package:nt_helper/domain/sysex/sysex_utils.dart';

class RequestMyNewCommandMessage extends SysexMessage {
  final int someParameter;

  RequestMyNewCommandMessage({
    required super.sysExId,
    required this.someParameter,
  });

  @override
  Uint8List encode() {
    final bytes = <int>[
      ...buildHeader(sysExId),
      DistingNTRequestMessageType.requestMyNewCommand.value,
      someParameter & 0x7F,  // Ensure 7-bit
      ...buildFooter(),
    ];
    return Uint8List.fromList(bytes);
  }
}
```

**Step 3**: Add response parser (if needed)

Create `lib/domain/sysex/responses/my_new_command_response.dart`:
```dart
// Parse response bytes into data structure
class MyNewCommandResponse {
  final int someValue;

  MyNewCommandResponse({required this.someValue});

  static MyNewCommandResponse? parse(Uint8List data) {
    if (data.length < expectedLength) return null;
    // Parse data bytes
    return MyNewCommandResponse(someValue: data[offsetIndex]);
  }
}
```

**Step 4**: Add method to IDistingMidiManager interface

In `lib/domain/i_disting_midi_manager.dart`:
```dart
abstract class IDistingMidiManager {
  // ... existing methods
  Future<MyNewCommandResponse?> requestMyNewCommand(int someParameter);
}
```

**Step 5**: Implement in DistingMidiManager

In `lib/domain/disting_midi_manager.dart`:
```dart
@override
Future<MyNewCommandResponse?> requestMyNewCommand(int someParameter) async {
  final message = RequestMyNewCommandMessage(
    sysExId: sysExId,
    someParameter: someParameter,
  );
  final packet = message.encode();
  final key = RequestKey(
    sysExId: sysExId,
    messageType: DistingNTRespMessageType.respMyNewCommand,
  );

  return await _scheduler.sendRequest<MyNewCommandResponse>(
    packet,
    key,
    responseExpectation: ResponseExpectation.required,
  );
}
```

**Step 6**: Add mock implementation

In `lib/domain/mock_disting_midi_manager.dart`:
```dart
@override
Future<MyNewCommandResponse?> requestMyNewCommand(int someParameter) async {
  await _simulateDelay();
  // Return simulated data
  return MyNewCommandResponse(someValue: 42);
}
```

**Step 7**: Add offline implementation

In `lib/domain/offline_disting_midi_manager.dart`:
```dart
@override
Future<MyNewCommandResponse?> requestMyNewCommand(int someParameter) async {
  // Return cached data or throw UnsupportedError
  throw UnsupportedError('MyNewCommand not supported in offline mode');
}
```

**Step 8**: Integrate into DistingCubit (if needed)

In `lib/cubit/disting_cubit.dart`, add methods to expose this functionality:
```dart
Future<MyNewCommandResponse?> getMyNewCommandData(int param) async {
  return state.maybeWhen(
    synchronized: (disting, _, __, ___, ____, _____) async {
      return await disting.requestMyNewCommand(param);
    },
    orElse: () => throw StateError('Not synchronized'),
  );
}
```

**Step 9**: Add tests

Create `test/domain/sysex/requests/request_my_new_command_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/domain/sysex/requests/request_my_new_command.dart';

void main() {
  test('RequestMyNewCommandMessage encodes correctly', () {
    final message = RequestMyNewCommandMessage(
      sysExId: 0,
      someParameter: 42,
    );

    final encoded = message.encode();

    expect(encoded[0], equals(0xF0)); // SysEx start
    expect(encoded[encoded.length - 1], equals(0xF7)); // SysEx end
    // ... more assertions
  });
}
```

### Important Files

- `lib/domain/disting_nt_sysex.dart` - Message type enums, data structures
- `lib/domain/sysex/requests/` - 47 request implementations
- `lib/domain/sysex/responses/` - Response parsers
- `lib/domain/disting_message_scheduler.dart` - Request queue and retry logic
- `lib/domain/i_disting_midi_manager.dart` - Interface
- `lib/domain/disting_midi_manager.dart` - Live implementation

## Critical Architecture: IDistingMidiManager Hierarchy

### Overview

The MIDI manager abstraction allows the app to run in three modes:
1. **Live** - Real hardware communication via flutter_midi_command
2. **Offline** - Cached data from database, no hardware
3. **Mock** - Simulated hardware for demo mode

**Interface**: `lib/domain/i_disting_midi_manager.dart` (113 lines)
- Defines 50+ abstract methods for all MIDI operations
- Groups: Requests, Actions, Lua Operations, SD Card Operations, Scala/Tuning, Backup

### Implementations

**DistingMidiManager** (`lib/domain/disting_midi_manager.dart`):
- **Purpose**: Live hardware communication
- **Dependencies**: `flutter_midi_command`, `DistingMessageScheduler`
- **Key Features**:
  - Uses `DistingMessageScheduler` for request queuing, retry, and timeout
  - Firmware version checking for feature availability (e.g., SD card requires 1.10+)
  - All requests return `Future<T?>` - null indicates failure or timeout

**MockDistingMidiManager** (`lib/domain/mock_disting_midi_manager.dart`):
- **Purpose**: Demo mode without hardware
- **Key Features**:
  - Simulates realistic delays (50-200ms)
  - Returns plausible fake data (e.g., version "1.10.0-mock")
  - Maintains internal preset state
  - Generates algorithm metadata from database

**OfflineDistingMidiManager** (`lib/domain/offline_disting_midi_manager.dart`):
- **Purpose**: Work with cached algorithm data without hardware
- **Key Features**:
  - Reads algorithm metadata from database
  - Maintains local preset state
  - Throws `UnsupportedError` for hardware-only operations (e.g., SD card, screenshot)

### State Selection Logic

In `lib/cubit/disting_cubit.dart`, the manager is selected based on user choice:
```dart
// Demo mode
if (useMock) {
  _midiManager = MockDistingMidiManager(database);
}
// Offline mode
else if (offline) {
  _midiManager = OfflineDistingMidiManager(database);
  _offlineManager = _midiManager as OfflineDistingMidiManager;
}
// Live hardware
else {
  _midiManager = DistingMidiManager(
    midiCommand: _midiCommand,
    inputDevice: inputDevice,
    outputDevice: outputDevice,
    sysExId: 0,
  );
}
```

### How to Add Functionality

**Adding a new operation**:
1. Add abstract method to `IDistingMidiManager`
2. Implement in all three subclasses
3. Consider what makes sense for each mode:
   - Live: Send actual SysEx command
   - Mock: Return simulated data
   - Offline: Return cached data or throw `UnsupportedError`

**Testing**:
- Use `MockDistingMidiManager` in tests to avoid hardware dependency
- See `test/domain/` for examples

### Important Files

- `lib/domain/i_disting_midi_manager.dart` - Interface
- `lib/domain/disting_midi_manager.dart` - Live implementation (380 lines)
- `lib/domain/mock_disting_midi_manager.dart` - Mock implementation (780 lines)
- `lib/domain/offline_disting_midi_manager.dart` - Offline implementation (580 lines)
- `lib/domain/disting_message_scheduler.dart` - Request scheduling logic

## Critical Architecture: MCP Server

### Overview

The MCP (Model Context Protocol) server exposes the app's functionality to external tools and AI agents via HTTP. This enables programmatic control of the Disting NT and access to algorithm metadata.

**Architecture**:
1. **HTTP Server**: `McpServerService` (multi-client StreamableHTTPServerTransport)
2. **Controller Interface**: `DistingController` (abstract)
3. **Controller Implementation**: `DistingControllerImpl` (delegates to DistingCubit)
4. **Tool Implementations**: `algorithm_tools.dart`, `disting_tools.dart`

### McpServerService

**File**: `lib/services/mcp_server_service.dart` (1100+ lines)

**Key Features**:
- HTTP server on port 3000 (default), endpoint `/mcp`
- Multi-client support via session management
- Pre-loads resources from `assets/mcp_docs/` for fast access
- Health monitoring and diagnostics
- Automatic cleanup of disconnected clients

**Lifecycle**:
```dart
// Initialize (in main.dart or DistingApp)
McpServerService.initialize(distingCubit: distingCubit);

// Start server
await McpServerService.instance.start(port: 3000);

// Stop server
await McpServerService.instance.stop();
```

**Session Management**:
- Each client connection gets a unique session ID (UUID)
- Separate `McpServer` instance per session
- Sessions auto-cleanup on disconnect

### DistingController Interface

**File**: `lib/services/disting_controller.dart` (200+ lines)

**Purpose**: Abstract interface for MCP tools to interact with Disting state

**Key Methods**:
- `getCurrentPresetName()` / `setPresetName(String name)`
- `getAlgorithmInSlot(int slotIndex)`
- `getParametersForSlot(int slotIndex)`
- `addAlgorithm(Algorithm algorithm)`
- `clearSlot(int slotIndex)`
- `updateParameterValue(int slotIndex, int parameterNumber, dynamic value)`
- `getAllSlots()`
- `newPreset()` / `savePreset()`
- `takeScreenshot()` - Returns base64 JPEG

**Implementation**: `lib/services/disting_controller_impl.dart`
- Delegates all operations to `DistingCubit`
- Handles state validation (throws `StateError` if not synchronized)
- Performs value scaling and type conversion

### MCP Tools

**Algorithm Tools** (`lib/mcp/tools/algorithm_tools.dart`):
- `list_algorithms` - Search/filter algorithms
- `get_algorithm_details` - Full metadata with fuzzy name matching
- `find_algorithm_in_preset` - Locate algorithm instances

**Disting Tools** (`lib/mcp/tools/disting_tools.dart`):
- `get_current_preset` - Complete preset state
- `add_algorithm` / `remove_algorithm`
- `set_parameter_value` / `get_parameter_value`
- `move_algorithm_up` / `move_algorithm_down`
- `set_preset_name` / `get_preset_name`
- `new_preset` / `save_preset`
- `get_cpu_usage` - Performance monitoring
- `get_module_screenshot` - Visual confirmation
- `build_preset_from_json` - Bulk preset creation

**Resources**:
- `mcp://nt-helper/bus-mapping` - Physical I/O to bus mapping
- `mcp://nt-helper/usage-guide` - Tool best practices
- `mcp://nt-helper/algorithm-categories` - Category list
- `mcp://nt-helper/preset-format` - JSON structure for bulk creation
- `mcp://nt-helper/routing-concepts` - Signal flow fundamentals

### How to Add a New MCP Tool

**Step 1**: Define the tool

In `lib/mcp/tools/disting_tools.dart` (or create new file):
```dart
final myNewTool = McpTool(
  name: 'my_new_tool',
  description: 'Does something useful',
  parameters: {
    'type': 'object',
    'properties': {
      'some_param': {
        'type': 'string',
        'description': 'Parameter description',
      },
    },
    'required': ['some_param'],
  },
  handler: (arguments) async {
    final controller = arguments['controller'] as DistingController;
    final someParam = arguments['some_param'] as String;

    // Implement logic
    final result = await controller.someOperation(someParam);

    return {'result': result};
  },
);
```

**Step 2**: Register the tool

In `lib/services/mcp_server_service.dart`, add to `_createServerForSession()`:
```dart
server.addTool(myNewTool);
```

**Step 3**: Add to documentation

Update `assets/mcp_docs/usage-guide.md` with tool description and examples.

**Step 4**: Test

Use MCP client (e.g., Claude Desktop) to test the new tool:
```json
{
  "method": "tools/call",
  "params": {
    "name": "my_new_tool",
    "arguments": {
      "some_param": "test value"
    }
  }
}
```

### Important Files

- `lib/services/mcp_server_service.dart` - HTTP server and session management
- `lib/services/disting_controller.dart` - Abstract interface
- `lib/services/disting_controller_impl.dart` - Implementation
- `lib/mcp/tools/algorithm_tools.dart` - Algorithm-related tools
- `lib/mcp/tools/disting_tools.dart` - Device control tools
- `assets/mcp_docs/` - MCP resource documentation
- `README.md` (lines 43-191) - MCP tool reference documentation

## Data Models and Database

### Database Schema (Drift ORM)

**File**: `lib/db/database.dart`
**Current Schema Version**: 10
**Recent Changes**:
- v10 (Story 7.7) added the nullable `ioFlags` column to the `Parameters` table to persist firmware I/O metadata.
- Exported metadata bumped to `exportVersion = 2` to include `ioFlags`. Importers remain backward-compatible with version 1 files, and the shipping bundled metadata is still version 1 until Story 7.8 regenerates it.

**Tables**:

**Core Metadata**:
- `Algorithms` - Algorithm definitions (name, GUID, category, description)
- `Specifications` - Algorithm specifications
- `Units` - Unit definitions for parameters
- `Parameters` - Parameter definitions (Epic 7: adds `ioFlags` integer column for I/O metadata)
- `ParameterEnums` - Enum values for parameters
- `ParameterPages` - UI pages grouping parameters
- `ParameterPageItems` - Items within parameter pages

**Epic 7 Schema Changes (Story 7.7)**:
- `Parameters` table now includes a nullable `ioFlags` column (4-bit field encoding input/output/audio/mode flags, `null` meaning no cached data yet).
- Migration history covers schema versions 1-10; upgrading from any version ≤9 automatically adds the column without touching existing parameter data.
- Story 7.8/7.9 will regenerate and re-import the bundled metadata so databases populated before v10 can receive real flag values.

**Preset Data**:
- `Presets` - Preset metadata
- `PresetSlots` - Algorithms in preset slots
- `PresetParameterValues` - Parameter values
- `PresetParameterStringValues` - String parameter values
- `PresetMappings` - CV/MIDI/I2C mappings
- `PresetRoutings` - Routing information

**Cache & Installations**:
- `MetadataCache` - General purpose cache
- `PluginInstallations` - Installed plugin tracking

**DAOs** (Data Access Objects):
- `MetadataDao` - Algorithm metadata queries
- `PresetsDao` - Preset CRUD operations
- `PluginInstallationsDao` - Plugin installation tracking

### Key Models

**Algorithm Metadata** (`lib/models/algorithm_metadata.dart`):
```dart
@freezed
class AlgorithmMetadata with _$AlgorithmMetadata {
  const factory AlgorithmMetadata({
    required String guid,
    required String name,
    required String category,
    required String description,
    required List<AlgorithmParameter> parameters,
    List<AlgorithmPort>? ports,
    List<AlgorithmConnection>? connections,
    List<AlgorithmFeature>? features,
  }) = _AlgorithmMetadata;
}
```

**Slot** (in `lib/cubit/disting_state.dart`):
```dart
class Slot {
  final int index;
  final Algorithm algorithm;
  final List<ParameterInfo> parameters;
  final List<int> parameterValues;
  final RoutingInfo routing;
  final String? customName;
  final Map<int, OutputModeUsage>? outputModeMap;  // Epic 7: Story 7.4
  // ...
}
```

**Epic 7 Addition (Story 7.4)**:
- `outputModeMap`: Maps mode control parameter numbers to lists of affected output parameters
- Populated by querying SysEx 0x55 when `isOutputMode` flag detected
- Used by routing framework to determine Add/Replace mode for output ports

**Models use Freezed + json_serializable**:
- Immutable data classes
- Union types (sealed classes)
- JSON serialization
- Copy-with methods
- Equality comparisons

### Important Files

- `lib/db/database.dart` - Schema definition
- `lib/db/tables.dart` - Table definitions
- `lib/db/daos/` - Data access objects
- `lib/models/` - 40+ model files
- `assets/metadata/` - Algorithm metadata JSON files

## Development and Deployment

### Local Development Setup

**Requirements**:
- Flutter 3.35.1+
- Dart SDK 3.8.1+
- Platform-specific toolchains (Xcode for macOS/iOS, Android Studio for Android)

**Steps**:
1. Clone repository
2. Run `flutter pub get` to install dependencies
3. Run `flutter pub run build_runner build` to generate code
4. For desktop: Run `flutter run -d macos` (or linux/windows)
5. For mobile: Connect device and run `flutter run -d <device-id>`

**Environment Variables** (`.env.example`):
- None required for basic development
- MCP server runs on localhost:3000 by default

**Database**:
- SQLite database auto-created on first run
- Location: Platform-specific app data directory
- Schema migrations handled automatically

### Build and Deployment Process

**Commands**:
- `flutter analyze` - **MUST pass with zero warnings before commit**
- `flutter test` - Run all tests (52 test files)
- `flutter build macos` - Build macOS app
- `flutter build ios` - Build iOS app
- `flutter build android` - Build Android APK/AAB
- `flutter pub run build_runner build` - Generate code

**GitHub Actions** (`.github/workflows/`):

**macOS Build** (`macos-build.yml`):
- Trigger: Tags matching `v*` or push to `macos-build` branch
- Steps:
  1. Flutter setup (3.35.1)
  2. Certificate decoding and keychain creation
  3. Build macOS app
  4. Code signing with Developer ID
  5. Notarization via Apple
  6. Staple notarization ticket
  7. Create ZIP and upload to GitHub Release

**iOS Build** (`ios-build.yml`):
- Similar flow for iOS
- Uploads to TestFlight

**Release Process**:
1. Update version in `pubspec.yaml`
2. Commit and push
3. Tag with `v<version>` (e.g., `v1.55.1`)
4. Push tag - triggers builds
5. GitHub Actions creates release with artifacts

**Platforms**:
- macOS: Fully supported, code-signed and notarized
- iOS: Fully supported, TestFlight distribution
- Linux: Supported, AppImage distribution
- Android: Supported, APK/AAB
- Windows: Supported, executable

### Code Generation

**Freezed** (immutable data classes):
```bash
flutter pub run build_runner build
```

**Drift** (database code generation):
```bash
flutter pub run build_runner build
```

**Running on watch mode** (auto-regenerate):
```bash
flutter pub run build_runner watch
```

## Testing

### Current Test Coverage

**Test Files**: 52 test files across:
- `test/cubit/` - State management tests
- `test/domain/` - MIDI layer tests
- `test/services/` - Service tests
- `test/core/routing/` - Routing framework tests
- `test/ui/` - UI component tests

**Test Stack**:
- `flutter_test` - Core testing framework
- `mocktail` - Mocking framework
- `bloc_test` - Cubit/Bloc testing utilities
- `mockito` - Alternative mocking (used in some tests)

**Testing Philosophy** (from user):
- Tests are NOT required for all code
- New features should include tests to ensure visibility and usefulness
- NOT full test-driven development
- Pragmatic testing approach

### Running Tests

**All tests**:
```bash
flutter test
```

**Specific test file**:
```bash
flutter test test/cubit/disting_cubit_test.dart
```

**With coverage**:
```bash
flutter test --coverage
```

### Test Patterns

**Cubit Testing** (using `bloc_test`):
```dart
blocTest<DistingCubit, DistingState>(
  'emits synchronized state when connected',
  build: () => DistingCubit(mockDatabase),
  act: (cubit) => cubit.connectToDevice(inputDevice, outputDevice),
  expect: () => [
    isA<DistingState>().having((s) => s, 'state', isA<Synchronized>()),
  ],
);
```

**Mocking MIDI Manager**:
```dart
class MockMidiManager extends Mock implements IDistingMidiManager {}

// In test:
when(() => mockMidiManager.requestVersionString())
  .thenAnswer((_) async => '1.10.0');
```

**Routing Tests**:
```dart
test('discovers connections between algorithms', () {
  final routings = [
    PolyAlgorithmRouting(...),
    MultiChannelAlgorithmRouting(...),
  ];

  final connections = ConnectionDiscoveryService.discoverConnections(routings);

  expect(connections, hasLength(greaterThan(0)));
  expect(connections.first.sourcePortId, equals('algo_0_port_0'));
});
```

## Algorithm Metadata Management

### Overview

Algorithm metadata describes what each algorithm does, its parameters, categories, and features. This metadata must be **reviewed and updated** with each new firmware release.

**Sources**:
1. **Database** (`lib/db/`) - Persistent storage
2. **JSON Assets** (`assets/metadata/`) - Bundled with app
3. **Hardware** - Read directly from Disting NT via SysEx
4. **Remote API** - Fetch from nt-gallery-frontend.fly.dev

### Metadata Sync Service

**File**: `lib/services/metadata_sync_service.dart` (900+ lines)

**Purpose**: Synchronize algorithm metadata from hardware or remote API

**Key Features**:
- Incremental sync - only fetch changed algorithms
- Plugin type detection from algorithm info
- Progress callbacks for UI updates
- Rescan algorithms on firmware updates

**Sync Process**:
1. Read number of algorithms from hardware
2. For each algorithm:
   - Request algorithm info (name, GUID, category)
   - Check if exists in database
   - If new or changed, request full details (parameters, pages, enum strings)
3. Store in database
4. Update asset JSON files (for offline use)

**Usage**:
```dart
final syncService = MetadataSyncService(distingCubit, database);

await syncService.syncAllAlgorithms(
  onProgress: (current, total, algorithmName) {
    print('Syncing $algorithmName ($current/$total)');
  },
);
```

### Algorithm Documentation

**Location**: `docs/algorithms/` (190 files)

**Format**: YAML front matter + Markdown
```yaml
---
guid: "{12345678-1234-1234-1234-123456789012}"
name: "Algorithm Name"
category: "Category"
---

# Algorithm Name

Description of the algorithm...

## Parameters

- **Parameter 1**: Description
- **Parameter 2**: Description
```

**Maintenance**:
- Update when new firmware is released
- Add missing descriptions and usage examples
- Python scripts in `scripts/` help automate this

### Important Files

- `lib/services/metadata_sync_service.dart` - Sync service
- `lib/services/algorithm_metadata_service.dart` - Metadata access
- `lib/db/daos/metadata_dao.dart` - Database queries
- `assets/metadata/` - Bundled JSON
- `docs/algorithms/` - Human-readable docs
- `scripts/populate_algorithm_stubs.py` - Automation script

## Coding Standards and Patterns

### Code Quality Requirements

**Zero Tolerance Policy**:
- `flutter analyze` MUST pass with zero warnings/errors before commit
- Fix all analyzer issues immediately
- No exceptions

**Linter**: Uses `package:flutter_lints/flutter.yaml`

### Debugging

**CRITICAL**: Always use `debugPrint()`, never `print()`

**Rationale**: `debugPrint()` throttles output and is stripped in release builds

**Example**:
```dart
debugPrint('[RoutingEditor] Processing ${slots.length} slots');
```

### State Management Patterns

**Cubit Pattern** (throughout app):
- Use `flutter_bloc` package
- States defined with `freezed`
- State variants as union types
- Emit new states, never mutate

**Example**:
```dart
@freezed
class MyState with _$MyState {
  const factory MyState.initial() = Initial;
  const factory MyState.loading() = Loading;
  const factory MyState.loaded(Data data) = Loaded;
  const factory MyState.error(String message) = Error;
}

class MyCubit extends Cubit<MyState> {
  MyCubit() : super(const MyState.initial());

  Future<void> loadData() async {
    emit(const MyState.loading());
    try {
      final data = await fetchData();
      emit(MyState.loaded(data));
    } catch (e) {
      emit(MyState.error(e.toString()));
    }
  }
}
```

### Async Patterns

**Use async/await**, not `.then()`:
```dart
// Good
Future<void> doSomething() async {
  final result = await someAsyncOperation();
  processResult(result);
}

// Bad
Future<void> doSomething() {
  return someAsyncOperation().then((result) {
    processResult(result);
  });
}
```

**Stream subscriptions** must be cancelled:
```dart
StreamSubscription? _subscription;

void listen() {
  _subscription = stream.listen((event) {
    // Handle event
  });
}

@override
void dispose() {
  _subscription?.cancel();
  super.dispose();
}
```

### Error Handling

**Specific exceptions** over generic:
```dart
// Good
throw StateError('Disting not synchronized');
throw ArgumentError.value(slotIndex, 'slotIndex', 'Invalid slot');

// Bad
throw Exception('Something went wrong');
```

**Null safety**:
- Use `?` for nullable types
- Use `!` only when absolutely certain
- Prefer null checks over force unwrap

### File Organization

**One class per file** (generally)

**File naming**: `snake_case.dart`

**Import ordering**:
1. Dart SDK imports
2. Flutter imports
3. Package imports
4. Local imports

**Example**:
```dart
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:bloc/bloc.dart';

import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'package:nt_helper/models/slot.dart';
```

## Common Workflows

### Adding a New Feature

**Step 1**: Understand existing patterns
- Read relevant files in `lib/`
- Check if similar functionality exists
- Identify which services/cubits are involved

**Step 2**: Design with existing infrastructure
- Use existing services (don't recreate)
- Follow Cubit pattern for state
- Delegate to DistingCubit when possible

**Step 3**: Implement
- Add methods to relevant services
- Update state classes if needed
- Add UI components

**Step 4**: Test
- Write tests for new functionality
- Run `flutter analyze` (must pass)
- Run `flutter test`
- Manual testing on target platforms

**Step 5**: Document
- Update CLAUDE.md if architecture changes
- Add comments for complex logic
- Update README if user-facing

### Fixing a Bug

**Step 1**: Reproduce
- Create minimal test case
- Use `MockDistingMidiManager` if possible

**Step 2**: Locate the issue
- Use debug prints (`debugPrint`)
- Check state flow in Cubit
- Verify SysEx message format
- For routing: Check connection discovery logic

**Step 3**: Fix
- Make minimal changes
- Follow existing patterns
- Don't introduce new dependencies

**Step 4**: Verify
- Run existing tests
- Add new test for the bug
- Test on actual hardware if MIDI-related
- Run `flutter analyze`

### Working with MCP Tools

**To test MCP tools locally**:

1. Run app with DTD enabled:
```bash
flutter run -d macos --print-dtd
```

2. Note the DTD URL from output

3. Connect MCP client (e.g., Claude Desktop) using DTD URL

4. Test tools via MCP client

**To add a new tool**: See "MCP Server" section above

## Troubleshooting

### Common Issues

**Issue**: `flutter analyze` fails
- **Solution**: Fix all warnings/errors. Zero tolerance policy.

**Issue**: Code generation fails
- **Solution**: Run `flutter clean && flutter pub get && flutter pub run build_runner build --delete-conflicting-outputs`

**Issue**: MIDI connection times out
- **Solution**: Check `SettingsService().requestTimeout` and `interMessageDelay`. Increase if needed.

**Issue**: Routing connections not showing
- **Solution**: Check bus assignments in slot routing data. Enable debug prints in `ConnectionDiscoveryService`.

**Issue**: MCP server won't start
- **Solution**: Check port 3000 is not in use. Try different port in `McpServerService.start(port: 3001)`.

**Issue**: Database migration fails
- **Solution**: Check `lib/db/database.dart` migration logic. May need to increment schema version.

### Debug Tools

**MCP Diagnostics**:
```dart
final diagnostics = McpServerService.instance.connectionDiagnostics;
debugPrint(diagnostics.toString());
```

**Routing Debug Prints**:
- Enable in `ConnectionDiscoveryService`
- Shows bus registry, connection discovery, port assignments

**SysEx Message Logging**:
- Enable in `DistingMessageScheduler`
- Shows all sent/received messages with timestamps

**CPU Usage Monitoring**:
```dart
distingCubit.cpuUsageStream.listen((usage) {
  debugPrint('CPU1: ${usage.cpu1}%, CPU2: ${usage.cpu2}%');
});
```

## Appendix - Useful Commands and Scripts

### Frequently Used Commands

```bash
# Development
flutter run -d macos                      # Run on macOS
flutter run -d macos --print-dtd          # Run with MCP DTD connection
flutter pub get                           # Install dependencies
flutter pub run build_runner build        # Generate code
flutter pub run build_runner watch        # Auto-generate code

# Quality Assurance
flutter analyze                           # MUST pass with zero warnings
flutter test                              # Run all tests
flutter test --coverage                   # With coverage report
flutter test test/cubit/disting_cubit_test.dart  # Run specific test

# Building
flutter build macos                       # Build macOS app
flutter build ios                         # Build iOS app
flutter build apk                         # Build Android APK
flutter build appbundle                   # Build Android AAB

# Maintenance
flutter clean                             # Clean build cache
flutter pub upgrade                       # Upgrade dependencies
flutter pub outdated                      # Check for updates

# Database
# (Database is auto-created, no manual commands needed)
```

### Python Scripts (for algorithm metadata)

```bash
# Located in scripts/

./generate_algorithm_stubs.py            # Create stub docs for new algorithms
python3 populate_algorithm_stubs.py      # Fill stubs with metadata
python3 sync_params_from_manual.py       # Extract params from firmware manual
python3 enrich_from_manual.py            # Enrich metadata from manual
./run_manual_scan.sh                     # Scan firmware manual for all algorithms
```

### Git Workflow

```bash
# Standard workflow
git checkout -b feature/my-new-feature
# ... make changes ...
flutter analyze                           # MUST pass
flutter test                              # Run tests
git add .
git commit -m "feat: Add my new feature"
git push origin feature/my-new-feature
# Create PR on GitHub
```

### Debugging and Troubleshooting

**View app logs**:
```bash
flutter logs                              # Tail logs from running app
```

**Attach to running app**:
```bash
flutter attach                            # Attach to running app for hot reload
```

**Check DTD connection** (for MCP):
```bash
# DTD URL is printed when running with --print-dtd
# Look for: "The Flutter DevTools debugger and profiler on macOS is available at: <URL>"
```

**Common Issues**:
- Port conflicts: Change MCP server port in code
- MIDI device not found: Check permissions and device connection
- Database locked: Close all instances of app

---

## Summary for AI Agents

**This codebase is mature and well-structured.** Your primary task is **maintenance and extension**, not reinvention.

**Before implementing a new feature**:
1. ✅ Read relevant existing code
2. ✅ Identify which services/cubits are involved
3. ✅ Check if similar functionality exists
4. ✅ Use existing patterns and infrastructure
5. ✅ Follow the Cubit pattern for state management
6. ✅ Delegate to DistingCubit when possible

**Critical areas requiring deep understanding**:
- **Routing Graph**: OO framework in `lib/core/routing/`, connection discovery via bus assignments
- **SysEx Commands**: 47 command types in `lib/domain/sysex/requests/`, follow the pattern when adding new ones
- **IDistingMidiManager**: Three implementations (Live, Mock, Offline), understand when each is used
- **MCP Server**: HTTP-based server, multi-client, tool implementations in `lib/mcp/tools/`

**Quality requirements**:
- `flutter analyze` MUST pass with zero warnings before committing
- Use `debugPrint()` for logging, never `print()`
- New features should include tests (pragmatic, not TDD)
- Follow existing code patterns and style

**Algorithm metadata**:
- Must be reviewed/updated with each firmware release
- Use `MetadataSyncService` to sync from hardware
- Document in `docs/algorithms/`

**Common tasks**:
- Adding SysEx command: Follow the 9-step process in "Critical Architecture: SysEx Command System"
- Fixing routing bugs: See "How to Fix Routing Graph Bugs" section
- Adding MCP tool: Follow the 4-step process in "Critical Architecture: MCP Server"

**When in doubt**:
- Check existing code for similar patterns
- Read the extensive documentation in `docs/` and `CLAUDE/`
- Use `MockDistingMidiManager` for testing
- Ask specific questions about areas you don't understand

This codebase values **pragmatism over perfection**, **maintenance over novelty**, and **understanding over reinvention**.
