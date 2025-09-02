# Technical Specification

This is the technical specification for the spec detailed in @.agent-os/specs/2025-08-30-physical-connections/spec.md

## Technical Requirements

### Architecture Integration
- Use existing `AlgorithmRouting.inputPorts/outputPorts` from routing factory instead of parameter name matching
- Leverage existing `RoutingEditorCubit._buildMetadataForSlot()` and `RoutingFactory.createValidatedRouting()`
- Add `PhysicalConnection` data model extending the existing connection infrastructure
- Integrate with current `RoutingEditorState.loaded()` by adding `physicalConnections` field

### Connection Discovery Logic
- **IO Counts**: 12 inputs (buses 1-12), 8 outputs (buses 13-20). Note: Hardware supports 12 outputs (buses 13-24)
- **Bus Resolution**: Prefer `port.metadata['busParam']`; fallback to poly `gateBus`/`suggestedBus`; inputs 1-12 → `hw_in_N`, outputs 13-20 → `hw_out_{bus-12}`; skip bus 0/invalid
- **Metadata Requirement**: Propagate `busIdRef` → `port.metadata['busParam']` for declared ports in `_buildMetadataForSlot()`
- **Edge Cases**: Bus 0/missing/out-of-range → skip and debug log; dedupe by `(sourcePortId, targetPortId)`

### Visual Rendering Requirements
- **Visuals**: Separate `ConnectionCanvas` layer behind user connections, `IgnorePointer`, solid distinct color, no mix/replace styling
- **Non-Interactive**: Physical connections are visual-only with no hit-testing, no tooltips/popovers
- **Labels**: Widget prop `showBusLabels`; default `true` when `canvasSize.width >= 800`; "I#" for inputs, "O#" for outputs format applies only to physical connections
- **Anchors**: If per-port anchors unavailable, attach to node edge/center; endpoints follow node movement

### State Management Integration  
- **State Extension**: Add `physicalConnections` to `RoutingEditorState.loaded` with deterministic IDs: `phys_${sourcePortId}->${targetPortId}`
- **Non-Persistence**: Physical connections are derived, non-persisted, and never sent to hardware
- **Recompute Triggers**: Only when bus-related Slot parameters or algorithm roster changes; not on node drag; include `physicalConnections` in UI diffing
- **Stable Sorting**: Sort by `algorithmIndex`, `isInputConnection`, `sourcePortId`, `targetPortId` before emitting
- **Discovery Integration**: Trigger in existing `_processSynchronizedState()` after algorithm routing creation

### Performance Considerations
- Limit connection discovery to when `slots` data changes (not on every render)
- Use existing rebuild optimization in `_hasLoadedStateChanged()` method
- Consider connection culling for complex routing scenarios with many algorithms

## Implementation Requirements

### Required Code Changes

#### 1. Fix Missing busParam Propagation
In `RoutingEditorCubit._buildMetadataForSlot()`, non-poly declared inputs/outputs must include busIdRef:
```dart
// For inputs in declaredInputs creation:
declaredInputs.add({
  'id': 'in_${label.replaceAll(' ', '_').toLowerCase()}',
  'name': label,
  'type': type,
  'busParam': busRef, // ADD THIS LINE
});

// For outputs in declaredOutputs creation:
declaredOutputs.add({
  'id': 'out_${label.replaceAll(' ', '_').toLowerCase()}',
  'name': label,
  'type': 'audio',
  'busParam': busRef, // ADD THIS LINE
});
```

#### 2. Add PhysicalConnection Data Model
```dart
@freezed
sealed class PhysicalConnection with _$PhysicalConnection {
  const factory PhysicalConnection({
    required String id, // Deterministic: phys_${sourcePortId}->${targetPortId}
    required String sourcePortId,
    required String targetPortId,
    required int busNumber,
    required bool isInputConnection,
    required int algorithmIndex,
    DateTime? detectedAt,
  }) = _PhysicalConnection;
}
```

#### 3. Extend RoutingEditorStateLoaded
Add `@Default([]) List<PhysicalConnection> physicalConnections` field.

#### 4. Implement Bus Resolution with Fallbacks
```dart
int? _getBusNumberForPort(core_port.Port port, Slot slot) {
  // Priority 1: busParam metadata
  final busParam = port.metadata['busParam'] as String?;
  if (busParam != null) {
    final paramInfo = slot.parameters.firstWhere(
      (p) => p.name == busParam,
      orElse: () => ParameterInfo.filler(),
    );
    if (paramInfo.parameterNumber >= 0) {
      final paramValue = slot.values.firstWhere(
        (v) => v.parameterNumber == paramInfo.parameterNumber,
        orElse: () => ParameterValue.filler(),
      );
      final bus = paramValue.value;
      return (bus > 0) ? bus : null; // Bus 0 = "None"
    }
  }
  
  // Priority 2: Poly CV ports - gateBus/suggestedBus
  final gateBus = port.metadata['gateBus'] as int?;
  final suggestedBus = port.metadata['suggestedBus'] as int?;
  final fallbackBus = gateBus ?? suggestedBus;
  return (fallbackBus != null && fallbackBus > 0) ? fallbackBus : null;
}
```

#### 5. Add Physical Connection Rendering Layer
In `RoutingEditorWidget`, add second `ConnectionCanvas` with physical connections:
- Reuse existing `ConnectionCanvas` as a second layer (no new widget)
- Use `IgnorePointer` wrapper
- Apply distinct visual styling (blue/green colors)
- Render behind user connections in z-order

### Implementation Order
1. Fix `busParam` propagation in `_buildMetadataForSlot()`
2. Add `PhysicalConnection` model and state field
3. Implement `_getBusNumberForPort()` with fallback logic
4. Add connection discovery methods to cubit with stable sorting
5. Add physical connection rendering layer to widget
6. Update `_hasLoadedStateChanged()` to include `physicalConnections`

### Configuration and Edge Cases

#### Bus Labels Configuration
- **Widget property**: `showBusLabels` parameter on `RoutingEditorWidget`  
- **Default**: `true` when `canvasSize.width >= 800`
- **Format**: "I#" for inputs (I1, I2, ..., I12), "O#" for outputs (O1, O2, ..., O8)
- **Scope**: Physical connections only (not user connections)

#### Output Mode Handling
Physical connections should **ignore** output mode (mix/replace) and remain purely informational.

#### Acceptance Criteria
- Connections appear/disappear on parameter changes
- Never block user interactions (visual-only, no hit-testing)
- Physical connections ignore output-mode styling (mix/replace)
- Follow algorithm nodes when moved
- Show I#/O# labels per widget setting
- Deterministic IDs: `phys_${sourcePortId}->${targetPortId}` for stable diffing
- Stable sorting: by `algorithmIndex`, `isInputConnection`, `sourcePortId`, `targetPortId`
- Non-persisted: derived state only, never sent to hardware
- Deduplicate by `(sourcePortId, targetPortId)` pairs