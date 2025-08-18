name: "Interactive Output Mode Toggle for Routing Canvas"
description: |
  Enable one-click toggling between Add and Replace modes for algorithm output connections directly on the routing canvas labels.

---

## Goal

**Feature Goal**: Enable users to toggle between Add and Replace modes for algorithm outputs by clicking on connection labels in the routing canvas

**Deliverable**: Interactive connection labels that display current mode and toggle between Add/Replace on click with optimistic updates

**Success Definition**: Users can click connection labels to toggle output modes with immediate visual feedback and background hardware synchronization

## User Persona

**Target User**: Musicians and sound designers using the Disting NT module

**Use Case**: Configuring signal routing modes while visually seeing the patch layout, without navigating to separate parameter editors

**User Journey**: 
1. User views routing canvas with connections displayed
2. User hovers over connection label to see it's interactive (cursor change, size increase)
3. User clicks label to toggle between Add and Replace modes
4. Label immediately updates with new mode and visual indicator
5. Hardware receives parameter update in background

**Pain Points Addressed**: 
- Currently must navigate away from routing view to change output modes
- No visual indication of current output mode on connections
- Tedious to find and modify mode parameters for each output

## Why

- Provides immediate visual feedback about signal routing behavior (mixing vs replacing)
- Reduces clicks and navigation required to configure routing modes
- Makes the routing canvas a complete routing configuration interface
- Improves workflow for complex patches with multiple signal paths
- Scalable to maximum preset size (32 algorithms = ~100 connections max)

## What

Interactive connection labels that show and control output modes with hover effects and click-to-toggle functionality

### Success Criteria

- [ ] Connection labels display current mode (Add/Replace) 
- [ ] Hover effect provides visual feedback (size increase, background color change)
- [ ] Click toggles between modes with optimistic UI update
- [ ] Background parameter updates sync to hardware
- [ ] Visual distinction between Add (black background) and Replace (blue background) modes
- [ ] Works with existing connection rendering and hit testing

## All Needed Context

### Context Completeness Check

_This PRP contains all routing canvas implementation details, parameter update patterns, and Flutter interaction patterns needed for implementation._

### Documentation & References

```yaml
# MUST READ - Include these in your context window
- url: https://api.flutter.dev/flutter/widgets/MouseRegion-class.html
  why: MouseRegion widget for hover detection over painted elements
  critical: onHover callback provides position for hit testing painted labels

- file: lib/ui/routing/connection_painter.dart
  why: Current connection and label rendering implementation
  pattern: _drawEdgeLabel method at line 219 for label drawing, _isPointNearBezier for hit testing
  gotcha: Labels drawn at bezier midpoint using _calculateBezierMidpoint

- file: lib/ui/routing/routing_canvas.dart
  why: Main canvas widget with event handling
  pattern: MouseRegion setup at line 190, _handleConnectionHover method
  gotcha: Must convert global to local coordinates for hit testing

- file: lib/domain/parameter_update_queue.dart
  why: Parameter update queue for hardware synchronization
  pattern: updateParameter method with latest-value-wins consolidation
  gotcha: 5ms processing interval, 25ms operation interval for rate limiting

- file: lib/cubit/disting_cubit.dart
  why: Main state management with optimistic update patterns
  pattern: updateParameterValue method shows optimistic update pattern
  gotcha: Must emit new state immediately, then queue hardware update

- file: lib/ui/widgets/file_parameter_editor.dart
  why: Example of click-to-edit and optimistic value patterns
  pattern: _optimisticValue tracking, GestureDetector for clicks
  gotcha: Shows both hover and click interaction patterns

- docfile: PRPs/ai_docs/flutter_hover_label_interaction.md
  why: Custom documentation for hover and click patterns in CustomPainter
  section: Connection Label Hover and Click Detection in CustomPainter

- docfile: PRPs/ai_docs/routing_bus_system.md
  why: Bus system documentation including signal modes
  section: Bus Signal Modes - explains Add/Replace behavior
```

### Current Codebase Structure

