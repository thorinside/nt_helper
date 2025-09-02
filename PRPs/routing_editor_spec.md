# Routing Editor Visual Interface Specification

> Ingest the information from this file, implement the Low-Level Tasks, and generate the code that will satisfy the High and Mid-Level Objectives.

## High-Level Objective

- Build a visual routing editor interface that allows users to drag and drop algorithm modules, create connections between inputs/outputs, and manage algorithm slots with up/down/delete actions in a grid-based layout.

## Mid-Level Objective

- Create draggable algorithm nodes with toolbar actions (up, down, delete)
- Implement draggable input and output connection panels
- Build visual connection lines between nodes with labeled intermediate bus indicators
- Add connection state management with "replace" mode visualization (blue labels with R suffix)
- Integrate with existing distingCubit for algorithm slot management
- Implement grid-based layout system for precise node positioning
- Add visual feedback for unavailable actions (greyed out buttons)

## Implementation Notes

- Follow existing Flutter/Cubit architecture patterns from the codebase
- Use CustomPainter or similar for drawing connection lines
- Integrate with existing DistingCubit state management
- Follow Material Design guidelines for drag interactions
- Use existing color scheme and typography from the app theme
- Ensure accessibility with proper semantic labels
- Connection labels should show bus numbers and output modes clearly
- Blue color specifically for "replace" mode connections with "(R)" suffix
- Grey out toolbar buttons when actions are not available (single algorithm can't move up/down)
- Canvas is internally 5000x5000 pixels with pan functionality when nodes exceed screen bounds
- Ensure precise mouse-to-canvas coordinate transforms for accurate dragging synchronization
- All drag operations must maintain 1:1 pixel correspondence with mouse movements
- Use debugPrint() for all logging (never print())
- Maintain zero tolerance for flutter analyze errors

## Context

### Beginning context

- Existing DistingCubit with algorithm slot management
- Current routing logic without visual interface
- Algorithm models with input/output specifications
- UI theme and styling system
- Basic Flutter widget structure

### Ending context

- Visual routing editor widget with draggable nodes
- Connection visualization system with labeled buses
- Integrated toolbar actions for algorithm management
- Grid-based layout system for precise positioning
- Connection state management with visual indicators
- Complete integration with DistingCubit for hardware communication

## Low-Level Tasks

> Ordered from start to finish

1. Create the base RoutingEditorWidget with grid layout and pan functionality

```
Create a new routing editor widget with 5000x5000 internal canvas and pan functionality
What file do you want to CREATE: lib/widgets/routing_editor_widget.dart
What function do you want to CREATE: RoutingEditorWidget class with StatefulWidget and InteractiveViewer
What are details you want to add: 
- 5000x5000 pixel internal canvas size
- InteractiveViewer for panning when nodes exceed screen bounds
- Grid background with snap-to-grid functionality
- Proper sizing and padding for node placement
- Integration with app theme for consistent styling
```

2. Implement draggable algorithm nodes with precise coordinate transforms

```
Create draggable algorithm node widgets with accurate mouse-to-canvas coordinate handling
What file do you want to CREATE: lib/widgets/algorithm_node_widget.dart
What function do you want to CREATE: AlgorithmNodeWidget class with custom drag handling
What are details you want to add:
- Title bar with algorithm name and slot number
- Toolbar with up/down/delete actions in overflow menu
- Input and output connection points
- Custom drag implementation with proper coordinate transforms
- Precise mouse-to-canvas position mapping through InteractiveViewer
- Visual states for enabled/disabled actions
- 1:1 pixel correspondence between mouse movement and node positioning
```

3. Create draggable input and output panel widgets with coordinate transforms

```
Build the left and right panels for inputs and outputs with precise coordinate handling
What file do you want to CREATE: lib/widgets/connection_panel_widget.dart
What function do you want to CREATE: InputPanelWidget and OutputPanelWidget classes with coordinate transforms
What are details you want to add:
- Draggable connection points for each input/output with accurate positioning
- Proper coordinate transforms for connection drag operations
- Mouse-to-canvas position mapping for connection endpoints
- Proper labeling (I1, I2, O1, O2, etc.)
- Visual connection indicators with precise positioning
- Consistent styling with algorithm nodes
```

4. Implement connection line drawing system

```
Create a system to draw connection lines between nodes with proper routing
What file do you want to CREATE: lib/widgets/connection_painter.dart
What function do you want to CREATE: ConnectionPainter class extending CustomPainter
What are details you want to add:
- Smooth curved or straight line connections
- Connection line routing to avoid overlaps
- Support for multiple connection types
- Integration with connection state data
```

5. Add connection labeling with bus indicators

```
Implement connection labels that show bus numbers and output modes
What file do you want to UPDATE: lib/widgets/connection_painter.dart
What function do you want to CREATE: drawConnectionLabel method
What are details you want to add:
- Text labels positioned on connection lines
- Blue color for "replace" mode connections
- "(R)" suffix for replace mode indicators
- Proper text positioning and readability
```

6. Integrate toolbar actions with DistingCubit

```
Connect the algorithm node toolbar actions to the existing state management
What file do you want to UPDATE: lib/widgets/algorithm_node_widget.dart
What function do you want to CREATE: _handleMoveUp, _handleMoveDown, _handleDelete methods
What are details you want to add:
- Integration with DistingCubit for algorithm slot management
- Proper state updates when algorithms are moved or deleted
- Visual feedback for action completion
- Error handling for invalid operations
```

7. Implement connection state management

```
Create a system to manage and persist connection states between nodes
What file do you want to CREATE: lib/cubits/routing_editor_cubit.dart
What function do you want to CREATE: RoutingEditorCubit class with connection state management
What are details you want to add:
- Connection creation and deletion
- Bus assignment logic
- Output mode management (replace/mix)
- Integration with DistingCubit for hardware sync
```

8. Add visual feedback and interaction states with coordinate accuracy

```
Implement hover, drag, and selection states with precise coordinate handling
What file do you want to UPDATE: lib/widgets/routing_editor_widget.dart
What function do you want to CREATE: interaction state management methods with coordinate transforms
What are details you want to add:
- Hover effects for connection points and nodes with accurate hit testing
- Drag preview and drop zones with precise positioning
- Selection highlighting for active connections at exact coordinates
- Visual feedback for valid/invalid drop targets
- Coordinate transform utilities for all interactive elements
- Mouse position to canvas position conversion methods
```

9. Implement grid snapping and coordinate transform utilities

```
Add grid snapping functionality with precise coordinate transform handling
What file do you want to UPDATE: lib/widgets/routing_editor_widget.dart
What function do you want to CREATE: snapToGrid, coordinate transform, and positioning helper methods
What are details you want to add:
- Grid snap calculations with accurate mouse-to-canvas coordinate conversion
- Position constraints to keep nodes within canvas bounds
- Pan viewport to follow dragged nodes near edges
- Visual grid guidelines during drag operations aligned with transforms
- Smooth positioning animations maintaining coordinate accuracy
- Utility methods for screen-to-canvas and canvas-to-screen coordinate conversion
- Transform matrix calculations for InteractiveViewer state
```

10. Add responsive layout and accessibility features

```
Ensure the routing editor works well on different screen sizes and is accessible
What file do you want to UPDATE: lib/widgets/routing_editor_widget.dart
What function do you want to UPDATE: build method with responsive and accessibility features
What are details you want to add:
- Responsive grid sizing based on screen dimensions
- Semantic labels for screen readers
- Keyboard navigation support
- Touch-friendly sizing for mobile devices
- Proper contrast ratios for all visual elements
```