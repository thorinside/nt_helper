# Spec Tasks

## Tasks

- [ ] 1. Create MiniMapWidget component with basic structure
  - [ ] 1.1 Write tests for MiniMapWidget initialization and scroll controller binding
  - [ ] 1.2 Create MiniMapWidget stateful widget class in lib/ui/widgets/routing/mini_map_widget.dart
  - [ ] 1.3 Implement scroll controller listeners for viewport position tracking
  - [ ] 1.4 Add widget lifecycle management (dispose controllers, clean up listeners)
  - [ ] 1.5 Verify widget properly receives and stores canvas dimensions
  - [ ] 1.6 Ensure all initialization tests pass

- [ ] 2. Implement MiniMapPainter for scaled content rendering
  - [ ] 2.1 Write tests for MiniMapPainter coordinate scaling calculations
  - [ ] 2.2 Create MiniMapPainter CustomPainter class with scale factor computation
  - [ ] 2.3 Implement node rendering as simplified colored rectangles
  - [ ] 2.4 Add connection line rendering without labels
  - [ ] 2.5 Implement viewport rectangle overlay with border and fill
  - [ ] 2.6 Add canvas clipping to prevent overflow
  - [ ] 2.7 Verify all painter rendering tests pass

- [ ] 3. Add tap-to-navigate interaction
  - [ ] 3.1 Write tests for tap coordinate transformation from mini-map to canvas space
  - [ ] 3.2 Implement GestureDetector with onTapDown handler
  - [ ] 3.3 Calculate target canvas position from mini-map tap coordinates
  - [ ] 3.4 Implement ScrollController.animateTo() for smooth navigation
  - [ ] 3.5 Add boundary checking to prevent invalid scroll positions
  - [ ] 3.6 Verify tap navigation tests pass with correct positioning

- [ ] 4. Implement viewport rectangle dragging
  - [ ] 4.1 Write tests for drag gesture handling and continuous position updates
  - [ ] 4.2 Add onPanStart, onPanUpdate, and onPanEnd handlers
  - [ ] 4.3 Track drag state and calculate viewport movement deltas
  - [ ] 4.4 Update scroll positions in real-time during drag
  - [ ] 4.5 Implement edge clamping to keep viewport within canvas bounds
  - [ ] 4.6 Add visual feedback (cursor change, rectangle highlight)
  - [ ] 4.7 Verify all drag interaction tests pass

- [ ] 5. Integrate MiniMapWidget with RoutingEditorWidget
  - [ ] 5.1 Write integration tests for mini-map within routing editor
  - [ ] 5.2 Add MiniMapWidget to Stack in RoutingEditorWidget
  - [ ] 5.3 Pass ScrollControllers and node positions to mini-map
  - [ ] 5.4 Connect to RoutingEditorCubit for connection data updates
  - [ ] 5.5 Position mini-map in bottom-right with proper margins
  - [ ] 5.6 Ensure mini-map updates when canvas content changes
  - [ ] 5.7 Test proper z-ordering with other overlay widgets
  - [ ] 5.8 Verify all integration tests pass and mini-map functions correctly