# Test Specification

## Unit Tests

### AlgorithmConnection Data Model Tests

**File**: @test/models/algorithm_connection_test.dart

```dart
group('AlgorithmConnection', () {
  test('violatesExecutionOrder returns true when source >= target', () {
    final connection = AlgorithmConnection(
      id: 'test',
      sourceAlgorithmIndex: 2,
      targetAlgorithmIndex: 1,
      // ... other fields
    );
    expect(connection.violatesExecutionOrder, isTrue);
  });
  
  test('generateId creates deterministic ID', () {
    final id1 = AlgorithmConnectionHelpers.generateId(0, 'out1', 1, 'in1', 5);
    final id2 = AlgorithmConnectionHelpers.generateId(0, 'out1', 1, 'in1', 5);
    expect(id1, equals(id2));
  });
  
  test('busTypeLabel returns correct labels', () {
    final inputConnection = AlgorithmConnection(busNumber: 5, /* ... */);
    final outputConnection = AlgorithmConnection(busNumber: 15, /* ... */);
    final auxConnection = AlgorithmConnection(busNumber: 25, /* ... */);
    
    expect(inputConnection.busTypeLabel, equals('Input'));
    expect(outputConnection.busTypeLabel, equals('Output'));  
    expect(auxConnection.busTypeLabel, equals('Aux'));
  });
});
```

### AlgorithmConnectionService Tests  

**File**: @test/core/routing/services/algorithm_connection_service_test.dart

```dart
group('AlgorithmConnectionService', () {
  late AlgorithmConnectionService service;
  late RoutingFactory mockRoutingFactory;
  
  setUp(() {
    mockRoutingFactory = MockRoutingFactory();
    service = AlgorithmConnectionService(mockRoutingFactory);
  });
  
  test('discoverAlgorithmConnections finds matching bus connections', () {
    final slots = _createTestSlots();
    when(mockRoutingFactory.createRouting(any))
        .thenReturn(_createMockRouting());
    
    final connections = service.discoverAlgorithmConnections(slots);
    
    expect(connections, hasLength(2)); // Expected connections
    expect(connections.first.busNumber, equals(5));
    expect(connections.first.sourceAlgorithmIndex, equals(0));
    expect(connections.first.targetAlgorithmIndex, equals(1));
  });
  
  test('connections are sorted deterministically', () {
    final slots = _createMultipleConnectionSlots();
    
    final connections1 = service.discoverAlgorithmConnections(slots);
    final connections2 = service.discoverAlgorithmConnections(slots);
    
    expect(connections1.map((c) => c.id), equals(connections2.map((c) => c.id)));
  });
  
  test('invalid connections are marked correctly', () {
    final slots = _createInvalidOrderSlots(); // Source slot > target slot
    
    final connections = service.discoverAlgorithmConnections(slots);
    
    expect(connections.first.isValid, isFalse);
    expect(connections.first.violatesExecutionOrder, isTrue);
  });
  
  test('self-connections are excluded', () {
    final slots = _createSelfConnectionSlots();
    
    final connections = service.discoverAlgorithmConnections(slots);
    
    expect(connections.every((c) => 
        c.sourceAlgorithmIndex != c.targetAlgorithmIndex), isTrue);
  });
  
  test('handles empty slots gracefully', () {
    final connections = service.discoverAlgorithmConnections([]);
    expect(connections, isEmpty);
  });
  
  test('handles slots with no bus assignments', () {
    final slots = _createSlotsWithoutBuses();
    
    final connections = service.discoverAlgorithmConnections(slots);
    
    expect(connections, isEmpty);
  });
});
```

### Bus Resolution Tests

**File**: @test/core/routing/bus_resolution_test.dart

```dart
group('Bus Resolution', () {
  test('resolves bus from busParam metadata', () {
    final port = Port(
      id: 'test_port',
      metadata: {'busParam': 'Audio Output'},
    );
    final slot = _createSlotWithParameter('Audio Output', 15);
    
    final busNumber = _getBusNumberForPort(port, slot);
    
    expect(busNumber, equals(15));
  });
  
  test('falls back to polyphonic gate logic', () {
    final port = Port(
      id: 'poly_gate_in_1',
      metadata: {'isGateInput': true, 'gateBus': 9},
    );
    final slot = _createPolySlot();
    
    final busNumber = _getBusNumberForPort(port, slot);
    
    expect(busNumber, equals(9));
  });
  
  test('returns null for bus 0 (None)', () {
    final port = Port(
      metadata: {'busParam': 'Output Bus'},
    );
    final slot = _createSlotWithParameter('Output Bus', 0);
    
    final busNumber = _getBusNumberForPort(port, slot);
    
    expect(busNumber, isNull);
  });
  
  test('returns null for invalid bus range', () {
    final port = Port(
      metadata: {'busParam': 'Invalid Bus'},
    );
    final slot = _createSlotWithParameter('Invalid Bus', 25);
    
    final busNumber = _getBusNumberForPort(port, slot);
    
    expect(busNumber, isNull);
  });
});
```

