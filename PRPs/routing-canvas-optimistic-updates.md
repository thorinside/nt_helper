name: "Routing Canvas Optimistic Updates - UX Speed Enhancement"
description: |
  Implement comprehensive optimistic updates for the routing canvas to provide immediate visual feedback
  while hardware updates happen asynchronously in the background.

---

## Goal

**Feature Goal**: Enhance routing canvas UX speed by implementing optimistic updates with confirmation for all user interactions

**Deliverable**: Modified routing canvas system with immediate visual feedback and background hardware synchronization

**Success Definition**: All routing canvas operations show immediate visual feedback (<50ms), with hardware updates confirming in background without blocking UI

## User Persona

**Target User**: Musicians and sound designers using Disting NT hardware module

**Use Case**: Creating and modifying audio signal routing between algorithms in real-time during performance or sound design

**User Journey**: 
1. User drags from output port to create connection
2. Connection appears immediately with visual confirmation
3. User continues working while hardware updates in background
4. If hardware update fails, visual indication shows error state

**Pain Points Addressed**: 
- Current lag between user action and visual feedback disrupts creative flow
- Sequential hardware updates block rapid routing changes
- Waiting for hardware confirmation interrupts workflow

## Why

- Musicians need responsive interfaces during live performance
- Complex routing setups require rapid iteration and experimentation
- Hardware communication delays (50-1000ms) shouldn't block UI interactions
- Creative flow requires immediate visual feedback for all actions

## What

Implement optimistic update patterns for all routing canvas operations with immediate visual feedback and background hardware synchronization.

### Success Criteria

- [ ] Connection creation shows visual feedback in <50ms
- [ ] Connection removal updates UI immediately
- [ ] Node position changes are instant with no lag
- [ ] Hardware updates happen asynchronously without blocking UI
- [ ] Failed operations show clear error states without full UI refresh
- [ ] Successful operations show subtle confirmation indicators

## All Needed Context

### Context Completeness Check

_This PRP provides complete context for implementing optimistic updates in the routing canvas without requiring knowledge of the broader application architecture._

### Documentation & References

```yaml
# MUST READ - Include these in your context window
- url: https://docs.flutter.dev/app-architecture/design-patterns/optimistic-state
  why: Flutter's official optimistic state pattern guide
  critical: Shows proper state rollback patterns for failed operations

- url: https://bloclibrary.dev/#/architecture
  why: Cubit state management patterns for optimistic updates
  critical: copyWith pattern for state updates without mutations

- file: lib/cubit/node_routing_cubit.dart
  why: Current routing state management with partial optimistic updates
  pattern: removeConnection already uses optimistic pattern - extend to other operations
  gotcha: Must preserve subscription to DistingCubit for hardware state sync

- file: lib/services/auto_routing_service.dart
  why: Hardware communication layer for routing updates
  pattern: updateBusParameters method currently awaits each update sequentially
  gotcha: Parameter updates trigger DistingCubit state changes that NodeRoutingCubit subscribes to

- file: lib/cubit/disting_cubit.dart
  why: Core hardware state management with existing optimistic patterns
  pattern: updateParameterValue already has optimistic updates with 2-second verification
  gotcha: Verification delay is currently too conservative at 2000ms

- file: lib/domain/parameter_update_queue.dart
  why: Existing queue system for consolidating parameter updates
  pattern: Latest-value-wins consolidation prevents queue buildup
  gotcha: Current 50ms operation interval could be reduced to 25-30ms
```

### Current Implementation Analysis

```dart
// CURRENT: removeConnection has optimistic updates (good pattern to extend)
Future<void> removeConnection(Connection connection) async {
  // Immediate visual update
  final updatedConnections = currentState.connections
      .where((c) => c.id != connection.id)
      .toList();
  emit(currentState.copyWith(connections: updatedConnections));
  
  // Background hardware update
  _autoRoutingService.removeConnection(...).then((_) {
    // Success
  }).catchError((e) {
    // Error handling
  });
}

// CURRENT: createConnection waits for hardware (needs optimization)
Future<void> createConnection(...) async {
  // Validation first
  final validationResult = RoutingValidator.validateConnection(...);
  
  // Hardware update (blocking)
  await _autoRoutingService.assignBusForConnection(...);
  await _autoRoutingService.updateBusParameters(...);
  
  // State update only after hardware confirms
  _updateFromDistingState(latestState);
}
```

### Known Gotchas

```dart
// CRITICAL: NodeRoutingCubit subscribes to DistingCubit state changes
// Any optimistic update must not break this subscription pattern

// CRITICAL: Connection IDs use pattern: '${source}_${sourcePort}_${target}_${targetPort}'
// This must remain consistent for proper connection tracking

// CRITICAL: Bus assignment (21-28 for aux buses) happens in AutoRoutingService
// Optimistic updates need to predict bus assignment or show placeholder

// CRITICAL: Execution order validation - connections can't go backwards
// Source algorithm index must be less than target (except for physical nodes)
```

## Implementation Blueprint

### Data Models and Structure

