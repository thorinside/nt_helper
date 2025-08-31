# Spec Tasks

These are the tasks to be completed for the spec detailed in @.agent-os/specs/2025-08-30-physical-connections/spec.md

> Created: 2025-08-30
> Status: Ready for Implementation

## Tasks

### 1. Core Physical Connection Discovery Infrastructure

**Description:** Implement the core data models and bus resolution logic for discovering physical input/output connections using existing AlgorithmRouting abstractions.

**Dependencies:** None

**Subtasks:**

#### 1.1 Create PhysicalConnection Data Model
- Write unit tests for PhysicalConnection data class with deterministic IDs: `phys_${sourcePortId}->${targetPortId}`
- Implement PhysicalConnection with fields: `id`, `sourcePortId`, `targetPortId`, `busNumber`, `isInputConnection`, `algorithmIndex`
- Add PhysicalConnection to existing connection infrastructure as immutable freezed class
- Verify data model handles stable diffing and all required connection metadata correctly

#### 1.2 Fix busParam Propagation in Metadata Building
- Write unit tests for `_buildMetadataForSlot()` ensuring busIdRef is propagated to port metadata
- Fix missing `busParam` propagation in declaredInputs and declaredOutputs creation
- Add `busParam: busRef` field to non-poly declared inputs/outputs metadata
- Verify AlgorithmRouting instances receive proper busParam metadata for port creation

#### 1.3 Implement Bus Number Resolution Method
- Write unit tests for `_getBusNumberForPort(Port port, Slot slot)` method covering all bus ranges (1-12 input, 13-20 output)
- Implement bus resolution with fallback logic: prefer `port.metadata['busParam']`, fallback to poly `gateBus`/`suggestedBus`
- Handle edge cases: bus 0 ("None"), missing parameters, invalid bus values, out-of-range buses
- Verify method correctly resolves bus numbers for all supported algorithm types including poly CV ports

#### 1.4 Implement Physical Input Connection Discovery
- Write unit tests for discovering connections from physical inputs (buses 1-12) to algorithm input ports
- Implement `_createPhysicalInputConnections()` method using AlgorithmRouting.inputPorts
- Map hardware inputs (`hw_in_1` through `hw_in_12`) to algorithm inputs based on resolved bus numbers
- Verify discovery works with polyphonic and multi-channel algorithm routing instances

#### 1.5 Implement Physical Output Connection Discovery
- Write unit tests for discovering connections from algorithm output ports to physical outputs (buses 13-20)
- Implement `_createPhysicalOutputConnections()` method using AlgorithmRouting.outputPorts
- Map algorithm outputs to hardware outputs (`hw_out_1` through `hw_out_8`) based on resolved bus numbers
- Verify discovery handles all algorithm output configurations correctly

#### 1.6 Integrate Connection Discovery with State Management
- Write unit tests for `_createPhysicalConnectionsForAlgorithm()` combining input and output discovery
- Extend `RoutingEditorStateLoaded` to include `physicalConnections` field with stable sorting by `algorithmIndex`, `isInputConnection`, `sourcePortId`, `targetPortId`
- Integrate physical connection discovery into existing `_processSynchronizedState()` method after routing creation
- Verify physical connections are derived, non-persisted state that updates only when bus-related parameters change

#### 1.7 Add Performance Optimization
- Write unit tests for connection discovery optimization ensuring discovery only runs when slots change
- Implement connection discovery caching using existing `_hasLoadedStateChanged()` rebuild logic
- Add connection culling consideration for complex scenarios with many algorithms
- Verify performance improvements maintain connection accuracy

### 2. Visual Physical Connection Rendering

**Description:** Implement visual rendering of physical connections with distinct styling that doesn't interfere with user interaction workflows.

**Dependencies:** Task 1 (Core Infrastructure)

**Subtasks:**

#### 2.1 Create Physical Connection Rendering Layer
- Write tests for second ConnectionCanvas layer rendering physical connections with distinct styling
- Implement ConnectionCanvas with solid lines and blue/green colors (distinct from orange user connections)
- Use `IgnorePointer` to prevent physical connections from blocking user interaction
- Verify layer renders connections correctly without interfering with touch/click events

#### 2.2 Implement I#/O# Labels
- Write tests for optional I#/O# labels on physical connections when `showBusLabels: true`
- Implement label rendering with "I#" for inputs, "O#" for outputs format
- Add label styling that's readable but unobtrusive to overall routing visualization
- Default: expose a widget prop `showBusLabels`; default to `true` when `canvasSize.width >= 800`
- Verify labels appear/disappear based on `showBusLabels` and available space