```bash
lib/
├── ui/
│   └── routing/
│       ├── routing_canvas.dart          # Main canvas widget with MouseRegion
│       ├── connection_painter.dart      # Connection and label rendering
│       ├── node_routing_widget.dart     # BlocBuilder wrapper
│       └── connection_state_indicator.dart # Connection state visuals
├── cubit/
│   ├── node_routing_cubit.dart         # Routing state management
│   ├── node_routing_state.dart         # State definitions
│   └── disting_cubit.dart              # Main app state with parameters
├── domain/
│   └── parameter_update_queue.dart     # Hardware update queue
├── models/
│   └── connection.dart                 # Connection model with replaceMode field
└── services/
    └── auto_routing_service.dart       # Bus assignment and routing
```

### Known Gotchas & Implementation Notes

```dart
// CRITICAL: Mode parameter naming pattern
// Pattern: Output parameter name + " mode" (e.g., "Output" → "Output mode")
// Values: Integer 0 = Add, 1 = Replace

// GOTCHA: ConnectionPainter is stateless, must track hover state in parent widget
// Pattern: Pass hoveredLabelId to painter, rebuild on hover change

// CRITICAL: Must use optimistic updates with revert on failure
// Pattern: Update UI immediately, revert if hardware update fails
// Debounce: 500ms debounce for rapid clicks

// GOTCHA: Hit boxes for labels need padding for easier clicking
// Use 4-6 pixel padding around text bounds for hit detection

// CRITICAL: Physical I/O detection
// Check algorithmIndex < 0 (negative values indicate physical I/O)
// Physical I/O connections don't have mode parameters

// VISUAL: Exact specifications
// Add mode: Black background with 0.7 opacity (0.9 on hover)
// Replace mode: Blue background with 0.7 opacity (0.9 on hover)
// Font size: 10px normal, 12px on hover

// MOBILE: No hover effects, direct tap to toggle
// Desktop: Hover + click interaction
// Mobile: Tap only interaction

// SOURCE OF TRUTH: Parameter values
// Initial mode state must be read from actual parameter values
// Connection.replaceMode field used for UI state tracking

// PERFORMANCE: No optimization needed
// Max 32 algorithms = max ~100 connections
// Linear hit testing is fast enough for human interaction
```

## Implementation Blueprint

### Data Models and Structure

```dart
// Add to lib/ui/routing/connection_painter.dart
class LabelHitBox {
  final String id;        // Format: "connection_${connectionId}_mode"
  final Rect bounds;      // Hit detection area with padding
  final Offset center;    // Label center position
  
  LabelHitBox({
    required this.id,
    required this.bounds,
    required this.center,
  });
}

// Modify lib/models/connection.dart
class Connection {
  // ... existing fields
  final bool replaceMode;  // true = Replace (1), false = Add (0)
  // This field already exists, we'll use it for mode state
}

// Add to lib/cubit/node_routing_state.dart
class NodeRoutingState {
  // ... existing fields
  final String? hoveredLabelId;  // Currently hovered label ID
  // Note: Mode state stored in Connection.replaceMode, not separate map
}
```

### Implementation Tasks (ordered by dependencies)

