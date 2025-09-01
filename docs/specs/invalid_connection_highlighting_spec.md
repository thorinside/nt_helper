# Invalid Connection Highlighting Specification

## Feature Overview
Add visual feedback for invalid algorithm-to-algorithm connections where the source algorithm has a higher slot number than the destination algorithm, indicating that the connection violates the Disting NT's processing order constraints.

## Problem Statement
The Disting NT processes algorithms in slot order (1, 2, 3, etc.). When an algorithm in a higher-numbered slot attempts to send data to an algorithm in a lower-numbered slot, the connection cannot work due to processing order constraints. Currently, users may create these invalid connections without realizing they won't function, leading to confusion and requiring manual debugging.

## Solution
Display invalid connections with a distinctive visual style (dotted red line) to immediately communicate to users that the connection won't work due to slot ordering, while still showing the connection attempt so users can understand the routing intent and correct it using the up/down reordering buttons.

## High-Level Objectives

1. **Immediate Visual Feedback**: Users instantly see when a connection violates slot ordering rules
2. **Non-Destructive Display**: Invalid connections remain visible, preserving user intent
3. **Actionable Guidance**: Visual feedback encourages users to reorder algorithms to fix the issue
4. **Consistent UX**: Integrates seamlessly with existing connection rendering system

## Mid-Level Objectives

1. **Connection Validation Logic**
   - Detect algorithm-to-algorithm connections
   - Compare source and destination slot numbers
   - Flag connections as invalid when source slot > destination slot

2. **Visual Rendering**
   - Render invalid connections with dotted/dashed line style
   - Use error color (red) from theme
   - Maintain all other connection properties (labels, routing)

3. **State Management**
   - Track connection validity in connection metadata
   - Update validity when algorithms are reordered
   - Preserve connection data even when invalid

4. **User Feedback**
   - Show tooltip/hint on hover explaining the issue
   - Maintain consistent visual language with other error states
   - Ensure visibility against various backgrounds

## Technical Specifications

### Connection Validation

```dart
class ConnectionValidator {
  static bool isValidSlotOrder(Connection connection, RoutingEditorState state) {
    // Extract algorithm IDs from port IDs
    final sourceAlgoId = extractAlgorithmId(connection.sourcePortId);
    final targetAlgoId = extractAlgorithmId(connection.targetPortId);
    
    // Get slot numbers
    final sourceSlot = getAlgorithmSlot(sourceAlgoId, state);
    final targetSlot = getAlgorithmSlot(targetAlgoId, state);
    
    // Physical connections are always valid
    if (sourceSlot == null || targetSlot == null) return true;
    
    // Check slot ordering
    return sourceSlot <= targetSlot;
  }
}
```

### Connection Rendering

```dart
class ConnectionPainter {
  void paintConnection(Canvas canvas, ConnectionData connection) {
    final paint = Paint()
      ..color = connection.isInvalidOrder 
        ? theme.errorColor 
        : getConnectionColor(connection)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    
    if (connection.isInvalidOrder) {
      // Use dotted/dashed pattern for invalid connections
      paint.pathEffect = DashPathEffect([5, 5], 0);
    }
    
    // Draw the connection path
    canvas.drawPath(connectionPath, paint);
  }
}
```

### Metadata Structure

```dart
class ConnectionMetadata {
  final bool isAlgorithmConnection;
  final int? sourceSlotNumber;
  final int? targetSlotNumber;
  final bool isInvalidOrder;
  final String? invalidReason;
}
```

## Implementation Tasks

### Phase 1: Core Validation Logic
1. **Add slot number extraction utilities**
   - Create helper functions to extract algorithm IDs from port IDs
   - Add methods to retrieve slot numbers from algorithm IDs
   - Handle edge cases (physical ports, missing algorithms)

2. **Implement connection validator**
   - Create ConnectionValidator class
   - Add isValidSlotOrder method
   - Include validation in connection creation flow

