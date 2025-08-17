name: "Routing Node Editor Improvements - Correct Algorithm I/O and Connection Feedback"
description: |
  Enhance the routing node editor to display correct algorithm-specific input/output ports
  and improve connection feedback with bezier curves and bus labeling

---

## Goal

**Feature Goal**: Display algorithm-specific input/output ports accurately in the routing node editor and enhance connection feedback with bezier curves and bus/mode labels

**Deliverable**: Enhanced node routing system with correct algorithm port extraction, improved visual connection rendering with bezier curves, and informative bus labeling

**Success Definition**: Node editor accurately displays each algorithm's actual inputs/outputs from metadata, connections show smooth bezier curves with bus labels during creation and display

## User Persona

**Target User**: Disting NT hardware users configuring audio routing

**Use Case**: Visually connecting algorithm outputs to inputs to create complex audio routing configurations

**User Journey**: 
1. User opens routing editor and sees algorithms with their actual inputs/outputs
2. User drags from an output port, sees visual feedback line following cursor
3. User drops on compatible input port, connection snaps with bezier curve
4. Connection displays bus assignment (e.g., "A1 R") at midpoint

**Pain Points Addressed**: 
- Currently shows generic "Input 1/2, Output 1/2" for all algorithms
- No visual feedback during connection dragging
- Unclear which bus is being used for connections

## Why

- Accurate port representation enables correct routing configuration
- Visual feedback improves user confidence during connection creation
- Bus labeling clarifies resource usage and routing mode
- Professional node editor experience matches industry standards

## What

Enhanced routing node editor with:
- Algorithm-specific input/output port extraction from metadata
- Dynamic port rendering based on algorithm capabilities
- Bezier curve connections with smooth curves
- Connection preview during drag operations
- Bus and mode labels on connections (I1-I12, O1-O12, A1-A8 with R/A suffix)

### Success Criteria

- [ ] Each algorithm displays its actual inputs/outputs from metadata
- [ ] Dragging from output shows bezier preview line to cursor
- [ ] Connections render as smooth bezier curves
- [ ] Each connection shows bus assignment and mode label
- [ ] Port names match algorithm documentation

## All Needed Context

### Context Completeness Check

_"If someone knew nothing about this codebase, would they have everything needed to implement this successfully?"_ - YES

### Documentation & References

```yaml
# MUST READ - Include these in your context window
- file: /Users/nealsanche/nosuch/nt_helper/lib/models/algorithm_metadata.dart
  why: Algorithm metadata structure with input_ports and output_ports arrays
  pattern: AlgorithmMetadata class with inputPorts/outputPorts lists
  gotcha: Some algorithms use isPerChannel for multiple port instances

- file: /Users/nealsanche/nosuch/nt_helper/lib/models/algorithm_parameter.dart
  why: Parameter structure to identify routing parameters
  pattern: Parameters with unit='bus' and scope='routing' are I/O controls
  gotcha: Alternative syntax uses is_bus=true instead of unit='bus'

- file: /Users/nealsanche/nosuch/nt_helper/lib/services/algorithm_metadata_service.dart
  why: Service for loading and accessing algorithm metadata
  pattern: getExpandedParameters() merges algorithm + feature parameters
  gotcha: Must handle both JSON formats (new with ports, old without)

- file: /Users/nealsanche/nosuch/nt_helper/lib/ui/routing/routing_canvas.dart
  why: Main canvas widget handling connection rendering
  pattern: Uses ConnectionPainter for drawing connections
  gotcha: Port positions calculated in _getPortPosition method

- file: /Users/nealsanche/nosuch/nt_helper/lib/ui/routing/connection_painter.dart
  why: Custom painter for bezier curve connections
  pattern: _createBezierPath() with horizontal emphasis
  gotcha: Edge labels already implemented with getEdgeLabel()

- file: /Users/nealsanche/nosuch/nt_helper/lib/cubit/node_routing_cubit.dart
  why: State management for node routing
  pattern: _extractAlgorithmPorts() currently returns hardcoded ports
  gotcha: Must integrate with AlgorithmMetadataService for real data

- file: /Users/nealsanche/nosuch/nt_helper/lib/models/algorithm_port.dart
  why: Port model with busIdRef linking to parameters
  pattern: Port.busIdRef references parameter name controlling bus
  gotcha: isPerChannel flag indicates multiple instances per channel

- file: /Users/nealsanche/nosuch/nt_helper/docs/algorithms/mix1.json
  why: Example algorithm JSON with input_ports/output_ports
  pattern: Shows port structure with id, name, description, busIdRef
  gotcha: busIdRef matches parameter name in parameters array

- docfile: PRPs/ai_docs/node_routing_implementation_details.md
  why: Previous implementation details for node routing
  section: Connection rendering and bus labeling specifications

- url: https://pub.dev/packages/fl_nodes
  why: Reference for Flutter node editor best practices
  critical: Performance optimizations for many bezier curves
```

