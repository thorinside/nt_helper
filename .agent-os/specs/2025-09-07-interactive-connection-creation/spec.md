# Spec Requirements Document

> Spec: Interactive Connection Creation
> Created: 2025-09-07

## Overview

Implement interactive connection creation in the routing editor by allowing users to drag from any output port to any input port, creating connections through synchronized bus number assignment. This feature will enable intuitive visual patching between algorithm ports while maintaining consistency with the existing connection deletion functionality.

## User Stories

### Visual Connection Patching

As a user configuring algorithm routing, I want to create connections by dragging from output ports to input ports, so that I can intuitively patch signal flow without manually entering bus numbers.

The user hovers over an output port, initiates a drag gesture, and sees a preview line following their cursor. As they drag toward input ports, compatible ports are highlighted. Upon releasing over a valid input port, the connection is established by setting both ports to use the same bus number. If one port already has a bus assignment, the other port adopts that bus number; otherwise, the system assigns an available bus number. The connection appears immediately due to optimistic updates in the state management layer.

### Smart Bus Assignment

As a user creating connections, I want the system to intelligently handle bus number assignment, so that existing connections are preserved when possible and new connections use available buses.

When connecting two ports where one already has a bus assignment, the unassigned port inherits that bus number, preserving any existing connections. When both ports are unassigned, the system finds the next available bus number appropriate for the connection type (buses 1-12 for hardware inputs, 13-20 for hardware outputs, or buses 21-28 for algorithm-to-algorithm connections using aux buses). For algorithm connections, the system uses the first available aux bus. The bus assignment follows the same update pattern as the existing connection deletion feature for consistency.

## Spec Scope

1. **Drag Gesture Handler** - Implement drag detection from output ports with visual feedback during drag operations
2. **Connection Preview Rendering** - Display a preview line that follows the cursor using the same math as existing connection rendering
3. **Port Compatibility Detection** - Identify valid target ports and provide visual highlighting during drag operations
4. **Bus Number Synchronization** - Update source and target port bus parameters to create connections using optimistic updates
5. **State Management Integration** - Leverage distingCubit's optimistic parameter updates without adding local connection state

## Out of Scope

- Manual bus number entry UI
- Connection validation beyond basic port compatibility
- Batch connection creation or templates
- Undo/redo functionality for connection operations
- Connection strength or priority settings

## Expected Deliverable

1. Users can create connections by dragging from any output port to any compatible input port
2. Created connections appear immediately with the same visual representation as existing connections
3. Bus numbers are properly synchronized between connected ports following the existing update pattern