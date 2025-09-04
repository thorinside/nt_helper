# Spec Requirements Document

> Spec: Physical IO Node Redesign
> Created: 2025-09-04
> Status: Planning

## Overview

Create a universal port widget and redesign all nodes in the routing editor to use consistent port visualization. Currently, physical I/O nodes use JackConnectionWidget while algorithm nodes use different port rendering approaches. This spec establishes a single port_widget used by both algorithm nodes and physical I/O nodes, creating true design system unification across all routing visualization.

## User Stories

- As a user, I want all nodes (algorithm and physical I/O) to use consistent port visualization for unified design language
- As a user, I want physical input nodes (I1-I12) to have labels on the left and connection ports on the right for clear signal flow direction
- As a user, I want physical output nodes (O1-O8) to have connection ports on the left and labels on the right to indicate signal destination
- As a user, I want both node types to be draggable so I can organize my routing layout as needed
- As a user, I want node titles to be simple ("Inputs"/"Outputs") without decorative icons for clean presentation
- As a user, I want clean node designs without background colors on text elements that detract from the visual consistency

## Spec Scope

- Create universal port_widget used by both algorithm nodes and physical I/O nodes
- Redesign physical input node widget to use port_widget
- Redesign physical output node widget to use port_widget
- Redesign algorithm nodes to use port_widget
- Implement left-aligned labels (I1-I12) with right-aligned port sockets for input nodes
- Implement left-aligned port sockets with right-aligned labels (O1-O8) for output nodes
- Add simple "Inputs" and "Outputs" titles without icons
- Make both node types draggable for layout organization only
- Update routing editor to use port_widget across all node types
- Remove JackConnectionWidget, existing algorithm port rendering, and connection gesture handling after implementation

## Out of Scope

- Changes to algorithm node design patterns (maintain existing as reference)
- Modifications to connection logic or discovery mechanisms
- Changes to physical IO port definitions or bus assignments
- Implementation of connection dragging functionality (reserved for future spec)
- Updates to other routing editor UI elements beyond physical IO nodes
- Performance optimizations for dragging (unless critical issues arise)

## Expected Deliverable

- Universal port_widget used by all node types in routing editor
- Redesigned physical input and output nodes using port_widget
- Redesigned algorithm nodes using port_widget
- Integration of port_widget across entire routing system
- Removal of JackConnectionWidget and existing algorithm port rendering code
- Consistent Material Design language across all routing nodes
- Clean removal of old connection gesture handling from all nodes
- Preparation for future manual connection dragging implementation

## Spec Documentation

- Tasks: @.agent-os/specs/2025-09-04-physical-io-node-redesign/tasks.md
- Technical Specification: @.agent-os/specs/2025-09-04-physical-io-node-redesign/sub-specs/technical-spec.md