### Current Codebase Structure

```bash
lib/
├── cubit/
│   ├── node_routing_cubit.dart         # State management for routing
│   └── node_routing_state.dart         # State definitions
├── models/
│   ├── algorithm_metadata.dart         # Algorithm metadata with ports
│   ├── algorithm_parameter.dart        # Parameter definitions
│   ├── algorithm_port.dart            # Port model
│   ├── connection.dart                 # Connection model with bus info
│   └── routing_information.dart        # Hardware routing data
├── services/
│   ├── algorithm_metadata_service.dart # Metadata loading service
│   └── auto_routing_service.dart       # Bus assignment logic
└── ui/
    └── routing/
        ├── routing_canvas.dart         # Main canvas widget
        ├── connection_painter.dart      # Bezier curve painter
        ├── algorithm_node_widget.dart   # Node rendering widget
        └── node_routing_widget.dart    # Top-level routing widget
```

### Desired Implementation Structure

```bash
lib/
├── cubit/
│   └── node_routing_cubit.dart         # MODIFY: Use real algorithm ports
├── services/
│   └── port_extraction_service.dart    # CREATE: Extract ports from metadata
└── ui/
    └── routing/
        ├── algorithm_node_widget.dart   # MODIFY: Render dynamic ports
        ├── connection_painter.dart      # ENHANCE: Improve bezier curves
        └── routing_canvas.dart         # ENHANCE: Better drag feedback
```

### Known Gotchas & Library Quirks

```dart
// CRITICAL: Algorithm metadata has two formats
// New format: Has input_ports and output_ports arrays
// Old format: Only has parameters with unit='bus' or is_bus=true

// GOTCHA: Port extraction must handle per-channel ports
// Example: Euclidean patterns have isPerChannel=true outputs

// PATTERN: Bus numbering convention
// 1-12: Input buses (I1-I12)
// 13-24: Output buses (O1-O12, displayed as 1-12)
// 21-28: Aux buses (A1-A8, displayed as 1-8)

// GOTCHA: busIdRef in ports references parameter name, not direct bus number
// Must look up parameter by name to get actual bus assignment
```

## Implementation Blueprint

### Data Models and Structure

```dart
// Port extraction result
class AlgorithmPortInfo {
  final List<AlgorithmPort> inputPorts;
  final List<AlgorithmPort> outputPorts;
  final Map<String, int> portBusAssignments; // port.busIdRef -> bus number
  
  const AlgorithmPortInfo({
    required this.inputPorts,
    required this.outputPorts,
    required this.portBusAssignments,
  });
}

// Enhanced connection for preview
class ConnectionPreview {
  final int sourceAlgorithmIndex;
  final String sourcePortId;
  final Offset currentPosition; // Cursor position during drag
  final bool isValid;
  
  const ConnectionPreview({
    required this.sourceAlgorithmIndex,
    required this.sourcePortId,
    required this.currentPosition,
    required this.isValid,
  });
}
```

### Implementation Tasks (ordered by dependencies)

