# Technical Specification

This is the technical specification for the spec detailed in @.agent-os/specs/2025-09-04-physical-io-node-redesign/spec.md

> Created: 2025-09-04
> Version: 1.0.0

## Technical Requirements

### Widget Architecture Modifications

#### Port Widget Refactoring
- **Extract existing algorithm port rendering**: Refactor the current `AlgorithmPort` + label implementation into a reusable `port_widget`
- **Add label positioning configuration**: Add property to control whether label appears on left or right side of port
- **Preserve existing port functionality**: Maintain all current port behavior (click handlers, styling, connection points)
- **Minimal algorithm node changes**: Algorithm nodes should work the same as before, just using the extracted `port_widget`

#### PhysicalInputNode Implementation
- **Use port_widget**: Replace existing port rendering with the new `port_widget` component
- **Label positioning**: Configure `port_widget` for left-side labels (I1, I2, I3... I12)
- **Port count**: Support up to 12 input ports (matching hardware capability)
- **Make movable**: Ensure node can be dragged with connections following

#### PhysicalOutputNode Implementation  
- **Use port_widget**: Replace existing port rendering with the new `port_widget` component
- **Label positioning**: Configure `port_widget` for right-side labels (O1, O2, O3... O8)
- **Port count**: Support up to 8 output ports (matching hardware capability)
- **Make movable**: Ensure node can be dragged with connections following

### Layout Specifications

#### Port Widget Configuration
- **Label positioning**: Enum or boolean property to control left/right label placement
- **Preserve existing styling**: Keep current algorithm port styling (size, colors, etc.)
- **Connection anchoring**: Maintain existing connection point behavior from algorithm nodes
- **Global positioning**: Return port center coordinates for connection drawing (as current algorithm ports do)

#### Physical I/O Node Layout  
- **Use existing node styling**: Keep current physical I/O node container styling where it works
- **Port spacing**: Use same vertical spacing as current physical I/O nodes
- **Node positioning**: Ensure nodes can be moved and connections update accordingly
- **Connection compatibility**: Ensure connections work between physical I/O and algorithm nodes

#### Algorithm Node Preservation
- **Minimal visual changes**: Algorithm nodes should look and behave the same as before
- **Use extracted port_widget**: Replace current port rendering with the new extracted component
- **Preserve all functionality**: Maintain existing click handlers, connection logic, etc.

### Integration Requirements

#### RoutingEditor Compatibility
- **Preserve existing functionality**: All current routing editor behavior should work as before
- **Node positioning**: Ensure physical I/O nodes can be moved and connections update
- **State management**: Continue using RoutingEditorCubit for node state coordination
- **Connection discovery**: Maintain existing connection discovery and visualization logic

#### Port Widget Integration
- **Extract from algorithm nodes**: Base the `port_widget` on existing algorithm node port rendering
- **Shared component**: Use same `port_widget` for both algorithm and physical I/O nodes
- **Label positioning**: Configure left/right label placement per node type requirements
- **Connection compatibility**: Ensure connections work between all node types using the widget
- **Port ID consistency**: Maintain existing port ID formats for both algorithm and physical I/O ports
- **Bus mapping**: Preserve existing bus mapping logic for physical ports

## Approach

### Implementation Strategy

#### Phase 1: Port Widget Extraction
1. Extract existing algorithm node port rendering code into a reusable `port_widget` component
2. Add configurable label positioning (left/right) to the extracted widget
3. Ensure the widget maintains all existing functionality (connection points, styling, event handlers)
4. Test that algorithm nodes work unchanged with the new extracted widget

#### Phase 2: Physical I/O Node Updates
1. Update `PhysicalInputNode` to use `port_widget` with left-label positioning for I1-I12 ports
2. Update `PhysicalOutputNode` to use `port_widget` with right-label positioning for O1-O8 ports
3. Ensure physical I/O nodes become movable with connections that follow
4. Test that connections work correctly between physical I/O and algorithm nodes

#### Phase 3: Integration Testing
1. Verify algorithm nodes continue to work as before (minimal visual/functional changes)
2. Verify physical I/O nodes are movable and connections update correctly
3. Test connection functionality between all node types
4. Ensure routing editor state management works with movable physical I/O nodes

#### Phase 4: Code Cleanup (if needed)
1. Remove any obsolete physical I/O rendering code replaced by `port_widget`
2. Clean up any unused imports or constants
3. Update any hardcoded references to work with the new shared widget

### File Modifications

#### New Files
- `lib/ui/widgets/routing/port_widget.dart` - Extracted port widget from algorithm node rendering with configurable label positioning

#### Primary Files  
- `lib/ui/widgets/routing/algorithm_node_widget.dart` - Minimal changes to use extracted `port_widget`
- `lib/ui/widgets/routing/physical_input_node.dart` - Update to use `port_widget` with left-label positioning
- `lib/ui/widgets/routing/physical_output_node.dart` - Update to use `port_widget` with right-label positioning
- Routing editor files - Ensure physical I/O nodes are movable with connection updates

#### Files to Potentially Remove
- Any physical I/O specific port rendering code that gets replaced by `port_widget`
- Unused imports or constants after refactoring

#### Supporting Files
- Widget tests to verify the refactoring preserves algorithm node functionality
- Tests for physical I/O node movement and connection behavior

### Testing Strategy

#### Algorithm Node Preservation Testing
- Verify algorithm nodes look and behave exactly the same as before the refactoring
- Test all existing algorithm node functionality (clicking, connection points, etc.)
- Ensure no visual regressions in algorithm node appearance
- Confirm connection anchoring points remain accurate

#### Physical I/O Node Testing  
- Test that physical I/O nodes use the new `port_widget` correctly
- Verify label positioning (left for inputs I1-I12, right for outputs O1-O8)
- Test that physical I/O nodes are movable and connections follow
- Ensure connections work between physical I/O and algorithm nodes

#### Integration Testing
- Verify routing editor continues to work with all node types
- Test connection discovery and visualization across all node types
- Ensure no performance regressions with the shared widget
- Test various routing configurations to ensure stability

## External Dependencies

This specification requires no new external dependencies. All modifications work within the existing Flutter and routing framework architecture.

### Existing Dependencies Used
- Flutter widgets and layout system
- Current routing editor state management (RoutingEditorCubit)  
- Existing algorithm node port rendering (to be extracted into `port_widget`)
- Current connection discovery and drawing systems
- Existing typography and theming systems