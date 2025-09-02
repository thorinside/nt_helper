# Spec Tasks

## Tasks

- [ ] 1. Create ConnectionValidator service
  - [ ] 1.1 Write tests for ConnectionValidator class
  - [ ] 1.2 Create ConnectionValidator class in lib/core/routing/services/
  - [ ] 1.3 Implement validateConnections method with algorithm index extraction
  - [ ] 1.4 Add helper methods for physical connection detection
  - [ ] 1.5 Verify all tests pass

- [ ] 2. Integrate validation into RoutingEditorCubit
  - [ ] 2.1 Write tests for connection validation in cubit
  - [ ] 2.2 Import ConnectionValidator in RoutingEditorCubit
  - [ ] 2.3 Call validateConnections in _processRoutingData method
  - [ ] 2.4 Verify connections are validated on algorithm reordering
  - [ ] 2.5 Verify all tests pass

- [ ] 3. Update ConnectionPainter for invalid connections
  - [ ] 3.1 Write tests for invalid connection rendering
  - [ ] 3.2 Extend ConnectionData to include isInvalidOrder field from properties
  - [ ] 3.3 Modify _applyConnectionStyle to check for invalid connections
  - [ ] 3.4 Apply error color and dashed pattern to invalid connections
  - [ ] 3.5 Test visual rendering with multiple invalid connections
  - [ ] 3.6 Verify all tests pass

- [ ] 4. Update routing editor widget integration
  - [ ] 4.1 Write integration tests for complete feature
  - [ ] 4.2 Extract isInvalidOrder from connection properties in _buildUnifiedConnectionCanvas
  - [ ] 4.3 Pass flag to ConnectionData constructor
  - [ ] 4.4 Test end-to-end with algorithm reordering
  - [ ] 4.5 Verify visual feedback updates in real-time
  - [ ] 4.6 Verify all tests pass