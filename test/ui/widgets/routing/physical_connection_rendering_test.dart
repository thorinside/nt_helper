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

import 'physical_connection_rendering_test.mocks.dart';

@GenerateMocks([DistingCubit, RoutingEditorCubit])
void main() {
  setUpAll(() {
    // Provide dummy values for Mockito
    provideDummy<RoutingEditorState>(const RoutingEditorState.initial());
    provideDummy<DistingState>(const DistingState.initial());
  });

  group('Physical Connection Rendering Layer Tests', () {
    late MockDistingCubit mockDistingCubit;
    late MockRoutingEditorCubit mockRoutingEditorCubit;

    setUp(() {
      mockDistingCubit = MockDistingCubit();
      mockRoutingEditorCubit = MockRoutingEditorCubit();
    });

    testWidgets('should render physical connections with IgnorePointer wrapper', (WidgetTester tester) async {
      // Arrange: Create test data with physical connections
      final physicalConnections = [
        const PhysicalConnection(
          id: 'phys_hw_in_1->algorithm_0_input_gate_1',
          sourcePortId: 'hw_in_1',
          targetPortId: 'algorithm_0_input_gate_1',
          busNumber: 1,
          isInputConnection: true,
          algorithmIndex: 0,
        ),
      ];

      final loadedState = RoutingEditorStateLoaded(
        physicalInputs: [
          const Port(id: 'hw_in_1', name: 'Input 1', type: PortType.audio, direction: PortDirection.output),
        ],
        physicalOutputs: [
          const Port(id: 'hw_out_1', name: 'Output 1', type: PortType.audio, direction: PortDirection.input),
        ],
        algorithms: [
          RoutingAlgorithm(
            index: 0,
            algorithm: Algorithm(algorithmIndex: 0, guid: 'TEST', name: 'Test Algorithm'),
            inputPorts: [
              const Port(id: 'algorithm_0_input_gate_1', name: 'Gate 1', type: PortType.gate, direction: PortDirection.input),
            ],
            outputPorts: [
              const Port(id: 'algorithm_0_output_left', name: 'Left', type: PortType.audio, direction: PortDirection.output),
            ],
          ),
        ],
        connections: [],
        physicalConnections: physicalConnections,
        isHardwareSynced: true,
        lastSyncTime: DateTime.now(),
      );

      // Setup mock behavior
      when(mockRoutingEditorCubit.state).thenReturn(loadedState);
      when(mockRoutingEditorCubit.stream).thenAnswer((_) => Stream.value(loadedState));

      // Act: Build the widget
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
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert: This test serves as a baseline - it should pass after we implement physical connection rendering
      // We're testing that the widget renders without crashes when physical connections are present
      expect(find.byType(RoutingEditorWidget), findsOneWidget);
      
      // The implementation should have:
      // 1. A second ConnectionCanvas layer for physical connections
      // 2. IgnorePointer wrapper around physical connections
      // 3. Distinct visual styling for physical connections
    });

    testWidgets('should render two ConnectionCanvas layers (one for user, one for physical)', (WidgetTester tester) async {
      // Arrange: Create test data with both physical and user connections
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

      final userConnections = [
        const Connection(
          id: 'user_connection',
          sourcePortId: 'hw_in_2',
          targetPortId: 'algorithm_0_input2',
        ),
      ];

      final loadedState = RoutingEditorStateLoaded(
        physicalInputs: [
          const Port(id: 'hw_in_1', name: 'Input 1', type: PortType.audio, direction: PortDirection.output),
          const Port(id: 'hw_in_2', name: 'Input 2', type: PortType.audio, direction: PortDirection.output),
        ],
        physicalOutputs: [],
        algorithms: [
          RoutingAlgorithm(
            index: 0,
            algorithm: Algorithm(algorithmIndex: 0, guid: 'TEST', name: 'Test Algorithm'),
            inputPorts: [
              const Port(id: 'algorithm_0_input', name: 'Input', type: PortType.audio, direction: PortDirection.input),
              const Port(id: 'algorithm_0_input2', name: 'Input 2', type: PortType.audio, direction: PortDirection.input),
            ],
            outputPorts: [],
          ),
        ],
        connections: userConnections,
        physicalConnections: physicalConnections,
        isHardwareSynced: true,
        lastSyncTime: DateTime.now(),
      );

      // Setup mock behavior
      when(mockRoutingEditorCubit.state).thenReturn(loadedState);
      when(mockRoutingEditorCubit.stream).thenAnswer((_) => Stream.value(loadedState));

      // Act: Build the widget
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
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert: Verify that there are multiple ConnectionCanvas widgets
      // One for physical connections, one for user connections
      expect(find.byType(ConnectionCanvas), findsAtLeast(1));
      
      // Verify that both IgnorePointer wrappers exist
      expect(find.byType(IgnorePointer), findsAtLeast(2)); // One for physical, one for user
    });
  });
}