## Integration Tests

### RoutingEditorCubit Integration

**File**: @test/cubit/routing_editor_cubit_integration_test.dart

```dart
group('RoutingEditorCubit Algorithm Connections', () {
  late RoutingEditorCubit cubit;
  late MockDistingCubit mockDistingCubit;
  
  setUp(() {
    mockDistingCubit = MockDistingCubit();
    cubit = RoutingEditorCubit(mockDistingCubit);
  });
  
  testWidgets('algorithm connections update when slots change', (tester) async {
    // Setup initial state
    final initialSlots = _createTestSlots();
    _emitSynchronizedState(mockDistingCubit, initialSlots);
    
    await tester.pump();
    
    final initialState = cubit.state as RoutingEditorStateLoaded;
    expect(initialState.algorithmConnections, hasLength(1));
    
    // Change slot parameters to create new connections
    final updatedSlots = _createUpdatedTestSlots();
    _emitSynchronizedState(mockDistingCubit, updatedSlots);
    
    await tester.pump();
    
    final updatedState = cubit.state as RoutingEditorStateLoaded;
    expect(updatedState.algorithmConnections, hasLength(2));
  });
  
  testWidgets('handles algorithm connection service errors', (tester) async {
    when(mockAlgorithmConnectionService.discoverAlgorithmConnections(any))
        .thenThrow(Exception('Discovery failed'));
    
    _emitSynchronizedState(mockDistingCubit, _createTestSlots());
    
    await tester.pump();
    
    expect(cubit.state, isA<RoutingEditorStateError>());
  });
});
```

### End-to-End Workflow Tests

**File**: @test/integration/algorithm_connections_e2e_test.dart

```dart
group('Algorithm Connections End-to-End', () {
  testWidgets('complete workflow from preset load to visualization', (tester) async {
    // Load a preset with algorithm connections
    await tester.pumpWidget(_createTestApp());
    
    // Simulate loading preset with connected algorithms
    final preset = _createPresetWithAlgorithmConnections();
    await _loadPreset(tester, preset);
    
    // Verify connections are discovered
    final routingEditor = find.byType(RoutingEditorWidget);
    expect(routingEditor, findsOneWidget);
    
    // Verify connections are rendered
    final canvas = find.byType(RoutingCanvas);
    expect(canvas, findsOneWidget);
    
    // Check that algorithm connections are painted
    await expectLater(
      canvas,
      matchesGoldenFile('algorithm_connections_rendered.png'),
    );
  });
  
  testWidgets('invalid connections shown in red', (tester) async {
    await tester.pumpWidget(_createTestApp());
    
    // Load preset with invalid execution order
    final preset = _createInvalidExecutionOrderPreset();
    await _loadPreset(tester, preset);
    
    // Verify invalid connection styling
    await expectLater(
      find.byType(RoutingCanvas),
      matchesGoldenFile('invalid_connections_red.png'),
    );
  });
  
  testWidgets('connections update when parameters change', (tester) async {
    await tester.pumpWidget(_createTestApp());
    
    // Initial state
    await _loadPreset(tester, _createPresetWithConnections());
    await tester.pump();
    
    // Change algorithm parameter to create new connection
    await _changeAlgorithmParameter(tester, slotIndex: 1, paramName: 'Audio Output', value: 15);
    await tester.pump();
    
    // Verify new connection appears
    await expectLater(
      find.byType(RoutingCanvas), 
      matchesGoldenFile('updated_connections.png'),
    );
  });
});
```

## Visual Regression Tests

### Connection Rendering Tests

**File**: @test/ui/routing_canvas_visual_test.dart

```dart
group('RoutingCanvas Visual Tests', () {
  testWidgets('renders valid algorithm connections correctly', (tester) async {
    final state = _createStateWithValidConnections();
    
    await tester.pumpWidget(
      MaterialApp(
        home: RoutingCanvas(state: state),
      ),
    );
    
    await expectLater(
      find.byType(RoutingCanvas),
      matchesGoldenFile('valid_algorithm_connections.png'),
    );
  });
  
  testWidgets('renders invalid connections in red with dashed lines', (tester) async {
    final state = _createStateWithInvalidConnections();
    
    await tester.pumpWidget(
      MaterialApp(
        home: RoutingCanvas(state: state),
      ),
    );
    
    await expectLater(
      find.byType(RoutingCanvas),
      matchesGoldenFile('invalid_algorithm_connections.png'),
    );
  });
  
  testWidgets('color follows source output port type', (tester) async {
    final state = _createStateWithConnectionsFromDifferentOutputPorts();
    
    await tester.pumpWidget(
      MaterialApp(
        home: RoutingCanvas(state: state),
      ),
    );
    
    await expectLater(
      find.byType(RoutingCanvas),
      matchesGoldenFile('output_port_type_color_consistency.png'),
    );
  });
  
  testWidgets('connection labels positioned correctly', (tester) async {
    final state = _createStateWithLabeledConnections();
    
    await tester.pumpWidget(
      MaterialApp(
        home: RoutingCanvas(state: state),
      ),
    );
    
    await expectLater(
      find.byType(RoutingCanvas),
      matchesGoldenFile('connection_labels.png'),
    );
  });
});
```