```dart
// Add to NodeRoutingState for tracking pending operations
class NodeRoutingStateLoaded extends NodeRoutingState {
  final Set<String> pendingConnections;  // Connection IDs being created
  final Set<String> failedConnections;   // Connection IDs that failed
  final Map<String, DateTime> operationTimestamps; // For timeout tracking
  
  // Existing fields remain...
}

// Add connection states enum
enum ConnectionState {
  confirmed,   // Hardware confirmed
  pending,     // Optimistically added, awaiting confirmation  
  failed,      // Hardware update failed
}
```

### Implementation Tasks (ordered by dependencies)

```yaml
Task 1: MODIFY lib/cubit/node_routing_state.dart
  - ADD: pendingConnections Set<String> field to NodeRoutingStateLoaded
  - ADD: failedConnections Set<String> field for error tracking
  - ADD: operationTimestamps Map<String, DateTime> for timeout detection
  - FOLLOW pattern: Existing copyWith implementation
  - PRESERVE: All existing state fields and functionality

Task 2: MODIFY lib/cubit/node_routing_cubit.dart - createConnection method
  - IMPLEMENT: Optimistic connection creation with immediate visual feedback
  - ADD: Connection to state immediately with pending status
  - MOVE: Hardware update to background Future
  - ADD: Success callback to mark connection as confirmed
  - ADD: Error callback with rollback logic
  - PATTERN: Follow existing removeConnection optimistic pattern

Task 3: MODIFY lib/services/auto_routing_service.dart - updateBusParameters
  - CHANGE: Sequential awaits to parallel Future.wait where possible
  - ADD: Return Future that completes when all updates finish
  - REDUCE: Operation delays from 50ms to 25-30ms
  - PRESERVE: Existing parameter update logic and bus assignment

Task 4: MODIFY lib/ui/routing/routing_canvas.dart - Visual feedback
  - ADD: Visual indicators for pending connections (dashed lines, opacity)
  - ADD: Error state visualization for failed connections (red highlight)
  - ADD: Success confirmation animation (subtle green flash)
  - IMPLEMENT: Loading spinners on connection endpoints during pending state
  - PRESERVE: Existing drag-and-drop interaction logic

Task 5: MODIFY lib/domain/parameter_update_queue.dart - Timing optimization
  - REDUCE: processingInterval from 10ms to 5ms
  - REDUCE: operationInterval from 50ms to 25ms
  - ADD: Priority queue for user-initiated updates
  - PRESERVE: Latest-value-wins consolidation logic

Task 6: ADD lib/ui/routing/connection_state_indicator.dart
  - CREATE: Widget for showing connection state (pending/confirmed/failed)
  - IMPLEMENT: Animated transitions between states
  - ADD: Retry button for failed connections
  - FOLLOW pattern: Material Design loading indicators
```

### Implementation Patterns & Key Details

```dart
// Enhanced createConnection with optimistic updates
Future<void> createConnection({
  required int sourceAlgorithmIndex,
  required String sourcePortId,
  required int targetAlgorithmIndex,
  required String targetPortId,
}) async {
  final currentState = state;
  if (currentState is! NodeRoutingStateLoaded) return;

  // Generate connection ID
  final connectionId = '${sourceAlgorithmIndex}_${sourcePortId}_${targetAlgorithmIndex}_$targetPortId';
  
  // Create optimistic connection
  final optimisticConnection = Connection(
    id: connectionId,
    sourceAlgorithmIndex: sourceAlgorithmIndex,
    sourcePortId: sourcePortId,
    targetAlgorithmIndex: targetAlgorithmIndex,
    targetPortId: targetPortId,
    assignedBus: 21, // Temporary, will be assigned by service
    replaceMode: true,
    isValid: true,
  );

  // Validate locally first
  final validationResult = RoutingValidator.validateConnection(
    proposedConnection: optimisticConnection,
    existingConnections: currentState.connections,
    algorithmPorts: currentState.portLayouts,
  );

  if (!validationResult.isValid) {
    emit(currentState.copyWith(
      errorMessage: validationResult.errors.join(', '),
    ));
    return;
  }

  // OPTIMISTIC UPDATE - Add connection immediately
  emit(currentState.copyWith(
    connections: [...currentState.connections, optimisticConnection],
    pendingConnections: {...currentState.pendingConnections, connectionId},
    connectedPorts: _extractConnectedPorts([...currentState.connections, optimisticConnection]),
    errorMessage: null,
  ));

  // Hardware update in background
  _autoRoutingService.assignBusForConnection(
    sourceAlgorithmIndex: sourceAlgorithmIndex,
    sourcePortId: sourcePortId,
    targetAlgorithmIndex: targetAlgorithmIndex,
    targetPortId: targetPortId,
    existingConnections: currentState.connections,
  ).then((busAssignment) async {
    // Update with actual bus assignment
    await _autoRoutingService.updateBusParameters(busAssignment.parameterUpdates);
    
    // Mark as confirmed
    final confirmedState = state;
    if (confirmedState is NodeRoutingStateLoaded) {
      final updatedConnections = confirmedState.connections.map((c) {
        if (c.id == connectionId) {
          return c.copyWith(
            assignedBus: busAssignment.assignedBus,
            edgeLabel: busAssignment.edgeLabel,
          );
        }
        return c;
      }).toList();
      
      emit(confirmedState.copyWith(
        connections: updatedConnections,
        pendingConnections: confirmedState.pendingConnections.difference({connectionId}),
      ));
    }
  }).catchError((error) {
    // Rollback on failure
    final errorState = state;
    if (errorState is NodeRoutingStateLoaded) {
      emit(errorState.copyWith(
        connections: errorState.connections.where((c) => c.id != connectionId).toList(),
        pendingConnections: errorState.pendingConnections.difference({connectionId}),
        failedConnections: {...errorState.failedConnections, connectionId},
        errorMessage: 'Failed to create connection: $error',
      ));
    }
  });
}

// Visual feedback in RoutingCanvas
Widget _buildConnection(Connection connection, bool isPending, bool isFailed) {
  return CustomPaint(
    painter: ConnectionPainter(
      connection: connection,
      style: ConnectionStyle(
        color: isFailed ? Colors.red : 
               isPending ? Colors.grey : 
               Colors.blue,
        strokeWidth: isPending ? 2.0 : 3.0,
        dashPattern: isPending ? [5, 5] : null, // Dashed for pending
        opacity: isPending ? 0.6 : 1.0,
      ),
    ),
  );
}
```