```yaml
Task 1: MODIFY lib/ui/routing/connection_painter.dart
  - ADD: List<LabelHitBox> labelHitBoxes field to track label positions
  - MODIFY: _drawEdgeLabel to record hit boxes and apply hover effects
  - ADD: getLabelAtPosition(Offset position) method for hit testing
  - IMPLEMENT: Hover visual feedback (10px→12px font, opacity change)
  - VISUAL: Black (Add) vs Blue (Replace) backgrounds as specified
  - NAMING: Use existing _drawEdgeLabel pattern, add _recordLabelHitBox helper
  - PLACEMENT: Add fields at top, modify existing _drawEdgeLabel method

Task 2: MODIFY lib/cubit/node_routing_cubit.dart
  - ADD: hoveredLabelId field to state for hover tracking
  - ADD: Timer? _toggleDebounceTimer for 500ms debounce
  - IMPLEMENT: loadConnectionModes() to read mode parameters from slots on init
  - IMPLEMENT: toggleConnectionMode(String connectionId) with optimistic update and revert
  - ADD: findModeParameterForOutput() helper method in cubit
  - FOLLOW pattern: Existing optimistic update pattern in createConnection
  - ERROR: Revert Connection.replaceMode on parameter update failure

Task 3: MODIFY lib/ui/routing/routing_canvas.dart
  - MODIFY: _handleConnectionHover to detect label hover using painter hit boxes
  - ADD: _handleLabelClick to detect label clicks with debounce
  - MODIFY: MouseRegion cursor to show click cursor on label hover
  - PLATFORM: Check Platform.isAndroid || Platform.isIOS for mobile behavior
  - IMPLEMENT: Call cubit.toggleConnectionMode on label click
  - FOLLOW pattern: Existing _handleConnectionHover at line 495
  - PLACEMENT: Modify existing MouseRegion and GestureDetector setup

Task 4: MODIFY lib/models/connection.dart
  - MODIFY: getEdgeLabel() to include mode in label text
  - ADD: getModeText() helper returning 'A' for Add, 'R' for Replace
  - UPDATE: copyWith to handle replaceMode changes
  - FOLLOW pattern: Existing getEdgeLabel implementation
  - NAMING: Keep consistent with existing label methods

Task 5: MODIFY lib/cubit/node_routing_cubit.dart (helper methods)
  - ADD: _findParameterByName(int algorithmIndex, String paramName) helper
  - ADD: _getOutputParameterName(int algorithmIndex, String portId) helper
  - IMPLEMENT: Logic to find parameter with name pattern: outputName + " mode"
  - INTEGRATE: Use existing slots and parameter info from DistingCubit
  - PATTERN: Similar to existing parameter lookup patterns in cubit

Task 6: CREATE test/ui/routing/connection_mode_toggle_test.dart
  - IMPLEMENT: Test hover detection on labels
  - IMPLEMENT: Test click toggles mode with debounce
  - IMPLEMENT: Test optimistic update and revert on failure
  - IMPLEMENT: Test mobile vs desktop behavior differences
  - FOLLOW pattern: Existing widget tests in test/ui/
  - COVERAGE: Hover, click, state updates, error cases, debounce timing
```

### Implementation Patterns & Key Details

