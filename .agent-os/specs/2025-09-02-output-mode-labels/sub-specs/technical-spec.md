# Technical Specification

This is the technical specification for the spec detailed in @.agent-os/specs/2025-09-02-output-mode-labels/spec.md

## Technical Requirements

### Core Model Changes

- **OutputMode Enum** - Add new enum with values `add` and `replace` to represent output modes
- **Port Model Enhancement** - Extend Port model to include optional OutputMode field for output ports
- **Mode Parameter Extraction** - Implement detection following the same pattern as ioParameter extraction:
  - Create `extractModeParameters()` method parallel to existing `extractIOParameters()`
  - Use identical discovery pattern: iterate through parameters, filter by criteria
  - Detection criteria: parameter name ending with 'mode', unit == 1 (enum), enumStrings containing 'Add' and 'Replace'
  - Return Map<String, Parameter> just like ioParameters for consistency
- **AlgorithmRouting Factory Method** - Modify fromSlot() to:
  - Call both extractIOParameters() and extractModeParameters() 
  - Pass both maps to subclass constructors as sibling parameters
  - Maintain parallel structure for easy discovery and maintenance

### Routing Framework Integration

- **PolyAlgorithmRouting** - Update createFromSlot() to accept modeParameters and apply OutputMode to generated output ports
- **MultiChannelAlgorithmRouting** - Update createFromSlot() to accept modeParameters and apply OutputMode to generated output ports
- **Port Generation** - Modify port generation methods to set OutputMode based on corresponding mode parameter values
- **Connection Discovery** - Ensure ConnectionDiscoveryService preserves OutputMode information when creating connections

### Label Display System

- **BusLabelFormatter Enhancement** - Add formatBusLabelWithMode() method that accepts bus number and OutputMode, returning labels like "O1 R" for replace mode
- **ConnectionData Model** - Extend ConnectionData to include OutputMode information from source port
- **ConnectionPainter Update** - Modify _drawConnectionLabel() to use enhanced formatter with mode information
- **Label Formatting Logic** - Append " R" suffix only for output connections (buses 13-20) in replace mode

### Data Flow Requirements

- **Parameter Value Lookup** - Use existing getParameterValue() helper to retrieve current mode parameter values
- **Real-time Updates** - Ensure labels update when parameter values change through cubit state updates
- **Type Safety** - Maintain type safety throughout the routing system with proper OutputMode enum usage
- **Performance** - Minimize impact on existing routing performance by caching mode parameter lookups

## Implementation Architecture

### Phase 1: Core Models
1. Define OutputMode enum in models/port.dart
2. Add outputMode field to Port model
3. Update Port factory constructors and JSON serialization

### Phase 2: Parameter Detection (Parallel to IO Parameter Pattern)
1. Create extractModeParameters() method in AlgorithmRouting base class
   - Mirror the implementation pattern of extractIOParameters()
   - Use same iteration and filtering approach
   - Return Map<String, Parameter> for consistency
2. Update AlgorithmRouting.fromSlot() to:
   - Call extractModeParameters() right after extractIOParameters()
   - Store both in local variables with parallel naming
   - Pass both to subclass factory methods as siblings
3. Document the parallel pattern for future maintainers

### Phase 3: Routing Integration  
1. Update PolyAlgorithmRouting.createFromSlot() signature and implementation
2. Update MultiChannelAlgorithmRouting.createFromSlot() signature and implementation
3. Modify port generation to apply OutputMode based on mode parameters

### Phase 4: Label Enhancement
1. Add formatBusLabelWithMode() to BusLabelFormatter
2. Extend ConnectionData to include OutputMode
3. Update ConnectionPainter._drawConnectionLabel() to use enhanced formatting

### Testing Strategy
- Unit tests for OutputMode enum and Port model changes
- Unit tests for mode parameter detection logic
- Unit tests for enhanced BusLabelFormatter functionality
- Integration tests for end-to-end label display with replace mode parameters
- Visual tests to verify correct " R" suffix display in routing editor