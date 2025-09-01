# Product Roadmap

> Last Updated: 2025-09-01
> Version: 1.1.0
> Status: Active Development

## Phase 0: Foundation - COMPLETED (3-4 months)

**Goal:** Establish core MIDI communication and preset management capabilities
**Success Criteria:** Reliable bidirectional MIDI SysEx communication with comprehensive preset management

### Completed Features

- **Core MIDI Infrastructure**
  - MIDI SysEx communication with Disting NT hardware
  - Interface-based MIDI layer (mock, offline, live implementations)
  - Robust error handling and connection management

- **Preset Management System**
  - Comprehensive preset management (load/save/create)
  - Drag & drop preset installation
  - Backup and restore functionality
  - Cross-platform file handling

- **Algorithm Support**
  - Algorithm parameter editing with specialized UI views
  - CV, MIDI, and I2C parameter mapping
  - Offline algorithm metadata management
  - Multiple operation modes (Demo, Offline, Connected)

- **Architecture Foundation**
  - Cubit-based state management with flutter_bloc
  - Drift ORM database layer with SQLite
  - Cross-platform Flutter implementation
  - Zero-error code quality standards

## Phase 1: Routing Visualization - IN PROGRESS (2-3 months)

**Goal:** Complete visual routing editor with comprehensive signal flow analysis
**Success Criteria:** Users can visualize and understand complex routing configurations through intuitive canvas interface

### Current Progress

- **Routing Editor Architecture** ✓
  - Object-oriented routing framework in lib/core/routing/
  - AlgorithmRouting base class with factory pattern (.fromSlot())
  - PolyAlgorithmRouting for gate-driven CV and declared outputs
  - MultiChannelAlgorithmRouting for width-based routing
  - ConnectionDiscoveryService for automatic bus-based connection discovery
  - RoutingEditorWidget for pure visualization (no business logic)
  - Automatic connection discovery from bus assignments (1-12 inputs, 13-20 outputs)
  - Auto-refresh when algorithm parameters change

### Remaining Features

- **Enhanced Routing Visualization**
  - Interactive connection editing
  - Real-time routing updates
  - Connection validation and conflict detection
  - Export routing diagrams

- **Advanced Routing Features**
  - Routing templates and presets
  - Automated routing suggestions
  - Complex multi-algorithm routing scenarios

## Phase 2: Performance & Live Features (2-3 months)

**Goal:** Optimize for live performance with real-time control capabilities
**Success Criteria:** Sub-10ms parameter response times with stable performance mode

### Must-Have Features

- **Performance Mode Enhancement**
  - Optimized real-time parameter control
  - MIDI CC mapping and automation
  - Performance preset quick-switching
  - Latency optimization and monitoring

- **Live Performance Tools**
  - Scene management for live sets
  - Hardware controller integration
  - Performance statistics and monitoring
  - Emergency fallback modes

## Phase 3: Integration & Ecosystem (3-4 months)

**Goal:** Expand integration capabilities and external tool ecosystem
**Success Criteria:** Seamless integration with major DAWs and external control surfaces

### Must-Have Features

- **MCP Server Enhancement**
  - Advanced Model Context Protocol features
  - External tool API expansion
  - Plugin architecture for extensions

- **DAW Integration**
  - VST/AU plugin development
  - MIDI mapping standardization
  - Timeline synchronization
  - Automation recording and playback

- **Hardware Ecosystem**
  - Multiple Disting NT support
  - Other Expert Sleepers module support
  - Generic Eurorack module framework

## Phase 4: Advanced Features & AI (4-5 months)

**Goal:** Implement intelligent features and advanced workflow automation
**Success Criteria:** AI-assisted patch creation and intelligent routing suggestions

### Must-Have Features

- **Intelligent Patch Analysis**
  - AI-powered routing suggestions
  - Patch complexity analysis
  - Performance optimization recommendations
  - Automated documentation generation

- **Advanced Workflow Tools**
  - Version control for patches
  - Collaborative patch sharing
  - Cloud synchronization
  - Advanced backup strategies

- **Community Features**
  - Patch sharing platform integration
  - Community preset library
  - Rating and review system
  - Tutorial and learning resources