```dart
// Modified _drawEdgeLabel in ConnectionPainter
void _drawEdgeLabel(
  Canvas canvas,
  Path path,
  String label,
  Color connectionColor,
  String connectionId,
  bool replaceMode,  // Use existing Connection field
) {
  final midpoint = _calculateBezierMidpoint(/* ... */);
  
  // Check if this connection supports mode toggle
  final hasMode = connection.sourceAlgorithmIndex >= 0;  // Not physical I/O
  final displayLabel = hasMode 
    ? '$label (${replaceMode ? 'R' : 'A'})'
    : label;
  
  // Check hover state
  final isHovered = hoveredLabelId == 'connection_${connectionId}_mode';
  
  final textPainter = TextPainter(
    text: TextSpan(
      text: displayLabel,
      style: TextStyle(
        color: Colors.white,
        fontSize: isHovered ? 12 : 10,  // 10px normal, 12px hover
        fontWeight: FontWeight.bold,
      ),
    ),
    textDirection: TextDirection.ltr,
  );
  
  textPainter.layout();
  final textSize = textPainter.size;
  
  // Record hit box for click detection
  if (hasMode) {
    const padding = 6.0;
    labelHitBoxes.add(LabelHitBox(
      id: 'connection_${connectionId}_mode',
      bounds: Rect.fromCenter(
        center: midpoint,
        width: textSize.width + padding * 2,
        height: textSize.height + padding * 2,
      ),
      center: midpoint,
    ));
  }
  
  // Draw background with mode-specific color
  final backgroundColor = hasMode
    ? (replaceMode 
      ? Colors.blue.withOpacity(isHovered ? 0.9 : 0.7)    // Replace = blue
      : Colors.black.withOpacity(isHovered ? 0.9 : 0.7))  // Add = black
    : Colors.black.withOpacity(0.7);  // No mode = black
    
  // Draw background and text (existing pattern)
  // ...
}

// Toggle implementation in NodeRoutingCubit with debounce and error handling
Timer? _toggleDebounceTimer;

Future<void> toggleConnectionMode(String connectionId) async {
  // Cancel previous debounce timer
  _toggleDebounceTimer?.cancel();
  
  // Debounce rapid clicks (500ms)
  _toggleDebounceTimer = Timer(const Duration(milliseconds: 500), () async {
    final connection = state.connections.firstWhere((c) => c.id == connectionId);
    
    // Skip physical I/O connections (negative algorithmIndex)
    if (connection.sourceAlgorithmIndex < 0) return;
    
    // Find mode parameter (pattern: output name + " mode")
    final outputParam = /* find output parameter name */;
    final modeParamName = outputParam + " mode";
    final modeParamNumber = _findParameterByName(
      connection.sourceAlgorithmIndex, 
      modeParamName
    );
    
    if (modeParamNumber == null) return;
    
    // Get current mode from Connection
    final currentMode = connection.replaceMode ? 1 : 0;
    final newMode = currentMode == 0 ? 1 : 0;
    
    // Optimistic update - immediate UI change
    final updatedConnection = connection.copyWith(
      replaceMode: newMode == 1,
    );
    
    final updatedConnections = state.connections.map((c) => 
      c.id == connectionId ? updatedConnection : c
    ).toList();
    
    emit(state.copyWith(connections: updatedConnections));
    
    try {
      // Queue hardware update
      await _distingCubit.updateParameterValue(
        algorithmIndex: connection.sourceAlgorithmIndex,
        parameterNumber: modeParamNumber,
        value: newMode.toDouble(),
        needsStringUpdate: false,  // Mode enums don't need string update
      );
    } catch (error) {
      // Revert on failure
      debugPrint('Mode toggle failed, reverting: $error');
      emit(state.copyWith(connections: state.connections.map((c) => 
        c.id == connectionId ? connection : c  // Revert to original
      ).toList()));
    }
  });
}

// Mobile platform detection in routing_canvas.dart
import 'dart:io' show Platform;

bool get isMobile => Platform.isAndroid || Platform.isIOS;

// In build method:
MouseRegion(
  cursor: isMobile ? SystemMouseCursors.basic 
    : (_hoveredLabelId != null ? SystemMouseCursors.click : SystemMouseCursors.basic),
  onHover: isMobile ? null : _handleConnectionHover,
  onExit: isMobile ? null : (_) => _handleConnectionExit(),
  // ...

// Initial mode loading from parameters (source of truth)
Future<void> loadConnectionModes() async {
  final updatedConnections = <Connection>[];
  
  for (final connection in state.connections) {
    // Skip physical I/O
    if (connection.sourceAlgorithmIndex < 0) {
      updatedConnections.add(connection);
      continue;
    }
    
    // Find output parameter name first
    final outputParamName = _getOutputParameterName(
      connection.sourceAlgorithmIndex,
      connection.sourcePortId,
    );
    
    // Find mode parameter by pattern
    final modeParamName = '$outputParamName mode';
    final modeParam = _findParameterByName(
      connection.sourceAlgorithmIndex,
      modeParamName,
    );
    
    if (modeParam != null) {
      // Read actual value from slots (source of truth)
      final modeValue = _distingCubit.state.slots[connection.sourceAlgorithmIndex]
        .values[modeParam].value;
      
      // Update connection with actual mode
      updatedConnections.add(connection.copyWith(
        replaceMode: modeValue == 1,  // 1 = Replace, 0 = Add
      ));
    } else {
      // Keep existing if no mode parameter found
      updatedConnections.add(connection);
    }
  }
  
  emit(state.copyWith(connections: updatedConnections));
}
```

### Integration Points

```yaml
STATE:
  - add to: NodeRoutingState
  - fields: "String? hoveredLabelId only (mode stored in Connection.replaceMode)"

CONNECTION:
  - use: Connection.replaceMode field (already exists)
  - pattern: "Update via copyWith when toggling modes"

HOVER:
  - modify: routing_canvas.dart MouseRegion
  - pattern: "Check painter.getLabelAtPosition in _handleConnectionHover"
  - mobile: "Disable hover on Platform.isAndroid || Platform.isIOS"

CLICK:
  - modify: routing_canvas.dart GestureDetector
  - pattern: "Add label click detection to existing onTapDown"
  - debounce: "500ms timer to prevent rapid toggles"
  
PARAMETER:
  - integrate: DistingCubit.updateParameterValue
  - pattern: "Use existing optimistic update flow with try/catch for revert"
  - discovery: "Find mode param by pattern: outputName + ' mode'"

INITIAL_STATE:
  - source: "Read from actual parameter values on preset load"
  - method: "loadConnectionModes() called after preset loaded"
  - update: "Set Connection.replaceMode based on parameter value"
```

