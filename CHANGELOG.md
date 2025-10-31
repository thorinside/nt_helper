# Changelog

All notable changes to the nt_helper project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.61.0] - 2025-10-30

### ✨ Added
- **Platform-native image sharing for mobile routing editor** - Native share functionality using share_plus package for mobile platforms
- Share icon on mobile devices for easy image sharing from routing editor
- Automatic platform detection for appropriate sharing method

### 🔧 Changed
- Enhanced routing editor controller to support share operations
- Extracted image capture logic into reusable helper functions
- Updated UI to show share icon on mobile, copy icon on desktop

### 🛠️ Technical
- Added share_plus package dependency for mobile sharing capabilities
- Maintained backward compatibility with existing clipboard functionality
- Improved code organization for image capture and sharing logic

### 🐛 Fixed
- Resolves issue #78 - mobile image sharing functionality

---

## [1.60.0] - 2025-10-28

### ✨ Added
- **Epic 4: Complete ES-5 Direct Output Support** - Extended ES-5 routing to all firmware 1.12+ algorithms
  - **Clock Multiplier (clkm)** ES-5 direct output routing
  - **Clock Divider (clkd)** per-channel ES-5 configuration  
  - **Poly CV (pycv)** gate-only ES-5 routing (gates to ES-5, pitch/velocity to normal buses)
- All 5 ES-5-capable algorithms now fully supported: Clock, Euclidean, Clock Multiplier, Clock Divider, Poly CV
- Advanced algorithm metadata management with ES-5 parameter definitions
- Comprehensive ES-5 routing visualization in routing editor

### 🔧 Changed
- Enhanced routing editor to display ES-5 direct connections vs. normal bus routing
- Optimized metadata service performance for multi-channel algorithms
- Improved connection discovery for mixed ES-5/normal output scenarios
- Enhanced user experience for ES-5 expander hardware configuration

### 🛠️ Technical  
- Extended `Es5DirectOutputAlgorithmRouting` base class architecture
- Implemented dual-mode output logic (ES-5 direct vs. normal buses)
- Added per-channel and global ES-5 configuration patterns
- Comprehensive test coverage for all ES-5 routing implementations
- Updated algorithm metadata for Clock Multiplier, Clock Divider, and Poly CV

---

## [1.59.2] - 2025-10-28

### 🐛 Fixed
- Critical bug fixes for drag-and-drop package installation edge cases
- Stability improvements for large preset package processing
- Memory optimization during batch file operations

### 🔧 Changed
- Enhanced error handling for corrupted package files
- Improved progress tracking accuracy during installation
- Optimized conflict detection for complex package structures

---

## [1.59.1] - 2025-10-27

### 🐛 Fixed
- Hotfix for package installation on certain file systems
- Resolved cross-platform path separator issues
- Fixed UI responsiveness during package analysis

### 🔧 Changed
- Improved package file validation logic
- Enhanced error messaging for installation failures
- Streamlined desktop-specific dependency handling

---

## [1.59.0] - 2025-10-27

### ✨ Added
- **Epic 3: Drag-and-Drop Preset Package Installation** - Restored drag-and-drop functionality to Browse Presets dialog
  - Visual feedback with blue border on drag-over
  - Automatic package analysis and manifest validation
  - Intelligent conflict detection against existing SD card files
  - Granular control over file installation with conflict resolution
  - Progress tracking during package installation
  - Cross-platform compatibility (desktop only)
- **Incremental sync** - More efficient algorithm metadata synchronization
- **Improved algorithm rescan UX** - Better user experience during algorithm discovery
- Enhanced fuzzy category matching for algorithm discovery
- CPU usage monitoring for MCP server operations

### 🔧 Changed
- Simplified MCP server implementation with improved connection stability
- Enhanced real-time routing data queries from hardware
- Optimized algorithm matching algorithms
- Improved error handling for SD card communication
- Streamlined preset package workflow (removed 835 lines of obsolete code)

### 🛠️ Technical
- Leveraged existing `PresetPackageAnalyzer`, `FileConflictDetector`, and `PackageInstallDialog` infrastructure
- Refactored sync mechanism for better performance
- Enhanced error handling for hardware communication
- Better resource management for background operations
- Maintained 100% test coverage (388 tests passing)

### 📱 Mobile
- Improved touch responsiveness
- Enhanced mobile-specific UI optimizations
- Better handling of device orientation changes

### 🗑️ Removed
- Obsolete `LoadPresetDialog` widget and associated code (net reduction of 635 lines)

---

## Release History Overview

nt_helper has grown from a simple preset editor to a comprehensive cross-platform application for managing Disting NT Eurorack module presets and algorithms. Key milestones include:

- **Early versions (1.8.x - 1.20.x)**: Core MIDI communication and basic preset management
- **Mid versions (1.21.x - 1.40.x)**: Advanced parameter mapping, visual routing analysis, performance mode
- **Recent versions (1.41.x - 1.58.x)**: MCP server integration, drag & drop support, offline data management
- **Latest versions (1.59.x+)**: Platform-native features, enhanced mobile support, performance optimizations

### 🎯 Core Features Across Versions
- **Comprehensive Preset Management**: Load, save, and create presets with ease
- **Detailed Algorithm Editing**: Access all parameters with custom UI views
- **Advanced Parameter Mapping**: CV, MIDI (with CC detection), and I2C mappings
- **Visual Routing Analysis**: Clear graphical representation of signal flow
- **Performance Mode**: Real-time parameter interaction on a single screen
- **Specialized Editors**: Dedicated UI components like BPM editor
- **MCP Server**: Built-in Model Context Protocol server for AI integration
- **Cross-Platform Support**: Windows, macOS, Linux, iOS, and Android

### 🚀 Development Philosophy
- **Zero tolerance for `flutter analyze` errors**
- **Cubit pattern for state management**
- **Interface-based MIDI layer design**
- **Drift ORM for local data persistence**
- **Object-oriented routing framework**

---

*For detailed technical documentation, see the [CLAUDE/](./CLAUDE/) directory.*
*For the latest releases, visit our [GitHub Releases](https://github.com/thorinside/nt_helper/releases) page.*