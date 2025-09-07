# Spec Tasks

These are the tasks to be completed for the spec detailed in @.agent-os/specs/2025-09-07-interactive-connection-creation/spec.md

> Created: 2025-09-07
> Status: Ready for Implementation

## Tasks

- [ ] 1. Implement drag gesture handling for output ports
  - [ ] 1.1 Write tests for drag gesture detection on output ports
  - [ ] 1.2 Add GestureDetector to PortWidget for output ports
  - [ ] 1.3 Create drag state management in RoutingEditorCubit
  - [ ] 1.4 Implement drag start, update, and end callbacks
  - [ ] 1.5 Add cursor position tracking during drag
  - [ ] 1.6 Verify all tests pass

- [ ] 2. Create connection preview visualization
  - [ ] 2.1 Write tests for connection preview rendering
  - [ ] 2.2 Extract connection path calculation from ConnectionPainter into reusable method
  - [ ] 2.3 Implement preview line rendering with semi-transparent styling
  - [ ] 2.4 Update preview position in real-time during drag
  - [ ] 2.5 Ensure preview uses identical bezier curve math as existing connections
  - [ ] 2.6 Add RepaintBoundary for performance isolation
  - [ ] 2.7 Verify all tests pass

- [ ] 3. Implement port highlighting (no compatibility checks)
  - [ ] 3.1 Write tests for proximity-based port highlighting
  - [ ] 3.2 Implement proximity detection for hover highlighting
  - [ ] 3.3 Add visual feedback for any input port within proximity
  - [ ] 3.4 Cache port positions during drag operation
  - [ ] 3.5 Verify all tests pass

- [ ] 4. Implement bus number assignment and connection creation
  - [ ] 4.1 Write tests for bus assignment logic including aux bus handling
  - [ ] 4.2 Implement aux bus (21-28) selection for algorithm-to-algorithm connections
  - [ ] 4.3 Create bus assignment logic matching deletion pattern
  - [ ] 4.4 Handle case where one port already has bus assignment
  - [ ] 4.5 Find first available bus in appropriate range (1-12, 13-20, or 21-28)
  - [ ] 4.6 Call updateParameterValueOptimistically for bus updates
  - [ ] 4.7 Trigger routing refresh after connection creation
  - [ ] 4.8 Verify all tests pass

- [ ] 5. Add error handling and edge cases
  - [ ] 5.1 Write tests for error conditions and edge cases
  - [ ] 5.2 Implement drag cancellation handling (ESC key)
  - [ ] 5.3 Handle invalid drop targets gracefully (no port validation needed)
  - [ ] 5.4 Add debouncing for drag move events
  - [ ] 5.5 Batch parameter updates when possible
  - [ ] 5.6 Test with various algorithm configurations
  - [ ] 5.7 Verify all tests pass and flutter analyze shows no errors