## Validation Loop

### Level 1: Syntax & Style (Immediate Feedback)

```bash
# After each file modification
flutter analyze lib/ui/routing/connection_painter.dart
flutter analyze lib/cubit/node_routing_cubit.dart
flutter analyze lib/ui/routing/routing_canvas.dart
flutter analyze lib/services/mode_parameter_service.dart

# Full project check
flutter analyze

# Expected: Zero errors and warnings
```

### Level 2: Unit Tests (Component Validation)

```bash
# Test mode parameter service
flutter test test/services/mode_parameter_service_test.dart -v

# Test connection mode toggle
flutter test test/ui/routing/connection_mode_toggle_test.dart -v

# Test hover and click detection
flutter test test/ui/routing/connection_painter_test.dart -v

# Run all routing tests
flutter test test/ui/routing/ -v

# Expected: All tests pass
```

### Level 3: Integration Testing (System Validation)

```bash
# Run the app and test interactively
flutter run

# Manual test checklist:
# 1. Create algorithm with output mode parameter
# 2. Connect algorithm output to another algorithm or physical output
# 3. Hover over connection label - verify cursor change and size increase
# 4. Click label - verify mode toggles between A and R
# 5. Verify background color changes (black for Add, blue for Replace)
# 6. Check parameter editor shows updated mode value
# 7. Save preset and reload - verify mode persists

# Check optimistic updates work
# 1. Disconnect from hardware (demo mode)
# 2. Click label - should still update immediately
# 3. Reconnect - verify sync with hardware
```

### Level 4: Hardware Validation

```bash
# Connect to actual Disting NT hardware

# Verify parameter updates reach hardware
# 1. Toggle mode via label click
# 2. Check MIDI monitor for SysEx parameter update
# 3. Verify audio behavior matches (Add mixes, Replace overwrites)

# Test rapid clicking
# 1. Click label multiple times quickly
# 2. Verify parameter queue consolidates updates
# 3. Check final state matches UI

# Test with multiple connections
# 1. Create multiple algorithm outputs
# 2. Toggle different modes
# 3. Verify each connection maintains correct mode
```

## Final Validation Checklist

### Technical Validation

- [ ] All validation levels completed successfully
- [ ] `flutter analyze` shows zero issues
- [ ] All unit tests pass
- [ ] Integration tests with real hardware successful
- [ ] Optimistic updates work in both connected and demo modes

### Feature Validation

- [ ] Labels show current mode (A or R) based on Connection.replaceMode
- [ ] Hover effect changes font size from 10px to 12px on desktop
- [ ] Click reliably toggles between modes with 500ms debounce
- [ ] Background colors: Black (0.7/0.9 opacity) for Add, Blue (0.7/0.9 opacity) for Replace
- [ ] Mode changes revert on hardware update failure
- [ ] Physical I/O connections (algorithmIndex < 0) show no mode toggle
- [ ] Mobile platforms use tap without hover effects
- [ ] Initial modes loaded from parameter values (source of truth)

### Code Quality Validation

- [ ] Follows existing ConnectionPainter patterns
- [ ] Uses established optimistic update pattern from DistingCubit
- [ ] Integrates with ParameterUpdateQueue properly
- [ ] No new dependencies added unnecessarily
- [ ] Code is debugPrint-based, not print

### User Experience

- [ ] Responsive hover feedback (< 16ms)
- [ ] Immediate mode toggle on click
- [ ] Clear visual distinction between modes
- [ ] Works on all platforms (desktop hover, mobile tap)
- [ ] No UI jank or lag during updates

---

## Anti-Patterns to Avoid

- ❌ Don't rebuild entire canvas on hover - only update painter
- ❌ Don't skip optimistic updates - users expect immediate feedback
- ❌ Don't hardcode mode values - use parameter system
- ❌ Don't assume all connections have modes - check first
- ❌ Don't use print() - always use debugPrint()
- ❌ Don't ignore physical I/O special cases