```yaml
Task 1: CREATE lib/services/port_extraction_service.dart
  - IMPLEMENT: PortExtractionService class with extractPorts() method
  - FOLLOW pattern: lib/services/algorithm_metadata_service.dart structure
  - NAMING: extractPortsFromAlgorithm(), extractPortsFromParameters()
  - LOGIC: Check for input_ports/output_ports first, fallback to parameters
  - PLACEMENT: Service layer in lib/services/

Task 2: MODIFY lib/cubit/node_routing_cubit.dart
  - INTEGRATE: PortExtractionService to replace _extractAlgorithmPorts()
  - FIND pattern: Line 213-244 _extractAlgorithmPorts() method
  - REPLACE: Hardcoded ports with actual algorithm metadata
  - ADD: Dependency injection for AlgorithmMetadataService
  - PRESERVE: Existing connection logic and state management

Task 3: MODIFY lib/ui/routing/algorithm_node_widget.dart
  - IMPLEMENT: Dynamic port rendering based on actual algorithm ports
  - FIND pattern: Port rendering section with fixed 2 inputs/2 outputs
  - REPLACE: Static port list with dynamic from algorithmPorts parameter
  - ADD: Port layout calculation for variable port counts
  - PRESERVE: Existing drag/drop interaction handlers

Task 4: ENHANCE lib/ui/routing/connection_painter.dart
  - IMPROVE: _createBezierPath() for better curve aesthetics
  - FIND pattern: Line with path.cubicTo() for bezier creation
  - ADD: Adaptive control points based on distance and angle
  - ENHANCE: Preview connection rendering with dashed line style
  - PRESERVE: Existing arrow head and label rendering

Task 5: ENHANCE lib/ui/routing/routing_canvas.dart
  - IMPLEMENT: Connection preview during drag operations
  - FIND pattern: _handleCanvasPanUpdate for drag handling
  - ADD: Preview connection state management and rendering
  - ENHANCE: Visual feedback with cursor changes during drag
  - PRESERVE: Existing node positioning and selection logic

Task 6: CREATE test/services/port_extraction_service_test.dart
  - IMPLEMENT: Unit tests for port extraction logic
  - FOLLOW pattern: test/services/auto_routing_service_test.dart
  - COVERAGE: New format, old format, per-channel ports, edge cases
  - NAMING: test_extractPorts_withNewFormat(), test_extractPorts_withOldFormat()
  - PLACEMENT: Test file alongside service implementation
```

### Implementation Patterns & Key Details

```dart
// Port extraction pattern
class PortExtractionService {
  final AlgorithmMetadataService _metadataService;
  
  AlgorithmPortInfo extractPorts(String algorithmGuid) {
    final metadata = _metadataService.getAlgorithmMetadata(algorithmGuid);
    
    // PATTERN: Check new format first
    if (metadata.inputPorts.isNotEmpty || metadata.outputPorts.isNotEmpty) {
      return _extractFromPortArrays(metadata);
    }
    
    // PATTERN: Fallback to parameter-based extraction
    final parameters = _metadataService.getExpandedParameters(algorithmGuid);
    return _extractFromParameters(parameters);
  }
  
  AlgorithmPortInfo _extractFromParameters(List<AlgorithmParameter> params) {
    final inputPorts = <AlgorithmPort>[];
    final outputPorts = <AlgorithmPort>[];
    
    for (final param in params) {
      // CRITICAL: Check both unit='bus' and is_bus=true
      if (param.unit == 'bus' || param.isBus == true) {
        // PATTERN: Infer from parameter name
        if (param.name.toLowerCase().contains('input')) {
          inputPorts.add(AlgorithmPort(
            id: param.name.replaceAll(' ', '_').toLowerCase(),
            name: param.name,
            busIdRef: param.name,
          ));
        } else if (param.name.toLowerCase().contains('output')) {
          outputPorts.add(AlgorithmPort(
            id: param.name.replaceAll(' ', '_').toLowerCase(),
            name: param.name,
            busIdRef: param.name,
          ));
        }
      }
    }
    
    return AlgorithmPortInfo(
      inputPorts: inputPorts,
      outputPorts: outputPorts,
      portBusAssignments: _extractBusAssignments(params),
    );
  }
}

// Enhanced bezier curve pattern
Path _createAdaptiveBezierPath(Offset start, Offset end) {
  final path = Path();
  path.moveTo(start.dx, start.dy);
  
  // PATTERN: Adaptive control points
  final distance = (end - start).distance;
  final controlStrength = math.min(distance * 0.4, 100.0);
  
  // GOTCHA: Different curves for horizontal vs vertical routing
  if ((end.dx - start.dx).abs() > (end.dy - start.dy).abs()) {
    // Horizontal-dominant: smooth S-curve
    final cp1 = Offset(start.dx + controlStrength, start.dy);
    final cp2 = Offset(end.dx - controlStrength, end.dy);
    path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, end.dx, end.dy);
  } else {
    // Vertical: use midpoint control
    final midY = (start.dy + end.dy) / 2;
    final cp1 = Offset(start.dx + controlStrength * 0.3, midY);
    final cp2 = Offset(end.dx - controlStrength * 0.3, midY);
    path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, end.dx, end.dy);
  }
  
  return path;
}

// Connection preview pattern
void _drawPreviewConnection(Canvas canvas, ConnectionPreview preview) {
  final sourcePos = _getPortPosition(
    preview.sourceAlgorithmIndex,
    preview.sourcePortId,
    isOutput: true,
  );
  
  if (sourcePos == null) return;
  
  // PATTERN: Dashed line for preview
  final paint = Paint()
    ..color = preview.isValid ? Colors.green : Colors.red
    ..strokeWidth = 2.0
    ..style = PaintingStyle.stroke;
  
  // CRITICAL: Use PathDashPath for dashed effect
  final path = _createAdaptiveBezierPath(sourcePos, preview.currentPosition);
  _drawDashedPath(canvas, path, paint, dashArray: [8, 4]);
}
```