3. **Update connection metadata**
   - Add isInvalidOrder flag to ConnectionData
   - Store source/target slot numbers
   - Include validation reason for tooltips

### Phase 2: Visual Rendering
4. **Modify ConnectionPainter**
   - Add support for dashed line rendering
   - Implement error color theming
   - Ensure proper layering and visibility

5. **Add dash pattern support**
   - Implement DashPathEffect for Flutter Canvas
   - Configure appropriate dash/gap sizes
   - Ensure smooth rendering at different zoom levels

6. **Update connection themes**
   - Add invalidConnectionColor to theme
   - Define dash pattern constants
   - Ensure accessibility (sufficient contrast)

### Phase 3: State Management
7. **Update RoutingEditorCubit**
   - Add validation to connection creation
   - Track invalid connections in state
   - Update validation on algorithm reordering

8. **Handle algorithm reordering**
   - Re-validate connections when algorithms move
   - Update visual state immediately
   - Preserve connection data during transitions

### Phase 4: User Experience
9. **Add hover tooltips**
   - Show explanation on invalid connection hover
   - Include suggestion to reorder algorithms
   - Display current slot numbers

10. **Testing and refinement**
    - Test with various algorithm configurations
    - Verify visual clarity at different scales
    - Ensure performance with many connections

## Visual Design

### Invalid Connection Appearance
- **Line Style**: Dashed (5px dash, 5px gap)
- **Color**: Theme error color (typically red #F44336)
- **Width**: Same as valid connections (2px)
- **Opacity**: Full opacity (no transparency)
- **Labels**: Maintained but possibly with error indicator

### Hover State
- **Tooltip Content**: "Invalid connection: Algorithm in slot {source} cannot connect to slot {target}. Use up/down buttons to reorder."
- **Tooltip Style**: Error background with white text
- **Cursor**: Pointer with error indicator

## Edge Cases and Considerations

1. **Physical Connections**: Never marked as invalid (no slot ordering applies)
2. **Self-Connections**: Handle algorithms connecting to themselves
3. **Multi-hop Connections**: Consider transitive dependencies
4. **Performance**: Optimize validation for large numbers of connections
5. **Accessibility**: Ensure error state is communicated to screen readers
6. **Theme Support**: Work with both light and dark themes
7. **Animation**: Consider subtle pulse animation for invalid connections

## Success Criteria

1. Invalid connections are immediately visible as red dotted lines
2. Users understand why connections are invalid through visual feedback
3. Performance impact is negligible (<1ms per connection validation)
4. Feature works consistently across all platforms
5. Invalid connections update correctly when algorithms are reordered
6. No regression in existing connection functionality

## Testing Strategy

### Unit Tests
- Connection validation logic with various slot configurations
- Metadata generation and updates
- Edge case handling (physical ports, missing algorithms)

### Widget Tests
- ConnectionPainter rendering with invalid connections
- Hover tooltip display and content
- Theme integration and color application

### Integration Tests
- End-to-end connection creation and validation
- Algorithm reordering with connection updates
- Performance with 50+ connections

### Manual Testing
- Visual clarity at different zoom levels
- Color contrast in light/dark themes
- Tooltip behavior and positioning
- Interaction with drag operations

## Documentation Updates

1. Update user guide with slot ordering explanation
2. Add troubleshooting section for invalid connections
3. Include visual examples in documentation
4. Update API documentation for new validation methods

## Migration and Rollout

1. Feature flag for gradual rollout (if needed)
2. No data migration required (computed at runtime)
3. Backward compatible with existing saved presets
4. Can be disabled via settings if needed

## Future Enhancements

1. **Auto-fix suggestions**: Offer to automatically reorder algorithms
2. **Connection preview**: Show validity before completing connection
3. **Batch validation**: Validate all connections with single action
4. **Smart routing**: Automatically avoid invalid configurations
5. **Warning levels**: Different styles for warnings vs errors