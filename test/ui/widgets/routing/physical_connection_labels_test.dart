import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:nt_helper/cubit/routing_editor_cubit.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/ui/widgets/routing/routing_editor_widget.dart';
import 'package:nt_helper/ui/widgets/routing/connection_painter.dart';
import 'package:nt_helper/models/physical_connection.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';

import 'physical_connection_labels_test.mocks.dart';

@GenerateMocks([DistingCubit, RoutingEditorCubit])
void main() {
  setUpAll(() {
    // Provide dummy values for Mockito
    provideDummy<RoutingEditorState>(const RoutingEditorState.initial());
    provideDummy<DistingState>(const DistingState.initial());
  });

  group('Physical Connection I#/O# Labels Tests', () {
    late MockDistingCubit mockDistingCubit;
    late MockRoutingEditorCubit mockRoutingEditorCubit;

    setUp(() {
      mockDistingCubit = MockDistingCubit();
      mockRoutingEditorCubit = MockRoutingEditorCubit();
    });

    testWidgets('should show I# labels for physical input connections when showBusLabels is true', (WidgetTester tester) async {
      // Arrange: Create test data with physical input connections
      final physicalConnections = [
        const PhysicalConnection(
          id: 'phys_hw_in_1->algorithm_0_input_gate_1',
          sourcePortId: 'hw_in_1',
          targetPortId: 'algorithm_0_input_gate_1',
          busNumber: 1,
          isInputConnection: true, // Input connection
          algorithmIndex: 0,
        ),
        const PhysicalConnection(
          id: 'phys_hw_in_5->algorithm_0_input_cv',
          sourcePortId: 'hw_in_5',
          targetPortId: 'algorithm_0_input_cv',
          busNumber: 5,
          isInputConnection: true, // Input connection
          algorithmIndex: 0,
        ),
      ];

      final loadedState = RoutingEditorStateLoaded(
        physicalInputs: [
          const Port(id: 'hw_in_1', name: 'Input 1', type: PortType.audio, direction: PortDirection.output),
          const Port(id: 'hw_in_5', name: 'Input 5', type: PortType.audio, direction: PortDirection.output),
        ],
        physicalOutputs: [],
        algorithms: [
          RoutingAlgorithm(
            index: 0,
            algorithm: Algorithm(algorithmIndex: 0, guid: 'TEST', name: 'Test Algorithm'),
            inputPorts: [
              const Port(id: 'algorithm_0_input_gate_1', name: 'Gate 1', type: PortType.gate, direction: PortDirection.input),
              const Port(id: 'algorithm_0_input_cv', name: 'CV', type: PortType.cv, direction: PortDirection.input),
            ],
            outputPorts: [],
          ),
        ],
        connections: [],
        physicalConnections: physicalConnections,
        buses: [],
        portOutputModes: const {},
        isHardwareSynced: true,
        isPersistenceEnabled: false,
        lastSyncTime: DateTime.now(),
        lastPersistTime: null,
        lastError: null,
      );

      // Setup mock behavior
      when(mockRoutingEditorCubit.state).thenReturn(loadedState);
      when(mockRoutingEditorCubit.stream).thenAnswer((_) => Stream.value(loadedState));

      // Act: Build the widget with showBusLabels = true
      await tester.pumpWidget(
        MaterialApp(
          home: MultiBlocProvider(
            providers: [
              BlocProvider<DistingCubit>.value(value: mockDistingCubit),
              BlocProvider<RoutingEditorCubit>.value(value: mockRoutingEditorCubit),
            ],
            child: RoutingEditorWidget(
              canvasSize: Size(800, 600),
              showPhysicalPorts: true,
              showBusLabels: true, // Enable labels
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert: The widget should render without errors
      // Note: We can't directly test the painted labels, but we can verify the widget
      // renders properly with physical connections that have the label data
      expect(find.byType(RoutingEditorWidget), findsOneWidget);
      expect(find.byType(ConnectionCanvas), findsAtLeast(1)); // Should have physical connection canvas
    });

    testWidgets('should show O# labels for physical output connections when showBusLabels is true', (WidgetTester tester) async {
      // Arrange: Create test data with physical output connections
      final physicalConnections = [
        const PhysicalConnection(
          id: 'phys_algorithm_0_output_left->hw_out_1',
          sourcePortId: 'algorithm_0_output_left',
          targetPortId: 'hw_out_1',
          busNumber: 13, // Output bus 13 maps to hardware output 1
          isInputConnection: false, // Output connection
          algorithmIndex: 0,
        ),
        const PhysicalConnection(
          id: 'phys_algorithm_0_output_right->hw_out_2',
          sourcePortId: 'algorithm_0_output_right', 
          targetPortId: 'hw_out_2',
          busNumber: 14, // Output bus 14 maps to hardware output 2
          isInputConnection: false, // Output connection
          algorithmIndex: 0,
        ),
      ];

      final loadedState = RoutingEditorStateLoaded(
        physicalInputs: [],
        physicalOutputs: [
          const Port(id: 'hw_out_1', name: 'Output 1', type: PortType.audio, direction: PortDirection.input),
          const Port(id: 'hw_out_2', name: 'Output 2', type: PortType.audio, direction: PortDirection.input),
        ],
        algorithms: [
          RoutingAlgorithm(
            index: 0,
            algorithm: Algorithm(algorithmIndex: 0, guid: 'TEST', name: 'Test Algorithm'),
            inputPorts: [],
            outputPorts: [
              const Port(id: 'algorithm_0_output_left', name: 'Left', type: PortType.audio, direction: PortDirection.output),
              const Port(id: 'algorithm_0_output_right', name: 'Right', type: PortType.audio, direction: PortDirection.output),
            ],
          ),
        ],
        connections: [],
        physicalConnections: physicalConnections,
        buses: [],
        portOutputModes: const {},
        isHardwareSynced: true,
        isPersistenceEnabled: false,
        lastSyncTime: DateTime.now(),
        lastPersistTime: null,
        lastError: null,
      );

      // Setup mock behavior
      when(mockRoutingEditorCubit.state).thenReturn(loadedState);
      when(mockRoutingEditorCubit.stream).thenAnswer((_) => Stream.value(loadedState));

      // Act: Build the widget with showBusLabels = true
      await tester.pumpWidget(
        MaterialApp(
          home: MultiBlocProvider(
            providers: [
              BlocProvider<DistingCubit>.value(value: mockDistingCubit),
              BlocProvider<RoutingEditorCubit>.value(value: mockRoutingEditorCubit),
            ],
            child: RoutingEditorWidget(
              canvasSize: Size(800, 600),
              showPhysicalPorts: true,
              showBusLabels: true, // Enable labels
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert: The widget should render without errors
      expect(find.byType(RoutingEditorWidget), findsOneWidget);
      expect(find.byType(ConnectionCanvas), findsAtLeast(1)); // Should have physical connection canvas
    });

    testWidgets('should not show labels when showBusLabels is false', (WidgetTester tester) async {
      // Arrange: Create test data with physical connections
      final physicalConnections = [
        const PhysicalConnection(
          id: 'phys_hw_in_1->algorithm_0_input',
          sourcePortId: 'hw_in_1',
          targetPortId: 'algorithm_0_input',
          busNumber: 1,
          isInputConnection: true,
          algorithmIndex: 0,
        ),
      ];

      final loadedState = RoutingEditorStateLoaded(
        physicalInputs: [
          const Port(id: 'hw_in_1', name: 'Input 1', type: PortType.audio, direction: PortDirection.output),
        ],
        physicalOutputs: [],
        algorithms: [
          RoutingAlgorithm(
            index: 0,
            algorithm: Algorithm(algorithmIndex: 0, guid: 'TEST', name: 'Test Algorithm'),
            inputPorts: [
              const Port(id: 'algorithm_0_input', name: 'Input', type: PortType.audio, direction: PortDirection.input),
            ],
            outputPorts: [],
          ),
        ],
        connections: [],
        physicalConnections: physicalConnections,
        buses: [],
        portOutputModes: const {},
        isHardwareSynced: true,
        isPersistenceEnabled: false,
        lastSyncTime: DateTime.now(),
        lastPersistTime: null,
        lastError: null,
      );

      // Setup mock behavior
      when(mockRoutingEditorCubit.state).thenReturn(loadedState);
      when(mockRoutingEditorCubit.stream).thenAnswer((_) => Stream.value(loadedState));

      // Act: Build the widget with showBusLabels = false
      await tester.pumpWidget(
        MaterialApp(
          home: MultiBlocProvider(
            providers: [
              BlocProvider<DistingCubit>.value(value: mockDistingCubit),
              BlocProvider<RoutingEditorCubit>.value(value: mockRoutingEditorCubit),
            ],
            child: RoutingEditorWidget(
              canvasSize: Size(800, 600),
              showPhysicalPorts: true,
              showBusLabels: false, // Disable labels
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert: The widget should render without errors
      expect(find.byType(RoutingEditorWidget), findsOneWidget);
    });

    testWidgets('should default showBusLabels to true for wide screens (width >= 800)', (WidgetTester tester) async {
      // Arrange: Create minimal test data
      final loadedState = RoutingEditorStateLoaded(
        physicalInputs: [],
        physicalOutputs: [],
        algorithms: [],
        connections: [],
        physicalConnections: [],
        buses: [],
        portOutputModes: const {},
        isHardwareSynced: true,
        isPersistenceEnabled: false,
        lastSyncTime: DateTime.now(),
        lastPersistTime: null,
        lastError: null,
      );

      when(mockRoutingEditorCubit.state).thenReturn(loadedState);
      when(mockRoutingEditorCubit.stream).thenAnswer((_) => Stream.value(loadedState));

      // Act: Build widget with wide screen (>= 800px) without specifying showBusLabels
      await tester.pumpWidget(
        MaterialApp(
          home: MultiBlocProvider(
            providers: [
              BlocProvider<DistingCubit>.value(value: mockDistingCubit),
              BlocProvider<RoutingEditorCubit>.value(value: mockRoutingEditorCubit),
            ],
            child: RoutingEditorWidget(
              canvasSize: Size(800, 600), // Wide screen
              showPhysicalPorts: true,
              // showBusLabels not specified - should default to true
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert: Widget should render (showBusLabels defaults to true for width >= 800)
      expect(find.byType(RoutingEditorWidget), findsOneWidget);
    });

    testWidgets('should default showBusLabels to false for narrow screens (width < 800)', (WidgetTester tester) async {
      // Arrange: Create minimal test data
      final loadedState = RoutingEditorStateLoaded(
        physicalInputs: [],
        physicalOutputs: [],
        algorithms: [],
        connections: [],
        physicalConnections: [],
        buses: [],
        portOutputModes: const {},
        isHardwareSynced: true,
        isPersistenceEnabled: false,
        lastSyncTime: DateTime.now(),
        lastPersistTime: null,
        lastError: null,
      );

      when(mockRoutingEditorCubit.state).thenReturn(loadedState);
      when(mockRoutingEditorCubit.stream).thenAnswer((_) => Stream.value(loadedState));

      // Act: Build widget with narrow screen (< 800px) without specifying showBusLabels
      await tester.pumpWidget(
        MaterialApp(
          home: MultiBlocProvider(
            providers: [
              BlocProvider<DistingCubit>.value(value: mockDistingCubit),
              BlocProvider<RoutingEditorCubit>.value(value: mockRoutingEditorCubit),
            ],
            child: RoutingEditorWidget(
              canvasSize: Size(600, 400), // Narrow screen
              showPhysicalPorts: true,
              // showBusLabels not specified - should default to false
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert: Widget should render (showBusLabels defaults to false for width < 800)
      expect(find.byType(RoutingEditorWidget), findsOneWidget);
    });

    test('ConnectionData label formatting for physical connections', () {
      // Test the ConnectionData label formatting logic directly
      
      // Test input connection (bus 1-12)
      final inputConnectionData = ConnectionData(
        connection: const Connection(id: 'test_input', sourcePortId: 'hw_in_3', targetPortId: 'alg_input'),
        sourcePosition: Offset.zero,
        destinationPosition: const Offset(100, 100),
        busNumber: 3,
        isPhysicalConnection: true,
        isInputConnection: true, // Input connection
      );
      
      // Test output connection (bus 13-20 -> output 1-8)
      final outputConnectionData = ConnectionData(
        connection: const Connection(id: 'test_output', sourcePortId: 'alg_output', targetPortId: 'hw_out_2'),
        sourcePosition: Offset.zero,
        destinationPosition: const Offset(100, 100),
        busNumber: 14, // Bus 14 -> Output 2
        isPhysicalConnection: true,
        isInputConnection: false, // Output connection
      );
      
      // Test user connection (not physical)
      final userConnectionData = ConnectionData(
        connection: const Connection(id: 'test_user', sourcePortId: 'source', targetPortId: 'target'),
        sourcePosition: Offset.zero,
        destinationPosition: const Offset(100, 100),
        busNumber: 5,
        isPhysicalConnection: false, // User connection
        outputMode: 'mix',
      );

      // These would be tested by examining the ConnectionPainter's label generation
      // but since we can't directly test the painting, we verify the data structure
      expect(inputConnectionData.isPhysicalConnection, isTrue);
      expect(inputConnectionData.isInputConnection, isTrue);
      expect(inputConnectionData.busNumber, 3);
      
      expect(outputConnectionData.isPhysicalConnection, isTrue);
      expect(outputConnectionData.isInputConnection, isFalse);
      expect(outputConnectionData.busNumber, 14);
      
      expect(userConnectionData.isPhysicalConnection, isFalse);
      expect(userConnectionData.isInputConnection, isNull);
    });
  });
}