### Integration Points

```yaml
STATE_MANAGEMENT:
  - location: lib/cubit/node_routing_cubit.dart
  - pattern: "Inject AlgorithmMetadataService via constructor"
  - change: "Replace _extractAlgorithmPorts with PortExtractionService"

RENDERING:
  - location: lib/ui/routing/algorithm_node_widget.dart
  - pattern: "Use algorithmPorts from state for port rendering"
  - change: "Dynamic Column/Row for variable port counts"

METADATA:
  - location: lib/services/algorithm_metadata_service.dart
  - pattern: "Existing getAlgorithmMetadata() and getExpandedParameters()"
  - usage: "Called by PortExtractionService for metadata access"
```

## Validation Loop

### Level 1: Syntax & Style (Immediate Feedback)

```bash
# Run after each file modification
flutter analyze
# Expected: Zero errors/warnings

# Format code
dart format lib/services/port_extraction_service.dart
dart format lib/cubit/node_routing_cubit.dart
dart format lib/ui/routing/

# Expected: All files formatted
```

### Level 2: Unit Tests (Component Validation)

```bash
# Test port extraction service
flutter test test/services/port_extraction_service_test.dart

# Test node routing cubit with new port logic
flutter test test/cubit/node_routing_cubit_test.dart

# Run all routing-related tests
flutter test test/ --name routing

# Expected: All tests pass
```

### Level 3: Integration Testing (System Validation)

```bash
# Run app and verify visually
flutter run

# Manual validation steps:
# 1. Open routing editor
# 2. Verify each algorithm shows correct ports from metadata
# 3. Drag from output port - verify bezier preview line
# 4. Drop on input - verify connection with bus label
# 5. Test with different algorithm types (mixer, oscillator, etc.)

# Automated widget tests
flutter test test/ui/routing/

# Expected: Visual verification matches algorithm documentation
```

### Level 4: Performance Validation

```bash
# Profile with many connections
flutter run --profile

# In DevTools:
# 1. Add 50+ connections
# 2. Monitor frame rendering time
# 3. Check for jank during pan/zoom

# Performance targets:
# - 60 FPS with 100 connections
# - <16ms frame time during interaction
# - Smooth bezier curve rendering

# Expected: No performance degradation
```

## Final Validation Checklist

### Technical Validation

- [ ] All 4 validation levels completed successfully
- [ ] Flutter analyze shows zero issues
- [ ] All routing tests pass
- [ ] Performance meets 60 FPS target

### Feature Validation

- [ ] Each algorithm displays correct input/output ports from metadata
- [ ] Port names match algorithm documentation
- [ ] Dragging shows bezier preview line
- [ ] Connections render as smooth bezier curves
- [ ] Bus labels show correct format (I1-I12, O1-O12, A1-A8 with R/A)
- [ ] Connection preview changes color for valid/invalid targets

### Code Quality Validation

- [ ] Port extraction service has comprehensive tests
- [ ] Code follows existing Cubit state management pattern
- [ ] No hardcoded port lists remain
- [ ] Documentation comments added for complex logic

### Documentation & Deployment

- [ ] Algorithm port extraction logic documented
- [ ] Bezier curve algorithm improvements documented
- [ ] No breaking changes to existing routing functionality

---

## Anti-Patterns to Avoid

- ❌ Don't hardcode port lists for specific algorithms
- ❌ Don't skip parameter-based fallback for old format
- ❌ Don't ignore isPerChannel flag for multi-instance ports
- ❌ Don't render too many bezier control points (performance)
- ❌ Don't forget to dispose of animation controllers
- ❌ Don't mix port extraction logic into UI components