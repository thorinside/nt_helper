# Epic ES5I: ES-5 Routing Editor Interactivity

## Epic Title

**ES-5 Routing Editor Interactivity - Brownfield Enhancement**

## Epic Goal

Enable direct manipulation of ES-5 routing configurations within the routing editor, eliminating the need to switch to the parameter page for USB Audio L/R routing and Clock/Euclidean ES-5 expander settings. This enhancement reduces context switching and improves the workflow for users configuring ES-5 expander outputs.

## Epic Description

### Existing System Context

**Current relevant functionality**:
- Routing editor visualizes algorithm connections using drag-and-drop
- USB From Host algorithm supports routing to ES-5 L/R (bus values 29-30) via parameters
- Clock and Euclidean algorithms support ES-5 direct output mode via ES-5 Expander and ES-5 Output parameters
- All ES-5 configuration currently requires switching to the parameter page

**Technology stack**:
- Flutter/Dart UI with custom canvas rendering
- Cubit-based state management (DistingCubit, RoutingEditorCubit)
- OO routing framework with specialized AlgorithmRouting classes
- Port-based connection discovery system

**Integration points**:
- `RoutingEditorWidget` (drag-and-drop connection handling)
- `UsbFromAlgorithmRouting` (bus value 29-30 for ES-5 L/R)
- `ClockAlgorithmRouting` and `EuclideanAlgorithmRouting` (extend `Es5DirectOutputAlgorithmRouting`)
- `DistingCubit` parameter update callbacks
- ES-5 node visualization (`es5_node.dart`)

### Enhancement Details

**What's being added/changed**:

1. **USB From Host → ES-5 Drag Routing**: Enable drag-and-drop connections from USB From Host algorithm outputs directly to ES-5 L/R input ports, automatically setting the appropriate bus parameter values (29-30)

2. **Clock/Euclidean ES-5 Toggle Control**: Add small toggle UI affordances next to Clock and Euclidean channel output labels in the routing editor to switch ES-5 Expander parameter between Off (0) and expander 1, and enable drag connections to ES-5 ports that set the ES-5 Output parameter value

**How it integrates**:
- Extends existing drag-and-drop connection system in RoutingEditorWidget
- Leverages existing parameter update mechanism through DistingCubit
- Follows existing port connection patterns and visual design language
- Uses existing ES-5 node rendering infrastructure
- Maintains separation between visualization (widget) and business logic (routing classes/cubits)

**Success criteria**:
1. Users can drag from USB From Host outputs to ES-5 L/R inputs without opening parameter page
2. Toggle control appears for Clock/Euclidean output channels and successfully switches ES-5 Expander parameter
3. Drag connections to ES-5 correctly update ES-5 Output parameter value
4. All parameter changes reflect immediately in both routing editor and parameter page
5. Zero regression in existing routing editor functionality

## Stories

This epic will be completed through 2 focused stories:

### Story 1: USB From Host ES-5 Direct Routing

Enable drag-and-drop connections from USB From Host algorithm outputs to ES-5 L/R input ports. Automatically set bus parameter values to 29 (ES-5 L) or 30 (ES-5 R) when connection is created. Update routing visualization to show ES-5 L/R as valid drop targets for USB outputs. Support connection deletion to reset bus values.

**Status**: Done ✅

### Story 2: Clock/Euclidean ES-5 Expander Interactive Controls

Add toggle UI control next to Clock and Euclidean output channel labels. Toggle switches ES-5 Expander parameter between 0 (Off) and 1 (Expander 1). When ES-5 mode is active, enable drag connections from channel outputs to ES-5 ports. Dragging connection to ES-5 port sets ES-5 Output parameter to the target port number (1-8). Update port visualization to reflect ES-5 mode state.

**Status**: Done ✅

## Compatibility Requirements

- ✅ **Existing APIs remain unchanged**: All routing framework interfaces preserved
- ✅ **Database schema changes are backward compatible**: No database changes required
- ✅ **UI changes follow existing patterns**: Extends existing drag-and-drop and visual design language
- ✅ **Performance impact is minimal**: UI-only enhancements with parameter updates via existing mechanisms

## Risk Mitigation

**Primary Risk**: Breaking existing drag-and-drop connection logic or parameter synchronization between routing editor and parameter page

**Mitigation**:
- Implement as additive UI enhancements without modifying core connection discovery
- Extensive testing of parameter bidirectional sync
- Validate all existing routing scenarios remain functional
- Use existing parameter update callbacks (no new update pathways)

**Rollback Plan**:
- Changes are UI-only additions; can be feature-flagged or conditionally rendered
- No database migrations or schema changes to reverse
- Revert affected widget files and routing classes to restore original behavior

## Definition of Done

- [x] All stories completed with acceptance criteria met
- [x] Existing routing functionality verified through regression testing
- [x] Integration points (parameter sync, connection discovery) working correctly
- [x] `flutter analyze` passes with zero warnings
- [x] No regression in existing routing features (verified via manual and automated tests)
- [x] Documentation updated (inline code comments for new UI controls and connection logic)

## Story Manager Handoff

**For detailed story creation:**

Please develop detailed user stories for this brownfield epic. Key considerations:

- **This is an enhancement to an existing system running**: Flutter/Dart with Cubit state management and a custom OO routing framework for the Disting NT hardware module

- **Integration points**:
  - `RoutingEditorWidget` - Main canvas widget with drag-and-drop connection handling
  - `UsbFromAlgorithmRouting` - Handles USB From Host algorithm routing (supports bus values 29-30 for ES-5 L/R)
  - `ClockAlgorithmRouting` and `EuclideanAlgorithmRouting` - Extend `Es5DirectOutputAlgorithmRouting` base class
  - `DistingCubit` - Parameter update mechanism (source of truth for slot state)
  - `RoutingEditorCubit` - Orchestrates routing framework state
  - `es5_node.dart` - ES-5 node visualization component

- **Existing patterns to follow**:
  - Drag-and-drop connection creation with source/target port validation
  - Parameter updates flow through DistingCubit callbacks
  - Port generation uses busValue, busParam, and special markers (e.g., 'es5_direct')
  - Separation of concerns: visualization in widgets, business logic in routing classes and cubits
  - Connection discovery via shared bus assignments
  - Zero tolerance for `flutter analyze` errors

- **Critical compatibility requirements**:
  - All existing drag-and-drop connection flows must remain functional
  - Parameter synchronization between routing editor and parameter page must be bidirectional
  - No changes to core AlgorithmRouting interfaces or connection discovery logic
  - UI additions must follow existing visual design language
  - No database schema changes

- **Each story must include**:
  - Verification that existing routing functionality remains intact
  - Acceptance criteria for parameter bidirectional sync
  - Testing against existing connection creation/deletion flows

The epic should maintain system integrity while delivering **the ability to configure ES-5 routing directly in the routing editor, eliminating context switching to the parameter page for USB Audio L/R routing and Clock/Euclidean ES-5 expander settings**.
