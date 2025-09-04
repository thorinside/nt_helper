# Spec Requirements Document

> Spec: Physical IO Node Redesign
> Created: 2025-09-04
> Status: Planning

## Overview

Refactor the existing algorithm node port rendering (`AlgorithmPort` + label) into a reusable `port_widget` component that can be configured for label positioning (left or right side). This minimal refactoring allows both algorithm nodes and physical I/O nodes to use the same port visualization component while maintaining existing algorithm node functionality. The focus is on making physical I/O nodes movable with working connections, using the same port widget as algorithm nodes.

## User Stories

- As a user, I want algorithm nodes to continue working as they do now, with minimal changes
- As a user, I want physical I/O nodes to use the same port component as algorithm nodes for consistency
- As a user, I want physical I/O nodes to be movable with connections that follow the node movement
- As a user, I want connections to physical I/O ports to work correctly
- As a user, I want the port widget to be configurable for label positioning (left or right side of port)
- As a user, I want physical input nodes (I1-I12) to have labels on the left and connection ports on the right
- As a user, I want physical output nodes (O1-O8) to have connection ports on the left and labels on the right

## Spec Scope

- Refactor existing algorithm node port rendering (`AlgorithmPort` + label) into a reusable `port_widget` 
- Add configurable label positioning to `port_widget` (left or right side of port)
- Minimal changes to algorithm nodes - just use the new `port_widget` instead of current port rendering
- Update physical I/O nodes to use the same `port_widget` with appropriate label positioning
- Ensure physical I/O nodes are movable with connections that move with them
- Ensure connections to physical I/O ports work correctly
- Maintain existing algorithm node behavior and appearance as much as possible

## Out of Scope

- Major changes to algorithm node design patterns (only minimal refactoring to use `port_widget`)
- Modifications to connection logic or discovery mechanisms  
- Changes to physical IO port definitions or bus assignments
- Implementation of connection dragging functionality (reserved for future spec)
- Updates to other routing editor UI elements beyond physical IO nodes
- Performance optimizations for dragging (unless critical issues arise)
- Visual redesigns beyond the port widget consolidation

## Expected Deliverable

- Refactored `port_widget` extracted from existing algorithm node port rendering with configurable label positioning
- Algorithm nodes updated to use `port_widget` with minimal changes to existing behavior
- Physical I/O nodes updated to use same `port_widget` with appropriate label positioning
- Physical I/O nodes are movable with connections that follow node movement
- Working connections to/from physical I/O ports
- Preserved algorithm node functionality and appearance
- Clean refactored codebase with shared port widget component

## Spec Documentation

- Tasks: @.agent-os/specs/2025-09-04-physical-io-node-redesign/tasks.md
- Technical Specification: @.agent-os/specs/2025-09-04-physical-io-node-redesign/sub-specs/technical-spec.md