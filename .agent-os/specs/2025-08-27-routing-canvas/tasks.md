# Spec Tasks

These are the tasks to be completed for the spec detailed in @.agent-os/specs/2025-08-27-routing-canvas/spec.md

> Created: 2025-08-27
> Status: Ready for Implementation

## Tasks

### 1. Core State Management Implementation ✅ COMPLETE
**Priority:** High
**Estimated Effort:** 3-4 hours

Create RoutingEditorCubit and RoutingEditorState classes to manage canvas state and coordinate with existing application state management.

**Subtasks:**
- ✅ Define RoutingEditorState with physical ports, algorithms, and connections
- ✅ Implement RoutingEditorCubit with basic state transitions  
- ✅ Add SynchronizedState processing for physical port creation
- ✅ Create state management integration tests
- ✅ Define Port model with name, type, and direction
- ✅ Define Connection model linking port IDs

### 2. AlgorithmRouting OOP Hierarchy
**Priority:** High  
**Estimated Effort:** 4-5 hours

Design and implement the AlgorithmRouting class hierarchy to abstract port extraction and preset update procedures for different algorithm routing patterns.

**Subtasks:**
- Define base AlgorithmRouting abstract class working with Port/Connection models
- Implement NormalAlgorithmRouting for standard algorithm port extraction
- Create port extraction logic to convert algorithm parameters into Port objects
- Implement preset update procedures to apply Connection changes back to parameters
- Create connection extraction logic to build Connection objects from routing parameters
- Add unit tests for port extraction, connection creation, and preset updates

### 3. Canvas Widget Foundation
**Priority:** High
**Estimated Effort:** 5-6 hours

Build the core visual canvas widget for displaying physical ports, algorithm ports, and routing connections.

**Subtasks:**
- Create RoutingCanvasWidget with CustomPainter for port/connection rendering
- Implement PhysicalPortNode visual components (different styles for audio/CV/gate/trigger)
- Implement AlgorithmPortNode visual components for algorithm input/output ports
- Add basic port positioning and layout algorithms for physical hardware and algorithms
- Create connection line rendering with Bezier curves between Port IDs

### 4. Drag-and-Drop Interaction System
**Priority:** Medium
**Estimated Effort:** 6-7 hours

Implement the interactive drag-and-drop system for creating and modifying routing connections between ports.

**Subtasks:**
- Add drag detection and gesture handling to Port visual components
- Implement Connection creation by dragging between source and target ports
- Add visual feedback during drag operations (ghost connection lines)
- Handle port type validation during drag operations (audio to audio, etc.)
- Add visual highlighting of valid connection targets during drag

### 5. Connection Management and Validation
**Priority:** Medium
**Estimated Effort:** 3-4 hours

Create systems for managing existing connections and validating routing configurations.

**Subtasks:**
- Implement Connection deletion functionality (click to delete, context menu)
- Add routing validation with visual error indicators on invalid connections
- Create conflict detection for invalid port type connections
- Add connection modification (reconnection by dragging existing connection endpoints)
- Add visual feedback for connection validity (color coding, error highlights)

### 6. Advanced Algorithm Routing Types
**Priority:** Medium
**Estimated Effort:** 4-5 hours

Implement PolyAlgorithmRouting and WidthAlgorithmRouting with their specialized port extraction and preset update procedures.

**Subtasks:**
- Implement PolyAlgorithmRouting to create virtual poly Port objects from gate + CV parameters
- Create PolyAlgorithmRouting preset update procedures to save Connection changes to gate/CV parameters
- Implement WidthAlgorithmRouting to create consecutive virtual Port objects from width parameters
- Create WidthAlgorithmRouting preset update procedures to save Connection changes to width parameters
- Add specialized validation for complex port routing types
- Create visual indicators in canvas for different algorithm routing patterns (normal/poly/width)

### 7. Undo/Redo Functionality
**Priority:** Low
**Estimated Effort:** 3-4 hours

Add undo/redo capabilities for connection modifications to improve user experience.

**Subtasks:**
- Implement command pattern for Connection operations (create, delete, modify)
- Add undo/redo stack management to RoutingEditorCubit
- Create UI controls for undo/redo operations
- Add keyboard shortcuts for undo/redo actions (Ctrl+Z, Ctrl+Y)

### 8. Preset Integration and Persistence
**Priority:** High
**Estimated Effort:** 2-3 hours

Integrate routing canvas Connection changes with the existing preset management system.

**Subtasks:**
- Connect Connection modifications to preset saving workflow via AlgorithmRouting classes
- Add validation before applying parameter changes to hardware
- Implement Connection change detection and dirty state management
- Create integration with existing PresetCubit state management
- Ensure parameter updates properly reflect in SynchronizedState

### 9. UI Integration and Polish
**Priority:** Medium
**Estimated Effort:** 3-4 hours

Integrate the routing canvas into the existing application UI and add polish features.

**Subtasks:**
- Embed canvas in preset editing screens with proper physical port layout
- Add loading states and progress indicators for port/connection loading
- Implement responsive design for different screen sizes (zoom, pan controls)
- Add accessibility features and keyboard navigation for port selection
- Create port type legend (color coding for audio/CV/gate/trigger ports)

### 10. Testing and Documentation
**Priority:** Medium
**Estimated Effort:** 2-3 hours

Create comprehensive tests and documentation for the routing canvas feature.

**Subtasks:**
- Add widget tests for port rendering and connection interactions
- Create integration tests for complete Port/Connection workflows
- Add performance tests for complex algorithm routing configurations
- Update user documentation with physical routing canvas usage
- Test offline mode functionality with cached port data