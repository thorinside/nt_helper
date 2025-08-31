# Product Mission

> Last Updated: 2025-08-31
> Version: 1.0.0

## Pitch

nt_helper is a cross-platform Flutter application that bridges the gap between Eurorack hardware and modern software workflows. It provides comprehensive MIDI SysEx communication with the Disting NT module, enabling musicians to manage presets, load algorithms, and control parameters with an intuitive interface that works seamlessly across desktop and mobile platforms.

## Users

### Primary Users
- **Eurorack Musicians**: Electronic music producers who use the Disting NT module in their modular synthesizer setups
- **Live Performers**: Artists who need real-time parameter control and preset switching during performances
- **Studio Producers**: Musicians who want to integrate Disting NT workflows into their DAW-based production environments

### User Personas
- **The Touring Artist**: Needs reliable preset management and performance mode for live shows
- **The Studio Producer**: Wants seamless integration with existing workflows and backup/restore capabilities
- **The Sound Designer**: Requires deep parameter control and routing visualization for complex patches

## The Problem

Eurorack musicians using the Disting NT module face several significant challenges:

1. **Limited Hardware Interface**: The Disting NT's small screen and minimal controls make complex preset management and parameter editing cumbersome
2. **Preset Management Complexity**: Organizing, backing up, and transferring presets between devices is difficult without proper tooling
3. **Parameter Visibility**: Understanding and visualizing complex routing and parameter relationships is challenging on hardware alone
4. **Cross-Platform Gaps**: No unified solution exists that works consistently across desktop and mobile platforms
5. **Workflow Integration**: Difficulty integrating Disting NT control into modern music production workflows

## Differentiators

### Technical Excellence
- **Cross-Platform Unity**: Single codebase supporting Linux, macOS, iOS, Android, and Windows
- **Robust MIDI Implementation**: Reliable SysEx communication with comprehensive error handling
- **Offline Capability**: Full functionality without hardware connection for preparation and planning
- **Visual Routing Analysis**: Canvas-based routing visualization unique in the Eurorack ecosystem

### User Experience
- **Multiple Operation Modes**: Demo, Offline, and Connected modes accommodate different use cases
- **Performance-First Design**: Real-time parameter control optimized for live performance
- **Drag-and-Drop Simplicity**: Intuitive preset installation and management
- **Professional Architecture**: Cubit-based state management ensures reliable, predictable behavior

### Integration & Extensibility
- **MCP Server Integration**: Model Context Protocol support enables external tool ecosystem
- **Modern Development Standards**: Zero-tolerance quality standards with comprehensive testing
- **Open Architecture**: Interface-based MIDI layer supports future hardware extensions

## Key Features

### Core Functionality
- **MIDI SysEx Communication**: Bidirectional communication with Disting NT hardware
- **Comprehensive Preset Management**: Load, save, create, and organize presets with full backup/restore
- **Algorithm Parameter Control**: Specialized UI views for different parameter types (CV, MIDI, I2C)
- **Visual Routing Editor**: Canvas-based display of signal routing and parameter relationships

### Advanced Capabilities  
- **Performance Mode**: Real-time parameter control optimized for live performance scenarios
- **Cross-Platform Support**: Native performance on desktop and mobile with platform-specific optimizations
- **Offline Algorithm Management**: Complete algorithm metadata management without hardware dependency
- **External Tool Integration**: MCP server enables integration with other music production tools

### User Experience Features
- **Multiple Operation Modes**: Seamless switching between Demo, Offline, and Connected modes
- **Drag-and-Drop Installation**: Simple preset and algorithm installation workflows
- **Responsive Interface**: Material Design with custom components optimized for music production
- **Professional Workflow**: Git-like versioning concepts applied to preset management