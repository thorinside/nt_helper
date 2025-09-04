# Technical Specification

This is the technical specification for the spec detailed in @.agent-os/specs/2025-09-04-physical-io-node-redesign/spec.md

> Created: 2025-09-04
> Version: 1.0.0

## Technical Requirements

### Widget Architecture Modifications

#### PhysicalIONodeWidget Base Class
- **Remove icon parameter**: Eliminate icon display from node headers
- **Match algorithm node styling**: Use the same visual styling as algorithm nodes, removing current background colors and styling inconsistencies
- **Fixed jack spacing**: Implement 24px vertical spacing between jack sockets (replacing current adaptive 28px-42px range)
- **Header simplification**: Display only node title without icon decoration

#### PhysicalInputNode Implementation
- **Port label format**: Generate labels as I1, I2, I3... I12 for input ports
- **Label positioning**: Position port labels on the left side of jacks
- **Port count**: Support up to 12 input ports (matching hardware capability)
- **Jack alignment**: Maintain right-side jack positioning for outgoing connections

#### PhysicalOutputNode Implementation
- **Port label format**: Generate labels as O1, O2, O3... O8 for output ports
- **Label positioning**: Position port labels on the right side of jacks
- **Port count**: Support up to 8 output ports (matching hardware capability)
- **Jack alignment**: Maintain left-side jack positioning for incoming connections

### Layout Specifications

#### Node Dimensions
- **Width**: Fit content with exactly 16px margin around the entire content area (port + label)
- **Height**: Dynamic based on port count (ports × 24px spacing + header + padding)
- **Styling**: Match algorithm node Material Design exactly (borders, colors, shadows, container styling)

#### Port Socket Layout
- **Vertical spacing**: 24px between port centers (configurable constant with vertical spacers)
- **Port widget**: New 24px circular port_widget
- **Alignment**: Input ports right-aligned, output ports left-aligned within node bounds
- **Connection anchoring**: Target center of 24px circles for connection line drawing

#### Label Positioning
- **Input nodes**: Labels positioned to the left of port sockets (within port_widget)
- **Output nodes**: Labels positioned to the right of port sockets (within port_widget)
- **Typography**: Match algorithm node label styling exactly
- **Port Widget**: Port and label combined in single widget with left/right positioning property
- **Global Positioning**: Widget returns global coordinates of port center for connection drawing

### Integration Requirements

#### RoutingEditor Compatibility
- **Positioning logic**: Maintain compatibility with existing RoutingEditor node positioning
- **Connection callbacks**: Remove drag/drop connection event handling, keep only node positioning callbacks
- **State management**: Continue using RoutingEditorCubit for node state coordination

#### Port Widget Architecture
- **Universal Port Widget**: Create a single port_widget used by both algorithm nodes and physical I/O nodes with 24px circular port and configurable label positioning
- **Label Positioning**: Left labels for inputs (physical I/O), right labels for outputs (physical I/O), opposite positioning for algorithm ports
- **Port Model**: Use existing Port model with busValue metadata for connection discovery across all node types
- **Connection Drawing**: Support existing connection line drawing to port centers (no drag/drop gestures)
- **Position Reporting**: Widget must return global coordinates of port center after first draw for connection anchoring
- **Port ID Consistency**: Maintain hw_in_X/hw_out_X format for physical ports, existing format for algorithm ports
- **Bus Mapping**: Physical ports use fixed bus mapping (Input 1=bus 1...Input 12=bus 12, Output 1=bus 13...Output 8=bus 20)

## Approach

### Implementation Strategy

#### Phase 1: Universal Port Widget Creation
1. Create new port_widget with 24px circular port and configurable label positioning for all node types
2. Implement global coordinate reporting for port center after first draw
3. Add left/right label positioning property supporting both algorithm and physical I/O orientation patterns
4. Use consistent Material Design styling across all node types

#### Phase 2: Node Redesign Implementation
1. Refactor `PhysicalInputNode` to use port_widget with left-label positioning (I1-I12 format)
2. Refactor `PhysicalOutputNode` to use port_widget with right-label positioning (O1-O8 format)
3. Refactor `AlgorithmNodeWidget` to use port_widget for all input/output ports
4. Implement 24px vertical spacing using configurable constants and vertical spacers
5. Apply consistent Material Design styling across all node types (borders, colors, shadows, container)

#### Phase 3: Integration and Layout
1. Implement 16px margin around entire content area (port + label)
2. Integrate with existing connection drawing system (target port centers)
3. Maintain stable hw_in_X/hw_out_X port IDs with fixed bus mapping
4. Test label positioning and connection anchoring accuracy

#### Phase 4: Code Cleanup
1. Remove JackConnectionWidget and obsolete physical I/O implementations
2. Remove all drag/drop gesture handling (simplified for future connection spec)
3. Clean up unused constants and helper methods
4. Update references to use new port_widget and spacing constants

### File Modifications

#### New Files
- `lib/ui/widgets/routing/port_widget.dart` - New port widget with configurable label positioning

#### Primary Files
- `lib/ui/widgets/routing/physical_io_node_widget.dart` - Base class modifications to use port_widget
- `lib/ui/widgets/routing/physical_input_node.dart` - Input-specific implementation with left-label positioning
- `lib/ui/widgets/routing/physical_output_node.dart` - Output-specific implementation with right-label positioning
- `lib/ui/widgets/routing/algorithm_node_widget.dart` - Algorithm node modifications to use port_widget

#### Files to Remove
- `lib/ui/widgets/routing/jack_connection_widget.dart` - Replace with port_widget
- Any existing algorithm node port rendering code (replaced by port_widget)

#### Supporting Files
- Spacing constants for 24px vertical port spacing configuration
- Widget tests that verify physical I/O node layout and connection anchoring

### Testing Strategy

#### Visual Testing
- Verify algorithm node styling consistency (no header background colors)
- Confirm exactly 16px margin around port content area
- Confirm 24px port spacing consistency
- Validate label positioning (left for inputs, right for outputs)
- Test connection line attachment points remain accurate with unified port widgets
- Ensure visual design family consistency with algorithm nodes

#### Functional Testing
- Verify connection gesture removal (no drag/drop on jacks)
- Ensure whole-node dragging still works
- Verify RoutingEditor integration continues working
- Test node positioning and layout in various routing configurations

#### Regression Testing
- Confirm existing routing functionality unaffected
- Verify no impact on non-physical I/O nodes
- Test connection discovery and visualization remains intact

## External Dependencies

This specification requires no new external dependencies. All modifications work within the existing Flutter and routing framework architecture.

### Existing Dependencies Used
- Flutter widgets and layout system
- Current routing editor state management (RoutingEditorCubit)
- JackConnectionWidget for socket visualization
- Existing typography and theming systems