# Technical Specification

This is the technical specification for the spec detailed in @.agent-os/specs/2025-08-27-routing-canvas/spec.md

> Created: 2025-08-27
> Version: 1.0.0

## Technical Requirements

### State Management Architecture

**RoutingEditorCubit**
- Consumes synchronized `Slot`s from DistingCubit
- Derives routing metadata from Slot parameters (gate inputs, gate CV counts, extra inputs, outputs)
- Instantiates routing via `RoutingFactory` (Poly/Multi) and enumerates ports
- Emits `RoutingEditorState` with precomputed physical ports, algorithm ports, and connections
- Manages interaction state (selection, dragging) and validation

**RoutingEditorState**
- Physical hardware ports (12 inputs, 8 outputs) with type information
- Algorithm entries with their input/output ports (precomputed)
- All routing connections between ports
- Current selection and interaction state

### OOP Routing Hierarchy

The AlgorithmRouting hierarchy abstracts two key responsibilities:
1. **Port Enumeration** - Generate input/output ports from routing metadata (derived from Slot)
2. **Validation** - Validate individual connections and overall routing consistency

**Base AlgorithmRouting Class**
```dart
abstract class AlgorithmRouting {
  List<Port> get inputPorts; // generated once per instance
  List<Port> get outputPorts;
  bool validateConnection(Port source, Port destination);
  ValidationResult validateRouting();
}
```

**Physical Port System**
```dart
// Port types representing different signal types
enum PortType { audio, cv, gate, trigger }
enum PortDirection { input, output }

class Port {
  final String id;           // Unique identifier
  final String name;         // Display name
  final PortType type;       // Signal type
  final PortDirection direction;
}

// Simple connection between two ports
class Connection {
  final String sourcePortId;
  final String targetPortId;
}
```

### Physical Hardware Layout

**Disting NT Hardware Ports**
- **12 Physical Inputs**: 2 audio, 6 CV, 2 gate, 2 trigger
- **8 Physical Outputs**: All audio

**Port Identification System**
- Hardware ports: `hw_in_1` to `hw_in_12`, `hw_out_1` to `hw_out_8`
- Algorithm ports: `algo_{index}_in_{port}`, `algo_{index}_out_{port}`
- Connections reference ports by ID for simple routing representation

**NormalAlgorithmRouting**
- **Port Extraction**: Direct mapping from parameter enumeration values to bus numbers
- **Preset Update**: Simple parameter value assignments for routing connections
- Standard 1:1 input/output routing patterns

**PolyAlgorithmRouting** 
- **Port Extraction**: Interprets gate inputs + CV count parameters to create virtual poly ports
- **Preset Update**: Updates gate parameters and CV routing parameters based on poly channel assignments
- Multi-channel routing with gate + CV grouping logic

**WidthAlgorithmRouting**
- **Port Extraction**: Uses width parameters to determine consecutive CV input ranges as virtual ports  
- **Preset Update**: Updates width start parameter and routing parameters for consecutive CV assignments
- Width-based consecutive input routing patterns

### Canvas Widget Architecture

**RoutingEditorWidget**
- CustomPainter-based canvas for performance
- Node positioning and connection line rendering
- Hit testing for drag-and-drop interactions
- Zoom/pan capabilities (future enhancement)

**Node Representation**
- PhysicalInputNode / PhysicalOutputNode and AlgorithmNode widgets
- Visual indication of port types and current connections
- Drag handles and connection points

**Connection Visualization**
- Bezier curves for routing connections
- Color coding for different connection types
- Animation support for connection creation/deletion

## Approach

### Phase 1: Core Architecture
1. Implement RoutingEditorCubit with basic state management
2. Create AlgorithmRouting base class and NormalAlgorithmRouting implementation
3. Build basic canvas widget with static node display

### Phase 2: Interaction System
1. Add drag-and-drop functionality for connection creation
2. Implement connection deletion and modification
3. Add validation system with visual feedback

### Phase 3: Advanced Features
1. Implement PolyAlgorithmRouting and WidthAlgorithmRouting
2. Add undo/redo functionality
3. Integrate with preset saving system

### Integration Points

**SynchronizedState Processing**
- Convert existing routing data to visual representation
- Maintain bidirectional synchronization with hardware state

**Preset Management Integration**
- Save routing changes to preset data structures
- Validate routing before applying to hardware
- Handle routing conflicts and error states

**UI Integration**
- Embed canvas in existing preset editing workflow
- Maintain consistent UI patterns with rest of application

## External Dependencies

**Flutter Packages**
- No additional dependencies required beyond existing nt_helper stack
- Leverage existing Cubit/BLoC pattern
- Use Flutter's CustomPainter for canvas rendering

**Internal Dependencies**
- AlgorithmCubit for algorithm data
- PresetCubit for preset management  
- SynchronizedState for hardware communication
- Existing MIDI bus and routing data structures
