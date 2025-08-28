# Spec Requirements Document

> Spec: Algorithm Routing Framework
> Created: 2025-08-27
> Status: Planning

## Overview

The Algorithm Routing Framework provides an object-oriented abstraction layer for managing MIDI routing patterns between input/output pairs in the Disting NT module. The framework defines a base `AlgorithmRouting` class with two specialized subclasses (`PolyAlgorithmRouting`, `MultiChannelAlgorithmRouting`) that handle different routing behaviors while maintaining a consistent API for the UI and state management layers.

This framework replaces the current procedural routing logic with a clean, extensible architecture that separates routing concerns from UI rendering and provides type-safe routing operations with proper validation and error handling.

## User Stories

**As a developer**, I want a unified routing API so that I can work with different routing patterns without knowing their internal implementation details.

**As a developer**, I want type-safe routing operations so that invalid routing configurations are caught at compile time rather than runtime.

**As a UI developer**, I want consistent routing state management so that all routing variants can be rendered with the same UI components.

**As a maintainer**, I want extensible routing architecture so that new routing patterns can be added without modifying existing code.

**As a user**, I want reliable routing behavior so that my MIDI configurations work consistently across all algorithm types.

## Spec Scope

### Core Framework Components

- **Base AlgorithmRouting Class**: Abstract base class defining the routing interface and common functionality
- **PolyAlgorithmRouting Class**: Manages polyphonic routing with gate input and virtual CV ports based on algorithm properties
- **MultiChannelAlgorithmRouting Class**: Supports width-based routing with configurable channel count (default: 1 for normal algorithms, N for width-based algorithms)

### Routing Operations

- **Connection Management**: Create, update, and delete routing connections
- **Validation Logic**: Ensure routing configurations are valid for each routing type
- **State Serialization**: Convert routing state to/from JSON for persistence
- **Conflict Resolution**: Handle conflicting routing requests appropriately
- **Change Notifications**: Emit events when routing configuration changes

### Integration Points

- **Algorithm Integration**: Each algorithm specifies its supported routing type(s)
- **UI Integration**: Routing canvas and controls consume routing state through unified API
- **MIDI Integration**: Routing framework translates abstract connections to MIDI messages
- **Preset Integration**: Routing configurations are included in preset save/load operations

## Out of Scope

- **MIDI Protocol Implementation**: The framework works with abstract routing concepts, not raw MIDI
- **UI Rendering Logic**: Routing classes provide state, but don't handle visual representation
- **Hardware Communication**: Routing framework is agnostic to actual MIDI transmission
- **Algorithm-Specific Logic**: Routing classes handle connection patterns, not audio processing
- **Undo/Redo System**: Command pattern implementation is handled at a higher level

## Expected Deliverable

A complete OOP routing framework consisting of:

1. **Base AlgorithmRouting class** with abstract interface and shared functionality
2. **Two concrete routing implementations** (PolyAlgorithmRouting, MultiChannelAlgorithmRouting) 
3. **Comprehensive unit tests** covering all routing operations and edge cases
4. **Integration with existing algorithm system** maintaining backward compatibility
5. **Updated UI components** that consume the new routing API
6. **Documentation and examples** for adding new routing types

The framework should be production-ready with full test coverage, proper error handling, and seamless integration with the existing codebase.

## Spec Documentation

- Tasks: @.agent-os/specs/2025-08-27-algorithm-routing-framework/tasks.md
- Technical Specification: @.agent-os/specs/2025-08-27-algorithm-routing-framework/sub-specs/technical-spec.md