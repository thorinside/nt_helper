# Technical Specification

This is the technical specification for the spec detailed in @.agent-os/specs/2025-09-01-invalid-connection-highlighting/spec.md

## Technical Requirements

### ConnectionValidator Class (New)
- Create new class `ConnectionValidator` in lib/core/routing/services/
- Stateless utility class with pure functions for connection validation
- Main method: `List<Connection> validateConnections(List<Connection> connections, List<RoutingAlgorithm> algorithms)`
- Returns new Connection objects with updated properties Map containing validation flags
- Extracts algorithm indices by matching port IDs to algorithm ports
- Sets 'isInvalidOrder' flag in properties when source index > target index
- Preserves all existing connection data and properties

### Connection Validation Logic
- Extract algorithm slot numbers from RoutingAlgorithm.index field
- For each Connection, determine source and target algorithm indices using port IDs
- Flag connections as invalid when source algorithm index > target algorithm index
- Skip validation for physical connections (ports starting with 'hw_in_' or 'hw_out_')
- Add 'isInvalidOrder' boolean to connection properties Map

### Visual Rendering in ConnectionPainter
- Extend ConnectionData class to include `isInvalidOrder` boolean field (extracted from connection.properties)
- Modify `_applyConnectionStyle` method to check isInvalidOrder flag
- Use existing `_drawDashedPath` method for invalid connections (not just ghost connections)
- Apply theme.colorScheme.error color to invalid connection paint
- Maintain existing stroke width (from ConnectionStyle)
- Use dash pattern: 8px dash, 4px gap (matching ghost connection pattern)
- Preserve existing label rendering with optional error indicator

### Minimal RoutingEditorCubit Changes
- In `_processRoutingData` method, after ConnectionDiscoveryService creates connections:
  1. Call ConnectionValidator.validateConnections(connections, algorithms)
  2. Use the returned validated connections list
- No other changes needed - existing stream subscription handles updates
- Keeps cubit focused on orchestration, not business logic

### Real-time Updates
- Leverage existing DistingCubit stream subscription in RoutingEditorCubit
- Algorithm reordering already triggers _processDistingState → _processRoutingData
- ConnectionPainter will automatically repaint when new ConnectionData is provided
- No additional listeners needed - existing architecture handles updates

### Theme and Accessibility
- Use theme.colorScheme.error for invalid connection color (already available in ConnectionPainter)
- Existing ConnectionVisualTheme can be extended if needed for invalid state
- Label text can include error indicator (modify _drawConnectionLabel method)
- Semantic labels already supported through widget tree

### Implementation Locations
- **ConnectionValidator class**: NEW file at lib/core/routing/services/connection_validator.dart
- **ConnectionData extension**: lib/ui/widgets/routing/connection_painter.dart (line 7-32)
- **Cubit integration**: lib/cubit/routing_editor_cubit.dart in _processRoutingData method (minimal change)
- **Visual rendering**: lib/ui/widgets/routing/connection_painter.dart in _applyConnectionStyle (line 225-258)
- **Dashed path rendering**: Already exists in _drawDashedPath method (line 261-283)
- **Connection widget**: lib/ui/widgets/routing/routing_editor_widget.dart extracts isInvalidOrder from properties

### Example ConnectionValidator Implementation
```dart
class ConnectionValidator {
  /// Validates connections for slot ordering violations
  static List<Connection> validateConnections(
    List<Connection> connections,
    List<RoutingAlgorithm> algorithms,
  ) {
    return connections.map((connection) {
      // Skip physical connections
      if (_isPhysicalConnection(connection)) {
        return connection;
      }
      
      // Find source and target algorithm indices
      final sourceIndex = _findAlgorithmIndex(connection.sourcePortId, algorithms);
      final targetIndex = _findAlgorithmIndex(connection.targetPortId, algorithms);
      
      // Check if invalid order
      if (sourceIndex != null && targetIndex != null && sourceIndex > targetIndex) {
        // Add validation flag to properties
        final updatedProperties = {
          ...?connection.properties,
          'isInvalidOrder': true,
          'sourceSlotIndex': sourceIndex,
          'targetSlotIndex': targetIndex,
        };
        return connection.copyWith(properties: updatedProperties);
      }
      
      return connection;
    }).toList();
  }
  
  static bool _isPhysicalConnection(Connection connection) {
    return connection.sourcePortId.startsWith('hw_') || 
           connection.targetPortId.startsWith('hw_');
  }
  
  static int? _findAlgorithmIndex(String portId, List<RoutingAlgorithm> algorithms) {
    for (final algo in algorithms) {
      if (algo.inputPorts.any((p) => p.id == portId) ||
          algo.outputPorts.any((p) => p.id == portId)) {
        return algo.index;
      }
    }
    return null;
  }
}
```