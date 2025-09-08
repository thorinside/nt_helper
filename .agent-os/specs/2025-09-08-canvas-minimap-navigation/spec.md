# Spec Requirements Document

> Spec: Canvas Mini-Map Navigation
> Created: 2025-09-08

## Overview

Implement a mini-map overview widget in the bottom-right corner of the routing canvas that provides bird's-eye navigation and viewport visualization. This feature enables users to quickly navigate the large 5000x5000px canvas by tapping on the mini-map and see their current viewport position relative to the entire canvas content.

## User Stories

### Quick Canvas Navigation

As a user working with complex routing configurations, I want to see a mini-map overview of the entire canvas, so that I can quickly navigate to different areas without excessive scrolling.

When working with large routing configurations that span beyond the visible viewport, users need a way to understand where they are in the canvas and quickly jump to other areas. The mini-map provides a scaled-down view of the entire canvas showing all nodes and connections. Users can tap anywhere on the mini-map to instantly center their viewport at that location, eliminating the need for tedious scrolling across large distances.

### Viewport Context Awareness

As a user examining detailed routing connections, I want to see my current viewport outlined on the mini-map, so that I understand my position within the larger canvas context.

Users working on specific routing details can lose track of their location within the overall canvas. The mini-map displays a highlighted rectangle showing the exact area currently visible in the main viewport. This viewport indicator updates in real-time as users pan or scroll the main canvas, providing constant spatial awareness. The outline uses a contrasting color to ensure visibility against the mini-map background.

### Efficient Workspace Management

As a power user managing multiple algorithm nodes, I want to drag the viewport rectangle within the mini-map, so that I can precisely control my view without switching between navigation methods.

Advanced users benefit from direct manipulation of the viewport rectangle within the mini-map. By clicking and dragging the viewport outline, users can smoothly pan the main canvas view to explore adjacent areas. This interaction method is particularly useful for systematically reviewing connections between distant nodes or following signal paths across the canvas.

## Spec Scope

1. **Mini-Map Widget Component** - A standalone overlay widget positioned in the bottom-right corner of the canvas that renders a scaled representation of the entire routing canvas
2. **Scaled Content Rendering** - CustomPainter implementation that efficiently draws simplified versions of nodes and connections at a reduced scale
3. **Viewport Rectangle Overlay** - A highlighted rectangle on the mini-map showing the current visible area with real-time position updates
4. **Tap-to-Navigate Interaction** - Click/tap handling on the mini-map that centers the main viewport at the selected location
5. **Drag-to-Pan Functionality** - Ability to drag the viewport rectangle within the mini-map to smoothly pan the main canvas view

## Out of Scope

- Zoom level controls or scaling adjustments
- Mini-map resizing or repositioning by users
- Detailed node content or labels in the mini-map
- Connection interaction or selection through the mini-map
- Animated transitions when navigating via mini-map
- Collapsible/expandable mini-map states
- Multiple viewport indicators for split views
- Mini-map persistence or settings storage

## Expected Deliverable

1. A functional mini-map widget in the bottom-right corner showing a scaled overview of the entire 5000x5000px canvas with simplified node and connection rendering
2. Visible viewport rectangle outline that accurately reflects and updates with the current main canvas view position
3. Working tap-to-navigate functionality that centers the viewport at the clicked mini-map location with proper coordinate transformation