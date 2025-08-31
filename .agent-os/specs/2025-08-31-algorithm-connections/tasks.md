# Algorithm Connections Implementation Tasks

## Phase 1: Core Data Model (Week 1)

### Task 1.1: Create AlgorithmConnection Data Model
- [ ] Create @lib/models/algorithm_connection.dart with freezed
- [ ] Add fields: id, sourceAlgorithmIndex, sourcePortId, targetAlgorithmIndex, targetPortId, busNumber, isValid, createdAt
- [ ] Add extension methods for validation and labeling
- [ ] Generate freezed/json serialization code
- [ ] Unit tests for data model and helpers

### Task 1.2: Extend RoutingEditorState  
- [ ] Add `algorithmConnections` field to @lib/cubit/routing_editor_state.dart
- [ ] Update RoutingEditorStateLoaded with new field
- [ ] Regenerate freezed code
- [ ] Update state construction in cubit

## Phase 2: Connection Discovery Service (Week 1-2)

### Task 2.1: Implement AlgorithmConnectionService
- [ ] Create `@lib/core/routing/services/algorithm_connection_service.dart`
- [ ] Implement `discoverAlgorithmConnections(List<Slot> slots)` method
- [ ] Port enumeration with shared bus assignment resolution (1–28)
- [ ] Connection creation with execution order validation
- [ ] Deterministic sorting implementation
- [ ] Simple last-hash caching
- [ ] Comprehensive unit tests

### Task 2.2: Integrate with RoutingEditorCubit
- [ ] Add service injection to @lib/cubit/routing_editor_cubit.dart
- [ ] Call discovery service in `_processSynchronizedState` method  
- [ ] Include algorithm connections in state emission
- [ ] Handle errors and edge cases
- [ ] Integration tests with real slot data

## Phase 3: UI Visualization (Week 2)

### Task 3.1: Add Algorithm Connection Layer
- [ ] Add `ConnectionCanvas` layer for `algorithmConnections` in `@lib/ui/widgets/routing/routing_editor_widget.dart`
- [ ] Convert connections to `ConnectionData` using existing anchor/position logic
- [ ] Labels at connection midpoints ("Bus #")
- [ ] Visual validation with various connection scenarios

### Task 3.2: Connection Styling Implementation
- [ ] Invalid connection styling: red, dashed lines
- [ ] Valid connection styling: color follows source output port type (no per-port hue changes)
- [ ] Connection line width and visual hierarchy
- [ ] Hover and selection states

### Task 3.3: Performance (Optional)
- [ ] Basic caching by slot hash in service
- [ ] Deterministic sorting and stable IDs for diffing
- [ ] Optional performance sanity checks

## Phase 4: Testing & Polish (Week 3)

### Task 4.1: Comprehensive Testing
- [ ] Unit tests for all new components
- [ ] Integration tests for end-to-end workflow
- [ ] Visual regression tests for UI rendering
- [ ] Performance benchmarks
- [ ] Edge case testing (empty slots, invalid parameters)

### Task 4.2: Documentation & Polish
- [ ] Update @CLAUDE.md routing architecture documentation
- [ ] Code documentation and examples
- [ ] Error handling and user feedback
- [ ] Final visual polish and accessibility
- [ ] User acceptance testing

## Acceptance Criteria

- [ ] All algorithm-to-algorithm connections correctly identified
- [ ] Invalid connections clearly marked in red
- [ ] Real-time updates when parameters change
- [ ] No performance degradation with complex presets
- [ ] Clean integration with existing routing visualization
- [ ] Comprehensive test coverage (>90%)
- [ ] Documentation updated

## Dependencies

- Existing routing architecture in @lib/cubit/routing_editor_cubit.dart
- Physical connection visualization already implemented
- Algorithm routing implementations in @lib/core/routing/

## Risk Mitigation

- **Performance**: Implement connection caching early in Phase 2
- **Complexity**: Validate core discovery logic before UI implementation  
- **UI Clutter**: Design clear visual hierarchy for connection types
- **Testing**: Continuous testing throughout implementation phases