### Integration Points

```yaml
TIMING:
  - parameter_update_queue.dart: Reduce intervals to 5ms/25ms
  - settings_service.dart: Add optimistic update timeout setting (default 500ms)
  
STATE:
  - NodeRoutingCubit: Subscribe to DistingCubit for hardware sync
  - NodeRoutingState: Track pending/failed operations
  
VISUAL:
  - RoutingCanvas: Show connection states with visual indicators
  - ConnectionPainter: Support dashed lines and opacity for pending
```

## Validation Loop

### Level 1: Syntax & Style

```bash
# Validate modified files
flutter analyze lib/cubit/node_routing_cubit.dart
flutter analyze lib/cubit/node_routing_state.dart  
flutter analyze lib/services/auto_routing_service.dart
flutter analyze lib/ui/routing/routing_canvas.dart

# Expected: Zero errors or warnings
```

### Level 2: Unit Tests

```bash
# Test optimistic update logic
flutter test test/cubit/node_routing_cubit_test.dart
flutter test test/services/auto_routing_service_test.dart

# Test timing changes
flutter test test/domain/parameter_update_queue_test.dart

# Expected: All tests pass, new tests for optimistic scenarios
```

### Level 3: Integration Testing

```bash
# Run the app and test routing canvas
flutter run

# Manual validation checklist:
# 1. Create connection - should appear immediately
# 2. Remove connection - should disappear immediately  
# 3. Create multiple connections rapidly - all should appear without blocking
# 4. Disconnect hardware - connections should show error state
# 5. Reconnect hardware - state should reconcile automatically

# Performance testing - measure UI response time
# Target: <50ms from user action to visual feedback
```

### Level 4: Hardware Validation

```bash
# Test with actual Disting NT hardware
# 1. Connect to hardware via MIDI
# 2. Create routing connections rapidly
# 3. Verify hardware state matches visual state
# 4. Test error recovery by disconnecting MIDI during operation
# 5. Verify rollback on hardware communication failure

# Monitor performance metrics
flutter analyze --watch
# Check for jank in routing canvas interactions
```

## Final Validation Checklist

### Technical Validation

- [ ] All routing operations show immediate visual feedback (<50ms)
- [ ] Hardware updates complete asynchronously without blocking UI
- [ ] Failed operations rollback gracefully with error indication
- [ ] Successful operations show subtle confirmation
- [ ] No flutter analyze warnings or errors
- [ ] Unit tests cover optimistic update scenarios

### Feature Validation

- [ ] Connection creation is instantaneous visually
- [ ] Connection removal is instantaneous visually
- [ ] Multiple rapid operations don't block each other
- [ ] Hardware state eventually becomes consistent
- [ ] Error states are clearly indicated
- [ ] Users can retry failed operations

### Code Quality Validation

- [ ] Follows existing Cubit patterns for state management
- [ ] Preserves DistingCubit subscription for hardware sync
- [ ] Optimistic updates use copyWith pattern consistently
- [ ] Error handling includes proper rollback logic
- [ ] Visual indicators follow Material Design guidelines

### Performance Validation

- [ ] UI response time <50ms for all operations
- [ ] No frame drops during routing operations
- [ ] Parameter queue processes efficiently at new intervals
- [ ] Memory usage remains stable during extended use

---

## Anti-Patterns to Avoid

- ❌ Don't break the DistingCubit subscription pattern
- ❌ Don't mutate state directly - always use copyWith
- ❌ Don't block UI thread with await for hardware operations
- ❌ Don't ignore validation before optimistic updates
- ❌ Don't forget rollback logic for failed operations
- ❌ Don't make visual feedback too aggressive or distracting