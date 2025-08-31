# Algorithm Connections Implementation Checklist

## Pre-Implementation Setup
- [ ] Review all specification documents
- [ ] Continue work on current branch: `feature/routing_editor`
- [ ] Verify test environment with 32-slot presets
- [ ] Confirm understanding of bus mapping (1-12 input, 13-20 output, 21-28 aux)
 - [ ] Confirm using existing `PortTypeColors` (type-based); no per-port hue variation

## Phase 1: Data Model (Target: Day 1-2)

### 1.1 AlgorithmConnection Model
- [ ] Create `lib/models/algorithm_connection.dart`
- [ ] Define AlgorithmConnection with freezed annotation
- [ ] Add required fields:
  - [ ] `String id` - Unique identifier
  - [ ] `int sourceAlgorithmIndex` - Source slot (0-31)
  - [ ] `String sourcePortId` - Source port identifier
  - [ ] `int targetAlgorithmIndex` - Target slot (0-31)
  - [ ] `String targetPortId` - Target port identifier
  - [ ] `int busNumber` - Bus assignment (1-28)
  - [ ] `bool isValid` - Execution order validation
  - [ ] `DateTime createdAt` - Creation timestamp
- [ ] Implement AlgorithmConnectionHelpers extension:
  - [ ] `violatesExecutionOrder` getter
  - [ ] `busTypeLabel` getter (Input/Output/Aux)
  - [ ] `generateId` static method
- [ ] Run build_runner to generate freezed code
- [ ] Write unit tests for model and helpers

### 1.2 State Model Extension
- [ ] Update `lib/cubit/routing_editor_state.dart`
- [ ] Add `List<AlgorithmConnection> algorithmConnections` to RoutingEditorStateLoaded
- [ ] Regenerate freezed code
- [ ] Update all state constructors
- [ ] Test state serialization/deserialization

## Phase 2: Connection Discovery Service (Target: Day 3-5)

### 2.1 Service Implementation
- [ ] Create `lib/core/routing/services/algorithm_connection_service.dart`
- [ ] Implement AlgorithmConnectionService class:
  - [ ] Constructor with RoutingFactory injection
  - [ ] Simple last-hash connection cache implementation
  - [ ] `discoverAlgorithmConnections(List<Slot> slots)` method
- [ ] Implement private methods:
  - [ ] `_collectAlgorithmPorts` - enumerate ports with bus assignments
  - [ ] `_getBusNumberForPort` - resolve bus from port metadata
  - [ ] `_createBusConnections` - match outputs to inputs by bus
  - [ ] `_compareConnections` - deterministic sorting
- [ ] Add _PortWithBus helper class
- [ ] Implement stable slot-hash computation

### 2.2 Bus Resolution Logic
- [ ] Create shared `lib/core/routing/utils/bus_resolution.dart`
- [ ] Handle busParam metadata lookup
- [ ] Support polyphonic gate/CV fallback
- [ ] Validate bus range (1-28, 0 = None)
- [ ] Test with various algorithm types

### 2.3 Service Testing
- [ ] Unit tests for connection discovery
- [ ] Test with empty slots
- [ ] Test with maximum slots (32)
- [ ] Test execution order validation
- [ ] Test self-connection exclusion
- [ ] Performance benchmarks

## Phase 3: Cubit Integration (Target: Day 6-7)

### 3.1 RoutingEditorCubit Enhancement
- [ ] Add AlgorithmConnectionService as dependency
- [ ] Update constructor to inject service
- [ ] Modify `_processSynchronizedState`:
  - [ ] Call connection discovery service
  - [ ] Include algorithm connections in state
  - [ ] Handle discovery errors gracefully
- [ ] Update state emissions throughout
 - [ ] Update `_hasLoadedStateChanged` to include `algorithmConnections`

### 3.2 Integration Testing
- [ ] Test state updates on slot changes
- [ ] Test connection updates on parameter changes
- [ ] Verify memory management
- [ ] Test error recovery

## Phase 4: UI Implementation (Target: Day 8-10)

### 4.1 Canvas Rendering
- [ ] Add an additional `ConnectionCanvas` layer in `lib/ui/widgets/routing/routing_editor_widget.dart` for `algorithmConnections`
- [ ] Convert `AlgorithmConnection` → `ConnectionData` with positions from existing anchor logic
- [ ] Use error style (red/dashed) for invalid connections
- [ ] Use source output port color for valid connections

### 4.2 Visual Styling
- [ ] Valid connections follow source output port type color (align with existing `PortTypeColors`)
- [ ] Invalid connections: red color with dashed lines
- [ ] Labels at connection midpoint ("Bus #")

### 4.3 Performance (Optional)
- [ ] Ensure responsiveness with typical presets (32 algorithms)

## Phase 5: Testing & Validation (Target: Day 11-12)

### 5.1 Unit Tests
- [ ] AlgorithmConnection model tests
- [ ] AlgorithmConnectionService tests
- [ ] Bus resolution tests
- [ ] Sorting algorithm tests
- [ ] Color generation tests

### 5.2 Integration Tests
- [ ] End-to-end workflow tests
- [ ] State management tests
- [ ] Optional performance sanity checks

### 5.3 Visual Tests
- [ ] Golden file tests for valid connections (output-port colors)
- [ ] Golden file tests for invalid connections (red/dashed)
- [ ] Label positioning tests

### 5.4 User Acceptance Testing
- [ ] Load complex presets with many connections
- [ ] Verify visual clarity
- [ ] Test real-time parameter updates
- [ ] Validate execution order indicators
- [ ] Performance validation

## Phase 6: Documentation & Polish (Target: Day 13-14)

### 6.1 Code Documentation
- [ ] Add dartdoc comments to all public APIs
- [ ] Document service architecture
- [ ] Add usage examples

### 6.2 User Documentation
- [ ] Update CLAUDE.md with routing changes
- [ ] Create user guide section
- [ ] Add troubleshooting guide

### 6.3 Final Polish
- [ ] Code review and refactoring
- [ ] Performance profiling
- [ ] Memory optimization
- [ ] Accessibility improvements

## Acceptance Validation

### Functional Validation
- [ ] All algorithm connections discovered correctly
- [ ] Invalid connections marked in red
- [ ] Connections update on parameter changes
- [ ] No duplicate connections shown
- [ ] Physical connections not duplicated

### Performance Validation (Non-gating)
- [ ] Reasonable responsiveness with typical presets

### Quality Validation
- [ ] Test coverage > 90%
- [ ] No regressions in existing features
- [ ] All documentation complete
- [ ] Code passes linting

## Sign-off Checklist
- [ ] Development complete
- [ ] All tests passing
- [ ] Documentation updated
- [ ] Code reviewed
- [ ] Performance validated
- [ ] Ready for merge

## Notes
- Maximum 32 algorithm slots (0-31)
- 28 buses total: 1-12 (input), 13-20 (output), 21-28 (aux)
- Bus value 0 means "None" (no connection)
- Execution order: source slot must be < target slot
- Feedback Send/Receive algorithms follow same rules (no special handling needed)
