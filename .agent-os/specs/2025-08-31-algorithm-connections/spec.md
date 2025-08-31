# Algorithm-to-Algorithm Connection Visualization Spec

## Executive Summary

This specification defines the implementation of algorithm-to-algorithm connection visualization in the NT Helper routing editor. The feature will enable users to see complete signal routing between algorithm slots, including validation of execution order constraints.

## Overview

Add visualization of algorithm-to-algorithm connections in the routing editor to show signal flow between algorithm slots based on shared bus assignments, providing users with a complete understanding of their patch routing. The UI integrates with the existing `RoutingEditorWidget` and `ConnectionCanvas` rather than introducing a separate painter.

## Background

The Disting NT processes algorithms in slot order (0→1→2→...→31) with each algorithm potentially sending signals to subsequent algorithms via shared bus assignments. Currently, users can only see physical I/O connections but not internal algorithm connections, making it difficult to understand complete signal routing. This gap in visualization can lead to configuration errors and makes debugging complex patches challenging.

### Current State
- Physical input/output connections are visualized
- Algorithm nodes show ports but not inter-algorithm connections
- Users must mentally track bus assignments to understand signal flow

### Desired State
- Complete visualization of all internal algorithm routing
- Clear indication of valid vs invalid connections
- Real-time updates as parameters change

## Requirements

### Functional Requirements

1. **Connection Discovery**
   - Automatically discover connections where algorithm outputs and inputs share the same bus number (1–28)
   - Sort connections deterministically (source slot, target slot, bus)
   - Update connections immediately when algorithm parameters change

2. **Execution Order Validation**
   - Mark connections as invalid (red/dashed) when source slot ≥ target slot
   - Still render invalid connections to allow user correction
   - Valid connections use the source output port’s color

3. **Bus Type Handling**
   - Treat all bus numbers (1–28) equally for internal algorithm connections from a validation/logic perspective
   - UI may visually indicate categories (input/output/aux) but no behavioral distinction is enforced in this phase

4. **Exclude Physical Connections**
   - Only create algorithm-to-algorithm internal connections (no duplication of physical I/O visualization)

### Non-Functional Requirements

1. **Performance**: Reasonable responsiveness with typical presets (32 algorithms max)
2. **Visual Clarity**: Clear distinction between valid/invalid connections  
3. **Maintainability**: Clean separation of concerns with existing architecture
4. **Testability**: Comprehensive unit and integration test coverage

### User Experience

1. **Visual Feedback**
   - Invalid connections displayed in red with dashed lines
   - Valid connections use the source output port type color (no per-port hue changes)
   - Bus number labels at connection midpoints (format "Bus #")

2. **Real-time Updates**
   - Connections update immediately when parameters change
   - Smooth visual transitions for connection changes

## Success Criteria

### Functional Success
1. **Connection Discovery**: 100% of algorithm-to-algorithm connections correctly identified based on bus assignments (1–28)
2. **Validation Accuracy**: All invalid connections (source slot ≥ target slot) correctly identified and marked
3. **Visual Clarity**: Invalid connections clearly distinguishable from valid ones (red/dashed vs output-port-colored)
4. **Real-time Updates**: Connections update promptly when parameters change
5. **Integration**: Seamless integration with existing physical connection visualization via `ConnectionCanvas`

### Performance Guidance (Non-gating)
- Reasonable responsiveness with typical presets (no formal targets required)

### Quality Success
1. **Test Coverage**: > 90% code coverage for new components
2. **Zero Regressions**: No breaking changes to existing routing functionality
3. **Documentation**: Complete API documentation and user guide updates

## Out of Scope

- User editing of algorithm connections (connections are derived from parameters)
- Bus type validation (all buses treated equally)
- Physical connection modifications (already implemented)
- Connection filtering or grouping (future enhancement)

## Dependencies

- Existing `@lib/cubit/routing_editor_cubit.dart` routing architecture
- Current `@lib/core/routing/` polyphonic and multi-channel routing implementations
- Physical connection visualization already in place (`ConnectionCanvas` layer)
- Shared bus-resolution utility (new): `@lib/core/routing/utils/bus_resolution.dart`

## Assumptions

- Algorithm slots process in order (0, 1, 2, ..., 31)
- Bus assignments determine signal routing  
- Users understand execution order constraints
- Existing routing architecture remains unchanged
- Maximum 32 algorithms
- Bus values 1–28 are valid for internal connections; 0 means "None"
- Physical outputs map to buses 13–20 (hardware jacks), which will not change

## Risks and Mitigations

| Risk | Impact | Probability | Mitigation |
|------|--------|------------|------------|
| Performance degradation with many connections | High | Medium | Implement connection caching and viewport culling |
| Visual clutter with complex routing | Medium | High | Add connection opacity/filtering options in future phase |
| Incorrect bus resolution logic | High | Low | Reuse existing tested bus resolution from RoutingEditorCubit |
| Memory leaks from connection updates | Medium | Low | Implement proper disposal and connection lifecycle management |
| User confusion about invalid connections | Medium | Medium | Clear visual distinction and optional tooltips |