#### 2.3 Add Physical Connection Layer to RoutingEditorWidget
- Write integration tests for physical connections rendering behind user connections in RoutingEditorWidget
- Integrate second ConnectionCanvas layer into existing RoutingEditorWidget hierarchy
- Ensure physical connections render in correct z-order (behind user connections, above background)
- Verify physical connections don't interfere with existing user connection workflows

#### 2.4 Implement Dynamic Endpoint Updates
- Write tests for connection endpoint updates when algorithm nodes move (`_nodePositions` changes)
- Implement automatic connection path recalculation when node positions change
- Ensure physical connections follow algorithm nodes smoothly during repositioning
- Verify connection endpoints remain accurate during node manipulation

#### 2.5 Verify Visual Distinction and Non-Interactive Behavior
- Write comprehensive visual tests ensuring physical connections are clearly distinguishable from user connections
- Test that physical connections are visual-only with no hit-testing, no tooltips/popovers
- Verify visual hierarchy: background < physical connections < user connections < UI controls
- Test that physical connections ignore output-mode styling (mix/replace) and never block interactions

### 3. Integration with Existing Routing System

**Description:** Integrate physical connection visualization with existing RoutingEditorCubit and RoutingEditorWidget without disrupting current functionality.

**Dependencies:** Task 1 (Core Infrastructure), Task 2 (Visual Rendering)

**Subtasks:**

#### 3.1 Extend RoutingEditorCubit State Management
- Write unit tests for RoutingEditorCubit handling physical connections alongside existing routing
- Update cubit to manage physical connections in loaded state with proper state transitions
- Ensure physical connection updates don't interfere with user connection management
- Verify cubit maintains consistency between algorithm routing and physical connections

#### 3.2 Update RoutingEditorWidget Integration
- Write widget tests for RoutingEditorWidget rendering both user and physical connections
- Integrate physical connection rendering into existing widget rebuild logic
- Ensure physical connections update when routing state changes
- Verify widget performance remains acceptable with additional physical connection rendering

#### 3.3 Test Parameter Value Change Responsiveness
- Write integration tests for physical connection updates when algorithm parameters change
- Verify connections appear/disappear when bus assignments are modified
- Test connection updates for all supported parameter types and value ranges
- Ensure responsive updates without performance degradation during parameter manipulation

#### 3.4 Test Algorithm Addition/Removal Scenarios
- Write tests for physical connection handling when algorithms are added or removed from slots
- Verify connections are properly created when new algorithms are loaded
- Test connection cleanup when algorithms are removed or changed
- Ensure no orphaned connections remain after algorithm changes

#### 3.5 Verify Routing Factory Compatibility
- Write compatibility tests with all existing AlgorithmRouting implementations (Poly, MultiChannel)
- Test physical connection discovery with various algorithm types and configurations
- Verify routing factory changes don't break physical connection discovery
- Ensure future routing implementations will work correctly with physical connection system

#### 3.6 Integration Testing with Real Hardware Scenarios
- Create integration tests simulating real Disting NT hardware configurations
- Test complete signal flow visualization from physical inputs through algorithms to physical outputs
- Verify accuracy of connection visualization against known hardware routing behavior
- Test edge cases: complex multi-algorithm patches, bus conflicts, parameter edge values

### 4. Polish and User Experience Optimization

**Description:** Refine the physical connection visualization for optimal user experience, performance, and maintainability.

**Dependencies:** Task 1 (Core Infrastructure), Task 2 (Visual Rendering), Task 3 (Integration)

**Subtasks:**

#### 4.1 Optimize Connection Rendering Performance
- Write performance tests for physical connection rendering with complex routing scenarios
- Implement connection culling for off-screen or overlapping connections when beneficial
- Optimize rendering pipeline to minimize impact on canvas responsiveness
- Verify smooth performance with maximum supported algorithm configurations

#### 4.2 Enhance Visual Design and Accessibility
- Conduct user experience testing for connection visibility and clarity
- Refine color scheme and line styling for optimal contrast and accessibility
- Implement responsive visual design that works across different screen sizes
- Add accessibility features: high contrast mode support, screen reader compatibility

#### 4.3 Error Handling and Edge Case Robustness
- Write comprehensive error handling tests for invalid bus assignments, corrupted parameter data
- Implement graceful degradation when physical connection discovery fails
- Add logging and debugging support for connection discovery troubleshooting
- Ensure system remains stable when encountering unexpected algorithm configurations

#### 4.4 Documentation and Code Quality
- Write comprehensive code documentation for all physical connection classes and methods
- Add inline comments explaining bus number mapping and connection discovery logic
- Ensure code follows project style guidelines and passes all lint checks
- Create developer documentation for extending physical connection system

#### 4.5 Final Integration Testing and Validation
- Conduct comprehensive end-to-end testing of complete physical connection system
- Verify all user stories from spec are fully implemented and working correctly
- Test system stability and performance under various usage scenarios
- Perform final validation against technical specification requirements
