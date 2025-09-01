# Spec Requirements Document

> Spec: Invalid Connection Highlighting
> Created: 2025-09-01

## Overview

Add visual feedback for algorithm-to-algorithm connections that violate Disting NT's slot processing order by rendering them as dotted red lines. This feature helps users identify and correct invalid routing configurations where higher-numbered algorithm slots attempt to send data to lower-numbered slots.

## User Stories

### Routing Editor User

As a Disting NT user configuring algorithm routing, I want to see invalid connections highlighted in red dotted lines, so that I can immediately identify and fix routing issues caused by incorrect algorithm ordering.

When I create a connection from an algorithm in slot 3 to an algorithm in slot 1, the connection line should appear as a red dotted line instead of the normal solid line. This visual indicator tells me the connection won't work because the Disting NT processes algorithms in sequential order. I can then use the up/down buttons on the algorithm nodes to reorder them so the source algorithm has a lower slot number than the destination, making the connection valid and changing the line back to normal.

### Live Performance User

As a performer using the Disting NT in a live setting, I want to quickly identify routing problems without debugging, so that I can fix configuration issues before or during performances.

During sound check or performance preparation, I need to immediately see which connections are invalid due to slot ordering. The red dotted lines provide instant visual feedback that prevents confusion when patches don't work as expected. This allows me to quickly reorder algorithms using the toolbar buttons without needing to trace through complex routing logic.

## Spec Scope

1. **Connection Validation** - Detect when algorithm connections violate slot ordering rules (source slot > destination slot)
2. **Visual Rendering** - Display invalid connections as red dotted lines while preserving all other connection properties
3. **Real-time Updates** - Re-validate and update connection appearance when algorithms are reordered
4. **Metadata Tracking** - Store validation state and slot numbers in connection metadata for efficient rendering
5. **Theme Integration** - Use theme-aware error colors that work in both light and dark modes

## Out of Scope

- Automatic algorithm reordering to fix invalid connections
- Preventing creation of invalid connections
- Validation of physical input/output connections (always valid regardless of algorithm slot)
- Connection type compatibility checking (audio/CV/gate mismatches)
- Performance analysis or optimization suggestions
- Batch fixing of multiple invalid connections

## Expected Deliverable

1. Invalid algorithm connections display as red dotted lines in the routing editor canvas
2. Connection validation updates immediately when algorithms are moved up or down
3. All connection features (labels, routing, selection) continue working with invalid connections visible