## Performance Tests

### Connection Discovery Performance (Optional)

**File**: @test/performance/algorithm_connections_performance_test.dart

```dart
group('Algorithm Connections Performance', () {
  test('discovery scales with slot count', () {
    final stopwatch = Stopwatch()..start();
    
    // Test with maximum slot configuration
    final slots = _createMaximumSlots(8);
    final service = AlgorithmConnectionService(RoutingFactory());
    
    final connections = service.discoverAlgorithmConnections(slots);
    
    stopwatch.stop();
    
    // Should complete within reasonable time on typical dev hardware
    expect(connections, isNotEmpty);
  });
  
  test('rendering performance with many connections', () {
    final state = _createStateWithManyConnections(100);
    
    final stopwatch = Stopwatch()..start();
    
    // Simulate canvas painting
    final canvas = MockCanvas();
    _paintAllAlgorithmConnections(canvas, state.algorithmConnections);
    
    stopwatch.stop();
    
    // Should render smoothly under typical conditions
    expect(connections.length, equals(100));
  });
  
  test('connection caching effectiveness', () {
    final slots = _createTestSlots();
    final cache = _ConnectionCache();
    final service = AlgorithmConnectionService(RoutingFactory());
    
    // First call - should hit service
    final stopwatch1 = Stopwatch()..start();
    final connections1 = cache.getConnections(slots, service);
    stopwatch1.stop();
    
    // Second call with same slots - should hit cache
    final stopwatch2 = Stopwatch()..start();  
    final connections2 = cache.getConnections(slots, service);
    stopwatch2.stop();
    
    expect(connections1, equals(connections2));
    expect(connections1, equals(connections2));
  });
});
```

## Test Utilities

### Mock Data Creation

**File**: @test/test_utils/algorithm_connection_test_utils.dart

```dart
class AlgorithmConnectionTestUtils {
  static List<Slot> createTestSlots() {
    return [
      Slot(
        algorithm: Algorithm(name: 'Source Algo'),
        parameters: [
          ParameterInfo(name: 'Audio Output', parameterNumber: 1, defaultValue: 0),
        ],
        values: [
          ParameterValue(parameterNumber: 1, value: 15), // Bus 15
        ],
      ),
      Slot(
        algorithm: Algorithm(name: 'Target Algo'),  
        parameters: [
          ParameterInfo(name: 'Audio Input', parameterNumber: 1, defaultValue: 0),
        ],
        values: [
          ParameterValue(parameterNumber: 1, value: 15), // Same bus 15
        ],
      ),
    ];
  }
  
  static RoutingEditorStateLoaded createStateWithAlgorithmConnections() {
    return RoutingEditorStateLoaded(
      algorithmConnections: [
        AlgorithmConnection(
          id: 'test_connection_1',
          sourceAlgorithmIndex: 0,
          sourcePortId: 'out_1',
          targetAlgorithmIndex: 1,
          targetPortId: 'in_1',
          busNumber: 15,
          isValid: true,
          createdAt: DateTime.now(),
        ),
      ],
      // ... other required fields
    );
  }
  
  // Additional utility methods...
}
```

## Test Coverage Goals

- **Unit Tests**: >95% code coverage for new components
- **Integration Tests**: All major user workflows covered
- **Visual Tests**: Key UI states with golden file comparisons
- **Performance Tests**: Scalability validation with realistic data sets

## Continuous Integration

### Automated Test Execution

```yaml
# .github/workflows/algorithm_connections_tests.yml
name: Algorithm Connections Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: subosito/flutter-action@v2
      
      - name: Run Algorithm Connection Unit Tests
        run: flutter test test/models/algorithm_connection_test.dart
        
      - name: Run Service Tests  
        run: flutter test test/core/routing/services/
        
      - name: Run Integration Tests
        run: flutter test test/cubit/routing_editor_cubit_integration_test.dart
        
      - name: Run Visual Tests
        run: flutter test --update-goldens test/ui/routing_canvas_visual_test.dart
        
      - name: Run Performance Tests
        run: flutter test test/performance/
```

This comprehensive test specification ensures thorough validation of the algorithm connections feature across all layers of the application.
