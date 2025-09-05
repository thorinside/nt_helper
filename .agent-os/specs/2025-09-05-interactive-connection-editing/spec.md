# Spec Requirements Document

> Spec: Interactive Connection Editing
> Created: 2025-09-05
> Status: Planning

## Overview

Implement interactive connection editing functionality in the routing editor that allows users to drag connections between ports, delete connections through intuitive gestures, and toggle output modes with optimistic updates and automatic hardware synchronization.

## User Stories

### Interactive Connection Creation

As a Eurorack musician, I want to drag from any output port to any input port (or vice versa) to create connections, so that I can intuitively build complex routing configurations without technical knowledge of bus assignments.

The user can click and drag from either direction - from an output to an input, or from an input to an output - and the system automatically creates the appropriate connection. During the drag operation, a preview line follows the cursor and valid drop zones are highlighted. The system handles all bus assignment logic automatically, using physical port numbers for hardware connections and aux buses for algorithm-to-algorithm connections.

### Connection Deletion

As a user, I want to click on any connection to delete it with a confirmation dialog, and on mouse hover see immediate visual feedback with a delete option, so that I can quickly clean up unwanted connections without accidentally removing the wrong ones.

When using a mouse, hovering over a connection increases its thickness by 10% and shows a delete icon near the cursor. Clicking the delete icon immediately removes the connection. On touch devices, tapping a connection shows a delete confirmation dialog with cancel option.

### Output Mode Toggle

As a user, I want to tap on algorithm output port labels to toggle between Add and Replace modes, so that I can control how the algorithm processes multiple input signals on the same bus.

Tapping an output port label toggles its mode property between Add and Replace. Replace mode connections are visually distinct (blue coloring) and show "(R)" suffix in labels. This affects how the algorithm handles signal mixing when multiple inputs share the same bus.

## Spec Scope

1. **Drag-and-Drop Connection Creation** - Bidirectional dragging between any compatible ports with automatic bus assignment
2. **Connection Deletion System** - Mouse hover with delete icon and touch-friendly tap-to-delete with confirmation
3. **Output Mode Toggle** - Visual toggle system for Add/Replace modes accessible through port label taps
4. **Optimistic Updates** - Immediate visual feedback with automatic hardware synchronization and revert on failure
5. **Connection Validation** - Real-time validation during drag operations with clear feedback for invalid connections

## Out of Scope

- Advanced connection routing paths or curves
- Bulk connection operations (select multiple, mass delete)
- Connection grouping or bundling features
- Custom bus assignment or manual bus selection
- Connection templates or presets

## Expected Deliverable

1. Users can create connections by dragging from any port to any compatible port in either direction
2. Connection deletion works through both mouse hover + click and touch tap with confirmation
3. Output mode toggling functions correctly with visual feedback and hardware synchronization
4. All operations show optimistic updates with automatic revert on hardware sync failure

## Spec Documentation

- Tasks: @.agent-os/specs/2025-09-05-interactive-connection-editing/tasks.md
- Technical Specification: @.agent-os/specs/2025-09-05-interactive-connection-editing/sub-specs/technical-spec.md