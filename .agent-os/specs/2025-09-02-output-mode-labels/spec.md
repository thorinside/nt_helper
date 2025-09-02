# Spec Requirements Document

> Spec: Output Mode Labels for Routing Connections  
> Created: 2025-09-02

## Overview

Enhance the routing editor to display output mode information on connection labels by appending " R" for replace mode outputs. This feature helps users understand when an algorithm output is replacing another output lower in the processing chain rather than mixing with it.

## User Stories

### Visual Output Mode Indication

As a user working with Disting NT routing, I want to see when an output connection is in replace mode, so that I can understand the signal processing behavior and properly configure my routing chains.

When viewing the routing editor, output connections that are configured to replace (rather than add/mix) will display labels like "O1 R" instead of just "O1", making the signal flow behavior immediately clear. This is essential when multiple algorithms share the same bus to save routing space, and later algorithms replace the output rather than mixing with it.

## Spec Scope

1. **Mode Parameter Detection** - Automatically identify output mode parameters based on naming convention (ending with 'mode'), unit type (enum), and enum values ('Add', 'Replace')
2. **Port Metadata Enhancement** - Add OutputMode enum to port models and pass mode parameters alongside ioParameters when building AlgorithmRouting subclasses
3. **Label Formatting Update** - Modify BusLabelFormatter to append " R" suffix when an output connection is in replace mode
4. **Connection Display Integration** - Update ConnectionPainter to use the enhanced labels when rendering connection labels

## Out of Scope

- Changes to input mode parameters (only output modes are relevant)
- Modification of existing routing logic beyond label display
- UI controls for changing output modes (this is parameter-driven)
- Performance optimizations for mode parameter extraction

## Expected Deliverable

1. Users can visually distinguish between add mode (default, no suffix) and replace mode (shows " R" suffix) output connections in the routing editor
2. The system automatically detects output mode parameters without requiring manual configuration
3. Connection labels accurately reflect the current parameter values and update when parameters change