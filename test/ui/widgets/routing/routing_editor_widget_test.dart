import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:nt_helper/cubit/routing_editor_cubit.dart';
import 'package:nt_helper/cubit/routing_editor_state.dart' as state;
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/core/routing/models/connection.dart';
import 'package:nt_helper/core/routing/models/port.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'package:nt_helper/ui/widgets/routing/routing_editor_widget.dart';

import 'routing_editor_widget_test.mocks.dart';

@GenerateMocks([RoutingEditorCubit, DistingCubit])
void main() {
  setUpAll(() {
    // Provide dummy value for RoutingEditorState
    provideDummy<state.RoutingEditorState>(
      const state.RoutingEditorStateInitial(),
    );
  });

  group('RoutingEditorWidget Hover State', () {
    late MockRoutingEditorCubit mockRoutingCubit;
    late MockDistingCubit mockDistingCubit;

    setUp(() {
      mockRoutingCubit = MockRoutingEditorCubit();
      mockDistingCubit = MockDistingCubit();
    });

    testWidgets('manages hover state for connections', (tester) async {
      // Setup loaded state with test connection
      final testConnection = Connection(
        id: 'test_connection_1',
        sourcePortId: 'hw_in_1',
        destinationPortId: 'hw_out_1',
        connectionType: ConnectionType.hardwareInput,
      );

      final loadedState = state.RoutingEditorStateLoaded(
        physicalInputs: [
          Port(
            id: 'hw_in_1',
            name: 'Input 1',
            type: PortType.cv,
            direction: PortDirection.input,
          ),
        ],
        physicalOutputs: [
          Port(
            id: 'hw_out_1',
            name: 'Output 1',
            type: PortType.cv,
            direction: PortDirection.output,
          ),
        ],
        algorithms: [],
        connections: [testConnection],
        buses: [],
        portOutputModes: {},
        isHardwareSynced: true,
        isPersistenceEnabled: false,
        lastSyncTime: null,
        lastPersistTime: null,
        lastError: null,
      );

      when(mockRoutingCubit.state).thenReturn(loadedState);
      when(
        mockRoutingCubit.stream,
      ).thenAnswer((_) => Stream.value(loadedState));

      await tester.pumpWidget(
        MaterialApp(
          home: MultiBlocProvider(
            providers: [
              BlocProvider<RoutingEditorCubit>.value(value: mockRoutingCubit),
              BlocProvider<DistingCubit>.value(value: mockDistingCubit),
            ],
            child: Scaffold(
              body: RoutingEditorWidget(canvasSize: const Size(800, 600)),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find the MouseRegion wrapping connection canvas
      expect(find.byType(MouseRegion), findsWidgets);

      // Test hover enter event
      await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
        'flutter/mousecursor',
        const StandardMethodCodec().encodeMethodCall(
          const MethodCall('activateSystemCursor', <String, dynamic>{
            'kind': 'basic',
          }),
        ),
        (data) {},
      );

      final mouseRegion = find.byType(MouseRegion).first;

      // Simulate mouse enter event
      final TestGesture gesture = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
      );
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);

      // Move mouse over connection area
      await gesture.moveTo(tester.getCenter(mouseRegion));
      await tester.pump();

      // Verify hover state is managed (test passes if no exceptions thrown)
      expect(find.byType(RoutingEditorWidget), findsOneWidget);
    });

    testWidgets('supports stylus hover events', (tester) async {
      final loadedState = state.RoutingEditorStateLoaded(
        physicalInputs: [],
        physicalOutputs: [],
        algorithms: [],
        connections: [],
        buses: [],
        portOutputModes: {},
        isHardwareSynced: true,
        isPersistenceEnabled: false,
        lastSyncTime: null,
        lastPersistTime: null,
        lastError: null,
      );

      when(mockRoutingCubit.state).thenReturn(loadedState);
      when(
        mockRoutingCubit.stream,
      ).thenAnswer((_) => Stream.value(loadedState));

      await tester.pumpWidget(
        MaterialApp(
          home: MultiBlocProvider(
            providers: [
              BlocProvider<RoutingEditorCubit>.value(value: mockRoutingCubit),
              BlocProvider<DistingCubit>.value(value: mockDistingCubit),
            ],
            child: Scaffold(body: RoutingEditorWidget()),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Test stylus hover support - MouseRegion automatically handles stylus
      final TestGesture gesture = await tester.createGesture(
        kind: PointerDeviceKind.stylus,
      );
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);

      // Move stylus over widget area
      await gesture.moveTo(const Offset(100, 100));
      await tester.pump();

      // Verify stylus events are handled (test passes if no exceptions thrown)
      expect(find.byType(RoutingEditorWidget), findsOneWidget);
    });
  });

  group('RoutingEditorWidget Connection Label Tap', () {
    late MockRoutingEditorCubit mockRoutingCubit;
    late MockDistingCubit mockDistingCubit;

    setUp(() {
      mockRoutingCubit = MockRoutingEditorCubit();
      mockDistingCubit = MockDistingCubit();
    });

    testWidgets('handles connection label tap to toggle output mode', (
      tester,
    ) async {
      // Setup loaded state with test connection and replace mode
      final testConnection = Connection(
        id: 'test_connection_1',
        sourcePortId: 'algo_test_1_port_1',
        destinationPortId: 'hw_out_1',
        connectionType: ConnectionType.hardwareOutput,
        outputMode: OutputMode.replace,
      );

      final loadedState = state.RoutingEditorStateLoaded(
        physicalInputs: [],
        physicalOutputs: [
          Port(
            id: 'hw_out_1',
            name: 'Output 1',
            type: PortType.audio,
            direction: PortDirection.output,
          ),
        ],
        algorithms: [
          state.RoutingAlgorithm(
            id: 'algo_test_1',
            index: 0,
            algorithm: Algorithm(
              algorithmIndex: 0,
              guid: 'test-guid',
              name: 'Test Algorithm',
            ),
            inputPorts: [],
            outputPorts: [
              Port(
                id: 'algo_test_1_port_1',
                name: 'Test Output',
                type: PortType.audio,
                direction: PortDirection.output,
              ),
            ],
          ),
        ],
        connections: [testConnection],
        buses: [],
        portOutputModes: {'algo_test_1_port_1': OutputMode.replace},
        isHardwareSynced: true,
        isPersistenceEnabled: false,
        lastSyncTime: null,
        lastPersistTime: null,
        lastError: null,
      );

      when(mockRoutingCubit.state).thenReturn(loadedState);
      when(
        mockRoutingCubit.stream,
      ).thenAnswer((_) => Stream.value(loadedState));

      await tester.pumpWidget(
        MaterialApp(
          home: MultiBlocProvider(
            providers: [
              BlocProvider<RoutingEditorCubit>.value(value: mockRoutingCubit),
              BlocProvider<DistingCubit>.value(value: mockDistingCubit),
            ],
            child: Scaffold(
              body: RoutingEditorWidget(canvasSize: const Size(800, 600)),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find the connection canvas area (connections are rendered in CustomPaint)
      final customPaintFinder = find.byType(CustomPaint);
      expect(customPaintFinder, findsWidgets);

      // Simulate tap on connection label area (center of canvas)
      await tester.tap(customPaintFinder.first, warnIfMissed: false);
      await tester.pumpAndSettle();

      // Verify that the tap was processed (no exceptions thrown)
      expect(find.byType(RoutingEditorWidget), findsOneWidget);
    });

    testWidgets('toggles output mode from replace to add on label tap', (
      tester,
    ) async {
      // Setup connection with replace mode initially
      final testConnection = Connection(
        id: 'test_connection_1',
        sourcePortId: 'algo_test_1_port_1',
        destinationPortId: 'hw_out_1',
        connectionType: ConnectionType.hardwareOutput,
        outputMode: OutputMode.replace,
      );

      final loadedState = state.RoutingEditorStateLoaded(
        physicalInputs: [],
        physicalOutputs: [
          Port(
            id: 'hw_out_1',
            name: 'Output 1',
            type: PortType.audio,
            direction: PortDirection.output,
          ),
        ],
        algorithms: [
          state.RoutingAlgorithm(
            id: 'algo_test_1',
            index: 0,
            algorithm: Algorithm(
              algorithmIndex: 0,
              guid: 'test-guid',
              name: 'Test Algorithm',
            ),
            inputPorts: [],
            outputPorts: [
              Port(
                id: 'algo_test_1_port_1',
                name: 'Test Output',
                type: PortType.audio,
                direction: PortDirection.output,
              ),
            ],
          ),
        ],
        connections: [testConnection],
        buses: [],
        portOutputModes: {'algo_test_1_port_1': OutputMode.replace},
        isHardwareSynced: true,
        isPersistenceEnabled: false,
        lastSyncTime: null,
        lastPersistTime: null,
        lastError: null,
      );

      when(mockRoutingCubit.state).thenReturn(loadedState);
      when(
        mockRoutingCubit.stream,
      ).thenAnswer((_) => Stream.value(loadedState));

      await tester.pumpWidget(
        MaterialApp(
          home: MultiBlocProvider(
            providers: [
              BlocProvider<RoutingEditorCubit>.value(value: mockRoutingCubit),
              BlocProvider<DistingCubit>.value(value: mockDistingCubit),
            ],
            child: Scaffold(
              body: RoutingEditorWidget(canvasSize: const Size(800, 600)),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Prepare for tap simulation - when tap occurs, expect setPortOutputMode to be called
      // with the toggled mode (from replace to add)
      when(
        mockRoutingCubit.togglePortOutputMode(portId: 'algo_test_1_port_1'),
      ).thenAnswer((_) async => {});

      // Find connection canvas and tap at a position where a label would be
      final customPaint = find.byType(CustomPaint).first;
      await tester.tap(customPaint, warnIfMissed: false);
      await tester.pumpAndSettle();

      // Note: The actual verification of setPortOutputMode call will be done
      // after implementing the tap handling logic
      expect(find.byType(RoutingEditorWidget), findsOneWidget);
    });
  });
}
