# Technical Specification

This is the technical specification for the spec detailed in @.agent-os/specs/2025-09-02-unconnected-bus-display/spec.md

## Technical Requirements

### Implementation Approach
- This feature should be a natural extension of the existing connection discovery algorithm
- Minimal new code - leverage existing connection infrastructure
- The core logic: when discovering connections, any port with a non-zero bus that doesn't match another port automatically becomes a partial connection
- Think of it as: full connections are ports that found a match, partial connections are ports that didn't - both discovered in the same pass

### Connection Model Enhancement
- Minimal change to existing `Connection` model - add a simple flag for partial connections
- A partial connection is just a regular connection with one endpoint being a bus label position instead of another port
- The existing connection already stores bus information, just mark when there's no matching port
- Differentiate between truly unconnected ports (bus value 0) and ports with active bus assignments lacking connections

### Integration with Existing Connection Drawing
- Modify the existing connection drawing logic in `RoutingEditorWidget` to handle partial connections
- Reuse existing connection line rendering code with modifications for partial connections
- Extend connection path calculation to terminate at bus label position instead of another port
- Position partial connections to indicate signal flow direction:
  - Output ports: line extends outward from port to bus label position
  - Input ports: bus label positioned with line extending inward to port
  - Visual representation shows connection directionality (not literal ASCII art)
- Ensure partial connections use the same rendering pipeline as full connections for consistency

### Connection Discovery Service Updates
- Integrate partial connection detection directly into existing `discoverConnections()` method
- During the regular connection discovery process:
  - Track which ports with non-zero bus values get matched to other ports
  - Any port with a non-zero bus value that doesn't get matched becomes a partial connection
  - Create partial connections as a natural byproduct of the discovery algorithm
- Return both full and partial connections from the same discovery pass
- No need for separate discovery methods - this is a single-pass enhancement

### State Management Integration
- Store partial connections in the same `connections` list in `RoutingEditorState`
- Add a simple boolean flag or enum to Connection model to indicate partial status
- No changes needed to state update logic - partial connections flow through existing pipeline
- Maintain consistent data structures to simplify future interactive connection features

### Bus Label Rendering
- Implement bus label rendering as part of the connection drawing process
- Create label components that can be positioned at connection endpoints
- Format bus labels consistently with system conventions:
  - Hardware input buses (1-12): Use system-defined bus names
  - Hardware output buses (13-20): Use system-defined bus names  
  - Algorithm buses: Follow existing naming patterns
  - Note: Labels should display actual bus identifiers, not placeholder text
- Design label rendering to be extensible for future interactive features

### Zero-Value Handling
- During connection discovery, treat ports with bus value 0 as truly unconnected
- These ports are simply skipped - no partial connection needed
- This is a simple check during the existing discovery loop

### Visual Styling Integration
- Apply existing connection styling to partial connections with modifications
- Use consistent color scheme with slight variation to indicate partial state
- Consider using dashed lines or reduced opacity for partial connections
- Ensure visual hierarchy shows partial connections as informational, not errors
- Maintain visual consistency at all zoom levels

### Future-Proofing for Interactivity
- Structure partial connections to easily convert to full connections
- Store sufficient metadata (bus assignment, port info) for future drag operations
- Design connection data model to support state transitions (partial → full)
- Keep connection endpoints accessible for future hit-testing requirements

### Performance Considerations
- Leverage existing connection rendering optimizations
- Minimize additional overhead by reusing connection drawing infrastructure
- Update only affected connections on state changes
- Cache bus label formatting where appropriate