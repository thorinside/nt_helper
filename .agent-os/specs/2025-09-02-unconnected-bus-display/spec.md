# Spec Requirements Document

> Spec: Unconnected Bus Display
> Created: 2025-09-02
> Status: Planning

## Overview

Enhance the routing editor to visually indicate ports that are assigned to a bus but lack corresponding connections, providing users with immediate feedback about potentially incomplete signal routing. This feature will display short connection lines with bus labels for unconnected ports, serving as a visual warning system without treating these as errors.

## User Stories

### Visual Feedback for Unconnected Buses

As a Eurorack musician, I want to see when my algorithm ports are assigned to buses but don't have matching connections, so that I can quickly identify potential routing issues or intentional open connections.

When working with complex routing configurations in the Disting NT, users need to understand which signals are being sent to or expected from buses that have no corresponding connections. The routing editor will display these unconnected bus assignments as short connection lines terminating in bus labels (e.g., o----[A1] for outputs, [A3]---o for inputs), making it immediately clear where signals may be lost or missing. This visual feedback helps users distinguish between intentional routing choices and potential configuration oversights.

### Intelligent Zero-Value Handling

As a user managing routing configurations, I want the system to intelligently handle ports with zero values as unconnected without cluttering the interface, so that I can focus on active bus assignments that need attention.

The system will treat ports with a value of 0 as unconnected but won't display visual representations for these, reducing visual noise while still properly tracking connection states. This allows users to focus on bus assignments that are actively configured but potentially incomplete.

## Spec Scope

1. **Unconnected Bus Detection** - Identify input/output ports assigned to buses without matching algorithm connections
2. **Visual Representation** - Display short connection lines with bus labels for unconnected ports (o----[A1] or [A3]---o format)
3. **Zero-Value Handling** - Treat ports with value 0 as unconnected without visual representation
4. **Warning Indication** - Present unconnected buses as informational warnings, not errors
5. **Connection State Management** - Update visualizations dynamically as connections change

## Out of Scope

- Interactive dragging of bus labels to create connections (future spec)
- Error handling or validation for unconnected buses
- Automatic connection suggestions or auto-routing
- Bus assignment modification through the visualization

## Expected Deliverable

1. Routing editor displays short connection lines with bus labels for all ports assigned to buses without matching connections
2. Visual indicators update in real-time as bus assignments and connections change
3. Zero-value ports are properly handled as unconnected without creating visual clutter

## Spec Documentation

- Tasks: @.agent-os/specs/2025-09-02-unconnected-bus-display/tasks.md
- Technical Specification: @.agent-os/specs/2025-09-02-unconnected-bus-display/sub-specs/technical-spec.md