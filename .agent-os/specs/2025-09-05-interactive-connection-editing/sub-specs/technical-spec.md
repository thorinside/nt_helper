# Technical Specification

This is the technical specification for the spec detailed in @.agent-os/specs/2025-09-05-interactive-connection-editing/spec.md

> Created: 2025-09-05
> Version: 1.0.0

## Technical Requirements

- **Gesture Recognition System**: Implement drag detection using Flutter's GestureDetector with proper hit testing for port coordinates and drag preview rendering during connection creation
- **Bus Assignment Logic**: Automatic bus assignment using physical port numbers (1-12 for inputs, 13-20 for outputs) and aux buses (21-28) for algorithm-to-algorithm connections
- **Optimistic State Management**: Extend RoutingEditorCubit with optimistic update methods that immediately show changes while syncing to hardware in background with automatic revert on failure
- **Connection Validation**: Real-time validation during drag operations checking port compatibility (output-to-input, compatible signal types), preventing self-connections and duplicate connections
- **Visual Feedback System**: Connection preview lines during drag, 10% thickness increase on hover, delete icons near cursor, mode indicators (blue styling for Replace mode), and valid drop zone highlighting
- **Hardware Synchronization**: Automatic parameter updates through existing MIDI SysEx communication with conflict detection and user notification on sync failures
- **Touch and Mouse Support**: Dual interaction support with mouse hover effects and touch-friendly gesture recognition for cross-platform compatibility
- **Connection Mode Toggle**: Toggle between Add/Replace modes by updating corresponding algorithm mode parameters with visual indicators and "(R)" suffix display

## Performance Requirements

- Drag operations must maintain 60fps with smooth preview rendering
- Connection validation must complete within 16ms for real-time feedback
- Hardware sync operations should complete within 2 seconds with timeout handling
- Visual feedback animations must be smooth and responsive on all target platforms

## Integration Requirements

- Use existing RoutingEditorCubit state management architecture
- Integrate with ConnectionDiscoveryService for bus assignment logic
- Maintain compatibility with existing Port and Connection model classes
- Follow established Flutter/Cubit patterns and zero-tolerance flutter analyze policy
- Use debugPrint() for all logging and maintain existing color scheme standards

## Approach

### Core Architecture

The interactive connection editing will be implemented as extensions to the existing routing framework:

1. **RoutingEditorCubit Extensions**:
   - Add `beginConnectionDrag(Port sourcePort)` method for starting drag operations
   - Add `updateConnectionPreview(Offset position)` for real-time drag tracking
   - Add `completeConnection(Port targetPort)` for finalizing connections
   - Add `cancelConnectionDrag()` for handling cancelled operations
   - Add `deleteConnection(Connection connection)` for connection removal

2. **Interactive Connection Manager**:
   - New service class `InteractiveConnectionManager` to handle drag state
   - Manages temporary connection preview during drag operations
   - Validates connection compatibility in real-time
   - Coordinates with existing ConnectionDiscoveryService for bus assignments

3. **Widget Layer Enhancements**:
   - Extend `RoutingEditorWidget` with gesture detection overlay
   - Add `ConnectionDragLayer` widget for rendering drag previews
   - Implement hit testing for accurate port targeting
   - Add hover effects and visual feedback systems

### Bus Assignment Strategy

- **Physical Hardware Ports**: Use direct mapping (1-12 inputs, 13-20 outputs)
- **Algorithm Connections**: Automatically assign from aux bus pool (21-28)
- **Conflict Resolution**: Detect bus conflicts and prompt user for resolution
- **Mode-Aware Assignment**: Respect Add/Replace mode settings for existing connections

### State Synchronization Flow

```
User Drag Start → Optimistic State Update → Hardware Sync Request
                                         ↓
User Sees Change ← Visual Confirmation ← Sync Success
                                         ↓
                  ← State Revert ← Sync Failure
```

### Validation Rules

1. **Port Compatibility**: Output ports can only connect to input ports
2. **Signal Type Matching**: CV-to-CV, Audio-to-Audio, Gate-to-Gate connections
3. **Self-Connection Prevention**: Algorithm cannot connect to itself
4. **Duplicate Prevention**: Same source-target pair cannot have multiple connections
5. **Bus Availability**: Ensure target bus numbers are available for assignment

## External Dependencies

- **Flutter Framework**: GestureDetector, CustomPainter for drag rendering
- **Existing Routing Framework**: All classes in `lib/core/routing/`
- **MIDI Communication**: Existing SysEx parameter update mechanisms
- **State Management**: Cubit pattern extensions for optimistic updates
- **Touch/Mouse Input**: Platform-specific gesture recognition systems