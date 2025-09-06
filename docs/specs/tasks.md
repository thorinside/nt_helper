# Spec Tasks

These are the tasks to be completed for the invalid connection highlighting specification detailed in @docs/specs/invalid_connection_highlighting_spec.md

> Created: 2025-09-06
> Status: Ready for Implementation

## Tasks

- [x] 1. Core Connection Validation Infrastructure
  - [x] 1.1 Write tests for ConnectionValidator class with various slot configurations
  - [x] 1.2 Write tests for algorithm ID extraction from port IDs
  - [x] 1.3 Implement helper utilities to extract algorithm IDs from connection port IDs
  - [x] 1.4 Add methods to retrieve slot numbers from algorithm IDs in RoutingEditorState
  - [x] 1.5 Create ConnectionValidator class with isValidSlotOrder static method
  - [x] 1.6 Handle edge cases for physical ports and missing algorithms in validation
  - [x] 1.7 Add connection metadata fields (isInvalidOrder, sourceSlot, targetSlot, invalidReason)
  - [x] 1.8 Verify all validation tests pass and cover edge cases

- [x] 2. Visual Rendering System for Invalid Connections
  - [x] 2.1 Write tests for ConnectionPainter with invalid connection rendering
  - [x] 2.2 Write tests for dash pattern implementation and visual accuracy
  - [x] 2.3 Implement DashPathEffect support for Canvas drawing with configurable patterns
  - [x] 2.4 Modify ConnectionPainter to render invalid connections with dashed red lines
  - [x] 2.5 Add invalidConnectionColor and dash pattern constants to theme system
  - [x] 2.6 Ensure proper color contrast and accessibility in both light/dark themes
  - [x] 2.7 Test rendering performance and visual clarity at different zoom levels
  - [x] 2.8 Verify all visual rendering tests pass and maintain existing functionality

- [x] 3. State Management and Dynamic Validation
  - [x] 3.1 Write tests for RoutingEditorCubit connection validation integration
  - [x] 3.2 Write tests for validation updates during algorithm reordering scenarios
  - [x] 3.3 Integrate connection validation into RoutingEditorCubit connection creation flow
  - [x] 3.4 Add invalid connection tracking to RoutingEditorState
  - [x] 3.5 Implement automatic re-validation when algorithms are reordered via up/down buttons
  - [x] 3.6 Ensure connection data preservation during algorithm position changes
  - [x] 3.7 Add validation trigger in ConnectionDiscoveryService for newly discovered connections
  - [x] 3.8 Verify all state management tests pass and connections update correctly

- [x] 4. User Experience and Interaction Features  
  - [x] 4.1 Write tests for hover tooltip content generation and positioning
  - [x] 4.2 Write tests for tooltip behavior with various connection states
  - [x] 4.3 Implement hover tooltip system for invalid connections in RoutingEditorWidget
  - [x] 4.4 Add explanatory tooltip content with slot numbers and reordering suggestions
  - [x] 4.5 Ensure tooltip accessibility and screen reader compatibility
  - [x] 4.6 Test tooltip performance and interaction with connection drag operations
  - [x] 4.7 Conduct manual testing across platforms for visual clarity and usability
  - [x] 4.8 Verify all user experience tests pass and feature integrates seamlessly