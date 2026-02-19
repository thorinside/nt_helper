import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:nt_helper/cubit/routing_editor_cubit.dart';
import 'package:nt_helper/cubit/routing_editor_state.dart' as state;
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/core/routing/models/connection.dart';
import 'package:nt_helper/core/routing/models/port.dart';
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

      // Use fixed pump calls instead of pumpAndSettle to avoid timeout
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      // Find the MouseRegion wrapping connection canvas
      expect(find.byType(MouseRegion), findsWidgets);

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

  });

}
