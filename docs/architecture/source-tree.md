# Source Tree

## Project Structure

```text
nt_helper/
├── lib/
│   ├── main.dart                    # App entry point, initialization
│   ├── disting_app.dart             # Root widget, theme, routing
│   ├── constants.dart               # App constants
│   │
│   ├── cubit/                       # State management (Cubit pattern)
│   │   ├── disting_cubit.dart       # Primary Cubit (composed via delegates/mixins)
│   │   ├── disting_cubit_connection_delegate.dart
│   │   ├── disting_cubit_parameter_fetch_delegate.dart
│   │   ├── disting_cubit_parameter_refresh_delegate.dart
│   │   ├── disting_cubit_plugin_delegate.dart
│   │   ├── disting_cubit_offline_demo_delegate.dart
│   │   ├── disting_cubit_algorithm_ops.dart
│   │   ├── disting_cubit_preset_ops.dart
│   │   ├── disting_cubit_slot_ops.dart
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

## Key Module Purposes

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
- **AppDatabase** - Drift ORM, schema version 10 (Story 7.7 adds `ioFlags` to `Parameters`)
- Tables: Algorithms, Parameters (with `ioFlags`), Presets, PluginInstallations, MetadataCache
- DAOs provide typed queries and operations
