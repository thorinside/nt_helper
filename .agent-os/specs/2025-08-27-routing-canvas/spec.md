# Spec Requirements Document

> Spec: Routing Canvas Visual Editor
> Created: 2025-08-27
> Status: Planning

## Overview

The Routing Canvas is a visual editing interface that allows users to interactively modify routing configurations for Disting NT algorithm presets. This feature transforms the complex parameter-based routing system into an intuitive drag-and-drop canvas where users can visually connect ports, understand signal flow, and make routing changes in real-time.

The canvas displays the physical Disting NT hardware (12 inputs, 8 outputs) alongside algorithm ports as visual nodes, with connection lines representing signal routing paths. Users can create, modify, and delete routing connections by dragging between ports, providing immediate visual feedback for complex routing scenarios.

## User Stories

As a Disting NT user, I want to:
- Visually see how signals are routed between physical hardware ports and algorithm ports
- Drag and drop connections between ports to change routing configurations  
- Understand complex poly and width algorithm routing scenarios through visual port representation
- See port types (audio, CV, gate, trigger) clearly distinguished in the interface
- Save routing changes back to algorithm presets
- Undo/redo routing modifications
- Validate routing configurations before applying them

## Spec Scope

- RoutingEditorCubit state management for canvas interactions
- RoutingEditorState containing physical ports, algorithm ports, and connections
- Physical port system (12 hardware inputs, 8 hardware outputs with type information)
- OOP hierarchy for different algorithm routing types (NormalAlgorithmRouting, PolyAlgorithmRouting, WidthAlgorithmRouting)
- Visual canvas widget for displaying ports and routing connections
- Drag-and-drop interaction system for connecting ports
- Real-time validation of routing configurations
- Parameter abstraction layer hiding low-level routing details
- Integration with existing SynchronizedState and preset management
- Undo/redo functionality for routing changes

## Out of Scope

- Audio processing or signal flow simulation
- Advanced canvas features like zooming, panning, or multi-selection
- Routing templates or presets beyond basic configurations
- Integration with external MIDI routing hardware
- Real-time audio monitoring of routing changes

## Expected Deliverable

A complete visual routing editor integrated into the nt_helper application that allows users to:
1. Open any algorithm preset and view its current routing configuration visually
2. Modify routing connections through drag-and-drop interactions
3. Save routing changes back to the preset with proper validation
4. Understand different routing scenarios through clear visual representation

## Spec Documentation

- Tasks: @.agent-os/specs/2025-08-27-routing-canvas/tasks.md
- Technical Specification: @.agent-os/specs/2025-08-27-routing-canvas/sub-specs/technical-spec.md